# GdUnit4 test suite covering VFX Manager event integration
class_name TestVFXEvents
extends GdUnitTestSuite

const LEON_SCENE_PATH := "res://scenes/leon_side.tscn"

func test_vfx_manager_direct_spawn() -> void:
	var vfx_mgr: VFXManagerClass = auto_free(VFXManagerClass.new())
	add_child(vfx_mgr)

	assert_that(vfx_mgr.VFX_SCENES.size()).is_equal(4)
	assert_that(vfx_mgr.VFX_SCENES.has("HIT_IMPACT")).is_true()
	assert_that(vfx_mgr.VFX_SCENES.has("DUST_PUFF")).is_true()
	assert_that(vfx_mgr.VFX_SCENES.has("SPAWN_FLASH")).is_true()
	assert_that(vfx_mgr.VFX_SCENES.has("SMOKE_BOMB")).is_true()

	var emitter = vfx_mgr.spawn_vfx("HIT_IMPACT", Vector2(100, 200), self)
	assert_that(emitter).is_not_null()
	assert_that(emitter.global_position).is_equal(Vector2(100, 200))
	assert_that(vfx_mgr.total_vfx_spawned).is_equal(1)
	assert_that(vfx_mgr.vfx_counts.get("HIT_IMPACT", 0)).is_equal(1)

func test_vfx_manager_character_event_binding() -> void:
	var vfx_mgr: VFXManagerClass = auto_free(VFXManagerClass.new())
	add_child(vfx_mgr)

	var scene: PackedScene = load(LEON_SCENE_PATH)
	var leon = auto_free(scene.instantiate())
	add_child(leon)

	vfx_mgr.bind_character(leon)

	# 1. Test LAND -> DUST_PUFF
	leon.state_changed.emit("JUMP_AIRBORNE", "JUMP_LAND")
	assert_that(vfx_mgr.last_vfx_event).is_equal("DUST_PUFF")
	assert_that(vfx_mgr.vfx_counts.get("DUST_PUFF", 0)).is_equal(1)

	# 2. Test ATTACK_IMPACT -> HIT_IMPACT
	leon.attack_impact.emit(Vector2(350, 420))
	assert_that(vfx_mgr.last_vfx_event).is_equal("HIT_IMPACT")
	assert_that(vfx_mgr.last_vfx_position).is_equal(Vector2(350, 420))
	assert_that(vfx_mgr.vfx_counts.get("HIT_IMPACT", 0)).is_equal(1)

	# 3. Test PROJECTILE_SPAWNED -> SPAWN_FLASH
	leon.projectile_spawned.emit(Vector2(200, 300), 1)
	assert_that(vfx_mgr.last_vfx_event).is_equal("SPAWN_FLASH")
	assert_that(vfx_mgr.last_vfx_position).is_equal(Vector2(200, 300))
	assert_that(vfx_mgr.vfx_counts.get("SPAWN_FLASH", 0)).is_equal(1)

	# 4. Test SUPER_START -> SMOKE_BOMB
	leon.super_event.emit("SUPER_START", {})
	assert_that(vfx_mgr.last_vfx_event).is_equal("SMOKE_BOMB")
	assert_that(vfx_mgr.vfx_counts.get("SMOKE_BOMB", 0)).is_equal(1)

	# 5. Test SUPER_END -> SMOKE_BOMB
	leon.super_event.emit("SUPER_END", {})
	assert_that(vfx_mgr.last_vfx_event).is_equal("SMOKE_BOMB")
	assert_that(vfx_mgr.vfx_counts.get("SMOKE_BOMB", 0)).is_equal(2)
