@tool
extends SceneTree

func _init():
	print("Instantiating brawler_side_by_side.tscn...")
	var scene = load("res://scenes/brawler_side_by_side.tscn").instantiate()
	root.add_child(scene)
	
	# Position a camera so both brawlers are in view
	var cam = Camera2D.new()
	cam.position = Vector2(0, -60)
	cam.zoom = Vector2(2.0, 2.0)
	root.add_child(cam)
	
	for i in range(10):
		await process_frame
	
	var img = root.get_viewport().get_texture().get_image()
	img.save_png("/Users/talus/.gemini/antigravity-ide/brain/cb60eb4e-9e0b-41e6-b4c4-1c1b5e374298/previews/side_by_side_capture.png")
	print("CAPTURE COMPLETE!")
	quit()
