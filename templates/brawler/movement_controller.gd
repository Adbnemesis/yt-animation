class_name BrawlerMovementController
extends Node

# Deterministic Movement & Locomotion State Controller
# Extracts universal locomotion and physics logic proven in Leon.

signal state_changed(old_state: String, new_state: String)
signal facing_changed(direction: int)

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
	KNOCKBACK,
	DEATH
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
	State.KNOCKBACK: "KNOCKBACK",
	State.DEATH: "DEATH"
}

@export var config: BrawlerConfig

var body: CharacterBody2D = null
var current_state: State = State.IDLE
var previous_locomotion: State = State.IDLE
var state_timer: float = 0.0

var input_dir: float = 0.0
var wants_run: bool = false
var wants_jump: bool = false

var facing_direction: int = 1:
	set(val):
		if val != 0 and val != facing_direction:
			facing_direction = val
			facing_changed.emit(facing_direction)

var target_turn_dir: int = 1

func _ready() -> void:
	body = get_parent() as CharacterBody2D

func is_grounded() -> bool:
	if not body or not body.is_inside_tree():
		return true
	var vp = body.get_viewport()
	if vp:
		var w2d = vp.find_world_2d()
		if w2d and w2d.space.is_valid():
			return body.is_on_floor()
	return body.position.y >= 0.0

func move(dir: float, sprint: bool) -> void:
	input_dir = dir
	wants_run = sprint

func jump() -> void:
	wants_jump = true

func change_state(new_state: State) -> void:
	if current_state == new_state and new_state != State.IDLE:
		return
	if current_state in [State.WALK, State.RUN]:
		previous_locomotion = current_state

	var old_name = STATE_NAMES.get(current_state, "UNKNOWN")
	var new_name = STATE_NAMES.get(new_state, "UNKNOWN")
	current_state = new_state
	state_timer = 0.0
	state_changed.emit(old_name, new_name)

func physics_step(delta: float) -> void:
	if not body or not config:
		return

	state_timer += delta

	# Apply gravity if airborne
	if not is_grounded():
		body.velocity.y += config.gravity * delta
	elif body.velocity.y > 0.0:
		body.velocity.y = 0.0

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
		State.DEATH:
			_process_death(delta)

	wants_jump = false

func _process_idle(delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * delta)
	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return
	if not is_grounded():
		change_state(State.FALL)
		return
	if abs(input_dir) > 0.1:
		var dir_sign = 1 if input_dir > 0 else -1
		if dir_sign != facing_direction:
			target_turn_dir = dir_sign
			change_state(State.TURN)
		else:
			change_state(State.RUN if wants_run else State.WALK)

func _process_walk(delta: float) -> void:
	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return
	if not is_grounded():
		change_state(State.FALL)
		return
	if abs(input_dir) < 0.1:
		change_state(State.STOP)
		return

	var dir_sign = 1 if input_dir > 0 else -1
	if dir_sign != facing_direction:
		target_turn_dir = dir_sign
		change_state(State.TURN)
		return

	if wants_run:
		change_state(State.RUN)
		return

	var target_vx = dir_sign * config.walk_speed
	body.velocity.x = move_toward(body.velocity.x, target_vx, config.acceleration * delta)

func _process_run(delta: float) -> void:
	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return
	if not is_grounded():
		change_state(State.FALL)
		return
	if abs(input_dir) < 0.1:
		change_state(State.STOP)
		return

	var dir_sign = 1 if input_dir > 0 else -1
	if dir_sign != facing_direction:
		target_turn_dir = dir_sign
		change_state(State.TURN)
		return

	if not wants_run:
		change_state(State.WALK)
		return

	var target_vx = dir_sign * config.run_speed
	body.velocity.x = move_toward(body.velocity.x, target_vx, config.acceleration * delta)

func _process_stop(delta: float) -> void:
	var brake_rate = config.friction * 1.5
	body.velocity.x = move_toward(body.velocity.x, 0.0, brake_rate * delta)
	if wants_jump and is_grounded():
		change_state(State.JUMP_ANTICIPATION)
		return
	if not is_grounded():
		change_state(State.FALL)
		return
	if abs(input_dir) > 0.1:
		var dir_sign = 1 if input_dir > 0 else -1
		if dir_sign != facing_direction:
			target_turn_dir = dir_sign
			change_state(State.TURN)
		else:
			change_state(State.RUN if wants_run else State.WALK)
		return

	var stop_limit = 0.36 if previous_locomotion == State.RUN else 0.24
	if state_timer >= stop_limit or abs(body.velocity.x) < 5.0:
		body.velocity.x = 0.0
		change_state(State.IDLE)

func _process_turn(_delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * _delta)
	if state_timer >= 0.20:
		facing_direction = target_turn_dir
		if abs(input_dir) > 0.1:
			change_state(State.RUN if wants_run else State.WALK)
		else:
			change_state(State.IDLE)

func _process_jump_anticipation(_delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * _delta)
	if state_timer >= 0.10:
		body.velocity.y = config.jump_velocity
		if abs(input_dir) > 0.1:
			var speed = config.run_speed if wants_run else config.walk_speed
			body.velocity.x = (1 if input_dir > 0 else -1) * speed
		change_state(State.JUMP_AIRBORNE)

func _process_jump_airborne(_delta: float) -> void:
	if abs(input_dir) > 0.1:
		var speed = config.run_speed if wants_run else config.walk_speed
		var target_vx = (1 if input_dir > 0 else -1) * speed
		body.velocity.x = move_toward(body.velocity.x, target_vx, config.acceleration * 0.5 * _delta)

	if body.velocity.y >= 0.0:
		change_state(State.FALL)

func _process_fall(_delta: float) -> void:
	if abs(input_dir) > 0.1:
		var speed = config.run_speed if wants_run else config.walk_speed
		var target_vx = (1 if input_dir > 0 else -1) * speed
		body.velocity.x = move_toward(body.velocity.x, target_vx, config.acceleration * 0.5 * _delta)

	if is_grounded():
		change_state(State.JUMP_LAND)

func _process_jump_land(delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * delta)
	if state_timer >= 0.20:
		if abs(input_dir) > 0.1:
			change_state(State.RUN if wants_run else State.WALK)
		else:
			change_state(State.IDLE)

func _process_attack(delta: float) -> void:
	# Maintain momentum during attack if moving
	if abs(body.velocity.x) > 0.0:
		body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * 0.3 * delta)

func _process_hit(delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * delta)
	if state_timer >= 0.25:
		change_state(State.IDLE)

func _process_knockback(delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * 0.8 * delta)
	if state_timer >= 0.40 and is_grounded():
		change_state(State.IDLE)

func _process_death(delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, 0.0, config.friction * delta)
