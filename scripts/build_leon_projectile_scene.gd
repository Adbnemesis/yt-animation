extends SceneTree

func _init() -> void:
	print("[BUILD] Generating Leon Projectile Scene (scenes/leon_projectile.tscn)...")

	var root = Area2D.new()
	root.name = "LeonProjectile"
	root.set_script(load("res://scripts/leon_projectile.gd"))
	root.add_to_group("projectiles", true)

	# Collision Layer & Mask (layer 4 = projectiles, mask 2 = targets/hit receivers)
	root.collision_layer = 8
	root.collision_mask = 4 | 2

	# Collision Shape
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	root.add_child(col)
	col.owner = root

	# Trail (Line2D)
	var trail = Line2D.new()
	trail.name = "Trail"
	trail.width = 4.0
	trail.default_color = Color(0.0, 0.9, 1.0, 0.5)
	var grad = Gradient.new()
	grad.set_color(0, Color(0.0, 0.9, 1.0, 0.6))
	grad.set_color(1, Color(0.0, 0.9, 1.0, 0.0))
	trail.gradient = grad
	root.add_child(trail)
	trail.owner = root

	# Visuals
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	visuals.owner = root

	var sprite = Sprite2D.new()
	sprite.name = "BladeSprite"
	var tex = load("res://assets/leon/projectile/spinner_blade.svg")
	sprite.texture = tex
	visuals.add_child(sprite)
	sprite.owner = root

	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack leon_projectile: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/leon_projectile.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/leon_projectile.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/leon_projectile.tscn!")
	quit(0)
