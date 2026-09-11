extends GdUnitTestSuite

# ============================================================================
# PRODUCTION VERIFICATION SUITE: "LEON AND THE RUNAWAY STAR"
# ----------------------------------------------------------------------------
# Validates all core production invariants for the animated short:
# 1. Single-Instance Rule: EXACTLY ONE live Leon character in the scene tree.
# 2. Audio Law: STRICTLY NO BGM. Only character SFX, footsteps, and star sounds.
# 3. 4-View Presentation: Side, Front, 3/4, Back motivated by camera/orientation.
# 4. 2.5D Spatial Scaling: Monotonic perspective depth scaling.
# 5. Footstep Synchronization: Contact-driven walk/run cadence.
# 6. Star & Circle Causality: Star states, circle activation, shuriken hit.
# 7. Comedy Payoff: Cross-eyed facial acting.
# ============================================================================

const MOVIE_SCENE := preload("res://scenes/production/runaway_star/runaway_star_movie.tscn")
const LeonCharacterScript := preload("res://scenes/production/runaway_star/leon_movie_character.gd")

var runner: Node = null
var movie: Node2D = null
var leon: Node2D = null
var star: Node2D = null
var circle: Node2D = null
var camera: CinematicCamera = null

func before_test() -> void:
	movie = MOVIE_SCENE.instantiate()
	get_tree().root.add_child(movie)
	
	leon = movie.get_node("LeonCharacter")
	star = movie.get_node("RunawayStar")
	circle = movie.get_node("GlowingCircle")
	camera = movie.get_node("CinematicCamera")
	
	leon.camera = camera
	star.camera = camera
	circle.camera = camera

func after_test() -> void:
	if movie and is_instance_valid(movie):
		if movie.is_inside_tree():
			movie.get_parent().remove_child(movie)
		movie.free()
		movie = null

# --- 1. SINGLE-INSTANCE LEON INVARIANT ---

func test_exactly_one_leon_character_instance() -> void:
	assert_that(leon).is_not_null()
	
	# Audit entire scene tree: count how many Leon characters exist
	var leon_chars := []
	_collect_nodes_by_type(movie, LeonCharacterScript, leon_chars)
	assert_that(leon_chars.size()).is_equal(1)
	
	# Verify ViewSlot has exactly ONE active view child
	var view_slot: Node2D = leon.get_node("ViewSlot")
	assert_that(view_slot.get_child_count()).is_equal(1)

func test_single_leon_across_all_four_views() -> void:
	var views := [&"front_3q", &"front", &"side", &"back"]
	var view_slot: Node2D = leon.get_node("ViewSlot")
	
	for v in views:
		leon.set_view(v, false)
		
		# Give one frame for queue_free cleanup
		await get_tree().process_frame
		
		# Invariant check: only 1 Leon character in the entire hierarchy
		var leon_chars := []
		_collect_nodes_by_type(movie, LeonCharacterScript, leon_chars)
		assert_that(leon_chars.size()).is_equal(1)
		
		# Exactly 1 active view node in the slot
		assert_that(view_slot.get_child_count()).is_equal(1)
		assert_that(leon.active_view_name).is_equal(v)

func test_super_does_not_spawn_duplicate_leon() -> void:
	leon.trigger_super(0.2)
	
	# Audit during stealth after fade-in completes (fade takes 0.22s)
	await get_tree().create_timer(0.3).timeout
	var leon_chars := []
	_collect_nodes_by_type(movie, LeonCharacterScript, leon_chars)
	assert_that(leon_chars.size()).is_equal(1)
	assert_that(leon.modulate.a).is_less_equal(0.25)
	
	# Audit after recovery completes (0.22s fade in + 0.2s hold + 0.28s fade out = 0.70s total)
	await get_tree().create_timer(0.55).timeout
	leon_chars.clear()
	_collect_nodes_by_type(movie, LeonCharacterScript, leon_chars)
	assert_that(leon_chars.size()).is_equal(1)
	assert_that(leon.modulate.a).is_equal(1.0)

# --- 2. RAGNAROK BGM INTEGRATION ---

func test_ragnarok_bgm_integration() -> void:
	# Verify BGMPlayer is instantiated and loaded with Ragnarok BGM
	assert_that(movie.bgm_player).is_not_null()
	assert_that(movie.bgm_player.stream).is_not_null()
	var path: String = movie.bgm_player.stream.resource_path.to_lower()
	assert_that(path.contains("ragnarok_menu_01")).is_true()
	if movie.bgm_player.stream is AudioStreamOggVorbis:
		assert_that(movie.bgm_player.stream.loop).is_true()

# --- 3. 2.5D PERSPECTIVE DEPTH SCALING ---

func test_2_5d_depth_monotonic_scaling() -> void:
	# Position Leon at NEAR, MID, FAR depths
	leon.world_pos = Vector2(0.0, 80.0)   # NEAR
	leon._apply_projection()
	var scale_near: float = leon.scale.x
	
	leon.world_pos = Vector2(0.0, 240.0)  # MID
	leon._apply_projection()
	var scale_mid: float = leon.scale.x
	
	leon.world_pos = Vector2(0.0, 520.0)  # FAR
	leon._apply_projection()
	var scale_far: float = leon.scale.x
	
	# Apparent scale MUST strictly decrease with depth: Near > Mid > Far
	assert_that(scale_near).is_greater(scale_mid)
	assert_that(scale_mid).is_greater(scale_far)

func test_horizontal_movement_preserves_scale() -> void:
	leon.world_pos = Vector2(-200.0, 220.0)
	leon._apply_projection()
	var s_left: float = leon.scale.x
	
	leon.world_pos = Vector2(200.0, 220.0)
	leon._apply_projection()
	var s_right: float = leon.scale.x
	
	# Same depth => invariant scale
	assert_that(absf(s_left - s_right)).is_less(0.001)

# --- 4. SYNCHRONIZED FOOTSTEP SYSTEM ---

func test_synchronized_footstep_events() -> void:
	var counters := {"walk": 0, "run": 0}
	
	leon.footstep_stepped.connect(func(is_run: bool):
		if is_run:
			counters["run"] += 1
		else:
			counters["walk"] += 1
	)
	
	# Simulate walk for 0.6s
	leon.walk_to(Vector2(600.0, 180.0), 120.0)
	await get_tree().create_timer(0.6).timeout
	assert_that(counters["walk"]).is_greater_equal(1)
	
	# Simulate run for 0.6s
	leon.run_to(Vector2(1200.0, 180.0), 280.0)
	await get_tree().create_timer(0.6).timeout
	assert_that(counters["run"]).is_greater_equal(2)

# --- 5. STAR & CIRCLE CAUSALITY ---

func test_star_and_circle_interaction() -> void:
	assert_that(circle.is_activated).is_false()
	
	# Star enters circle & circle activates
	circle.activate()
	assert_that(circle.is_activated).is_true()
	
	# Shuriken hits circle and is absorbed without destroying the circle
	circle.absorb_hit(Vector2(180.0, 240.0))
	assert_that(circle.is_inside_tree()).is_true()

# --- 6. COMEDY PAYOFF: CROSS-EYED FACIAL ACTING ---

func test_cross_eyed_facial_acting() -> void:
	leon.set_view(&"front_3q", false)
	await get_tree().process_frame
	
	var pupil_l: Node2D = leon.current_view_node.find_child("PupilL", true, false)
	var pupil_r: Node2D = leon.current_view_node.find_child("PupilR", true, false)
	
	if pupil_l and pupil_r:
		var orig_l_x := pupil_l.position.x
		var orig_r_x := pupil_r.position.x
		
		leon.set_cross_eyed(true)
		await get_tree().create_timer(0.2).timeout
		
		# Pupils must move inward toward nose: Left pupil moves right (+X), Right pupil moves left (-X)
		assert_that(pupil_l.position.x).is_greater(orig_l_x)
		assert_that(pupil_r.position.x).is_less(orig_r_x)
		
		leon.set_cross_eyed(false)
		await get_tree().create_timer(0.2).timeout
		assert_that(absf(pupil_l.position.x - orig_l_x)).is_less(0.01)

# --- 7. SHADOW THEFT & RETURN MECHANIC ---

func test_shadow_theft_and_return_mechanic() -> void:
	var detached_shadow: Node2D = movie.get_node_or_null("DetachedShadow")
	assert_that(detached_shadow).is_not_null()
	
	# Initial state: Leon has shadow
	assert_that(leon.has_shadow).is_true()
	leon._apply_projection()
	assert_that(leon.shadow.visible).is_true()
	
	# Theft: has_shadow becomes false
	leon.has_shadow = false
	leon._apply_projection()
	assert_that(leon.shadow.visible).is_false()
	
	# Detached shadow steals from Leon to star
	detached_shadow.steal_from(leon.world_pos, star, Vector2.ZERO, 0.1)
	assert_that(detached_shadow.visible).is_true()
	assert_that(detached_shadow.is_active).is_true()
	
	# Return to Leon
	detached_shadow.return_to_leon(leon.world_pos, 0.1)
	await get_tree().create_timer(0.2).timeout
	leon.has_shadow = true
	leon._apply_projection()
	assert_that(leon.shadow.visible).is_true()
	
	# Final gag shadow wave test
	var arm: Polygon2D = leon.shadow.get_node_or_null("ShadowArm")
	assert_that(arm).is_not_null()
	leon.trigger_shadow_wave(0.2)
	assert_that(arm.is_inside_tree()).is_true()

# --- 8. ENVIRONMENT Z-ORDER & VISIBILITY ---

func test_sky_ground_actor_z_order() -> void:
	var sky: CanvasItem = movie.get_node("Sky")
	var ground: CanvasItem = movie.get_node("Ground")
	var horizon: CanvasItem = movie.get_node("HorizonLine")
	
	# Sky must be strictly in the far background
	assert_that(sky.z_index).is_less(ground.z_index)
	# Ground must be behind horizon and actors
	assert_that(ground.z_index).is_less(horizon.z_index)
	# All actors must have higher z_index than sky and ground
	assert_that(leon.z_index).is_greater(ground.z_index)
	assert_that(star.z_index).is_greater(ground.z_index)

# --- 9. WALKING FOOTSTEP AUDIO LAW ---

func test_footstep_audio_uses_land_sfx() -> void:
	var cache: Dictionary = movie._audio_cache
	assert_that(cache.has("land")).is_true()
	var land_stream: AudioStream = cache["land"]
	assert_that(land_stream.resource_path.to_lower().ends_with("land.ogg")).is_true()
	
	# Walking footstep keys must point to land.ogg
	assert_that(cache["footstep_walk_01"].resource_path.to_lower().ends_with("land.ogg")).is_true()
	assert_that(cache["footstep_run_01"].resource_path.to_lower().ends_with("land.ogg")).is_true()

# --- Helpers ---

func _collect_nodes_by_type(root: Node, script_type: Variant, out_array: Array) -> void:
	if root.get_script() == script_type or (script_type is String and root.is_class(script_type)):
		out_array.append(root)
	elif script_type is GDScript and root.get_script() == script_type:
		out_array.append(root)
	for child in root.get_children():
		_collect_nodes_by_type(child, script_type, out_array)
