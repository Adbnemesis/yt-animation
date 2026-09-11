extends SceneTree

# Build Three Brawlers Showcase Scene (Leon, Nita, Bo)
# Assembles scenes/three_brawler_test.tscn
# Run: /Users/talus/Downloads/Godot.app/Contents/MacOS/Godot --headless --script scripts/build_three_brawler_test_scene.gd

func _init() -> void:
	print("=== Building Three Brawlers Test Scene ===")

	var root = Node2D.new()
	root.name = "ThreeBrawlerTest"
	root.set_script(load("res://scripts/three_brawler_test.gd"))

	# Camera
	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.position = Vector2(0, -120)
	cam.zoom = Vector2(1.5, 1.5)
	root.add_child(cam)
	cam.owner = root

	# Visual Ground
	var ground = ColorRect.new()
	ground.name = "Ground"
	ground.position = Vector2(-1200, 0)
	ground.size = Vector2(2400, 240)
	ground.color = Color(0.15, 0.35, 0.20)
	root.add_child(ground)
	ground.owner = root

	# Physics Floor
	var floor_body = StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector2(0, 0)
	root.add_child(floor_body)
	floor_body.owner = root

	var floor_col = CollisionShape2D.new()
	floor_col.name = "CollisionShape2D"
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(2400, 40)
	floor_col.shape = floor_shape
	floor_col.position = Vector2(0, 20)
	floor_body.add_child(floor_col)
	floor_col.owner = root

	# Labels
	var lbl_leon = Label.new()
	lbl_leon.name = "LabelLeon"
	lbl_leon.text = "LEON (Speed: 170 / Stealth)"
	lbl_leon.position = Vector2(-360, -220)
	lbl_leon.add_theme_font_size_override("font_size", 14)
	lbl_leon.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	root.add_child(lbl_leon)
	lbl_leon.owner = root

	var lbl_nita = Label.new()
	lbl_nita.name = "LabelNita"
	lbl_nita.text = "NITA (Speed: 145 / Ground Shocker)"
	lbl_nita.position = Vector2(-110, -220)
	lbl_nita.add_theme_font_size_override("font_size", 14)
	lbl_nita.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	root.add_child(lbl_nita)
	lbl_nita.owner = root

	var lbl_bo = Label.new()
	lbl_bo.name = "LabelBo"
	lbl_bo.text = "BO (Speed: 150 / Eagle Archer)"
	lbl_bo.position = Vector2(140, -220)
	lbl_bo.add_theme_font_size_override("font_size", 14)
	lbl_bo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	root.add_child(lbl_bo)
	lbl_bo.owner = root

	# Place Leon (scenes/leon.tscn)
	var leon_packed = load("res://scenes/leon.tscn") as PackedScene
	if leon_packed:
		var leon_inst = leon_packed.instantiate()
		leon_inst.name = "LeonBrawler"
		leon_inst.position = Vector2(-260, 0)
		root.add_child(leon_inst)
		leon_inst.owner = root
		_set_owner_recursive(leon_inst, root)
		print("  ✓ Placed Leon at x=-260")

	# Place Nita (brawler_nita.tscn)
	var nita_packed = load("res://scenes/brawler_nita.tscn") as PackedScene
	if nita_packed:
		var nita_inst = nita_packed.instantiate()
		nita_inst.name = "NitaBrawler"
		nita_inst.position = Vector2(0, 0)
		root.add_child(nita_inst)
		nita_inst.owner = root
		_set_owner_recursive(nita_inst, root)
		print("  ✓ Placed Nita at x=0")

	# Place Bo (brawler_bo.tscn)
	var bo_packed = load("res://scenes/brawler_bo.tscn") as PackedScene
	if bo_packed:
		var bo_inst = bo_packed.instantiate()
		bo_inst.name = "BrawlerBo"
		bo_inst.position = Vector2(260, 0)
		root.add_child(bo_inst)
		bo_inst.owner = root
		_set_owner_recursive(bo_inst, root)
		print("  ✓ Placed Bo at x=260")

	# UI Overlay
	var ui = CanvasLayer.new()
	ui.name = "UI"
	root.add_child(ui)
	ui.owner = root

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(20, 20)
	panel.size = Vector2(520, 100)
	ui.add_child(panel)
	panel.owner = root

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	vbox.owner = root

	var title = Label.new()
	title.name = "LblTitle"
	title.text = "THREE BRAWLERS SHOWCASE (LEON + NITA + BO)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	title.owner = root

	var lbl_info = Label.new()
	lbl_info.name = "LblInfo"
	lbl_info.text = "Automated Showcase Active (Synchronizing Leon, Nita, Bo)"
	lbl_info.add_theme_font_size_override("font_size", 13)
	lbl_info.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	vbox.add_child(lbl_info)
	lbl_info.owner = root

	var controls = Label.new()
	controls.name = "LblControls"
	controls.text = "Tab: Auto-cycle | 1: Idle | 2: Walk | 3: Run | 4: Jump | 5: Attack | 6: Hit | E: Cycle Expressions"
	controls.add_theme_font_size_override("font_size", 11)
	controls.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	vbox.add_child(controls)
	controls.owner = root

	# Save PackedScene
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err != OK:
		push_error("Failed to pack three_brawler_test scene: %s" % error_string(err))
		root.free()
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/three_brawler_test.tscn")
	if err != OK:
		push_error("Failed to save three_brawler_test.tscn: %s" % error_string(err))
		root.free()
		quit(1)
		return

	print("  ✓ Saved res://scenes/three_brawler_test.tscn successfully")
	root.free()
	quit(0)

func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)
