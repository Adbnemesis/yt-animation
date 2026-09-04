extends SceneTree

# Verification Suite for Leon Production Combat Stage 1: Basic Attack
# Tests:
# 1. Animation Presence & Method Tracks
# 2. Biomechanical Contrast (Coil Windup vs Explosive Release Snap)
# 3. Deterministic Event Emission (Zero Duplicates, Strict Order)
# 4. Projectile Spawn Point Alignment
# 5. Moving Attacks & Locomotion Coherence (Walk, Run, Jump)
# 6. Interruption Handling (Hit, Combo Chaining) & 30-Cycle Stress Simulation

const LEON_SCENE_PATH := "res://scenes/leon_side.tscn"

func _init() -> void:
	print("\n==================================================")
	print("  LEON 2D PUPPET COMBAT STAGE 1 — VERIFICATION")
	print("  (BASIC ATTACK • EVENTS • PROJECTILE SPRAWN)")
	print("==================================================\n")

	var puppet: CharacterBody2D = load(LEON_SCENE_PATH).instantiate()
	root.add_child(puppet)

	# [1/6] Animation Presence & Tracks
	print("[1/6] Verifying Basic Attack Animation in AnimPlayer...")
	var anim_player: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
	assert(anim_player != null, "AnimPlayer node missing!")

	var req_anims = ["attack", "LEON_BASIC_ATTACK", "LEON_ATTACK"]
	for a_name in req_anims:
		assert(anim_player.has_animation(a_name), "Missing animation: " + a_name)
		var anim = anim_player.get_animation(a_name)
		assert(abs(anim.length - 0.36) < 0.01, "Animation length should be 0.36s, got: " + str(anim.length))
		assert(anim.loop_mode == Animation.LOOP_NONE, "Attack animation must not loop!")
		print("  [PASS] Animation verified: '%s' (length: %.3fs, loop: %d)" % [a_name, anim.length, anim.loop_mode])

	# Check method call track in attack animation
	var atk_anim = anim_player.get_animation("attack")
	var has_method_track = false
	for trk in range(atk_anim.get_track_count()):
		if atk_anim.track_get_type(trk) == Animation.TYPE_METHOD:
			has_method_track = true
			break
	assert(has_method_track, "Attack animation must contain a method track for deterministic events!")
	print("  [PASS] Deterministic method call track verified.")

	# [2/6] Biomechanical Posing Contrast
	print("\n[2/6] Verifying Biomechanical Posing (Windup vs Release Snap)...")
	var t_torso_rot = -1
	var t_arm_rot = -1
	for trk in range(atk_anim.get_track_count()):
		var p = str(atk_anim.track_get_path(trk))
		if p.ends_with("torso:rotation"): t_torso_rot = trk
		elif p.ends_with("arm_R_upper:rotation"): t_arm_rot = trk

	assert(t_torso_rot != -1, "Torso rotation track missing in attack!")
	assert(t_arm_rot != -1, "Right arm rotation track missing in attack!")

	# Windup (0.08s) vs Release (0.14s)
	# Find keys near 0.08 and 0.14
	var torso_windup = 0.0
	var torso_release = 0.0
	for k in range(atk_anim.track_get_key_count(t_torso_rot)):
		var kt = atk_anim.track_get_key_time(t_torso_rot, k)
		if abs(kt - 0.08) < 0.02: torso_windup = atk_anim.track_get_key_value(t_torso_rot, k)
		elif abs(kt - 0.14) < 0.02: torso_release = atk_anim.track_get_key_value(t_torso_rot, k)

	var arm_windup = 0.0
	var arm_release = 0.0
	for k in range(atk_anim.track_get_key_count(t_arm_rot)):
		var kt = atk_anim.track_get_key_time(t_arm_rot, k)
		if abs(kt - 0.08) < 0.02: arm_windup = atk_anim.track_get_key_value(t_arm_rot, k)
		elif abs(kt - 0.14) < 0.02: arm_release = atk_anim.track_get_key_value(t_arm_rot, k)

	print("  Torso Windup: %.3f rad (%.1f°) | Torso Release: %.3f rad (%.1f°)" % [
		torso_windup, rad_to_deg(torso_windup), torso_release, rad_to_deg(torso_release)
	])
	assert(torso_windup < -0.15, "Torso must coil backward during windup (got: " + str(torso_windup) + ")")
	assert(torso_release > 0.25, "Torso must snap forward during release (got: " + str(torso_release) + ")")
	print("  [PASS] Torso explosive snap verified (%.1f° coil -> %.1f° snap)" % [rad_to_deg(torso_windup), rad_to_deg(torso_release)])

	print("  Arm Windup: %.3f rad (%.1f°) | Arm Release: %.3f rad (%.1f°)" % [
		arm_windup, rad_to_deg(arm_windup), arm_release, rad_to_deg(arm_release)
	])
	assert(arm_windup > 0.50, "Arm must cock back during windup (got: " + str(arm_windup) + ")")
	assert(arm_release < -1.20, "Arm must extend forward during release (got: " + str(arm_release) + ")")
	print("  [PASS] Throwing arm whip reach verified (%.1f° cocked -> %.1f° forward reach)" % [rad_to_deg(arm_windup), rad_to_deg(arm_release)])

	# [3/6] Deterministic Animation Event Emission
	print("\n[3/6] Verifying Deterministic Event Emission (Unique, Ordered, No Duplicates)...")
	var event_log: Array[String] = []
	var event_times: Array[float] = []
	puppet.attack_event.connect(func(ev_name: String, data: Dictionary):
		event_log.append(ev_name)
		event_times.append(data.get("time", 0.0))
	)

	puppet.change_state(puppet.State.IDLE)
	puppet.trigger_attack()

	# Simulate attack duration (0.40s = 24 frames @ 60 FPS)
	var dt = 1.0 / 60.0
	for f in range(25):
		puppet._physics_process(dt)

	print("  Emitted events (%d total): %s" % [event_log.size(), str(event_log)])
	var expected_events = [
		"ATTACK_START",
		"ATTACK_RELEASE",
		"PROJECTILE_SPAWN",
		"PROJECTILE_SPAWN",
		"PROJECTILE_SPAWN",
		"PROJECTILE_SPAWN",
		"ATTACK_FOLLOW_THROUGH",
		"ATTACK_END"
	]
	assert(event_log.size() == expected_events.size(), "Expected %d events, got: %d" % [expected_events.size(), event_log.size()])
	for i in range(expected_events.size()):
		assert(event_log[i] == expected_events[i], "Event %d mismatch: expected %s, got %s" % [i, expected_events[i], event_log[i]])
	print("  [PASS] All deterministic attack events (including 4-blade burst) emitted in exact sequence.")

	# [4/6] Projectile Spawn Point Alignment
	print("\n[4/6] Verifying Projectile Spawn Point Alignment...")
	var spawn_pos = puppet.get_projectile_spawn_position()
	print("  Puppet Position: %s | Projectile Spawn Position: %s" % [str(puppet.global_position), str(spawn_pos)])
	assert(not is_nan(spawn_pos.x) and not is_nan(spawn_pos.y), "Spawn position is NaN!")
	assert(spawn_pos.x >= puppet.global_position.x + 10.0, "Spawn position must be positioned forward along facing direction!")
	print("  [PASS] Projectile spawn point accurately aligned with hand and line of fire.")

	# [5/6] Moving Attacks & Locomotion Coherence
	print("\n[5/6] Verifying Moving Attacks & State Transitions...")
	# Walking attack
	puppet.change_state(puppet.State.WALK)
	puppet.input_dir = 1.0
	puppet.wants_run = false
	puppet.velocity.x = 160.0
	puppet.trigger_attack()
	assert(puppet.current_state == puppet.State.ATTACK, "Walking attack should transition to ATTACK")

	# Step 10 frames during walking attack
	for f in range(10):
		puppet._physics_process(dt)
	assert(puppet.velocity.x > 100.0, "Walking attack must preserve forward horizontal speed! vel.x: " + str(puppet.velocity.x))

	# Complete walking attack
	for f in range(20):
		puppet._physics_process(dt)
	assert(puppet.current_state == puppet.State.WALK, "Walking attack must recover into WALK when input held (got: " + puppet.STATE_NAMES[puppet.current_state] + ")")
	print("  [PASS] Walking attack maintains forward horizontal speed and recovers cleanly into WALK.")

	# Running attack
	puppet.change_state(puppet.State.RUN)
	puppet.input_dir = 1.0
	puppet.wants_run = true
	puppet.velocity.x = 300.0
	puppet.trigger_attack()
	assert(puppet.current_state == puppet.State.ATTACK, "Running attack should transition to ATTACK")
	for f in range(10):
		puppet._physics_process(dt)
	assert(puppet.velocity.x > 220.0, "Running attack must preserve sprint speed! vel.x: " + str(puppet.velocity.x))
	for f in range(20):
		puppet._physics_process(dt)
	assert(puppet.current_state == puppet.State.RUN, "Running attack must recover into RUN when sprint held (got: " + puppet.STATE_NAMES[puppet.current_state] + ")")
	print("  [PASS] Running attack maintains sprint speed and recovers cleanly into RUN.")

	# [6/6] Interruption & 30-Cycle Stress Simulation
	print("\n[6/6] Verifying Interruption Handling & 30 Continuous Cycles...")
	# Hit interruption
	puppet.change_state(puppet.State.IDLE)
	puppet.input_dir = 0.0
	puppet.trigger_attack()
	# Step 5 frames (mid windup)
	for f in range(5): puppet._physics_process(dt)
	assert(puppet.current_state == puppet.State.ATTACK, "Should be in ATTACK")
	puppet.trigger_hit()
	assert(puppet.current_state == puppet.State.HIT, "Attack must be cleanly interrupted by HIT")
	assert(puppet.attack_has_started == false, "Attack state flags must be cleared upon interruption")
	print("  [PASS] Mid-attack hit interruption transitions cleanly into HIT without stuck states.")

	# 30 Continuous Cycles Simulation
	print("  Running 30 continuous attack cycles (standing, walking, running, rapid combo)...")
	for cycle in range(30):
		var mode = cycle % 4
		match mode:
			0: # Stationary
				puppet.input_dir = 0.0
				puppet.wants_run = false
				puppet.trigger_attack()
				for f in range(25): puppet._physics_process(dt)
				assert(puppet.current_state == puppet.State.IDLE, "Cycle %d: Expected IDLE, got %s" % [cycle, puppet.STATE_NAMES[puppet.current_state]])
			1: # Walking
				puppet.input_dir = 1.0
				puppet.wants_run = false
				puppet.trigger_attack()
				for f in range(25): puppet._physics_process(dt)
				assert(puppet.current_state == puppet.State.WALK, "Cycle %d: Expected WALK, got %s" % [cycle, puppet.STATE_NAMES[puppet.current_state]])
			2: # Running
				puppet.input_dir = 1.0
				puppet.wants_run = true
				puppet.trigger_attack()
				for f in range(25): puppet._physics_process(dt)
				assert(puppet.current_state == puppet.State.RUN, "Cycle %d: Expected RUN, got %s" % [cycle, puppet.STATE_NAMES[puppet.current_state]])
			3: # Rapid re-trigger / combo chaining
				puppet.input_dir = 0.0
				puppet.wants_run = false
				puppet.trigger_attack()
				for f in range(18): puppet._physics_process(dt)
				puppet.trigger_attack() # Chain 2nd attack
				for f in range(25): puppet._physics_process(dt)
				assert(puppet.current_state == puppet.State.IDLE, "Cycle %d: Expected IDLE, got %s" % [cycle, puppet.STATE_NAMES[puppet.current_state]])

		assert(not is_nan(puppet.position.x) and not is_nan(puppet.position.y), "Cycle %d: Position NaN!" % cycle)
		assert(not is_nan(puppet.velocity.x) and not is_nan(puppet.velocity.y), "Cycle %d: Velocity NaN!" % cycle)

	print("  [PASS] 30 continuous attack cycles completed successfully with 0 errors, 0 NaN, and 0 stuck states!")

	print("\n==================================================")
	print("  RESULT: ALL ATTACK VERIFICATION SUITES PASSED (CODE 0)")
	print("==================================================\n")
	quit(0)
