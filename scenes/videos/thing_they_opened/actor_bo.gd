class_name FacilityActorBo
extends Node2D

# Cinematic Actor for Bo in "The Thing They Shouldn't Have Opened"
# First video production appearance for Bo.
# Wraps the production brawler_bo.tscn (BrawlerBase) SideView rig.

signal walk_finished()
signal attack_finished()

@onready var side_view: BrawlerBase = get_node_or_null("SideView")

var is_walking: bool = false
var target_pos: Vector2 = Vector2.ZERO
var walk_speed: float = 150.0
var facing_direction: int = 1
var base_scale: float = 1.05

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
				anim.speed_scale = walk_speed / 150.0

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
		var visuals = side_view.get_node_or_null("Visuals")
		if visuals:
			visuals.scale.x = float(facing_direction)

func walk_to(dest_x: float, speed: float = 150.0) -> void:
	walk_to_2d(Vector2(dest_x, position.y), speed)

func walk_to_2d(dest: Vector2, speed: float = 150.0) -> void:
	target_pos = dest
	walk_speed = speed
	var dir = 1 if dest.x >= position.x else -1
	set_facing(dir)
	is_walking = true
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("walk")
			anim.speed_scale = walk_speed / 150.0

func run_to(dest_x: float) -> void:
	run_to_2d(Vector2(dest_x, position.y))

func run_to_2d(dest: Vector2) -> void:
	walk_to_2d(dest, 280.0)

func set_expression(expr: String, eyes: String = "open") -> void:
	_ensure_nodes()
	if side_view:
		if side_view.has_method("set_expression"):
			side_view.set_expression(expr)
		if side_view.has_method("set_eye_state"):
			side_view.set_eye_state(eyes)
		# Also try direct face controller
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

	# BrawlerBase uses attack() method
	if side_view.has_method("attack"):
		side_view.attack()
	elif side_view.has_method("trigger_attack"):
		side_view.trigger_attack()

	# Listen for attack end
	if side_view.has_signal("game_event_emitted"):
		if not side_view.game_event_emitted.is_connected(_on_game_event):
			side_view.game_event_emitted.connect(_on_game_event)

	# Fallback timeout
	var tw = create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(func():
		if side_view:
			side_view.set_physics_process(false)
			side_view.position = Vector2.ZERO
			var anim = side_view.find_child("AnimPlayer", true, false)
			if anim:
				anim.play("idle")
		attack_finished.emit()
	)

func _on_game_event(event_name: String, _data: Dictionary) -> void:
	if event_name == "ATTACK_END":
		if side_view:
			side_view.set_physics_process(false)
			side_view.position = Vector2.ZERO
			var anim = side_view.find_child("AnimPlayer", true, false)
			if anim:
				anim.play("idle")
		attack_finished.emit()

# --- ACTING BEATS ---

func tactical_observe() -> void:
	# Studying the threat calmly — slight head tilt, steady posture
	set_expression("stoic", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var head = side_view.find_child("head", true, false)
		var torso = side_view.find_child("torso", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if head: tw.tween_property(head, "rotation", 0.12, 0.3)
		if torso: tw.tween_property(torso, "rotation", 0.05, 0.3)

func precise_aim() -> void:
	# Careful bow draw — leaning into the shot
	set_expression("serious", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var torso = side_view.find_child("torso", true, false)
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var head = side_view.find_child("head", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if torso: tw.tween_property(torso, "rotation", 0.12, 0.3)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.8, 0.3)
		if arm_l: tw.tween_property(arm_l, "rotation", -0.5, 0.3)
		if head: tw.tween_property(head, "rotation", 0.05, 0.3)

func calm_assessment() -> void:
	# Head tilt analyzing situation
	set_expression("neutral", "open")
	if side_view:
		var head = side_view.find_child("head", true, false)
		var tw = create_tween().set_trans(Tween.TRANS_SINE)
		if head:
			tw.tween_property(head, "rotation", 0.2, 0.25)
			tw.tween_property(head, "rotation", -0.05, 0.25)
			tw.tween_property(head, "rotation", 0.1, 0.2)

func steady_retreat(new_x: float) -> void:
	steady_retreat_2d(Vector2(new_x, position.y))

func steady_retreat_2d(new_pos: Vector2, duration: float = 0.4) -> void:
	# Controlled repositioning across depth lanes
	set_expression("serious", "open")
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", new_pos, duration)
	tw.parallel().tween_method(func(_val): _update_depth_scale(), 0.0, 1.0, duration)
	await tw.finished
	_update_depth_scale()

func weapon_lower() -> void:
	# Post-victory weapon down — bow arm drops, relaxes
	set_expression("neutral", "open")
	if side_view:
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var torso = side_view.find_child("torso", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if arm_r: tw.tween_property(arm_r, "rotation", 0.1, 0.4)
		if arm_l: tw.tween_property(arm_l, "rotation", 0.05, 0.4)
		if torso: tw.tween_property(torso, "rotation", -0.05, 0.4)

func alert_stance() -> void:
	# Combat alertness — bow ready
	set_expression("serious", "open")
	if side_view:
		var anim = side_view.find_child("AnimPlayer", true, false)
		if anim: anim.stop()
		var arm_r = side_view.find_child("arm_R_upper", true, false)
		var arm_l = side_view.find_child("arm_L_upper", true, false)
		var torso = side_view.find_child("torso", true, false)
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if arm_r: tw.tween_property(arm_r, "rotation", -0.6, 0.2)
		if arm_l: tw.tween_property(arm_l, "rotation", -0.4, 0.2)
		if torso: tw.tween_property(torso, "rotation", 0.08, 0.2)

func dodge_back(distance: float = 80.0, delta_y: float = 0.0) -> void:
	# Quick backstep dodge across depth lanes
	set_expression("neutral", "open")
	var dest_pos = Vector2(position.x + facing_direction * -distance, position.y + delta_y)
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", dest_pos, 0.25)
	tw.parallel().tween_method(func(_val): _update_depth_scale(), 0.0, 1.0, 0.25)
	await tw.finished
	_update_depth_scale()

func look_at_target(target_pos: Vector2) -> void:
	var dir = 1 if target_pos.x > global_position.x else -1
	if side_view:
		var head = side_view.find_child("head", true, false)
		if head:
			var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(head, "rotation", dir * 0.12, 0.2)
