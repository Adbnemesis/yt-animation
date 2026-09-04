@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Authentic Leon Side-View Puppet Rig (scenes/leon_side.tscn)...")

	var root = CharacterBody2D.new()
	root.name = "LeonSide"
	root.set_script(load("res://scripts/character_controller.gd"))

	# 1. Collision Shape (Capsule)
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var capsule = CapsuleShape2D.new()
	capsule.radius = 22.0
	capsule.height = 96.0
	col.shape = capsule
	col.position = Vector2(0, -48)
	root.add_child(col)
	col.owner = root

	# 2. Visuals Root (z_index = 5, z_as_relative = false)
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

	# Textures Preload
	var tex_hood = load("res://assets/leon/side/hood.svg")
	var tex_face = load("res://assets/leon/side/face.svg")
	var tex_torso = load("res://assets/leon/side/torso.svg")
	var tex_tail = load("res://assets/leon/side/tail.svg")
	var tex_leg_upper = load("res://assets/leon/side/leg_upper.svg")
	var tex_leg_lower = load("res://assets/leon/side/leg_lower.svg")
	var tex_foot = load("res://assets/leon/side/foot.svg")
	var tex_arm_upper = load("res://assets/leon/side/arm_upper.svg")
	var tex_arm_lower = load("res://assets/leon/side/arm_lower.svg")
	var tex_hand = load("res://assets/leon/side/hand.svg")

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

	# Tail (Z = -2)
	var b_tail = create_bone.call("tail", Vector2(-16, 12), b_root, true)
	create_sprite.call("TailSprite", tex_tail, Vector2(-8, 10), -2, b_tail)

	# FAR LIMBS (Back Layer, Z = -1)
	# Far Leg: Hip -> Knee -> Ankle -> Foot
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
	# Near Leg: Hip -> Knee -> Ankle -> Foot
	var b_leg_r_upper = create_bone.call("leg_R_upper", Vector2(4, 10), b_root)
	create_sprite.call("LegSpriteR", tex_leg_upper, Vector2(0, 8), 1, b_leg_r_upper)

	var b_leg_r_lower = create_bone.call("leg_R_lower", Vector2(0, 14), b_leg_r_upper)
	create_sprite.call("LegLowerSpriteR", tex_leg_lower, Vector2(0, 6), 1, b_leg_r_lower)

	var b_foot_r = create_bone.call("foot_R", Vector2(0, 14), b_leg_r_lower, true)
	create_sprite.call("FootSpriteR", tex_foot, Vector2(4, 2), 1, b_foot_r)

	# Near Arm (Front Layer, Z = 3 so it renders in front of Hood & Face Z = 2)
	var b_arm_r_upper = create_bone.call("arm_R_upper", Vector2(6, -20), b_torso)
	create_sprite.call("ArmSpriteR", tex_arm_upper, Vector2(0, 8), 3, b_arm_r_upper)

	var b_arm_r_lower = create_bone.call("arm_R_lower", Vector2(0, 14), b_arm_r_upper)
	create_sprite.call("ArmLowerSpriteR", tex_arm_lower, Vector2(0, 6), 3, b_arm_r_lower)

	var b_hand_r = create_bone.call("hand_R", Vector2(0, 12), b_arm_r_lower, true)
	create_sprite.call("HandSpriteR", tex_hand, Vector2(0, 4), 3, b_hand_r)

	# Projectile Spawn Point (Hand Attachment)
	var p_spawn = Marker2D.new()
	p_spawn.name = "ProjectileSpawnPoint"
	p_spawn.position = Vector2(10, 2)
	b_hand_r.add_child(p_spawn)
	p_spawn.owner = root

	# Neck & Head (Z = 2)
	var b_neck = create_bone.call("neck", Vector2(0, -26), b_torso)
	var b_head = create_bone.call("head", Vector2(0, -8), b_neck, true)
	create_sprite.call("HoodSprite", tex_hood, Vector2(-4, -34), 2, b_head)
	create_sprite.call("FaceSprite", tex_face, Vector2(10, -20), 2, b_head)

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

	var candy_point = Marker2D.new()
	candy_point.name = "CandyPoint"
	candy_point.position = Vector2(28, -56)
	vfx.add_child(candy_point)
	candy_point.owner = root

	var proj_point = Marker2D.new()
	proj_point.name = "ProjectileSpawn"
	proj_point.position = Vector2(28, -48)
	vfx.add_child(proj_point)
	proj_point.owner = root

	# ANIMATION PLAYER
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
		for i in range(times.size()):
			anim.track_insert_key(idx, times[i], values[i])

	# Helper for adding method call tracks
	var add_method_track = func(anim: Animation, times: Array, methods: Array) -> void:
		var idx = anim.add_track(Animation.TYPE_METHOD)
		anim.track_set_path(idx, ".")
		for i in range(times.size()):
			anim.track_insert_key(idx, times[i], {
				"method": methods[i],
				"args": []
			})

	# 1. IDLE Animation (2.0s, Side Breathing Stance)
	var a_idle = Animation.new()
	a_idle.length = 2.0
	a_idle.loop_mode = Animation.LOOP_LINEAR
	add_track_keys.call(a_idle, "Visuals/Skeleton/root:position", [0.0, 1.0, 2.0], [Vector2(0, -38.0), Vector2(0, -39.2), Vector2(0, -38.0)])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso:rotation", [0.0, 1.0, 2.0], [0.03, 0.05, 0.03])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/neck/head:rotation", [0.0, 1.0, 2.0], [-0.02, 0.0, -0.02])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/tail:rotation", [0.0, 0.7, 1.4, 2.0], [0.0, 0.08, -0.06, 0.0])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", [0.0, 1.0, 2.0], [0.05, -0.02, 0.05])
	add_track_keys.call(a_idle, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", [0.0, 1.0, 2.0], [0.20, 0.28, 0.20])
	anim_lib.add_animation("idle", a_idle)

	# 2. CLASSICAL 6-PHASE SIDE WALK CYCLE (0.80s, Pure Side Profile, Walk 1 & Walk 2)
	# Times: 0.0 (Contact 1), 0.10 (Down 1), 0.20 (Passing 1), 0.30 (Up 1),
	#        0.40 (Contact 2), 0.50 (Down 2), 0.60 (Passing 2), 0.70 (Up 2), 0.80 (Contact 1)
	var a_walk = Animation.new()
	a_walk.length = 0.80
	a_walk.loop_mode = Animation.LOOP_LINEAR
	var walk_times = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80]

	# Root Vertical Bobbing
	add_track_keys.call(a_walk, "Visuals/Skeleton/root:position", walk_times, [
		Vector2(0, -38.0), Vector2(0, -36.2), Vector2(0, -38.5), Vector2(0, -40.0),
		Vector2(0, -38.0), Vector2(0, -36.2), Vector2(0, -38.5), Vector2(0, -40.0), Vector2(0, -38.0)
	])

	# Root Sway / Hip Rotation
	add_track_keys.call(a_walk, "Visuals/Skeleton/root:rotation", walk_times, [
		-0.02, -0.035, -0.015, 0.015, 0.02, 0.035, 0.015, -0.015, -0.02
	])

	# Torso Forward Lean
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso:rotation", walk_times, [
		0.06, 0.08, 0.04, 0.05, 0.06, 0.08, 0.04, 0.05, 0.06
	])

	# Neck Stabilization
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck:rotation", walk_times, [
		-0.02, -0.03, -0.01, -0.02, -0.02, -0.03, -0.01, -0.02, -0.02
	])

	# Head Counter-Rotation (Gaze Stabilized Forward)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/neck/head:rotation", walk_times, [
		-0.04, -0.02, -0.05, -0.03, -0.04, -0.02, -0.05, -0.03, -0.04
	])

	# NEAR LEG (Right, Z = +1): Stride Forward on Contact 1 (t=0.0) -> Planted Cushion (t=0.1) -> Support (t=0.2) -> Push-off (t=0.3)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper:rotation", walk_times, [
		0.52, 0.26, -0.06, -0.48, -0.40, -0.15, 0.30, 0.50, 0.52
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", walk_times, [
		0.00, 0.30, 0.08, 0.12, 0.22, 0.60, 0.70, 0.14, 0.00
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", walk_times, [
		-0.40, 0.00, 0.00, 0.38, 0.25, -0.10, -0.15, -0.36, -0.40
	])

	# FAR LEG (Left, Z = -1): Push-off (t=0.0) -> Swing Recovery (t=0.1-0.3) -> Contact 2 (t=0.4) -> Cushion (t=0.5)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper:rotation", walk_times, [
		-0.40, -0.15, 0.30, 0.50, 0.52, 0.26, -0.06, -0.48, -0.40
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", walk_times, [
		0.22, 0.60, 0.70, 0.14, 0.00, 0.30, 0.08, 0.12, 0.22
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", walk_times, [
		0.25, -0.10, -0.15, -0.36, -0.40, 0.00, 0.00, 0.38, 0.25
	])

	# NEAR ARM (Right, Z = +1): Opposes Near Leg (Swings Back when Near Leg reaches forward)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", walk_times, [
		-0.42, -0.28, -0.08, 0.22, 0.45, 0.30, 0.08, -0.22, -0.42
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", walk_times, [
		0.18, 0.22, 0.25, 0.40, 0.42, 0.32, 0.22, 0.18, 0.18
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation", walk_times, [
		0.06, 0.08, 0.00, -0.08, -0.10, -0.05, 0.02, 0.08, 0.06
	])

	# FAR ARM (Left, Z = -1): Opposes Far Leg (Swings Forward when Near Leg reaches forward)
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", walk_times, [
		0.45, 0.30, 0.08, -0.22, -0.42, -0.28, -0.08, 0.22, 0.45
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", walk_times, [
		0.42, 0.32, 0.22, 0.18, 0.18, 0.22, 0.25, 0.40, 0.42
	])
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation", walk_times, [
		-0.10, -0.05, 0.02, 0.08, 0.06, 0.08, 0.00, -0.08, -0.10
	])

	# Tail Secondary Motion
	add_track_keys.call(a_walk, "Visuals/Skeleton/root/tail:rotation", walk_times, [
		0.10, -0.06, 0.04, -0.10, 0.10, -0.06, 0.04, -0.10, 0.10
	])

	anim_lib.add_animation("walk", a_walk)
	anim_lib.add_animation("LEON_WALK", a_walk.duplicate())

	# 3. RUN CYCLE (0.50s, High Energy Cartoon Sprint, Loop Linear)
	# Times: 0.0 (Contact 1), 0.08 (Compression 1), 0.16 (Apex 1),
	#        0.25 (Contact 2), 0.33 (Compression 2), 0.41 (Apex 2), 0.50 (Loop)
	var a_run = Animation.new()
	a_run.length = 0.50
	a_run.loop_mode = Animation.LOOP_LINEAR
	var run_times = [0.0, 0.08, 0.16, 0.25, 0.33, 0.41, 0.50]

	# Root Vertical Bounce (Deep dip during plant, high lift during push-off)
	add_track_keys.call(a_run, "Visuals/Skeleton/root:position", run_times, [
		Vector2(0, -38.0), Vector2(0, -35.2), Vector2(0, -41.5),
		Vector2(0, -38.0), Vector2(0, -35.2), Vector2(0, -41.5), Vector2(0, -38.0)
	])

	# Root Hip Roll
	add_track_keys.call(a_run, "Visuals/Skeleton/root:rotation", run_times, [
		-0.04, -0.06, -0.02, 0.04, 0.06, 0.02, -0.04
	])

	# Torso Aggressive Sprint Forward Lean (~14° - 16°)
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso:rotation", run_times, [
		0.24, 0.28, 0.22, 0.24, 0.28, 0.22, 0.24
	])

	# Neck & Head Gaze Stabilization (Counter-rotating to lock horizon forward)
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/neck:rotation", run_times, [
		-0.08, -0.10, -0.06, -0.08, -0.10, -0.06, -0.08
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/neck/head:rotation", run_times, [
		-0.14, -0.16, -0.12, -0.14, -0.16, -0.12, -0.14
	])

	# NEAR LEG (Right, Z = +1): Wide stride reach -> Plant cushion -> Apex drive
	add_track_keys.call(a_run, "Visuals/Skeleton/root/leg_R_upper:rotation", run_times, [
		0.72, 0.35, -0.35, -0.65, -0.20, 0.45, 0.72
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", run_times, [
		0.05, 0.42, 0.18, 0.35, 0.95, 0.80, 0.05
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", run_times, [
		-0.45, 0.00, 0.25, 0.40, -0.15, -0.20, -0.45
	])

	# FAR LEG (Left, Z = -1): Trailing push-off -> High knee recovery -> Contact 2
	add_track_keys.call(a_run, "Visuals/Skeleton/root/leg_L_upper:rotation", run_times, [
		-0.65, -0.20, 0.45, 0.72, 0.35, -0.35, -0.65
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", run_times, [
		0.35, 0.95, 0.80, 0.05, 0.42, 0.18, 0.35
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", run_times, [
		0.40, -0.15, -0.20, -0.45, 0.00, 0.25, 0.40
	])

	# NEAR ARM (Right, Z = +1): Athletic arm pump with tucked elbow
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", run_times, [
		-0.75, -0.40, 0.20, 0.80, 0.50, -0.20, -0.75
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", run_times, [
		0.70, 0.55, 0.65, 0.85, 0.70, 0.65, 0.70
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation", run_times, [
		0.12, 0.08, -0.05, -0.15, -0.08, 0.05, 0.12
	])

	# FAR ARM (Left, Z = -1): Opposing pump
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", run_times, [
		0.80, 0.50, -0.20, -0.75, -0.40, 0.20, 0.80
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", run_times, [
		0.85, 0.70, 0.65, 0.70, 0.55, 0.65, 0.85
	])
	add_track_keys.call(a_run, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation", run_times, [
		-0.15, -0.08, 0.05, 0.12, 0.08, -0.05, -0.15
	])

	# Tail Energetic Sway
	add_track_keys.call(a_run, "Visuals/Skeleton/root/tail:rotation", run_times, [
		-0.15, 0.12, -0.08, 0.15, -0.12, 0.08, -0.15
	])

	anim_lib.add_animation("run", a_run)
	anim_lib.add_animation("LEON_RUN", a_run.duplicate())

	# 4. RUN STOP / DECELERATION (0.36s, Momentum Braking & Settle, Non-Looping)
	var a_run_stop = Animation.new()
	a_run_stop.length = 0.36
	var run_stop_times = [0.0, 0.08, 0.18, 0.28, 0.36]

	# Root: Skids low during brake, rebounds slightly, settles to idle
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root:position", run_stop_times, [
		Vector2(0, -38.0), Vector2(0, -35.0), Vector2(0, -36.8), Vector2(0, -37.8), Vector2(0, -38.0)
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root:rotation", run_stop_times, [
		0.0, -0.05, 0.02, 0.0, 0.0
	])

	# Torso: Leans BACK against forward momentum, overshoots forward, settles to 0.03 rad (idle)
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/torso:rotation", run_stop_times, [
		0.20, -0.18, 0.08, 0.04, 0.03
	])

	# Neck & Head: Head fights forward during brake, overshoots, settles
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/torso/neck:rotation", run_stop_times, [
		-0.08, 0.05, -0.03, 0.0, 0.0
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/torso/neck/head:rotation", run_stop_times, [
		-0.12, 0.10, -0.06, -0.03, -0.02
	])

	# Near Leg: Plants out forward for braking (heel dig), then settles
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/leg_R_upper:rotation", run_stop_times, [
		0.55, 0.52, 0.18, 0.05, 0.0
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", run_stop_times, [
		0.10, 0.25, 0.12, 0.04, 0.0
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", run_stop_times, [
		-0.35, -0.15, 0.0, 0.0, 0.0
	])

	# Far Leg: Braces slightly behind/center
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/leg_L_upper:rotation", run_stop_times, [
		-0.20, 0.25, -0.08, -0.02, 0.0
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", run_stop_times, [
		0.30, 0.35, 0.10, 0.02, 0.0
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", run_stop_times, [
		0.0, 0.0, 0.0, 0.0, 0.0
	])

	# Arms: Flailed back/out for balance during brake, then swing forward during rebound, settle
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", run_stop_times, [
		-0.50, -0.45, 0.18, 0.08, 0.05
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", run_stop_times, [
		0.60, 0.50, 0.30, 0.22, 0.20
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", run_stop_times, [
		-0.45, -0.40, 0.15, 0.05, 0.0
	])
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", run_stop_times, [
		0.55, 0.45, 0.28, 0.20, 0.18
	])

	# Tail: Lifts up from sudden stop
	add_track_keys.call(a_run_stop, "Visuals/Skeleton/root/tail:rotation", run_stop_times, [
		-0.10, 0.22, -0.08, 0.02, 0.0
	])

	anim_lib.add_animation("run_stop", a_run_stop)
	anim_lib.add_animation("LEON_STOP", a_run_stop.duplicate())

	# 5. WALK STOP / DECELERATION (0.24s, Gentle Stride Settle, Non-Looping)
	var a_walk_stop = Animation.new()
	a_walk_stop.length = 0.24
	var walk_stop_times = [0.0, 0.08, 0.16, 0.24]

	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root:position", walk_stop_times, [
		Vector2(0, -38.0), Vector2(0, -36.8), Vector2(0, -37.8), Vector2(0, -38.0)
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root:rotation", walk_stop_times, [
		0.0, -0.02, 0.01, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/torso:rotation", walk_stop_times, [
		0.06, -0.04, 0.05, 0.03
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/torso/neck/head:rotation", walk_stop_times, [
		-0.03, 0.02, -0.01, -0.02
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/leg_R_upper:rotation", walk_stop_times, [
		0.30, 0.15, 0.05, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", walk_stop_times, [
		0.08, 0.12, 0.04, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", walk_stop_times, [
		-0.10, 0.0, 0.0, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/leg_L_upper:rotation", walk_stop_times, [
		-0.20, 0.08, -0.02, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", walk_stop_times, [
		0.15, 0.10, 0.02, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", walk_stop_times, [
		0.05, 0.0, 0.0, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", walk_stop_times, [
		-0.20, 0.10, 0.06, 0.05
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", walk_stop_times, [
		0.25, 0.22, 0.20, 0.20
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", walk_stop_times, [
		0.20, -0.05, 0.02, 0.0
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", walk_stop_times, [
		0.25, 0.20, 0.18, 0.18
	])
	add_track_keys.call(a_walk_stop, "Visuals/Skeleton/root/tail:rotation", walk_stop_times, [
		0.05, 0.10, -0.02, 0.0
	])

	anim_lib.add_animation("walk_stop", a_walk_stop)

	# 6. TURN (0.20s, 180° Direction Change Pivot, Non-Looping)
	var a_turn = Animation.new()
	a_turn.length = 0.20
	var turn_times = [0.0, 0.06, 0.10, 0.15, 0.20]

	# Root: Anticipation crouch (0.06), spring pivot (0.10), land cushion (0.15), settle (0.20)
	add_track_keys.call(a_turn, "Visuals/Skeleton/root:position", turn_times, [
		Vector2(0, -38.0), Vector2(0, -34.8), Vector2(0, -40.5), Vector2(0, -36.5), Vector2(0, -38.0)
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root:rotation", turn_times, [
		0.0, 0.06, -0.04, 0.02, 0.0
	])

	# Torso: Anticipation twist inward, snap, settle
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/torso:rotation", turn_times, [
		0.04, 0.14, -0.10, 0.05, 0.04
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/torso/neck/head:rotation", turn_times, [
		-0.02, -0.08, 0.06, -0.04, -0.02
	])

	# Legs: Crouch, pivot spring, foot reposition
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/leg_R_upper:rotation", turn_times, [
		0.10, 0.25, -0.15, 0.08, 0.0
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", turn_times, [
		0.0, 0.35, 0.10, 0.15, 0.0
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", turn_times, [
		0.0, -0.10, 0.05, 0.0, 0.0
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/leg_L_upper:rotation", turn_times, [
		-0.10, -0.18, 0.20, -0.05, 0.0
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", turn_times, [
		0.0, 0.32, 0.12, 0.12, 0.0
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", turn_times, [
		0.0, 0.05, -0.05, 0.0, 0.0
	])

	# Arms: Tuck in close during pivot
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", turn_times, [
		0.0, 0.30, -0.25, 0.10, 0.05
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", turn_times, [
		0.20, 0.50, 0.35, 0.25, 0.20
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", turn_times, [
		0.0, -0.25, 0.20, -0.05, 0.0
	])
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", turn_times, [
		0.18, 0.45, 0.30, 0.22, 0.18
	])

	# Tail: Swings around during body pivot
	add_track_keys.call(a_turn, "Visuals/Skeleton/root/tail:rotation", turn_times, [
		0.0, 0.20, -0.18, 0.05, 0.0
	])

	anim_lib.add_animation("turn", a_turn)
	anim_lib.add_animation("LEON_TURN", a_turn.duplicate())

	# 7. JUMP ANTICIPATION (0.10s, Snappy Crouch & Coiling, Non-Looping)
	var a_jump_anticipation = Animation.new()
	a_jump_anticipation.length = 0.10
	var j_anti_times = [0.0, 0.05, 0.10]

	# Root: Dips down 6px into compression crouch
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root:position", j_anti_times, [
		Vector2(0, -38.0), Vector2(0, -32.5), Vector2(0, -32.0)
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root:rotation", j_anti_times, [
		0.0, 0.02, 0.03
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/torso:rotation", j_anti_times, [
		0.03, 0.10, 0.12
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/torso/neck:rotation", j_anti_times, [
		0.0, -0.04, -0.05
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/torso/neck/head:rotation", j_anti_times, [
		-0.02, -0.06, -0.08
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/leg_R_upper:rotation", j_anti_times, [
		0.0, 0.18, 0.22
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", j_anti_times, [
		0.0, 0.45, 0.52
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", j_anti_times, [
		0.0, -0.05, -0.08
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/leg_L_upper:rotation", j_anti_times, [
		0.0, 0.16, 0.20
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", j_anti_times, [
		0.0, 0.45, 0.52
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", j_anti_times, [
		0.0, -0.05, -0.08
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", j_anti_times, [
		0.05, -0.35, -0.45
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", j_anti_times, [
		0.20, 0.45, 0.50
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", j_anti_times, [
		0.0, -0.30, -0.40
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", j_anti_times, [
		0.18, 0.40, 0.45
	])
	add_track_keys.call(a_jump_anticipation, "Visuals/Skeleton/root/tail:rotation", j_anti_times, [
		0.0, -0.12, -0.15
	])

	anim_lib.add_animation("jump_anticipation", a_jump_anticipation)

	# 8. JUMP AIRBORNE / ASCENT (0.30s, Elongated Airborne Stretch, Non-Looping)
	var a_jump_airborne = Animation.new()
	a_jump_airborne.length = 0.30
	var j_air_times = [0.0, 0.12, 0.30]

	# Root lifts high in stretch
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root:position", j_air_times, [
		Vector2(0, -32.0), Vector2(0, -42.0), Vector2(0, -40.0)
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root:rotation", j_air_times, [
		0.03, -0.02, -0.01
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/torso:rotation", j_air_times, [
		0.12, -0.06, -0.04
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/torso/neck/head:rotation", j_air_times, [
		-0.08, 0.04, 0.02
	])
	# Legs extended downward with toes pointed
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/leg_R_upper:rotation", j_air_times, [
		0.22, -0.12, -0.10
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", j_air_times, [
		0.52, 0.08, 0.06
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", j_air_times, [
		-0.08, 0.35, 0.30
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/leg_L_upper:rotation", j_air_times, [
		0.20, -0.08, -0.06
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", j_air_times, [
		0.52, 0.10, 0.08
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", j_air_times, [
		-0.08, 0.35, 0.30
	])
	# Arms lifted high in ascent
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", j_air_times, [
		-0.45, 0.65, 0.55
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", j_air_times, [
		0.50, 0.35, 0.30
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", j_air_times, [
		-0.40, 0.60, 0.50
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", j_air_times, [
		0.45, 0.35, 0.30
	])
	add_track_keys.call(a_jump_airborne, "Visuals/Skeleton/root/tail:rotation", j_air_times, [
		-0.15, 0.12, 0.08
	])

	anim_lib.add_animation("jump_airborne", a_jump_airborne)
	anim_lib.add_animation("LEON_JUMP", a_jump_airborne.duplicate())

	# 9. FALL (0.30s, Dedicated Descent Pose with Tucked Knees, Loop Linear)
	var a_fall = Animation.new()
	a_fall.length = 0.30
	a_fall.loop_mode = Animation.LOOP_LINEAR
	var fall_times = [0.0, 0.15, 0.30]

	add_track_keys.call(a_fall, "Visuals/Skeleton/root:position", fall_times, [
		Vector2(0, -38.0), Vector2(0, -37.5), Vector2(0, -38.0)
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root:rotation", fall_times, [
		0.02, 0.04, 0.02
	])
	# Torso forward lean into descent
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/torso:rotation", fall_times, [
		0.14, 0.16, 0.14
	])
	# Head looking down toward landing zone
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/torso/neck/head:rotation", fall_times, [
		0.12, 0.15, 0.12
	])
	# Knees tucked up in air, feet ready to contact
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/leg_R_upper:rotation", fall_times, [
		0.22, 0.25, 0.22
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", fall_times, [
		0.40, 0.45, 0.40
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", fall_times, [
		-0.12, -0.15, -0.12
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/leg_L_upper:rotation", fall_times, [
		-0.10, -0.12, -0.10
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", fall_times, [
		0.38, 0.42, 0.38
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", fall_times, [
		-0.10, -0.12, -0.10
	])
	# Arms flared out/upward against wind
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", fall_times, [
		-0.28, -0.32, -0.28
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", fall_times, [
		0.50, 0.55, 0.50
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", fall_times, [
		0.22, 0.25, 0.22
	])
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", fall_times, [
		0.48, 0.52, 0.48
	])
	# Tail lifted by airflow
	add_track_keys.call(a_fall, "Visuals/Skeleton/root/tail:rotation", fall_times, [
		0.18, 0.22, 0.18
	])

	anim_lib.add_animation("fall", a_fall)
	anim_lib.add_animation("LEON_FALL", a_fall.duplicate())

	# 10. JUMP LAND (0.20s, Contact -> Impact Squash -> Rebound -> Recovery, Non-Looping)
	var a_jump_land = Animation.new()
	a_jump_land.length = 0.20
	var land_times = [0.0, 0.06, 0.14, 0.20]

	# Root: Contact (-38) -> Deep 7px Impact Squash (-31) -> Rebound (-39) -> Settle (-38)
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root:position", land_times, [
		Vector2(0, -38.0), Vector2(0, -31.0), Vector2(0, -39.0), Vector2(0, -38.0)
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root:rotation", land_times, [
		0.02, -0.04, 0.01, 0.0
	])
	# Torso: Absorbs impact with heavy forward compression
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/torso:rotation", land_times, [
		0.14, 0.22, 0.06, 0.03
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/torso/neck/head:rotation", land_times, [
		0.12, -0.08, 0.02, -0.02
	])
	# Knees flex deeply on impact squash
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/leg_R_upper:rotation", land_times, [
		0.0, 0.28, 0.08, 0.0
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", land_times, [
		0.0, 0.65, 0.10, 0.0
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", land_times, [
		0.0, 0.0, 0.0, 0.0
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/leg_L_upper:rotation", land_times, [
		0.0, 0.25, 0.06, 0.0
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", land_times, [
		0.0, 0.65, 0.10, 0.0
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", land_times, [
		0.0, 0.0, 0.0, 0.0
	])
	# Arms drop down/forward to brace impact, then recover
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", land_times, [
		-0.28, 0.15, 0.08, 0.05
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", land_times, [
		0.50, 0.50, 0.25, 0.20
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", land_times, [
		0.22, 0.12, 0.05, 0.0
	])
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", land_times, [
		0.48, 0.45, 0.22, 0.18
	])
	# Tail dips on impact, settles
	add_track_keys.call(a_jump_land, "Visuals/Skeleton/root/tail:rotation", land_times, [
		0.18, -0.10, 0.04, 0.0
	])

	anim_lib.add_animation("jump_land", a_jump_land)
	anim_lib.add_animation("LEON_LAND", a_jump_land.duplicate())

	# 7. BASIC ATTACK Animation (0.36s, Non-looping, Shuriken Throw Snap)
	# ANTICIPATION (0.00s) -> WINDUP (0.08s) -> RELEASE (0.14s) -> FOLLOW-THROUGH (0.22s) -> RECOVERY (0.36s)
	var a_attack = Animation.new()
	a_attack.length = 0.36
	a_attack.loop_mode = Animation.LOOP_NONE
	var atk_times = [0.0, 0.08, 0.14, 0.22, 0.36]

	# Root: Coils slightly back on windup, lunges forward on throw snap, settles
	add_track_keys.call(a_attack, "Visuals/Skeleton/root:position", atk_times, [
		Vector2(0, -38.0), Vector2(-2, -34.0), Vector2(4, -36.0), Vector2(5, -37.0), Vector2(0, -38.0)
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root:rotation", atk_times, [
		0.0, -0.06, 0.05, 0.02, 0.0
	])

	# Torso: Loaded back (-0.22 rad) -> explosive forward snap (+0.32 rad) -> overshoot (+0.36 rad) -> settle
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso:rotation", atk_times, [
		0.0, -0.22, 0.32, 0.36, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/neck/head:rotation", atk_times, [
		0.0, -0.04, 0.03, 0.04, 0.0
	])

	# Throwing Arm (Near/Right Arm - Layer Z = 3):
	# Windup: Cocked high behind body (+0.70 rad) with bent elbow (+0.75 rad)
	# Release Snap: Whips aggressively forward horizontally (-1.45 rad) with extended arm (-0.10 rad) and wrist flick (-0.25 rad)
	# Follow-through: Sweeps forward/down (-1.20 rad) with downward wrist flick (+0.25 rad)
	# Recovery: Returns smoothly to neutral
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_R_upper:rotation", atk_times, [
		0.0, 0.70, -1.45, -1.20, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation", atk_times, [
		0.0, 0.75, -0.10, 0.15, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation", atk_times, [
		0.0, 0.35, -0.25, 0.25, 0.0
	])

	# Off-hand Arm (Far/Left Arm):
	# Opposing action: Reaches forward for balance during windup (-0.65 rad), pulls back sharply on release (+0.55 rad)
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_L_upper:rotation", atk_times, [
		0.0, -0.65, 0.55, 0.45, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation", atk_times, [
		0.0, 0.30, 0.60, 0.40, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation", atk_times, [
		0.0, 0.0, 0.0, 0.0, 0.0
	])

	# Legs: Dynamic braced stance
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/leg_R_upper:rotation", atk_times, [
		0.0, 0.18, 0.32, 0.28, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation", atk_times, [
		0.0, 0.25, 0.10, 0.05, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", atk_times, [
		0.0, -0.05, 0.0, 0.0, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/leg_L_upper:rotation", atk_times, [
		0.0, -0.15, -0.28, -0.22, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation", atk_times, [
		0.0, 0.35, 0.45, 0.30, 0.0
	])
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", atk_times, [
		0.0, 0.15, 0.25, 0.10, 0.0
	])

	# Tail: Counter-balance whip
	add_track_keys.call(a_attack, "Visuals/Skeleton/root/tail:rotation", atk_times, [
		0.0, -0.20, 0.35, 0.15, 0.0
	])

	# Method Call Track: Deterministic Animation Events
	add_method_track.call(a_attack, [0.0, 0.14, 0.14, 0.22, 0.36], [
		"_on_anim_attack_start",
		"_on_anim_attack_release",
		"_on_anim_projectile_spawn",
		"_on_anim_attack_follow_through",
		"_on_anim_attack_end"
	])

	anim_lib.add_animation("attack", a_attack)
	anim_lib.add_animation("LEON_BASIC_ATTACK", a_attack.duplicate())
	anim_lib.add_animation("LEON_ATTACK", a_attack.duplicate())

	anim_player.add_animation_library("", anim_lib)

	# Save to scenes/leon_side.tscn
	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack leon_side scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/leon_side.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/leon_side.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/leon_side.tscn!")
	quit(0)
