class_name StoryDirector
extends Node2D

# Master Story Director for Leon — "Stuck in the Elevator"
# Controls the entire 67-second narrative sequence deterministically.

const ElevatorCabinClass = preload("res://scenes/videos/leon_elevator/elevator.gd")
const PhoneNotificationClass = preload("res://scenes/videos/leon_elevator/phone_notification.gd")
const ActorLeonClass = preload("res://scenes/videos/leon_elevator/actor_leon.gd")

signal story_completed()

@onready var camera: Camera2D = get_node_or_null("Camera2D")

# Environments
@onready var lobby_env: Node2D = get_node_or_null("Environments/NormalLobby")
@onready var hallway_env: Node2D = get_node_or_null("Environments/StrangeHallway")
@onready var elevator1: ElevatorCabin = get_node_or_null("Environments/Elevator1")
@onready var elevator2: ElevatorCabin = get_node_or_null("Environments/Elevator2")

# Characters
@onready var leon1: ActorLeon = get_node_or_null("Characters/Leon1")
@onready var leon2: ActorLeon = get_node_or_null("Characters/Leon2")

# UI & Overlays
@onready var phone_ui: PhoneNotification = get_node_or_null("UI/PhoneNotification")
@onready var blackout_rect: ColorRect = get_node_or_null("UI/BlackoutOverlay/ColorRect")

# Ambient / Voice Audio
@onready var voice_player: AudioStreamPlayer = get_node_or_null("Audio/VoicePlayer")
@onready var sfx_door_creak: AudioStreamPlayer = get_node_or_null("Audio/DoorCreak")
@onready var bgm_player: AudioStreamPlayer = get_node_or_null("Audio/BGMPlayer")

var is_running: bool = false
var elapsed_story_time: float = 0.0
var auto_quit_duration: float = -1.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

	_init_scene_state()
	# Start sequence after first frame renders
	RenderingServer.frame_post_draw.connect(start_story, CONNECT_ONE_SHOT)

func _process(delta: float) -> void:
	if is_running:
		elapsed_story_time += delta

func _init_scene_state() -> void:
	# Camera initial setup: framing Lobby and Elevator 1
	if camera:
		camera.position = Vector2(0, 420)
		camera.zoom = Vector2(1.0, 1.0)

	# Environments
	if lobby_env:
		lobby_env.visible = true
		lobby_env.position = Vector2(0, 520)
	if hallway_env:
		hallway_env.visible = false
		hallway_env.position = Vector2(0, 520)

	# Elevator 1 at (0, 520) with closed doors
	if elevator1:
		elevator1.position = Vector2(0, 520)
		elevator1.visible = true
		elevator1.set_doors_visible(true)
		elevator1.set_display("1", false)

	# Elevator 2 at (800, 520) in hallway
	if elevator2:
		elevator2.position = Vector2(800, 520)
		elevator2.visible = true
		elevator2.set_doors_visible(true)
		elevator2.set_display("2", false)

	# Characters
	if leon1:
		leon1.position = Vector2(-280, 540)
		leon1.set_view(ActorLeon.ViewMode.SIDE)
		leon1.set_facing(1)
		leon1.set_expression("neutral", "open")
		leon1.set_in_cabin(false)

	if leon2:
		leon2.position = Vector2(800, 509)
		leon2.set_view(ActorLeon.ViewMode.SIDE)
		leon2.set_facing(-1)
		leon2.visible = false
		leon2.set_expression("neutral", "open")
		leon2.set_in_cabin(true)

	# Overlays
	if blackout_rect:
		blackout_rect.modulate.a = 0.0

func start_story() -> void:
	if is_running:
		return
	is_running = true
	elapsed_story_time = 0.0
	_execute_story_coroutine()

# Deterministic frame-based wait (ensures exact 60fps pacing in Movie Maker mode)
func wait_sec(seconds: float) -> void:
	var total_frames = int(round(seconds * 60.0))
	for i in range(total_frames):
		await RenderingServer.frame_post_draw

func _execute_story_coroutine() -> void:
	# =========================================================================
	# SHOT 1: Normal Entrance & Back View Boarding (0.0s - 6.8s)
	# =========================================================================
	print("[STORY 0.0s] Shot 1: Normal Entrance")
	_set_camera_view(Vector2(0, 420), Vector2(1.0, 1.0))
	_start_bgm("res://assets/audio/bgm/the_complex.mp3", -14.0)
	leon1.set_in_cabin(false) # Foreground z_index = 15: in front of doors
	leon1.set_view(ActorLeon.ViewMode.SIDE)
	leon1.position = Vector2(-280, 540)
	leon1.set_facing(1)
	await wait_sec(0.3)

	# Elevator 1 dings and opens in the lobby
	elevator1.set_display("1", true)
	await wait_sec(0.25)
	elevator1.open_doors(0.8)
	await wait_sec(0.4)

	# Leon1 plays start voice and walks to the elevator in foreground
	_play_voice("res://assets/audio/voices/leon/leon_start_vo_01.ogg")
	leon1.walk_to(15.0, 170.0) # Walks in foreground at Y=540
	await leon1.walk_finished
	await wait_sec(0.3)

	# Leon turns to face INTO the elevator (BACK VIEW)!
	print("[STORY] Leon faces into elevator (Back View)")
	leon1.set_view(ActorLeon.ViewMode.BACK)
	await wait_sec(0.2)

	# Leon steps forward into the cabin depth (Y: 540 -> 509)!
	var tw_step = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_step.tween_property(leon1, "position:y", 509.0, 0.35)
	await tw_step.finished

	# Leon is now inside the cabin: transition to cabin layer (z_index = 2)
	leon1.set_in_cabin(true)
	await wait_sec(0.15)

	# Leon reaches out right arm and presses button 3 directly on the visible panel!
	leon1.press_button_animation()
	await wait_sec(0.12)
	elevator1.press_button(3)
	await wait_sec(0.5)

	# Leon steps to cabin center
	create_tween().tween_property(leon1, "position:x", 0.0, 0.35)
	await wait_sec(0.35)

	# Elevator doors close in front of Leon (Doors are at z_index = 10, fully covering him!)
	elevator1.close_doors(0.8)
	await wait_sec(1.0)

	# =========================================================================
	# SHOT 2: Inside Elevator Cabin (Dynamic Interior Close-Up + Sudden Jolt)
	# =========================================================================
	print("[STORY] Shot 2: Inside Elevator Cabin & Sudden Jolt")
	# Punch camera directly inside elevator cabin!
	_tween_camera(Vector2(0, 435), Vector2(2.1, 2.1), 0.5)

	# Inside elevator, doors are behind camera, Leon is in FRONT VIEW facing forward/doors!
	elevator1.set_doors_visible(false)
	leon1.position = Vector2(0, 509)
	leon1.set_view(ActorLeon.ViewMode.FRONT)
	leon1.set_expression("neutral", "open")
	elevator1.start_hum()

	# Display counts floors with comfortable, natural pacing
	await wait_sec(1.8)
	elevator1.set_display("2", true)
	await wait_sec(1.8)
	elevator1.set_display("3", true)
	await wait_sec(0.8)

	# SUDDEN JOLT! Abrupt brake screech and violent cabin shake
	elevator1.stop_hum()
	_duck_bgm(-24.0, 0.15)
	elevator1.jolt()
	_shake_camera(8.0, 0.45)
	elevator1.set_lights(true, true) # flicker ceiling lights
	leon1.set_expression("confused", "wide")
	leon1.position.y = 510
	create_tween().tween_property(leon1, "position:y", 509.0, 0.15)

	# Silence & unease, then music gently recovers
	await wait_sec(1.6)
	_duck_bgm(-14.0, 0.8)
	await wait_sec(1.2)

	# =========================================================================
	# SHOT 3: Button Pressing Escalation (Close-Up Inside Cabin)
	# =========================================================================
	print("[STORY] Shot 3: Interior Button Pressing Escalation")
	# Leon stands at X = 15.0 with button panel fully visible on screen-right
	create_tween().tween_property(leon1, "position:x", 15.0, 0.3)
	_tween_camera(Vector2(40, 435), Vector2(2.15, 2.15), 0.4)
	await wait_sec(0.35)

	# Retries button 3 on panel
	leon1.press_button_animation()
	await wait_sec(0.12)
	elevator1.press_button(3)
	await wait_sec(0.9)

	# Nothing happens. Leon gets frustrated!
	leon1.set_expression("angry", "angry")
	await wait_sec(0.5)

	# Rapid pressing of multiple buttons directly on the panel!
	for b_id in [1, 2, 4, 3, 2, 1]:
		leon1.press_button_animation()
		await wait_sec(0.09)
		elevator1.press_button(b_id)
		await wait_sec(0.13)

	# Exhausted pause, slumps shoulders, returns to center
	await wait_sec(0.6)
	leon1.set_expression("hurt", "closed")
	create_tween().tween_property(leon1, "position:x", 0.0, 0.4)
	await wait_sec(1.1)

	# =========================================================================
	# SHOT 4: Unfamiliar Hallway Reveal
	# =========================================================================
	print("[STORY] Shot 4: Unfamiliar Hallway Reveal")
	elevator1.set_display("???", true)
	leon1.set_expression("shocked", "wide")
	await wait_sec(1.4)

	# Swap background to Strange Hallway before doors open
	if lobby_env:
		lobby_env.visible = false
	if hallway_env:
		hallway_env.visible = true

	# Restore doors and pull camera back to hallway perspective as doors open
	elevator1.set_doors_visible(true)
	_tween_camera(Vector2(120, 420), Vector2(1.05, 1.05), 0.8)
	elevator1.open_doors(0.8)
	await wait_sec(0.7)

	# Leon is stunned by what he sees outside
	leon1.set_expression("shocked", "wide")
	await wait_sec(0.7)

	# Leon switches to Side View and steps forward out into the hallway foreground!
	leon1.set_view(ActorLeon.ViewMode.SIDE)
	leon1.set_facing(1)
	# Stepping out from cabin (0, 509) into hallway (160, 540)
	leon1.walk_to(160.0, 120.0, 540.0)
	await wait_sec(0.25)
	leon1.set_in_cabin(false) # Foreground z_index = 15! In front of doors/frame!
	await leon1.walk_finished
	leon1.set_expression("confused", "open")
	await wait_sec(1.5)

	# =========================================================================
	# SHOT 5: The Disappearance
	# =========================================================================
	print("[STORY] Shot 5: The Disappearance")
	# Doors close behind Leon
	elevator1.close_doors(0.8)
	await wait_sec(0.9)

	# Leon turns around to look at the elevator
	leon1.set_facing(-1)
	await wait_sec(0.35)

	# Elevator disappears! Replaced by solid wall with weird eye art
	elevator1.visible = false
	leon1.set_expression("scared", "wide")
	_shake_camera(4.0, 0.3)

	# Flinches back 25 pixels
	create_tween().tween_property(leon1, "position:x", 185.0, 0.2)
	await wait_sec(1.8)

	# =========================================================================
	# SHOT 6: The Second Elevator & Mirroring
	# =========================================================================
	print("[STORY] Shot 6: The Second Elevator & Mirroring")
	# Camera pans down the hallway toward Elevator 2
	_tween_camera(Vector2(550, 420), Vector2(0.9, 0.9), 1.8)

	# Leon turns and walks forward toward Elevator 2 (foreground z_index = 15)
	leon1.walk_to(560.0, 160.0, 540.0)
	await leon1.walk_finished
	await wait_sec(0.35)

	# Elevator 2 doors open automatically with chime!
	elevator2.set_display("2", true)
	elevator2.open_doors(0.9)
	leon2.position = Vector2(800, 509)
	leon2.visible = true
	leon2.set_view(ActorLeon.ViewMode.SIDE)
	leon2.set_facing(-1)
	leon2.set_expression("neutral", "open")
	leon2.set_in_cabin(true) # Leon 2 is inside cabin (z_index = 5)
	await wait_sec(0.8)

	# Two-shot framing of the two Leons staring across the threshold
	_tween_camera(Vector2(680, 425), Vector2(1.15, 1.15), 0.7)
	await wait_sec(1.2)

	# Leon1 points at himself
	_point_at_self(leon1)
	await wait_sec(0.35)

	# Leon2 mirrors him!
	_point_at_self(leon2)
	leon1.set_expression("scared", "wide")
	leon2.set_expression("scared", "wide")
	await wait_sec(1.8)

	# =========================================================================
	# SHOT 7: Entering & The Blackout
	# =========================================================================
	print("[STORY] Shot 7: Entering & Blackout")
	# Leon 1 steps forward into Elevator 2 cabin depth (Y: 540 -> 509)
	leon1.walk_to(760.0, 135.0, 509.0)
	await leon1.walk_finished
	leon1.set_facing(-1)
	leon1.set_in_cabin(true) # Both Leons now inside cabin (z_index = 5)

	# Elevator 2 doors close in front of both Leons (Doors z_index = 10)
	elevator2.close_doors(0.8)
	await wait_sec(0.8)

	# SUDDEN BLACKOUT!
	_duck_bgm(-80.0, 0.05)
	if blackout_rect:
		blackout_rect.modulate.a = 1.0
	elevator2.set_lights(false, true)
	_play_voice("res://assets/audio/voices/leon/leon_hurt_vo_01.ogg")

	# Darkness hold
	await wait_sec(1.6)

	# Lights return: SECOND LEON IS GONE!
	leon2.visible = false
	elevator2.set_lights(true, false)
	_duck_bgm(-14.0, 0.6)
	if blackout_rect:
		blackout_rect.modulate.a = 0.0

	leon1.set_expression("scared", "wide")
	leon1.set_facing(1)
	await wait_sec(0.35)
	leon1.set_facing(-1)
	await wait_sec(0.35)
	leon1.set_facing(1)
	await wait_sec(0.5)

	# =========================================================================
	# SHOT 8: Return to Normal & Phone Message
	# =========================================================================
	print("[STORY] Shot 8: Return to Normal & Phone Message")
	elevator2.set_display("1", true)
	await wait_sec(0.35)

	# Restore normal lobby background
	if hallway_env:
		hallway_env.visible = false
	if lobby_env:
		lobby_env.visible = true
		lobby_env.position = Vector2(800, 520)

	_tween_camera(Vector2(680, 425), Vector2(1.1, 1.1), 0.6)
	elevator2.open_doors(0.8)
	await wait_sec(0.4)

	# Leon steps forward out into normal lobby foreground!
	leon1.walk_to(560.0, 140.0, 540.0)
	await wait_sec(0.25)
	leon1.set_in_cabin(false) # Foreground z_index = 15!
	await leon1.walk_finished
	leon1.set_expression("happy", "open")
	await wait_sec(0.6)

	# Phone notification pops up!
	phone_ui.show_notification("Your elevator ride has been rated ⭐⭐⭐⭐⭐.")
	await wait_sec(0.35)
	leon1.set_expression("confused", "open")
	await wait_sec(2.4)
	phone_ui.hide_notification()
	await wait_sec(0.35)

	# =========================================================================
	# SHOT 9: Final Reveal & Smooth Fade to Black
	# =========================================================================
	print("[STORY] Shot 9: Final Reveal")
	elevator2.open_doors(0.8)
	leon2.position = Vector2(800, 509)
	leon2.visible = true
	leon2.set_view(ActorLeon.ViewMode.SIDE)
	leon2.set_facing(-1)
	leon2.set_expression("happy", "open")
	leon2.set_in_cabin(true) # Inside cabin (z_index = 5)

	await wait_sec(0.4)
	leon1.set_facing(1)
	leon1.set_expression("shocked", "wide")

	_tween_camera(Vector2(760, 435), Vector2(1.35, 1.35), 1.0)
	await wait_sec(1.5)

	# Smooth fade to black (1.2s fade)
	print("[STORY] FADE TO BLACK")
	_fade_bgm_out(1.2)
	if blackout_rect:
		var tw = create_tween()
		tw.tween_property(blackout_rect, "modulate:a", 1.0, 1.2)
		await tw.finished

	await wait_sec(0.4) # Clean dramatic black hold before exit

	story_completed.emit()
	print("Story sequence completed successfully.")
	is_running = false
	get_tree().quit(0)

# --- Helper Functions ---

func _set_camera_view(pos: Vector2, zoom_val: Vector2) -> void:
	if camera:
		camera.position = pos
		camera.zoom = zoom_val

func _point_at_self(actor: ActorLeon) -> void:
	if not actor or not actor.side_view:
		return
	var arm = actor.side_view.find_child("arm_R_upper", true, false)
	if arm:
		var tw = create_tween()
		tw.tween_property(arm, "rotation", -0.95, 0.25)
		tw.tween_interval(1.2)
		tw.tween_property(arm, "rotation", 0.0, 0.25)

func _tween_camera(target_pos: Vector2, target_zoom: Vector2, duration: float) -> void:
	if not camera:
		return
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel(true)
	tw.tween_property(camera, "position", target_pos, duration)
	tw.tween_property(camera, "zoom", target_zoom, duration)

func _shake_camera(intensity: float, duration: float) -> void:
	if not camera:
		return
	var orig_pos = camera.position
	var tw = create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(camera, "position", orig_pos + offset, 0.04)
	tw.tween_property(camera, "position", orig_pos, 0.04)

func _play_voice(stream_path: String) -> void:
	if voice_player and ResourceLoader.exists(stream_path):
		voice_player.stream = load(stream_path)
		voice_player.play()

func _start_bgm(stream_path: String = "res://assets/audio/bgm/the_complex.mp3", vol_db: float = -14.0) -> void:
	if bgm_player:
		if ResourceLoader.exists(stream_path):
			bgm_player.stream = load(stream_path)
		bgm_player.volume_db = vol_db
		bgm_player.play()

func _duck_bgm(target_db: float, duration: float) -> void:
	if bgm_player and bgm_player.playing:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(bgm_player, "volume_db", target_db, duration)

func _fade_bgm_out(duration: float) -> void:
	if bgm_player and bgm_player.playing:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(bgm_player, "volume_db", -80.0, duration)
		tw.tween_callback(bgm_player.stop)
