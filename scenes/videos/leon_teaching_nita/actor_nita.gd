class_name TeachingActorNita
extends Node2D

# Cinematic Actor for Nita Littlefoot in "Leon Tries to Teach Nita How to Fight"
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
			if torso: torso.position.y = -68.0 + breath * 0.4
			if head: head.position.y = -114.0 + breath * 0.7

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
			if face.has_method("set_eye_state"):
				face.set_eye_state(eyes)
	if front_view:
		var face = front_view.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr)
			if face.has_method("set_eye_state"):
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

func eager_hop() -> void:
	# Eager student bouncing asking to be taught
	set_expression("grin", "wide")
	var orig_y = position.y
	var tw = create_tween()
	tw.tween_property(self, "position:y", orig_y - 20.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", orig_y, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", orig_y - 15.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", orig_y, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

func imitation_pose() -> void:
	# Clumsily attempting to copy Leon's windup posture
	set_expression("grin", "wide")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.65, 0.3)
		if arm_l: tw.tween_property(arm_l, "rotation", -0.4, 0.3)
		if torso: tw.tween_property(torso, "rotation", -0.15, 0.3)
		# Look sideways at Leon to see if posture looks right
		if head: tw.tween_property(head, "rotation", 0.20, 0.3)

func clumsy_fumble_attack() -> void:
	# Over-enthusiastic swing, losing balance forward in facing direction and firing wild
	set_expression("shocked", "wide")
	var orig_pos = position
	var dir = float(facing_direction)
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", orig_pos.x + dir * 20.0, 0.18)
	tw.parallel().tween_property(self, "scale", Vector2(1.15, 0.85), 0.18)
	trigger_attack()
	await attack_finished
	# Stumble settle
	var tw_settle = create_tween()
	tw_settle.tween_property(self, "position:x", orig_pos.x + dir * 10.0, 0.25)
	tw_settle.parallel().tween_property(self, "scale", Vector2.ONE, 0.25)
	await tw_settle.finished

func embarrassed_shrink() -> void:
	# Head droops, shoulders slump in shame ("I didn't get it...")
	set_expression("hurt", "blink")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if head: tw.tween_property(head, "rotation", 0.38, 0.35)
		if torso: tw.tween_property(torso, "rotation", 0.15, 0.35)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.1, 0.35)
	var tw_scale = create_tween()
	tw_scale.tween_property(self, "scale", Vector2(0.92, 0.88), 0.35).set_ease(Tween.EASE_OUT)

func learning_stance() -> void:
	# Plants feet firmly, straightens spine, aligns arm directly to dummy
	reset_pose()
	set_expression("grin", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_r_low = side_view.find_child("arm_R_lower", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", 0.05, 0.3)
		if head: tw.tween_property(head, "rotation", 0.0, 0.3)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.65, 0.3)
		if arm_r_low: tw.tween_property(arm_r_low, "rotation", 0.0, 0.3)

func proud_hop() -> void:
	# Bouncy joyful hops when Leon praises her
	reset_pose()
	set_expression("happy", "happy")
	var orig_y = position.y
	var tw = create_tween()
	tw.tween_property(self, "position:y", orig_y - 32.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", orig_y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", orig_y - 24.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", orig_y, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

func overconfident_swagger() -> void:
	# Puffed chest, head held high, cocky grin ("Did you see that?! Watch THIS!")
	reset_pose()
	set_expression("smug", "wide")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var torso = side_view.find_child("torso", true, false)
		var head = side_view.find_child("head", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", -0.22, 0.3)
		if head: tw.tween_property(head, "rotation", -0.18, 0.3)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.45, 0.3)
	var tw_bob = create_tween().set_trans(Tween.TRANS_SINE).set_loops(2)
	tw_bob.tween_property(self, "position:y", position.y - 6.0, 0.15)
	tw_bob.tween_property(self, "position:y", position.y, 0.15)

func innocent_pose() -> void:
	# Wide innocent round-eyed look with head tilt expecting applause
	set_expression("grin", "open")
	if front_view:
		set_view(ViewMode.FRONT)
		var head = front_view.get_node_or_null("Head")
		if head:
			var tw = create_tween()
			tw.tween_property(head, "rotation", -0.15, 0.3)
