@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Building demo.tscn...")

	var demo_root = Node2D.new()
	demo_root.name = "DemoRoot"

	# 1. Background (CanvasLayer / ColorRect)
	var bg_layer = CanvasLayer.new()
	bg_layer.name = "BackgroundLayer"
	bg_layer.layer = -10
	demo_root.add_child(bg_layer)
	bg_layer.owner = demo_root

	var bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.12, 0.14, 0.18, 1.0) # Sleek cartoon dark slate
	bg_layer.add_child(bg_rect)
	bg_rect.owner = demo_root

	# Grid / Ground shadow line on background
	var bg_grid = Line2D.new()
	bg_grid.name = "HorizonLine"
	bg_grid.points = PackedVector2Array([Vector2(0, 520), Vector2(1152, 520)])
	bg_grid.default_color = Color(0.18, 0.22, 0.28, 1.0)
	bg_grid.width = 3.0
	bg_layer.add_child(bg_grid)
	bg_grid.owner = demo_root

	# 2. Ground StaticBody2D
	var ground = StaticBody2D.new()
	ground.name = "Ground"
	ground.position = Vector2(576, 560)
	demo_root.add_child(ground)
	ground.owner = demo_root

	var ground_shape = CollisionShape2D.new()
	ground_shape.name = "CollisionShape2D"
	var box = RectangleShape2D.new()
	box.size = Vector2(1400, 80)
	ground_shape.shape = box
	ground.add_child(ground_shape)
	ground_shape.owner = demo_root

	# Visual representation of ground
	var ground_visual = ColorRect.new()
	ground_visual.name = "GroundVisual"
	ground_visual.position = Vector2(-700, -40)
	ground_visual.size = Vector2(1400, 200)
	ground_visual.color = Color(0.18, 0.20, 0.26, 1.0)
	ground.add_child(ground_visual)
	ground_visual.owner = demo_root

	# Ground top highlight strip
	var ground_top = ColorRect.new()
	ground_top.name = "GroundTopStrip"
	ground_top.position = Vector2(-700, -40)
	ground_top.size = Vector2(1400, 6)
	ground_top.color = Color(0.24, 0.58, 0.92, 1.0) # Hero cyan strip
	ground.add_child(ground_top)
	ground_top.owner = demo_root

	# Left & Right boundary walls (to prevent falling off stage in manual mode)
	var wall_l = StaticBody2D.new()
	wall_l.name = "WallLeft"
	wall_l.position = Vector2(20, 300)
	demo_root.add_child(wall_l)
	wall_l.owner = demo_root
	var wall_l_shape = CollisionShape2D.new()
	var wall_box = RectangleShape2D.new()
	wall_box.size = Vector2(40, 800)
	wall_l_shape.shape = wall_box
	wall_l.add_child(wall_l_shape)
	wall_l_shape.owner = demo_root

	var wall_r = StaticBody2D.new()
	wall_r.name = "WallRight"
	wall_r.position = Vector2(1132, 300)
	demo_root.add_child(wall_r)
	wall_r.owner = demo_root
	var wall_r_shape = CollisionShape2D.new()
	wall_r_shape.shape = wall_box
	wall_r.add_child(wall_r_shape)
	wall_r_shape.owner = demo_root

	# 3. Instance Character
	var char_packed = load("res://scenes/character.tscn")
	var character = char_packed.instantiate()
	character.name = "Character"
	character.position = Vector2(576, 520)
	demo_root.add_child(character)
	character.owner = demo_root

	# 4. DemoDirector
	var director = Node.new()
	director.name = "DemoDirector"
	director.set_script(load("res://scripts/demo_director.gd"))
	director.set("character", character)
	demo_root.add_child(director)
	director.owner = demo_root

	# 5. Debug Overlay (CanvasLayer)
	var overlay = CanvasLayer.new()
	overlay.name = "DebugOverlay"
	overlay.set_script(load("res://scripts/debug_overlay.gd"))
	demo_root.add_child(overlay)
	overlay.owner = demo_root

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(24, 24)
	panel.size = Vector2(440, 310)
	overlay.add_child(panel)
	panel.owner = demo_root

	# Style panel background
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.14, 0.90)
	sb.border_width_bottom = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_color = Color(0.3, 0.5, 0.8, 0.7)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)

	var margin = MarginContainer.new()
	margin.name = "Margin"
	panel.add_child(margin)
	margin.owner = demo_root

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	vbox.owner = demo_root

	var create_label = func(l_name: String, text: String, font_size: int, col: Color) -> Label:
		var lbl = Label.new()
		lbl.name = l_name
		lbl.text = text
		lbl.add_theme_font_size_override("font_size", font_size)
		lbl.modulate = col
		vbox.add_child(lbl)
		lbl.owner = demo_root
		return lbl

	create_label.call("HeaderTitle", "BRAWL ANIMATION PROTOTYPE", 16, Color(0.4, 0.8, 1.0))
	create_label.call("LabelMode", "Mode: [AUTO DEMO]", 13, Color(0.3, 1.0, 0.5))
	create_label.call("LabelAnim", "Current animation: idle", 13, Color(1, 1, 1))
	create_label.call("LabelState", "Current state: IDLE", 13, Color(1, 1, 1))
	create_label.call("LabelFace", "Facial expression: neutral", 13, Color(0.9, 0.7, 1.0))
	create_label.call("LabelPos", "Position: (576.0, 520.0)", 13, Color(0.85, 0.85, 0.85))
	create_label.call("LabelVel", "Velocity: (0.0, 0.0)", 13, Color(0.85, 0.85, 0.85))
	create_label.call("LabelGround", "Grounded: YES", 13, Color(0.85, 0.85, 0.85))
	create_label.call("LabelFacing", "Facing direction: RIGHT (+1)", 13, Color(0.85, 0.85, 0.85))
	create_label.call("LabelImpact", "", 13, Color(1.0, 0.3, 0.3))

	# Divider line
	var sep = HSeparator.new()
	vbox.add_child(sep)
	sep.owner = demo_root

	create_label.call("LabelControls", "Controls: [A/D] Move | [Shift] Run | [Space] Jump | [J] Attack | [K] Hit | [L] Knockback\n[1-0] Inspect Anims | [O] Toggle Loop | [F1-F7] Expressions | [Tab] Toggle Mode", 11, Color(0.7, 0.75, 0.8))

	# Add hook in demo_root script to connect overlay setup
	var demo_script = GDScript.new()
	demo_script.source_code = """extends Node2D

func _ready() -> void:
	var character = $Character
	var director = $DemoDirector
	var overlay = $DebugOverlay
	if overlay and character and director:
		overlay.setup(character, director)
"""
	demo_root.set_script(demo_script)

	# Save demo scene
	var scene = PackedScene.new()
	var err = scene.pack(demo_root)
	if err != OK:
		printerr("[BUILD] Failed to pack demo scene: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/demo.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save demo scene: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/demo.tscn!")
	quit(0)
