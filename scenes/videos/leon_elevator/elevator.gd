class_name ElevatorCabin
extends Node2D

# Production Elevator Cabin Component for "Stuck in the Elevator"
# Handles doors, button illumination, floor display, lights, and cabin movement/jolt.

signal doors_opened()
signal doors_closed()
signal button_pressed(button_id: int)

@onready var door_l: Node2D = get_node_or_null("Doors/DoorL")
@onready var door_r: Node2D = get_node_or_null("Doors/DoorR")
@onready var display_label: Label = get_node_or_null("Frame/Display/Label")
@onready var ceiling_light: CanvasModulate = get_node_or_null("CeilingLight")
@onready var button_container: Node2D = get_node_or_null("ButtonPanel/Buttons")
@onready var cabin_interior: Node2D = get_node_or_null("Interior")

# Audio players
@onready var sfx_ding: AudioStreamPlayer2D = get_node_or_null("Audio/Ding")
@onready var sfx_door_open: AudioStreamPlayer2D = get_node_or_null("Audio/DoorOpen")
@onready var sfx_door_close: AudioStreamPlayer2D = get_node_or_null("Audio/DoorClose")
@onready var sfx_click: AudioStreamPlayer2D = get_node_or_null("Audio/Click")
@onready var sfx_hum: AudioStreamPlayer2D = get_node_or_null("Audio/Hum")
@onready var sfx_jolt: AudioStreamPlayer2D = get_node_or_null("Audio/Jolt")
@onready var sfx_flicker: AudioStreamPlayer2D = get_node_or_null("Audio/Flicker")

const DOOR_CLOSED_L := -75.0
const DOOR_OPEN_L := -205.0
const DOOR_CLOSED_R := 75.0
const DOOR_OPEN_R := 205.0

var are_doors_open: bool = false
var illuminated_buttons: Array[int] = []

func _ready() -> void:
	if display_label:
		display_label.text = "1"
	if ceiling_light:
		ceiling_light.color = Color.WHITE

func set_doors_visible(is_vis: bool) -> void:
	var doors_node = get_node_or_null("Doors")
	if doors_node:
		doors_node.visible = is_vis

func open_doors(duration: float = 1.0) -> void:
	if sfx_door_open:
		sfx_door_open.play()

	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if door_l:
		tw.tween_property(door_l, "position:x", DOOR_OPEN_L, duration)
	if door_r:
		tw.tween_property(door_r, "position:x", DOOR_OPEN_R, duration)

	tw.chain().tween_callback(func():
		are_doors_open = true
		doors_opened.emit()
	)

func close_doors(duration: float = 1.0) -> void:
	if sfx_door_close:
		sfx_door_close.play()

	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if door_l:
		tw.tween_property(door_l, "position:x", DOOR_CLOSED_L, duration)
	if door_r:
		tw.tween_property(door_r, "position:x", DOOR_CLOSED_R, duration)

	tw.chain().tween_callback(func():
		are_doors_open = false
		doors_closed.emit()
	)

func set_display(text: String, play_chime: bool = false) -> void:
	if display_label:
		display_label.text = text
	if play_chime and sfx_ding:
		sfx_ding.play()

func press_button(btn_id: int) -> void:
	if sfx_click:
		sfx_click.play()
	if not illuminated_buttons.has(btn_id):
		illuminated_buttons.append(btn_id)

	_update_button_visuals()
	button_pressed.emit(btn_id)

func clear_buttons() -> void:
	illuminated_buttons.clear()
	_update_button_visuals()

func _update_button_visuals() -> void:
	if not button_container:
		return
	for i in range(1, 5):
		var btn = button_container.get_node_or_null("Btn" + str(i))
		if btn and btn is Polygon2D:
			if illuminated_buttons.has(i):
				btn.color = Color(0.3, 0.9, 1.0, 1.0) # Bright cyan glow
			else:
				btn.color = Color(0.25, 0.28, 0.35, 1.0) # Dim unpressed

func set_lights(enabled: bool, flicker_first: bool = false) -> void:
	if flicker_first:
		if sfx_flicker:
			sfx_flicker.play()
		var tw = create_tween()
		tw.tween_property(ceiling_light, "color", Color(0.2, 0.2, 0.2), 0.08)
		tw.tween_property(ceiling_light, "color", Color.WHITE, 0.08)
		tw.tween_property(ceiling_light, "color", Color(0.05, 0.05, 0.05), 0.06)
		tw.tween_property(ceiling_light, "color", Color.WHITE if enabled else Color(0.02, 0.02, 0.03), 0.1)
	else:
		if ceiling_light:
			ceiling_light.color = Color.WHITE if enabled else Color(0.02, 0.02, 0.03)

func jolt() -> void:
	if sfx_jolt:
		sfx_jolt.play()
	if cabin_interior:
		var tw = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(cabin_interior, "position:y", -14.0, 0.08)
		tw.tween_property(cabin_interior, "position:y", 6.0, 0.10)
		tw.tween_property(cabin_interior, "position:y", 0.0, 0.12)

func start_hum() -> void:
	if sfx_hum and not sfx_hum.playing:
		sfx_hum.play()

func stop_hum() -> void:
	if sfx_hum and sfx_hum.playing:
		sfx_hum.stop()
