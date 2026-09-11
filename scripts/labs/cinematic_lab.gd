extends Node2D

# ============================================================================
# CINEMATIC 2D/2.5D STAGING LAB (v2) — EXPERIMENTAL
# ----------------------------------------------------------------------------
# Proves/disproves: paper-cutout brawlers filmed inside a 3D-like cinematic
# spatial world (multi-view switching, camera-relative orientation, depth
# scale, ortho vs perspective, occlusion, projectile depth, close-ups).
# Production is untouched; everything here is lab-only.
# ============================================================================

const PropScript := preload("res://scripts/labs/cinematic_prop.gd")
const ProjectileScript := preload("res://scripts/labs/cinematic_projectile.gd")
const DUMMY_SCENE := "res://scenes/target_dummy.tscn"
const TEX_BO_ARROW := "res://assets/brawlers/bo/equipment/bo_arrow.svg"

@onready var camera: CinematicCamera = $CameraRig
@onready var leon: CinematicActor = $Leon
@onready var nita: CinematicActor = $Nita
@onready var bo: CinematicActor = $Bo
@onready var ground: ColorRect = $Ground
@onready var horizon_line: Line2D = $HorizonLine
@onready var lbl_mode: Label = $UI/Panel/VBox/LblMode
@onready var lbl_demo: Label = $UI/Panel/VBox/LblDemo

var props: Array = []
var dummies: Array = [] # {node, world_pos, radius}
var running := false
var current_test := ""
var auto := true

func _ready() -> void:
	_build_world()
	_setup_actors()
	if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
		get_tree().process_frame.connect(start_demo, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(start_demo, CONNECT_ONE_SHOT)

func _physics_process(_delta: float) -> void:
	_apply_horizon()
	_project_dummies()
	_update_ui()

# --- World construction (Part 33: deliberately simple) ----------------------

func _build_world() -> void:
	# props: door, crate, wall, table, pillar + one foreground blocker
	_make_prop("door", Vector2(-260, 260), 170.0, Color(0.55, 0.4, 0.24), "door")
	_make_prop("crate", Vector2(240, 210), 70.0, Color(0.62, 0.48, 0.3), "crate")
	_make_prop("wall", Vector2(-60, 420), 150.0, Color(0.4, 0.44, 0.55), "wall")
	_make_prop("table", Vector2(330, 330), 80.0, Color(0.5, 0.38, 0.26), "table")
	_make_prop("pillar", Vector2(480, 300), 190.0, Color(0.45, 0.5, 0.62), "pillar")
	_make_prop("fg_blocker", Vector2(120, -160), 240.0, Color(0.24, 0.22, 0.3), "pillar")
	# target dummies at three depths
	_make_dummy("dummy_near", Vector2(620, 120), 0.0)
	_make_dummy("dummy_mid", Vector2(560, 300), 0.0)
	_make_dummy("dummy_far", Vector2(480, 480), 0.0)

func _make_prop(prop_name: String, pos: Vector2, height: float, color: Color, kind: String) -> void:
	var root: CinematicProp = PropScript.new()
	root.name = prop_name
	add_child(root)
	root.setup(camera, pos, height, color)
	var body := Polygon2D.new()
	body.name = "Body"
	root.add_child(body)
	match kind:
		"door":
			body.polygon = PackedVector2Array([
				Vector2(-42, -height), Vector2(42, -height),
				Vector2(42, 0), Vector2(-42, 0)])
			body.color = color
			var knob := Polygon2D.new()
			knob.polygon = PackedVector2Array([Vector2(-4, -84), Vector2(8, -84), Vector2(8, -72), Vector2(-4, -72)])
			knob.color = Color(0.85, 0.72, 0.3)
			root.add_child(knob)
		"crate":
			body.polygon = PackedVector2Array([
				Vector2(-34, -height), Vector2(34, -height),
				Vector2(38, 0), Vector2(-38, 0)])
			body.color = color
			var band := Polygon2D.new()
			band.polygon = PackedVector2Array([Vector2(-34, -height * 0.55), Vector2(34, -height * 0.55), Vector2(36, -height * 0.4), Vector2(-36, -height * 0.4)])
			band.color = color.darkened(0.25)
			root.add_child(band)
		"wall":
			body.polygon = PackedVector2Array([
				Vector2(-160, -height), Vector2(160, -height),
				Vector2(160, 0), Vector2(-160, 0)])
			body.color = color
		"table":
			body.polygon = PackedVector2Array([
				Vector2(-70, -height), Vector2(70, -height),
				Vector2(70, -height + 14), Vector2(-70, -height + 14),
				Vector2(-70, 0), Vector2(-56, 0), Vector2(-56, -height + 14),
				Vector2(56, -height + 14), Vector2(56, 0), Vector2(70, 0)])
			body.color = color
		_:
			body.polygon = PackedVector2Array([
				Vector2(-26, -height), Vector2(26, -height),
				Vector2(34, 0), Vector2(-34, 0)])
			body.color = color
	props.append(root)

func _make_dummy(dummy_name: String, pos: Vector2, _elev: float) -> void:
	var packed: PackedScene = load(DUMMY_SCENE)
	var node := packed.instantiate()
	add_child(node)
	dummies.append({"node": node, "world_pos": pos, "radius": 40.0})
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").bind_target(node)

func _project_dummies() -> void:
	for d in dummies:
		var node: Node2D = d.node
		var p := camera.project(d.world_pos, 0.0)
		node.position = p.pos
		node.scale = Vector2.ONE * maxf(p.scale, 0.01)
		node.z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
		node.visible = p.visible

func _dummy_react(node: Node2D) -> void:
	if node.has_method("play_hit"):
		node.play_hit()
	elif node.has_method("hit"):
		node.hit()
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color(1.6, 0.7, 0.7), 0.06)
	tw.tween_property(node, "modulate", Color.WHITE, 0.25)

# --- Actors (Part 26/27: causal projectile spawn at RELEASE) ----------------

func _setup_actors() -> void:
	leon.setup(camera, Vector2(-120, 60), 0.0)
	nita.setup(camera, Vector2(120, 220), 20.0)
	bo.setup(camera, Vector2(-40, 400), 10.0)
	leon.attack_released.connect(_spawn_projectile.bind(leon, TEX_BO_ARROW, 460.0, 900.0))
	nita.attack_released.connect(_spawn_projectile.bind(nita, TEX_BO_ARROW, 500.0, 900.0))
	bo.attack_released.connect(_spawn_projectile.bind(bo, TEX_BO_ARROW, 560.0, 1000.0))

func _spawn_projectile(socket_world: Vector2, facing_deg: float, actor: CinematicActor,
		tex_path: String, speed: float, range_len: float) -> void:
	var proj: CinematicProjectile = ProjectileScript.new()
	proj.name = "Projectile"
	add_child(proj)
	var visual := Sprite2D.new()
	visual.name = "Visual"
	visual.texture = load(tex_path)
	proj.add_child(visual)
	# socket local (feet origin, art px) -> world (x, z, elevation)
	var local := actor.model.attack_socket_local()
	var f := deg_to_rad(facing_deg)
	var world_spawn := actor.world_pos + Vector2(cos(f), sin(f)) * local.x * 0.6
	var elev: float = -local.y
	proj.setup(camera, world_spawn, Vector2.from_angle(f), elev, speed, range_len, dummies)
	proj.hit_target.connect(_on_projectile_hit)

func _on_projectile_hit(target: Node2D) -> void:
	for d in dummies:
		if d.node == target:
			_dummy_react(target)
			return

# --- Camera helpers ---------------------------------------------------------

func cam_tween(props: Dictionary, dur: float) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for key in props:
		tw.tween_property(camera, key, props[key], dur)

## True orbit (Part 8): the camera POSITION travels an arc around the target
## while yawing to keep looking at it. a=-90 deg = default camera side.
func orbit_around(center: Vector2, radius: float, from_deg: float, to_deg: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_method(_orbit_step.bind(center, radius, from_deg, to_deg), 0.0, 1.0, dur)

func _orbit_step(t: float, center: Vector2, radius: float, a0: float, a1: float) -> void:
	var a := deg_to_rad(lerpf(a0, a1, t))
	camera.cam_x = center.x + cos(a) * radius
	camera.cam_z = center.y + sin(a) * radius
	var dir := center - Vector2(camera.cam_x, camera.cam_z)
	camera.yaw_deg = rad_to_deg(atan2(dir.x, dir.y))

func wait_sec(seconds: float) -> void:
	var frames := int(round(seconds * 60.0))
	for i in range(frames):
		await get_tree().process_frame

func _apply_horizon() -> void:
	var hy := camera.horizon_y + camera.pitch_deg * 2.2
	ground.position = Vector2(0, hy)
	ground.size = Vector2(1200, 660 - hy)
	horizon_line.points = PackedVector2Array([Vector2(-20, hy), Vector2(1200, hy)])
	horizon_line.position = Vector2.ZERO

func _update_ui() -> void:
	if lbl_mode:
		lbl_mode.text = "MODE: %s | yaw %.0f | zoom %.2f | pitch %.0f | h %.0f" % [
			"ORTHO" if camera.mode == CinematicCamera.ProjMode.ORTHO else "PERSPECTIVE",
			camera.yaw_deg, camera.zoom, camera.pitch_deg, camera.cam_height]
	if lbl_demo:
		lbl_demo.text = current_test

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()):
		return
	match event.keycode:
		KEY_1:
			camera.mode = CinematicCamera.ProjMode.ORTHO
		KEY_2:
			camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
		KEY_LEFT:
			camera.yaw_deg -= 10.0
		KEY_RIGHT:
			camera.yaw_deg += 10.0
		KEY_UP:
			camera.zoom = minf(camera.zoom + 0.1, 2.4)
		KEY_DOWN:
			camera.zoom = maxf(camera.zoom - 0.1, 0.5)
		KEY_SPACE:
			auto = not auto

# --- Demo timeline (deterministic, auto-cycling) ----------------------------

func start_demo() -> void:
	if running:
		return
	running = true
	_demo_sequence()

func _demo_sequence() -> void:
	await wait_sec(0.6)
	while true:
		if not auto:
			await wait_sec(0.5)
			continue
		await _test_orbit()
		await _test_character_rotation()
		await _test_both_rotation()
		await _test_ground_movement()
		await _test_depth_scale()
		await _test_environment_scale()
		await _test_occlusion()
		await _test_close_up()
		await _test_34_close_up()
		await _test_high_low()
		await _test_45deg()
		await _test_projection_compare()
		await _test_projectiles()
		await _test_crossing()
		await _test_cinematic_demo()

func _face_camera(a: CinematicActor) -> void:
	a.set_facing_deg(rad_to_deg((Vector2(camera.cam_x, camera.cam_z) - a.world_pos).angle()), true)

func _test_orbit() -> void:
	current_test = "TEST 1: CAMERA ORBIT AROUND LEON (front->3q->side->back)"
	camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
	leon.world_pos = Vector2(0, 120)
	leon.set_facing_deg(-90.0, true)
	nita.world_pos = Vector2(700, 520)
	bo.world_pos = Vector2(-640, 540)
	_face_camera(nita)
	_face_camera(bo)
	camera.cam_x = 0.0
	camera.cam_z = -160.0
	camera.yaw_deg = 0.0
	camera.zoom = 1.0
	camera.pitch_deg = 0.0
	camera.cam_height = 150.0
	await wait_sec(1.2)
	orbit_around(leon.world_pos, 280.0, -90.0, 270.0, 12.0)
	await wait_sec(12.4)
	orbit_around(leon.world_pos, 280.0, 270.0, -90.0, 12.0)
	await wait_sec(12.4)
	camera.yaw_deg = 0.0
	camera.cam_x = 0.0
	camera.cam_z = -160.0

func _test_character_rotation() -> void:
	current_test = "TEST 2: LEON ROTATES, CAMERA FIXED (front->3q->side->back->reverse)"
	camera.cam_x = 0.0
	camera.cam_z = -160.0
	camera.yaw_deg = 0.0
	camera.zoom = 1.1
	leon.world_pos = Vector2(0, 120)
	leon.set_facing_deg(-90.0, true)
	await wait_sec(0.8)
	var tw := create_tween()
	tw.tween_property(leon, "facing_deg", 90.0, 5.0)
	await wait_sec(5.2)
	var tw2 := create_tween()
	tw2.tween_property(leon, "facing_deg", -90.0, 5.0)
	await wait_sec(5.2)

func _test_both_rotation() -> void:
	current_test = "TEST 3: CAMERA + CHARACTER BOTH MOVE (relative angle stays correct)"
	leon.world_pos = Vector2(0, 120)
	leon.set_facing_deg(-90.0, true)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(camera, "yaw_deg", 120.0, 5.0)
	tw.tween_property(leon, "facing_deg", 30.0, 5.0)
	await wait_sec(5.2)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(camera, "yaw_deg", 0.0, 4.0)
	tw2.tween_property(leon, "facing_deg", -90.0, 4.0)
	await wait_sec(4.2)

func _test_ground_movement() -> void:
	current_test = "TEST 4: GROUND MOVEMENT (left/right/forward/back/diagonal)"
	camera.cam_x = 0.0
	camera.cam_z = -220.0
	camera.yaw_deg = 0.0
	camera.zoom = 1.0
	camera.pitch_deg = 0.0
	camera.cam_height = 150.0
	leon.world_pos = Vector2(0, 150)
	leon.set_facing_deg(-90.0, true)
	_face_camera(nita)
	nita.world_pos = Vector2(680, 520)
	bo.world_pos = Vector2(-680, 540)
	_face_camera(bo)
	await wait_sec(0.8)
	leon.walk_to(Vector2(260, 150), 170.0)
	await wait_sec(2.6)
	leon.walk_to(Vector2(-160, 320), 170.0)
	await wait_sec(2.8)
	leon.walk_to(Vector2(60, 40), 170.0)
	await wait_sec(2.8)
	leon.walk_to(Vector2(0, 150), 170.0)
	await wait_sec(2.4)
	_face_camera(leon)
	await wait_sec(0.8)

func _test_depth_scale() -> void:
	current_test = "TEST 5: DEPTH SCALE — each brawler near / mid / far"
	leon.world_pos = Vector2(-200, 480)
	nita.world_pos = Vector2(0, 480)
	bo.world_pos = Vector2(200, 480)
	leon.set_facing_deg(-90.0, true)
	nita.set_facing_deg(-90.0, true)
	bo.set_facing_deg(-90.0, true)
	camera.cam_x = 0.0
	camera.cam_z = -260.0
	camera.yaw_deg = 0.0
	camera.zoom = 0.95
	await wait_sec(1.0)
	for depth in [420.0, 240.0, 40.0]:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(leon, "world_pos", Vector2(-200, depth), 1.6)
		tw.tween_property(nita, "world_pos", Vector2(0, depth), 1.6)
		tw.tween_property(bo, "world_pos", Vector2(200, depth), 1.6)
		await wait_sec(2.2)

func _test_environment_scale() -> void:
	current_test = "TEST 6: ENVIRONMENT SCALE (door / crate / table / pillar)"
	camera.cam_x = 0.0
	camera.cam_z = -300.0
	camera.yaw_deg = 0.0
	camera.zoom = 0.9
	leon.world_pos = Vector2(-330, 260)
	_face_camera(leon)
	nita.world_pos = Vector2(305, 330)
	_face_camera(nita)
	bo.world_pos = Vector2(180, 210)
	_face_camera(bo)
	await wait_sec(3.4)
	camera.zoom = 1.25
	await wait_sec(2.4)

func _test_occlusion() -> void:
	current_test = "TEST 7: OCCLUSION — behind / in front of pillar, crate, wall"
	camera.cam_x = 0.0
	camera.cam_z = -300.0
	camera.yaw_deg = 0.0
	camera.zoom = 1.0
	leon.world_pos = Vector2(380, 180)
	_face_camera(leon)
	nita.world_pos = Vector2(300, 80)
	_face_camera(nita)
	bo.world_pos = Vector2(-200, 300)
	_face_camera(bo)
	await wait_sec(0.8)
	leon.walk_to(Vector2(560, 300), 130.0)
	await wait_sec(2.6)
	leon.walk_to(Vector2(400, 180), 130.0)
	nita.walk_to(Vector2(160, 210), 130.0)
	await wait_sec(2.6)
	nita.walk_to(Vector2(300, 80), 130.0)
	bo.walk_to(Vector2(60, 420), 130.0)
	await wait_sec(2.8)
	bo.walk_to(Vector2(-200, 300), 130.0)
	await wait_sec(2.6)

func _test_close_up() -> void:
	current_test = "TEST 8: CLOSE-UP — wide -> medium -> close -> extreme (Leon face)"
	camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
	leon.world_pos = Vector2(0, 150)
	leon.set_facing_deg(-90.0, true)
	nita.world_pos = Vector2(700, 540)
	bo.world_pos = Vector2(-700, 540)
	_face_camera(nita)
	_face_camera(bo)
	camera.cam_x = 0.0
	camera.cam_z = -300.0
	camera.yaw_deg = 0.0
	camera.zoom = 0.85
	camera.pitch_deg = 0.0
	camera.cam_height = 150.0
	await wait_sec(1.0)
	cam_tween({"cam_z": -80.0, "zoom": 1.15}, 2.0)
	await wait_sec(2.2)
	cam_tween({"cam_z": 40.0, "zoom": 1.7, "cam_height": 120.0}, 2.2)
	await wait_sec(2.4)
	cam_tween({"cam_z": 100.0, "zoom": 2.4, "cam_height": 108.0}, 2.0)
	await wait_sec(2.2)

func _test_34_close_up() -> void:
	current_test = "TEST 9: 3/4 CLOSE-UP — frontal -> 3/4 -> side near Leon's face"
	camera.cam_z = 80.0
	camera.cam_x = 0.0
	camera.zoom = 2.1
	camera.cam_height = 110.0
	leon.set_facing_deg(-90.0, true)
	await wait_sec(1.0)
	cam_tween({"yaw_deg": 40.0}, 2.4)
	await wait_sec(2.6)
	cam_tween({"yaw_deg": 90.0}, 2.4)
	await wait_sec(2.6)
	cam_tween({"yaw_deg": 0.0, "zoom": 1.0, "cam_height": 150.0, "cam_z": -300.0}, 2.0)
	await wait_sec(2.2)

func _test_high_low() -> void:
	current_test = "TEST 10: HIGH ANGLE / LOW ANGLE"
	leon.world_pos = Vector2(0, 120)
	leon.set_facing_deg(-90.0, true)
	camera.cam_x = 0.0
	camera.cam_z = -220.0
	camera.yaw_deg = 0.0
	camera.zoom = 1.1
	await wait_sec(0.8)
	cam_tween({"pitch_deg": 24.0, "cam_height": 300.0}, 2.2)
	await wait_sec(2.4)
	cam_tween({"pitch_deg": -16.0, "cam_height": 60.0}, 2.2)
	await wait_sec(2.4)
	cam_tween({"pitch_deg": 0.0, "cam_height": 150.0}, 1.8)
	await wait_sec(2.0)

func _test_45deg() -> void:
	current_test = "TEST 11: 45-DEGREE SHOT — Leon near / Nita mid / Bo far"
	camera.yaw_deg = 45.0
	camera.zoom = 0.95
	camera.pitch_deg = 0.0
	camera.cam_height = 150.0
	leon.world_pos = Vector2(60, 60)
	nita.world_pos = Vector2(180, 280)
	bo.world_pos = Vector2(300, 500)
	_face_camera(leon)
	_face_camera(nita)
	_face_camera(bo)
	await wait_sec(3.6)
	camera.yaw_deg = 0.0
	await wait_sec(0.8)

func _test_projection_compare() -> void:
	current_test = "TEST 12: ORTHOGRAPHIC vs PERSPECTIVE (same framing)"
	camera.cam_x = 0.0
	camera.cam_z = -320.0
	camera.yaw_deg = 0.0
	camera.zoom = 0.9
	leon.world_pos = Vector2(-170, 80)
	nita.world_pos = Vector2(0, 260)
	bo.world_pos = Vector2(170, 460)
	_face_camera(leon)
	_face_camera(nita)
	_face_camera(bo)
	camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
	await wait_sec(2.6)
	camera.mode = CinematicCamera.ProjMode.ORTHO
	await wait_sec(2.6)
	camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
	await wait_sec(0.6)

func _test_projectiles() -> void:
	current_test = "TEST 13: PROJECTILE DEPTH + CAUSALITY (attack->release->hit)"
	camera.cam_x = 0.0
	camera.cam_z = -300.0
	camera.yaw_deg = 0.0
	camera.zoom = 1.0
	leon.world_pos = Vector2(200, 40)
	leon.set_facing_deg(0.0, true) # faces +x toward the dummy line
	bo.world_pos = Vector2(320, 500)
	bo.set_facing_deg(180.0, true) # faces -x toward the near dummy
	await wait_sec(0.8)
	leon.attack()
	await wait_sec(1.6)
	bo.attack()
	await wait_sec(2.4)
	leon.attack()
	await wait_sec(2.2)

func _test_crossing() -> void:
	current_test = "TEST 14: CROSSING IN DEPTH (order updates naturally)"
	camera.cam_x = 0.0
	camera.cam_z = -320.0
	camera.yaw_deg = 0.0
	camera.zoom = 0.9
	leon.world_pos = Vector2(-220, 60)
	leon.set_facing_deg(45.0, true)
	nita.world_pos = Vector2(-260, 480)
	nita.set_facing_deg(-45.0, true)
	bo.world_pos = Vector2(260, 260)
	_face_camera(bo)
	await wait_sec(0.8)
	leon.walk_to(Vector2(240, 480), 150.0)
	nita.walk_to(Vector2(260, 60), 170.0)
	await wait_sec(3.4)
	bo.walk_to(Vector2(-260, 260), 140.0)
	await wait_sec(3.0)
	leon.walk_to(Vector2(-220, 60), 150.0)
	nita.walk_to(Vector2(-260, 480), 170.0)
	bo.walk_to(Vector2(260, 260), 140.0)
	await wait_sec(4.0)

func _test_cinematic_demo() -> void:
	current_test = "TEST 15: CINEMATIC SHOT DEMO (Part 34)"
	# 1. wide shot
	camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
	camera.cam_x = 0.0
	camera.cam_z = -360.0
	camera.yaw_deg = 0.0
	camera.zoom = 0.8
	camera.pitch_deg = 0.0
	camera.cam_height = 160.0
	leon.world_pos = Vector2(-140, 140)
	_face_camera(leon)
	nita.world_pos = Vector2(560, 520)
	bo.world_pos = Vector2(-560, 560)
	_face_camera(nita)
	_face_camera(bo)
	await wait_sec(2.0)
	# 2-4. dolly toward Leon, view change, close-up
	leon.set_facing_deg(-90.0, true)
	cam_tween({"cam_z": 40.0, "zoom": 1.9, "cam_height": 120.0, "cam_x": -140.0}, 3.0)
	await wait_sec(3.2)
	# 5-6. lateral move -> side view transition
	cam_tween({"yaw_deg": 70.0, "zoom": 2.0}, 2.6)
	await wait_sec(2.8)
	# 7. pull back
	cam_tween({"yaw_deg": 0.0, "cam_z": -360.0, "zoom": 0.8, "cam_height": 160.0, "cam_x": 0.0}, 2.6)
	await wait_sec(2.8)
	# 8-9. Nita enters from background, approaches foreground
	nita.world_pos = Vector2(240, 620)
	nita.set_facing_deg(-100.0, true)
	nita.walk_to(Vector2(210, 80), 190.0)
	await wait_sec(3.2)
	# 10. Bo crosses through the scene
	bo.world_pos = Vector2(-520, 300)
	bo.set_facing_deg(0.0, true)
	bo.walk_to(Vector2(560, 260), 200.0)
	await wait_sec(3.4)
	# 11-13. all three at depths, one projectile through depth, fg occlusion
	leon.world_pos = Vector2(-160, 200)
	_face_camera(leon)
	nita.world_pos = Vector2(210, 120)
	_face_camera(nita)
	bo.world_pos = Vector2(500, 480)
	bo.set_facing_deg(180.0, true)
	leon.attack()
	await wait_sec(2.4)
	nita.walk_to(Vector2(80, -120), 160.0)
	await wait_sec(2.2)
	nita.walk_to(Vector2(210, 120), 160.0)
	await wait_sec(1.6)
	# 14. final wide
	cam_tween({"zoom": 0.78, "cam_z": -400.0}, 2.0)
	await wait_sec(2.4)
