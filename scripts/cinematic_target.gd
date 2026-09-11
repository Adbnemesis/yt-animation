extends Node2D
class_name CinematicTarget

# ============================================================================
# CINEMATIC TARGET (2.5D) — Distant Horizon Objective Beacon
# ----------------------------------------------------------------------------
# Master Production Standard:
# docs/CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md (Parts 4, 6, 7, 44, 56)
#
# Spatial Properties:
# - Projected by CinematicCamera at world_pos (X, Z) with ground shadow.
# - Distant depth cue on the ground plane.
# - Subtle ambient glow when waiting; energetic burst when reached.
# ============================================================================

signal activated(target: CinematicTarget)

@export var target_id: int = 1
@export var beacon_color: Color = Color(0.2, 0.9, 1.0, 1.0)

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO
var elevation: float = 0.0
var base_scale: float = 1.0
var is_active: bool = false
var is_completed: bool = false

var _pulse_t: float = 0.0
var shadow: Polygon2D = null
var base_poly: Polygon2D = null
var crystal_poly: Polygon2D = null
var glow_ring: Line2D = null
var aura: Polygon2D = null

func _ready() -> void:
	_setup_visuals()

func setup(cam: CinematicCamera, pos: Vector2, id: int, col: Color) -> void:
	camera = cam
	world_pos = pos
	target_id = id
	beacon_color = col
	if crystal_poly:
		crystal_poly.color = beacon_color
	if glow_ring:
		glow_ring.default_color = beacon_color
	_apply_camera()

func _setup_visuals() -> void:
	# 1. Ground Shadow
	shadow = Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.04, 0.08, 0.12, 0.5)
	_build_shadow_mesh(38.0, 14.0)
	add_child(shadow)

	# 2. Base Pedestal Polygon
	base_poly = Polygon2D.new()
	base_poly.name = "Base"
	base_poly.color = Color(0.22, 0.28, 0.35, 1.0)
	base_poly.polygon = PackedVector2Array([
		Vector2(-24, 0), Vector2(24, 0),
		Vector2(16, -18), Vector2(-16, -18)
	])
	add_child(base_poly)

	# 3. Outer Aura
	aura = Polygon2D.new()
	aura.name = "Aura"
	aura.color = Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.25)
	_build_circle_mesh(aura, 36.0, Vector2(0, -48))
	add_child(aura)

	# 4. Floating Crystal / Obelisk Diamond
	crystal_poly = Polygon2D.new()
	crystal_poly.name = "Crystal"
	crystal_poly.color = beacon_color
	crystal_poly.polygon = PackedVector2Array([
		Vector2(0, -82), Vector2(18, -48),
		Vector2(0, -22), Vector2(-18, -48)
	])
	add_child(crystal_poly)

	# 5. Glowing Ring
	glow_ring = Line2D.new()
	glow_ring.name = "GlowRing"
	glow_ring.width = 3.0
	glow_ring.default_color = beacon_color
	_build_ring_mesh(glow_ring, 28.0, Vector2(0, -48))
	add_child(glow_ring)

func _build_shadow_mesh(rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	var steps := 20
	for i in range(steps):
		var th := i * TAU / steps
		pts.append(Vector2(cos(th) * rx, sin(th) * ry))
	shadow.polygon = pts

func _build_circle_mesh(poly: Polygon2D, r: float, center: Vector2) -> void:
	var pts := PackedVector2Array()
	var steps := 20
	for i in range(steps):
		var th := i * TAU / steps
		pts.append(center + Vector2(cos(th) * r, sin(th) * r))
	poly.polygon = pts

func _build_ring_mesh(line: Line2D, r: float, center: Vector2) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var th := i * TAU / steps
		pts.append(center + Vector2(cos(th) * r, sin(th) * r))
	line.points = pts

func _physics_process(delta: float) -> void:
	_pulse_t += delta
	var float_offset := sin(_pulse_t * 3.5 + target_id * 1.5) * 4.0
	crystal_poly.position.y = float_offset
	glow_ring.position.y = float_offset

	var pulse := (sin(_pulse_t * 4.0) + 1.0) * 0.5
	if is_completed:
		aura.scale = Vector2.ONE * (1.2 + pulse * 0.3)
		aura.modulate.a = 0.85
	elif is_active:
		aura.scale = Vector2.ONE * (1.0 + pulse * 0.2)
		aura.modulate.a = 0.5 + pulse * 0.3
	else:
		aura.scale = Vector2.ONE * 0.8
		aura.modulate.a = 0.2

	_apply_camera()

func _apply_camera() -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, elevation)
	position = p.pos
	var s := maxf(p.scale, 0.01) * base_scale
	scale = Vector2(s, s)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) + 1
	visible = p.visible

func activate_beacon() -> void:
	is_active = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.4)
	tw.tween_property(aura, "scale", Vector2.ONE * 1.4, 0.3).set_trans(Tween.TRANS_BACK)

func trigger_completion() -> void:
	is_completed = true
	activated.emit(self)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(crystal_poly, "scale", Vector2(1.4, 1.4), 0.25)
	tw.tween_property(aura, "color", Color(1.0, 0.95, 0.6, 0.9), 0.25)
	tw.chain().tween_property(crystal_poly, "scale", Vector2.ONE, 0.3)
