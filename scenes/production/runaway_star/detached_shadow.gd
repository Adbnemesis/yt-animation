extends Node2D
class_name DetachedShadowActor

# ============================================================================
# DETACHED SHADOW ACTOR (2.5D STYLIZED SHADOW)
# ----------------------------------------------------------------------------
# The detached shadow stolen by the Runaway Star in "The Runaway Star".
#
# Story & Visual Requirements:
# 1. Stays flat on the ground plane in 2.5D space (projected by CinematicCamera).
# 2. Visually resembles Leon's silhouette: dark, translucent, flat on the grass.
# 3. Exactly ONE detached shadow exists. It is NOT another Leon character.
# 4. Supports:
#    - steal_from(leon_pos, star_actor, duration):
#      Stretches & detaches from Leon's feet toward the star with elastic distortion.
#    - follow_star(star_actor):
#      Follows the star's ground footprint across the chases.
#    - return_to_leon(leon_pos, duration):
#      Glides back across the ground to Leon's feet and re-attaches cleanly.
# ============================================================================

signal reconnected()

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, z) on ground plane
var is_active: bool = false
var is_following_star: bool = false
var star_target: Node2D = null

# Visual subnodes
var root_shadow: Node2D = null
var base_ellipse: Polygon2D = null
var body_silhouette: Polygon2D = null
var arm_polygon: Polygon2D = null

var _tween: Tween = null
var _wobble_time: float = 0.0

func _ready() -> void:
	_build_visuals()
	visible = false

func setup(cam: CinematicCamera) -> void:
	camera = cam
	_apply_projection()

func _process(delta: float) -> void:
	if not is_active:
		return
		
	var d := (1.0 / 60.0) if OS.has_feature("movie") else delta
	_wobble_time += d
	
	if is_following_star and star_target != null and is_instance_valid(star_target):
		# Follow star's ground position with subtle trailing lag
		var target_pos: Vector2 = star_target.world_pos
		world_pos = world_pos.lerp(target_pos, clampf(d * 14.0, 0.0, 1.0))
		
		# Subtle fluttering organic distortion while being carried
		if body_silhouette:
			body_silhouette.scale.x = 1.0 + sin(_wobble_time * 9.0) * 0.06
			body_silhouette.scale.y = 1.0 + cos(_wobble_time * 8.0) * 0.04
			
	_apply_projection()

func _apply_projection() -> void:
	if camera == null:
		return
		
	var p := camera.project(world_pos, 0.0)
	global_position = p.pos + Vector2(0.0, 4.0 * p.scale)
	var s: float = maxf(p.scale, 0.01)
	# Foreshortened ground perspective
	scale = Vector2(s, s * 0.55)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) - 1

## Initiates shadow theft: stretches from Leon's feet to the star's ground position
func steal_from(start_pos: Vector2, star: Node2D, target_pos: Vector2 = Vector2.ZERO, duration: float = 1.2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	world_pos = start_pos
	star_target = star
	is_active = true
	is_following_star = false
	visible = true
	modulate.a = 0.85
	
	_apply_projection()
	
	var dest: Vector2 = target_pos if target_pos != Vector2.ZERO else star.world_pos
	_tween = create_tween()
	_tween.tween_property(self, "world_pos", dest, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func():
		is_following_star = true
	)

## Returns the shadow from the star back to Leon's feet
func return_to_leon(target_pos: Vector2, duration: float = 1.4) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		
	is_following_star = false
	star_target = null
	
	_tween = create_tween()
	_tween.tween_property(self, "world_pos", target_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func():
		reconnected.emit()
		# Fade out cleanly as Leon's own attached shadow takes over
		var fade_tw := create_tween()
		fade_tw.tween_property(self, "modulate:a", 0.0, 0.25)
		fade_tw.tween_callback(func():
			is_active = false
			visible = false
		)
	)

func _build_visuals() -> void:
	root_shadow = Node2D.new()
	root_shadow.name = "ShadowRigs"
	add_child(root_shadow)
	
	var shadow_color := Color(0.04, 0.08, 0.04, 0.85)
	
	# 1. Base ground contact ellipse
	base_ellipse = Polygon2D.new()
	base_ellipse.name = "BaseEllipse"
	base_ellipse.color = shadow_color
	var base_pts := PackedVector2Array()
	var segs := 24
	for i in range(segs):
		var th := float(i) / segs * TAU
		base_pts.append(Vector2(cos(th) * 44.0, sin(th) * 22.0))
	base_ellipse.polygon = base_pts
	root_shadow.add_child(base_ellipse)
	
	# 2. Leon-shaped silhouette (hood with chameleon crest & torso projection)
	body_silhouette = Polygon2D.new()
	body_silhouette.name = "BodySilhouette"
	body_silhouette.color = shadow_color
	var body_pts := PackedVector2Array([
		Vector2(-24.0, -4.0),
		Vector2(-30.0, -18.0),
		Vector2(-32.0, -38.0),
		Vector2(-24.0, -58.0),
		Vector2(-12.0, -68.0),
		Vector2(0.0, -78.0),   # Crest tip
		Vector2(12.0, -72.0),
		Vector2(26.0, -56.0),
		Vector2(32.0, -36.0),
		Vector2(28.0, -16.0),
		Vector2(22.0, -4.0),
		Vector2(14.0, 8.0),
		Vector2(-14.0, 8.0)
	])
	body_silhouette.polygon = body_pts
	root_shadow.add_child(body_silhouette)
