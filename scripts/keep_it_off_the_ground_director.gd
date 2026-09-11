extends Node2D
class_name KeepItOffTheGroundDirector

# ============================================================================
# "KEEP IT OFF THE GROUND" — 2D/2.5D ANIMATED SHORT DIRECTOR
# ----------------------------------------------------------------------------
# Master Production Standard:
# docs/CINEMATIC_2D_2_5D_ANIMATION_BIBLE.md
# docs/CINEMATIC_ANIMATION_CONTRACT.md
# docs/CINEMATIC_ANIMATION_CHECKLIST.md
# docs/CINEMATIC_2D_2_5D_QUICK_REFERENCE.md
#
# FEATURING: LEON + NITA + BO + MYSTERIOUS GLOWING OBJECT
#
# 28 Narrative Beats (~46.5 Seconds):
# Sequence 1 (0.0s - 6.0s)   : Wide Staging, Celestial Descent & Bo's Catch (Beats 1-4)
# Sequence 2 (6.0s - 14.5s)  : Erratic Flight, First Ground Shockwave & Alarm (Beats 5-11)
# Sequence 3 (14.5s - 17.5s) : Three Targets Reveal & Strategic Objective (Beats 12-13)
# Sequence 4 (17.5s - 25.5s) : Teamwork: Bo Arrow & Nita Redirects (Beats 14-16)
# Sequence 5 (25.5s - 30.0s) : Multi-View Camera Orbit around Leon & Close-Up 1 (Beats 17-18)
# Sequence 6 (30.0s - 34.5s) : Escalation & Nita's Desperate Airborne Jump (Beats 19-20)
# Sequence 7 (34.5s - 42.5s) : Leon's Tactical Super, Target 3 Burst & Calm (Beats 21-24)
# Sequence 8 (42.5s - 46.5s) : Delivery Complete, The Warning Glow & Comedic Drop (Beats 25-28)
# ============================================================================

const PropScript := preload("res://scripts/hero_prop.gd")
const ProjectileScript := preload("res://scripts/hero_projectile.gd")
const TargetScript := preload("res://scripts/cinematic_target.gd")
const ObjectScript := preload("res://scripts/mysterious_object.gd")

const BGM_TRACK := "res://assets/audio/bgm/brawlcade_ingame_02.ogg"
const SFX_LEON_ATK := "res://assets/audio/sfx/leon/leon_atk_01.ogg"
const SFX_LEON_INVIS := "res://assets/audio/sfx/leon/leon_invis_01.ogg"
const SFX_LEON_INVIS_END := "res://assets/audio/sfx/leon/leon_invis_end_01.ogg"
const SFX_NITA_ATK := "res://assets/audio/sfx/nita/nita_atk_01.ogg"
const SFX_BO_ATK := "res://assets/audio/sfx/bo/bo_atk_01.ogg"
const SFX_JUMP := "res://assets/audio/sfx/common/jump.ogg"
const SFX_LAND := "res://assets/audio/sfx/common/princess_land_01.ogg"
const SFX_WHOOSH := "res://assets/audio/sfx/elevator/elevator_whoosh.wav"
const SFX_SHOCKWAVE := "res://assets/audio/sfx/elevator/elevator_jolt.wav"
const SFX_DING := "res://assets/audio/sfx/elevator/elevator_ding.wav"
const SFX_GLOW := "res://assets/audio/sfx/elevator/light_flicker.wav"

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
@onready var sfx_object: AudioStreamPlayer = $Audio/SFXObject
@onready var sfx_common: AudioStreamPlayer = $Audio/SFXCommon

@onready var review_overlay: ColorRect = $UI/ReviewOverlay

var mysterious_object: Node2D = null
var target_1: Node2D = null
var target_2: Node2D = null
var target_3: Node2D = null
var fg_pillar: Node2D = null

var is_running: bool = false
var elapsed_time: float = 0.0
var auto_quit_duration: float = 48.0
var review_mode: String = "none" # "none", "muted", "silhouette", "grayscale", "spatial"

var _grid_lines: Array[Line2D] = []

func _ready() -> void:
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
		elif arg.begins_with("--review-mode="):
			review_mode = arg.trim_prefix("--review-mode=")

	_setup_world()
	_setup_actors()
	_setup_targets_and_object()
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
			print("[AUTO-QUIT] 'Keep It Off The Ground' finished at %.2fs" % elapsed_time)
			get_tree().quit(0)

	_update_horizon_and_ground()
	_update_actor_eyelines()

# ============================================================================
# WORLD SETUP
# ============================================================================

func _setup_world() -> void:
	sky.color = Color(0.35, 0.65, 0.94, 1.0) # Vibrant blue sky
	ground_far.color = Color(0.20, 0.52, 0.19, 1.0)
	ground_mid.color = Color(0.24, 0.62, 0.22, 1.0)
	ground_near.color = Color(0.28, 0.72, 0.25, 1.0)

	for i in range(9):
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(0.18, 0.48, 0.16, 0.38)
		depth_lines_container.add_child(line)
		_grid_lines.append(line)

	# Foreground Pillar for Occlusion (Z = 0)
	# z_as_relative = false so pillar draws ABOVE characters behind it
	fg_pillar = _create_prop("pillar", Vector2(-320, 0), "pillar", 1.35)
	fg_pillar.z_as_relative = false
	fg_pillar.z_index = 500  # Always in front of anything at positive depth
	fg_pillar.force_foreground = true

	# Background Depth Props
	_create_prop("rock", Vector2(-520, 480), "rock", 1.3)
	_create_prop("sign", Vector2(-540, 180), "sign", 1.0)
	_create_prop("bush", Vector2(520, 460), "bush", 1.2)

func _create_prop(p_name: String, pos: Vector2, kind: String, scale_factor: float) -> Node2D:
	var prop: Node2D = PropScript.new()
	prop.name = p_name
	$World/Props.add_child(prop)
	prop.setup(camera, pos, kind, scale_factor)
	return prop

func _setup_targets_and_object() -> void:
	# 3 Distant Horizon Targets
	target_1 = TargetScript.new()
	target_1.name = "Target1"
	$World/Targets.add_child(target_1)
	target_1.setup(camera, Vector2(-360, 520), 1, Color(0.2, 0.9, 1.0, 1.0))
	target_1.modulate.a = 0.0 # Reveals after ground impact

	target_2 = TargetScript.new()
	target_2.name = "Target2"
	$World/Targets.add_child(target_2)
	target_2.setup(camera, Vector2(0, 560), 2, Color(1.0, 0.85, 0.2, 1.0))
	target_2.modulate.a = 0.0

	target_3 = TargetScript.new()
	target_3.name = "Target3"
	$World/Targets.add_child(target_3)
	target_3.setup(camera, Vector2(360, 500), 3, Color(0.9, 0.3, 1.0, 1.0))
	target_3.modulate.a = 0.0

	# Mysterious Glowing Object
	mysterious_object = ObjectScript.new()
	mysterious_object.name = "MysteriousObject"
	$World.add_child(mysterious_object)
	mysterious_object.setup(camera, Vector2(240, 320), 500.0)
	mysterious_object.visible = false

func _setup_actors() -> void:
	# Diagonal Staging (Bible Part 4 & Prompt):
	# Leon: foreground-left (X = -260, Z = 40)
	leon.setup(camera, Vector2(-260, 40), -45.0)

	# Nita: midground-center (X = -40, Z = 220)
	nita.setup(camera, Vector2(-40, 220), -90.0)

	# Bo: background-right (X = 360, Z = 440)
	bo.setup(camera, Vector2(360, 440), -90.0)

	leon.attack_released.connect(_on_leon_attack_released)
	nita.attack_released.connect(_on_nita_attack_released)
	bo.attack_released.connect(_on_bo_attack_released)

func _setup_audio() -> void:
	if ResourceLoader.exists(BGM_TRACK):
		bgm_player.stream = load(BGM_TRACK)
		bgm_player.volume_db = -10.0

	sfx_leon.stream = load(SFX_LEON_ATK)
	sfx_nita.stream = load(SFX_NITA_ATK)
	sfx_bo.stream = load(SFX_BO_ATK)
	sfx_common.stream = load(SFX_LAND)
	sfx_object.stream = load(SFX_WHOOSH)

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
			COLOR = vec4(mix(vec3(l), vec3(0.2, 0.75, 0.95), 0.28), c.a);
		}
		"""
	var shader := Shader.new()
	shader.code = code
	mat.shader = shader
	review_overlay.material = mat

func _update_horizon_and_ground() -> void:
	var hy := camera.horizon_y + camera.pitch_deg * 2.2
	sky.position = Vector2(0, 0)
	sky.size = Vector2(1200, hy + 2)

	var d1 := hy + 70.0
	ground_far.polygon = PackedVector2Array([
		Vector2(-40, hy), Vector2(1240, hy),
		Vector2(1240, d1), Vector2(-40, d1)
	])

	var d2 := hy + 180.0
	ground_mid.polygon = PackedVector2Array([
		Vector2(-40, d1), Vector2(1240, d1),
		Vector2(1240, d2), Vector2(-40, d2)
	])

	ground_near.polygon = PackedVector2Array([
		Vector2(-40, d2), Vector2(1240, d2),
		Vector2(1240, 720), Vector2(-40, 720)
	])

	horizon_line.points = PackedVector2Array([Vector2(-40, hy), Vector2(1240, hy)])

	var cx := camera.screen_center_x - camera.cam_x * 0.4
	var offsets := [-600.0, -450.0, -300.0, -150.0, 0.0, 150.0, 300.0, 450.0, 600.0]
	for i in range(min(_grid_lines.size(), offsets.size())):
		var line: Line2D = _grid_lines[i]
		var bottom_x = cx + offsets[i] * 1.85
		var top_x = cx + offsets[i] * 0.08
		line.points = PackedVector2Array([Vector2(top_x, hy), Vector2(bottom_x, 720)])

func _update_actor_eyelines() -> void:
	if mysterious_object and mysterious_object.visible:
		var obj_pos: Vector2 = mysterious_object.world_pos
		var dir_to_obj: Vector2 = (obj_pos - leon.world_pos).normalized()
		_set_leon_pupils(Vector2(dir_to_obj.x * 4.0, dir_to_obj.y * -2.0))

# ============================================================================
# CINEMATIC 28-BEAT TIMELINE ORCHESTRATION
# ============================================================================

func start_sequence() -> void:
	is_running = true
	if bgm_player.stream and review_mode != "muted":
		bgm_player.play()

	print("[FILM START] 'KEEP IT OFF THE GROUND' Production Short Beginning...")

	# ------------------------------------------------------------------------
	# SEQUENCE 1: WIDE INTRO & CELESTIAL DESCENT (Beats 1-4, 0.0s - 7.0s)
	# ------------------------------------------------------------------------
	# Beat 1: Wide Spatial Staging (Leon Near-L, Nita Mid-C, Bo Far-R)
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
	await wait_sec(3.2)  # +0.4s: Let the world breathe, establish spatial relationships

	# Beat 2: Glowing Object Enters from Sky
	mysterious_object.visible = true
	mysterious_object.start_fall(Vector2(240, 320), 440.0, Vector2(-15.0, -10.0))
	_play_sfx(sfx_object, SFX_WHOOSH)
	await wait_sec(1.0)  # +0.2s: Give the fall more time to travel

	# Beat 3: Bo Spots It, Anticipates & Runs to Catch
	bo.walk_to(Vector2(230, 315), 180.0)
	await wait_sec(1.4)  # +0.2s: More readable run

	# Beat 4: Bo Catches Object Cleanly
	mysterious_object.catch_by(bo, Vector3(0, 0, 32.0))
	_play_sfx(sfx_common, SFX_LAND)
	_camera_shake(1.5, 0.2)
	await wait_sec(1.0)  # +0.2s: Catch settle

	# ------------------------------------------------------------------------
	# SEQUENCE 2: UNPREDICTABLE BEHAVIOR & FIRST SHOCKWAVE (Beats 5-11, 7.0s - 15.5s)
	# ------------------------------------------------------------------------
	# Beat 5: Object Vibrates & Pulses Strangely; Leon Concerned
	_play_sfx(sfx_object, SFX_GLOW)
	mysterious_object.set_pulsing_warning(true)
	_set_leon_expression("confused")
	await wait_sec(1.5)  # +0.3s: Hold on the strange behavior for tension

	# Beat 6: Bo Throws Object Away Deep into Horizon
	mysterious_object.set_pulsing_warning(false)
	mysterious_object.throw_toward(Vector2(140, 520), 120.0, 1.6)
	_play_sfx(sfx_object, SFX_WHOOSH)
	await wait_sec(1.6)  # +0.2s: Longer flight

	# Beat 7: Object Reverses Trajectory & Returns (eerie)
	mysterious_object.throw_toward(Vector2(-10, 220), 40.0, 1.5)
	_play_sfx(sfx_object, SFX_WHOOSH)
	await wait_sec(1.5)  # +0.3s: Give return path more time

	# Beat 8: Nita Steps In & Catches It
	nita.walk_to(Vector2(-10, 220), 140.0)
	await wait_sec(0.4)  # +0.1s
	mysterious_object.catch_by(nita, Vector3(0, 0, 28.0))
	_play_sfx(sfx_common, SFX_LAND)
	_set_nita_expression("happy")
	await wait_sec(1.2)  # +0.2s: Hold on Nita's excitement

	# Beat 9: Object Shakes; Nita Throws Toward Leon
	mysterious_object.throw_toward(Vector2(-240, 45), 20.0, 1.1)
	_play_sfx(sfx_object, SFX_WHOOSH)
	await wait_sec(0.8)  # +0.2s

	# Beat 10: Leon Dodges Aside! Object Crashes Into Ground!
	leon.walk_to(Vector2(-310, 45), 240.0) # Leon dives left!
	_set_leon_expression("shocked")
	await wait_sec(0.6)  # +0.1s

	# Beat 11: Ground Impact Shockwave Event!
	_trigger_ground_impact_event(Vector2(-220, 45))
	await wait_sec(1.8)  # +0.3s: Let the shockwave ring expand fully

	# ------------------------------------------------------------------------
	# SEQUENCE 3: TARGET REVEAL & STRATEGIC OBJECTIVE (Beats 12-13, 15.5s - 19.0s)
	# ------------------------------------------------------------------------
	# Beat 12: Three Distant Targets Manifest on Horizon
	_reveal_targets()
	_play_sfx(sfx_object, SFX_DING)
	mysterious_object.start_fall(Vector2(-220, 45), 10.0, Vector2(10.0, 20.0))
	mysterious_object.elevation = 42.0 # Rebounds into airborne hover
	mysterious_object.state = ObjectScript.State.HOVERING
	await wait_sec(1.8)  # +0.4s: Let the targets sink in

	# Beat 13: Trio Realizes Objective (Keep Airborne & Deliver)
	_set_leon_expression("smug")
	_set_nita_expression("grin")
	await wait_sec(1.5)  # +0.3s: Hold the reaction moment

	# ------------------------------------------------------------------------
	# SEQUENCE 4: TEAMWORK REDIRECTIONS (Beats 14-16, 17.5s - 25.5s)
	# ------------------------------------------------------------------------
	# Beat 14: Object floats toward midground. Bo takes aim.
	mysterious_object.throw_toward(Vector2(60, 320), 48.0, 1.6)
	bo.set_facing_deg(-135.0, true)
	await wait_sec(0.8)

	# Beat 15: Bo Fires Arrow -> Visible Travel -> Collision -> Target 1
	bo.attack()
	await wait_sec(1.8)

	# Object redirects toward Target 1 and activates it!
	target_1.trigger_completion()
	_play_sfx(sfx_object, SFX_DING)
	_duck_bgm(0.3)
	await wait_sec(0.8)

	# Beat 16: Object ricochets toward center. Nita unleashes shockwave attack!
	mysterious_object.throw_toward(Vector2(-40, 240), 45.0, 1.4)
	nita.walk_to(Vector2(-60, 240), 160.0)
	await wait_sec(0.6)
	nita.set_facing_deg(20.0, true)
	nita.attack()
	await wait_sec(1.8)

	# ------------------------------------------------------------------------
	# SEQUENCE 5: MULTI-VIEW CAMERA ORBIT & CLOSE-UP 1 (Beats 17-18, 25.5s - 30.0s)
	# ------------------------------------------------------------------------
	# Beat 17: Leon runs diagonally forward-right underneath trajectory
	leon.walk_to(Vector2(-140, 30), 160.0)

	# Beat 18: Camera orbits around Leon: Front -> Front-3/4 -> Side
	cam_tween({"cam_x": -140.0, "cam_z": -90.0, "yaw_deg": 40.0, "zoom": 1.45, "cam_height": 105.0}, 2.0)
	await wait_sec(2.0)

	# Close-Up 1 on Leon's face reacting to the orb
	cam_tween({"zoom": 2.15, "cam_z": -65.0, "cam_height": 85.0}, 1.0)
	await wait_sec(1.0)
	_set_leon_expression("confused")
	_trigger_leon_blink()
	await wait_sec(0.8)

	# ------------------------------------------------------------------------
	# SEQUENCE 6: ESCALATION & NITA'S DESPERATE JUMP (Beats 19-20, 30.0s - 34.5s)
	# ------------------------------------------------------------------------
	# Beat 19: Object accelerates downward steeply; Leon stresses!
	cam_tween({"zoom": 1.0, "cam_x": 0.0, "cam_z": -180.0, "yaw_deg": 0.0, "cam_height": 140.0}, 1.0)
	_set_leon_expression("shocked")
	mysterious_object.throw_toward(Vector2(20, 240), 10.0, 1.6) # falling to ground!
	await wait_sec(0.6)

	# Beat 20: Nita's Desperate Jump: Anticipation -> Launch -> Intercept -> Land
	await _animate_nita_desperate_jump()
	# Nita saves it and redirects to Target 2!
	mysterious_object.throw_toward(Vector2(0, 560), 60.0, 1.4)
	await wait_sec(1.4)
	target_2.trigger_completion()
	_play_sfx(sfx_object, SFX_DING)
	_duck_bgm(0.3)
	await wait_sec(0.6)

	# ------------------------------------------------------------------------
	# SEQUENCE 7: LEON TACTICAL SUPER & FINAL TARGET BURST (Beats 21-24, 35.0s - 43.0s)
	# ------------------------------------------------------------------------
	# Beat 21: Object rebounds right ($X=280, Z=140$), falling rapidly. Leon uses Super!
	mysterious_object.throw_toward(Vector2(260, 120), 12.0, 2.4)

	# Leon activates Invisibility Super
	_trigger_leon_super_start()
	await wait_sec(0.4)  # +0.1s: Hold on the dramatic cloak

	# Leon runs across foreground, occluded by tall stone pillar at Z=0
	# Route: Leon walks toward pillar (Z=0) so he passes behind it at close depth
	leon.walk_to(Vector2(-320, 5), 240.0)  # passes behind pillar at Z ≈ 0
	await wait_sec(0.8)  # +0.1s
	leon.walk_to(Vector2(180, 100), 280.0) # fast invisible dash across scene
	await wait_sec(1.4)  # +0.2s: Let the traversal breathe

	# Leon decloaks at right flank and redirects object toward Target 3!
	_trigger_leon_super_end()
	leon.set_facing_deg(35.0, true)
	leon.attack()
	await wait_sec(0.5)  # +0.1s

	mysterious_object.throw_toward(Vector2(360, 500), 55.0, 1.8)
	await wait_sec(1.8)  # +0.3s: Longer flight to target 3

	# Beat 22 & 23: Target 3 Impact & Energy Burst!
	target_3.trigger_completion()
	_trigger_final_energy_burst(Vector2(360, 500))
	_play_sfx(sfx_object, SFX_SHOCKWAVE)
	_camera_shake(3.2, 0.4)

	# Beat 24: False Resolution & Calm
	var tw_calm := create_tween()
	tw_calm.tween_property(bgm_player, "volume_db", -24.0, 1.2)
	_set_leon_expression("happy")
	_set_nita_expression("happy")
	await wait_sec(2.6)  # +0.4s: Let the calm fully settle

	# ------------------------------------------------------------------------
	# SEQUENCE 8: DELIVERY COMPLETE & THE FINAL JOKE (Beats 25-28, 43.0s - 48.0s)
	# ------------------------------------------------------------------------
	# Reset camera to mid-wide framing for the denouement
	cam_tween({"cam_x": -20.0, "cam_z": -120.0, "yaw_deg": 0.0, "zoom": 1.15, "cam_height": 125.0}, 0.8)

	# Beat 25: Object drops to ground, shrinks to tiny handheld size
	mysterious_object.throw_toward(Vector2(0, 120), 0.0, 1.2)
	await wait_sec(1.2)  # +0.2s
	mysterious_object.shrink_to_tiny(0.8)
	await wait_sec(1.0)  # +0.2s: Watch it shrink

	# Beat 26: Leon picks it up; Displays "DELIVERY COMPLETE"
	leon.walk_to(Vector2(0, 120), 120.0)
	await wait_sec(0.8)  # +0.2s
	mysterious_object.catch_by(leon, Vector3(0, 0, 24.0))
	mysterious_object.show_delivery_complete()
	_play_sfx(sfx_object, SFX_DING)
	_set_leon_expression("smug")
	await wait_sec(1.2)  # +0.2s: Hold on the reveal

	# Beat 27: Object suddenly starts pulsing/glowing ominously! Close-Up 2 on Leon!
	cam_tween({"cam_x": 0.0, "cam_z": 40.0, "zoom": 2.2, "cam_height": 75.0}, 0.5)
	_play_sfx(sfx_object, SFX_GLOW)
	mysterious_object.set_pulsing_warning(true)
	await wait_sec(0.5)  # +0.1s

	# Leon's horrified reaction
	_set_leon_expression("shocked")
	await wait_sec(1.0)  # +0.2s: Hold the horror

	# Beat 28: Leon looks at Nita; Nita smiles innocently; Leon drops it!
	_set_leon_pupils(Vector2(-5, 0)) # looks sideways toward Nita
	_set_nita_expression("grin")
	await wait_sec(0.8)  # +0.2s: Hold the look

	# Leon drops the orb!
	mysterious_object.catch_by(null)
	mysterious_object.elevation = 0.0
	_play_sfx(sfx_common, SFX_LAND)
	await wait_sec(0.4)  # +0.1s

	# HARD CUT TO BLACK!
	_hard_cut_to_black()
	await wait_sec(1.0)  # +0.2s: Hold on black before auto-quit

	print("[FILM END] 'KEEP IT OFF THE GROUND' Successfully Completed!")

# ============================================================================
# ACTION & PROJECTILE CAUSALITY
# ============================================================================

func _on_leon_attack_released(socket_world: Vector2, facing_deg: float) -> void:
	sfx_leon.play()
	var targets := []
	if mysterious_object:
		targets.append({"node": mysterious_object, "world_pos": mysterious_object.world_pos, "radius": 40.0})

	var dir := Vector2.from_angle(deg_to_rad(facing_deg))
	_spawn_projectile("leon", socket_world, dir, 32.0, 560.0, 950.0, targets)

func _on_nita_attack_released(socket_world: Vector2, facing_deg: float) -> void:
	sfx_nita.play()
	var targets := []
	if mysterious_object:
		targets.append({"node": mysterious_object, "world_pos": mysterious_object.world_pos, "radius": 42.0})

	var dir := Vector2.from_angle(deg_to_rad(facing_deg))
	_spawn_projectile("nita", socket_world, dir, 24.0, 480.0, 900.0, targets)

func _on_bo_attack_released(socket_world: Vector2, _facing_deg: float) -> void:
	sfx_bo.play()
	var targets := []
	if mysterious_object:
		targets.append({"node": mysterious_object, "world_pos": mysterious_object.world_pos, "radius": 44.0})

	# Bo aims precisely at the mysterious object
	var obj_pos: Vector2 = mysterious_object.world_pos
	var to_obj: Vector2 = (obj_pos - bo.world_pos).normalized()
	_spawn_projectile("bo", socket_world, to_obj, 36.0, 580.0, 1200.0, targets)

func _spawn_projectile(
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
	proj.hit_target.connect(_on_projectile_hit)

func _on_projectile_hit(_target: Node2D) -> void:
	_duck_bgm(0.22)
	sfx_common.play()

# ============================================================================
# NITA'S DESPERATE JUMP HELPER (Classical Principles: Anticipation, Arc, Settle)
# ============================================================================

func _animate_nita_desperate_jump() -> void:
	# 1. Anticipation: Crouch compression
	var active_nita = nita.model.active_node()
	if active_nita:
		var tw_crouch := create_tween()
		tw_crouch.tween_property(active_nita, "scale:y", 0.82, 0.18)
		tw_crouch.tween_property(active_nita, "scale:x", 1.18, 0.18)
	await wait_sec(0.18)

	# 2. Explosive Launch & Parabolic Arc
	_play_sfx(sfx_common, SFX_JUMP)
	if active_nita:
		active_nita.scale = Vector2(0.88, 1.22)

	var tw_jump := create_tween().set_parallel(true)
	tw_jump.tween_property(nita, "elevation", 72.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_jump.tween_property(nita, "world_pos:x", 15.0, 0.9)
	tw_jump.tween_property(nita, "world_pos:y", 240.0, 0.9)
	tw_jump.chain().tween_property(nita, "elevation", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await wait_sec(0.45) # Apex reached!

	# Mid-air strike: spawn hit impact
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("HIT_IMPACT", nita.position, self)
	sfx_common.play()
	await wait_sec(0.45) # Descend & contact ground!

	# 3. Landing Settle & Absorption
	_play_sfx(sfx_common, SFX_LAND)
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("DUST_PUFF", nita.position, self)
	if active_nita:
		var tw_land := create_tween()
		tw_land.tween_property(active_nita, "scale", Vector2(1.24, 0.76), 0.1)
		tw_land.tween_property(active_nita, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	await wait_sec(0.32)

# ============================================================================
# LEON SUPER ABILITY (TACTICAL INVISIBILITY TRAVERSAL)
# ============================================================================

func _trigger_leon_super_start() -> void:
	sfx_leon.stream = load(SFX_LEON_INVIS)
	sfx_leon.play()
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SMOKE_BOMB", leon.position, self)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(leon.model, "modulate:a", 0.08, 0.22)
	tw.tween_property(leon.shadow, "modulate:a", 0.12, 0.22)
	_set_leon_expression("smug")

func _trigger_leon_super_end() -> void:
	sfx_leon.stream = load(SFX_LEON_INVIS_END)
	sfx_leon.play()
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SMOKE_BOMB", leon.position, self)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(leon.model, "modulate:a", 1.0, 0.18)
	tw.tween_property(leon.shadow, "modulate:a", 0.42, 0.18)

# ============================================================================
# ENVIRONMENTAL EVENTS & SHOCKWAVE
# ============================================================================

func _trigger_ground_impact_event(pos_world: Vector2) -> void:
	_play_sfx(sfx_object, SFX_SHOCKWAVE)
	_camera_shake(2.8, 0.35)
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("HIT_IMPACT", mysterious_object.position, self)
		get_tree().root.get_node("VFXManager").spawn_vfx("DUST_PUFF", mysterious_object.position, self)

	# Atmospheric sky shift
	var tw_sky := create_tween()
	tw_sky.tween_property(sky, "color", Color(0.55, 0.35, 0.75, 1.0), 0.1)
	tw_sky.tween_property(sky, "color", Color(0.35, 0.65, 0.94, 1.0), 0.6)

func _reveal_targets() -> void:
	target_1.activate_beacon()
	target_2.activate_beacon()
	target_3.activate_beacon()

func _trigger_final_energy_burst(pos_world: Vector2) -> void:
	if get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SPAWN_FLASH", target_3.position, self)
		get_tree().root.get_node("VFXManager").spawn_vfx("HIT_IMPACT", target_3.position, self)

func _hard_cut_to_black() -> void:
	var black_screen := ColorRect.new()
	black_screen.name = "BlackScreen"
	black_screen.color = Color.BLACK
	# Use actual viewport size to guarantee full coverage
	var vp_size := get_viewport().get_visible_rect().size
	black_screen.size = vp_size + Vector2(100, 100)  # overscan safety
	black_screen.position = Vector2(-50, -50)
	black_screen.z_index = 4000
	black_screen.z_as_relative = false
	add_child(black_screen)
	# Fade BGM out gracefully instead of hard stop
	var tw := create_tween()
	tw.tween_property(bgm_player, "volume_db", -60.0, 0.3)
	tw.tween_callback(bgm_player.stop)

# ============================================================================
# FACIAL & EYELINE HELPERS
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

func _set_nita_expression(expr: String) -> void:
	var face = nita.model.get_node_or_null("ViewFront/Head/Face")
	if face and face.has_method("set_expression"):
		face.set_expression(expr)

# ============================================================================
# UTILITIES
# ============================================================================

func _face_camera(actor: CinematicActor) -> void:
	var to_cam = Vector2(camera.cam_x, camera.cam_z) - actor.world_pos
	actor.set_facing_deg(rad_to_deg(to_cam.angle()), true)

func _camera_shake(intensity: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(camera, "pitch_deg", intensity, duration * 0.25)
	tw.tween_property(camera, "pitch_deg", -intensity * 0.75, duration * 0.35)
	tw.tween_property(camera, "pitch_deg", 0.0, duration * 0.4)

func cam_tween(props_dict: Dictionary, dur: float) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for key in props_dict:
		tw.tween_property(camera, key, props_dict[key], dur)

func _duck_bgm(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(bgm_player, "volume_db", -16.0, 0.05)
	tw.tween_interval(duration)
	tw.tween_property(bgm_player, "volume_db", -10.0, 0.25)

func _play_sfx(player: AudioStreamPlayer, path: String) -> void:
	if ResourceLoader.exists(path):
		player.stream = load(path)
		player.play()

func wait_sec(seconds: float) -> void:
	var frames := int(round(seconds * 60.0))
	for i in range(frames):
		await get_tree().process_frame
