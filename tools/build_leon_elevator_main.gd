@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Assembling Leon Elevator Main Production Scene...")

	var root = Node2D.new()
	root.name = "LeonElevatorMain"
	root.set_script(load("res://scenes/videos/leon_elevator/story_director.gd"))

	# 1. Camera2D
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, 420)
	camera.zoom = Vector2(1.0, 1.0)
	root.add_child(camera)
	camera.owner = root

	# 2. Ground StaticBody2D (Collision for physics support)
	var ground = StaticBody2D.new()
	ground.name = "Ground"
	ground.position = Vector2(400, 560)
	root.add_child(ground)
	ground.owner = root

	var ground_shape = CollisionShape2D.new()
	ground_shape.name = "CollisionShape2D"
	var box = RectangleShape2D.new()
	box.size = Vector2(2400, 80)
	ground_shape.shape = box
	ground.add_child(ground_shape)
	ground_shape.owner = root

	# 3. Environments Node
	var envs = Node2D.new()
	envs.name = "Environments"
	root.add_child(envs)
	envs.owner = root

	# 3a. Normal Lobby
	var lobby_scn = load("res://scenes/videos/leon_elevator/normal_lobby.tscn")
	if lobby_scn:
		var lobby = lobby_scn.instantiate()
		lobby.name = "NormalLobby"
		lobby.position = Vector2(0, 520)
		envs.add_child(lobby)
		lobby.owner = root

	# 3b. Strange Hallway
	var hallway_scn = load("res://scenes/videos/leon_elevator/hallway.tscn")
	if hallway_scn:
		var hallway = hallway_scn.instantiate()
		hallway.name = "StrangeHallway"
		hallway.position = Vector2(0, 520)
		hallway.visible = false
		envs.add_child(hallway)
		hallway.owner = root

	# 3c. Elevator 1 (Cabin 1)
	var elevator_scn = load("res://scenes/videos/leon_elevator/elevator.tscn")
	if elevator_scn:
		var el1 = elevator_scn.instantiate()
		el1.name = "Elevator1"
		el1.position = Vector2(0, 520)
		envs.add_child(el1)
		el1.owner = root

		# 3d. Elevator 2 (Cabin 2 at Hallway end)
		var el2 = elevator_scn.instantiate()
		el2.name = "Elevator2"
		el2.position = Vector2(800, 520)
		envs.add_child(el2)
		el2.owner = root

	# 4. Characters Node
	var chars = Node2D.new()
	chars.name = "Characters"
	root.add_child(chars)
	chars.owner = root

	var leon_scn = load("res://scenes/leon.tscn")
	if leon_scn:
		# Leon 1 (Hero)
		var l1 = leon_scn.instantiate()
		l1.name = "Leon1"
		l1.position = Vector2(-280, 520)
		chars.add_child(l1)
		l1.owner = root

		# Leon 2 (Doppelganger)
		var l2 = leon_scn.instantiate()
		l2.name = "Leon2"
		l2.position = Vector2(800, 520)
		l2.visible = false
		chars.add_child(l2)
		l2.owner = root

	# 5. UI Node
	var ui = Node2D.new()
	ui.name = "UI"
	root.add_child(ui)
	ui.owner = root

	# 5a. Phone Notification
	var phone_scn = load("res://scenes/videos/leon_elevator/phone_notification.tscn")
	if phone_scn:
		var phone = phone_scn.instantiate()
		phone.name = "PhoneNotification"
		ui.add_child(phone)
		phone.owner = root

	# 5b. Blackout Overlay
	var blackout_layer = CanvasLayer.new()
	blackout_layer.name = "BlackoutOverlay"
	blackout_layer.layer = 50
	ui.add_child(blackout_layer)
	blackout_layer.owner = root

	var blackout_rect = ColorRect.new()
	blackout_rect.name = "ColorRect"
	blackout_rect.anchors_preset = Control.PRESET_FULL_RECT
	blackout_rect.anchor_right = 1.0
	blackout_rect.anchor_bottom = 1.0
	blackout_rect.offset_right = 1920.0
	blackout_rect.offset_bottom = 1080.0
	blackout_rect.color = Color(0, 0, 0, 1)
	blackout_rect.modulate.a = 0.0
	blackout_layer.add_child(blackout_rect)
	blackout_rect.owner = root

	# 6. Audio Node
	var audio = Node2D.new()
	audio.name = "Audio"
	root.add_child(audio)
	audio.owner = root

	var voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	audio.add_child(voice_player)
	voice_player.owner = root

	var door_creak = AudioStreamPlayer.new()
	door_creak.name = "DoorCreak"
	audio.add_child(door_creak)
	door_creak.owner = root

	# Pack and Save Scene
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err != OK:
		printerr("[ERROR] Failed to pack scene: ", err)
		quit(1)
		return

	var out_path = "res://scenes/videos/leon_elevator/leon_elevator_main.tscn"
	err = ResourceSaver.save(packed, out_path)
	if err != OK:
		printerr("[ERROR] Failed to save scene: ", err)
		quit(1)
		return

	print("[BUILD SUCCESS] Saved scene to ", out_path)
	quit(0)
