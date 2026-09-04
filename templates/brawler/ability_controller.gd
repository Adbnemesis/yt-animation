class_name BrawlerAbilityController
extends Node

# Generic Ability Controller for Brawler Template
# Manages Basic Attack bursts, Super abilities, and Gadget triggers.

signal attack_started()
signal attack_released()
signal projectile_spawned(spawn_position: Vector2, direction: Vector2)
signal attack_ended()

signal super_started()
signal super_activated()
signal super_ended()
signal gadget_activated()

enum SuperState { NONE, SUPER_START, SUPER_ACTIVE, SUPER_END }

const SUPER_FADE_DURATION := 0.20

@export var config: BrawlerConfig

var brawler: CharacterBody2D = null
var projectile_spawn_point: Marker2D = null

var is_attacking: bool = false
var attack_timer: float = 0.0
var burst_projectiles_remaining: int = 0
var burst_timer: float = 0.0

var super_state: SuperState = SuperState.NONE
var super_timer: float = 0.0
var super_phase_timer: float = 0.0
var gadget_charges_remaining: int = 3


func _ready() -> void:
	brawler = get_parent() as CharacterBody2D

func set_projectile_spawn(marker: Marker2D) -> void:
	projectile_spawn_point = marker

func attack() -> bool:
	if is_attacking:
		return false

	is_attacking = true
	attack_timer = 0.0
	burst_projectiles_remaining = config.projectiles_per_burst if config else 1
	burst_timer = 0.0

	attack_started.emit()
	return true

func activate_super() -> bool:
	if super_state != SuperState.NONE:
		return false

	super_state = SuperState.SUPER_START
	super_timer = 0.0
	super_phase_timer = 0.0
	super_started.emit()
	return true

func activate_gadget() -> bool:
	if gadget_charges_remaining <= 0:
		return false

	gadget_charges_remaining -= 1
	gadget_activated.emit()
	return true

func physics_step(delta: float) -> void:
	_step_attack(delta)
	_step_super(delta)

func _step_attack(delta: float) -> void:
	if not is_attacking:
		return

	attack_timer += delta

	# Process projectile burst
	if burst_projectiles_remaining > 0:
		burst_timer -= delta
		if burst_timer <= 0.0:
			_spawn_next_burst_projectile()
			var interval = config.burst_interval if config else 0.030
			burst_timer = interval

	var duration = config.attack_duration if config else 0.36
	if attack_timer >= duration:
		is_attacking = false
		attack_ended.emit()

func _spawn_next_burst_projectile() -> void:
	if not config or not config.projectile_scene:
		burst_projectiles_remaining -= 1
		return

	var burst_index = config.projectiles_per_burst - burst_projectiles_remaining
	burst_projectiles_remaining -= 1

	var spawn_pos = brawler.global_position if brawler else Vector2.ZERO
	if projectile_spawn_point:
		spawn_pos = projectile_spawn_point.global_position

	var facing_sign = 1.0
	if brawler and "facing_direction" in brawler:
		facing_sign = float(brawler.facing_direction)

	var spread_angle = 0.0
	if config.spread_angles.size() > burst_index:
		spread_angle = config.spread_angles[burst_index]

	var base_dir = Vector2(facing_sign, 0.0)
	var fire_dir = base_dir.rotated(spread_angle * facing_sign)

	var proj = config.projectile_scene.instantiate()
	if proj:
		if proj.has_method("initialize"):
			proj.initialize(spawn_pos, fire_dir, brawler)
		elif proj is Node2D:
			proj.global_position = spawn_pos

		var scene_root = brawler.get_tree().current_scene if brawler and brawler.get_tree() else null
		if scene_root:
			scene_root.add_child(proj)
		elif brawler:
			brawler.add_sibling(proj)

		projectile_spawned.emit(spawn_pos, fire_dir)

func _step_super(delta: float) -> void:
	match super_state:
		SuperState.NONE:
			pass

		SuperState.SUPER_START:
			super_phase_timer += delta
			var t = clampf(super_phase_timer / SUPER_FADE_DURATION, 0.0, 1.0)
			if brawler and brawler.has_node("Visuals"):
				brawler.get_node("Visuals").modulate.a = lerpf(1.0, 0.1, t)

			if super_phase_timer >= SUPER_FADE_DURATION:
				super_state = SuperState.SUPER_ACTIVE
				super_timer = 0.0
				super_activated.emit()

		SuperState.SUPER_ACTIVE:
			super_timer += delta
			var duration = config.super_duration if config else 5.0
			if super_timer >= duration:
				super_state = SuperState.SUPER_END
				super_phase_timer = 0.0

		SuperState.SUPER_END:
			super_phase_timer += delta
			var t = clampf(super_phase_timer / SUPER_FADE_DURATION, 0.0, 1.0)
			if brawler and brawler.has_node("Visuals"):
				brawler.get_node("Visuals").modulate.a = lerpf(0.1, 1.0, t)

			if super_phase_timer >= SUPER_FADE_DURATION:
				super_state = SuperState.NONE
				if brawler and brawler.has_node("Visuals"):
					brawler.get_node("Visuals").modulate.a = 1.0
				super_ended.emit()

func cancel_super() -> void:
	if super_state != SuperState.NONE:
		super_state = SuperState.NONE
		if brawler and brawler.has_node("Visuals"):
			brawler.get_node("Visuals").modulate.a = 1.0
		super_ended.emit()
