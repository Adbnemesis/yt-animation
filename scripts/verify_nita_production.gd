extends SceneTree

func _init() -> void:
	print("=======================================================")
	print("[VERIFY] Starting Comprehensive Nita Verification...")
	print("=======================================================")

	# 1. Test Instantiation of All Scenes
	print("[1/4] Testing Scene Loading & Instantiation...")
	var scn_front = load("res://scenes/nita_front.tscn")
	assert(scn_front != null, "Failed to load scenes/nita_front.tscn")
	var inst_front = scn_front.instantiate()
	assert(inst_front != null, "Failed to instantiate scenes/nita_front.tscn")
	print("  ✓ scenes/nita_front.tscn instantiates cleanly")

	var scn_back = load("res://scenes/nita_back.tscn")
	assert(scn_back != null, "Failed to load scenes/nita_back.tscn")
	var inst_back = scn_back.instantiate()
	assert(inst_back != null, "Failed to instantiate scenes/nita_back.tscn")
	print("  ✓ scenes/nita_back.tscn instantiates cleanly")

	var scn_side = load("res://scenes/nita_side.tscn")
	assert(scn_side != null, "Failed to load scenes/nita_side.tscn")
	var inst_side = scn_side.instantiate()
	assert(inst_side != null, "Failed to instantiate scenes/nita_side.tscn")
	print("  ✓ scenes/nita_side.tscn instantiates cleanly")

	var scn_main = load("res://scenes/nita.tscn")
	assert(scn_main != null, "Failed to load scenes/nita.tscn")
	var inst_main = scn_main.instantiate()
	assert(inst_main != null, "Failed to instantiate scenes/nita.tscn")
	print("  ✓ scenes/nita.tscn instantiates cleanly")

	var scn_actor = load("res://scenes/actor_nita.tscn")
	assert(scn_actor != null, "Failed to load scenes/actor_nita.tscn")
	var inst_actor = scn_actor.instantiate()
	assert(inst_actor != null, "Failed to instantiate scenes/actor_nita.tscn")
	print("  ✓ scenes/actor_nita.tscn instantiates cleanly")

	# 2. Test FaceControllerNita Features
	print("\n[2/4] Testing FaceControllerNita Expressions...")
	var face = inst_front.find_child("Face", true, false)
	assert(face != null, "Face node not found on NitaFront")
	assert(face.has_method("set_expression"), "Face missing set_expression method")
	assert(not face.hide_eyes_in_neutral, "hide_eyes_in_neutral must be FALSE for Nita!")

	var expressions = ["neutral", "grin", "happy", "angry", "shocked", "hurt"]
	for expr in expressions:
		face.set_expression(expr)
		assert(face.current_expression == expr, "Failed to set expression: " + expr)
		print("  ✓ Expression '%s' tested successfully" % expr)
	face.set_expression("grin") # Set back to signature smirk

	# 3. Test ActorNita Methods & View Switching
	print("\n[3/4] Testing ActorNita Multi-View Control...")
	assert(inst_actor.has_method("set_view"), "ActorNita missing set_view")
	assert(inst_actor.has_method("set_facing"), "ActorNita missing set_facing")
	assert(inst_actor.has_method("walk_to"), "ActorNita missing walk_to")
	assert(inst_actor.has_method("set_expression"), "ActorNita missing set_expression")

	const ActorNitaScript = preload("res://scenes/actor_nita.gd")
	get_root().add_child(inst_actor)
	inst_actor.set_view(ActorNitaScript.ViewMode.FRONT)
	assert(inst_actor.front_view != null and inst_actor.front_view.visible, "Front view should be visible")
	assert(not inst_actor.side_view.visible, "Side view should be hidden")

	inst_actor.set_view(ActorNitaScript.ViewMode.BACK)
	assert(inst_actor.back_view.visible, "Back view should be visible")

	inst_actor.set_view(ActorNitaScript.ViewMode.SIDE)
	assert(inst_actor.side_view.visible, "Side view should be visible")
	print("  ✓ ActorNita view switching verified")

	# 4. Render High-Resolution Showcase & Comparison
	print("\n[4/4] Rendering 1920x1080 Showcase & Scale Comparison...")
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Background (Studio dark theme matching Leon's showcase)
	var bg = ColorRect.new()
	bg.size = Vector2(1920, 1080)
	bg.color = Color(0.09, 0.10, 0.13, 1.0)
	viewport.add_child(bg)

	# Ground Line
	var ground_y = 740.0
	var ground = Line2D.new()
	ground.default_color = Color(0.20, 0.22, 0.28, 1.0)
	ground.width = 4.0
	ground.add_point(Vector2(60, ground_y))
	ground.add_point(Vector2(1860, ground_y))
	viewport.add_child(ground)

	# UI Header Label
	var title_lbl = Label.new()
	title_lbl.text = "BRAWL STARS — NITA REDESIGN & LEON CONSISTENCY SHOWCASE"
	title_lbl.position = Vector2(80, 50)
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	viewport.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Authentic Bear Cowl ('X' Eyes, Snout, Fangs) • War Paint Eye Mask • Bare Chibi Hands • 100% Leon Art Style Harmony"
	sub_lbl.position = Vector2(80, 95)
	sub_lbl.add_theme_font_size_override("font_size", 20)
	sub_lbl.add_theme_color_override("font_color", Color(0.68, 0.73, 0.82, 1.0))
	viewport.add_child(sub_lbl)

	# Shadows under characters
	var add_shadow = func(x_pos: float) -> void:
		var shadow = Polygon2D.new()
		shadow.color = Color(0.05, 0.06, 0.08, 0.65)
		var pts = PackedVector2Array()
		for i in range(24):
			var angle = i * TAU / 24.0
			pts.append(Vector2(x_pos + cos(angle) * 70.0, ground_y + sin(angle) * 16.0))
		shadow.polygon = pts
		viewport.add_child(shadow)

	var positions = [
		{"name": "Leon (Front)", "x": 260.0, "type": "leon_front"},
		{"name": "Nita (Front)", "x": 620.0, "type": "nita_front"},
		{"name": "Nita (Side Rig)", "x": 980.0, "type": "nita_side"},
		{"name": "Nita (Back)", "x": 1340.0, "type": "nita_back"},
		{"name": "Leon (Side Rig)", "x": 1680.0, "type": "leon_side"}
	]

	for item in positions:
		add_shadow.call(item["x"])

		var char_node: Node2D = null
		match item["type"]:
			"leon_front":
				char_node = load("res://scenes/videos/leon_elevator/leon_front.tscn").instantiate()
			"nita_front":
				char_node = load("res://scenes/nita_front.tscn").instantiate()
			"nita_side":
				char_node = load("res://scenes/nita_side.tscn").instantiate()
				char_node.set_script(null) # Pure rest pose
			"nita_back":
				char_node = load("res://scenes/nita_back.tscn").instantiate()
			"leon_side":
				char_node = load("res://scenes/leon.tscn").instantiate()
				char_node.set_script(null) # Pure rest pose

		if char_node:
			char_node.position = Vector2(item["x"], ground_y)
			viewport.add_child(char_node)

		var lbl = Label.new()
		lbl.text = item["name"]
		lbl.position = Vector2(item["x"] - 90.0, ground_y + 35.0)
		lbl.size = Vector2(180, 40)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1.0))
		viewport.add_child(lbl)

	get_root().add_child(viewport)

	# Wait for render passes to complete
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var img = viewport.get_texture().get_image()
	img.save_png("scratch/nita_production_showcase.png")
	print("  ✓ Rendered and saved to scratch/nita_production_showcase.png")

	print("\n=======================================================")
	print("[VERIFY SUCCESS] All Nita Production Assets Verified!")
	print("=======================================================")
	quit(0)
