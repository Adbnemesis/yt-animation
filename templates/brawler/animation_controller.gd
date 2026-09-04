class_name BrawlerAnimationController
extends Node

# Generic Animation Controller for Brawler Template
# Bridges state machine requests to AnimationPlayer with fallback handling.

signal animation_started(anim_name: String)
signal animation_finished(anim_name: String)

@export var anim_player: AnimationPlayer

# Maps State name to expected Animation name in AnimationPlayer
var animation_map: Dictionary = {
	"IDLE": "idle",
	"WALK": "walk",
	"RUN": "run",
	"STOP": "stop",
	"TURN": "turn",
	"JUMP_ANTICIPATION": "jump_anticipation",
	"JUMP_AIRBORNE": "jump_airborne",
	"FALL": "fall",
	"JUMP_LAND": "jump_land",
	"ATTACK": "attack",
	"HIT": "hit",
	"KNOCKBACK": "knockback",
	"DEATH": "death"
}

func _ready() -> void:
	if not anim_player:
		anim_player = get_parent().get_node_or_null("AnimPlayer") as AnimationPlayer
	if anim_player and not anim_player.animation_finished.is_connected(_on_anim_finished):
		anim_player.animation_finished.connect(_on_anim_finished)

func play_state_animation(state_name: String) -> void:
	if not anim_player:
		return

	var target_anim = animation_map.get(state_name, state_name.to_lower())

	# Fallback checks if specific variations don't exist
	if not anim_player.has_animation(target_anim):
		if state_name == "JUMP_ANTICIPATION" or state_name == "JUMP_AIRBORNE":
			target_anim = "jump"
		elif state_name == "JUMP_LAND":
			target_anim = "idle"
		elif state_name == "STOP" or state_name == "TURN":
			target_anim = "idle"
		elif state_name == "KNOCKBACK":
			target_anim = "hit"

	if anim_player.has_animation(target_anim):
		anim_player.play(target_anim)
		animation_started.emit(target_anim)

func play_custom(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		animation_started.emit(anim_name)

func _on_anim_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)
