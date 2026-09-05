@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating scenes/nita_walk_test.tscn...")

	var root = Node2D.new()
	root.name = "NitaWalkTest"
	root.set_script(load("res://scripts/nita_walk_test.gd"))

	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1152, 648)
	bg.color = Color(0.09, 0.11, 0.15, 1.0)
	root.add_child(bg)
	bg.owner = root

	# Title UI
	var title = Label.new()
	title.name = "Title"
	title.text = "NITA & LEON DUAL WALK TEST (LOCOMOTION RIG SYNC)"
	title.position = Vector2(40, 30)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	root.add_child(title)
	title.owner = root

	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "6-Phase Classical Walk Cycle • Skirt Physics & Hip Sway • Matching Stride & Height"
	subtitle.position = Vector2(40, 65)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.73, 0.82, 1.0))
	root.add_child(subtitle)
	subtitle.owner = root

	# Ground Line
	var ground = Line2D.new()
	ground.name = "GroundLine"
	ground.default_color = Color(0.20, 0.55, 0.85, 0.8)
	ground.width = 3.0
	ground.add_point(Vector2(0, 520))
	ground.add_point(Vector2(1152, 520))
	root.add_child(ground)
	ground.owner = root

	# Nita Actor
	var nita_actor = load("res://scenes/actor_nita.tscn").instantiate()
	nita_actor.name = "NitaActor"
	nita_actor.position = Vector2(250, 520)
	root.add_child(nita_actor)
	nita_actor.owner = root

	# Leon Actor
	var leon_actor = load("res://scenes/videos/leon_elevator/actor_leon.tscn").instantiate()
	leon_actor.name = "LeonActor"
	leon_actor.position = Vector2(400, 520)
	root.add_child(leon_actor)
	leon_actor.owner = root

	var scn = PackedScene.new()
	scn.pack(root)
	ResourceSaver.save(scn, "res://scenes/nita_walk_test.tscn")
	print("  -> Saved scenes/nita_walk_test.tscn successfully!")
	quit(0)
