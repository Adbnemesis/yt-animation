class_name TestBrawlerTemplate
extends GdUnitTestSuite

# Automated Test Suite for Reusable Brawler Template
# Validates node architecture, state machine, physics, combat, Super, and face interfaces.

const TEST_BRAWLER_SCENE := "res://templates/brawler/test_brawler/test_brawler.tscn"
const TEST_ARENA_SCENE := "res://templates/brawler/test_brawler/test_arena.tscn"

func test_template_validation_and_components() -> void:
	var scene = load(TEST_BRAWLER_SCENE)
	assert_that(scene).is_not_null()

	var brawler = scene.instantiate() as BrawlerBase
	assert_that(brawler).is_not_null()

	# Verify required nodes
	assert_that(brawler.has_node("CollisionShape2D")).is_true()
	assert_that(brawler.has_node("Visuals")).is_true()
	assert_that(brawler.has_node("VFXAttachmentPoints")).is_true()
	assert_that(brawler.has_node("AnimPlayer")).is_true()
	assert_that(brawler.has_node("MovementController")).is_true()
	assert_that(brawler.has_node("AnimationController")).is_true()
	assert_that(brawler.has_node("AbilityController")).is_true()
	assert_that(brawler.has_node("HitReceiver")).is_true()

	# Validate via BrawlerBuilder
	var report = BrawlerBuilder.validate_brawler(brawler)
	assert_that(report["valid"]).is_true()
	assert_that(report["missing_nodes"]).is_empty()
	assert_that(report["missing_animations"]).is_empty()

	brawler.free()

func test_brawler_locomotion_states() -> void:
	var runner = scene_runner(TEST_ARENA_SCENE)
	var arena = runner.scene()
	var brawler = arena.get_node("Brawler") as BrawlerBase
	assert_that(brawler).is_not_null()

	# Settle onto floor
	await runner.simulate_frames(10)

	# 1. Starts in IDLE
	var state_idle = BrawlerMovementController.State.IDLE
	assert_that(brawler.movement_controller.current_state).is_equal(state_idle)

	# 2. Walk
	brawler.move(1.0, false)
	await runner.simulate_frames(15)
	var state_walk = BrawlerMovementController.State.WALK
	assert_that(brawler.movement_controller.current_state).is_equal(state_walk)
	assert_that(brawler.velocity.x).is_greater(50.0)

	# 3. Run
	brawler.move(1.0, true)
	await runner.simulate_frames(15)
	var state_run = BrawlerMovementController.State.RUN
	assert_that(brawler.movement_controller.current_state).is_equal(state_run)
	assert_that(brawler.velocity.x).is_greater(150.0)

	# 4. Stop -> Idle
	brawler.move(0.0, false)
	await runner.simulate_frames(5)
	var state_stop = BrawlerMovementController.State.STOP
	assert_that(brawler.movement_controller.current_state).is_equal(state_stop)
	await runner.simulate_frames(30)
	assert_that(brawler.movement_controller.current_state).is_equal(state_idle)
	assert_that(abs(brawler.velocity.x)).is_less(1.0)

	# 5. Jump
	brawler.jump()
	await runner.simulate_frames(2)
	var state_anticip = BrawlerMovementController.State.JUMP_ANTICIPATION
	assert_that(brawler.movement_controller.current_state).is_equal(state_anticip)
	await runner.simulate_frames(10)
	var state_air = BrawlerMovementController.State.JUMP_AIRBORNE
	assert_that(brawler.movement_controller.current_state).is_equal(state_air)
	assert_that(brawler.velocity.y).is_less(0.0)

func test_brawler_attack_and_projectile() -> void:
	var runner = scene_runner(TEST_ARENA_SCENE)
	var arena = runner.scene()
	var brawler = arena.get_node("Brawler") as BrawlerBase
	assert_that(brawler).is_not_null()

	var events_received: Array[String] = []
	brawler.game_event_emitted.connect(func(ev_name: String, _data: Dictionary):
		events_received.append(ev_name)
	)

	# Trigger attack
	var ok = brawler.attack()
	assert_that(ok).is_true()
	var state_atk = BrawlerMovementController.State.ATTACK
	assert_that(brawler.movement_controller.current_state).is_equal(state_atk)

	# Simulate attack burst & duration (0.30s = ~18 frames)
	await runner.simulate_frames(25)

	assert_that(events_received).contains([BrawlerEvents.EVENT_ATTACK_START])
	assert_that(events_received).contains([BrawlerEvents.EVENT_PROJECTILE_SPAWN])
	assert_that(events_received).contains([BrawlerEvents.EVENT_ATTACK_END])
	var state_idle = BrawlerMovementController.State.IDLE
	assert_that(brawler.movement_controller.current_state).is_equal(state_idle)

func test_brawler_hit_and_knockback() -> void:
	var runner = scene_runner(TEST_ARENA_SCENE)
	var arena = runner.scene()
	var brawler = arena.get_node("Brawler") as BrawlerBase
	assert_that(brawler).is_not_null()

	await runner.simulate_frames(5)
	var initial_hp = brawler.hit_receiver.current_health
	var hit = HitData.create(50.0, Vector2.LEFT, 100.0, null, "TEST_HIT")
	brawler.take_hit(hit)

	assert_that(brawler.hit_receiver.current_health).is_equal(initial_hp - 50.0)
	var state_hit = BrawlerMovementController.State.HIT
	assert_that(brawler.movement_controller.current_state).is_equal(state_hit)

	# High force knockback
	var kb_hit = HitData.create(50.0, Vector2.LEFT, 250.0, null, "HEAVY_HIT")
	brawler.take_hit(kb_hit)
	var state_kb = BrawlerMovementController.State.KNOCKBACK
	assert_that(brawler.movement_controller.current_state).is_equal(state_kb)

	await runner.simulate_frames(35)
	var state_idle = BrawlerMovementController.State.IDLE
	assert_that(brawler.movement_controller.current_state).is_equal(state_idle)

func test_brawler_super_ability() -> void:
	var runner = scene_runner(TEST_ARENA_SCENE)
	var arena = runner.scene()
	var brawler = arena.get_node("Brawler") as BrawlerBase
	assert_that(brawler).is_not_null()

	var ok = brawler.activate_super()
	assert_that(ok).is_true()
	var state_sup_start = BrawlerAbilityController.SuperState.SUPER_START
	assert_that(brawler.ability_controller.super_state).is_equal(state_sup_start)

	# Simulate fade in (~0.2s = 12 frames)
	await runner.simulate_frames(15)
	var state_sup_active = BrawlerAbilityController.SuperState.SUPER_ACTIVE
	assert_that(brawler.ability_controller.super_state).is_equal(state_sup_active)
	assert_that(brawler.visuals.modulate.a).is_less(0.2)

func test_brawler_face_controller() -> void:
	var runner = scene_runner(TEST_ARENA_SCENE)
	var arena = runner.scene()
	var brawler = arena.get_node("Brawler") as BrawlerBase
	assert_that(brawler.face_controller).is_not_null()

	brawler.set_expression("happy")
	assert_that(brawler.face_controller.current_expression).is_equal("happy")

	brawler.set_expression("angry")
	assert_that(brawler.face_controller.current_expression).is_equal("angry")

	brawler.set_eye_state("wide")
	assert_that(brawler.face_controller.current_eye_state).is_equal("wide")
