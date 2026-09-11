class_name DestructibleProps
extends Node2D

# Authoritative environmental destructible props system for "Leon Tries to Teach Nita How to Fight"
# Direct projectile collision detection via PropHitReceiver:
# Every reaction/destruction occurs at the EXACT collision position and timestamp.

signal crates_destroyed()
signal sign_destroyed()
signal target_1_destroyed()
signal target_2_destroyed()
signal dummy_launched()

@onready var crate_stack: Area2D = get_node_or_null("CrateStack")
@onready var signpost: Area2D = get_node_or_null("TrainingSign")
@onready var practice_target_1: Area2D = get_node_or_null("PracticeTarget1")
@onready var practice_target_2: Area2D = get_node_or_null("PracticeTarget2")
@onready var debris_container: Node2D = get_node_or_null("DebrisContainer")

var crates_broken: bool = false
var sign_broken: bool = false
var target_1_broken: bool = false
var target_2_broken: bool = false
var dummy_launched_flag: bool = false
var dummy_launch_armed: bool = false

var crates_vulnerable: bool = false
var sign_vulnerable: bool = false
var target_1_vulnerable: bool = false
var target_2_vulnerable: bool = false

var wood_textures = [
	preload("res://assets/props/prop_plank_wide_01.png"),
	preload("res://assets/props/prop_plank_tall_01.png"),
	preload("res://assets/vfx/vfx_debris_wood_01.png"),
	preload("res://assets/vfx/vfx_debris_wood_02.png"),
	preload("res://assets/vfx/vfx_debris_wood_03.png")
]
var puff_texture = preload("res://assets/vfx/vfx_puff_round_01.png")

func _ready() -> void:
	if not debris_container:
		debris_container = Node2D.new()
		debris_container.name = "DebrisContainer"
		add_child(debris_container)

	# Connect hit signals from authoritative collision receivers
	if crate_stack and crate_stack.has_signal("hit_received"):
		crate_stack.hit_received.connect(_on_crate_stack_hit)
	if signpost and signpost.has_signal("hit_received"):
		signpost.hit_received.connect(_on_signpost_hit)
	if practice_target_1 and practice_target_1.has_signal("hit_received"):
		practice_target_1.hit_received.connect(_on_target_1_hit)
	if practice_target_2 and practice_target_2.has_signal("hit_received"):
		practice_target_2.hit_received.connect(_on_target_2_hit)

	# Initially hide and disable challenge practice targets until Leon establishes them
	_set_target_active(practice_target_1, false)
	_set_target_active(practice_target_2, false)

func _set_target_active(target_node: Area2D, active: bool) -> void:
	if not target_node:
		return
	target_node.visible = active
	var col = target_node.get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", not active)

func setup_challenge_targets() -> void:
	# Leon sets up controlled challenge targets with squash-and-stretch pop-in and dust puffs
	target_1_vulnerable = true
	target_2_vulnerable = true
	if practice_target_1 and not target_1_broken:
		_set_target_active(practice_target_1, true)
		practice_target_1.scale = Vector2.ZERO
		var tw1 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw1.tween_property(practice_target_1, "scale", Vector2(1.0, 1.0), 0.35)
		if has_node("/root/VFXManager"):
			get_node("/root/VFXManager").spawn_vfx("DUST_PUFF", practice_target_1.global_position + Vector2(0, -5))

	if practice_target_2 and not target_2_broken:
		_set_target_active(practice_target_2, true)
		practice_target_2.scale = Vector2.ZERO
		var tw2 = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw2.tween_interval(0.12)
		tw2.tween_property(practice_target_2, "scale", Vector2(1.0, 1.0), 0.35)
		tw2.chain().tween_callback(func():
			if has_node("/root/VFXManager") and practice_target_2:
				get_node("/root/VFXManager").spawn_vfx("DUST_PUFF", practice_target_2.global_position + Vector2(0, -5))
		)

func arm_chaos() -> void:
	crates_vulnerable = true
	sign_vulnerable = true

func _on_crate_stack_hit(hit_data: RefCounted) -> void:
	if not crates_vulnerable:
		return
	var hit_pos = hit_data.position if "position" in hit_data else crate_stack.global_position
	destroy_crates(hit_pos)

func _on_signpost_hit(hit_data: RefCounted) -> void:
	if not sign_vulnerable:
		return
	var hit_pos = hit_data.position if "position" in hit_data else signpost.global_position
	destroy_sign(hit_pos)

func _on_target_1_hit(hit_data: RefCounted) -> void:
	if not target_1_vulnerable:
		return
	var hit_pos = hit_data.position if "position" in hit_data else practice_target_1.global_position
	destroy_target_1(hit_pos)

func _on_target_2_hit(hit_data: RefCounted) -> void:
	if not target_2_vulnerable:
		return
	var hit_pos = hit_data.position if "position" in hit_data else practice_target_2.global_position
	destroy_target_2(hit_pos)

func destroy_crates(impact_pos: Vector2 = Vector2.ZERO) -> void:
	if crates_broken:
		return
	crates_broken = true
	crates_destroyed.emit()

	if not crate_stack:
		return

	crate_stack.visible = false
	var col = crate_stack.get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)

	var spawn_center = impact_pos if impact_pos != Vector2.ZERO else (crate_stack.global_position + Vector2(0, -30))

	# Spawn hit impact spark and dust via VFXManager at collision position
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.spawn_vfx("HIT_IMPACT", spawn_center)
		vfx.spawn_vfx("DUST_PUFF", crate_stack.global_position + Vector2(0, -10))

	# Dust puffs
	for i in range(6):
		var puff = Sprite2D.new()
		puff.texture = puff_texture
		puff.position = to_local(spawn_center) + Vector2(randf_range(-45, 45), randf_range(-40, 20))
		puff.scale = Vector2(0.45, 0.45)
		puff.modulate = Color(0.9, 0.85, 0.75, 0.85)
		debris_container.add_child(puff)

		var tw_puff = create_tween().set_parallel(true)
		tw_puff.tween_property(puff, "scale", Vector2(1.3, 1.3), 0.55).set_ease(Tween.EASE_OUT)
		tw_puff.tween_property(puff, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN)
		tw_puff.chain().tween_callback(puff.queue_free)

	# Flying wood fragments exploding outward from collision point
	for i in range(12):
		var frag = Sprite2D.new()
		frag.texture = wood_textures[i % wood_textures.size()]
		frag.position = to_local(spawn_center) + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		frag.scale = Vector2(0.65, 0.65)
		debris_container.add_child(frag)

		var throw_x = randf_range(80.0, 260.0) * (1.0 if randf() > 0.25 else -1.0)
		var throw_y = randf_range(-220.0, -110.0)
		var target_pos = frag.position + Vector2(throw_x, throw_y + 140.0)
		var rot_target = randf_range(-9.0, 9.0)

		var tw_frag = create_tween().set_parallel(true)
		tw_frag.tween_property(frag, "position:x", target_pos.x, 0.68).set_ease(Tween.EASE_OUT)
		tw_frag.tween_property(frag, "position:y", crate_stack.position.y + randf_range(-6, 6), 0.68).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_frag.tween_property(frag, "rotation", rot_target, 0.68)
		tw_frag.tween_property(frag, "modulate:a", 0.8, 0.68)

func destroy_sign(impact_pos: Vector2 = Vector2.ZERO) -> void:
	if sign_broken:
		return
	sign_broken = true
	sign_destroyed.emit()

	if not signpost:
		return

	var col = signpost.get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)

	var spawn_center = impact_pos if impact_pos != Vector2.ZERO else (signpost.global_position + Vector2(0, -35))

	# Impact flash at exact collision position
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.spawn_vfx("HIT_IMPACT", spawn_center)
		vfx.spawn_vfx("DUST_PUFF", signpost.global_position)

	# Dramatic tilt and snap animation
	var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(signpost, "rotation", 1.35, 0.4)
	tw.parallel().tween_property(signpost, "position:y", signpost.position.y + 16.0, 0.4)

	# Dust puff at base
	var puff = Sprite2D.new()
	puff.texture = preload("res://assets/vfx/vfx_puff_round_02.png")
	puff.position = signpost.position + Vector2(0, -10)
	puff.scale = Vector2(0.55, 0.55)
	puff.modulate = Color(0.85, 0.8, 0.7, 0.9)
	debris_container.add_child(puff)

	var tw_puff = create_tween().set_parallel(true)
	tw_puff.tween_property(puff, "scale", Vector2(1.2, 1.2), 0.45).set_ease(Tween.EASE_OUT)
	tw_puff.tween_property(puff, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
	tw_puff.chain().tween_callback(puff.queue_free)

func destroy_target_1(impact_pos: Vector2 = Vector2.ZERO) -> void:
	if target_1_broken:
		return
	target_1_broken = true
	target_1_destroyed.emit()

	if not practice_target_1:
		return

	_set_target_active(practice_target_1, false)

	var spawn_center = impact_pos if impact_pos != Vector2.ZERO else (practice_target_1.global_position + Vector2(0, -30))

	# Impact VFX at projectile collision point
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.spawn_vfx("HIT_IMPACT", spawn_center)
		vfx.spawn_vfx("DUST_PUFF", practice_target_1.global_position + Vector2(0, -5))

	# 6 flying wood target splinters
	for i in range(6):
		var frag = Sprite2D.new()
		frag.texture = wood_textures[i % wood_textures.size()]
		frag.position = to_local(spawn_center) + Vector2(randf_range(-15, 15), randf_range(-20, 10))
		frag.scale = Vector2(0.5, 0.5)
		debris_container.add_child(frag)

		var throw_x = randf_range(60.0, 180.0)
		var throw_y = randf_range(-160.0, -80.0)
		var target_pos = frag.position + Vector2(throw_x, throw_y + 110.0)

		var tw_frag = create_tween().set_parallel(true)
		tw_frag.tween_property(frag, "position:x", target_pos.x, 0.55).set_ease(Tween.EASE_OUT)
		tw_frag.tween_property(frag, "position:y", practice_target_1.position.y + randf_range(-4, 4), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_frag.tween_property(frag, "rotation", randf_range(-6.0, 6.0), 0.55)
		tw_frag.tween_property(frag, "modulate:a", 0.7, 0.55)

func destroy_target_2(impact_pos: Vector2 = Vector2.ZERO) -> void:
	if target_2_broken:
		return
	target_2_broken = true
	target_2_destroyed.emit()

	if not practice_target_2:
		return

	_set_target_active(practice_target_2, false)

	var spawn_center = impact_pos if impact_pos != Vector2.ZERO else (practice_target_2.global_position + Vector2(0, -25))

	# Impact VFX at projectile collision point
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.spawn_vfx("HIT_IMPACT", spawn_center)
		vfx.spawn_vfx("DUST_PUFF", practice_target_2.global_position + Vector2(0, -5))

	# 8 flying wood crate splinters
	for i in range(8):
		var frag = Sprite2D.new()
		frag.texture = wood_textures[i % wood_textures.size()]
		frag.position = to_local(spawn_center) + Vector2(randf_range(-15, 15), randf_range(-20, 10))
		frag.scale = Vector2(0.55, 0.55)
		debris_container.add_child(frag)

		var throw_x = randf_range(70.0, 210.0) * (1.0 if randf() > 0.2 else -1.0)
		var throw_y = randf_range(-180.0, -90.0)
		var target_pos = frag.position + Vector2(throw_x, throw_y + 120.0)

		var tw_frag = create_tween().set_parallel(true)
		tw_frag.tween_property(frag, "position:x", target_pos.x, 0.58).set_ease(Tween.EASE_OUT)
		tw_frag.tween_property(frag, "position:y", practice_target_2.position.y + randf_range(-4, 4), 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_frag.tween_property(frag, "rotation", randf_range(-7.0, 7.0), 0.58)
		tw_frag.tween_property(frag, "modulate:a", 0.75, 0.58)

func arm_dummy_launch(dummy_node: Node2D) -> void:
	dummy_launch_armed = true
	if dummy_node and dummy_node.has_signal("hit_received"):
		if not dummy_node.hit_received.is_connected(_on_dummy_hit_for_launch):
			dummy_node.hit_received.connect(_on_dummy_hit_for_launch.bind(dummy_node), CONNECT_ONE_SHOT)

func _on_dummy_hit_for_launch(hit_data: RefCounted, dummy_node: Node2D) -> void:
	if not dummy_launched_flag:
		var hit_pos = hit_data.position if "position" in hit_data else dummy_node.global_position
		launch_dummy(dummy_node, hit_pos)

func launch_dummy(dummy_node: Node2D, impact_pos: Vector2 = Vector2.ZERO) -> void:
	if dummy_launched_flag or not dummy_node:
		return
	dummy_launched_flag = true
	dummy_launched.emit()

	var spawn_center = impact_pos if impact_pos != Vector2.ZERO else (dummy_node.global_position + Vector2(0, -35))

	# Big smoke burst and impact flash at launch point
	if has_node("/root/VFXManager"):
		var vfx = get_node("/root/VFXManager")
		vfx.spawn_vfx("SMOKE_BOMB", spawn_center)
		vfx.spawn_vfx("HIT_IMPACT", spawn_center + Vector2(0, -10))

	# Launch dummy high into the sky spinning comedically
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dummy_node, "position:x", dummy_node.position.x + 200.0, 0.85).set_ease(Tween.EASE_OUT)
	tw.tween_property(dummy_node, "position:y", -240.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(dummy_node, "rotation", 8.0, 0.85)
	tw.tween_property(dummy_node, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_IN)

func spawn_lingering_smoke(center_pos: Vector2) -> void:
	for i in range(4):
		var puff = Sprite2D.new()
		puff.texture = puff_texture
		puff.position = to_local(center_pos) + Vector2(randf_range(-30, 30), randf_range(-15, 10))
		puff.scale = Vector2(0.25, 0.25)
		puff.modulate = Color(0.85, 0.85, 0.85, 0.6)
		debris_container.add_child(puff)

		var tw = create_tween().set_parallel(true)
		var delay = i * 0.22
		tw.tween_interval(delay)
		tw.tween_property(puff, "position:y", puff.position.y - 45.0, 1.3).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "position:x", puff.position.x + randf_range(-15, 15), 1.3)
		tw.tween_property(puff, "scale", Vector2(0.7, 0.7), 1.3)
		tw.tween_property(puff, "modulate:a", 0.0, 1.3).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(puff.queue_free)

