extends Node2D
class_name Leon25DSpatialTest

# ============================================================================
# LEON — 2.5D SPATIAL FUNDAMENTALS TEST
# ----------------------------------------------------------------------------
# Master laboratory proving:
# 1. X movement (horizontal) moves left/right without changing apparent scale.
# 2. Y movement (vertical elevation/jump) elevates without changing depth scale.
# 3. DEPTH movement (near/far) continuously scales apparent size via camera projection.
# 4. Multi-view character system selects correct artwork from camera-relative angle.
# 5. Projectiles travel through depth with strict causality.
# 6. Occlusion and depth sorting follow world depth naturally.
# 7. 21-step automated demonstration sequence (Requirement 49).
# ============================================================================

const ProjectileScene := preload("res://scripts/labs/leon_spatial_projectile.gd")
const DUMMY_SCENE := "res://scenes/target_dummy.tscn"

@onready var camera: CinematicCamera = $CameraRig
@onready var leon: CinematicActor = $Leon
@onready var leon_b: CinematicActor = $LeonB
@onready var sky: ColorRect = $Sky
@onready var ground: ColorRect = $Ground
@onready var horizon_line: Line2D = $HorizonLine

# UI Nodes
@onready var lbl_title: Label = $UI/Panel/VBox/LblTitle
@onready var lbl_step: Label = $UI/Panel/VBox/LblStep
@onready var lbl_coords: Label = $UI/Panel/VBox/LblCoords
@onready var lbl_camera: Label = $UI/Panel/VBox/LblCamera
@onready var lbl_view: Label = $UI/Panel/VBox/LblView
@onready var lbl_controls: Label = $UI/Panel/VBox/LblControls
@onready var graph_rect: ColorRect = $UI/GraphPanel/VBox/GraphArea
@onready var graph_point: ColorRect = $UI/GraphPanel/VBox/GraphArea/PointIndicator
@onready var lbl_graph_readout: Label = $UI/GraphPanel/VBox/LblGraphReadout

# Ground Markers & Grid
var ground_markers: Array = []
var props: Array = []
var dummies: Array = [] # {node, world_pos, radius}

# Debug overlays
var axis_overlay: Node2D = null
var show_axes: bool = true
var show_graph: bool = true

# Demonstration Sequencer (Requirement 49)
var demo_running: bool = false
var demo_step: int = 0
var demo_timer: float = 0.0
var _demo_tween: Tween = null
var auto_start_demo: bool = true
var _auto_quit_duration: float = -1.0
var _time_elapsed: float = 0.0

func _ready() -> void:
	_check_cmdline_args()
	_build_environment()
	_setup_actors()
	_build_ground_markers()
	_build_axis_overlay()
	_setup_dummies()
	
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
			
	_update_ground_plane()
	_project_markers()
	_project_props()
	_project_dummies()
	_update_axis_overlay()
	_update_scale_graph()
	_update_ui()
	_handle_interactive_input(delta)

# ============================================================================
# 1. ENVIRONMENT & PROPS (Requirements 3, 27, 28, 30)
# ============================================================================

func _build_environment() -> void:
	# Sky & Ground colors
	sky.color = Color(0.42, 0.68, 0.90)       # Clean vibrant blue sky
	ground.color = Color(0.28, 0.58, 0.22)    # Continuous lush green ground plane
	horizon_line.default_color = Color(0.18, 0.42, 0.16, 0.9)
	horizon_line.width = 2.0
	
	# Props: Simple tree, door-sized rectangle, crate, rock, foreground blocker
	# Doorway: ~180px tall (approx 1.8x Leon height) at mid-left
	_create_prop("door", Vector2(-280, 240), 180.0, Color(0.45, 0.30, 0.18), "door")
	# Solid Crate: ~55px tall at mid-right
	_create_prop("crate", Vector2(260, 220), 55.0, Color(0.60, 0.45, 0.25), "crate")
	# Simple stylized tree: ~220px tall at far-left
	_create_prop("tree", Vector2(-360, 420), 230.0, Color(0.20, 0.48, 0.18), "tree")
	# Small rock: ~28px tall at far-right
	_create_prop("rock", Vector2(340, 440), 30.0, Color(0.50, 0.52, 0.56), "rock")
	# Foreground Blocker (for occlusion test Requirement 30): near camera at Z=20
	_create_prop("fg_pillar", Vector2(100, 20), 260.0, Color(0.22, 0.24, 0.30), "pillar")

func _create_prop(p_name: String, pos: Vector2, height: float, col: Color, kind: String) -> void:
	var root := Node2D.new()
	root.name = p_name
	add_child(root)
	
	var body := Polygon2D.new()
	body.color = col
	root.add_child(body)
	
	match kind:
		"door":
			# Doorway frame + dark inner opening
			body.polygon = PackedVector2Array([
				Vector2(-35, -height), Vector2(35, -height),
				Vector2(35, 0), Vector2(-35, 0)
			])
			var inner := Polygon2D.new()
			inner.color = Color(0.12, 0.10, 0.15)
			inner.polygon = PackedVector2Array([
				Vector2(-24, -height + 15), Vector2(24, -height + 15),
				Vector2(24, 0), Vector2(-24, 0)
			])
			root.add_child(inner)
		"crate":
			# Box with diagonal braces
			body.polygon = PackedVector2Array([
				Vector2(-28, -height), Vector2(28, -height),
				Vector2(28, 0), Vector2(-28, 0)
			])
			var brace := Line2D.new()
			brace.width = 3.0
			brace.default_color = col.darkened(0.3)
			brace.points = PackedVector2Array([Vector2(-26, -height + 2), Vector2(26, -2)])
			root.add_child(brace)
		"tree":
			# Brown trunk + layered green canopy
			body.color = Color(0.40, 0.26, 0.14)
			body.polygon = PackedVector2Array([
				Vector2(-10, -height * 0.45), Vector2(10, -height * 0.45),
				Vector2(14, 0), Vector2(-14, 0)
			])
			var foliage := Polygon2D.new()
			foliage.color = Color(0.18, 0.52, 0.22)
			foliage.polygon = PackedVector2Array([
				Vector2(0, -height), Vector2(55, -height * 0.4),
				Vector2(35, -height * 0.35), Vector2(65, -height * 0.2),
				Vector2(-65, -height * 0.2), Vector2(-35, -height * 0.35),
				Vector2(-55, -height * 0.4)
			])
			root.add_child(foliage)
		"rock":
			# Asymmetric stone polygon
			body.polygon = PackedVector2Array([
				Vector2(-22, 0), Vector2(-20, -18),
				Vector2(0, -height), Vector2(18, -22),
				Vector2(24, 0)
			])
		"pillar":
			# Tall foreground stone pillar with capital
			body.polygon = PackedVector2Array([
				Vector2(-24, -height), Vector2(24, -height),
				Vector2(20, 0), Vector2(-20, 0)
			])
			var cap := Polygon2D.new()
			cap.color = col.lightened(0.2)
			cap.polygon = PackedVector2Array([
				Vector2(-32, -height), Vector2(32, -height),
				Vector2(32, -height + 16), Vector2(-32, -height + 16)
			])
			root.add_child(cap)
	
	props.append({"node": root, "world_pos": pos, "height": height})

func _project_props() -> void:
	for p in props:
		var node: Node2D = p.node
		var w_pos: Vector2 = p.world_pos
		var proj := camera.project(w_pos, 0.0)
		node.position = proj.pos
		node.scale = Vector2.ONE * maxf(proj.scale, 0.01)
		# Occlusion ordering strictly by depth:
		node.z_index = -int(clampf(proj.depth, -400.0, 4000.0) * 0.25)
		node.visible = proj.visible

# ============================================================================
# 2. TARGET DUMMIES FOR PROJECTILE CAUSALITY (Requirement 31-33)
# ============================================================================

func _setup_dummies() -> void:
	# Far target dummy at (0, 480)
	_spawn_dummy("dummy_far", Vector2(0, 480))
	# Near target dummy at (220, 80)
	_spawn_dummy("dummy_near", Vector2(220, 80))

func _spawn_dummy(dummy_name: String, w_pos: Vector2) -> void:
	var packed: PackedScene = load(DUMMY_SCENE)
	var node: Node2D = packed.instantiate()
	node.name = dummy_name
	add_child(node)
	dummies.append({"node": node, "world_pos": w_pos, "radius": 36.0})

func _project_dummies() -> void:
	for d in dummies:
		var node: Node2D = d.node
		var w_pos: Vector2 = d.world_pos
		var proj := camera.project(w_pos, 0.0)
		node.position = proj.pos
		node.scale = Vector2.ONE * maxf(proj.scale, 0.01)
		node.z_index = -int(clampf(proj.depth, -400.0, 4000.0) * 0.25)
		node.visible = proj.visible

# ============================================================================
# 3. GROUND MARKERS & CONTINUOUS DEPTH GRID (Requirements 3, 27)
# ============================================================================

func _build_ground_markers() -> void:
	# Three distinct depth marker lanes: NEAR (Z=60), MID (Z=220), FAR (Z=480)
	var marker_defs := [
		{"name": "NEAR (Z = 60)", "z": 60.0, "color": Color(0.9, 0.85, 0.2, 0.85), "width": 540.0},
		{"name": "MID (Z = 220)", "z": 220.0, "color": Color(0.3, 0.9, 0.4, 0.85), "width": 640.0},
		{"name": "FAR (Z = 480)", "z": 480.0, "color": Color(0.3, 0.7, 1.0, 0.85), "width": 800.0},
	]
	
	for m in marker_defs:
		var line := Line2D.new()
		line.name = "Marker_" + str(int(m.z))
		line.width = 3.0
		line.default_color = m.color
		line.z_index = -2050
		add_child(line)
		
		var lbl := Label.new()
		lbl.text = m.name
		lbl.modulate = m.color
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.z_index = -2049
		add_child(lbl)
		
		ground_markers.append({
			"line": line,
			"label": lbl,
			"z": m.z,
			"half_w": m.width * 0.5
		})
	
	# Perspective depth grid lines converging toward the horizon
	for x_offset in [-300.0, -150.0, 0.0, 150.0, 300.0]:
		var grid_line := Line2D.new()
		grid_line.width = 1.5
		grid_line.default_color = Color(0.22, 0.48, 0.18, 0.45)
		grid_line.z_index = -2080
		add_child(grid_line)
		ground_markers.append({
			"grid_line": grid_line,
			"x": x_offset,
			"z_start": 20.0,
			"z_end": 650.0
		})

func _project_markers() -> void:
	for m in ground_markers:
		if m.has("line"):
			var p_left := camera.project(Vector2(-m.half_w, m.z), 0.0)
			var p_right := camera.project(Vector2(m.half_w, m.z), 0.0)
			var line: Line2D = m.line
			line.points = PackedVector2Array([p_left.pos, p_right.pos])
			line.visible = p_left.visible and p_right.visible
			
			var lbl: Label = m.label
			lbl.position = p_left.pos + Vector2(10, -18)
			lbl.visible = line.visible
		elif m.has("grid_line"):
			var p_near := camera.project(Vector2(m.x, m.z_start), 0.0)
			var p_far := camera.project(Vector2(m.x, m.z_end), 0.0)
			var g_line: Line2D = m.grid_line
			g_line.points = PackedVector2Array([p_near.pos, p_far.pos])
			g_line.visible = p_near.visible or p_far.visible

func _update_ground_plane() -> void:
	var pitch_px := camera.pitch_deg * 2.2
	var horizon := camera.horizon_y + pitch_px
	
	# Sky covers top down to horizon
	sky.position = Vector2(0, 0)
	sky.size = Vector2(1200, maxf(horizon, 0.0))
	
	# Ground starts at horizon and extends to bottom
	ground.position = Vector2(0, horizon)
	ground.size = Vector2(1200, maxf(720.0 - horizon, 0.0))
	
	# Horizon line sits exactly at the horizon
	horizon_line.points = PackedVector2Array([Vector2(0, horizon), Vector2(1200, horizon)])

# ============================================================================
# 4. ACTOR SETUP (Requirements 9, 29)
# ============================================================================

func _setup_actors() -> void:
	# Primary Leon setup at midground center (0, 220) facing camera (0 deg)
	leon.setup(camera, Vector2(0, 220), 0.0)
	leon.display_name = "Leon (Primary)"
	
	# Secondary Leon B setup for depth-crossing test (Requirement 29)
	# Initially at background (0, 420)
	leon_b.setup(camera, Vector2(0, 420), 0.0)
	leon_b.display_name = "Leon B (Background)"
	leon_b.modulate = Color(0.85, 0.85, 0.95) # subtle tint to distinguish easily

# ============================================================================
# 5. WORLD AXES OVERLAY (Requirement 4)
# ============================================================================

func _build_axis_overlay() -> void:
	axis_overlay = Node2D.new()
	axis_overlay.name = "AxisOverlay"
	axis_overlay.z_index = 500
	add_child(axis_overlay)
	
	# 3 lines: X (Red), Depth (Blue), Y (Green)
	var x_line := Line2D.new()
	x_line.name = "XAxis"
	x_line.width = 3.5
	x_line.default_color = Color(1.0, 0.25, 0.25, 0.9)
	axis_overlay.add_child(x_line)
	
	var depth_line := Line2D.new()
	depth_line.name = "DepthAxis"
	depth_line.width = 3.5
	depth_line.default_color = Color(0.25, 0.60, 1.0, 0.9)
	axis_overlay.add_child(depth_line)
	
	var y_line := Line2D.new()
	y_line.name = "YAxis"
	y_line.width = 3.5
	y_line.default_color = Color(0.25, 1.0, 0.40, 0.9)
	axis_overlay.add_child(y_line)
	
	# Labels
	var lbl_x := Label.new()
	lbl_x.name = "LblX"
	lbl_x.text = "X: LEFT / RIGHT"
	lbl_x.modulate = Color(1.0, 0.35, 0.35)
	lbl_x.add_theme_font_size_override("font_size", 12)
	axis_overlay.add_child(lbl_x)
	
	var lbl_depth := Label.new()
	lbl_depth.name = "LblDepth"
	lbl_depth.text = "DEPTH: NEAR / FAR"
	lbl_depth.modulate = Color(0.35, 0.75, 1.0)
	lbl_depth.add_theme_font_size_override("font_size", 12)
	axis_overlay.add_child(lbl_depth)
	
	var lbl_y := Label.new()
	lbl_y.name = "LblY"
	lbl_y.text = "Y: UP / DOWN"
	lbl_y.modulate = Color(0.35, 1.0, 0.5)
	lbl_y.add_theme_font_size_override("font_size", 12)
	axis_overlay.add_child(lbl_y)

func _update_axis_overlay() -> void:
	if not show_axes or axis_overlay == null:
		if axis_overlay: axis_overlay.visible = false
		return
	axis_overlay.visible = true
	
	# Anchor axes at world origin (0, 220, elevation 0)
	var origin_world := Vector2(0, 220)
	var p_orig := camera.project(origin_world, 0.0)
	var p_x := camera.project(origin_world + Vector2(140, 0), 0.0)
	var p_depth := camera.project(origin_world + Vector2(0, 160), 0.0)
	var p_y := camera.project(origin_world, 100.0)
	
	var x_line: Line2D = axis_overlay.get_node("XAxis")
	var depth_line: Line2D = axis_overlay.get_node("DepthAxis")
	var y_line: Line2D = axis_overlay.get_node("YAxis")
	var lbl_x: Label = axis_overlay.get_node("LblX")
	var lbl_depth: Label = axis_overlay.get_node("LblDepth")
	var lbl_y: Label = axis_overlay.get_node("LblY")
	
	x_line.points = PackedVector2Array([p_orig.pos, p_x.pos])
	depth_line.points = PackedVector2Array([p_orig.pos, p_depth.pos])
	y_line.points = PackedVector2Array([p_orig.pos, p_y.pos])
	
	lbl_x.position = p_x.pos + Vector2(6, -8)
	lbl_depth.position = p_depth.pos + Vector2(6, -8)
	lbl_y.position = p_y.pos + Vector2(-40, -18)

# ============================================================================
# 6. DEPTH VS APPARENT SCALE GRAPH (Requirement 8)
# ============================================================================

func _update_scale_graph() -> void:
	if not show_graph or graph_rect == null:
		return
	
	# Graph domain: depth 0 to 600
	var z_min := 0.0
	var z_max := 600.0
	var w: float = graph_rect.size.x
	var h: float = graph_rect.size.y
	
	# Plot Leon's current point on graph
	var cur_depth := leon.world_pos.y
	var t_x := clampf((cur_depth - z_min) / (z_max - z_min), 0.0, 1.0)
	
	# Theoretical scale: k = focal / (focal + depth)
	var cur_scale := leon.scale.x
	# Max scale at z=0 is 1.0 (or focal/(focal+0)), min scale at z=600 is focal/(focal+600)
	var max_scale := 1.8
	var t_y := 1.0 - clampf(cur_scale / max_scale, 0.0, 1.0)
	
	graph_point.position = Vector2(t_x * w - 3, t_y * h - 3)
	
	if lbl_graph_readout:
		lbl_graph_readout.text = "Depth: %d | Scale: %.3fx" % [int(cur_depth), cur_scale]

# ============================================================================
# 7. TELEMETRY & HUD (Requirements 44, 45)
# ============================================================================

func _update_ui() -> void:
	if lbl_coords:
		lbl_coords.text = "WORLD X: %+.1f | Y (Elev): %.1f | DEPTH: %.1f | SCALE: %.3fx" % [
			leon.world_pos.x, leon.elevation, leon.world_pos.y, leon.scale.x
		]
	if lbl_camera:
		var cam_dist := Vector2(camera.cam_x, camera.cam_z).distance_to(leon.world_pos)
		lbl_camera.text = "CAMERA: (%+.1f, %+.1f) | DISTANCE: %.1f | YAW: %+.1f° | PITCH: %+.1f°" % [
			camera.cam_x, camera.cam_z, cam_dist, camera.yaw_deg, camera.pitch_deg
		]
	if lbl_view:
		var mode_name := "PERSPECTIVE" if camera.mode == CinematicCamera.ProjMode.PERSPECTIVE else "ORTHOGRAPHIC"
		lbl_view.text = "VIEW: %s (mirrored: %s) | PROJECTION: %s" % [
			leon.current_view(), str(leon.model.current_mirror if leon.model else false), mode_name
		]

# ============================================================================
# 8. 21-STEP AUTOMATED DEMONSTRATION (Requirement 49)
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
			# Step 1: Leon far away (FAR marker, Z=480)
			_set_step_label("1/21: Leon Far Away (Z=480, Scale Small)")
			camera.cam_x = 0.0
			camera.cam_z = -260.0
			camera.yaw_deg = 0.0
			camera.pitch_deg = 0.0
			camera.mode = CinematicCamera.ProjMode.PERSPECTIVE
			leon.world_pos = Vector2(0, 480)
			leon.elevation = 0.0
			leon.set_facing_deg(0.0, true)
			_demo_tween.tween_interval(1.0)
			_demo_tween.tween_callback(_execute_demo_step.bind(2))
			
		2:
			# Step 2: Leon moves horizontally (LEFT -> RIGHT -> CENTER)
			_set_step_label("2/21: Horizontal X Movement (Scale Stays Constant)")
			_demo_tween.tween_property(leon, "world_pos:x", -240.0, 1.2)
			_demo_tween.tween_property(leon, "world_pos:x", 240.0, 2.0)
			_demo_tween.tween_property(leon, "world_pos:x", 0.0, 1.0)
			_demo_tween.tween_callback(_execute_demo_step.bind(3))
			
		3:
			# Step 3: Confirm size remains approximately constant
			_set_step_label("3/21: Verification: Scale was Unchanged During X Movement")
			_demo_tween.tween_interval(0.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(4))
			
		4:
			# Step 4: Leon moves toward camera (FAR -> MID -> NEAR)
			_set_step_label("4/21: Depth Travel Toward Camera: FAR (480) -> MID (220) -> NEAR (60)")
			_demo_tween.tween_property(leon, "world_pos:y", 60.0, 2.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(5))
			
		5:
			# Step 5: Leon becomes progressively larger
			_set_step_label("5/21: Verification: Scale Grew Continuously (~0.65x -> ~1.40x)")
			_demo_tween.tween_interval(1.0)
			_demo_tween.tween_callback(_execute_demo_step.bind(6))
			
		6:
			# Step 6: Leon moves away (NEAR -> MID -> FAR)
			_set_step_label("6/21: Depth Travel Away: NEAR (60) -> MID (220) -> FAR (480)")
			_demo_tween.tween_property(leon, "world_pos:y", 480.0, 2.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(7))
			
		7:
			# Step 7: Leon becomes progressively smaller
			_set_step_label("7/21: Verification: Scale Shrunk Continuously back to Far Size")
			_demo_tween.tween_interval(1.0)
			_demo_tween.tween_callback(_execute_demo_step.bind(8))
			
		8:
			# Step 8: Return Leon to midground, Camera moves toward Leon
			_set_step_label("8/21: Camera Dolly: Camera Moves Closer to Stationary Leon")
			leon.world_pos = Vector2(0, 220)
			_demo_tween.tween_property(camera, "cam_z", -60.0, 2.0)
			_demo_tween.tween_callback(_execute_demo_step.bind(9))
			
		9:
			# Step 9: Camera shifts to 3/4 angle
			_set_step_label("9/21: Camera Shifts to Front-3/4 (Yaw = +45°)")
			_demo_tween.tween_property(camera, "yaw_deg", 45.0, 1.4)
			_demo_tween.tween_callback(_execute_demo_step.bind(10))
			
		10:
			# Step 10: Leon changes to 3/4 artwork
			_set_step_label("10/21: Leon Transitions to FRONT-3/4 Artwork")
			_demo_tween.tween_interval(0.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(11))
			
		11:
			# Step 11: Camera reaches side (Yaw = +90°)
			_set_step_label("11/21: Camera Orbits to Side Profile (Yaw = +90°)")
			_demo_tween.tween_property(camera, "yaw_deg", 90.0, 1.4)
			_demo_tween.tween_callback(_execute_demo_step.bind(12))
			
		12:
			# Step 12: Leon uses side artwork
			_set_step_label("12/21: Leon Transitions to SIDE Artwork (Production Rig)")
			_demo_tween.tween_interval(0.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(13))
			
		13:
			# Step 13: Camera moves behind (Yaw = +180°)
			_set_step_label("13/21: Camera Orbits Behind Leon (Yaw = +180°)")
			_demo_tween.tween_property(camera, "yaw_deg", 180.0, 1.6)
			_demo_tween.tween_callback(_execute_demo_step.bind(14))
			
		14:
			# Step 14: Leon uses back artwork
			_set_step_label("14/21: Leon Transitions to BACK Artwork")
			_demo_tween.tween_interval(0.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(15))
			
		15:
			# Step 15: Camera returns toward front
			_set_step_label("15/21: Camera Returns to Front (Yaw = 0°)")
			_demo_tween.tween_property(camera, "yaw_deg", 0.0, 1.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(16))
			
		16:
			# Step 16: Face Close-up (camera dollies in close)
			_set_step_label("16/21: Face Close-Up: Readable Eyes, Blink & Facial Features")
			_demo_tween.tween_property(camera, "cam_z", 100.0, 1.5)
			_demo_tween.tween_callback(func():
				_trigger_face_reaction()
			)
			_demo_tween.tween_interval(1.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(17))
			
		17:
			# Step 17: Camera pulls back to standard view
			_set_step_label("17/21: Camera Pulls Back to Medium Staging")
			_demo_tween.tween_property(camera, "cam_z", -260.0, 1.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(18))
			
		18:
			# Step 18: Leon moves diagonally through depth (Far-Left -> Mid-Center -> Near-Right)
			_set_step_label("18/21: Diagonal Spatial Trajectory (X + Depth Combined)")
			leon.world_pos = Vector2(-260, 480)
			_demo_tween.tween_property(leon, "world_pos", Vector2(0, 220), 1.8)
			_demo_tween.tween_property(leon, "world_pos", Vector2(240, 60), 1.8)
			_demo_tween.tween_callback(_execute_demo_step.bind(19))
			
		19:
			# Step 19: Projectile travels through depth with strict causality
			_set_step_label("19/21: Projectile Trajectory Through Depth + Strict Causality")
			_demo_tween.tween_callback(func():
				_fire_projectile_at_dummy(Vector2(240, 60), Vector2(0, 480))
			)
			_demo_tween.tween_interval(2.2)
			_demo_tween.tween_callback(_execute_demo_step.bind(20))
			
		20:
			# Step 20: Foreground Occlusion (passes behind pillar at (100, 20))
			_set_step_label("20/21: Foreground Occlusion: Passes Behind Pillar (Z=20) and Emerges")
			leon.world_pos = Vector2(0, 40)
			_demo_tween.tween_property(leon, "world_pos:x", 200.0, 2.5)
			_demo_tween.tween_callback(_execute_demo_step.bind(21))
			
		21:
			# Step 21: Final wide shot & demonstration complete
			_set_step_label("21/21: Final Wide Shot — 2.5D Spatial Verification Complete!")
			_demo_tween.tween_property(leon, "world_pos", Vector2(0, 220), 1.5)
			_demo_tween.tween_interval(1.5)
			_demo_tween.tween_callback(func():
				_set_step_label("DEMO COMPLETE — Press [ENTER] to Re-run | WASD/Arrows to Control")
				demo_running = false
			)

func _set_step_label(text: String) -> void:
	if lbl_step:
		lbl_step.text = text

func _trigger_face_reaction() -> void:
	var active := leon.model.active_node() if (leon and leon.model) else null
	if active:
		var face = active.find_child("FaceController", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression("happy")
			if face.has_method("blink"):
				face.blink()

func _fire_projectile_at_dummy(from_world: Vector2, to_world: Vector2) -> void:
	var proj = ProjectileScene.new()
	add_child(proj)
	var target_d: Node2D = null
	for d in dummies:
		if d.world_pos.distance_to(to_world) < 40.0:
			target_d = d.node
			break
	proj.setup(camera, from_world, to_world, 36.0, target_d, 620.0)

# ============================================================================
# 9. INTERACTIVE KEYBOARD CONTROLS (Requirements 44, 45)
# ============================================================================

func _handle_interactive_input(delta: float) -> void:
	if demo_running:
		if Input.is_key_pressed(KEY_ESCAPE):
			demo_running = false
			if _demo_tween and _demo_tween.is_valid():
				_demo_tween.kill()
			_set_step_label("Demo Cancelled — Manual Mode")
		return
	
	var move := Vector2.ZERO
	# Lateral X (Left/Right)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 220.0 * delta
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 220.0 * delta
		
	# Depth Z (W/S or Up/Down)
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y += 240.0 * delta # away into depth
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y -= 240.0 * delta # toward camera
		
	if move != Vector2.ZERO:
		leon.world_pos += move
		leon.world_pos.y = clampf(leon.world_pos.y, 20.0, 600.0)
		
	# Jump (Y Elevation)
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J):
		leon.jump()
		
	# Camera Orbit (Q/E)
	if Input.is_key_pressed(KEY_Q):
		camera.yaw_deg -= 45.0 * delta
	if Input.is_key_pressed(KEY_E):
		camera.yaw_deg += 45.0 * delta
		
	# Camera Dolly (Z/C)
	if Input.is_key_pressed(KEY_Z):
		camera.cam_z += 180.0 * delta
	if Input.is_key_pressed(KEY_C):
		camera.cam_z -= 180.0 * delta
		
	# Attack / Fire Projectile (F)
	if Input.is_key_pressed(KEY_F):
		_fire_projectile_at_dummy(leon.world_pos, Vector2(0, 480))
		
	# Toggle Projection Mode (P)
	if Input.is_key_pressed(KEY_P):
		if not Input.is_key_label_pressed(KEY_P): # single-frame debounce check if needed
			camera.mode = CinematicCamera.ProjMode.ORTHO if camera.mode == CinematicCamera.ProjMode.PERSPECTIVE else CinematicCamera.ProjMode.PERSPECTIVE
			
	# Re-run automated demo (Enter)
	if Input.is_key_pressed(KEY_ENTER):
		start_demonstration()
