@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating scenes/nita_showcase.tscn...")

	var root = Node2D.new()
	root.name = "NitaShowcase"
	root.set_script(load("res://scripts/nita_showcase.gd"))

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
	title.text = "BRAWL STARS — NITA LITTLEFOOT (AUTHENTIC PRODUCTION RIG)"
	title.position = Vector2(40, 30)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Bear Cowl ('X' Eyes, Snout, Fangs) • War Paint Mask • Bare Chibi Hands • Exact 1:1 Leon Parity"
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

	# 1. Leon Front (for scale reference)
	var leon_front = load("res://scenes/videos/leon_elevator/leon_front.tscn").instantiate()
	leon_front.name = "LeonReference"
	leon_front.position = Vector2(180, ground_y)
	root.add_child(leon_front)
	leon_front.owner = root

	var lbl1 = Label.new()
	lbl1.name = "LeonLabel"
	lbl1.text = "Leon (Scale Ref)"
	lbl1.position = Vector2(110, ground_y + 20)
	lbl1.size = Vector2(140, 30)
	lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl1.add_theme_font_size_override("font_size", 14)
	lbl1.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	root.add_child(lbl1)
	lbl1.owner = root

	# 2. Nita Front View
	var nita_front = load("res://scenes/nita_front.tscn").instantiate()
	nita_front.name = "NitaFrontView"
	nita_front.position = Vector2(450, ground_y)
	root.add_child(nita_front)
	nita_front.owner = root

	var lbl2 = Label.new()
	lbl2.name = "NitaFrontLabel"
	lbl2.text = "Nita (Front View)"
	lbl2.position = Vector2(380, ground_y + 20)
	lbl2.size = Vector2(140, 30)
	lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl2.add_theme_font_size_override("font_size", 14)
	lbl2.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(lbl2)
	lbl2.owner = root

	# 3. Nita Side Locomotion Rig
	var nita_side = load("res://scenes/nita_side.tscn").instantiate()
	nita_side.name = "NitaSideRig"
	nita_side.position = Vector2(740, ground_y)
	root.add_child(nita_side)
	nita_side.owner = root

	var lbl3 = Label.new()
	lbl3.name = "NitaSideLabel"
	lbl3.text = "Nita (Side Rig)"
	lbl3.position = Vector2(670, ground_y + 20)
	lbl3.size = Vector2(140, 30)
	lbl3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl3.add_theme_font_size_override("font_size", 14)
	lbl3.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(lbl3)
	lbl3.owner = root

	# 4. Nita Back View
	var nita_back = load("res://scenes/nita_back.tscn").instantiate()
	nita_back.name = "NitaBackView"
	nita_back.position = Vector2(1020, ground_y)
	root.add_child(nita_back)
	nita_back.owner = root

	var lbl4 = Label.new()
	lbl4.name = "NitaBackLabel"
	lbl4.text = "Nita (Back View)"
	lbl4.position = Vector2(950, ground_y + 20)
	lbl4.size = Vector2(140, 30)
	lbl4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl4.add_theme_font_size_override("font_size", 14)
	lbl4.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(lbl4)
	lbl4.owner = root

	# Expression Status UI
	var expr_lbl = Label.new()
	expr_lbl.name = "ExpressionStatus"
	expr_lbl.text = "Current Expression: GRIN (Signature Smirk)"
	expr_lbl.position = Vector2(380, ground_y + 55)
	expr_lbl.size = Vector2(500, 30)
	expr_lbl.add_theme_font_size_override("font_size", 14)
	expr_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7, 1.0))
	root.add_child(expr_lbl)
	expr_lbl.owner = root

	var scn = PackedScene.new()
	scn.pack(root)
	ResourceSaver.save(scn, "res://scenes/nita_showcase.tscn")
	print("  -> Saved scenes/nita_showcase.tscn successfully!")
	quit(0)
