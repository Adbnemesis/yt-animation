extends Node2D
class_name MysteriousObject

# ============================================================================
# MYSTERIOUS GLOWING OBJECT (2.5D) — Central Visual & Narrative Prop
# ----------------------------------------------------------------------------
# Master Production Standard:
# docs/CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md (Parts 4, 6, 7, 41-47, 83-85)
# docs/CINEMATIC_ANIMATION_CONTRACT.md (Laws 2, 3, 5, 12, 13, 14, 17)
#
# Spatial Properties:
# - Lives in world coordinates: world_pos (X, Z ground plane) and elevation (Y).
# - Projected every physics frame by CinematicCamera.project(world_pos, elevation).
# - Contact shadow on ground plane (world_pos, 0.0) that expands, shrinks, and
#   modulates opacity based on elevation (lifts realistically when airborne).
# - Obeying strict causal physics: changes direction only upon collision with
#   projectiles (Bo arrow, Nita shockwave), character interaction, or ground impact.
# ============================================================================

signal trajectory_changed(new_dir: Vector2)
signal hit_ground(pos_world: Vector2)
signal target_reached(target_id: int)

enum State {
	INACTIVE,
	FALLING,
	CARRIED,
	AIRBORNE_TRAJECTORY,
	HOVERING,
	TINY,
	PULSING
}

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, z) on ground plane
var elevation: float = 0.0           # height Y above ground plane
var velocity: Vector3 = Vector3.ZERO  # (vx, vz on ground plane, vy elevation)
var state: State = State.INACTIVE

var radius: float = 34.0
var base_scale: float = 1.3  # Larger default for better readability in wide shots
var is_pulsing: bool = false
var pulse_time: float = 0.0

# Visual Elements
var core_circle: Polygon2D = null
var aura_circle: Polygon2D = null
var pulse_ring: Line2D = null
var trail: Line2D = null
var shadow: Polygon2D = null
var label_container: Node2D = null
var holo_label: Label = null

# Carried offset
var carried_actor: Node2D = null
var carried_offset: Vector3 = Vector3.ZERO

# Shockwave visual
var shockwave_ring: Line2D = null
var _shockwave_radius: float = 0.0
var _shockwave_active: bool = false

func _ready() -> void:
	_setup_visuals()

func setup(cam: CinematicCamera, pos: Vector2, elev: float = 0.0) -> void:
	camera = cam
	world_pos = pos
	elevation = elev
	_apply_camera()

func _setup_visuals() -> void:
	# 1. Contact Shadow on ground plane (z_index below object)
	shadow = Polygon2D.new()
	shadow.name = "GroundShadow"
	shadow.color = Color(0.02, 0.05, 0.08, 0.5)
	_build_shadow_polygon(34.0, 12.0)
	add_child(shadow)

	# 2. Motion Trail
	trail = Line2D.new()
	trail.name = "MotionTrail"
	trail.width = 18.0
	trail.default_color = Color(0.15, 0.85, 1.0, 0.65)
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(trail)

	# 3. Outer Energy Aura
	aura_circle = Polygon2D.new()
	aura_circle.name = "AuraCircle"
	aura_circle.color = Color(0.08, 0.72, 1.0, 0.45)
	_build_circle_polygon(aura_circle, 42.0)
	add_child(aura_circle)

	# 4. Core Luminous Circle
	core_circle = Polygon2D.new()
	core_circle.name = "CoreCircle"
	core_circle.color = Color(0.85, 0.98, 1.0, 1.0)
	_build_circle_polygon(core_circle, 24.0)
	add_child(core_circle)

	# 5. Expanding Pulse Ring
	pulse_ring = Line2D.new()
	pulse_ring.name = "PulseRing"
	pulse_ring.width = 3.0
	pulse_ring.default_color = Color(0.2, 0.9, 1.0, 0.8)
	_build_ring_polygon(pulse_ring, 48.0)
	add_child(pulse_ring)

	# 6. Expanding Ground Shockwave Ring
	shockwave_ring = Line2D.new()
	shockwave_ring.name = "ShockwaveRing"
	shockwave_ring.width = 4.0
	shockwave_ring.default_color = Color(0.25, 0.95, 1.0, 0.0)
	add_child(shockwave_ring)

	# 7. Holographic "DELIVERY COMPLETE" Label
	label_container = Node2D.new()
	label_container.name = "HoloLabelContainer"
	label_container.visible = false
	add_child(label_container)

	holo_label = Label.new()
	holo_label.name = "HoloText"
	holo_label.text = "DELIVERY COMPLETE"
	holo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holo_label.position = Vector2(-90, -75)
	holo_label.size = Vector2(180, 26)
	holo_label.add_theme_font_size_override("font_size", 14)
	holo_label.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0, 1.0))
	holo_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.2, 0.4, 0.8))
	holo_label.add_theme_constant_override("shadow_offset_x", 1)
	holo_label.add_theme_constant_override("shadow_offset_y", 1)
	label_container.add_child(holo_label)

func _build_shadow_polygon(rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var th := i * TAU / steps
		pts.append(Vector2(cos(th) * rx, sin(th) * ry))
	shadow.polygon = pts

func _build_circle_polygon(poly: Polygon2D, r: float) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var th := i * TAU / steps
		pts.append(Vector2(cos(th) * r, sin(th) * r))
	poly.polygon = pts

func _build_ring_polygon(line: Line2D, r: float) -> void:
	var pts := PackedVector2Array()
	var steps := 28
	for i in range(steps + 1):
		var th := i * TAU / steps
		pts.append(Vector2(cos(th) * r, sin(th) * r))
	line.points = pts

func _physics_process(delta: float) -> void:
	pulse_time += delta
	_update_pulse(delta)
	_step_physics(delta)
	_apply_camera()
	_update_trail()
	_update_shockwave(delta)

func _update_pulse(_delta: float) -> void:
	var pulse := (sin(pulse_time * 6.0) + 1.0) * 0.5
	if state == State.PULSING:
		# Erratic intense warning pulse
		pulse = (sin(pulse_time * 18.0) + 1.0) * 0.5
		aura_circle.color = Color(1.0, 0.25 + pulse * 0.4, 0.1, 0.75 + pulse * 0.2)
		core_circle.color = Color(1.0, 0.9, 0.4, 1.0)
		pulse_ring.default_color = Color(1.0, 0.3, 0.1, 0.9)
	else:
		aura_circle.scale = Vector2.ONE * (1.0 + pulse * 0.22)
		aura_circle.modulate.a = 0.5 + pulse * 0.4
		pulse_ring.scale = Vector2.ONE * (1.0 + pulse * 0.35)
		pulse_ring.modulate.a = 0.8 - pulse * 0.6

func _step_physics(delta: float) -> void:
	match state:
		State.FALLING:
			velocity.y -= 750.0 * delta # gravity
			elevation += velocity.y * delta
			world_pos.x += velocity.x * delta
			world_pos.y += velocity.z * delta
			if elevation <= 0.0:
				elevation = 0.0
				velocity = Vector3.ZERO
				_trigger_ground_impact()

		State.AIRBORNE_TRAJECTORY:
			velocity.y -= 520.0 * delta # subtle gravity
			elevation += velocity.y * delta
			world_pos.x += velocity.x * delta
			world_pos.y += velocity.z * delta
			if elevation <= 0.0:
				elevation = 0.0
				velocity.y = 0.0
				_trigger_ground_impact()

		State.CARRIED:
			if is_instance_valid(carried_actor):
				world_pos = carried_actor.world_pos + Vector2(carried_offset.x, carried_offset.z)
				elevation = carried_actor.elevation + carried_offset.y

func _apply_camera() -> void:
	if camera == null:
		return

	# 1. Project Object Position in 2.5D space
	var p := camera.project(world_pos, elevation)
	position = p.pos
	var s := maxf(p.scale, 0.01) * base_scale
	core_circle.scale = Vector2(s, s)
	aura_circle.scale = Vector2(s, s) * (aura_circle.scale.x if state != State.PULSING else 1.0)
	pulse_ring.scale = Vector2(s, s)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25) + 3

	# 2. Project Ground Contact Shadow (always elevation = 0)
	var p_ground := camera.project(world_pos, 0.0)
	shadow.global_position = p_ground.pos
	var s_ground := maxf(p_ground.scale, 0.01) * base_scale
	# Shadow lifts: size shrinks and alpha decreases with elevation
	var lift_factor := clampf(1.0 - elevation / 260.0, 0.15, 1.0)
	shadow.scale = Vector2(s_ground, s_ground) * lift_factor
	shadow.color.a = 0.48 * lift_factor
	shadow.z_index = -int(clampf(p_ground.depth, -400.0, 4000.0) * 0.25) - 1

func _update_trail() -> void:
	if trail == null:
		return
	if state == State.FALLING or state == State.AIRBORNE_TRAJECTORY:
		trail.visible = true
		trail.add_point(position)
		if trail.get_point_count() > 14:
			trail.remove_point(0)
	else:
		if trail.get_point_count() > 0:
			trail.remove_point(0)
		else:
			trail.visible = false

func _update_shockwave(delta: float) -> void:
	if not _shockwave_active:
		return
	_shockwave_radius += 480.0 * delta
	var pts := PackedVector2Array()
	var steps := 32
	for i in range(steps + 1):
		var th := i * TAU / steps
		pts.append(Vector2(cos(th) * _shockwave_radius, sin(th) * _shockwave_radius * 0.42))
	shockwave_ring.points = pts
	var alpha := clampf(1.0 - _shockwave_radius / 360.0, 0.0, 1.0)
	shockwave_ring.default_color = Color(0.25, 0.95, 1.0, alpha * 0.85)
	if _shockwave_radius >= 360.0:
		_shockwave_active = false
		shockwave_ring.points = PackedVector2Array()

# --- Public Trajectory & State Control ---

func start_fall(start_pos: Vector2, start_elev: float, h_vel: Vector2 = Vector2.ZERO) -> void:
	world_pos = start_pos
	elevation = start_elev
	velocity = Vector3(h_vel.x, h_vel.y, -140.0)
	state = State.FALLING
	base_scale = 1.3
	label_container.visible = false

func catch_by(actor: Node2D, offset: Vector3 = Vector3(0, 0, 32.0)) -> void:
	carried_actor = actor
	carried_offset = offset
	state = State.CARRIED
	velocity = Vector3.ZERO
	trail.clear_points()

func throw_toward(target_pos: Vector2, target_elev: float, flight_time: float) -> void:
	carried_actor = null
	state = State.AIRBORNE_TRAJECTORY
	var dx := target_pos.x - world_pos.x
	var dz := target_pos.y - world_pos.y
	var de := target_elev - elevation
	# Parabolic throw: vy = de/t + 0.5 * g * t
	var g := 520.0
	velocity = Vector3(dx / flight_time, dz / flight_time, (de / flight_time) + 0.5 * g * flight_time)

func redirect(new_velocity: Vector3) -> void:
	state = State.AIRBORNE_TRAJECTORY
	velocity = new_velocity
	trajectory_changed.emit(Vector2(velocity.x, velocity.y))

func take_projectile_impact(impulse: Vector3) -> void:
	state = State.AIRBORNE_TRAJECTORY
	velocity += impulse
	trajectory_changed.emit(Vector2(velocity.x, velocity.z))

func _trigger_ground_impact() -> void:
	state = State.HOVERING
	hit_ground.emit(world_pos)
	_shockwave_active = true
	_shockwave_radius = 10.0
	shockwave_ring.global_position = position

func set_pulsing_warning(enabled: bool) -> void:
	is_pulsing = enabled
	state = State.PULSING if enabled else State.HOVERING

func shrink_to_tiny(duration: float = 1.2) -> void:
	state = State.TINY
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "base_scale", 0.42, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_delivery_complete() -> void:
	label_container.visible = true
	label_container.modulate.a = 0.0
	label_container.scale = Vector2(0.5, 0.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label_container, "modulate:a", 1.0, 0.4)
	tw.tween_property(label_container, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_delivery_complete() -> void:
	if label_container:
		label_container.visible = false
