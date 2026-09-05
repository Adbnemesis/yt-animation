class_name VFXOneShot
extends Node2D
## Generic reusable one-shot VFX emitter.
##
## Usage:
##   - Instance any scenes/vfx/vfx_*.tscn into a scene.
##   - It plays once on _ready() and frees itself (auto_free).
##   - Call restart() to replay it manually.
##   - Tweak the child CPUParticles2D nodes (or exported tint) to re-style.
##
## Deterministic-friendly: uses CPUParticles2D and one_shot emission,
## suitable for fixed-fps Movie Maker rendering.
## Independent of any specific character.

@export var auto_free := true
## Optional global tint applied to all child emitters.
@export var tint := Color.WHITE

func _ready() -> void:
	restart()

func restart() -> void:
	var max_life := 0.0
	for child in get_children():
		if child is CPUParticles2D:
			child.color = tint
			child.restart()
			child.emitting = true
			max_life = maxf(max_life, child.lifetime)
	if auto_free:
		get_tree().create_timer(max_life + 0.5).timeout.connect(queue_free)
