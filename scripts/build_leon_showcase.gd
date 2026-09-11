@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating scenes/leon_showcase.tscn...")

	var root = Node2D.new()
	root.name = "LeonShowcase"
	root.set_script(load("res://scripts/leon_showcase.gd"))

	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.08, 0.09, 0.12, 1.0)
	root.add_child(bg)
	bg.owner = root

	# Title UI
	var title = Label.new()
	title.name = "Title"
	title.text = "BRAWL STARS — LEON CHAMELEON (AUTHENTIC PRODUCTION RIG)"
	title.position = Vector2(40, 30)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Chameleon Cowl (Cross-Stitch Button Eyes, Yellow Crest) • Lollipop • Multi-View Rigs • Exact 1:1 Scale Parity"
	subtitle.position = Vector2(40, 65)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.73, 0.82, 1.0))
	root.add_child(subtitle)
	subtitle.owner = root

	# Ground Line
	var ground_y = 520.0
	var ground = Line2D.new()
	ground.name = "GroundLine"
	ground.default_color = Color(0.20, 0.22, 0.28, 1.0)
	ground.width = 3.0
	ground.add_point(Vector2(40, ground_y))
	ground.add_point(Vector2(1240, ground_y))
	root.add_child(ground)
	ground.owner = root

	# 1. Nita Front (for scale reference)
	var nita_front = load("res://scenes/nita_front.tscn").instantiate()
	nita_front.name = "NitaReference"
	nita_front.position = Vector2(180, ground_y)
	root.add_child(nita_front)
	nita_front.owner = root

	var lbl1 = Label.new()
	lbl1.name = "NitaLabel"
	lbl1.text = "Nita (Scale Ref)"
	lbl1.position = Vector2(110, ground_y + 20)
	lbl1.size = Vector2(140, 30)
	lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl1.add_theme_font_size_override("font_size", 14)
	lbl1.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	root.add_child(lbl1)
	lbl1.owner = root

	# 2. Leon Front View
	var leon_front = load("res://scenes/videos/leon_elevator/leon_front.tscn").instantiate()
	leon_front.name = "LeonFrontView"
	leon_front.position = Vector2(450, ground_y)
	root.add_child(leon_front)
	leon_front.owner = root

	var lbl2 = Label.new()
	lbl2.name = "LeonFrontLabel"
	lbl2.text = "Leon (Front View)"
	lbl2.position = Vector2(380, ground_y + 20)
	lbl2.size = Vector2(140, 30)
	lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl2.add_theme_font_size_override("font_size", 14)
	lbl2.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(lbl2)
	lbl2.owner = root

	# 3. Leon Side Locomotion Rig
	var leon_side = load("res://scenes/leon.tscn").instantiate()
	leon_side.name = "LeonSideRig"
	leon_side.position = Vector2(740, ground_y)
	root.add_child(leon_side)
	leon_side.owner = root

	var lbl3 = Label.new()
	lbl3.name = "LeonSideLabel"
	lbl3.text = "Leon (Side Rig)"
	lbl3.position = Vector2(670, ground_y + 20)
	lbl3.size = Vector2(140, 30)
	lbl3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl3.add_theme_font_size_override("font_size", 14)
	lbl3.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(lbl3)
	lbl3.owner = root

	# 4. Leon Back View
	var leon_back = load("res://scenes/videos/leon_elevator/leon_back.tscn").instantiate()
	leon_back.name = "LeonBackView"
	leon_back.position = Vector2(1020, ground_y)
	root.add_child(leon_back)
	leon_back.owner = root

	var lbl4 = Label.new()
	lbl4.name = "LeonBackLabel"
	lbl4.text = "Leon (Back View)"
	lbl4.position = Vector2(950, ground_y + 20)
	lbl4.size = Vector2(140, 30)
	lbl4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl4.add_theme_font_size_override("font_size", 14)
	lbl4.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(lbl4)
	lbl4.owner = root

	# Expression Status Label
	var expr_lbl = Label.new()
	expr_lbl.name = "ExpressionStatus"
	expr_lbl.position = Vector2(380, ground_y + 55)
	expr_lbl.size = Vector2(500, 30)
	expr_lbl.add_theme_font_size_override("font_size", 14)
	expr_lbl.add_theme_color_override("font_color", Color(0.60, 0.90, 0.70, 1.0))
	expr_lbl.text = "Current Expression: NEUTRAL (1/10)"
	root.add_child(expr_lbl)
	expr_lbl.owner = root

	# Save PackedScene
	var scene = PackedScene.new()
	var result = scene.pack(root)
	if result == OK:
		var err = ResourceSaver.save(scene, "res://scenes/leon_showcase.tscn")
		if err == OK:
			print("[BUILD] SUCCESS: Saved scenes/leon_showcase.tscn")
		else:
			push_error("Failed to save scene: %d" % err)
	else:
		push_error("Failed to pack scene: %d" % result)

	quit(0)
