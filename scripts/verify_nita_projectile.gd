extends SceneTree

# Verification Suite for Nita Production Combat Stage 1:
# Basic Attack & Shockwave Rupture Projectile & Target Dummy Hit Reaction
#
# Tests:
# 1. Projectile Node & Configurable Parameters (Speed 600, Range 480, Lifetime 1.0s, Damage 80)
# 2. Projectile Spawn Point Socket & World Alignment (hand_R/ProjectileSpawnPoint)
# 3. Detached Flight & Independent Direction
# 4. Maximum Range & Lifetime Clean Despawn
# 5. Target Dummy Collision & HitData Exchange (Damage 80, Direction, Force 45, NITA_BASIC)
# 6. Idempotency (Exactly 1 Hit per Shockwave) & Elastic Recoil Settle
# 7. Interruption Safety (Before Spawn -> 0; After Spawn -> Completes Flight & Hits)
# 8. 50+ Continuous Attack Stress Simulation (Standing, Walking, Running, Left/Right)

const NITA_SCENE_PATH := "res://scenes/nita_side.tscn"
const PROJ_SCENE_PATH := "res://scenes/nita_projectile.tscn"
const DUMMY_SCENE_PATH := "res://scenes/target_dummy.tscn"
const HitDataClass = preload("res://scripts/hit_data.gd")

func _init() -> void:
	_run()

func _run() -> void:
	print("\n==================================================")
	print("  NITA 2D COMBAT STAGE 1 — VERIFICATION SUITE")
	print("  (RUPTURE SHOCKWAVE PROJECTILE • COLLISION • DUMMY)")
	print("==================================================\n")

	# Test harness root
	var test_root = Node2D.new()
	test_root.name = "TestHarness"
	root.add_child(test_root)

	# [1/8] Projectile Node & Configurable Parameters
	print("[1/8] Verifying Projectile Scene & Configurable Parameters...")
	var proj_scene: PackedScene = load(PROJ_SCENE_PATH)
	assert(proj_scene != null, "Nita projectile scene missing!")
	var proj = proj_scene.instantiate()
	test_root.add_child(proj)

	assert(proj is Area2D, "Projectile must be an Area2D!")
	assert(proj.speed == 600.0, "Default speed should be 600.0 px/s, got: " + str(proj.speed))
	assert(proj.max_range == 480.0, "Default max_range should be 480.0 px, got: " + str(proj.max_range))
	assert(proj.max_lifetime == 1.0, "Default max_lifetime should be 1.0s, got: " + str(proj.max_lifetime))
	assert(proj.damage == 80.0, "Default damage should be 80.0, got: " + str(proj.damage))
	assert(proj.knockback_force == 45.0, "Default knockback_force should be 45.0, got: " + str(proj.knockback_force))
	assert(proj.attack_type == "NITA_BASIC", "Default attack_type should be 'NITA_BASIC', got: " + str(proj.attack_type))
	assert(proj.is_in_group("projectiles"), "Projectile must be registered in 'projectiles' group!")

	# Check subnodes: Visuals with Sprite2D, Trail with Line2D, CollisionShape2D
	var proj_col = proj.find_child("CollisionShape2D", true, false)
	assert(proj_col != null, "Projectile missing CollisionShape2D!")
	assert(proj_col.shape is CircleShape2D, "Projectile collision shape must be CircleShape2D!")
	var proj_vis = proj.find_child("Visuals", true, false)
	assert(proj_vis != null, "Projectile missing Visuals node!")
	var proj_sprite = proj_vis.find_child("ShockwaveSprite", true, false)
	if not proj_sprite:
		proj_sprite = proj_vis.find_child("*Sprite*", true, false)
	assert(proj_sprite != null and proj_sprite is Sprite2D, "Projectile Visuals missing Sprite2D!")
	var proj_trail = proj.find_child("Trail", true, false)
	assert(proj_trail != null and proj_trail is Line2D, "Projectile missing Trail (Line2D)!")

	proj.queue_free()
	print("  [PASS] Nita shockwave properties, collision shape, visuals, and trail verified.")

	# [2/8] Projectile Spawn Point Socket & World Alignment
	print("\n[2/8] Verifying Projectile Spawn Point Socket on Nita Rig...")
	var puppet: CharacterBody2D = load(NITA_SCENE_PATH).instantiate()
	puppet.position = Vector2(400, 520)
	test_root.add_child(puppet)

	# Allow SceneTree to flush transforms
	for i in range(2):
		await process_frame

	var spawn_socket = puppet.find_child("ProjectileSpawnPoint", true, false)
	assert(spawn_socket != null, "Rig missing 'ProjectileSpawnPoint' node!")
	var hand_r = puppet.find_child("hand_R", true, false)
	assert(hand_r != null and spawn_socket.get_parent() == hand_r, "'ProjectileSpawnPoint' must be a child of 'hand_R'!")

	var right_spawn = puppet.get_projectile_spawn_position()
	assert(right_spawn.x > puppet.position.x, "Facing right: spawn position must be offset forward (+X)!")
	print("  Facing Right Spawn Pos: %s (puppet: %s, delta: +%.1f px)" % [right_spawn, puppet.position, right_spawn.x - puppet.position.x])

	# Flip facing to Left
	puppet.facing_direction = -1
	for i in range(2):
		await process_frame
	var left_spawn = puppet.get_projectile_spawn_position()
	assert(left_spawn.x < puppet.position.x, "Facing left: spawn position must be offset backward (-X)!")
	print("  Facing Left Spawn Pos:  %s (puppet: %s, delta: %+.1f px)" % [left_spawn, puppet.position, left_spawn.x - puppet.position.x])
	puppet.facing_direction = 1
	for i in range(2):
		await process_frame

	# Verify throwing arm layering
	var arm_r_sprite = puppet.find_child("ArmSpriteR", true, false)
	assert(arm_r_sprite != null and arm_r_sprite.z_index == 3, "ArmSpriteR must have z_index = 3 (foreground layering)!")
	print("  Throwing arm layering z_index = %d (renders foreground in front of torso)." % arm_r_sprite.z_index)
	print("  [PASS] Spawn socket, arm layering, and bidirectional world alignment verified.")

	# [3/8] Detached Flight & Independent Direction
	print("\n[3/8] Verifying Detached Flight & Independent Direction...")
	var flight_proj = proj_scene.instantiate()
	test_root.add_child(flight_proj)
	flight_proj.initialize(Vector2(200, 300), Vector2.RIGHT, puppet)

	var prev_x = flight_proj.global_position.x
	var dt = 1.0 / 60.0

	# Advance 10 physics frames
	for frame in range(10):
		flight_proj._physics_process(dt)

	var cur_x = flight_proj.global_position.x
	var expected_dist = flight_proj.speed * dt * 10
	assert(abs((cur_x - prev_x) - expected_dist) < 1.0, "Projectile moved incorrect distance! Expected: %.1f, got: %.1f" % [expected_dist, cur_x - prev_x])
	print("  Distance after 10 frames (%.3fs): %.1f px" % [dt * 10, cur_x - prev_x])

	# Verify flight independence: Turn Nita left while projectile is flying
	puppet.facing_direction = -1
	flight_proj._physics_process(dt)
	assert(flight_proj.direction == Vector2.RIGHT, "Projectile direction must be completely independent of puppet facing!")
	puppet.facing_direction = 1
	flight_proj.queue_free()
	print("  [PASS] Detached flight and directional independence verified.")

	# [4/8] Maximum Range (480px) & Lifetime (1.0s) Despawn
	print("\n[4/8] Verifying Maximum Range (480px) & Lifetime (1.0s) Despawn...")
	var range_proj = proj_scene.instantiate()
	test_root.add_child(range_proj)
	range_proj.initialize(Vector2(100, 300), Vector2.RIGHT, puppet)

	var expired_called = [false]
	range_proj.expired.connect(func(): expired_called[0] = true)

	var f_count = 0
	while range_proj.is_active and f_count < 100:
		range_proj._physics_process(dt)
		f_count += 1

	assert(expired_called[0], "Expired signal should have fired on reaching max range or lifetime!")
	assert(not range_proj.is_active, "is_active should be false on expiration!")
	assert(range_proj.distance_traveled >= range_proj.max_range or range_proj.lifetime >= range_proj.max_lifetime, "Projectile should have reached max range or lifetime!")
	print("  Despawned at distance: %.1f px (limit: %.1f px) in %d frames (%.3fs)" % [
		range_proj.distance_traveled, range_proj.max_range, f_count, f_count * dt
	])
	range_proj.queue_free()
	print("  [PASS] Range & lifetime clean despawn verified.")

	# [5/8] Target Dummy Collision & HitData Exchange
	print("\n[5/8] Verifying Target Dummy Collision & HitData Exchange...")
	var dummy_scene: PackedScene = load(DUMMY_SCENE_PATH)
	assert(dummy_scene != null, "TargetDummy scene missing!")
	var dummy = dummy_scene.instantiate()
	dummy.position = Vector2(700, 520)
	test_root.add_child(dummy)

	var hit_proj = proj_scene.instantiate()
	test_root.add_child(hit_proj)
	hit_proj.initialize(Vector2(650, 480), Vector2.RIGHT, puppet)

	var proj_hit_called = [false]
	var received_hit_data = [null]
	hit_proj.hit_target.connect(func(_target, hit):
		proj_hit_called[0] = true
		received_hit_data[0] = hit
	)

	# Simulate collision dispatch
	hit_proj._handle_collision(dummy)

	assert(proj_hit_called[0], "hit_target signal not emitted!")
	assert(received_hit_data[0] != null, "HitData was not passed to hit_target!")
	var h: RefCounted = received_hit_data[0]
	assert(h.damage == 80.0, "HitData damage should be 80.0, got: " + str(h.damage))
	assert(h.direction == Vector2.RIGHT, "HitData direction should be Vector2.RIGHT!")
	assert(h.force == 45.0, "HitData force should be 45.0, got: " + str(h.force))
	assert(h.source == puppet, "HitData source should be puppet!")
	assert(h.attack_type == "NITA_BASIC", "HitData attack_type should be 'NITA_BASIC'!")
	assert(not hit_proj.is_active, "Projectile is_active must become false immediately on impact!")
	print("  [PASS] Collision and HitData exchange successfully verified.")

	# [6/8] Idempotency & Target Reaction Elastic Settle
	print("\n[6/8] Verifying Idempotency (Zero Duplicate Hits) & Recoil Settle...")
	assert(dummy.hit_count == 1, "Dummy hit_count should be exactly 1, got: " + str(dummy.hit_count))
	assert(dummy.current_hp == 920.0, "Dummy current_hp should be 920.0 (1000 - 80), got: " + str(dummy.current_hp))
	assert(dummy.recoil_offset.x > 0.0, "Dummy recoil_offset should be pushed rightwards, got: " + str(dummy.recoil_offset))
	assert(dummy.flash_timer > 0.0, "Dummy flash_timer should be active, got: " + str(dummy.flash_timer))

	# Attempt second collision on inactive projectile
	hit_proj._handle_collision(dummy)
	assert(dummy.hit_count == 1, "IDEMPOTENCY FAILED: Inactive projectile triggered second hit!")
	assert(dummy.current_hp == 920.0, "IDEMPOTENCY FAILED: Dummy HP deducted twice!")
	hit_proj.queue_free()
	for i in range(2):
		await process_frame

	# Run dummy physics process to verify elastic settle
	for f in range(25):
		dummy._physics_process(dt)

	assert(dummy.recoil_offset.length() < 1.0, "Recoil offset should settle back to ~0, got: " + str(dummy.recoil_offset))
	assert(dummy.flash_timer <= 0.0, "Flash timer should have expired!")
	print("  Dummy settled recoil: %s | Flash expired: %s" % [dummy.recoil_offset, dummy.flash_timer <= 0.0])
	print("  [PASS] Idempotency and target reaction elastic settle verified.")

	# [7/8] Interruption Safety
	print("\n[7/8] Verifying Interruption Safety (Before vs After Spawn)...")
	# Scenario A: Interruption BEFORE PROJECTILE_SPAWN (frame 4, before 0.14s)
	puppet.current_state = puppet.State.IDLE
	puppet.wants_attack = true
	puppet._physics_process(dt)
	assert(puppet.current_state == puppet.State.ATTACK, "State should be ATTACK!")

	for f in range(4):
		puppet._physics_process(dt)

	puppet.take_hit(Vector2.LEFT, 100.0)
	puppet._physics_process(dt)
	assert(puppet.current_state == puppet.State.HIT, "Puppet should be in HIT state!")

	for f in range(20):
		puppet._physics_process(dt)

	var active_projs = test_root.get_children().filter(func(c): return c is Area2D and c != dummy and not c.is_queued_for_deletion() and c.is_active)
	assert(active_projs.size() == 0, "Interrupt before spawn must produce 0 projectiles! Found: " + str(active_projs.size()))
	print("  Scenario A: Pre-spawn interruption produced 0 projectiles. Clean!")

	# Scenario B: Interruption AFTER PROJECTILE_SPAWN (frame 10, after 0.14s)
	dummy.reset_dummy()
	puppet.current_state = puppet.State.IDLE
	puppet.wants_attack = true
	puppet._physics_process(dt)

	for f in range(10):
		puppet._physics_process(dt)

	active_projs = test_root.get_children().filter(func(c): return c is Area2D and c != dummy and c.is_in_group("projectiles"))
	assert(active_projs.size() == 1, "Single shockwave projectile should have spawned! Count: " + str(active_projs.size()))

	# Interrupt Nita during follow-through
	puppet.take_hit(Vector2.LEFT, 100.0)
	puppet._physics_process(dt)
	assert(puppet.current_state == puppet.State.HIT, "Puppet interrupted to HIT state!")

	# Step world physics: Active projectile continues flying towards dummy
	for f in range(45):
		puppet._physics_process(dt)
		for proj_item in active_projs:
			if is_instance_valid(proj_item) and proj_item.is_active:
				proj_item._physics_process(dt)
				if abs(proj_item.global_position.x - dummy.global_position.x) < 35.0:
					proj_item._handle_collision(dummy)

	assert(dummy.hit_count == 1, "Spawned shockwave projectile must hit target despite Nita interruption! Hits: " + str(dummy.hit_count))
	print("  Scenario B: Post-spawn interruption: Shockwave completed flight and struck target!")
	print("  [PASS] Interruption safety verified.")
	for proj_item in active_projs:
		if is_instance_valid(proj_item):
			proj_item.queue_free()
	for i in range(2):
		await process_frame

	# [8/8] 50+ Continuous Attack Stress Simulation
	print("\n[8/8] Running 50+ Continuous Attack Stress Simulation (Standing, Moving, Directional)...")
	dummy.reset_dummy()
	var total_attacks = 60
	var total_projectiles_spawned = [0]
	var total_hits = 0

	puppet.attack_event.connect(func(evt, _data):
		if evt == "PROJECTILE_SPAWN":
			total_projectiles_spawned[0] += 1
	)

	for atk_idx in range(total_attacks):
		puppet.position = Vector2(400, 520)
		puppet.current_state = puppet.State.IDLE
		var face = 1 if (atk_idx % 4 < 3) else -1
		puppet.facing_direction = face
		puppet.find_child("Visuals", true, false).scale.x = face

		# Locomotion variation:
		# 0: Standing
		# 1: Walk forward
		# 2: Run forward
		# 3: Reverse walk
		if atk_idx % 4 == 1:
			puppet.input_dir = 1.0
			puppet.wants_run = false
		elif atk_idx % 4 == 2:
			puppet.input_dir = 1.0
			puppet.wants_run = true
		elif atk_idx % 4 == 3:
			puppet.input_dir = -1.0
			puppet.wants_run = false
		else:
			puppet.input_dir = 0.0
			puppet.wants_run = false

		puppet.wants_attack = true

		# Attack execution frames (~25 frames = 0.41s)
		for f in range(25):
			puppet._physics_process(dt)

			for child in test_root.get_children():
				if child is Area2D and child.is_in_group("projectiles") and child.is_active:
					child._physics_process(dt)
					if child.direction.x > 0 and abs(child.global_position.x - dummy.global_position.x) < 35.0:
						child._handle_collision(dummy)
						total_hits += 1

		# Flight arrival frames
		for f in range(15):
			puppet._physics_process(dt)
			for child in test_root.get_children():
				if child is Area2D and child.is_in_group("projectiles") and child.is_active:
					child._physics_process(dt)
					if child.direction.x > 0 and abs(child.global_position.x - dummy.global_position.x) < 35.0:
						child._handle_collision(dummy)
						total_hits += 1

	print("  Total Attacks Simulated: %d" % total_attacks)
	print("  Total Projectiles Spawned: %d" % total_projectiles_spawned[0])
	print("  Total Target Hits Registered: %d" % total_hits)
	print("  Target Dummy HP: %.0f / %.0f (Total Hits: %d)" % [dummy.current_hp, dummy.max_hp, dummy.hit_count])

	assert(total_projectiles_spawned[0] == total_attacks, "Every attack must produce exactly 1 shockwave projectile! Spawned: " + str(total_projectiles_spawned[0]))
	assert(total_hits == dummy.hit_count, "Hit count must match registered hits!")

	# Clean up any remaining projectiles
	for child in test_root.get_children():
		if child is Area2D and child.is_in_group("projectiles"):
			child.queue_free()

	assert(not is_nan(puppet.position.x) and not is_nan(puppet.position.y), "Puppet position contains NaN!")
	assert(not is_nan(dummy.position.x) and not is_nan(dummy.position.y), "Dummy position contains NaN!")

	print("  [PASS] 50+ Continuous attack stress simulation completed with 0 errors!")

	print("\n==================================================")
	print("  NITA COMBAT STAGE 1 — ALL 8/8 TESTS PASSED!    ")
	print("==================================================\n")

	quit(0)
