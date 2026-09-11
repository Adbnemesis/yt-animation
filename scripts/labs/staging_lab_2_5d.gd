extends Node2D
class_name StagingLab25D

# ============================================================================
# 2.5D STAGING LAB — EXPERIMENTAL
# ----------------------------------------------------------------------------
# Answers: "Can our existing 2D cutout brawlers occupy a real 3D space while
# staying 2D?"  Uses ONLY the existing Leon/Nita/Bo rigs (wrapped, untouched)
# plus a shared projection model. Nothing in production is modified.
#
# Controls:
#   1-4  : FRONT / SIDE / 45 / OBLIQUE view modes
#   F    : cycle Nita rig (side -> front -> back)
#   V    : toggle A/B (flat z=0 vs 2.5D depth)
#   SPACE: toggle auto demo
#   R    : reset dummies
# ============================================================================

const ProjectionClass = preload("res://scripts/labs/projection_2_5d.gd")

const BO_PROJ_SCENE := "res://scenes/bo_projectile.tscn"
const LAB_PROJ_SCENE := "res://scenes/labs/lab_projectile.tscn"

@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var stage: Node2D = get_node_or_null("World/Stage")
@onready var hill_far: Sprite2D = get_node_or_null("BG/HillFar")
@onready var hill_near: Sprite2D = get_node_or_null("BG/HillNear")
@onready var crate_mid: Sprite2D = get_node_or_null("World/Stage/CrateMid")
@onready var crate_near: Sprite2D = get_node_or_null("World/Stage/CrateNear")
@onready var pillar: Sprite2D = get_node_or_null("World/Stage/Pillar")
@onready var wall_back: StaticBody2D = get_node_or_null("World/Stage/WallBack")

@onready var leon_a: DepthActor25D = get_node_or_null("World/Stage/LeonA")
@onready var leon_b: DepthActor25D = get_node_or_null("World/Stage/LeonB")
@onready var leon_c: DepthActor25D = get_node_or_null("World/Stage/LeonC")
@onready var nita: DepthActor25D = get_node_or_null("World/Stage/Nita")
@onready var bo: DepthActor25D = get_node_or_null("World/Stage/Bo")

@onready var dummy_near: Area2D = get_node_or_null("World/Stage/DummyNear")
@onready var dummy_mid: Area2D = get_node_or_null("World/Stage/DummyMid")
@onready var dummy_far: Area2D = get_node_or_null("World/Stage/DummyFar")

@onready var lbl_mode: Label = get_node_or_null("UI/Panel/VBox/LblMode")
@onready var lbl_demo: Label = get_node_or_null("UI/Panel/VBox/LblDemo")

const ACTORS := ["leon_a", "leon_b", "leon_c", "nita", "bo"]

var view_mode: int = ProjectionClass.ViewMode.SIDE
var flat_mode: bool = false
var _saved_z := {} # actor name -> world_z captured when collapsing to flat
var auto: bool = true
var running: bool = false
var nita_rig: int = DepthActor25D.RIG_SIDE
var focused: String = "leon_a"
var demo_timer: float = 0.0
var current_test: String = "TEST: depth triangle"

func _ready() -> void:
	if get_tree().root.has_node("VFXManager"):
		var vm = get_tree().root.get_node("VFXManager")
		for d in [dummy_near, dummy_mid, dummy_far]:
			if d:
				vm.bind_target(d)
	# Bo's real arrows spawn into the lab root; re-parent them into the Bo
	# wrapper so they inherit its depth scale/position.
	if bo and bo.get_node_or_null("Body"):
		var bbody = bo.get_node("Body")
		if bbody.has_signal("game_event_emitted") and not bbody.game_event_emitted.is_connected(_on_bo_event):
			bbody.game_event_emitted.connect(_on_bo_event)
	if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
		get_tree().process_frame.connect(start_demo, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(start_demo, CONNECT_ONE_SHOT)

func wait_sec(seconds: float) -> void:
	var frames := int(round(seconds * 60.0))
	for i in range(frames):
		if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw

func _physics_process(delta: float) -> void:
	demo_timer += delta
	_apply_parallax()
	_anchor_bo_projectiles()
	_update_ui()

func _on_bo_event(_ev_name: String, _data: Dictionary) -> void:
	# Bo's real arrows are re-parented into the wrapper every frame by
	# _anchor_bo_projectiles(), which keeps them at Bo's depth.
	pass

func _anchor_bo_projectiles() -> void:
	if not bo:
		return
	for child in get_children():
		if child is Area2D and child.is_in_group("projectiles") and child.get_parent() == self:
			child.reparent.call_deferred(bo)

func _apply_parallax() -> void:
	if not camera:
		return
	var cam_offset := camera.position - Vector2(576, 430)
	if hill_far:
		hill_far.position = Vector2(576, 330) + cam_offset * (1.0 - 0.12)
	if hill_near:
		hill_near.position = Vector2(576, 400) + cam_offset * (1.0 - 0.4)

# --- Staging helpers ---

func _actor(a: String) -> DepthActor25D:
	match a:
		"leon_a":
			return leon_a
		"leon_b":
			return leon_b
		"leon_c":
			return leon_c
		"nita":
			return nita
		"bo":
			return bo
	return null

func _place(a: String, x: float, z: float, f: int = -1) -> void:
	var actor := _actor(a)
	if not actor:
		return
	actor.world_x = x
	actor.world_z = 0.0 if flat_mode else z
	if f >= 0:
		actor.set_facing(f)
	actor.apply_projection()

func _set_view(mode: int) -> void:
	view_mode = mode
	for a in ACTORS:
		var actor := _actor(a)
		if actor:
			actor.set_view_mode(mode)
	# Lab projectiles already in flight keep their own mode; new ones use it.
	_update_ui()

func _set_flat(flat: bool) -> void:
	flat_mode = flat
	for a in ACTORS:
		var actor := _actor(a)
		if not actor:
			continue
		if flat:
			# Collapse depth (A/B comparison): remember z so B can restore it.
			_saved_z[a] = actor.world_z
			actor.world_z = 0.0
		elif _saved_z.has(a):
			actor.world_z = _saved_z[a]
			_saved_z.erase(a)
		actor.apply_projection()
	if flat:
		if crate_mid: crate_mid.visible = false
		if pillar: pillar.visible = false
		if wall_back: wall_back.visible = false
	else:
		if crate_mid: crate_mid.visible = true
		if pillar: pillar.visible = true
		if wall_back: wall_back.visible = true
	_update_ui()

func _cycle_nita_rig() -> void:
	if not nita:
		return
	nita_rig = (nita_rig + 1) % 3
	nita.set_rig(nita_rig)

func _reset_dummies() -> void:
	for d in [dummy_near, dummy_mid, dummy_far]:
		if d and d.has_method("reset_dummy"):
			d.reset_dummy()

func _spawn_depth_arrow(from_x: float, from_z: float, dir_x: float, dir_z: float) -> void:
	if not stage:
		return
	var p: LabProjectile = load(LAB_PROJ_SCENE).instantiate() as LabProjectile
	if not p:
		return
	stage.add_child(p)
	p.setup(
		BO_PROJ_SCENE, from_x, from_z, dir_x, dir_z,
		560.0, 40.0, "BO_BASIC", view_mode
	)

func _pan(pos: Vector2, zoom: float, dur: float) -> void:
	if not camera:
		return
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(camera, "position", pos, dur)
	tw.tween_property(camera, "zoom", Vector2(zoom, zoom), dur)

func _update_ui() -> void:
	if lbl_mode:
		var vname := "SIDE"
		match view_mode:
			ProjectionClass.ViewMode.FRONT:
				vname = "FRONT"
			ProjectionClass.ViewMode.DEG45:
				vname = "45"
			ProjectionClass.ViewMode.OBLIQUE:
				vname = "OBLIQUE"
		lbl_mode.text = "VIEW: %s | STAGING: %s" % [vname, ("A: FLAT z=0" if flat_mode else "B: 2.5D depth")]
	if lbl_demo:
		var leon_z := "n/a"
		if leon_a:
			leon_z = "%.0f" % leon_a.world_z
		lbl_demo.text = "%s\nLeon z=%s | Nita z=%s | Bo z=%s (0=near,180=far)" % [
			current_test,
			leon_z,
			("%.0f" % nita.world_z) if nita else "?",
			("%.0f" % bo.world_z) if bo else "?"
		]

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()):
		return
	match event.keycode:
		KEY_1: _set_view(ProjectionClass.ViewMode.FRONT)
		KEY_2: _set_view(ProjectionClass.ViewMode.SIDE)
		KEY_3: _set_view(ProjectionClass.ViewMode.DEG45)
		KEY_4: _set_view(ProjectionClass.ViewMode.OBLIQUE)
		KEY_F: _cycle_nita_rig()
		KEY_V:
			_set_flat(not flat_mode)
		KEY_SPACE:
			auto = not auto
		KEY_R:
			_reset_dummies()

# --- Demo timeline (deterministic, auto-cycling) ---

func start_demo() -> void:
	if running:
		return
	running = true
	_demo_sequence()

func _demo_sequence() -> void:
	_set_flat(false)
	while true:
		if not auto:
			await wait_sec(0.5)
			continue
		current_test = "TEST 1: SAME BRAWLER x3 (Leon at near/mid/far)"
		_pan(Vector2(560, 430), 1.02, 0.5)
		_place("leon_a", 300, 20, 1)
		_place("leon_b", 540, 95, 1)
		_place("leon_c", 810, 150, 1)
		_place("nita", 2000, 0)
		_place("bo", 2090, 0)
		await wait_sec(3.0)

		current_test = "TEST 2: TRIANGLE — Leon near / Nita mid / Bo far"
		_place("leon_a", 300, 15, 1)
		_place("nita", 460, 80, 1)
		_place("bo", 200, 145, 1)
		_place("leon_b", 2000, 0)
		_place("leon_c", 2090, 0)
		nita.jump()
		await wait_sec(3.0)

		current_test = "TEST 3: REVERSE — Bo near / Nita mid / Leon far"
		await wait_sec(0.5)
		_place("bo", 820, 15, 1)
		_place("nita", 470, 80, 1)
		_place("leon_a", 540, 145, 1)
		await wait_sec(3.0)

		current_test = "TEST 4: LEON MOVES THROUGH DEPTH (toward + away camera)"
		_place("leon_a", 700, 150, 1)
		_place("nita", 460, 80, 1)
		_place("bo", 300, 90, 1)
		_pan(Vector2(560, 430), 1.0, 0.5)
		leon_a.walk_to_2d(340, 20, 260.0)
		await wait_sec(5.0)
		leon_a.walk_to_2d(820, 155, 260.0)
		await wait_sec(5.0)

		current_test = "TEST 5: CROSSING CHARACTERS (sort flips by depth)"
		_place("leon_a", 260, 70, 1)
		_place("nita", 820, 70, -1)
		leon_a.walk_to_2d(560, 70, 150.0)
		nita.walk_to_2d(470, 70, 150.0)
		await wait_sec(4.5)
		await wait_sec(1.0)

		current_test = "TEST 6: FOREGROUND OCCLUSION (behind crate + pillar)"
		_place("nita", 700, 70, -1)
		_place("leon_a", 320, 70, 1)
		_place("bo", 960, 130, 1)
		nita.walk_to_2d(120, 70, 120.0)
		await wait_sec(6.5)

		current_test = "TEST 7: PROJECTILE THROUGH DEPTH (bg->fg, then fg->bg)"
		_place("nita", 620, 70, 1)
		_pan(Vector2(560, 430), 1.0, 0.4)
		_spawn_depth_arrow(220, 150, 1.0, -0.8)
		await wait_sec(2.2)
		_spawn_depth_arrow(880, 15, -1.0, 0.8)
		await wait_sec(2.4)

		current_test = "TEST 8: CAMERA WIDE/MEDIUM/CLOSE + DEPTH APPROACH"
		_place("leon_a", 560, 95, 1)
		_pan(Vector2(576, 430), 0.86, 0.8)
		await wait_sec(1.2)
		_pan(Vector2(520, 430), 1.12, 0.8)
		await wait_sec(1.2)
		_pan(Vector2(420, 430), 1.42, 0.8)
		leon_a.walk_to_2d(320, 15, 200.0)
		await wait_sec(4.0)

		current_test = "TEST 9: COMBAT GEOGRAPHY (3-depth attacks, real projectiles)"
		_reset_dummies()
		_pan(Vector2(540, 440), 1.05, 0.6)
		_place("leon_a", 300, 15, 1)
		_place("nita", 450, 80, 1)
		_place("bo", 170, 145, 1)
		await wait_sec(1.0)
		leon_a.trigger_attack()
		await wait_sec(1.0)
		nita.trigger_attack()
		await wait_sec(1.0)
		bo.trigger_attack()
		await wait_sec(2.6)

		current_test = "TEST 10: VIEW MODES (FRONT/SIDE/45/OBLIQUE) + Nita rigs"
		_pan(Vector2(500, 430), 1.0, 0.6)
		_place("leon_a", 520, 60, 1)
		_place("nita", 360, 30, 1)
		_place("bo", 2000, 0)
		_place("leon_b", 2090, 0)
		_set_view(ProjectionClass.ViewMode.FRONT)
		await wait_sec(1.4)
		_set_view(ProjectionClass.ViewMode.SIDE)
		await wait_sec(1.4)
		_set_view(ProjectionClass.ViewMode.DEG45)
		await wait_sec(1.4)
		_set_view(ProjectionClass.ViewMode.OBLIQUE)
		await wait_sec(1.4)
		nita.set_rig(DepthActor25D.RIG_FRONT)
		await wait_sec(1.6)
		nita.set_rig(DepthActor25D.RIG_BACK)
		await wait_sec(1.6)
		nita.set_rig(DepthActor25D.RIG_SIDE)
		await wait_sec(0.6)

		current_test = "TEST 11: A/B — FLAT vs 2.5D DEPTH"
		_set_flat(true)
		_pan(Vector2(540, 430), 1.0, 0.6)
		await wait_sec(3.0)
		_set_flat(false)
		await wait_sec(3.0)

		current_test = "TEST: depth triangle (loop)"