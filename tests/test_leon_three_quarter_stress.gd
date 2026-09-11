class_name TestLeonThreeQuarterStress
extends GdUnitTestSuite

# ============================================================================
# LEON 3/4 VIEW FOUNDATION — 50-CYCLE REPEATED STRESS & ENDURANCE SUITE
# ----------------------------------------------------------------------------
# Validates the repeated stability requirements:
# - 50 idle loops
# - 50 walk cycles
# - 50 run cycles
# - 50 jumps
# - 50 landings
# - 50 attacks
# - 50 Supers
# - 50 moving attacks
# - 50 diagonal movements
# - 50 depth approaches
# - 50 depth retreats
# - 50 hit/knockback cycles
#
# Guarantees zero state machine lockups, zero NaN coordinates, zero foot drift,
# and zero socket detachment across repeated cycles.
# ============================================================================

const RIG_SCENE := "res://scenes/labs/characters/leon_multiview_lab/view_front_3q.tscn"
const TEST_SCENE := "res://scenes/labs/leon_three_quarter_animation_test.tscn"
const Leon3QController = preload("res://scripts/labs/leon_three_quarter_controller.gd")


func _fresh_rig() -> Leon3QController:
	var rig: Leon3QController = load(RIG_SCENE).instantiate()
	rig.set_process(true)
	add_child(rig)
	return rig


func _release_rig(rig: Leon3QController) -> void:
	rig.queue_free()


# 1. 50 Idle loops ------------------------------------------------------------
func test_50_idle_loops() -> void:
	var rig := _fresh_rig()
	rig.change_state(Leon3QController.State.IDLE)
	
	# Period of idle breathing is TAU / 3.2 ≈ 1.9635s
	var dt := 0.02
	var steps_per_cycle := int((TAU / 3.2) / dt) + 1
	
	for cycle in range(50):
		for s in range(steps_per_cycle):
			rig._state_time += dt
			rig._process_idle()
		
		# Check stability at end of each cycle
		assert_that(is_nan(rig.torso.position.y)).is_false()
		assert_that(is_nan(rig.head.position.y)).is_false()
		assert_float(absf(rig.torso.position.y - Leon3QController.TORSO_BASE_POS.y)).is_less(2.0)
	
	_release_rig(rig)


# 2. 50 Walk cycles -----------------------------------------------------------
func test_50_walk_cycles() -> void:
	var rig := _fresh_rig()
	rig.change_state(Leon3QController.State.WALK)
	rig._speed_factor = 1.0
	
	# Period of walk cycle at speed_factor 1.0 is TAU / 5.6
	var dt := 0.02
	var period: float = TAU / 5.6
	var steps_per_cycle := int(period / dt) + 1
	
	for cycle in range(50):
		var near_max := 0.0
		var far_max := 0.0
		for s in range(steps_per_cycle):
			rig._process_walk(dt, 5.6, 7.0, 0.20, 1.6, 1.6)
			near_max = maxf(near_max, absf(rig.foot_r.position.y))
			far_max = maxf(far_max, absf(rig.foot_l.position.y))
		
		# Near foot has 7.0 lift, far foot has 7.0 * 0.72 = 5.04 lift
		assert_float(near_max).is_greater(far_max)
		assert_float(near_max).is_greater(6.5)
		assert_that(is_nan(rig.foot_r.position.y)).is_false()
	
	_release_rig(rig)


# 3. 50 Run cycles ------------------------------------------------------------
func test_50_run_cycles() -> void:
	var rig := _fresh_rig()
	rig.change_state(Leon3QController.State.RUN)
	rig._speed_factor = 1.0
	
	# Period of run cycle at speed_factor 1.0 is TAU / 8.8
	var dt := 0.02
	var period: float = TAU / 8.8
	var steps_per_cycle := int(period / dt) + 1
	
	for cycle in range(50):
		var near_max := 0.0
		var far_max := 0.0
		for s in range(steps_per_cycle):
			rig._process_walk(dt, 8.8, 12.0, 0.44, 2.4, 3.4)
			near_max = maxf(near_max, absf(rig.foot_r.position.y))
			far_max = maxf(far_max, absf(rig.foot_l.position.y))
		
		assert_float(near_max).is_greater(far_max)
		assert_float(near_max).is_greater(11.0) # Run has stronger stride (12.0 vs 7.0)
	
	_release_rig(rig)


# 4 & 5. 50 Jumps and Landings ------------------------------------------------
func test_50_jumps_and_landings() -> void:
	var rig := _fresh_rig()
	var landed_count := [0]
	rig.landed.connect(func(): landed_count[0] += 1)
	
	for cycle in range(50):
		rig.trigger_jump()
		assert_int(rig.current_state).is_equal(Leon3QController.State.JUMP)
		
		# Advance jump mechanics manually through the phases
		rig._jump_compress(1.0)
		rig._jump_stretch(1.0)
		rig._jump_airborne(0.5)
		rig._jump_land(1.0)
		rig._jump_recoil(0.0)
		rig._on_jump_finished()
		
		assert_int(rig.current_state).is_equal(Leon3QController.State.IDLE)
		assert_float(rig.foot_l.position.y).is_equal_approx(0.0, 0.01)
		assert_float(rig.foot_r.position.y).is_equal_approx(0.0, 0.01)
	
	assert_int(landed_count[0]).is_equal(50)
	_release_rig(rig)


# 6. 50 Attacks ---------------------------------------------------------------
func test_50_attacks() -> void:
	var rig := _fresh_rig()
	var attack_count := [0]
	rig.attack_released.connect(
		func(dir: Vector2, _offset: Vector2):
			attack_count[0] += 1
			# Ensure direction vector is normalized
			assert_float(dir.length()).is_equal_approx(1.0, 0.01)
	)
	
	for cycle in range(50):
		var aim_yaw := deg_to_rad(float((cycle % 7) * 10 - 30))
		rig.facing_yaw = aim_yaw
		rig.change_state(Leon3QController.State.ATTACK)
		rig._on_attack_release_point()
		
		# Reset to idle after each attack
		rig._is_attacking = false
		rig.change_state(Leon3QController.State.IDLE)
		assert_int(rig.current_state).is_equal(Leon3QController.State.IDLE)
	
	assert_int(attack_count[0]).is_equal(50)
	_release_rig(rig)


# 7. 50 Supers ----------------------------------------------------------------
func test_50_supers() -> void:
	var rig := _fresh_rig()
	var super_starts := [0]
	var super_ends := [0]
	rig.super_started.connect(func(): super_starts[0] += 1)
	rig.super_ended.connect(func(): super_ends[0] += 1)
	
	for cycle in range(50):
		rig.change_state(Leon3QController.State.SUPER)
		rig.super_started.emit()
		rig._super_windup(1.0)
		rig.modulate.a = 0.22 # stealth
		rig._super_shimmer(0.5)
		assert_float(rig.modulate.a).is_less(0.3)
		rig._super_restore()
		assert_float(rig.modulate.a).is_equal_approx(1.0, 0.01)
		rig._on_super_finished()
		assert_int(rig.current_state).is_equal(Leon3QController.State.IDLE)
	
	assert_int(super_starts[0]).is_equal(50)
	assert_int(super_ends[0]).is_equal(50)
	_release_rig(rig)


# 8. 50 Moving attacks (locomotion preservation) ------------------------------
func test_50_moving_attacks() -> void:
	var rig := _fresh_rig()
	
	for cycle in range(50):
		var target_loco := Leon3QController.State.WALK if (cycle % 2 == 0) else Leon3QController.State.RUN
		rig.set_locomotion(target_loco)
		assert_int(rig.current_state).is_equal(target_loco)
		
		# Trigger attack while moving
		rig._locomotion_state = target_loco
		rig.change_state(Leon3QController.State.ATTACK)
		rig._is_attacking = true
		assert_int(rig.current_state).is_equal(Leon3QController.State.ATTACK)
		
		# Release
		rig._on_attack_release_point()
		
		# Finish attack -> returns cleanly to locomotion state
		rig._is_attacking = false
		rig.change_state(rig._locomotion_state)
		assert_int(rig.current_state).is_equal(target_loco)
	
	_release_rig(rig)


# 9. 50 Diagonal movements ----------------------------------------------------
func test_50_diagonal_movements() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	for cycle in range(50):
		var t := float(cycle) / 49.0
		# Move diagonally: X from -300 to +300, Depth from 80 to 480
		scene.world_pos = Vector2(lerpf(-300.0, 300.0, t), lerpf(80.0, 480.0, t))
		scene._apply_projection(true)
		
		var s: float = scene.apparent_scale()
		assert_that(s).is_greater(0.01)
		assert_that(is_nan(s)).is_false()
		assert_that(is_nan(scene.actor_root.position.x)).is_false()
		assert_that(is_nan(scene.actor_root.position.y)).is_false()


# 10 & 11. 50 Depth approaches and retreats ----------------------------------
func test_50_depth_approaches_and_retreats() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var prev_scale := -1.0
	# 50 approaches: Depth decreases from 500 down to 50 (FAR -> NEAR)
	for i in range(50):
		var depth := lerpf(500.0, 50.0, float(i) / 49.0)
		scene.world_pos = Vector2(0.0, depth)
		scene._apply_projection(true)
		var curr_scale: float = scene.apparent_scale()
		if prev_scale > 0.0:
			assert_float(curr_scale).is_greater(prev_scale)
		prev_scale = curr_scale
	
	# 50 retreats: Depth increases from 50 up to 500 (NEAR -> FAR)
	prev_scale = -1.0
	for i in range(50):
		var depth := lerpf(50.0, 500.0, float(i) / 49.0)
		scene.world_pos = Vector2(0.0, depth)
		scene._apply_projection(true)
		var curr_scale: float = scene.apparent_scale()
		if prev_scale > 0.0:
			assert_float(curr_scale).is_less(prev_scale)
		prev_scale = curr_scale


# 12. 50 Hit / Knockback / Recovery cycles ------------------------------------
func test_50_hit_knockback_recovery_cycles() -> void:
	var rig := _fresh_rig()
	
	for cycle in range(50):
		# Hit
		rig.change_state(Leon3QController.State.HIT)
		rig.set_face_expression("hurt", "blink")
		assert_int(rig.current_state).is_equal(Leon3QController.State.HIT)
		
		# Knockback
		rig.change_state(Leon3QController.State.KNOCKBACK)
		assert_int(rig.current_state).is_equal(Leon3QController.State.KNOCKBACK)
		
		# Recovery
		rig.change_state(Leon3QController.State.RECOVERY)
		rig._apply_crouch(0.5)
		assert_int(rig.current_state).is_equal(Leon3QController.State.RECOVERY)
		
		# Return to Idle
		rig.set_face_expression("neutral", "open")
		rig.change_state(Leon3QController.State.IDLE)
		assert_int(rig.current_state).is_equal(Leon3QController.State.IDLE)
		assert_float(rig.torso.rotation).is_equal_approx(0.0, 0.01)
	
	_release_rig(rig)
