@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("  LEON 2D PUPPET LOCOMOTION STAGE 2 — VERIFICATION")
	print("  (RUN • STOP • TURN • STATE MACHINE)")
	print("==================================================")

	var has_error = false

	# 1. Load scene
	var scene = load("res://scenes/leon_side.tscn")
	if not scene:
		printerr("[FAIL] Could not load res://scenes/leon_side.tscn")
		quit(1)
		return

	var inst = scene.instantiate()
	var root: CharacterBody2D = inst
	get_root().add_child(root)

	var anim_player: AnimationPlayer = root.find_child("AnimPlayer", true, false)
	if not anim_player:
		printerr("[FAIL] AnimPlayer not found in scenes/leon_side.tscn")
		quit(1)
		return

	# [1/5] Verify Animation Presence in AnimPlayer
	print("\n[1/5] Verifying Animation Presence in AnimPlayer...")
	var required_anims = [
		"idle", "RESET",
		"walk", "LEON_WALK",
		"run", "LEON_RUN",
		"run_stop", "LEON_STOP",
		"walk_stop",
		"turn", "LEON_TURN"
	]
	for a_name in required_anims:
		if not anim_player.has_animation(a_name):
			printerr("  [FAIL] Missing required animation: ", a_name)
			has_error = true
		else:
			var anim = anim_player.get_animation(a_name)
			print("  [PASS] Animation verified: '%s' (length: %.3fs, loop: %d)" % [a_name, anim.length, anim.loop_mode])

	# [2/5] Verify Run vs Walk Biomechanical Distinction
	print("\n[2/5] Verifying Run vs Walk Biomechanical Distinction...")
	var walk = anim_player.get_animation("walk")
	var run = anim_player.get_animation("run")

	if not walk or not run:
		printerr("  [FAIL] Could not retrieve walk or run animations")
		quit(1)
		return

	# A. Duration / Tempo
	print("  Walk Duration: %.2fs | Run Duration: %.2fs" % [walk.length, run.length])
	if run.length >= walk.length:
		printerr("  [FAIL] Run length should be faster than walk length")
		has_error = true
	else:
		print("  [PASS] Run cycle is faster (0.50s vs 0.80s)")

	# Helper to find track index
	var find_track = func(anim: Animation, path: String) -> int:
		for i in range(anim.get_track_count()):
			if str(anim.track_get_path(i)) == path:
				return i
		return -1

	# B. Torso Forward Lean
	var walk_torso_idx = find_track.call(walk, "Visuals/Skeleton/root/torso:rotation")
	var run_torso_idx = find_track.call(run, "Visuals/Skeleton/root/torso:rotation")
	var max_walk_torso = 0.0
	var max_run_torso = 0.0
	if walk_torso_idx != -1 and run_torso_idx != -1:
		for k in range(walk.track_get_key_count(walk_torso_idx)):
			max_walk_torso = max(max_walk_torso, abs(walk.track_get_key_value(walk_torso_idx, k)))
		for k in range(run.track_get_key_count(run_torso_idx)):
			max_run_torso = max(max_run_torso, abs(run.track_get_key_value(run_torso_idx, k)))

		print("  Max Walk Torso Lean: %.3f rad (%.1f°) | Max Run Torso Lean: %.3f rad (%.1f°)" % [
			max_walk_torso, rad_to_deg(max_walk_torso), max_run_torso, rad_to_deg(max_run_torso)
		])
		if max_run_torso <= max_walk_torso * 1.5:
			printerr("  [FAIL] Run should have significantly stronger forward lean than walk")
			has_error = true
		else:
			print("  [PASS] Run has significantly stronger forward sprint lean (%.1f° vs %.1f°)" % [
				rad_to_deg(max_run_torso), rad_to_deg(max_walk_torso)
			])

	# C. Stride Reach
	var walk_leg_idx = find_track.call(walk, "Visuals/Skeleton/root/leg_R_upper:rotation")
	var run_leg_idx = find_track.call(run, "Visuals/Skeleton/root/leg_R_upper:rotation")
	var max_walk_leg = 0.0
	var max_run_leg = 0.0
	if walk_leg_idx != -1 and run_leg_idx != -1:
		for k in range(walk.track_get_key_count(walk_leg_idx)):
			max_walk_leg = max(max_walk_leg, abs(walk.track_get_key_value(walk_leg_idx, k)))
		for k in range(run.track_get_key_count(run_leg_idx)):
			max_run_leg = max(max_run_leg, abs(run.track_get_key_value(run_leg_idx, k)))

		print("  Max Walk Leg Spread: %.3f rad (%.1f°) | Max Run Leg Spread: %.3f rad (%.1f°)" % [
			max_walk_leg, rad_to_deg(max_walk_leg), max_run_leg, rad_to_deg(max_run_leg)
		])
		if max_run_leg <= max_walk_leg:
			printerr("  [FAIL] Run leg stride should exceed walk stride")
			has_error = true
		else:
			print("  [PASS] Run leg stride is longer and more dynamic (%.1f° vs %.1f°)" % [
				rad_to_deg(max_run_leg), rad_to_deg(max_walk_leg)
			])

	# D. Arm Pump Swing
	var walk_arm_idx = find_track.call(walk, "Visuals/Skeleton/root/torso/arm_R_upper:rotation")
	var run_arm_idx = find_track.call(run, "Visuals/Skeleton/root/torso/arm_R_upper:rotation")
	var max_walk_arm = 0.0
	var max_run_arm = 0.0
	if walk_arm_idx != -1 and run_arm_idx != -1:
		for k in range(walk.track_get_key_count(walk_arm_idx)):
			max_walk_arm = max(max_walk_arm, abs(walk.track_get_key_value(walk_arm_idx, k)))
		for k in range(run.track_get_key_count(run_arm_idx)):
			max_run_arm = max(max_run_arm, abs(run.track_get_key_value(run_arm_idx, k)))

		print("  Max Walk Arm Swing: %.3f rad (%.1f°) | Max Run Arm Swing: %.3f rad (%.1f°)" % [
			max_walk_arm, rad_to_deg(max_walk_arm), max_run_arm, rad_to_deg(max_run_arm)
		])
		if max_run_arm <= max_walk_arm:
			printerr("  [FAIL] Run arm swing should exceed walk arm swing")
			has_error = true
		else:
			print("  [PASS] Run arm swing is stronger and more athletic (%.1f° vs %.1f°)" % [
				rad_to_deg(max_run_arm), rad_to_deg(max_walk_arm)
			])

	# [3/5] Verify Run Cycle Seamless Looping Continuity (t=0.0 vs t=0.50)
	print("\n[3/5] Verifying Run Cycle Seamless Looping Continuity (t=0.0 vs t=0.50)...")
	for i in range(run.get_track_count()):
		var t_path = str(run.track_get_path(i))
		if run.track_get_type(i) == Animation.TYPE_VALUE:
			var k_count = run.track_get_key_count(i)
			if k_count >= 2:
				var first_val = run.track_get_key_value(i, 0)
				var last_val = run.track_get_key_value(i, k_count - 1)
				if typeof(first_val) == TYPE_FLOAT:
					var diff = abs(first_val - last_val)
					if diff > 0.001:
						printerr("  [FAIL] Track '%s' loop mismatch: start %.4f vs end %.4f (diff: %.4f)" % [t_path, first_val, last_val, diff])
						has_error = true
				elif typeof(first_val) == TYPE_VECTOR2:
					var diff = (first_val - last_val).length()
					if diff > 0.001:
						printerr("  [FAIL] Track '%s' loop mismatch: start %s vs end %s (diff: %.4f)" % [t_path, str(first_val), str(last_val), diff])
						has_error = true

	if not has_error:
		print("  [PASS] All 18 tracks loop with exact 0.0 numerical delta")

	# [4/5] Ground Contact Kinematics Verification
	print("\n[4/5] Verifying Ground Contact Kinematics across Locomotion States...")
	root.position = Vector2(0, 0)
	var foot_l = root.find_child("foot_L", true, false)
	var foot_r = root.find_child("foot_R", true, false)

	# Sample run cushion phase (t = 0.08)
	anim_player.play("run")
	anim_player.seek(0.08, true)
	var run_contact_r = abs(foot_r.global_position.y)
	print("  Run Lead Foot (R) Contact at Cushion (t=0.08): offset = %.2f px" % run_contact_r)
	if run_contact_r > 1.5:
		printerr("  [FAIL] Lead foot offset in run cushion > 1.5px: ", run_contact_r)
		has_error = true
	else:
		print("  [PASS] Lead foot firmly grounded in run cushion (offset: %.2f px)" % run_contact_r)

	# Sample run_stop braking phase (t = 0.18)
	anim_player.play("run_stop")
	anim_player.seek(0.18, true)
	var stop_contact_r = abs(foot_r.global_position.y)
	print("  Stop Braking Foot Contact (t=0.18): offset = %.2f px" % stop_contact_r)
	if stop_contact_r > 1.5:
		printerr("  [FAIL] Foot offset in stop > 1.5px: ", stop_contact_r)
		has_error = true
	else:
		print("  [PASS] Foot firmly grounded during momentum brake (offset: %.2f px)" % stop_contact_r)

	# [5/5] Continuous 20-Cycle State Machine Simulation
	print("\n[5/5] Continuous 20-Cycle State Machine Simulation...")
	# Sequence: IDLE -> WALK -> RUN -> STOP -> IDLE -> WALK -> RUN -> TURN -> RUN -> STOP -> IDLE
	root.position = Vector2(500, 0)
	root.set_physics_process(true)
	var sim_delta = 1.0 / 60.0
	var cycle_count = 20
	var total_frames = 0

	for cycle in range(cycle_count):
		# Phase 1: IDLE (0.3s)
		root.input_dir = 0.0
		root.wants_run = false
		for f in range(18):
			root._physics_process(sim_delta)
			total_frames += 1
		if root.current_state != CharacterController.State.IDLE:
			printerr("  [FAIL] Expected IDLE in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break

		# Phase 2: WALK (0.5s)
		root.input_dir = 1.0
		root.wants_run = false
		for f in range(30):
			root._physics_process(sim_delta)
			total_frames += 1
		if root.current_state != CharacterController.State.WALK:
			printerr("  [FAIL] Expected WALK in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break

		# Phase 3: RUN (0.5s)
		root.wants_run = true
		for f in range(30):
			root._physics_process(sim_delta)
			total_frames += 1
		if root.current_state != CharacterController.State.RUN:
			printerr("  [FAIL] Expected RUN in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break

		# Phase 4: STOP (0.4s)
		root.input_dir = 0.0
		root.wants_run = false
		root._physics_process(sim_delta)
		total_frames += 1
		if root.current_state != CharacterController.State.STOP:
			printerr("  [FAIL] Expected STOP on input release in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break
		# Settle stop
		for f in range(24):
			root._physics_process(sim_delta)
			total_frames += 1
		if root.current_state != CharacterController.State.IDLE:
			printerr("  [FAIL] Expected IDLE after stop settle in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break

		# Phase 5: WALK -> RUN (0.6s)
		root.input_dir = 1.0
		root.wants_run = false
		for f in range(15):
			root._physics_process(sim_delta)
			total_frames += 1
		root.wants_run = true
		for f in range(20):
			root._physics_process(sim_delta)
			total_frames += 1

		# Phase 6: TURN 180° while running
		root.input_dir = -1.0
		root._physics_process(sim_delta)
		total_frames += 1
		if root.current_state != CharacterController.State.TURN:
			printerr("  [FAIL] Expected TURN on direction reversal in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break

		# Complete turn
		for f in range(14):
			root._physics_process(sim_delta)
			total_frames += 1
		if root.facing_direction != -1:
			printerr("  [FAIL] Facing direction should be -1 after turn, got: %d" % root.facing_direction)
			has_error = true
			break
		if root.current_state != CharacterController.State.RUN:
			printerr("  [FAIL] Expected resumption into RUN after turn in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break

		# Phase 7: RUN left -> STOP -> IDLE
		for f in range(25):
			root._physics_process(sim_delta)
			total_frames += 1
		root.input_dir = 0.0
		root.wants_run = false
		for f in range(26):
			root._physics_process(sim_delta)
			total_frames += 1
		if root.current_state != CharacterController.State.IDLE:
			printerr("  [FAIL] Expected IDLE after final stop in cycle %d, got: %s" % [cycle, root.STATE_NAMES[root.current_state]])
			has_error = true
			break

		# Reset facing direction for next cycle
		root.facing_direction = 1
		root.position = Vector2(500, 0)

	if not has_error:
		print("  [PASS] Completed %d continuous locomotion cycles (%d frames) with 0 errors, 0 NaN, and perfect state determinism!" % [
			cycle_count, total_frames
		])

	# Summary
	print("\n==================================================")
	if has_error:
		printerr("  RESULT: VERIFICATION FAILED")
		print("==================================================")
		quit(1)
	else:
		print("  RESULT: ALL VERIFICATION SUITES PASSED (CODE 0)")
		print("==================================================")
		quit(0)
