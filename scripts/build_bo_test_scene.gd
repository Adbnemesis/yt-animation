extends SceneTree

# Build Standalone Bo Test Arena Scene
# Creates scenes/bo_test.tscn
# Run: /Users/talus/Downloads/Godot.app/Contents/MacOS/Godot --headless --script scripts/build_bo_test_scene.gd

func _init() -> void:
	print("=== Building Bo Test Arena Scene ===")

	var root = Node2D.new()
	root.name = "BoTest"
	root.set_script(load("res://scripts/bo_test.gd"))

	# Camera
	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.position = Vector2(0, -120)
	cam.zoom = Vector2(1.8, 1.8)
	root.add_child(cam)
	cam.owner = root

	# Visual Ground
	var ground = ColorRect.new()
	ground.name = "Ground"
	ground.position = Vector2(-1000, 0)
	ground.size = Vector2(2000, 240)
	ground.color = Color(0.16, 0.38, 0.22)
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
	floor_shape.size = Vector2(2000, 40)
	floor_col.shape = floor_shape
	floor_col.position = Vector2(0, 20)
	floor_body.add_child(floor_col)
	floor_col.owner = root

	# Instance Bo
	var bo_packed = load("res://scenes/brawler_bo.tscn") as PackedScene
	if not bo_packed:
		push_error("Cannot load scenes/brawler_bo.tscn")
		quit(1)
		return

	var bo_node = bo_packed.instantiate()
	bo_node.name = "BrawlerBo"
	bo_node.position = Vector2(0, 0)
	root.add_child(bo_node)
	bo_node.owner = root
	_set_owner_recursive(bo_node, root)

	# UI Overlay
	var ui = CanvasLayer.new()
	ui.name = "UI"
	root.add_child(ui)
	ui.owner = root

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(20, 20)
	panel.size = Vector2(560, 220)
	ui.add_child(panel)
	panel.owner = root

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	vbox.owner = root

	var title = Label.new()
	title.name = "LblTitle"
	title.text = "BO (EAGLE ARCHER) — BRAWLER TEMPLATE TEST ARENA"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(title)
	title.owner = root

	var lbl_mode = Label.new()
	lbl_mode.name = "LblMode"
	lbl_mode.text = "Mode: INTERACTIVE [Tab to toggle]"
	lbl_mode.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_mode)
	lbl_mode.owner = root

	var lbl_state = Label.new()
	lbl_state.name = "LblState"
	lbl_state.text = "State: IDLE"
	lbl_state.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_state)
	lbl_state.owner = root

	var lbl_health = Label.new()
	lbl_health.name = "LblHealth"
	lbl_health.text = "Health: 1400 / 1400"
	lbl_health.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_health)
	lbl_health.owner = root

	var lbl_expr = Label.new()
	lbl_expr.name = "LblExpr"
	lbl_expr.text = "Expression: serious | Eyes: open"
	lbl_expr.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_expr)
	lbl_expr.owner = root

	var lbl_telemetry = Label.new()
	lbl_telemetry.name = "LblTelemetry"
	lbl_telemetry.text = "Events: 0 | Cycles: 0 | Time: 0.0s"
	lbl_telemetry.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_telemetry)
	lbl_telemetry.owner = root

	var lbl_controls = Label.new()
	lbl_controls.name = "LblControls"
	lbl_controls.text = "Controls: [A/D] Move | [Shift] Run | [Space] Jump | [J] Attack | [H] Hit | [K] Knockback | [X] Death | [E, 1-0] Expressions | [R] Reset"
	lbl_controls.add_theme_font_size_override("font_size", 11)
	lbl_controls.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	vbox.add_child(lbl_controls)
	lbl_controls.owner = root

	# Save PackedScene
	var packed = PackedScene.new()
	var err = packed.pack(root)
	if err != OK:
		push_error("Failed to pack bo_test scene: %s" % error_string(err))
		root.free()
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/bo_test.tscn")
	if err != OK:
		push_error("Failed to save bo_test.tscn: %s" % error_string(err))
		root.free()
		quit(1)
		return

	print("  ✓ Saved res://scenes/bo_test.tscn successfully")
	root.free()
	quit(0)

func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)
