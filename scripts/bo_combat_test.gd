extends Node2D

# Bo Production Combat Test Harness
# Stage 1: Basic Attack (BO_BASIC_ATTACK) + Arrow Projectile + Target Dummy
#
# Validates causality: Bo fires -> arrow visibly leaves the weapon -> arrow
# travels -> arrow collides -> only then hit VFX / target reaction.
#
# Modes: 1 Standing Demo | 2 Walking Demo | 3 Running Demo | 4 Directional Demo
#        5 Interactive (A/D move, SHIFT run, SPACE jump, J attack)
#        R reset dummy | T toggle ground line

enum Mode {
	STANDING_DEMO,
	WALKING_DEMO,
	RUNNING_DEMO,
	DIRECTIONAL_DEMO,
	INTERACTIVE
}

@onready var bo: BrawlerBase = $Bo
@onready var dummy: Area2D = get_node_or_null("TargetDummy")
@onready var ground_line: Line2D = get_node_or_null("GroundLine")
@onready var mode_label: Label = $UI/InfoPanel/VBox/LblMode
@onready var stats_label: Label = $UI/InfoPanel/VBox/LblStats

var current_mode: Mode = Mode.INTERACTIVE
var base_ground_y: float = 520.0
var show_ground_line: bool = true
var time_elapsed: float = 0.0

# Demo timers
var demo_timer: float = 0.0
var last_attack_time: float = 0.0
var attacks_fired: int = 0
var demo_direction: int = 1

# Combat telemetry
var last_attack_event: String = "None"
var last_hit_info: String = "None"
var last_hit_time: float = -1.0

func _ready() -> void:
	_ensure_nodes()
	if bo:
		bo.position = Vector2(380, base_ground_y)
		var ap: AnimationPlayer = bo.get_node_or_null("AnimPlayer")
		if ap and ap.has_animation("idle"):
			ap.play("idle")
		if not bo.game_event_emitted.is_connected(_on_game_event):
			bo.game_event_emitted.connect(_on_game_event)

	if dummy:
		if dummy.has_signal("hit_received") and not dummy.hit_received.is_connected(_on_dummy_hit_received):
			dummy.hit_received.connect(_on_dummy_hit_received)
		# Impact VFX is bound to the TARGET so it can only trigger from a real
		# projectile collision — never from the attack animation itself.
		if get_tree().root.has_node("VFXManager") and dummy.has_signal("hit_received"):
			get_tree().root.get_node("VFXManager").bind_target(dummy)

	_update_ui()

func _ensure_nodes() -> void:
	if not bo: bo = get_node_or_null("Bo") as BrawlerBase
	if not dummy: dummy = get_node_or_null("TargetDummy")
	if not ground_line: ground_line = get_node_or_null("GroundLine")
	if not mode_label: mode_label = get_node_or_null("UI/InfoPanel/VBox/LblMode")
	if not stats_label: stats_label = get_node_or_null("UI/InfoPanel/VBox/LblStats")

func _physics_process(delta: float) -> void:
	_ensure_nodes()
	time_elapsed += delta
	demo_timer += delta

	match current_mode:
		Mode.STANDING_DEMO:
			_process_standing_demo()
		Mode.WALKING_DEMO:
			_process_walking_demo()
		Mode.RUNNING_DEMO:
			_process_running_demo()
		Mode.DIRECTIONAL_DEMO:
			_process_directional_demo(delta)
		Mode.INTERACTIVE:
			_process_interactive()

	_update_ui()

# --- Demo Modes ---

func _try_attack(interval: float) -> void:
	if demo_timer - last_attack_time >= interval:
		last_attack_time = demo_timer
		if bo.attack():
			attacks_fired += 1

func _process_standing_demo() -> void:
	bo.move(0.0, false)
	bo.movement_controller.facing_direction = 1
	_try_attack(0.9)

func _process_walking_demo() -> void:
	bo.move(demo_direction, false)
	if bo.position.x > 640:
		demo_direction = -1
	elif bo.position.x < 220:
		demo_direction = 1
	_try_attack(1.2)

func _process_running_demo() -> void:
	bo.move(demo_direction, true)
	if bo.position.x > 660:
		demo_direction = -1
	elif bo.position.x < 200:
		demo_direction = 1
	_try_attack(1.2)

func _process_directional_demo(delta: float) -> void:
	bo.move(0.0, false)
	if fmod(time_elapsed, 3.2) < delta:
		demo_direction = -demo_direction
	bo.movement_controller.facing_direction = demo_direction
	_try_attack(0.9)

func _process_interactive() -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir += 1.0
	var sprint := Input.is_key_pressed(KEY_SHIFT)
	bo.move(dir, sprint)
	if Input.is_key_pressed(KEY_SPACE):
		bo.jump()
	if Input.is_key_pressed(KEY_J):
		bo.attack()

# --- Telemetry ---

func _on_game_event(event_name: String, _data: Dictionary) -> void:
	last_attack_event = event_name

func _on_dummy_hit_received(hit_data: RefCounted) -> void:
	var dmg = hit_data.damage if "damage" in hit_data else 40.0
	var atk_type = hit_data.attack_type if "attack_type" in hit_data else "?"
	last_hit_info = "-%.0f HP (%s)" % [dmg, atk_type]
	last_hit_time = time_elapsed

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()):
		return

	match event.keycode:
		KEY_1: set_mode(Mode.STANDING_DEMO)
		KEY_2: set_mode(Mode.WALKING_DEMO)
		KEY_3: set_mode(Mode.RUNNING_DEMO)
		KEY_4: set_mode(Mode.DIRECTIONAL_DEMO)
		KEY_5: set_mode(Mode.INTERACTIVE)
		KEY_R:
			if dummy and dummy.has_method("reset_dummy"):
				dummy.reset_dummy()
		KEY_T:
			show_ground_line = not show_ground_line
			if ground_line:
				ground_line.visible = show_ground_line

func set_mode(m: Mode) -> void:
	current_mode = m
	demo_timer = 0.0
	last_attack_time = -1.0
	demo_direction = 1
	if bo:
		bo.position = Vector2(380, base_ground_y)
		bo.velocity = Vector2.ZERO
		bo.movement_controller.facing_direction = 1
		bo.move(0.0, false)
	_update_ui()

func _update_ui() -> void:
	if not mode_label or not stats_label or not bo:
		return

	var mode_str = ""
	match current_mode:
		Mode.STANDING_DEMO: mode_str = "MODE: Standing Attack Demo (3-Arrow Volley • Collision • Hit)"
		Mode.WALKING_DEMO: mode_str = "MODE: Walking Attack Demo (Locomotion + Attack)"
		Mode.RUNNING_DEMO: mode_str = "MODE: Running Attack Demo (Run Speed + Attack)"
		Mode.DIRECTIONAL_DEMO: mode_str = "MODE: Directional Attack Demo (Bidirectional Left/Right)"
		Mode.INTERACTIVE: mode_str = "MODE: Interactive (A/D: Move, SHIFT: Run, SPACE: Jump, J: Attack)"

	mode_label.text = mode_str

	var anim_name := "none"
	var anim_pos := 0.0
	var anim_len := 0.0
	var ap: AnimationPlayer = bo.get_node_or_null("AnimPlayer")
	if ap and ap.is_playing() and ap.current_animation != "":
		anim_name = ap.current_animation
		anim_pos = ap.current_animation_position
		anim_len = ap.current_animation_length

	var state_name := "IDLE"
	if bo.movement_controller:
		state_name = BrawlerMovementController.STATE_NAMES.get(
			bo.movement_controller.current_state, "UNKNOWN")

	var face_str = "+1 (RIGHT)" if bo.facing_direction > 0 else "-1 (LEFT)"

	var active_projs := 0
	for child in get_children():
		if child is Area2D and child.is_in_group("projectiles") and "is_active" in child and child.is_active:
			active_projs += 1

	var dummy_hp := "N/A"
	if dummy and "current_hp" in dummy:
		dummy_hp = "%.0f / %.0f" % [dummy.current_hp, dummy.max_hp]

	var hit_display = last_hit_info
	if last_hit_time > 0 and time_elapsed - last_hit_time > 2.0:
		hit_display = "Idle"

	stats_label.text = (
		"BO STATE: %s | ANIM: %s (%.2fs/%.2fs) | FACING: %s\n" % [state_name, anim_name, anim_pos, anim_len, face_str] +
		"PROJECTILES ACTIVE: %d | LAST EVENT: %s | LAST HIT: %s | TARGET HP: %s\n" % [active_projs, last_attack_event, hit_display, dummy_hp] +
		"ARROW SPEED: %.0f px/s | VOLLEY: %d arrows | RANGE: %.0f px | VEL: (%.1f, %.1f) px/s" % [620.0, 3, 520.0, bo.velocity.x, bo.velocity.y]
	)

