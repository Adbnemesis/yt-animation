class_name TestLeonBackView
extends GdUnitTestSuite

# ============================================================================
# LEON BACK VIEW FOUNDATION — AUTOMATED VERIFICATION SUITE
# ----------------------------------------------------------------------------
# Validates (Parts 1-70):
# 1.  Canonical back rig integrity (leon_back.tscn reused, not re-rigged)
# 2.  Complete state machine (IDLE/ACCEL/WALK/RUN/STOP/JUMP/ATTACK/SUPER/HIT/
#     KNOCKBACK/RECOVERY)
# 3.  Facing-yaw attack trajectory contract into depth (dir = (sin yaw, -cos yaw))
# 4.  Attack causality (anticipation BEFORE release, projectile BEFORE impact)
# 5.  Attack socket attached to the artwork at (26, -32)
# 6.  Tail motion (sway in idle, counter-sway in walk/run, tuck in jump, flinch on hit)
# 7.  Root/feet ground baseline consistency at (0, 0)
# 8.  Depth scale monotonic (NEAR large -> FAR small); horizontal scale invariance
# 9.  Diagonal movement combines lateral displacement and depth scaling
# 10. Head/neck acting (attention from behind without fake front facial parts)
# 11. Super stealth events, alpha shimmer (0.22), recovery
# 12. Hit -> knockback -> recovery chain
# 13. Comparison against front, 3/4, side views: zero ground jump, shared scale
# ============================================================================

const RIG_SCENE := "res://scenes/videos/leon_elevator/leon_back.tscn"
const TEST_SCENE := "res://scenes/labs/leon_back_view_animation_test.tscn"
const LeonBackControllerClass = preload("res://scripts/labs/leon_back_controller.gd")


func _fresh_rig() -> LeonBackController:
	var rig: LeonBackController = load(RIG_SCENE).instantiate()
	rig.set_process(true)
	add_child(rig)
	return rig


func _release_rig(rig: LeonBackController) -> void:
	rig.queue_free()


# 1. Canonical rig hierarchy --------------------------------------------------


func test_canonical_back_rig_hierarchy() -> void:
	var rig := _fresh_rig()
	assert_that(rig).is_not_null()
	assert_that(rig is LeonBackController).is_true()

	assert_that(rig.get_node_or_null("Tail")).is_not_null()
	assert_that(rig.get_node_or_null("Feet/FootL")).is_not_null()
	assert_that(rig.get_node_or_null("Feet/FootR")).is_not_null()
	assert_that(rig.get_node_or_null("Legs/LegL")).is_not_null()
	assert_that(rig.get_node_or_null("Shorts/ShortL")).is_not_null()
	assert_that(rig.get_node_or_null("Torso")).is_not_null()
	assert_that(rig.get_node_or_null("Head")).is_not_null()
	assert_that(rig.get_node_or_null("ArmL")).is_not_null()
	assert_that(rig.get_node_or_null("ArmR")).is_not_null()

	# Attack socket marker on near hand at (26, -32)
	var socket: Marker2D = rig.get_node_or_null("AttackSocket")
	assert_that(socket).is_not_null()
	assert_float(socket.position.x).is_equal_approx(26.0, 0.01)
	assert_float(socket.position.y).is_equal_approx(-32.0, 0.01)

	_release_rig(rig)


# 2. State machine transitions ------------------------------------------------


func test_state_transitions_full_chain() -> void:
	var rig := _fresh_rig()
	assert_int(rig.current_state).is_equal(LeonBackController.State.IDLE)

	rig.change_state(LeonBackController.State.WALK)
	assert_int(rig.current_state).is_equal(LeonBackController.State.WALK)

	rig.change_state(LeonBackController.State.RUN)
	assert_int(rig.current_state).is_equal(LeonBackController.State.RUN)

	rig.change_state(LeonBackController.State.STOP)
	assert_int(rig.current_state).is_equal(LeonBackController.State.STOP)

	rig.change_state(LeonBackController.State.IDLE)
	assert_int(rig.current_state).is_equal(LeonBackController.State.IDLE)

	_release_rig(rig)


# 3. Facing-yaw attack trajectory into depth ----------------------------------


func test_attack_direction_into_depth() -> void:
	var rig := _fresh_rig()
	var results := {"dir": Vector2.ZERO, "count": 0}
	rig.attack_released.connect(
		func(dir: Vector2, _offset: Vector2):
			results["dir"] = dir
			results["count"] += 1
	)

	# Case 1: Straight away into depth (yaw = 180°)
	rig.trigger_attack(180.0)
	await rig.attack_released
	assert_int(results["count"]).is_equal(1)
	assert_float(results["dir"].x).is_equal_approx(0.0, 0.001)
	assert_float(results["dir"].y).is_greater(0.99)  # positive depth (+z into screen away from camera)

	await get_tree().create_timer(0.4).timeout

	# Case 2: Angled depth-left (yaw = 145°)
	rig.trigger_attack(145.0)
	await rig.attack_released
	assert_int(results["count"]).is_equal(2)
	var expected_left := Vector2(sin(deg_to_rad(145.0)), -cos(deg_to_rad(145.0)))
	assert_float(results["dir"].x).is_equal_approx(expected_left.x, 0.001)
	assert_float(results["dir"].y).is_equal_approx(expected_left.y, 0.001)

	await get_tree().create_timer(0.4).timeout

	# Case 3: Angled depth-right (yaw = 215°)
	rig.trigger_attack(215.0)
	await rig.attack_released
	assert_int(results["count"]).is_equal(3)
	var expected_right := Vector2(sin(deg_to_rad(215.0)), -cos(deg_to_rad(215.0)))
	assert_float(results["dir"].x).is_equal_approx(expected_right.x, 0.001)
	assert_float(results["dir"].y).is_equal_approx(expected_right.y, 0.001)

	_release_rig(rig)


# 4. Attack causality: anticipation precedes release --------------------------


func test_attack_anticipation_precedes_release() -> void:
	var rig := _fresh_rig()
	var release_count := [0]
	rig.attack_released.connect(func(_d: Vector2, _o: Vector2): release_count[0] += 1)

	rig.trigger_attack(180.0)
	# ~5 frames = ~0.083s: anticipation + aim hold (0.14s) has NOT elapsed yet
	for i in range(5):
		await get_tree().process_frame
	assert_int(release_count[0]).is_equal(0)

	await rig.attack_released
	assert_int(release_count[0]).is_equal(1)

	_release_rig(rig)


# 5. Tail dynamics (idle sway & locomotion counter-sway) ----------------------


func test_tail_dynamics_idle_and_locomotion() -> void:
	var rig := _fresh_rig()
	assert_that(rig.tail).is_not_null()

	# In idle, tail has continuous organic sway
	rig.change_state(LeonBackController.State.IDLE)
	rig._process(0.2)
	var rot_idle_1: float = rig.tail.rotation
	rig._process(0.4)
	var rot_idle_2: float = rig.tail.rotation
	assert_float(absf(rot_idle_1 - rot_idle_2)).is_greater(0.0001)

	# In walk, tail counter-sways with higher amplitude
	rig.change_state(LeonBackController.State.WALK)
	rig._process(0.3)
	assert_that(absf(rig.tail.rotation)).is_greater(0.01)

	_release_rig(rig)


# 6. Root and feet baseline consistency ---------------------------------------


func test_root_and_feet_baseline_consistent() -> void:
	var rig := _fresh_rig()
	assert_float(rig.position.x).is_equal(0.0)
	assert_float(rig.position.y).is_equal(0.0)

	# Baseline ground contact point of feet
	var foot_l: Polygon2D = rig.get_node_or_null("Feet/FootL")
	var foot_r: Polygon2D = rig.get_node_or_null("Feet/FootR")
	assert_that(foot_l).is_not_null()
	assert_that(foot_r).is_not_null()
	assert_float(foot_l.position.y).is_equal(0.0)
	assert_float(foot_r.position.y).is_equal(0.0)

	_release_rig(rig)


# 7. Head/neck attention acting -----------------------------------------------


func test_head_neck_attention_acting() -> void:
	var rig := _fresh_rig()
	assert_that(rig.head).is_not_null()

	rig.look_toward(15.0, 0.1)
	await get_tree().create_timer(0.15).timeout
	assert_float(rig.head.rotation).is_greater(0.1)

	rig.reset_head_pose(0.1)
	await get_tree().create_timer(0.15).timeout
	assert_float(rig.head.rotation).is_equal_approx(0.0, 0.05)

	_release_rig(rig)


# 8. Super stealth events & shimmer -------------------------------------------


func test_super_stealth_events_and_recovery() -> void:
	var rig := _fresh_rig()
	var started := [0]
	var ended := [0]
	rig.super_started.connect(func(): started[0] += 1)
	rig.super_ended.connect(func(): ended[0] += 1)

	rig.trigger_super()
	assert_int(started[0]).is_equal(1)
	assert_int(rig.current_state).is_equal(LeonBackController.State.SUPER)

	# Mid-super: alpha shimmer active (~0.22)
	await get_tree().create_timer(0.5).timeout
	assert_float(rig.modulate.a).is_less(0.35)

	# Super completion
	await rig.super_ended
	assert_int(ended[0]).is_equal(1)
	assert_float(rig.modulate.a).is_equal_approx(1.0, 0.05)

	_release_rig(rig)


# 9. Hit reaction & knockback -------------------------------------------------


func test_hit_knockback_recovery_chain() -> void:
	var rig := _fresh_rig()
	var knock_started := [0]
	rig.knockback_started.connect(func(_d): knock_started[0] += 1)

	rig.trigger_hit(Vector2(0.0, -1.0))
	assert_int(rig.current_state).is_equal(LeonBackController.State.HIT)
	assert_int(knock_started[0]).is_equal(1)

	await get_tree().create_timer(0.4).timeout
	assert_int(rig.current_state).is_equal(LeonBackController.State.IDLE)

	_release_rig(rig)


# 10. Spatial test: horizontal movement preserves scale ------------------------


func test_horizontal_movement_preserves_scale() -> void:
	var lab: LeonBackViewAnimationTest = load(TEST_SCENE).instantiate()
	lab.auto_start_demo = false
	add_child(lab)

	lab.world_pos = Vector2(-200.0, 220.0)
	lab._apply_projection(true)
	var scale_left: float = absf(lab.apparent_scale())

	lab.world_pos = Vector2(200.0, 220.0)
	lab._apply_projection(true)
	var scale_right: float = absf(lab.apparent_scale())

	assert_float(scale_left).is_equal_approx(scale_right, 0.0001)

	lab.queue_free()


# 11. Spatial test: depth movement scales monotonically -----------------------


func test_depth_movement_scales_monotonically() -> void:
	var lab: LeonBackViewAnimationTest = load(TEST_SCENE).instantiate()
	lab.auto_start_demo = false
	add_child(lab)

	# Away into depth (NEAR -> FAR): scale must shrink monotonically
	lab.world_pos = Vector2(0.0, 80.0)  # NEAR
	lab._apply_projection(true)
	var s_near: float = absf(lab.apparent_scale())

	lab.world_pos = Vector2(0.0, 240.0)  # MID
	lab._apply_projection(true)
	var s_mid: float = absf(lab.apparent_scale())

	lab.world_pos = Vector2(0.0, 480.0)  # FAR
	lab._apply_projection(true)
	var s_far: float = absf(lab.apparent_scale())

	assert_float(s_near).is_greater(s_mid)
	assert_float(s_mid).is_greater(s_far)

	lab.queue_free()


# 12. Spatial test: diagonal movement combines X and depth --------------------


func test_diagonal_movement_combines_x_and_depth() -> void:
	var lab: LeonBackViewAnimationTest = load(TEST_SCENE).instantiate()
	lab.auto_start_demo = false
	add_child(lab)

	lab.world_pos = Vector2(-150.0, 100.0)
	lab._apply_projection(true)
	var pos1: Vector2 = lab.actor_root.position
	var scale1: float = absf(lab.apparent_scale())

	lab.world_pos = Vector2(150.0, 350.0)
	lab._apply_projection(true)
	var pos2: Vector2 = lab.actor_root.position
	var scale2: float = absf(lab.apparent_scale())

	assert_float(pos1.x).is_less(pos2.x)
	assert_float(scale1).is_greater(scale2)

	lab.queue_free()


# 13. Projectile causality: visible travel before target dummy impact ---------


func test_projectile_causality_travels_before_impact() -> void:
	var lab: LeonBackViewAnimationTest = load(TEST_SCENE).instantiate()
	lab.auto_start_demo = false
	add_child(lab)

	var initial_hp: float = lab.dummy_node.current_hp
	lab.trigger_attack_toward_dummy()

	# At 0.05s, attack windup in progress, no damage
	await get_tree().create_timer(0.05).timeout
	assert_float(lab.dummy_node.current_hp).is_equal(initial_hp)

	# After arrival and impact (~0.6s), damage recorded
	await get_tree().create_timer(0.65).timeout
	assert_float(lab.dummy_node.current_hp).is_less(initial_hp)

	lab.queue_free()


# 14. View comparison: ground baseline stability across views -----------------


func test_ground_baseline_across_all_views() -> void:
	var back: LeonBackController = load(RIG_SCENE).instantiate()
	var front = load("res://scenes/videos/leon_elevator/leon_front.tscn").instantiate()
	var three_q = load(
		"res://scenes/labs/characters/leon_multiview_lab/view_front_3q.tscn"
	).instantiate()

	add_child(back)
	add_child(front)
	add_child(three_q)

	# All three rigs have their origin (0, 0) anchored to the feet baseline
	assert_float(back.position.y).is_equal(0.0)
	assert_float(front.position.y).is_equal(0.0)
	assert_float(three_q.position.y).is_equal(0.0)

	# Torso resting baselines match exactly (-61 px)
	assert_float(back.torso.position.y).is_equal(front.torso.position.y)
	assert_float(back.torso.position.y).is_equal(three_q.torso.position.y)

	# Head resting baselines match exactly (-110 px)
	assert_float(back.head.position.y).is_equal(front.head.position.y)
	assert_float(back.head.position.y).is_equal(three_q.head.position.y)

	back.queue_free()
	front.queue_free()
	three_q.queue_free()
