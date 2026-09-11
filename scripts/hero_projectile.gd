extends Node2D
class_name HeroProjectile

# ============================================================================
# HERO PROJECTILE (2.5D) — Authoritative Spatial Projectile
# ----------------------------------------------------------------------------
# Fulfils Bible Parts 41-43 and Contract Law 13:
# ATTACK -> RELEASE -> PROJECTILE -> TRAVEL -> COLLISION -> IMPACT -> VFX -> SFX -> REACTION
#
# Exists in world coordinates (world_pos.x, world_pos.y as Z, elevation).
# Projected by CinematicCamera each frame so apparent scale and depth ordering
# are pure consequences of spatial depth. Collides by world-space distance.
# ============================================================================

signal hit_target(target: Node2D)

const TEX_LEON_SPINNER := "res://assets/brawlers/leon/projectile/spinner_blade.svg"
const TEX_NITA_SHOCKWAVE := "res://assets/brawlers/nita/projectile/shockwave_rupture.svg"
const TEX_BO_ARROW := "res://assets/brawlers/bo/equipment/bo_arrow.svg"

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, z) in world space
var elevation: float = 30.0           # height above ground plane
var direction: Vector2 = Vector2.RIGHT # movement vector on ground plane (x, z)
var speed: float = 520.0
var max_range: float = 1200.0
var hit_radius: float = 36.0
var base_scale: float = 1.0
var kind: String = "leon"

var _travelled: float = 0.0
var _targets: Array = []
var _dead: bool = false
var _spin_speed: float = 0.0

var visual: Sprite2D = null
var trail: Line2D = null

func _ready() -> void:
	if visual == null:
		visual = Sprite2D.new()
		visual.name = "Visual"
		add_child(visual)
	if trail == null:
		trail = Line2D.new()
		trail.name = "Trail"
		trail.width = 5.0
		add_child(trail)

func setup(
	cam: CinematicCamera,
	spawn_pos: Vector2,
	dir: Vector2,
	elev: float,
	p_kind: String,
	p_speed: float,
	p_range: float,
	targets: Array
) -> void:
	camera = cam
	world_pos = spawn_pos
	direction = dir.normalized()
	elevation = elev
	kind = p_kind
	speed = p_speed
	max_range = p_range
	_targets = targets
	_ensure_components()
	_apply_camera()

func _ensure_components() -> void:
	if visual == null:
		visual = Sprite2D.new()
		visual.name = "Visual"
		add_child(visual)
	if trail == null:
		trail = Line2D.new()
		trail.name = "Trail"
		trail.width = 5.0
		add_child(trail)

	match kind:
		"leon":
			visual.texture = load(TEX_LEON_SPINNER)
			base_scale = 1.1
			_spin_speed = 24.0
			trail.width = 4.0
			trail.default_color = Color(0.0, 0.92, 1.0, 0.65)
		"nita":
			visual.texture = load(TEX_NITA_SHOCKWAVE)
			base_scale = 1.25
			_spin_speed = 0.0
			trail.width = 7.0
			trail.default_color = Color(0.1, 0.95, 1.0, 0.75)
		"bo":
			visual.texture = load(TEX_BO_ARROW)
			base_scale = 1.0
			_spin_speed = 0.0
			trail.width = 3.5
			trail.default_color = Color(0.0, 0.72, 0.92, 0.55)

func _physics_process(delta: float) -> void:
	if _dead:
		return

	var step := speed * delta
	world_pos += direction * step
	_travelled += step

	if _spin_speed != 0.0:
		visual.rotation += _spin_speed * delta
	else:
		# Angle on screen determined by direction
		visual.rotation = direction.angle()

	_apply_camera()
	_update_trail()
	_check_collisions()

	if _travelled >= max_range:
		_expire()

func _apply_camera() -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, elevation)
	position = p.pos
	var s := maxf(p.scale, 0.01) * base_scale
	scale = Vector2(s, s)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) + 2

func _update_trail() -> void:
	if trail == null:
		return
	trail.add_point(position)
	if trail.get_point_count() > 8:
		trail.remove_point(0)

func _check_collisions() -> void:
	for t in _targets:
		var target_node: Node2D = t.get("node")
		if not is_instance_valid(target_node):
			continue
		var tw: Vector2 = target_node.world_pos if "world_pos" in target_node else t.get("world_pos", target_node.position)
		var rad: float = t.get("radius", 40.0)
		if world_pos.distance_to(tw) <= rad + hit_radius * 0.45:
			_impact(target_node, t)
			return

func _impact(target_node: Node2D, target_info: Dictionary) -> void:
	if _dead:
		return
	_dead = true

	hit_target.emit(target_node)

	# Impact VFX at exact screen contact position
	if get_tree().root.has_node("VFXManager"):
		var vfx_mgr = get_tree().root.get_node("VFXManager")
		vfx_mgr.spawn_vfx("HIT_IMPACT", position, get_parent())
		if elevation <= 30.0:
			vfx_mgr.spawn_vfx("DUST_PUFF", position, get_parent())

	# Target reaction
	if target_node.has_method("take_hit"):
		var hit = HitData.create(150.0, direction, 140.0, self, "HERO_" + kind.to_upper(), position)
		target_node.take_hit(hit)
	elif target_node.has_method("take_projectile_impact"):
		var impulse_elev := 220.0 if kind == "nita" else 140.0
		var impulse_h := 320.0 if kind == "bo" else 260.0
		target_node.take_projectile_impact(Vector3(direction.x * impulse_h, direction.y * impulse_h, impulse_elev))
	elif target_node.has_method("react_hit"):
		target_node.react_hit(direction)
	elif target_node.has_method("play_hit"):
		target_node.play_hit()

	queue_free()

func _expire() -> void:
	if _dead:
		return
	_dead = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)
