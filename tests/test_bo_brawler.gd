class_name TestBoBrawler
extends GdUnitTestSuite

# Automated Test Suite for Bo Brawler Integration
# Validates node architecture, skeleton hierarchy, pivots, locomotion,
# combat hit/knockback/death, 10 facial expressions, and adapter validation.

const BO_SCENE_PATH := "res://scenes/brawler_bo.tscn"
const BO_TEST_ARENA_PATH := "res://scenes/test_bo_arena.tscn"

func test_bo_validation_and_components() -> void:
	var scene = load(BO_SCENE_PATH)
	assert_that(scene).is_not_null()

	var bo = scene.instantiate() as BrawlerBase
	assert_that(bo).is_not_null()

	# 1. Standard Brawler Components
	assert_that(bo.has_node("CollisionShape2D")).is_true()
	assert_that(bo.has_node("Visuals")).is_true()
	assert_that(bo.has_node("VFXAttachmentPoints")).is_true()
	assert_that(bo.has_node("AnimPlayer")).is_true()
	assert_that(bo.has_node("MovementController")).is_true()
	assert_that(bo.has_node("AnimationController")).is_true()
	assert_that(bo.has_node("AbilityController")).is_true()
	assert_that(bo.has_node("HitReceiver")).is_true()

	# 2. Validation via BoAdapter and BrawlerBuilder
	var report = BoAdapter.validate_bo(bo)
	assert_that(report["valid"]).is_true()
	assert_that(report["missing_nodes"]).is_empty()
	assert_that(report["missing_animations"]).is_empty()
	assert_that(report["missing_bones"]).is_empty()

	# 3. Attachment points
	var vfx = bo.get_node("VFXAttachmentPoints")
	assert_that(vfx.has_node("HitPoint")).is_true()
	assert_that(vfx.has_node("HeadPoint")).is_true()
	assert_that(vfx.has_node("ProjectileSpawn")).is_true()

	# 4. Skeleton Hierarchy & Equipment
	var skel = bo.get_node("Visuals/SkeletonSlot/Skeleton")
	assert_that(skel).is_not_null()
	assert_that(skel.has_node("root")).is_true()
	assert_that(skel.has_node("root/torso")).is_true()
	assert_that(skel.has_node("root/torso/neck/head")).is_true()

	# Arms
	assert_that(skel.has_node("root/torso/arm_L_upper/arm_L_lower/hand_L")).is_true()
	assert_that(skel.has_node("root/torso/arm_R_upper/arm_R_lower/hand_R")).is_true()

	# Legs
	assert_that(skel.has_node("root/leg_L_upper/leg_L_lower/foot_L")).is_true()
	assert_that(skel.has_node("root/leg_R_upper/leg_R_lower/foot_R")).is_true()

	# Equipment nodes
	var hand_l = skel.get_node("root/torso/arm_L_upper/arm_L_lower/hand_L")
	assert_that(hand_l.has_node("BowSprite")).is_true()
	assert_that(hand_l.has_node("ProjectileSpawnPoint")).is_true()

	var torso = skel.get_node("root/torso")
	assert_that(torso.has_node("QuiverSprite")).is_true()
	assert_that(torso.has_node("TorsoSprite")).is_true()

	# 5. Face Controller
	var face = bo.get_node("Visuals/SkeletonSlot/Face") as FaceControllerBoBrawler
	assert_that(face).is_not_null()

	# 6. Config Resource
	var cfg = BoAdapter.get_bo_config()
	assert_that(cfg).is_not_null()
	assert_that(cfg.character_name).is_equal("Bo")
	assert_that(cfg.max_health).is_equal(1400.0)
	assert_that(cfg.walk_speed).is_equal(150.0)
	assert_that(cfg.run_speed).is_equal(280.0)

	bo.free()

func test_bo_locomotion_states() -> void:
	var runner = scene_runner(BO_TEST_ARENA_PATH)
	var arena = runner.scene()
	var bo = arena.get_node("BrawlerBo") as BrawlerBase
	assert_that(bo).is_not_null()

	# Settle onto floor into IDLE
	await runner.simulate_frames(18)
	var state_idle = BrawlerMovementController.State.IDLE
	assert_that(bo.movement_controller.current_state).is_equal(state_idle)

	# 1. Walk Right
	bo.move(1.0, false)
	await runner.simulate_frames(15)
	var state_walk = BrawlerMovementController.State.WALK
	assert_that(bo.movement_controller.current_state).is_equal(state_walk)
	assert_that(bo.velocity.x).is_greater(40.0)
	assert_that(bo.facing_direction).is_equal(1)

	# 2. Run Right (accelerate)
	bo.move(1.0, true)
	await runner.simulate_frames(15)
	var state_run = BrawlerMovementController.State.RUN
	assert_that(bo.movement_controller.current_state).is_equal(state_run)
	assert_that(bo.velocity.x).is_greater(150.0)
	assert_that(bo.facing_direction).is_equal(1)

	# 3. Stop -> Settle into Idle
	bo.move(0.0, false)
	await runner.simulate_frames(4)
	var state_stop = BrawlerMovementController.State.STOP
	assert_that(bo.movement_controller.current_state).is_equal(state_stop)
	await runner.simulate_frames(30)
	assert_that(bo.movement_controller.current_state).is_equal(state_idle)
	assert_that(abs(bo.velocity.x)).is_less(1.0)

	# 4. Jump
	bo.jump()
	await runner.simulate_frames(4)
	var state_anticip = BrawlerMovementController.State.JUMP_ANTICIPATION
	assert_that(bo.movement_controller.current_state).is_equal(state_anticip)
	await runner.simulate_frames(25)
	var state_air = BrawlerMovementController.State.JUMP_AIRBORNE
	assert_that(bo.movement_controller.current_state).is_equal(state_air)
	assert_that(bo.velocity.y).is_less(0.0)

func test_bo_facial_expressions() -> void:
	var runner = scene_runner(BO_TEST_ARENA_PATH)
	var arena = runner.scene()
	var bo = arena.get_node("BrawlerBo") as BrawlerBase
	assert_that(bo).is_not_null()
	assert_that(bo.face_controller).is_not_null()

	var expressions: Array[String] = [
		"serious", "neutral", "angry", "happy", "shocked",
		"scared", "hurt", "confused", "smug", "sad"
	]

	for expr in expressions:
		bo.set_expression(expr)
		assert_that(bo.face_controller.current_expression).is_equal(expr)

	# Test eye states
	bo.set_eye_state("wide")
	assert_that(bo.face_controller.current_eye_state).is_equal("wide")
	bo.set_eye_state("blink")
	assert_that(bo.face_controller.current_eye_state).is_equal("blink")
	bo.set_eye_state("open")
	assert_that(bo.face_controller.current_eye_state).is_equal("open")

func test_bo_attack() -> void:
	var runner = scene_runner(BO_TEST_ARENA_PATH)
	var arena = runner.scene()
	var bo = arena.get_node("BrawlerBo") as BrawlerBase
	assert_that(bo).is_not_null()

	var events_received: Array[String] = []
	bo.game_event_emitted.connect(func(ev_name: String, _data: Dictionary):
		events_received.append(ev_name)
	)

	var ok = bo.attack()
	assert_that(ok).is_true()
	var state_atk = BrawlerMovementController.State.ATTACK
	assert_that(bo.movement_controller.current_state).is_equal(state_atk)

	# Simulate attack duration (~0.38s)
	await runner.simulate_frames(50)
	assert_that(events_received).contains([BrawlerEvents.EVENT_ATTACK_START])
	assert_that(events_received).contains([BrawlerEvents.EVENT_ATTACK_END])

	var state_idle = BrawlerMovementController.State.IDLE
	assert_that(bo.movement_controller.current_state).is_equal(state_idle)

func test_bo_hit_knockback_and_death() -> void:
	var runner = scene_runner(BO_TEST_ARENA_PATH)
	var arena = runner.scene()
	var bo = arena.get_node("BrawlerBo") as BrawlerBase
	assert_that(bo).is_not_null()

	await runner.simulate_frames(5)
	assert_that(bo.hit_receiver.current_health).is_equal(1400.0)

	# 1. Light hit
	var hit = HitData.create(150.0, Vector2.LEFT, 80.0, null, "TEST_HIT")
	bo.take_hit(hit)
	assert_that(bo.hit_receiver.current_health).is_equal(1250.0)
	var state_hit = BrawlerMovementController.State.HIT
	assert_that(bo.movement_controller.current_state).is_equal(state_hit)
	assert_that(bo.face_controller.current_expression).is_equal("hurt")

	# 2. Heavy knockback hit
	var kb_hit = HitData.create(250.0, Vector2.LEFT, 260.0, null, "HEAVY_HIT")
	bo.take_hit(kb_hit)
	assert_that(bo.hit_receiver.current_health).is_equal(1000.0)
	var state_kb = BrawlerMovementController.State.KNOCKBACK
	assert_that(bo.movement_controller.current_state).is_equal(state_kb)

	# Recover to idle (knockback duration is 0.40s)
	await runner.simulate_frames(65)
	var state_idle_2 = BrawlerMovementController.State.IDLE
	assert_that(bo.movement_controller.current_state).is_equal(state_idle_2)

	# 3. Lethal hit
	var lethal = HitData.create(1000.0, Vector2.LEFT, 50.0, null, "LETHAL_HIT")
	bo.take_hit(lethal)
	assert_that(bo.hit_receiver.current_health).is_equal(0.0)
	var state_death = BrawlerMovementController.State.DEATH
	assert_that(bo.movement_controller.current_state).is_equal(state_death)
	assert_that(bo.face_controller.current_expression).is_equal("sad")

