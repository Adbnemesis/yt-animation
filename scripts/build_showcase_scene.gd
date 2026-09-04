@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Character Showcase Scene (scenes/showcase.tscn)...")
	var root = Node2D.new()
	root.name = "Showcase"

	# 1. Background Studio Canvas (1280 x 720) - Clean Neutral Slate Backdrop
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.16, 0.18, 0.23)
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	bg.owner = root

	# Soft Light Vignette in Center
	var center_glow = Polygon2D.new()
	center_glow.name = "CenterGlow"
	var glow_pts: PackedVector2Array = []
	for i in range(32):
		var a = i * TAU / 32.0
		glow_pts.append(Vector2(640 + cos(a) * 360.0, 410 + sin(a) * 260.0))
	center_glow.polygon = glow_pts
	center_glow.color = Color(0.22, 0.25, 0.32, 0.85)
	root.add_child(center_glow)
	center_glow.owner = root

	# Studio Spotlight Pedestal (Ground Oval)
	var ground_shadow = Polygon2D.new()
	ground_shadow.name = "GroundPedestal"
	var pts: PackedVector2Array = []
	for i in range(32):
		var angle = i * TAU / 32.0
		pts.append(Vector2(640 + cos(angle) * 160.0, 580 + sin(angle) * 32.0))
	ground_shadow.polygon = pts
	ground_shadow.color = Color(0.09, 0.11, 0.14, 0.90)
	root.add_child(ground_shadow)
	ground_shadow.owner = root

	# 2. Main Character Instance (Large, Centered Full Figure: 2.2x Scale)
	var sample_res = load("res://scenes/sample_brawler.tscn")
	var brawler = sample_res.instantiate()
	brawler.name = "SampleBrawlerMain"
	brawler.position = Vector2(640, 570)
	brawler.scale = Vector2(2.2, 2.2)
	root.add_child(brawler)
	brawler.owner = root

	# 3. CanvasLayer for UI / Model Sheet Annotation Cards
	var canvas = CanvasLayer.new()
	canvas.name = "UI"
	root.add_child(canvas)
	canvas.owner = root

	# Header Title
	var title = Label.new()
	title.text = "CUTENEMI 2D BRAWLER — FULL FIGURE MODEL SHEET"
	title.position = Vector2(40, 24)
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.45, 0.85, 1.0)
	canvas.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.text = "Visual Standard: 45% Head Ratio • 3.5px Ink Outlines • 2-Tone Cel Shading • Modular Cutout Skeleton"
	subtitle.position = Vector2(40, 56)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.modulate = Color(0.75, 0.80, 0.88)
	canvas.add_child(subtitle)
	subtitle.owner = root

	# Left Sidebar Card: Proportion & Style Metrics
	var panel_l = PanelContainer.new()
	panel_l.position = Vector2(40, 100)
	panel_l.size = Vector2(280, 540)

	var sb_l = StyleBoxFlat.new()
	sb_l.bg_color = Color(0.10, 0.12, 0.16, 0.92)
	sb_l.border_width_bottom = 2
	sb_l.border_width_left = 2
	sb_l.border_width_right = 2
	sb_l.border_width_top = 2
	sb_l.border_color = Color(0.3, 0.45, 0.65, 0.7)
	sb_l.corner_radius_top_left = 8
	sb_l.corner_radius_top_right = 8
	sb_l.corner_radius_bottom_left = 8
	sb_l.corner_radius_bottom_right = 8
	sb_l.content_margin_left = 16
	sb_l.content_margin_right = 16
	sb_l.content_margin_top = 16
	sb_l.content_margin_bottom = 16
	panel_l.add_theme_stylebox_override("panel", sb_l)
	canvas.add_child(panel_l)
	panel_l.owner = root

	var vbox_l = VBoxContainer.new()
	vbox_l.add_theme_constant_override("separation", 10)
	panel_l.add_child(vbox_l)
	vbox_l.owner = root

	var add_lbl_l = func(txt: String, fsize: int, col: Color) -> Label:
		var l = Label.new()
		l.text = txt
		l.add_theme_font_size_override("font_size", fsize)
		l.modulate = col
		vbox_l.add_child(l)
		l.owner = root
		return l

	add_lbl_l.call("PROPORTIONS (220px)", 15, Color(0.3, 0.9, 0.6))
	add_lbl_l.call("• Head: 45% (Chunky/Cute)\n• Torso: 22% (Compact Slate Coat)\n• Limbs: 18% (Short Ball-Socket)\n• Boots: 15% (Oversized Grip Sole)\n• Fists: 28px Cartoon Mitts", 12, Color(0.92, 0.92, 0.92))

	var sep1 = HSeparator.new()
	vbox_l.add_child(sep1)
	sep1.owner = root

	add_lbl_l.call("COLOR PALETTE", 15, Color(0.3, 0.9, 0.6))
	add_lbl_l.call("■ #1e1e2c (3.5px Ink Outline)\n■ #34495e (Primary Slate Coat)\n■ #2c3e50 (Dark Charcoal Vest)\n■ #f8d79b (Warm Skin Surface)\n■ #ff4757 (Vibrant Crimson Scarf)\n■ #1e272e (Obsidian Hair)\n■ #747d8c (Chunky Sole Trim)\n■ #232f3e (2-Tone Cel Shadow)", 12, Color(0.85, 0.88, 0.92))

	# Right Sidebar Card: Face Component System & Expression Palette
	var panel_r = PanelContainer.new()
	panel_r.position = Vector2(960, 100)
	panel_r.size = Vector2(280, 540)

	var sb_r = StyleBoxFlat.new()
	sb_r.bg_color = Color(0.10, 0.12, 0.16, 0.92)
	sb_r.border_width_bottom = 2
	sb_r.border_width_left = 2
	sb_r.border_width_right = 2
	sb_r.border_width_top = 2
	sb_r.border_color = Color(0.3, 0.45, 0.65, 0.7)
	sb_r.corner_radius_top_left = 8
	sb_r.corner_radius_top_right = 8
	sb_r.corner_radius_bottom_left = 8
	sb_r.corner_radius_bottom_right = 8
	sb_r.content_margin_left = 16
	sb_r.content_margin_right = 16
	sb_r.content_margin_top = 16
	sb_r.content_margin_bottom = 16
	panel_r.add_theme_stylebox_override("panel", sb_r)
	canvas.add_child(panel_r)
	panel_r.owner = root

	var vbox_r = VBoxContainer.new()
	vbox_r.add_theme_constant_override("separation", 10)
	panel_r.add_child(vbox_r)
	vbox_r.owner = root

	var add_lbl_r = func(txt: String, fsize: int, col: Color) -> Label:
		var l = Label.new()
		l.text = txt
		l.add_theme_font_size_override("font_size", fsize)
		l.modulate = col
		vbox_r.add_child(l)
		l.owner = root
		return l

	add_lbl_r.call("FACE SYSTEM", 15, Color(0.3, 0.9, 0.6))
	add_lbl_r.call("• Decoupled from Body Rig\n• Eye Sclera: Clean white beans\n• Pupils: Dark ellipses + catchlight\n• Brows: Expressive floating wedges\n• Auto-Blink: Every 3.0s (0.12s)\n• Gaze Tracking Supported", 12, Color(0.92, 0.92, 0.92))

	var sep3 = HSeparator.new()
	vbox_r.add_child(sep3)
	sep3.owner = root

	add_lbl_r.call("10 EXPRESSION LIBRARY", 15, Color(0.3, 0.9, 0.6))
	add_lbl_r.call("1. neutral (Default Confident)\n2. happy (Wide Smile)\n3. angry (Clenched Teeth)\n4. sad (Drooping Frown)\n5. shocked (Tall 'O')\n6. scared (Chattering Teeth)\n7. hurt (Zigzag Grimace)\n8. confused (Asymmetrical)\n9. smug (Sideways Smirk)\n10. laughing (Open Arcs)", 11, Color(0.85, 0.88, 0.92))

	# Script to setup character poses on ready
	var showcase_script = GDScript.new()
	showcase_script.source_code = """extends Node2D

func _ready() -> void:
	var main_brawler = get_node_or_null("SampleBrawlerMain")
	if main_brawler:
		main_brawler.set_physics_process(false)
		main_brawler.set_process(false)
		main_brawler.change_state(main_brawler.State.IDLE)
		main_brawler.face_controller.set_expression("neutral")
		if main_brawler.anim_player:
			main_brawler.anim_player.play("idle")
			main_brawler.anim_player.seek(0.0, true)
			main_brawler.anim_player.pause()
"""
	root.set_script(showcase_script)

	# Save PackedScene
	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack showcase scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/showcase.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save showcase scene: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/showcase.tscn with physics-disabled idle figure!")
	quit(0)
