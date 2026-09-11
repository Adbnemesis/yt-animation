extends Node2D
class_name LeonThreeQuarterController

# ============================================================================
# LEON 3/4-VIEW CONTROLLER
# ----------------------------------------------------------------------------
# Complete animation controller for the canonical cinematic-lab 3/4 rig:
#   res://scenes/labs/characters/leon_multiview_lab/view_front_3q.tscn
#
# This controller EXTENDS the existing cinematic-lab 3/4 implementation
# (approved hood_34.svg composition). It does NOT re-rig anything: it binds to
# the same cutout pivots the lab already uses and animates them in place,
# exactly the way leon_front_controller.gd binds to the front rig.
#
# 3/4 VIEW RULES (view-specific quality):
# - The art is authored turning toward the viewer's right, so the NEAR side
#   of the body is the artwork's RIGHT side (ArmR, FootR, LegR) and the FAR
#   side is the LEFT. Every animation keeps near/far asymmetric — never a
#   front-facing idle pasted onto an angled body.
# - The face is embedded in the head: head rotation carries Head/Face with it
#   so eyes/brows/mouth stay aligned with the 3/4 head turn.
# - Root scale is NEVER animated here: the multiview controller mirrors this
#   view by setting scale.x = -1. Squash/stretch is done through rig-node
#   compression so mirroring always stays intact.
# - Attack trajectory is strictly derived from the character's facing yaw
#   (Z-rotation): rotation = 0 fires toward the camera (dir = (0, -1)),
#   +theta fires toward (sin, -cos) — the same spatial contract as the front
#   controller, so 2.5D behaviour stays consistent across views.
# - SFX uses the real Leon audio chain via AudioManager.trigger_event.
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

# Base resting offsets — EXACT authored values of view_front_3q.tscn
const TORSO_BASE_POS := Vector2(0.0, -61.0)
const HEAD_BASE_POS := Vector2(0.0, -110.0)
const ARM_L_BASE_POS := Vector2(-23.0, -68.0)  # far arm (smaller sleeve = farther)
const ARM_R_BASE_POS := Vector2(27.0, -68.0)  # near arm (bigger sleeve = nearer)
const ATTACK_SOCKET_LOCAL := Vector2(27.0, -32.0)
const FACE_BASE_POS := Vector2(6.0, 14.0)  # authored 3/4 face shift in head
const PUPIL_BASE_POS := Vector2(2.0, 0.0)

# Rig node references (existing cinematic-lab 3/4 cutout pivots)
@onready var foot_l: Polygon2D = get_node_or_null("Feet/FootL")
@onready var foot_r: Polygon2D = get_node_or_null("Feet/FootR")
@onready var sole_l: Polygon2D = get_node_or_null("Feet/SoleL")
@onready var sole_r: Polygon2D = get_node_or_null("Feet/SoleR")
@onready var leg_l: Polygon2D = get_node_or_null("Legs/LegL")
@onready var leg_r: Polygon2D = get_node_or_null("Legs/LegR")
@onready var shorts_l: Polygon2D = get_node_or_null("Shorts/ShortL")
@onready var shorts_r: Polygon2D = get_node_or_null("Shorts/ShortR")
@onready var torso: Sprite2D = get_node_or_null("Torso")
@onready var arm_l: Node2D = get_node_or_null("ArmL")  # far arm
@onready var arm_r: Node2D = get_node_or_null("ArmR")  # near arm
@onready var head: Node2D = get_node_or_null("Head")
@onready var face: FaceController = get_node_or_null("Head/Face")
@onready var pupil_l: Sprite2D = get_node_or_null("Head/Face/EyeL/PupilL")
@onready var pupil_r: Sprite2D = get_node_or_null("Head/Face/EyeR/PupilR")

@export var auto_animate: bool = true

## Facing yaw in radians (Z-rotation convention shared with the front view):
## In 3/4 view, resting facing is +35° (front-right) when unmirrored, -35° when mirrored.
var facing_yaw: float = deg_to_rad(35.0)

var current_state: State = State.IDLE
var wants_run: bool = false
var input_dir: float = 0.0

var _state_time: float = 0.0
var _walk_time: float = 0.0
var _is_attacking: bool = false
var _is_jumping: bool = false
var _is_hit: bool = false
var _is_super: bool = false

# Locomotion context (the state actions return to after finishing)
var _locomotion_state: State = State.IDLE

# 3/4 body language amounts (set by the lab driver from actual movement)
var _depth_lean: float = 0.0  # + lean toward camera, - lean away
var _speed_factor: float = 0.0  # 0..1 how fast we are actually moving
var _gaze_offset: Vector2 = Vector2.ZERO

var _action_tween: Tween = null


func _ready() -> void:
	_ensure_node_refs()
	reset_to_idle()


func _ensure_node_refs() -> void:
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
	if not arm_l:
		arm_l = get_node_or_null("ArmL")
	if not arm_r:
		arm_r = get_node_or_null("ArmR")
	if not head:
		head = get_node_or_null("Head")
	if not face:
		face = get_node_or_null("Head/Face")
	if not pupil_l:
		pupil_l = get_node_or_null("Head/Face/EyeL/PupilL")
	if not pupil_r:
		pupil_r = get_node_or_null("Head/Face/EyeR/PupilR")


func _process(delta: float) -> void:
	if not auto_animate:
		return

	_state_time += delta

	match current_state:
		State.IDLE:
			_process_idle()
		State.ACCEL:
			_process_accel()
		State.WALK:
			_process_walk(delta, 5.6, 7.0, 0.20, 1.6, 1.6)
		State.RUN:
			_process_walk(delta, 8.8, 12.0, 0.44, 2.4, 3.4)
		State.STOP:
			_process_stop()
		State.JUMP:
			pass  # Jump compression/stretch handled by the jump tween
		State.ATTACK:
			# Attack arm motion driven by the attack tween; keep torso alive
			if torso and not _is_hit:
				torso.position.y = TORSO_BASE_POS.y + sin(_state_time * 2.0) * 0.5
		State.HIT, State.KNOCKBACK, State.RECOVERY:
			pass
		State.SUPER:
			_process_idle()


# --- State control -----------------------------------------------------------


func change_state(new_state: State) -> void:
	if (
		current_state == new_state
		and not (
			new_state == State.ATTACK or new_state == State.HIT or new_state == State.KNOCKBACK
		)
	):
		return

	current_state = new_state
	_state_time = 0.0
	state_changed.emit(new_state)

	if new_state == State.IDLE:
		reset_to_idle()


## Locomotion context: which state actions should return to (IDLE/WALK/RUN).
func set_locomotion(state: State) -> void:
	_locomotion_state = state
	if current_state in [State.IDLE, State.WALK, State.RUN, State.ACCEL, State.STOP]:
		change_state(state)


func reset_to_idle() -> void:
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	facing_yaw = deg_to_rad(35.0 * mirror_sign)
	_restore_pose()


func _restore_pose() -> void:
	if torso:
		torso.position = TORSO_BASE_POS
		torso.rotation = 0.0
	if head:
		head.position = HEAD_BASE_POS
		head.rotation = 0.0
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
	_reset_gaze()


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


# --- Gaze / face (Parts 36/37/38) --------------------------------------------


func set_face_expression(expr: String, eye_state: String = "open") -> void:
	if face and face.has_method("set_expression"):
		face.set_expression(expr)
		face.set_eye_state(eye_state)


func blink_now() -> void:
	if face and face.has_method("_trigger_blink"):
		face._trigger_blink()


## 3/4 eyeline: pupils drift within the eyes and the head tilts slightly
## toward the gaze point while the authored 3/4 head turn is preserved.
func set_gaze(offset: Vector2) -> void:
	_gaze_offset = Vector2(clampf(offset.x, -3.5, 3.5), clampf(offset.y, -2.5, 2.5))


func _reset_gaze() -> void:
	_gaze_offset = Vector2.ZERO
	if pupil_l:
		pupil_l.position = PUPIL_BASE_POS
	if pupil_r:
		pupil_r.position = PUPIL_BASE_POS


func _apply_gaze() -> void:
	# Far eye drifts less than the near eye (depth-consistent gaze)
	if pupil_l:
		pupil_l.position = PUPIL_BASE_POS + _gaze_offset * 0.5
	if pupil_r:
		pupil_r.position = PUPIL_BASE_POS + _gaze_offset
	if head and not (current_state in [State.HIT, State.KNOCKBACK, State.JUMP]):
		head.rotation = _depth_lean * 0.35 + _gaze_offset.x * 0.006


## Movement modifier from the spatial driver: how fast we actually move and
## whether we move toward/away from the camera (drives the 3/4 body lean).
func set_motion_context(speed_factor: float, depth_lean: float) -> void:
	_speed_factor = clampf(speed_factor, 0.0, 1.0)
	_depth_lean = clampf(depth_lean, -1.0, 1.0)


# --- Procedural animators ----------------------------------------------------


func _process_idle() -> void:
	# Asymmetric 3/4 breathing: the near side (R) breathes more than the far (L)
	var breath := sin(_state_time * 3.2) * 0.85
	if torso:
		torso.position.y = TORSO_BASE_POS.y + breath * 0.5
		torso.position.x = TORSO_BASE_POS.x + sin(_state_time * 0.9) * 0.9
		torso.rotation = _depth_lean * 0.045
	if head:
		head.position.y = HEAD_BASE_POS.y + breath * 0.8
		head.position.x = HEAD_BASE_POS.x + sin(_state_time * 0.9) * 0.65
	# Near arm hangs slightly ahead of the far arm (3/4 asymmetry)
	if arm_l:
		arm_l.position.y = ARM_L_BASE_POS.y + breath * 0.2
		arm_l.rotation = -sin(_state_time * 1.6) * 0.022
	if arm_r and not _is_attacking:
		arm_r.position.y = ARM_R_BASE_POS.y + breath * 0.35
		arm_r.position.x = ARM_R_BASE_POS.x + sin(_state_time * 0.9) * 0.3
		arm_r.rotation = sin(_state_time * 1.6) * 0.03
	# Weight shift through the hip line
	if shorts_l:
		shorts_l.position.x = sin(_state_time * 0.9) * 0.5
	if shorts_r:
		shorts_r.position.x = sin(_state_time * 0.9) * 0.5
	_apply_gaze()


func _process_accel() -> void:
	# Start-up: crouch push-off, then hand over to the locomotion state
	var t := _state_time
	if t < 0.16:
		_apply_crouch(remap(t, 0.0, 0.16, 0.0, 1.0) * 0.5)
	elif t < 0.34:
		_apply_crouch(remap(t, 0.16, 0.34, 0.5, 1.0))
	elif t < 0.55:
		_apply_crouch(remap(t, 0.34, 0.55, 1.0, 0.0))
		# push-off: near leg drives back
		if foot_r:
			foot_r.position.x = remap(t, 0.34, 0.55, 0.0, -3.0)
		if leg_r:
			leg_r.position.x = remap(t, 0.34, 0.55, 0.0, -2.0)
	else:
		change_state(_locomotion_state)


func _apply_crouch(amount: float) -> void:
	# amount 0..1 — compression through hips/torso, feet stay planted
	if torso:
		torso.position.y = TORSO_BASE_POS.y + amount * 6.0
	if head:
		head.position.y = HEAD_BASE_POS.y + amount * 8.0
	if arm_l:
		arm_l.position.y = ARM_L_BASE_POS.y + amount * 4.0
	if arm_r:
		arm_r.position.y = ARM_R_BASE_POS.y + amount * 4.0
	if foot_l:
		foot_l.position.y = -amount * 0.5
	if foot_r:
		foot_r.position.y = -amount * 0.5
	if sole_l:
		sole_l.position.y = -amount * 0.5
	if sole_r:
		sole_r.position.y = -amount * 0.5
	if leg_l:
		leg_l.position.y = -amount * 0.3
	if leg_r:
		leg_r.position.y = -amount * 0.3


## 3/4 walk/run: the near (R) limb performs the readable stride; the far (L)
## limb follows behind at reduced amplitude — genuine 3/4 locomotion, not a
## side-view walk reused with different art.
func _process_walk(
	delta: float, cadence: float, foot_lift: float, arm_swing: float, sway_x: float, bounce_y: float
) -> void:
	_walk_time += delta * cadence * (0.6 + _speed_factor * 0.4)

	var cycle := sin(_walk_time)
	var abs_cycle := absf(cycle)

	# --- near leg / far leg distinction ---
	# Near leg: big readable stride (lift + screen-x swing = step through space)
	var r_lift := -maxf(0.0, sin(_walk_time)) * foot_lift
	var r_swing_x := sin(_walk_time) * foot_lift * 0.32
	# Far leg: same rhythm but compressed (reads behind the near leg)
	var l_lift := -maxf(0.0, sin(_walk_time + PI)) * foot_lift * 0.72
	var l_swing_x := sin(_walk_time + PI) * foot_lift * 0.2

	if foot_r:
		foot_r.position.y = r_lift
		foot_r.position.x = r_swing_x
	if sole_r:
		sole_r.position.y = r_lift
		sole_r.position.x = r_swing_x
	if leg_r:
		leg_r.position.y = r_lift * 0.6
		leg_r.position.x = r_swing_x * 0.6
	if foot_l:
		foot_l.position.y = l_lift
		foot_l.position.x = l_swing_x
	if sole_l:
		sole_l.position.y = l_lift
		sole_l.position.x = l_swing_x
	if leg_l:
		leg_l.position.y = l_lift * 0.6
		leg_l.position.x = l_swing_x * 0.6

	# --- torso: bounce + lateral sway + depth lean (3/4 body lean) ---
	if torso:
		torso.position.y = TORSO_BASE_POS.y + abs_cycle * bounce_y
		torso.position.x = TORSO_BASE_POS.x + sin(_walk_time * 0.5) * sway_x
		torso.rotation = _depth_lean * 0.08 + sin(_walk_time) * 0.02
	# hip line follows the weight shift
	if shorts_l:
		shorts_l.position.x = sin(_walk_time * 0.5) * sway_x * 0.5
	if shorts_r:
		shorts_r.position.x = sin(_walk_time * 0.5) * sway_x * 0.5

	# --- head stability with counter-bounce ---
	if head:
		head.position.y = HEAD_BASE_POS.y + abs_cycle * (bounce_y * 1.15)
		head.position.x = HEAD_BASE_POS.x + sin(_walk_time * 0.5) * (sway_x * 0.8)
	_apply_gaze()

	# --- arm swing in opposition (near arm strong, far arm subtle) ---
	if arm_l:
		arm_l.rotation = -cycle * arm_swing * 0.55
		arm_l.position.y = ARM_L_BASE_POS.y + abs_cycle * 0.8
	if arm_r and not _is_attacking:
		arm_r.rotation = cycle * arm_swing
		arm_r.position.y = ARM_R_BASE_POS.y + abs_cycle * 1.4


func _process_stop() -> void:
	# Foot braking + body settling — never a snap into idle
	var t := _state_time
	if t < 0.3:
		_apply_crouch(remap(t, 0.0, 0.3, 0.0, 0.8) * (0.5 + _speed_factor * 0.5))
		# braking: near foot plants forward
		if foot_r:
			foot_r.position.x = remap(t, 0.0, 0.3, 0.0, 4.0)
		if leg_r:
			leg_r.position.x = remap(t, 0.0, 0.3, 0.0, 2.5)
	elif t < 0.55:
		_apply_crouch(remap(t, 0.3, 0.55, 0.8, 0.15))
		if foot_r:
			foot_r.position.x = remap(t, 0.3, 0.55, 4.0, 0.0)
		if leg_r:
			leg_r.position.x = remap(t, 0.3, 0.55, 2.5, 0.0)
	elif t < 0.75:
		# follow-through: torso settles back with elastic ease
		var s := remap(t, 0.55, 0.75, 0.15, 0.0)
		_apply_crouch(s)
		if torso:
			torso.rotation = -0.03 * sin(s * PI)
	else:
		change_state(State.IDLE)
	_apply_gaze()


# --- Jump (Parts 18/19/20/21) -------------------------------------------------


func trigger_jump() -> void:
	_ensure_node_refs()
	if _is_jumping:
		return
	_is_jumping = true
	_locomotion_state = (
		current_state if current_state in [State.WALK, State.RUN] else _locomotion_state
	)
	change_state(State.JUMP)

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# 1. ANTICIPATION — body compression (knees/hips/torso, arm preparation)
	_action_tween.tween_method(_jump_compress, 0.0, 1.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

	# 2. LAUNCH — stretch upward, near arm throws up
	_action_tween.tween_callback(_on_jump_launch)
	_action_tween.tween_method(_jump_stretch, 0.0, 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

	# 3. AIRBORNE hang — legs tuck, arms settle
	_action_tween.tween_method(_jump_airborne, 0.0, 1.0, 0.30)

	# 4. LAND — contact compression (heavy, fast)
	_action_tween.tween_method(_jump_land, 0.0, 1.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)

	# 5. RECOIL + SETTLE — elastic back to stance
	(
		_action_tween
		. tween_method(_jump_recoil, 1.0, 0.0, 0.22)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)
	_action_tween.tween_callback(_on_jump_finished)


func _jump_compress(a: float) -> void:
	_apply_crouch(a)
	if arm_l:
		arm_l.rotation = -a * 0.35
	if arm_r:
		arm_r.rotation = a * 0.35  # near arm sweeps back to prepare


func _on_jump_launch() -> void:
	_play_sfx("JUMP")


func _jump_stretch(a: float) -> void:
	if torso:
		torso.position.y = TORSO_BASE_POS.y - a * 5.0
	if head:
		head.position.y = HEAD_BASE_POS.y - a * 7.0
	if arm_l:
		arm_l.position.y = ARM_L_BASE_POS.y - a * 10.0
		arm_l.rotation = a * 0.15
	if arm_r:
		arm_r.position.y = ARM_R_BASE_POS.y - a * 12.0
		arm_r.rotation = -a * 0.3


func _jump_airborne(a: float) -> void:
	# legs tuck under (near leg tucks more), arms settle, readable silhouette
	var tuck := sin(a * PI)  # 0 -> 1 -> 0 over the hang
	if foot_r:
		foot_r.position.y = -4.0 * tuck
		foot_r.position.x = -2.0 * tuck
	if sole_r:
		sole_r.position.y = -4.0 * tuck
	if leg_r:
		leg_r.position.y = -3.0 * tuck
	if foot_l:
		foot_l.position.y = -2.0 * tuck
		foot_l.position.x = -1.0 * tuck
	if sole_l:
		sole_l.position.y = -2.0 * tuck
	if leg_l:
		leg_l.position.y = -1.5 * tuck
	if torso:
		torso.position.y = TORSO_BASE_POS.y - 2.0 * tuck
	if head:
		head.position.y = HEAD_BASE_POS.y - 3.0 * tuck


func _jump_land(a: float) -> void:
	# CONTACT -> COMPRESSION: deep crouch
	_apply_crouch(a * 1.25)
	if torso:
		torso.rotation = a * 0.06


func _jump_recoil(a: float) -> void:
	# COMPRESSION -> RECOIL -> SETTLE (a runs 1 -> 0, elastic)
	_apply_crouch(a * 1.25)
	if torso:
		torso.rotation = a * 0.06


func _on_jump_finished() -> void:
	_is_jumping = false
	_play_sfx("LAND")
	landed.emit()
	change_state(State.IDLE)
	# Secondary motion: dazed blink after a heavy landing
	set_face_expression("neutral", "open")
	blink_now()


# --- Attack (Parts 24/25/26/27/28) --------------------------------------------


## Genuine 3/4 attack: anticipation across the body, aim hold, RELEASE through
## the near arm, follow-through and recovery. The projectile direction is
## strictly derived from the facing yaw (see _on_attack_release_point).
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

	var prev_state := _locomotion_state

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# 1. ANTICIPATION — near arm pulls across the body, torso coils
	(
		_action_tween
		. tween_property(arm_r, "position", ARM_R_BASE_POS + Vector2(-9.0, -6.0), 0.09)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	_action_tween.parallel().tween_property(arm_r, "rotation", -0.6, 0.09)
	if torso:
		_action_tween.parallel().tween_property(torso, "rotation", -0.08, 0.09)

	# 2. PREPARE / AIM — brief readable hold, head turns toward the aim
	_action_tween.tween_interval(0.05)
	if head:
		_action_tween.parallel().tween_property(head, "rotation", _sign(facing_yaw) * 0.06, 0.05)

	# 3. RELEASE — near arm swings through, torso uncoils
	_action_tween.tween_callback(_on_attack_release_point)
	(
		_action_tween
		. tween_property(arm_r, "position", ARM_R_BASE_POS + Vector2(13.0, 2.0), 0.08)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	_action_tween.parallel().tween_property(arm_r, "rotation", 0.85, 0.08)
	if torso:
		_action_tween.parallel().tween_property(torso, "rotation", 0.1, 0.08)

	# 4. FOLLOW-THROUGH / RECOVERY — elastic settle to base
	(
		_action_tween
		. tween_property(arm_r, "position", ARM_R_BASE_POS, 0.18)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
	_action_tween.parallel().tween_property(arm_r, "rotation", 0.0, 0.18)
	if torso:
		_action_tween.parallel().tween_property(torso, "rotation", 0.0, 0.18)
	if head:
		_action_tween.parallel().tween_property(head, "rotation", 0.0, 0.18)

	_action_tween.tween_callback(
		func():
			_is_attacking = false
			# End of chain: reload SFX
			_play_sfx("RELOAD")
			change_state(prev_state)
	)


func _sign(x: float) -> float:
	return -1.0 if x < 0.0 else 1.0


func _on_attack_release_point() -> void:
	# CRITICAL: the projectile direction is strictly derived from the facing
	# yaw (ground orientation) — the same spatial contract as the front view:
	#   yaw = 0   => dir = (0, -1) straight toward the camera (-z)
	#   yaw = +t  => dir = (sin t, -cos t)
	#   yaw = -t  => dir = (-sin t, -cos t)
	var dir_2_5d := Vector2(sin(facing_yaw), -cos(facing_yaw)).normalized()

	# Socket offset in world units: the near-hand anchor follows the facing yaw
	# AND the artwork's presentation mirror, so the projectile NEVER spawns
	# from an arbitrary screen anchor.
	var spawn_offset := Vector2(mirror_sign * 8.0 + sin(facing_yaw) * 14.0, -cos(facing_yaw) * 12.0)

	_play_sfx("ATTACK_RELEASE")
	attack_released.emit(dir_2_5d, spawn_offset)


func is_attacking() -> bool:
	return _is_attacking


## Attack socket in this view's local space (feet origin), mirroring-aware:
## the driver flips the artwork for the other horizontal direction via
## set_mirror_sign, so the socket flips WITH the art and never drifts.
func attack_socket_local() -> Vector2:
	return Vector2(ATTACK_SOCKET_LOCAL.x * mirror_sign, ATTACK_SOCKET_LOCAL.y)


## Presentation flip of the artwork for the other horizontal turn direction.
## This is a presentation mirror ONLY — spatial facing (facing_yaw) is owned
## by aim/movement logic, never by the flip.
var mirror_sign: float = 1.0


func set_mirror_sign(sign: float) -> void:
	mirror_sign = sign
	facing_yaw = deg_to_rad(35.0 * sign)


func is_jumping() -> bool:
	return _is_jumping


# --- Hit / knockback / recovery (Parts 22/23) ---------------------------------


func trigger_hit(knock_dir: Vector2 = Vector2.ZERO) -> void:
	_ensure_node_refs()
	if _is_hit:
		return
	_is_hit = true
	_locomotion_state = (
		current_state if current_state in [State.WALK, State.RUN] else _locomotion_state
	)
	change_state(State.HIT)
	set_face_expression("hurt", "blink")
	_play_sfx("CHARACTER_HIT")

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# Recoil flinch — readable from the angled view: head snap + torso coil
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y - 9.0, 0.08)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
		_action_tween.parallel().tween_property(torso, "rotation", -0.14, 0.08)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y - 12.0, 0.08)
		_action_tween.parallel().tween_property(head, "rotation", -0.16, 0.08)
	# limb response: near arm flails back
	if arm_r:
		_action_tween.parallel().tween_property(
			arm_r, "position", ARM_R_BASE_POS + Vector2(-6.0, -10.0), 0.08
		)
		_action_tween.parallel().tween_property(arm_r, "rotation", -0.5, 0.08)
	if arm_l:
		_action_tween.parallel().tween_property(
			arm_l, "position", ARM_L_BASE_POS + Vector2(-4.0, -6.0), 0.08
		)
		_action_tween.parallel().tween_property(arm_l, "rotation", -0.35, 0.08)

	# follow-through recovery
	if torso:
		(
			_action_tween
			. tween_property(torso, "position:y", TORSO_BASE_POS.y, 0.22)
			. set_trans(Tween.TRANS_BOUNCE)
			. set_ease(Tween.EASE_OUT)
		)
		_action_tween.parallel().tween_property(torso, "rotation", 0.0, 0.22)
	if head:
		_action_tween.parallel().tween_property(head, "position:y", HEAD_BASE_POS.y, 0.22)
		_action_tween.parallel().tween_property(head, "rotation", 0.0, 0.22)

	_action_tween.tween_callback(
		func():
			_is_hit = false
			if knock_dir != Vector2.ZERO:
				trigger_knockback(knock_dir)
			else:
				set_face_expression("neutral", "open")
				change_state(_locomotion_state)
	)


## Knockback moves the ART pose only; actual spatial displacement stays with
## the lab driver's world physics, so animation and movement never conflict.
func trigger_knockback(dir_vector: Vector2 = Vector2.RIGHT) -> void:
	change_state(State.KNOCKBACK)
	knockback_started.emit(dir_vector)
	set_face_expression("hurt", "blink")

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# Launch: thrown along the knock direction (art-local offset)
	var kick := Vector2(clampf(dir_vector.x, -1.0, 1.0) * 16.0, -6.0)
	if torso:
		(
			_action_tween
			. tween_property(torso, "position", TORSO_BASE_POS + kick * 0.6, 0.1)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
		_action_tween.parallel().tween_property(torso, "rotation", 0.18, 0.1)
	if head:
		_action_tween.parallel().tween_property(head, "position", HEAD_BASE_POS + kick * 0.8, 0.1)
		_action_tween.parallel().tween_property(head, "rotation", 0.22, 0.1)
	if foot_r:
		foot_r.position.x = kick.x * 0.4
	if foot_l:
		foot_l.position.x = -kick.x * 0.3

	# Tumble settle: elastic back to a braced stance
	if torso:
		(
			_action_tween
			. tween_property(torso, "position", TORSO_BASE_POS, 0.35)
			. set_trans(Tween.TRANS_ELASTIC)
			. set_ease(Tween.EASE_OUT)
		)
		_action_tween.parallel().tween_property(torso, "rotation", 0.0, 0.35)
	if head:
		_action_tween.parallel().tween_property(head, "position", HEAD_BASE_POS, 0.35)
		_action_tween.parallel().tween_property(head, "rotation", 0.0, 0.35)
	_action_tween.tween_callback(_enter_recovery)


func _enter_recovery() -> void:
	change_state(State.RECOVERY)
	# braced settle: deep crouch unwinding
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_action_tween.tween_method(_apply_crouch, 0.8, 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_OUT
	)
	_action_tween.tween_callback(
		func():
			set_face_expression("neutral", "open")
			change_state(_locomotion_state)
	)


func trigger_recovery() -> void:
	_enter_recovery()


# --- Super (Parts 33/34/35) ---------------------------------------------------


func trigger_super() -> void:
	_ensure_node_refs()
	if _is_super:
		return
	_is_super = true
	_locomotion_state = (
		current_state if current_state in [State.WALK, State.RUN] else _locomotion_state
	)
	change_state(State.SUPER)
	super_started.emit()
	_play_sfx("SUPER_START")

	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	_action_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

	# 1. ANTICIPATION / ACTIVATION — crouch + arms tuck in (3/4 silhouette)
	_action_tween.tween_method(_super_windup, 0.0, 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	_action_tween.tween_callback(func(): _spawn_smoke_vfx())

	# 2. DISAPPEARANCE — fade to stealth (alpha 0.22)
	(
		_action_tween
		. tween_property(self, "modulate:a", 0.22, 0.25)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)

	# 3. STEALTH hold — subtle shimmer while invisible
	_action_tween.tween_method(_super_shimmer, 0.0, 1.0, 1.5)

	# 4. REAPPEARANCE — smoke puff + fade back
	_action_tween.tween_callback(func(): _spawn_smoke_vfx())
	(
		_action_tween
		. tween_property(self, "modulate:a", 1.0, 0.35)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	_action_tween.tween_callback(_super_restore)

	# 5. RECOVERY — windup unwinds elastically
	(
		_action_tween
		. tween_method(_super_windup, 1.0, 0.0, 0.25)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)
	_action_tween.tween_callback(_on_super_finished)


func _super_windup(a: float) -> void:
	_apply_crouch(a * 0.9)
	if arm_l:
		arm_l.rotation = a * 0.3
	if arm_r:
		arm_r.rotation = -a * 0.3


func _super_shimmer(a: float) -> void:
	modulate.a = 0.22 + sin(a * PI * 6.0) * 0.04


func _super_restore() -> void:
	modulate.a = 1.0
	_play_sfx("SUPER_END")


func _on_super_finished() -> void:
	_is_super = false
	super_ended.emit()
	change_state(_locomotion_state)


func is_in_super() -> bool:
	return _is_super


# --- SFX + VFX (real Leon chain) ----------------------------------------------


func _play_sfx(event_name: String) -> void:
	var tree := get_tree()
	if tree and tree.root.has_node("AudioManager"):
		tree.root.get_node("AudioManager").trigger_event(event_name, {"character": "leon"})


## Cyan smoke puff (the same Super treatment the front view uses), anchored to
## the 3/4 body centre so it inherits the actor's projection scale/depth.
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
		tw.parallel().tween_property(puff, "modulate:a", 0.0, 0.45)

	get_tree().create_timer(0.55).timeout.connect(smoke.queue_free)
