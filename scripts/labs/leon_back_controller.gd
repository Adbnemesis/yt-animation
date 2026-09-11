extends Node2D
class_name LeonBackController

# ============================================================================
# LEON BACK-VIEW CONTROLLER
# ----------------------------------------------------------------------------
# Complete animation controller for the canonical back-view rig:
#   res://scenes/videos/leon_elevator/leon_back.tscn
#
# This controller EXTENDS the existing approved back rig composition.
# It binds directly to the cutout pivots and animates them in place:
#
# BACK VIEW RULES:
# - Leon is viewed primarily from behind: rear silhouette, back of hood,
#   back of jacket, tail, rear view of arms and legs.
# - Tail is an expressive secondary motion element: it sways in idle,
#   counters leg strides in walk/run, tucks on jumps, flinches on hits.
# - Head/neck acting: because the face is not visible from behind, attention
#   and emotional state are communicated through head turns, head tilts,
#   shoulder shrugs, and tail reactions (Parts 32/33).
# - Attack trajectory: Leon faces away from camera into depth by default
#   (facing_yaw = 180° = PI rad). Projectile vector is dir = (sin yaw, -cos yaw),
#   firing forward into the 2.5D background (+z depth).
# - SFX & VFX: Uses Leon's character-specific audio chain via AudioManager.
# ============================================================================

signal attack_released(dir_vector: Vector2, spawn_offset: Vector2)
signal super_started
signal super_ended
signal state_changed(new_state: State)
signal knockback_started(dir_vector: Vector2)
signal landed

enum State { IDLE, ACCEL, WALK, RUN, STOP, JUMP, ATTACK, SUPER, HIT, KNOCKBACK, RECOVERY }

const STATE_NAMES := {
	State.IDLE: "IDLE",
	State.ACCEL: "ACCEL",
	State.WALK: "WALK",
	State.RUN: "RUN",
	State.STOP: "STOP",
	State.JUMP: "JUMP",
	State.ATTACK: "ATTACK",
	State.SUPER: "SUPER",
	State.HIT: "HIT",
	State.KNOCKBACK: "KNOCKBACK",
	State.RECOVERY: "RECOVERY"
}

# Base resting offsets — EXACT authored values of leon_back.tscn
const TORSO_BASE_POS := Vector2(0.0, -61.0)
const HEAD_BASE_POS := Vector2(0.0, -110.0)
const ARM_L_BASE_POS := Vector2(-26.0, -68.0)
const ARM_R_BASE_POS := Vector2(26.0, -68.0)
const TAIL_BASE_POS := Vector2(0.0, -22.0)
const ATTACK_SOCKET_LOCAL := Vector2(26.0, -32.0)

# Rig node references
@onready var tail: Sprite2D = get_node_or_null("Tail")
@onready var foot_l: Polygon2D = get_node_or_null("Feet/FootL")
@onready var foot_r: Polygon2D = get_node_or_null("Feet/FootR")
@onready var sole_l: Polygon2D = get_node_or_null("Feet/SoleL")
@onready var sole_r: Polygon2D = get_node_or_null("Feet/SoleR")
@onready var leg_l: Polygon2D = get_node_or_null("Legs/LegL")
@onready var leg_r: Polygon2D = get_node_or_null("Legs/LegR")
@onready var shorts_l: Polygon2D = get_node_or_null("Shorts/ShortL")
@onready var shorts_r: Polygon2D = get_node_or_null("Shorts/ShortR")
@onready var torso: Sprite2D = get_node_or_null("Torso")
@onready var head: Sprite2D = get_node_or_null("Head")
@onready var arm_l: Node2D = get_node_or_null("ArmL")
@onready var arm_r: Node2D = get_node_or_null("ArmR")

@export var auto_animate: bool = true

## Facing yaw in radians: 180° (PI rad) = facing away from camera into depth (+z)
var facing_yaw: float = deg_to_rad(180.0)

var current_state: State = State.IDLE
var wants_run: bool = false
var input_dir: float = 0.0

var _state_time: float = 0.0
var _walk_time: float = 0.0
var _is_attacking: bool = false
var _is_jumping: bool = false
var _is_hit: bool = false
var _is_super: bool = false

var _locomotion_state: State = State.IDLE
var _speed_factor: float = 0.0
var _depth_lean: float = 0.0
var _action_tween: Tween = null
var mirror_sign: float = 1.0


func _ready() -> void:
	_ensure_node_refs()
	reset_to_idle()


func _ensure_node_refs() -> void:
	if not tail:
		tail = get_node_or_null("Tail")
	if not foot_l:
		foot_l = get_node_or_null("Feet/FootL")
	if not foot_r:
		foot_r = get_node_or_null("Feet/FootR")
	if not sole_l:
		sole_l = get_node_or_null("Feet/SoleL")
	if not sole_r:
		sole_r = get_node_or_null("Feet/SoleR")
	if not leg_l:
		leg_l = get_node_or_null("Legs/LegL")
	if not leg_r:
		leg_r = get_node_or_null("Legs/LegR")
	if not shorts_l:
		shorts_l = get_node_or_null("Shorts/ShortL")
	if not shorts_r:
		shorts_r = get_node_or_null("Shorts/ShortR")
	if not torso:
		torso = get_node_or_null("Torso")
	if not head:
		head = get_node_or_null("Head")
	if not arm_l:
		arm_l = get_node_or_null("ArmL")
	if not arm_r:
		arm_r = get_node_or_null("ArmR")


func _process(delta: float) -> void:
	if not auto_animate:
		return

	_state_time += delta

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta, 5.8, 6.0, 0.24, 1.4, 1.8)
		State.RUN:
			_process_walk(delta, 8.8, 10.5, 0.44, 2.6, 3.2)
		State.STOP:
			_process_stop(delta)
		State.ACCEL:
			_process_accel(delta)
		State.JUMP:
			pass
		State.ATTACK:
			if torso and not _is_hit:
				torso.position.y = TORSO_BASE_POS.y + sin(_state_time * 2.0) * 0.4
			if tail:
				tail.rotation = sin(_state_time * 2.0) * 0.08
		State.SUPER:
			_process_idle(delta)
		State.HIT:
			pass
		State.KNOCKBACK:
			pass
		State.RECOVERY:
			_process_idle(delta)


func set_motion_context(speed_factor: float, depth_lean: float) -> void:
	_speed_factor = clampf(speed_factor, 0.0, 1.0)
	_depth_lean = clampf(depth_lean, -1.0, 1.0)


func change_state(new_state: State) -> void:
	if current_state == new_state and not (new_state in [State.ATTACK, State.HIT]):
		return
	current_state = new_state
	_state_time = 0.0
	state_changed.emit(new_state)

	if new_state == State.IDLE:
		reset_to_idle()


func set_locomotion(state: State) -> void:
	if _is_attacking or _is_jumping or _is_hit or _is_super:
		_locomotion_state = state
		return
	if current_state != state:
		change_state(state)


func reset_to_idle() -> void:
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	facing_yaw = deg_to_rad(180.0)
	_restore_pose()


func _restore_pose() -> void:
	if torso:
		torso.position = TORSO_BASE_POS
		torso.rotation = 0.0
	if head:
		head.position = HEAD_BASE_POS
		head.rotation = 0.0
	if tail:
		tail.position = TAIL_BASE_POS
		tail.rotation = 0.0
	if arm_l:
		arm_l.position = ARM_L_BASE_POS
		arm_l.rotation = 0.0
	if arm_r and not _is_attacking:
		arm_r.position = ARM_R_BASE_POS
		arm_r.rotation = 0.0
	if shorts_l:
		shorts_l.position = Vector2.ZERO
	if shorts_r:
		shorts_r.position = Vector2.ZERO
	_reset_feet()


func _reset_feet() -> void:
	if foot_l:
		foot_l.position = Vector2.ZERO
	if foot_r:
		foot_r.position = Vector2.ZERO
	if sole_l:
		sole_l.position = Vector2.ZERO
	if sole_r:
		sole_r.position = Vector2.ZERO
	if leg_l:
		leg_l.position = Vector2.ZERO
	if leg_r:
		leg_r.position = Vector2.ZERO


# ============================================================================
# PROCEDURAL ANIMATION LOOPS
# ============================================================================


## 1. BACK IDLE: subtle breathing, gentle shoulder drift, living tail sway.
func _process_idle(_delta: float) -> void:
	var breath: float = sin(_state_time * 2.8) * 0.75
	var sway: float = sin(_state_time * 1.4) * 0.6

	if torso:
		torso.position.y = TORSO_BASE_POS.y + breath * 0.45
		torso.position.x = TORSO_BASE_POS.x + sway * 0.35
		torso.rotation = sway * 0.008
	if head:
		head.position.y = HEAD_BASE_POS.y + breath * 0.7
		head.position.x = HEAD_BASE_POS.x + sway * 0.2
	if tail:
		tail.position.y = TAIL_BASE_POS.y + breath * 0.2
		tail.rotation = sin(_state_time * 2.2) * 0.12
	if arm_l:
		arm_l.position.y = ARM_L_BASE_POS.y + breath * 0.35
		arm_l.rotation = sin(_state_time * 1.4) * 0.035
	if arm_r and not _is_attacking:
		arm_r.position.y = ARM_R_BASE_POS.y + breath * 0.35
		arm_r.rotation = -sin(_state_time * 1.4) * 0.035


## 2. BACK WALK & RUN: alternating strides away into depth, arm swing, tail counter-sway.
func _process_walk(
	delta: float, cadence: float, foot_lift: float, arm_swing: float, sway_x: float, bounce_y: float
) -> void:
	_walk_time += delta * cadence
	var cycle: float = sin(_walk_time)
	var abs_cycle: float = absf(cycle)
	var is_left_stride: bool = cycle > 0.0

	var lift: float = foot_lift * (1.0 - absf(cos(_walk_time)))

	# Feet contact and lift
	if foot_l:
		foot_l.position.y = -lift if is_left_stride else 0.0
	if sole_l:
		sole_l.position.y = -lift if is_left_stride else 0.0
	if leg_l:
		leg_l.position.y = -lift * 0.5 if is_left_stride else 0.0

	if foot_r:
		foot_r.position.y = -lift if not is_left_stride else 0.0
	if sole_r:
		sole_r.position.y = -lift if not is_left_stride else 0.0
	if leg_r:
		leg_r.position.y = -lift * 0.5 if not is_left_stride else 0.0

	# Torso bounce and forward lean
	var lean_fwd := _depth_lean * 0.06
	if torso:
		torso.position.y = TORSO_BASE_POS.y - abs_cycle * bounce_y
		torso.position.x = TORSO_BASE_POS.x + cycle * sway_x
		torso.rotation = -cycle * 0.025 + lean_fwd
	if head:
		head.position.y = HEAD_BASE_POS.y - abs_cycle * (bounce_y * 1.1)
		head.position.x = HEAD_BASE_POS.x - cycle * (sway_x * 0.4)
		head.rotation = cycle * 0.015

	# Tail sways opposite to leg swing
	if tail:
		tail.rotation = -cycle * 0.25 + sin(_walk_time * 2.0) * 0.08
		tail.position.y = TAIL_BASE_POS.y - abs_cycle * (bounce_y * 0.6)

	# Arms counter-swing
	if arm_l:
		arm_l.rotation = cycle * arm_swing
		arm_l.position.y = ARM_L_BASE_POS.y - abs_cycle * (bounce_y * 0.5)
	if arm_r and not _is_attacking:
		arm_r.rotation = -cycle * arm_swing
		arm_r.position.y = ARM_R_BASE_POS.y - abs_cycle * (bounce_y * 0.5)


## 3. BACK STOP: deceleration ramp with foot braking and body settling.
func _process_stop(delta: float) -> void:
	_walk_time += delta * 3.0
	var settle: float = exp(-_state_time * 4.5)
	var breath: float = sin(_state_time * 2.0) * (0.8 * (1.0 - settle))

	if torso:
		torso.position = TORSO_BASE_POS + Vector2(0.0, -settle * 2.5 + breath * 0.4)
		torso.rotation = settle * 0.04
	if head:
		head.position = HEAD_BASE_POS + Vector2(0.0, settle * 1.5 + breath * 0.6)
		head.rotation = -settle * 0.02
	if tail:
		tail.rotation = sin(_state_time * 3.0) * 0.15 * settle
	if arm_l:
		arm_l.position = ARM_L_BASE_POS
		arm_l.rotation = settle * 0.12
	if arm_r and not _is_attacking:
		arm_r.position = ARM_R_BASE_POS
		arm_r.rotation = -settle * 0.12

	_reset_feet()
	if _state_time > 0.6:
		change_state(State.IDLE)


## 4. BACK ACCEL: anticipation crouch -> push-off -> walk transition.
func _process_accel(_delta: float) -> void:
	var t := clampf(_state_time / 0.35, 0.0, 1.0)
	var crouch := sin(t * PI) * 3.5

	if torso:
		torso.position.y = TORSO_BASE_POS.y + crouch
		torso.rotation = t * 0.05
	if head:
		head.position.y = HEAD_BASE_POS.y + crouch * 0.8
	if tail:
		tail.rotation = -t * 0.15


# ============================================================================
# HEAD & NECK ACTING (Parts 32/33)
# ============================================================================


## Communicates attention from behind via head turn / tilt.
func look_toward(angle_offset_deg: float, dur: float = 0.35) -> void:
	if not head:
		return
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "rotation", deg_to_rad(angle_offset_deg), dur)
	tw.parallel().tween_property(head, "position:x", HEAD_BASE_POS.x + angle_offset_deg * 0.15, dur)


func reset_head_pose(dur: float = 0.25) -> void:
	if not head:
		return
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "rotation", 0.0, dur)
	tw.parallel().tween_property(head, "position:x", HEAD_BASE_POS.x, dur)


# ============================================================================
# JUMP (Parts 17/18/19/20)
# ============================================================================


func trigger_jump() -> void:
	_ensure_node_refs()
	if _is_jumping:
		return
	_is_jumping = true
	_locomotion_state = (
		current_state if current_state in [State.WALK, State.RUN] else _locomotion_state
	)
	change_state(State.JUMP)
	_play_sfx("JUMP")

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# 1. ANTICIPATION: body compresses down
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y + 7.0, 0.10)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_IN)
		)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y + 5.0, 0.10)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", 0.2, 0.10)
	if arm_l:
		_action_tween.parallel().tween_property(arm_l, "rotation", 0.3, 0.10)
	if arm_r and not _is_attacking:
		_action_tween.parallel().tween_property(arm_r, "rotation", -0.3, 0.10)

	# 2. LAUNCH: stretch upward
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y - 8.0, 0.12)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y - 6.0, 0.12)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", -0.25, 0.12)

	# 3. AIRBORNE: tuck legs, stabilize
	_action_tween.tween_callback(
		func():
			if foot_l:
				foot_l.position.y = -6.0
			if foot_r:
				foot_r.position.y = -6.0
	)
	_action_tween.tween_interval(0.28)

	# 4. LANDING: heavy contact compression
	_action_tween.tween_callback(
		func():
			_reset_feet()
			_play_sfx("LAND")
			landed.emit()
	)
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y + 6.0, 0.09)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_IN)
		)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y + 4.0, 0.09)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", 0.3, 0.09)

	# 5. RECOVERY: elastic settle back to base
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y, 0.22)
			. set_trans(Tween.TRANS_ELASTIC)
			. set_ease(Tween.EASE_OUT)
		)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y, 0.22)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", 0.0, 0.22)
	if arm_l:
		_action_tween.parallel().tween_property(arm_l, "rotation", 0.0, 0.22)
	if arm_r and not _is_attacking:
		_action_tween.parallel().tween_property(arm_r, "rotation", 0.0, 0.22)

	var prev_state := _locomotion_state
	_action_tween.tween_callback(
		func():
			_is_jumping = false
			change_state(prev_state)
	)


func is_jumping() -> bool:
	return _is_jumping


# ============================================================================
# BASIC ATTACK & PROJECTILE (Parts 23/24/25/26/27)
# ============================================================================


func trigger_attack(aim_angle_deg: float = INF) -> void:
	_ensure_node_refs()
	if _is_attacking:
		return
	_is_attacking = true
	_locomotion_state = (
		current_state if current_state in [State.WALK, State.RUN] else _locomotion_state
	)
	change_state(State.ATTACK)

	if not is_inf(aim_angle_deg):
		facing_yaw = deg_to_rad(aim_angle_deg)
	else:
		facing_yaw = deg_to_rad(180.0)

	var prev_state := _locomotion_state

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# 1. ANTICIPATION: Right arm pulls back, torso coils away
	(
		_action_tween
		. tween_property(arm_r, "position", ARM_R_BASE_POS + Vector2(-8.0, -6.0), 0.09)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	_action_tween.parallel().tween_property(arm_r, "rotation", -0.55, 0.09)
	if torso:
		_action_tween.parallel().tween_property(torso, "rotation", 0.06, 0.09)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", -0.2, 0.09)

	# 2. PREPARE / AIM hold
	_action_tween.tween_interval(0.05)

	# 3. RELEASE: Right arm swings forward through socket
	_action_tween.tween_callback(_on_attack_release_point)
	(
		_action_tween
		. tween_property(arm_r, "position", ARM_R_BASE_POS + Vector2(12.0, 2.0), 0.08)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	_action_tween.parallel().tween_property(arm_r, "rotation", 0.8, 0.08)
	if torso:
		_action_tween.parallel().tween_property(torso, "rotation", -0.08, 0.08)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", 0.25, 0.08)

	# 4. FOLLOW-THROUGH / RECOVERY
	(
		_action_tween
		. tween_property(arm_r, "position", ARM_R_BASE_POS, 0.18)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	_action_tween.parallel().tween_property(arm_r, "rotation", 0.0, 0.18)
	if torso:
		_action_tween.parallel().tween_property(torso, "rotation", 0.0, 0.18)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", 0.0, 0.18)

	_action_tween.tween_callback(
		func():
			_is_attacking = false
			_play_sfx("RELOAD")
			change_state(prev_state)
	)


func _on_attack_release_point() -> void:
	# Trajectory strictly derived from facing_yaw:
	# yaw = 180° => dir = (sin 180, -cos 180) = (0, 1) straight into depth away from camera
	var dir_2_5d := Vector2(sin(facing_yaw), -cos(facing_yaw)).normalized()
	var spawn_offset := Vector2(
		mirror_sign * ATTACK_SOCKET_LOCAL.x + sin(facing_yaw) * 12.0,
		ATTACK_SOCKET_LOCAL.y + cos(facing_yaw) * 10.0
	)

	_play_sfx("ATTACK_RELEASE")
	attack_released.emit(dir_2_5d, spawn_offset)


func is_attacking() -> bool:
	return _is_attacking


func attack_socket_local() -> Vector2:
	return Vector2(ATTACK_SOCKET_LOCAL.x * mirror_sign, ATTACK_SOCKET_LOCAL.y)


func set_mirror_sign(sign: float) -> void:
	mirror_sign = sign


# ============================================================================
# SUPER (Parts 29/30/31)
# ============================================================================


func trigger_super() -> void:
	_ensure_node_refs()
	if _is_super:
		return
	_is_super = true
	_locomotion_state = (
		current_state if current_state in [State.WALK, State.RUN] else _locomotion_state
	)
	change_state(State.SUPER)
	_play_sfx("SUPER_START")
	super_started.emit()

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# 1. Crouch windup
	_action_tween.tween_callback(_spawn_smoke_vfx)
	if torso:
		_action_tween.tween_property(torso, "position:y", TORSO_BASE_POS.y + 8.0, 0.12)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", 0.35, 0.12)

	# 2. Stealth shimmer fade
	_action_tween.tween_property(self, "modulate:a", 0.22, 0.15)
	if torso:
		_action_tween.parallel().tween_property(torso, "position:y", TORSO_BASE_POS.y, 0.15)

	# 3. Stealth duration
	_action_tween.tween_interval(1.6)

	# 4. Reappear & recovery
	_action_tween.tween_callback(_spawn_smoke_vfx)
	_action_tween.tween_callback(func(): _play_sfx("SUPER_END"))
	_action_tween.tween_property(self, "modulate:a", 1.0, 0.18)

	var prev_state := _locomotion_state
	_action_tween.tween_callback(
		func():
			_is_super = false
			super_ended.emit()
			change_state(prev_state)
	)


func is_super() -> bool:
	return _is_super


# ============================================================================
# HIT / KNOCKBACK / RECOVERY (Parts 21/22)
# ============================================================================


func trigger_hit(knock_dir: Vector2 = Vector2.ZERO) -> void:
	_ensure_node_refs()
	if _is_hit:
		return
	_is_hit = true
	_locomotion_state = (
		current_state if current_state in [State.WALK, State.RUN] else _locomotion_state
	)
	change_state(State.HIT)
	_play_sfx("CHARACTER_HIT")

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# Recoil flinch readable from behind: torso recoil, head snap, tail twitch
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y - 9.0, 0.08)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
		_action_tween.parallel().tween_property(torso, "rotation", -0.12, 0.08)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y - 10.0, 0.08)
		_action_tween.parallel().tween_property(head, "rotation", 0.08, 0.08)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", -0.4, 0.08)

	if knock_dir != Vector2.ZERO:
		knockback_started.emit(knock_dir)

	# Settle back to base
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y, 0.24)
			. set_trans(Tween.TRANS_ELASTIC)
			. set_ease(Tween.EASE_OUT)
		)
		_action_tween.parallel().tween_property(torso, "rotation", 0.0, 0.24)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y, 0.24)
		_action_tween.parallel().tween_property(head, "rotation", 0.0, 0.24)
	if tail:
		_action_tween.parallel().tween_property(tail, "rotation", 0.0, 0.24)

	var prev_state := _locomotion_state
	_action_tween.tween_callback(
		func():
			_is_hit = false
			change_state(prev_state)
	)


func is_hit() -> bool:
	return _is_hit


# ============================================================================
# AUDIO INTEGRATION
# ============================================================================


func _play_sfx(event_name: String) -> void:
	var tree := get_tree()
	if tree and tree.root.has_node("AudioManager"):
		tree.root.get_node("AudioManager").trigger_event(event_name, {"character": "leon"})


## Cyan smoke puff for the Super, anchored to body center
func _spawn_smoke_vfx() -> void:
	var smoke := Node2D.new()
	smoke.name = "SmokePuff"
	smoke.position = Vector2(0, -60)
	smoke.z_index = z_index + 10
	add_child(smoke)

	for i in range(12):
		var puff := Polygon2D.new()
		puff.color = Color(0.18, 0.88, 0.95, 0.85)
		var pts := PackedVector2Array(
			[Vector2(-14, -14), Vector2(14, -14), Vector2(16, 16), Vector2(-16, 16)]
		)
		puff.polygon = pts
		var angle := randf() * TAU
		var dist := randf_range(10.0, 48.0)
		var target_offset := Vector2(cos(angle), sin(angle)) * dist
		smoke.add_child(puff)

		var tw := smoke.create_tween()
		(
			tw
			. tween_property(puff, "position", target_offset, 0.45)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
		(
			tw
			. parallel()
			. tween_property(puff, "scale", Vector2.ZERO, 0.45)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_IN)
		)
	get_tree().create_timer(0.6).timeout.connect(func(): if is_instance_valid(smoke): smoke.queue_free())
