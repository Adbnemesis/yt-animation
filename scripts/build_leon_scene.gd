@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Production-Ready Leon 2D Puppet Rig (scenes/leon.tscn)...")
	var root = CharacterBody2D.new()
	root.name = "Leon"
	root.set_script(load("res://scripts/character_controller.gd"))

	# 1. Collision Shape (Capsule covering from ground y=0 up to top of hood y=-96)
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var capsule = CapsuleShape2D.new()
	capsule.radius = 22.0
	capsule.height = 96.0
	col.shape = capsule
	col.position = Vector2(0, -48)
	root.add_child(col)
	col.owner = root

	# 2. Visuals Root
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	visuals.z_index = 5
	visuals.z_as_relative = false
	root.add_child(visuals)
	visuals.owner = root

	# 3. Skeleton2D
	var skel = Skeleton2D.new()
	skel.name = "Skeleton"
	visuals.add_child(skel)
	skel.owner = root

	# Texture Preloads
	var tex_hood = load("res://assets/leon/hood.svg")
	var tex_face_base = load("res://assets/leon/face_base.svg")
	var tex_torso = load("res://assets/leon/torso_jacket.svg")
	var tex_tail = load("res://assets/leon/tail.svg")
	var tex_arm_l = load("res://assets/leon/arm_L.svg")
	var tex_arm_r = load("res://assets/leon/arm_R.svg")
	var tex_hand_l = load("res://assets/leon/hand_L.svg")
	var tex_hand_r = load("res://assets/leon/hand_R.svg")
	var tex_leg_l = load("res://assets/leon/leg_L.svg")
	var tex_leg_r = load("res://assets/leon/leg_R.svg")
	var tex_foot_l = load("res://assets/leon/foot_L.svg")
	var tex_foot_r = load("res://assets/leon/foot_R.svg")

	var tex_eye_l = load("res://assets/leon/eye_L.svg")
	var tex_eye_r = load("res://assets/leon/eye_R.svg")
	var tex_pupil_l = load("res://assets/leon/pupil_L.svg")
	var tex_pupil_r = load("res://assets/leon/pupil_R.svg")
	var tex_brow_l = load("res://assets/leon/eyebrow_L.svg")
	var tex_brow_r = load("res://assets/leon/eyebrow_R.svg")
	var tex_mouth = load("res://assets/leon/mouth_neutral.svg")

	var create_bone = func(b_name: String, rest_pos: Vector2, parent: Node, is_leaf: bool = false) -> Bone2D:
		var b = Bone2D.new()
		b.name = b_name
		b.position = rest_pos
		b.rest = Transform2D(0.0, rest_pos)
		b.auto_calculate_length_and_angle = false
		b.length = 14.0 if is_leaf else 16.0
		parent.add_child(b)
		b.owner = root
		return b

	var create_sprite = func(s_name: String, tex: Texture2D, offset: Vector2, z_idx: int, parent: Node) -> Sprite2D:
		var s = Sprite2D.new()
		s.name = s_name
		s.texture = tex
		s.offset = offset
		s.z_index = z_idx
		parent.add_child(s)
		s.owner = root
		return s

	# BONE HIERARCHY (Standard Production 2D Puppet Structure)
	# root: Pelvis / Hip Center at (0, -38)
	var b_root = create_bone.call("root", Vector2(0, -38), skel)

	# Tail: Attached to root, curves behind, Z = -2
	var b_tail = create_bone.call("tail", Vector2(-16, 14), b_root, true)
	create_sprite.call("TailSprite", tex_tail, Vector2(-12, 8), -2, b_tail)

	# Left Leg: Back Leg (Z = -1)
	# Hip -> Knee -> Ankle -> Foot
	var b_leg_l_upper = create_bone.call("leg_L_upper", Vector2(-12, 10), b_root)
	create_sprite.call("LegSpriteL", tex_leg_l, Vector2(0, 8), -1, b_leg_l_upper)

	var b_leg_l_lower = create_bone.call("leg_L_lower", Vector2(0, 16), b_leg_l_upper)
	var b_foot_l = create_bone.call("foot_L", Vector2(0, 14), b_leg_l_lower, true)
	create_sprite.call("FootSpriteL", tex_foot_l, Vector2(2, 4), -1, b_foot_l)

	# Right Leg: Front Leg (Z = 1)
	# Hip -> Knee -> Ankle -> Foot
	var b_leg_r_upper = create_bone.call("leg_R_upper", Vector2(12, 10), b_root)
	create_sprite.call("LegSpriteR", tex_leg_r, Vector2(0, 8), 1, b_leg_r_upper)

	var b_leg_r_lower = create_bone.call("leg_R_lower", Vector2(0, 16), b_leg_r_upper)
	var b_foot_r = create_bone.call("foot_R", Vector2(0, 14), b_leg_r_lower, true)
	create_sprite.call("FootSpriteR", tex_foot_r, Vector2(2, 4), 1, b_foot_r)

	# Torso: Green Hoodie Jacket (Z = 0)
	var b_torso = create_bone.call("torso", Vector2(0, -6), b_root)
	create_sprite.call("TorsoSprite", tex_torso, Vector2(0, -16), 0, b_torso)

	# Left Arm: Back Arm (Z = -1)
	# Shoulder -> Elbow -> Wrist -> Hand
	var b_arm_l_upper = create_bone.call("arm_L_upper", Vector2(-20, -20), b_torso)
	create_sprite.call("ArmSpriteL", tex_arm_l, Vector2(0, 14), -1, b_arm_l_upper)

	var b_arm_l_lower = create_bone.call("arm_L_lower", Vector2(0, 16), b_arm_l_upper)
	var b_hand_l = create_bone.call("hand_L", Vector2(0, 14), b_arm_l_lower, true)
	create_sprite.call("HandSpriteL", tex_hand_l, Vector2(0, 6), -1, b_hand_l)

	# Right Arm: Front Arm (Z = 1)
	# Shoulder -> Elbow -> Wrist -> Hand
	var b_arm_r_upper = create_bone.call("arm_R_upper", Vector2(20, -20), b_torso)
	create_sprite.call("ArmSpriteR", tex_arm_r, Vector2(0, 14), 1, b_arm_r_upper)

	var b_arm_r_lower = create_bone.call("arm_R_lower", Vector2(0, 16), b_arm_r_upper)
	var b_hand_r = create_bone.call("hand_R", Vector2(0, 14), b_arm_r_lower, true)
	create_sprite.call("HandSpriteR", tex_hand_r, Vector2(0, 6), 1, b_hand_r)

	# Neck & Head (Z = 2)
	var b_neck = create_bone.call("neck", Vector2(0, -26), b_torso)
	var b_head = create_bone.call("head", Vector2(0, -8), b_neck, true)
	create_sprite.call("HoodSprite", tex_hood, Vector2(0, -32), 2, b_head)

	# FaceSystem: Decoupled facial hierarchy inside Hood Opening
	var face = Node2D.new()
	face.name = "Face"
	face.position = Vector2(0, -20)
	face.z_index = 2
	face.set_script(load("res://scripts/face_controller.gd"))
	b_head.add_child(face)
	face.owner = root

	var face_base = Sprite2D.new()
	face_base.name = "FaceBase"
	face_base.texture = tex_face_base
	face_base.position = Vector2(0, 4)
	face.add_child(face_base)
	face_base.owner = root

	var eye_l = Sprite2D.new()
	eye_l.name = "EyeL"
	eye_l.texture = tex_eye_l
	eye_l.position = Vector2(-14, 0)
	face.add_child(eye_l)
	eye_l.owner = root

	var pupil_l = Sprite2D.new()
	pupil_l.name = "PupilL"
	pupil_l.texture = tex_pupil_l
	pupil_l.position = Vector2.ZERO
	eye_l.add_child(pupil_l)
	pupil_l.owner = root

	var eye_r = Sprite2D.new()
	eye_r.name = "EyeR"
	eye_r.texture = tex_eye_r
	eye_r.position = Vector2(14, 0)
	face.add_child(eye_r)
	eye_r.owner = root

	var pupil_r = Sprite2D.new()
	pupil_r.name = "PupilR"
	pupil_r.texture = tex_pupil_r
	pupil_r.position = Vector2.ZERO
	eye_r.add_child(pupil_r)
	pupil_r.owner = root

	var brow_l = Sprite2D.new()
	brow_l.name = "BrowL"
	brow_l.texture = tex_brow_l
	brow_l.position = Vector2(-14, -12)
	face.add_child(brow_l)
	brow_l.owner = root

	var brow_r = Sprite2D.new()
	brow_r.name = "BrowR"
	brow_r.texture = tex_brow_r
	brow_r.position = Vector2(14, -12)
	face.add_child(brow_r)
	brow_r.owner = root

	var mouth = Sprite2D.new()
	mouth.name = "Mouth"
	mouth.texture = tex_mouth
	mouth.position = Vector2(0, 10)
	mouth.z_index = 2
	face.add_child(mouth)
	mouth.owner = root

	# 4. VFX Attachment Points
	var vfx = Node2D.new()
	vfx.name = "VFXAttachmentPoints"
	root.add_child(vfx)
	vfx.owner = root

	var hit_point = Marker2D.new()
	hit_point.name = "HitPoint"
	hit_point.position = Vector2(0, -48)
	vfx.add_child(hit_point)
	hit_point.owner = root

	var head_point = Marker2D.new()
	head_point.name = "HeadPoint"
	head_point.position = Vector2(0, -114)
	vfx.add_child(head_point)
	head_point.owner = root

	var candy_point = Marker2D.new()
	candy_point.name = "CandyPoint"
	candy_point.position = Vector2(16, -70)
	vfx.add_child(candy_point)
	candy_point.owner = root

	# 5. AnimationPlayer Setup
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimPlayer"
	root.add_child(anim_player)
	anim_player.owner = root

	var anim_lib = AnimationLibrary.new()

	# RESET Animation (Rest Pose)
	var a_reset = Animation.new()
	a_reset.length = 0.001
	var reset_tracks = {
		"Visuals/Skeleton/root:position": Vector2(0, -38),
		"Visuals/Skeleton/root:rotation": 0.0,
		"Visuals/Skeleton/root/torso:rotation": 0.0,
		"Visuals/Skeleton/root/torso/neck:rotation": 0.0,
		"Visuals/Skeleton/root/torso/neck/head:rotation": 0.0,
		"Visuals/Skeleton/root/torso/arm_L_upper:rotation": 0.0,
		"Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation": 0.0,
		"Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation": 0.0,
		"Visuals/Skeleton/root/torso/arm_R_upper:rotation": 0.0,
		"Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation": 0.0,
		"Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation": 0.0,
		"Visuals/Skeleton/root/leg_L_upper:rotation": 0.0,
		"Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation": 0.0,
		"Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation": 0.0,
		"Visuals/Skeleton/root/leg_R_upper:rotation": 0.0,
		"Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation": 0.0,
		"Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation": 0.0,
		"Visuals/Skeleton/root/tail:rotation": 0.0
	}
	for track_path in reset_tracks.keys():
		var idx = a_reset.add_track(Animation.TYPE_VALUE)
		a_reset.track_set_path(idx, track_path)
		a_reset.track_insert_key(idx, 0.0, reset_tracks[track_path])
	anim_lib.add_animation("RESET", a_reset)

	# Helper for adding value animation tracks
	var add_track_keys = func(anim: Animation, path: String, times: Array, values: Array, interp: int = Animation.INTERPOLATION_CUBIC) -> void:
		var idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(idx, path)
		anim.track_set_interpolation_type(idx, interp)
		if interp == Animation.INTERPOLATION_NEAREST:
			anim.value_track_set_update_mode(idx, Animation.UPDATE_DISCRETE)
		for i in range(times.size()):
			anim.track_insert_key(idx, times[i], values[i])

	# 1. IDLE Animation (2.0s, Organic Breathing, Subtle Sway, Resting Stance)
	var a_idle = Animation.new()
	a_idle.length = 2.0
	a_idle.loop_mode = Animation.LOOP_LINEAR

	add_track_keys.call(a_idle, "Visuals/Skeleton/root:position",
		[0.0, 1.0, 2.0],
		[Vector2(0, -38.0), Vector2(0, -39.2), Vector2(0, -38.0)])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso:rotation",
		[0.0, 0.5, 1.0, 1.5, 2.0],
		[0.0, 0.015, 0.0, -0.015, 0.0])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/neck:rotation",
		[0.0, 0.6, 1.2, 1.7, 2.0],
		[0.0, -0.01, 0.005, -0.005, 0.0])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/neck/head:rotation",
		[0.0, 0.65, 1.15, 1.65, 2.0],
		[-0.01, -0.02, 0.01, 0.02, -0.01])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_L_upper:rotation",
		[0.0, 1.0, 2.0],
		[-0.03, 0.02, -0.03])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation",
		[0.0, 1.0, 2.0],
		[0.10, 0.15, 0.10])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_R_upper:rotation",
		[0.0, 1.0, 2.0],
		[0.05, -0.02, 0.05])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation",
		[0.0, 1.0, 2.0],
		[0.18, 0.24, 0.18])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/leg_L_upper:rotation", [0.0, 2.0], [-0.02, -0.02])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", [0.0, 2.0], [0.02, 0.02])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", [0.0, 2.0], [0.0, 0.0])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/leg_R_upper:rotation", [0.0, 2.0], [0.02, 0.02])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", [0.0, 2.0], [0.02, 0.02])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", [0.0, 2.0], [0.0, 0.0])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/tail:rotation",
		[0.0, 0.7, 1.4, 2.0],
		[0.0, 0.06, -0.05, 0.0])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/neck/head/Face:expression", [0.0], ["neutral"], Animation.INTERPOLATION_NEAREST)
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/neck/head/Face:eye_state", [0.0], ["open"], Animation.INTERPOLATION_NEAREST)
	anim_lib.add_animation("idle", a_idle)

	# 2. CLASSICAL 6-PHASE WALK CYCLE (0.80s, Classical Ground Stride, Snappy Cartoon Timing)
	# Key Times: 0.00 (Contact 1), 0.10 (Down 1), 0.20 (Passing 1), 0.30 (Up 1),
	#            0.40 (Contact 2), 0.50 (Down 2), 0.60 (Passing 2), 0.70 (Up 2), 0.80 (Contact 1)
	var a_walk = Animation.new()
	a_walk.length = 0.80
	a_walk.loop_mode = Animation.LOOP_LINEAR
	var walk_times = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80]

	# Root Vertical Bobbing: Dips at 0.10 & 0.50 (Cushion), Rises at 0.30 & 0.70 (Apex)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root:position", walk_times, [
		Vector2(0, -38.0), Vector2(0, -36.2), Vector2(0, -38.5), Vector2(0, -40.0),
		Vector2(0, -38.0), Vector2(0, -36.2), Vector2(0, -38.5), Vector2(0, -40.0), Vector2(0, -38.0)
	])

	# Root Sway / Hip Weight Shift
	add_track_keys.call(a_walk, "Visuals/Skeleton/root:rotation", walk_times, [
		-0.02, -0.035, -0.015, 0.015, 0.02, 0.035, 0.015, -0.015, -0.02
	])

	# Torso Forward Lean & Thoracic Compression
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso:rotation", walk_times, [
		0.05, 0.07, 0.03, 0.04, 0.05, 0.07, 0.03, 0.04, 0.05
	])

	# Neck Stabilization
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck:rotation", walk_times, [
		-0.02, -0.03, -0.01, -0.02, -0.02, -0.03, -0.01, -0.02, -0.02
	])

	# Head Counter-Rotation (Gaze Stabilized Forward)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck/head:rotation", walk_times, [
		-0.03, -0.01, -0.04, -0.02, -0.03, -0.01, -0.04, -0.02, -0.03
	])

	# LEFT LEG (Back Layer, Z=-1): Contact (0.0) -> Cushion (0.1) -> Passing (0.2) -> Push-off (0.3) -> Swing (0.5-0.7)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper:rotation", walk_times, [
		0.38, 0.20, -0.05, -0.42, -0.35, -0.15, 0.22, 0.42, 0.38
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", walk_times, [
		0.00, 0.28, 0.08, 0.10, 0.25, 0.55, 0.65, 0.12, 0.00
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", walk_times, [
		-0.35, 0.00, 0.00, 0.32, 0.28, -0.10, -0.15, -0.32, -0.35
	])

	# RIGHT LEG (Front Layer, Z=+1): Push-off (0.0) -> Swing (0.1-0.3) -> Contact (0.4) -> Cushion (0.5) -> Passing (0.6)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper:rotation", walk_times, [
		-0.35, -0.15, 0.22, 0.42, 0.38, 0.20, -0.05, -0.42, -0.35
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", walk_times, [
		0.25, 0.55, 0.65, 0.12, 0.00, 0.28, 0.08, 0.10, 0.25
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", walk_times, [
		0.28, -0.10, -0.15, -0.32, -0.35, 0.00, 0.00, 0.32, 0.28
	])

	# LEFT ARM (Back Layer, Z=-1): Opposes Left Leg (Swings Back when Left Leg reaches forward)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", walk_times, [
		-0.35, -0.22, -0.05, 0.20, 0.38, 0.25, 0.05, -0.20, -0.35
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", walk_times, [
		0.15, 0.18, 0.22, 0.35, 0.38, 0.30, 0.20, 0.15, 0.15
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation", walk_times, [
		0.05, 0.08, 0.00, -0.08, -0.10, -0.05, 0.02, 0.08, 0.05
	])

	# RIGHT ARM (Front Layer, Z=+1): Opposes Right Leg (Swings Forward when Left Leg reaches forward)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", walk_times, [
		0.38, 0.25, 0.05, -0.20, -0.35, -0.22, -0.05, 0.20, 0.38
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", walk_times, [
		0.38, 0.30, 0.20, 0.15, 0.15, 0.18, 0.22, 0.35, 0.38
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation", walk_times, [
		-0.10, -0.05, 0.02, 0.08, 0.05, 0.08, 0.00, -0.08, -0.10
	])

	# Tail Secondary Motion (Lagging Swish)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/tail:rotation", walk_times, [
		-0.08, 0.05, -0.02, 0.10, -0.08, 0.05, -0.02, 0.10, -0.08
	])

	# Neutral Expression & Eyes
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck/head/Face:expression", [0.0], ["neutral"], Animation.INTERPOLATION_NEAREST)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck/head/Face:eye_state", [0.0], ["open"], Animation.INTERPOLATION_NEAREST)

	anim_lib.add_animation("walk", a_walk)
	anim_lib.add_animation("LEON_WALK", a_walk.duplicate())

	anim_player.add_animation_library("", anim_lib)

	# Save to scenes/leon.tscn
	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack leon scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/leon.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/leon.tscn: ", err)
		quit(1)
		return

	# Also save to scenes/character.tscn to maintain project compatibility
	err = ResourceSaver.save(scene, "res://scenes/character.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/character.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/leon.tscn and res://scenes/character.tscn with production hierarchy!")
	quit(0)
