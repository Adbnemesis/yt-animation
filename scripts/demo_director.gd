extends Node
class_name DemoDirector

const CharacterControllerClass = preload("res://scripts/character_controller.gd")

@export var character: CharacterBody2D
@export var auto_mode: bool = true

enum AutoStep {
	IDLE_START,
	WALK_RIGHT,
	TURN_LEFT,
	RUN_LEFT,
	STOP_SKID,
	JUMP_START,
	JUMP_WAIT_LAND,
	POST_LAND,
	ATTACK,
	SUPER_INVIS,
	HIT,
	KNOCKBACK,
	IDLE_FINISH
}

const STEP_NAMES := {
	AutoStep.IDLE_START: "IDLE (START)",
	AutoStep.WALK_RIGHT: "WALK (RIGHT)",
	AutoStep.TURN_LEFT: "TURN (LEFT)",
	AutoStep.RUN_LEFT: "RUN (LEFT)",
	AutoStep.STOP_SKID: "STOP (SKID)",
	AutoStep.JUMP_START: "JUMP (START)",
	AutoStep.JUMP_WAIT_LAND: "JUMP (WAIT LAND)",
	AutoStep.POST_LAND: "POST LAND",
	AutoStep.ATTACK: "ATTACK (THROW SFX)",
	AutoStep.SUPER_INVIS: "SUPER (INVISIBILITY SFX & VO)",
	AutoStep.HIT: "HIT (VO)",
	AutoStep.KNOCKBACK: "KNOCKBACK",
	AutoStep.IDLE_FINISH: "IDLE (FINISH)"
}

var current_step: AutoStep = AutoStep.IDLE_START
var step_timer: float = 0.0

# Inspection Mode State
var inspect_anim_name: String = ""
var inspect_loop: bool = false

# Stage boundary limits to keep character in view
const MIN_X: float = 240.0
const MAX_X: float = 910.0
const CENTER_X: float = 576.0

func _ready() -> void:
	if not character:
		character = get_parent().get_node_or_null("Character")
	if character:
		character.state_changed.connect(func(old_s, new_s):
			print("[CHARACTER STATE] %s -> %s" % [old_s, new_s])
		)
		character.attack_impact.connect(func(pos):
			print("[DEMO DIRECTOR] ATTACK_IMPACT Event detected at: ", pos)
		)
	print("[DEMO DIRECTOR] Initialized with upgraded animations. Auto demo mode: ", auto_mode)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# TAB: Toggle between Auto and Manual mode (and clear inspect mode)
	if event.keycode == KEY_TAB:
		if inspect_anim_name != "":
			inspect_anim_name = ""
			auto_mode = false
			character.change_state(CharacterControllerClass.State.IDLE)
		else:
			auto_mode = not auto_mode
		if not auto_mode and character:
			character.input_dir = 0.0
			character.wants_run = false
		return

	# Keys 1-0: Direct Animation Inspection
	var inspect_map := {
		KEY_1: "idle",
		KEY_2: "walk",
		KEY_3: "run",
		KEY_4: "run_stop",
		KEY_5: "turn",
		KEY_6: "jump_anticipation",
		KEY_7: "jump_airborne",
		KEY_8: "fall",
		KEY_9: "jump_land",
		KEY_0: "attack",
		KEY_MINUS: "hit",
		KEY_EQUAL: "knockback"
	}

	if inspect_map.has(event.keycode):
		var anim = inspect_map[event.keycode]
		_trigger_inspect_animation(anim)
		return

	# 'O' key: Toggle looping for current inspected animation
	if event.keycode == KEY_O and inspect_anim_name != "":
		inspect_loop = not inspect_loop
		print("[INSPECT] Looping toggled: ", inspect_loop)
		return

	# F1-F7: Facial Expression Direct Testing
	var face_map := {
		KEY_F1: "neutral",
		KEY_F2: "happy",
		KEY_F3: "angry",
		KEY_F4: "shocked",
		KEY_F5: "hurt",
		KEY_F6: "scared",
		KEY_F7: "confused"
	}
	if face_map.has(event.keycode):
		var expr = face_map[event.keycode]
		if character:
			character.set_face_expression_override(expr)
		print("[FACE] Override set to: ", expr)
		return

	# Manual Action Keys
	if not auto_mode:
		if event.keycode == KEY_SPACE:
			character.wants_jump = true
		elif event.keycode == KEY_J:
			character.wants_attack = true
		elif event.keycode in [KEY_U, KEY_E]:
			character.wants_super = true
		elif event.keycode == KEY_K:
			character.wants_hit = true
		elif event.keycode == KEY_L:
			character.wants_knockback = true
		elif event.keycode == KEY_M:
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").toggle_mute()
	else:
		if event.keycode in [KEY_J, KEY_K, KEY_L, KEY_U, KEY_E, KEY_SPACE, KEY_A, KEY_D]:
			auto_mode = false
			inspect_anim_name = ""
			if event.keycode == KEY_SPACE:
				character.wants_jump = true
			elif event.keycode == KEY_J:
				character.wants_attack = true
			elif event.keycode in [KEY_U, KEY_E]:
				character.wants_super = true
			elif event.keycode == KEY_K:
				character.wants_hit = true
			elif event.keycode == KEY_L:
				character.wants_knockback = true

func _trigger_inspect_animation(anim_name: String) -> void:
	auto_mode = false
	inspect_anim_name = anim_name
	character.velocity = Vector2.ZERO
	character.input_dir = 0.0

	var state_map := {
		"idle": CharacterControllerClass.State.IDLE,
		"walk": CharacterControllerClass.State.WALK,
		"run": CharacterControllerClass.State.RUN,
		"run_stop": CharacterControllerClass.State.STOP,
		"turn": CharacterControllerClass.State.TURN,
		"jump_anticipation": CharacterControllerClass.State.JUMP_ANTICIPATION,
		"jump_airborne": CharacterControllerClass.State.JUMP_AIRBORNE,
		"fall": CharacterControllerClass.State.FALL,
		"jump_land": CharacterControllerClass.State.JUMP_LAND,
		"attack": CharacterControllerClass.State.ATTACK,
		"hit": CharacterControllerClass.State.HIT,
		"knockback": CharacterControllerClass.State.KNOCKBACK
	}

	if state_map.has(anim_name):
		character.change_state(state_map[anim_name])
	else:
		character.anim_player.play(anim_name)
	print("[INSPECT] Playing animation: ", anim_name)

func _process(delta: float) -> void:
	if not character:
		return

	if inspect_anim_name != "":
		# If inspection animation finishes and loop is enabled, replay it
		if inspect_loop and not character.anim_player.is_playing():
			character.anim_player.play(inspect_anim_name)
		return

	if not auto_mode:
		_process_manual_input()
	else:
		_process_auto_demo(delta)

func _process_manual_input() -> void:
	var dir = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir += 1.0

	character.input_dir = dir
	character.wants_run = Input.is_key_pressed(KEY_SHIFT)

	if Input.is_key_pressed(KEY_SPACE):
		character.wants_jump = true

func _process_auto_demo(delta: float) -> void:
	step_timer += delta

	match current_step:
		AutoStep.IDLE_START:
			character.input_dir = 0.0
			character.wants_run = false
			if step_timer >= 1.4:
				_advance_step(AutoStep.WALK_RIGHT)

		AutoStep.WALK_RIGHT:
			var target_dir = 1.0 if character.position.x < MAX_X - 100.0 else -1.0
			character.input_dir = target_dir
			character.wants_run = false
			if step_timer >= 1.6:
				_advance_step(AutoStep.TURN_LEFT)

		AutoStep.TURN_LEFT:
			# Reverse direction through turn state
			character.input_dir = -1.0
			character.wants_run = false
			if step_timer >= 0.22:
				_advance_step(AutoStep.RUN_LEFT)

		AutoStep.RUN_LEFT:
			var target_dir = -1.0 if character.position.x > MIN_X + 120.0 else 1.0
			character.input_dir = target_dir
			character.wants_run = true
			if step_timer >= 1.4:
				_advance_step(AutoStep.STOP_SKID)

		AutoStep.STOP_SKID:
			# Release run to trigger braking skid
			character.input_dir = 0.0
			character.wants_run = false
			if character.current_state == CharacterControllerClass.State.IDLE and step_timer >= 0.40:
				_advance_step(AutoStep.JUMP_START)

		AutoStep.JUMP_START:
			# Jump forward slightly
			character.input_dir = float(character.facing_direction)
			character.wants_jump = true
			_advance_step(AutoStep.JUMP_WAIT_LAND)

		AutoStep.JUMP_WAIT_LAND:
			if step_timer > 0.35 and character.is_on_floor() and character.current_state != CharacterControllerClass.State.JUMP_AIRBORNE and character.current_state != CharacterControllerClass.State.FALL:
				character.input_dir = 0.0
				_advance_step(AutoStep.POST_LAND)

		AutoStep.POST_LAND:
			character.input_dir = 0.0
			if step_timer >= 0.50:
				_advance_step(AutoStep.ATTACK)

		AutoStep.ATTACK:
			if step_timer < 0.05:
				character.wants_attack = true
			elif character.current_state == CharacterControllerClass.State.IDLE and step_timer >= 0.58:
				_advance_step(AutoStep.SUPER_INVIS)

		AutoStep.SUPER_INVIS:
			if step_timer < 0.05:
				character.wants_super = true # Triggers invisibility vanish SFX & VO
			elif step_timer >= 0.25 and step_timer < 1.4:
				character.input_dir = 1.0 # Walk invisibly across stage
			elif step_timer >= 1.4 and step_timer < 1.8:
				character.input_dir = 0.0
			elif step_timer >= 1.8:
				# Attack while invisible to demonstrate uncloak SFX + combat break
				character.wants_attack = true
				_advance_step(AutoStep.HIT)

		AutoStep.HIT:
			if step_timer < 0.05:
				character.wants_hit = true
			elif character.current_state == CharacterControllerClass.State.IDLE and step_timer >= 0.50:
				_advance_step(AutoStep.KNOCKBACK)

		AutoStep.KNOCKBACK:
			if step_timer < 0.05:
				if character.position.x < CENTER_X:
					character.facing_direction = 1
				else:
					character.facing_direction = -1
				character.wants_knockback = true
			elif character.current_state == CharacterControllerClass.State.IDLE and step_timer >= 0.75:
				_advance_step(AutoStep.IDLE_FINISH)

		AutoStep.IDLE_FINISH:
			character.input_dir = 0.0
			character.wants_run = false
			if step_timer >= 1.2:
				_advance_step(AutoStep.IDLE_START)

func _advance_step(next_step: AutoStep) -> void:
	current_step = next_step
	step_timer = 0.0
	print("[DEMO DIRECTOR] Advancing to: ", STEP_NAMES.get(next_step, "UNKNOWN"))
