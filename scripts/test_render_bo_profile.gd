@tool
extends SceneTree

# Quick visual alignment test for Bo side view
func _init() -> void:
	print("=== Rendering Bo Visual Test ===")
	var vp = SubViewport.new()
	vp.size = Vector2i(800, 800)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var bg = ColorRect.new()
	bg.size = Vector2(800, 800)
	bg.color = Color("#181a20")
	vp.add_child(bg)

	var cam = Camera2D.new()
	cam.position = Vector2(0, -70)
	cam.zoom = Vector2(2.35, 2.35)
	vp.add_child(cam)

	var bo = load("res://scenes/brawler_bo.tscn").instantiate()
	vp.add_child(bo)

	for i in range(10):
		await process_frame

	var img = vp.get_texture().get_image()
	if img:
		img.save_png("/Users/talus/.gemini/antigravity-ide/brain/cb60eb4e-9e0b-41e6-b4c4-1c1b5e374298/bo_test_align.png")
		print("Saved bo_test_align.png")

	quit(0)
