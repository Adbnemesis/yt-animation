class_name ActorLeon
extends Node2D

# Composite Actor for Video Production: Leon
# Manages Side View (full skeleton rig), Front View (closeups/facing camera),
# and Back View (facing into elevator/pressing panel).

enum ViewMode { SIDE, FRONT, BACK }

signal walk_finished()

@onready var side_view: CharacterController = get_node_or_null("SideView")
@onready var front_view: Node2D = get_node_or_null("FrontView")
@onready var back_view: Node2D = get_node_or_null("BackView")

var current_view: ViewMode = ViewMode.SIDE
var is_walking: bool = false
var target_x: float = 0.0
var walk_speed: float = 180.0
var facing_direction: int = 1

func _ready() -> void:
	if side_view:
		side_view.set_physics_process(false)
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("idle")
	set_view(ViewMode.SIDE)

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
	current_view = mode
	if side_view:
		side_view.visible = (mode == ViewMode.SIDE)
	if front_view:
		front_view.visible = (mode == ViewMode.FRONT)
	if back_view:
		back_view.visible = (mode == ViewMode.BACK)

func set_facing(dir: int) -> void:
	facing_direction = 1 if dir >= 0 else -1
	if side_view:
		side_view.facing_direction = facing_direction
		# Flip side_view Visuals horizontally
		var visuals = side_view.get_node_or_null("Visuals")
		if visuals:
			visuals.scale.x = float(facing_direction)

func walk_to(dest_x: float, speed: float = 160.0) -> void:
	set_view(ViewMode.SIDE)
	target_x = dest_x
	walk_speed = speed
	var dir = 1 if dest_x > position.x else -1
	set_facing(dir)
	is_walking = true
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("walk")
			anim.speed_scale = walk_speed / 160.0

func set_expression(expr: String, eyes: String = "open") -> void:
	# Update side view face if present
	if side_view:
		var face = side_view.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr)
			face.set_eye_state(eyes)

	# Update front view face
	if front_view:
		var face = front_view.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr)
			face.set_eye_state(eyes)

func press_button_animation() -> void:
	match current_view:
		ViewMode.BACK:
			if back_view:
				var arm = back_view.get_node_or_null("ArmR")
				if arm:
					var tw = create_tween()
					tw.tween_property(arm, "rotation", -0.9, 0.12)
					tw.tween_property(arm, "rotation", 0.0, 0.12)
		ViewMode.FRONT:
			if front_view:
				var arm = front_view.get_node_or_null("ArmR")
				if arm:
					var tw = create_tween()
					tw.tween_property(arm, "rotation", -0.75, 0.12)
					tw.tween_property(arm, "rotation", 0.0, 0.12)
		ViewMode.SIDE:
			if side_view:
				var arm = side_view.find_child("arm_R_upper", true, false)
				if arm:
					var tw = create_tween()
					tw.tween_property(arm, "rotation", -0.75, 0.12)
					tw.tween_property(arm, "rotation", 0.0, 0.12)
