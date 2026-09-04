@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Leon Walk Test Scene (scenes/walk_test.tscn)...")

	var root = Node2D.new()
	root.name = "WalkTestHarness"
	root.set_script(load("res://scripts/walk_test.gd"))

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
	ground_strip.color = Color(0.20, 0.55, 0.85)
	ground.add_child(ground_strip)
	ground_strip.owner = root

	# 3. Ground Contact Verification Line (Exact y = 520.0)
	var ground_line = Line2D.new()
	ground_line.name = "GroundLine"
	ground_line.points = PackedVector2Array([Vector2(0, 520), Vector2(1152, 520)])
	ground_line.default_color = Color(1.0, 0.85, 0.25, 0.85) # High-visibility gold
	ground_line.width = 2.0
	ground_line.z_index = 5
	root.add_child(ground_line)
	ground_line.owner = root

	# 4. Main Puppet Instance (Side View Profile)
	var leon_scene = load("res://scenes/leon_side.tscn")
	var puppet = leon_scene.instantiate()
	puppet.name = "Puppet"
	puppet.position = Vector2(576, 520)
	root.add_child(puppet)
	puppet.owner = root

	# 4b. Target Dummy Instance
	var dummy_scene = load("res://scenes/target_dummy.tscn")
	var dummy = dummy_scene.instantiate()
	dummy.name = "TargetDummy"
	dummy.position = Vector2(880, 520)
	root.add_child(dummy)
	dummy.owner = root

	# 5. UI Layer
	var ui = CanvasLayer.new()
	ui.name = "UI"
	root.add_child(ui)
	ui.owner = root

	# Header Title
	var title = Label.new()
	title.text = "LEON 2D PUPPET — PRODUCTION COMBAT STAGE 4 (SUPER INVISIBILITY)"
	title.position = Vector2(24, 16)
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(0.45, 0.85, 1.0)
	ui.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.text = "Walk • Run • Jump • 4-Blade Spinner Burst • Super Invisibility (5s Ghost Fade) • Ground y=520"
	subtitle.position = Vector2(24, 42)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.modulate = Color(0.70, 0.75, 0.85)
	ui.add_child(subtitle)
	subtitle.owner = root

	# Mode Button Bar
	var bar = HBoxContainer.new()
	bar.position = Vector2(24, 70)
	bar.add_theme_constant_override("separation", 6)
	ui.add_child(bar)
	bar.owner = root

	var create_btn = func(text: String, call_code: String) -> Button:
		var btn = Button.new()
		btn.text = text
		btn.add_theme_font_size_override("font_size", 11)
		var b_script = GDScript.new()
		b_script.source_code = """extends Button
func _pressed() -> void:
	var harness = get_tree().current_scene
	if harness:
		%s
""" % call_code
		btn.set_script(b_script)
		bar.add_child(btn)
		btn.owner = root
		return btn

	create_btn.call("1. Walk In Place", "harness.set_mode(harness.Mode.IN_PLACE_WALK)")
	create_btn.call("2. Run In Place", "harness.set_mode(harness.Mode.IN_PLACE_RUN)")
	create_btn.call("3. Locomotion Demo", "harness.set_mode(harness.Mode.LOCOMOTION_DEMO)")
	create_btn.call("4. Jump Demo", "harness.set_mode(harness.Mode.JUMP_DEMO)")
	create_btn.call("5. Projectile Demo", "harness.set_mode(harness.Mode.PROJECTILE_DEMO)")
	create_btn.call("6. Super Demo", "harness.set_mode(harness.Mode.SUPER_DEMO)")
	create_btn.call("7. Interactive Keys", "harness.set_mode(harness.Mode.INTERACTIVE)")
	create_btn.call("Attack (J)", "harness.trigger_attack()")
	create_btn.call("Super (L)", "harness.trigger_super()")
	create_btn.call("Jump (Space)", "harness.trigger_jump()")
	create_btn.call("Reset Dummy", "harness.reset_target_dummy()")
	create_btn.call("Toggle Line", "harness.toggle_ground_line()")

	# Info Panel
	var info_panel = PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.position = Vector2(24, 115)
	info_panel.size = Vector2(580, 95)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.15, 0.20, 0.90)
	sb.border_width_left = 1; sb.border_width_right = 1; sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_color = Color(0.25, 0.35, 0.50, 0.8)
	sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6; sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	info_panel.add_theme_stylebox_override("panel", sb)
	ui.add_child(info_panel)
	info_panel.owner = root

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	info_panel.add_child(vbox)
	vbox.owner = root

	var lbl_mode = Label.new()
	lbl_mode.name = "LblMode"
	lbl_mode.text = "MODE: Walk In Place (Stationary Stride)"
	lbl_mode.add_theme_font_size_override("font_size", 12)
	lbl_mode.modulate = Color(0.3, 0.85, 1.0)
	vbox.add_child(lbl_mode)
	lbl_mode.owner = root

	var lbl_stats = Label.new()
	lbl_stats.name = "LblStats"
	lbl_stats.text = "Pos: (576.0, 520.0) | Anim Time: 0.00s / 0.80s\nFoot L Ground: +0.0 px | Foot R Ground: +0.0 px"
	lbl_stats.add_theme_font_size_override("font_size", 11)
	lbl_stats.modulate = Color(0.8, 0.85, 0.92)
	vbox.add_child(lbl_stats)
	lbl_stats.owner = root

	# Save Scene
	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack walk test scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/walk_test.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/walk_test.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/walk_test.tscn!")
	quit(0)
