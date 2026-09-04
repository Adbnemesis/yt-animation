class_name ProjectileBase
extends Area2D

# Generic Reusable Projectile Framework for 2D Brawlers

signal hit_target(target: Node, hit_data: RefCounted)
signal expired()

const HitDataClass = preload("res://scripts/hit_data.gd")
const MAX_TRAIL_POINTS := 5

@export var speed: float = 650.0
@export var max_range: float = 550.0
@export var max_lifetime: float = 1.2
@export var damage: float = 25.0
@export var knockback_force: float = 40.0
@export var attack_type: String = "BASIC_PROJECTILE"
@export var spin_speed: float = 0.0

var direction: Vector2 = Vector2.RIGHT
var source: Node = null
var distance_traveled: float = 0.0
var lifetime: float = 0.0
var is_active: bool = true
var trail_points: Array[Vector2] = []

@onready var visual: Node2D = get_node_or_null("Visuals")
@onready var trail: Line2D = get_node_or_null("Trail")

func _ready() -> void:
	add_to_group("projectiles")
	if not visual:
		visual = get_node_or_null("Visuals")
	if not trail:
		trail = get_node_or_null("Trail")

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func initialize(origin_pos: Vector2, aim_dir: Vector2, p_source: Node = null) -> void:
	global_position = origin_pos
	direction = aim_dir.normalized() if aim_dir != Vector2.ZERO else Vector2.RIGHT
	source = p_source
	distance_traveled = 0.0
	lifetime = 0.0
	is_active = true
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

	if visual and spin_speed != 0.0:
		visual.rotation += spin_speed * delta * (1.0 if direction.x >= 0 else -1.0)

	if trail:
		_update_trail()

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

	if collider == source:
		return
	if source and (collider.is_ancestor_of(source) or source.is_ancestor_of(collider)):
		return

	if collider.has_method("take_hit") or collider.is_in_group("hit_receiver"):
		is_active = false
		var hit = HitDataClass.create(
			damage, direction, knockback_force, source, attack_type, global_position
		)
		if collider.has_method("take_hit"):
			collider.take_hit(hit)
		hit_target.emit(collider, hit)
		queue_free()

func expire() -> void:
	is_active = false
	expired.emit()
	queue_free()
