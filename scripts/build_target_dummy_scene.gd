extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Target Dummy Scene (scenes/target_dummy.tscn)...")

	var root = Area2D.new()
	root.name = "TargetDummy"
	root.set_script(load("res://scripts/target_dummy.gd"))

	# Target collision layer (layer 4 = targets, mask 8 = projectiles)
	root.collision_layer = 4
	root.collision_mask = 8
	root.add_to_group("hit_receiver", true)

	# Collision Shape (capsule covering the dummy torso & head)
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.position = Vector2(0, -42)
	var cap = CapsuleShape2D.new()
	cap.radius = 22.0
	cap.height = 74.0
	col.shape = cap
	root.add_child(col)
	col.owner = root

	# Visuals Node
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	visuals.owner = root

	# Ground Shadow
	var shadow = Line2D.new()
	shadow.name = "GroundShadow"
	shadow.points = PackedVector2Array([Vector2(-20, 0), Vector2(20, 0)])
	shadow.width = 6.0
	shadow.default_color = Color(0.05, 0.07, 0.1, 0.5)
	visuals.add_child(shadow)
	shadow.owner = root

	# Wooden Post
	var post = Line2D.new()
	post.name = "Post"
	post.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -35)])
	post.width = 8.0
	post.default_color = Color(0.45, 0.28, 0.18, 1.0)
	visuals.add_child(post)
	post.owner = root

	# Dummy Torso / Sandbag (ColorRect with border or Polygon2D)
	var dummy_body = Polygon2D.new()
	dummy_body.name = "DummyBody"
	dummy_body.polygon = PackedVector2Array([
		Vector2(-18, -25), Vector2(-22, -45), Vector2(-16, -65),
		Vector2(16, -65), Vector2(22, -45), Vector2(18, -25)
	])
	dummy_body.color = Color(0.82, 0.68, 0.52, 1.0) # Canvas burlap color
	visuals.add_child(dummy_body)
	dummy_body.owner = root

	# Bullseye Rings on Dummy
	var ring_outer = Line2D.new()
	ring_outer.name = "BullseyeOuter"
	var pts_outer = PackedVector2Array()
	for i in range(17):
		var ang = i * (PI * 2.0 / 16.0)
		pts_outer.append(Vector2(cos(ang) * 14.0, -45.0 + sin(ang) * 14.0))
	ring_outer.points = pts_outer
	ring_outer.width = 2.5
	ring_outer.default_color = Color(0.9, 0.2, 0.2, 1.0)
	visuals.add_child(ring_outer)
	ring_outer.owner = root

	var bullseye_center = Line2D.new()
	bullseye_center.name = "BullseyeCenter"
	var pts_center = PackedVector2Array()
	for i in range(17):
		var ang = i * (PI * 2.0 / 16.0)
		pts_center.append(Vector2(cos(ang) * 5.0, -45.0 + sin(ang) * 5.0))
	bullseye_center.points = pts_center
	bullseye_center.width = 3.0
	bullseye_center.default_color = Color(0.9, 0.2, 0.2, 1.0)
	visuals.add_child(bullseye_center)
	bullseye_center.owner = root

	# Head Plate
	var head = Polygon2D.new()
	head.name = "Head"
	head.polygon = PackedVector2Array([
		Vector2(-10, -66), Vector2(-12, -78), Vector2(0, -84), Vector2(12, -78), Vector2(10, -66)
	])
	head.color = Color(0.75, 0.62, 0.46, 1.0)
	visuals.add_child(head)
	head.owner = root

	# UI: Floating Health Bar & Label
	var ui = Node2D.new()
	ui.name = "UI"
	ui.position = Vector2(0, -96)
	root.add_child(ui)
	ui.owner = root

	var lbl_name = Label.new()
	lbl_name.name = "LblName"
	lbl_name.text = "TARGET DUMMY"
	lbl_name.position = Vector2(-45, -28)
	lbl_name.add_theme_font_size_override("font_size", 9)
	lbl_name.modulate = Color(0.8, 0.85, 0.95)
	ui.add_child(lbl_name)
	lbl_name.owner = root

	var pbar = ProgressBar.new()
	pbar.name = "ProgressBar"
	pbar.position = Vector2(-36, -14)
	pbar.size = Vector2(72, 8)
	pbar.max_value = 1000.0
	pbar.value = 1000.0
	pbar.show_percentage = false
	ui.add_child(pbar)
	pbar.owner = root

	var lbl_hp = Label.new()
	lbl_hp.name = "LblHP"
	lbl_hp.text = "HP: 1000 / 1000"
	lbl_hp.position = Vector2(-38, -6)
	lbl_hp.add_theme_font_size_override("font_size", 9)
	lbl_hp.modulate = Color(0.4, 0.95, 0.5)
	ui.add_child(lbl_hp)
	lbl_hp.owner = root

	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack target_dummy: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/target_dummy.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/target_dummy.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/target_dummy.tscn!")
	quit(0)
