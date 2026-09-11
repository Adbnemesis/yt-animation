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

	var expressions = ["neutral", "happy", "angry", "sad", "shocked", "scared", "hurt", "confused", "smug", "laughing"]
	for expr_name in expressions:
		var leon = get_node_or_null("Leon_" + expr_name)
		if leon:
			var face = leon.find_child("Face", true, false)
			if face and face.has_method("set_expression"):
				face.set_expression(expr_name)

func _process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed >= auto_quit_duration:
		get_tree().quit(0)
