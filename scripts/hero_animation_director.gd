extends Node2D
class_name HeroAnimationDirector

# ============================================================================
# HERO ANIMATION DIRECTOR — 2D / 2.5D MASTER HERO ANIMATION TEST
# ----------------------------------------------------------------------------
# Authoritative Production Standard:
# docs/CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md
# docs/CINEMATIC_ANIMATION_CONTRACT.md
# docs/CINEMATIC_ANIMATION_CHECKLIST.md
# docs/CINEMATIC_2D_2_5D_QUICK_REFERENCE.md
#
# FEATURING: LEON + NITA + BO
#
# 7-Beat Structured Cinematic Sequence (~26 seconds):
# Beat 1 (0.0s - 2.5s)   : Wide Spatial Staging (Near/Mid/Far, Ground, Sky)
# Beat 2 (2.5s - 7.5s)   : Continuous Depth Locomotion & Full Multi-View Orbit
#                          (Front -> 3/4 -> Side -> Back 3/4 -> Back -> Return)
# Beat 3 (7.5s - 11.5s)  : 2.5D Camera Push-In & Close-Up Character Acting
# Beat 4 (11.5s - 15.0s) : Action Transition & Bo's Multi-Depth Causal Arrow
# Beat 5 (15.0s - 18.5s) : Nita's Midground Attack & Reposition
# Beat 6 (18.5s - 23.0s) : Leon's Foreground Occlusion, Attack & Tactical Super
# Beat 7 (23.0s - 26.0s) : Settle & Final Heroic 2.5D Panoramic Composition
# ============================================================================

const PropScript := preload("res://scripts/hero_prop.gd")
const ProjectileScript := preload("res://scripts/hero_projectile.gd")
const DUMMY_SCENE := "res://scenes/target_dummy.tscn"

const BGM_TRACK := "res://assets/audio/bgm/brawlcade_ingame_02.ogg"
const SFX_LEON_ATK := "res://assets/audio/sfx/leon/leon_atk_01.ogg"
const SFX_NITA_ATK := "res://assets/audio/sfx/nita/nita_atk_01.ogg"
const SFX_BO_ATK := "res://assets/audio/sfx/bo/bo_atk_01.ogg"
const SFX_LEON_INVIS := "res://assets/audio/sfx/leon/leon_invis_01.ogg"
const SFX_LEON_INVIS_END := "res://assets/audio/sfx/leon/leon_invis_end_01.ogg"
const SFX_LAND := "res://assets/audio/sfx/common/princess_land_01.ogg"

@onready var camera: CinematicCamera = $CameraRig
@onready var sky: ColorRect = $World/Sky
@onready var ground_far: Polygon2D = $World/GroundFar
@onready var ground_mid: Polygon2D = $World/GroundMid
@onready var ground_near: Polygon2D = $World/GroundNear
@onready var horizon_line: Line2D = $World/HorizonLine
@onready var depth_lines_container: Node2D = $World/DepthLines

@onready var leon: CinematicActor = $Characters/Leon
@onready var nita: CinematicActor = $Characters/Nita
@onready var bo: CinematicActor = $Characters/Bo

@onready var bgm_player: AudioStreamPlayer = $Audio/BGMPlayer
@onready var sfx_leon: AudioStreamPlayer = $Audio/SFXLeon
@onready var sfx_nita: AudioStreamPlayer = $Audio/SFXNita
@onready var sfx_bo: AudioStreamPlayer = $Audio/SFXBo
@onready var sfx_common: AudioStreamPlayer = $Audio/SFXCommon

@onready var review_overlay: ColorRect = $UI/ReviewOverlay

var props: Array = []
var target_crate: Node2D = null
var fg_pillar: Node2D = null
var dummy_data: Dictionary = {}

var is_running: bool = false
var elapsed_time: float = 0.0
var auto_quit_duration: float = 26.0
var review_mode: String = "none" # "none", "silhouette", "grayscale"

# Perspective grid depth lines
var _grid_lines: Array[Line2D] = []

func _ready() -> void:
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
		elif arg.begins_with("--review-mode="):
			review_mode = arg.trim_prefix("--review-mode=")

	_setup_world()
	_setup_actors()
	_setup_audio()
	_setup_review_mode()

	if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
		get_tree().process_frame.connect(start_sequence, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(start_sequence, CONNECT_ONE_SHOT)

func _physics_process(delta: float) -> void:
	if is_running:
		elapsed_time += delta
		if auto_quit_duration > 0.0 and elapsed_time >= auto_quit_duration:
			print("[AUTO-QUIT] Hero Animation Test finished at %.2fs" % elapsed_time)
			get_tree().quit(0)

	_update_horizon_and_ground()
	_update_dummy_projection()

# ============================================================================
# WORLD & ENVIRONMENT SETUP (Parts 1, 2, 3, 56, 57)
# ============================================================================

func _setup_world() -> void:
	# 1. Clean Blue Sky
	sky.color = Color(0.35, 0.65, 0.94, 1.0) # Vibrant, clean blue sky

	# 2. Layered Ground Planes (Distant, Midground, Near Ground)
	ground_far.color = Color(0.20, 0.52, 0.19, 1.0) # Distant horizon green
	ground_mid.color = Color(0.24, 0.62, 0.22, 1.0) # Field midground green
	ground_near.color = Color(0.28, 0.72, 0.25, 1.0) # Warm foreground green

	# 3. Perspective Depth Markers (converging lines proving the spatial plane)
	for i in range(9):
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(0.18, 0.48, 0.16, 0.38)
		depth_lines_container.add_child(line)
		_grid_lines.append(line)

	# 4. Spatial Props (Parts 3, 16, 17, 20, 22)
	# FG Occlusion Pillar (Z = 0, positioned directly in front of Leon's lane)
	fg_pillar = _create_prop("pillar", Vector2(-320, 0), "pillar", 1.3)

	# Midground Target Crate (Z = 240, target for Bo's multi-depth arrow)
	target_crate = _create_prop("crate", Vector2(240, 240), "crate", 1.25)
	target_crate.is_destructible = true

	# Background Rock (Z = 480, establishing deep ground plane left)
	_create_prop("rock", Vector2(-500, 480), "rock", 1.3)

	# Midground Signpost (Z = 180, spatial marker far left)
	_create_prop("sign", Vector2(-540, 180), "sign", 1.0)

	# Distant Green Bush (Z = 460, depth marker far right)
	_create_prop("bush", Vector2(520, 460), "bush", 1.2)

	# 5. Target Dummy (Z = 220, reactive target for Nita's attack)
	_setup_dummy(Vector2(120, 220))

func _create_prop(p_name: String, pos: Vector2, kind: String, scale_factor: float) -> Node2D:
	var prop: Node2D = PropScript.new()
	prop.name = p_name
	$World/Props.add_child(prop)
	prop.setup(camera, pos, kind, scale_factor)
	props.append(prop)
	return prop

func _setup_dummy(pos: Vector2) -> void:
	var packed: PackedScene = load(DUMMY_SCENE)
	var node := packed.instantiate()
	$World/Dummies.add_child(node)
	dummy_data = {"node": node, "world_pos": pos, "radius": 42.0}
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").bind_target(node)

func _update_dummy_projection() -> void:
	if not dummy_data.is_empty():
		var node: Node2D = dummy_data.node
		if is_instance_valid(node):
			var p := camera.project(dummy_data.world_pos, 0.0)
			node.position = p.pos
			node.scale = Vector2.ONE * maxf(p.scale, 0.01) * 0.92
			node.z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
			node.visible = p.visible

func _update_horizon_and_ground() -> void:
	var hy := camera.horizon_y + camera.pitch_deg * 2.2
	sky.position = Vector2(0, 0)
	sky.size = Vector2(1200, hy + 2)

	# Distant ground band (horizon to +70px)
	var d1 := hy + 70.0
	ground_far.polygon = PackedVector2Array([
		Vector2(-40, hy), Vector2(1240, hy),
		Vector2(1240, d1), Vector2(-40, d1)
	])

	# Midground band (+70px to +180px)
	var d2 := hy + 180.0
	ground_mid.polygon = PackedVector2Array([
		Vector2(-40, d1), Vector2(1240, d1),
		Vector2(1240, d2), Vector2(-40, d2)
	])

	# Near ground band (+180px to bottom)
	ground_near.polygon = PackedVector2Array([
		Vector2(-40, d2), Vector2(1240, d2),
		Vector2(1240, 720), Vector2(-40, 720)
	])

	horizon_line.points = PackedVector2Array([Vector2(-40, hy), Vector2(1240, hy)])

	# Dynamic perspective ground lines radiating from vanishing point
	var cx := camera.screen_center_x - camera.cam_x * 0.4
	var offsets := [-600.0, -450.0, -300.0, -150.0, 0.0, 150.0, 300.0, 450.0, 600.0]
	for i in range(min(_grid_lines.size(), offsets.size())):
		var line: Line2D = _grid_lines[i]
		var bottom_x = cx + offsets[i] * 1.85
		var top_x = cx + offsets[i] * 0.08
		line.points = PackedVector2Array([Vector2(top_x, hy), Vector2(bottom_x, 720)])

# ============================================================================
# ACTORS SETUP (Leon, Nita, Bo)
# ============================================================================

func _setup_actors() -> void:
	# Clear spatial starting separation (Part 4):
	# LEON: Foreground-Left (X = -260, Z = 40)
	leon.setup(camera, Vector2(-260, 40), -45.0)

	# NITA: Midground-Center (X = -40, Z = 220)
	nita.setup(camera, Vector2(-40, 220), -90.0)

	# BO: Background-Right (X = 360, Z = 440)
	bo.setup(camera, Vector2(360, 440), -90.0)

	# Connect attack release events to authoritative projectile spawners
	leon.attack_released.connect(_on_leon_attack_released)
	nita.attack_released.connect(_on_nita_attack_released)
	bo.attack_released.connect(_on_bo_attack_released)

func _setup_audio() -> void:
	if ResourceLoader.exists(BGM_TRACK):
		bgm_player.stream = load(BGM_TRACK)
		bgm_player.volume_db = -11.0 # Balanced underneath SFX

	sfx_leon.stream = load(SFX_LEON_ATK)
	sfx_nita.stream = load(SFX_NITA_ATK)
	sfx_bo.stream = load(SFX_BO_ATK)
	sfx_common.stream = load(SFX_LAND)

func _setup_review_mode() -> void:
	if review_overlay == null:
		return
	if review_mode == "none":
		review_overlay.visible = false
		return
	elif review_mode == "muted":
		review_overlay.visible = false
		AudioServer.set_bus_mute(0, true)
		return

	review_overlay.visible = true
	var mat := ShaderMaterial.new()
	var code := ""
	if review_mode == "silhouette":
		code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
		void fragment() {
			vec4 c = texture(screen_texture, SCREEN_UV);
			float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
			COLOR = l > 0.42 ? vec4(1.0, 1.0, 1.0, 1.0) : vec4(0.0, 0.0, 0.0, 1.0);
		}
		"""
	elif review_mode == "grayscale":
		code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
		void fragment() {
			vec4 c = texture(screen_texture, SCREEN_UV);
			float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
			COLOR = vec4(vec3(l), c.a);
		}
		"""
	elif review_mode == "spatial":
		code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
		void fragment() {
			vec4 c = texture(screen_texture, SCREEN_UV);
			float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
			// Cyan tinted spatial analysis with enhanced contrast
			vec3 tint = vec3(0.2, 0.75, 0.95);
			COLOR = vec4(mix(vec3(l), tint, 0.28), c.a);
		}
		"""
	var shader := Shader.new()
	shader.code = code
	mat.shader = shader
	review_overlay.material = mat

# ============================================================================
# CINEMATIC TIMELINE EXECUTION (7-BEAT SEQUENCE)
# ============================================================================

func start_sequence() -> void:
	is_running = true
	if bgm_player.stream and review_mode != "muted":
		bgm_player.play()

	print("[HERO TEST] Starting 7-Beat Cinematic Sequence...")

	# --- BEAT 1: Wide Spatial Staging (0.0s - 3.5s) ---
	camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
	camera.cam_x = 0.0
	camera.cam_z = -180.0
	camera.yaw_deg = 0.0
	camera.zoom = 1.0
	camera.pitch_deg = 0.0
	camera.cam_height = 140.0

	_face_camera(leon)
	_face_camera(nita)
	_face_camera(bo)
	await wait_sec(3.2)

	# --- BEAT 2: Spatial Locomotion & Full Multi-View Turnaround (3.5s - 7.5s) ---
	# Leon walks diagonally forward-right: Z goes from 40 -> 20
	# Angle smoothly shifts through Front -> Front 3/4 -> Side
	leon.walk_to(Vector2(-160, 20), 80.0)

	# Bo paces across the background
	bo.walk_to(Vector2(280, 440), 60.0)

	# Subtle parallax camera motion
	cam_tween({"cam_x": -40.0, "yaw_deg": 5.0}, 2.5)
	await wait_sec(1.4)

	# Multi-view turnaround: Leon shows Back 3/4 -> Back
	leon.set_facing_deg(150.0)
	await wait_sec(0.8)
	leon.set_facing_deg(180.0)
	await wait_sec(0.8)

	# Bo turns away from camera, showing his approved Back view
	bo.set_facing_deg(90.0)
	await wait_sec(0.5)

	# Nita turns to Front 3/4
	nita.set_facing_deg(-45.0)
	await wait_sec(0.5)

	# --- BEAT 3: 2.5D Camera Push-In & Close-Up Acting (7.5s - 11.5s) ---
	# Camera smoothly dollies in front of Leon into close-up
	leon.stop()
	cam_tween({"cam_z": -70.0, "cam_x": -160.0, "zoom": 2.15, "cam_height": 85.0, "yaw_deg": 0.0}, 1.4)
	await wait_sec(1.4)
	_face_camera(leon) # Faces straight into camera lens!
	await wait_sec(0.2)

	# Facial Acting Performance on Leon (Part 11)
	_trigger_leon_blink()
	await wait_sec(0.3)
	# Pupils dart toward distant target
	_set_leon_pupils(Vector2(5, -2))
	await wait_sec(0.3)
	# Detects threat: shock / alert expression!
	_set_leon_expression("shocked")
	await wait_sec(0.7)
	# Confident smile / smug readiness
	_set_leon_pupils(Vector2(0, 0))
	_set_leon_expression("smug")
	await wait_sec(0.9)

	# --- BEAT 4: Action Transition & Bo's Multi-Depth Causal Arrow (11.5s - 15.0s) ---
	# Camera pulls back to action-readable framing
	cam_tween({"cam_z": -180.0, "cam_x": 0.0, "zoom": 1.0, "cam_height": 140.0, "yaw_deg": 0.0}, 1.2)
	_set_leon_expression("neutral")
	await wait_sec(1.2)

	# Bo loads bow and fires from background (Z=440) toward midground crate (Z=240)
	bo.set_facing_deg(-140.0, true)
	await wait_sec(0.3)
	bo.attack()
	await wait_sec(1.8)

	# --- BEAT 5: Nita's Midground Attack & Reposition (15.0s - 18.5s) ---
	# Nita reacts to arrow impact, repositions, aims at TargetDummy
	nita.walk_to(Vector2(-10, 220), 120.0)
	await wait_sec(0.6)
	nita.set_facing_deg(0.0, true)
	nita.attack()
	await wait_sec(2.2)

	# --- BEAT 6: Leon's Occlusion, Attack & Super Ability (18.5s - 22.5s) ---
	# Leon runs across foreground behind the tall stone pillar (Z=0)
	# Leon is at Z=20, pillar is at Z=0, so pillar completely occludes him!
	leon.walk_to(Vector2(-340, 20), 220.0)
	await wait_sec(1.0) # Passes behind pillar, occluded

	# Leon activates Super (Invisibility):
	_trigger_leon_super_start()
	await wait_sec(0.3)
	# Flanks across depth to center-left while invisible (unblocking Nita!)
	leon.walk_to(Vector2(-70, 50), 200.0)
	await wait_sec(1.4)
	# Reappears in dramatic heroic stance!
	_trigger_leon_super_end()
	await wait_sec(0.3)
	leon.stop()
	leon.set_facing_deg(0.0, true)
	leon.attack() # Spinner blade attack
	await wait_sec(1.0)

	# --- BEAT 7: Settle & Final Heroic 2.5D Composition (22.5s - 26.0s) ---
	# All three settle into distinct heroic depth poses (Golden Triangle)
	cam_tween({"cam_z": -200.0, "cam_x": 0.0, "zoom": 0.98, "cam_height": 142.0}, 1.4)
	leon.set_facing_deg(-90.0, true)
	_set_leon_expression("happy")

	nita.walk_to(Vector2(-220, 220), 140.0)
	await wait_sec(0.6)
	nita.set_facing_deg(-75.0, true)

	bo.walk_to(Vector2(240, 420), 100.0)
	await wait_sec(0.4)
	bo.set_facing_deg(-105.0, true)

	var tw_bgm := create_tween()
	tw_bgm.tween_property(bgm_player, "volume_db", -18.0, 1.8)
	await wait_sec(1.0)

	print("[HERO TEST] Sequence successfully completed!")

# ============================================================================
# PROJECTILE SPAWNERS & ATTACK CAUSALITY
# ============================================================================

func _on_leon_attack_released(socket_world: Vector2, facing_deg: float) -> void:
	sfx_leon.play()
	var targets := []
	if not dummy_data.is_empty():
		targets.append(dummy_data)
	if target_crate:
		targets.append({"node": target_crate, "world_pos": target_crate.world_pos, "radius": 36.0})

	var dir := Vector2.from_angle(deg_to_rad(facing_deg))
	_spawn_hero_projectile("leon", socket_world, dir, 32.0, 540.0, 950.0, targets)

func _on_nita_attack_released(socket_world: Vector2, facing_deg: float) -> void:
	sfx_nita.play()
	var targets := []
	if not dummy_data.is_empty():
		targets.append(dummy_data)

	var dir := Vector2.from_angle(deg_to_rad(facing_deg))
	_spawn_hero_projectile("nita", socket_world, dir, 20.0, 480.0, 900.0, targets)

func _on_bo_attack_released(socket_world: Vector2, facing_deg: float) -> void:
	sfx_bo.play()
	var targets := []
	if target_crate:
		targets.append({"node": target_crate, "world_pos": target_crate.world_pos, "radius": 40.0})

	# Bo fires diagonally forward-left toward the crate in midground!
	var to_crate = (target_crate.world_pos - bo.world_pos).normalized()
	_spawn_hero_projectile("bo", socket_world, to_crate, 40.0, 560.0, 1100.0, targets)

func _spawn_hero_projectile(
	kind: String,
	_socket: Vector2,
	dir: Vector2,
	elev: float,
	speed: float,
	rng: float,
	targets: Array
) -> void:
	var proj: Node2D = ProjectileScript.new()
	proj.name = "Projectile_" + kind.capitalize()
	$Projectiles.add_child(proj)

	var actor: CinematicActor = leon if kind == "leon" else (nita if kind == "nita" else bo)
	var spawn_world := actor.world_pos + dir * 18.0
	proj.setup(camera, spawn_world, dir, elev, kind, speed, rng, targets)
	proj.hit_target.connect(_on_projectile_impact)

func _on_projectile_impact(_target: Node2D) -> void:
	# Subtle BGM ducking for punchy impact emphasis
	_duck_bgm(0.25)
	sfx_common.play()

func _duck_bgm(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(bgm_player, "volume_db", -15.0, 0.05)
	tw.tween_interval(duration)
	tw.tween_property(bgm_player, "volume_db", -11.0, 0.25)

# ============================================================================
# LEON SUPER ABILITY (TACTICAL INVISIBILITY)
# ============================================================================

func _trigger_leon_super_start() -> void:
	sfx_leon.stream = load(SFX_LEON_INVIS)
	sfx_leon.play()
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SMOKE_BOMB", leon.position, self)

	# Modulate to 0.08 ghost outline
	var tw := create_tween().set_parallel(true)
	tw.tween_property(leon.model, "modulate:a", 0.08, 0.22)
	tw.tween_property(leon.shadow, "modulate:a", 0.12, 0.22)
	_set_leon_expression("smug")

func _trigger_leon_super_end() -> void:
	sfx_leon.stream = load(SFX_LEON_INVIS_END)
	sfx_leon.play()
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SMOKE_BOMB", leon.position, self)

	# Restore full opacity
	var tw := create_tween().set_parallel(true)
	tw.tween_property(leon.model, "modulate:a", 1.0, 0.18)
	tw.tween_property(leon.shadow, "modulate:a", 0.42, 0.18)

# ============================================================================
# FACE SYSTEM HELPERS (LEON)
# ============================================================================

func _set_leon_expression(expr: String) -> void:
	var face = leon.model.get_node_or_null("ViewFront/Head/Face")
	if face and face.has_method("set_expression"):
		face.set_expression(expr)

func _set_leon_pupils(offset: Vector2) -> void:
	var pl = leon.model.get_node_or_null("ViewFront/Head/Face/EyeL/PupilL")
	var pr = leon.model.get_node_or_null("ViewFront/Head/Face/EyeR/PupilR")
	if pl and pr:
		pl.position = Vector2(2, 0) + offset
		pr.position = Vector2(2, 0) + offset

func _trigger_leon_blink() -> void:
	var face = leon.model.get_node_or_null("ViewFront/Head/Face")
	if face and face.has_method("_trigger_blink"):
		face._trigger_blink()

# ============================================================================
# UTILITIES
# ============================================================================

func _face_camera(actor: CinematicActor) -> void:
	var to_cam = Vector2(camera.cam_x, camera.cam_z) - actor.world_pos
	actor.set_facing_deg(rad_to_deg(to_cam.angle()), true)

func cam_tween(props_dict: Dictionary, dur: float) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for key in props_dict:
		tw.tween_property(camera, key, props_dict[key], dur)

func wait_sec(seconds: float) -> void:
	var frames := int(round(seconds * 60.0))
	for i in range(frames):
		await get_tree().process_frame
