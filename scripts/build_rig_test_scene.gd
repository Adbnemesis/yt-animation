@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Interactive Leon Rig Test Scene (scenes/rig_test.tscn)...")

	var root = Node2D.new()
	root.name = "RigTestHarness"
	root.set_script(load("res://scripts/rig_test.gd"))

	# 1. Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.08, 0.10, 0.13)
	root.add_child(bg)
	bg.owner = root

	# Subtle Ground / Pedestal Line
	var floor_shadow = Polygon2D.new()
	floor_shadow.name = "FloorShadow"
	var pts: PackedVector2Array = []
	for i in range(32):
		var a = i * TAU / 32.0
		pts.append(Vector2(580 + cos(a) * 110, 535 + sin(a) * 22))
	floor_shadow.polygon = pts
	floor_shadow.color = Color(0.04, 0.05, 0.07, 0.9)
	root.add_child(floor_shadow)
	floor_shadow.owner = root

	# 2. Main Puppet Instance (Scaled 2.5x)
	var leon_scene = load("res://scenes/leon.tscn")
	var puppet = leon_scene.instantiate()
	puppet.name = "Puppet"
	puppet.position = Vector2(580, 520)
	puppet.scale = Vector2(2.5, 2.5)
	root.add_child(puppet)
	puppet.owner = root

	# 3. Pivot Overlay Node (z_index = 10)
	var overlay = Node2D.new()
	overlay.name = "PivotOverlay"
	overlay.z_index = 10
	overlay.set_script(load("res://scripts/pivot_overlay.gd"))
	root.add_child(overlay)
	overlay.owner = root

	# 4. CanvasLayer UI
	var ui = CanvasLayer.new()
	ui.name = "UI"
	root.add_child(ui)
	ui.owner = root

	# Header Title
	var title = Label.new()
	title.text = "LEON 2D PUPPET RIG — PRODUCTION TEST HARNESS"
	title.position = Vector2(24, 16)
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(0.45, 0.85, 1.0)
	ui.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.text = "17 Bones • Neck/Shoulders/Elbows/Wrists/Hips/Knees/Ankles • Decoupled Face System"
	subtitle.position = Vector2(24, 42)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.modulate = Color(0.70, 0.75, 0.85)
	ui.add_child(subtitle)
	subtitle.owner = root

	# Top Quick-Pose Presets Bar
	var preset_bar = HBoxContainer.new()
	preset_bar.position = Vector2(24, 70)
	preset_bar.add_theme_constant_override("separation", 10)
	ui.add_child(preset_bar)
	preset_bar.owner = root

	var create_btn = func(text: String, method_name: String, parent: Node, arg: String = "") -> Button:
		var btn = Button.new()
		btn.text = text
		btn.add_theme_font_size_override("font_size", 11)
		var s_code = """extends Button
func _pressed() -> void:
	var harness = get_tree().current_scene
	if harness and harness.has_method("%s"):
		%s
"""
		var call_str = "harness." + method_name + "(\"" + arg + "\")" if arg != "" else "harness." + method_name + "()"
		var b_script = GDScript.new()
		b_script.source_code = s_code % [method_name, call_str]
		btn.set_script(b_script)
		parent.add_child(btn)
		btn.owner = root
		return btn

	create_btn.call("Rest Pose", "reset_to_rest", preset_bar)
	create_btn.call("Elbows / Knees Flex", "apply_pose_elbows_knees", preset_bar)
	create_btn.call("Arms Across Torso", "apply_pose_cross_arms", preset_bar)
	create_btn.call("Extreme Joint Stress", "apply_pose_extreme_stress", preset_bar)
	create_btn.call("Toggle Pivot Rings", "toggle_pivots", preset_bar)
	create_btn.call("▶ Auto Demo Loop", "toggle_auto_demo", preset_bar)

	# Left Bone Slider Panel
	var panel_l = PanelContainer.new()
	panel_l.position = Vector2(24, 110)
	panel_l.size = Vector2(270, 580)
	var sb_l = StyleBoxFlat.new()
	sb_l.bg_color = Color(0.12, 0.15, 0.20, 0.92)
	sb_l.border_width_left = 1; sb_l.border_width_right = 1; sb_l.border_width_top = 1; sb_l.border_width_bottom = 1
	sb_l.border_color = Color(0.25, 0.35, 0.50, 0.8)
	sb_l.corner_radius_top_left = 6; sb_l.corner_radius_top_right = 6
	sb_l.corner_radius_bottom_left = 6; sb_l.corner_radius_bottom_right = 6
	sb_l.content_margin_left = 12; sb_l.content_margin_right = 12
	sb_l.content_margin_top = 10; sb_l.content_margin_bottom = 10
	panel_l.add_theme_stylebox_override("panel", sb_l)
	ui.add_child(panel_l)
	panel_l.owner = root

	var scroll_l = ScrollContainer.new()
	scroll_l.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel_l.add_child(scroll_l)
	scroll_l.owner = root

	var vbox_sliders = VBoxContainer.new()
	vbox_sliders.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_sliders.add_theme_constant_override("separation", 6)
	scroll_l.add_child(vbox_sliders)
	vbox_sliders.owner = root

	var lbl_sliders_head = Label.new()
	lbl_sliders_head.text = "JOINT ROTATION CONTROLS"
	lbl_sliders_head.add_theme_font_size_override("font_size", 13)
	lbl_sliders_head.modulate = Color(1.0, 0.82, 0.4)
	vbox_sliders.add_child(lbl_sliders_head)
	lbl_sliders_head.owner = root

	var slider_specs = [
		{"name": "head", "label": "Head (-60° to +60°)", "min": -60.0, "max": 60.0},
		{"name": "neck", "label": "Neck (-30° to +30°)", "min": -30.0, "max": 30.0},
		{"name": "torso", "label": "Torso (-45° to +45°)", "min": -45.0, "max": 45.0},
		{"name": "arm_L_upper", "label": "L Shoulder (-180° to 180°)", "min": -180.0, "max": 180.0},
		{"name": "arm_L_lower", "label": "L Elbow (0° to 120°)", "min": 0.0, "max": 120.0},
		{"name": "hand_L", "label": "L Wrist (-90° to +90°)", "min": -90.0, "max": 90.0},
		{"name": "arm_R_upper", "label": "R Shoulder (-180° to 180°)", "min": -180.0, "max": 180.0},
		{"name": "arm_R_lower", "label": "R Elbow (0° to 120°)", "min": 0.0, "max": 120.0},
		{"name": "hand_R", "label": "R Wrist (-90° to +90°)", "min": -90.0, "max": 90.0},
		{"name": "leg_L_upper", "label": "L Hip (-90° to +90°)", "min": -90.0, "max": 90.0},
		{"name": "leg_L_lower", "label": "L Knee (0° to 110°)", "min": 0.0, "max": 110.0},
		{"name": "foot_L", "label": "L Ankle (-60° to +60°)", "min": -60.0, "max": 60.0},
		{"name": "leg_R_upper", "label": "R Hip (-90° to +90°)", "min": -90.0, "max": 90.0},
		{"name": "leg_R_lower", "label": "R Knee (0° to 110°)", "min": 0.0, "max": 110.0},
		{"name": "foot_R", "label": "R Ankle (-60° to +60°)", "min": -60.0, "max": 60.0},
		{"name": "tail", "label": "Tail (-60° to +60°)", "min": -60.0, "max": 60.0}
	]

	for spec in slider_specs:
		var lbl = Label.new()
		lbl.text = spec["label"]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.modulate = Color(0.85, 0.88, 0.92)
		vbox_sliders.add_child(lbl)
		lbl.owner = root

		var slider = HSlider.new()
		slider.min_value = spec["min"]
		slider.max_value = spec["max"]
		slider.value = 0.0
		slider.step = 1.0

		var s_script = GDScript.new()
		s_script.source_code = """extends HSlider
@export var bone_name: String = "%s"
func _value_changed(new_val: float) -> void:
	var harness = get_tree().current_scene
	if harness and harness.has_method("set_bone_angle"):
		harness.set_bone_angle(bone_name, new_val)
""" % spec["name"]
		slider.set_script(s_script)
		vbox_sliders.add_child(slider)
		slider.owner = root

	# Right Face Controller Panel
	var panel_r = PanelContainer.new()
	panel_r.position = Vector2(980, 110)
	panel_r.size = Vector2(275, 580)
	var sb_r = sb_l.duplicate()
	panel_r.add_theme_stylebox_override("panel", sb_r)
	ui.add_child(panel_r)
	panel_r.owner = root

	var vbox_r = VBoxContainer.new()
	vbox_r.add_theme_constant_override("separation", 10)
	panel_r.add_child(vbox_r)
	vbox_r.owner = root

	var lbl_expr_title = Label.new()
	lbl_expr_title.text = "FACE SYSTEM (DECOUPLED)"
	lbl_expr_title.add_theme_font_size_override("font_size", 13)
	lbl_expr_title.modulate = Color(0.35, 0.9, 0.6)
	vbox_r.add_child(lbl_expr_title)
	lbl_expr_title.owner = root

	var lbl_expr_sub = Label.new()
	lbl_expr_sub.text = "Expressions:"
	lbl_expr_sub.add_theme_font_size_override("font_size", 11)
	lbl_expr_sub.modulate = Color(0.8, 0.85, 0.9)
	vbox_r.add_child(lbl_expr_sub)
	lbl_expr_sub.owner = root

	var grid_expr = GridContainer.new()
	grid_expr.columns = 2
	grid_expr.add_theme_constant_override("h_separation", 6)
	grid_expr.add_theme_constant_override("v_separation", 6)
	vbox_r.add_child(grid_expr)
	grid_expr.owner = root

	var expressions = ["neutral", "happy", "angry", "sad", "shocked", "scared", "hurt", "confused", "smug", "laughing"]
	for expr_name in expressions:
		create_btn.call(expr_name.capitalize(), "apply_expression", grid_expr, expr_name)

	var lbl_eye_sub = Label.new()
	lbl_eye_sub.text = "Eye States:"
	lbl_eye_sub.add_theme_font_size_override("font_size", 11)
	lbl_eye_sub.modulate = Color(0.8, 0.85, 0.9)
	vbox_r.add_child(lbl_eye_sub)
	lbl_eye_sub.owner = root

	var grid_eyes = GridContainer.new()
	grid_eyes.columns = 2
	grid_eyes.add_theme_constant_override("h_separation", 6)
	grid_eyes.add_theme_constant_override("v_separation", 6)
	vbox_r.add_child(grid_eyes)
	grid_eyes.owner = root

	var eye_states = ["open", "blink", "wide", "closed"]
	for eye_name in eye_states:
		create_btn.call(eye_name.capitalize(), "apply_eye_state", grid_eyes, eye_name)

	# Hierarchy Summary
	var lbl_hier = Label.new()
	lbl_hier.text = "\nBone Hierarchy:\n• root (Pelvis)\n  ├── tail (Z=-2)\n  ├── leg_L_upper -> lower -> foot (Z=-1)\n  ├── leg_R_upper -> lower -> foot (Z=1)\n  └── torso (Z=0)\n      ├── arm_L_upper -> lower -> hand (Z=-1)\n      ├── arm_R_upper -> lower -> hand (Z=1)\n      └── neck -> head (Z=2)\n          └── Face (Controller)"
	lbl_hier.add_theme_font_size_override("font_size", 10)
	lbl_hier.modulate = Color(0.65, 0.72, 0.82)
	vbox_r.add_child(lbl_hier)
	lbl_hier.owner = root

	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack rig test scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/rig_test.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/rig_test.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/rig_test.tscn!")
	quit(0)
