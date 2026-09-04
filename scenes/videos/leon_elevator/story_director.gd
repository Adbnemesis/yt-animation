class_name StoryDirector
extends Node2D

# Master Story Director for Leon — "Stuck in the Elevator"
# Controls the entire 66-second narrative sequence deterministically.

const ElevatorCabinClass = preload("res://scenes/videos/leon_elevator/elevator.gd")
const PhoneNotificationClass = preload("res://scenes/videos/leon_elevator/phone_notification.gd")

signal story_completed()

@onready var camera: Camera2D = get_node_or_null("Camera2D")

# Environments
@onready var lobby_env: Node2D = get_node_or_null("Environments/NormalLobby")
@onready var hallway_env: Node2D = get_node_or_null("Environments/StrangeHallway")
@onready var elevator1: Node2D = get_node_or_null("Environments/Elevator1")
@onready var elevator2: Node2D = get_node_or_null("Environments/Elevator2")

# Characters
@onready var leon1: CharacterController = get_node_or_null("Characters/Leon1")
@onready var leon2: CharacterController = get_node_or_null("Characters/Leon2")

# UI & Overlays
@onready var phone_ui: CanvasLayer = get_node_or_null("UI/PhoneNotification")
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
	# Start sequence after one frame to ensure nodes and physics spaces are settled
	get_tree().create_timer(0.1).timeout.connect(start_story)

func _process(delta: float) -> void:
	if is_running:
		elapsed_story_time += delta
		if auto_quit_duration > 0.0 and elapsed_story_time >= auto_quit_duration:
			print("[STORY] Auto-quit reached at ", elapsed_story_time, "s")
			get_tree().quit(0)

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
		elevator1.set_display("1", false)

	# Elevator 2 at (800, 520) in hallway
	if elevator2:
		elevator2.position = Vector2(800, 520)
		elevator2.visible = true
		elevator2.set_display("2", false)

	# Characters
	if leon1:
		leon1.position = Vector2(-280, 520)
		leon1.facing_direction = 1
		leon1.change_state(leon1.State.IDLE)
		_set_leon_face(leon1, "neutral", "open")

	if leon2:
		leon2.position = Vector2(800, 520)
		leon2.facing_direction = -1
		leon2.visible = false
		leon2.change_state(leon2.State.IDLE)
		_set_leon_face(leon2, "neutral", "open")

	# Overlays
	if blackout_rect:
		blackout_rect.modulate.a = 0.0

func start_story() -> void:
	if is_running:
		return
	is_running = true
	elapsed_story_time = 0.0
	_execute_story_coroutine()

func _execute_story_coroutine() -> void:
	# =========================================================================
	# SHOT 1: Normal Entrance (0.0s - 7.5s)
	# =========================================================================
	print("[STORY 0.0s] Shot 1: Normal Entrance")
	await get_tree().create_timer(0.4).timeout

	# Elevator 1 dings and opens in the lobby
	elevator1.set_display("1", true)
	await get_tree().create_timer(0.3).timeout
	elevator1.open_doors(1.0)
	await get_tree().create_timer(0.6).timeout

	# Leon1 walks in
	_play_voice("res://assets/audio/voices/leon/leon_start_vo_01.ogg")
	_walk_leon_to(leon1, 0.0, 160.0, 1.5)
	await get_tree().create_timer(1.6).timeout

	# Leon1 turns to face front/panel
	leon1.facing_direction = 1
	_set_leon_face(leon1, "neutral", "open")
	await get_tree().create_timer(0.5).timeout

	# Leon1 presses button 3
	_animate_button_press(leon1)
	await get_tree().create_timer(0.3).timeout
	elevator1.press_button(3)
	await get_tree().create_timer(0.8).timeout

	# Doors close smoothly
	elevator1.close_doors(1.0)
	await get_tree().create_timer(1.2).timeout

	# =========================================================================
	# SHOT 2: Movement & Sudden Jolt Stop (7.5s - 16.5s)
	# =========================================================================
	print("[STORY 7.5s] Shot 2: Movement & Jolt Stop")
	_tween_camera(Vector2(0, 425), Vector2(1.25, 1.25), 1.0)
	elevator1.start_hum()

	# Display counts floors
	await get_tree().create_timer(1.5).timeout
	elevator1.set_display("2")
	await get_tree().create_timer(1.8).timeout
	elevator1.set_display("3")
	await get_tree().create_timer(1.0).timeout

	# SUDDEN JOLT!
	elevator1.stop_hum()
	elevator1.jolt()
	_shake_camera(6.0, 0.4)
	elevator1.set_lights(true, true) # flicker lights
	_set_leon_face(leon1, "confused", "wide")
	leon1.position.y = 512 # small physical recoil bounce
	create_tween().tween_property(leon1, "position:y", 520.0, 0.15)

	# Silence & unease
	await get_tree().create_timer(2.8).timeout

	# =========================================================================
	# SHOT 3: Button Pressing Escalation (16.5s - 25.5s)
	# =========================================================================
	print("[STORY 16.5s] Shot 3: Button Pressing Escalation")
	_tween_camera(Vector2(45, 420), Vector2(1.4, 1.4), 0.8)

	# Leon1 steps toward button panel
	_walk_leon_to(leon1, 45.0, 140.0, 0.5)
	await get_tree().create_timer(0.6).timeout

	# Tries button 3 again
	_animate_button_press(leon1)
	await get_tree().create_timer(0.2).timeout
	elevator1.press_button(3)
	await get_tree().create_timer(0.8).timeout

	# Nothing happens. Leon gets frustrated!
	_set_leon_face(leon1, "angry", "open")
	await get_tree().create_timer(0.5).timeout

	# Rapid pressing of multiple buttons
	for b_id in [1, 2, 4, 3, 2, 1]:
		_animate_button_press(leon1)
		elevator1.press_button(b_id)
		await get_tree().create_timer(0.18).timeout

	# Exhausted pause
	await get_tree().create_timer(0.8).timeout
	_set_leon_face(leon1, "hurt", "closed")
	await get_tree().create_timer(1.2).timeout

	# =========================================================================
	# SHOT 4: Unfamiliar Hallway Reveal (25.5s - 34.5s)
	# =========================================================================
	print("[STORY 25.5s] Shot 4: Unfamiliar Hallway Reveal")
	# Chime dings and display glitches to "???"
	elevator1.set_display("???", true)
	await get_tree().create_timer(0.8).timeout

	# Swap background to Strange Hallway before doors open
	if lobby_env:
		lobby_env.visible = false
	if hallway_env:
		hallway_env.visible = true

	# Pull camera back to wide hallway shot
	_tween_camera(Vector2(120, 420), Vector2(1.05, 1.05), 1.0)
	elevator1.open_doors(1.2)
	await get_tree().create_timer(0.6).timeout

	# Leon is stunned by what he sees outside
	_set_leon_face(leon1, "shocked", "wide")
	await get_tree().create_timer(1.0).timeout

	# Leon cautiously steps out into the hallway
	_walk_leon_to(leon1, 160.0, 100.0, 1.8)
	await get_tree().create_timer(2.0).timeout
	leon1.change_state(leon1.State.IDLE)
	_set_leon_face(leon1, "confused", "open")
	await get_tree().create_timer(1.0).timeout

	# =========================================================================
	# SHOT 5: The Disappearance (34.5s - 41.5s)
	# =========================================================================
	print("[STORY 34.5s] Shot 5: The Disappearance")
	# Doors close behind Leon
	elevator1.close_doors(1.0)
	await get_tree().create_timer(1.2).timeout

	# Leon turns around to look at the elevator
	leon1.facing_direction = -1
	await get_tree().create_timer(0.4).timeout

	# The elevator disappears! Replaced by solid wall with weird eye art
	elevator1.visible = false
	_set_leon_face(leon1, "scared", "wide")
	_shake_camera(4.0, 0.3)

	# Flinches back 20 pixels
	create_tween().tween_property(leon1, "position:x", 185.0, 0.25)
	await get_tree().create_timer(2.5).timeout

	# =========================================================================
	# SHOT 6: The Second Elevator & Mirroring (41.5s - 50.0s)
	# =========================================================================
	print("[STORY 41.5s] Shot 6: The Second Elevator & Mirroring")
	# Camera pans down the hallway toward Elevator 2
	_tween_camera(Vector2(550, 420), Vector2(0.9, 0.9), 1.8)

	# Leon turns and walks forward toward Elevator 2
	leon1.facing_direction = 1
	_walk_leon_to(leon1, 620.0, 140.0, 2.5)
	await get_tree().create_timer(2.2).timeout

	# Elevator 2 doors open automatically with a chime!
	elevator2.set_display("2", true)
	elevator2.open_doors(1.0)
	leon2.visible = true
	leon2.facing_direction = -1
	_set_leon_face(leon2, "neutral", "open")
	await get_tree().create_timer(0.8).timeout

	# Camera frames two-shot of the two Leons staring
	_tween_camera(Vector2(710, 425), Vector2(1.25, 1.25), 0.8)
	await get_tree().create_timer(1.2).timeout

	# Leon1 points at himself (attack windup / hand raise)
	_point_at_self(leon1)
	await get_tree().create_timer(0.3).timeout

	# Leon2 MIRRORS him! Points at himself!
	_point_at_self(leon2)
	_set_leon_face(leon1, "scared", "wide")
	_set_leon_face(leon2, "scared", "wide")
	await get_tree().create_timer(1.6).timeout

	# =========================================================================
	# SHOT 7: Entering & The Blackout (50.0s - 56.5s)
	# =========================================================================
	print("[STORY 50.0s] Shot 7: Entering & Blackout")
	# Leon1 cautiously steps inside Elevator 2 next to Leon2
	_walk_leon_to(leon1, 750.0, 80.0, 1.2)
	await get_tree().create_timer(1.3).timeout
	leon1.facing_direction = -1

	# Doors close
	elevator2.close_doors(1.0)
	await get_tree().create_timer(1.1).timeout

	# SUDDEN BLACKOUT!
	if blackout_rect:
		blackout_rect.modulate.a = 1.0
	elevator2.set_lights(false, true)
	_play_voice("res://assets/audio/voices/leon/leon_hurt_vo_01.ogg")

	# Darkness hold (1.5s)
	await get_tree().create_timer(1.5).timeout

	# Lights return: SECOND LEON IS GONE!
	leon2.visible = false
	elevator2.set_lights(true, false)
	if blackout_rect:
		blackout_rect.modulate.a = 0.0

	_set_leon_face(leon1, "scared", "wide")
	# Leon frantically looks left and right
	leon1.facing_direction = 1
	await get_tree().create_timer(0.4).timeout
	leon1.facing_direction = -1
	await get_tree().create_timer(0.4).timeout
	leon1.facing_direction = 1
	await get_tree().create_timer(0.8).timeout

	# =========================================================================
	# SHOT 8: Return to Normal & Phone Message (56.5s - 62.5s)
	# =========================================================================
	print("[STORY 56.5s] Shot 8: Return to Normal & Phone Message")
	# Elevator dings! Display shows "1"
	elevator2.set_display("1", true)
	await get_tree().create_timer(0.6).timeout

	# Restore normal lobby background behind elevator
	if hallway_env:
		hallway_env.visible = false
	if lobby_env:
		lobby_env.visible = true
		lobby_env.position = Vector2(800, 520) # Aligned with elevator 2 exit

	# Doors open to familiar lobby
	_tween_camera(Vector2(700, 420), Vector2(1.1, 1.1), 0.8)
	elevator2.open_doors(1.0)
	await get_tree().create_timer(0.5).timeout

	# Leon steps out into normal lobby
	_walk_leon_to(leon1, 620.0, 120.0, 1.2)
	await get_tree().create_timer(1.3).timeout
	leon1.change_state(leon1.State.IDLE)
	_set_leon_face(leon1, "happy", "open") # Relieved!
	await get_tree().create_timer(0.8).timeout

	# BUZZ-BUZZ! Phone notification pops up!
	phone_ui.show_notification("Your elevator ride has been rated ⭐⭐⭐⭐⭐.")
	await get_tree().create_timer(0.4).timeout
	_set_leon_face(leon1, "confused", "open")
	await get_tree().create_timer(2.0).timeout
	phone_ui.hide_notification()

	# =========================================================================
	# SHOT 9: Final Reveal & Cut to Black (62.5s - 66.5s)
	# =========================================================================
	print("[STORY 62.5s] Shot 9: Final Reveal")
	# Elevator doors slowly start opening behind Leon
	elevator2.open_doors(1.4)
	# Leon2 is revealed inside, smiling!
	leon2.position = Vector2(800, 520)
	leon2.facing_direction = -1
	leon2.visible = true
	_set_leon_face(leon2, "happy", "open") # Knowing confident smile

	# Leon1 slowly turns around
	await get_tree().create_timer(0.6).timeout
	leon1.facing_direction = 1
	_set_leon_face(leon1, "shocked", "wide")

	# Camera slowly pushes in on the smiling second Leon
	_tween_camera(Vector2(780, 435), Vector2(1.45, 1.45), 1.8)

	# Hold on smiling Leon 2 for 2.2 seconds
	await get_tree().create_timer(2.4).timeout

	# CUT TO BLACK!
	print("[STORY 66.0s] CUT TO BLACK")
	if blackout_rect:
		blackout_rect.modulate.a = 1.0

	await get_tree().create_timer(1.0).timeout
	is_running = false
	story_completed.emit()
	print("Story sequence completed successfully.")
	get_tree().quit(0)

# --- Helper Functions ---

func _set_leon_face(leon_node: CharacterController, expr: String, eyes: String = "open") -> void:
	if not leon_node:
		return
	var face = leon_node.find_child("Face", true, false)
	if face and face.has_method("set_expression"):
		face.set_expression(expr)
		face.set_eye_state(eyes)

func _walk_leon_to(leon_node: CharacterController, target_x: float, speed: float, duration: float) -> void:
	if not leon_node:
		return
	leon_node.facing_direction = 1 if target_x > leon_node.position.x else -1
	leon_node.change_state(leon_node.State.WALK)
	var tw = create_tween()
	tw.tween_property(leon_node, "position:x", target_x, duration)
	tw.tween_callback(func():
		leon_node.change_state(leon_node.State.IDLE)
	)

func _point_at_self(leon_node: CharacterController) -> void:
	if not leon_node:
		return
	var arm = leon_node.find_child("arm_R_upper", true, false)
	if arm:
		var tw = create_tween()
		tw.tween_property(arm, "rotation", -0.95, 0.25)
		tw.tween_interval(1.2)
		tw.tween_property(arm, "rotation", 0.0, 0.25)

func _animate_button_press(leon_node: CharacterController) -> void:
	if not leon_node:
		return
	var arm = leon_node.find_child("arm_R_upper", true, false)
	if arm:
		var tw = create_tween()
		tw.tween_property(arm, "rotation", -0.75, 0.12)
		tw.tween_property(arm, "rotation", 0.0, 0.12)

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
