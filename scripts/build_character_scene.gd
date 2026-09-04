@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Starting character scene generation with upgraded cartoon animation...")
	var root = CharacterBody2D.new()
	root.name = "Character"
	root.set_script(load("res://scripts/character_controller.gd"))

	# Collision Shape (Capsule for smooth ground navigation)
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var capsule = CapsuleShape2D.new()
	capsule.radius = 20.0
	capsule.height = 100.0
	col.shape = capsule
	col.position = Vector2(0, -50)
	root.add_child(col)
	col.owner = root

	# Visuals Root (Handles facing direction scale.x)
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	visuals.owner = root

	# Skeleton2D
	var skel = Skeleton2D.new()
	skel.name = "Skeleton"
	visuals.add_child(skel)
	skel.owner = root

	# Textures
	var tex_torso = load("res://assets/character/torso.svg")
	var tex_head = load("res://assets/character/head.svg")
	var tex_arm_u = load("res://assets/character/arm_upper.svg")
	var tex_arm_l = load("res://assets/character/arm_lower.svg")
	var tex_hand = load("res://assets/character/hand_fist.svg")
	var tex_leg_u = load("res://assets/character/leg_upper.svg")
	var tex_leg_l = load("res://assets/character/leg_lower.svg")
	var tex_foot = load("res://assets/character/foot.svg")
	var tex_scarf = load("res://assets/character/scarf.svg")
	var tex_eyes_n = load("res://assets/character/eyes_neutral.svg")
	var tex_mouth_n = load("res://assets/character/mouth_neutral.svg")

	# Helper to create Bone2D
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

	# Helper to create Sprite2D child
	var create_sprite = func(s_name: String, tex: Texture2D, offset: Vector2, z_idx: int, parent: Node) -> Sprite2D:
		var s = Sprite2D.new()
		s.name = s_name
		s.texture = tex
		s.offset = offset
		s.z_index = z_idx
		parent.add_child(s)
		s.owner = root
		return s

	# Build Bone Hierarchy
	# Hip (Pelvis Root at y = -56)
	var hip = create_bone.call("Hip", Vector2(0, -56), skel)

	# Torso
	var torso = create_bone.call("Torso", Vector2(0, -10), hip)
	create_sprite.call("TorsoSprite", tex_torso, Vector2(0, -18), 0, torso)

	# Head
	var head = create_bone.call("Head", Vector2(0, -38), torso)
	create_sprite.call("HeadSprite", tex_head, Vector2(0, -26), 0, head)

	# Face Node (FaceController)
	var face = Node2D.new()
	face.name = "Face"
	face.position = Vector2(0, -22)
	face.set_script(load("res://scripts/face_controller.gd"))
	head.add_child(face)
	face.owner = root

	var eyes = Sprite2D.new()
	eyes.name = "Eyes"
	eyes.texture = tex_eyes_n
	eyes.offset = Vector2(0, -2)
	eyes.z_index = 2
	face.add_child(eyes)
	eyes.owner = root

	var mouth = Sprite2D.new()
	mouth.name = "Mouth"
	mouth.texture = tex_mouth_n
	mouth.offset = Vector2(0, 12)
	mouth.z_index = 2
	face.add_child(mouth)
	mouth.owner = root

	# Scarf (secondary motion leaf bone)
	var scarf = create_bone.call("Scarf", Vector2(-16, 2), head, true)
	create_sprite.call("ScarfSprite", tex_scarf, Vector2(-10, 16), -1, scarf)

	# Left Arm (Back Arm: z-index -1)
	var arm_l_u = create_bone.call("LeftUpperArm", Vector2(-20, -26), torso)
	create_sprite.call("ArmSpriteL", tex_arm_u, Vector2(0, 14), -1, arm_l_u)

	var arm_l_l = create_bone.call("LeftLowerArm", Vector2(0, 24), arm_l_u)
	create_sprite.call("ForearmSpriteL", tex_arm_l, Vector2(0, 12), -1, arm_l_l)

	var hand_l = create_bone.call("LeftHand", Vector2(0, 22), arm_l_l, true)
	create_sprite.call("HandSpriteL", tex_hand, Vector2(0, 8), -1, hand_l)

	# Right Arm (Front Arm: z-index 1)
	var arm_r_u = create_bone.call("RightUpperArm", Vector2(20, -26), torso)
	create_sprite.call("ArmSpriteR", tex_arm_u, Vector2(0, 14), 1, arm_r_u)

	var arm_r_l = create_bone.call("RightLowerArm", Vector2(0, 24), arm_r_u)
	create_sprite.call("ForearmSpriteR", tex_arm_l, Vector2(0, 12), 1, arm_r_l)

	var hand_r = create_bone.call("RightHand", Vector2(0, 22), arm_r_l, true)
	create_sprite.call("HandSpriteR", tex_hand, Vector2(0, 8), 1, hand_r)

	# Left Leg (Back Leg: z-index -1)
	var leg_l_u = create_bone.call("LeftUpperLeg", Vector2(-12, 10), hip)
	create_sprite.call("LegSpriteL", tex_leg_u, Vector2(0, 14), -1, leg_l_u)

	var leg_l_l = create_bone.call("LeftLowerLeg", Vector2(0, 24), leg_l_u)
	create_sprite.call("ShinSpriteL", tex_leg_l, Vector2(0, 12), -1, leg_l_l)

	var foot_l = create_bone.call("LeftFoot", Vector2(0, 22), leg_l_l, true)
	create_sprite.call("FootSpriteL", tex_foot, Vector2(6, 4), -1, foot_l)

	# Right Leg (Front Leg: z-index 1)
	var leg_r_u = create_bone.call("RightUpperLeg", Vector2(12, 10), hip)
	create_sprite.call("LegSpriteR", tex_leg_u, Vector2(0, 14), 1, leg_r_u)

	var leg_r_l = create_bone.call("RightLowerLeg", Vector2(0, 24), leg_r_u)
	create_sprite.call("ShinSpriteR", tex_leg_l, Vector2(0, 12), 1, leg_r_l)

	var foot_r = create_bone.call("RightFoot", Vector2(0, 22), leg_r_l, true)
	create_sprite.call("FootSpriteR", tex_foot, Vector2(6, 4), 1, foot_r)

	# AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimPlayer"
	root.add_child(anim_player)
	anim_player.owner = root

	var anim_lib = AnimationLibrary.new()

	# Track Paths
	var P_HIP_POS = "Visuals/Skeleton/Hip:position"
	var P_HIP_ROT = "Visuals/Skeleton/Hip:rotation"
	var P_TORSO_ROT = "Visuals/Skeleton/Hip/Torso:rotation"
	var P_TORSO_SCL = "Visuals/Skeleton/Hip/Torso:scale"
	var P_HEAD_ROT = "Visuals/Skeleton/Hip/Torso/Head:rotation"
	var P_SCARF_ROT = "Visuals/Skeleton/Hip/Torso/Head/Scarf:rotation"
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
	var P_VISUALS_SCL = "Visuals:scale"

	var add_track_keys = func(anim: Animation, path: String, times: Array, values: Array) -> void:
		var idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(idx, path)
		anim.track_set_interpolation_type(idx, Animation.INTERPOLATION_CUBIC)
		for i in range(times.size()):
			anim.track_insert_key(idx, times[i], values[i])

	# ============================================================
	# 1. POLISHED IDLE (2.0s, Natural Asymmetry, Organic Breath & Head Lag)
	# ============================================================
	var anim_idle = Animation.new()
	anim_idle.length = 2.0
	anim_idle.loop_mode = Animation.LOOP_LINEAR

	# Subtle breathing lift (organic curve)
	add_track_keys.call(anim_idle, P_HIP_POS,
		[0.0, 1.0, 2.0],
		[Vector2(0, -56.0), Vector2(0, -54.8), Vector2(0, -56.0)])

	add_track_keys.call(anim_idle, P_TORSO_SCL,
		[0.0, 1.0, 2.0],
		[Vector2(1.0, 1.0), Vector2(1.025, 0.985), Vector2(1.0, 1.0)])

	# Thoracic tilt
	add_track_keys.call(anim_idle, P_TORSO_ROT,
		[0.0, 0.5, 1.0, 1.5, 2.0],
		[0.0, 0.012, 0.0, -0.012, 0.0])

	# Delayed Head Tilt (phase shifted for neck elasticity)
	add_track_keys.call(anim_idle, P_HEAD_ROT,
		[0.0, 0.65, 1.15, 1.65, 2.0],
		[-0.008, -0.022, 0.005, 0.020, -0.008])

	# Asymmetrical Arm Rest Poses (Right arm relaxed slightly forward, Left arm resting down)
	add_track_keys.call(anim_idle, P_ARM_L_U_ROT,
		[0.0, 1.0, 2.0],
		[-0.04, 0.02, -0.04])
	add_track_keys.call(anim_idle, P_ARM_L_L_ROT,
		[0.0, 1.0, 2.0],
		[0.10, 0.16, 0.10])

	add_track_keys.call(anim_idle, P_ARM_R_U_ROT,
		[0.0, 1.0, 2.0],
		[0.08, -0.02, 0.08])
	add_track_keys.call(anim_idle, P_ARM_R_L_ROT,
		[0.0, 1.0, 2.0],
		[0.24, 0.32, 0.24])

	# Fluid trailing secondary motion on Scarf (lagging behind body by 0.25s)
	add_track_keys.call(anim_idle, P_SCARF_ROT,
		[0.0, 0.6, 1.2, 1.7, 2.0],
		[0.0, 0.08, -0.02, -0.09, 0.0])

	# Relaxed natural leg stance
	add_track_keys.call(anim_idle, P_LEG_L_U_ROT, [0.0, 2.0], [-0.02, -0.02])
	add_track_keys.call(anim_idle, P_LEG_L_L_ROT, [0.0, 2.0], [0.02, 0.02])
	add_track_keys.call(anim_idle, P_LEG_L_F_ROT, [0.0, 2.0], [0.0, 0.0])
	add_track_keys.call(anim_idle, P_LEG_R_U_ROT, [0.0, 2.0], [0.03, 0.03])
	add_track_keys.call(anim_idle, P_LEG_R_L_ROT, [0.0, 2.0], [0.02, 0.02])
	add_track_keys.call(anim_idle, P_LEG_R_F_ROT, [0.0, 2.0], [-0.05, -0.05])

	anim_lib.add_animation("idle", anim_idle)

	# ============================================================
	# 2. CLASSICAL 6-PHASE WALK CYCLE (0.80s, Ground Interaction, No Sliding)
	# ============================================================
	var anim_walk = Animation.new()
	anim_walk.length = 0.80
	anim_walk.loop_mode = Animation.LOOP_LINEAR

	# Body vertical displacement: Down on contact/cushion (0.1, 0.5), Up on push-off apex (0.3, 0.7)
	add_track_keys.call(anim_walk, P_HIP_POS,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[Vector2(0, -55.0), Vector2(0, -52.2), Vector2(0, -55.8), Vector2(0, -58.5),
		 Vector2(0, -55.0), Vector2(0, -52.2), Vector2(0, -55.8), Vector2(0, -58.5), Vector2(0, -55.0)])

	# Torso forward lean & rotational bob
	add_track_keys.call(anim_walk, P_TORSO_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.06, 0.04, 0.07, 0.05, 0.06, 0.04, 0.07, 0.05, 0.06])

	# Head stabilization (counter-rotates to keep gaze forward)
	add_track_keys.call(anim_walk, P_HEAD_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.04, 0.01, -0.05, 0.02, -0.04, 0.01, -0.05, 0.02, -0.04])

	# Opposite Arm Counter-Swings with natural elbow articulation
	add_track_keys.call(anim_walk, P_ARM_L_U_ROT,
		[0.0, 0.20, 0.40, 0.60, 0.80],
		[-0.42, 0.05, 0.38, 0.02, -0.42])
	add_track_keys.call(anim_walk, P_ARM_L_L_ROT,
		[0.0, 0.20, 0.40, 0.60, 0.80],
		[0.20, 0.42, 0.15, 0.38, 0.20])

	add_track_keys.call(anim_walk, P_ARM_R_U_ROT,
		[0.0, 0.20, 0.40, 0.60, 0.80],
		[0.38, 0.02, -0.42, 0.05, 0.38])
	add_track_keys.call(anim_walk, P_ARM_R_L_ROT,
		[0.0, 0.20, 0.40, 0.60, 0.80],
		[0.15, 0.38, 0.20, 0.42, 0.15])

	# Alternating Legs with Heel Strike, Flat Cushion, and Toe Push-Off
	# Left Leg: Contact (0.0) -> Cushion (0.1) -> Passing (0.2) -> Push-off (0.3) -> Reaching (0.6)
	add_track_keys.call(anim_walk, P_LEG_L_U_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.48, 0.22, -0.08, -0.46, -0.38, 0.12, 0.38, 0.52, 0.48])
	add_track_keys.call(anim_walk, P_LEG_L_L_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.06, 0.32, 0.18, 0.08, 0.28, 0.62, 0.32, -0.04, -0.06])
	add_track_keys.call(anim_walk, P_LEG_L_F_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.42, -0.08, 0.0, 0.38, 0.10, -0.22, -0.28, -0.48, -0.42])

	# Right Leg: Push-off (0.0) -> Reaching (0.2) -> Contact (0.4) -> Cushion (0.5) -> Passing (0.6)
	add_track_keys.call(anim_walk, P_LEG_R_U_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[-0.38, 0.12, 0.38, 0.52, 0.48, 0.22, -0.08, -0.46, -0.38])
	add_track_keys.call(anim_walk, P_LEG_R_L_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.28, 0.62, 0.32, -0.04, -0.06, 0.32, 0.18, 0.08, 0.28])
	add_track_keys.call(anim_walk, P_LEG_R_F_ROT,
		[0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80],
		[0.10, -0.22, -0.28, -0.48, -0.42, -0.08, 0.0, 0.38, 0.10])

	# Scarf trailing response
	add_track_keys.call(anim_walk, P_SCARF_ROT,
		[0.0, 0.20, 0.40, 0.60, 0.80],
		[-0.12, 0.10, -0.12, 0.10, -0.12])

	anim_lib.add_animation("walk", anim_walk)

	# ============================================================
	# 3. HIGH-ENERGY RUN CYCLE (0.52s, True Flight Phase, 16° Lean, Deep Cushion)
	# ============================================================
	var anim_run = Animation.new()
	anim_run.length = 0.52
	anim_run.loop_mode = Animation.LOOP_LINEAR

	# Flight phase bounce: Air time at 0.13 and 0.39 (hip -64.0), Cushion at 0.0 and 0.26 (hip -49.0)
	add_track_keys.call(anim_run, P_HIP_POS,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[Vector2(0, -49.0), Vector2(0, -64.0), Vector2(0, -49.0), Vector2(0, -64.0), Vector2(0, -49.0)])

	# Strong forward lean (16° = 0.28 rad) with bounce
	add_track_keys.call(anim_run, P_TORSO_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[0.26, 0.32, 0.26, 0.32, 0.26])

	add_track_keys.call(anim_run, P_TORSO_SCL,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[Vector2(1.14, 0.88), Vector2(0.92, 1.10), Vector2(1.14, 0.88), Vector2(0.92, 1.10), Vector2(1.14, 0.88)])

	add_track_keys.call(anim_run, P_HEAD_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[-0.12, 0.04, -0.12, 0.04, -0.12])

	# 90° Bent Pumping Arms driving vigorously
	add_track_keys.call(anim_run, P_ARM_L_U_ROT,
		[0.0, 0.26, 0.52],
		[-1.05, 0.95, -1.05])
	add_track_keys.call(anim_run, P_ARM_L_L_ROT,
		[0.0, 0.26, 0.52],
		[0.85, 0.45, 0.85])

	add_track_keys.call(anim_run, P_ARM_R_U_ROT,
		[0.0, 0.26, 0.52],
		[0.95, -1.05, 0.95])
	add_track_keys.call(anim_run, P_ARM_R_L_ROT,
		[0.0, 0.26, 0.52],
		[0.45, 0.85, 0.45])

	# High knee drive (+0.95 rad) & deep back kick (-0.85 rad)
	add_track_keys.call(anim_run, P_LEG_L_U_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[0.95, 0.25, -0.85, 0.20, 0.95])
	add_track_keys.call(anim_run, P_LEG_L_L_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[-0.20, 0.55, 0.95, 0.80, -0.20])
	add_track_keys.call(anim_run, P_LEG_L_F_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[-0.55, -0.10, 0.25, -0.35, -0.55])

	add_track_keys.call(anim_run, P_LEG_R_U_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[-0.85, 0.20, 0.95, 0.25, -0.85])
	add_track_keys.call(anim_run, P_LEG_R_L_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[0.95, 0.80, -0.20, 0.55, 0.95])
	add_track_keys.call(anim_run, P_LEG_R_F_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[0.25, -0.35, -0.55, -0.10, 0.25])

	# Rapid dynamic scarf flutter behind character
	add_track_keys.call(anim_run, P_SCARF_ROT,
		[0.0, 0.13, 0.26, 0.39, 0.52],
		[-0.55, -0.38, -0.55, -0.38, -0.55])

	anim_lib.add_animation("run", anim_run)

	# ============================================================
	# 4. RUN STOP / BRAKING SKID (0.34s, Heel Dig, Backward Lean & Settle)
	# ============================================================
	var anim_stop = Animation.new()
	anim_stop.length = 0.34

	add_track_keys.call(anim_stop, P_HIP_POS,
		[0.0, 0.10, 0.22, 0.34],
		[Vector2(0, -52.0), Vector2(0, -46.0), Vector2(0, -55.0), Vector2(0, -56.0)])

	add_track_keys.call(anim_stop, P_TORSO_SCL,
		[0.0, 0.10, 0.22, 0.34],
		[Vector2(1.0, 1.0), Vector2(1.20, 0.82), Vector2(0.98, 1.02), Vector2(1.0, 1.0)])

	# Lean backward against momentum (-0.32 rad), rebound forward (+0.06 rad), settle to 0
	add_track_keys.call(anim_stop, P_TORSO_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[0.20, -0.32, 0.06, 0.0])

	add_track_keys.call(anim_stop, P_HEAD_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[0.05, 0.15, -0.04, 0.0])

	# Arms thrown forward for balance
	add_track_keys.call(anim_stop, P_ARM_L_U_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[0.20, 0.68, -0.15, -0.04])
	add_track_keys.call(anim_stop, P_ARM_R_U_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[0.20, 0.68, -0.15, 0.08])

	# Heels dug into ground, knees bent
	add_track_keys.call(anim_stop, P_LEG_L_U_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[0.40, 0.35, 0.05, -0.02])
	add_track_keys.call(anim_stop, P_LEG_L_L_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[-0.10, -0.60, -0.10, 0.02])
	add_track_keys.call(anim_stop, P_LEG_L_F_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[-0.30, -0.35, 0.05, 0.0])

	add_track_keys.call(anim_stop, P_LEG_R_U_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[0.40, 0.35, 0.05, 0.03])
	add_track_keys.call(anim_stop, P_LEG_R_L_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[-0.10, -0.60, -0.10, 0.02])
	add_track_keys.call(anim_stop, P_LEG_R_F_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[-0.30, -0.35, 0.05, -0.05])

	# Scarf snaps forward from sudden deceleration
	add_track_keys.call(anim_stop, P_SCARF_ROT,
		[0.0, 0.10, 0.22, 0.34],
		[-0.45, 0.38, -0.10, 0.0])

	anim_lib.add_animation("run_stop", anim_stop)

	# ============================================================
	# 5. TURN TRANSITION (0.18s, Weight Shift & Profile Pivot)
	# ============================================================
	var anim_turn = Animation.new()
	anim_turn.length = 0.18

	add_track_keys.call(anim_turn, P_HIP_POS,
		[0.0, 0.09, 0.18],
		[Vector2(0, -56.0), Vector2(0, -52.0), Vector2(0, -56.0)])

	add_track_keys.call(anim_turn, P_TORSO_SCL,
		[0.0, 0.09, 0.18],
		[Vector2(1.0, 1.0), Vector2(0.40, 1.05), Vector2(1.0, 1.0)])

	add_track_keys.call(anim_turn, P_HEAD_ROT,
		[0.0, 0.09, 0.18],
		[0.0, -0.25, 0.0])

	add_track_keys.call(anim_turn, P_ARM_L_U_ROT,
		[0.0, 0.09, 0.18],
		[-0.04, -0.35, -0.04])
	add_track_keys.call(anim_turn, P_ARM_R_U_ROT,
		[0.0, 0.09, 0.18],
		[0.08, 0.35, 0.08])

	add_track_keys.call(anim_turn, P_SCARF_ROT,
		[0.0, 0.09, 0.18],
		[0.0, 0.45, 0.0])

	anim_lib.add_animation("turn", anim_turn)

	# ============================================================
	# 6. JUMP ANTICIPATION (0.10s, Deep Elastic Crouch)
	# ============================================================
	var anim_jump_anti = Animation.new()
	anim_jump_anti.length = 0.10

	add_track_keys.call(anim_jump_anti, P_HIP_POS,
		[0.0, 0.10],
		[Vector2(0, -56.0), Vector2(0, -44.0)])

	add_track_keys.call(anim_jump_anti, P_TORSO_SCL,
		[0.0, 0.10],
		[Vector2(1.0, 1.0), Vector2(1.24, 0.78)])

	add_track_keys.call(anim_jump_anti, P_TORSO_ROT,
		[0.0, 0.10],
		[0.0, 0.08])

	add_track_keys.call(anim_jump_anti, P_ARM_L_U_ROT,
		[0.0, 0.10],
		[0.0, -0.72])
	add_track_keys.call(anim_jump_anti, P_ARM_R_U_ROT,
		[0.0, 0.10],
		[0.0, -0.72])

	add_track_keys.call(anim_jump_anti, P_LEG_L_U_ROT,
		[0.0, 0.10],
		[0.0, 0.42])
	add_track_keys.call(anim_jump_anti, P_LEG_L_L_ROT,
		[0.0, 0.10],
		[0.0, -0.75])

	add_track_keys.call(anim_jump_anti, P_LEG_R_U_ROT,
		[0.0, 0.10],
		[0.0, 0.42])
	add_track_keys.call(anim_jump_anti, P_LEG_R_L_ROT,
		[0.0, 0.10],
		[0.0, -0.75])

	anim_lib.add_animation("jump_anticipation", anim_jump_anti)

	# ============================================================
	# 7. JUMP AIRBORNE / ASCENT (0.28s, Vertical Stretch & Sky Reach)
	# ============================================================
	var anim_jump_air = Animation.new()
	anim_jump_air.length = 0.28

	add_track_keys.call(anim_jump_air, P_HIP_POS,
		[0.0, 0.28],
		[Vector2(0, -58.0), Vector2(0, -60.0)])

	add_track_keys.call(anim_jump_air, P_TORSO_SCL,
		[0.0, 0.12, 0.28],
		[Vector2(0.88, 1.18), Vector2(0.96, 1.04), Vector2(1.0, 1.0)])

	add_track_keys.call(anim_jump_air, P_ARM_L_U_ROT,
		[0.0, 0.28],
		[0.82, 0.65])
	add_track_keys.call(anim_jump_air, P_ARM_R_U_ROT,
		[0.0, 0.28],
		[0.82, 0.65])

	add_track_keys.call(anim_jump_air, P_LEG_L_U_ROT,
		[0.0, 0.28],
		[-0.15, -0.08])
	add_track_keys.call(anim_jump_air, P_LEG_L_L_ROT,
		[0.0, 0.28],
		[0.08, 0.15])
	add_track_keys.call(anim_jump_air, P_LEG_L_F_ROT,
		[0.0, 0.28],
		[0.28, 0.18])

	add_track_keys.call(anim_jump_air, P_LEG_R_U_ROT,
		[0.0, 0.28],
		[0.10, 0.14])
	add_track_keys.call(anim_jump_air, P_LEG_R_L_ROT,
		[0.0, 0.28],
		[0.32, 0.38])
	add_track_keys.call(anim_jump_air, P_LEG_R_F_ROT,
		[0.0, 0.28],
		[0.25, 0.15])

	add_track_keys.call(anim_jump_air, P_SCARF_ROT,
		[0.0, 0.28],
		[0.28, 0.16])

	anim_lib.add_animation("jump_airborne", anim_jump_air)

	# ============================================================
	# 8. FALL (0.28s, Air Drag Pose, Feet Dangling, Scarf Upward)
	# ============================================================
	var anim_fall = Animation.new()
	anim_fall.length = 0.28

	add_track_keys.call(anim_fall, P_HIP_POS,
		[0.0, 0.28],
		[Vector2(0, -56.0), Vector2(0, -56.0)])

	add_track_keys.call(anim_fall, P_TORSO_SCL,
		[0.0, 0.28],
		[Vector2(1.06, 0.94), Vector2(1.06, 0.94)])

	add_track_keys.call(anim_fall, P_TORSO_ROT,
		[0.0, 0.28],
		[0.06, 0.06])

	add_track_keys.call(anim_fall, P_ARM_L_U_ROT,
		[0.0, 0.28],
		[1.05, 1.0])
	add_track_keys.call(anim_fall, P_ARM_R_U_ROT,
		[0.0, 0.28],
		[1.05, 1.0])

	add_track_keys.call(anim_fall, P_LEG_L_U_ROT,
		[0.0, 0.28],
		[0.24, 0.24])
	add_track_keys.call(anim_fall, P_LEG_L_L_ROT,
		[0.0, 0.28],
		[-0.32, -0.32])

	add_track_keys.call(anim_fall, P_LEG_R_U_ROT,
		[0.0, 0.28],
		[0.24, 0.24])
	add_track_keys.call(anim_fall, P_LEG_R_L_ROT,
		[0.0, 0.28],
		[-0.32, -0.32])

	# Scarf pushed upward by air resistance
	add_track_keys.call(anim_fall, P_SCARF_ROT,
		[0.0, 0.28],
		[0.55, 0.50])

	anim_lib.add_animation("fall", anim_fall)

	# ============================================================
	# 9. JUMP LAND (0.18s, Heavy Impact Compression & Rebound)
	# ============================================================
	var anim_land = Animation.new()
	anim_land.length = 0.18

	add_track_keys.call(anim_land, P_HIP_POS,
		[0.0, 0.07, 0.18],
		[Vector2(0, -56.0), Vector2(0, -45.0), Vector2(0, -56.0)])

	add_track_keys.call(anim_land, P_TORSO_SCL,
		[0.0, 0.07, 0.18],
		[Vector2(1.0, 1.0), Vector2(1.26, 0.75), Vector2(1.0, 1.0)])

	add_track_keys.call(anim_land, P_TORSO_ROT,
		[0.0, 0.07, 0.18],
		[0.0, 0.06, 0.0])

	add_track_keys.call(anim_land, P_ARM_L_U_ROT,
		[0.0, 0.07, 0.18],
		[0.45, -0.48, -0.04])
	add_track_keys.call(anim_land, P_ARM_R_U_ROT,
		[0.0, 0.07, 0.18],
		[0.45, -0.48, 0.08])

	add_track_keys.call(anim_land, P_LEG_L_U_ROT,
		[0.0, 0.07, 0.18],
		[0.0, 0.40, -0.02])
	add_track_keys.call(anim_land, P_LEG_L_L_ROT,
		[0.0, 0.07, 0.18],
		[0.0, -0.72, 0.02])

	add_track_keys.call(anim_land, P_LEG_R_U_ROT,
		[0.0, 0.07, 0.18],
		[0.0, 0.40, 0.03])
	add_track_keys.call(anim_land, P_LEG_R_L_ROT,
		[0.0, 0.07, 0.18],
		[0.0, -0.72, 0.02])

	anim_lib.add_animation("jump_land", anim_land)

	# ============================================================
	# 10. HIGH-PRIORITY ATTACK (0.50s, Deep Anticipation, Piston Strike, Hit-Stop, Follow-Through)
	# ============================================================
	var anim_atk = Animation.new()
	anim_atk.length = 0.50

	# Hip Position: Coil back (0.12), Explosive lunge forward (0.18), Settle (0.50)
	add_track_keys.call(anim_atk, P_HIP_POS,
		[0.0, 0.12, 0.18, 0.30, 0.50],
		[Vector2(0, -56.0), Vector2(-8, -52.0), Vector2(16, -54.0), Vector2(6, -56.0), Vector2(0, -56.0)])

	# Torso: Coil backward (-0.35 rad), Violent punch thrust (+0.38 rad), Overshoot (+0.18 rad), Settle (0)
	add_track_keys.call(anim_atk, P_TORSO_ROT,
		[0.0, 0.12, 0.18, 0.30, 0.50],
		[0.0, -0.35, 0.38, 0.18, 0.0])

	add_track_keys.call(anim_atk, P_TORSO_SCL,
		[0.0, 0.12, 0.18, 0.30, 0.50],
		[Vector2(1, 1), Vector2(0.88, 1.14), Vector2(1.20, 0.85), Vector2(1.02, 0.98), Vector2(1, 1)])

	add_track_keys.call(anim_atk, P_HEAD_ROT,
		[0.0, 0.12, 0.18, 0.30, 0.50],
		[0.0, -0.22, 0.12, 0.06, 0.0])

	# Right Arm: Piston Punch (Cocked back tightly at 0.12, Full thrust punch at 0.18)
	add_track_keys.call(anim_atk, P_ARM_R_U_ROT,
		[0.0, 0.12, 0.18, 0.30, 0.50],
		[0.08, -1.35, 1.38, 1.15, 0.08])
	add_track_keys.call(anim_atk, P_ARM_R_L_ROT,
		[0.0, 0.12, 0.18, 0.30, 0.50],
		[0.24, 1.55, 0.05, 0.18, 0.24])

	# Left Arm: Counter-balance aim forward (0.12), Recoil back (0.18)
	add_track_keys.call(anim_atk, P_ARM_L_U_ROT,
		[0.0, 0.12, 0.18, 0.30, 0.50],
		[-0.04, 0.58, -0.92, -0.55, -0.04])

	# Legs: Wide combat stance
	add_track_keys.call(anim_atk, P_LEG_L_U_ROT,
		[0.0, 0.12, 0.18, 0.50],
		[-0.02, -0.20, -0.38, -0.02])
	add_track_keys.call(anim_atk, P_LEG_R_U_ROT,
		[0.0, 0.12, 0.18, 0.50],
		[0.03, 0.28, 0.48, 0.03])

	# Scarf: Coils back, then whips forward over shoulder
	add_track_keys.call(anim_atk, P_SCARF_ROT,
		[0.0, 0.12, 0.22, 0.50],
		[0.0, -0.45, 0.48, 0.0])

	# Method Track: Deterministic ATTACK_IMPACT event fired precisely at t = 0.18s
	var m_idx = anim_atk.add_track(Animation.TYPE_METHOD)
	anim_atk.track_set_path(m_idx, ".")
	anim_atk.track_insert_key(m_idx, 0.18, {"method": "on_attack_impact_event", "args": []})

	anim_lib.add_animation("attack", anim_atk)

	# ============================================================
	# 11. HIT REACTION (0.24s, Impact Compression, Recoil & Head Whip)
	# ============================================================
	var anim_hit = Animation.new()
	anim_hit.length = 0.24

	add_track_keys.call(anim_hit, P_HIP_POS,
		[0.0, 0.06, 0.15, 0.24],
		[Vector2(0, -56.0), Vector2(-15, -53.0), Vector2(-5, -56.0), Vector2(0, -56.0)])

	add_track_keys.call(anim_hit, P_TORSO_ROT,
		[0.0, 0.06, 0.15, 0.24],
		[0.0, -0.42, -0.14, 0.0])

	add_track_keys.call(anim_hit, P_TORSO_SCL,
		[0.0, 0.06, 0.15, 0.24],
		[Vector2(1, 1), Vector2(0.82, 1.18), Vector2(1.06, 0.94), Vector2(1, 1)])

	add_track_keys.call(anim_hit, P_HEAD_ROT,
		[0.0, 0.06, 0.15, 0.24],
		[0.0, -0.52, -0.16, 0.0])

	add_track_keys.call(anim_hit, P_ARM_L_U_ROT,
		[0.0, 0.06, 0.15, 0.24],
		[0.0, -0.92, -0.32, -0.04])
	add_track_keys.call(anim_hit, P_ARM_R_U_ROT,
		[0.0, 0.06, 0.15, 0.24],
		[0.0, -0.92, -0.32, 0.08])

	add_track_keys.call(anim_hit, P_SCARF_ROT,
		[0.0, 0.06, 0.24],
		[0.0, -0.62, 0.0])

	anim_lib.add_animation("hit", anim_hit)

	# ============================================================
	# 12. KNOCKBACK (0.65s, Airborne Tumble Arc, Ground Crash & Standup)
	# ============================================================
	var anim_kb = Animation.new()
	anim_kb.length = 0.65

	add_track_keys.call(anim_kb, P_HIP_POS,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[Vector2(0, -56.0), Vector2(-10, -64.0), Vector2(-4, -56.0), Vector2(0, -46.0), Vector2(0, -56.0)])

	add_track_keys.call(anim_kb, P_TORSO_ROT,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[0.0, -0.85, -0.38, 0.18, 0.0])

	add_track_keys.call(anim_kb, P_TORSO_SCL,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[Vector2(1, 1), Vector2(0.82, 1.18), Vector2(1, 1), Vector2(1.28, 0.74), Vector2(1, 1)])

	add_track_keys.call(anim_kb, P_HEAD_ROT,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[0.0, -0.55, -0.22, 0.12, 0.0])

	add_track_keys.call(anim_kb, P_ARM_L_U_ROT,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[0.0, -1.18, 0.45, -0.55, -0.04])
	add_track_keys.call(anim_kb, P_ARM_R_U_ROT,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[0.0, -1.32, 0.60, -0.55, 0.08])

	add_track_keys.call(anim_kb, P_LEG_L_U_ROT,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[0.0, 0.72, 0.24, 0.38, -0.02])
	add_track_keys.call(anim_kb, P_LEG_R_U_ROT,
		[0.0, 0.14, 0.35, 0.50, 0.65],
		[0.0, 0.92, 0.45, 0.38, 0.03])

	add_track_keys.call(anim_kb, P_SCARF_ROT,
		[0.0, 0.14, 0.35, 0.65],
		[0.0, -0.78, 0.35, 0.0])

	anim_lib.add_animation("knockback", anim_kb)

	# Register library with AnimationPlayer
	anim_player.add_animation_library("", anim_lib)

	# Configure smooth cross-fade blend times to prevent visual popping
	anim_player.set_blend_time("idle", "walk", 0.12)
	anim_player.set_blend_time("walk", "idle", 0.12)
	anim_player.set_blend_time("walk", "run", 0.10)
	anim_player.set_blend_time("run", "walk", 0.12)
	anim_player.set_blend_time("run", "run_stop", 0.08)
	anim_player.set_blend_time("run_stop", "idle", 0.10)
	anim_player.set_blend_time("jump_land", "idle", 0.10)
	anim_player.set_blend_time("jump_land", "walk", 0.10)
	anim_player.set_blend_time("jump_land", "run", 0.10)
	anim_player.set_blend_time("attack", "idle", 0.12)
	anim_player.set_blend_time("hit", "idle", 0.10)
	anim_player.set_blend_time("knockback", "idle", 0.12)

	# Save PackedScene
	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/character.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scene: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/character.tscn with 12 high-quality cartoon animations & cross-fade blends!")
	quit(0)
