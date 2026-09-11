extends Node2D
class_name DepthActor25D

# Lab wrapper: gives an existing production brawler rig a world-space depth
# position. The wrapper projects (x, z, elevation) onto the 2D stage every
# frame and delegates ALL animation/attack behavior to the wrapped rig —
# the rig itself is never modified.
#
# Rig scenes are packed in as children:
#   - "Body"       (leon_side / brawler_bo)
#   - "BodySide"   (nita_side, animated)
#   - "BodyFront"  (nita_front, static pose rig)
#   - "BodyBack"   (nita_back, static pose rig)
#
# Origin convention: the rig node's origin sits at the character's ground
# contact (same convention as the production floor placement), so the
# projected position places the feet exactly on the projected ground line.

signal attack_finished()
signal walk_finished()

const ProjectionClass = preload("res://scripts/labs/projection_2_5d.gd")

const RIG_SIDE := 0
const RIG_FRONT := 1
const RIG_BACK := 2

@export var base_scale: float = 1.0

var world_x: float = 0.0
var world_z: float = 0.0
var elevation: float = 0.0
var facing: int = 1
var view_mode: int = ProjectionClass.ViewMode.SIDE

var active_rig: String = "Body"
var body: Node = null
var anim_player: AnimationPlayer = null
var attack_in_progress: bool = false

var is_walking: bool = false
var walk_target_x: float = 0.0
var walk_target_z: float = 0.0
var walk_speed: float = 150.0
var walk_anim: StringName = "walk"

var is_jumping: bool = false
var jump_timer: float = 0.0

@onready var shadow: Polygon2D = get_node_or_null("Shadow")
@onready var shadow_far: Polygon2D = get_node_or_null("ShadowFar")

func _ready() -> void:
	if has_node("BodySide"):
		_cache_rig("BodySide", true)
	else:
		_cache_rig("Body", true)
	apply_projection()
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _cache_rig(node_name: String, disable_physics: bool) -> void:
	for child_name in ["Body", "BodySide", "BodyFront", "BodyBack"]:
		if has_node(child_name):
			var child = get_node(child_name)
			if child_name == node_name:
				child.visible = true
			else:
				child.visible = false
			if child.has_method("set_physics_process"):
				child.set_physics_process(false)
			child.position = Vector2.ZERO
	active_rig = node_name
	body = get_node_or_null(node_name)
	anim_player = null
	if body:
		anim_player = body.find_child("AnimPlayer", true, false) as AnimationPlayer

# Internal: choose front/back/side rig (used by the Nita view test).
func set_rig(kind: int) -> void:
	var node_name := "BodySide"
	match kind:
		RIG_FRONT:
			node_name = "BodyFront"
		RIG_BACK:
			node_name = "BodyBack"
	if not has_node(node_name):
		return
	_cache_rig(node_name, false)
	apply_projection()
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func set_view_mode(mode: int) -> void:
	view_mode = mode
	apply_projection()

func get_depth_scale() -> float:
	return ProjectionClass.scale_at(world_z, view_mode, base_scale)

func apply_projection() -> void:
	var s := get_depth_scale()
	position = Vector2(world_x, ProjectionClass.screen_y_at(world_z, elevation, view_mode))
	scale = Vector2(s, s)
	if shadow:
		shadow.modulate.a = ProjectionClass.shadow_alpha(world_z, view_mode)
	if shadow_far:
		shadow_far.modulate.a = ProjectionClass.shadow_alpha(world_z, view_mode) * 0.5

func _physics_process(delta: float) -> void:
	if attack_in_progress and body:
		if body is CharacterBody2D:
			body.velocity = Vector2.ZERO
	if is_walking:
		_step_walk(delta)
	if is_jumping:
		_step_jump(delta)
	apply_projection()

func _step_walk(delta: float) -> void:
	var dx := walk_target_x - world_x
	var dz := walk_target_z - world_z
	var dist := sqrt(dx * dx + dz * dz)
	if dist < 2.0:
		world_x = walk_target_x
		world_z = walk_target_z
		is_walking = false
		if anim_player:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("idle"):
				anim_player.play("idle")
		walk_finished.emit()
		return
	var step := walk_speed * delta
	world_x += dx / dist * step
	world_z += dz / dist * step
	var dir := 1 if dx >= 0.0 else -1
	if facing != dir:
		set_facing(dir)
	if anim_player and anim_player.current_animation != walk_anim:
		anim_player.play(walk_anim)
		anim_player.speed_scale = clampf(walk_speed / 150.0, 0.6, 1.6)

func _step_jump(delta: float) -> void:
	jump_timer += delta
	if jump_timer < 0.12:
		elevation = 0.0
		if anim_player and anim_player.has_animation("jump_anticipation"):
			anim_player.play("jump_anticipation")
	elif jump_timer < 0.7:
		var t := (jump_timer - 0.12) / 0.58
		elevation = 46.0 * sin(t * PI)
		if anim_player and anim_player.has_animation("jump_airborne"):
			anim_player.play("jump_airborne")
	elif jump_timer < 0.9:
		elevation = 0.0
		if anim_player and anim_player.has_animation("jump_land"):
			anim_player.play("jump_land")
	else:
		is_jumping = false
		elevation = 0.0
		if anim_player and anim_player.has_animation("idle"):
			anim_player.play("idle")

# --- Movement Controls (world-space, projected automatically) ---

func walk_to_2d(dest_x: float, dest_z: float, speed: float = 150.0) -> void:
	walk_target_x = dest_x
	walk_target_z = dest_z
	walk_speed = speed
	is_walking = true

func jump() -> void:
	if is_jumping:
		return
	is_jumping = true
	jump_timer = 0.0

func set_facing(dir: int) -> void:
	facing = 1 if dir >= 0 else -1
	_apply_facing_to_body()

func _apply_facing_to_body() -> void:
	if not body:
		return
	var mc: Node = body.get_node_or_null("MovementController")
	if mc and "facing_direction" in mc:
		mc.facing_direction = facing
		return
	if "facing_direction" in body:
		body.facing_direction = facing
		return
	var visuals = body.get_node_or_null("Visuals")
	if visuals:
		visuals.scale.x = float(facing)

func set_expression(expr: String, eyes: String = "open") -> void:
	if not body:
		return
	if body.has_method("set_expression"):
		body.set_expression(expr)
		if body.has_method("set_eye_state"):
			body.set_eye_state(eyes)
	var face = body.find_child("Face", true, false)
	if face and face.has_method("set_expression"):
		face.set_expression(expr)
		if face.has_method("set_eye_state"):
			face.set_eye_state(eyes)

# --- Attack (uses the rig's own attack + real projectile) ---

func trigger_attack() -> void:
	if not body:
		attack_finished.emit()
		return
	attack_in_progress = true
	body.set_physics_process(true)
	if body.has_method("attack"):
		body.attack()
	elif body.has_method("trigger_attack"):
		body.trigger_attack()
	if body.has_signal("attack_ended") and not body.attack_ended.is_connected(_on_attack_ended):
		body.attack_ended.connect(_on_attack_ended, CONNECT_ONE_SHOT)
	if body.has_signal("game_event_emitted") and not body.game_event_emitted.is_connected(_on_game_event):
		body.game_event_emitted.connect(_on_game_event)

func _on_attack_ended() -> void:
	_finish_attack()

func _on_game_event(ev_name: String, _data: Dictionary) -> void:
	if ev_name == "ATTACK_END":
		_finish_attack()

func _finish_attack() -> void:
	if not attack_in_progress:
		return
	attack_in_progress = false
	if body:
		body.set_physics_process(false)
		body.position = Vector2.ZERO
		if body is CharacterBody2D:
			body.velocity = Vector2.ZERO
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")
	apply_projection()
	attack_finished.emit()