class_name FaceControllerBase
extends Node2D

# Generic Facial Expression & Auto-Blink Controller
# Provides slot-based face management for 2D Brawlers (supports Sprite2D, Polygon2D, etc.)

signal expression_changed(new_expression: String)
signal eye_state_changed(new_state: String)

@export var auto_blink_enabled: bool = true
@export var default_expression: String = "neutral"
@export var default_eye_state: String = "open"

# Configurable Texture Dictionaries
var mouth_textures: Dictionary = {}
var eye_textures: Dictionary = {}

var current_expression: String = "neutral"
var current_eye_state: String = "open"

var is_blinking: bool = false
var blink_timer: float = 0.0
var next_blink_interval: float = 3.0
var blink_duration: float = 0.12
var blink_elapsed: float = 0.0

@onready var eye_l: CanvasItem = get_node_or_null("EyeL")
@onready var eye_r: CanvasItem = get_node_or_null("EyeR")
@onready var pupil_l: CanvasItem = get_node_or_null("EyeL/PupilL")
@onready var pupil_r: CanvasItem = get_node_or_null("EyeR/PupilR")
@onready var brow_l: CanvasItem = get_node_or_null("BrowL")
@onready var brow_r: CanvasItem = get_node_or_null("BrowR")
@onready var mouth: CanvasItem = get_node_or_null("Mouth")

func _ready() -> void:
	_ensure_nodes()
	set_expression(default_expression)
	set_eye_state(default_eye_state)
	next_blink_interval = randf_range(2.0, 4.0)

func _ensure_nodes() -> void:
	if not eye_l: eye_l = get_node_or_null("EyeL")
	if not eye_r: eye_r = get_node_or_null("EyeR")
	if not pupil_l: pupil_l = get_node_or_null("EyeL/PupilL")
	if not pupil_r: pupil_r = get_node_or_null("EyeR/PupilR")
	if not brow_l: brow_l = get_node_or_null("BrowL")
	if not brow_r: brow_r = get_node_or_null("BrowR")
	if not mouth: mouth = get_node_or_null("Mouth")

func _process(delta: float) -> void:
	if not auto_blink_enabled:
		return

	if is_blinking:
		blink_elapsed += delta
		if blink_elapsed >= blink_duration:
			_end_blink()
	else:
		blink_timer += delta
		if blink_timer >= next_blink_interval:
			_trigger_blink()

func _trigger_blink() -> void:
	if current_expression in ["hurt", "laughing"] or current_eye_state in ["closed", "blink"]:
		return
	is_blinking = true
	blink_elapsed = 0.0
	_apply_eye_state("blink")

func _end_blink() -> void:
	is_blinking = false
	blink_timer = 0.0
	next_blink_interval = randf_range(2.2, 4.5)
	_apply_eye_state(current_eye_state)

func set_expression(expr: String) -> void:
	_ensure_nodes()
	current_expression = expr
	if mouth and mouth_textures.has(expr):
		if mouth is Sprite2D:
			mouth.texture = mouth_textures[expr]
	expression_changed.emit(current_expression)

func set_eye_state(state: String) -> void:
	_ensure_nodes()
	current_eye_state = state
	if not is_blinking:
		_apply_eye_state(state)
	eye_state_changed.emit(current_eye_state)

func _apply_eye_state(state: String) -> void:
	if not eye_textures.has(state):
		return
	var tex = eye_textures[state]
	if eye_l and eye_l is Sprite2D:
		eye_l.texture = tex
	if eye_r and eye_r is Sprite2D:
		eye_r.texture = tex

	var hide_pupils = (state in ["blink", "closed"])
	if pupil_l: pupil_l.visible = not hide_pupils
	if pupil_r: pupil_r.visible = not hide_pupils
