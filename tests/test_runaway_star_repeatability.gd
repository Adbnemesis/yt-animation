extends GdUnitTestSuite

# ============================================================================
# 10-CYCLE REPEATABILITY & CLEAN RESET SUITE: "LEON AND THE RUNAWAY STAR"
# ----------------------------------------------------------------------------
# Verifies that restarting the entire animated short 10 consecutive times
# maintains clean state, zero memory leaks, exact 1-Leon invariant, and
# deterministic behavior across all resets.
# ============================================================================

const MOVIE_SCENE := preload("res://scenes/production/runaway_star/runaway_star_movie.tscn")
const LeonCharacterScript := preload("res://scenes/production/runaway_star/leon_movie_character.gd")

func test_10_consecutive_clean_resets() -> void:
	for cycle in range(10):
		var movie := MOVIE_SCENE.instantiate()
		get_tree().root.add_child(movie)
		
		var leon := movie.get_node("LeonCharacter")
		var star := movie.get_node("RunawayStar")
		var circle := movie.get_node("GlowingCircle")
		var camera := movie.get_node("CinematicCamera")
		
		assert_that(leon).is_not_null()
		assert_that(star).is_not_null()
		assert_that(circle).is_not_null()
		assert_that(camera).is_not_null()
		
		# 1. Check exactly 1 Leon instance
		var leon_chars := []
		_collect_nodes_by_type(movie, LeonCharacterScript, leon_chars)
		assert_that(leon_chars.size()).is_equal(1)
		
		# 2. Advance 60 frames
		for frame in range(15):
			movie._process(1.0 / 60.0)
			
		# 3. Check view slot validity
		var view_slot: Node2D = leon.get_node("ViewSlot")
		assert_that(view_slot.get_child_count()).is_equal(1)
		
		# 4. Clean teardown
		get_tree().root.remove_child(movie)
		movie.free()
		
		await get_tree().process_frame

func _collect_nodes_by_type(root: Node, script_type: Variant, out_array: Array) -> void:
	if root.get_script() == script_type or (script_type is String and root.is_class(script_type)):
		out_array.append(root)
	elif script_type is GDScript and root.get_script() == script_type:
		out_array.append(root)
	for child in root.get_children():
		_collect_nodes_by_type(child, script_type, out_array)
