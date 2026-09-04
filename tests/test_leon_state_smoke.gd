# GdUnit4 smoke test suite covering Leon state transitions
class_name TestLeonStateSmoke
extends GdUnitTestSuite

func test_leon_state_transitions_idle_walk_stop_idle() -> void:
	var runner := scene_runner("res://scenes/walk_test.tscn")
	var harness = runner.scene()
	assert_that(harness).is_not_null()

	# Activate interactive mode with physics enabled
	harness.set_mode(harness.Mode.INTERACTIVE)
	var leon = harness.puppet
	assert_that(leon).is_not_null()

	# Settle for 15 frames so initial landing squash finishes into IDLE
	await runner.simulate_frames(15)

	# 1. Verify Initial State is IDLE
	assert_that(leon.current_state).is_equal(leon.State.IDLE)
	assert_that(leon.STATE_NAMES[leon.current_state]).is_equal("IDLE")

	# 2. Transition IDLE -> WALK by pressing KEY_D
	runner.simulate_key_press(KEY_D)
	await runner.simulate_frames(15)

	assert_that(leon.current_state).is_equal(leon.State.WALK)
	assert_that(leon.STATE_NAMES[leon.current_state]).is_equal("WALK")
	assert_that(leon.velocity.x).is_greater(0.0)

	# 3. Transition WALK -> STOP by releasing KEY_D
	runner.simulate_key_release(KEY_D)
	await runner.simulate_frames(2)

	assert_that(leon.current_state).is_equal(leon.State.STOP)
	assert_that(leon.STATE_NAMES[leon.current_state]).is_equal("STOP")

	# 4. Recover STOP -> IDLE as stopping deceleration settles
	await runner.simulate_frames(25)

	assert_that(leon.current_state).is_equal(leon.State.IDLE)
	assert_that(leon.STATE_NAMES[leon.current_state]).is_equal("IDLE")
	assert_that(leon.velocity.x).is_equal_approx(0.0, 1.0)
