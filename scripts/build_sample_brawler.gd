@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Cutenemi Sample Neutral Brawler Scene...")
	var root = CharacterBody2D.new()
	root.name = "SampleBrawler"
	root.set_script(load("res://scripts/character_controller.gd"))

	# Collision Shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var capsule = CapsuleShape2D.new()
	capsule.radius = 22.0
	capsule.height = 104.0
	col.shape = capsule
	col.position = Vector2(0, -52)
	root.add_child(col)
	col.owner = root

	# Visuals Root
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	visuals.owner = root

	# Skeleton2D
	var skel = Skeleton2D.new()
	skel.name = "Skeleton"
	visuals.add_child(skel)
	skel.owner = root

	# Texture Preloads
	var tex_head = load("res://assets/sample_brawler/head.svg")
	var tex_hair_back = load("res://assets/sample_brawler/hair_back.svg")
	var tex_hair_front = load("res://assets/sample_brawler/hair_front.svg")
	var tex_torso = load("res://assets/sample_brawler/torso.svg")
	var tex_coat_tails = load("res://assets/sample_brawler/coat_tails.svg")
	var tex_scarf = load("res://assets/sample_brawler/scarf.svg")
	var tex_arm_u = load("res://assets/sample_brawler/arm_upper.svg")
	var tex_arm_l = load("res://assets/sample_brawler/arm_lower.svg")
	var tex_hand = load("res://assets/sample_brawler/hand_fist.svg")
	var tex_leg_u = load("res://assets/sample_brawler/leg_upper.svg")
	var tex_leg_l = load("res://assets/sample_brawler/leg_lower.svg")
	var tex_boot = load("res://assets/sample_brawler/boot.svg")

	# Facial Textures
	var tex_eye_l = load("res://assets/sample_brawler/eye_L.svg")
	var tex_eye_r = load("res://assets/sample_brawler/eye_R.svg")
	var tex_pupil_l = load("res://assets/sample_brawler/pupil_L.svg")
	var tex_pupil_r = load("res://assets/sample_brawler/pupil_R.svg")
	var tex_brow_l = load("res://assets/sample_brawler/eyebrow_L.svg")
	var tex_brow_r = load("res://assets/sample_brawler/eyebrow_R.svg")
	var tex_mouth_n = load("res://assets/sample_brawler/mouth_neutral.svg")

	var create_bone = func(b_name: String, rest_pos: Vector2, parent: Node, is_leaf: bool = false) -> Bone2D:
		var b = Bone2D.new()
		b.name = b_name
		b.position = rest_pos
		b.rest = Transform2D(0.0, rest_pos)
		if is_leaf:
			b.auto_calculate_length_and_angle = false
			b.length = 16.0
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

	# 1. Bone Hierarchy
	# Hip (Pelvis Root at y = -56)
	var hip = create_bone.call("Hip", Vector2(0, -56), skel)

	# Coat Tails (Secondary Drag Z = -2)
	var coat_tails = create_bone.call("CoatTails", Vector2(0, 18), hip, true)
	create_sprite.call("CoatTailsSprite", tex_coat_tails, Vector2(0, 18), -2, coat_tails)

	# Torso
	var torso = create_bone.call("Torso", Vector2(0, -10), hip)
	create_sprite.call("TorsoSprite", tex_torso, Vector2(0, -18), 0, torso)

	# Head
	var head = create_bone.call("Head", Vector2(0, -38), torso)
	create_sprite.call("HairBackSprite", tex_hair_back, Vector2(0, -22), -2, head)
	create_sprite.call("HeadSprite", tex_head, Vector2(0, -20), 0, head)
	create_sprite.call("HairFrontSprite", tex_hair_front, Vector2(0, -38), 1, head)

	# Scarf (Signature Crimson Accent, Leaf Bone)
	var scarf = create_bone.call("Scarf", Vector2(-12, 6), head, true)
	create_sprite.call("ScarfSprite", tex_scarf, Vector2(-6, 18), 1, scarf)

	# Modular Face Controller (Z = 2)
	var face = Node2D.new()
	face.name = "Face"
	face.position = Vector2(0, -14)
	face.z_index = 2
	face.set_script(load("res://scripts/face_controller.gd"))
	head.add_child(face)
	face.owner = root

	var eye_l = Sprite2D.new()
	eye_l.name = "EyeL"
	eye_l.texture = tex_eye_l
	eye_l.position = Vector2(-16, 0)
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
	eye_r.position = Vector2(16, 0)
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
	brow_l.position = Vector2(-16, -14)
	face.add_child(brow_l)
	brow_l.owner = root

	var brow_r = Sprite2D.new()
	brow_r.name = "BrowR"
	brow_r.texture = tex_brow_r
	brow_r.position = Vector2(16, -14)
	face.add_child(brow_r)
	brow_r.owner = root

	var mouth = Sprite2D.new()
	mouth.name = "Mouth"
	mouth.texture = tex_mouth_n
	mouth.position = Vector2(0, 16)
	face.add_child(mouth)
	mouth.owner = root

	# Left Arm (Back Arm: z-index -1)
	var arm_l_u = create_bone.call("LeftUpperArm", Vector2(-22, -24), torso)
	create_sprite.call("ArmSpriteL", tex_arm_u, Vector2(0, 14), -1, arm_l_u)

	var arm_l_l = create_bone.call("LeftLowerArm", Vector2(0, 24), arm_l_u)
	create_sprite.call("ForearmSpriteL", tex_arm_l, Vector2(0, 12), -1, arm_l_l)

	var hand_l = create_bone.call("LeftHand", Vector2(0, 22), arm_l_l, true)
	create_sprite.call("HandSpriteL", tex_hand, Vector2(0, 10), -1, hand_l)

	# Right Arm (Front Arm: z-index 1)
	var arm_r_u = create_bone.call("RightUpperArm", Vector2(22, -24), torso)
	create_sprite.call("ArmSpriteR", tex_arm_u, Vector2(0, 14), 1, arm_r_u)

	var arm_r_l = create_bone.call("RightLowerArm", Vector2(0, 24), arm_r_u)
	create_sprite.call("ForearmSpriteR", tex_arm_l, Vector2(0, 12), 1, arm_r_l)

	var hand_r = create_bone.call("RightHand", Vector2(0, 22), arm_r_l, true)
	create_sprite.call("HandSpriteR", tex_hand, Vector2(0, 10), 1, hand_r)

	# Left Leg (Back Leg: z-index -1)
	var leg_l_u = create_bone.call("LeftUpperLeg", Vector2(-14, 10), hip)
	create_sprite.call("LegSpriteL", tex_leg_u, Vector2(0, 14), -1, leg_l_u)

	var leg_l_l = create_bone.call("LeftLowerLeg", Vector2(0, 24), leg_l_u)
	create_sprite.call("ShinSpriteL", tex_leg_l, Vector2(0, 12), -1, leg_l_l)

	var foot_l = create_bone.call("LeftFoot", Vector2(0, 22), leg_l_l, true)
	create_sprite.call("BootSpriteL", tex_boot, Vector2(8, 4), -1, foot_l)

	# Right Leg (Front Leg: z-index 1)
	var leg_r_u = create_bone.call("RightUpperLeg", Vector2(14, 10), hip)
	create_sprite.call("LegSpriteR", tex_leg_u, Vector2(0, 14), 1, leg_r_u)

	var leg_r_l = create_bone.call("RightLowerLeg", Vector2(0, 24), leg_r_u)
	create_sprite.call("ShinSpriteR", tex_leg_l, Vector2(0, 12), 1, leg_r_l)

	var foot_r = create_bone.call("RightFoot", Vector2(0, 22), leg_r_l, true)
	create_sprite.call("BootSpriteR", tex_boot, Vector2(8, 4), 1, foot_r)

	# AnimationPlayer Setup
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimPlayer"
	root.add_child(anim_player)
	anim_player.owner = root

	var anim_lib = AnimationLibrary.new()

	var P_HIP_POS = "Visuals/Skeleton/Hip:position"
	var P_TORSO_ROT = "Visuals/Skeleton/Hip/Torso:rotation"
	var P_TORSO_SCL = "Visuals/Skeleton/Hip/Torso:scale"
	var P_HEAD_ROT = "Visuals/Skeleton/Hip/Torso/Head:rotation"
	var P_SCARF_ROT = "Visuals/Skeleton/Hip/Torso/Head/Scarf:rotation"
	var P_COAT_ROT = "Visuals/Skeleton/Hip/CoatTails:rotation"
	var P_ARM_L_U_ROT = "Visuals/Skeleton/Hip/Torso/LeftUpperArm:rotation"
	var P_ARM_L_L_ROT = "Visuals/Skeleton/Hip/Torso/LeftUpperArm/LeftLowerArm:rotation"
	var P_ARM_R_U_ROT = "Visuals/Skeleton/Hip/Torso/RightUpperArm:rotation"
	var P_ARM_R_L_ROT = "Visuals/Skeleton/Hip/Torso/RightUpperArm/RightLowerArm:rotation"
	var P_LEG_L_U_ROT = "Visuals/Skeleton/Hip/LeftUpperLeg:rotation"
	var P_LEG_L_L_ROT = "Visuals/Skeleton/Hip/LeftUpperLeg/LeftLowerLeg:rotation"
	var P_LEG_L_F_ROT = "Visuals/Skeleton/Hip/LeftUpperLeg/LeftLowerLeg/LeftFoot:rotation"
	var P_LEG_R_U_ROT = "Visuals/Skeleton/Hip/RightUpperLeg:rotation"
	var P_LEG_R_L_ROT = "Visuals/Skeleton/Hip/RightUpperLeg/RightLowerLeg:rotation"
	var P_LEG_R_F_ROT = "Visuals/Skeleton/Hip/RightUpperLeg/RightLowerLeg/RightFoot:rotation"

	var add_track = func(anim: Animation, path: String, times: Array, values: Array) -> void:
		var idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(idx, path)
		anim.track_set_interpolation_type(idx, Animation.INTERPOLATION_CUBIC)
		for i in range(times.size()):
			anim.track_insert_key(idx, times[i], values[i])

	# 1. IDLE (2.0s Loop)
	var a_idle = Animation.new()
	a_idle.length = 2.0
	a_idle.loop_mode = Animation.LOOP_LINEAR
	add_track.call(a_idle, P_HIP_POS, [0.0, 1.0, 2.0], [Vector2(0, -56.0), Vector2(0, -54.8), Vector2(0, -56.0)])
	add_track.call(a_idle, P_TORSO_SCL, [0.0, 1.0, 2.0], [Vector2(1.0, 1.0), Vector2(1.025, 0.985), Vector2(1.0, 1.0)])
	add_track.call(a_idle, P_TORSO_ROT, [0.0, 0.5, 1.0, 1.5, 2.0], [0.0, 0.012, 0.0, -0.012, 0.0])
	add_track.call(a_idle, P_HEAD_ROT, [0.0, 0.65, 1.15, 1.65, 2.0], [-0.008, -0.022, 0.005, 0.020, -0.008])
	add_track.call(a_idle, P_ARM_L_U_ROT, [0.0, 1.0, 2.0], [-0.04, 0.02, -0.04])
	add_track.call(a_idle, P_ARM_L_L_ROT, [0.0, 1.0, 2.0], [0.10, 0.16, 0.10])
	add_track.call(a_idle, P_ARM_R_U_ROT, [0.0, 1.0, 2.0], [0.08, -0.02, 0.08])
	add_track.call(a_idle, P_ARM_R_L_ROT, [0.0, 1.0, 2.0], [0.24, 0.32, 0.24])
	add_track.call(a_idle, P_SCARF_ROT, [0.0, 0.6, 1.2, 1.7, 2.0], [0.0, 0.08, -0.02, -0.09, 0.0])
	add_track.call(a_idle, P_COAT_ROT, [0.0, 1.0, 2.0], [0.0, 0.04, 0.0])
	add_track.call(a_idle, P_LEG_L_U_ROT, [0.0, 2.0], [-0.02, -0.02])
	add_track.call(a_idle, P_LEG_L_L_ROT, [0.0, 2.0], [0.02, 0.02])
	add_track.call(a_idle, P_LEG_L_F_ROT, [0.0, 2.0], [0.0, 0.0])
	add_track.call(a_idle, P_LEG_R_U_ROT, [0.0, 2.0], [0.03, 0.03])
	add_track.call(a_idle, P_LEG_R_L_ROT, [0.0, 2.0], [0.02, 0.02])
	add_track.call(a_idle, P_LEG_R_F_ROT, [0.0, 2.0], [-0.05, -0.05])
	anim_lib.add_animation("idle", a_idle)

	# 2. WALK (0.80s Loop)
	var a_walk = Animation.new()
	a_walk.length = 0.80
	a_walk.loop_mode = Animation.LOOP_LINEAR
	add_track.call(a_walk, P_HIP_POS,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[Vector2(0, -55.0), Vector2(0, -52.2), Vector2(0, -55.8), Vector2(0, -58.5),
		 Vector2(0, -55.0), Vector2(0, -52.2), Vector2(0, -55.8), Vector2(0, -58.5), Vector2(0, -55.0)])
	add_track.call(a_walk, P_TORSO_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.06, 0.04, 0.07, 0.05, 0.06, 0.04, 0.07, 0.05, 0.06])
	add_track.call(a_walk, P_HEAD_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.04, 0.01, -0.05, 0.02, -0.04, 0.01, -0.05, 0.02, -0.04])
	add_track.call(a_walk, P_ARM_L_U_ROT, [0.0, 0.20, 0.40, 0.60, 0.80], [-0.42, 0.05, 0.38, 0.02, -0.42])
	add_track.call(a_walk, P_ARM_L_L_ROT, [0.0, 0.20, 0.40, 0.60, 0.80], [0.20, 0.42, 0.15, 0.38, 0.20])
	add_track.call(a_walk, P_ARM_R_U_ROT, [0.0, 0.20, 0.40, 0.60, 0.80], [0.38, 0.02, -0.42, 0.05, 0.38])
	add_track.call(a_walk, P_ARM_R_L_ROT, [0.0, 0.20, 0.40, 0.60, 0.80], [0.15, 0.38, 0.20, 0.42, 0.15])
	add_track.call(a_walk, P_LEG_L_U_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.48, 0.22, -0.08, -0.46, -0.38, 0.12, 0.38, 0.52, 0.48])
	add_track.call(a_walk, P_LEG_L_L_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.06, 0.32, 0.18, 0.08, 0.28, 0.62, 0.32, -0.04, -0.06])
	add_track.call(a_walk, P_LEG_L_F_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.42, -0.08, 0.0, 0.38, 0.10, -0.22, -0.28, -0.48, -0.42])
	add_track.call(a_walk, P_LEG_R_U_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.38, 0.12, 0.38, 0.52, 0.48, 0.22, -0.08, -0.46, -0.38])
	add_track.call(a_walk, P_LEG_R_L_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.28, 0.62, 0.32, -0.04, -0.06, 0.32, 0.18, 0.08, 0.28])
	add_track.call(a_walk, P_LEG_R_F_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.10, -0.22, -0.28, -0.48, -0.42, -0.08, 0.0, 0.38, 0.10])
	add_track.call(a_walk, P_SCARF_ROT, [0.0, 0.20, 0.40, 0.60, 0.80], [-0.12, 0.10, -0.12, 0.10, -0.12])
	add_track.call(a_walk, P_COAT_ROT, [0.0, 0.20, 0.40, 0.60, 0.80], [0.10, -0.06, 0.10, -0.06, 0.10])
	anim_lib.add_animation("walk", a_walk)

	# 3. RUN (0.52s Loop)
	var a_run = Animation.new()
	a_run.length = 0.52
	a_run.loop_mode = Animation.LOOP_LINEAR
	add_track.call(a_run, P_HIP_POS, [0.0, 0.13, 0.26, 0.39, 0.52], [Vector2(0, -49.0), Vector2(0, -64.0), Vector2(0, -49.0), Vector2(0, -64.0), Vector2(0, -49.0)])
	add_track.call(a_run, P_TORSO_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [0.26, 0.32, 0.26, 0.32, 0.26])
	add_track.call(a_run, P_TORSO_SCL, [0.0, 0.13, 0.26, 0.39, 0.52], [Vector2(1.14, 0.88), Vector2(0.92, 1.10), Vector2(1.14, 0.88), Vector2(0.92, 1.10), Vector2(1.14, 0.88)])
	add_track.call(a_run, P_HEAD_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [-0.12, 0.04, -0.12, 0.04, -0.12])
	add_track.call(a_run, P_ARM_L_U_ROT, [0.0, 0.26, 0.52], [-1.05, 0.95, -1.05])
	add_track.call(a_run, P_ARM_L_L_ROT, [0.0, 0.26, 0.52], [0.85, 0.45, 0.85])
	add_track.call(a_run, P_ARM_R_U_ROT, [0.0, 0.26, 0.52], [0.95, -1.05, 0.95])
	add_track.call(a_run, P_ARM_R_L_ROT, [0.0, 0.26, 0.52], [0.45, 0.85, 0.45])
	add_track.call(a_run, P_LEG_L_U_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [0.95, 0.25, -0.85, 0.20, 0.95])
	add_track.call(a_run, P_LEG_L_L_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [-0.20, 0.55, 0.95, 0.80, -0.20])
	add_track.call(a_run, P_LEG_L_F_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [-0.55, -0.10, 0.25, -0.35, -0.55])
	add_track.call(a_run, P_LEG_R_U_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [-0.85, 0.20, 0.95, 0.25, -0.85])
	add_track.call(a_run, P_LEG_R_L_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [0.95, 0.80, -0.20, 0.55, 0.95])
	add_track.call(a_run, P_LEG_R_F_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [0.25, -0.35, -0.55, -0.10, 0.25])
	add_track.call(a_run, P_SCARF_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [-0.55, -0.38, -0.55, -0.38, -0.55])
	add_track.call(a_run, P_COAT_ROT, [0.0, 0.13, 0.26, 0.39, 0.52], [-0.45, -0.25, -0.45, -0.25, -0.45])
	anim_lib.add_animation("run", a_run)

	# 4. RUN STOP
	var a_stop = Animation.new()
	a_stop.length = 0.34
	add_track.call(a_stop, P_HIP_POS, [0.0, 0.10, 0.22, 0.34], [Vector2(0, -52.0), Vector2(0, -46.0), Vector2(0, -55.0), Vector2(0, -56.0)])
	add_track.call(a_stop, P_TORSO_SCL, [0.0, 0.10, 0.22, 0.34], [Vector2(1.0, 1.0), Vector2(1.20, 0.82), Vector2(0.98, 1.02), Vector2(1.0, 1.0)])
	add_track.call(a_stop, P_TORSO_ROT, [0.0, 0.10, 0.22, 0.34], [0.20, -0.32, 0.06, 0.0])
	add_track.call(a_stop, P_HEAD_ROT, [0.0, 0.10, 0.22, 0.34], [0.05, 0.15, -0.04, 0.0])
	add_track.call(a_stop, P_ARM_L_U_ROT, [0.0, 0.10, 0.22, 0.34], [0.20, 0.68, -0.15, -0.04])
	add_track.call(a_stop, P_ARM_R_U_ROT, [0.0, 0.10, 0.22, 0.34], [0.20, 0.68, -0.15, 0.08])
	add_track.call(a_stop, P_LEG_L_U_ROT, [0.0, 0.10, 0.22, 0.34], [0.40, 0.35, 0.05, -0.02])
	add_track.call(a_stop, P_LEG_L_L_ROT, [0.0, 0.10, 0.22, 0.34], [-0.10, -0.60, -0.10, 0.02])
	add_track.call(a_stop, P_LEG_L_F_ROT, [0.0, 0.10, 0.22, 0.34], [-0.30, -0.35, 0.05, 0.0])
	add_track.call(a_stop, P_LEG_R_U_ROT, [0.0, 0.10, 0.22, 0.34], [0.40, 0.35, 0.05, 0.03])
	add_track.call(a_stop, P_LEG_R_L_ROT, [0.0, 0.10, 0.22, 0.34], [-0.10, -0.60, -0.10, 0.02])
	add_track.call(a_stop, P_LEG_R_F_ROT, [0.0, 0.10, 0.22, 0.34], [-0.30, -0.35, 0.05, -0.05])
	add_track.call(a_stop, P_SCARF_ROT, [0.0, 0.10, 0.22, 0.34], [-0.45, 0.38, -0.10, 0.0])
	anim_lib.add_animation("run_stop", a_stop)

	# 5. ATTACK (Piston Punch)
	var a_atk = Animation.new()
	a_atk.length = 0.50
	add_track.call(a_atk, P_HIP_POS, [0.0, 0.12, 0.18, 0.30, 0.50], [Vector2(0, -56.0), Vector2(-8, -52.0), Vector2(16, -54.0), Vector2(6, -56.0), Vector2(0, -56.0)])
	add_track.call(a_atk, P_TORSO_ROT, [0.0, 0.12, 0.18, 0.30, 0.50], [0.0, -0.35, 0.38, 0.18, 0.0])
	add_track.call(a_atk, P_TORSO_SCL, [0.0, 0.12, 0.18, 0.30, 0.50], [Vector2(1, 1), Vector2(0.88, 1.14), Vector2(1.20, 0.85), Vector2(1.02, 0.98), Vector2(1, 1)])
	add_track.call(a_atk, P_HEAD_ROT, [0.0, 0.12, 0.18, 0.30, 0.50], [0.0, -0.22, 0.12, 0.06, 0.0])
	add_track.call(a_atk, P_ARM_R_U_ROT, [0.0, 0.12, 0.18, 0.30, 0.50], [0.08, -1.35, 1.38, 1.15, 0.08])
	add_track.call(a_atk, P_ARM_R_L_ROT, [0.0, 0.12, 0.18, 0.30, 0.50], [0.24, 1.55, 0.05, 0.18, 0.24])
	add_track.call(a_atk, P_ARM_L_U_ROT, [0.0, 0.12, 0.18, 0.30, 0.50], [-0.04, 0.58, -0.92, -0.55, -0.04])
	add_track.call(a_atk, P_LEG_L_U_ROT, [0.0, 0.12, 0.18, 0.50], [-0.02, -0.20, -0.38, -0.02])
	add_track.call(a_atk, P_LEG_R_U_ROT, [0.0, 0.12, 0.18, 0.50], [0.03, 0.28, 0.48, 0.03])
	add_track.call(a_atk, P_SCARF_ROT, [0.0, 0.12, 0.22, 0.50], [0.0, -0.45, 0.48, 0.0])
	add_track.call(a_atk, P_COAT_ROT, [0.0, 0.12, 0.22, 0.50], [0.0, -0.35, 0.35, 0.0])
	var m_idx = a_atk.add_track(Animation.TYPE_METHOD)
	a_atk.track_set_path(m_idx, ".")
	a_atk.track_insert_key(m_idx, 0.18, {"method": "on_attack_impact_event", "args": []})
	anim_lib.add_animation("attack", a_atk)

	# Register anims
	anim_player.add_animation_library("", anim_lib)

	# Save PackedScene
	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/sample_brawler.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scene: ", err)
		quit(1)
		return

	print("[BUILD] Successfully rebuilt res://scenes/sample_brawler.tscn!")
	quit(0)
