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
		leon1.position = Vector2(-280, 520)
		leon1.set_view(ActorLeon.ViewMode.SIDE)
		leon1.set_facing(1)
		leon1.set_expression("neutral", "open")

	if leon2:
		leon2.position = Vector2(800, 520)
		leon2.set_view(ActorLeon.ViewMode.SIDE)
		leon2.set_facing(-1)
		leon2.visible = false
		leon2.set_expression("neutral", "open")

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
	# SHOT 1: Normal Entrance & Back View Boarding (0.0s - 7.5s)
	# =========================================================================
	print("[STORY 0.0s] Shot 1: Normal Entrance")
	_set_camera_view(Vector2(0, 420), Vector2(1.0, 1.0))
	leon1.set_view(ActorLeon.ViewMode.SIDE)
	leon1.position = Vector2(-280, 520)
	leon1.set_facing(1)
	await wait_sec(0.5)

	# Elevator 1 dings and opens in the lobby
	elevator1.set_display("1", true)
	await wait_sec(0.3)
	elevator1.open_doors(1.0)
	await wait_sec(0.5)

	# Leon1 plays start voice and walks to the elevator (true synchronized walk)
	_play_voice("res://assets/audio/voices/leon/leon_start_vo_01.ogg")
	leon1.walk_to(-25.0, 160.0)
	await leon1.walk_finished
	await wait_sec(0.4)

	# Leon turns to face INTO the elevator (BACK VIEW)!
	print("[STORY] Leon faces into elevator (Back View)")
	leon1.set_view(ActorLeon.ViewMode.BACK)
	await wait_sec(0.5)

	# Leon presses button 3 with his arm
	leon1.press_button_animation()
	await wait_sec(0.18)
	elevator1.press_button(3)
	await wait_sec(0.6)

	# Leon steps forward into the cabin
	create_tween().tween_property(leon1, "position:x", 0.0, 0.4)
	await wait_sec(0.5)

	# Elevator doors close in front of Leon (Doors are at z_index = 10, fully covering him!)
	elevator1.close_doors(1.0)
	await wait_sec(1.5)

	# =========================================================================
	# SHOT 2: Inside Elevator Cabin (Dynamic Interior Close-Up + Sudden Jolt) (7.5s - 18.0s)
	# =========================================================================
	print("[STORY 7.5s] Shot 2: Inside Elevator Cabin & Sudden Jolt")
	# Punch camera directly inside elevator cabin!
	_tween_camera(Vector2(0, 435), Vector2(2.1, 2.1), 0.6)

	# Inside elevator, doors are behind camera, Leon is in FRONT VIEW facing forward/doors!
	elevator1.set_doors_visible(false)
	leon1.position = Vector2(0, 520)
	leon1.set_view(ActorLeon.ViewMode.FRONT)
	leon1.set_expression("neutral", "open")
	elevator1.start_hum()

	# Display counts floors
	await wait_sec(2.0)
	elevator1.set_display("2")
	await wait_sec(2.0)
	elevator1.set_display("3")
	await wait_sec(1.0)

	# SUDDEN JOLT! Abrupt brake screech and violent cabin shake
	elevator1.stop_hum()
	elevator1.jolt()
	_shake_camera(8.0, 0.45)
	elevator1.set_lights(true, true) # flicker ceiling lights
	leon1.set_expression("confused", "wide")
	leon1.position.y = 512
	create_tween().tween_property(leon1, "position:y", 520.0, 0.15)

	# Silence & unease
	await wait_sec(3.0)

	# =========================================================================
	# SHOT 3: Button Pressing Escalation (Close-Up Inside Cabin) (18.0s - 27.5s)
	# =========================================================================
	print("[STORY 18.0s] Shot 3: Interior Button Pressing Escalation")
	_tween_camera(Vector2(15, 435), Vector2(2.25, 2.25), 0.5)

	# Retries button 3
	leon1.press_button_animation()
	await wait_sec(0.18)
	elevator1.press_button(3)
	await wait_sec(1.0)

	# Nothing happens. Leon gets frustrated!
	leon1.set_expression("angry", "angry")
	await wait_sec(0.6)

	# Rapid pressing of multiple buttons
	for b_id in [1, 2, 4, 3, 2, 1]:
		leon1.press_button_animation()
		elevator1.press_button(b_id)
		await wait_sec(0.22)

	# Exhausted pause, slumps shoulders
	await wait_sec(1.0)
	leon1.set_expression("hurt", "closed")
	await wait_sec(2.0)

	# =========================================================================
	# SHOT 4: Unfamiliar Hallway Reveal (27.5s - 37.0s)
	# =========================================================================
	print("[STORY 27.5s] Shot 4: Unfamiliar Hallway Reveal")
	elevator1.set_display("???", true)
	await wait_sec(1.0)

	# Swap background to Strange Hallway before doors open
	if lobby_env:
		lobby_env.visible = false
	if hallway_env:
		hallway_env.visible = true

	# Restore doors and pull camera back to hallway perspective as doors open
	elevator1.set_doors_visible(true)
	_tween_camera(Vector2(120, 420), Vector2(1.05, 1.05), 1.0)
	elevator1.open_doors(1.2)
	await wait_sec(0.8)

	# Leon is stunned by what he sees outside
	leon1.set_expression("shocked", "wide")
	await wait_sec(1.2)

	# Leon switches to Side View and cautiously steps out into the hallway
	leon1.set_view(ActorLeon.ViewMode.SIDE)
	leon1.walk_to(160.0, 90.0)
	await leon1.walk_finished
	leon1.set_expression("confused", "open")
	await wait_sec(2.0)

	# =========================================================================
	# SHOT 5: The Disappearance (37.0s - 44.0s)
	# =========================================================================
	print("[STORY 37.0s] Shot 5: The Disappearance")
	# Doors close behind Leon
	elevator1.close_doors(1.0)
	await wait_sec(1.4)

	# Leon turns around to look at the elevator
	leon1.set_facing(-1)
	await wait_sec(0.5)

	# Elevator disappears! Replaced by solid wall with weird eye art
	elevator1.visible = false
	leon1.set_expression("scared", "wide")
	_shake_camera(4.0, 0.3)

	# Flinches back 20 pixels
	create_tween().tween_property(leon1, "position:x", 185.0, 0.25)
	await wait_sec(3.0)

	# =========================================================================
	# SHOT 6: The Second Elevator & Mirroring (44.0s - 53.0s)
	# =========================================================================
	print("[STORY 44.0s] Shot 6: The Second Elevator & Mirroring")
	# Camera pans down the hallway toward Elevator 2
	_tween_camera(Vector2(550, 420), Vector2(0.9, 0.9), 2.0)

	# Leon turns and walks forward toward Elevator 2
	leon1.walk_to(620.0, 140.0)
	await leon1.walk_finished
	await wait_sec(0.5)

	# Elevator 2 doors open automatically with chime!
	elevator2.set_display("2", true)
	elevator2.open_doors(1.0)
	leon2.visible = true
	leon2.set_view(ActorLeon.ViewMode.SIDE)
	leon2.set_facing(-1)
	leon2.set_expression("neutral", "open")
	await wait_sec(1.0)

	# Two-shot framing of the two Leons staring
	_tween_camera(Vector2(710, 425), Vector2(1.25, 1.25), 0.8)
	await wait_sec(1.4)

	# Leon1 points at himself
	_point_at_self(leon1)
	await wait_sec(0.3)

	# Leon2 mirrors him!
	_point_at_self(leon2)
	leon1.set_expression("scared", "wide")
	leon2.set_expression("scared", "wide")
	await wait_sec(1.8)

	# =========================================================================
	# SHOT 7: Entering & The Blackout (53.0s - 59.0s)
	# =========================================================================
	print("[STORY 53.0s] Shot 7: Entering & Blackout")
	leon1.walk_to(750.0, 80.0)
	await leon1.walk_finished
	leon1.set_facing(-1)

	# Elevator 2 doors close in front of both Leons
	elevator2.close_doors(1.0)
	await wait_sec(1.2)

	# SUDDEN BLACKOUT!
	if blackout_rect:
		blackout_rect.modulate.a = 1.0
	elevator2.set_lights(false, true)
	_play_voice("res://assets/audio/voices/leon/leon_hurt_vo_01.ogg")

	# Darkness hold (1.5s)
	await wait_sec(1.5)

	# Lights return: SECOND LEON IS GONE!
	leon2.visible = false
	elevator2.set_lights(true, false)
	if blackout_rect:
		blackout_rect.modulate.a = 0.0

	leon1.set_expression("scared", "wide")
	leon1.set_facing(1)
	await wait_sec(0.5)
	leon1.set_facing(-1)
	await wait_sec(0.5)
	leon1.set_facing(1)
	await wait_sec(0.8)

	# =========================================================================
	# SHOT 8: Return to Normal & Phone Message (59.0s - 64.0s)
	# =========================================================================
	print("[STORY 59.0s] Shot 8: Return to Normal & Phone Message")
	elevator2.set_display("1", true)
	await wait_sec(0.6)

	# Restore normal lobby background
	if hallway_env:
		hallway_env.visible = false
	if lobby_env:
		lobby_env.visible = true
		lobby_env.position = Vector2(800, 520)

	_tween_camera(Vector2(700, 420), Vector2(1.1, 1.1), 0.8)
	elevator2.open_doors(1.0)
	await wait_sec(0.6)

	# Leon steps out into normal lobby
	leon1.walk_to(620.0, 120.0)
	await leon1.walk_finished
	leon1.set_expression("happy", "open")
	await wait_sec(1.0)

	# Phone notification pops up!
	phone_ui.show_notification("Your elevator ride has been rated ⭐⭐⭐⭐⭐.")
	await wait_sec(0.5)
	leon1.set_expression("confused", "open")
	await wait_sec(2.2)
	phone_ui.hide_notification()

	# =========================================================================
	# SHOT 9: Final Reveal & Cut to Black (64.0s - 67.0s)
	# =========================================================================
	print("[STORY 64.0s] Shot 9: Final Reveal")
	elevator2.open_doors(1.2)
	leon2.position = Vector2(800, 520)
	leon2.visible = true
	leon2.set_view(ActorLeon.ViewMode.SIDE)
	leon2.set_facing(-1)
	leon2.set_expression("happy", "open")

	await wait_sec(0.6)
	leon1.set_facing(1)
	leon1.set_expression("shocked", "wide")

	_tween_camera(Vector2(780, 435), Vector2(1.45, 1.45), 1.6)
	await wait_sec(2.2)

	# CUT TO BLACK!
	print("[STORY] CUT TO BLACK")
	if blackout_rect:
		blackout_rect.modulate.a = 1.0

	story_completed.emit()
	print("Story sequence completed successfully. Holding black until auto-quit.")
	if auto_quit_duration > 0.0:
		var target_frames = int(round(auto_quit_duration * 60.0))
		while Engine.get_frames_drawn() < target_frames:
			await RenderingServer.frame_post_draw
	else:
		await wait_sec(1.0)
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
