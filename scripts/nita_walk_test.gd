extends Node2D

@onready var nita_actor: Node2D = get_node_or_null("NitaActor")
@onready var leon_actor: Node2D = get_node_or_null("LeonActor")

var time_elapsed := 0.0
var auto_quit_duration := 4.0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

	if nita_actor and nita_actor.has_method("walk_to"):
		nita_actor.position = Vector2(250, 520)
		nita_actor.walk_to(750, 140.0)

	if leon_actor and leon_actor.has_method("walk_to"):
		leon_actor.position = Vector2(400, 520)
		leon_actor.walk_to(900, 140.0)

func _process(delta: float) -> void:
	time_elapsed += delta
	if auto_quit_duration > 0.0 and time_elapsed >= auto_quit_duration:
		get_tree().quit(0)
