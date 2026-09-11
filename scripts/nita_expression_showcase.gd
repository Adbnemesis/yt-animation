extends Node2D

var auto_quit_duration := 0.2
var time_elapsed := 0.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

	var expressions = ["grin", "happy", "angry", "shocked", "hurt", "neutral"]
	for expr_name in expressions:
		var nita = get_node_or_null("Nita_" + expr_name)
		if nita:
			var face = nita.find_child("Face", true, false)
			if face and face.has_method("set_expression"):
				face.set_expression(expr_name)

func _process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed >= auto_quit_duration:
		get_tree().quit(0)
