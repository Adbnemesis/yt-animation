@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating scenes/nita_expression_showcase.tscn and scenes/leon_expression_showcase.tscn...")
	build_nita_expressions()
	build_leon_expressions()
	quit(0)

func build_nita_expressions() -> void:
	var root = Node2D.new()
	root.name = "NitaExpressionShowcase"
	root.set_script(load("res://scripts/nita_expression_showcase.gd"))

	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.08, 0.09, 0.12, 1.0)
	root.add_child(bg)
	bg.owner = root

	var title = Label.new()
	title.name = "Title"
	title.text = "BRAWL STARS — NITA EXPRESSION MATRIX (AUTHENTIC RIG)"
	title.position = Vector2(40, 30)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Authentic Cut-Paper Facial Swaps on Production Front Rig • In-Engine Texture Assets"
	subtitle.position = Vector2(40, 65)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.73, 0.82, 1.0))
	root.add_child(subtitle)
	subtitle.owner = root

	var expressions = ["grin", "happy", "angry", "shocked", "hurt", "neutral"]
	var cols = 3
	var start_x = 240.0
	var spacing_x = 400.0
	var start_y = 300.0
	var spacing_y = 260.0

	for i in range(expressions.size()):
		var expr_name = expressions[i]
		var col = i % cols
		var row = i / cols
		var pos = Vector2(start_x + col * spacing_x, start_y + row * spacing_y)

		var nita = load("res://scenes/nita_front.tscn").instantiate()
		nita.name = "Nita_" + expr_name
		nita.position = pos
		root.add_child(nita)
		nita.owner = root

		var face = nita.find_child("Face", true, false)
		if face:
			face.set("expression", expr_name)
			if face.has_method("set_expression"):
				face.set_expression(expr_name)

		var lbl = Label.new()
		lbl.name = "Label_" + expr_name
		lbl.text = expr_name.to_upper()
		lbl.position = Vector2(pos.x - 100, pos.y + 20)
		lbl.size = Vector2(200, 30)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
		root.add_child(lbl)
		lbl.owner = root

	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/nita_expression_showcase.tscn")
	print("[BUILD] Saved scenes/nita_expression_showcase.tscn")

func build_leon_expressions() -> void:
	var root = Node2D.new()
	root.name = "LeonExpressionShowcase"
	root.set_script(load("res://scripts/leon_expression_showcase.gd"))

	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.08, 0.09, 0.12, 1.0)
	root.add_child(bg)
	bg.owner = root

	var title = Label.new()
	title.name = "Title"
	title.text = "BRAWL STARS — LEON EXPRESSION MATRIX (AUTHENTIC RIG)"
	title.position = Vector2(40, 30)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Authentic Cut-Paper Facial Swaps on Production Front Rig • In-Engine Texture Assets"
	subtitle.position = Vector2(40, 65)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.73, 0.82, 1.0))
	root.add_child(subtitle)
	subtitle.owner = root

	var expressions = ["neutral", "happy", "angry", "sad", "shocked", "scared", "hurt", "confused", "smug", "laughing"]
	var cols = 5
	var start_x = 150.0
	var spacing_x = 245.0
	var start_y = 300.0
	var spacing_y = 260.0

	for i in range(expressions.size()):
		var expr_name = expressions[i]
		var col = i % cols
		var row = i / cols
		var pos = Vector2(start_x + col * spacing_x, start_y + row * spacing_y)

		var leon = load("res://scenes/videos/leon_elevator/leon_front.tscn").instantiate()
		leon.name = "Leon_" + expr_name
		leon.position = pos
		root.add_child(leon)
		leon.owner = root

		var face = leon.find_child("Face", true, false)
		if face:
			face.set("expression", expr_name)
			if face.has_method("set_expression"):
				face.set_expression(expr_name)

		var lbl = Label.new()
		lbl.name = "Label_" + expr_name
		lbl.text = expr_name.to_upper()
		lbl.position = Vector2(pos.x - 100, pos.y + 20)
		lbl.size = Vector2(200, 30)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
		root.add_child(lbl)
		lbl.owner = root

	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/leon_expression_showcase.tscn")
	print("[BUILD] Saved scenes/leon_expression_showcase.tscn")
