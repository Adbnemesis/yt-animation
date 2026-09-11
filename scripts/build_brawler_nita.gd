extends SceneTree

# Build Brawler Nita Scene
# Generates scenes/brawler_nita.tscn by assembling the Brawler template
# with Nita's skeleton rig, face controller, and animations.
# Run: godot --headless --script scripts/build_brawler_nita.gd

func _init() -> void:
	print("=== Building Brawler Nita Scene ===")

	# Load nita source for skeleton & animations reference
	var nita_scene = load("res://scenes/nita.tscn") as PackedScene
	if not nita_scene:
		push_error("Cannot load nita.tscn")
		quit()
		return

	var nita_inst = nita_scene.instantiate()
	print("  Loaded source nita.tscn")

	# Build the brawler scene from scratch matching brawler_base.tscn structure
	var root_node = CharacterBody2D.new()
	root_node.name = "BrawlerNita"
	root_node.set_script(load("res://templates/brawler/brawler_base.gd"))

	# Assign config
	var config = load("res://templates/brawler/brawler_config_nita.tres")
	root_node.set("config", config)

	# CollisionShape2D (Nita is slightly shorter/wider than Leon)
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.position = Vector2(0, -48)
	var shape = CapsuleShape2D.new()
	shape.radius = 22.0
	shape.height = 96.0
	col.shape = shape
	root_node.add_child(col)
	col.owner = root_node

	# Visuals container
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	root_node.add_child(visuals)
	visuals.owner = root_node

	# SkeletonSlot — extract skeleton from source
	var skeleton_slot = Node2D.new()
	skeleton_slot.name = "SkeletonSlot"
	visuals.add_child(skeleton_slot)
	skeleton_slot.owner = root_node

	# Clone the entire skeleton from the source nita
	var src_visuals = nita_inst.get_node("Visuals")
	var src_skeleton = src_visuals.get_node("Skeleton")

	# Deep clone the skeleton
	var skeleton_copy = src_skeleton.duplicate()
	skeleton_slot.add_child(skeleton_copy)
	_set_owner_recursive(skeleton_copy, root_node)
	print("  Cloned skeleton with %d bones" % _count_bones(skeleton_copy))

	# Add Face controller as child of SkeletonSlot
	var face_node = Node2D.new()
	face_node.name = "Face"
	face_node.set_script(load("res://templates/brawler/face_controller_nita_brawler.gd"))
	skeleton_slot.add_child(face_node)
	face_node.owner = root_node

	# Add face child sprite nodes that FaceControllerBase._ensure_nodes() looks for
	_add_face_sprites(face_node, root_node)
	print("  Added face controller with sprite nodes")

	# VFXAttachmentPoints
	var vfx_pts = Node2D.new()
	vfx_pts.name = "VFXAttachmentPoints"
	root_node.add_child(vfx_pts)
	vfx_pts.owner = root_node

	var hit_pt = Marker2D.new()
	hit_pt.name = "HitPoint"
	hit_pt.position = Vector2(0, -48)
	vfx_pts.add_child(hit_pt)
	hit_pt.owner = root_node

	var head_pt = Marker2D.new()
	head_pt.name = "HeadPoint"
	head_pt.position = Vector2(0, -114)
	vfx_pts.add_child(head_pt)
	head_pt.owner = root_node

	var proj_pt = Marker2D.new()
	proj_pt.name = "ProjectileSpawn"
	proj_pt.position = Vector2(20, -50)
	vfx_pts.add_child(proj_pt)
	proj_pt.owner = root_node

	# AnimPlayer — copy animations from source, add run
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimPlayer"
	root_node.add_child(anim_player)
	anim_player.owner = root_node

	# Copy animations from source AnimPlayer
	var src_anim = nita_inst.get_node("AnimPlayer") as AnimationPlayer
	if src_anim:
		var lib = AnimationLibrary.new()
		for anim_name in src_anim.get_animation_list():
			var src_animation = src_anim.get_animation(anim_name)
			var new_anim = _remap_animation(src_animation)
			lib.add_animation(anim_name, new_anim)
			print("  Copied animation: %s (%.2fs)" % [anim_name, new_anim.length])

		# Create "run" animation: compressed walk cycle (0.8s → 0.615s ≈ 1.3× speed)
		var walk_anim = src_anim.get_animation("walk")
		if walk_anim:
			var run_anim = _create_run_animation(walk_anim)
			lib.add_animation("run", run_anim)
			print("  Created 'run' animation (walk @ 1.3×, %.2fs)" % run_anim.length)

		# Create "hit" alias for "hurt" (BrawlerBuilder expects "hit")
		var hurt_anim = src_anim.get_animation("hurt")
		if hurt_anim and not lib.has_animation("hit"):
			var hit_anim = _remap_animation(hurt_anim)
			lib.add_animation("hit", hit_anim)
			print("  Created 'hit' animation (alias of hurt)")

		anim_player.add_animation_library("", lib)
		print("  Total animations: %d" % lib.get_animation_list().size())

	# MovementController
	var move_ctrl = Node.new()
	move_ctrl.name = "MovementController"
	move_ctrl.set_script(load("res://templates/brawler/movement_controller.gd"))
	root_node.add_child(move_ctrl)
	move_ctrl.owner = root_node

	# AnimationController
	var anim_ctrl = Node.new()
	anim_ctrl.name = "AnimationController"
	anim_ctrl.set_script(load("res://templates/brawler/animation_controller.gd"))
	root_node.add_child(anim_ctrl)
	anim_ctrl.owner = root_node

	# AbilityController
	var ability_ctrl = Node.new()
	ability_ctrl.name = "AbilityController"
	ability_ctrl.set_script(load("res://templates/brawler/ability_controller.gd"))
	root_node.add_child(ability_ctrl)
	ability_ctrl.owner = root_node

	# HitReceiver (Area2D)
	var hit_recv = Area2D.new()
	hit_recv.name = "HitReceiver"
	hit_recv.set_script(load("res://templates/brawler/hit_receiver.gd"))
	root_node.add_child(hit_recv)
	hit_recv.owner = root_node

	var hurtbox_shape = CollisionShape2D.new()
	hurtbox_shape.name = "CollisionShape2D"
	hurtbox_shape.position = Vector2(0, -48)
	var hb_capsule = CapsuleShape2D.new()
	hb_capsule.radius = 24.0
	hb_capsule.height = 98.0
	hurtbox_shape.shape = hb_capsule
	hurtbox_shape.debug_color = Color(0.9, 0.2, 0.2, 0.42)
	hit_recv.add_child(hurtbox_shape)
	hurtbox_shape.owner = root_node

	# Save scene
	var packed = PackedScene.new()
	var err = packed.pack(root_node)
	if err != OK:
		push_error("Failed to pack brawler_nita scene: %s" % error_string(err))
		nita_inst.free()
		root_node.free()
		quit()
		return

	err = ResourceSaver.save(packed, "res://scenes/brawler_nita.tscn")
	if err != OK:
		push_error("Failed to save brawler_nita.tscn: %s" % error_string(err))
	else:
		print("  ✓ Saved scenes/brawler_nita.tscn")

	# Cleanup
	nita_inst.free()
	root_node.free()
	print("=== Brawler Nita Build Complete ===")
	quit()


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)


func _count_bones(node: Node) -> int:
	var count = 0
	if node is Bone2D:
		count = 1
	for child in node.get_children():
		count += _count_bones(child)
	return count


func _remap_animation(src_anim: Animation) -> Animation:
	var new_anim = src_anim.duplicate(true)

	# Remap track paths: "Visuals/Skeleton/..." → "Visuals/SkeletonSlot/Skeleton/..."
	for i in range(new_anim.get_track_count()):
		var path = new_anim.track_get_path(i)
		var path_str = str(path)
		if path_str.begins_with("Visuals/Skeleton"):
			var new_path = path_str.replace("Visuals/Skeleton", "Visuals/SkeletonSlot/Skeleton")
			new_anim.track_set_path(i, NodePath(new_path))

	return new_anim


func _create_run_animation(walk_anim: Animation) -> Animation:
	var run_anim = walk_anim.duplicate(true)

	# Compress time: 0.8s walk → ~0.615s run (1.3× speed)
	var speed_factor := 1.3
	var new_length = walk_anim.length / speed_factor
	run_anim.length = new_length

	# Remap paths first
	for track_idx in range(run_anim.get_track_count()):
		var path = run_anim.track_get_path(track_idx)
		var path_str = str(path)
		if path_str.begins_with("Visuals/Skeleton"):
			var new_path = path_str.replace("Visuals/Skeleton", "Visuals/SkeletonSlot/Skeleton")
			run_anim.track_set_path(track_idx, NodePath(new_path))

	# For value tracks, rescale keyframe times
	for track_idx in range(run_anim.get_track_count()):
		if run_anim.track_get_type(track_idx) != Animation.TYPE_VALUE:
			continue

		var key_count = run_anim.track_get_key_count(track_idx)
		if key_count == 0:
			continue

		# Collect all keys
		var keys_data := []
		for key_idx in range(key_count):
			keys_data.append({
				"time": run_anim.track_get_key_time(track_idx, key_idx) / speed_factor,
				"value": run_anim.track_get_key_value(track_idx, key_idx),
				"transition": run_anim.track_get_key_transition(track_idx, key_idx)
			})

		# Remove all keys (reverse order)
		for key_idx in range(key_count - 1, -1, -1):
			run_anim.track_remove_key(track_idx, key_idx)

		# Re-insert with scaled times
		for kd in keys_data:
			run_anim.track_insert_key(track_idx, kd["time"], kd["value"], kd["transition"])

	run_anim.loop_mode = Animation.LOOP_LINEAR

	return run_anim


func _add_face_sprites(face_node: Node2D, new_owner: Node) -> void:
	# Create the sprite nodes that FaceControllerBase._ensure_nodes() looks for
	var eye_l = Sprite2D.new()
	eye_l.name = "EyeL"
	eye_l.texture = load("res://assets/brawlers/nita/face/eye_L.svg")
	eye_l.position = Vector2(-6, -4)
	face_node.add_child(eye_l)
	eye_l.owner = new_owner

	var pupil_l = Sprite2D.new()
	pupil_l.name = "PupilL"
	pupil_l.texture = load("res://assets/brawlers/nita/face/pupil_L.svg")
	eye_l.add_child(pupil_l)
	pupil_l.owner = new_owner

	var eye_r = Sprite2D.new()
	eye_r.name = "EyeR"
	eye_r.texture = load("res://assets/brawlers/nita/face/eye_R.svg")
	eye_r.position = Vector2(6, -4)
	face_node.add_child(eye_r)
	eye_r.owner = new_owner

	var pupil_r = Sprite2D.new()
	pupil_r.name = "PupilR"
	pupil_r.texture = load("res://assets/brawlers/nita/face/pupil_R.svg")
	eye_r.add_child(pupil_r)
	pupil_r.owner = new_owner

	var brow_l = Sprite2D.new()
	brow_l.name = "BrowL"
	brow_l.texture = load("res://assets/brawlers/nita/face/eyebrow_L.svg")
	brow_l.position = Vector2(-6, -10)
	face_node.add_child(brow_l)
	brow_l.owner = new_owner

	var brow_r = Sprite2D.new()
	brow_r.name = "BrowR"
	brow_r.texture = load("res://assets/brawlers/nita/face/eyebrow_R.svg")
	brow_r.position = Vector2(6, -10)
	face_node.add_child(brow_r)
	brow_r.owner = new_owner

	var mouth_sprite = Sprite2D.new()
	mouth_sprite.name = "Mouth"
	mouth_sprite.texture = load("res://assets/brawlers/nita/face/mouth_grin.svg")
	mouth_sprite.position = Vector2(0, 4)
	face_node.add_child(mouth_sprite)
	mouth_sprite.owner = new_owner
