# GdUnit4 test suite covering Phantom Camera 2D integration
class_name TestPhantomCamera
extends GdUnitTestSuite

func test_phantom_camera_follow_zoom_and_switching() -> void:
	var runner := scene_runner("res://scenes/camera_test.tscn")
	var scene: CameraTestController = runner.scene()
	assert_that(scene).is_not_null()

	var cam2d = scene.camera_2d
	var pcam_follow = scene.pcam_follow
	var pcam_wide = scene.pcam_wide
	var pcam_closeup = scene.pcam_closeup
	var leon = scene.leon

	assert_that(cam2d).is_not_null()
	assert_that(pcam_follow).is_not_null()
	assert_that(pcam_wide).is_not_null()
	assert_that(pcam_closeup).is_not_null()
	assert_that(leon).is_not_null()

	# Settle for 10 frames to let Phantom Camera attach and initialize
	await runner.simulate_frames(10)

	# 1. Verify Follow Cam is active and zoom is 1.0
	assert_that(scene.current_cam_state).is_equal(scene.CamState.FOLLOW)
	assert_that(pcam_follow.priority).is_greater(pcam_wide.priority)
	assert_float(cam2d.zoom.x).is_equal_approx(1.0, 0.05)

	# 2. Verify Damped Follow: Move Leon and observe camera follow with damping
	var initial_cam_x = cam2d.global_position.x
	leon.position.x += 200.0
	# Camera should not teleport instantly due to damping
	await runner.simulate_frames(2)
	assert_that(cam2d.global_position.x).is_less(leon.position.x)
	# After 30 frames, camera has moved significantly towards Leon (smooth damping)
	await runner.simulate_frames(30)
	assert_that(cam2d.global_position.x).is_greater(initial_cam_x + 80.0)

	# 3. Switch to Wide Cam (priority switch + zoom change)
	scene.set_camera_state(scene.CamState.WIDE)
	# Allow tween transition frames
	await runner.simulate_frames(40)

	assert_that(scene.current_cam_state).is_equal(scene.CamState.WIDE)
	assert_that(pcam_wide.priority).is_greater(pcam_follow.priority)
	assert_float(cam2d.zoom.x).is_less(0.8)

	# 4. Switch to Close-Up Cam (zoom punch)
	scene.set_camera_state(scene.CamState.CLOSEUP)
	await runner.simulate_frames(40)

	assert_that(scene.current_cam_state).is_equal(scene.CamState.CLOSEUP)
	assert_that(pcam_closeup.priority).is_greater(pcam_wide.priority)
	assert_float(cam2d.zoom.x).is_greater(1.3)
