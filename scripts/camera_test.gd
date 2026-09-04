extends Node2D
class_name CameraTestController

@onready var leon: CharacterBody2D = get_node_or_null("Leon")
@onready var camera_2d: Camera2D = get_node_or_null("Camera2D")
@onready var pcam_host: PhantomCameraHost = get_node_or_null("Camera2D/PhantomCameraHost")

@onready var pcam_follow: PhantomCamera2D = get_node_or_null("PCamFollow")
@onready var pcam_wide: PhantomCamera2D = get_node_or_null("PCamWide")
@onready var pcam_closeup: PhantomCamera2D = get_node_or_null("PCamCloseUp")

@onready var ui_label: Label = get_node_or_null("UI/StatsLabel")

enum CamState { FOLLOW, WIDE, CLOSEUP }
var current_cam_state: CamState = CamState.FOLLOW

func _ready() -> void:
	if leon and pcam_follow:
		pcam_follow.follow_target = leon
	if leon and pcam_closeup:
		pcam_closeup.follow_target = leon

	set_camera_state(CamState.FOLLOW)
	_update_ui()

func set_camera_state(state: CamState) -> void:
	current_cam_state = state
	if not pcam_follow or not pcam_wide or not pcam_closeup:
		return

	match state:
		CamState.FOLLOW:
			pcam_follow.priority = 20
			pcam_wide.priority = 10
			pcam_closeup.priority = 10
		CamState.WIDE:
			pcam_follow.priority = 10
			pcam_wide.priority = 20
			pcam_closeup.priority = 10
		CamState.CLOSEUP:
			pcam_follow.priority = 10
			pcam_wide.priority = 10
			pcam_closeup.priority = 20

func cycle_camera() -> void:
	var next = (int(current_cam_state) + 1) % 3
	set_camera_state(next as CamState)

func _physics_process(delta: float) -> void:
	_handle_leon_input()
	_update_ui()

func _handle_leon_input() -> void:
	if not leon:
		return

	var move_x = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_x += 1.0

	leon.input_dir = move_x
	leon.wants_run = Input.is_key_pressed(KEY_SHIFT)

	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		leon.wants_jump = true
	if Input.is_key_pressed(KEY_J):
		leon.wants_attack = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_camera_state(CamState.FOLLOW)
			KEY_2:
				set_camera_state(CamState.WIDE)
			KEY_3:
				set_camera_state(CamState.CLOSEUP)
			KEY_C:
				cycle_camera()
			KEY_Z:
				_adjust_active_zoom(0.1)
			KEY_X:
				_adjust_active_zoom(-0.1)

func _adjust_active_zoom(amount: float) -> void:
	var active_pcam = get_active_pcam()
	if active_pcam:
		var new_zoom = active_pcam.zoom + Vector2(amount, amount)
		new_zoom.x = clampf(new_zoom.x, 0.4, 2.5)
		new_zoom.y = clampf(new_zoom.y, 0.4, 2.5)
		active_pcam.zoom = new_zoom

func get_active_pcam() -> PhantomCamera2D:
	match current_cam_state:
		CamState.FOLLOW: return pcam_follow
		CamState.WIDE: return pcam_wide
		CamState.CLOSEUP: return pcam_closeup
	return pcam_follow

func _update_ui() -> void:
	if not ui_label:
		return
	var cam_name = "Follow (1.0x Damped)"
	match current_cam_state:
		CamState.WIDE: cam_name = "Wide Overview (0.65x Fixed)"
		CamState.CLOSEUP: cam_name = "Close-up Action (1.6x Zoom)"

	var cam_pos = camera_2d.global_position if camera_2d else Vector2.ZERO
	var cam_zoom = camera_2d.zoom if camera_2d else Vector2.ONE
	var leon_pos = leon.global_position if leon else Vector2.ZERO

	ui_label.text = "PHANTOM CAMERA 2D DEMO\n" \
		+ "ACTIVE CAM: %s\n" % [cam_name] \
		+ "CAMERA POS: (%.1f, %.1f) | ZOOM: (%.2f, %.2f)\n" % [cam_pos.x, cam_pos.y, cam_zoom.x, cam_zoom.y] \
		+ "LEON POS: (%.1f, %.1f) | STATE: %s\n" % [leon_pos.x, leon_pos.y, leon.STATE_NAMES[leon.current_state] if leon else "N/A"] \
		+ "CONTROLS: [1] Follow Cam  [2] Wide Cam  [3] Close-up  [C] Cycle Cam  [Z/X] Zoom  |  A/D = Move, Shift = Run, Space = Jump, J = Attack"
