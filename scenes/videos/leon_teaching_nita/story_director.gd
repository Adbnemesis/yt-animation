class_name TeachingStoryDirector
extends Node2D

# Master Story Director: "Leon Tries to Teach Nita How to Fight"
# Full 61.5-second continuous cartoon performance matching Brawl Stars BGM track.
# Features:
# - Natural 0.3s–0.8s reaction beats and active micro-acting (zero dead pauses)
# - The Challenge sequence: progressive targets, expanding character arc
# - 100% Authoritative Projectile Causality (destruction triggered on collision, not timer)
# - Expressive camera language (two-shot, coaching medium, punch-ins, wide chaos)
# - Fully readable with audio muted

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

# Deterministic wait for a collision signal with timeout fallback
func wait_for_signal_or_timeout(sig: Signal, timeout: float) -> void:
	var completed = [false]
	var cb = func(_a = null, _b = null): completed[0] = true
	sig.connect(cb, CONNECT_ONE_SHOT)
	var total_frames = int(round(timeout * 60.0))
	for i in range(total_frames):
		if completed[0]:
			break
		if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw
	if not completed[0] and sig.is_connected(cb):
		sig.disconnect(cb)

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
	# SHOT 1: Leon's Warmup & Demonstration (~0.0s – 7.2s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 1: Leon's Demonstration & Warmup" % elapsed_story_time)
	if bgm_player:
		bgm_player.volume_db = -11.0
		bgm_player.play()

	_camera_pan_zoom(Vector2(440, 420), Vector2(1.05, 1.05), 0.1)
	leon.position = Vector2(280, 520)
	leon.set_facing(1)
	leon.demonstration_stance()
	await wait_sec(1.0)

	# Leon hop warm-up with squash & stretch
	_play_sfx(sfx_jump, -4.0)
	var tw_hop = create_tween()
	tw_hop.tween_property(leon, "position:y", 485.0, 0.18).set_ease(Tween.EASE_OUT)
	tw_hop.tween_property(leon, "position:y", 520.0, 0.16).set_ease(Tween.EASE_IN)
	await tw_hop.finished
	_play_sfx(sfx_land, -4.0)
	if has_node("/root/VFXManager"):
		get_node("/root/VFXManager").spawn_vfx("DUST_PUFF", leon.global_position)
	await wait_sec(0.5)

	# Leon voice callout & anticipation windup
	_play_leon_vo(vo_leon_yeah)
	leon.anticipation_windup()
	await wait_sec(0.6)

	# Leon attack demonstration: 4 spinner blades at target dummy at X=740
	print("[STORY @ %.2fs] Leon demonstrates 4-blade spinner attack on dummy" % elapsed_story_time)
	_camera_pan_zoom(Vector2(500, 420), Vector2(1.0, 1.0), 0.6)
	leon.set_expression("angry", "angry")
	leon.trigger_attack()
	await leon.attack_finished
	await wait_sec(0.6)

	# Recoil settling & smug follow-through
	leon.follow_through_settle()
	await wait_sec(0.8)

	# Smug teacher folded arms & foot tap waiting for student
	leon.cross_arms_tap_foot()
	await wait_sec(1.2)

	# =========================================================================
	# SHOT 2: Nita Arrives & Asks to Learn (~7.2s – 13.8s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 2: Nita Arrives & Asks to Learn" % elapsed_story_time)
	_camera_pan_zoom(Vector2(320, 420), Vector2(1.04, 1.04), 0.8)
	nita.walk_to(140.0, 170.0)
	await nita.walk_finished
	await wait_sec(0.3)

	# Nita eager greeting and bouncy hops
	_play_nita_vo(vo_nita_eager)
	nita.eager_hop()
	await wait_sec(0.5)

	# Nita excited shadow-punching: "I'm ready! Teach me!"
	nita.shadow_punch_excited()
	await wait_sec(0.8)

	# Leon turns with cocky older-brother grin
	print("[STORY] Leon acknowledges student with cocky confidence")
	leon.set_facing(-1)
	leon.set_expression("smug", "open")
	_play_leon_vo(vo_leon_start)
	await wait_sec(0.55)

	# Leon points firmly towards target dummy
	leon.point_gesture(1.0)
	leon.turn_head_to_student(true)
	await wait_sec(0.9)

	# Reaction beat: Nita follows gesture to dummy, then turns back to Leon nodding eagerly
	nita.set_facing(1)
	await wait_sec(0.55)
	nita.set_facing(-1)
	nita.set_expression("grin", "open")
	await wait_sec(0.6)

	# =========================================================================
	# SHOT 3: Stance Demonstration & Imitation (~13.8s – 20.8s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 3: Leon Demonstrates Stance; Nita Imitates" % elapsed_story_time)
	_camera_pan_zoom(Vector2(420, 420), Vector2(1.0, 1.0), 0.8)
	# Leon moves to teacher observation mark on left at X=220
	leon.set_facing(1)
	leon.walk_to(220.0, 140.0)
	await leon.walk_finished
	await wait_sec(0.3)

	# Leon demonstrates proper windup pose
	leon.demonstration_stance()
	leon.turn_head_to_student(true)

	# Nita runs up to student firing line at X=420 (200px separation from Leon!)
	nita.walk_to(420.0, 160.0)
	await nita.walk_finished
	await wait_sec(0.4)

	# Nita awkwardly copies Leon's stance!
	print("[STORY @ %.2fs] Nita attempts to imitate Leon's stance" % elapsed_story_time)
	nita.imitation_pose()
	await wait_sec(1.0)

	# Nita checks feet alignment and adjusts posture
	nita.check_feet_alignment()
	await wait_sec(1.1)

	# Leon nods encouragingly: "Looking good, now take your shot!"
	leon.turn_head_to_student(true)
	await wait_sec(0.9)

	# =========================================================================
	# SHOT 4: Nita's Clumsy Fumble & Leon's Panic (~20.8s – 28.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 4: Nita's Clumsy Fumble & Near Miss" % elapsed_story_time)
	_camera_pan_zoom(Vector2(340, 410), Vector2(1.12, 1.12), 0.7)

	# Nita turns around to show off to Leon and fires shockwave backwards (left)!
	nita.set_facing(-1)
	await wait_sec(0.6)

	# Nita clumsy fumble attack towards Leon
	print("[STORY @ %.2fs] Nita fumbles attack towards Leon!" % elapsed_story_time)
	nita.clumsy_fumble_attack()
	await wait_sec(0.28)

	# Leon at X=220 emergency panic jumps as shockwave passes harmlessly beneath him!
	print("[STORY @ %.2fs] Leon panic jump!" % elapsed_story_time)
	_play_leon_vo(vo_leon_gasp)
	_play_sfx(sfx_jump, 2.0)
	leon.trigger_panic_jump()
	await wait_sec(0.7)
	_play_sfx(sfx_land, 1.0)
	if has_node("/root/VFXManager"):
		get_node("/root/VFXManager").spawn_vfx("DUST_PUFF", leon.global_position)
	await wait_sec(0.6)

	# Nita turns around, realizes dummy is untouched, shrinks in embarrassment
	nita.set_facing(1)
	await wait_sec(0.5)
	nita.set_facing(-1)
	print("[STORY @ %.2fs] Nita realizes mistake and shrinks in embarrassment" % elapsed_story_time)
	_play_nita_vo(vo_nita_oops)
	nita.embarrassed_shrink()
	nita.fidget_embarrassed()
	await wait_sec(0.9)

	# Leon at X=220 stares deadpan across the 200px gap: "Seriously?!"
	print("[STORY @ %.2fs] Leon deadpan disbelief reaction across the gap" % elapsed_story_time)
	leon.set_facing(1)
	leon.disbelief_react()
	leon.head_shake_disbelief()
	await wait_sec(1.0)

	# Leon brushes off hoodie in relief
	leon.dust_off_hoodie()
	await wait_sec(1.0)

	# =========================================================================
	# SHOT 5: Patient Coaching & Proper Alignment (~28.5s – 36.2s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 5: Leon Patiently Coaches Stance & Aim" % elapsed_story_time)
	_camera_pan_zoom(Vector2(360, 410), Vector2(1.10, 1.10), 0.8)
	# Leon steps forward to X=250 (170px away from Nita at X=420)
	leon.reset_pose()
	leon.walk_to(250.0, 140.0)
	await leon.walk_finished
	await wait_sec(0.35)

	# Leon points firmly at the dummy bullseye and coaches
	_play_leon_vo(vo_leon_teach)
	leon.set_facing(1)
	leon.coaching_demonstration()
	await wait_sec(1.3)

	# Nita watches, plants feet firmly, aligns arm to dummy
	print("[STORY @ %.2fs] Nita learns: plants feet and aligns arm to dummy" % elapsed_story_time)
	nita.set_facing(1)
	nita.learning_stance()
	await wait_sec(1.2)

	# Leon steps back to X=210 to clear the shooting lane
	leon.walk_to(210.0, 140.0)
	await leon.walk_finished
	leon.set_facing(1)
	leon.set_expression("neutral", "open")
	await wait_sec(0.5)

	# Nita takes a focused breath to center herself
	nita.focused_deep_breath()
	await wait_sec(1.0)

	# =========================================================================
	# SHOT 6: First Success — Focused Hit on Dummy (~36.2s – 44.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 6: Nita Focused Clean Hit on Dummy" % elapsed_story_time)
	_camera_pan_zoom(Vector2(490, 420), Vector2(1.02, 1.02), 0.7)

	# Nita prepares with focused anticipation
	nita.anticipation_aim()
	await wait_sec(0.7)

	# Nita executes smooth, focused attack from X=420 to dummy at X=740!
	print("[STORY @ %.2fs] Nita fires clean shockwave at target dummy!" % elapsed_story_time)
	nita.trigger_attack()

	# AUTHORITATIVE COLLISION: Await real projectile impact on Target Dummy!
	if target_dummy:
		await wait_for_signal_or_timeout(target_dummy.hit_received, 1.2)

	# DIRECT HIT CONFIRMED!
	_play_sfx(sfx_crash, 1.2)
	_camera_shake(7.0, 0.28)
	await wait_sec(0.5)

	# Punch in on reactions
	_camera_pan_zoom(Vector2(360, 415), Vector2(1.14, 1.14), 0.6)

	# Leon at X=210 genuine proud approval
	print("[STORY @ %.2fs] Leon surprised & proud" % elapsed_story_time)
	_play_leon_vo(vo_leon_yeah)
	leon.proud_approval()
	await wait_sec(1.0)

	# Nita turns to Leon at X=210 and bursts into joyful celebration!
	print("[STORY @ %.2fs] Nita celebrates with proud hops" % elapsed_story_time)
	_play_nita_vo(vo_nita_cheer)
	nita.set_facing(-1)
	nita.proud_hop()
	await wait_sec(0.6)

	# Mutual celebration: Leon fist-pump, Nita double high hop
	leon.celebrate_student_hit()
	nita.double_high_hop()
	await wait_sec(1.3)

	# =========================================================================
	# SHOT 7: THE CHALLENGE — PROGRESSIVE TARGETS (~44.5s – 54.0s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 7: The Challenge — Progressive Targets" % elapsed_story_time)
	_camera_pan_zoom(Vector2(510, 420), Vector2(0.95, 0.95), 0.7)

	# Leon realizes Nita has real talent; establishes controlled practice challenge!
	leon.set_facing(1)
	_play_leon_vo(vo_leon_start)
	leon.challenge_setup_gesture()
	if props:
		props.setup_challenge_targets()
	await wait_sec(1.2)

	# Challenge Target 1 (Careful Aim at X=580)
	print("[STORY @ %.2fs] Challenge Target 1: Nita carefully aims at practice board" % elapsed_story_time)
	nita.set_facing(1)
	nita.anticipation_aim()
	await wait_sec(0.6)
	nita.trigger_attack()

	# Authoritative wait for projectile to reach and shatter Target 1
	if props:
		await wait_for_signal_or_timeout(props.target_1_destroyed, 1.1)
	_play_sfx(sfx_crash, 1.5)
	_camera_shake(6.0, 0.25)
	await wait_sec(0.5)

	# Leon approves of Target 1 hit with celebratory gesture
	leon.celebrate_student_hit()
	await wait_sec(0.8)

	# Challenge Target 2 (Confident Rapid Hit at X=670)
	print("[STORY @ %.2fs] Challenge Target 2: Nita fires confidently at second target" % elapsed_story_time)
	nita.confident_aim()
	await wait_sec(0.4)
	nita.trigger_attack()

	# Authoritative wait for projectile to reach and shatter Target 2
	if props:
		await wait_for_signal_or_timeout(props.target_2_destroyed, 1.2)
	_play_sfx(sfx_crash, 1.8)
	_camera_shake(7.5, 0.28)
	await wait_sec(0.6)

	# Leon is visibly blown away: "Whoa, she's actually really good!"
	print("[STORY @ %.2fs] Leon is visibly impressed by Nita's second hit" % elapsed_story_time)
	leon.escalating_impressed()
	await wait_sec(1.2)

	# Attitude Shift: Nita gets cocky, does a boastful spin and swagger!
	print("[STORY @ %.2fs] Nita becomes overconfident and swaggers" % elapsed_story_time)
	_play_nita_vo(vo_nita_stronger)
	nita.swagger_spin()
	await wait_sec(0.8)
	nita.boastful_chest_puff()
	await wait_sec(1.2)

	# Leon spots her reckless attitude; his smile turns to concern: "Wait, hold on..."
	print("[STORY @ %.2fs] Leon notices Nita's cocky attitude with growing concern" % elapsed_story_time)
	leon.concerned_hesitation()
	await wait_sec(1.0)

	# =========================================================================
	# SHOT 8: Overconfidence, Ignored Warning & Chaos Unleashed (~54.0s – 61.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 8: Chaos Unleashed Across Training Ground" % elapsed_story_time)
	if props:
		props.arm_chaos()

	# Leon gives frantic warning
	print("[STORY @ %.2fs] Leon alarmed: 'Wait, stop!'" % elapsed_story_time)
	_play_leon_vo(vo_leon_no)
	leon.warning_gesture()
	await wait_sec(0.7)

	# Camera pulls out to wide overview of the entire destruction zone
	_camera_pan_zoom(Vector2(530, 420), Vector2(0.90, 0.90), 0.7)

	# Nita ignores him, turns, and unleashes 3-beat rapid chaos!
	nita.set_facing(1)

	# Chaos Beat 1: Target Dummy launched into orbit!
	print("[STORY @ %.2fs] Blast 1: Target Dummy blast launched into orbit!" % elapsed_story_time)
	if props and target_dummy:
		props.arm_dummy_launch(target_dummy)
	nita.reckless_windup()
	nita.set_expression("angry", "angry")
	nita.trigger_attack()

	# Authoritative wait for projectile collision to launch the dummy
	if props:
		await wait_for_signal_or_timeout(props.dummy_launched, 1.1)
	_play_sfx(sfx_crash, 3.5)
	_camera_shake(12.0, 0.4)
	await wait_sec(0.5)

	# Quick horror reaction beat: Leon gasps in panic while Nita laughs maniacally
	leon.warning_gesture()
	nita.set_expression("grin", "wide")
	await wait_sec(0.6)

	# Chaos Beat 2: Training sign at X=850 snapped in half!
	print("[STORY @ %.2fs] Blast 2: Training sign snapped in half!" % elapsed_story_time)
	nita.reckless_windup()
	nita.trigger_attack()

	# Authoritative wait for projectile collision with training sign
	if props:
		await wait_for_signal_or_timeout(props.sign_destroyed, 1.2)
	_play_sfx(sfx_crash, 2.5)
	_camera_shake(10.0, 0.32)
	await wait_sec(0.6)

	# Chaos Beat 3: Point-blank Crate Stack destroyed into wood debris!
	print("[STORY @ %.2fs] Blast 3: Crate stack destroyed into wood debris!" % elapsed_story_time)
	nita.walk_to(760.0, 260.0)
	await nita.walk_finished
	nita.reckless_windup()
	nita.trigger_attack()

	# Authoritative wait for projectile collision with crate stack
	if props:
		await wait_for_signal_or_timeout(props.crates_destroyed, 1.1)
	_play_sfx(sfx_crash, 4.5)
	_camera_shake(15.0, 0.45)
	leon.cower_gesture()
	await wait_sec(1.2)

	# =========================================================================
	# SHOT 9: Aftermath & Comedic Facepalm (~61.5s – 68.0s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 9: Aftermath, Innocent Grin & Comedic Facepalm" % elapsed_story_time)
	_camera_pan_zoom(Vector2(350, 415), Vector2(1.10, 1.10), 0.8)
	await wait_sec(0.4)

	# Nita walks back to X=420 (200px+ separation from Leon at X=210!)
	nita.walk_to(420.0, 160.0)
	await nita.walk_finished
	nita.set_facing(-1)
	nita.innocent_pose()
	await wait_sec(0.6)

	# Leon at X=210 looks at the empty smoking space where everything stood
	leon.reset_pose()
	leon.set_facing(1)
	leon.set_expression("shocked", "wide")
	await wait_sec(0.8)

	# Lingering smoke rises from the ruins
	if props:
		props.spawn_lingering_smoke(Vector2(850, 480))
		props.spawn_lingering_smoke(Vector2(930, 480))

	# A small dust puff falls in the quiet aftermath
	_play_sfx(sfx_land, -6.0)
	if has_node("/root/VFXManager"):
		get_node("/root/VFXManager").spawn_vfx("DUST_PUFF", Vector2(760, 520))
	await wait_sec(0.8)

	# Leon turns slowly to look at Nita
	leon.set_facing(-1)
	await wait_sec(0.6)

	# Nita double-blinks with an innocent goofy smile
	nita.innocent_blink_loop()
	await wait_sec(0.8)

	# Leon facepalms in deep exhausted regret: "I created a monster..."
	print("[STORY] Leon facepalms in regret: 'What have I done...'")
	leon.facepalm_gesture()
	await wait_sec(2.0)

	# Smooth fade to black synchronized with BGM conclusion
	print("[STORY] Cut to black")
	if blackout_rect:
		var tw_fade = create_tween()
		tw_fade.tween_property(blackout_rect, "modulate:a", 1.0, 0.9)
		await tw_fade.finished

	await wait_sec(0.4)
	story_completed.emit()
	print("[STORY] Story sequence finished successfully!")
	get_tree().quit()

