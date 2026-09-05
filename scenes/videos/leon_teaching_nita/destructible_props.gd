class_name DestructibleProps
extends Node2D

# Controls environmental props in the training ground:
# - Crate stack (wooden crates that shatter into debris and dust)
# - Training signpost (sign that snaps and topples into the dirt)
# - Dummy launch reaction on the chaotic 3rd blast

signal crates_destroyed()
signal sign_destroyed()
signal dummy_launched()

@onready var crate_stack: Node2D = get_node_or_null("CrateStack")
@onready var signpost: Node2D = get_node_or_null("TrainingSign")
@onready var debris_container: Node2D = get_node_or_null("DebrisContainer")

var crates_broken: bool = false
var sign_broken: bool = false

func _ready() -> void:
	if not debris_container:
		debris_container = Node2D.new()
		debris_container.name = "DebrisContainer"
		add_child(debris_container)

func destroy_crates(impact_pos: Vector2 = Vector2.ZERO) -> void:
	if crates_broken:
		return
	crates_broken = true
	crates_destroyed.emit()

	if not crate_stack:
		return

	# Hide intact crates
	crate_stack.visible = false

	# Spawn flying wood planks and splinters
	var wood_textures = [
		preload("res://assets/props/prop_plank_wide_01.png"),
		preload("res://assets/props/prop_plank_tall_01.png"),
		preload("res://assets/vfx/vfx_debris_wood_01.png"),
		preload("res://assets/vfx/vfx_debris_wood_02.png"),
		preload("res://assets/vfx/vfx_debris_wood_03.png")
	]

	var puff_texture = preload("res://assets/vfx/vfx_puff_round_01.png")

	# Dust puffs
	for i in range(4):
		var puff = Sprite2D.new()
		puff.texture = puff_texture
		puff.position = crate_stack.position + Vector2(randf_range(-40, 40), randf_range(-50, 10))
		puff.scale = Vector2(0.4, 0.4)
		puff.modulate = Color(0.9, 0.85, 0.75, 0.8)
		debris_container.add_child(puff)

		var tw_puff = create_tween().set_parallel(true)
		tw_puff.tween_property(puff, "scale", Vector2(1.2, 1.2), 0.5).set_ease(Tween.EASE_OUT)
		tw_puff.tween_property(puff, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
		tw_puff.chain().tween_callback(puff.queue_free)

	# Flying wood fragments
	for i in range(8):
		var frag = Sprite2D.new()
		frag.texture = wood_textures[i % wood_textures.size()]
		frag.position = crate_stack.position + Vector2(randf_range(-30, 30), randf_range(-60, 0))
		frag.scale = Vector2(0.6, 0.6)
		debris_container.add_child(frag)

		var throw_x = randf_range(60.0, 220.0) * (1.0 if randf() > 0.3 else -1.0)
		var throw_y = randf_range(-180.0, -90.0)
		var target_pos = frag.position + Vector2(throw_x, throw_y + 120.0)
		var rot_target = randf_range(-6.0, 6.0)

		var tw_frag = create_tween().set_parallel(true)
		tw_frag.tween_property(frag, "position:x", target_pos.x, 0.65).set_ease(Tween.EASE_OUT)
		tw_frag.tween_property(frag, "position:y", crate_stack.position.y + randf_range(-5, 5), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_frag.tween_property(frag, "rotation", rot_target, 0.65)
		tw_frag.tween_property(frag, "modulate:a", 0.7, 0.65)

func destroy_sign(impact_pos: Vector2 = Vector2.ZERO) -> void:
	if sign_broken:
		return
	sign_broken = true
	sign_destroyed.emit()

	if not signpost:
		return

	# Dramatic tilt and snap animation
	var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(signpost, "rotation", 1.25, 0.45)
	tw.parallel().tween_property(signpost, "position:y", signpost.position.y + 15.0, 0.45)

	# Dust puff at the base of the broken sign
	var puff = Sprite2D.new()
	puff.texture = preload("res://assets/vfx/vfx_puff_round_02.png")
	puff.position = signpost.position + Vector2(0, -10)
	puff.scale = Vector2(0.5, 0.5)
	puff.modulate = Color(0.85, 0.8, 0.7, 0.9)
	debris_container.add_child(puff)

	var tw_puff = create_tween().set_parallel(true)
	tw_puff.tween_property(puff, "scale", Vector2(1.1, 1.1), 0.4).set_ease(Tween.EASE_OUT)
	tw_puff.tween_property(puff, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tw_puff.chain().tween_callback(puff.queue_free)

func launch_dummy(dummy_node: Node2D) -> void:
	if not dummy_node:
		return
	dummy_launched.emit()

	# Launch dummy high into the sky spinning comedically
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dummy_node, "position:x", dummy_node.position.x + 180.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(dummy_node, "position:y", -200.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(dummy_node, "rotation", 7.2, 0.9)
	tw.tween_property(dummy_node, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
