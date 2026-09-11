extends Node2D
class_name Simple2D5Prop

# ============================================================================
# SIMPLE 2.5D PROP
# ----------------------------------------------------------------------------
# Minimal environmental props (rocks, signpost, fence post) that occupy real
# ground coordinates (X, Z) and project via CinematicCamera.
# Provides depth anchoring, scale references, and natural occlusion.
# ============================================================================

@export var prop_type: String = "rock" # "rock", "sign", "post"
@export var world_pos: Vector2 = Vector2.ZERO
@export var prop_height: float = 45.0

var camera: CinematicCamera = null
var shadow: Polygon2D = null
var body: Polygon2D = null
var outline: Line2D = null

func _ready() -> void:
	_build_prop()

func setup(cam: CinematicCamera, pos: Vector2, kind: String = "rock", h: float = 45.0) -> void:
	camera = cam
	world_pos = pos
	prop_type = kind
	prop_height = h
	_build_prop()
	_apply_projection()

func _process(_delta: float) -> void:
	_apply_projection()

func _apply_projection() -> void:
	if camera == null:
		return
		
	var p := camera.project(world_pos, 0.0)
	position = p.pos
	scale = Vector2.ONE * maxf(p.scale, 0.01)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
	
	if shadow:
		shadow.scale = Vector2.ONE * maxf(p.scale, 0.01)

func _build_prop() -> void:
	# Clear old children
	for child in get_children():
		child.queue_free()
		
	# Ground shadow
	shadow = Polygon2D.new()
	shadow.name = "PropShadow"
	shadow.color = Color(0.08, 0.14, 0.08, 0.55)
	var s_pts := PackedVector2Array()
	var r_sh := 26.0 if prop_type == "rock" else 14.0
	for i in range(16):
		var th := float(i) / 16.0 * TAU
		s_pts.append(Vector2(cos(th) * r_sh, sin(th) * (r_sh * 0.42)))
	shadow.polygon = s_pts
	shadow.z_index = -1
	add_child(shadow)
	
	body = Polygon2D.new()
	body.name = "PropBody"
	outline = Line2D.new()
	outline.name = "PropOutline"
	outline.width = 2.4
	outline.default_color = Color(0.12, 0.12, 0.17, 1.0)
	
	match prop_type:
		"rock":
			body.color = Color(0.55, 0.58, 0.62, 1.0) # Stone grey
			var pts := PackedVector2Array([
				Vector2(-24, 0), Vector2(-28, -14), Vector2(-16, -prop_height),
				Vector2(12, -prop_height * 0.9), Vector2(26, -18), Vector2(24, 0)
			])
			body.polygon = pts
			var cl := pts.duplicate()
			cl.append(pts[0])
			outline.points = cl
		"sign":
			body.color = Color(0.62, 0.44, 0.28, 1.0) # Wood plank brown
			var pts := PackedVector2Array([
				Vector2(-5, 0), Vector2(-5, -prop_height),
				Vector2(-32, -prop_height), Vector2(-32, -prop_height - 24),
				Vector2(32, -prop_height - 24), Vector2(32, -prop_height),
				Vector2(5, -prop_height), Vector2(5, 0)
			])
			body.polygon = pts
			var cl := pts.duplicate()
			cl.append(pts[0])
			outline.points = cl
		"post":
			body.color = Color(0.52, 0.38, 0.24, 1.0) # Wooden pole
			var pts := PackedVector2Array([
				Vector2(-6, 0), Vector2(-6, -prop_height),
				Vector2(0, -prop_height - 6), Vector2(6, -prop_height),
				Vector2(6, 0)
			])
			body.polygon = pts
			var cl := pts.duplicate()
			cl.append(pts[0])
			outline.points = cl
		"bush":
			body.color = Color(0.22, 0.55, 0.26, 1.0) # Bush green
			var pts := PackedVector2Array([
				Vector2(-26, 0), Vector2(-30, -prop_height * 0.45), Vector2(-18, -prop_height),
				Vector2(0, -prop_height * 1.1), Vector2(18, -prop_height),
				Vector2(30, -prop_height * 0.45), Vector2(26, 0)
			])
			body.polygon = pts
			var cl := pts.duplicate()
			cl.append(pts[0])
			outline.points = cl
		"flower":
			body.color = Color(0.92, 0.42, 0.65, 1.0) # Pink flower patch
			var pts := PackedVector2Array([
				Vector2(-12, 0), Vector2(-16, -prop_height * 0.6), Vector2(-6, -prop_height),
				Vector2(0, -prop_height * 1.15), Vector2(6, -prop_height),
				Vector2(16, -prop_height * 0.6), Vector2(12, 0)
			])
			body.polygon = pts
			var cl := pts.duplicate()
			cl.append(pts[0])
			outline.points = cl
		"grass":
			body.color = Color(0.20, 0.58, 0.24, 1.0) # Vibrant green blades
			var pts := PackedVector2Array([
				Vector2(-18, 0), Vector2(-24, -prop_height * 0.7), Vector2(-15, -prop_height),
				Vector2(-8, -prop_height * 0.5), Vector2(0, -prop_height * 1.15),
				Vector2(8, -prop_height * 0.55), Vector2(18, -prop_height * 0.85),
				Vector2(22, 0)
			])
			body.polygon = pts
			var cl := pts.duplicate()
			cl.append(pts[0])
			outline.points = cl
			
	add_child(body)
	add_child(outline)
