extends Node2D
class_name CinematicActor

# ============================================================================
# CINEMATIC ACTOR (LAB) — a multiview character living on the ground plane
# ----------------------------------------------------------------------------
# Owns world position (x, z), elevation (jump) and facing (degrees). Every
# frame the camera projects the feet position; the multiview model inside
# picks its artwork from the camera-relative angle. Movement/physics are NOT
# duplicated per view: the side view's production rig supplies walk/idle/
# jump/attack animations; static views reuse the same world behaviour.
# ============================================================================

signal attack_released(socket_world: Vector2, facing_deg: float)
signal attack_finished

@export var display_name: String = "actor"

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, z) on the ground plane
var elevation: float = 0.0
var facing_deg: float = 0.0 # world yaw; 0 = toward +x

var _walk_target := Vector2.ZERO
var _walk_speed := 140.0
var _is_walking := false
var _jump_t := -1.0
var _attacking := false
var _face_target_deg: float = 0.0

@onready var model: MultiviewController = get_node_or_null("Model")
@onready var shadow: Polygon2D = get_node_or_null("Shadow")

func _ready() -> void:
	if model == null:
		for child in get_children():
			if child is MultiviewController:
				model = child
				break
	if model:
		for view_name in MultiviewController.VIEW_NODES.values():
			var view_node := model.get_node_or_null(NodePath(view_name))
			if view_node and view_node is CharacterBody2D:
				view_node.set_physics_process(false)

func setup(cam: CinematicCamera, pos: Vector2, facing: float) -> void:
	camera = cam
	world_pos = pos
	facing_deg = facing
	_face_target_deg = facing
	_apply_camera(true)

func _physics_process(delta: float) -> void:
	_step_walk(delta)
	_step_jump(delta)
	_apply_camera()

# --- Projection -------------------------------------------------------------

func _apply_camera(instant: bool = false) -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, elevation)
	position = p.pos
	scale = Vector2.ONE * maxf(p.scale, 0.01)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
	if model:
		var rel := camera.relative_view_angle(world_pos, facing_deg)
		if instant:
			var v := MultiviewController._bucket_to_view(rel)
			var m := MultiviewController._bucket_to_mirror(rel, v)
			model._apply(v, m, true)
		else:
			model.set_relative_angle(rel)
	if shadow:
		shadow.modulate.a = 0.42 if elevation <= 0.5 else 0.2

func current_view() -> StringName:
	return model.current_view if model else &"front"

# --- Movement (Part 13: left/right/forward/back/diagonal on the ground) -----

func walk_to(target: Vector2, speed: float = 140.0) -> void:
	_walk_target = target
	_walk_speed = speed
	_is_walking = true

func stop() -> void:
	_is_walking = false

func set_facing_deg(deg: float, instant: bool = false) -> void:
	_face_target_deg = deg
	if instant:
		facing_deg = deg
		_apply_camera(true)

func jump() -> void:
	if _jump_t < 0.0:
		_jump_t = 0.0

func _step_walk(delta: float) -> void:
	if not _is_walking:
		return
	var to_target := _walk_target - world_pos
	var dist := to_target.length()
	if dist < 2.0:
		_is_walking = false
		return
	var step := minf(_walk_speed * delta, dist)
	world_pos += to_target / dist * step
	# turn smoothly toward the motion direction
	var move_dir := to_target.angle()
	_face_target_deg = rad_to_deg(move_dir)
	facing_deg = lerp_angle(facing_deg, _face_target_deg, minf(1.0, delta * 6.0))

func _step_jump(delta: float) -> void:
	if _jump_t < 0.0:
		return
	_jump_t += delta
	if _jump_t < 0.7:
		elevation = 46.0 * sin((_jump_t / 0.7) * PI)
	else:
		elevation = 0.0
		_jump_t = -1.0

# --- Attack (Parts 26/27/43/44) ---------------------------------------------

## Fires the attack chain: the RELEASE event emits the socket's WORLD position
## so the projectile spawns from the weapon — never from an arbitrary anchor.
## The side rig contributes its attack ANIMATION; the projectile itself is
## always spawned by the lab at RELEASE from the view's socket (Part 27).
func attack() -> void:
	if _attacking:
		return
	_attacking = true
	var view_node := _active_view_node()
	var anim: AnimationPlayer = null
	if view_node:
		anim = view_node.find_child("AnimPlayer", true, false)
		if anim == null:
			for ap in view_node.find_children("*", "AnimationPlayer", true, false):
				anim = ap
				break
	if anim and anim.has_animation("attack"):
		anim.play("attack")
	elif anim and anim.has_animation("attack_basic"):
		anim.play("attack_basic")
	elif view_node:
		# readable aimed release for static artwork
		var tw := create_tween()
		tw.tween_property(view_node, "position", Vector2(4, 0), 0.08)
		tw.tween_property(view_node, "position", Vector2.ZERO, 0.12)
	get_tree().create_timer(0.2).timeout.connect(_emit_release)
	get_tree().create_timer(0.55).timeout.connect(_finish_attack)

func attack_socket_world() -> Vector2:
	if model == null:
		return world_pos
	var local := model.attack_socket_local()
	return model.to_global(local)

func _emit_release() -> void:
	attack_released.emit(attack_socket_world(), facing_deg)

func _finish_attack() -> void:
	if not _attacking:
		return
	_attacking = false
	var view_node := _active_view_node()
	if view_node and view_node is CharacterBody2D:
		view_node.set_physics_process(false)
		if "velocity" in view_node:
			view_node.velocity = Vector2.ZERO
	var anim: AnimationPlayer = null
	if view_node:
		anim = view_node.find_child("AnimPlayer", true, false)
	if anim and anim.has_animation("idle"):
		anim.play("idle")
	attack_finished.emit()

func _on_rig_attack_ended() -> void:
	_finish_attack()

func _on_rig_game_event(_ev: String, _data: Dictionary) -> void:
	# any attack-end style event closes the attack; RELEASE is driven by the
	# rig's own event below
	_finish_attack()

func _active_view_node() -> Node2D:
	return model.active_node() if model else null
