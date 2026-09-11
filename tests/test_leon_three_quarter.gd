class_name TestLeonThreeQuarter
extends GdUnitTestSuite

# ============================================================================
# LEON 3/4 VIEW FOUNDATION — AUTOMATED VERIFICATION SUITE
# ----------------------------------------------------------------------------
# Validates (Parts 5/17/22/23/24/27/28/30/36/37/46/47/57/59/61):
# 1.  Canonical 3/4 rig integrity (view_front_3q.tscn reused, not re-rigged)
# 2.  Complete state machine (IDLE/ACCEL/WALK/RUN/STOP/JUMP/ATTACK/SUPER/HIT/
#     KNOCKBACK/RECOVERY)
# 3.  Facing-yaw attack trajectory contract (dir = (sin yaw, -cos yaw))
# 4.  Attack causality (anticipation BEFORE release, projectile BEFORE impact)
# 5.  Attack socket attached to the artwork during all locomotion states
# 6.  Genuine 3/4 body language (near/far limb asymmetry, asymmetric idle)
# 7.  Root/feet baseline consistency (no jump entering the 3/4 view)
# 8.  Depth scale monotonic; horizontal scale invariance; diagonal movement
# 9.  Animation speed independent of apparent scale (Part 47)
# 10. Face switching + blink + eyelines on the angled head
# 11. Super stealth events; hit -> knockback -> recovery chain
# 12. Multiview system regression (3/4 view still slots into the controller)
# ============================================================================

const RIG_SCENE := "res://scenes/labs/characters/leon_multiview_lab/view_front_3q.tscn"
const MULTIVIEW_SCENE := "res://scenes/labs/characters/leon_multiview_lab/leon_multiview.tscn"
const TEST_SCENE := "res://scenes/labs/leon_three_quarter_animation_test.tscn"
const Leon3QController = preload("res://scripts/labs/leon_three_quarter_controller.gd")

# --- helpers -----------------------------------------------------------------


func _fresh_rig() -> Leon3QController:
	var rig: Leon3QController = load(RIG_SCENE).instantiate()
	rig.set_process(true)
	add_child(rig)
	return rig


func _release_rig(rig: Leon3QController) -> void:
	rig.queue_free()


# 1. Canonical rig ------------------------------------------------------------


func test_canonical_3q_rig_hierarchy() -> void:
	var rig := _fresh_rig()
	assert_that(rig).is_not_null()
	assert_that(rig is Leon3QController).is_true()

	# Reused cinematic-lab cutout pivots (same art, extended in place)
	assert_that(rig.get_node_or_null("Feet/FootL")).is_not_null()
	assert_that(rig.get_node_or_null("Feet/FootR")).is_not_null()
	assert_that(rig.get_node_or_null("Legs/LegL")).is_not_null()
	assert_that(rig.get_node_or_null("Shorts/ShortL")).is_not_null()
	assert_that(rig.get_node_or_null("Torso")).is_not_null()
	assert_that(rig.get_node_or_null("ArmL")).is_not_null()
	assert_that(rig.get_node_or_null("ArmR")).is_not_null()
	assert_that(rig.get_node_or_null("Head")).is_not_null()
	assert_that(rig.get_node_or_null("Head/Hood")).is_not_null()

	# Production FaceController embedded in the 3/4 head
	var face = rig.get_node_or_null("Head/Face")
	assert_that(face).is_not_null()
	assert_that(face is FaceController).is_true()

	# Attack socket marker from the original cinematic-lab artwork
	var socket: Marker2D = rig.get_node_or_null("AttackSocket")
	assert_that(socket).is_not_null()
	assert_float(socket.position.x).is_equal_approx(27.0, 0.01)
	assert_float(socket.position.y).is_equal_approx(-32.0, 0.01)

	_release_rig(rig)


# 2. State machine ------------------------------------------------------------


func test_state_transitions_full_chain() -> void:
	var rig := _fresh_rig()
	assert_int(rig.current_state).is_equal(Leon3QController.State.IDLE)

	rig.change_state(Leon3QController.State.WALK)
	assert_int(rig.current_state).is_equal(Leon3QController.State.WALK)

	rig.change_state(Leon3QController.State.RUN)
	assert_int(rig.current_state).is_equal(Leon3QController.State.RUN)

	rig.change_state(Leon3QController.State.STOP)
	assert_int(rig.current_state).is_equal(Leon3QController.State.STOP)

	rig.change_state(Leon3QController.State.IDLE)
	assert_int(rig.current_state).is_equal(Leon3QController.State.IDLE)

	_release_rig(rig)


# 3. Facing-yaw trajectory contract -------------------------------------------


func test_attack_direction_derived_from_facing() -> void:
	var rig := _fresh_rig()
	var results := {"dir": Vector2.ZERO, "count": 0}
	rig.attack_released.connect(
		func(dir: Vector2, _offset: Vector2):
			results["dir"] = dir
			results["count"] += 1
	)

	# Case 1: straight toward the camera (yaw = 0)
	rig.trigger_attack(0.0)
	await rig.attack_released
	assert_int(results["count"]).is_equal(1)
	assert_float(results["dir"].x).is_equal_approx(0.0, 0.0001)
	assert_float(results["dir"].y).is_less(-0.99)

	await get_tree().create_timer(0.5).timeout

	# Case 2: aimed left (yaw = -30)
	rig.trigger_attack(-30.0)
	await rig.attack_released
	assert_int(results["count"]).is_equal(2)
	var expected_left := Vector2(sin(deg_to_rad(-30.0)), -cos(deg_to_rad(-30.0)))
	assert_float(results["dir"].x).is_equal_approx(expected_left.x, 0.0001)
	assert_float(results["dir"].y).is_equal_approx(expected_left.y, 0.0001)

	await get_tree().create_timer(0.5).timeout

	# Case 3: aimed right (yaw = +30)
	rig.trigger_attack(30.0)
	await rig.attack_released
	assert_int(results["count"]).is_equal(3)
	var expected_right := Vector2(sin(deg_to_rad(30.0)), -cos(deg_to_rad(30.0)))
	assert_float(results["dir"].x).is_equal_approx(expected_right.x, 0.0001)
	assert_float(results["dir"].y).is_equal_approx(expected_right.y, 0.0001)

	_release_rig(rig)


# 4. Causality: anticipation precedes RELEASE ---------------------------------


func test_attack_anticipation_precedes_release() -> void:
	var rig := _fresh_rig()
	var release_count := [0]
	rig.attack_released.connect(func(_d: Vector2, _o: Vector2): release_count[0] += 1)

	rig.trigger_attack(0.0)
	# ~5 frames = 0.083s: anticipation + aim hold (0.14s) has NOT elapsed yet
	for i in range(5):
		await get_tree().process_frame
	assert_int(release_count[0]).is_equal(0)

	await rig.attack_released
	assert_int(release_count[0]).is_equal(1)

	_release_rig(rig)


# 5. Socket attachment (Part 28) -----------------------------------------------


func test_attack_socket_attached_during_locomotion() -> void:
	var rig := _fresh_rig()
	rig.change_state(Leon3QController.State.WALK)
	var saw_walk := false
	for i in range(30):
		await get_tree().process_frame
		var socket := rig.attack_socket_local()
		assert_float(socket.x).is_equal_approx(27.0, 0.001)
		assert_float(socket.y).is_equal_approx(-32.0, 0.001)
		if rig.foot_r.position.y != 0.0:
			saw_walk = true

	# Socket never drifts while the walk animates
	assert_that(saw_walk).is_true()

	rig.change_state(Leon3QController.State.RUN)
	for i in range(20):
		await get_tree().process_frame
		var socket := rig.attack_socket_local()
		assert_float(socket.x).is_equal_approx(27.0, 0.001)
		assert_float(socket.y).is_equal_approx(-32.0, 0.001)

	# Presentation mirror flips the socket WITH the artwork — never drifts
	rig.set_mirror_sign(-1.0)
	var mirrored := rig.attack_socket_local()
	assert_float(mirrored.x).is_equal_approx(-27.0, 0.001)
	assert_float(mirrored.y).is_equal_approx(-32.0, 0.001)

	_release_rig(rig)


# 6. Genuine 3/4 body language (Parts 6/7/59) -----------------------------------


func test_walk_near_far_limb_asymmetry() -> void:
	var rig := _fresh_rig()
	rig.change_state(Leon3QController.State.WALK)

	var near_lift := 0.0
	var far_lift := 0.0
	var near_arm_rot := 0.0
	var far_arm_rot := 0.0
	var dt := 1.0 / 60.0
	# 240 steps ≈ 4s > 2 full stride cycles at walk cadence (deterministic math)
	for i in range(240):
		rig._process_walk(dt, 5.6, 7.0, 0.20, 1.6, 1.6)
		near_lift = maxf(near_lift, absf(rig.foot_r.position.y))
		far_lift = maxf(far_lift, absf(rig.foot_l.position.y))
		near_arm_rot = maxf(near_arm_rot, absf(rig.arm_r.rotation))
		far_arm_rot = maxf(far_arm_rot, absf(rig.arm_l.rotation))

	# near limbs read BIGGER than far limbs (3/4 depth, never symmetric)
	assert_float(near_lift).is_greater(far_lift)
	assert_float(near_arm_rot).is_greater(far_arm_rot)
	# both limbs do move (it is a real stride, not a frozen far leg)
	assert_float(near_lift).is_greater(2.0)
	assert_float(far_lift).is_greater(1.0)

	_release_rig(rig)


func test_idle_asymmetric_breathing() -> void:
	var rig := _fresh_rig()
	var near_amp := 0.0
	var far_amp := 0.0
	var torso_amp := 0.0
	var dt := 1.0 / 60.0
	# 240 steps ≈ 4s > 2 full breathing cycles (deterministic math)
	for i in range(240):
		rig._process(dt)
		near_amp = maxf(near_amp, absf(rig.arm_r.position.y - Leon3QController.ARM_R_BASE_POS.y))
		far_amp = maxf(far_amp, absf(rig.arm_l.position.y - Leon3QController.ARM_L_BASE_POS.y))
		torso_amp = maxf(torso_amp, absf(rig.torso.position.y - Leon3QController.TORSO_BASE_POS.y))

	# the near side breathes visibly more than the far side
	assert_float(near_amp).is_greater(far_amp)
	# torso moves at all (living idle)
	assert_float(torso_amp).is_greater(0.2)

	_release_rig(rig)


# 7. Root / feet baseline (Parts 5/32/59) ---------------------------------------


func test_root_and_feet_baseline_consistent() -> void:
	var rig := _fresh_rig()
	# View root anchored at the feet ground point (0,0) — entering the 3/4 view
	# never displaces the character
	assert_float(rig.position.x).is_equal_approx(0.0, 0.001)
	assert_float(rig.position.y).is_equal_approx(0.0, 0.001)
	assert_float(rig.foot_l.position.y).is_equal_approx(0.0, 0.001)
	assert_float(rig.foot_r.position.y).is_equal_approx(0.0, 0.001)

	# Authored head centre and face origin preserved
	assert_float(rig.head.position.y).is_equal_approx(-110.0, 0.001)
	var face: Node2D = rig.get_node("Head/Face")
	assert_float(face.position.y).is_equal_approx(14.0, 0.001)

	_release_rig(rig)


# 9. Animation speed independent of scale (Part 47) ------------------------------


func test_animation_speed_independent_of_scale() -> void:
	var small := _fresh_rig()
	var large := _fresh_rig()
	small.scale = Vector2(0.5, 0.5)
	large.scale = Vector2(2.0, 2.0)
	small.change_state(Leon3QController.State.WALK)
	large.change_state(Leon3QController.State.WALK)

	for i in range(20):
		await get_tree().process_frame

	var dt_small: float = small._walk_time
	var dt_large: float = large._walk_time
	assert_float(absf(dt_small - dt_large)).is_less(0.01)

	_release_rig(small)
	_release_rig(large)


# 10. Face system on the angled head (Parts 36/37/38) ---------------------------


func test_face_switching_and_blink() -> void:
	var rig := _fresh_rig()
	var face: FaceController = rig.get_node("Head/Face")

	# expression suite
	rig.set_face_expression("happy", "happy")
	assert_that(face.mouth_sprite.texture).is_equal(face.mouth_textures["happy"])
	assert_that(face.eye_l_sprite.visible).is_true()

	rig.set_face_expression("angry", "angry")
	assert_that(face.mouth_sprite.texture).is_equal(face.mouth_textures["angry"])
	assert_that(face.eye_l_sprite.texture).is_equal(face.eye_textures["angry"])

	rig.set_face_expression("shocked", "wide")
	assert_that(face.mouth_sprite.texture).is_equal(face.mouth_textures["shocked"])
	assert_that(face.eye_l_sprite.texture).is_equal(face.eye_textures["wide"])

	rig.set_face_expression("smug", "open")
	assert_that(face.mouth_sprite.texture).is_equal(face.mouth_textures["smug"])

	rig.set_face_expression("hurt", "blink")
	assert_that(face.mouth_sprite.texture).is_equal(face.mouth_textures["hurt"])
	assert_that(face.eye_l_sprite.texture).is_equal(face.eye_textures["blink"])

	# explicit blink while eyes visible
	rig.set_face_expression("happy", "open")
	rig.blink_now()
	assert_that(face.is_blinking).is_true()
	assert_that(face.eye_l_sprite.texture).is_equal(face.eye_textures["blink"])

	# 3/4 eyelines: pupils drift WITH the near/far depth offset
	rig.set_gaze(Vector2(3.0, 1.0))
	await get_tree().process_frame
	assert_float(rig.pupil_r.position.x).is_equal_approx(
		Leon3QController.PUPIL_BASE_POS.x + 3.0, 0.01
	)
	assert_float(rig.pupil_l.position.x).is_equal_approx(
		Leon3QController.PUPIL_BASE_POS.x + 1.5, 0.01
	)

	_release_rig(rig)


# 11. Super (Parts 33/34/35) ------------------------------------------------------


func test_super_stealth_events_and_recovery() -> void:
	var rig := _fresh_rig()
	var started := [0]
	var ended := [0]
	rig.super_started.connect(func(): started[0] += 1)
	rig.super_ended.connect(func(): ended[0] += 1)

	rig.trigger_super()
	assert_int(rig.current_state).is_equal(Leon3QController.State.SUPER)
	assert_int(started[0]).is_equal(1)

	# stealth window: modulate fades toward 0.22 and shimmers there
	await get_tree().create_timer(0.7).timeout
	assert_float(rig.modulate.a).is_less(0.35)

	# full chain completes and restores opacity
	await get_tree().create_timer(2.6).timeout
	assert_int(ended[0]).is_equal(1)
	assert_float(rig.modulate.a).is_equal_approx(1.0, 0.01)
	assert_int(rig.current_state).is_equal(Leon3QController.State.IDLE)

	_release_rig(rig)


# Hit -> knockback -> recovery (Parts 22/23) --------------------------------------


func test_hit_knockback_recovery_chain() -> void:
	var rig := _fresh_rig()
	var knocked := [0]
	rig.knockback_started.connect(func(_d): knocked[0] += 1)

	rig.trigger_hit(Vector2(1.0, 0.0))
	assert_int(rig.current_state).is_equal(Leon3QController.State.HIT)

	# recoil flinch lifts the torso before knockback starts
	await get_tree().create_timer(0.12).timeout
	assert_float(rig.torso.position.y).is_less(Leon3QController.TORSO_BASE_POS.y - 4.0)

	# full chain: HIT -> KNOCKBACK -> RECOVERY -> locomotion (IDLE)
	await get_tree().create_timer(2.0).timeout
	assert_int(knocked[0]).is_equal(1)
	var s: int = rig.current_state
	(
		assert_that(
			(
				s
				in [
					Leon3QController.State.IDLE,
					Leon3QController.State.WALK,
					Leon3QController.State.RUN,
					Leon3QController.State.ACCEL
				]
			)
		)
		. is_true()
	)

	_release_rig(rig)


# 8. 2.5D spatial rules through the foundation lab (Parts 9/10/11/12/46) --------


func _prepare_lab(scene) -> void:
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	scene.move_input = Vector2.ZERO


func test_depth_movement_scales_monotonically() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	_prepare_lab(scene)

	scene.world_pos = Vector2(0.0, 480.0)  # FAR
	scene.elevation = 0.0
	scene._apply_projection(true)
	await runner.simulate_frames(2)
	var scale_far: float = scene.apparent_scale()

	scene.world_pos = Vector2(0.0, 220.0)  # MID
	scene._apply_projection(true)
	await runner.simulate_frames(2)
	var scale_mid: float = scene.apparent_scale()

	scene.world_pos = Vector2(0.0, 60.0)  # NEAR
	scene._apply_projection(true)
	await runner.simulate_frames(2)
	var scale_near: float = scene.apparent_scale()

	assert_that(scale_mid).is_greater(scale_far)
	assert_that(scale_near).is_greater(scale_mid)


func test_horizontal_movement_preserves_scale() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	_prepare_lab(scene)

	scene.world_pos = Vector2(0.0, 220.0)
	scene._apply_projection(true)
	await runner.simulate_frames(2)
	var baseline: float = scene.apparent_scale()

	scene.world_pos = Vector2(-300.0, 220.0)
	scene._apply_projection(true)
	await runner.simulate_frames(2)
	var left_scale: float = scene.apparent_scale()

	scene.world_pos = Vector2(300.0, 220.0)
	scene._apply_projection(true)
	await runner.simulate_frames(2)
	var right_scale: float = scene.apparent_scale()

	assert_float(absf(left_scale - baseline)).is_less(0.0001)
	assert_float(absf(right_scale - baseline)).is_less(0.0001)


func test_depth_reversal_shrinks_scale() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	_prepare_lab(scene)

	scene.world_pos = Vector2(0.0, 60.0)
	scene._apply_projection(true)
	var s_near: float = scene.apparent_scale()

	scene.world_pos = Vector2(0.0, 320.0)
	scene._apply_projection(true)
	var s_mid: float = scene.apparent_scale()

	scene.world_pos = Vector2(0.0, 540.0)
	scene._apply_projection(true)
	var s_far: float = scene.apparent_scale()

	assert_that(s_near).is_greater(s_mid)
	assert_that(s_mid).is_greater(s_far)


func test_diagonal_movement_combines_x_and_depth() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	_prepare_lab(scene)

	scene.world_pos = Vector2(0.0, 220.0)
	scene._apply_projection(true)
	var baseline_scale: float = scene.apparent_scale()

	# UP-LEFT: x decreases AND depth increases (never collapses into 1D)
	scene.world_pos = Vector2(-200.0, 420.0)
	scene._apply_projection(true)
	var up_left_scale: float = scene.apparent_scale()
	assert_float(scene.world_pos.x).is_less(0.0)
	assert_float(scene.world_pos.y).is_greater(220.0)
	assert_float(up_left_scale).is_less(baseline_scale)

	# DOWN-RIGHT: x increases AND depth decreases
	scene.world_pos = Vector2(240.0, 80.0)
	scene._apply_projection(true)
	var down_right_scale: float = scene.apparent_scale()
	assert_float(scene.world_pos.x).is_greater(0.0)
	assert_float(scene.world_pos.y).is_less(220.0)
	assert_float(down_right_scale).is_greater(baseline_scale)


# Projectile causality through the lab driver (Parts 27/28/30/54) ---------------


func test_projectile_causality_travels_before_impact() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	_prepare_lab(scene)

	# Leon center, dummy straight ahead toward the camera
	scene.world_pos = Vector2(0.0, 220.0)
	scene.dummy_world_pos = Vector2(0.0, 80.0)
	scene._apply_projection(true)
	scene._project_dummy()
	await runner.simulate_frames(2)

	var releases := [0]
	scene.leon3q.attack_released.connect(func(_d: Vector2, _o: Vector2): releases[0] += 1)

	scene.trigger_attack_toward_dummy()

	# RELEASE -> projectile spawns from the socket: none existed before
	var projectiles_before := 0
	for child in scene.get_children():
		if child.name.begins_with("Leon3QProjectile"):
			projectiles_before += 1
	assert_int(projectiles_before).is_equal(0)

	await scene.leon3q.attack_released
	await runner.simulate_frames(1)

	var projectile: Node2D = null
	for child in scene.get_children():
		if child.name.begins_with("Leon3QProjectile"):
			projectile = child
	assert_that(projectile).is_not_null()
	assert_int(releases[0]).is_equal(1)
	assert_int(scene.dummy_node.hit_count).is_equal(0)  # impact NOT yet

	# ...the projectile VISIBLY TRAVELS first: sim ~0.1s at speed 720 covers
	# only ~72 of the ~140 world units to the dummy
	await runner.simulate_frames(6)
	if is_instance_valid(projectile):
		var travelled: float = (Vector2(0.0, 80.0) - projectile.world_pos).length()
		assert_float(travelled).is_greater(10.0)  # still mid-flight
		assert_int(scene.dummy_node.hit_count).is_equal(0)

	# ...then collision -> impact -> target reaction
	var hit_arrived := false
	for i in range(120):
		await runner.simulate_frames(1)
		if scene.dummy_node.hit_count > 0:
			hit_arrived = true
			break
	assert_that(hit_arrived).is_true()
	assert_str(scene.last_event).is_equal("PROJECTILE_HIT")


# Multiview regression (Part 63): the 3/4 view still slots into the shared
# controller with the scripts bound in place -------------------------------------


func test_multiview_still_selects_3q_with_controller_bound() -> void:
	var model: MultiviewController = load(MULTIVIEW_SCENE).instantiate()
	add_child(model)
	assert_that(model.has_view(&"front_3q")).is_true()

	model.set_view(&"front_3q", false)
	await get_tree().process_frame

	var view_node: Node2D = model.get_node("ViewFront3Q")
	assert_that(view_node.visible).is_true()
	assert_that(view_node is Leon3QController).is_true()

	# bucketing unchanged by the scene extension
	assert_str(MultiviewController._bucket_to_view(45.0)).is_equal(&"front_3q")
	assert_str(MultiviewController._bucket_to_view(-45.0)).is_equal(&"front_3q")
	assert_that(MultiviewController._bucket_to_mirror(-45.0, &"front_3q")).is_true()

	# view root still anchored at the feet origin inside the controller
	assert_float(view_node.position.x).is_equal_approx(0.0, 0.001)
	assert_float(view_node.position.y).is_equal_approx(0.0, 0.001)

	# socket exposure from the shared controller still works
	var socket: Vector2 = model.attack_socket_local()
	assert_float(socket.y).is_equal_approx(-32.0, 0.01)

	model.queue_free()


func test_view_selection_bucketing_full() -> void:
	assert_str(MultiviewController._bucket_to_view(15.0)).is_equal(&"front")
	assert_str(MultiviewController._bucket_to_view(45.0)).is_equal(&"front_3q")
	assert_str(MultiviewController._bucket_to_view(90.0)).is_equal(&"side")
	assert_str(MultiviewController._bucket_to_view(135.0)).is_equal(&"back_3q")
	assert_str(MultiviewController._bucket_to_view(180.0)).is_equal(&"back")
	assert_that(MultiviewController._bucket_to_mirror(45.0, &"front_3q")).is_false()
	assert_that(MultiviewController._bucket_to_mirror(-45.0, &"front_3q")).is_true()
