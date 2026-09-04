class_name BrawlerBase
extends CharacterBody2D

# Universal Brawler Base Controller
# Coordinates Movement, Animation, Abilities, Combat, and Event Routing.

signal game_event_emitted(event_name: String, data: Dictionary)
signal state_changed(old_state: String, new_state: String)
signal attack_impact(hit_position: Vector2)

@export var config: BrawlerConfig

var facing_direction: int = 1:
	get:
		if movement_controller:
			return movement_controller.facing_direction
		return 1

@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimPlayer")
@onready var movement_controller: BrawlerMovementController = (
	get_node_or_null("MovementController")
)
@onready var animation_controller: BrawlerAnimationController = (
	get_node_or_null("AnimationController")
)
@onready var ability_controller: BrawlerAbilityController = (
	get_node_or_null("AbilityController")
)
@onready var hit_receiver: BrawlerHitReceiver = get_node_or_null("HitReceiver")
@onready var face_controller: FaceControllerBase = get_node_or_null("Visuals/SkeletonSlot/Face")

@onready var marker_projectile_spawn: Marker2D = (
	get_node_or_null("VFXAttachmentPoints/ProjectileSpawn")
)
@onready var marker_hit_point: Marker2D = get_node_or_null("VFXAttachmentPoints/HitPoint")

func _ready() -> void:
	_ensure_components()
	_bind_component_signals()

	if config and hit_receiver:
		hit_receiver.configure(config.max_health, config.knockback_resistance)

	# Auto-register with AudioManager and VFXManager if autoloaded in scene tree
	_connect_audio_and_vfx()

func _ensure_components() -> void:
	if not visuals:
		visuals = get_node_or_null("Visuals")
	if not anim_player:
		anim_player = get_node_or_null("AnimPlayer")
	if not movement_controller:
		movement_controller = get_node_or_null("MovementController")
	if not animation_controller:
		animation_controller = get_node_or_null("AnimationController")
	if not ability_controller:
		ability_controller = get_node_or_null("AbilityController")
	if not hit_receiver:
		hit_receiver = get_node_or_null("HitReceiver")
	if not face_controller:
		face_controller = find_child("Face") as FaceControllerBase

	if not marker_projectile_spawn:
		marker_projectile_spawn = get_node_or_null("VFXAttachmentPoints/ProjectileSpawn")
	if not marker_hit_point:
		marker_hit_point = get_node_or_null("VFXAttachmentPoints/HitPoint")

	if ability_controller and marker_projectile_spawn:
		ability_controller.set_projectile_spawn(marker_projectile_spawn)

	if movement_controller and config:
		movement_controller.config = config
	if ability_controller and config:
		ability_controller.config = config

func _bind_component_signals() -> void:
	if movement_controller:
		movement_controller.state_changed.connect(_on_movement_state_changed)
		movement_controller.facing_changed.connect(_on_facing_changed)

	if ability_controller:
		ability_controller.attack_started.connect(func():
			_emit_event(BrawlerEvents.EVENT_ATTACK_START)
			if movement_controller:
				movement_controller.change_state(BrawlerMovementController.State.ATTACK)
			if animation_controller:
				animation_controller.play_state_animation("ATTACK")
		)
		ability_controller.projectile_spawned.connect(func(pos: Vector2, dir: Vector2):
			_emit_event(BrawlerEvents.EVENT_PROJECTILE_SPAWN, {"position": pos, "direction": dir})
		)
		ability_controller.attack_ended.connect(func():
			_emit_event(BrawlerEvents.EVENT_ATTACK_END)
			var cur_s = movement_controller.current_state if movement_controller else -1
			if cur_s == BrawlerMovementController.State.ATTACK:
				movement_controller.change_state(BrawlerMovementController.State.IDLE)
		)
		ability_controller.super_started.connect(func():
			_emit_event(BrawlerEvents.EVENT_SUPER_START)
		)
		ability_controller.super_activated.connect(func():
			_emit_event(BrawlerEvents.EVENT_SUPER_ACTIVE)
		)
		ability_controller.super_ended.connect(func():
			_emit_event(BrawlerEvents.EVENT_SUPER_END)
		)

	if hit_receiver:
		hit_receiver.hit_received.connect(func(hit_data: RefCounted):
			_emit_event(BrawlerEvents.EVENT_CHARACTER_HIT, {"hit_data": hit_data})
		)
		hit_receiver.died.connect(func():
			_emit_event(BrawlerEvents.EVENT_DEATH)
			if movement_controller:
				movement_controller.change_state(BrawlerMovementController.State.DEATH)
			if animation_controller:
				animation_controller.play_state_animation("DEATH")
		)

func _physics_process(delta: float) -> void:
	if movement_controller:
		movement_controller.physics_step(delta)
	if ability_controller:
		ability_controller.physics_step(delta)

	if _has_physics_space():
		move_and_slide()
	else:
		position += velocity * delta
		if position.y >= 0.0 and velocity.y >= 0.0:
			position.y = 0.0
			velocity.y = 0.0

func _has_physics_space() -> bool:
	if not is_inside_tree():
		return false
	var vp = get_viewport()
	if not vp:
		return false
	var w2d = vp.find_world_2d()
	return w2d != null and w2d.space.is_valid()

# --- Public Gameplay Controls ---

func move(dir: float, sprint: bool = false) -> void:
	if movement_controller:
		movement_controller.move(dir, sprint)

func jump() -> void:
	if movement_controller:
		movement_controller.jump()

func attack() -> bool:
	if ability_controller:
		return ability_controller.attack()
	return false

func activate_super() -> bool:
	if ability_controller:
		return ability_controller.activate_super()
	return false

func activate_gadget() -> bool:
	if ability_controller:
		return ability_controller.activate_gadget()
	return false

func set_expression(expr: String) -> void:
	if face_controller:
		face_controller.set_expression(expr)

func set_eye_state(state: String) -> void:
	if face_controller:
		face_controller.set_eye_state(state)

func take_hit(hit_data: RefCounted) -> void:
	if hit_receiver:
		hit_receiver.take_hit(hit_data)

func on_hit_received(hit_data: RefCounted) -> void:
	var force = hit_data.force if "force" in hit_data else 0.0
	if ability_controller:
		ability_controller.cancel_super()

	if movement_controller:
		if force > 150.0:
			movement_controller.change_state(BrawlerMovementController.State.KNOCKBACK)
		else:
			movement_controller.change_state(BrawlerMovementController.State.HIT)

	if face_controller:
		face_controller.set_expression("hurt")

func on_death() -> void:
	if face_controller:
		face_controller.set_expression("sad")

# --- Internal Signal Handlers ---

func _on_movement_state_changed(old_state: String, new_state: String) -> void:
	if animation_controller:
		animation_controller.play_state_animation(new_state)

	state_changed.emit(old_state, new_state)

	if new_state == "JUMP_AIRBORNE":
		_emit_event(BrawlerEvents.EVENT_JUMP)
	elif new_state == "JUMP_LAND":
		_emit_event(BrawlerEvents.EVENT_LAND)

func _on_facing_changed(direction: int) -> void:
	if visuals:
		visuals.scale.x = direction

func _emit_event(event_name: String, data: Dictionary = {}) -> void:
	game_event_emitted.emit(event_name, data)

	# Audio routing
	if config and config.audio_event_map.has(event_name):
		var sound_id = config.audio_event_map[event_name]
		if is_inside_tree() and get_tree().root.has_node("AudioManager"):
			var am = get_tree().root.get_node("AudioManager")
			if am.has_method("play_sfx"):
				am.play_sfx(sound_id)
			elif am.has_method("trigger_event"):
				am.trigger_event(event_name)

	# VFX routing
	if config and config.vfx_event_map.has(event_name):
		var vfx_name = config.vfx_event_map[event_name]
		var spawn_pos = global_position
		if data.has("position"):
			spawn_pos = data["position"]
		elif marker_hit_point and (event_name == "HIT" or event_name == "CHARACTER_HIT"):
			spawn_pos = marker_hit_point.global_position

		if is_inside_tree() and get_tree().root.has_node("VFXManager"):
			var vm = get_tree().root.get_node("VFXManager")
			if vm.has_method("spawn_vfx"):
				vm.spawn_vfx(vfx_name, spawn_pos)

func _connect_audio_and_vfx() -> void:
	if is_inside_tree():
		if get_tree().root.has_node("VFXManager"):
			var vm = get_tree().root.get_node("VFXManager")
			if vm.has_method("bind_character"):
				vm.bind_character(self)
