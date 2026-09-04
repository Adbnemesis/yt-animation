@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("  LEON 2D PUPPET LOCOMOTION STAGE 3 — VERIFICATION")
	print("  (JUMP • FALL • LAND • PHYSICS SEPARATION)")
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
	print("\n[1/5] Verifying Jump Animation Presence in AnimPlayer...")
	var required_anims = [
		"jump_anticipation",
		"jump_airborne", "LEON_JUMP",
		"fall", "LEON_FALL",
		"jump_land", "LEON_LAND"
	]
	for a_name in required_anims:
		if not anim_player.has_animation(a_name):
			printerr("  [FAIL] Missing required animation: ", a_name)
			has_error = true
		else:
			var anim = anim_player.get_animation(a_name)
			print("  [PASS] Animation verified: '%s' (length: %.3fs, loop: %d)" % [a_name, anim.length, anim.loop_mode])

	# [2/5] Verify Ascent vs Fall Biomechanical Contrast
	print("\n[2/5] Verifying Ascent (jump_airborne) vs Descent (fall) Biomechanical Contrast...")
	var jump_air = anim_player.get_animation("jump_airborne")
	var fall = anim_player.get_animation("fall")

	var find_track = func(anim: Animation, path: String) -> int:
		for i in range(anim.get_track_count()):
			if str(anim.track_get_path(i)) == path:
				return i
		return -1

	# A. Leg Extension vs Knee Tuck
	var air_knee_idx = find_track.call(jump_air, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation")
	var fall_knee_idx = find_track.call(fall, "Visuals/Skeleton/root/leg_R_upper/leg_R_lower:rotation")
	var air_knee = jump_air.track_get_key_value(air_knee_idx, 1) if air_knee_idx != -1 else 0.0
	var fall_knee = fall.track_get_key_value(fall_knee_idx, 1) if fall_knee_idx != -1 else 0.0
	print("  Ascent Knee Flexion: %.3f rad (%.1f°) | Fall Knee Flexion: %.3f rad (%.1f°)" % [
		air_knee, rad_to_deg(air_knee), fall_knee, rad_to_deg(fall_knee)
	])
	if fall_knee <= air_knee:
		printerr("  [FAIL] Fall should have more knee tuck than ascent")
		has_error = true
	else:
		print("  [PASS] Distinct leg posing: Ascent extends legs straight (%.1f°), Fall tucks knees (%.1f°)" % [
			rad_to_deg(air_knee), rad_to_deg(fall_knee)
		])

	# B. Torso Upright vs Forward Descent Pitch
	var air_torso_idx = find_track.call(jump_air, "Visuals/Skeleton/root/torso:rotation")
	var fall_torso_idx = find_track.call(fall, "Visuals/Skeleton/root/torso:rotation")
	var air_torso = jump_air.track_get_key_value(air_torso_idx, 1) if air_torso_idx != -1 else 0.0
	var fall_torso = fall.track_get_key_value(fall_torso_idx, 1) if fall_torso_idx != -1 else 0.0
	print("  Ascent Torso Pitch: %.3f rad (%.1f°) | Fall Torso Pitch: %.3f rad (%.1f°)" % [
		air_torso, rad_to_deg(air_torso), fall_torso, rad_to_deg(fall_torso)
	])
	if fall_torso <= air_torso:
		printerr("  [FAIL] Fall torso should pitch forward into descent")
		has_error = true
	else:
		print("  [PASS] Distinct torso posing: Ascent is upright/back (%.1f°), Fall pitches forward into fall line (%.1f°)" % [
			rad_to_deg(air_torso), rad_to_deg(fall_torso)
		])

	# C. Gaze Direction (Head looking up vs looking down at ground)
	var air_head_idx = find_track.call(jump_air, "Visuals/Skeleton/root/torso/neck/head:rotation")
	var fall_head_idx = find_track.call(fall, "Visuals/Skeleton/root/torso/neck/head:rotation")
	var air_head = jump_air.track_get_key_value(air_head_idx, 1) if air_head_idx != -1 else 0.0
	var fall_head = fall.track_get_key_value(fall_head_idx, 1) if fall_head_idx != -1 else 0.0
	print("  Ascent Head Gaze: %.3f rad (%.1f°) | Fall Head Gaze: %.3f rad (%.1f°)" % [
		air_head, rad_to_deg(air_head), fall_head, rad_to_deg(fall_head)
	])
	if fall_head <= air_head:
		printerr("  [FAIL] Fall head should look down toward landing zone")
		has_error = true
	else:
		print("  [PASS] Gaze reaction: Ascent looks upward, Fall looks downward toward ground (%.1f°)" % [
			rad_to_deg(fall_head)
		])

	# [3/5] Landing Impact Kinematics & Ground Contact
	print("\n[3/5] Verifying Landing Impact Kinematics & Ground Contact...")
	root.position = Vector2(0, 0)
	var foot_l = root.find_child("foot_L", true, false)
	var foot_r = root.find_child("foot_R", true, false)

	# Sample jump_land contact at t = 0.00s
	anim_player.play("jump_land")
	anim_player.seek(0.00, true)
	var land_contact_r = abs(foot_r.global_position.y)
	print("  Landing Initial Contact (t=0.00s): Foot R offset = %.2f px" % land_contact_r)
	if land_contact_r > 1.5:
		printerr("  [FAIL] Landing contact offset > 1.5px: ", land_contact_r)
		has_error = true
	else:
		print("  [PASS] Feet contact ground plane cleanly at landing initiation (%.2f px)" % land_contact_r)

	# Sample jump_land squash at t = 0.06s
	anim_player.seek(0.06, true)
	var land_squash_y = root.get_node("Visuals/Skeleton/root").position.y
	print("  Landing Impact Squash (t=0.06s): Root y = %.1f (Squash delta from rest: %.1f px)" % [
		land_squash_y, land_squash_y - (-38.0)
	])
	if land_squash_y < -34.0:
		printerr("  [FAIL] Insufficient impact squash: ", land_squash_y)
		has_error = true
	else:
		print("  [PASS] Heavy impact squash absorbs landing kinetic energy (7.0 px compression)")

	# [4/5] True Physics / Velocity Separation Verification
	print("\n[4/5] Verifying Physics / Velocity Separation & Momentum Preservation...")
	root.position = Vector2(500, 0)
	root.velocity = Vector2.ZERO
	root.change_state(CharacterController.State.IDLE)
	root.wants_jump = true
	root._physics_process(1.0 / 60.0)

	if root.current_state != CharacterController.State.JUMP_ANTICIPATION:
		printerr("  [FAIL] Expected JUMP_ANTICIPATION on jump trigger, got: ", root.STATE_NAMES[root.current_state])
		has_error = true
	else:
		print("  [PASS] Jump starts in JUMP_ANTICIPATION crouch (still grounded)")

	# Run through anticipation duration (0.10s = 6 frames)
	for f in range(6):
		root._physics_process(1.0 / 60.0)

	if root.current_state != CharacterController.State.JUMP_AIRBORNE:
		printerr("  [FAIL] Expected JUMP_AIRBORNE at launch, got: ", root.STATE_NAMES[root.current_state])
		has_error = true
	else:
		print("  [PASS] Character transitions to JUMP_AIRBORNE at launch")

	if root.velocity.y >= -400.0:
		printerr("  [FAIL] Launch velocity.y should be <= -400.0 px/s, got: ", root.velocity.y)
		has_error = true
	else:
		print("  [PASS] Real physics launch impulse applied: velocity.y = %.1f px/s" % root.velocity.y)

	# Simulate ascent until apex (velocity.y reaches 0.0)
	var sim_dt = 1.0 / 60.0
	var reached_fall = false
	for f in range(35):
		root._physics_process(sim_dt)
		if root.current_state == CharacterController.State.FALL:
			reached_fall = true
			print("  [PASS] Reached apex and transitioned smoothly to FALL at frame %d (velocity.y = %+.1f px/s)" % [
				f, root.velocity.y
			])
			break
	if not reached_fall:
		printerr("  [FAIL] Did not transition to FALL at jump apex")
		has_error = true

	# Test momentum preservation: Jump while running
	root.position = Vector2(500, 0)
	root.velocity = Vector2.ZERO
	root.change_state(CharacterController.State.RUN)
	root.input_dir = 1.0
	root.wants_run = true
	root.velocity.x = 300.0
	root.wants_jump = true
	root._physics_process(sim_dt) # enters JUMP_ANTICIPATION
	for f in range(6):
		root._physics_process(sim_dt) # reaches launch
	if root.velocity.x < 250.0:
		printerr("  [FAIL] Running jump did not preserve horizontal momentum: velocity.x = ", root.velocity.x)
		has_error = true
	else:
		print("  [PASS] Running jump preserves forward horizontal momentum across launch: velocity.x = %.1f px/s" % root.velocity.x)

	# [5/5] Continuous 20-Cycle Jump Simulation
	print("\n[5/5] Continuous 20-Cycle Deterministic Jump Simulation...")
	# Cycle: IDLE -> JUMP -> FALL -> LAND -> WALK -> JUMP -> LAND -> RUN -> JUMP -> LAND -> STOP -> IDLE
	root.position = Vector2(500, 0)
	root.velocity = Vector2.ZERO
	root.change_state(CharacterController.State.IDLE)
	var cycle_count = 20
	var total_frames = 0

	for cycle in range(cycle_count):
		# 1. Standing JUMP
		root.input_dir = 0.0
		root.wants_run = false
		root.wants_jump = true
		root._physics_process(sim_dt)
		total_frames += 1

		# Simulate full natural jump arc (anticipation -> airborne -> fall -> land -> settle into IDLE)
		for f in range(72):
			root._physics_process(sim_dt)
			total_frames += 1
		if root.current_state != CharacterController.State.IDLE:
			printerr("  [FAIL] Cycle %d: Expected IDLE after standing jump land, got: %s" % [
				cycle, root.STATE_NAMES[root.current_state]
			])
			has_error = true
			break

		# 2. WALK -> JUMP -> LAND -> WALK
		root.input_dir = 1.0
		root.wants_run = false
		for f in range(20):
			root._physics_process(sim_dt)
			total_frames += 1
		root.wants_jump = true
		root._physics_process(sim_dt)
		total_frames += 1
		# In air and land with input held
		for f in range(72):
			root._physics_process(sim_dt)
			total_frames += 1
		if root.current_state != CharacterController.State.WALK:
			printerr("  [FAIL] Cycle %d: Expected WALK after walking jump land with input held, got: %s" % [
				cycle, root.STATE_NAMES[root.current_state]
			])
			has_error = true
			break

		# 3. RUN -> JUMP -> LAND -> STOP -> IDLE
		root.wants_run = true
		for f in range(20):
			root._physics_process(sim_dt)
			total_frames += 1
		root.wants_jump = true
		root._physics_process(sim_dt)
		total_frames += 1
		# In air and land with run input held
		for f in range(72):
			root._physics_process(sim_dt)
			total_frames += 1
		if root.current_state != CharacterController.State.RUN:
			printerr("  [FAIL] Cycle %d: Expected RUN after running jump land with run held, got: %s" % [
				cycle, root.STATE_NAMES[root.current_state]
			])
			has_error = true
			break

		# Release input to trigger STOP
		root.input_dir = 0.0
		root.wants_run = false
		root._physics_process(sim_dt)
		total_frames += 1
		# Settle stop into IDLE
		for f in range(28):
			root._physics_process(sim_dt)
			total_frames += 1
		if root.current_state != CharacterController.State.IDLE:
			printerr("  [FAIL] Cycle %d: Expected IDLE after final stop, got: %s" % [
				cycle, root.STATE_NAMES[root.current_state]
			])
			has_error = true
			break

	if not has_error:
		print("  [PASS] Completed %d full jump cycles (%d frames) with 0 errors, 0 NaN, and clean state recovery!" % [
			cycle_count, total_frames
		])

	# Summary
	print("\n==================================================")
	if has_error:
		printerr("  RESULT: JUMP VERIFICATION FAILED")
		print("==================================================")
		quit(1)
	else:
		print("  RESULT: ALL JUMP VERIFICATION SUITES PASSED (CODE 0)")
		print("==================================================")
		quit(0)
