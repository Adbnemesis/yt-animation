extends Area2D
class_name NitaProjectile

# Nita Shockwave Rupture Projectile
# Authentic 2D Paper-Cutout Piercing Energy Shockwave
# Configurable, deterministic, detached from character, and idempotent.

const HitDataClass = preload("res://scripts/hit_data.gd")

signal hit_target(target: Node, hit_data: RefCounted)
signal expired()

@export var speed: float = 600.0
@export var max_range: float = 480.0
@export var max_lifetime: float = 1.0
@export var damage: float = 80.0
@export var knockback_force: float = 45.0
@export var attack_type: String = "NITA_BASIC"

var direction: Vector2 = Vector2.RIGHT
var source: Node = null
var distance_traveled: float = 0.0
var lifetime: float = 0.0
var is_active: bool = true

@onready var visual: Node2D = get_node_or_null("Visuals")
@onready var trail: Line2D = get_node_or_null("Trail")

var trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS := 6

func _ready() -> void:
	add_to_group("projectiles")
	_ensure_nodes()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _ensure_nodes() -> void:
	if not visual:
		visual = get_node_or_null("Visuals")
	if not trail:
		trail = get_node_or_null("Trail")

func initialize(origin_pos: Vector2, aim_dir: Vector2, p_source: Node = null) -> void:
	global_position = origin_pos
	direction = aim_dir.normalized() if aim_dir != Vector2.ZERO else Vector2.RIGHT
	source = p_source
	distance_traveled = 0.0
	lifetime = 0.0
	is_active = true

	_ensure_nodes()
	if visual:
		visual.rotation = direction.angle()
		visual.scale = Vector2.ONE

	trail_points.clear()
	if trail:
		trail.clear_points()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	var step = speed * delta
	global_position += direction * step
	distance_traveled += step
	lifetime += delta

	# Subtle energetic shockwave pulse vibration
	if visual:
		var pulse = 1.0 + sin(lifetime * 24.0) * 0.04
		visual.scale = Vector2(pulse, pulse)

	# Update trailing ribbon
	if trail:
		_update_trail()

	# Clean despawn on maximum range or lifetime limit
	if distance_traveled >= max_range or lifetime >= max_lifetime:
		expire()

func _update_trail() -> void:
	trail_points.push_front(global_position)
	if trail_points.size() > MAX_TRAIL_POINTS:
		trail_points.pop_back()

	trail.clear_points()
	for pt in trail_points:
		trail.add_point(to_local(pt))

func _on_area_entered(area: Area2D) -> void:
	_handle_collision(area)

func _on_body_entered(body: Node2D) -> void:
	_handle_collision(body)

func _handle_collision(collider: Node) -> void:
	if not is_active:
		return

	# Ignore self, source character, or source's children
	if collider == source or (source and (collider.is_ancestor_of(source) or source.is_ancestor_of(collider))):
		return

	# Check if collider is a valid hit receiver
	if collider.has_method("take_hit") or collider.is_in_group("hit_receiver"):
		is_active = false
		var hit = HitDataClass.create(
			damage,
			direction,
			knockback_force,
			source,
			attack_type,
			global_position
		)
		if collider.has_method("take_hit"):
			collider.take_hit(hit)
		hit_target.emit(collider, hit)

		if is_inside_tree() and get_tree().root.has_node("AudioManager"):
			get_tree().root.get_node("AudioManager").trigger_event("HIT", {"position": global_position})

		queue_free()

func expire() -> void:
	if not is_active:
		return
	is_active = false
	expired.emit()
	queue_free()
