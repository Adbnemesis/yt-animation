extends SceneTree

# Build Side-by-Side Brawler Test Scene
# Creates scenes/brawler_side_by_side.tscn with both Leon and Nita brawlers.
# Run: godot --headless --script scripts/build_brawler_test_scene.gd

func _init() -> void:
	print("=== Building Side-by-Side Brawler Test Scene ===")

	# Root Node2D
	var root_node = Node2D.new()
	root_node.name = "BrawlerSideBySide"

	# Camera
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, -120)
	camera.zoom = Vector2(1.8, 1.8)
	root_node.add_child(camera)
	camera.owner = root_node

	# Ground (visual)
	var ground = ColorRect.new()
	ground.name = "Ground"
	ground.color = Color(0.2, 0.5, 0.25, 1.0)
	ground.position = Vector2(-800, 0)
	ground.size = Vector2(1600, 200)
	root_node.add_child(ground)
	ground.owner = root_node

	# Floor (physics)
	var floor_body = StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector2(0, 0)
	root_node.add_child(floor_body)
	floor_body.owner = root_node

	var floor_col = CollisionShape2D.new()
	floor_col.name = "CollisionShape2D"
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(1600, 40)
	floor_col.shape = floor_shape
	floor_col.position = Vector2(0, 20)
	floor_body.add_child(floor_col)
	floor_col.owner = root_node

	# Labels
	var label_leon = Label.new()
	label_leon.name = "LabelLeon"
	label_leon.text = "LEON (Template Reference)"
	label_leon.position = Vector2(-280, -220)
	label_leon.add_theme_font_size_override("font_size", 16)
	label_leon.add_theme_color_override("font_color", Color.WHITE)
	root_node.add_child(label_leon)
	label_leon.owner = root_node

	var label_nita = Label.new()
	label_nita.name = "LabelNita"
	label_nita.text = "NITA (Template Integration)"
	label_nita.position = Vector2(80, -220)
	label_nita.add_theme_font_size_override("font_size", 16)
	label_nita.add_theme_color_override("font_color", Color.WHITE)
	root_node.add_child(label_nita)
	label_nita.owner = root_node

	# Place Leon (sample brawler)
	var leon_placed = false
	if ResourceLoader.exists("res://scenes/sample_brawler.tscn"):
		var leon_scene = load("res://scenes/sample_brawler.tscn") as PackedScene
		if leon_scene:
			var leon = leon_scene.instantiate()
			leon.name = "LeonBrawler"
			leon.position = Vector2(-180, 0)
			root_node.add_child(leon)
			leon.owner = root_node
			_set_owner_recursive(leon, root_node)
			leon_placed = true
			print("  Placed Leon brawler")

	if not leon_placed:
		print("  ⚠ Leon brawler scene (sample_brawler.tscn) not found")

	# Place Nita
	var nita_placed = false
	if ResourceLoader.exists("res://scenes/brawler_nita.tscn"):
		var nita_scene = load("res://scenes/brawler_nita.tscn") as PackedScene
		if nita_scene:
			var nita = nita_scene.instantiate()
			nita.name = "NitaBrawler"
			nita.position = Vector2(180, 0)
			root_node.add_child(nita)
			nita.owner = root_node
			_set_owner_recursive(nita, root_node)
			nita_placed = true
			print("  Placed Nita brawler")

	if not nita_placed:
		print("  ⚠ Nita brawler scene not found — run build_brawler_nita.gd first!")

	# Save
	var packed = PackedScene.new()
	var err = packed.pack(root_node)
	if err != OK:
		push_error("Failed to pack side-by-side scene: %s" % error_string(err))
		root_node.free()
		quit()
		return

	err = ResourceSaver.save(packed, "res://scenes/brawler_side_by_side.tscn")
	if err != OK:
		push_error("Failed to save: %s" % error_string(err))
	else:
		print("  ✓ Saved scenes/brawler_side_by_side.tscn")

	root_node.free()
	print("=== Side-by-Side Build Complete ===")
	quit()


func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)
