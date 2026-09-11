extends Node2D

var auto_quit_duration := 0.5
var time_elapsed := 0.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

func _process(delta: float) -> void:
	time_elapsed += delta
	if time_elapsed >= auto_quit_duration:
		get_tree().quit(0)
