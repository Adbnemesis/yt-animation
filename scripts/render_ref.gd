@tool
extends SceneTree

func _init() -> void:
	var tex = load("res://assets/brawlers/bo/references/bo_view_side.svg") as Texture2D
	if tex:
		var img = tex.get_image()
		if img:
			img.save_png("/Users/talus/.gemini/antigravity-ide/brain/cb60eb4e-9e0b-41e6-b4c4-1c1b5e374298/ref_side_view.png")
			print("Saved ref_side_view.png successfully!")
	quit(0)
