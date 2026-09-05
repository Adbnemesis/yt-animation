extends SceneTree

# Verify Nita Brawler Integration
# Validates the Nita brawler scene against the BrawlerBuilder standard.
# Run: godot --headless --script scripts/verify_nita_brawler.gd

var pass_count: int = 0
var fail_count: int = 0
var warn_count: int = 0

func _init() -> void:
	print("")
	print("╔══════════════════════════════════════════════════════╗")
	print("║       NITA BRAWLER INTEGRATION VERIFICATION         ║")
	print("╚══════════════════════════════════════════════════════╝")
	print("")

	_verify_config()
	_verify_adapter()
	_verify_face_controller()
	_verify_brawler_scene()
	_verify_builder_validation()
	_print_summary()

	quit()

func _verify_config() -> void:
	print("── Config Resource ──")

	var config = load("res://templates/brawler/brawler_config_nita.tres")
	_check("Config loads", config != null)
	if not config:
		return

	_check("Config is BrawlerConfig", config is BrawlerConfig)
	_check("character_name = 'Nita'", config.character_name == "Nita")
	_check("character_id = 'brawler_nita'", config.character_id == "brawler_nita")
	_check("walk_speed > 0", config.walk_speed > 0)
	_check("run_speed > walk_speed", config.run_speed > config.walk_speed)
	_check("max_health > 0", config.max_health > 0)
	_check("super_type = 'bear_summon'", config.super_type == "bear_summon")
	_check("audio_event_map not empty", config.audio_event_map.size() > 0)
	_check("vfx_event_map not empty", config.vfx_event_map.size() > 0)

	# Verify all standard events are mapped
	var required_events = ["ATTACK_RELEASE", "JUMP", "LAND", "SUPER_START", "CHARACTER_HIT", "DEATH"]
	for evt in required_events:
		_check("audio_event_map has '%s'" % evt, config.audio_event_map.has(evt))

	print("")

func _verify_adapter() -> void:
	print("── Nita Adapter ──")

	var adapter_script = load("res://templates/brawler/nita_adapter.gd")
	_check("NitaAdapter script loads", adapter_script != null)

	if adapter_script:
		# Use the script's static method via instantiation
		var adapter = adapter_script.new()
		if adapter:
			var get_config_result = adapter_script.get_nita_config()
			_check("get_nita_config() returns valid config", get_config_result != null)
			if get_config_result:
				_check("Config name matches", get_config_result.character_name == "Nita")
			adapter = null  # RefCounted auto-frees

	print("")

func _verify_face_controller() -> void:
	print("── Face Controller (Brawler-Compatible) ──")

	var script = load("res://templates/brawler/face_controller_nita_brawler.gd")
	_check("FaceControllerNitaBrawler script loads", script != null)

	if script:
		# Instantiate and check inheritance
		var face = script.new()
		_check("Extends FaceControllerBase", face is FaceControllerBase)
		_check("Extends Node2D", face is Node2D)

		# Check it has the standard interface methods
		_check("has set_expression()", face.has_method("set_expression"))
		_check("has set_eye_state()", face.has_method("set_eye_state"))

		face.free()

	print("")

func _verify_brawler_scene() -> void:
	print("── Brawler Nita Scene ──")

	if not ResourceLoader.exists("res://scenes/brawler_nita.tscn"):
		_warn("brawler_nita.tscn not found — run build_brawler_nita.gd first")
		print("")
		return

	var scene = load("res://scenes/brawler_nita.tscn") as PackedScene
	_check("Scene loads", scene != null)
	if not scene:
		print("")
		return

	var inst = scene.instantiate()
	_check("Scene instantiates", inst != null)
	if not inst:
		print("")
		return

	# Check root type
	_check("Root is CharacterBody2D", inst is CharacterBody2D)
	_check("Root has BrawlerBase script", inst.get_script() != null)

	# Check required nodes
	_check("Has CollisionShape2D", inst.has_node("CollisionShape2D"))
	_check("Has Visuals", inst.has_node("Visuals"))
	_check("Has Visuals/SkeletonSlot", inst.has_node("Visuals/SkeletonSlot"))
	_check("Has AnimPlayer", inst.has_node("AnimPlayer"))
	_check("Has MovementController", inst.has_node("MovementController"))
	_check("Has AnimationController", inst.has_node("AnimationController"))
	_check("Has AbilityController", inst.has_node("AbilityController"))
	_check("Has HitReceiver", inst.has_node("HitReceiver"))
	_check("Has VFXAttachmentPoints", inst.has_node("VFXAttachmentPoints"))
	_check("Has VFXAttachmentPoints/HitPoint", inst.has_node("VFXAttachmentPoints/HitPoint"))
	_check("Has VFXAttachmentPoints/HeadPoint", inst.has_node("VFXAttachmentPoints/HeadPoint"))
	_check("Has VFXAttachmentPoints/ProjectileSpawn", inst.has_node("VFXAttachmentPoints/ProjectileSpawn"))

	# Check skeleton
	var skeleton = inst.find_child("Skeleton*", true, false)
	_check("Has Skeleton2D", skeleton != null)
	if skeleton:
		var expected_bones = ["root", "torso", "head", "arm_L_upper", "arm_L_lower",
			"hand_L", "arm_R_upper", "arm_R_lower", "hand_R",
			"leg_L_upper", "leg_L_lower", "foot_L",
			"leg_R_upper", "leg_R_lower", "foot_R"]
		for bone_name in expected_bones:
			var found = skeleton.find_child(bone_name, true, false)
			_check("Bone '%s' exists" % bone_name, found != null)

	# Check animations
	var anim_player = inst.get_node_or_null("AnimPlayer") as AnimationPlayer
	_check("AnimPlayer is valid", anim_player != null)
	if anim_player:
		var required_anims = ["idle", "walk", "run", "attack", "hit"]
		for anim_name in required_anims:
			_check("Animation '%s' exists" % anim_name, anim_player.has_animation(anim_name))

		# Check run animation properties
		if anim_player.has_animation("run") and anim_player.has_animation("walk"):
			var run_anim = anim_player.get_animation("run")
			var walk_anim = anim_player.get_animation("walk")
			_check("'run' animation loops", run_anim.loop_mode != Animation.LOOP_NONE)
			_check("'run' is faster than walk (%.2fs < %.2fs)" % [run_anim.length, walk_anim.length],
				run_anim.length < walk_anim.length)

	# Check face controller
	var face = inst.find_child("Face", true, false)
	if face:
		_check("Face controller found", true)
		_check("Face is FaceControllerBase", face is FaceControllerBase)
	else:
		_warn("Face controller not found in scene tree")

	# Check config assignment
	var config_val = inst.get("config")
	_check("Config is assigned", config_val != null)
	if config_val:
		_check("Config is Nita's", config_val.character_name == "Nita")

	inst.free()
	print("")

func _verify_builder_validation() -> void:
	print("── BrawlerBuilder Validation ──")

	if not ResourceLoader.exists("res://scenes/brawler_nita.tscn"):
		_warn("Cannot run builder validation — scene not built yet")
		print("")
		return

	var scene = load("res://scenes/brawler_nita.tscn") as PackedScene
	if not scene:
		_warn("Cannot load scene for validation")
		print("")
		return

	var inst = scene.instantiate()
	var result = BrawlerBuilder.validate_brawler(inst)

	_check("BrawlerBuilder.validate_brawler() passes", result.valid)

	if not result.valid:
		if result.missing_nodes.size() > 0:
			print("    Missing nodes: %s" % str(result.missing_nodes))
		if result.missing_animations.size() > 0:
			print("    Missing animations: %s" % str(result.missing_animations))
		if result.missing_bones.size() > 0:
			print("    Missing bones: %s" % str(result.missing_bones))

	if result.warnings.size() > 0:
		for w in result.warnings:
			_warn(w)

	if result.missing_attachments.size() > 0:
		for a in result.missing_attachments:
			_warn("Missing attachment: %s" % a)

	inst.free()
	print("")

func _check(check_name: String, passed: bool) -> void:
	if passed:
		print("  ✓ %s" % check_name)
		pass_count += 1
	else:
		print("  ✗ FAIL: %s" % check_name)
		fail_count += 1

func _warn(msg: String) -> void:
	print("  ⚠ WARN: %s" % msg)
	warn_count += 1

func _print_summary() -> void:
	print("╔══════════════════════════════════════════════════════╗")
	print("║                    RESULTS                          ║")
	print("╠══════════════════════════════════════════════════════╣")
	print("║  Passed:   %3d                                      ║" % pass_count)
	print("║  Failed:   %3d                                      ║" % fail_count)
	print("║  Warnings: %3d                                      ║" % warn_count)
	print("╠══════════════════════════════════════════════════════╣")
	if fail_count == 0:
		print("║  STATUS: ✓ ALL CHECKS PASSED                       ║")
	else:
		print("║  STATUS: ✗ SOME CHECKS FAILED                      ║")
	print("╚══════════════════════════════════════════════════════╝")
