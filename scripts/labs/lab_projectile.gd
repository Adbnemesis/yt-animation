extends Area2D
class_name LabProjectile

# Lab depth projectile: wraps a REAL production projectile scene (art + hit
# contract) and drives it through world depth so it demonstrates apparent
# scale change, y-sort occlusion, and real collision while traveling
# background->foreground (and reverse).
#
# The wrapped projectile instance has its own physics disabled (it is used
# as the visual + collision shape); movement/lifetime/projection are handled
# here so depth is fully scripted.

const ProjectionClass = preload("res://scripts/labs/projection_2_5d.gd")
const HitDataClass = preload("res://scripts/hit_data.gd")

var world_x: float = 0.0
var world_z: float = 0.0
var vx: float = 0.0
var vz: float = 0.0
var speed: float = 420.0
var damage: float = 40.0
var knockback_force: float = 40.0
var attack_type: String = "LAB_PROJECTILE"
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0
var max_lifetime: float = 2.5
var view_mode: int = ProjectionClass.ViewMode.SIDE

var is_active: bool = true
var inner: Node = null

func _ready() -> void:
	add_to_group("projectiles")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(scene_path: String, start_x: float, start_z: float, dir_x: float, dir_z: float, p_speed: float, p_damage: float, atype: String, p_view_mode: int) -> void:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene:
		inner = scene.instantiate()
		if inner:
			inner.name = "ProjVisual"
			if inner.has_method("set_physics_process"):
				inner.set_physics_process(false)
			add_child(inner)
	world_x = start_x
	world_z = start_z
	speed = p_speed
	damage = p_damage
	attack_type = atype
	view_mode = p_view_mode
	var d := Vector2(dir_x, dir_z)
	if d != Vector2.ZERO:
		d = d.normalized()
	vx = d.x * speed
	vz = d.y * speed
	direction = Vector2(dir_x, 0.0).normalized()
	lifetime = 0.0
	_apply_projection()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	world_x += vx * delta
	world_z += vz * delta
	lifetime += delta
	if lifetime >= max_lifetime or world_z < -10.0 or world_z > ProjectionClass.Z_FAR + 10.0:
		queue_free()
		return
	_apply_projection()

func _apply_projection() -> void:
	var s := ProjectionClass.scale_at(world_z, view_mode, 1.0)
	position = Vector2(world_x, ProjectionClass.screen_y_at(world_z, 0.0, view_mode))
	scale = Vector2(s, s)

func _on_area_entered(area: Area2D) -> void:
	_handle_collision(area)

func _on_body_entered(body: Node2D) -> void:
	_handle_collision(body)

func _handle_collision(collider: Node) -> void:
	if not is_active:
		return
	if collider == self or collider == inner:
		return
	if collider.is_in_group("projectiles"):
		return
	if collider.has_method("take_hit") or collider.is_in_group("hit_receiver"):
		is_active = false
		var hit = HitDataClass.create(
			damage, direction, knockback_force, null, attack_type, global_position
		)
		if collider.has_method("take_hit"):
			collider.take_hit(hit)
		if is_inside_tree() and get_tree().root.has_node("VFXManager"):
			get_tree().root.get_node("VFXManager").spawn_vfx("HIT_IMPACT", global_position)
		queue_free()