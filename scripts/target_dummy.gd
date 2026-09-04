extends Area2D
class_name TargetDummy

signal hit_received(hit_data: RefCounted)

@export var max_hp: float = 1000.0
var current_hp: float = 1000.0
var hit_count: int = 0
var last_hit_data: RefCounted = null

var home_position: Vector2 = Vector2.ZERO
var recoil_offset: Vector2 = Vector2.ZERO
var flash_timer: float = 0.0

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var hp_label: Label = get_node_or_null("UI/LblHP")
@onready var hp_bar: ProgressBar = get_node_or_null("UI/ProgressBar")

func _ready() -> void:
	add_to_group("hit_receiver")
	home_position = global_position
	current_hp = max_hp
	_ensure_nodes()
	_update_ui()

func _ensure_nodes() -> void:
	if not visuals: visuals = get_node_or_null("Visuals")
	if not hp_label: hp_label = get_node_or_null("UI/LblHP")
	if not hp_bar: hp_bar = get_node_or_null("UI/ProgressBar")

func take_hit(hit_data: RefCounted) -> void:
	_ensure_nodes()
	var dmg = hit_data.damage if "damage" in hit_data else 100.0
	var dir = hit_data.direction if "direction" in hit_data else Vector2.RIGHT
	var force = hit_data.force if "force" in hit_data else 120.0

	current_hp = max(0.0, current_hp - dmg)
	hit_count += 1
	last_hit_data = hit_data
	flash_timer = 0.10
	recoil_offset = dir * (force * 0.05)

	hit_received.emit(hit_data)
	_update_ui()

func _physics_process(delta: float) -> void:
	_ensure_nodes()

	# Recoil elastic spring return
	if recoil_offset != Vector2.ZERO:
		recoil_offset = recoil_offset.move_toward(Vector2.ZERO, 180.0 * delta)
		if visuals:
			visuals.position = recoil_offset

	# Flash white/red on impact
	if flash_timer > 0.0:
		flash_timer -= delta
		if visuals:
			visuals.modulate = Color(1.8, 0.4, 0.4, 1.0)
		if flash_timer <= 0.0:
			if visuals:
				visuals.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _update_ui() -> void:
	if hp_label:
		hp_label.text = "HP: %d / %d" % [int(current_hp), int(max_hp)]
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

func reset_dummy() -> void:
	current_hp = max_hp
	hit_count = 0
	last_hit_data = null
	flash_timer = 0.0
	recoil_offset = Vector2.ZERO
	if visuals:
		visuals.position = Vector2.ZERO
		visuals.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_update_ui()
