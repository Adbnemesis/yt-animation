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
	# SHOT 1: Leon's Practice & Confidence (0.0s – 9.0s)
	# =========================================================================
	print("[STORY] Shot 1: Leon's Practice")
	if bgm_player:
		bgm_player.play()

	_camera_pan_zoom(Vector2(500, 420), Vector2(1.0, 1.0), 0.1)
	leon.set_expression("smug", "open")
	await wait_sec(1.5)

	# Leon hop warm-up
	_play_sfx(sfx_jump, -4.0)
	var tw_hop = create_tween()
	tw_hop.tween_property(leon, "position:y", 480.0, 0.20).set_ease(Tween.EASE_OUT)
	tw_hop.tween_property(leon, "position:y", 520.0, 0.18).set_ease(Tween.EASE_IN)
	await tw_hop.finished
	_play_sfx(sfx_land, -4.0)
	await wait_sec(1.0)

	# Leon voice & attack demonstration
	_play_leon_vo(vo_leon_yeah)
	await wait_sec(1.0)

	print("[STORY] Leon unleashes 4-blade burst attack on dummy")
	leon.set_expression("angry", "angry")
	leon.trigger_attack()
	await leon.attack_finished
	await wait_sec(1.2)

	# Leon proud pose & smug smile
	leon.set_expression("smug", "happy")
	await wait_sec(2.0)

	# =========================================================================
	# SHOT 2: Nita Arrives & Asks for Training (9.0s – 18.0s)
	# =========================================================================
	print("[STORY] Shot 2: Nita Arrives")
	_camera_pan_zoom(Vector2(400, 420), Vector2(1.05, 1.05), 1.2)
	nita.set_expression("grin", "wide")
	nita.walk_to(220.0, 160.0)
	await nita.walk_finished
	await wait_sec(0.6)

	# Nita eager request & hops
	_play_nita_vo(vo_nita_eager)
	nita.proud_hop()
	await wait_sec(1.6)

	# Leon turns around to face Nita
	print("[STORY] Leon notices Nita and acts cocky")
	leon.set_facing(-1)
	leon.set_expression("smug", "open")
	await wait_sec(0.8)
	_play_leon_vo(vo_leon_start)
	await wait_sec(2.2)

	# =========================================================================
	# SHOT 3: Leon Demonstrates (18.0s – 26.5s)
	# =========================================================================
	print("[STORY] Shot 3: Leon Demonstrates Aim")
	_camera_pan_zoom(Vector2(480, 420), Vector2(1.0, 1.0), 1.0)
	leon.set_facing(1)
	leon.walk_to(450.0, 130.0)
	await leon.walk_finished
	await wait_sec(0.5)

	# Leon points to dummy
	leon.set_expression("neutral", "open")
	leon.point_gesture()
	await wait_sec(1.4)

	# Leon demonstrates attack cleanly
	print("[STORY] Leon demonstrates attack cleanly")
	leon.set_expression("angry", "angry")
	leon.trigger_attack()
	await leon.attack_finished
	await wait_sec(1.2)

	# Leon turns to Nita: "Your turn!"
	leon.set_facing(-1)
	leon.set_expression("smug", "happy")
	await wait_sec(1.2)

	# =========================================================================
	# SHOT 4: Nita's Clumsy First Attempt (Near-Miss!) (26.5s – 37.5s)
	# =========================================================================
	print("[STORY] Shot 4: Nita's Bad Attempt & Near Miss")
	_camera_pan_zoom(Vector2(410, 410), Vector2(1.08, 1.08), 1.0)
	nita.walk_to(240.0, 130.0)
	await nita.walk_finished
	nita.set_facing(1)
	nita.set_expression("angry", "open")
	await wait_sec(1.2)

	# Nita attacks! Fissure goes directly towards Leon!
	print("[STORY] Nita fires shockwave directly at Leon's feet!")
	nita.trigger_attack()
	await wait_sec(0.32)

	# Leon emergency jump dodging the rupture!
	print("[STORY] Leon panic jump!")
	_play_leon_vo(vo_leon_gasp)
	_play_sfx(sfx_jump, 2.0)
	leon.trigger_panic_jump()
	await wait_sec(0.65)
	_play_sfx(sfx_land, 1.0)
	await wait_sec(0.6)

	# Leon lands frustrated & glaring at Nita
	leon.set_facing(-1)
	leon.set_expression("angry", "shocked")
	await wait_sec(1.0)

	# Nita realizes mistake and cowers embarrassed
	print("[STORY] Nita embarrassed")
	_play_nita_vo(vo_nita_oops)
	nita.embarrassed_shrink()
	await wait_sec(3.0)

	# =========================================================================
	# SHOT 5: Leon Teaches Stance & Aim Patiently (37.5s – 46.5s)
	# =========================================================================
	print("[STORY] Shot 5: Leon Teaches Aim & Stance")
	_camera_pan_zoom(Vector2(360, 410), Vector2(1.12, 1.12), 1.0)
	leon.set_expression("neutral", "open")
	leon.walk_to(350.0, 120.0)
	await leon.walk_finished
	await wait_sec(0.5)

	# Leon points directly at the dummy
	_play_leon_vo(vo_leon_teach)
	leon.set_facing(1)
	leon.point_gesture()
	await wait_sec(1.6)

	# Nita nods with focus
	nita.set_expression("grin", "open")
	await wait_sec(0.8)

	# Leon steps safely behind Nita
	leon.walk_to(130.0, 130.0)
	await leon.walk_finished
	leon.set_facing(1)
	leon.set_expression("neutral", "open")
	await wait_sec(1.2)

	# =========================================================================
	# SHOT 6: Nita's Second Attempt (Clean Hit!) (46.5s – 54.5s)
	# =========================================================================
	print("[STORY] Shot 6: Nita Clean Hit on Dummy")
	_camera_pan_zoom(Vector2(480, 420), Vector2(1.0, 1.0), 1.0)
	nita.set_expression("angry", "angry")
	await wait_sec(1.0)

	# Nita strikes! Clean hit!
	nita.trigger_attack()
	await wait_sec(0.7)
	_play_sfx(sfx_crash, 1.0)
	_camera_shake(6.0, 0.25)
	await wait_sec(0.8)

	# Leon surprised approval
	print("[STORY] Leon pleasantly surprised & proud")
	leon.set_expression("happy", "wide")
	await wait_sec(1.0)
	leon.set_expression("smug", "happy")

	# Nita beaming with joy and bouncing
	print("[STORY] Nita proud & excited")
	_play_nita_vo(vo_nita_cheer)
	nita.set_facing(-1)
	nita.proud_hop()
	await wait_sec(2.5)

	# =========================================================================
	# SHOT 7: Reckless Escalation (Chaos Unleashed) (54.5s – 63.5s)
	# =========================================================================
	print("[STORY] Shot 7: Reckless Escalation")
	_camera_pan_zoom(Vector2(530, 420), Vector2(0.95, 0.95), 0.8)
	_play_nita_vo(vo_nita_stronger)
	nita.set_expression("smug", "wide")
	await wait_sec(1.2)

	# Leon panics: "No wait!"
	_play_leon_vo(vo_leon_no)
	leon.set_expression("scared", "wide")
	await wait_sec(1.0)

	# Nita turns and unleashes RAPID ATTACKS!
	nita.set_facing(1)

	# Blast 1 -> Crate stack at X=920
	print("[STORY] Blast 1: Crate stack destroyed!")
	nita.set_expression("angry", "angry")
	nita.trigger_attack()
	await wait_sec(0.7)
	if props:
		props.destroy_crates()
	_play_sfx(sfx_crash, 3.0)
	_camera_shake(10.0, 0.35)
	await wait_sec(0.8)

	# Blast 2 -> Training sign at X=840
	print("[STORY] Blast 2: Training sign snapped!")
	nita.trigger_attack()
	await wait_sec(0.65)
	if props:
		props.destroy_sign()
	_play_sfx(sfx_crash, 2.0)
	_camera_shake(8.0, 0.3)
	await wait_sec(0.8)

	# Blast 3 -> Point-blank dummy launch!
	print("[STORY] Blast 3: Dummy launched into orbit!")
	nita.trigger_attack()
	await wait_sec(0.6)
	if props and target_dummy:
		props.launch_dummy(target_dummy)
	_play_sfx(sfx_crash, 4.0)
	_camera_shake(14.0, 0.45)
	await wait_sec(2.0)

	# =========================================================================
	# SHOT 8: The Aftermath & Final Payoff (63.5s – 70.0s)
	# =========================================================================
	print("[STORY] Shot 8: Aftermath & Comedic Facepalm")
	_camera_pan_zoom(Vector2(320, 410), Vector2(1.15, 1.15), 1.2)
	await wait_sec(1.2)

	# Nita turns around with innocent look
	nita.walk_to(260.0, 140.0)
	await nita.walk_finished
	nita.set_facing(-1)
	nita.innocent_pose()
	await wait_sec(1.0)

	# Leon looks at the destruction on the right
	leon.set_facing(1)
	leon.set_expression("shocked", "wide")
	await wait_sec(1.8)

	# Leon turns slowly to look at Nita
	leon.set_facing(-1)
	await wait_sec(1.0)

	# Nita blinks with pure innocence
	nita.set_expression("grin", "blink")
	await wait_sec(0.25)
	nita.set_expression("grin", "open")
	await wait_sec(0.8)

	# Leon facepalm / disbelief slump
	print("[STORY] Leon facepalms in disbelief")
	leon.facepalm_gesture()
	await wait_sec(2.8)

	# Fade to black
	print("[STORY] Cut to black")
	if blackout_rect:
		var tw_fade = create_tween()
		tw_fade.tween_property(blackout_rect, "modulate:a", 1.0, 0.6)
		await tw_fade.finished

	await wait_sec(0.6)
	story_completed.emit()
	print("[STORY] Story sequence finished!")
	get_tree().quit()
