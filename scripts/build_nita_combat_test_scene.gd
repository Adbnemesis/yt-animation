extends SceneTree

# Build Nita Combat Test Scene (scenes/nita_combat_test.tscn)
# Assembles the full interactive combat testing harness for Nita.

func _init() -> void:
	print("[BUILD] Generating Nita Combat Test Scene (scenes/nita_combat_test.tscn)...")

	var root = Node2D.new()
	root.name = "NitaCombatTestHarness"
	root.set_script(load("res://scripts/nita_combat_test.gd"))

	# 1. Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1152, 648)
	bg.color = Color(0.09, 0.11, 0.15)
	root.add_child(bg)
	bg.owner = root

	# Horizon Line
	var horizon = Line2D.new()
	horizon.name = "Horizon"
	horizon.points = PackedVector2Array([Vector2(0, 360), Vector2(1152, 360)])
	horizon.default_color = Color(0.14, 0.17, 0.22)
	horizon.width = 1.5
	root.add_child(horizon)
	horizon.owner = root

	# 2. Ground StaticBody & Surface
	var ground = StaticBody2D.new()
	ground.name = "Ground"
	ground.position = Vector2(576, 560)
	root.add_child(ground)
	ground.owner = root

	var ground_col = CollisionShape2D.new()
	ground_col.name = "CollisionShape2D"
	var box = RectangleShape2D.new()
	box.size = Vector2(1400, 80)
	ground_col.shape = box
	ground.add_child(ground_col)
	ground_col.owner = root

	var ground_rect = ColorRect.new()
	ground_rect.name = "GroundVisual"
	ground_rect.position = Vector2(-700, -40)
	ground_rect.size = Vector2(1400, 200)
	ground_rect.color = Color(0.14, 0.17, 0.22)
	ground.add_child(ground_rect)
	ground_rect.owner = root

	var ground_strip = ColorRect.new()
	ground_strip.name = "GroundTopStrip"
	ground_strip.position = Vector2(-700, -40)
	ground_strip.size = Vector2(1400, 4)
	ground_strip.color = Color(0.15, 0.65, 0.85)
	ground.add_child(ground_strip)
	ground_strip.owner = root

	# 3. Ground Contact Verification Line (Exact y = 520.0)
	var ground_line = Line2D.new()
	ground_line.name = "GroundLine"
	ground_line.points = PackedVector2Array([Vector2(0, 520), Vector2(1152, 520)])
	ground_line.default_color = Color(0.0, 0.9, 1.0, 0.6)
	ground_line.width = 1.0
	root.add_child(ground_line)
	ground_line.owner = root

	# 4. Target Dummy
	var dummy_scene: PackedScene = load("res://scenes/target_dummy.tscn")
	var dummy = dummy_scene.instantiate()
	dummy.name = "TargetDummy"
	dummy.position = Vector2(760, 520)
	root.add_child(dummy)
	dummy.owner = root

	# 5. Puppet (Nita Side)
	var puppet_scene: PackedScene = load("res://scenes/nita_side.tscn")
	var puppet = puppet_scene.instantiate()
	puppet.name = "Puppet"
	puppet.position = Vector2(380, 520)
	root.add_child(puppet)
	puppet.owner = root

	# 6. UI Layer
	var ui = CanvasLayer.new()
	ui.name = "UI"
	root.add_child(ui)
	ui.owner = root

	var header_box = VBoxContainer.new()
	header_box.name = "Header"
	header_box.position = Vector2(24, 16)
	ui.add_child(header_box)
	header_box.owner = root

	var lbl_title = Label.new()
	lbl_title.name = "LblTitle"
	lbl_title.text = "NITA 2D PUPPET — PRODUCTION COMBAT STAGE 1 (BASIC ATTACK & RUPTURE)"
	lbl_title.add_theme_font_size_override("font_size", 18)
	lbl_title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	header_box.add_child(lbl_title)
	lbl_title.owner = root

	var lbl_subtitle = Label.new()
	lbl_subtitle.name = "LblSubtitle"
	lbl_subtitle.text = "Walk • Run • Jump • Basic Attack • Rupture Shockwave • Target Dummy Collision • Ground y=520"
	lbl_subtitle.add_theme_font_size_override("font_size", 13)
	lbl_subtitle.add_theme_color_override("font_color", Color(0.60, 0.68, 0.78))
	header_box.add_child(lbl_subtitle)
	lbl_subtitle.owner = root

	var lbl_inst = Label.new()
	lbl_inst.name = "LblInstructions"
	lbl_inst.text = "1. Projectile Demo  2. Walk Attack Demo  3. Run Attack Demo  4. Directional Demo  5. Interactive Keys   Attack (J)  Jump (Space)  Reset Dummy (R)  Toggle Line (T)"
	lbl_inst.add_theme_font_size_override("font_size", 12)
	lbl_inst.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
	header_box.add_child(lbl_inst)
	lbl_inst.owner = root

	# Info Telemetry Panel
	var info_panel = PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(24, 96)
	info_panel.size = Vector2(540, 90)
	ui.add_child(info_panel)
	info_panel.owner = root

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	sb.border_width_bottom = 1
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_color = Color(0.18, 0.24, 0.35, 0.80)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	info_panel.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	info_panel.add_child(vbox)
	vbox.owner = root

	var lbl_mode = Label.new()
	lbl_mode.name = "LblMode"
	lbl_mode.text = "MODE: Projectile Demo (Single Shockwave • Collision • Despawn)"
	lbl_mode.add_theme_font_size_override("font_size", 13)
	lbl_mode.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	vbox.add_child(lbl_mode)
	lbl_mode.owner = root

	var lbl_stats = Label.new()
	lbl_stats.name = "LblStats"
	lbl_stats.text = "STATE: IDLE | ANIM: idle (0.00s/2.00s) | FACING: +1 (RIGHT) | GROUNDED: TRUE\nPROJECTILES ACTIVE: 0 | LAST EVENT: None | LAST HIT: None | TARGET HP: 1000 / 1000\nSPEED: 600 px/s | BURST: 1 Shockwave | RANGE: 480 px | VEL: (0.0, 0.0) px/s"
	lbl_stats.add_theme_font_size_override("font_size", 12)
	lbl_stats.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	vbox.add_child(lbl_stats)
	lbl_stats.owner = root

	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack scenes/nita_combat_test.tscn: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/nita_combat_test.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/nita_combat_test.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/nita_combat_test.tscn!")
	quit(0)
