class_name TestLeonFrontView
extends GdUnitTestSuite

# ============================================================================
# LEON CANONICAL FRONT VIEW & ATTACK ROTATION VERIFICATION SUITE
# ----------------------------------------------------------------------------
# Validates:
# 1. Canonical rig integrity (scenes/videos/leon_elevator/leon_front.tscn)
# 2. Complete animation states (IDLE, WALK, RUN, STOP, JUMP, ATTACK, SUPER, HIT)
# 3. Z-axis rotation-dependent attack trajectory:
#    - Rotation 0° => dir = (0, -1) [straight toward camera]
#    - Rotation -θ => dir angled left [sin(-θ), -cos(-θ)]
#    - Rotation +θ => dir angled right [sin(+θ), -cos(+θ)]
# 4. FaceController expressions and eye states
# 5. Super stealth and hit recovery
# ============================================================================

const FRONT_SCENE := "res://scenes/videos/leon_elevator/leon_front.tscn"
const LeonFrontController = preload("res://scripts/leon_front_controller.gd")

func test_canonical_front_rig_hierarchy() -> void:
	var scene = load(FRONT_SCENE).instantiate()
	assert_that(scene).is_not_null()
	assert_that(scene is Node2D).is_true()
	
	# Verify canonical parts
	assert_that(scene.get_node_or_null("Feet")).is_not_null()
	assert_that(scene.get_node_or_null("Legs")).is_not_null()
	assert_that(scene.get_node_or_null("Shorts")).is_not_null()
	assert_that(scene.get_node_or_null("Torso")).is_not_null()
	assert_that(scene.get_node_or_null("ArmL")).is_not_null()
	assert_that(scene.get_node_or_null("ArmR")).is_not_null()
	assert_that(scene.get_node_or_null("Head")).is_not_null()
	assert_that(scene.get_node_or_null("Head/Hood")).is_not_null()
	
	var face = scene.get_node_or_null("Head/Face")
	assert_that(face).is_not_null()
	assert_that(face is FaceController).is_true()
	
	scene.free()

func test_state_transitions() -> void:
	var runner := scene_runner(FRONT_SCENE)
	var leon = runner.scene()
	assert_that(leon).is_not_null()
	
	# Initial State IDLE
	assert_that(leon.current_state).is_equal(LeonFrontController.State.IDLE)
	
	# WALK
	leon.change_state(LeonFrontController.State.WALK)
	assert_that(leon.current_state).is_equal(LeonFrontController.State.WALK)
	await runner.simulate_frames(10)
	
	# RUN
	leon.change_state(LeonFrontController.State.RUN)
	assert_that(leon.current_state).is_equal(LeonFrontController.State.RUN)
	await runner.simulate_frames(10)
	
	# STOP
	leon.change_state(LeonFrontController.State.STOP)
	assert_that(leon.current_state).is_equal(LeonFrontController.State.STOP)
	await runner.simulate_frames(5)
	
	# IDLE recovery
	leon.change_state(LeonFrontController.State.IDLE)
	assert_that(leon.current_state).is_equal(LeonFrontController.State.IDLE)

func test_attack_direction_derived_from_z_rotation() -> void:
	var runner := scene_runner(FRONT_SCENE)
	var leon = runner.scene()
	assert_that(leon).is_not_null()
	
	var results := {
		"dir": Vector2.ZERO,
		"count": 0
	}
	leon.attack_released.connect(func(dir: Vector2, _offset: Vector2):
		results["dir"] = dir
		results["count"] += 1
	)
	
	# Case 1: Straight Forward (rotation = 0°)
	leon.rotation = 0.0
	leon.trigger_attack(0.0)
	await leon.attack_released
	
	assert_that(results["count"]).is_equal(1)
	assert_that(is_equal_approx(results["dir"].x, 0.0)).is_true()
	assert_that(results["dir"].y).is_less(0.0) # Forward toward camera in 2.5D (-Z)
	
	await runner.simulate_frames(20) # finish attack
	
	# Case 2: Rotated Left (rotation = -30°)
	var angle_left := -30.0
	leon.trigger_attack(angle_left)
	await leon.attack_released
	
	assert_that(results["count"]).is_equal(2)
	assert_that(results["dir"].x).is_less(0.0) # Aimed left
	assert_that(results["dir"].y).is_less(0.0) # Aimed forward
	var expected_dir_left := Vector2(sin(deg_to_rad(angle_left)), -cos(deg_to_rad(angle_left))).normalized()
	assert_that(is_equal_approx(results["dir"].x, expected_dir_left.x)).is_true()
	assert_that(is_equal_approx(results["dir"].y, expected_dir_left.y)).is_true()
	
	await runner.simulate_frames(20)
	
	# Case 3: Rotated Right (rotation = +30°)
	var angle_right := 30.0
	leon.trigger_attack(angle_right)
	await leon.attack_released
	
	assert_that(results["count"]).is_equal(3)
	assert_that(results["dir"].x).is_greater(0.0) # Aimed right
	assert_that(results["dir"].y).is_less(0.0)    # Aimed forward
	var expected_dir_right := Vector2(sin(deg_to_rad(angle_right)), -cos(deg_to_rad(angle_right))).normalized()
	assert_that(is_equal_approx(results["dir"].x, expected_dir_right.x)).is_true()
	assert_that(is_equal_approx(results["dir"].y, expected_dir_right.y)).is_true()

func test_super_stealth_activation() -> void:
	var runner := scene_runner(FRONT_SCENE)
	var leon = runner.scene()
	assert_that(leon).is_not_null()
	
	leon.trigger_super()
	assert_that(leon.current_state).is_equal(LeonFrontController.State.SUPER)
	await runner.simulate_frames(20)
	
	# Alpha should fade into stealth
	assert_that(leon.modulate.a).is_less(0.5)

func test_hit_reaction_and_expressions() -> void:
	var runner := scene_runner(FRONT_SCENE)
	var leon = runner.scene()
	assert_that(leon).is_not_null()
	
	# Test hit reaction
	leon.trigger_hit()
	assert_that(leon.current_state).is_equal(LeonFrontController.State.HIT)
	assert_that(leon.face.current_expression).is_equal("hurt")
	
	# Test expression changes
	leon.set_face_expression("happy", "happy")
	assert_that(leon.face.current_expression).is_equal("happy")
	
	leon.set_face_expression("angry", "angry")
	assert_that(leon.face.current_expression).is_equal("angry")
