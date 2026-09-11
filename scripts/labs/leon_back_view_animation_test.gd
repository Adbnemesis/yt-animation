extends Node2D
class_name LeonBackViewAnimationTest

# ============================================================================
# LEON — BACK VIEW COMPLETE ANIMATION FOUNDATION TEST
# ----------------------------------------------------------------------------
# Master test bed for the canonical production Leon back rig:
#   res://scenes/videos/leon_elevator/leon_back.tscn
#
# SYSTEM A: VIEW-SPECIFIC BACK ANIMATION (via LeonBackController)
#   - Idle (breathing, shoulder shift, living tail sway)
#   - Acceleration, Stop, Walk, Run away into depth
#   - Jump (anticipation -> launch -> airborne -> fall -> land -> recovery)
#   - Hit -> Knockback -> Recovery (recoil flinch, tail twitch, elastic settle)
#   - Basic Attack (anticipation -> aim -> release through socket at (26, -32))
#     with trajectory firing away from camera into depth (+z)
#   - Super (anticipation -> activation -> smoke -> stealth -> reappear)
#   - Head/neck acting (attention from behind without fake front faces)
#   - Real Leon SFX chain via AudioManager
#
# SYSTEM B: 2.5D SPATIAL MOVEMENT (shared CinematicCamera)
#   - Horizontal X movement preserves apparent scale
#   - Depth movement scales character monotonically (FAR small, NEAR large)
#   - Diagonal movement combines X displacement and depth scaling
#   - Occlusion via foreground pillar, solid obstacle collision
#
# PROJECTILE CAUSALITY:
#   ATTACK -> RELEASE (real SFX) -> SPAWN at socket -> TRAVEL into depth
#   -> COLLISION -> IMPACT -> VFX -> TARGET REACTION
# ============================================================================

const DUMMY_SCENE := preload("res://scenes/target_dummy.tscn")
const PROJECTILE_SCENE := preload("res://scripts/labs/leon_spatial_projectile.gd")
const LeonBackControllerClass = preload("res://scripts/labs/leon_back_controller.gd")

# Movement tuning (world units per second)
const WALK_SPEED := 220.0
const RUN_SPEED := 420.0
const ACCEL := 900.0
const DECEL := 1300.0
const DEPTH_RANGE := Vector2(40.0, 550.0)
const X_RANGE := Vector2(-450.0, 450.0)

@onready var camera: CinematicCamera = $CameraRig
@onready var sky: ColorRect = $Sky
@onready var ground: ColorRect = $Ground
@onready var horizon_line: Line2D = $HorizonLine
@onready var actor_root: Node2D = $ActorRoot
@onready var shadow: Polygon2D = $ActorRoot/Shadow
@onready var leon_back: LeonBackController = $ActorRoot/LeonBack

# HUD
@onready var lbl_title: Label = $UI/Panel/VBox/LblTitle
@onready var lbl_step: Label = $UI/Panel/VBox/LblStep
@onready var lbl_debug: Label = $UI/Panel/VBox/LblDebug
@onready var lbl_debug2: Label = $UI/Panel/VBox/LblDebug2
@onready var lbl_combat: Label = $UI/Panel/VBox/LblCombat
@onready var lbl_controls: Label = $UI/Panel/VBox/LblControls

# Spatial coordinates for Leon (x = lateral, y = depth z)
var world_pos := Vector2(0.0, 160.0)
var elevation: float = 0.0
var base_scale: float = 1.9

# Movement state
var velocity := Vector2.ZERO
var move_input := Vector2.ZERO
var wants_run: bool = false
var mirror_sign: float = 1.0
var projectile_active: bool = false

# Debug tracking
var last_event: String = "—"
var last_hit: String = "—"
var debug_visible: bool = true

# Environment
var dummy_node: TargetDummy = null
var dummy_world_pos := Vector2(0.0, 360.0)
var crate_root: Node2D = null
var crate_world_pos := Vector2(-260.0, 300.0)
var pillar_root: Node2D = null
var pillar_world_pos := Vector2(260.0, 80.0)

# Demo sequencer
var demo_running: bool = false
var demo_step: int = 0
var _demo_tween: Tween = null
var auto_start_demo: bool = true
var _auto_quit_duration: float = -1.0
var _time_elapsed: float = 0.0


func _ready() -> void:
	_check_cmdline_args()
	_setup_environment()
	_setup_dummy()

	if leon_back:
		leon_back.position = Vector2.ZERO
		leon_back.attack_released.connect(_on_attack_released)
		leon_back.super_started.connect(func(): last_event = "SUPER_START")
		leon_back.super_ended.connect(func(): last_event = "SUPER_END")
		leon_back.knockback_started.connect(func(_d): last_event = "KNOCKBACK")
		leon_back.landed.connect(func(): last_event = "LAND")
		leon_back.state_changed.connect(func(_s): pass)

	_apply_projection(true)
	_project_dummy()
	_project_props()

	if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
		get_tree().process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _check_cmdline_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-quit="):
			_auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			_auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()


func _on_first_frame() -> void:
	if auto_start_demo:
		start_demonstration()


func _physics_process(delta: float) -> void:
	if _auto_quit_duration > 0.0:
		_time_elapsed += delta
		if _time_elapsed >= _auto_quit_duration:
			get_tree().quit(0)
			return

	_handle_interactive_input(delta)
	_step_movement(delta)
	_apply_projection()
	_project_dummy()
	_project_props()
	_update_ui()


# ============================================================================
# 1. ENVIRONMENT
# ============================================================================


func _setup_environment() -> void:
	_build_grid()

	# Crate: world scale reference (~55px height)
	crate_root = Node2D.new()
	crate_root.name = "Crate"
	add_child(crate_root)
	var crate_body := Polygon2D.new()
	crate_body.color = Color(0.6, 0.45, 0.25)
	crate_body.polygon = PackedVector2Array(
		[Vector2(-28, -55), Vector2(28, -55), Vector2(28, 0), Vector2(-28, 0)]
	)
	crate_root.add_child(crate_body)
	var brace := Line2D.new()
	brace.width = 3.0
	brace.default_color = Color(0.42, 0.31, 0.17)
	brace.points = PackedVector2Array([Vector2(-26, -53), Vector2(26, -2)])
	crate_root.add_child(brace)

	# Foreground pillar for occlusion test (depth 80)
	pillar_root = Node2D.new()
	pillar_root.name = "FgPillar"
	add_child(pillar_root)
	var pillar_body := Polygon2D.new()
	pillar_body.color = Color(0.22, 0.24, 0.3)
	pillar_body.polygon = PackedVector2Array(
		[Vector2(-24, -260), Vector2(24, -260), Vector2(20, 0), Vector2(-20, 0)]
	)
	pillar_root.add_child(pillar_body)
	var cap := Polygon2D.new()
	cap.color = Color(0.34, 0.37, 0.46)
	cap.polygon = PackedVector2Array(
		[Vector2(-32, -260), Vector2(32, -260), Vector2(32, -244), Vector2(-32, -244)]
	)
	pillar_root.add_child(cap)


func _build_grid() -> void:
	for x in [-420.0, -210.0, 0.0, 210.0, 420.0]:
		var grid_line := Line2D.new()
		grid_line.width = 1.6
		grid_line.default_color = Color(0.25, 0.48, 0.32, 0.35)
		var p_far := camera.project(Vector2(x, 520.0), 0.0)
		var p_near := camera.project(Vector2(x, -50.0), 0.0)
		grid_line.points = PackedVector2Array([p_far.pos, p_near.pos])
		grid_line.z_index = -2080
		add_child(grid_line)


func _setup_dummy() -> void:
	dummy_node = DUMMY_SCENE.instantiate()
	dummy_node.name = "TargetDummy"
	add_child(dummy_node)


func _project_dummy() -> void:
	if dummy_node and camera:
		var p := camera.project(dummy_world_pos, 0.0)
		dummy_node.position = p.pos
		dummy_node.scale = Vector2.ONE * maxf(p.scale, 0.01)
		dummy_node.z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)


func _project_props() -> void:
	for prop in [[crate_root, crate_world_pos], [pillar_root, pillar_world_pos]]:
		var node: Node2D = prop[0]
		var w_pos: Vector2 = prop[1]
		if node and camera:
			var p := camera.project(w_pos, 0.0)
			node.position = p.pos
			node.scale = Vector2.ONE * maxf(p.scale, 0.01)
			node.z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)


# ============================================================================
# 2. SPATIAL PROJECTION
# ============================================================================


func _apply_projection(_instant: bool = false) -> void:
	if camera == null or actor_root == null:
		return

	var p := camera.project(world_pos, elevation)
	actor_root.position = p.pos
	actor_root.scale = Vector2.ONE * maxf(p.scale * base_scale, 0.01)
	actor_root.scale.x = absf(actor_root.scale.x) * mirror_sign
	actor_root.z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)

	if shadow:
		shadow.modulate.a = 0.42 if elevation <= 0.5 else 0.18
		shadow.scale = Vector2.ONE * (1.0 if elevation <= 0.5 else 0.85)

	if leon_back:
		var speed_factor := velocity.length() / RUN_SPEED
		var depth_lean := clampf(velocity.y / RUN_SPEED, -1.0, 1.0)
		leon_back.set_motion_context(speed_factor, depth_lean)


func apparent_scale() -> float:
	return actor_root.scale.x if actor_root else 0.0


# ============================================================================
# 3. MOVEMENT — acceleration / deceleration ramp
# ============================================================================


func _step_movement(delta: float) -> void:
	var target_speed := RUN_SPEED if wants_run else WALK_SPEED
	var target_vel := move_input * target_speed

	if move_input != Vector2.ZERO:
		velocity = velocity.move_toward(target_vel, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECEL * delta)

	world_pos += velocity * delta
	world_pos.x = clampf(world_pos.x, X_RANGE.x, X_RANGE.y)
	world_pos.y = clampf(world_pos.y, DEPTH_RANGE.x, DEPTH_RANGE.y)
	elevation = maxf(elevation, 0.0)

	if not leon_back.is_attacking():
		var dir_sign := _axis_sign(velocity.x, 12.0)
		if dir_sign != 0.0 and dir_sign != mirror_sign:
			_turn_to(dir_sign)

	if (
		leon_back.current_state
		in [
			LeonBackController.State.IDLE,
			LeonBackController.State.WALK,
			LeonBackController.State.RUN,
			LeonBackController.State.ACCEL,
			LeonBackController.State.STOP
		]
	):
		_update_locomotion_state()


func _update_locomotion_state() -> void:
	var speed := velocity.length()
	var was_stopped := speed < 8.0
	if was_stopped:
		if leon_back.current_state != LeonBackController.State.IDLE:
			leon_back.set_locomotion(LeonBackController.State.IDLE)
		return
	if leon_back.current_state == LeonBackController.State.IDLE and speed < target_speed_now() * 0.85:
		leon_back.set_locomotion(LeonBackController.State.ACCEL)
		return
	leon_back.set_locomotion(
		LeonBackController.State.RUN if wants_run else LeonBackController.State.WALK
	)


func target_speed_now() -> float:
	return RUN_SPEED if wants_run else WALK_SPEED


func _axis_sign(v: float, dead: float) -> float:
	if absf(v) < dead:
		return 0.0
	return 1.0 if v > 0.0 else -1.0


func _turn_to(sign: float) -> void:
	mirror_sign = sign
	if leon_back:
		leon_back.set_mirror_sign(sign)
	var art := actor_root
	var tw := create_tween()
	tw.tween_property(art, "modulate:a", 0.25, 0.05)
	tw.tween_callback(func(): _apply_projection(true))
	tw.tween_property(art, "modulate:a", 1.0, 0.06)


# ============================================================================
# 4. INTERACTIVE TEST CONTROLS
# ============================================================================


func _handle_interactive_input(_delta: float) -> void:
	if demo_running:
		if Input.is_key_pressed(KEY_ESCAPE):
			demo_running = false
			if _demo_tween and _demo_tween.is_valid():
				_demo_tween.kill()
			_set_step_label("Demo Cancelled — Interactive Mode")
			move_input = Vector2.ZERO
		return

	move_input = Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		move_input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move_input.x += 1.0
	if Input.is_key_pressed(KEY_W):
		move_input.y += 1.0  # away into depth
	if Input.is_key_pressed(KEY_S):
		move_input.y -= 1.0  # toward camera
	if move_input.length() > 1.0:
		move_input = move_input.normalized()

	wants_run = Input.is_key_pressed(KEY_SHIFT)

	if Input.is_key_pressed(KEY_SPACE):
		_interactive_jump()
	if Input.is_key_pressed(KEY_J):
		_interactive_attack()
	if Input.is_key_pressed(KEY_K):
		_interactive_super()
	if Input.is_key_pressed(KEY_H):
		_interactive_hit()
	if Input.is_key_pressed(KEY_R):
		reset_test()
	if Input.is_key_pressed(KEY_F3) or Input.is_key_pressed(KEY_F):
		debug_visible = not debug_visible
		_apply_debug_visibility()
	if Input.is_key_pressed(KEY_ENTER):
		start_demonstration()


var _jump_lock: bool = false
var _attack_lock: bool = false
var _super_lock: bool = false
var _hit_lock: bool = false


func _interactive_jump() -> void:
	if _jump_lock:
		return
	_jump_lock = true
	var prev_input := move_input
	move_input = Vector2.ZERO
	trigger_jump()
	get_tree().create_timer(0.35).timeout.connect(func(): _jump_lock = false)
	get_tree().create_timer(1.3).timeout.connect(func(): move_input = prev_input)


func _interactive_attack() -> void:
	if _attack_lock:
		return
	_attack_lock = true
	var prev_input := move_input
	move_input = Vector2.ZERO
	trigger_attack_toward_dummy()
	get_tree().create_timer(0.4).timeout.connect(func(): _attack_lock = false)
	get_tree().create_timer(0.95).timeout.connect(func(): move_input = prev_input)


func _interactive_super() -> void:
	if _super_lock:
		return
	_super_lock = true
	var prev_input := move_input
	move_input = Vector2.ZERO
	leon_back.trigger_super()
	get_tree().create_timer(0.6).timeout.connect(func(): _super_lock = false)
	get_tree().create_timer(3.0).timeout.connect(func(): move_input = prev_input)


func _interactive_hit() -> void:
	if _hit_lock:
		return
	_hit_lock = true
	var knock := Vector2(0.0, -1.0)
	leon_back.trigger_hit(knock)
	var tw := create_tween()
	(
		tw
		. tween_property(self, "world_pos", world_pos + knock * 50.0, 0.25)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	get_tree().create_timer(1.0).timeout.connect(func(): _hit_lock = false)


func _apply_debug_visibility() -> void:
	if lbl_debug:
		lbl_debug.visible = debug_visible
	if lbl_debug2:
		lbl_debug2.visible = debug_visible
	if lbl_combat:
		lbl_combat.visible = debug_visible


# ============================================================================
# 5. ATTACK -> PROJECTILE CAUSALITY
# ============================================================================


func aim_angle_toward_dummy() -> float:
	var d := (dummy_world_pos - world_pos).normalized()
	return rad_to_deg(atan2(d.x, -d.y))


func trigger_attack_toward_dummy() -> void:
	if leon_back.is_attacking():
		return
	var aim_deg := aim_angle_toward_dummy()
	leon_back.trigger_attack(aim_deg)
	last_event = "ATTACK_RELEASE"


func trigger_jump() -> void:
	if leon_back.is_jumping():
		return
	leon_back.trigger_jump()
	var tw := create_tween()
	tw.tween_property(self, "elevation", 52.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	tw.tween_property(self, "elevation", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	tw.tween_callback(func(): last_event = "JUMP_LAND")


func _on_attack_released(dir_vector: Vector2, spawn_offset: Vector2) -> void:
	last_event = "PROJECTILE_SPAWN"
	projectile_active = true

	var spawn_world: Vector2 = world_pos + spawn_offset
	var spawn_elev: float = 38.0

	var proj = PROJECTILE_SCENE.new()
	proj.name = "LeonBackProjectile"
	add_child(proj)
	proj.setup(camera, spawn_world, dummy_world_pos, spawn_elev, dummy_node, 720.0)
	proj.hit_target.connect(_on_projectile_hit)


func _on_projectile_hit(target: Node2D) -> void:
	projectile_active = false
	last_event = "PROJECTILE_HIT"
	if dummy_node and target == dummy_node:
		last_hit = "TARGET_DUMMY (HP %.0f)" % dummy_node.current_hp
	else:
		last_hit = "TARGET_DUMMY"


# ============================================================================
# 6. DEBUG UI
# ============================================================================


func _update_ui() -> void:
	if leon_back and lbl_debug:
		var state_name: String = str(
			LeonBackController.STATE_NAMES.get(leon_back.current_state, "IDLE")
		)
		var yaw_deg := rad_to_deg(leon_back.facing_yaw)
		lbl_debug.text = (
			"STATE: %s | ANIMATION: %s | FACING: BACK (yaw %+.1f) | VIEW: BACK%s"
			% [state_name, state_name, yaw_deg, " [MIRRORED]" if mirror_sign < 0.0 else ""]
		)
		if lbl_debug2:
			var depth := world_pos.y
			var zone := "NEAR" if depth < 130.0 else ("MID" if depth < 320.0 else "FAR")
			lbl_debug2.text = (
				"WORLD X: %+.1f | DEPTH: %.1f (%s) | APPARENT SCALE: %.3fx | PROJECTILE: %s"
				% [
					world_pos.x,
					depth,
					zone,
					apparent_scale(),
					"ACTIVE" if projectile_active else "NONE"
				]
			)
	if lbl_combat:
		lbl_combat.text = (
			"TARGET DUMMY HP: %.0f / %.0f | HITS: %d | LAST EVENT: %s | LAST HIT: %s"
			% [
				dummy_node.current_hp if dummy_node else 0.0,
				dummy_node.max_hp if dummy_node else 0.0,
				dummy_node.hit_count if dummy_node else 0,
				last_event,
				last_hit
			]
		)


func _set_step_label(text: String) -> void:
	if lbl_step:
		lbl_step.text = text


# ============================================================================
# 7. DEMO MATRIX SEQUENCER — 17 steps
# ============================================================================


func start_demonstration() -> void:
	demo_running = true
	demo_step = 1
	_reset_state()
	_execute_demo_step(1)


func _reset_state() -> void:
	world_pos = Vector2(0.0, 160.0)
	elevation = 0.0
	velocity = Vector2.ZERO
	move_input = Vector2.ZERO
	wants_run = false
	mirror_sign = 1.0
	if leon_back:
		leon_back.set_mirror_sign(1.0)
		leon_back.reset_to_idle()
		leon_back.change_state(LeonBackController.State.IDLE)
	dummy_world_pos = Vector2(0.0, 360.0)
	if dummy_node:
		dummy_node.reset_dummy()
	_reset_camera()


func _reset_camera() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(camera, "cam_z", -260.0, 0.6)
	tw.parallel().tween_property(camera, "zoom", 1.0, 0.6)
	tw.parallel().tween_property(camera, "cam_height", 150.0, 0.6)
	tw.parallel().tween_property(camera, "cam_x", 0.0, 0.6)


func reset_test() -> void:
	demo_running = false
	if _demo_tween and _demo_tween.is_valid():
		_demo_tween.kill()
	_reset_state()
	_set_step_label("RESET — Interactive Mode (matrix re-runs on ENTER)")
	last_event = "RESET"
	if dummy_node:
		last_hit = "—"


func _demo_move(
	dir: Vector2, run: bool, duration: float, on_done: Callable, start_delay: float = 0.0
) -> void:
	if start_delay > 0.0:
		_demo_tween.tween_interval(start_delay)
	move_input = dir
	wants_run = run
	_demo_tween.tween_interval(duration)
	_demo_tween.tween_callback(
		func():
			move_input = Vector2.ZERO
			on_done.call()
	)


func _execute_demo_step(step: int) -> void:
	if not demo_running:
		return
	demo_step = step
	if _demo_tween and _demo_tween.is_valid():
		_demo_tween.kill()
	_demo_tween = create_tween()

	match step:
		1:
			_demo_step_1_idle()
		2:
			_demo_step_2_walk_depth()
		3:
			_demo_step_3_stop()
		4:
			_demo_step_4_run_depth()
		5:
			_demo_step_5_run_stop()
		6:
			_demo_step_6_accel()
		7:
			_demo_step_7_jump()
		8:
			_demo_step_8_hit_knockback()
		9:
			_demo_step_9_attack_straight()
		10:
			_demo_step_10_attack_left()
		11:
			_demo_step_11_attack_right()
		12:
			_demo_step_12_attack_while_moving()
		13:
			_demo_step_13_super()
		14:
			_demo_step_14_head_acting()
		15:
			_demo_step_15_depth_travel()
		16:
			_demo_step_16_occlusion()
		17:
			_demo_step_17_closeup()
		_:
			demo_running = false
			_set_step_label(
				"TEST COMPLETE — all 17 steps of Back View foundation matrix passed. ENTER: re-run"
			)


func _next_step() -> void:
	_execute_demo_step(demo_step + 1)


# ============================================================================
# 8. DEMO STEPS
# ============================================================================


## 1 — BACK IDLE: breathing, shoulder shift, living tail sway.
func _demo_step_1_idle() -> void:
	_set_step_label("1/17: BACK IDLE (breathing, shoulder shift, living tail sway)")
	_reset_state()
	_demo_tween.tween_interval(2.8)
	_demo_tween.tween_callback(_next_step)


## 2 — BACK WALK AWAY INTO DEPTH: strides away into depth, scale shrinks monotonically.
func _demo_step_2_walk_depth() -> void:
	_set_step_label("2/17: BACK WALK away into depth (alternating strides, tail counter-sway, scale shrinks)")
	_demo_move(Vector2(0.0, 1.0), false, 2.4, _next_step)


## 3 — BACK STOP: deceleration, foot braking, body settling.
func _demo_step_3_stop() -> void:
	_set_step_label("3/17: BACK WALK -> STOP (deceleration, foot braking, body settling)")
	_demo_tween.tween_interval(1.5)
	_demo_tween.tween_callback(_next_step)


## 4 — BACK RUN AWAY INTO DEPTH: stronger stride, forward lean, strong tail motion.
func _demo_step_4_run_depth() -> void:
	_set_step_label("4/17: BACK RUN away into depth (strong stride, forward lean, pronounced tail swing)")
	_demo_move(Vector2(0.0, 1.0), true, 2.0, _next_step)


## 5 — RUN -> STOP: readable run brake.
func _demo_step_5_run_stop() -> void:
	_set_step_label("5/17: BACK RUN -> STOP (deceleration, arm follow-through, tail settle)")
	_demo_tween.tween_interval(1.6)
	_demo_tween.tween_callback(_next_step)


## 6 — ACCELERATION: idle -> anticipation -> push-off -> walk into depth.
func _demo_step_6_accel() -> void:
	_set_step_label("6/17: BACK ACCELERATION (anticipation -> push-off -> walk into depth)")
	_reset_state()
	_demo_move(Vector2(0.0, 1.0), false, 1.8, _next_step, 0.4)


## 7 — JUMP: anticipation -> launch -> airborne tuck -> landing compression -> settle.
func _demo_step_7_jump() -> void:
	_set_step_label("7/17: BACK JUMP (anticipation -> launch -> airborne tuck -> landing settle)")
	_demo_tween.tween_interval(0.3)
	_demo_tween.tween_callback(func(): trigger_jump())
	_demo_tween.tween_interval(1.7)
	_demo_tween.tween_callback(_next_step)


## 8 — HIT -> KNOCKBACK -> RECOVERY: rear recoil flinch, tail twitch, elastic settle.
func _demo_step_8_hit_knockback() -> void:
	_set_step_label(
		"8/17: BACK HIT -> KNOCKBACK -> RECOVERY (recoil flinch, head snap, tail twitch, settle)"
	)
	_demo_tween.tween_interval(0.2)
	_demo_tween.tween_callback(
		func():
			leon_back.trigger_hit(Vector2(0.0, -1.0))
			var tw := create_tween()
			(
				tw
				. tween_property(self, "world_pos", world_pos + Vector2(0.0, -50.0), 0.3)
				. set_trans(Tween.TRANS_QUAD)
				. set_ease(Tween.EASE_OUT)
			)
	)
	_demo_tween.tween_interval(2.2)
	_demo_tween.tween_callback(_next_step)


## 9 — BACK BASIC ATTACK: fires shuriken straight into depth toward background dummy.
func _demo_step_9_attack_straight() -> void:
	_set_step_label("9/17: BACK BASIC ATTACK (fires shuriken into depth toward background dummy)")
	_reset_state()
	dummy_world_pos = Vector2(0.0, 360.0)
	_demo_tween.tween_interval(0.4)
	_demo_tween.tween_callback(func(): trigger_attack_toward_dummy())
	_demo_tween.tween_interval(1.5)
	_demo_tween.tween_callback(_next_step)


## 10 — BACK ATTACK ANGLED LEFT: fires into background-left dummy.
func _demo_step_10_attack_left() -> void:
	_set_step_label("10/17: BACK ATTACK aimed DEPTH-LEFT (trajectory follows aim to background dummy)")
	_reset_state()
	dummy_world_pos = Vector2(-140.0, 340.0)
	_demo_tween.tween_interval(0.4)
	_demo_tween.tween_callback(func(): trigger_attack_toward_dummy())
	_demo_tween.tween_interval(1.5)
	_demo_tween.tween_callback(_next_step)


## 11 — BACK ATTACK ANGLED RIGHT: fires into background-right dummy.
func _demo_step_11_attack_right() -> void:
	_set_step_label("11/17: BACK ATTACK aimed DEPTH-RIGHT (near-arm throw into background-right dummy)")
	_reset_state()
	dummy_world_pos = Vector2(140.0, 340.0)
	_demo_tween.tween_interval(0.4)
	_demo_tween.tween_callback(func(): trigger_attack_toward_dummy())
	_demo_tween.tween_interval(1.5)
	_demo_tween.tween_callback(_next_step)


## 12 — BACK ATTACK WHILE MOVING: depth walk -> attack -> resume walk.
func _demo_step_12_attack_while_moving() -> void:
	_set_step_label("12/17: BACK DEPTH WALK -> ATTACK -> RETURN TO WALK (seamless locomotion)")
	_reset_state()
	dummy_world_pos = Vector2(60.0, 380.0)
	_demo_move(Vector2(0.2, 0.8), false, 0.7, func(): trigger_attack_toward_dummy())
	_demo_tween.tween_interval(1.3)
	_demo_tween.tween_callback(_next_step)


## 13 — BACK SUPER WHILE WALKING: cyan smoke -> stealth shimmer -> reappear.
func _demo_step_13_super() -> void:
	_set_step_label("13/17: BACK SUPER while walking (cyan smoke -> stealth shimmer -> reappear)")
	_reset_state()
	_demo_move(Vector2(0.0, 0.8), false, 0.8, func(): leon_back.trigger_super())
	_demo_tween.tween_interval(2.6)
	_demo_tween.tween_callback(_next_step)


## 14 — HEAD & NECK ACTING: attention from behind via head turns and tilts (Parts 32/33).
func _demo_step_14_head_acting() -> void:
	_set_step_label("14/17: BACK HEAD/NECK ACTING (attention from behind: look left, look right, tilt)")
	_reset_state()
	_demo_tween.tween_interval(0.4)
	_demo_tween.tween_callback(func(): leon_back.look_toward(-18.0, 0.4))
	_demo_tween.tween_interval(0.8)
	_demo_tween.tween_callback(func(): leon_back.look_toward(18.0, 0.5))
	_demo_tween.tween_interval(0.8)
	_demo_tween.tween_callback(func(): leon_back.reset_head_pose(0.3))
	_demo_tween.tween_interval(0.6)
	_demo_tween.tween_callback(_next_step)


## 15 — DEPTH TRAVEL: NEAR -> FAR (size shrinks) then FAR -> NEAR (size grows).
func _demo_step_15_depth_travel() -> void:
	_set_step_label(
		"15/17: BACK DEPTH TRAVEL (NEAR -> FAR: size shrinks; FAR -> NEAR: size grows)"
	)
	_reset_state()
	world_pos = Vector2(0.0, 100.0)  # NEAR
	_demo_tween.tween_interval(0.4)
	_demo_tween.tween_callback(
		func():
			wants_run = true
			move_input = Vector2(0.0, 1.0)  # run away into depth
	)
	_demo_tween.tween_interval(2.2)
	_demo_tween.tween_callback(
		func():
			move_input = Vector2.ZERO
			wants_run = false
	)
	_demo_tween.tween_interval(0.6)
	_demo_tween.tween_callback(
		func():
			move_input = Vector2(0.0, -1.0)  # run toward camera
			wants_run = true
	)
	_demo_tween.tween_interval(2.0)
	_demo_tween.tween_callback(
		func():
			move_input = Vector2.ZERO
			wants_run = false
	)
	_demo_tween.tween_callback(_next_step)


## 16 — FOREGROUND OCCLUSION: passes behind foreground pillar at depth 80.
func _demo_step_16_occlusion() -> void:
	_set_step_label("16/17: FOREGROUND OCCLUSION (Passes Behind Pillar at Depth 80 and Emerges)")
	_reset_state()
	world_pos = Vector2(160.0, 160.0)
	_apply_projection(true)
	_demo_move(Vector2(1.0, 0.0), false, 1.8, _next_step, 0.3)


## 17 — CONTROLLED CLOSE-UP: WIDE -> MEDIUM -> CLOSE camera dolly framing back hood & tail.
func _demo_step_17_closeup() -> void:
	_set_step_label("17/17: BACK CLOSE-UP (WIDE -> MEDIUM -> CLOSE camera dolly framing hood & tail)")
	_reset_state()
	var tw := _demo_tween
	tw.tween_callback(func(): cam_tween({"cam_z": -100.0, "cam_height": 130.0, "zoom": 1.2}, 1.2))
	tw.tween_interval(1.4)
	tw.tween_callback(func(): cam_tween({"cam_z": 20.0, "cam_height": 85.0, "zoom": 1.5}, 1.2))
	tw.tween_interval(1.6)
	tw.tween_callback(func(): leon_back.look_toward(12.0, 0.5))
	tw.tween_interval(0.8)
	tw.tween_callback(func(): leon_back.reset_head_pose(0.3))
	tw.tween_callback(func(): cam_tween({"cam_z": -260.0, "cam_height": 150.0, "zoom": 1.0}, 1.2))
	tw.tween_interval(1.4)
	tw.tween_callback(
		func():
			demo_running = false
			_set_step_label(
				"TEST COMPLETE — all 17 steps of Back View foundation matrix passed. ENTER: re-run"
			)
	)


func cam_tween(props: Dictionary, dur: float) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for key in props:
		tw.tween_property(camera, key, props[key], dur)
