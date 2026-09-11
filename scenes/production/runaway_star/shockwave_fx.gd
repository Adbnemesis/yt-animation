extends Node2D
class_name ShockwaveFX

# ============================================================================
# SHOCKWAVE FX (2.5D IMPACT RING)
# ----------------------------------------------------------------------------
# Expanding ground shockwave ellipse that projects via CinematicCamera.
# Used on:
# - Star meteor crash landing
# - Shuriken projectile impact against barrier
# - Super stealth smoke burst
# - Final supernova sparkle burst
# ============================================================================

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO
var radius: float = 0.0
var max_radius: float = 120.0
var ring_color: Color = Color(1.0, 0.95, 0.5, 0.9)
var ring_width: float = 4.0
var is_active: bool = false

func setup(cam: CinematicCamera, pos: Vector2, max_r: float = 140.0, duration: float = 0.5, col: Color = Color(1.0, 0.95, 0.5, 0.9)) -> void:
	camera = cam
	world_pos = pos
	max_radius = max_r
	ring_color = col
	radius = 5.0
	is_active = true
	
	var tw := create_tween()
	tw.tween_property(self, "radius", max_r, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "ring_color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	if is_active:
		_apply_projection()
		queue_redraw()

func _apply_projection() -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, 0.0)
	position = p.pos
	scale = Vector2(p.scale, p.scale * 0.45) # Ground plane elliptical flattening
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) - 1

func _draw() -> void:
	if radius > 1.0 and ring_color.a > 0.01:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, ring_color, ring_width, true)
