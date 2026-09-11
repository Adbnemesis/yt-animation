@tool
extends SceneTree

func _init():
	var vp = SubViewport.new()
	vp.size = Vector2i(800, 800)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	
	# Dark background
	var bg = ColorRect.new()
	bg.size = Vector2(800, 800)
	bg.color = Color("#181a20")
	vp.add_child(bg)
	
	# Camera
	var cam = Camera2D.new()
	cam.position = Vector2(0, -45)
	cam.zoom = Vector2(4.0, 4.0)
	vp.add_child(cam)
	
	# Load Leon
	var leon = load("res://scenes/leon.tscn").instantiate()
	vp.add_child(leon)
	
	for i in range(5):
		await process_frame
		
	var img = vp.get_texture().get_image()
	img.save_png("/Users/talus/.gemini/antigravity-ide/brain/cb60eb4e-9e0b-41e6-b4c4-1c1b5e374298/previews/godot_leon_preview.png")
	print("GODOT LEON RENDERED SUCCESSFULLY!")
	
	# Now Nita
	leon.queue_free()
	var nita = load("res://scenes/nita_side.tscn").instantiate()
	vp.add_child(nita)
	
	for i in range(5):
		await process_frame
		
	var img_nita = vp.get_texture().get_image()
	img_nita.save_png("/Users/talus/.gemini/antigravity-ide/brain/cb60eb4e-9e0b-41e6-b4c4-1c1b5e374298/previews/godot_nita_preview.png")
	print("GODOT NITA RENDERED SUCCESSFULLY!")
	quit()
