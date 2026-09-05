class_name TeachingActorLeon
extends Node2D

# Cinematic Actor for Leon in "Leon Tries to Teach Nita How to Fight"
# Wraps full 2D skeleton rig (SideView) and closeup front view (FrontView)
# Exposes high-level deterministic narrative performance methods.

enum ViewMode { SIDE, FRONT }

signal walk_finished()
signal attack_finished()

@onready var side_view: CharacterBody2D = get_node_or_null("SideView")
@onready var front_view: Node2D = get_node_or_null("FrontView")

var current_view: ViewMode = ViewMode.SIDE
var is_walking: bool = false
var target_x: float = 0.0
var walk_speed: float = 160.0
var facing_direction: int = 1
var idle_breath_time: float = 0.0

func _ready() -> void:
	_ensure_nodes()
	if side_view:
		side_view.set_physics_process(false)
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("idle")
	set_view(ViewMode.SIDE)
	child_entered_tree.connect(_on_child_entered)

func _ensure_nodes() -> void:
	if not side_view:
		side_view = get_node_or_null("SideView")
	if not front_view:
		front_view = get_node_or_null("FrontView")

func _on_child_entered(node: Node) -> void:
	# Reparent spawned projectiles to world scene so they are independent of actor transform
	if node is Area2D and node.is_in_group("projectiles"):
		var world_scene = get_tree().current_scene
		if world_scene and world_scene != self:
			node.reparent.call_deferred(world_scene)

func _process(delta: float) -> void:
	if not is_walking:
		idle_breath_time += delta
		var breath: float = sin(idle_breath_time * 3.2) * 0.75
		if front_view and front_view.visible:
			var torso = front_view.get_node_or_null("Torso")
			var head = front_view.get_node_or_null("Head")
			if torso: torso.position.y = -61.0 + breath * 0.4
			if head: head.position.y = -110.0 + breath * 0.7

func _physics_process(delta: float) -> void:
	if is_walking:
		position.x = move_toward(position.x, target_x, walk_speed * delta)
		if side_view:
			side_view.position = Vector2.ZERO
			var anim = side_view.find_child("AnimPlayer", true, false)
			if anim and anim.current_animation != "walk":
				anim.play("walk")
				anim.speed_scale = walk_speed / 160.0

		if is_equal_approx(position.x, target_x):
			is_walking = false
			if side_view:
				var anim = side_view.find_child("AnimPlayer", true, false)
				if anim:
					anim.play("idle")
					anim.speed_scale = 1.0
			walk_finished.emit()

func set_view(mode: ViewMode) -> void:
	_ensure_nodes()
	current_view = mode
	if side_view:
		side_view.visible = (mode == ViewMode.SIDE)
	if front_view:
		front_view.visible = (mode == ViewMode.FRONT)

func set_facing(dir: int) -> void:
	facing_direction = 1 if dir >= 0 else -1
	if side_view:
		side_view.facing_direction = facing_direction
		var visuals = side_view.get_node_or_null("Visuals")
		if visuals:
			visuals.scale.x = float(facing_direction)
	if front_view:
		front_view.scale.x = float(facing_direction)

func walk_to(dest_x: float, speed: float = 160.0) -> void:
	set_view(ViewMode.SIDE)
	target_x = dest_x
	walk_speed = speed
	var dir = 1 if dest_x >= position.x else -1
	set_facing(dir)
	is_walking = true
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("walk")
			anim.speed_scale = walk_speed / 160.0

func set_expression(expr: String, eyes: String = "open") -> void:
	_ensure_nodes()
	if side_view:
		var face = side_view.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr)
			face.set_eye_state(eyes)
	if front_view:
		var face = front_view.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr)
			face.set_eye_state(eyes)

func trigger_attack() -> void:
	set_view(ViewMode.SIDE)
	if not side_view:
		attack_finished.emit()
		return

	side_view.position = Vector2.ZERO
	side_view.set_physics_process(true)
	side_view.trigger_attack()

	# Wait until attack completes
	if not side_view.attack_ended.is_connected(_on_side_view_attack_ended):
		side_view.attack_ended.connect(_on_side_view_attack_ended, CONNECT_ONE_SHOT)

func _on_side_view_attack_ended() -> void:
	if side_view:
		side_view.set_physics_process(false)
		side_view.position = Vector2.ZERO
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("idle")
	attack_finished.emit()

func trigger_panic_jump() -> void:
	# High emergency jump dodging Nita's wild attack
	set_expression("shocked", "wide")
	var orig_y = position.y
	var jump_apex = orig_y - 125.0

	var tw = create_tween()
	# Launch up with squash & stretch
	tw.tween_property(self, "position:y", jump_apex, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2(0.85, 1.2), 0.15)
	tw.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.28)
	# Fall down
	tw.tween_property(self, "position:y", orig_y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Land squash
	tw.tween_property(self, "scale", Vector2(1.25, 0.75), 0.08)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
	await tw.finished

func point_gesture() -> void:
	set_view(ViewMode.SIDE)
	if side_view:
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		if arm_r:
			var tw = create_tween()
			tw.tween_property(arm_r, "rotation", -0.65, 0.2).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.8)
			tw.tween_property(arm_r, "rotation", 0.0, 0.25).set_ease(Tween.EASE_IN)

func facepalm_gesture() -> void:
	# Exhausted sibling disbelief pose
	set_expression("sad", "closed")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_r_low = side_view.find_child("arm_R_lower", true, false)
		var tw = create_tween().set_parallel(true)
		if head: tw.tween_property(head, "rotation", 0.45, 0.4)
		if torso: tw.tween_property(torso, "rotation", 0.20, 0.4)
		if arm_r: tw.tween_property(arm_r, "rotation", -1.8, 0.4)
		if arm_r_low: tw.tween_property(arm_r_low, "rotation", -1.4, 0.4)
	if front_view:
		var arm_r = front_view.get_node_or_null("ArmR")
		var head = front_view.get_node_or_null("Head")
		if arm_r:
			var tw = create_tween().set_parallel(true)
			tw.tween_property(arm_r, "position", Vector2(10, -95), 0.35)
			tw.tween_property(arm_r, "rotation", -1.4, 0.35)
			if head: tw.tween_property(head, "rotation", 0.15, 0.35)
