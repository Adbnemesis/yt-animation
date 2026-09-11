class_name SecurityMachine
extends Node2D

# Deterministic Scripted Security Machine Enemy
# 100% scripted behavior — NO AI. Attacks at predetermined story beats.
# Built from existing asset library textures.

const SceneDepthClass = preload("res://scenes/videos/thing_they_opened/depth_model.gd")

signal hit_received(hit_data: RefCounted)
signal destroyed()
signal attack_fired(target_pos: Vector2)

var health: float = 300.0
var max_health: float = 300.0
var is_active: bool = false
var is_destroyed: bool = false
var base_scale: float = 1.18  # identity size; depth model scales from here

@onready var body_sprite: Sprite2D = get_node_or_null("Body")
@onready var turret: Node2D = get_node_or_null("Turret")
@onready var screen: Sprite2D = get_node_or_null("Screen")
@onready var hit_area: Area2D = get_node_or_null("HitArea")

func _ready() -> void:
	if hit_area:
		hit_area.add_to_group("hit_receiver")
	# Resolve apparent size from the shared floor-plane depth model
	SceneDepthClass.apply(self, base_scale)
	visible = true
	modulate.a = 1.0

func activate() -> void:
	is_active = true
	# Power-up animation: screen flickers on, turret rotates into position
	if screen:
		var tw = create_tween()
		tw.tween_property(screen, "modulate", Color(1.0, 0.3, 0.2, 1.0), 0.3)
		tw.tween_property(screen, "modulate", Color(0.2, 1.0, 0.3, 1.0), 0.2)
		tw.tween_property(screen, "modulate", Color(1.0, 0.3, 0.2, 1.0), 0.2)
	if turret:
		var tw2 = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.tween_property(turret, "rotation", -0.3, 0.5)

func attack_at(target_pos: Vector2) -> void:
	if is_destroyed or not is_active:
		return
	# Turret aims toward target
	if turret:
		var dir_to_target = (target_pos - turret.global_position).normalized()
		var angle = dir_to_target.angle()
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(turret, "rotation", angle, 0.25)
		await tw.finished

	# Fire a simple projectile (Area2D moving toward target)
	_fire_projectile(target_pos)
	attack_fired.emit(target_pos)

func _fire_projectile(target_pos: Vector2) -> void:
	var proj = Area2D.new()
	proj.name = "MachineProjectile"

	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 8)
	sprite.position = Vector2(-8, -4)
	sprite.color = Color(1.0, 0.4, 0.15, 1.0)
	proj.add_child(sprite)

	# Trail glow
	var glow = ColorRect.new()
	glow.size = Vector2(24, 6)
	glow.position = Vector2(-20, -3)
	glow.color = Color(1.0, 0.6, 0.2, 0.5)
	proj.add_child(glow)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 8)
	col.shape = shape
	proj.add_child(col)
	proj.collision_layer = 0
	proj.collision_mask = 0

	var spawn_pos = turret.global_position if turret else global_position
	proj.global_position = spawn_pos

	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(proj)

	var dir = (target_pos - spawn_pos).normalized()
	var speed = 500.0
	var lifetime = 0.0
	var max_life = 1.5

	# Move projectile each frame
	proj.set_meta("direction", dir)
	proj.set_meta("speed", speed)
	proj.set_meta("lifetime", lifetime)
	proj.set_meta("max_life", max_life)

	# Simple movement via tween
	var travel_dist = spawn_pos.distance_to(target_pos) + 100.0
	var travel_time = travel_dist / speed
	var tw = create_tween()
	tw.tween_property(proj, "global_position", spawn_pos + dir * travel_dist, travel_time)
	tw.tween_callback(func():
		if is_instance_valid(proj):
			proj.queue_free()
	)

func take_hit(hit_data = null) -> void:
	if is_destroyed:
		return

	var damage = 80.0
	if hit_data and "damage" in hit_data:
		damage = hit_data.damage

	health -= damage

	# Visual damage reaction
	_damage_react()

	hit_received.emit(hit_data)

	if health <= 0.0:
		_destroy()

func _damage_react() -> void:
	# Flash white, shake, emit sparks
	var orig_mod = modulate
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
	tw.tween_property(self, "modulate", orig_mod, 0.1)

	# Shake
	var orig_pos = position
	var shake_tw = create_tween()
	shake_tw.tween_property(self, "position", orig_pos + Vector2(6, -3), 0.04)
	shake_tw.tween_property(self, "position", orig_pos + Vector2(-5, 2), 0.04)
	shake_tw.tween_property(self, "position", orig_pos + Vector2(3, -1), 0.04)
	shake_tw.tween_property(self, "position", orig_pos, 0.04)

	# Sparks
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SPAWN_FLASH", global_position + Vector2(0, -40))

	# Progressive visual damage based on health percentage
	var health_pct = health / max_health
	if health_pct < 0.6 and screen:
		screen.modulate = Color(1.0, 0.5, 0.2, 0.8)
	if health_pct < 0.3:
		# Smoking
		if is_inside_tree() and get_tree().root.has_node("VFXManager"):
			get_tree().root.get_node("VFXManager").spawn_vfx("DUST_PUFF", global_position + Vector2(0, -60))

func _destroy() -> void:
	is_destroyed = true
	is_active = false

	# Collapse animation: turret drops, body slumps, sparks shower
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if turret:
		tw.tween_property(turret, "rotation", 0.8, 0.5)
		tw.tween_property(turret, "position:y", turret.position.y + 20.0, 0.5)
	tw.tween_property(self, "modulate:a", 0.6, 0.8)

	if screen:
		screen.modulate = Color(0.2, 0.2, 0.2, 0.5)

	# Debris and sparks
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		var vm = get_tree().root.get_node("VFXManager")
		vm.spawn_vfx("HIT_IMPACT", global_position + Vector2(-20, -40))
		vm.spawn_vfx("DUST_PUFF", global_position + Vector2(10, -20))
		vm.spawn_vfx("SPAWN_FLASH", global_position + Vector2(0, -50))

	destroyed.emit()
