class_name TeachingStoryDirector
extends Node2D

# Master Story Director: "Leon Tries to Teach Nita How to Fight"
# Orchestrates the ~68-second narrative short deterministically frame-by-frame.

const TeachingActorLeonClass = preload("res://scenes/videos/leon_teaching_nita/actor_leon.gd")
const TeachingActorNitaClass = preload("res://scenes/videos/leon_teaching_nita/actor_nita.gd")
const DestructiblePropsClass = preload("res://scenes/videos/leon_teaching_nita/destructible_props.gd")

signal story_completed()

@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var environment: Node2D = get_node_or_null("Environment")
@onready var target_dummy: Area2D = get_node_or_null("Environment/TargetDummy")
@onready var props: DestructibleProps = get_node_or_null("Environment/Props")

@onready var leon: TeachingActorLeon = get_node_or_null("Characters/Leon")
@onready var nita: TeachingActorNita = get_node_or_null("Characters/Nita")

@onready var blackout_rect: ColorRect = get_node_or_null("UI/BlackoutOverlay/ColorRect")

# Audio Players
@onready var bgm_player: AudioStreamPlayer = get_node_or_null("Audio/BGMPlayer")
@onready var sfx_player: AudioStreamPlayer = get_node_or_null("Audio/SFXPlayer")
@onready var voice_leon: AudioStreamPlayer = get_node_or_null("Audio/VoiceLeon")
@onready var voice_nita: AudioStreamPlayer = get_node_or_null("Audio/VoiceNita")

var is_running: bool = false
var elapsed_story_time: float = 0.0
var auto_quit_duration: float = -1.0

# Sound Resources
var sfx_jump = preload("res://assets/audio/sfx/common/jump.ogg")
var sfx_land = preload("res://assets/audio/sfx/common/land.ogg")
var sfx_crash = preload("res://assets/audio/sfx/elevator/elevator_jolt.wav")

var vo_leon_yeah = preload("res://assets/audio/voices/leon/leon_start_vo_01.ogg")
var vo_leon_start = preload("res://assets/audio/voices/leon/leon_start_vo_03.ogg")
var vo_leon_gasp = preload("res://assets/audio/voices/leon/leon_hurt_vo_01.ogg")
var vo_leon_teach = preload("res://assets/audio/voices/leon/leon_lead_vo_01.ogg")
var vo_leon_no = preload("res://assets/audio/voices/leon/leon_hurt_vo_02.ogg")

var vo_nita_eager = preload("res://assets/audio/voices/nita/nita_start_vo_01.ogg")
var vo_nita_oops = preload("res://assets/audio/voices/nita/nita_hurt_vo_01.ogg")
var vo_nita_cheer = preload("res://assets/audio/voices/nita/nita_kill_vo_01.ogg")
var vo_nita_stronger = preload("res://assets/audio/voices/nita/nita_start_vo_02.ogg")

func _ready() -> void:
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

	_init_scene_state()
	if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
		get_tree().process_frame.connect(start_story, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(start_story, CONNECT_ONE_SHOT)

func _process(delta: float) -> void:
	if is_running:
		elapsed_story_time += delta
		if auto_quit_duration > 0.0 and elapsed_story_time >= auto_quit_duration:
			print("[AUTO-QUIT] Elapsed time reached: %.2fs" % elapsed_story_time)
			get_tree().quit()

func _init_scene_state() -> void:
	if camera:
		camera.position = Vector2(500, 420)
		camera.zoom = Vector2(1.0, 1.0)

	if target_dummy and target_dummy.has_node("UI"):
		target_dummy.get_node("UI").visible = false

	if leon:
		leon.position = Vector2(420, 520)
		leon.set_view(TeachingActorLeonClass.ViewMode.SIDE)
		leon.set_facing(1)
		leon.set_expression("smug", "open")

	if nita:
		nita.position = Vector2(-120, 520)
		nita.set_view(TeachingActorNitaClass.ViewMode.SIDE)
		nita.set_facing(1)
		nita.set_expression("grin", "open")

	if blackout_rect:
		blackout_rect.modulate.a = 0.0

func start_story() -> void:
	if is_running:
		return
	is_running = true
	elapsed_story_time = 0.0
	_execute_story_sequence()

# Deterministic frame-based wait matching Movie Maker 60fps
func wait_sec(seconds: float) -> void:
	var total_frames = int(round(seconds * 60.0))
	for i in range(total_frames):
		if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw

func _play_sfx(stream: AudioStream, vol_db: float = 0.0) -> void:
	if sfx_player and stream:
		sfx_player.stream = stream
		sfx_player.volume_db = vol_db
		sfx_player.play()

func _play_leon_vo(stream: AudioStream, vol_db: float = 3.0) -> void:
	if voice_leon and stream:
		voice_leon.stream = stream
		voice_leon.volume_db = vol_db
		voice_leon.play()

func _play_nita_vo(stream: AudioStream, vol_db: float = 3.0) -> void:
	if voice_nita and stream:
		voice_nita.stream = stream
		voice_nita.volume_db = vol_db
		voice_nita.play()

func _camera_pan_zoom(target_pos: Vector2, target_zoom: Vector2, duration: float) -> void:
	if not camera:
		return
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(camera, "position", target_pos, duration)
	tw.tween_property(camera, "zoom", target_zoom, duration)

func _camera_shake(intensity: float = 8.0, duration: float = 0.3) -> void:
	if not camera:
		return
	var orig_pos = camera.position
	var tw = create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(camera, "position", orig_pos + offset, 0.04)
	tw.tween_property(camera, "position", orig_pos, 0.04)

func _execute_story_sequence() -> void:
	# =========================================================================
	# SHOT 1: Leon's Warmup & Demonstration (0.0s – 7.0s)
	# =========================================================================
	print("[STORY] Shot 1: Leon's Solo Practice & Demonstration")
	if bgm_player:
		bgm_player.play()

	_camera_pan_zoom(Vector2(500, 420), Vector2(1.0, 1.0), 0.1)
	leon.position = Vector2(280, 520)
	leon.set_facing(1)
	leon.demonstration_stance()
	await wait_sec(1.4)

	# Leon hop warm-up
	_play_sfx(sfx_jump, -4.0)
	var tw_hop = create_tween()
	tw_hop.tween_property(leon, "position:y", 485.0, 0.18).set_ease(Tween.EASE_OUT)
	tw_hop.tween_property(leon, "position:y", 520.0, 0.16).set_ease(Tween.EASE_IN)
	await tw_hop.finished
	_play_sfx(sfx_land, -4.0)
	await wait_sec(1.0)

	# Leon voice & attack demonstration
	_play_leon_vo(vo_leon_yeah)
	await wait_sec(0.8)

	print("[STORY] Leon demonstrates 4-blade spinner attack on dummy")
	leon.set_expression("angry", "angry")
	leon.trigger_attack()
	await leon.attack_finished
	await wait_sec(0.8)

	# Leon checks his work, satisfied smirk
	leon.set_expression("smug", "happy")
	leon.demonstration_stance()
	await wait_sec(1.8)

	# =========================================================================
	# SHOT 2: Nita Arrives & Asks for Training (7.0s – 14.0s)
	# =========================================================================
	print("[STORY] Shot 2: Nita Arrives & Asks to Learn")
	_camera_pan_zoom(Vector2(380, 420), Vector2(1.05, 1.05), 1.0)
	nita.walk_to(140.0, 160.0)
	await nita.walk_finished
	await wait_sec(0.4)

	# Nita eager request & hops
	_play_nita_vo(vo_nita_eager)
	nita.eager_hop()
	await wait_sec(0.8)

	# Leon turns to face Nita
	print("[STORY] Leon acknowledges student with cocky confidence")
	leon.set_facing(-1)
	leon.set_expression("smug", "open")
	await wait_sec(0.8)
	_play_leon_vo(vo_leon_start)

	# Leon gestures towards the target dummy
	leon.point_gesture(1.2)
	leon.turn_head_to_student(true)
	await wait_sec(1.8)

	# =========================================================================
	# SHOT 3: Leon Shows Stance & Nita Imitates (14.0s – 21.0s)
	# =========================================================================
	print("[STORY] Shot 3: Leon Demonstrates Stance; Nita Imitates")
	_camera_pan_zoom(Vector2(440, 420), Vector2(1.0, 1.0), 0.8)
	# Leon moves to his teacher observation spot on the left
	leon.set_facing(1)
	leon.walk_to(220.0, 130.0)
	await leon.walk_finished
	await wait_sec(0.3)

	# Leon demonstrates proper windup pose
	leon.demonstration_stance()
	await wait_sec(0.8)
	leon.turn_head_to_student(true)
	await wait_sec(0.6)

	# Nita runs up to the student firing mark at X=390 (170px away from Leon!)
	nita.walk_to(390.0, 150.0)
	await nita.walk_finished
	await wait_sec(0.4)

	# Nita awkwardly copies Leon's stance!
	print("[STORY] Nita attempts to imitate Leon's stance")
	nita.imitation_pose()
	await wait_sec(1.8)

	# Leon gives an approving head nod: "Go for it!"
	leon.turn_head_to_student(true)
	await wait_sec(1.2)

	# =========================================================================
	# SHOT 4: Nita's Clumsy Fumble & Leon's Disbelief (21.0s – 30.0s)
	# =========================================================================
	print("[STORY] Shot 4: Nita's Clumsy Fumble & Near Miss")
	_camera_pan_zoom(Vector2(380, 410), Vector2(1.06, 1.06), 0.8)

	# Nita turns around to show off to Leon and fires toward the left!
	nita.set_facing(-1)
	await wait_sec(0.4)

	# Nita over-swings wildly, stumbles forward towards Leon, and fires shockwave!
	print("[STORY] Nita fumbles attack towards Leon!")
	nita.clumsy_fumble_attack()
	await wait_sec(0.24)

	# Leon at X=220 emergency panic jumps as fissure passes beneath him!
	print("[STORY] Leon panic jump!")
	_play_leon_vo(vo_leon_gasp)
	_play_sfx(sfx_jump, 2.0)
	leon.trigger_panic_jump()
	await wait_sec(0.65)
	_play_sfx(sfx_land, 1.0)
	await wait_sec(0.6)

	# Nita turns around, sees the dummy is completely untouched, looks down at dirt
	nita.set_facing(1)
	await wait_sec(0.4)
	nita.set_facing(-1)
	print("[STORY] Nita realizes mistake and shrinks in embarrassment")
	_play_nita_vo(vo_nita_oops)
	nita.embarrassed_shrink()
	await wait_sec(0.8)

	# Leon at X=220 stares deadpan across the 160px gap: "Seriously?!"
	print("[STORY] Leon deadpan disbelief reaction across the gap")
	leon.set_facing(1)
	leon.disbelief_react()
	await wait_sec(2.4)

	# =========================================================================
	# SHOT 5: Leon Patiently Coaches Stance & Aim (30.0s – 37.5s)
	# =========================================================================
	print("[STORY] Shot 5: Leon Patiently Coaches Stance & Aim")
	_camera_pan_zoom(Vector2(400, 410), Vector2(1.1, 1.1), 0.8)
	# Leon walks up beside Nita's left shoulder (X=310, 80px away from Nita at X=390)
	leon.reset_pose()
	leon.walk_to(310.0, 130.0)
	await leon.walk_finished
	await wait_sec(0.4)

	# Leon points firmly at the dummy bullseye and coaches
	_play_leon_vo(vo_leon_teach)
	leon.set_facing(1)
	leon.coaching_demonstration()
	await wait_sec(1.6)

	# Nita watches, plants feet firmly, aligns arm to dummy
	print("[STORY] Nita learns: plants feet and aligns arm to dummy")
	nita.set_facing(1)
	nita.learning_stance()
	await wait_sec(1.4)

	# Leon steps back to X=210 to give her the entire field
	leon.walk_to(210.0, 130.0)
	await leon.walk_finished
	leon.set_facing(1)
	leon.set_expression("neutral", "open")
	await wait_sec(0.8)

	# =========================================================================
	# SHOT 6: Nita Focuses, Hits Dummy & Leon's Pride (37.5s – 46.5s)
	# =========================================================================
	print("[STORY] Shot 6: Nita Focused Clean Hit on Dummy")
	_camera_pan_zoom(Vector2(490, 420), Vector2(1.0, 1.0), 0.8)
	nita.set_expression("grin", "open")
	await wait_sec(0.8)

	# Nita executes smooth, focused attack from X=390 to dummy at X=710!
	print("[STORY] Nita fires clean shockwave at target dummy!")
	nita.trigger_attack()
	await wait_sec(0.7)

	# DIRECT HIT! Dummy impacts and shakes
	_play_sfx(sfx_crash, 1.5)
	_camera_shake(7.0, 0.28)
	await wait_sec(0.8)

	# Leon at X=210 genuine proud approval
	print("[STORY] Leon surprised & proud")
	_play_leon_vo(vo_leon_yeah)
	leon.proud_approval()
	await wait_sec(1.2)

	# Nita turns to Leon at X=210 and bursts into joy!
	print("[STORY] Nita celebrates with proud hops")
	_play_nita_vo(vo_nita_cheer)
	nita.set_facing(-1)
	nita.proud_hop()
	await wait_sec(2.2)

	# =========================================================================
	# SHOT 7: Reckless Overconfidence & 3-Beat Chaos (46.5s – 55.5s)
	# =========================================================================
	print("[STORY] Shot 7: Nita Overconfident Swagger & Chaos")
	_camera_pan_zoom(Vector2(520, 420), Vector2(0.96, 0.96), 0.8)

	# Nita shifts to cocky, overconfident swagger at X=390
	_play_nita_vo(vo_nita_stronger)
	nita.overconfident_swagger()
	await wait_sec(1.4)

	# Leon at X=210 realizes she's about to go crazy: frantic warning!
	print("[STORY] Leon alarmed: 'Wait, stop!'")
	_play_leon_vo(vo_leon_no)
	leon.warning_gesture()
	await wait_sec(1.2)

	# Nita turns and unleashes rapid chaos!
	nita.set_facing(1)

	# Chaos Beat 1: Crate stack at X=865 destroyed
	print("[STORY] Blast 1: Crate stack destroyed into wood debris!")
	nita.set_expression("angry", "angry")
	nita.trigger_attack()
	await wait_sec(0.7)
	if props:
		props.destroy_crates()
	_play_sfx(sfx_crash, 3.0)
	_camera_shake(10.0, 0.35)
	leon.cower_gesture()
	await wait_sec(0.8)

	# Chaos Beat 2: Training sign at X=790 snapped
	print("[STORY] Blast 2: Training sign snapped in half!")
	nita.trigger_attack()
	await wait_sec(0.65)
	if props:
		props.destroy_sign()
	_play_sfx(sfx_crash, 2.5)
	_camera_shake(9.0, 0.3)
	await wait_sec(0.8)

	# Chaos Beat 3: Point-blank dummy launch into space!
	print("[STORY] Blast 3: Dummy launched into orbit!")
	nita.walk_to(640.0, 220.0)
	await nita.walk_finished
	nita.trigger_attack()
	await wait_sec(0.6)
	if props and target_dummy:
		props.launch_dummy(target_dummy)
	_play_sfx(sfx_crash, 4.5)
	_camera_shake(14.0, 0.45)
	await wait_sec(1.6)

	# =========================================================================
	# SHOT 8: Aftermath & Comedic Facepalm (55.5s – 61.5s)
	# =========================================================================
	print("[STORY] Shot 8: Aftermath & Comedic Facepalm")
	_camera_pan_zoom(Vector2(360, 410), Vector2(1.12, 1.12), 0.8)
	await wait_sec(0.6)

	# Nita walks back to X=390 (170px away from Leon at X=220!)
	nita.walk_to(390.0, 160.0)
	await nita.walk_finished
	nita.set_facing(-1)
	nita.innocent_pose()
	await wait_sec(0.6)

	# Leon at X=220 looks at the empty smoking space on the right
	leon.reset_pose()
	leon.set_facing(1)
	leon.set_expression("shocked", "wide")
	await wait_sec(1.2)

	# Leon turns slowly to look at Nita
	leon.set_facing(-1)
	await wait_sec(0.6)

	# Nita blinks innocently expecting praise
	nita.set_expression("grin", "blink")
	await wait_sec(0.25)
	nita.set_expression("grin", "open")
	await wait_sec(0.6)

	# Leon facepalms in deep exhausted regret across the gap
	print("[STORY] Leon facepalms in disbelief: 'What have I done...'")
	leon.facepalm_gesture()
	await wait_sec(1.8)

	# Smooth fade to black synchronized with BGM conclusion
	print("[STORY] Cut to black")
	if blackout_rect:
		var tw_fade = create_tween()
		tw_fade.tween_property(blackout_rect, "modulate:a", 1.0, 0.7)
		await tw_fade.finished

	await wait_sec(0.3)
	story_completed.emit()
	print("[STORY] Story sequence finished!")
	get_tree().quit()
