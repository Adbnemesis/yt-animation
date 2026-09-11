class_name TestBoAttack
extends GdUnitTestSuite

# Bo Basic Attack (BO_BASIC_ATTACK) + Arrow Projectile — Stage 1 Validation
# Covers: event sequence, arrow volley count/direction/origin, direction
# preservation, projectile causality (arrow reaches target BEFORE hit),
# one hit per projectile, attack-while-moving, and repeated attacks.

const BO_ARENA_SCENE := "res://scenes/test_bo_arena.tscn"
const BO_COMBAT_SCENE := "res://scenes/bo_combat_test.tscn"


func _get_arrows(arena: Node) -> Array:
	var found: Array = []
	for child in arena.get_children():
		if child is Area2D and child.is_in_group("projectiles"):
			found.append(child)
	return found


func _event_names(events: Array) -> Array:
	return events.map(func(e): return e[0])


func test_attack_event_sequence_and_projectile_count() -> void:
	var runner = scene_runner(BO_ARENA_SCENE)
	var bo = runner.scene().get_node("BrawlerBo") as BrawlerBase
	await runner.simulate_frames(18)

	var events: Array = []
	bo.game_event_emitted.connect(func(ev_name: String, _data: Dictionary):
		events.append([ev_name])
	)

	assert_that(bo.attack()).is_true()
	await runner.simulate_frames(45)

	var names = _event_names(events)
	var idx_start := names.find(BrawlerEvents.EVENT_ATTACK_START)
	var idx_release := names.find(BrawlerEvents.EVENT_ATTACK_RELEASE)
	var idx_spawn := names.find(BrawlerEvents.EVENT_PROJECTILE_SPAWN)
	var idx_follow := names.find(BrawlerEvents.EVENT_ATTACK_FOLLOW_THROUGH)
	var idx_end := names.find(BrawlerEvents.EVENT_ATTACK_END)

	assert_int(idx_start).is_greater_equal(0)
	assert_int(idx_release).is_greater(idx_start)
	assert_int(idx_spawn).is_greater_equal(idx_release)
	assert_int(idx_follow).is_greater(idx_spawn)
	assert_int(idx_end).is_greater(idx_follow)

	# Exactly one PROJECTILE_SPAWN event per arrow in the volley (3 arrows)
	var spawn_count := 0
	for n in names:
		if n == BrawlerEvents.EVENT_PROJECTILE_SPAWN:
			spawn_count += 1
	assert_int(spawn_count).is_equal(3)

	# No duplicate ATTACK_START / ATTACK_END events
	var start_count := 0
	for n in names:
		if n == BrawlerEvents.EVENT_ATTACK_START:
			start_count += 1
	assert_int(start_count).is_equal(1)

	var end_count := 0
	for n in names:
		if n == BrawlerEvents.EVENT_ATTACK_END:
			end_count += 1
	assert_int(end_count).is_equal(1)


func test_arrow_volley_count_speed_and_direction_right() -> void:
	var runner = scene_runner(BO_ARENA_SCENE)
	var arena = runner.scene()
	var bo = arena.get_node("BrawlerBo") as BrawlerBase
	await runner.simulate_frames(18)

	var spawn_positions: Array[Vector2] = []
	var spawn_frames: Array = []
	bo.game_event_emitted.connect(func(ev_name: String, data: Dictionary):
		if ev_name == BrawlerEvents.EVENT_PROJECTILE_SPAWN:
			spawn_positions.append(data["position"])
			spawn_frames.append(Engine.get_physics_frames())
	)

	assert_that(bo.attack()).is_true()
	await runner.simulate_frames(25)

	var arrows = _get_arrows(arena)
	assert_int(arrows.size()).is_equal(3)
	assert_int(spawn_positions.size()).is_equal(3)

	# Staggered volley: arrows are released with a small gap (burst interval),
	# all within ~0.2s of the release frame — never simultaneously.
	assert_int(spawn_frames[1] - spawn_frames[0]).is_greater_equal(1)
	assert_int(spawn_frames[2] - spawn_frames[1]).is_greater_equal(1)
	assert_int(spawn_frames[2] - spawn_frames[0]).is_less_equal(12)

	for arrow in arrows:
		# Deterministic config-sourced tuning
		assert_float(arrow.speed).is_equal(620.0)
		assert_float(arrow.max_range).is_equal(520.0)
		assert_float(arrow.damage).is_equal(40.0)
		# Facing RIGHT: arrows travel right, spawned from the bow socket
		# (in front of Bo's body center, at bow height above the feet)
		assert_float(arrow.direction.x).is_greater(0.0)
	for p in spawn_positions:
		assert_float(p.x).is_greater(bo.global_position.x)
		assert_float(p.y).is_less(bo.global_position.y)


func test_arrow_direction_left_and_preserved_after_turn() -> void:
	var runner = scene_runner(BO_ARENA_SCENE)
	var arena = runner.scene()
	var bo = arena.get_node("BrawlerBo") as BrawlerBase
	await runner.simulate_frames(18)

	# Face LEFT and fire
	bo.movement_controller.facing_direction = -1
	await runner.simulate_frames(2)
	assert_that(bo.attack()).is_true()
	await runner.simulate_frames(25)

	var arrows = _get_arrows(arena)
	assert_int(arrows.size()).is_equal(3)
	for arrow in arrows:
		assert_float(arrow.direction.x).is_less(0.0)

	# Turn Bo back to the right while arrows are in flight:
	# arrows must NOT change direction after spawn.
	bo.movement_controller.facing_direction = 1
	await runner.simulate_frames(5)
	for arrow in arrows:
		if is_instance_valid(arrow):
			assert_float(arrow.direction.x).is_less(0.0)



func test_projectile_causality_and_single_hit_per_arrow() -> void:
	var runner = scene_runner(BO_COMBAT_SCENE)
	var arena = runner.scene()
	var bo = arena.get_node("Bo") as BrawlerBase
	var dummy = arena.get_node("TargetDummy")
	await runner.simulate_frames(18)

	var spawn_frames: Array = []
	var hit_frames: Array = []
	bo.game_event_emitted.connect(func(ev_name: String, _data: Dictionary):
		if ev_name == BrawlerEvents.EVENT_PROJECTILE_SPAWN:
			spawn_frames.append(Engine.get_physics_frames())
	)
	dummy.hit_received.connect(func(_hit_data):
		hit_frames.append(Engine.get_physics_frames())
	)

	assert_that(bo.attack()).is_true()

	# Wait until all three arrows physically reach the dummy (or timeout)
	for i in range(150):
		await runner.simulate_frames(1)
		if dummy.hit_count >= 3:
			break

	# Exactly one hit event per projectile — no duplicates, no early hits
	assert_int(dummy.hit_count).is_equal(3)
	assert_int(hit_frames.size()).is_equal(3)

	# Causality: every hit happened strictly AFTER the first projectile spawn
	assert_int(spawn_frames.size()).is_greater_equal(1)
	for hf in hit_frames:
		assert_int(hf).is_greater(spawn_frames[0])

	# No stuck projectiles remain
	await runner.simulate_frames(5)
	assert_int(_get_arrows(arena).size()).is_equal(0)

	# Existing hit data contract applied by the target dummy
	var last = dummy.last_hit_data
	assert_that(last.attack_type).is_equal("BO_BASIC")
	assert_float(last.damage).is_equal(40.0)
	assert_float(dummy.current_hp).is_equal(880.0)


func test_attack_while_moving_returns_to_locomotion() -> void:
	var runner = scene_runner(BO_ARENA_SCENE)
	var bo = runner.scene().get_node("BrawlerBo") as BrawlerBase
	await runner.simulate_frames(18)

	# Walk right, then attack mid-walk
	bo.move(1.0, false)
	await runner.simulate_frames(10)
	assert_int(bo.movement_controller.current_state) \
		.is_equal(BrawlerMovementController.State.WALK)

	assert_that(bo.attack()).is_true()
	await runner.simulate_frames(3)
	assert_int(bo.movement_controller.current_state) \
		.is_equal(BrawlerMovementController.State.ATTACK)

	# Attack finishes; with input still held Bo must return to WALK
	await runner.simulate_frames(45)
	assert_int(bo.movement_controller.current_state) \
		.is_equal(BrawlerMovementController.State.WALK)


func test_repeated_attacks_no_state_lock() -> void:
	var runner = scene_runner(BO_ARENA_SCENE)
	var arena = runner.scene()
	var bo = runner.scene().get_node("BrawlerBo") as BrawlerBase
	await runner.simulate_frames(18)

	var spawn_events: Array = []
	bo.game_event_emitted.connect(func(ev_name: String, _data: Dictionary):
		if ev_name == BrawlerEvents.EVENT_PROJECTILE_SPAWN:
			spawn_events.append(true)
	)

	for i in range(12):
		assert_that(bo.attack()).is_true()
		await runner.simulate_frames(40)  # full attack (30 frames) + margin
		# No state-machine lock: Bo always recovers to IDLE
		assert_int(bo.movement_controller.current_state) \
			.is_equal(BrawlerMovementController.State.IDLE)

	# 12 attacks x 3 arrows, each volley spawned exactly once
	assert_int(spawn_events.size()).is_equal(36)
	assert_that(bo.ability_controller.is_attacking).is_false()

	# All arrows eventually expire — none get stuck
	await runner.simulate_frames(60)
	assert_int(_get_arrows(arena).size()).is_equal(0)
