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

func reset_pose() -> void:
	scale = Vector2.ONE
	if side_view:
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_r_low = side_view.find_child("arm_R_lower", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		if head: head.rotation = 0.0
		if torso: torso.rotation = 0.0
		if arm_r: arm_r.rotation = 0.0
		if arm_r_low: arm_r_low.rotation = 0.0
		if arm_l: arm_l.rotation = 0.0
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim and not anim.is_playing():
			anim.play("idle")

func trigger_attack() -> void:
	reset_pose()
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

# --- ACTING BEATS ---

func demonstration_stance() -> void:
	# Confident "Watch me, I know what I'm doing" teacher pose
	set_expression("smug", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var head = side_view.find_child("head", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", 0.12, 0.3)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.45, 0.3)
		if head: tw.tween_property(head, "rotation", -0.08, 0.3)

func point_gesture(hold_time: float = 1.0) -> void:
	# Firmly outstretched arm pointing at target dummy
	set_expression("smug", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_r_low = side_view.find_child("arm_R_lower", true, false)
		var torso = side_view.find_child("torso", true, false)
		var head = side_view.find_child("head", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.75, 0.25)
		if arm_r_low: tw.tween_property(arm_r_low, "rotation", -0.1, 0.25)
		if torso: tw.tween_property(torso, "rotation", 0.05, 0.25)
		if head: tw.tween_property(head, "rotation", 0.0, 0.25)

func turn_head_to_student(to_student: bool = true) -> void:
	# Turns head toward student while body stays oriented
	if side_view:
		var head = side_view.find_child("head", true, false)
		if head:
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var target_rot = 0.25 if to_student else -0.05
			tw.tween_property(head, "rotation", target_rot, 0.25)

func trigger_panic_jump() -> void:
	# High emergency jump dodging Nita's wild attack near his feet
	set_expression("shocked", "wide")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		if arm_r: arm_r.rotation = -1.5
		if arm_l: arm_l.rotation = -1.5

	var orig_y = position.y
	var jump_apex = orig_y - 130.0

	var tw = create_tween()
	tw.tween_property(self, "position:y", jump_apex, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2(0.85, 1.25), 0.15)
	tw.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.26)
	tw.tween_property(self, "position:y", orig_y, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2(1.25, 0.75), 0.08)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
	await tw.finished
	reset_pose()

func disbelief_react() -> void:
	# Deadpan "Seriously?!" reaction: head cocked, eyes half-lidded, arms dropped limp
	set_expression("confused", "blink")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if head: tw.tween_property(head, "rotation", 0.35, 0.3)
		if torso: tw.tween_property(torso, "rotation", -0.10, 0.3)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.2, 0.3)
	await get_tree().create_timer(0.4).timeout
	set_expression("confused", "open")

func coaching_demonstration() -> void:
	# Step into solid grounded stance, point firmly, nod to reinforce
	set_expression("neutral", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_r_low = side_view.find_child("arm_R_lower", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.7, 0.3)
		if arm_r_low: tw.tween_property(arm_r_low, "rotation", 0.0, 0.3)
		if torso: tw.tween_property(torso, "rotation", 0.05, 0.3)
		if head: tw.tween_property(head, "rotation", 0.0, 0.3)
		var tw_nod = create_tween().set_trans(Tween.TRANS_SINE)
		tw_nod.tween_interval(0.35)
		tw_nod.tween_property(head, "rotation", 0.2, 0.15)
		tw_nod.tween_property(head, "rotation", -0.05, 0.15)
		tw_nod.tween_property(head, "rotation", 0.2, 0.15)
		tw_nod.tween_property(head, "rotation", 0.0, 0.15)

func proud_approval() -> void:
	# Surprise -> genuine proud smile & approving nod
	set_expression("shocked", "wide")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw_surprise = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw_surprise.tween_property(torso, "rotation", -0.15, 0.2)
		if head: tw_surprise.tween_property(head, "rotation", -0.1, 0.2)
		if arm_r: tw_surprise.tween_property(arm_r, "rotation", -0.4, 0.2)

	await get_tree().create_timer(0.45).timeout

	set_expression("happy", "open")
	if side_view:
		var head = side_view.find_child("head", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw_proud = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if arm_r: tw_proud.tween_property(arm_r, "rotation", -0.85, 0.3)
		var tw_nod = create_tween().set_trans(Tween.TRANS_SINE)
		tw_nod.tween_property(head, "rotation", 0.25, 0.14)
		tw_nod.tween_property(head, "rotation", -0.05, 0.14)
		tw_nod.tween_property(head, "rotation", 0.25, 0.14)
		tw_nod.tween_property(head, "rotation", 0.0, 0.14)

func warning_gesture() -> void:
	# Alarm: hands up, leaning back ("Wait, no, STOP!")
	set_expression("shocked", "wide")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", -0.35, 0.25)
		if head: tw.tween_property(head, "rotation", -0.2, 0.25)
		if arm_r: tw.tween_property(arm_r, "rotation", -1.2, 0.25)
		if arm_l: tw.tween_property(arm_l, "rotation", -1.0, 0.25)

func cower_gesture() -> void:
	# Shielding head/face as flying wood planks and debris erupt
	set_expression("scared", "closed")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var torso = side_view.find_child("torso", true, false)
		var head = side_view.find_child("head", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", 0.45, 0.2)
		if head: tw.tween_property(head, "rotation", 0.35, 0.2)
		if arm_r: tw.tween_property(arm_r, "rotation", -1.7, 0.2)
		if arm_l: tw.tween_property(arm_l, "rotation", -1.6, 0.2)

func facepalm_gesture() -> void:
	# Complete exhausted regret: slow turn, slump, hand pressed firmly against face
	set_expression("sad", "closed")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_r_low = side_view.find_child("arm_R_lower", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if head: tw.tween_property(head, "rotation", 0.45, 0.45)
		if torso: tw.tween_property(torso, "rotation", 0.25, 0.45)
		if arm_r: tw.tween_property(arm_r, "rotation", -1.85, 0.45)
		if arm_r_low: tw.tween_property(arm_r_low, "rotation", -1.4, 0.45)
	if front_view:
		var arm_r = front_view.get_node_or_null("ArmR")
		var head = front_view.get_node_or_null("Head")
		if arm_r:
			var tw = create_tween().set_parallel(true)
			tw.tween_property(arm_r, "position", Vector2(10, -95), 0.35)
			tw.tween_property(arm_r, "rotation", -1.4, 0.35)
			if head: tw.tween_property(head, "rotation", 0.15, 0.35)
