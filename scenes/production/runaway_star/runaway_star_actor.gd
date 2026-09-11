extends Node2D
class_name RunawayStarActor

# ============================================================================
# RUNAWAY STAR ACTOR (2.5D)
# ----------------------------------------------------------------------------
# The celestial runaway star in "Leon and the Runaway Star".
# Features:
# - Full 2.5D ground-plane coordinates: world_pos (X, Z) and elevation (Y).
# - Projected every physics frame by CinematicCamera.
# - Ground contact shadow dynamically scaled by depth & elevation.
# - Stylized hand-crafted 5-pointed golden star with cel outline & soft glow.
# - Whimsical expressive eyes that can look around, blink, and react.
# - Trailing stardust particles (CPUParticles2D).
# - Smooth trajectory interpolation, hovering wobble, mimicry, and final burst.
# ============================================================================

signal arrived_at_target()
signal pulse_emitted()
signal burst_completed()

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, z) in world space
var elevation: float = 0.0           # height above ground in world units

var star_scale_multiplier: float = 1.0
var is_active: bool = true
var is_hovering: bool = true

# Movement tweening
var _move_tween: Tween = null
var _wobble_time: float = 0.0
var _pulse_tween: Tween = null

# Visual subnodes
var body: Node2D = null
var star_poly: Polygon2D = null
var star_outline: Line2D = null
var star_core: Polygon2D = null
var glow: Polygon2D = null
var eye_l: Polygon2D = null
var eye_r: Polygon2D = null
var pupil_l: Polygon2D = null
var pupil_r: Polygon2D = null
var shadow: Polygon2D = null
var ground_glow: Polygon2D = null
var particles: CPUParticles2D = null

func _ready() -> void:
	_build_visuals()

func setup(cam: CinematicCamera, initial_world_pos: Vector2, initial_elevation: float = 0.0) -> void:
	camera = cam
	world_pos = initial_world_pos
	elevation = initial_elevation
	_apply_projection()

func _process(delta: float) -> void:
	if not is_active:
		return
		
	var d := (1.0 / 60.0) if OS.has_feature("movie") else delta
	_wobble_time += d
	
	if is_hovering:
		# Gentle organic floating bob
		var bob: float = sin(_wobble_time * 4.2) * 5.0
		if body:
			body.position.y = bob
			body.rotation = sin(_wobble_time * 2.8) * 0.08
		if glow:
			glow.modulate.a = 0.55 + sin(_wobble_time * 5.0) * 0.2
			
	_apply_projection()

func _apply_projection() -> void:
	if camera == null:
		return
		
	var p := camera.project(world_pos, elevation)
	position = p.pos
	var s: float = maxf(p.scale * star_scale_multiplier, 0.01)
	scale = Vector2(s, s)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) + 5 # slight bias above ground props
	
	if shadow:
		var ground_proj := camera.project(world_pos, 0.0)
		# Shadow sits on ground directly beneath star
		shadow.global_position = ground_proj.pos
		var shadow_scale := maxf(ground_proj.scale * maxf(0.2, 1.0 - elevation / 300.0), 0.01)
		shadow.scale = Vector2(shadow_scale, shadow_scale * 0.45)
		shadow.modulate.a = clampf(0.55 * (1.0 - elevation / 250.0), 0.0, 0.6)
		shadow.z_index = -int(clampf(ground_proj.depth, -400.0, 4000.0) * 0.25) - 1

	if ground_glow:
		var ground_proj := camera.project(world_pos, 0.0)
		ground_glow.global_position = ground_proj.pos
		var glow_scale := maxf(ground_proj.scale * maxf(0.3, 1.4 - elevation / 350.0), 0.01)
		ground_glow.scale = Vector2(glow_scale, glow_scale * 0.45)
		ground_glow.modulate.a = clampf(0.35 * (1.0 - elevation / 300.0), 0.0, 0.4) * (0.8 + sin(_wobble_time * 6.0) * 0.2)
		ground_glow.z_index = -int(clampf(ground_proj.depth, -400.0, 4000.0) * 0.25) - 2

# --- Movement API -----------------------------------------------------------

func fall_from_sky(target_pos: Vector2, target_elev: float, duration: float = 1.8) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
		
	is_hovering = false
	_move_tween = create_tween().set_parallel(true)
	_move_tween.tween_property(self, "world_pos", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "elevation", target_elev, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Slight spinning decelerating into hover
	if body:
		body.rotation = -TAU * 1.5
		_move_tween.tween_property(body, "rotation", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	_move_tween.chain().tween_callback(func():
		is_hovering = true
		arrived_at_target.emit()
	)

func dart_to(target_pos: Vector2, target_elev: float, duration: float = 0.45, ease_type: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
		
	is_hovering = false
	
	# Anticipation squash & stretch in direction of motion
	var to_dir := (target_pos - world_pos).normalized()
	if body and to_dir.length() > 0.01:
		var target_rot: float = to_dir.x * 0.35
		var squash_tw := create_tween()
		squash_tw.tween_property(body, "scale", Vector2(1.22, 0.82), 0.06).set_trans(Tween.TRANS_QUAD)
		squash_tw.tween_property(body, "scale", Vector2(0.85, 1.22), 0.1).set_trans(Tween.TRANS_QUAD)
		squash_tw.tween_property(body, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		create_tween().tween_property(body, "rotation", target_rot, 0.12)
		
	if particles:
		particles.amount = 26
		particles.initial_velocity_max = 55.0
		
	_move_tween = create_tween().set_parallel(true)
	_move_tween.tween_property(self, "world_pos", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(ease_type)
	_move_tween.tween_property(self, "elevation", target_elev, duration).set_trans(Tween.TRANS_QUAD).set_ease(ease_type)
	
	_move_tween.chain().tween_callback(func():
		is_hovering = true
		if body:
			create_tween().tween_property(body, "rotation", 0.0, 0.15)
			var settle_tw := create_tween()
			settle_tw.tween_property(body, "scale", Vector2(1.15, 0.88), 0.06)
			settle_tw.tween_property(body, "scale", Vector2.ONE, 0.12)
		if particles:
			particles.amount = 16
			particles.initial_velocity_max = 35.0
		arrived_at_target.emit()
	)

func arc_to(target_pos: Vector2, target_elev: float, duration: float = 0.65, arc_height: float = 70.0) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
		
	is_hovering = false
	var start_pos := world_pos
	var start_elev := elevation
	
	# Anticipation squash before launch
	if body:
		var squash_tw := create_tween()
		squash_tw.tween_property(body, "scale", Vector2(1.28, 0.75), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		squash_tw.tween_property(body, "scale", Vector2(0.8, 1.25), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		squash_tw.tween_property(body, "scale", Vector2.ONE, duration - 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	if particles:
		particles.amount = 28
		particles.initial_velocity_max = 65.0
	
	_move_tween = create_tween()
	_move_tween.tween_method(func(t: float):
		world_pos = start_pos.lerp(target_pos, t)
		var base_elev := lerpf(start_elev, target_elev, t)
		var arc := 4.0 * arc_height * t * (1.0 - t)
		elevation = base_elev + arc
		if body:
			body.rotation = sin(t * PI) * clampf((target_pos.x - start_pos.x) * 0.003, -0.4, 0.4)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	_move_tween.chain().tween_callback(func():
		is_hovering = true
		if body:
			body.rotation = 0.0
			var settle_tw := create_tween()
			settle_tw.tween_property(body, "scale", Vector2(1.18, 0.86), 0.07)
			settle_tw.tween_property(body, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
		if particles:
			particles.amount = 16
			particles.initial_velocity_max = 35.0
			particles.restart()
		arrived_at_target.emit()
	)

func jump_bob(jump_height: float = 40.0, duration: float = 0.45) -> void:
	var orig_elev := elevation
	var tw := create_tween()
	tw.tween_property(self, "elevation", orig_elev + jump_height, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "elevation", orig_elev, duration * 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func trigger_pulse(multiplier: float = 1.45) -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		
	pulse_emitted.emit()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "star_scale_multiplier", multiplier, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if glow:
		_pulse_tween.parallel().tween_property(glow, "scale", Vector2(multiplier * 1.25, multiplier * 1.25), 0.12)
		_pulse_tween.parallel().tween_property(glow, "modulate:a", 0.95, 0.12)
		
	_pulse_tween.tween_property(self, "star_scale_multiplier", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if glow:
		_pulse_tween.parallel().tween_property(glow, "scale", Vector2.ONE, 0.25)
		_pulse_tween.parallel().tween_property(glow, "modulate:a", 0.55, 0.25)

func trigger_burst() -> void:
	is_active = false
	if particles:
		particles.emitting = true
		particles.restart()
		
	var tw := create_tween().set_parallel(true)
	if body:
		tw.tween_property(body, "scale", Vector2(2.2, 2.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(body, "modulate:a", 0.0, 0.35)
	if shadow:
		tw.tween_property(shadow, "modulate:a", 0.0, 0.25)
		
	tw.chain().tween_callback(func():
		burst_completed.emit()
		visible = false
	)

func set_eye_gaze(gaze_offset: Vector2) -> void:
	if pupil_l:
		pupil_l.position = Vector2(-4.0, -1.0) + gaze_offset * 2.0
	if pupil_r:
		pupil_r.position = Vector2(4.0, -1.0) + gaze_offset * 2.0

func look_at_pos(target_world_pos: Vector2) -> void:
	var dir := (target_world_pos - world_pos).normalized()
	set_eye_gaze(Vector2(clampf(dir.x, -1.0, 1.0), clampf(dir.y * 0.6, -1.0, 1.0)))

func blink(duration: float = 0.18) -> void:
	if eye_l and eye_r:
		var tw := create_tween()
		tw.tween_property(eye_l, "scale:y", 0.15, duration * 0.4)
		tw.parallel().tween_property(eye_r, "scale:y", 0.15, duration * 0.4)
		tw.tween_property(eye_l, "scale:y", 1.0, duration * 0.6)
		tw.parallel().tween_property(eye_r, "scale:y", 1.0, duration * 0.6)

# --- Visual Construction ----------------------------------------------------

func _build_visuals() -> void:
	# Independent shadow placed directly under scene root (not rotated with star)
	shadow = Polygon2D.new()
	shadow.name = "StarShadow"
	shadow.color = Color(0.08, 0.15, 0.08, 0.45)
	var s_pts := PackedVector2Array()
	var s_segs := 16
	for i in range(s_segs):
		var th := float(i) / s_segs * TAU
		s_pts.append(Vector2(cos(th) * 22.0, sin(th) * 12.0))
	shadow.polygon = s_pts
	add_child(shadow)
	
	# Radiant ground glow decal
	ground_glow = Polygon2D.new()
	ground_glow.name = "GroundGlow"
	ground_glow.color = Color(1.0, 0.95, 0.4, 0.35)
	var gg_pts := PackedVector2Array()
	var gg_segs := 20
	for i in range(gg_segs):
		var th := float(i) / gg_segs * TAU
		gg_pts.append(Vector2(cos(th) * 44.0, sin(th) * 22.0))
	ground_glow.polygon = gg_pts
	add_child(ground_glow)
	
	body = Node2D.new()
	body.name = "StarBody"
	add_child(body)
	
	# Soft circular aura glow
	glow = Polygon2D.new()
	glow.name = "AuraGlow"
	glow.color = Color(1.0, 0.95, 0.4, 0.55)
	var g_pts := PackedVector2Array()
	var g_segs := 24
	for i in range(g_segs):
		var th := float(i) / g_segs * TAU
		g_pts.append(Vector2(cos(th) * 36.0, sin(th) * 36.0))
	glow.polygon = g_pts
	body.add_child(glow)
	
	# Stylized 5-pointed star polygon
	star_poly = Polygon2D.new()
	star_poly.name = "StarMesh"
	star_poly.color = Color(1.0, 0.88, 0.12, 1.0) # Radiant warm gold
	
	var r_outer: float = 24.0
	var r_inner: float = 10.5
	var star_pts := PackedVector2Array()
	
	for i in range(10):
		var th := (i / 10.0) * TAU - PI * 0.5
		var r := r_outer if (i % 2 == 0) else r_inner
		star_pts.append(Vector2(cos(th) * r, sin(th) * r))
	star_poly.polygon = star_pts
	body.add_child(star_poly)
	
	# Cel outline for consistent project paper-cutout style (#1e1e2c)
	star_outline = Line2D.new()
	star_outline.name = "StarOutline"
	star_outline.width = 2.8
	star_outline.default_color = Color(0.12, 0.12, 0.17, 1.0)
	var closed_pts := star_pts.duplicate()
	closed_pts.append(star_pts[0])
	star_outline.points = closed_pts
	star_outline.joint_mode = Line2D.LINE_JOINT_ROUND
	body.add_child(star_outline)
	
	# Inner core highlight
	star_core = Polygon2D.new()
	star_core.name = "StarCore"
	star_core.color = Color(1.0, 1.0, 0.85, 0.88)
	var core_pts := PackedVector2Array()
	for p in star_pts:
		core_pts.append(p * 0.42)
	star_core.polygon = core_pts
	body.add_child(star_core)
	
	# Cute expressive eyes
	eye_l = _create_eye(Vector2(-4.5, -1.0))
	eye_r = _create_eye(Vector2(4.5, -1.0))
	body.add_child(eye_l)
	body.add_child(eye_r)
	
	pupil_l = _create_pupil(Vector2(-4.5, -1.0))
	pupil_r = _create_pupil(Vector2(4.5, -1.0))
	body.add_child(pupil_l)
	body.add_child(pupil_r)
	
	# Trail & sparkle particles
	particles = CPUParticles2D.new()
	particles.name = "StardustParticles"
	particles.emitting = true
	particles.amount = 16
	particles.lifetime = 0.65
	particles.speed_scale = 1.0
	particles.explosiveness = 0.05
	particles.direction = Vector2(0, 1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 15)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 35.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	particles.color = Color(1.0, 0.95, 0.5, 0.85)
	body.add_child(particles)

func _create_eye(pos: Vector2) -> Polygon2D:
	var eye := Polygon2D.new()
	eye.position = pos
	eye.color = Color(0.12, 0.12, 0.17, 1.0)
	var pts := PackedVector2Array([
		Vector2(-1.5, -3.0), Vector2(1.5, -3.0),
		Vector2(1.5, 3.0), Vector2(-1.5, 3.0)
	])
	eye.polygon = pts
	return eye

func _create_pupil(pos: Vector2) -> Polygon2D:
	var pupil := Polygon2D.new()
	pupil.position = pos + Vector2(0.5, -1.0)
	pupil.color = Color(1.0, 1.0, 1.0, 0.9)
	var pts := PackedVector2Array([
		Vector2(-0.7, -0.7), Vector2(0.7, -0.7),
		Vector2(0.7, 0.7), Vector2(-0.7, 0.7)
	])
	pupil.polygon = pts
	return pupil
