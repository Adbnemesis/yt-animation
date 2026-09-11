class_name FacilityStoryDirector
extends Node2D

# Master Story Director: "The Thing They Shouldn't Have Opened"
# Full ~72-second continuous animated short.
# Features:
# - Immediate action hook (facility creeping -> ambush)
# - Two escalating fights with authoritative projectile causality
# - Leon Super tactical usage (vanish -> flank -> point-blank strike)
# - Three distinct character personalities (Leon clever, Nita eager, Bo tactical)
# - Progressive environmental & VFX escalation
# - False resolution -> massive multi-chamber reveal
# - Comedic escape ending ("RUN.")
# - 100% readable with audio muted

const FacilityActorLeonClass = preload("res://scenes/videos/thing_they_opened/actor_leon.gd")
const FacilityActorNitaClass = preload("res://scenes/videos/thing_they_opened/actor_nita.gd")
const FacilityActorBoClass = preload("res://scenes/videos/thing_they_opened/actor_bo.gd")

signal story_completed()

@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var facility: FacilityBuilder = get_node_or_null("Environment")
@onready var machine: SecurityMachine = get_node_or_null("SecurityMachine")
@onready var creature: FacilityCreature = get_node_or_null("Creature")

@onready var leon: FacilityActorLeon = get_node_or_null("Leon")
@onready var nita: FacilityActorNita = get_node_or_null("Nita")
@onready var bo: FacilityActorBo = get_node_or_null("Bo")

@onready var blackout_rect: ColorRect = get_node_or_null("UI/BlackoutOverlay/ColorRect")

# Audio Players
@onready var bgm_player: AudioStreamPlayer = get_node_or_null("Audio/BGMPlayer")
@onready var sfx_player: AudioStreamPlayer = get_node_or_null("Audio/SFXPlayer")
@onready var sfx_player2: AudioStreamPlayer = get_node_or_null("Audio/SFXPlayer2")
@onready var ambient_player: AudioStreamPlayer = get_node_or_null("Audio/AmbientPlayer")
@onready var voice_leon: AudioStreamPlayer = get_node_or_null("Audio/VoiceLeon")
@onready var voice_nita: AudioStreamPlayer = get_node_or_null("Audio/VoiceNita")
@onready var voice_bo: AudioStreamPlayer = get_node_or_null("Audio/VoiceBo")

var is_running: bool = false
var elapsed_story_time: float = 0.0
var auto_quit_duration: float = -1.0

# Preloaded Sound Resources
var sfx_jump = preload("res://assets/audio/sfx/common/jump.ogg")
var sfx_land = preload("res://assets/audio/sfx/common/land.ogg")
var sfx_crash = preload("res://assets/audio/sfx/elevator/elevator_jolt.wav")
var sfx_flicker = preload("res://assets/audio/sfx/elevator/light_flicker.wav")
var sfx_door_open = preload("res://assets/audio/sfx/elevator/elevator_door_open.wav")
var sfx_hum = preload("res://assets/audio/sfx/elevator/elevator_hum.wav")

var vo_leon_alert = preload("res://assets/audio/voices/leon/leon_hurt_vo_01.ogg")
var vo_leon_start = preload("res://assets/audio/voices/leon/leon_start_vo_01.ogg")
var vo_leon_yeah = preload("res://assets/audio/voices/leon/leon_start_vo_03.ogg")
var vo_leon_kill = preload("res://assets/audio/voices/leon/leon_kill_vo_01.ogg")
var vo_leon_ulti = preload("res://assets/audio/voices/leon/leon_ulti_vo_01.ogg")
var vo_leon_hurt = preload("res://assets/audio/voices/leon/leon_hurt_vo_02.ogg")

var vo_nita_start = preload("res://assets/audio/voices/nita/nita_start_vo_01.ogg")
var vo_nita_kill = preload("res://assets/audio/voices/nita/nita_kill_vo_01.ogg")
var vo_nita_hurt = preload("res://assets/audio/voices/nita/nita_hurt_vo_01.ogg")
var vo_nita_eager = preload("res://assets/audio/voices/nita/nita_start_vo_02.ogg")

var vo_bo_lead = preload("res://assets/audio/voices/bo/bo_lead_vo_01.ogg")
var vo_bo_start = preload("res://assets/audio/voices/bo/bo_start_vo_01.ogg")
var vo_bo_fire = preload("res://assets/audio/voices/bo/bo_fire_vo_01.ogg")
var vo_bo_hurt = preload("res://assets/audio/voices/bo/bo_hurt_01.ogg")

var sfx_leon_atk = preload("res://assets/audio/sfx/leon/leon_atk_01.ogg")
var sfx_nita_atk = preload("res://assets/audio/sfx/nita/nita_atk_01.ogg")
var sfx_bo_atk = preload("res://assets/audio/sfx/bo/bo_atk_01.ogg")
var sfx_leon_invis = preload("res://assets/audio/sfx/leon/leon_invis_01.ogg")
var sfx_leon_invis_end = preload("res://assets/audio/sfx/leon/leon_invis_end_01.ogg")

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
		# Restrained background parallax tracks the staging camera
		if facility and camera:
			facility.apply_parallax(camera.position)

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

func _play_sfx2(stream: AudioStream, vol_db: float = 0.0) -> void:
	if sfx_player2 and stream:
		sfx_player2.stream = stream
		sfx_player2.volume_db = vol_db
		sfx_player2.play()

func _play_ambient(stream: AudioStream, vol_db: float = -6.0) -> void:
	if ambient_player and stream:
		ambient_player.stream = stream
		ambient_player.volume_db = vol_db
		ambient_player.play()

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

func _play_bo_vo(stream: AudioStream, vol_db: float = 3.0) -> void:
	if voice_bo and stream:
		voice_bo.stream = stream
		voice_bo.volume_db = vol_db
		voice_bo.play()

func _camera_pan_zoom(target_pos: Vector2, target_zoom: Vector2, duration: float) -> void:
	if not camera:
		return
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(camera, "position", target_pos, duration)
	tw.tween_property(camera, "zoom", target_zoom, duration)

func _camera_shake(intensity: float, duration: float) -> void:
	if not camera:
		return
	var orig_pos = camera.position
	var tw = create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(camera, "position", orig_pos + offset, 0.04)
	tw.tween_property(camera, "position", orig_pos, 0.04)

func _init_scene_state() -> void:
	if camera:
		camera.position = Vector2(400, 430)
		camera.zoom = Vector2(1.0, 1.0)

	# Position trio in the Staging Triangle across 3 distinct depth lanes
	if leon:
		leon.position = Vector2(380, 565) # Foreground lane (near camera)
		leon.set_facing(1)
		leon.set_expression("neutral", "open")
		leon._update_depth_scale()
	if nita:
		nita.position = Vector2(270, 535) # Midground lane (active combat)
		nita.set_facing(1)
		nita.set_expression("grin", "open")
		nita._update_depth_scale()
	if bo:
		bo.position = Vector2(160, 490) # Background lane (deep anchor)
		bo.set_facing(1)
		bo.set_expression("neutral", "open")
		bo._update_depth_scale()

	if blackout_rect:
		blackout_rect.modulate.a = 0.0

	if machine:
		machine.position = Vector2(850, 530)

	# Creature hidden until reveal at deep blast door
	if creature:
		creature.position = Vector2(1050, 510)
		creature.visible = false

func start_story() -> void:
	if is_running:
		return
	is_running = true
	elapsed_story_time = 0.0
	_execute_story_sequence()

func _execute_story_sequence() -> void:
	# =========================================================================
	# SHOT 1: IMMEDIATE HOOK — Facility Exploration & Ambush (0.0s–5.0s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 1: Immediate Hook — Facility Ambush" % elapsed_story_time)
	if bgm_player:
		bgm_player.volume_db = -13.0
		bgm_player.play()

	# Trio moves through the facility in a clear depth triangle
	# WIDE shot: establish the full room geography and depth lanes
	_camera_pan_zoom(Vector2(430, 430), Vector2(0.92, 0.92), 0.2)
	_play_ambient(sfx_hum, -10.0)

	# Staggered multiplane advance: Leon foreground, Nita midground, Bo background
	leon.cautious_advance()
	leon.walk_to_2d(Vector2(450, 565), 110.0)
	nita.walk_to_2d(Vector2(330, 530), 105.0)
	bo.walk_to_2d(Vector2(210, 490), 100.0)
	await wait_sec(1.6)

	# Sudden red warning light flicker & hum — DANGER!
	print("[STORY @ %.2fs] Warning lights activate!" % elapsed_story_time)
	_play_sfx(sfx_flicker, 1.0)
	if facility:
		facility.flicker_warning_lights()
	await wait_sec(0.4)

	# Leon stops in foreground, alert snap reaction — CLOSE on his face
	leon.set_expression("shocked", "wide")
	leon.alert_react()
	_camera_pan_zoom(leon.position + Vector2(0, -46), Vector2(1.42, 1.42), 0.3)
	await wait_sec(0.55)
	# Pull back to MEDIUM: re-group the depth triangle before the machine acts
	_camera_pan_zoom(Vector2(430, 430), Vector2(1.0, 1.0), 0.4)
	await wait_sec(0.25)

	# Nita and Bo stop, eyelines track alarm
	nita.look_at_target(leon.global_position)
	nita.set_expression("shocked", "open")
	bo.look_at_target(Vector2(600, 200))
	bo.set_expression("serious", "open")
	await wait_sec(0.5)

	# Security machine powers up at midground Y=530 with ground rumble!
	print("[STORY @ %.2fs] Security Machine activates!" % elapsed_story_time)
	_play_sfx(sfx_crash, 2.5)
	_camera_shake(7.0, 0.35)
	if machine:
		machine.activate()
	await wait_sec(1.0)

	# =========================================================================
	# SHOT 2: Scatter & React (5.0s–9.0s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 2: Scatter & React" % elapsed_story_time)
	_camera_pan_zoom(Vector2(500, 430), Vector2(0.95, 0.95), 0.6)

	# Machine fires warning shot diagonally across lanes toward Leon!
	if machine:
		machine.attack_at(leon.global_position)
	await wait_sec(0.4)

	# Leon reactive dodge roll forward-left into foreground lane!
	_play_leon_vo(vo_leon_alert)
	_play_sfx(sfx_jump, -1.0)
	leon.dodge_roll(-1, 10.0)
	await wait_sec(0.8)

	# Nita aggressive stance in midground — excited for battle
	_play_nita_vo(vo_nita_eager)
	nita.aggressive_stance()
	await wait_sec(0.6)

	# Bo steps back calmly along background lane and notches arrow
	bo.dodge_back(50.0, -5.0)
	bo.tactical_observe()
	await wait_sec(0.8)

	# =========================================================================
	# SHOT 3: First Fight — Security Machine (9.0s–23.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 3: First Fight — Security Machine" % elapsed_story_time)

	# --- Beat 1: Bo takes the first calculated shot from deep lane ---
	_camera_pan_zoom(Vector2(480, 420), Vector2(1.0, 1.0), 0.6)
	_play_bo_vo(vo_bo_fire)
	bo.look_at_target(machine.global_position)
	bo.precise_aim()
	await wait_sec(0.7)

	bo.trigger_attack()
	_play_sfx(sfx_bo_atk, 1.0)

	# AUTHORITATIVE: wait for arrows to hit machine across depth
	if machine:
		await wait_for_signal_or_timeout(machine.hit_received, 1.2)
	_play_sfx(sfx_crash, 0.0)
	_camera_shake(5.0, 0.25)
	await wait_sec(0.6)

	# --- Beat 2: Machine retaliates — fires laser at Nita in midground ---
	print("[STORY @ %.2fs] Machine counterattacks Nita" % elapsed_story_time)
	if machine:
		machine.attack_at(nita.global_position)
	await wait_sec(0.4)

	# Nita dodges with an athletic leap landing forward in midground!
	nita.dodge_jump(50.0, 10.0)
	_play_sfx(sfx_jump, -0.5)
	await wait_sec(0.8)

	# --- Beat 3: Leon sees opening, repositions along foreground lane and strikes ---
	print("[STORY @ %.2fs] Leon repositions in foreground and attacks" % elapsed_story_time)
	_camera_pan_zoom(Vector2(560, 430), Vector2(1.04, 1.04), 0.5)
	leon.combat_ready_stance()
	leon.tactical_reposition_2d(Vector2(560, 570))
	await wait_sec(0.6)

	_play_leon_vo(vo_leon_yeah)
	leon.trigger_attack()
	_play_sfx(sfx_leon_atk, 1.2)

	# AUTHORITATIVE: wait for blades to hit machine up-depth
	if machine:
		await wait_for_signal_or_timeout(machine.hit_received, 1.0)
	_play_sfx2(sfx_crash, -1.0)
	_camera_shake(6.0, 0.22)
	await wait_sec(0.6)

	# --- Beat 4: Nita battle roar & charges diagonally in midground with shockwave ---
	print("[STORY @ %.2fs] Nita charges and attacks" % elapsed_story_time)
	nita.battle_windup()
	_play_nita_vo(vo_nita_start)
	await wait_sec(0.5)
	nita.eager_charge_2d(Vector2(500, 525))
	await nita.walk_finished
	nita.set_facing(1)

	nita.trigger_attack()
	_play_sfx(sfx_nita_atk, 1.2)

	# AUTHORITATIVE: wait for shockwave to hit machine
	if machine:
		await wait_for_signal_or_timeout(machine.hit_received, 1.2)
	_play_sfx2(sfx_crash, 1.5)
	_camera_shake(8.0, 0.3)
	await wait_sec(0.5)

	# Machine is visibly damaged — sputtering sparks!
	if facility:
		facility.spawn_sparks(machine.global_position + Vector2(0, -50))
	await wait_sec(0.8)

	# --- Beat 5: Machine desperate blast at Bo in deep lane ---
	print("[STORY @ %.2fs] Machine fires desperately at Bo" % elapsed_story_time)
	if machine:
		machine.attack_at(bo.global_position)
	await wait_sec(0.3)
	bo.dodge_back(70.0, 0.0)
	await wait_sec(0.6)

	# --- Beat 6: Bo finishes the machine with precise piercing shot ---
	print("[STORY @ %.2fs] Bo fires finishing arrows" % elapsed_story_time)
	_camera_pan_zoom(Vector2(530, 420), Vector2(1.05, 1.05), 0.5)
	bo.precise_aim()
	await wait_sec(0.5)

	bo.trigger_attack()
	_play_sfx(sfx_bo_atk, 1.5)

	# AUTHORITATIVE: final hit destroys machine
	if machine:
		await wait_for_signal_or_timeout(machine.hit_received, 1.2)
	await wait_sec(0.3)

	# =========================================================================
	# SHOT 4: Machine Falls (23.5s–29.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 4: Machine Falls" % elapsed_story_time)
	_camera_pan_zoom(Vector2(700, 430), Vector2(1.06, 1.06), 0.6)

	# Machine collapses with heavy debris at midground
	_play_sfx(sfx_crash, 4.0)
	_camera_shake(13.0, 0.5)
	if facility:
		facility.spawn_debris(machine.global_position + Vector2(-20, 0))
		facility.spawn_sparks(machine.global_position + Vector2(10, -60))
	await wait_sec(1.5)

	# Staging Triangle: Leon foreground right, Nita midground center, Bo background left
	leon.confident_smirk()
	leon.set_facing(1)
	await wait_sec(0.8)

	nita.excited_react()
	_play_nita_vo(vo_nita_kill)
	await wait_sec(0.8)

	bo.calm_assessment()
	await wait_sec(0.8)

	# Dust settles, warning lights shut down — false peace
	if facility:
		facility.spawn_debris(machine.global_position)
		facility.stop_warning_lights()
	await wait_sec(1.2)

	# =========================================================================
	# SHOT 5: THE REVEAL (29.5s–37.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 5: The Reveal" % elapsed_story_time)
	_camera_pan_zoom(Vector2(650, 410), Vector2(1.0, 1.0), 1.2)

	# Quiet moment — BGM dips to eerie background murmur
	if bgm_player:
		var tw_bgm = create_tween()
		tw_bgm.tween_property(bgm_player, "volume_db", -22.0, 1.0)
	await wait_sec(1.4)

	# Monitor suddenly flashes red WARNING
	print("[STORY @ %.2fs] Monitor displays WARNING" % elapsed_story_time)
	_play_sfx(sfx_flicker, 2.5)
	if facility:
		facility.flash_monitor_warning("WARNING:\nCONTAINMENT\nBREACH")
	await wait_sec(0.8)

	# Coordinated eyelines: Leon looks up-depth at monitor
	leon.look_at_target(Vector2(750, 350))
	leon.set_expression("confused", "open")
	await wait_sec(0.9)

	# Nita turns back to Leon, puzzled
	nita.set_facing(-1)
	nita.look_at_target(leon.global_position)
	nita.set_expression("confused", "open")
	await wait_sec(0.7)

	# Bo's gaze locks onto the massive sealed door at the far right background
	bo.set_facing(1)
	bo.look_at_target(Vector2(1050, 400))
	bo.set_expression("serious", "open")
	await wait_sec(0.9)

	# Massive hydraulic clunk & rumble as sealed blast door grinds open
	print("[STORY @ %.2fs] Sealed door opens!" % elapsed_story_time)
	_play_sfx(sfx_door_open, 3.5)
	_camera_shake(5.0, 0.4)
	if facility:
		facility.open_sealed_door()
	await wait_sec(2.0)

	# =========================================================================
	# SHOT 6: Creature Emerges (37.5s–44.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 6: Creature Emerges" % elapsed_story_time)
	_camera_pan_zoom(Vector2(780, 410), Vector2(0.88, 0.88), 1.2)

	# BGM surges back with heavy intensity
	if bgm_player:
		var tw_bgm = create_tween()
		tw_bgm.tween_property(bgm_player, "volume_db", -9.0, 1.5)

	# Creature emerges from dark chamber at deep blast door (Y=510)
	if creature:
		creature.emerge()
		await wait_for_signal_or_timeout(creature.emerged, 2.2)

	_camera_shake(9.0, 0.45)
	_play_sfx(sfx_crash, 3.5)
	await wait_sec(0.6)

	# Character reactions in sharp depth contrast:
	# Leon (foreground): concerned, eyes wide
	leon.set_expression("confused", "wide")
	leon.set_facing(1)
	await wait_sec(0.7)

	# Nita (midground): grinning, fist clenched — eager for a real fight!
	nita.set_facing(1)
	_play_nita_vo(vo_nita_eager)
	nita.excited_react()
	await wait_sec(0.7)

	# Bo (background): combat focused, draws bow, calls out leadership command
	bo.alert_stance()
	_play_bo_vo(vo_bo_lead)
	await wait_sec(0.8)

	# =========================================================================
	# SHOT 7: Second Fight — The Creature (44.5s–63.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 7: Second Fight — The Creature" % elapsed_story_time)

	# --- Beat 1: Creature ground pound slam, shockwave spreads across lanes ---
	_camera_pan_zoom(Vector2(700, 420), Vector2(0.92, 0.92), 0.6)
	if creature:
		creature.slam_attack()
	_camera_shake(12.0, 0.45)
	_play_sfx(sfx_crash, 3.5)
	await wait_sec(0.5)

	# Leon evasive roll along foreground lane
	leon.dodge_roll(1, -10.0)
	await wait_sec(0.4)

	# Nita jumps back in midground
	nita.dodge_jump(-40.0, 10.0)
	_play_sfx(sfx_jump, -0.5)
	await wait_sec(0.4)

	# Bo steady retreat along background lane
	bo.steady_retreat_2d(Vector2(90, 485))
	await wait_sec(0.5)

	# --- Beat 2: Bo fires arrows at creature's eye from deep lane ---
	print("[STORY @ %.2fs] Bo fires at creature" % elapsed_story_time)
	_camera_pan_zoom(Vector2(420, 420), Vector2(1.0, 1.0), 0.5)
	bo.precise_aim()
	await wait_sec(0.6)

	bo.trigger_attack()
	_play_sfx(sfx_bo_atk, 1.2)

	# AUTHORITATIVE: wait for arrows to hit creature
	if creature:
		await wait_for_signal_or_timeout(creature.hit_received, 1.5)
	_camera_shake(5.0, 0.25)
	await wait_sec(0.6)

	# --- Beat 3: Creature swipes massive arm at Bo ---
	print("[STORY @ %.2fs] Creature swipes at the group" % elapsed_story_time)
	if creature:
		creature.swipe_attack(-1)
	_camera_shake(7.0, 0.3)
	await wait_sec(0.3)

	# Bo backsteps smoothly avoiding claws
	bo.dodge_back(60.0, 0.0)
	await wait_sec(0.6)

	# --- Beat 4: Leon flanking rush along foreground lane ---
	print("[STORY @ %.2fs] Leon flanking attack" % elapsed_story_time)
	_camera_pan_zoom(Vector2(620, 420), Vector2(1.0, 1.0), 0.5)
	leon.tactical_reposition_2d(Vector2(720, 565))
	await wait_sec(0.5)

	leon.combat_ready_stance()
	await wait_sec(0.3)
	leon.trigger_attack()
	_play_sfx(sfx_leon_atk, 1.2)

	# AUTHORITATIVE: wait for blades to strike creature
	if creature:
		await wait_for_signal_or_timeout(creature.hit_received, 1.0)
	_camera_shake(6.0, 0.25)
	await wait_sec(0.6)

	# --- Beat 5: Creature spins and charges down midground lane ---
	print("[STORY @ %.2fs] Creature charges!" % elapsed_story_time)
	_camera_pan_zoom(Vector2(550, 420), Vector2(0.95, 0.95), 0.4)
	if creature:
		creature.charge_forward(140.0, 15.0)
	_camera_shake(9.0, 0.35)
	_play_sfx(sfx_crash, 2.5)
	await wait_sec(0.6)

	# Leon agile roll under the charge into foreground right
	_play_sfx(sfx_jump, 0.0)
	leon.dodge_roll(-1, 10.0)
	await wait_sec(0.5)

	# --- Beat 6: Nita aggressive shockwave attack staggers creature ---
	print("[STORY @ %.2fs] Nita aggressive attack" % elapsed_story_time)
	_camera_pan_zoom(Vector2(500, 420), Vector2(1.05, 1.05), 0.5)
	nita.battle_windup()
	_play_nita_vo(vo_nita_kill)
	await wait_sec(0.5)

	nita.set_facing(1)
	nita.trigger_attack()
	_play_sfx(sfx_nita_atk, 1.6)

	# AUTHORITATIVE: wait for shockwave to hit creature
	if creature:
		await wait_for_signal_or_timeout(creature.hit_received, 1.2)
	_play_sfx2(sfx_crash, 1.5)
	_camera_shake(8.0, 0.32)
	await wait_sec(0.6)

	# --- Beat 7: LEON SUPER — Tactical Invisibility & Deep Flank ---
	print("[STORY @ %.2fs] Leon activates Super!" % elapsed_story_time)
	_camera_pan_zoom(Vector2(600, 410), Vector2(1.1, 1.1), 0.5)

	# Creature raises both arms to crush Leon
	if creature:
		creature.swipe_attack(-1)
	await wait_sec(0.2)

	# Leon activates Super and vanishes in smoke puff!
	_play_sfx(sfx_leon_invis, 2.0)
	_play_leon_vo(vo_leon_ulti)
	leon.trigger_super()
	if has_node("/root/VFXManager"):
		get_node("/root/VFXManager").spawn_vfx("SMOKE_BOMB", leon.global_position + Vector2(0, -32))
	await wait_sec(0.6)

	# Creature slams empty floor, looks around confused
	_camera_shake(6.0, 0.25)

	# Leon quietly moves DEEP into the background lane behind creature (Y=485, scale drops naturally)
	leon.tactical_reposition_2d(Vector2(960, 485), 0.5)
	await wait_sec(0.8)

	# Leon reappears behind creature in the deep lane!
	_play_sfx(sfx_leon_invis_end, 1.2)
	if has_node("/root/VFXManager"):
		get_node("/root/VFXManager").spawn_vfx("SMOKE_BOMB", leon.global_position + Vector2(0, -32))
	leon.end_super()
	await wait_sec(0.6)

	# --- Beat 8: Coordinated 3-way multiplane final assault ---
	print("[STORY @ %.2fs] Coordinated final assault on creature" % elapsed_story_time)
	_camera_pan_zoom(Vector2(550, 420), Vector2(0.93, 0.93), 0.6)

	# Bo fires cover volley from deep left
	bo.trigger_attack()
	_play_sfx(sfx_bo_atk, 1.2)
	await wait_sec(0.4)

	# Leon fires point-blank blade barrage from deep right behind creature
	leon.set_facing(-1)
	leon.trigger_attack()
	_play_sfx2(sfx_leon_atk, 0.8)
	await wait_sec(0.4)

	# Nita delivers massive shockwave finisher from midground center
	nita.battle_windup()
	await wait_sec(0.3)
	nita.set_facing(1)
	nita.trigger_attack()
	_play_sfx(sfx_nita_atk, 2.2)

	# AUTHORITATIVE: wait for final hit
	if creature:
		await wait_for_signal_or_timeout(creature.hit_received, 1.5)
	await wait_sec(0.4)

	# =========================================================================
	# SHOT 8: Creature Defeated (63.5s–68.0s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 8: Creature Defeated" % elapsed_story_time)
	_camera_pan_zoom(Vector2(700, 410), Vector2(1.05, 1.05), 0.8)

	# Final massive collapse impact
	_play_sfx(sfx_crash, 5.0)
	_camera_shake(16.0, 0.55)
	if facility:
		facility.spawn_debris(creature.global_position + Vector2(-30, 0))
		facility.spawn_debris(creature.global_position + Vector2(20, -40))
		facility.spawn_smoke(creature.global_position)
	await wait_sec(2.2)

	# Dust cloud slowly settles...
	await wait_sec(1.0)

	# =========================================================================
	# SHOT 9: FALSE RESOLUTION (68.0s–73.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 9: False Resolution" % elapsed_story_time)
	_camera_pan_zoom(Vector2(450, 430), Vector2(1.02, 1.02), 1.0)

	# Regroup in staging triangle: Leon foreground, Nita midground, Bo background
	leon.tactical_reposition_2d(Vector2(480, 565), 0.6)
	leon.set_facing(-1)
	leon.victory_relax()
	_play_leon_vo(vo_leon_kill)
	await wait_sec(1.2)

	nita.tactical_reposition_2d(Vector2(380, 530), 0.5)
	nita.pumped_celebration()
	_play_nita_vo(vo_nita_kill)
	await wait_sec(1.2)

	bo.steady_retreat_2d(Vector2(220, 490), 0.5)
	bo.weapon_lower()
	await wait_sec(1.2)

	# Moment of pure quiet relief
	await wait_sec(0.8)

	# =========================================================================
	# SHOT 10: FINAL ESCALATION — Chambers Opening (73.5s–81.5s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 10: Final Escalation — Chambers Opening" % elapsed_story_time)

	# SUDDEN HEAVY METALLIC CLUNK!
	_play_sfx(sfx_crash, 3.0)
	_camera_shake(7.0, 0.3)
	await wait_sec(0.5)

	# Chamber 0 opens on far left
	_play_sfx2(sfx_door_open, 2.0)
	if facility:
		facility.open_chamber_door(0)
	await wait_sec(0.8)
	# Red glowing eyes ignite in the dark!
	if facility:
		facility.activate_chamber_eyes(0)
	await wait_sec(0.8)

	# SECOND CLUNK! Chamber 1 opens
	_play_sfx(sfx_crash, 3.0)
	_play_sfx2(sfx_door_open, 2.0)
	_camera_shake(8.0, 0.35)
	if facility:
		facility.open_chamber_door(1)
	await wait_sec(0.8)
	# Amber glowing eyes ignite!
	if facility:
		facility.activate_chamber_eyes(1)
	await wait_sec(0.8)

	# RAPID CASCADE: ALL REMAINING CHAMBERS OPEN SIMULTANEOUSLY!
	print("[STORY @ %.2fs] ALL CHAMBERS OPENING!" % elapsed_story_time)
	_play_sfx(sfx_crash, 5.0)
	_camera_shake(14.0, 0.6)
	_camera_pan_zoom(Vector2(500, 390), Vector2(0.8, 0.8), 1.0)

	if facility:
		facility.open_chamber_door(2)
		facility.open_chamber_door(3)
		facility.open_chamber_door(4)
	await wait_sec(0.8)

	# Glowing eyes light up across all chambers (red, yellow, green, pink)!
	if facility:
		facility.activate_chamber_eyes(2)
		facility.activate_chamber_eyes(3)
		facility.activate_chamber_eyes(4)
	await wait_sec(0.6)

	# Warning lights reactivate — flashing faster and brighter
	if facility:
		facility.flicker_warning_lights()
	_play_sfx(sfx_flicker, 3.0)
	await wait_sec(0.8)

	# Nita's celebration abruptly freezes into shock
	nita.set_expression("shocked", "wide")
	nita.set_facing(-1)
	await wait_sec(0.5)

	# Bo readies weapon again — serious stance
	bo.alert_stance()
	bo.set_expression("serious", "open")
	await wait_sec(0.5)

	# =========================================================================
	# SHOT 11: "RUN." & Comedic Escape (81.5s–87.0s)
	# =========================================================================
	print("[STORY @ %.2fs] Shot 11: Leon says RUN" % elapsed_story_time)
	_camera_pan_zoom(Vector2(460, 440), Vector2(1.15, 1.15), 0.4)

	# Leon realizes the sheer scale of the nightmare they unleashed
	leon.concern_realize()
	await wait_sec(1.2)

	# Leon whips his head around to Nita and Bo — panicked waving
	leon.set_facing(-1)
	leon.panic_run_signal()
	_play_leon_vo(vo_leon_hurt)
	await wait_sec(0.7)

	# All three TURN AND SPRINT LEFT AT FULL SPEED ACROSS 3 DEPTH LANES!
	# Passing behind foreground framing pillars at X=740 and X=60
	print("[STORY @ %.2fs] EVERYONE RUNS!" % elapsed_story_time)
	_camera_pan_zoom(Vector2(200, 420), Vector2(0.95, 0.95), 0.8)

	bo.run_to_2d(Vector2(-360, 490))
	nita.run_to_2d(Vector2(-420, 530))
	leon.run_to_2d(Vector2(-320, 575))
	await wait_sec(1.8)

	# =========================================================================
	# CUT TO BLACK
	# =========================================================================
	print("[STORY @ %.2fs] CUT TO BLACK" % elapsed_story_time)
	if blackout_rect:
		var tw_fade = create_tween()
		tw_fade.tween_property(blackout_rect, "modulate:a", 1.0, 0.5)
		await tw_fade.finished

	# BGM fade out
	if bgm_player:
		var tw_bgm = create_tween()
		tw_bgm.tween_property(bgm_player, "volume_db", -40.0, 0.6)

	await wait_sec(1.0)

	story_completed.emit()
	print("[STORY] 'The Thing They Shouldn't Have Opened' — COMPLETE!")
	print("[STORY] Total runtime: %.2fs" % elapsed_story_time)
	get_tree().quit()
