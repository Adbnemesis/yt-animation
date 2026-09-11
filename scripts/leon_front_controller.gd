extends Node2D
class_name LeonFrontController

# ============================================================================
# LEON FRONT-VIEW CONTROLLER
# ----------------------------------------------------------------------------
# Complete animation controller for the canonical front-view rig of Leon:
#   res://scenes/videos/leon_elevator/leon_front.tscn
#
# Controls:
# - Core States: IDLE, WALK, RUN, STOP, JUMP, ATTACK, SUPER, HIT
# - Natural procedural breathing, foot strides, arm swing, squash & stretch
# - Facial expressions & auto-blinking via FaceController
# - Attack aiming: Projectile trajectory is strictly derived from Leon's
#   rotation around the Z-axis (ground orientation / yaw), firing forward
#   towards the camera / target in 2.5D space.
# - Super ability: Invisibility smoke puff, transparency fade, and reappear.
# ============================================================================

signal attack_released(dir_vector: Vector2, spawn_world_offset: Vector2)
signal super_started()
signal super_ended()
signal state_changed(new_state: State)

enum State {
	IDLE,
	WALK,
	RUN,
	STOP,
	JUMP,
	ATTACK,
	SUPER,
	HIT
}

const STATE_NAMES := {
	State.IDLE: "IDLE",
	State.WALK: "WALK",
	State.RUN: "RUN",
	State.STOP: "STOP",
	State.JUMP: "JUMP",
	State.ATTACK: "ATTACK",
	State.SUPER: "SUPER",
	State.HIT: "HIT"
}

# Base resting offsets for canonical rig nodes
const TORSO_BASE_Y := -61.0
const HEAD_BASE_Y := -110.0
const ARM_L_BASE_POS := Vector2(-26.0, -68.0)
const ARM_R_BASE_POS := Vector2(26.0, -68.0)

# Hierarchy Node References
@onready var foot_l: Polygon2D = get_node_or_null("Feet/FootL")
@onready var foot_r: Polygon2D = get_node_or_null("Feet/FootR")
@onready var sole_l: Polygon2D = get_node_or_null("Feet/SoleL")
@onready var sole_r: Polygon2D = get_node_or_null("Feet/SoleR")
@onready var leg_l: Polygon2D = get_node_or_null("Legs/LegL")
@onready var leg_r: Polygon2D = get_node_or_null("Legs/LegR")
@onready var torso: Sprite2D = get_node_or_null("Torso")
@onready var arm_l: Node2D = get_node_or_null("ArmL")
@onready var arm_r: Node2D = get_node_or_null("ArmR")
@onready var head: Node2D = get_node_or_null("Head")
@onready var face: FaceController = get_node_or_null("Head/Face")

@export var auto_animate: bool = true

var current_state: State = State.IDLE
var wants_run: bool = false
var input_dir: float = 0.0

var _state_time: float = 0.0
var _walk_time: float = 0.0
var _is_attacking: bool = false
var _is_jumping: bool = false
var _is_hit: bool = false
var _is_super: bool = false

var _action_tween: Tween = null

func _ready() -> void:
	_ensure_node_refs()
	reset_to_idle()

func _ensure_node_refs() -> void:
	if not foot_l: foot_l = get_node_or_null("Feet/FootL")
	if not foot_r: foot_r = get_node_or_null("Feet/FootR")
	if not sole_l: sole_l = get_node_or_null("Feet/SoleL")
	if not sole_r: sole_r = get_node_or_null("Feet/SoleR")
	if not leg_l: leg_l = get_node_or_null("Legs/LegL")
	if not leg_r: leg_r = get_node_or_null("Legs/LegR")
	if not torso: torso = get_node_or_null("Torso")
	if not arm_l: arm_l = get_node_or_null("ArmL")
	if not arm_r: arm_r = get_node_or_null("ArmR")
	if not head: head = get_node_or_null("Head")
	if not face: face = get_node_or_null("Head/Face")

func _process(delta: float) -> void:
	if not auto_animate:
		return
		
	_state_time += delta
	
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta, 6.0, 5.0, 0.22, 1.5, 2.0)
		State.RUN:
			_process_walk(delta, 9.2, 9.0, 0.42, 2.8, 3.5)
		State.STOP:
			_process_stop(delta)
		State.JUMP:
			pass # Jump squash/stretch handled by tween
		State.ATTACK:
			# Arm motion driven by attack tween; torso slight breathing
			if torso and not _is_hit:
				torso.position.y = TORSO_BASE_Y + sin(_state_time * 2.0) * 0.5
		State.HIT:
			pass
		State.SUPER:
			_process_idle(delta)

# --- State Control -----------------------------------------------------------

func change_state(new_state: State) -> void:
	if current_state == new_state and not (new_state == State.ATTACK or new_state == State.HIT):
		return
		
	current_state = new_state
	_state_time = 0.0
	state_changed.emit(new_state)
	
	if new_state == State.IDLE:
		reset_to_idle()

func reset_to_idle() -> void:
	if torso:
		torso.position = Vector2(0.0, TORSO_BASE_Y)
		torso.rotation = 0.0
	if head:
		head.position = Vector2(0.0, HEAD_BASE_Y)
		head.rotation = 0.0
	if arm_l:
		arm_l.position = ARM_L_BASE_POS
		arm_l.rotation = 0.0
	if arm_r and not _is_attacking:
		arm_r.position = ARM_R_BASE_POS
		arm_r.rotation = 0.0
	_reset_feet()

func _reset_feet() -> void:
	if foot_l: foot_l.position.y = 0.0
	if foot_r: foot_r.position.y = 0.0
	if sole_l: sole_l.position.y = 0.0
	if sole_r: sole_r.position.y = 0.0
	if leg_l: leg_l.position.y = 0.0
	if leg_r: leg_r.position.y = 0.0

# --- Procedural Animators ---------------------------------------------------

func _process_idle(delta: float) -> void:
	var breath: float = sin(_state_time * 3.2) * 0.85
	if torso:
		torso.position.y = TORSO_BASE_Y + breath * 0.5
	if head:
		head.position.y = HEAD_BASE_Y + breath * 0.8
	if arm_l:
		arm_l.position.y = ARM_L_BASE_POS.y + breath * 0.35
		arm_l.rotation = sin(_state_time * 1.6) * 0.03
	if arm_r and not _is_attacking:
		arm_r.position.y = ARM_R_BASE_POS.y + breath * 0.35
		arm_r.rotation = -sin(_state_time * 1.6) * 0.03

func _process_walk(delta: float, cadence: float, foot_lift: float, arm_swing: float, sway_x: float, bounce_y: float) -> void:
	_walk_time += delta * cadence
	
	var cycle: float = sin(_walk_time)
	var abs_cycle: float = absf(cycle)
	
	# Feet alternating lift
	var l_lift: float = -maxf(0.0, sin(_walk_time)) * foot_lift
	var r_lift: float = -maxf(0.0, sin(_walk_time + PI)) * foot_lift
	
	if foot_l: foot_l.position.y = l_lift
	if sole_l: sole_l.position.y = l_lift
	if leg_l: leg_l.position.y = l_lift * 0.6
	
	if foot_r: foot_r.position.y = r_lift
	if sole_r: sole_r.position.y = r_lift
	if leg_r: leg_r.position.y = r_lift * 0.6
	
	# Body bounce & sway
	if torso:
		torso.position.y = TORSO_BASE_Y + abs_cycle * bounce_y
		torso.position.x = sin(_walk_time * 0.5) * sway_x
	if head:
		head.position.y = HEAD_BASE_Y + abs_cycle * (bounce_y * 1.2)
		head.position.x = sin(_walk_time * 0.5) * (sway_x * 0.8)
		
	# Arm swing in opposition
	if arm_l:
		arm_l.rotation = cycle * arm_swing
		arm_l.position.y = ARM_L_BASE_POS.y + abs_cycle * 1.2
	if arm_r and not _is_attacking:
		arm_r.rotation = -cycle * arm_swing
		arm_r.position.y = ARM_R_BASE_POS.y + abs_cycle * 1.2

func _process_stop(delta: float) -> void:
	_reset_feet()
	# Smooth settling to idle
	if _state_time > 0.4:
		change_state(State.IDLE)

# --- Actions & Mechanics ----------------------------------------------------

func trigger_jump() -> void:
	_ensure_node_refs()
	if _is_jumping:
		return
	_is_jumping = true
	change_state(State.JUMP)
	
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# 1. Anticipation squash
	_action_tween.tween_property(self, "scale", Vector2(1.10, 0.88), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Launch stretch
	_action_tween.tween_property(self, "scale", Vector2(0.92, 1.12), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. Airborne hang
	_action_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.28)
	
	# 4. Landing compression
	_action_tween.tween_property(self, "scale", Vector2(1.14, 0.86), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 5. Settle recovery
	_action_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_action_tween.tween_callback(func():
		_is_jumping = false
		change_state(State.IDLE)
	)

## Triggers front basic attack throwing a blade forward.
## Trajectory is strictly derived from Leon's rotation along the Z-axis (facing direction).
func trigger_attack(aim_angle_deg: float = INF) -> void:
	_ensure_node_refs()
	if _is_attacking:
		return
	_is_attacking = true
	change_state(State.ATTACK)
	
	# If caller explicitly supplied an aim rotation, rotate Leon to face that direction
	if not is_inf(aim_angle_deg):
		rotation = deg_to_rad(aim_angle_deg)
		
	var prev_state := current_state
	
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	var orig_pos := ARM_R_BASE_POS
	
	# 1. Wind-up anticipation (drawing arm back and up)
	if arm_r:
		_action_tween.tween_property(arm_r, "position", orig_pos + Vector2(-6.0, -14.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_action_tween.parallel().tween_property(arm_r, "rotation", -0.95, 0.10)
		
	# 2. Forward whip & release point
	if arm_r:
		_action_tween.tween_property(arm_r, "position", orig_pos + Vector2(12.0, 10.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_action_tween.parallel().tween_property(arm_r, "rotation", 0.65, 0.08)
		
	_action_tween.tween_callback(_on_attack_release_point)
	
	# 3. Follow-through and recovery
	if arm_r:
		_action_tween.tween_property(arm_r, "position", orig_pos, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_action_tween.parallel().tween_property(arm_r, "rotation", 0.0, 0.18)
		
	_action_tween.tween_callback(func():
		_is_attacking = false
		change_state(State.IDLE)
	)

func _on_attack_release_point() -> void:
	# Crucial: The projectile direction vector is strictly derived from Leon's
	# rotation along the Z-axis (ground plane orientation)!
	#
	# In 2.5D world space (x = lateral, z = depth into scene):
	#   rotation = 0   => Straight forward towards camera: dir = (0, -1)
	#   rotation = +θ  => Angled forward-right: dir = (sin θ, -cos θ)
	#   rotation = -θ  => Angled forward-left:  dir = (-sin θ, -cos θ)
	var z_rot: float = rotation
	var dir_2_5d := Vector2(sin(z_rot), -cos(z_rot)).normalized()
	
	# Calculate socket offset in world units
	var socket_local := Vector2(26.0, -42.0)
	var spawn_offset := Vector2(sin(z_rot) * 20.0, -cos(z_rot) * 15.0)
	
	attack_released.emit(dir_2_5d, spawn_offset)

func trigger_super() -> void:
	if _is_super:
		return
	_is_super = true
	change_state(State.SUPER)
	super_started.emit()
	
	_spawn_smoke_vfx()
	
	var tw := create_tween()
	# Fade to stealth (alpha = 0.22)
	tw.tween_property(self, "modulate:a", 0.22, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.8)
	tw.tween_callback(_spawn_smoke_vfx)
	# Reappear
	tw.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_is_super = false
		super_ended.emit()
		change_state(State.IDLE)
	)

func trigger_hit() -> void:
	_is_hit = true
	change_state(State.HIT)
	set_face_expression("hurt", "blink")
	
	var tw := create_tween()
	# Recoil flinch
	if torso:
		tw.tween_property(torso, "position:y", TORSO_BASE_Y - 9.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(torso, "rotation", -0.12, 0.08)
	if head:
		tw.parallel().tween_property(head, "position:y", HEAD_BASE_Y - 12.0, 0.08)
		tw.parallel().tween_property(head, "rotation", -0.15, 0.08)
		
	# Recoil recovery
	if torso:
		tw.tween_property(torso, "position:y", TORSO_BASE_Y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(torso, "rotation", 0.0, 0.22)
	if head:
		tw.parallel().tween_property(head, "position:y", HEAD_BASE_Y, 0.22)
		tw.parallel().tween_property(head, "rotation", 0.0, 0.22)
		
	tw.tween_callback(func():
		_is_hit = false
		set_face_expression("neutral", "open")
		change_state(State.IDLE)
	)

func set_face_expression(expr: String, eye_state: String = "open") -> void:
	if face and face.has_method("set_expression"):
		face.set_expression(expr)
		face.set_eye_state(eye_state)

func _spawn_smoke_vfx() -> void:
	var smoke := Node2D.new()
	smoke.name = "SmokePuff"
	smoke.position = Vector2(0, -60)
	smoke.z_index = z_index + 10
	add_child(smoke)
	
	for i in range(12):
		var puff := Polygon2D.new()
		puff.color = Color(0.18, 0.88, 0.95, 0.85)
		var pts := PackedVector2Array([
			Vector2(-14, -14), Vector2(14, -14),
			Vector2(16, 16), Vector2(-16, 16)
		])
		puff.polygon = pts
		var angle := randf() * TAU
		var dist := randf_range(10.0, 48.0)
		var target_offset := Vector2(cos(angle), sin(angle)) * dist
		smoke.add_child(puff)
		
		var tw := smoke.create_tween()
		tw.tween_property(puff, "position", target_offset, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(puff, "scale", Vector2.ZERO, 0.45).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(puff, "modulate:a", 0.0, 0.45)
		
	get_tree().create_timer(0.55).timeout.connect(smoke.queue_free)
