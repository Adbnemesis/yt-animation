extends Node2D

@onready var leon_front: Node2D = get_node_or_null("LeonFrontView")
@onready var leon_side: CharacterBody2D = get_node_or_null("LeonSideRig")
@onready var expr_label: Label = get_node_or_null("ExpressionStatus")

var expressions := ["neutral", "happy", "angry", "sad", "shocked", "scared", "hurt", "confused", "smug", "laughing"]
var expr_idx := 0
var timer := 0.0
var time_elapsed := 0.0
var auto_quit_duration := 0.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

	if leon_side:
		leon_side.set_physics_process(false)
		var anim = leon_side.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("idle")
	_update_expression()

func _process(delta: float) -> void:
	time_elapsed += delta
	if auto_quit_duration > 0.0 and time_elapsed >= auto_quit_duration:
		get_tree().quit(0)
		return

	timer += delta
	if timer >= 0.65:
		timer = 0.0
		expr_idx = (expr_idx + 1) % expressions.size()
		_update_expression()

func _update_expression() -> void:
	var expr_name = expressions[expr_idx]
	if leon_front:
		var face = leon_front.find_child("Face", true, false)
		if face and face.has_method("set_expression"):
			face.set_expression(expr_name)
	if expr_label:
		expr_label.text = "Current Expression: %s (%d/%d)" % [expr_name.to_upper(), expr_idx + 1, expressions.size()]
