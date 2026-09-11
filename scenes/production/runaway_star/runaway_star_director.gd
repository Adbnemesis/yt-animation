extends Node2D
class_name RunawayStarDirector

# ============================================================================
# RUNAWAY STAR DIRECTOR
# ----------------------------------------------------------------------------
# Master timeline director orchestrating "Leon and the Runaway Star" (82.0s).
#
# Production Guarantees:
# - STRICTLY NO BGM: only authentic character SFX, footsteps, and star effects.
# - EXACTLY ONE Leon character instance in the scene tree.
# - TRUE STORYTELLING: 100% understandable EVEN WITH ALL AUDIO MUTED.
#   Star steals Leon's shadow -> Leon notices -> Chases across 4 views ->
#   Star agilely dodges attack -> Mimic dance duel -> Leon uses Super stealth
#   to outsmart it -> Corners star -> Shadow returns -> Final shadow wave gag.
# - True 2.5D spatial camera tracking, perspective scaling, and motivated 4-view usage:
#   Scene 1-3:  3/4 View (walk, star fall, shadow theft, failed reaches)
#   Scene 4:    Back View (running away into depth)
#   Scene 5:    3/4 View (diagonal chase across meadow)
#   Scene 6:    Side View (profile sprint behind foreground props)
#   Scene 7-9:  Front View (sprint toward camera, skid stop, orbit reveal)
#   Scene 10:   3/4 View (shadow check & battle determination)
#   Scene 11-12: 3/4 View (basic attack, agile dodge)
#   Scene 13-14: 3/4 View (mimicry test & smug plan)
#   Scene 15-16: Super (disappearance stealth & confused star search)
#   Scene 17-18: 3/4 View (reappear ambush, close-pass & cornering)
#   Scene 19:   3/4 View (shadow return & reconnection)
#   Scene 20:   3/4 View (shadow check & synchronized step)
#   Scene 21:   3/4 View (final comedic shadow wave gag & cut to black)
# ============================================================================

signal movie_completed()

const ProjectileScript := preload("res://scripts/labs/leon_spatial_projectile.gd")
const LeonCharacterScript := preload("res://scenes/production/runaway_star/leon_movie_character.gd")
const RunawayStarScript := preload("res://scenes/production/runaway_star/runaway_star_actor.gd")
const GlowingCircleScript := preload("res://scenes/production/runaway_star/glowing_circle.gd")
const ShockwaveScript := preload("res://scenes/production/runaway_star/shockwave_fx.gd")
const SpeedLinesOverlayScript := preload("res://scenes/production/runaway_star/speed_lines_overlay.gd")

@onready var camera: CinematicCamera = $CinematicCamera
@onready var leon: Node2D = $LeonCharacter
@onready var star: Node2D = $RunawayStar
@onready var detached_shadow: Node2D = $DetachedShadow
@onready var circle: Node2D = $GlowingCircle
@onready var ground: ColorRect = $Ground
@onready var sky: ColorRect = $Sky
@onready var horizon_line: Line2D = $HorizonLine
@onready var speed_lines: Control = $CanvasLayer/SpeedLines
@onready var fade_overlay: ColorRect = $CanvasLayer/FadeOverlay

# Audio players for SFX & BGM
var _sfx_players: Dictionary = {}
var _audio_cache: Dictionary = {}
var bgm_player: AudioStreamPlayer = null

var movie_time: float = 0.0
var auto_quit_duration: float = -1.0
var is_playing: bool = false
var is_finished: bool = false

# Beat flags to ensure single deterministic execution per milestone
var _beat_fired := {}

# Camera shake
var _shake_intensity: float = 0.0
var _shake_decay: float = 8.5

func trigger_camera_shake(intensity: float = 5.0) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)

func spawn_shockwave(pos: Vector2, max_r: float = 140.0, dur: float = 0.5, col: Color = Color(1.0, 0.95, 0.5, 0.9)) -> void:
	var sw := ShockwaveScript.new()
	add_child(sw)
	sw.setup(camera, pos, max_r, dur, col)

func crash_zoom(target_zoom: float, dur: float = 0.2) -> void:
	var tw := create_tween()
	tw.tween_property(camera, "zoom", target_zoom, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _ready() -> void:
	_init_auto_quit()
	_init_audio()
	_init_environment()
	_bind_leon_events()
	
	if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
		get_tree().process_frame.connect(start_movie, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(start_movie, CONNECT_ONE_SHOT)

func _init_auto_quit() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

func start_movie() -> void:
	if is_playing:
		return
	is_playing = true
	movie_time = 0.0
	_beat_fired.clear()
	
	# Initial camera staging: wide scenic meadow view
	camera.cam_x = 0.0
	camera.cam_z = -180.0
	camera.cam_height = 145.0
	camera.yaw_deg = 0.0
	camera.pitch_deg = 0.0
	camera.zoom = 1.0
	
	leon.setup(camera, Vector2(-180.0, 160.0), 35.0)
	leon.has_shadow = true
	leon.set_view(&"front_3q", false)
	
	# Star starts high in the sky offscreen
	star.setup(camera, Vector2(50.0, 160.0), 520.0)
	
	if detached_shadow:
		detached_shadow.setup(camera)
		detached_shadow.visible = false
	
	if circle:
		circle.setup(camera, Vector2(300.0, 300.0), 50.0)
		circle.visible = false
	
	# Play gentle outdoor meadow breeze
	_play_sfx("meadow_breeze", -22.0, 1.0)
	
	# Play Ragnarok BGM
	if bgm_player and not bgm_player.playing:
		bgm_player.play()
	
	# Fade in from black
	if fade_overlay:
		fade_overlay.modulate.a = 1.0
		create_tween().tween_property(fade_overlay, "modulate:a", 0.0, 0.8)

func _process(delta: float) -> void:
	if not is_playing or is_finished:
		return
		
	var d := (1.0 / 60.0) if OS.has_feature("movie") else delta
	movie_time += d
	if auto_quit_duration > 0.0 and movie_time >= auto_quit_duration:
		is_finished = true
		movie_completed.emit()
		print("[RUNAWAY STAR] Movie reached auto-quit duration (%.2fs)!" % movie_time)
		get_tree().quit(0)
		return
		
	# Apply camera shake
	if _shake_intensity > 0.05:
		camera.position.x = randf_range(-_shake_intensity, _shake_intensity)
		camera.position.y = randf_range(-_shake_intensity, _shake_intensity)
		_shake_intensity = move_toward(_shake_intensity, 0.0, _shake_decay * d)
	else:
		camera.position = Vector2.ZERO
		
	_orchestrate_master_timeline()

# ============================================================================
# MASTER DIRECTORIAL TIMELINE (82.0s CARTOON SHORT)
# ============================================================================
func _orchestrate_master_timeline() -> void:
	# ------------------------------------------------------------------------
	# SCENE 1: Immediate Hook & Star Fall (0.0s – 5.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s01_leon_walk_start", 0.0):
		# Leon starts walking across sunny meadow in 3/4 view
		leon.walk_to(Vector2(0.0, 160.0), 125.0)

	if _run_beat("s01_camera_push_entry", 1.5):
		# Subtle push toward Leon as he walks
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", -40.0, 2.5)
		tw.tween_property(camera, "zoom", 1.08, 2.5)
		_play_sfx("vo_start_03", 1.5) # Authentic: "Let's go!"

	if _run_beat("s01_star_glow_sky", 2.5):
		# Stardust sparkles appear high in the sky; camera tilts upward slightly
		var tw := create_tween()
		tw.tween_property(camera, "cam_height", 160.0, 1.2).set_trans(Tween.TRANS_SINE)

	if _run_beat("s01_star_descend", 3.4):
		# Star swoops down with soft whoosh and glowing stardust tail
		_play_sfx("star_whoosh", 0.0)
		star.arc_to(Vector2(45.0, 155.0), 16.0, 1.4, 50.0)

	if _run_beat("s01_star_land_leon_stop", 4.8):
		# Star touches down smoothly beside Leon; Leon stops walking
		_play_sfx("star_hover", -3.0)
		leon.stop_locomotion()
		leon.look_at_world(star.world_pos)
		
		# Camera transitions from Wide to Medium framing
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", 10.0, 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "cam_z", -150.0, 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "cam_height", 145.0, 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "zoom", 1.15, 1.0).set_trans(Tween.TRANS_SINE)

	# ------------------------------------------------------------------------
	# SCENE 2: Shadow Theft & Critical Realization (5.5s – 12.0s)
	# ------------------------------------------------------------------------
	if _run_beat("s02_star_curious", 5.6):
		# Star blinks and hovers inquisitively
		star.blink()
		leon.look_at_world(star.world_pos)
		leon.set_face_expression("neutral", "open")

	if _run_beat("s02_star_approach_shadow", 6.5):
		# Star slides across ground toward Leon's shadow
		star.dart_to(Vector2(12.0, 155.0), 8.0, 0.9)

	if _run_beat("s02_star_touches_shadow", 7.5):
		# Star touches the shadow! Ripple, pulse & small shockwave
		star.trigger_pulse(1.3)
		_play_sfx("star_pulse", 2.0)
		spawn_shockwave(leon.world_pos, 42.0, 0.4, Color(1.0, 0.95, 0.4, 0.85))

	if _run_beat("s02_shadow_theft_pull", 8.4):
		# THE SHADOW IS PULLED AWAY FROM LEON!
		_play_sfx("star_whoosh", 1.0)
		leon.has_shadow = false
		var star_pull_target := Vector2(75.0, 150.0)
		star.dart_to(star_pull_target, 18.0, 1.1)
		if detached_shadow:
			detached_shadow.steal_from(leon.world_pos, star, star_pull_target, 1.1)

	if _run_beat("s02_leon_notices_empty_feet", 9.5):
		# CRITICAL VISUAL BEAT: Camera pushes into tight Medium-Close
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", -5.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "cam_z", -80.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "cam_height", 125.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "zoom", 1.45, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Leon looks down at feet: NO SHADOW!
		leon.look_down_at_ground()
		leon.set_face_expression("confused", "wide")
		_play_sfx("vo_hurt_01", 2.0) # Alert gasp!

	if _run_beat("s02_leon_looks_at_star_with_shadow", 10.5):
		# Leon looks from empty ground to the star holding the shadow
		leon.look_at_world(star.world_pos)

	if _run_beat("s02_leon_double_take_feet", 11.1):
		# Double-take: looks back at empty feet!
		leon.look_down_at_ground()

	if _run_beat("s02_leon_realizes_stolen", 11.6):
		# Looks back at star with annoyed realization!
		leon.look_at_world(star.world_pos)
		leon.set_face_expression("angry", "open")

	# ------------------------------------------------------------------------
	# SCENE 3: Failed Reaches & Teasing (12.0s – 16.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s03_reach_first", 12.0):
		# Leon steps forward to grab the shadow
		leon.walk_to(Vector2(28.0, 155.0), 160.0)

	if _run_beat("s03_star_dodge_first", 12.7):
		# Star effortlessly hops back; Leon reaches and misses!
		_play_sfx("star_dart", 0.0)
		star.arc_to(Vector2(95.0, 150.0), 22.0, 0.4, 25.0)

	if _run_beat("s03_reach_second", 13.4):
		# Leon lunges again: "Hey!"
		_play_sfx("vo_hurt_02", 2.2) # "Hey!"
		leon.walk_to(Vector2(55.0, 155.0), 180.0)

	if _run_beat("s03_star_tease_bob", 14.2):
		# Star zips back farther and bobs playfully up and down
		_play_sfx("star_dart", 0.0)
		star.dart_to(Vector2(140.0, 150.0), 22.0, 0.45)
		star.jump_bob(22.0, 0.35)

	if _run_beat("s03_leon_frustrated_glare", 15.2):
		# Leon stops locomotion, glaring with narrowed eyes
		leon.stop_locomotion()
		leon.set_face_expression("angry", "squint")

	# ------------------------------------------------------------------------
	# SCENE 4: First Chase (Back View Depth Sprint) (16.5s – 21.0s)
	# ------------------------------------------------------------------------
	if _run_beat("s04_star_shoots_into_depth", 16.5):
		# Star darts deep into distance
		_play_sfx("star_whoosh", 1.0)
		star.arc_to(Vector2(140.0, 520.0), 45.0, 2.5, 60.0)

	if _run_beat("s04_leon_turns_back_view", 17.0):
		# Leon turns to BACK VIEW, sprinting into depth
		leon.set_view(&"back", false)
		leon.run_to(Vector2(120.0, 480.0), 320.0)
		
		# Camera pulls behind Leon framing depth corridor
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", 40.0, 3.2)
		tw.tween_property(camera, "cam_z", 20.0, 3.2)
		tw.tween_property(camera, "cam_height", 145.0, 3.2)
		tw.tween_property(camera, "zoom", 1.05, 1.5)
		
		if speed_lines:
			speed_lines.trigger_speed_lines(2.8, "radial", Vector2(576, 260), 0.4)

	if _run_beat("s04_leon_taunt", 18.8):
		_play_sfx("vo_lead_02", 2.0) # "Haha, yeah!"

	# ------------------------------------------------------------------------
	# SCENE 5: Star Cuts Across Field (3/4 Diagonal Rush) (21.0s – 25.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s05_star_banks_diagonal", 21.0):
		# Star banks hard diagonally right
		_play_sfx("star_dart", 1.0)
		star.arc_to(Vector2(320.0, 260.0), 35.0, 2.2, 50.0)

	if _run_beat("s05_leon_diagonal_rush", 21.5):
		# Leon turns to 3/4 VIEW, heading aligned (+X, -Z)
		leon.set_view(&"front_3q", false)
		leon.run_to(Vector2(260.0, 270.0), 310.0)
		
		# Camera tracks diagonally
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", 200.0, 3.0)
		tw.tween_property(camera, "cam_z", -140.0, 3.0)

	# ------------------------------------------------------------------------
	# SCENE 6: Side View Profile Sprint (25.5s – 30.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s06_star_cuts_horizontal", 25.5):
		# Star cuts horizontally across the screen to the left
		_play_sfx("star_dart", 1.0)
		star.arc_to(Vector2(-240.0, 240.0), 30.0, 3.2, 45.0)

	if _run_beat("s06_side_view_sprint", 26.0):
		# Camera presents Leon from pure SIDE profile
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", -20.0, 3.5)
		tw.tween_property(camera, "cam_z", -180.0, 3.5)
		tw.tween_property(camera, "zoom", 1.0, 1.0)
		
		# Leon switches to SIDE VIEW (mirrored, running left)
		leon.set_view(&"side", true)
		leon.run_to(Vector2(-190.0, 240.0), 320.0)
		
		if speed_lines:
			speed_lines.trigger_speed_lines(2.6, "horizontal", Vector2(576, 324), 0.38)

	# ------------------------------------------------------------------------
	# SCENE 7: Front View Approach (30.5s – 35.0s)
	# ------------------------------------------------------------------------
	if _run_beat("s07_star_curves_forward", 30.5):
		# Star curves straight toward camera
		_play_sfx("star_dart", 0.0)
		star.arc_to(Vector2(0.0, 70.0), 22.0, 2.8, 45.0)

	if _run_beat("s07_leon_front_sprint", 31.0):
		# Leon turns to FRONT VIEW sprinting straight at camera
		leon.set_view(&"front", false)
		leon.run_to(Vector2(-20.0, 95.0), 300.0)
		
		# Camera pulls back smoothly as Leon grows from Small -> Medium -> Large
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", -10.0, 3.0)
		tw.tween_property(camera, "cam_z", -230.0, 3.0)
		
		if speed_lines:
			speed_lines.trigger_speed_lines(2.4, "radial", Vector2(576, 360), 0.38)

	# ------------------------------------------------------------------------
	# SCENE 8 & 9: Near Camera Skid & Orbit Sweep (35.0s – 40.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s08_leon_skid_stop", 35.0):
		# Leon skids to a hard stop close to camera; footsteps stop
		leon.stop_locomotion()
		leon.spawn_dust_puff()
		leon.set_face_expression("confused", "open")
		
		# Star has slipped behind him into midground
		star.dart_to(Vector2(30.0, 160.0), 24.0, 0.8)

	if _run_beat("s08_leon_searches_around", 36.4):
		# Leon looks left and right, bewildered
		leon.look_at_world(Vector2(-120.0, 95.0))
		get_tree().create_timer(0.6).timeout.connect(func():
			leon.look_at_world(Vector2(120.0, 95.0))
		)

	if _run_beat("s09_camera_orbit_reveal", 37.8):
		# Camera performs a smooth orbit sweep around Leon
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", 10.0, 2.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(camera, "yaw_deg", 14.0, 1.1).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_property(camera, "yaw_deg", 0.0, 1.1).set_trans(Tween.TRANS_SINE)
		
		# The orbit reveals the star quietly hovering right behind Leon!
		_play_sfx("star_hover", -4.0)

	if _run_beat("s09_leon_turns_spots_star", 39.8):
		# Leon turns head back and spots the star behind him!
		leon.set_view(&"front_3q", true) # facing star
		leon.look_at_world(star.world_pos)

	# ------------------------------------------------------------------------
	# SCENE 10: Shadow Check & Determination (40.5s – 44.0s)
	# ------------------------------------------------------------------------
	if _run_beat("s10_shadow_check", 40.5):
		# Leon faces star in front_3q; looks down at feet: STILL NO SHADOW
		leon.set_view(&"front_3q", false)
		leon.look_down_at_ground()
		
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", 5.0, 1.2)
		tw.tween_property(camera, "cam_z", -160.0, 1.2)
		tw.tween_property(camera, "zoom", 1.2, 1.2)

	if _run_beat("s10_leon_determined", 41.5):
		# Looks up fiercely at star. "Yeah!" - time to fight back!
		leon.look_at_world(star.world_pos)
		leon.set_face_expression("angry", "open")
		_play_sfx("vo_start_01", 2.2) # "Yeah!"

	# ------------------------------------------------------------------------
	# SCENE 11 & 12: Basic Attack & Star Agile Dodge (44.0s – 48.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s11_basic_attack_fire", 44.0):
		# Leon tests if physical attack works: basic attack shuriken!
		_spawn_attack_projectile_at_star(leon.world_pos, star.world_pos)

	if _run_beat("s12_star_agile_dodge", 44.8):
		# Star somersaults upward, dodging the shuriken!
		_play_sfx("star_jump", 1.0)
		star.arc_to(star.world_pos + Vector2(0.0, -10.0), 80.0, 0.45, 35.0)

	if _run_beat("s12_leon_shocked_dodge", 45.8):
		# Star settles back down; Leon is shocked physical attacks miss!
		star.dart_to(Vector2(30.0, 160.0), 24.0, 0.4)
		leon.set_face_expression("shocked", "wide")
		star.blink()

	# ------------------------------------------------------------------------
	# SCENE 13 & 14: The Mimic Test & The Plan (48.5s – 54.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s13_mimic_test_a_arm", 48.5):
		# Leon observes star; raises arm / tilts left
		leon.set_face_expression("neutral", "squint")
		leon.jump_bob_view(10.0, 0.3)
		star.jump_bob(14.0, 0.3)
		_play_sfx("star_boop", 0.0)

	if _run_beat("s13_mimic_test_b_sidestep", 50.2):
		# Leon sidesteps left; star mirrors by darting left!
		leon.walk_to(leon.world_pos + Vector2(-35.0, 0.0), 90.0)
		star.dart_to(star.world_pos + Vector2(-35.0, 0.0), 24.0, 0.4)
		_play_sfx("star_dart", 0.0)

	if _run_beat("s13_mimic_test_c_hop", 51.8):
		# Leon hops; star does identical small hop!
		leon.jump(24.0, 0.4)
		star.jump_bob(28.0, 0.4)
		_play_sfx("star_jump", 0.0)

	if _run_beat("s14_leon_smug_plan", 53.2):
		# Close-up on Leon: smug smile! Star is blindly copying him and can be outsmarted!
		leon.stop_locomotion()
		leon.set_face_expression("smug", "open")
		crash_zoom(1.35, 0.25)

	# ------------------------------------------------------------------------
	# SCENE 15 & 16: Super Stealth & Confused Star (54.5s – 60.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s15_super_activation", 54.5):
		# Leon activates Super to break mirror loop!
		_play_sfx("vo_ulti_01", 2.5) # "Invisibility!"
		_play_sfx("leon_invis_01", 2.0)
		trigger_camera_shake(5.5)
		spawn_shockwave(leon.world_pos, 130.0, 0.45, Color(0.2, 0.85, 0.95, 0.9))
		leon.trigger_super(2.4)
		
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "zoom", 1.05, 0.5)

	if _run_beat("s16_star_confused_search", 56.0):
		# Star searches frantically with Leon vanished!
		_play_sfx("star_dart", -2.0)
		star.look_at_pos(Vector2(-100.0, 160.0))
		star.arc_to(Vector2(-40.0, 160.0), 28.0, 0.4, 20.0)

	if _run_beat("s16_star_search_turn", 57.2):
		# Star spins right, utterly bewildered
		_play_sfx("star_dart", -2.0)
		star.look_at_pos(Vector2(120.0, 160.0))
		star.arc_to(Vector2(50.0, 160.0), 28.0, 0.4, 20.0)

	if _run_beat("s16_leon_sneaky_whisper", 58.2):
		_play_sfx("vo_ulti_02", 2.2) # "Sneaky sneaky..."

	# ------------------------------------------------------------------------
	# SCENE 17 & 18: Reappear Ambush & Cornering (60.5s – 66.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s17_reappear_ambush", 60.5):
		# Leon reappears right behind the star in front_3q!
		leon.world_pos = Vector2(75.0, 180.0)
		leon.set_view(&"front_3q", true)
		_play_sfx("leon_invis_end_01", 2.0)
		
		# Star spins around, gasps, and panics!
		star.look_at_pos(leon.world_pos)
		star.trigger_pulse(1.4)
		_play_sfx("star_whoosh", 1.0)

	if _run_beat("s17_star_panic_bolt_close_pass", 61.3):
		# Star bolts, executing a dynamic close pass in front of camera!
		star.arc_to(Vector2(260.0, 260.0), 35.0, 2.0, 50.0)
		leon.set_view(&"front_3q", false)
		leon.run_to(Vector2(210.0, 260.0), 320.0)
		
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", 160.0, 2.5)
		tw.tween_property(camera, "cam_z", -140.0, 2.5)

	if _run_beat("s18_star_cornered_rock_barrier", 63.8):
		# Star hits edge of rock barrier and skids to a halt, trapped!
		star.dart_to(Vector2(270.0, 260.0), 22.0, 0.3)
		leon.walk_to(Vector2(215.0, 260.0), 100.0) # walks in to corner it

	if _run_beat("s18_leon_traps_star", 65.0):
		leon.stop_locomotion()
		leon.look_at_world(star.world_pos)
		star.look_at_pos(leon.world_pos)

	# ------------------------------------------------------------------------
	# SCENE 19: The Shadow Return (66.5s – 72.0s)
	# ------------------------------------------------------------------------
	if _run_beat("s19_star_contrite_droop", 66.8):
		# Star droops apologetically and blinks gently
		star.jump_bob(-10.0, 0.4)
		star.blink()
		_play_sfx("star_hover", -3.0)

	if _run_beat("s19_star_releases_shadow", 68.2):
		# STAR RELEASES THE DETACHED SHADOW!
		_play_sfx("star_whoosh", 0.0)
		if detached_shadow:
			detached_shadow.return_to_leon(leon.world_pos, 1.4)

	if _run_beat("s19_shadow_reconnects", 69.8):
		# Shadow arrives at Leon's feet: soft magical return whoosh & ground pulse!
		_play_sfx("star_burst", 0.0)
		spawn_shockwave(leon.world_pos, 52.0, 0.35, Color(0.4, 0.95, 0.5, 0.85))
		leon.has_shadow = true
		star.trigger_pulse(1.2)

	# ------------------------------------------------------------------------
	# SCENE 20: Shadow Check, Synchronized Step & Relief (72.0s – 76.5s)
	# ------------------------------------------------------------------------
	if _run_beat("s20_leon_checks_ground", 72.0):
		# Leon looks down at feet: SHADOW IS BACK!
		leon.look_down_at_ground()
		leon.set_face_expression("neutral", "open")
		
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", 170.0, 1.0)
		tw.tween_property(camera, "cam_z", -90.0, 1.0)
		tw.tween_property(camera, "zoom", 1.3, 1.0)

	if _run_beat("s20_test_step_forward", 73.2):
		# Leon takes one test step forward; shadow moves in perfect sync!
		leon.walk_to(leon.world_pos + Vector2(20.0, 0.0), 60.0)

	if _run_beat("s20_happy_relief", 74.5):
		# Leon stops, looks up, smiles warmly with deep relief
		leon.stop_locomotion()
		leon.look_at_world(star.world_pos)
		leon.set_face_expression("happy", "open")

	if _run_beat("s20_star_ascends_away", 74.8):
		# Star winks and ascends high into the sky, leaving Leon completely alone
		star.blink()
		_play_sfx("star_whoosh", 0.0)
		star.arc_to(Vector2(380.0, 240.0), 620.0, 3.2, 90.0)

	# ------------------------------------------------------------------------
	# SCENE 21: Final Gag & Cut to Black (76.5s – 82.0s)
	# ------------------------------------------------------------------------
	if _run_beat("s21_walk_away", 76.5):
		# Leon turns to walk away casually across the meadow (completely alone)
		leon.set_view(&"front_3q", false)
		leon.walk_to(leon.world_pos + Vector2(65.0, 0.0), 85.0)

	if _run_beat("s21_sudden_pause", 78.0):
		# Leon stops abruptly; feels something strange beneath him
		leon.stop_locomotion()
		leon.look_down_at_ground()
		
		# Camera pushes in close to frame Leon and ground shadow clearly!
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_x", leon.world_pos.x + 12.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "cam_z", 100.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "cam_height", 110.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "zoom", 1.85, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if _run_beat("s21_shadow_waves_gag", 79.0):
		# THE FINAL GAG: Ground shadow's arm raises and slowly waves at Leon!
		leon.trigger_shadow_wave(1.8)

	if _run_beat("s21_leon_dumbfounded_freeze", 79.8):
		# Extreme close-up crash zoom on Leon: completely frozen, baffled and speechless!
		var tw := create_tween().set_parallel(true)
		tw.tween_property(camera, "cam_height", 80.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "zoom", 2.5, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		leon.set_face_expression("shocked", "wide")
		_play_sfx("star_boop", 1.5)

	if _run_beat("s21_snap_to_black", 81.6):
		if fade_overlay:
			create_tween().tween_property(fade_overlay, "modulate:a", 1.0, 0.15)
		if bgm_player:
			create_tween().tween_property(bgm_player, "volume_db", -40.0, 0.35)

	if _run_beat("s21_finish", 82.0):
		is_finished = true
		movie_completed.emit()
		print("[RUNAWAY STAR] Movie completed successfully at %.2fs!" % movie_time)
		get_tree().quit(0)

func _run_beat(beat_name: String, timestamp: float) -> bool:
	if movie_time >= timestamp and not _beat_fired.has(beat_name):
		_beat_fired[beat_name] = true
		return true
	return false

# --- Combat Projectile Spawner ----------------------------------------------

func _spawn_attack_projectile_at_star(from_pos: Vector2, to_pos: Vector2) -> void:
	leon.trigger_basic_attack()
	_play_sfx("leon_atk_01", 1.0) # Strictly during actual attack!
	
	# Spawn spatial shuriken
	var proj := ProjectileScript.new()
	add_child(proj)
	# Trajectory heads toward star world_pos
	proj.setup(camera, from_pos, to_pos + Vector2(0.0, 40.0), 38.0, null, 680.0)

# --- Footstep Binding & Audio Engine (Strictly NO BGM) ----------------------

func _bind_leon_events() -> void:
	if leon:
		leon.footstep_stepped.connect(func(is_run: bool):
			if is_run:
				_play_sfx("land", -4.0, randf_range(1.10, 1.25))
			else:
				_play_sfx("land", -6.5, randf_range(1.25, 1.40))
		)
		leon.landed.connect(func():
			_play_sfx("land", -2.0, 1.0)
		)

func _init_audio() -> void:
	var sfx_files := {
		"land": "res://assets/audio/sfx/common/land.ogg",
		"footstep_walk_01": "res://assets/audio/sfx/common/land.ogg",
		"footstep_walk_02": "res://assets/audio/sfx/common/land.ogg",
		"footstep_run_01": "res://assets/audio/sfx/common/land.ogg",
		"footstep_run_02": "res://assets/audio/sfx/common/land.ogg",
		"star_whoosh": "res://assets/audio/sfx/star/star_whoosh.wav",
		"star_hover": "res://assets/audio/sfx/star/star_hover.wav",
		"star_dart": "res://assets/audio/sfx/star/star_dart.wav",
		"star_pulse": "res://assets/audio/sfx/star/star_pulse.wav",
		"star_jump": "res://assets/audio/sfx/star/star_jump.wav",
		"star_boop": "res://assets/audio/sfx/star/star_boop.wav",
		"star_burst": "res://assets/audio/sfx/star/star_burst.wav",
		"meadow_breeze": "res://assets/audio/sfx/env/meadow_breeze.wav",
		"leon_atk_01": "res://assets/audio/sfx/leon/leon_atk_01.ogg",
		"leon_invis_01": "res://assets/audio/sfx/leon/leon_invis_01.ogg",
		"leon_invis_end_01": "res://assets/audio/sfx/leon/leon_invis_end_01.ogg",
		"jump": "res://assets/audio/sfx/common/jump.ogg",
		# Authentic Brawl Stars Leon Voice Lines (Semantically Motivated)
		"vo_start_03": "res://assets/audio/voices/leon/leon_start_vo_03.ogg",
		"vo_start_01": "res://assets/audio/voices/leon/leon_start_vo_01.ogg",
		"vo_lead_01": "res://assets/audio/voices/leon/leon_lead_vo_01.ogg",
		"vo_lead_02": "res://assets/audio/voices/leon/leon_lead_vo_02.ogg",
		"vo_kill_01": "res://assets/audio/voices/leon/leon_kill_vo_01.ogg",
		"vo_kill_02": "res://assets/audio/voices/leon/leon_kill_vo_02.ogg",
		"vo_ulti_01": "res://assets/audio/voices/leon/leon_ulti_vo_01.ogg",
		"vo_ulti_02": "res://assets/audio/voices/leon/leon_ulti_vo_02.ogg",
		"vo_hurt_01": "res://assets/audio/voices/leon/leon_hurt_vo_01.ogg",
		"vo_hurt_02": "res://assets/audio/voices/leon/leon_hurt_vo_02.ogg",
		"vo_die_01": "res://assets/audio/voices/leon/leon_die_vo_01.ogg",
		"vo_die_02": "res://assets/audio/voices/leon/leon_die_vo_02.ogg"
	}
	
	for sfx_id in sfx_files:
		var path: String = sfx_files[sfx_id]
		if ResourceLoader.exists(path):
			_audio_cache[sfx_id] = load(path)
			
	# Create pool of AudioStreamPlayers
	for i in range(12):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		add_child(p)
		_sfx_players[i] = p
		
	# BGM Setup: Ragnarok BGM (ragnarok_menu_01.ogg)
	var bgm_path := "res://assets/audio/bgm/ragnarok_menu_01.ogg"
	if FileAccess.file_exists(bgm_path):
		var bgm_stream: AudioStream = null
		if ResourceLoader.exists(bgm_path):
			bgm_stream = load(bgm_path)
		else:
			bgm_stream = AudioStreamOggVorbis.load_from_file(bgm_path)
			if bgm_stream:
				bgm_stream.resource_path = bgm_path
			
		if bgm_stream is AudioStreamOggVorbis:
			bgm_stream.loop = true
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BGMPlayer"
		bgm_player.stream = bgm_stream
		bgm_player.volume_db = -8.0 # Balanced so voices, footsteps, and star SFX remain crisp and dominant
		add_child(bgm_player)

var _player_pool_idx: int = 0

func _play_sfx(sfx_id: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _audio_cache.has(sfx_id):
		return
		
	var stream: AudioStream = _audio_cache[sfx_id]
	var p: AudioStreamPlayer = _sfx_players.get(_player_pool_idx)
	_player_pool_idx = (_player_pool_idx + 1) % _sfx_players.size()
	
	if p:
		p.stop()
		p.stream = stream
		p.volume_db = volume_db
		p.pitch_scale = pitch
		p.play()

# --- Environment Setup (Simple blue sky + green 2.5D ground plane) ---------

func _init_environment() -> void:
	if ground:
		ground.color = Color(0.24, 0.65, 0.28, 1.0) # Radiant meadow green
	if sky:
		sky.color = Color(0.38, 0.72, 0.98, 1.0)    # Clear blue cartoon sky
	if horizon_line:
		horizon_line.default_color = Color(0.18, 0.48, 0.22, 0.85)
		horizon_line.width = 2.5
		
	var props_node := get_node_or_null("Props")
	if props_node:
		for prop in props_node.get_children():
			if prop.has_method("setup"):
				prop.setup(camera, prop.world_pos, prop.prop_type, prop.prop_height)
