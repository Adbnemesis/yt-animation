@tool
extends SceneTree

# Verification & 20-Cycle Stability Script for Bo Brawler
# 1. Renders high-res previews of Bo in Idle and Attack
# 2. Renders Three Brawler side-by-side comparison (Leon, Nita, Bo)
# 3. Executes 20 complete locomotion/combat cycles verifying zero errors

const ARTIFACT_DIR := "/Users/talus/.gemini/antigravity-ide/brain/cb60eb4e-9e0b-41e6-b4c4-1c1b5e374298"

func _init() -> void:
	print("=== Starting Bo Production Verification & Visual Preview ===")

	var vp = SubViewport.new()
	vp.size = Vector2i(1000, 800)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	# Dark arena background
	var bg = ColorRect.new()
	bg.size = Vector2(1000, 800)
	bg.color = Color("#16181d")
	vp.add_child(bg)

	# Camera
	var cam = Camera2D.new()
	cam.position = Vector2(0, -60)
	cam.zoom = Vector2(3.0, 3.0)
	vp.add_child(cam)

	# 1. Capture Bo Idle
	var bo = load("res://scenes/brawler_bo.tscn").instantiate() as BrawlerBase
	vp.add_child(bo)

	for i in range(10):
		await process_frame

	var img_idle = vp.get_texture().get_image()
	var path_idle = ARTIFACT_DIR + "/bo_brawler_idle.png"
	img_idle.save_png(path_idle)
	print("  ✓ Captured Bo Idle preview: ", path_idle)

	# 2. Capture Bo Attack (Draw Bow pose)
	var anim_player: AnimationPlayer = bo.get_node("AnimPlayer")
	anim_player.play("attack")
	anim_player.seek(0.18, true) # Peak draw frame

	for i in range(5):
		await process_frame

	var img_atk = vp.get_texture().get_image()
	var path_atk = ARTIFACT_DIR + "/bo_brawler_attack.png"
	img_atk.save_png(path_atk)
	print("  ✓ Captured Bo Attack draw preview: ", path_atk)

	# 3. Three Brawler Comparison
	bo.queue_free()

	cam.position = Vector2(0, -70)
	cam.zoom = Vector2(1.5, 1.5)

	var three_scene = load("res://scenes/three_brawler_test.tscn").instantiate()
	vp.add_child(three_scene)

	for i in range(15):
		await process_frame

	var img_three = vp.get_texture().get_image()
	var path_three = ARTIFACT_DIR + "/three_brawlers_comparison.png"
	img_three.save_png(path_three)
	print("  ✓ Captured Three Brawlers comparison: ", path_three)

	three_scene.queue_free()

	# 4. 20-Cycle Stability Execution
	print("\n--- Running 20-Cycle Stability Test ---")
	var arena_scene = load("res://scenes/test_bo_arena.tscn").instantiate()
	vp.add_child(arena_scene)
	var test_bo = arena_scene.get_node("BrawlerBo") as BrawlerBase

	var expressions: Array[String] = [
		"serious", "neutral", "angry", "happy", "shocked",
		"scared", "hurt", "confused", "smug", "sad"
	]

	var total_cycles := 20
	var cycle_errors := 0

	# Settle onto floor
	for f in range(20): await physics_frame

	for c in range(total_cycles):
		var expr = expressions[c % expressions.size()]
		test_bo.set_expression(expr)

		# Step 1: Idle (10 physics ticks)
		test_bo.move(0.0, false)
		for f in range(10): await physics_frame
		if test_bo.movement_controller.current_state != BrawlerMovementController.State.IDLE:
			cycle_errors += 1

		# Step 2: Walk (12 physics ticks)
		test_bo.move(1.0, false)
		for f in range(12): await physics_frame
		if test_bo.movement_controller.current_state != BrawlerMovementController.State.WALK:
			cycle_errors += 1

		# Step 3: Run (12 physics ticks)
		test_bo.move(1.0, true)
		for f in range(12): await physics_frame
		if test_bo.movement_controller.current_state != BrawlerMovementController.State.RUN:
			cycle_errors += 1

		# Step 4: Stop & settle (20 physics ticks)
		test_bo.move(0.0, false)
		for f in range(20): await physics_frame

		# Step 5: Jump & land (50 physics ticks)
		test_bo.jump()
		for f in range(50): await physics_frame

		# Step 6: Attack (30 physics ticks)
		test_bo.attack()
		for f in range(30): await physics_frame

		# Step 7: Hit & recover (30 physics ticks)
		var hit_res = RefCounted.new()
		hit_res.set("damage", 10.0)
		hit_res.set("force", 60.0)
		hit_res.set("direction", Vector2(-1.0, 0.0))
		test_bo.take_hit(hit_res)
		for f in range(30): await physics_frame

		# Reset position, velocity, health and ensure idle for next cycle
		test_bo.position = Vector2(576, 520)
		test_bo.velocity = Vector2.ZERO
		test_bo.hit_receiver.current_health = test_bo.config.max_health
		test_bo.movement_controller.change_state(BrawlerMovementController.State.IDLE)
		for f in range(10): await physics_frame

		if (c + 1) % 5 == 0 or c == total_cycles - 1:
			print("  Cycle %2d / %2d completed | Expression: %-8s | Errors: %d" % [c + 1, total_cycles, expr, cycle_errors])

	arena_scene.queue_free()
	vp.queue_free()

	print("\n=== 20-Cycle Stability Result: %s (Total Cycle Failures: %d) ===" % [
		"SUCCESS" if cycle_errors == 0 else "FAILED",
		cycle_errors
	])

	quit(0 if cycle_errors == 0 else 1)
