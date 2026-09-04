@tool
extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Leon Master Showcase Scene (scenes/leon_showcase.tscn)...")
	var root = Node2D.new()
	root.name = "LeonShowcase"

	# Canvas 1280 x 840 displaying the Master Reference Sheet
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.08, 0.09, 0.12)
	bg.size = Vector2(1280, 840)
	root.add_child(bg)
	bg.owner = root

	var sheet_tex = load("res://assets/leon/sheets/leon_master_model_sheet.svg")
	var sprite = Sprite2D.new()
	sprite.name = "MasterSheetSprite"
	sprite.texture = sheet_tex
	sprite.centered = false
	sprite.position = Vector2.ZERO
	root.add_child(sprite)
	sprite.owner = root

	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack leon showcase: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/leon_showcase.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/leon_showcase.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/leon_showcase.tscn!")
	quit(0)
