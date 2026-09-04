@tool
extends SceneTree

func _init() -> void:
	var sc = load("res://scenes/leon.tscn")
	var char = sc.instantiate()
	get_root().add_child(char)

	var anim = char.find_child("AnimPlayer")
	print("--- REST POSE SPRITES ---")
	for s_name in ["LegSpriteL", "FootSpriteL", "LegSpriteR", "FootSpriteR", "TorsoSprite"]:
		var s = char.find_child(s_name, true, false)
		if s:
			print(s_name, " visible=", s.visible, " z_index=", s.z_index, " gpos=", s.global_position, " size=", s.texture.get_size() if s.texture else "no_tex")

	print("\n--- WALK ANIMATION TIMESTAMPS ---")
	anim.play("walk")
	for t in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]:
		anim.seek(t, true)
		var fl = char.find_child("FootSpriteL", true, false)
		var fr = char.find_child("FootSpriteR", true, false)
		var ll = char.find_child("LegSpriteL", true, false)
		var lr = char.find_child("LegSpriteR", true, false)
		print("t=%.2f | FootL: %s (z=%d) | FootR: %s (z=%d) | LegL: %s | LegR: %s" % [
			t, str(fl.global_position), fl.z_index, str(fr.global_position), fr.z_index,
			str(ll.global_position), str(lr.global_position)
		])

	quit(0)
