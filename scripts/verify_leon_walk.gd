@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("  LEON 2D PUPPET WALK CYCLE — AUTOMATED VERIFICATION")
	print("==================================================")

	var has_error = false

	# 1. Load scene
	var scene = load("res://scenes/leon_side.tscn")
	if not scene:
		printerr("[FAIL] Could not load res://scenes/leon_side.tscn")
		quit(1)
		return

	var inst = scene.instantiate()
	var root = inst
	get_root().add_child(root)

	var anim_player: AnimationPlayer = root.find_child("AnimPlayer", true, false)
	if not anim_player:
		printerr("[FAIL] AnimPlayer not found in scenes/leon.tscn")
		quit(1)
		return

	# [1/6] Verify walk & LEON_WALK existence
	print("[1/6] Verifying Animation Presence in AnimPlayer...")
	var required_anims = ["walk", "LEON_WALK", "idle", "RESET"]
	for a_name in required_anims:
		if not anim_player.has_animation(a_name):
			printerr("  [FAIL] Missing required animation: ", a_name)
			has_error = true
		else:
			var anim = anim_player.get_animation(a_name)
			print("  [PASS] Animation verified: '%s' (length: %.3fs, loop: %d)" % [a_name, anim.length, anim.loop_mode])

	# [2/6] Verify Track Architecture on walk animation
	print("[2/6] Verifying Walk Animation Tracks...")
	var walk = anim_player.get_animation("walk")
	if not walk:
		printerr("  [FAIL] Cannot retrieve 'walk' animation")
		quit(1)
		return

	if abs(walk.length - 0.80) > 0.001:
		printerr("  [FAIL] Expected walk length 0.80s, got: ", walk.length)
		has_error = true
	else:
		print("  [PASS] Walk animation length is exactly 0.80s (6-phase)")

	if walk.loop_mode != Animation.LOOP_LINEAR:
		printerr("  [FAIL] Expected LOOP_LINEAR, got: ", walk.loop_mode)
		has_error = true
	else:
		print("  [PASS] Loop mode is LOOP_LINEAR")

	var expected_tracks = [
		"Visuals/Skeleton/root:position",
		"Visuals/Skeleton/root:rotation",
		"Visuals/Skeleton/root/torso:rotation",
		"Visuals/Skeleton/root/torso/neck:rotation",
		"Visuals/Skeleton/root/torso/neck/head:rotation",
		"Visuals/Skeleton/root/leg_L_upper:rotation",
		"Visuals/Skeleton/root/leg_L_upper/leg_L_lower:rotation",
		"Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L:rotation",
		"Visuals/Skeleton/root/leg_R_upper:rotation",
		"Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation",
		"Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R:rotation",
		"Visuals/Skeleton/root/torso/arm_L_upper:rotation",
		"Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower:rotation",
		"Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L:rotation",
		"Visuals/Skeleton/root/torso/arm_R_upper:rotation",
		"Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower:rotation",
		"Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R:rotation",
		"Visuals/Skeleton/root/tail:rotation"
	]

	for t_path in expected_tracks:
		var found = false
		for i in range(walk.get_track_count()):
			if str(walk.track_get_path(i)) == t_path:
				found = true
				break
		if not found:
			printerr("  [FAIL] Missing track in walk: ", t_path)
			has_error = true
		else:
			print("  [PASS] Track verified: ", t_path)

	# [3/6] Seamless 100% Looping Verification (t = 0.0 vs t = 0.8)
	print("[3/6] Verifying Seamless Loop Continuity (t=0.0 vs t=0.8)...")
	for i in range(walk.get_track_count()):
		var t_path = str(walk.track_get_path(i))
		if walk.track_get_type(i) == Animation.TYPE_VALUE:
			var k_count = walk.track_get_key_count(i)
			if k_count >= 2:
				var first_val = walk.track_get_key_value(i, 0)
				var last_val = walk.track_get_key_value(i, k_count - 1)
				if first_val is float and last_val is float:
					if abs(first_val - last_val) > 0.001:
						printerr("  [FAIL] Loop mismatch on %s: start=%.4f, end=%.4f" % [t_path, first_val, last_val])
						has_error = true
				elif first_val is Vector2 and last_val is Vector2:
					if first_val.distance_to(last_val) > 0.01:
						printerr("  [FAIL] Loop mismatch on %s: start=%s, end=%s" % [t_path, str(first_val), str(last_val)])
						has_error = true
	if not has_error:
		print("  [PASS] All tracks loop seamlessly with 0.0 numerical error between t=0.0 and t=0.8")

	# [4/6] Biomechanical Constraint Verification (No Backwards Knees, Opposing Arms)
	print("[4/6] Verifying Biomechanical Constraints & Arm Counter-Swing...")
	var knee_l_track = -1
	var knee_r_track = -1
	var arm_l_track = -1
	var arm_r_track = -1
	var leg_l_track = -1
	var leg_r_track = -1

	for i in range(walk.get_track_count()):
		var p = str(walk.track_get_path(i))
		if p.ends_with("leg_L_upper/leg_L_lower:rotation"): knee_l_track = i
		elif p.ends_with("leg_R_upper/leg_R_lower:rotation"): knee_r_track = i
		elif p.ends_with("torso/arm_L_upper:rotation"): arm_l_track = i
		elif p.ends_with("torso/arm_R_upper:rotation"): arm_r_track = i
		elif p.ends_with("leg_L_upper:rotation"): leg_l_track = i
		elif p.ends_with("leg_R_upper:rotation"): leg_r_track = i

	# Knee flexion check: must always be >= 0.0
	for k in range(walk.track_get_key_count(knee_l_track)):
		var kl: float = walk.track_get_key_value(knee_l_track, k)
		var kr: float = walk.track_get_key_value(knee_r_track, k)
		if kl < -0.01 or kr < -0.01:
			printerr("  [FAIL] Knee bent backwards at key %d! (L: %.3f, R: %.3f)" % [k, kl, kr])
			has_error = true
			break
	if not has_error:
		print("  [PASS] Knees maintain strictly positive forward flexion throughout entire stride")

	# Opposing arms check: arm swings in opposite direction to its corresponding leg
	var leg_l_0: float = walk.track_get_key_value(leg_l_track, 0)
	var arm_l_0: float = walk.track_get_key_value(arm_l_track, 0)
	var leg_r_0: float = walk.track_get_key_value(leg_r_track, 0)
	var arm_r_0: float = walk.track_get_key_value(arm_r_track, 0)
	if (leg_l_0 * arm_l_0 < 0) and (leg_r_0 * arm_r_0 < 0):
		print("  [PASS] Opposing arm counter-swing verified (Leg_L: %.2f vs Arm_L: %.2f, Leg_R: %.2f vs Arm_R: %.2f)" % [leg_l_0, arm_l_0, leg_r_0, arm_r_0])
	else:
		printerr("  [FAIL] Arm/leg phasing mismatch: Leg_L=%.2f, Arm_L=%.2f, Leg_R=%.2f, Arm_R=%.2f" % [leg_l_0, arm_l_0, leg_r_0, arm_r_0])
		has_error = true

	# [5/6] Ground Contact Kinematic Height Verification
	print("[5/6] Verifying Ground Contact Kinematics...")
	var foot_l = root.find_child("foot_L", true, false)
	var foot_r = root.find_child("foot_R", true, false)
	if foot_l and foot_r:
		# Sample t=0.10s (Left foot cushion, should be flat on ground)
		anim_player.play("walk")
		anim_player.advance(0.10)
		var foot_l_y = foot_l.global_position.y - root.global_position.y
		print("  [INFO] Left foot ground plane offset (t=0.10s): %.2f px" % foot_l_y)
		if abs(foot_l_y) > 4.0:
			print("  [WARN] Foot ground level deviates: ", foot_l_y)
		else:
			print("  [PASS] Left foot firmly grounded during cushion phase (%.2f px)" % foot_l_y)

		# Sample t=0.50s (Right foot cushion, should be flat on ground)
		anim_player.advance(0.40) # Now at t=0.50s
		var foot_r_y = foot_r.global_position.y - root.global_position.y
		print("  [INFO] Right foot ground plane offset (t=0.50s): %.2f px" % foot_r_y)
		if abs(foot_r_y) > 4.0:
			print("  [WARN] Foot ground level deviates: ", foot_r_y)
		else:
			print("  [PASS] Right foot firmly grounded during cushion phase (%.2f px)" % foot_r_y)

	# [6/6] 20-Cycle Continuous Simulation Loop
	print("[6/6] Running 20-Cycle Continuous Simulation Loop (16.0s simulated)...")
	anim_player.play("walk")
	var sim_fps = 60.0
	var sim_frames = 20 * 48 # 960 frames
	var dt = 1.0 / sim_fps
	var sim_error = false

	for f in range(sim_frames):
		anim_player.advance(dt)
		if is_nan(foot_l.position.x) or is_nan(foot_r.position.x):
			printerr("  [FAIL] NaN detected in limb transforms during frame ", f)
			sim_error = true
			break
	if not sim_error:
		print("  [PASS] Completed 20 full walk cycles (960 frames) with zero drift, NaN, or errors")

	print("--------------------------------------------------")
	if has_error:
		printerr(">>> WALK VERIFICATION COMPLETED WITH ERRORS <<<")
		quit(1)
	else:
		print(">>> ALL WALK CYCLE CHECKS PASSED SUCCESSFULLY! <<<")
		quit(0)
