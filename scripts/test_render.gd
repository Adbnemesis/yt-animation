@tool
extends SceneTree

func _init() -> void:
	print("[RENDER] Rendering SVG sheets to PNGs using Godot Viewport...")
	# We can setup a sub-viewport, add a sprite with texture, and save the image
	# Since headless dummy renderer doesn't render viewports, we can use movie maker or a swift helper
	# Let's check if we can run movie maker for each or compile a master gallery scene
	quit(0)
