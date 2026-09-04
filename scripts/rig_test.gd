extends Node2D

@onready var puppet: CharacterBody2D = $Puppet
@onready var face: FaceController = $Puppet.find_child("Face")
@onready var overlay: Node2D = $PivotOverlay

# Bone references
var bones: Dictionary = {}

var bone_names = [
	"root", "head", "neck", "torso",
	"arm_L_upper", "arm_L_lower", "hand_L",
	"arm_R_upper", "arm_R_lower", "hand_R",
	"leg_L_upper", "leg_L_lower", "foot_L",
	"leg_R_upper", "leg_R_lower", "foot_R",
	"tail"
]

var show_pivots: bool = true

func _ready() -> void:
	# Cache bones
	for b_name in bone_names:
		var b = puppet.find_child(b_name, true, false)
		if b and b is Bone2D:
			bones[b_name] = b
		else:
			print("[RIG_TEST] Bone not found: ", b_name)

	# Ensure face is ready
	if not face:
		face = puppet.find_child("Face")
	if face:
		face.set_expression("neutral")
		face.set_eye_state("open")

	# Stop puppet physics/process in rig test mode
	if puppet.has_method("set_physics_process"):
		puppet.set_physics_process(false)
		puppet.set_process(false)

	# Setup overlay
	if not overlay:
		overlay = Node2D.new()
		overlay.name = "PivotOverlay"
		overlay.z_index = 10
		overlay.set_script(load("res://scripts/pivot_overlay.gd"))
		add_child(overlay)
	else:
		overlay.z_index = 10
		if not overlay.get_script():
			overlay.set_script(load("res://scripts/pivot_overlay.gd"))

	for arg in OS.get_cmdline_user_args():
		if arg == "--auto-demo":
			auto_demo = true
	for arg in OS.get_cmdline_args():
		if arg == "--auto-demo":
			auto_demo = true

var auto_demo: bool = false
var demo_timer: float = 0.0
var demo_step: int = 0

func _process(delta: float) -> void:
	if not auto_demo:
		return
	demo_timer += delta
	if demo_timer >= 0.8:
		demo_timer = 0.0
		demo_step = (demo_step + 1) % 5
		match demo_step:
			0:
				reset_to_rest()
				apply_expression("neutral")
				apply_eye_state("open")
			1:
				apply_pose_elbows_knees()
				apply_expression("happy")
				apply_eye_state("open")
			2:
				apply_pose_cross_arms()
				apply_expression("smug")
				apply_eye_state("open")
			3:
				apply_pose_extreme_stress()
				apply_expression("shocked")
				apply_eye_state("wide")
			4:
				reset_to_rest()
				apply_expression("laughing")
				apply_eye_state("blink")

func toggle_auto_demo() -> void:
	auto_demo = not auto_demo
	demo_timer = 0.0
	demo_step = 0

func set_bone_angle(b_name: String, angle_degrees: float) -> void:
	if bones.has(b_name):
		var b: Bone2D = bones[b_name]
		b.rotation = deg_to_rad(angle_degrees)
		if overlay:
			overlay.queue_redraw()

func reset_to_rest() -> void:
	for b_name in bones.keys():
		var b: Bone2D = bones[b_name]
		b.rotation = 0.0
	if overlay:
		overlay.queue_redraw()

func apply_pose_elbows_knees() -> void:
	reset_to_rest()
	set_bone_angle("arm_L_upper", 30.0)
	set_bone_angle("arm_L_lower", 60.0)
	set_bone_angle("hand_L", 15.0)

	set_bone_angle("arm_R_upper", -30.0)
	set_bone_angle("arm_R_lower", 60.0)
	set_bone_angle("hand_R", -15.0)

	set_bone_angle("leg_L_upper", -25.0)
	set_bone_angle("leg_L_lower", 45.0)
	set_bone_angle("foot_L", -15.0)

	set_bone_angle("leg_R_upper", 25.0)
	set_bone_angle("leg_R_lower", 40.0)
	set_bone_angle("foot_R", 15.0)

	set_bone_angle("torso", -4.0)
	set_bone_angle("head", 5.0)

func apply_pose_cross_arms() -> void:
	reset_to_rest()
	set_bone_angle("arm_L_upper", 48.0)
	set_bone_angle("arm_L_lower", 75.0)
	set_bone_angle("hand_L", 25.0)

	set_bone_angle("arm_R_upper", -48.0)
	set_bone_angle("arm_R_lower", 75.0)
	set_bone_angle("hand_R", -25.0)

	set_bone_angle("torso", 6.0)
	set_bone_angle("head", -6.0)

func apply_pose_extreme_stress() -> void:
	reset_to_rest()
	set_bone_angle("head", 45.0)
	set_bone_angle("neck", 20.0)
	set_bone_angle("torso", -30.0)
	set_bone_angle("tail", 45.0)

	set_bone_angle("arm_L_upper", -75.0)
	set_bone_angle("arm_L_lower", 85.0)
	set_bone_angle("hand_L", 40.0)

	set_bone_angle("arm_R_upper", 85.0)
	set_bone_angle("arm_R_lower", 90.0)
	set_bone_angle("hand_R", -35.0)

	set_bone_angle("leg_L_upper", -55.0)
	set_bone_angle("leg_L_lower", 65.0)
	set_bone_angle("foot_L", -30.0)

	set_bone_angle("leg_R_upper", 50.0)
	set_bone_angle("leg_R_lower", 60.0)
	set_bone_angle("foot_R", 30.0)

func apply_expression(expr: String) -> void:
	if face and face.has_method("set_expression"):
		face.set_expression(expr)

func apply_eye_state(state_name: String) -> void:
	if face and face.has_method("set_eye_state"):
		face.set_eye_state(state_name)

func toggle_pivots() -> void:
	show_pivots = not show_pivots
	if overlay:
		overlay.queue_redraw()
