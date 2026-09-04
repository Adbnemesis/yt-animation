class_name VFXManagerClass
extends Node

# Centralized Production VFX Manager for Godot 2D Brawler
# Event-driven spawning of reusable CPUParticles2D VFX components.

signal vfx_spawned(vfx_name: String, position: Vector2)

const VFX_SCENES := {
	"HIT_IMPACT": preload("res://scenes/vfx/vfx_hit_impact.tscn"),
	"DUST_PUFF": preload("res://scenes/vfx/vfx_dust_puff.tscn"),
	"SPAWN_FLASH": preload("res://scenes/vfx/vfx_spawn_flash.tscn"),
	"SMOKE_BOMB": preload("res://scenes/vfx/vfx_smoke_bomb.tscn")
}

var last_vfx_event: String = "None"
var last_vfx_position: Vector2 = Vector2.ZERO
var total_vfx_spawned: int = 0
var vfx_counts: Dictionary = {}

var _bound_characters: Array[CharacterBody2D] = []
var _bound_targets: Array[Node] = []

func spawn_vfx(vfx_name: String, global_pos: Vector2, custom_parent: Node = null) -> Node:
	if not VFX_SCENES.has(vfx_name):
		push_warning("[VFXManager] Unknown VFX type: %s" % vfx_name)
		return null

	var scene: PackedScene = VFX_SCENES[vfx_name]
	if not scene:
		return null

	var emitter: CPUParticles2D = scene.instantiate() as CPUParticles2D
	if not emitter:
		return null

	var target_parent = custom_parent
	if not target_parent:
		target_parent = get_tree().current_scene if get_tree() else null
	if not target_parent:
		target_parent = self

	target_parent.add_child(emitter)
	emitter.global_position = global_pos
	emitter.emitting = true

	last_vfx_event = vfx_name
	last_vfx_position = global_pos
	total_vfx_spawned += 1
	vfx_counts[vfx_name] = vfx_counts.get(vfx_name, 0) + 1

	vfx_spawned.emit(vfx_name, global_pos)
	return emitter

# Helper to automatically bind character controller signals without modifying character code
func bind_character(character: CharacterBody2D) -> void:
	if not character or _bound_characters.has(character):
		return
	_bound_characters.append(character)

	# 1. LAND -> dust VFX
	if character.has_signal("state_changed"):
		character.state_changed.connect(func(_old_s: String, new_s: String):
			if new_s == "JUMP_LAND":
				spawn_vfx("DUST_PUFF", character.global_position, character.get_parent())
		)

	# 2. ATTACK_IMPACT -> hit impact VFX
	if character.has_signal("attack_impact"):
		character.attack_impact.connect(func(pos: Vector2):
			spawn_vfx("HIT_IMPACT", pos, character.get_parent())
		)

	# 3. PROJECTILE_SPAWNED -> muzzle flash VFX
	if character.has_signal("projectile_spawned"):
		character.projectile_spawned.connect(func(spawn_pos: Vector2, _dir: int):
			spawn_vfx("SPAWN_FLASH", spawn_pos, character.get_parent())
		)

	# 4. SUPER_START / SUPER_END -> vanish & reveal smoke bomb VFX
	if character.has_signal("super_event"):
		character.super_event.connect(func(ev_name: String, _data: Dictionary):
			if ev_name == "SUPER_START" or ev_name == "SUPER_END":
				var offset_pos = character.global_position + Vector2(0, -32)
				spawn_vfx("SMOKE_BOMB", offset_pos, character.get_parent())
		)

# Helper to bind hit receivers (e.g. TargetDummy)
func bind_target(target: Node) -> void:
	if not target or _bound_targets.has(target):
		return
	_bound_targets.append(target)

	if target.has_signal("hit_received"):
		target.hit_received.connect(func(hit_data: RefCounted):
			var pos: Vector2 = target.global_position
			if "position" in hit_data and hit_data.position != Vector2.ZERO:
				pos = hit_data.position
			spawn_vfx("HIT_IMPACT", pos, target.get_parent())
		)
