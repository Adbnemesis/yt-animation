extends Node2D

# Nita Production Combat Test Harness
# Stage 1: Basic Attack + Rupture Shockwave Projectile + Target Dummy

enum Mode {
	PROJECTILE_DEMO,
	WALKING_ATTACK_DEMO,
	RUNNING_ATTACK_DEMO,
	DIRECTIONAL_DEMO,
	INTERACTIVE
}

@onready var puppet: CharacterBody2D = $Puppet
@onready var dummy: Area2D = get_node_or_null("TargetDummy")
@onready var ground_line: Line2D = get_node_or_null("GroundLine")
@onready var mode_label: Label = $UI/InfoPanel/VBox/LblMode
@onready var stats_label: Label = $UI/InfoPanel/VBox/LblStats

var current_mode: Mode = Mode.PROJECTILE_DEMO
var base_ground_y: float = 520.0
var show_ground_line: bool = true
var time_elapsed: float = 0.0

# Demo timers
var demo_timer: float = 0.0
var last_attack_time: float = 0.0
var attacks_fired: int = 0

# Combat telemetry
var last_attack_event: String = "None"
var last_hit_info: String = "None"
var last_hit_time: float = -1.0

func _ready() -> void:
	_ensure_nodes()
	if puppet:
		puppet.position = Vector2(380, base_ground_y)
		var ap: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
		if ap and ap.has_animation("idle"):
			ap.play("idle")
		if puppet.has_signal("attack_event") and not puppet.attack_event.is_connected(_on_attack_event):
			puppet.attack_event.connect(_on_attack_event)

	if dummy and dummy.has_signal("hit_received") and not dummy.hit_received.is_connected(_on_dummy_hit_received):
		dummy.hit_received.connect(_on_dummy_hit_received)

	_update_ui()

func _ensure_nodes() -> void:
	if not puppet: puppet = get_node_or_null("Puppet")
	if not dummy: dummy = get_node_or_null("TargetDummy")
	if not ground_line: ground_line = get_node_or_null("GroundLine")
	if not mode_label: mode_label = get_node_or_null("UI/InfoPanel/VBox/LblMode")
	if not stats_label: stats_label = get_node_or_null("UI/InfoPanel/VBox/LblStats")

func _physics_process(delta: float) -> void:
	_ensure_nodes()
	time_elapsed += delta
	demo_timer += delta

	match current_mode:
		Mode.PROJECTILE_DEMO:
			_process_projectile_demo(delta)
		Mode.WALKING_ATTACK_DEMO:
			_process_walking_attack_demo(delta)
		Mode.RUNNING_ATTACK_DEMO:
			_process_running_attack_demo(delta)
		Mode.DIRECTIONAL_DEMO:
			_process_directional_demo(delta)
		Mode.INTERACTIVE:
			_process_interactive(delta)

	_update_ui()

func _process_projectile_demo(_delta: float) -> void:
	# Standing attack rhythmically every 0.9s
	puppet.input_dir = 0.0
	puppet.wants_run = false
	puppet.facing_direction = 1

	if demo_timer - last_attack_time >= 0.9:
		last_attack_time = demo_timer
		puppet.wants_attack = true
		attacks_fired += 1
	else:
		puppet.wants_attack = false

func _process_walking_attack_demo(_delta: float) -> void:
	# Walk back and forth between 240 and 520, attacking occasionally
	puppet.wants_run = false
	if puppet.position.x > 500:
		puppet.input_dir = -1.0
		puppet.facing_direction = -1
	elif puppet.position.x < 260:
		puppet.input_dir = 1.0
		puppet.facing_direction = 1

	if demo_timer - last_attack_time >= 1.2:
		last_attack_time = demo_timer
		puppet.wants_attack = true
		attacks_fired += 1
	else:
		puppet.wants_attack = false

func _process_running_attack_demo(_delta: float) -> void:
	# Run back and forth between 220 and 540, attacking occasionally
	puppet.wants_run = true
	if puppet.position.x > 520:
		puppet.input_dir = -1.0
		puppet.facing_direction = -1
	elif puppet.position.x < 240:
		puppet.input_dir = 1.0
		puppet.facing_direction = 1

	if demo_timer - last_attack_time >= 1.0:
		last_attack_time = demo_timer
		puppet.wants_attack = true
		attacks_fired += 1
	else:
		puppet.wants_attack = false

func _process_directional_demo(_delta: float) -> void:
	# Alternate facing left and right attacks every 1.0s
	if demo_timer - last_attack_time >= 1.0:
		last_attack_time = demo_timer
		puppet.facing_direction = -puppet.facing_direction
		puppet.wants_attack = true
		attacks_fired += 1
	else:
		puppet.wants_attack = false

func _process_interactive(_delta: float) -> void:
	var move_h = 0.0
	if Input.is_action_pressed("ui_left"):
		move_h -= 1.0
	if Input.is_action_pressed("ui_right"):
		move_h += 1.0

	puppet.input_dir = move_h
	puppet.wants_run = Input.is_key_pressed(KEY_SHIFT)
	puppet.wants_jump = Input.is_action_just_pressed("ui_accept")
	puppet.wants_attack = Input.is_key_pressed(KEY_J)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return

	match event.keycode:
		KEY_1: set_mode(Mode.PROJECTILE_DEMO)
		KEY_2: set_mode(Mode.WALKING_ATTACK_DEMO)
		KEY_3: set_mode(Mode.RUNNING_ATTACK_DEMO)
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
	if puppet:
		puppet.position = Vector2(380, base_ground_y)
		puppet.velocity = Vector2.ZERO
		puppet.facing_direction = 1
		puppet.input_dir = 0.0
		puppet.wants_run = false
		puppet.wants_attack = false
		if puppet.has_method("change_state"):
			puppet.change_state(puppet.State.IDLE)
	_update_ui()

func _on_attack_event(event_name: String, _data: Dictionary) -> void:
	last_attack_event = event_name

func _on_dummy_hit_received(hit_data: RefCounted) -> void:
	var dmg = hit_data.damage if "damage" in hit_data else 80.0
	last_hit_info = "-%.0f HP" % dmg
	last_hit_time = time_elapsed

func _update_ui() -> void:
	if not mode_label or not stats_label or not puppet:
		return

	var mode_str = ""
	match current_mode:
		Mode.PROJECTILE_DEMO: mode_str = "MODE: Projectile Demo (Single Shockwave • Collision • Despawn)"
		Mode.WALKING_ATTACK_DEMO: mode_str = "MODE: Walking Attack Demo (Locomotion + Attack)"
		Mode.RUNNING_ATTACK_DEMO: mode_str = "MODE: Running Attack Demo (Run Speed + Attack)"
		Mode.DIRECTIONAL_DEMO: mode_str = "MODE: Directional Attack Demo (Bidirectional Left/Right)"
		Mode.INTERACTIVE: mode_str = "MODE: Interactive (Arrows: Move, Shift: Run, J: Attack, Space: Jump)"

	mode_label.text = mode_str

	var anim_name = "idle"
	var anim_pos = 0.0
	var anim_len = 0.0
	var ap: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
	if ap and ap.is_playing() and ap.current_animation != "":
		anim_name = ap.current_animation
		anim_pos = ap.current_animation_position
		anim_len = ap.current_animation_length
	elif ap and ap.has_animation("idle"):
		anim_len = ap.get_animation("idle").length

	var state_name = "IDLE"
	if "current_state" in puppet:
		state_name = str(puppet.current_state)
		if puppet.get("State") != null:
			var s_keys = puppet.State.keys()
			if puppet.current_state < s_keys.size():
				state_name = s_keys[puppet.current_state]

	var face_str = "+1 (RIGHT)" if puppet.facing_direction > 0 else "-1 (LEFT)"
	var is_g = puppet.is_on_floor() if puppet.has_method("is_on_floor") else true

	var active_projs = 0
	for child in get_children():
		if child is Area2D and child.is_in_group("projectiles") and "is_active" in child and child.is_active:
			active_projs += 1

	var dummy_hp = "N/A"
	if dummy:
		dummy_hp = "%.0f / %.0f" % [dummy.current_hp, dummy.max_hp]

	var hit_display = last_hit_info
	if last_hit_time > 0 and time_elapsed - last_hit_time > 2.0:
		hit_display = "Idle"

	stats_label.text = (
		"STATE: %s | ANIM: %s (%.2fs/%.2fs) | FACING: %s | GROUNDED: %s\n" % [state_name, anim_name, anim_pos, anim_len, face_str, str(is_g)] +
		"PROJECTILES ACTIVE: %d | LAST EVENT: %s | LAST HIT: %s | TARGET HP: %s\n" % [active_projs, last_attack_event, hit_display, dummy_hp] +
		"SPEED: 600 px/s | BURST: 1 Shockwave | RANGE: 480 px | VEL: (%.1f, %.1f) px/s" % [puppet.velocity.x, puppet.velocity.y]
	)
