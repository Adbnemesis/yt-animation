extends CharacterBody2D
class_name CharacterController

signal attack_impact(hit_position: Vector2)
signal state_changed(old_state: String, new_state: String)
signal attack_started()
signal attack_released()
signal projectile_spawned(spawn_position: Vector2, direction: int)
signal attack_follow_through()
signal attack_ended()
signal attack_event(event_name: String, data: Dictionary)
signal super_event(event_name: String, data: Dictionary)
signal super_state_changed(old_state: String, new_state: String)

enum State {
	IDLE,
	WALK,
	RUN,
	STOP,
	TURN,
	JUMP_ANTICIPATION,
	JUMP_AIRBORNE,
	FALL,
	JUMP_LAND,
	ATTACK,
	HIT,
	KNOCKBACK
}

const STATE_NAMES := {
	State.IDLE: "IDLE",
	State.WALK: "WALK",
	State.RUN: "RUN",
	State.STOP: "STOP",
	State.TURN: "TURN",
	State.JUMP_ANTICIPATION: "JUMP_ANTICIPATION",
	State.JUMP_AIRBORNE: "JUMP_AIRBORNE",
	State.FALL: "FALL",
	State.JUMP_LAND: "JUMP_LAND",
	State.ATTACK: "ATTACK",
	State.HIT: "HIT",
	State.KNOCKBACK: "KNOCKBACK"
}

@export var walk_speed: float = 160.0
@export var run_speed: float = 300.0
@export var jump_velocity: float = -460.0
@export var gravity: float = 1200.0
@export var acceleration: float = 1800.0
@export var friction: float = 2000.0
@export var character_name: String = ""
@export var projectile_scene: PackedScene = preload("res://scenes/leon_projectile.tscn")
@export var projectiles_per_attack: int = 4
@export var projectile_burst_interval: float = 0.030
@export var projectile_spread_angles: Array[float] = [-0.05, -0.015, 0.015, 0.05]
@export var super_duration: float = 5.0

var attack_burst_count: int = 0

func get_character_id() -> String:
	if not character_name.is_empty():
		return character_name.to_lower()
	if scene_file_path.to_lower().contains("nita") or (get_parent() and get_parent().name.to_lower().contains("nita")):
		return "nita"
	if scene_file_path.to_lower().contains("leon") or (get_parent() and get_parent().name.to_lower().contains("leon")):
		return "leon"
	return "leon"

# --- Super Ability Layer ---
enum SuperState { NONE, SUPER_START, SUPER_ACTIVE, SUPER_END }

const SUPER_STATE_NAMES := {
	SuperState.NONE: "NONE",
	SuperState.SUPER_START: "SUPER_START",
	SuperState.SUPER_ACTIVE: "SUPER_ACTIVE",
	SuperState.SUPER_END: "SUPER_END"
}

var super_state: SuperState = SuperState.NONE
var super_timer: float = 0.0
var super_phase_timer: float = 0.0  # Timer for START/END transition phases
var is_super_visible: bool = true
var wants_super: bool = false

# Deterministic Super Event Guards
var super_has_started: bool = false
var super_has_activated: bool = false
var super_has_ended: bool = false

const SUPER_TRANSITION_DURATION := 0.20  # Fade in/out duration

@onready var anim_player: AnimationPlayer = get_node_or_null("AnimPlayer")
@onready var visuals: Node2D = get_node_or_null("Visuals")
@onready var face_controller: Node2D = get_node_or_null("Visuals/Skeleton/root/torso/neck/head/Face")
@onready var projectile_spawn_point: Marker2D = get_node_or_null("Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R/ProjectileSpawnPoint")
@onready var vfx_projectile_spawn: Marker2D = get_node_or_null("VFXAttachmentPoints/ProjectileSpawn")

var current_state: State = State.IDLE
var facing_direction: int = 1: # 1 for right, -1 for left
	set(val):
		if val != 0 and val != facing_direction:
			facing_direction = val
			_ensure_nodes()
			if visuals:
				visuals.scale.x = facing_direction

var target_turn_dir: int = 1
var previous_locomotion: State = State.IDLE
var locked_expression: String = "" # If non-empty, manual facial override persists

# Movement inputs (can be set by player or demo director)
var input_dir: float = 0.0
var wants_run: bool = false
var wants_jump: bool = false
var wants_attack: bool = false
var wants_hit: bool = false
var wants_knockback: bool = false
# wants_super is declared above with Super variables

# Internal state timers & flags
var state_timer: float = 0.0
var hit_stop_timer: float = 0.0
var is_frozen_for_hitstop: bool = false

# Deterministic Attack Event Guards (Ensures each event fires exactly once per attack)
var attack_has_started: bool = false
var attack_has_released: bool = false
var attack_has_spawned_projectile: bool = false
var attack_has_followed_through: bool = false
var attack_has_ended: bool = false

func _ensure_nodes() -> void:
	if not anim_player:
		anim_player = get_node_or_null("AnimPlayer")
	if not visuals:
		visuals = get_node_or_null("Visuals")
	if not face_controller:
		face_controller = get_node_or_null("Visuals/Skeleton/root/torso/neck/head/Face")
	if not face_controller:
		face_controller = find_child("Face")
	if not projectile_spawn_point:
		projectile_spawn_point = get_node_or_null("Visuals/Skeleton/root/torso/arm_R_upper/arm_R_lower/hand_R/ProjectileSpawnPoint")
	if not vfx_projectile_spawn:
		vfx_projectile_spawn = get_node_or_null("VFXAttachmentPoints/ProjectileSpawn")

func _ready() -> void:
	_ensure_nodes()
	change_state(State.IDLE)
	if anim_player and not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		if am.has_method("bind_character"):
			am.bind_character(self)

func has_valid_physics_space() -> bool:
	if not is_inside_tree():
		return false
	var vp = get_viewport()
	if not vp:
		return false
	var w2d = vp.find_world_2d()
	return w2d != null and w2d.space.is_valid()

func is_grounded() -> bool:
	if has_valid_physics_space():
		return is_on_floor()
	return position.y >= 0.0

func _physics_process(delta: float) -> void:
	# Handle hit-stop freeze deterministically
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
		if hit_stop_timer <= 0.0:
			hit_stop_timer = 0.0
			_ensure_nodes()
			if anim_player:
				anim_player.speed_scale = 1.0
		else:
			return # Pause physics during hit-stop

	state_timer += delta

	# Apply gravity if not on floor
	if not is_grounded():
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	# Process current state logic
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta)
		State.RUN:
			_process_run(delta)
		State.STOP:
			_process_stop(delta)
		State.TURN:
			_process_turn(delta)
		State.JUMP_ANTICIPATION:
			_process_jump_anticipation(delta)
		State.JUMP_AIRBORNE:
			_process_jump_airborne(delta)
		State.FALL:
			_process_fall(delta)
		State.JUMP_LAND:
			_process_jump_land(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HIT:
			_process_hit(delta)
		State.KNOCKBACK:
			_process_knockback(delta)

	if has_valid_physics_space():
		move_and_slide()
	else:
		position += velocity * delta
		if position.y >= 0.0 and velocity.y >= 0.0:
			position.y = 0.0
			velocity.y = 0.0

	# Process Super ability layer (independent of movement state)
	_process_super(delta)

	# Clear edge-triggered input flags
	wants_jump = false
	wants_attack = false
	wants_hit = false
	wants_knockback = false
	wants_super = false

func change_state(new_state: State) -> void:
	_ensure_nodes()
	if current_state == new_state and new_state != State.IDLE:
		return

	if current_state in [State.WALK, State.RUN]:
		previous_locomotion = current_state

	# Reset attack flags when leaving attack
	if current_state == State.ATTACK and new_state != State.ATTACK:
		attack_has_started = false
		attack_has_released = false
		attack_has_spawned_projectile = false
		attack_has_followed_through = false
		attack_has_ended = false
		attack_burst_count = 0

	var old_state_name = STATE_NAMES[current_state]
	var new_state_name = STATE_NAMES[new_state]
	current_state = new_state
	state_timer = 0.0

	_ensure_nodes()
	if anim_player:
		anim_player.speed_scale = 1.0

	var play_anim = func(anim_name: String) -> void:
		if anim_player and anim_player.has_animation(anim_name):
			anim_player.play(anim_name)

	# Animation and face expression setup per state
	match new_state:
		State.IDLE:
			play_anim.call("idle")
			_apply_state_face("neutral")

		State.WALK:
			play_anim.call("walk")
			_apply_state_face("neutral")

		State.RUN:
			play_anim.call("run")
			_apply_state_face("neutral")

		State.STOP:
			if previous_locomotion == State.RUN:
				play_anim.call("run_stop")
			else:
				play_anim.call("walk_stop")
			_apply_state_face("neutral")

		State.TURN:
			play_anim.call("turn")
			_apply_state_face("neutral")

		State.JUMP_ANTICIPATION:
			play_anim.call("jump_anticipation")
			_apply_state_face("neutral")

		State.JUMP_AIRBORNE:
			play_anim.call("jump_airborne")
			_apply_state_face("neutral")

		State.FALL:
			play_anim.call("fall")
			_apply_state_face("neutral")

		State.JUMP_LAND:
			play_anim.call("jump_land")
			_apply_state_face("neutral")

		State.ATTACK:
			attack_has_started = false
			attack_has_released = false
			attack_has_spawned_projectile = false
			attack_has_followed_through = false
			attack_has_ended = false
			attack_burst_count = 0
			play_anim.call("attack")
			_apply_state_face("smug")
			_on_anim_attack_start()

		State.HIT:
			play_anim.call("hit")
			_apply_state_face("hurt")

		State.KNOCKBACK:
			play_anim.call("knockback")
			_apply_state_face("scared")

	state_changed.emit(old_state_name, new_state_name)

func _apply_state_face(default_expr: String) -> void:
	if not face_controller:
		return
	if locked_expression != "":
		face_controller.set_expression(locked_expression)
	else:
		face_controller.set_expression(default_expr)

func set_face_expression_override(expr: String) -> void:
	locked_expression = expr
	if face_controller:
		face_controller.set_expression(expr if expr != "" else "neutral")

# --- State Handlers ---

func _process_idle(delta: float) -> void:
	_apply_horizontal_deceleration(delta)

	if _check_combat_interrupts():
		return

	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return

	if not is_grounded():
		change_state(State.FALL)
		return

	if abs(input_dir) > 0.05:
		var intended_dir = int(sign(input_dir))
		if intended_dir != facing_direction:
			target_turn_dir = intended_dir
			change_state(State.TURN) # IDLE -> TURN
		else:
			change_state(State.RUN if wants_run else State.WALK) # IDLE -> RUN / IDLE -> WALK

func _process_walk(delta: float) -> void:
	if _check_combat_interrupts():
		return

	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return

	if not is_grounded():
		change_state(State.FALL)
		return

	if abs(input_dir) <= 0.05:
		change_state(State.STOP) # WALK -> STOP (Controlled deceleration)
		return

	var intended_dir = int(sign(input_dir))
	if intended_dir != facing_direction:
		target_turn_dir = intended_dir
		change_state(State.TURN) # WALK -> TURN
		return

	if wants_run:
		change_state(State.RUN) # WALK -> RUN
		return

	var target_speed = input_dir * walk_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)

	# Synchronize animation playback rate with movement speed to eliminate sliding
	if anim_player and anim_player.current_animation in ["walk", "LEON_WALK"]:
		var speed_ratio = clamp(abs(velocity.x) / walk_speed, 0.4, 1.2)
		anim_player.speed_scale = speed_ratio if abs(velocity.x) > 10.0 else 1.0

func _process_run(delta: float) -> void:
	if _check_combat_interrupts():
		return

	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return

	if not is_grounded():
		change_state(State.FALL)
		return

	if abs(input_dir) <= 0.05:
		change_state(State.STOP) # RUN -> STOP (Momentum skid stop)
		return

	var intended_dir = int(sign(input_dir))
	if intended_dir != facing_direction:
		target_turn_dir = intended_dir
		change_state(State.TURN) # RUN -> TURN (Brake pivot)
		return

	if not wants_run:
		change_state(State.WALK) # RUN -> WALK
		return

	var target_speed = input_dir * run_speed
	velocity.x = move_toward(velocity.x, target_speed, acceleration * 1.5 * delta)

	# Synchronize animation playback rate with run speed
	if anim_player and anim_player.current_animation in ["run", "LEON_RUN"]:
		var speed_ratio = clamp(abs(velocity.x) / run_speed, 0.4, 1.3)
		anim_player.speed_scale = speed_ratio if abs(velocity.x) > 15.0 else 1.0

func _process_stop(delta: float) -> void:
	if _check_combat_interrupts():
		return
	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return
	if not is_grounded():
		change_state(State.FALL)
		return

	# Natural braking deceleration communicating momentum
	velocity.x = move_toward(velocity.x, 0.0, friction * 1.2 * delta)

	var max_stop_time = 0.36 if previous_locomotion == State.RUN else 0.24

	# If player resumes movement during stop
	if abs(input_dir) > 0.05:
		var intended_dir = int(sign(input_dir))
		if intended_dir != facing_direction:
			target_turn_dir = intended_dir
			change_state(State.TURN)
		else:
			change_state(State.RUN if wants_run else State.WALK)
		return

	# STOP -> IDLE when settle completes
	if state_timer >= max_stop_time:
		change_state(State.IDLE)

func _process_turn(delta: float) -> void:
	if _check_combat_interrupts():
		return
	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return

	# Slow down during pivot
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Flip facing direction halfway through turn
	if state_timer >= 0.09 and facing_direction != target_turn_dir and target_turn_dir != 0:
		facing_direction = target_turn_dir

	# TURN -> WALK / RUN / IDLE upon turn completion
	if state_timer >= 0.20:
		if abs(input_dir) > 0.05:
			var intended_dir = int(sign(input_dir))
			if intended_dir != facing_direction:
				target_turn_dir = intended_dir
				change_state(State.TURN)
			else:
				change_state(State.RUN if wants_run else State.WALK)
		else:
			change_state(State.IDLE)

func _process_jump_anticipation(delta: float) -> void:
	# If movement input is held (e.g. running jump), maintain forward momentum!
	if abs(input_dir) > 0.05:
		var target_speed = input_dir * (run_speed if wants_run else walk_speed)
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if state_timer >= 0.08: # Jump anticipation duration
		velocity.y = jump_velocity
		# Preserve horizontal momentum at takeoff
		if abs(input_dir) > 0.05:
			velocity.x = input_dir * (run_speed if wants_run else walk_speed)
		change_state(State.JUMP_AIRBORNE)

func _process_jump_airborne(delta: float) -> void:
	_apply_air_steering(delta)

	if velocity.y >= 0.0:
		change_state(State.FALL)

func _process_fall(delta: float) -> void:
	_apply_air_steering(delta)

	if is_grounded():
		change_state(State.JUMP_LAND)

func _process_jump_land(delta: float) -> void:
	if abs(input_dir) > 0.05:
		var target_speed = input_dir * (run_speed if wants_run else walk_speed)
		velocity.x = move_toward(velocity.x, target_speed, acceleration * 0.5 * delta)
	else:
		_apply_horizontal_deceleration(delta)

	if state_timer >= 0.18: # Land recovery duration
		if abs(input_dir) > 0.05:
			change_state(State.RUN if wants_run else State.WALK)
		else:
			change_state(State.IDLE)

func _process_attack(delta: float) -> void:
	# Hit interrupts take highest priority
	if wants_knockback:
		trigger_knockback()
		return
	if wants_hit:
		trigger_hit()
		return

	# Deterministic timer fallbacks (ensures events fire reliably even in headless/low-tick)
	if state_timer >= 0.14:
		if not attack_has_released:
			_on_anim_attack_release()
		while attack_burst_count < projectiles_per_attack and state_timer >= 0.14 + (attack_burst_count * projectile_burst_interval):
			_spawn_burst_projectile(attack_burst_count)
	if state_timer >= 0.26 and not attack_has_followed_through:
		_on_anim_attack_follow_through()

	# Moving vs Stationary kinematics
	if abs(input_dir) > 0.05:
		var target_speed = input_dir * (run_speed if wants_run else walk_speed)
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		if state_timer >= 0.12 and state_timer < 0.18:
			velocity.x = move_toward(velocity.x, facing_direction * 40.0, acceleration * delta)
		else:
			_apply_horizontal_deceleration(delta)

	# Recovery check at animation duration
	if state_timer >= 0.36:
		if not attack_has_ended:
			_on_anim_attack_end()

func _process_hit(delta: float) -> void:
	_apply_horizontal_deceleration(delta)

func _process_knockback(delta: float) -> void:
	if is_grounded():
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 320.0 * delta)

# --- Helper Methods ---

func get_projectile_spawn_position() -> Vector2:
	_ensure_nodes()
	if projectile_spawn_point:
		return projectile_spawn_point.global_position
	if vfx_projectile_spawn:
		return vfx_projectile_spawn.global_position
	var hand = find_child("hand_R", true, false)
	if hand:
		return hand.global_position
	return global_position + Vector2(facing_direction * 36.0, -42.0)

# --- Deterministic Animation Event Handlers ---

func _on_anim_attack_start() -> void:
	if current_state != State.ATTACK or attack_has_started:
		return
	attack_has_started = true
	_apply_state_face("smug")
	attack_started.emit()
	attack_event.emit("ATTACK_START", {"time": state_timer})

func _on_anim_attack_release() -> void:
	if current_state != State.ATTACK or attack_has_released:
		return
	attack_has_released = true
	_apply_state_face("angry")
	attack_released.emit()
	attack_event.emit("ATTACK_RELEASE", {"time": state_timer, "character": get_character_id()})

func _on_anim_projectile_spawn() -> void:
	if current_state != State.ATTACK:
		return
	if attack_burst_count == 0:
		_spawn_burst_projectile(0)

func _spawn_burst_projectile(blade_idx: int) -> void:
	if current_state != State.ATTACK or blade_idx != attack_burst_count:
		return
	attack_burst_count += 1
	if not attack_has_spawned_projectile:
		attack_has_spawned_projectile = true

	var spawn_pos = get_projectile_spawn_position()
	# Fan spread angles: Leon spreads 4 blades across a tight arc
	var spread = projectile_spread_angles[blade_idx] if blade_idx < projectile_spread_angles.size() else 0.0
	var base_angle = 0.0 if facing_direction > 0 else PI
	var shoot_angle = base_angle + (spread * facing_direction)
	var shoot_dir = Vector2(cos(shoot_angle), sin(shoot_angle)).normalized()

	projectile_spawned.emit(spawn_pos, facing_direction)
	var impact_pos = global_position + Vector2(facing_direction * 52.0, -48.0)
	attack_impact.emit(impact_pos)
	attack_event.emit("PROJECTILE_SPAWN", {
		"position": spawn_pos,
		"direction": facing_direction,
		"blade_index": blade_idx,
		"time": state_timer,
		"character": get_character_id()
	})
	_spawn_projectile_object(spawn_pos, shoot_dir)

func _spawn_projectile_object(spawn_pos: Vector2, aim_dir: Vector2) -> Node:
	if not projectile_scene:
		return null
	var parent_node = get_parent()
	if not parent_node:
		return null
	var proj = projectile_scene.instantiate()
	parent_node.add_child(proj)
	if proj.has_method("initialize"):
		proj.initialize(spawn_pos, aim_dir, self)
	return proj

func _on_anim_attack_follow_through() -> void:
	if current_state != State.ATTACK or attack_has_followed_through:
		return
	attack_has_followed_through = true
	attack_follow_through.emit()
	attack_event.emit("ATTACK_FOLLOW_THROUGH", {"time": state_timer})

func _on_anim_attack_end() -> void:
	if current_state != State.ATTACK or attack_has_ended:
		return
	attack_has_ended = true
	_apply_state_face("neutral")
	attack_ended.emit()
	attack_event.emit("ATTACK_END", {"time": state_timer})
	_recover_from_attack()

func _recover_from_attack() -> void:
	if abs(input_dir) > 0.05:
		var intended_dir = int(sign(input_dir))
		if intended_dir != facing_direction:
			target_turn_dir = intended_dir
			change_state(State.TURN)
		else:
			change_state(State.RUN if wants_run else State.WALK)
	else:
		change_state(State.IDLE)

func _apply_horizontal_deceleration(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _apply_air_steering(delta: float) -> void:
	if abs(input_dir) > 0.05:
		var intended_dir = int(sign(input_dir))
		facing_direction = intended_dir
		var target_speed = input_dir * (run_speed if wants_run else walk_speed)
		velocity.x = move_toward(velocity.x, target_speed, acceleration * 0.85 * delta)

func _check_combat_interrupts() -> bool:
	if wants_knockback:
		trigger_knockback()
		return true
	if wants_hit:
		trigger_hit()
		return true
	if wants_attack:
		# Attack cancels Super (canonical Brawl Stars behavior)
		if super_state == SuperState.SUPER_ACTIVE:
			_end_super()
		trigger_attack()
		return true
	return false

# --- Public Triggers ---

func trigger_attack() -> void:
	if current_state == State.ATTACK:
		if state_timer >= 0.26: # Combo / rapid re-triggering during recovery
			change_state(State.IDLE)
			change_state(State.ATTACK)
		return
	change_state(State.ATTACK)

func take_hit(hit_data_or_dir = null, force: float = 140.0) -> void:
	# Hit immediately cancels Super
	if super_state != SuperState.NONE:
		_cancel_super()
	if hit_data_or_dir is Vector2:
		velocity.x = hit_data_or_dir.x * force
	elif hit_data_or_dir != null and "direction" in hit_data_or_dir:
		var f = hit_data_or_dir.force if "force" in hit_data_or_dir else force
		velocity.x = hit_data_or_dir.direction.x * f
	else:
		velocity.x = -facing_direction * force
	trigger_hit_stop(0.06)
	change_state(State.HIT)

func trigger_hit() -> void:
	# Hit immediately cancels Super
	if super_state != SuperState.NONE:
		_cancel_super()
	velocity.x = -facing_direction * 140.0
	trigger_hit_stop(0.06)
	change_state(State.HIT)

func trigger_knockback() -> void:
	# Knockback immediately cancels Super
	if super_state != SuperState.NONE:
		_cancel_super()
	velocity.x = -facing_direction * 280.0
	velocity.y = -360.0
	trigger_hit_stop(0.08)
	change_state(State.KNOCKBACK)

func trigger_hit_stop(duration: float) -> void:
	hit_stop_timer = duration
	_ensure_nodes()
	if anim_player:
		anim_player.speed_scale = 0.0 # Brief freeze for cartoon impact

# Called by AnimationPlayer method track precisely on attack impact
func on_attack_impact_event() -> void:
	var impact_pos = global_position + Vector2(facing_direction * 52.0, -48.0)
	attack_impact.emit(impact_pos)
	trigger_hit_stop(0.06) # Snappy cartoon hit-stop

func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"run_stop", "walk_stop", "LEON_STOP":
			if current_state == State.STOP:
				if abs(input_dir) > 0.05:
					var intended_dir = int(sign(input_dir))
					if intended_dir != facing_direction:
						target_turn_dir = intended_dir
						change_state(State.TURN)
					else:
						change_state(State.RUN if wants_run else State.WALK)
				else:
					change_state(State.IDLE)
		"turn", "LEON_TURN":
			if current_state == State.TURN:
				if abs(input_dir) > 0.05:
					var intended_dir = int(sign(input_dir))
					if intended_dir != facing_direction:
						target_turn_dir = intended_dir
						change_state(State.TURN)
					else:
						change_state(State.RUN if wants_run else State.WALK)
				else:
					change_state(State.IDLE)
		"attack", "LEON_BASIC_ATTACK", "LEON_ATTACK":
			if current_state == State.ATTACK:
				_on_anim_attack_end()
		"hit":
			if current_state == State.HIT:
				change_state(State.IDLE)
		"knockback":
			if current_state == State.KNOCKBACK:
				change_state(State.IDLE)
		"jump_land", "LEON_LAND":
			if current_state == State.JUMP_LAND:
				if abs(input_dir) > 0.05:
					change_state(State.RUN if wants_run else State.WALK)
				else:
					change_state(State.IDLE)
		"jump_anticipation":
			if current_state == State.JUMP_ANTICIPATION:
				velocity.y = jump_velocity
				if abs(input_dir) > 0.05:
					velocity.x = input_dir * (run_speed if wants_run else walk_speed)
				change_state(State.JUMP_AIRBORNE)

# ===========================================================================
# SUPER ABILITY LAYER — Invisibility
# ===========================================================================

func _process_super(delta: float) -> void:
	match super_state:
		SuperState.NONE:
			if wants_super:
				trigger_super()

		SuperState.SUPER_START:
			super_phase_timer += delta
			# Fade from 1.0 → 0.08 over SUPER_TRANSITION_DURATION
			var t = clamp(super_phase_timer / SUPER_TRANSITION_DURATION, 0.0, 1.0)
			_apply_super_visibility(lerp(1.0, 0.08, t))

			# Transition to SUPER_ACTIVE after fade completes
			if super_phase_timer >= SUPER_TRANSITION_DURATION - 0.001:
				_change_super_state(SuperState.SUPER_ACTIVE)

		SuperState.SUPER_ACTIVE:
			super_timer -= delta

			# Maintain ghost alpha
			_apply_super_visibility(0.08)
			is_super_visible = false

			# Attack during Super cancels it (handled in _check_combat_interrupts too)
			if wants_attack and current_state != State.ATTACK:
				_end_super()
				trigger_attack()
				return

			# Timer expiry → graceful end
			if super_timer <= 0.0:
				super_timer = 0.0
				_end_super()

		SuperState.SUPER_END:
			super_phase_timer += delta
			# Fade from 0.08 → 1.0 over SUPER_TRANSITION_DURATION
			var t = clamp(super_phase_timer / SUPER_TRANSITION_DURATION, 0.0, 1.0)
			_apply_super_visibility(lerp(0.08, 1.0, t))

			# Fully visible → return to NONE
			if super_phase_timer >= SUPER_TRANSITION_DURATION - 0.001:
				_change_super_state(SuperState.NONE)

func _change_super_state(new_super_state: SuperState) -> void:
	var old_name = SUPER_STATE_NAMES[super_state]
	var new_name = SUPER_STATE_NAMES[new_super_state]
	super_state = new_super_state
	super_phase_timer = 0.0

	# Immediate event emission & setup upon entering new state
	match new_super_state:
		SuperState.NONE:
			super_has_started = false
			super_has_activated = false
			super_has_ended = false
			is_super_visible = true
			_apply_super_visibility(1.0)
			_apply_state_face("neutral")
		SuperState.SUPER_START:
			super_has_started = true
			_apply_state_face("smug")
			super_event.emit("SUPER_START", {"time": 0.0})
		SuperState.SUPER_ACTIVE:
			super_has_activated = true
			is_super_visible = false
			_apply_super_visibility(0.08)
			_apply_state_face("neutral")
			super_event.emit("SUPER_ACTIVE", {"time": super_timer, "duration": super_duration})
		SuperState.SUPER_END:
			super_has_ended = true
			_apply_state_face("neutral")
			super_event.emit("SUPER_END", {"time": 0.0})

	super_state_changed.emit(old_name, new_name)

func trigger_super() -> void:
	if super_state != SuperState.NONE:
		return  # Already in Super — no double activation
	super_timer = super_duration
	_change_super_state(SuperState.SUPER_START)

func _end_super() -> void:
	# Graceful end — plays SUPER_END transition
	if super_state == SuperState.NONE or super_state == SuperState.SUPER_END:
		return
	_change_super_state(SuperState.SUPER_END)

func _cancel_super() -> void:
	# Immediate cancellation — no transition animation (for hit/knockback)
	if super_state == SuperState.NONE:
		return
	super_state = SuperState.NONE
	super_timer = 0.0
	super_phase_timer = 0.0
	super_has_started = false
	super_has_activated = false
	super_has_ended = false
	is_super_visible = true
	_apply_super_visibility(1.0)
	_apply_state_face("neutral")
	super_event.emit("SUPER_CANCELLED", {"time": 0.0})
	super_state_changed.emit("CANCELLED", "NONE")

func _apply_super_visibility(target_alpha: float) -> void:
	_ensure_nodes()
	if visuals:
		visuals.modulate.a = target_alpha
