@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Comprehensive Leon Presentation Scene (scenes/leon_presentation.tscn)...")
	var root = Node2D.new()
	root.name = "LeonPresentation"

	# Background Canvas (1280 x 720) - Dark Studio Grey
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.10, 0.12, 0.16)
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	bg.owner = root

	# Studio Spotlight Podiums
	var create_pedestal = func(pos: Vector2, rx: float, ry: float) -> Polygon2D:
		var p = Polygon2D.new()
		var pts: PackedVector2Array = []
		for i in range(32):
			var a = i * TAU / 32.0
			pts.append(Vector2(pos.x + cos(a) * rx, pos.y + sin(a) * ry))
		p.polygon = pts
		p.color = Color(0.06, 0.07, 0.10, 0.85)
		root.add_child(p)
		p.owner = root
		return p

	create_pedestal.call(Vector2(240, 560), 80, 16)
	create_pedestal.call(Vector2(640, 560), 120, 24)
	create_pedestal.call(Vector2(1040, 560), 80, 16)

	# 1. Front View (Left, Scale 1.7)
	var char_res = load("res://scenes/leon.tscn")

	var front_sprite = Sprite2D.new()
	front_sprite.name = "FrontViewSprite"
	front_sprite.texture = load("res://assets/leon/sheets/01_leon_front_view.svg")
	front_sprite.position = Vector2(240, 360)
	front_sprite.scale = Vector2(0.85, 0.85)
	root.add_child(front_sprite)
	front_sprite.owner = root

	# 2. Main Center Puppet Instance (Scale 2.4x)
	var main_leon = char_res.instantiate()
	main_leon.name = "LeonMain"
	main_leon.position = Vector2(640, 550)
	main_leon.scale = Vector2(2.4, 2.4)
	root.add_child(main_leon)
	main_leon.owner = root

	# 3. 3/4 & Side Views (Right)
	var side_sprite = Sprite2D.new()
	side_sprite.name = "SideViewSprite"
	side_sprite.texture = load("res://assets/leon/sheets/02_leon_34_view.svg")
	side_sprite.position = Vector2(1040, 360)
	side_sprite.scale = Vector2(0.85, 0.85)
	root.add_child(side_sprite)
	side_sprite.owner = root

	# 4. CanvasLayer for UI / Model Sheet Information
	var canvas = CanvasLayer.new()
	canvas.name = "UI"
	root.add_child(canvas)
	canvas.owner = root

	# Header Title
	var title = Label.new()
	title.text = "CUTENEMI 2D BRAWLER — LEON (EARLY SOUTH PARK STYLE)"
	title.position = Vector2(40, 20)
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.45, 0.85, 1.0)
	canvas.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.text = "Visual Standard: 45% Head • 3.5px Ink Outlines • Flat Colors • South Park Paper-Cutout Construction"
	subtitle.position = Vector2(40, 52)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.modulate = Color(0.75, 0.80, 0.88)
	canvas.add_child(subtitle)
	subtitle.owner = root

	# Left Metric Card
	var panel_l = PanelContainer.new()
	panel_l.position = Vector2(40, 90)
	panel_l.size = Vector2(220, 200)
	var sb_l = StyleBoxFlat.new()
	sb_l.bg_color = Color(0.12, 0.15, 0.20, 0.90)
	sb_l.border_width_bottom = 2; sb_l.border_width_left = 2; sb_l.border_width_right = 2; sb_l.border_width_top = 2
	sb_l.border_color = Color(0.25, 0.40, 0.60, 0.8)
	sb_l.corner_radius_top_left = 8; sb_l.corner_radius_top_right = 8
	sb_l.corner_radius_bottom_left = 8; sb_l.corner_radius_bottom_right = 8
	sb_l.content_margin_left = 12; sb_l.content_margin_top = 10; sb_l.content_margin_right = 12; sb_l.content_margin_bottom = 10
	panel_l.add_theme_stylebox_override("panel", sb_l)
	canvas.add_child(panel_l)
	panel_l.owner = root

	var vbox_l = VBoxContainer.new()
	panel_l.add_child(vbox_l)
	vbox_l.owner = root
	var lbl_prop_t = Label.new(); lbl_prop_t.text = "PROPORTIONS"; lbl_prop_t.add_theme_font_size_override("font_size", 14); lbl_prop_t.modulate = Color(0.3, 0.9, 0.6); vbox_l.add_child(lbl_prop_t); lbl_prop_t.owner = root
	var lbl_prop_b = Label.new(); lbl_prop_b.text = "• Head: ≈ 45% (Oversized)\n• Torso: ≈ 25% (Green Hoodie)\n• Legs: ≈ 30% (Shorts + Feet)\n• Outlines: 3.5px Solid Black"; lbl_prop_b.add_theme_font_size_override("font_size", 11); vbox_l.add_child(lbl_prop_b); lbl_prop_b.owner = root

	# Right Palette Card
	var panel_r = PanelContainer.new()
	panel_r.position = Vector2(1020, 90)
	panel_r.size = Vector2(220, 200)
	var sb_r = sb_l.duplicate()
	panel_r.add_theme_stylebox_override("panel", sb_r)
	canvas.add_child(panel_r)
	panel_r.owner = root

	var vbox_r = VBoxContainer.new()
	panel_r.add_child(vbox_r)
	vbox_r.owner = root
	var lbl_pal_t = Label.new(); lbl_pal_t.text = "LEON PALETTE"; lbl_pal_t.add_theme_font_size_override("font_size", 14); lbl_pal_t.modulate = Color(0.3, 0.9, 0.6); vbox_r.add_child(lbl_pal_t); lbl_pal_t.owner = root
	var lbl_pal_b = Label.new(); lbl_pal_b.text = "■ #38b000 (Hood & Hoodie)\n■ #ffd166 (Yellow Crest Stripe)\n■ #1e90ff (Buttons & Pocket)\n■ #1f3160 (Navy Shorts)\n■ #c47d48 (Tanned Skin)\n■ #e63946 (Red Lollipop Candy)\n■ #1e1e2c (3.5px Ink Outlines)"; lbl_pal_b.add_theme_font_size_override("font_size", 11); vbox_r.add_child(lbl_pal_b); lbl_pal_b.owner = root

	# Bottom Annotation Strip
	var banner = PanelContainer.new()
	banner.position = Vector2(40, 640)
	banner.size = Vector2(1200, 56)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = Color(0.12, 0.15, 0.20, 0.95)
	sb_b.border_width_bottom = 2; sb_b.border_width_left = 2; sb_b.border_width_right = 2; sb_b.border_width_top = 2
	sb_b.border_color = Color(0.25, 0.40, 0.60, 0.8)
	sb_b.corner_radius_top_left = 6; sb_b.corner_radius_top_right = 6
	sb_b.corner_radius_bottom_left = 6; sb_b.corner_radius_bottom_right = 6
	sb_b.content_margin_left = 16; sb_b.content_margin_top = 8; sb_b.content_margin_right = 16; sb_b.content_margin_bottom = 8
	banner.add_theme_stylebox_override("panel", sb_b)
	canvas.add_child(banner)
	banner.owner = root

	var lbl_banner = Label.new()
	lbl_banner.text = "16 DELIVERABLE SHEETS GENERATED IN assets/leon/sheets/:\n01 Front • 02 3/4 • 03 Side • 04 Expressions (10) • 05 Construction (Pivots) • 06-16 Poses (Idle, Walk 1-2, Run 1-2, Atk Coil, Strike, Follow-through, Jump, Fall, Land, Hit, Knockback)"
	lbl_banner.add_theme_font_size_override("font_size", 12)
	lbl_banner.modulate = Color(0.9, 0.92, 0.96)
	banner.add_child(lbl_banner)
	lbl_banner.owner = root

	# Showcase Script to pause main puppet in neutral idle
	var script = GDScript.new()
	script.source_code = """extends Node2D

func _ready() -> void:
	var leon = get_node_or_null("LeonMain")
	if leon:
		leon.set_physics_process(false)
		leon.set_process(false)
		if leon.has_method("change_state"):
			leon.change_state(leon.State.IDLE)
		var face = leon.find_child("Face")
		if face and face.has_method("set_expression"):
			face.set_expression("neutral")
		var anim = leon.get_node_or_null("AnimPlayer")
		if anim and anim.has_animation("RESET"):
			anim.play("RESET")
			anim.pause()
"""
	root.set_script(script)

	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/leon_presentation.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/leon_presentation.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/leon_presentation.tscn!")
	quit(0)
