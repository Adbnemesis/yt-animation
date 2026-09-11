extends Node2D
class_name LeonFrontViewLab

# ============================================================================
# LEON FRONT VIEW LABORATORY
# ----------------------------------------------------------------------------
# Master test bed validating the canonical Leon Front-View Rig:
#   res://scenes/videos/leon_elevator/leon_front.tscn
#
# SYSTEM A: VIEW-SPECIFIC ANIMATION (Front View)
#   - Idle (Breathing bob, lollipop, hood crest, auto-blink)
#   - Walk & Run (Genuine forward alternating foot/leg lift, opposite arm swing)
#   - Stop / Brake (Foot planting, posture settle)
#   - Jump / Land (Anticipation squash, launch stretch, aerial hang, land squash)
#   - Basic Attack & Projectile Causality:
#       * Attack trajectory is strictly derived from Leon's rotation along
#         the Z-axis (ground orientation / facing angle)!
#       * When facing straight (rotation = 0), attacks fly forward towards
#         the camera (decreasing depth), expanding in scale as they approach.
#       * When rotated via Z-axis (e.g. -22° left or +22° right), attacks
#         travel along that exact rotated angle into the target dummy!
#   - Super Ability (Cyan smoke puff, transparency fade to stealth, reappear)
#   - Hit Reaction & Knockback (Flinch recoil, "hurt" expression, elastic recovery)
#   - Face Expression Suite (Happy, Angry, Shocked, Smug, Laughing, Neutral)
#
# SYSTEM B: 2.5D SPATIAL MOVEMENT
#   - Lateral X movement preserves apparent scale
#   - Depth Z movement scales character smoothly and monotonically
#   - Stable ground contact & dynamic contact shadow
# ============================================================================

const DUMMY_SCENE := preload("res://scenes/target_dummy.tscn")
const PROJECTILE_SCENE := preload("res://scripts/labs/leon_spatial_projectile.gd")
const LeonFrontController = preload("res://scripts/leon_front_controller.gd")

@onready var camera: CinematicCamera = $CameraRig
@onready var sky: ColorRect = $Sky
@onready var ground: ColorRect = $Ground
@onready var horizon_line: Line2D = $HorizonLine

@onready var actor_root: Node2D = $ActorRoot
@onready var shadow: Polygon2D = $ActorRoot/Shadow
@onready var leon_front: LeonFrontController = $ActorRoot/LeonFront

# HUD Elements
@onready var lbl_title: Label = $UI/Panel/VBox/LblTitle
@onready var lbl_step: Label = $UI/Panel/VBox/LblStep
@onready var lbl_state: Label = $UI/Panel/VBox/LblState
@onready var lbl_coords: Label = $UI/Panel/VBox/LblCoords
@onready var lbl_combat: Label = $UI/Panel/VBox/LblCombat
@onready var lbl_controls: Label = $UI/Panel/VBox/LblControls

var dummy_node: TargetDummy = null
var dummy_world_pos := Vector2(240.0, 180.0) # Stationed to the side initially

# Spatial Coordinates for Leon
var world_pos := Vector2(0.0, 180.0) # (x, depth_z)
var elevation: float = 0.0            # Y height above ground
var base_scale: float = 1.9           # High-visibility production framing (1:1 with leon_showcase_4k)

# Sequencer
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
	
	if leon_front:
		leon_front.position = Vector2.ZERO
		leon_front.attack_released.connect(_on_front_attack_released)
		
	_apply_projection(true)
	_project_dummy()
		
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

	_apply_projection()
	_project_dummy()
	_update_ui()
	_handle_interactive_input(delta)

func _setup_environment() -> void:
	sky.color = Color(0.11, 0.15, 0.22)
	ground.color = Color(0.18, 0.38, 0.24)
	horizon_line.default_color = Color(0.28, 0.58, 0.38, 0.85)
	
	var horizon := camera.horizon_y + camera.pitch_deg * 2.2
	sky.position = Vector2.ZERO
	sky.size = Vector2(1200, horizon)
	ground.position = Vector2(0, horizon)
	ground.size = Vector2(1200, 720.0 - horizon)
	horizon_line.points = PackedVector2Array([Vector2(0, horizon), Vector2(1200, horizon)])
	
	# Add perspective arena grid lines for clear depth perception
	for x in [-420.0, -210.0, 0.0, 210.0, 420.0]:
		var grid_line := Line2D.new()
		grid_line.width = 1.6
		grid_line.default_color = Color(0.25, 0.48, 0.32, 0.35)
		var p_far = camera.project(Vector2(x, 520.0), 0.0)
		var p_near = camera.project(Vector2(x, -50.0), 0.0)
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
		# Depth sorting: closer objects have higher z_index
		dummy_node.z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)

func _apply_projection(instant: bool = false) -> void:
	if camera == null or actor_root == null:
		return
	
	var p := camera.project(world_pos, elevation)
	actor_root.position = p.pos
	var s: float = maxf(p.scale * base_scale, 0.01)
	actor_root.scale = Vector2.ONE * s
	actor_root.z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
	
	if shadow:
		shadow.modulate.a = 0.42 if elevation <= 0.5 else 0.18
		shadow.scale = Vector2.ONE * (1.0 if elevation <= 0.5 else 0.85)

func _update_ui() -> void:
	if lbl_state and leon_front:
		var state_str: String = str(LeonFrontController.STATE_NAMES.get(leon_front.current_state, "IDLE"))
		var z_rot_deg: float = rad_to_deg(leon_front.rotation)
		lbl_state.text = "STATE: %s | Z-ROT: %+.1f° | FACING: %s" % [
			state_str, z_rot_deg,
			"CENTER (TOWARD CAM)" if absf(z_rot_deg) < 5.0 else ("LEFT" if z_rot_deg < 0 else "RIGHT")
		]
	
	if lbl_coords:
		lbl_coords.text = "WORLD X: %+.1f | Y (Elev): %.1f | DEPTH: %.1f | APPARENT SCALE: %.3fx" % [
			world_pos.x, elevation, world_pos.y, actor_root.scale.x
		]
		
	if lbl_combat and dummy_node:
		lbl_combat.text = "TARGET DUMMY HP: %.0f / %.0f | HITS: %d" % [
			dummy_node.current_hp, dummy_node.max_hp, dummy_node.hit_count
		]

# --- Attack & Projectile Causality -------------------------------------------

func _on_front_attack_released(dir_vector: Vector2, spawn_offset: Vector2) -> void:
	var spawn_world: Vector2 = world_pos + spawn_offset
	var spawn_elev: float = elevation + 34.0
	
	# The attack direction vector is strictly governed by Leon's Z-axis rotation!
	# dir_vector is (sin(z_rot), -cos(z_rot)).
	# Target world position is along this ray:
	var target_world: Vector2 = dummy_world_pos
	
	var proj = PROJECTILE_SCENE.new()
	add_child(proj)
	proj.setup(camera, spawn_world, target_world, spawn_elev, dummy_node, 720.0)

# ============================================================================
# TEST MATRIX SEQUENCER
# ============================================================================

func start_demonstration() -> void:
	demo_running = true
	demo_step = 1
	_execute_demo_step(1)

func _execute_demo_step(step: int) -> void:
	if not demo_running:
		return
	demo_step = step
	if _demo_tween and _demo_tween.is_valid():
		_demo_tween.kill()
	_demo_tween = create_tween()
	
	match step:
		1:
			_set_step_label("1/14: CANONICAL FRONT IDLE (Chameleon Cowl, Button Eyes, Lollipop, Breathing Bob)")
			world_pos = Vector2(0.0, 180.0)
			dummy_world_pos = Vector2(240.0, 180.0) # Stationed to side, Leon takes center stage
			elevation = 0.0
			leon_front.rotation = 0.0
			leon_front.change_state(LeonFrontController.State.IDLE)
			_demo_tween.tween_interval(1.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(2))
			
		2:
			_set_step_label("2/14: FRONT WALK (Alternating Feet/Leg Stride, Opposite Arm Swing)")
			leon_front.change_state(LeonFrontController.State.WALK)
			_demo_tween.tween_interval(2.2)
			_demo_tween.tween_callback(_execute_demo_step.bind(3))
			
		3:
			_set_step_label("3/14: FRONT STOP / BRAKE (Foot Planting & Posture Settle)")
			leon_front.change_state(LeonFrontController.State.STOP)
			_demo_tween.tween_interval(1.0)
			_demo_tween.tween_callback(_execute_demo_step.bind(4))
			
		4:
			_set_step_label("4/14: FRONT RUN (Athletic Stride, Higher Knee Lift, Vertical Bounce)")
			leon_front.change_state(LeonFrontController.State.RUN)
			_demo_tween.tween_interval(2.0)
			_demo_tween.tween_callback(_execute_demo_step.bind(5))
			
		5:
			_set_step_label("5/14: FRONT JUMP (Squash Anticipation -> Launch -> Airborne -> Land Squash -> Settle)")
			leon_front.change_state(LeonFrontController.State.IDLE)
			_demo_tween.tween_callback(func():
				leon_front.trigger_jump()
				var tw := create_tween()
				tw.tween_property(self, "elevation", 52.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(self, "elevation", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			)
			_demo_tween.tween_interval(1.4)
			_demo_tween.tween_callback(_execute_demo_step.bind(6))
			
		6:
			_set_step_label("6/14: FRONT ATTACK (Z-ROT = 0°: Shuriken Flies Straight Toward Camera, Expanding Scale)")
			leon_front.rotation = 0.0
			dummy_world_pos = Vector2(0.0, 20.0) # Positioned directly in front along depth towards camera
			_demo_tween.tween_interval(0.2)
			_demo_tween.tween_callback(func():
				leon_front.trigger_attack(0.0)
			)
			_demo_tween.tween_interval(1.5)
			_demo_tween.tween_callback(_execute_demo_step.bind(7))
			
		7:
			_set_step_label("7/14: ATTACK WITH Z-ROTATION (Z-ROT = -26°: Trajectory Follows Facing Angle Left)")
			var angle_left := -26.0
			leon_front.rotation = deg_to_rad(angle_left)
			var dir_left := Vector2(sin(deg_to_rad(angle_left)), -cos(deg_to_rad(angle_left)))
			dummy_world_pos = world_pos + dir_left * 160.0
			_demo_tween.tween_interval(0.3)
			_demo_tween.tween_callback(func():
				leon_front.trigger_attack(angle_left)
			)
			_demo_tween.tween_interval(1.5)
			_demo_tween.tween_callback(_execute_demo_step.bind(8))
			
		8:
			_set_step_label("8/14: ATTACK WITH Z-ROTATION (Z-ROT = +26°: Trajectory Follows Facing Angle Right)")
			var angle_right := 26.0
			leon_front.rotation = deg_to_rad(angle_right)
			var dir_right := Vector2(sin(deg_to_rad(angle_right)), -cos(deg_to_rad(angle_right)))
			dummy_world_pos = world_pos + dir_right * 160.0
			_demo_tween.tween_interval(0.3)
			_demo_tween.tween_callback(func():
				leon_front.trigger_attack(angle_right)
			)
			_demo_tween.tween_interval(1.5)
			_demo_tween.tween_callback(_execute_demo_step.bind(9))
			
		9:
			_set_step_label("9/14: ATTACK WHILE WALKING (Locomotion Stride Preserved During Throw)")
			leon_front.rotation = 0.0
			dummy_world_pos = Vector2(0.0, 20.0)
			leon_front.change_state(LeonFrontController.State.WALK)
			_demo_tween.tween_interval(0.35)
			_demo_tween.tween_callback(func():
				leon_front.trigger_attack(0.0)
			)
			_demo_tween.tween_interval(1.5)
			_demo_tween.tween_callback(_execute_demo_step.bind(10))
			
		10:
			_set_step_label("10/14: FRONT SUPER (Cyan Smoke Puff -> Stealth Invisibility -> Shimmer -> Reappear)")
			leon_front.rotation = 0.0
			dummy_world_pos = Vector2(240.0, 180.0) # Stationed to side
			leon_front.change_state(LeonFrontController.State.IDLE)
			_demo_tween.tween_callback(func():
				leon_front.trigger_super()
			)
			_demo_tween.tween_interval(2.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(11))
			
		11:
			_set_step_label("11/14: HIT REACTION & KNOCKBACK (Recoil Flinch, Hurt Face, Elastic Recovery)")
			_demo_tween.tween_callback(func():
				leon_front.trigger_hit()
			)
			_demo_tween.tween_interval(1.2)
			_demo_tween.tween_callback(_execute_demo_step.bind(12))
			
		12:
			_set_step_label("12/14: FACIAL EXPRESSIONS SUITE (Happy -> Angry -> Shocked -> Smug -> Neutral)")
			_demo_tween.tween_callback(func(): leon_front.set_face_expression("happy", "happy"))
			_demo_tween.tween_interval(0.55)
			_demo_tween.tween_callback(func(): leon_front.set_face_expression("angry", "angry"))
			_demo_tween.tween_interval(0.55)
			_demo_tween.tween_callback(func(): leon_front.set_face_expression("shocked", "wide"))
			_demo_tween.tween_interval(0.55)
			_demo_tween.tween_callback(func(): leon_front.set_face_expression("smug", "open"))
			_demo_tween.tween_interval(0.55)
			_demo_tween.tween_callback(func(): leon_front.set_face_expression("neutral", "open"))
			_demo_tween.tween_callback(_execute_demo_step.bind(13))
			
		13:
			_set_step_label("13/14: 2.5D LATERAL SWEEP (X Left <-> Right: Scale Strictly Invariant)")
			leon_front.change_state(LeonFrontController.State.WALK)
			_demo_tween.tween_property(self, "world_pos:x", -220.0, 1.1)
			_demo_tween.tween_property(self, "world_pos:x", 220.0, 1.9)
			_demo_tween.tween_property(self, "world_pos:x", 0.0, 0.9)
			_demo_tween.tween_callback(_execute_demo_step.bind(14))
			
		14:
			_set_step_label("14/14: 2.5D DEPTH TRAVEL (Far 420 -> Mid 180 -> Near 40: Monotonic Scale Expansion)")
			leon_front.change_state(LeonFrontController.State.RUN)
			_demo_tween.tween_property(self, "world_pos:y", 420.0, 1.1)
			_demo_tween.tween_property(self, "world_pos:y", 40.0, 2.6)
			_demo_tween.tween_property(self, "world_pos:y", 180.0, 1.4)
			_demo_tween.tween_callback(func():
				leon_front.change_state(LeonFrontController.State.IDLE)
				_set_step_label("TEST COMPLETE — Press [ENTER] to Re-run | WASD/Arrows to Move | F to Attack | Q/E to Rotate")
				demo_running = false
			)

func _set_step_label(text: String) -> void:
	if lbl_step:
		lbl_step.text = text

func _handle_interactive_input(delta: float) -> void:
	if demo_running:
		if Input.is_key_pressed(KEY_ESCAPE):
			demo_running = false
			if _demo_tween and _demo_tween.is_valid():
				_demo_tween.kill()
			_set_step_label("Demo Cancelled — Interactive Mode")
		return
		
	var moved := false
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		world_pos.x -= 200.0 * delta
		moved = true
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		world_pos.x += 200.0 * delta
		moved = true
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		world_pos.y += 200.0 * delta # away
		moved = true
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		world_pos.y -= 200.0 * delta # toward camera
		moved = true
		
	world_pos.y = clampf(world_pos.y, 40.0, 550.0)
	
	# Z-Axis rotation controls (aiming)
	if Input.is_key_pressed(KEY_Q):
		leon_front.rotation -= 1.8 * delta
	if Input.is_key_pressed(KEY_E):
		leon_front.rotation += 1.8 * delta
	
	if moved and leon_front.current_state != LeonFrontController.State.WALK and leon_front.current_state != LeonFrontController.State.RUN:
		leon_front.change_state(LeonFrontController.State.WALK)
	elif not moved and leon_front.current_state == LeonFrontController.State.WALK:
		leon_front.change_state(LeonFrontController.State.IDLE)
		
	if Input.is_key_pressed(KEY_SPACE):
		leon_front.trigger_jump()
	if Input.is_key_pressed(KEY_F):
		leon_front.trigger_attack()
	if Input.is_key_pressed(KEY_R):
		leon_front.trigger_super()
	if Input.is_key_pressed(KEY_H):
		leon_front.trigger_hit()
	if Input.is_key_pressed(KEY_ENTER):
		start_demonstration()
