class_name FacilityBuilder
extends Node2D

# Abandoned Facility Environment for "The Thing They Shouldn't Have Opened"
# Built from existing asset library textures. Manages environmental reactions,
# warning systems, sealed chambers, and the warning monitor display.

signal warning_light_activated()
signal chamber_door_opened(index: int)
signal all_chambers_opening()

# Environment node references (populated in _ready)
@onready var warning_lights: Node2D = get_node_or_null("WarningLights")
@onready var monitor_display: Node2D = get_node_or_null("MonitorDisplay")
@onready var monitor_label: Label = get_node_or_null("MonitorDisplay/WarningLabel")
@onready var sealed_door: Node2D = get_node_or_null("SealedDoor")
@onready var chamber_doors: Node2D = get_node_or_null("ChamberDoors")
@onready var bg_dark: Sprite2D = get_node_or_null("BG/DarkBG")
@onready var bg_vignette: Sprite2D = get_node_or_null("BG/Vignette")

var warning_lights_active: bool = false
var _light_tween: Tween = null

const BG_BASE_POS := Vector2(640, 360)
const PARALLAX_FACTOR := 0.08  # restrained: far backdrop drifts against camera

func _ready() -> void:
	# Hide monitor text initially
	if monitor_label:
		monitor_label.modulate.a = 0.0
	# Sealed door starts closed
	if sealed_door:
		sealed_door.visible = true

# Subtle multiplane parallax: the far backdrop drifts slightly against the
# camera so the room reads as a space with depth, not a painted flat.
func apply_parallax(cam_pos: Vector2) -> void:
	var shift = (cam_pos - Vector2(500, 400)) * -PARALLAX_FACTOR
	if bg_dark:
		bg_dark.position = BG_BASE_POS + shift
	if bg_vignette:
		bg_vignette.position = BG_BASE_POS + shift * 0.6

# --- Environmental Reactions ---

func flicker_warning_lights() -> void:
	if not warning_lights or warning_lights_active:
		return
	warning_lights_active = true
	warning_light_activated.emit()

	# Pulse red warning lights with deterministic tween
	for light in warning_lights.get_children():
		if light is Sprite2D or light is ColorRect:
			_light_tween = create_tween().set_loops(0)  # infinite
			_light_tween.tween_property(light, "modulate:a", 0.3, 0.4).set_trans(Tween.TRANS_SINE)
			_light_tween.tween_property(light, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)

func stop_warning_lights() -> void:
	if _light_tween:
		_light_tween.kill()
		_light_tween = null
	warning_lights_active = false
	if warning_lights:
		for light in warning_lights.get_children():
			if light is Sprite2D or light is ColorRect:
				light.modulate.a = 1.0

func spawn_sparks(pos: Vector2) -> void:
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SPAWN_FLASH", pos)

func spawn_debris(pos: Vector2) -> void:
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("DUST_PUFF", pos)

func spawn_smoke(pos: Vector2) -> void:
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("SMOKE_BOMB", pos)

# --- Monitor Warning Display ---

func display_warning(text: String, duration: float = 2.0) -> void:
	if not monitor_label:
		return
	monitor_label.text = text
	var tw = create_tween()
	tw.tween_property(monitor_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(duration)
	tw.tween_property(monitor_label, "modulate:a", 0.0, 0.5)

func flash_monitor_warning(text: String) -> void:
	if not monitor_label:
		return
	monitor_label.text = text
	monitor_label.modulate.a = 1.0
	# Flash effect
	var tw = create_tween().set_loops(3)
	tw.tween_property(monitor_label, "modulate:a", 0.2, 0.15)
	tw.tween_property(monitor_label, "modulate:a", 1.0, 0.15)

# --- Sealed Door ---

func open_sealed_door() -> void:
	if not sealed_door:
		return
	var door_panel = sealed_door.get_node_or_null("DoorPanel")
	if door_panel:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(door_panel, "position:y", door_panel.position.y - 180.0, 1.5)

# --- Chamber Doors (Final Reveal) ---

func open_chamber_door(index: int) -> void:
	if not chamber_doors:
		return
	var doors = chamber_doors.get_children()
	if index < 0 or index >= doors.size():
		return
	var door = doors[index]
	var panel = door.get_node_or_null("Panel")
	if panel:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(panel, "position:y", panel.position.y - 120.0, 0.8)
	chamber_door_opened.emit(index)

func open_all_chambers_sequential(interval: float = 0.4) -> void:
	if not chamber_doors:
		return
	all_chambers_opening.emit()
	var doors = chamber_doors.get_children()
	for i in range(doors.size()):
		open_chamber_door(i)
		# Stagger openings
		var tw = create_tween()
		tw.tween_interval(interval)
		await tw.finished

# --- Glowing Eyes in Chamber (Final Reveal) ---

func activate_chamber_eyes(index: int) -> void:
	if not chamber_doors:
		return
	var doors = chamber_doors.get_children()
	if index < 0 or index >= doors.size():
		return
	var eyes = doors[index].get_node_or_null("Eyes")
	if eyes:
		eyes.visible = true
		var tw = create_tween()
		tw.tween_property(eyes, "modulate:a", 1.0, 0.3).from(0.0)

func activate_all_chamber_eyes() -> void:
	if not chamber_doors:
		return
	var doors = chamber_doors.get_children()
	for i in range(doors.size()):
		activate_chamber_eyes(i)
