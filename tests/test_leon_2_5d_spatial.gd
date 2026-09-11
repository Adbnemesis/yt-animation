class_name TestLeon25DSpatial
extends GdUnitTestSuite

# ============================================================================
# LEON 2.5D SPATIAL FUNDAMENTALS — AUTOMATED VERIFICATION SUITE
# ----------------------------------------------------------------------------
# Validates the core spatial rules of the 2.5D engine:
# 1. Horizontal movement preserves scale at fixed depth.
# 2. Depth movement scales character monotonically (FAR = small, NEAR = large).
# 3. Depth reversal reverses scale trend.
# 4. Vertical jump/elevation preserves depth scale while moving up on screen.
# 5. Multiview selection transitions at correct angles.
# 6. Root/feet origin remains stable (<2px drift) across all 5 views.
# 7. Camera dolly toward stationary character increases apparent scale.
# 8. Projectile travel through depth scales according to camera projection.
# 9. Depth occlusion ordering follows world depth naturally.
# ============================================================================

const TEST_SCENE := "res://scenes/labs/leon_2_5d_spatial_test.tscn"

func test_horizontal_movement_preserves_scale() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var leon = scene.leon
	var cam = scene.camera
	
	# Place Leon at fixed midground depth Z=220, X=0
	leon.world_pos = Vector2(0.0, 220.0)
	leon.elevation = 0.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	
	var baseline_scale: float = leon.scale.x
	assert_that(baseline_scale).is_greater(0.0)
	
	# Move far left to X = -280.0 at same depth
	leon.world_pos.x = -280.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	
	var left_scale: float = leon.scale.x
	assert_that(absf(left_scale - baseline_scale)).is_less(0.0001)
	
	# Move far right to X = +280.0 at same depth
	leon.world_pos.x = 280.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	
	var right_scale: float = leon.scale.x
	assert_that(absf(right_scale - baseline_scale)).is_less(0.0001)

func test_depth_movement_scales_monotonically() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var leon = scene.leon
	
	# 1. FAR Marker (Z=480)
	leon.world_pos = Vector2(0.0, 480.0)
	leon.elevation = 0.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	var scale_far: float = leon.scale.x
	
	# 2. MID Marker (Z=220)
	leon.world_pos = Vector2(0.0, 220.0)
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	var scale_mid: float = leon.scale.x
	
	# 3. NEAR Marker (Z=60)
	leon.world_pos = Vector2(0.0, 60.0)
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	var scale_near: float = leon.scale.x
	
	# Verify progressive continuous scaling: NEAR > MID > FAR
	assert_that(scale_mid).is_greater(scale_far)
	assert_that(scale_near).is_greater(scale_mid)
	
	# Verify ground Y position: deeper objects sit higher on screen (smaller screen Y)
	var p_far = scene.camera.project(Vector2(0, 480), 0.0)
	var p_near = scene.camera.project(Vector2(0, 60), 0.0)
	assert_that(p_near.pos.y).is_greater(p_far.pos.y)

func test_depth_reversal_decreases_scale() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var leon = scene.leon
	
	# Start near, move far
	leon.world_pos = Vector2(0.0, 60.0)
	leon._apply_camera(true)
	var s1: float = leon.scale.x
	
	leon.world_pos = Vector2(0.0, 300.0)
	leon._apply_camera(true)
	var s2: float = leon.scale.x
	
	leon.world_pos = Vector2(0.0, 550.0)
	leon._apply_camera(true)
	var s3: float = leon.scale.x
	
	assert_that(s1).is_greater(s2)
	assert_that(s2).is_greater(s3)

func test_vertical_jump_elevation_preserves_scale() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var leon = scene.leon
	
	# Grounded at Z=220
	leon.world_pos = Vector2(0.0, 220.0)
	leon.elevation = 0.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	
	var ground_scale: float = leon.scale.x
	var ground_screen_y: float = leon.position.y
	
	# Jump / elevate Y to 80.0
	leon.elevation = 80.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	
	var jump_scale: float = leon.scale.x
	var jump_screen_y: float = leon.position.y
	
	# Scale must remain identical (Y movement does NOT scale!)
	assert_that(absf(jump_scale - ground_scale)).is_less(0.0001)
	# Screen Y moves UP on screen (smaller Y coordinate in Godot 2D)
	assert_that(jump_screen_y).is_less(ground_screen_y)

func test_multiview_selection_angles() -> void:
	# Check bucket boundaries in MultiviewController:
	# FRONT: |a| < 22.5°
	# FRONT_3Q: 22.5° <= |a| < 67.5°
	# SIDE: 67.5° <= |a| < 112.5°
	# BACK_3Q: 112.5° <= |a| < 157.5°
	# BACK: |a| >= 157.5°
	
	assert_that(MultiviewController._bucket_to_view(0.0)).is_equal(&"front")
	assert_that(MultiviewController._bucket_to_view(15.0)).is_equal(&"front")
	
	assert_that(MultiviewController._bucket_to_view(45.0)).is_equal(&"front_3q")
	assert_that(MultiviewController._bucket_to_mirror(45.0, &"front_3q")).is_false()
	assert_that(MultiviewController._bucket_to_mirror(-45.0, &"front_3q")).is_true()
	
	assert_that(MultiviewController._bucket_to_view(90.0)).is_equal(&"side")
	assert_that(MultiviewController._bucket_to_mirror(90.0, &"side")).is_false()
	assert_that(MultiviewController._bucket_to_mirror(-90.0, &"side")).is_true()
	
	assert_that(MultiviewController._bucket_to_view(135.0)).is_equal(&"back_3q")
	assert_that(MultiviewController._bucket_to_view(180.0)).is_equal(&"back")
	assert_that(MultiviewController._bucket_to_mirror(180.0, &"back")).is_false()

func test_multiview_root_stability() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var model: MultiviewController = scene.leon.model
	assert_that(model).is_not_null()
	
	# Verify each view scene root position is at (0, 0)
	for view_key in MultiviewController.VIEW_NODES.keys():
		var node_name: String = MultiviewController.VIEW_NODES[view_key]
		var view_node: Node2D = model.get_node_or_null(node_name)
		if view_node:
			assert_that(view_node.position.x).is_equal(0.0)
			assert_that(view_node.position.y).is_equal(0.0)

func test_camera_dolly_scales_character() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var leon = scene.leon
	var cam = scene.camera
	
	# Keep Leon stationary at (0, 220)
	leon.world_pos = Vector2(0.0, 220.0)
	leon.elevation = 0.0
	
	# Wide camera distance
	cam.cam_z = -300.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	var scale_wide: float = leon.scale.x
	
	# Close camera distance (dolly in)
	cam.cam_z = -50.0
	leon._apply_camera(true)
	await runner.simulate_frames(2)
	var scale_close: float = leon.scale.x
	
	# Dolly in must increase apparent scale
	assert_that(scale_close).is_greater(scale_wide)

func test_projectile_travel_and_scale() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var cam = scene.camera
	
	# Projectile at Near (Z=60) targeting far away
	var proj_near = scene.ProjectileScene.new()
	scene.add_child(proj_near)
	proj_near.setup(cam, Vector2(0, 60), Vector2(0, 800), 36.0)
	var scale_near_proj: float = proj_near.scale.x
	
	# Projectile at Far (Z=480) targeting further away
	var proj_far = scene.ProjectileScene.new()
	scene.add_child(proj_far)
	proj_far.setup(cam, Vector2(0, 480), Vector2(0, 800), 36.0)
	var scale_far_proj: float = proj_far.scale.x
	
	assert_that(scale_near_proj).is_greater(scale_far_proj)
	
	proj_near.queue_free()
	proj_far.queue_free()

func test_depth_occlusion_sorting() -> void:
	var runner := scene_runner(TEST_SCENE)
	var scene = runner.scene()
	scene.auto_start_demo = false
	if scene._demo_tween and scene._demo_tween.is_valid():
		scene._demo_tween.kill()
	scene.demo_running = false
	
	var leon_a = scene.leon
	var leon_b = scene.leon_b
	
	# Case 1: Leon A is near (Z=100), Leon B is far (Z=400)
	leon_a.world_pos = Vector2(0, 100)
	leon_b.world_pos = Vector2(0, 400)
	leon_a._apply_camera(true)
	leon_b._apply_camera(true)
	await runner.simulate_frames(2)
	
	assert_that(leon_a.z_index).is_greater(leon_b.z_index)
	
	# Case 2: Reverse depths: Leon A is far (Z=400), Leon B is near (Z=100)
	leon_a.world_pos = Vector2(0, 400)
	leon_b.world_pos = Vector2(0, 100)
	leon_a._apply_camera(true)
	leon_b._apply_camera(true)
	await runner.simulate_frames(2)
	
	assert_that(leon_b.z_index).is_greater(leon_a.z_index)
