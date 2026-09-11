class_name FacilityActorLeon
extends Node2D

# Cinematic Actor for Leon in "The Thing They Shouldn't Have Opened"
# Wraps the production leon.tscn SideView rig.
# Exposes high-level deterministic narrative performance methods.

signal walk_finished()
signal attack_finished()

@onready var side_view: CharacterBody2D = get_node_or_null("SideView")

var is_walking: bool = false
var target_pos: Vector2 = Vector2.ZERO
var walk_speed: float = 160.0
var facing_direction: int = 1
var idle_breath_time: float = 0.0
var base_scale: float = 1.0

func _ready() -> void:
	_ensure_nodes()
	_update_depth_scale()
	if side_view:
		side_view.set_physics_process(false)
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("idle")
	child_entered_tree.connect(_on_child_entered)

func _ensure_nodes() -> void:
	if not side_view:
		side_view = get_node_or_null("SideView")

const SceneDepthClass = preload("res://scenes/videos/thing_they_opened/depth_model.gd")

func get_depth_scale() -> float:
	return SceneDepthClass.scale_at(position.y, base_scale)

func _update_depth_scale() -> void:
	var s = get_depth_scale()
	scale = Vector2(s, s)

func _on_child_entered(node: Node) -> void:
	if node is Area2D and node.is_in_group("projectiles"):
		var world_scene = get_tree().current_scene
		if world_scene and world_scene != self:
			node.reparent.call_deferred(world_scene)

func _physics_process(delta: float) -> void:
	if is_walking:
		position = position.move_toward(target_pos, walk_speed * delta)
		_update_depth_scale()
		if side_view:
			side_view.position = Vector2.ZERO
			var anim = side_view.find_child("AnimPlayer", true, false)
			if anim and anim.current_animation != "walk":
				anim.play("walk")
				anim.speed_scale = walk_speed / 160.0

		if position.distance_to(target_pos) < 2.0:
			position = target_pos
			_update_depth_scale()
			is_walking = false
			if side_view:
				var anim = side_view.find_child("AnimPlayer", true, false)
				if anim:
					anim.play("idle")
					anim.speed_scale = 1.0
			walk_finished.emit()

# --- Core Controls ---

func set_facing(dir: int) -> void:
	facing_direction = 1 if dir >= 0 else -1
	if side_view:
		side_view.facing_direction = facing_direction
		var visuals = side_view.get_node_or_null("Visuals")
		if visuals:
			visuals.scale.x = float(facing_direction)

func walk_to(dest_x: float, speed: float = 160.0) -> void:
	walk_to_2d(Vector2(dest_x, position.y), speed)

func walk_to_2d(dest: Vector2, speed: float = 160.0) -> void:
	target_pos = dest
	walk_speed = speed
	var dir = 1 if dest.x >= position.x else -1
	set_facing(dir)
	is_walking = true
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("walk")
			anim.speed_scale = walk_speed / 160.0

func run_to(dest_x: float) -> void:
	run_to_2d(Vector2(dest_x, position.y))

func run_to_2d(dest: Vector2) -> void:
	walk_to_2d(dest, 300.0)
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim and anim.has_animation("run"):
			anim.play("run")

func set_expression(expr: String, eyes: String = "open") -> void:
	_ensure_nodes()
	if side_view:
		var face = side_view.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr)
			if face.has_method("set_eye_state"):
				face.set_eye_state(eyes)

func reset_pose() -> void:
	_update_depth_scale()
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
	if not side_view:
		attack_finished.emit()
		return

	side_view.position = Vector2.ZERO
	side_view.set_physics_process(true)
	side_view.trigger_attack()

	if not side_view.attack_ended.is_connected(_on_attack_ended):
		side_view.attack_ended.connect(_on_attack_ended, CONNECT_ONE_SHOT)

func _on_attack_ended() -> void:
	if side_view:
		side_view.set_physics_process(false)
		side_view.position = Vector2.ZERO
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("idle")
	attack_finished.emit()

func trigger_super() -> void:
	if not side_view:
		return
	side_view.set_physics_process(true)
	if side_view.has_method("activate_super"):
		side_view.activate_super()
	elif "wants_super" in side_view:
		side_view.wants_super = true

func end_super() -> void:
	if side_view:
		if side_view.has_method("_cancel_super"):
			side_view._cancel_super()
		elif side_view.has_method("cancel_super"):
			side_view.cancel_super()
		if "visuals" in side_view and side_view.visuals:
			side_view.visuals.modulate.a = 1.0
		var visuals = side_view.get_node_or_null("Visuals")
		if visuals:
			visuals.modulate.a = 1.0
		side_view.modulate.a = 1.0
	modulate.a = 1.0

# --- ACTING BEATS ---

func cautious_advance() -> void:
	# Creeping forward through the facility, wary and alert
	set_expression("neutral", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", 0.08, 0.3)
		if head: tw.tween_property(head, "rotation", 0.1, 0.3)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.3, 0.3)

func alert_react() -> void:
	# Snaps to attention when danger is detected
	set_expression("shocked", "wide")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", -0.15, 0.18)
		if head: tw.tween_property(head, "rotation", -0.1, 0.18)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.6, 0.18)
		if arm_l: tw.tween_property(arm_l, "rotation", -0.5, 0.18)

func dodge_roll(direction: int = 1, delta_y: float = 0.0) -> void:
	# Quick evasive leap to the side across depth lanes
	set_expression("serious", "open")
	var orig_y = position.y
	var dest_y = orig_y + delta_y
	var base_s = get_depth_scale()
	var tw = create_tween()
	tw.tween_property(self, "position:x", position.x + direction * 120.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "position:y", orig_y - 40.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "scale", Vector2(base_s * 0.85, base_s * 1.15), 0.12)
	tw.tween_property(self, "position:y", dest_y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector2(base_s * 1.15, base_s * 0.85), 0.08)
	tw.tween_callback(func(): _update_depth_scale())
	await tw.finished
	_update_depth_scale()
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("DUST_PUFF", global_position)

func confident_smirk() -> void:
	# "I got this" confident pose
	set_expression("smug", "open")
	if side_view:
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", -0.1, 0.25)
		if head: tw.tween_property(head, "rotation", -0.08, 0.25)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.3, 0.25)

func concern_realize() -> void:
	# Confidence drains as Leon realizes the scale of what they've done
	set_expression("confused", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", 0.12, 0.4)
		if head: tw.tween_property(head, "rotation", 0.2, 0.4)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.15, 0.4)
		if arm_l: tw.tween_property(arm_l, "rotation", -0.15, 0.4)
	# Shift to scared expression
	var tw_expr = create_tween()
	tw_expr.tween_interval(0.5)
	tw_expr.tween_callback(func(): set_expression("scared", "wide"))

func panic_run_signal() -> void:
	# "RUN!" — arms out pushing teammates, body language screaming urgency
	set_expression("shocked", "wide")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", -0.3, 0.2)
		if head: tw.tween_property(head, "rotation", -0.15, 0.2)
		if arm_r: tw.tween_property(arm_r, "rotation", -1.3, 0.2)
		if arm_l: tw.tween_property(arm_l, "rotation", -1.1, 0.2)

func victory_relax() -> void:
	# Post-victory relief: shoulders drop, exhales, slight smile
	set_expression("happy", "open")
	if side_view:
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", -0.08, 0.4)
		if head: tw.tween_property(head, "rotation", -0.05, 0.4)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.15, 0.4)
	# Exhale breath
	var s = get_depth_scale()
	var tw_scale = create_tween().set_trans(Tween.TRANS_SINE)
	tw_scale.tween_property(self, "scale", Vector2(s * 1.04, s * 0.96), 0.3)
	tw_scale.tween_property(self, "scale", Vector2(s, s), 0.3)

func tactical_reposition(new_x: float) -> void:
	tactical_reposition_2d(Vector2(new_x, position.y))

func tactical_reposition_2d(new_pos: Vector2, duration: float = 0.35) -> void:
	# Quick repositioning across depth lanes — maintains facing direction
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", new_pos, duration)
	tw.parallel().tween_method(func(_val): _update_depth_scale(), 0.0, 1.0, duration)
	await tw.finished
	_update_depth_scale()

func look_at_target(target_pos: Vector2) -> void:
	# Turns head toward a specific position
	var dir = 1 if target_pos.x > global_position.x else -1
	if side_view:
		var head = side_view.find_child("head", true, false)
		if head:
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(head, "rotation", dir * 0.15, 0.2)

func combat_ready_stance() -> void:
	# Battle-ready posture
	set_expression("serious", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", 0.1, 0.2)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.5, 0.2)
