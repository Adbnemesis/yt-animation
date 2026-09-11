@tool
extends SceneTree

# Build Brawler Bo Scene — Authentic Side-View (Profile) Rig
# Programmatically constructs scenes/brawler_bo.tscn matching the reusable Brawler framework
# using modular side-view SVGs from assets/brawlers/bo/side/ matching bo_view_side.svg.
# Run: /Users/talus/Downloads/Godot.app/Contents/MacOS/Godot --headless --script scripts/build_brawler_bo.gd

func _init() -> void:
	print("=== Building Brawler Bo Scene (Side-View Profile Rig) ===")

	var root = CharacterBody2D.new()
	root.name = "BrawlerBo"
	root.set_script(load("res://templates/brawler/brawler_base.gd"))

	# Assign config
	var config = load("res://templates/brawler/brawler_config_bo.tres")
	root.set("config", config)

	# 1. CollisionShape2D (Broad muscular adult archer build)
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.position = Vector2(0, -52)
	var shape = CapsuleShape2D.new()
	shape.radius = 24.0
	shape.height = 108.0
	col.shape = shape
	root.add_child(col)
	col.owner = root

	# 2. Visuals Root
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	visuals.owner = root

	# 3. SkeletonSlot
	var skeleton_slot = Node2D.new()
	skeleton_slot.name = "SkeletonSlot"
	visuals.add_child(skeleton_slot)
	skeleton_slot.owner = root

	# 4. Skeleton2D
	var skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton"
	skeleton_slot.add_child(skeleton)
	skeleton.owner = root

	# Texture Preloads — Authentic Side-View Assets from bo_view_side.svg
	var tex_torso = load("res://assets/brawlers/bo/side/torso.svg")
	var tex_hood = load("res://assets/brawlers/bo/side/hood.svg")
	var tex_beak = load("res://assets/brawlers/bo/side/beak.svg")
	var tex_hair = load("res://assets/brawlers/bo/side/hair.svg")
	var tex_face_base = load("res://assets/brawlers/bo/side/face_base.svg")

	var tex_arm_l_up = load("res://assets/brawlers/bo/side/arm_L_upper.svg")
	var tex_arm_l_low = load("res://assets/brawlers/bo/side/arm_L_lower.svg")
	var tex_hand_l = load("res://assets/brawlers/bo/side/hand_L.svg")

	var tex_arm_r_up = load("res://assets/brawlers/bo/side/arm_R_upper.svg")
	var tex_arm_r_low = load("res://assets/brawlers/bo/side/arm_R_lower.svg")
	var tex_hand_r = load("res://assets/brawlers/bo/side/hand_R.svg")

	var tex_leg_l_up = load("res://assets/brawlers/bo/side/leg_L_upper.svg")
	var tex_leg_l_low = load("res://assets/brawlers/bo/side/leg_L_lower.svg")
	var tex_foot_l = load("res://assets/brawlers/bo/side/foot_L.svg")

	var tex_leg_r_up = load("res://assets/brawlers/bo/side/leg_R_upper.svg")
	var tex_leg_r_low = load("res://assets/brawlers/bo/side/leg_R_lower.svg")
	var tex_foot_r = load("res://assets/brawlers/bo/side/foot_R.svg")

	var tex_bow = load("res://assets/brawlers/bo/side/bow.svg")
	var tex_arrow = load("res://assets/brawlers/bo/side/arrow.svg")
	var tex_quiver = load("res://assets/brawlers/bo/side/quiver.svg")

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

	# ==========================================
	# SKELETON HIERARCHY (Side-View Conventions)
	# ==========================================

	# root: Pelvis at Vector2(0, -42)
	var b_root = create_bone.call("root", Vector2(0, -42), skeleton)

	# Far Leg (Left Leg, Back Layer, Z = -1)
	var b_leg_l_upper = create_bone.call("leg_L_upper", Vector2(-4, 10), b_root)
	create_sprite.call("LegSpriteL", tex_leg_l_up, Vector2(2, 10), -1, b_leg_l_upper)

	var b_leg_l_lower = create_bone.call("leg_L_lower", Vector2(0, 16), b_leg_l_upper)
	create_sprite.call("LegLowerSpriteL", tex_leg_l_low, Vector2(0, 10), -1, b_leg_l_lower)

	var b_foot_l = create_bone.call("foot_L", Vector2(0, 16), b_leg_l_lower, true)
	create_sprite.call("FootSpriteL", tex_foot_l, Vector2(6, 4), -1, b_foot_l)

	# Near Leg (Right Leg, Front Layer, Z = 1)
	var b_leg_r_upper = create_bone.call("leg_R_upper", Vector2(6, 10), b_root)
	create_sprite.call("LegSpriteR", tex_leg_r_up, Vector2(4, 10), 1, b_leg_r_upper)

	var b_leg_r_lower = create_bone.call("leg_R_lower", Vector2(0, 16), b_leg_r_upper)
	create_sprite.call("LegLowerSpriteR", tex_leg_r_low, Vector2(0, 10), 1, b_leg_r_lower)

	var b_foot_r = create_bone.call("foot_R", Vector2(0, 16), b_leg_r_lower, true)
	create_sprite.call("FootSpriteR", tex_foot_r, Vector2(6, 4), 1, b_foot_r)

	# Torso (Base Layer, Z = 0)
	var b_torso = create_bone.call("torso", Vector2(0, -8), b_root)
	# Quiver mounted behind torso (Z = -2)
	create_sprite.call("QuiverSprite", tex_quiver, Vector2(-16, -26), -2, b_torso)
	# Broad muscular chest with open emerald vest & sash (Z = 0)
	create_sprite.call("TorsoSprite", tex_torso, Vector2(10, -16), 0, b_torso)

	# Far Arm (Left Arm, Back Layer, Z = -1, Reaches forward holding bow)
	var b_arm_l_upper = create_bone.call("arm_L_upper", Vector2(10, -18), b_torso)
	create_sprite.call("ArmSpriteL", tex_arm_l_up, Vector2(10, 2), -1, b_arm_l_upper)

	var b_arm_l_lower = create_bone.call("arm_L_lower", Vector2(18, 4), b_arm_l_upper)
	create_sprite.call("ArmLowerSpriteL", tex_arm_l_low, Vector2(8, 4), -1, b_arm_l_lower)

	var b_hand_l = create_bone.call("hand_L", Vector2(18, 4), b_arm_l_lower, true)
	create_sprite.call("HandSpriteL", tex_hand_l, Vector2(0, 0), -1, b_hand_l)

	# Recurve Bow mounted on left hand (Z = 4 so it renders in front of body)
	var bow_sprite = create_sprite.call("BowSprite", tex_bow, Vector2(10, -2), 4, b_hand_l)
	bow_sprite.z_as_relative = false
	bow_sprite.z_index = 4

	# Projectile Spawn Point on Left Hand (Bow center)
	var spawn_pt = Marker2D.new()
	spawn_pt.name = "ProjectileSpawnPoint"
	spawn_pt.position = Vector2(14, 0)
	b_hand_l.add_child(spawn_pt)
	spawn_pt.owner = root

	# Near Arm (Right Arm, Front Layer, Z = 3, Deltoid + Talon Bracer + Drawing Fist)
	var b_arm_r_upper = create_bone.call("arm_R_upper", Vector2(4, -16), b_torso)
	create_sprite.call("ArmSpriteR", tex_arm_r_up, Vector2(4, 10), 3, b_arm_r_upper)

	var b_arm_r_lower = create_bone.call("arm_R_lower", Vector2(0, 16), b_arm_r_upper)
	create_sprite.call("ArmLowerSpriteR", tex_arm_r_low, Vector2(4, 8), 3, b_arm_r_lower)

	var b_hand_r = create_bone.call("hand_R", Vector2(0, 14), b_arm_r_lower, true)
	create_sprite.call("HandSpriteR", tex_hand_r, Vector2(0, 4), 3, b_hand_r)

	var arrow_sprite = create_sprite.call("ArrowSprite", tex_arrow, Vector2(14, 0), 5, b_hand_r)
	arrow_sprite.z_as_relative = false
	arrow_sprite.z_index = 5
	arrow_sprite.visible = false

	var atk_pt = Marker2D.new()
	atk_pt.name = "AttackSpawnPoint"
	atk_pt.position = Vector2(10, 0)
	b_hand_r.add_child(atk_pt)
	atk_pt.owner = root

	# Neck & Head (Layer Z = 2)
	var b_neck = create_bone.call("neck", Vector2(4, -30), b_torso)
	var b_head = create_bone.call("head", Vector2(4, -12), b_neck, true)

	var head_offset = Vector2(0, -36)
	create_sprite.call("HairSprite", tex_hair, head_offset, 1, b_head)
	create_sprite.call("HoodSprite", tex_hood, head_offset, 2, b_head)
	create_sprite.call("FaceBaseSprite", tex_face_base, head_offset, 2, b_head)
	create_sprite.call("BeakSprite", tex_beak, head_offset, 3, b_head)

	# 5. Face Controller under SkeletonSlot (Synchronizes with b_head via FaceControllerBoBrawler)
	var face_node = Node2D.new()
	face_node.name = "Face"
	face_node.position = Vector2(0, -94)
	face_node.z_index = 4
	face_node.set_script(load("res://templates/brawler/face_controller_bo_brawler.gd"))
	skeleton_slot.add_child(face_node)
	face_node.owner = root

	# Single Profile Eye (matches unified head origin and offset)
	var eye_l = Sprite2D.new()
	eye_l.name = "EyeL"
	eye_l.texture = load("res://assets/brawlers/bo/side/face/eye_open.svg")
	eye_l.position = Vector2.ZERO
	eye_l.offset = head_offset
	face_node.add_child(eye_l)
	eye_l.owner = root

	var brow_l = Sprite2D.new()
	brow_l.name = "BrowL"
	brow_l.texture = load("res://assets/brawlers/bo/side/face/brow.svg")
	brow_l.position = Vector2.ZERO
	brow_l.offset = head_offset
	face_node.add_child(brow_l)
	brow_l.owner = root

	var mouth_sprite = Sprite2D.new()
	mouth_sprite.name = "Mouth"
	mouth_sprite.texture = load("res://assets/brawlers/bo/side/face/mouth_stoic.svg")
	mouth_sprite.position = Vector2.ZERO
	mouth_sprite.offset = head_offset
	face_node.add_child(mouth_sprite)
	mouth_sprite.owner = root

	# Far Eye & Far Brow (Present for framework interface compatibility, but kept strictly HIDDEN)
	var eye_r = Sprite2D.new()
	eye_r.name = "EyeR"
	eye_r.visible = false
	face_node.add_child(eye_r)
	eye_r.owner = root

	var brow_r = Sprite2D.new()
	brow_r.name = "BrowR"
	brow_r.visible = false
	face_node.add_child(brow_r)
	brow_r.owner = root

	# 6. VFX Attachment Points
	var vfx_pts = Node2D.new()
	vfx_pts.name = "VFXAttachmentPoints"
	root.add_child(vfx_pts)
	vfx_pts.owner = root

	var hit_pt = Marker2D.new()
	hit_pt.name = "HitPoint"
	hit_pt.position = Vector2(0, -52)
	vfx_pts.add_child(hit_pt)
	hit_pt.owner = root

	var head_pt = Marker2D.new()
	head_pt.name = "HeadPoint"
	head_pt.position = Vector2(0, -118)
	vfx_pts.add_child(head_pt)
	head_pt.owner = root

	var proj_pt = Marker2D.new()
	proj_pt.name = "ProjectileSpawn"
	proj_pt.position = Vector2(28, -50)
	vfx_pts.add_child(proj_pt)
	proj_pt.owner = root

	# 7. AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimPlayer"
	root.add_child(anim_player)
	anim_player.owner = root

	var anim_lib = AnimationLibrary.new()

	# Helper for adding value tracks
	var add_track_keys = func(anim: Animation, path: String, times: Array, values: Array, interp: int = Animation.INTERPOLATION_CUBIC) -> void:
		var idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(idx, path)
		anim.track_set_interpolation_type(idx, interp)
		if interp == Animation.INTERPOLATION_NEAREST:
			anim.value_track_set_update_mode(idx, Animation.UPDATE_DISCRETE)
		for i in range(times.size()):
			anim.track_insert_key(idx, times[i], values[i])

	# RESET Animation (Rest Pose)
	var a_reset = Animation.new()
	a_reset.length = 0.001
	var reset_tracks = {
		"Visuals/SkeletonSlot/Skeleton/root:position": Vector2(0, -42),
		"Visuals/SkeletonSlot/Skeleton/root:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/neck:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/neck/head:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/leg_L_upper/leg_L_lower:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/leg_R_upper/leg_R_lower:rotation": 0.0,
		"Visuals/SkeletonSlot/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation": 0.0,
		"Visuals/SkeletonSlot/Face:position": Vector2(0, -94),
		"Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R/ArrowSprite:visible": false
	}
	for track_path in reset_tracks.keys():
		var idx = a_reset.add_track(Animation.TYPE_VALUE)
		a_reset.track_set_path(idx, track_path)
		a_reset.track_insert_key(idx, 0.0, reset_tracks[track_path])
	anim_lib.add_animation("RESET", a_reset)

	# 1. IDLE Animation (2.0s, Stoic warrior, firm grounding, subtle breathing)
	var a_idle = Animation.new()
	a_idle.length = 2.0
	a_idle.loop_mode = Animation.LOOP_LINEAR

	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 1.0, 2.0],
		[Vector2(0, -42.0), Vector2(0, -43.2), Vector2(0, -42.0)])
	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.5, 1.0, 1.5, 2.0],
		[0.0, 0.012, 0.0, -0.012, 0.0])
	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root/torso/neck:rotation",
		[0.0, 0.6, 1.2, 1.7, 2.0],
		[0.0, -0.008, 0.004, -0.004, 0.0])
	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root/torso/neck/head:rotation",
		[0.0, 0.7, 1.3, 2.0],
		[0.0, -0.01, 0.01, 0.0])
	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation",
		[0.0, 1.0, 2.0],
		[-0.04, 0.01, -0.04])
	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation",
		[0.0, 1.0, 2.0],
		[0.12, 0.16, 0.12])
	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation",
		[0.0, 1.0, 2.0],
		[0.04, -0.01, 0.04])
	add_track_keys.call(a_idle, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation",
		[0.0, 1.0, 2.0],
		[0.14, 0.18, 0.14])
	anim_lib.add_animation("idle", a_idle)

	# 2. WALK Animation (0.80s, Grounded, confident warrior stride)
	var a_walk = Animation.new()
	a_walk.length = 0.80
	a_walk.loop_mode = Animation.LOOP_LINEAR
	var walk_times = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80]

	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root:position", walk_times, [
		Vector2(0, -42.0), Vector2(0, -40.2), Vector2(0, -42.5), Vector2(0, -44.0),
		Vector2(0, -42.0), Vector2(0, -40.2), Vector2(0, -42.5), Vector2(0, -44.0), Vector2(0, -42.0)
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root:rotation", walk_times, [
		-0.02, -0.03, -0.01, 0.01, 0.02, 0.03, 0.01, -0.01, -0.02
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation", walk_times, [
		0.04, 0.06, 0.02, 0.03, 0.04, 0.06, 0.02, 0.03, 0.04
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation", walk_times, [
		0.42, 0.22, -0.05, -0.38, -0.30, -0.15, 0.20, 0.45, 0.42
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper/leg_L_lower:rotation", walk_times, [
		0.04, 0.25, 0.08, 0.10, 0.22, 0.50, 0.60, 0.14, 0.04
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation", walk_times, [
		-0.30, 0.00, 0.00, 0.28, 0.24, -0.08, -0.12, -0.28, -0.30
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation", walk_times, [
		-0.30, -0.15, 0.20, 0.45, 0.42, 0.22, -0.05, -0.38, -0.30
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper/leg_R_lower:rotation", walk_times, [
		0.22, 0.50, 0.60, 0.14, 0.04, 0.25, 0.08, 0.10, 0.22
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation", walk_times, [
		0.24, -0.08, -0.12, -0.28, -0.30, 0.00, 0.00, 0.28, 0.24
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation", walk_times, [
		-0.28, -0.18, -0.04, 0.16, 0.30, 0.20, 0.04, -0.16, -0.28
	])
	add_track_keys.call(a_walk, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation", walk_times, [
		0.30, 0.20, 0.04, -0.16, -0.28, -0.18, -0.04, 0.16, 0.30
	])
	anim_lib.add_animation("walk", a_walk)

	# 3. RUN Animation (0.55s, Athletic sprint with bow carried forward)
	var a_run = Animation.new()
	a_run.length = 0.55
	a_run.loop_mode = Animation.LOOP_LINEAR
	var run_times = [0.0, 0.07, 0.14, 0.21, 0.28, 0.35, 0.42, 0.49, 0.55]

	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root:position", run_times, [
		Vector2(0, -42.0), Vector2(0, -38.0), Vector2(0, -43.0), Vector2(0, -46.0),
		Vector2(0, -42.0), Vector2(0, -38.0), Vector2(0, -43.0), Vector2(0, -46.0), Vector2(0, -42.0)
	])
	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation", run_times, [
		0.14, 0.16, 0.12, 0.13, 0.14, 0.16, 0.12, 0.13, 0.14
	])
	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation", run_times, [
		0.52, 0.26, -0.10, -0.55, -0.45, -0.20, 0.30, 0.58, 0.52
	])
	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper/leg_L_lower:rotation", run_times, [
		0.05, 0.35, 0.10, 0.12, 0.30, 0.70, 0.85, 0.18, 0.05
	])
	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation", run_times, [
		-0.45, -0.20, 0.30, 0.58, 0.52, 0.26, -0.10, -0.55, -0.45
	])
	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper/leg_R_lower:rotation", run_times, [
		0.30, 0.70, 0.85, 0.18, 0.05, 0.35, 0.10, 0.12, 0.30
	])
	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation", run_times, [
		-0.40, -0.25, -0.05, 0.25, 0.42, 0.28, 0.05, -0.25, -0.40
	])
	add_track_keys.call(a_run, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation", run_times, [
		0.42, 0.28, 0.05, -0.25, -0.40, -0.25, -0.05, 0.25, 0.42
	])
	anim_lib.add_animation("run", a_run)

	# 4. STOP Animation (0.25s, firm foot plant braking)
	var a_stop = Animation.new()
	a_stop.length = 0.25
	add_track_keys.call(a_stop, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.12, 0.25],
		[Vector2(0, -40.0), Vector2(0, -38.0), Vector2(0, -42.0)])
	add_track_keys.call(a_stop, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.12, 0.25],
		[0.10, -0.06, 0.0])
	add_track_keys.call(a_stop, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation",
		[0.0, 0.12, 0.25],
		[0.25, 0.10, 0.0])
	add_track_keys.call(a_stop, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation",
		[0.0, 0.12, 0.25],
		[-0.20, -0.05, 0.0])
	anim_lib.add_animation("stop", a_stop)

	# 5. TURN Animation (0.20s, swift pivot)
	var a_turn = Animation.new()
	a_turn.length = 0.20
	add_track_keys.call(a_turn, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.10, 0.20],
		[Vector2(0, -42.0), Vector2(0, -40.0), Vector2(0, -42.0)])
	add_track_keys.call(a_turn, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.10, 0.20],
		[0.0, 0.08, 0.0])
	add_track_keys.call(a_turn, "Visuals/SkeletonSlot/Skeleton/root/torso/neck/head:rotation",
		[0.0, 0.10, 0.20],
		[0.0, 0.12, 0.0])
	anim_lib.add_animation("turn", a_turn)

	# 6. JUMP Animation (0.60s, agile vertical leap)
	var a_jump = Animation.new()
	a_jump.length = 0.60
	add_track_keys.call(a_jump, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.10, 0.30, 0.50, 0.60],
		[Vector2(0, -42.0), Vector2(0, -36.0), Vector2(0, -48.0), Vector2(0, -40.0), Vector2(0, -42.0)])
	add_track_keys.call(a_jump, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation",
		[0.0, 0.25, 0.60],
		[0.0, -0.35, 0.0])
	add_track_keys.call(a_jump, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation",
		[0.0, 0.25, 0.60],
		[0.0, 0.35, 0.0])
	add_track_keys.call(a_jump, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation",
		[0.0, 0.25, 0.60],
		[0.0, 0.30, 0.0])
	add_track_keys.call(a_jump, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation",
		[0.0, 0.25, 0.60],
		[0.0, -0.20, 0.0])
	anim_lib.add_animation("jump", a_jump)

	# 7. JUMP_ANTICIPATION (0.12s, crouch down)
	var a_jump_antic = Animation.new()
	a_jump_antic.length = 0.12
	add_track_keys.call(a_jump_antic, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.12],
		[Vector2(0, -42.0), Vector2(0, -34.0)])
	add_track_keys.call(a_jump_antic, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.12],
		[0.0, 0.12])
	add_track_keys.call(a_jump_antic, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation",
		[0.0, 0.12],
		[0.0, 0.25])
	add_track_keys.call(a_jump_antic, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation",
		[0.0, 0.12],
		[0.0, 0.25])
	anim_lib.add_animation("jump_anticipation", a_jump_antic)

	# 8. JUMP_AIRBORNE (0.35s loop, legs tucked, bow ready)
	var a_airborne = Animation.new()
	a_airborne.length = 0.35
	a_airborne.loop_mode = Animation.LOOP_LINEAR
	add_track_keys.call(a_airborne, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.18, 0.35],
		[Vector2(0, -46.0), Vector2(0, -48.0), Vector2(0, -46.0)])
	add_track_keys.call(a_airborne, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation",
		[0.0, 0.35],
		[-0.30, -0.30])
	add_track_keys.call(a_airborne, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation",
		[0.0, 0.35],
		[0.28, 0.28])
	add_track_keys.call(a_airborne, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation",
		[0.0, 0.35],
		[-0.22, -0.22])
	anim_lib.add_animation("jump_airborne", a_airborne)

	# 9. FALL (0.30s, descending stance)
	var a_fall = Animation.new()
	a_fall.length = 0.30
	add_track_keys.call(a_fall, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.30],
		[Vector2(0, -44.0), Vector2(0, -42.0)])
	add_track_keys.call(a_fall, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation",
		[0.0, 0.30],
		[0.15, 0.05])
	add_track_keys.call(a_fall, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation",
		[0.0, 0.30],
		[-0.10, 0.05])
	anim_lib.add_animation("fall", a_fall)

	# 10. JUMP_LAND (0.20s, deep knee impact absorption)
	var a_land = Animation.new()
	a_land.length = 0.20
	add_track_keys.call(a_land, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.08, 0.20],
		[Vector2(0, -42.0), Vector2(0, -34.0), Vector2(0, -42.0)])
	add_track_keys.call(a_land, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.08, 0.20],
		[0.0, 0.10, 0.0])
	add_track_keys.call(a_land, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation",
		[0.0, 0.08, 0.20],
		[0.0, 0.24, 0.0])
	add_track_keys.call(a_land, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation",
		[0.0, 0.08, 0.20],
		[0.0, 0.24, 0.0])
	anim_lib.add_animation("jump_land", a_land)

	# 11. ATTACK Animation (0.45s, Bo draws and releases bow!)
	var a_atk = Animation.new()
	a_atk.length = 0.45

	# Torso rotation: turns into draw stance, releases
	add_track_keys.call(a_atk, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.15, 0.22, 0.35, 0.45],
		[0.0, -0.15, 0.18, 0.08, 0.0])
	# Left arm (bow arm): raises forward to aim, recoils back on release
	add_track_keys.call(a_atk, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation",
		[0.0, 0.15, 0.22, 0.35, 0.45],
		[0.0, -0.45, -0.20, -0.10, 0.0])
	add_track_keys.call(a_atk, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation",
		[0.0, 0.15, 0.22, 0.45],
		[0.12, 0.05, 0.18, 0.12])
	# Right arm (string hand): reaches back to draw, then snaps forward on release
	add_track_keys.call(a_atk, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation",
		[0.0, 0.15, 0.22, 0.35, 0.45],
		[0.0, 0.55, -0.25, -0.10, 0.0])
	add_track_keys.call(a_atk, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation",
		[0.0, 0.15, 0.22, 0.45],
		[0.14, 0.65, 0.10, 0.14])
	# Arrow visibility during draw (visible from 0.02s to 0.22s release)
	add_track_keys.call(a_atk, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R/ArrowSprite:visible",
		[0.0, 0.02, 0.22],
		[false, true, false],
		Animation.INTERPOLATION_NEAREST)
	anim_lib.add_animation("attack", a_atk)

	# 12. HIT Animation (0.35s, recoil flinch)
	var a_hit = Animation.new()
	a_hit.length = 0.35
	add_track_keys.call(a_hit, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.10, 0.35],
		[Vector2(0, -42.0), Vector2(-8, -40.0), Vector2(0, -42.0)])
	add_track_keys.call(a_hit, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.10, 0.35],
		[0.0, -0.22, 0.0])
	add_track_keys.call(a_hit, "Visuals/SkeletonSlot/Skeleton/root/torso/neck/head:rotation",
		[0.0, 0.10, 0.35],
		[0.0, -0.15, 0.0])
	anim_lib.add_animation("hit", a_hit)
	anim_lib.add_animation("hurt", a_hit.duplicate())

	# 13. KNOCKBACK Animation (0.45s, large backward impact)
	var a_knock = Animation.new()
	a_knock.length = 0.45
	add_track_keys.call(a_knock, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.12, 0.30, 0.45],
		[Vector2(0, -42.0), Vector2(-16, -38.0), Vector2(-8, -40.0), Vector2(0, -42.0)])
	add_track_keys.call(a_knock, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.12, 0.45],
		[0.0, -0.35, 0.0])
	anim_lib.add_animation("knockback", a_knock)

	# 14. DEATH Animation (0.70s, warrior drops to one knee)
	var a_death = Animation.new()
	a_death.length = 0.70
	add_track_keys.call(a_death, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.25, 0.50, 0.70],
		[Vector2(0, -42.0), Vector2(-4, -36.0), Vector2(-8, -24.0), Vector2(-8, -24.0)])
	add_track_keys.call(a_death, "Visuals/SkeletonSlot/Skeleton/root/torso:rotation",
		[0.0, 0.35, 0.70],
		[0.0, 0.25, 0.35])
	add_track_keys.call(a_death, "Visuals/SkeletonSlot/Skeleton/root/torso/neck/head:rotation",
		[0.0, 0.40, 0.70],
		[0.0, 0.30, 0.42])
	add_track_keys.call(a_death, "Visuals/SkeletonSlot/Skeleton/root/leg_L_upper:rotation",
		[0.0, 0.50, 0.70],
		[0.0, 0.65, 0.75])
	add_track_keys.call(a_death, "Visuals/SkeletonSlot/Skeleton/root/leg_R_upper:rotation",
		[0.0, 0.50, 0.70],
		[0.0, 0.55, 0.65])
	anim_lib.add_animation("death", a_death)

	# 15. CELEBRATE Animation (1.0s, raises bow proudly)
	var a_celeb = Animation.new()
	a_celeb.length = 1.0
	a_celeb.loop_mode = Animation.LOOP_LINEAR
	add_track_keys.call(a_celeb, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.5, 1.0],
		[Vector2(0, -42.0), Vector2(0, -44.0), Vector2(0, -42.0)])
	add_track_keys.call(a_celeb, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation",
		[0.0, 0.5, 1.0],
		[-0.85, -0.95, -0.85])
	add_track_keys.call(a_celeb, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation",
		[0.0, 0.5, 1.0],
		[0.35, 0.40, 0.35])
	anim_lib.add_animation("celebrate", a_celeb)

	# 16. EMOTE Animation (0.8s, nodding / warrior salute)
	var a_emote = Animation.new()
	a_emote.length = 0.8
	add_track_keys.call(a_emote, "Visuals/SkeletonSlot/Skeleton/root/torso/neck/head:rotation",
		[0.0, 0.4, 0.8],
		[0.0, 0.18, 0.0])
	anim_lib.add_animation("emote", a_emote)

	# 17. SUPER Animation (0.6s, leaps slightly, broad arm sweep)
	var a_super = Animation.new()
	a_super.length = 0.60
	add_track_keys.call(a_super, "Visuals/SkeletonSlot/Skeleton/root:position",
		[0.0, 0.25, 0.60],
		[Vector2(0, -42.0), Vector2(0, -52.0), Vector2(0, -42.0)])
	add_track_keys.call(a_super, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_R_upper:rotation",
		[0.0, 0.30, 0.60],
		[0.0, -0.80, 0.0])
	add_track_keys.call(a_super, "Visuals/SkeletonSlot/Skeleton/root/torso/arm_L_upper:rotation",
		[0.0, 0.30, 0.60],
		[0.0, 0.60, 0.0])
	anim_lib.add_animation("super", a_super)

	anim_player.add_animation_library("", anim_lib)

	# 8. Standard Components for Brawler Framework
	var mc = Node.new()
	mc.name = "MovementController"
	mc.set_script(load("res://templates/brawler/movement_controller.gd"))
	root.add_child(mc)
	mc.owner = root

	var ac = Node.new()
	ac.name = "AnimationController"
	ac.set_script(load("res://templates/brawler/animation_controller.gd"))
	root.add_child(ac)
	ac.owner = root

	var abc = Node.new()
	abc.name = "AbilityController"
	abc.set_script(load("res://templates/brawler/ability_controller.gd"))
	root.add_child(abc)
	abc.owner = root

	var hr = Area2D.new()
	hr.name = "HitReceiver"
	hr.set_script(load("res://templates/brawler/hit_receiver.gd"))
	root.add_child(hr)
	hr.owner = root

	# Save packed scene
	var packed = PackedScene.new()
	var result = packed.pack(root)
	if result == OK:
		var save_err = ResourceSaver.save(packed, "res://scenes/brawler_bo.tscn")
		if save_err == OK:
			print("[SUCCESS] Successfully created and saved scenes/brawler_bo.tscn!")
		else:
			push_error("Failed to save scenes/brawler_bo.tscn: " + str(save_err))
	else:
		push_error("Failed to pack scene: " + str(result))

	quit()
