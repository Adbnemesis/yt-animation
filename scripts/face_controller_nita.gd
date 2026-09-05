@tool
extends Node2D
class_name FaceControllerNita

# Child node references
@onready var eye_l_sprite: Sprite2D = get_node_or_null("EyeL")
@onready var eye_r_sprite: Sprite2D = get_node_or_null("EyeR")
@onready var pupil_l_sprite: Sprite2D = get_node_or_null("EyeL/PupilL")
@onready var pupil_r_sprite: Sprite2D = get_node_or_null("EyeR/PupilR")
@onready var brow_l_sprite: Sprite2D = get_node_or_null("BrowL")
@onready var brow_r_sprite: Sprite2D = get_node_or_null("BrowR")
@onready var mouth_sprite: Sprite2D = get_node_or_null("Mouth")

# Nita Authentic Cut-Paper Textures
var mouth_textures := {
	"neutral": preload("res://assets/nita/face/mouth_neutral.svg"),
	"grin": preload("res://assets/nita/face/mouth_grin.svg"),
	"happy": preload("res://assets/nita/face/mouth_happy.svg"),
	"angry": preload("res://assets/nita/face/mouth_angry.svg"),
	"shocked": preload("res://assets/nita/face/mouth_shocked.svg"),
	"hurt": preload("res://assets/nita/face/mouth_hurt.svg"),
	"smug": preload("res://assets/nita/face/mouth_grin.svg")
}

var eye_textures_l := {
	"open": preload("res://assets/nita/face/eye_L.svg"),
	"blink": preload("res://assets/nita/face/eyes_blink.svg"),
	"closed": preload("res://assets/nita/face/eyes_blink.svg"),
	"happy": preload("res://assets/nita/face/eyes_happy.svg"),
	"wide": preload("res://assets/nita/face/eyes_wide.svg"),
	"angry": preload("res://assets/nita/face/eyes_angry.svg")
}

var eye_textures_r := {
	"open": preload("res://assets/nita/face/eye_R.svg"),
	"blink": preload("res://assets/nita/face/eyes_blink.svg"),
	"closed": preload("res://assets/nita/face/eyes_blink.svg"),
	"happy": preload("res://assets/nita/face/eyes_happy.svg"),
	"wide": preload("res://assets/nita/face/eyes_wide.svg"),
	"angry": preload("res://assets/nita/face/eyes_angry.svg")
}

@export_enum("neutral", "grin", "happy", "angry", "shocked", "hurt", "smug") var expression: String = "grin":
	set(val):
		if expression != val:
			expression = val
			set_expression(val)

@export_enum("open", "blink", "wide", "closed", "happy", "angry") var eye_state: String = "open":
	set(val):
		if eye_state != val:
			eye_state = val
			set_eye_state(val)

var current_expression: String = "grin"
var current_eye_state: String = "open"
var is_blinking: bool = false
var blink_timer: float = 0.0
var next_blink_interval: float = 3.0
var blink_duration: float = 0.12
var blink_elapsed: float = 0.0
@export var auto_blink_enabled: bool = true
@export var hide_eyes_in_neutral: bool = false # Nita's fierce eyes are ALWAYS visible!

func _ensure_nodes() -> void:
	if not eye_l_sprite: eye_l_sprite = get_node_or_null("EyeL")
	if not eye_r_sprite: eye_r_sprite = get_node_or_null("EyeR")
	if not pupil_l_sprite: pupil_l_sprite = get_node_or_null("EyeL/PupilL")
	if not pupil_r_sprite: pupil_r_sprite = get_node_or_null("EyeR/PupilR")
	if not brow_l_sprite: brow_l_sprite = get_node_or_null("BrowL")
	if not brow_r_sprite: brow_r_sprite = get_node_or_null("BrowR")
	if not mouth_sprite: mouth_sprite = get_node_or_null("Mouth")

func _ready() -> void:
	_ensure_nodes()
	var initial_expr = current_expression if current_expression != "" else expression
	set_expression(initial_expr)
	set_eye_state(eye_state)

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not auto_blink_enabled:
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
	if current_expression in ["hurt"] or current_eye_state in ["closed", "blink"]:
		return
	is_blinking = true
	blink_elapsed = 0.0
	_apply_eye_state("blink")

func _end_blink() -> void:
	is_blinking = false
	blink_timer = 0.0
	next_blink_interval = randf_range(2.5, 5.0)
	_apply_eye_state(current_eye_state)

func set_expression(expr: String) -> void:
	_ensure_nodes()
	current_expression = expr
	if expression != expr:
		expression = expr
	var key = expr if mouth_textures.has(expr) else "grin"
	if mouth_sprite:
		mouth_sprite.texture = mouth_textures[key]
	_apply_expression_eyes(expr)

func set_eye_state(state_name: String) -> void:
	_ensure_nodes()
	current_eye_state = state_name
	_apply_eye_state(state_name)

func _apply_eye_state(state_name: String) -> void:
	_ensure_nodes()
	var tex_l = eye_textures_l.get(state_name, eye_textures_l["open"])
	var tex_r = eye_textures_r.get(state_name, eye_textures_r["open"])
	if eye_l_sprite: eye_l_sprite.texture = tex_l
	if eye_r_sprite: eye_r_sprite.texture = tex_r
	var show_pupils = (state_name in ["open", "wide"])
	if pupil_l_sprite: pupil_l_sprite.visible = show_pupils
	if pupil_r_sprite: pupil_r_sprite.visible = show_pupils

func _apply_expression_eyes(expr: String) -> void:
	_ensure_nodes()
	var show_eyes = not (expr == "neutral" and hide_eyes_in_neutral)
	if eye_l_sprite: eye_l_sprite.visible = show_eyes
	if eye_r_sprite: eye_r_sprite.visible = show_eyes
	if brow_l_sprite: brow_l_sprite.visible = show_eyes
	if brow_r_sprite: brow_r_sprite.visible = show_eyes

	match expr:
		"neutral", "grin", "smug":
			_apply_eye_state("open")
			if brow_l_sprite: brow_l_sprite.rotation = 0.0
			if brow_r_sprite: brow_r_sprite.rotation = 0.0
		"happy":
			_apply_eye_state("happy")
			if brow_l_sprite: brow_l_sprite.rotation = 0.0
			if brow_r_sprite: brow_r_sprite.rotation = 0.0
		"angry":
			_apply_eye_state("angry")
			if brow_l_sprite: brow_l_sprite.rotation = 0.22
			if brow_r_sprite: brow_r_sprite.rotation = -0.22
		"shocked":
			_apply_eye_state("wide")
			if brow_l_sprite: brow_l_sprite.rotation = -0.12
			if brow_r_sprite: brow_r_sprite.rotation = 0.12
		"hurt":
			_apply_eye_state("blink")
			if brow_l_sprite: brow_l_sprite.rotation = 0.20
			if brow_r_sprite: brow_r_sprite.rotation = -0.20
		_:
			_apply_eye_state("open")
