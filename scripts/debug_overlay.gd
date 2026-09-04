extends CanvasLayer
class_name DebugOverlay

const CharacterControllerClass = preload("res://scripts/character_controller.gd")

@onready var panel: PanelContainer = $Panel
@onready var label_mode: Label = $Panel/Margin/VBox/LabelMode
@onready var label_anim: Label = $Panel/Margin/VBox/LabelAnim
@onready var label_state: Label = $Panel/Margin/VBox/LabelState
@onready var label_face: Label = $Panel/Margin/VBox.get_node_or_null("LabelFace")
@onready var label_pos: Label = $Panel/Margin/VBox/LabelPos
@onready var label_vel: Label = $Panel/Margin/VBox/LabelVel
@onready var label_ground: Label = $Panel/Margin/VBox/LabelGround
@onready var label_facing: Label = $Panel/Margin/VBox/LabelFacing
@onready var label_impact: Label = $Panel/Margin/VBox/LabelImpact

var character: CharacterBody2D
var demo_director: Node

var impact_flash_timer: float = 0.0

func setup(p_character: CharacterBody2D, p_director: Node) -> void:
	character = p_character
	demo_director = p_director
	if character and character.has_signal("attack_impact"):
		character.attack_impact.connect(_on_attack_impact)

func _process(delta: float) -> void:
	if not character:
		return

	var is_auto: bool = demo_director.auto_mode if demo_director else false
	var inspect_anim = demo_director.inspect_anim_name if (demo_director and "inspect_anim_name" in demo_director) else ""

	if inspect_anim != "":
		var is_loop = demo_director.inspect_loop if ("inspect_loop" in demo_director) else false
		label_mode.text = "Mode: [INSPECT: %s] (Loop: %s | TAB to exit)" % [inspect_anim, "ON" if is_loop else "OFF"]
		label_mode.modulate = Color(0.4, 0.9, 1.0)
	elif is_auto:
		label_mode.text = "Mode: [AUTO DEMO] (Press TAB for Manual)"
		label_mode.modulate = Color(0.3, 1.0, 0.5)
	else:
		label_mode.text = "Mode: [MANUAL CONTROL] (Press TAB for Auto)"
		label_mode.modulate = Color(1.0, 0.8, 0.2)

	var current_anim = character.anim_player.current_animation if character.anim_player else "none"
	var anim_pos = character.anim_player.current_animation_position if character.anim_player else 0.0
	var anim_len = character.anim_player.current_animation_length if character.anim_player else 0.0
	var pct = (anim_pos / anim_len * 100.0) if anim_len > 0.0 else 0.0
	label_anim.text = "Current animation: %s [%.2fs / %.2fs (%d%%)]" % [
		(current_anim if current_anim != "" else "idle"),
		anim_pos, anim_len, int(pct)
	]

	label_state.text = "Current state: %s" % CharacterControllerClass.STATE_NAMES[character.current_state]

	if label_face and character.face_controller:
		var expr = character.face_controller.current_expression
		var blk = " (Blink)" if character.face_controller.is_blinking else ""
		label_face.text = "Facial expression: %s%s" % [expr, blk]

	label_pos.text = "Position: (%.1f, %.1f)" % [character.position.x, character.position.y]
	label_vel.text = "Velocity: (%.1f, %.1f)" % [character.velocity.x, character.velocity.y]
	label_ground.text = "Grounded: %s" % ("YES" if character.is_on_floor() else "NO")
	label_facing.text = "Facing direction: %s" % ("RIGHT (+1)" if character.facing_direction > 0 else "LEFT (-1)")

	if impact_flash_timer > 0.0:
		impact_flash_timer -= delta
		label_impact.modulate = Color(1.0, 0.3, 0.3, clampf(impact_flash_timer / 0.3, 0.0, 1.0))
		label_impact.text = ">>> ATTACK_IMPACT EVENT FIRED! <<<"
	else:
		label_impact.text = ""

func _on_attack_impact(_pos: Vector2) -> void:
	impact_flash_timer = 0.35
