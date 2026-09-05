@tool
extends SceneTree

func _init() -> void:
	print("[BUILD NITA] Starting full Nita scene generation...")
	build_nita_front()
	build_nita_back()
	build_nita_side()
	build_actor_nita()
	print("[BUILD NITA] Completed all Nita scenes successfully!")
	quit(0)

func build_nita_front() -> void:
	print("  -> Building scenes/nita_front.tscn...")
	var root = Node2D.new()
	root.name = "NitaFront"

	# 1. Feet
	var feet = Node2D.new()
	feet.name = "Feet"
	root.add_child(feet)
	feet.owner = root

	var foot_l = Sprite2D.new()
	foot_l.name = "FootL"
	foot_l.texture = load("res://assets/nita/body/foot_L.svg")
	foot_l.position = Vector2(-14, -10)
	feet.add_child(foot_l)
	foot_l.owner = root

	var foot_r = Sprite2D.new()
	foot_r.name = "FootR"
	foot_r.texture = load("res://assets/nita/body/foot_R.svg")
	foot_r.position = Vector2(14, -10)
	feet.add_child(foot_r)
	foot_r.owner = root

	# 2. Legs
	var legs = Node2D.new()
	legs.name = "Legs"
	root.add_child(legs)
	legs.owner = root

	var leg_l = Sprite2D.new()
	leg_l.name = "LegL"
	leg_l.texture = load("res://assets/nita/body/leg_L.svg")
	leg_l.position = Vector2(-14, -30)
	legs.add_child(leg_l)
	leg_l.owner = root

	var leg_r = Sprite2D.new()
	leg_r.name = "LegR"
	leg_r.texture = load("res://assets/nita/body/leg_R.svg")
	leg_r.position = Vector2(14, -30)
	legs.add_child(leg_r)
	leg_r.owner = root

	# 3. Skirt (z_index = 1)
	var skirt = Sprite2D.new()
	skirt.name = "Skirt"
	skirt.texture = load("res://assets/nita/skirt.svg")
	skirt.position = Vector2(0, -42)
	skirt.z_index = 1
	root.add_child(skirt)
	skirt.owner = root

	# 4. Torso (z_index = 2)
	var torso = Sprite2D.new()
	torso.name = "Torso"
	torso.texture = load("res://assets/nita/torso.svg")
	torso.position = Vector2(0, -68)
	torso.z_index = 2
	root.add_child(torso)
	torso.owner = root

	# 5. Left Arm (z_index = 2)
	var arm_l = Node2D.new()
	arm_l.name = "ArmL"
	arm_l.position = Vector2(-28, -72)
	arm_l.z_index = 2
	root.add_child(arm_l)
	arm_l.owner = root

	var arm_l_spr = Sprite2D.new()
	arm_l_spr.name = "Arm"
	arm_l_spr.texture = load("res://assets/nita/body/arm_L.svg")
	arm_l_spr.position = Vector2(0, 16)
	arm_l.add_child(arm_l_spr)
	arm_l_spr.owner = root

	var hand_l_spr = Sprite2D.new()
	hand_l_spr.name = "Hand"
	hand_l_spr.texture = load("res://assets/nita/body/hand_L.svg")
	hand_l_spr.position = Vector2(0, 36)
	arm_l.add_child(hand_l_spr)
	hand_l_spr.owner = root

	# 6. Right Arm (z_index = 3)
	var arm_r = Node2D.new()
	arm_r.name = "ArmR"
	arm_r.position = Vector2(28, -72)
	arm_r.z_index = 3
	root.add_child(arm_r)
	arm_r.owner = root

	var arm_r_spr = Sprite2D.new()
	arm_r_spr.name = "Arm"
	arm_r_spr.texture = load("res://assets/nita/body/arm_R.svg")
	arm_r_spr.position = Vector2(0, 16)
	arm_r.add_child(arm_r_spr)
	arm_r_spr.owner = root

	var hand_r_spr = Sprite2D.new()
	hand_r_spr.name = "Hand"
	hand_r_spr.texture = load("res://assets/nita/body/hand_R.svg")
	hand_r_spr.position = Vector2(0, 36)
	arm_r.add_child(hand_r_spr)
	hand_r_spr.owner = root

	# 7. Head (z_index = 3)
	var head = Node2D.new()
	head.name = "Head"
	head.position = Vector2(0, -114)
	head.z_index = 3
	root.add_child(head)
	head.owner = root

	var hood = Sprite2D.new()
	hood.name = "Hood"
	hood.texture = load("res://assets/nita/hood_front.svg")
	head.add_child(hood)
	hood.owner = root

	# 8. Face with FaceControllerNita
	var face = Node2D.new()
	face.name = "Face"
	face.position = Vector2(0, 14)
	face.set_script(load("res://scripts/face_controller_nita.gd"))
	head.add_child(face)
	face.owner = root

	var face_base = Sprite2D.new()
	face_base.name = "FaceBase"
	face_base.texture = load("res://assets/nita/face_base.svg")
	face.add_child(face_base)
	face_base.owner = root

	var eye_l = Sprite2D.new()
	eye_l.name = "EyeL"
	eye_l.texture = load("res://assets/nita/face/eye_L.svg")
	eye_l.position = Vector2(-14, -4)
	face.add_child(eye_l)
	eye_l.owner = root

	var pupil_l = Sprite2D.new()
	pupil_l.name = "PupilL"
	pupil_l.texture = load("res://assets/nita/face/pupil_L.svg")
	eye_l.add_child(pupil_l)
	pupil_l.owner = root

	var eye_r = Sprite2D.new()
	eye_r.name = "EyeR"
	eye_r.texture = load("res://assets/nita/face/eye_R.svg")
	eye_r.position = Vector2(14, -4)
	face.add_child(eye_r)
	eye_r.owner = root

	var pupil_r = Sprite2D.new()
	pupil_r.name = "PupilR"
	pupil_r.texture = load("res://assets/nita/face/pupil_R.svg")
	eye_r.add_child(pupil_r)
	pupil_r.owner = root

	var brow_l = Sprite2D.new()
	brow_l.name = "BrowL"
	brow_l.texture = load("res://assets/nita/face/eyebrow_L.svg")
	brow_l.position = Vector2(-14, -14)
	face.add_child(brow_l)
	brow_l.owner = root

	var brow_r = Sprite2D.new()
	brow_r.name = "BrowR"
	brow_r.texture = load("res://assets/nita/face/eyebrow_R.svg")
	brow_r.position = Vector2(14, -14)
	face.add_child(brow_r)
	brow_r.owner = root

	var mouth = Sprite2D.new()
	mouth.name = "Mouth"
	mouth.texture = load("res://assets/nita/face/mouth_grin.svg")
	mouth.position = Vector2(0, 14)
	mouth.z_index = 2
	face.add_child(mouth)
	mouth.owner = root

	var scn = PackedScene.new()
	scn.pack(root)
	ResourceSaver.save(scn, "res://scenes/nita_front.tscn")
	print("  -> Saved scenes/nita_front.tscn")

func build_nita_back() -> void:
	print("  -> Building scenes/nita_back.tscn...")
	var root = Node2D.new()
	root.name = "NitaBack"

	# 1. Feet
	var feet = Node2D.new()
	feet.name = "Feet"
	root.add_child(feet)
	feet.owner = root

	var foot_l = Sprite2D.new()
	foot_l.name = "FootL"
	foot_l.texture = load("res://assets/nita/body/foot_L.svg")
	foot_l.position = Vector2(-14, -10)
	feet.add_child(foot_l)
	foot_l.owner = root

	var foot_r = Sprite2D.new()
	foot_r.name = "FootR"
	foot_r.texture = load("res://assets/nita/body/foot_R.svg")
	foot_r.position = Vector2(14, -10)
	feet.add_child(foot_r)
	foot_r.owner = root

	# 2. Legs
	var legs = Node2D.new()
	legs.name = "Legs"
	root.add_child(legs)
	legs.owner = root

	var leg_l = Sprite2D.new()
	leg_l.name = "LegL"
	leg_l.texture = load("res://assets/nita/body/leg_L.svg")
	leg_l.position = Vector2(-14, -30)
	legs.add_child(leg_l)
	leg_l.owner = root

	var leg_r = Sprite2D.new()
	leg_r.name = "LegR"
	leg_r.texture = load("res://assets/nita/body/leg_R.svg")
	leg_r.position = Vector2(14, -30)
	legs.add_child(leg_r)
	leg_r.owner = root

	# 3. Skirt
	var skirt = Sprite2D.new()
	skirt.name = "Skirt"
	skirt.texture = load("res://assets/nita/skirt.svg")
	skirt.position = Vector2(0, -42)
	skirt.z_index = 1
	root.add_child(skirt)
	skirt.owner = root

	# 4. Torso Back
	var torso = Sprite2D.new()
	torso.name = "Torso"
	torso.texture = load("res://assets/nita/torso_back.svg")
	torso.position = Vector2(0, -68)
	torso.z_index = 2
	root.add_child(torso)
	torso.owner = root

	# 5. Head Back
	var head = Sprite2D.new()
	head.name = "Head"
	head.texture = load("res://assets/nita/hood_back.svg")
	head.position = Vector2(0, -114)
	head.z_index = 3
	root.add_child(head)
	head.owner = root

	# 6. Left Arm
	var arm_l = Node2D.new()
	arm_l.name = "ArmL"
	arm_l.position = Vector2(-28, -72)
	arm_l.z_index = 2
	root.add_child(arm_l)
	arm_l.owner = root

	var arm_l_spr = Sprite2D.new()
	arm_l_spr.name = "Arm"
	arm_l_spr.texture = load("res://assets/nita/body/arm_L.svg")
	arm_l_spr.position = Vector2(0, 16)
	arm_l.add_child(arm_l_spr)
	arm_l_spr.owner = root

	var hand_l_spr = Sprite2D.new()
	hand_l_spr.name = "Hand"
	hand_l_spr.texture = load("res://assets/nita/body/hand_L.svg")
	hand_l_spr.position = Vector2(0, 36)
	arm_l.add_child(hand_l_spr)
	hand_l_spr.owner = root

	# 7. Right Arm
	var arm_r = Node2D.new()
	arm_r.name = "ArmR"
	arm_r.position = Vector2(28, -72)
	arm_r.z_index = 3
	root.add_child(arm_r)
	arm_r.owner = root

	var arm_r_spr = Sprite2D.new()
	arm_r_spr.name = "Arm"
	arm_r_spr.texture = load("res://assets/nita/body/arm_R.svg")
	arm_r_spr.position = Vector2(0, 16)
	arm_r.add_child(arm_r_spr)
	arm_r_spr.owner = root

	var hand_r_spr = Sprite2D.new()
	hand_r_spr.name = "Hand"
	hand_r_spr.texture = load("res://assets/nita/body/hand_R.svg")
	hand_r_spr.position = Vector2(0, 36)
	arm_r.add_child(hand_r_spr)
	hand_r_spr.owner = root

	var scn = PackedScene.new()
	scn.pack(root)
	ResourceSaver.save(scn, "res://scenes/nita_back.tscn")
	print("  -> Saved scenes/nita_back.tscn")

func build_nita_side() -> void:
	print("  -> Building scenes/nita_side.tscn...")
	var root = CharacterBody2D.new()
	root.name = "NitaSide"
	root.set_script(load("res://scripts/character_controller.gd"))

	# 1. Collision Shape
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

	# Side Profile Textures
	var tex_hood = load("res://assets/nita/side/hood.svg")
	var tex_face = load("res://assets/nita/side/face.svg")
	var tex_torso = load("res://assets/nita/side/torso.svg")
	var tex_skirt = load("res://assets/nita/side/skirt.svg")
	var tex_leg_upper = load("res://assets/nita/side/leg_upper.svg")
	var tex_leg_lower = load("res://assets/nita/side/leg_lower.svg")
	var tex_foot = load("res://assets/nita/side/foot.svg")
	var tex_arm_upper = load("res://assets/nita/side/arm_upper.svg")
	var tex_arm_lower = load("res://assets/nita/side/arm_lower.svg")
	var tex_hand = load("res://assets/nita/side/hand.svg")

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

	# SKELETON HIERARCHY
	# Pelvis / Root
	var b_root = create_bone.call("root", Vector2(0, -38), skel)
	# Skirt on root (Z = 0)
	create_sprite.call("SkirtSprite", tex_skirt, Vector2(0, 10), 0, b_root)

	# FAR LIMBS (Back Layer, Z = -1)
	var b_leg_l_upper = create_bone.call("leg_L_upper", Vector2(-4, 10), b_root)
	create_sprite.call("LegSpriteL", tex_leg_upper, Vector2(0, 8), -1, b_leg_l_upper)

	var b_leg_l_lower = create_bone.call("leg_L_lower", Vector2(0, 14), b_leg_l_upper)
	create_sprite.call("LegLowerSpriteL", tex_leg_lower, Vector2(0, 6), -1, b_leg_l_lower)

	var b_foot_l = create_bone.call("foot_L", Vector2(0, 14), b_leg_l_lower, true)
	create_sprite.call("FootSpriteL", tex_foot, Vector2(4, 2), -1, b_foot_l)

	# Torso (Base Layer, Z = 0)
	var b_torso = create_bone.call("torso", Vector2(0, -6), b_root)
	create_sprite.call("TorsoSprite", tex_torso, Vector2(0, -16), 0, b_torso)

	# Far Arm (Back Layer, Z = -1)
	var b_arm_l_upper = create_bone.call("arm_L_upper", Vector2(-6, -20), b_torso)
	create_sprite.call("ArmSpriteL", tex_arm_upper, Vector2(0, 8), -1, b_arm_l_upper)

	var b_arm_l_lower = create_bone.call("arm_L_lower", Vector2(0, 14), b_arm_l_upper)
	create_sprite.call("ArmLowerSpriteL", tex_arm_lower, Vector2(0, 6), -1, b_arm_l_lower)

	var b_hand_l = create_bone.call("hand_L", Vector2(0, 12), b_arm_l_lower, true)
	create_sprite.call("HandSpriteL", tex_hand, Vector2(0, 4), -1, b_hand_l)

	# NEAR LIMBS (Front Layer, Z = 1)
	var b_leg_r_upper = create_bone.call("leg_R_upper", Vector2(4, 10), b_root)
	create_sprite.call("LegSpriteR", tex_leg_upper, Vector2(0, 8), 1, b_leg_r_upper)

	var b_leg_r_lower = create_bone.call("leg_R_lower", Vector2(0, 14), b_leg_r_upper)
	create_sprite.call("LegLowerSpriteR", tex_leg_lower, Vector2(0, 6), 1, b_leg_r_lower)

	var b_foot_r = create_bone.call("foot_R", Vector2(0, 14), b_leg_r_lower, true)
	create_sprite.call("FootSpriteR", tex_foot, Vector2(4, 2), 1, b_foot_r)

	# Near Arm (Front Layer, Z = 3)
	var b_arm_r_upper = create_bone.call("arm_R_upper", Vector2(6, -20), b_torso)
	create_sprite.call("ArmSpriteR", tex_arm_upper, Vector2(0, 8), 3, b_arm_r_upper)

	var b_arm_r_lower = create_bone.call("arm_R_lower", Vector2(0, 14), b_arm_r_upper)
	create_sprite.call("ArmLowerSpriteR", tex_arm_lower, Vector2(0, 6), 3, b_arm_r_lower)

	var b_hand_r = create_bone.call("hand_R", Vector2(0, 12), b_arm_r_lower, true)
	create_sprite.call("HandSpriteR", tex_hand, Vector2(0, 4), 3, b_hand_r)

	# Attack / Swipe Spawn Point
	var p_spawn = Marker2D.new()
	p_spawn.name = "AttackSpawnPoint"
	p_spawn.position = Vector2(12, 2)
	b_hand_r.add_child(p_spawn)
	p_spawn.owner = root

	# Neck & Head (Z = 2)
	var b_neck = create_bone.call("neck", Vector2(0, -26), b_torso)
	var b_head = create_bone.call("head", Vector2(0, -8), b_neck, true)
	create_sprite.call("HoodSprite", tex_hood, Vector2(-4, -34), 2, b_head)
	create_sprite.call("FaceSprite", tex_face, Vector2(8, -18), 2, b_head)

	# VFX Attachment Points
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

	# ANIMATIONS
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimPlayer"
	root.add_child(anim_player)
	anim_player.owner = root

	var anim_lib = AnimationLibrary.new()

	var add_track_keys = func(anim: Animation, prop_path: String, times: Array, values: Array) -> void:
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, NodePath(prop_path))
		anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)
		for i in range(times.size()):
			anim.track_insert_key(track_idx, times[i], values[i])

	# RESET Animation
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
		"Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation": 0.0
	}
	for prop in reset_tracks.keys():
		var idx = a_reset.add_track(Animation.TYPE_VALUE)
		a_reset.track_set_path(idx, NodePath(prop))
		a_reset.track_insert_key(idx, 0.0, reset_tracks[prop])
	anim_lib.add_animation("RESET", a_reset)

	# IDLE Animation
	var a_idle = Animation.new()
	a_idle.length = 2.0
	a_idle.loop_mode = Animation.LOOP_LINEAR
	add_track_keys.call(a_idle, "Visuals/Skeleton/root:position", [0.0, 1.0, 2.0], [Vector2(0, -38.0), Vector2(0, -39.2), Vector2(0, -38.0)])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso:rotation", [0.0, 1.0, 2.0], [0.03, 0.05, 0.03])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/neck/head:rotation", [0.0, 1.0, 2.0], [-0.02, 0.0, -0.02])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", [0.0, 1.0, 2.0], [0.06, -0.02, 0.06])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", [0.0, 1.0, 2.0], [0.20, 0.28, 0.20])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", [0.0, 1.0, 2.0], [-0.04, 0.02, -0.04])
	anim_lib.add_animation("idle", a_idle)

	# WALK CYCLE Animation (0.80s matching Leon's 6-phase walk cycle)
	var a_walk = Animation.new()
	a_walk.length = 0.80
	a_walk.loop_mode = Animation.LOOP_LINEAR
	var walk_times = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80]

	add_track_keys.call(a_walk, "Visuals/Skeleton/root:position", walk_times, [
		Vector2(0, -38.0), Vector2(0, -36.2), Vector2(0, -38.5), Vector2(0, -40.0),
		Vector2(0, -38.0), Vector2(0, -36.2), Vector2(0, -38.5), Vector2(0, -40.0), Vector2(0, -38.0)
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root:rotation", walk_times, [
		-0.02, -0.035, -0.015, 0.015, 0.02, 0.035, 0.015, -0.015, -0.02
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso:rotation", walk_times, [
		0.06, 0.08, 0.04, 0.05, 0.06, 0.08, 0.04, 0.05, 0.06
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck:rotation", walk_times, [
		-0.02, -0.03, -0.01, -0.02, -0.02, -0.03, -0.01, -0.02, -0.02
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck/head:rotation", walk_times, [
		-0.04, -0.02, -0.05, -0.03, -0.04, -0.02, -0.05, -0.03, -0.04
	])

	# Near Leg (Right)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper:rotation", walk_times, [
		0.52, 0.26, -0.06, -0.48, -0.40, -0.15, 0.30, 0.50, 0.52
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", walk_times, [
		0.00, 0.30, 0.08, 0.12, 0.22, 0.60, 0.70, 0.14, 0.00
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", walk_times, [
		-0.40, 0.00, 0.00, 0.38, 0.25, -0.10, -0.15, -0.36, -0.40
	])

	# Far Leg (Left)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper:rotation", walk_times, [
		-0.40, -0.15, 0.30, 0.50, 0.52, 0.26, -0.06, -0.48, -0.40
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", walk_times, [
		0.22, 0.60, 0.70, 0.14, 0.00, 0.30, 0.08, 0.12, 0.22
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", walk_times, [
		0.25, -0.10, -0.15, -0.36, -0.40, 0.00, 0.00, 0.38, 0.25
	])

	# Near Arm (Right)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", walk_times, [
		-0.42, -0.28, -0.08, 0.22, 0.45, 0.30, 0.08, -0.22, -0.42
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", walk_times, [
		0.18, 0.22, 0.25, 0.40, 0.42, 0.32, 0.22, 0.18, 0.18
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation", walk_times, [
		0.06, 0.08, 0.00, -0.08, -0.10, -0.05, 0.02, 0.08, 0.06
	])

	# Far Arm (Left)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", walk_times, [
		0.45, 0.30, 0.08, -0.22, -0.42, -0.28, -0.08, 0.22, 0.45
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", walk_times, [
		0.42, 0.32, 0.22, 0.18, 0.18, 0.22, 0.25, 0.40, 0.42
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation", walk_times, [
		-0.10, -0.05, 0.02, 0.08, 0.06, 0.08, 0.00, -0.08, -0.10
	])
	anim_lib.add_animation("walk", a_walk)

	# ATTACK Animation (Fierce Bear Spirit Swipe)
	var a_attack = Animation.new()
	a_attack.length = 0.45
	var atk_times = [0.0, 0.10, 0.22, 0.45]
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso:rotation", atk_times, [0.0, -0.18, 0.22, 0.0])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", atk_times, [0.0, -0.90, 0.85, 0.0])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", atk_times, [0.2, 0.75, 0.10, 0.2])
	anim_lib.add_animation("attack", a_attack)

	# HURT Animation (Recoil)
	var a_hurt = Animation.new()
	a_hurt.length = 0.35
	var hurt_times = [0.0, 0.08, 0.20, 0.35]
	add_track_keys.call(a_hurt, "Visuals/Skeleton/root:position", hurt_times, [
		Vector2(0, -38), Vector2(-12, -42), Vector2(-4, -39), Vector2(0, -38)
	])
	add_track_keys.call(a_hurt, "Visuals/Skeleton/root/torso:rotation", hurt_times, [0.0, -0.30, -0.10, 0.0])
	add_track_keys.call(a_hurt, "Visuals/Skeleton/root/torso/neck/head:rotation", hurt_times, [0.0, -0.25, -0.05, 0.0])
	anim_lib.add_animation("hurt", a_hurt)

	anim_player.add_animation_library("", anim_lib)

	var scn = PackedScene.new()
	scn.pack(root)
	ResourceSaver.save(scn, "res://scenes/nita_side.tscn")
	ResourceSaver.save(scn, "res://scenes/nita.tscn")
	print("  -> Saved scenes/nita_side.tscn & scenes/nita.tscn")

func build_actor_nita() -> void:
	print("  -> Building scenes/actor_nita.tscn...")
	var root = Node2D.new()
	root.name = "ActorNita"
	root.set_script(load("res://scenes/actor_nita.gd"))

	var side_inst = load("res://scenes/nita_side.tscn").instantiate()
	side_inst.name = "SideView"
	root.add_child(side_inst)
	side_inst.owner = root

	var front_inst = load("res://scenes/nita_front.tscn").instantiate()
	front_inst.name = "FrontView"
	front_inst.visible = false
	root.add_child(front_inst)
	front_inst.owner = root

	var back_inst = load("res://scenes/nita_back.tscn").instantiate()
	back_inst.name = "BackView"
	back_inst.visible = false
	root.add_child(back_inst)
	back_inst.owner = root

	var scn = PackedScene.new()
	scn.pack(root)
	ResourceSaver.save(scn, "res://scenes/actor_nita.tscn")
	print("  -> Saved scenes/actor_nita.tscn")
