extends Node2D
class_name GlowingCircle

# ============================================================================
# GLOWING CIRCLE (2.5D Ground Glyph)
# ----------------------------------------------------------------------------
# The mystical ancient circular mark on the grassy field.
# Sits directly on the ground plane at world_pos (X, Z).
#
# Behaviors:
# - Dormant: subtle glowing runic ring etched into the meadow grass.
# - Activated: When the Runaway Star enters, the circle ignites with a vibrant
#   cyan-teal pulse, expanding ring shockwaves, and mystical chime.
# - Impact reaction: When attacked by Leon's shuriken, it absorbs the hit with
#   a shimmering ripple wave, proving it is indestructible.
# ============================================================================

signal circle_activated()
signal hit_absorbed()

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2(180.0, 240.0) # Ground position in 2.5D world
var radius_world: float = 65.0

var is_activated: bool = false
var _pulse_time: float = 0.0

var ring_outer: Line2D = null
var ring_inner: Line2D = null
var runes: Node2D = null
var core_glow: Polygon2D = null
var ripple_wave: Line2D = null

func _ready() -> void:
	_build_visuals()

func setup(cam: CinematicCamera, pos: Vector2, radius: float = 65.0) -> void:
	camera = cam
	world_pos = pos
	radius_world = radius
	_apply_projection()

func _process(delta: float) -> void:
	_pulse_time += delta
	_apply_projection()
	
	if is_activated:
		# Mystical energetic respiration
		var breath: float = 0.65 + sin(_pulse_time * 4.5) * 0.25
		if core_glow:
			core_glow.modulate.a = breath * 0.6
		if ring_outer:
			ring_outer.modulate.a = 0.75 + sin(_pulse_time * 6.0) * 0.2
	else:
		if core_glow:
			core_glow.modulate.a = 0.22 + sin(_pulse_time * 2.0) * 0.08

func _apply_projection() -> void:
	if camera == null:
		return
		
	var p := camera.project(world_pos, 0.0)
	position = p.pos
	
	# In perspective, horizontal ground circle projects as an ellipse
	var s: float = maxf(p.scale, 0.01)
	scale = Vector2(s, s * 0.48) # ground perspective compression
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) - 2 # firmly under actors

func activate() -> void:
	if is_activated:
		return
	is_activated = true
	circle_activated.emit()
	
	var tw := create_tween().set_parallel(true)
	if ring_outer:
		ring_outer.default_color = Color(0.15, 0.95, 0.95, 1.0)
		tw.tween_property(ring_outer, "width", 5.5, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if core_glow:
		tw.tween_property(core_glow, "modulate:a", 0.85, 0.35)
		
	# Spawn expanding shockwave
	_spawn_shockwave()

func absorb_hit(hit_world_pos: Vector2) -> void:
	hit_absorbed.emit()
	
	# Shimmer & ripple reaction
	var tw := create_tween()
	if core_glow:
		tw.tween_property(core_glow, "modulate", Color(1.5, 1.8, 2.0, 1.0), 0.08)
		tw.tween_property(core_glow, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
		
	_spawn_shockwave(0.4)

func _spawn_shockwave(duration: float = 0.6) -> void:
	var wave := Line2D.new()
	wave.width = 3.5
	wave.default_color = Color(0.2, 1.0, 0.95, 0.9)
	var pts := PackedVector2Array()
	var segs := 24
	for i in range(segs):
		var th := float(i) / segs * TAU
		pts.append(Vector2(cos(th) * (radius_world * 0.8), sin(th) * (radius_world * 0.8)))
	pts.append(pts[0])
	wave.points = pts
	add_child(wave)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(wave, "scale", Vector2(1.8, 1.8), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(wave, "modulate:a", 0.0, duration)
	tw.chain().tween_callback(wave.queue_free)

# --- Visual Construction ----------------------------------------------------

func _build_visuals() -> void:
	# Core glow pool
	core_glow = Polygon2D.new()
	core_glow.name = "CoreGlow"
	core_glow.color = Color(0.12, 0.82, 0.92, 0.3)
	var g_pts := PackedVector2Array()
	var segs := 28
	for i in range(segs):
		var th := float(i) / segs * TAU
		g_pts.append(Vector2(cos(th) * (radius_world * 0.92), sin(th) * (radius_world * 0.92)))
	core_glow.polygon = g_pts
	add_child(core_glow)
	
	# Outer border ring
	ring_outer = Line2D.new()
	ring_outer.name = "RingOuter"
	ring_outer.width = 3.6
	ring_outer.default_color = Color(0.18, 0.72, 0.82, 0.75)
	var r_pts := PackedVector2Array()
	for i in range(segs):
		var th := float(i) / segs * TAU
		r_pts.append(Vector2(cos(th) * radius_world, sin(th) * radius_world))
	r_pts.append(r_pts[0])
	ring_outer.points = r_pts
	add_child(ring_outer)
	
	# Inner decorative ring
	ring_inner = Line2D.new()
	ring_inner.name = "RingInner"
	ring_inner.width = 2.0
	ring_inner.default_color = Color(0.15, 0.88, 0.95, 0.5)
	var in_pts := PackedVector2Array()
	for i in range(segs):
		var th := float(i) / segs * TAU
		in_pts.append(Vector2(cos(th) * (radius_world * 0.65), sin(th) * (radius_world * 0.65)))
	in_pts.append(in_pts[0])
	ring_inner.points = in_pts
	add_child(ring_inner)
	
	# Runic radiating spoke marks
	runes = Node2D.new()
	runes.name = "Runes"
	add_child(runes)
	
	for i in range(8):
		var th := float(i) / 8.0 * TAU
		var mark := Line2D.new()
		mark.width = 2.4
		mark.default_color = Color(0.18, 0.78, 0.88, 0.65)
		var p1 := Vector2(cos(th) * (radius_world * 0.65), sin(th) * (radius_world * 0.65))
		var p2 := Vector2(cos(th) * (radius_world * 0.98), sin(th) * (radius_world * 0.98))
		mark.points = PackedVector2Array([p1, p2])
		runes.add_child(mark)
