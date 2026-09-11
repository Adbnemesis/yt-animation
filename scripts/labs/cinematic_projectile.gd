extends Node2D
class_name CinematicProjectile

# ============================================================================
# CINEMATIC PROJECTILE (LAB) — a projectile that exists in the world (x, z)
# ----------------------------------------------------------------------------
# Causality chain (Part 27): the actor emits attack_released(socket_world) at
# RELEASE; the lab spawns THIS projectile at that world position; it travels
# through depth, is projected by the same camera as everything else, and
# collides by WORLD distance — never by animation timing.
# ============================================================================

signal hit_target(target: Node2D)

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO
var elevation: float = 0.0
var direction := Vector2.RIGHT
var speed: float = 420.0
var max_range: float = 900.0
var hit_radius: float = 34.0
var _travelled: float = 0.0
var _targets: Array = [] # [{node, world, radius}]
var _dead := false

@onready var visual: Sprite2D = get_node_or_null("Visual")

func setup(cam: CinematicCamera, from: Vector2, dir: Vector2, elev: float,
		p_speed: float, p_range: float, targets: Array) -> void:
	camera = cam
	world_pos = from
	direction = dir.normalized()
	elevation = elev
	speed = p_speed
	max_range = p_range
	_targets = targets
	_apply_camera()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	var step := speed * delta
	world_pos += direction * step
	_travelled += step
	_apply_camera()
	for t in _targets:
		var tw: Vector2 = t.get("world_pos")
		var radius: float = t.get("radius")
		if world_pos.distance_to(tw) <= radius + hit_radius * 0.4:
			_impact(t.get("node"))
			return
	if _travelled >= max_range:
		_expire()

func _apply_camera() -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, elevation)
	position = p.pos
	scale = Vector2.ONE * maxf(p.scale, 0.01)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) + 1
	if visual:
		visual.rotation = direction.angle()

func _impact(target: Node2D) -> void:
	if _dead:
		return
	_dead = true
	hit_target.emit(target)
	if target and target.has_method("react_hit"):
		target.react_hit()
	queue_free()

func _expire() -> void:
	if _dead:
		return
	_dead = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
