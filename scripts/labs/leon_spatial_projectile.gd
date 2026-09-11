extends Node2D
class_name LeonSpatialProjectile

# ============================================================================
# LEON SPATIAL PROJECTILE (LAB)
# ----------------------------------------------------------------------------
# A 2.5D projectile that exists in 3D world space:
#   world_pos: (x = lateral, z = depth) on ground plane
#   elevation: height above ground (y)
#
# Follows strict causality (Bible Part 27, Contract Law 13):
#   ATTACK -> RELEASE -> SPAWN -> TRAVEL -> COLLISION -> IMPACT -> VFX -> REACTION
#
# The apparent scale responds directly to the camera projection:
#   k = focal / (focal + depth)
# Scale is NOT manually animated; it is a direct consequence of spatial depth.
# ============================================================================

signal hit_target(target: Node2D)

const TEX_SPINNER := preload("res://assets/brawlers/leon/projectile/spinner_blade.svg")

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, depth_z)
var elevation: float = 38.0           # y height above ground
var target_pos: Vector2 = Vector2.ZERO
var target_node: Node2D = null
var speed: float = 680.0
var spin_speed: float = 28.0
var _dead: bool = false
var _travelled: float = 0.0
var _max_range: float = 1400.0

var sprite: Sprite2D = null
var trail: Line2D = null

func setup(
	cam: CinematicCamera,
	from_world: Vector2,
	to_world: Vector2,
	from_elevation: float,
	target: Node2D = null,
	proj_speed: float = 680.0
) -> void:
	camera = cam
	world_pos = from_world
	target_pos = to_world
	elevation = from_elevation
	target_node = target
	speed = proj_speed
	
	_build_visuals()
	_apply_camera()

func _build_visuals() -> void:
	# Create trail
	trail = Line2D.new()
	trail.name = "Trail"
	trail.width = 6.0
	trail.default_color = Color(0.0, 0.9, 1.0, 0.6)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.0, 0.9, 1.0, 0.7), Color(0.0, 0.9, 1.0, 0.0)])
	trail.gradient = grad
	add_child(trail)
	
	# Create spinning blade sprite
	sprite = Sprite2D.new()
	sprite.name = "BladeSprite"
	sprite.texture = TEX_SPINNER
	sprite.scale = Vector2(1.3, 1.3)
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	
	if sprite:
		sprite.rotation += spin_speed * delta
		
	var to_target := target_pos - world_pos
	var dist := to_target.length()
	var step := speed * delta
	
	if dist <= maxf(step, 24.0):
		# Reached target plane / position!
		world_pos = target_pos
		_apply_camera()
		_impact()
		return
		
	var dir := to_target.normalized()
	world_pos += dir * step
	_travelled += step
	
	_apply_camera()
	
	if _travelled >= _max_range:
		_expire()

func _apply_camera() -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, elevation)
	position = p.pos
	var proj_scale: float = maxf(p.scale * 1.8, 0.02)
	scale = Vector2.ONE * proj_scale
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) + 5

func _impact() -> void:
	if _dead:
		return
	_dead = true
	
	# 1. Trigger impact VFX (cyan burst at current screen position)
	_spawn_impact_vfx()
	
	# 2. Strict causality: Target reacts upon arrival
	if is_instance_valid(target_node):
		if target_node.has_method("take_hit"):
			var hit_payload = RefCounted.new()
			hit_payload.set("damage", 150.0)
			hit_payload.set("direction", (target_pos - world_pos).normalized())
			hit_payload.set("force", 140.0)
			target_node.take_hit(hit_payload)
		elif target_node.has_method("react_hit"):
			target_node.react_hit()
		elif target_node.has_method("play_hit"):
			target_node.play_hit()
			
		hit_target.emit(target_node)
	
	# 3. Quick cleanup
	queue_free()

func _spawn_impact_vfx() -> void:
	var vfx := Node2D.new()
	vfx.position = position
	vfx.z_index = z_index + 1
	get_parent().add_child(vfx)
	
	# Draw expanding ring + sparks
	for i in range(6):
		var spark := Line2D.new()
		spark.width = 2.5
		spark.default_color = Color(0.2, 0.95, 1.0, 0.9)
		var angle := i * (PI / 3.0) + randf_range(-0.2, 0.2)
		var dir := Vector2(cos(angle), sin(angle))
		spark.points = PackedVector2Array([Vector2.ZERO, dir * randf_range(16.0, 28.0) * scale.x])
		vfx.add_child(spark)
	
	var tw := vfx.create_tween()
	tw.set_parallel(true)
	tw.tween_property(vfx, "modulate:a", 0.0, 0.22)
	tw.tween_property(vfx, "scale", vfx.scale * 1.5, 0.22)
	tw.chain().tween_callback(vfx.queue_free)

func _expire() -> void:
	if _dead:
		return
	_dead = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(queue_free)
