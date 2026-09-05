class_name ActorNita
extends Node2D

# Composite Multi-View Actor for Video Production: Nita Littlefoot
# Manages Side View (full skeleton rig), Front View (closeups/facing camera),
# and Back View (cinematic reverse shots/facing into depth).

enum ViewMode { SIDE, FRONT, BACK }

signal walk_finished()

@onready var side_view: CharacterController = get_node_or_null("SideView")
@onready var front_view: Node2D = get_node_or_null("FrontView")
@onready var back_view: Node2D = get_node_or_null("BackView")

var current_view: ViewMode = ViewMode.SIDE
var is_walking: bool = false
var target_x: float = 0.0
var target_y: float = 0.0
var is_walking_y: bool = false
var walk_speed: float = 180.0
var facing_direction: int = 1

func _ensure_nodes() -> void:
	if not side_view: side_view = get_node_or_null("SideView")
	if not front_view: front_view = get_node_or_null("FrontView")
	if not back_view: back_view = get_node_or_null("BackView")

func _ready() -> void:
	_ensure_nodes()
	if side_view:
		side_view.set_physics_process(false)
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("idle")
	set_view(ViewMode.SIDE)
	set_in_cabin(false)

func set_in_cabin(in_cabin: bool) -> void:
	var target_z = 2 if in_cabin else 15
	z_index = target_z
	if side_view:
		side_view.z_as_relative = true
		side_view.z_index = 0
		var visuals = side_view.get_node_or_null("Visuals")
		if visuals:
			visuals.z_as_relative = true
			visuals.z_index = 0

var idle_breath_time: float = 0.0

func _process(delta: float) -> void:
	if not is_walking:
		idle_breath_time += delta
		var breath: float = sin(idle_breath_time * 3.2) * 0.75
		if front_view and front_view.visible:
			var torso = front_view.get_node_or_null("Torso")
			var head = front_view.get_node_or_null("Head")
			var arm_l = front_view.get_node_or_null("ArmL")
			var arm_r = front_view.get_node_or_null("ArmR")
			if torso:
				torso.position.y = -68.0 + breath * 0.4
			if head:
				head.position.y = -114.0 + breath * 0.7
			if arm_l:
				arm_l.position.y = -72.0 + breath * 0.3
			if arm_r and arm_r.rotation == 0.0:
				arm_r.position.y = -72.0 + breath * 0.3
		elif back_view and back_view.visible:
			var torso = back_view.get_node_or_null("Torso")
			var head = back_view.get_node_or_null("Head")
			var arm_l = back_view.get_node_or_null("ArmL")
			var arm_r = back_view.get_node_or_null("ArmR")
			if torso:
				torso.position.y = -68.0 + breath * 0.4
			if head:
				head.position.y = -114.0 + breath * 0.7
			if arm_l:
				arm_l.position.y = -72.0 + breath * 0.3
			if arm_r and arm_r.rotation == 0.0:
				arm_r.position.y = -72.0 + breath * 0.3

func _physics_process(delta: float) -> void:
	if is_walking:
		position.x = move_toward(position.x, target_x, walk_speed * delta)
		if is_walking_y:
			position.y = move_toward(position.y, target_y, (walk_speed * 0.6) * delta)
		if side_view:
			side_view.position = Vector2.ZERO
			var anim = side_view.find_child("AnimPlayer", true, false)
			if anim and anim.current_animation != "walk":
				anim.play("walk")
				anim.speed_scale = walk_speed / 160.0

		var reached_x = is_equal_approx(position.x, target_x)
		var reached_y = (not is_walking_y) or is_equal_approx(position.y, target_y)
		if reached_x and reached_y:
			is_walking = false
			is_walking_y = false
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
		if mode == ViewMode.SIDE:
			var visuals = side_view.get_node_or_null("Visuals")
			if visuals:
				visuals.z_as_relative = true
				visuals.z_index = 0
	if front_view:
		front_view.visible = (mode == ViewMode.FRONT)
	if back_view:
		back_view.visible = (mode == ViewMode.BACK)

func set_facing(dir: int) -> void:
	facing_direction = 1 if dir >= 0 else -1
	if side_view:
		side_view.facing_direction = facing_direction
		var visuals = side_view.get_node_or_null("Visuals")
		if visuals:
			visuals.scale.x = float(facing_direction)

func walk_to(dest_x: float, speed: float = 160.0, dest_y: float = -9999.0) -> void:
	set_view(ViewMode.SIDE)
	target_x = dest_x
	walk_speed = speed
	var dir = 1 if dest_x >= position.x else -1
	set_facing(dir)
	if dest_y > -9000.0:
		target_y = dest_y
		is_walking_y = true
	else:
		is_walking_y = false
	is_walking = true
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("walk")
			anim.speed_scale = walk_speed / 160.0

func set_expression(expr: String, eyes: String = "open") -> void:
	if front_view:
		var face = front_view.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr)
			face.set_eye_state(eyes)

func attack_animation() -> void:
	match current_view:
		ViewMode.SIDE:
			if side_view:
				var anim = side_view.find_child("AnimPlayer", true, false)
				if anim:
					anim.play("attack")
					await anim.animation_finished
					anim.play("idle")
		ViewMode.FRONT:
			if front_view:
				var arm = front_view.get_node_or_null("ArmR")
				if arm:
					var orig_pos = Vector2(28, -72)
					var tw = create_tween()
					tw.tween_property(arm, "position", Vector2(46, -66), 0.10)
					tw.parallel().tween_property(arm, "rotation", -0.70, 0.10)
					tw.tween_property(arm, "position", orig_pos, 0.14)
					tw.parallel().tween_property(arm, "rotation", 0.0, 0.14)
