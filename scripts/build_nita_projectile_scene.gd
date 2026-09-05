extends SceneTree

# Build Nita Projectile Scene (scenes/nita_projectile.tscn)
# Generates the authentic ground-piercing shockwave rupture projectile PackedScene.

func _init() -> void:
	print("[BUILD] Generating Nita Projectile Scene (scenes/nita_projectile.tscn)...")

	var root = Area2D.new()
	root.name = "NitaProjectile"
	root.set_script(load("res://scripts/nita_projectile.gd"))
	root.add_to_group("projectiles", true)

	# Collision Layer & Mask (layer 4 = projectiles (bit 3 = 8), mask 2 = targets/hit receivers (bit 1 = 2))
	root.collision_layer = 8
	root.collision_mask = 4 | 2

	# Collision Shape centered at (0, -36) covering character impact zone while grounded
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 28.0
	col.shape = shape
	col.position = Vector2(0, -36)
	root.add_child(col)
	col.owner = root

	# Ground Fissure Trail (Line2D running along the ground contact plane)
	var trail = Line2D.new()
	trail.name = "Trail"
	trail.width = 5.0
	trail.default_color = Color(0.0, 0.94, 1.0, 0.7)
	var grad = Gradient.new()
	grad.set_color(0, Color(0.0, 0.94, 1.0, 0.8))
	grad.set_color(1, Color(0.12, 0.12, 0.17, 0.0))
	trail.gradient = grad
	root.add_child(trail)
	trail.owner = root

	# Visuals Container
	var visuals = Node2D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	visuals.owner = root

	# Shockwave Sprite (centered at y = -36 so SVG ground line y=80 aligns with local y=0)
	var sprite = Sprite2D.new()
	sprite.name = "ShockwaveSprite"
	var tex = load("res://assets/nita/projectile/shockwave_rupture.svg")
	sprite.texture = tex
	sprite.position = Vector2(0, -36)
	visuals.add_child(sprite)
	sprite.owner = root

	var scene = PackedScene.new()
	var err = scene.pack(root)
	if err != OK:
		printerr("[BUILD] Failed to pack nita_projectile: ", err)
		quit(1)
		return

	err = ResourceSaver.save(scene, "res://scenes/nita_projectile.tscn")
	if err != OK:
		printerr("[BUILD] Failed to save scenes/nita_projectile.tscn: ", err)
		quit(1)
		return

	print("[BUILD] Successfully generated res://scenes/nita_projectile.tscn!")
	quit(0)
