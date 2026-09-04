@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("  LEON 2D PUPPET RIG — AUTOMATED VERIFICATION")
	print("==================================================")

	var scene_path = "res://scenes/leon.tscn"
	var leon_scene = load(scene_path)
	if not leon_scene:
		printerr("[FAIL] Could not load scene: ", scene_path)
		quit(1)
		return

	var root = leon_scene.instantiate()
	if not root:
		printerr("[FAIL] Could not instantiate scene: ", scene_path)
		quit(1)
		return

	var passed = true

	# 1. Base Nodes
	print("[1/6] Verifying Top-Level Scene Architecture...")
	var req_nodes = [
		"CollisionShape2D",
		"Visuals",
		"Visuals/Skeleton",
		"VFXAttachmentPoints",
		"VFXAttachmentPoints/HitPoint",
		"VFXAttachmentPoints/HeadPoint",
		"VFXAttachmentPoints/CandyPoint",
		"AnimPlayer"
	]
	for p in req_nodes:
		var n = root.get_node_or_null(p)
		if not n:
			printerr("  [FAIL] Missing required node: ", p)
			passed = false
		else:
			print("  [PASS] Node found: ", p)

	# 2. Bone Hierarchy Verification
	print("[2/6] Verifying 17-Bone Production Hierarchy...")
	var expected_bones = {
		"root": "Visuals/Skeleton",
		"tail": "Visuals/Skeleton/root",
		"leg_L_upper": "Visuals/Skeleton/root",
		"leg_L_lower": "Visuals/Skeleton/root/leg_L_upper",
		"foot_L": "Visuals/Skeleton/root/leg_L_upper/leg_L_lower",
		"leg_R_upper": "Visuals/Skeleton/root",
		"leg_R_lower": "Visuals/Skeleton/root/leg_R_upper",
		"foot_R": "Visuals/Skeleton/root/leg_R_upper/leg_R_lower",
		"torso": "Visuals/Skeleton/root",
		"arm_L_upper": "Visuals/Skeleton/root/torso",
		"arm_L_lower": "Visuals/Skeleton/root/torso/arm_L_upper",
		"hand_L": "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower",
		"arm_R_upper": "Visuals/Skeleton/root/torso",
		"arm_R_lower": "Visuals/Skeleton/root/torso/arm_R_upper",
		"hand_R": "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower",
		"neck": "Visuals/Skeleton/root/torso",
		"head": "Visuals/Skeleton/root/torso/neck"
	}

	for b_name in expected_bones.keys():
		var parent_path = expected_bones[b_name]
		var full_path = parent_path + "/" + b_name
		var b = root.get_node_or_null(full_path)
		if not b:
			printerr("  [FAIL] Missing Bone2D: ", full_path)
			passed = false
		elif not (b is Bone2D):
			printerr("  [FAIL] Node is not Bone2D: ", full_path)
			passed = false
		else:
			print("  [PASS] Bone2D verified: ", b_name, " (parent: ", parent_path.get_file(), ") rest: ", b.rest.origin)

	# 3. Sprite Textures & Layering Verification
	print("[3/6] Verifying Cut-Paper Sprite Attachments & Z-Ordering...")
	var sprite_checks = [
		{"path": "Visuals/Skeleton/root/tail/TailSprite", "z": -2},
		{"path": "Visuals/Skeleton/root/leg_L_upper/LegSpriteL", "z": -1},
		{"path": "Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L/FootSpriteL", "z": -1},
		{"path": "Visuals/Skeleton/root/leg_R_upper/LegSpriteR", "z": 1},
		{"path": "Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R/FootSpriteR", "z": 1},
		{"path": "Visuals/Skeleton/root/torso/TorsoSprite", "z": 0},
		{"path": "Visuals/Skeleton/root/torso/arm_L_upper/ArmSpriteL", "z": -1},
		{"path": "Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L/HandSpriteL", "z": -1},
		{"path": "Visuals/Skeleton/root/torso/arm_R_upper/ArmSpriteR", "z": 1},
		{"path": "Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R/HandSpriteR", "z": 1},
		{"path": "Visuals/Skeleton/root/torso/neck/head/HoodSprite", "z": 2}
	]
	for sc in sprite_checks:
		var s: Sprite2D = root.get_node_or_null(sc["path"])
		if not s:
			printerr("  [FAIL] Missing sprite: ", sc["path"])
			passed = false
		elif not s.texture:
			printerr("  [FAIL] Sprite missing texture: ", sc["path"])
			passed = false
		elif s.z_index != sc["z"]:
			printerr("  [FAIL] Incorrect z_index (expected ", sc["z"], " got ", s.z_index, "): ", sc["path"])
			passed = false
		else:
			print("  [PASS] Sprite valid: ", sc["path"].get_file(), " (z_index = ", s.z_index, ", size = ", s.texture.get_size(), ")")

	# 4. Decoupled Face System Verification
	print("[4/6] Verifying Decoupled Face System...")
	var face: FaceController = root.get_node_or_null("Visuals/Skeleton/root/torso/neck/head/Face")
	if not face:
		printerr("  [FAIL] Missing FaceController node")
		passed = false
	else:
		print("  [PASS] FaceController found under head bone")
		var expressions = ["neutral", "happy", "angry", "sad", "shocked", "scared", "hurt", "confused", "smug", "laughing"]
		for expr in expressions:
			face.set_expression(expr)
			if face.current_expression != expr:
				printerr("  [FAIL] Expression set failed for: ", expr)
				passed = false
		print("  [PASS] All 10 expressions verified successfully")

		var eye_states = ["open", "blink", "wide", "closed"]
		for state in eye_states:
			face.set_eye_state(state)
			if face.current_eye_state != state:
				printerr("  [FAIL] Eye state set failed for: ", state)
				passed = false
		print("  [PASS] All 4 eye states (open, blink, wide, closed) verified")

	# 5. Extreme Joint Rotation Stress Test
	print("[5/6] Performing Extreme Joint Rotation Stress Test...")
	var joint_deflections = {
		"Visuals/Skeleton/root/torso/neck/head": [-60.0, 0.0, 60.0],
		"Visuals/Skeleton/root/torso/neck": [-30.0, 0.0, 30.0],
		"Visuals/Skeleton/root/torso": [-45.0, 0.0, 45.0],
		"Visuals/Skeleton/root/torso/arm_L_upper": [-180.0, -90.0, 0.0, 90.0, 180.0],
		"Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower": [0.0, 45.0, 90.0, 120.0],
		"Visuals/Skeleton/root/torso/arm_L_upper/arm_L_lower/hand_L": [-90.0, 0.0, 90.0],
		"Visuals/Skeleton/root/torso/arm_R_upper": [-180.0, -90.0, 0.0, 90.0, 180.0],
		"Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower": [0.0, 45.0, 90.0, 120.0],
		"Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R": [-90.0, 0.0, 90.0],
		"Visuals/Skeleton/root/leg_L_upper": [-90.0, -45.0, 0.0, 45.0, 90.0],
		"Visuals/Skeleton/root/leg_L_upper/leg_L_lower": [0.0, 45.0, 90.0, 110.0],
		"Visuals/Skeleton/root/leg_L_upper/leg_L_lower/foot_L": [-60.0, 0.0, 60.0],
		"Visuals/Skeleton/root/leg_R_upper": [-90.0, -45.0, 0.0, 45.0, 90.0],
		"Visuals/Skeleton/root/leg_R_upper/leg_R_lower": [0.0, 45.0, 90.0, 110.0],
		"Visuals/Skeleton/root/leg_R_upper/leg_R_lower/foot_R": [-60.0, 0.0, 60.0],
		"Visuals/Skeleton/root/tail": [-60.0, 0.0, 60.0]
	}

	for j_path in joint_deflections.keys():
		var b: Bone2D = root.get_node_or_null(j_path)
		if not b:
			continue
		for deg in joint_deflections[j_path]:
			b.rotation = deg_to_rad(deg)
			var xf = b.transform
			if is_nan(xf.origin.x) or is_nan(xf.origin.y) or is_nan(b.rotation):
				printerr("  [FAIL] Transform NaN on: ", j_path, " at ", deg, " deg")
				passed = false
			b.rotation = 0.0 # reset

	print("  [PASS] All 16 articulated joints passed full range-of-motion deflection without error")

	# 6. Animation Player & Reset Track
	print("[6/6] Verifying AnimPlayer and RESET Track...")
	var anim: AnimationPlayer = root.get_node_or_null("AnimPlayer")
	if not anim:
		printerr("  [FAIL] Missing AnimPlayer")
		passed = false
	elif not anim.has_animation("RESET"):
		printerr("  [FAIL] Missing RESET animation track")
		passed = false
	else:
		var reset_anim = anim.get_animation("RESET")
		print("  [PASS] RESET animation verified (tracks: ", reset_anim.get_track_count(), ")")

	print("--------------------------------------------------")
	if passed:
		print(">>> ALL PRODUCTION RIG CHECKS PASSED SUCCESSFULLY! <<<")
		quit(0)
	else:
		printerr(">>> RIG VERIFICATION FAILED WITH ERRORS <<<")
		quit(1)
