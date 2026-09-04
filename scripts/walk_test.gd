extends Node2D

enum Mode {
	IN_PLACE_WALK,
	IN_PLACE_RUN,
	WALK_FORWARD,
	RUN_FORWARD,
	LOCOMOTION_DEMO,
	JUMP_DEMO,
	ATTACK_DEMO,
	PROJECTILE_DEMO,
	SUPER_DEMO,
	AUDIO_PREVIEW,
	INTERACTIVE
}

@onready var puppet: CharacterBody2D = $Puppet
@onready var dummy: Area2D = get_node_or_null("TargetDummy")
@onready var ground_line: Line2D = $GroundLine
@onready var mode_label: Label = $UI/InfoPanel/VBox/LblMode
@onready var stats_label: Label = $UI/InfoPanel/VBox/LblStats

var current_mode: Mode = Mode.IN_PLACE_WALK
var base_ground_y: float = 520.0
var walk_speed: float = 160.0
var run_speed: float = 300.0
var show_ground_line: bool = true
var time_elapsed: float = 0.0

# Automated demonstration timers
var demo_timer: float = 0.0
var demo_cycle_duration: float = 7.0
var jump_demo_timer: float = 0.0
var jump_demo_duration: float = 7.2
var attack_demo_timer: float = 0.0
var attack_demo_duration: float = 8.4
var projectile_demo_timer: float = 0.0
var projectile_demo_duration: float = 8.5
var super_demo_timer: float = 0.0
var super_demo_duration: float = 10.0
var audio_preview_timer: float = 0.0
var audio_preview_step: int = 0

# Combat & projectile telemetry
var last_attack_event: String = "None"
var attack_event_timer: float = 0.0
var last_projectile_spawn_time: float = -1.0
var last_hit_time: float = -1.0
var last_hit_damage: float = 0.0
var last_super_event: String = "None"
var super_event_timer: float = 0.0

var auto_quit_timer: float = 0.0
var auto_quit_duration: float = -1.0

func _ready() -> void:
	if puppet:
		puppet.position = Vector2(576, base_ground_y)
		if puppet.has_method("set_physics_process"):
			puppet.set_physics_process(false)
		var anim: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
		if anim:
			anim.play("walk")
		if puppet.has_signal("attack_event"):
			puppet.attack_event.connect(_on_attack_event)
		if puppet.has_signal("super_event"):
			puppet.super_event.connect(_on_super_event)
	if dummy:
		dummy.hit_received.connect(_on_dummy_hit_received)
	_update_ui()

	# Command-line mode flags
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg == "--walk-forward":
			set_mode(Mode.WALK_FORWARD)
		elif arg == "--run-forward":
			set_mode(Mode.RUN_FORWARD)
		elif arg == "--walk-in-place":
			set_mode(Mode.IN_PLACE_WALK)
		elif arg == "--run-in-place":
			set_mode(Mode.IN_PLACE_RUN)
		elif arg == "--locomotion-demo":
			set_mode(Mode.LOCOMOTION_DEMO)
		elif arg == "--jump-demo":
			set_mode(Mode.JUMP_DEMO)
		elif arg == "--attack-demo":
			set_mode(Mode.ATTACK_DEMO)
		elif arg == "--projectile-demo":
			set_mode(Mode.PROJECTILE_DEMO)
		elif arg == "--super-demo":
			set_mode(Mode.SUPER_DEMO)
		elif arg == "--audio-preview":
			set_mode(Mode.AUDIO_PREVIEW)
		elif arg == "--interactive":
			set_mode(Mode.INTERACTIVE)
		elif arg.begins_with("--auto-quit="):
			auto_quit_duration = arg.trim_prefix("--auto-quit=").to_float()

func _on_super_event(event_name: String, _data: Dictionary) -> void:
	last_super_event = event_name
	super_event_timer = 1.5

func _on_attack_event(event_name: String, _data: Dictionary) -> void:
	last_attack_event = event_name
	attack_event_timer = 1.2
	if event_name == "PROJECTILE_SPAWN":
		last_projectile_spawn_time = time_elapsed

func _on_dummy_hit_received(hit_data: RefCounted) -> void:
	last_hit_time = time_elapsed
	if "damage" in hit_data:
		last_hit_damage = hit_data.damage

func _physics_process(delta: float) -> void:
	time_elapsed += delta
	if auto_quit_duration > 0.0:
		auto_quit_timer += delta
		if auto_quit_timer >= auto_quit_duration:
			get_tree().quit(0)
			return

	if attack_event_timer > 0.0:
		attack_event_timer -= delta
		if attack_event_timer <= 0.0:
			last_attack_event = "None"
	if super_event_timer > 0.0:
		super_event_timer -= delta
		if super_event_timer <= 0.0:
			last_super_event = "None"

	if not puppet:
		return

	var anim: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
	var visuals: Node2D = puppet.find_child("Visuals", true, false)

	match current_mode:
		Mode.IN_PLACE_WALK:
			puppet.position = Vector2(576, base_ground_y)
			if visuals:
				visuals.scale.x = 1.0
			if anim and anim.current_animation != "walk":
				anim.play("walk")

		Mode.IN_PLACE_RUN:
			puppet.position = Vector2(576, base_ground_y)
			if visuals:
				visuals.scale.x = 1.0
			if anim and anim.current_animation != "run":
				anim.play("run")

		Mode.WALK_FORWARD:
			puppet.position.x += walk_speed * delta
			puppet.position.y = base_ground_y
			if visuals:
				visuals.scale.x = 1.0
			if anim and anim.current_animation != "walk":
				anim.play("walk")

			# Screen wrap
			if puppet.position.x > 1050:
				puppet.position.x = 100

		Mode.RUN_FORWARD:
			puppet.position.x += run_speed * delta
			puppet.position.y = base_ground_y
			if visuals:
				visuals.scale.x = 1.0
			if anim and anim.current_animation != "run":
				anim.play("run")

			# Screen wrap
			if puppet.position.x > 1050:
				puppet.position.x = 100

		Mode.LOCOMOTION_DEMO:
			_process_locomotion_demo(delta)

		Mode.JUMP_DEMO:
			_process_jump_demo(delta)

		Mode.ATTACK_DEMO:
			_process_attack_demo(delta)

		Mode.PROJECTILE_DEMO:
			_process_projectile_demo(delta)

		Mode.SUPER_DEMO:
			_process_super_demo(delta)

		Mode.AUDIO_PREVIEW:
			_process_audio_preview_mode(delta)

		Mode.INTERACTIVE:
			_process_interactive_input()

	_update_stats()

func _process_interactive_input() -> void:
	var input_x = 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_x -= 1.0

	var run_pressed = Input.is_key_pressed(KEY_SHIFT)
	var jump_pressed = Input.is_key_pressed(KEY_SPACE) or Input.is_action_just_pressed("ui_accept")
	var attack_pressed = Input.is_key_pressed(KEY_J) or Input.is_action_just_pressed("ui_select")
	var super_pressed = Input.is_key_pressed(KEY_L)

	if "input_dir" in puppet:
		puppet.input_dir = input_x
	if "wants_run" in puppet:
		puppet.wants_run = run_pressed
	if "wants_jump" in puppet and jump_pressed:
		puppet.wants_jump = true
	if "wants_attack" in puppet and attack_pressed:
		puppet.wants_attack = true
	if "wants_super" in puppet and super_pressed:
		puppet.wants_super = true

	# Keep puppet on screen
	if puppet.position.x < 80:
		puppet.position.x = 80
		puppet.velocity.x = 0
	elif puppet.position.x > 1072:
		puppet.position.x = 1072
		puppet.velocity.x = 0

func _process_locomotion_demo(delta: float) -> void:
	demo_timer += delta
	var t = fmod(demo_timer, demo_cycle_duration)

	var inp = 0.0
	var run = false

	if t >= 0.6 and t < 1.4:
		inp = 1.0
		run = false
	elif t >= 1.4 and t < 2.4:
		inp = 1.0
		run = true
	elif t >= 2.4 and t < 3.2:
		inp = 0.0
		run = false
	elif t >= 3.2 and t < 4.0:
		inp = 1.0
		run = false
	elif t >= 4.0 and t < 4.6:
		inp = 1.0
		run = true
	elif t >= 4.6 and t < 6.0:
		inp = -1.0
		run = true
	elif t >= 6.0:
		inp = 0.0
		run = false

	if "input_dir" in puppet:
		puppet.input_dir = inp
	if "wants_run" in puppet:
		puppet.wants_run = run

	# Re-center puppet if near edges
	if puppet.position.x < 150:
		puppet.position.x = 150
	elif puppet.position.x > 1000:
		puppet.position.x = 1000

func _process_jump_demo(delta: float) -> void:
	jump_demo_timer += delta
	var t = fmod(jump_demo_timer, jump_demo_duration)

	# Deterministic Stage 3 Demonstration:
	# IDLE -> JUMP -> FALL -> LAND -> WALK -> JUMP -> LAND -> RUN -> JUMP -> LAND -> STOP -> IDLE
	var inp = 0.0
	var run = false
	var jump = false

	if t < 0.5:
		# IDLE
		inp = 0.0
		run = false
	elif t >= 0.5 and t < 0.55:
		# Trigger standing jump
		jump = true
		inp = 0.0
	elif t >= 0.55 and t < 1.6:
		# In air / land into idle
		inp = 0.0
	elif t >= 1.6 and t < 2.5:
		# WALK right
		inp = 1.0
		run = false
	elif t >= 2.5 and t < 2.55:
		# Trigger walking jump
		jump = true
		inp = 1.0
		run = false
	elif t >= 2.55 and t < 3.7:
		# Walking jump in air / land into walk
		inp = 1.0
		run = false
	elif t >= 3.7 and t < 4.6:
		# RUN right
		inp = 1.0
		run = true
	elif t >= 4.6 and t < 4.65:
		# Trigger running jump
		jump = true
		inp = 1.0
		run = true
	elif t >= 4.65 and t < 5.8:
		# Running jump in air / land into run
		inp = 1.0
		run = true
	elif t >= 5.8 and t < 6.5:
		# STOP (momentum brake)
		inp = 0.0
		run = false
	elif t >= 6.5:
		# IDLE settle
		inp = 0.0
		run = false

	if "input_dir" in puppet:
		puppet.input_dir = inp
	if "wants_run" in puppet:
		puppet.wants_run = run
	if "wants_jump" in puppet and jump:
		puppet.wants_jump = true

	# Re-center puppet if near edges
	if puppet.position.x < 150:
		puppet.position.x = 150
	elif puppet.position.x > 1000:
		puppet.position.x = 1000

func _process_attack_demo(delta: float) -> void:
	attack_demo_timer += delta
	var t = fmod(attack_demo_timer, attack_demo_duration)

	# Continuous Combat Sequence:
	# 1. Standing Attack (0.0s - 1.4s)
	# 2. Walking Attack (1.4s - 3.2s)
	# 3. Running Attack (3.2s - 5.0s)
	# 4. Rapid Combo Attacks (5.0s - 6.8s)
	# 5. Hit Interruption (6.8s - 8.4s)
	var inp = 0.0
	var run = false
	var atk = false
	var hit = false

	if t < 0.4:
		inp = 0.0
	elif t >= 0.4 and t < 0.45:
		atk = true
	elif t >= 0.45 and t < 1.4:
		inp = 0.0
	elif t >= 1.4 and t < 2.0:
		inp = 1.0 # Start walking
	elif t >= 2.0 and t < 2.05:
		inp = 1.0
		atk = true # Walking attack
	elif t >= 2.05 and t < 3.2:
		inp = 1.0 # Continue walking
	elif t >= 3.2 and t < 3.8:
		inp = 1.0
		run = true # Sprint
	elif t >= 3.8 and t < 3.85:
		inp = 1.0
		run = true
		atk = true # Running attack
	elif t >= 3.85 and t < 4.8:
		inp = 1.0
		run = true
	elif t >= 4.8 and t < 5.0:
		inp = 0.0 # Stop & turn back left
	elif t >= 5.0 and t < 5.05:
		atk = true # Combo hit 1
	elif t >= 5.35 and t < 5.40:
		atk = true # Combo hit 2
	elif t >= 5.70 and t < 5.75:
		atk = true # Combo hit 3
	elif t >= 6.4 and t < 6.8:
		inp = 0.0
	elif t >= 6.8 and t < 6.85:
		atk = true # Start attack
	elif t >= 6.98 and t < 7.02:
		hit = true # Interrupt mid-attack!
	elif t >= 7.02:
		inp = 0.0

	if "input_dir" in puppet:
		puppet.input_dir = inp
	if "wants_run" in puppet:
		puppet.wants_run = run
	if "wants_attack" in puppet and atk:
		puppet.wants_attack = true
	if "wants_hit" in puppet and hit:
		puppet.wants_hit = true

	# Screen wrap/re-center
	if puppet.position.x < 150:
		puppet.position.x = 150
	elif puppet.position.x > 1000:
		puppet.position.x = 1000

func _process_projectile_demo(delta: float) -> void:
	projectile_demo_timer += delta
	var t = fmod(projectile_demo_timer, projectile_demo_duration)

	# 5-Phase Projectile Combat Showcase:
	# Phase 1 (0.0s - 1.6s): Standing throw towards target dummy at x=880
	# Phase 2 (1.6s - 3.4s): Walk forward throw
	# Phase 3 (3.4s - 5.0s): Sprint throw with momentum
	# Phase 4 (5.0s - 6.6s): Turn left & throw into open space (max range despawn)
	# Phase 5 (6.6s - 8.5s): Rapid double shuriken combo into target dummy
	var inp = 0.0
	var run = false
	var atk = false

	if t < 0.3:
		inp = 0.0
	elif t >= 0.3 and t < 0.35:
		# Standing throw
		atk = true
	elif t >= 0.35 and t < 1.6:
		inp = 0.0
	elif t >= 1.6 and t < 2.2:
		# Walk forward
		inp = 1.0
	elif t >= 2.2 and t < 2.25:
		# Walking throw
		inp = 1.0
		atk = true
	elif t >= 2.25 and t < 3.4:
		inp = 1.0
	elif t >= 3.4 and t < 3.9:
		# Sprint forward
		inp = 1.0
		run = true
	elif t >= 3.9 and t < 3.95:
		# Running throw
		inp = 1.0
		run = true
		atk = true
	elif t >= 3.95 and t < 4.8:
		inp = 1.0
		run = true
	elif t >= 4.8 and t < 5.0:
		inp = 0.0 # Decelerate
	elif t >= 5.0 and t < 5.6:
		inp = -1.0 # Turn and walk left
	elif t >= 5.6 and t < 5.65:
		inp = -1.0 # Throw leftwards into distance (range test)
		atk = true
	elif t >= 5.65 and t < 6.6:
		inp = 0.0
	elif t >= 6.6 and t < 7.0:
		inp = 1.0 # Turn back right towards dummy
	elif t >= 7.0 and t < 7.05:
		inp = 0.0
		atk = true # Rapid combo throw 1
	elif t >= 7.35 and t < 7.40:
		inp = 0.0
		atk = true # Rapid combo throw 2
	elif t >= 7.40:
		inp = 0.0

	if "input_dir" in puppet:
		puppet.input_dir = inp
	if "wants_run" in puppet:
		puppet.wants_run = run
	if "wants_attack" in puppet and atk:
		puppet.wants_attack = true

	# Keep puppet positioned well in relation to dummy (dummy is at 880)
	if puppet.position.x < 120:
		puppet.position.x = 120
	elif puppet.position.x > 750:
		puppet.position.x = 750

func _process_super_demo(delta: float) -> void:
	super_demo_timer += delta
	var t = fmod(super_demo_timer, super_demo_duration)

	# Super Showcase Sequence:
	# 0.0s - 0.5s: IDLE
	# 0.5s: Activate Super (Ghost fade 1.0 -> 0.08)
	# 0.8s - 2.2s: Invisible Walk Right
	# 2.2s - 3.4s: Invisible Run Right
	# 3.4s - 3.45s: Invisible Jump!
	# 3.45s - 4.8s: Invisible Air / Land / Run
	# 4.8s - 5.4s: Invisible Turn Left
	# 5.4s - 5.7s: Invisible Settle
	# 5.7s - 5.9s: Natural Super Expiry (Ghost fade 0.08 -> 1.0)
	# 5.9s - 6.5s: Visible IDLE
	# 6.5s: Activate Super again
	# 6.8s - 7.3s: Invisible Walk Right
	# 7.3s: Attack pressed -> CANCELS Super immediately, becomes visible, throws 4 blades!
	# 7.3s - 8.5s: Projectiles hit dummy at x=880
	# 8.5s - 10.0s: IDLE settle
	var inp = 0.0
	var run = false
	var jump = false
	var atk = false
	var sup = false

	if t < 0.5:
		inp = 0.0
	elif t >= 0.5 and t < 0.55:
		sup = true
	elif t >= 0.55 and t < 0.8:
		inp = 0.0
	elif t >= 0.8 and t < 2.2:
		inp = 1.0
	elif t >= 2.2 and t < 3.4:
		inp = 1.0
		run = true
	elif t >= 3.4 and t < 3.45:
		inp = 1.0
		run = true
		jump = true
	elif t >= 3.45 and t < 4.8:
		inp = 1.0
		run = true
	elif t >= 4.8 and t < 5.4:
		inp = -1.0
	elif t >= 5.4 and t < 6.5:
		inp = 0.0
	elif t >= 6.5 and t < 6.55:
		sup = true
	elif t >= 6.55 and t < 6.8:
		inp = 0.0
	elif t >= 6.8 and t < 7.3:
		inp = 1.0
	elif t >= 7.3 and t < 7.35:
		inp = 0.0
		atk = true
	elif t >= 7.35:
		inp = 0.0

	if "input_dir" in puppet:
		puppet.input_dir = inp
	if "wants_run" in puppet:
		puppet.wants_run = run
	if "wants_jump" in puppet and jump:
		puppet.wants_jump = true
	if "wants_attack" in puppet and atk:
		puppet.wants_attack = true
	if "wants_super" in puppet and sup:
		puppet.wants_super = true

	# Boundary constraint relative to dummy (x=880)
	if puppet.position.x < 150:
		puppet.position.x = 150
	elif puppet.position.x > 750:
		puppet.position.x = 750

func set_mode(m: Mode) -> void:
	current_mode = m
	if m in [Mode.INTERACTIVE, Mode.LOCOMOTION_DEMO, Mode.JUMP_DEMO, Mode.ATTACK_DEMO, Mode.PROJECTILE_DEMO, Mode.SUPER_DEMO, Mode.AUDIO_PREVIEW]:
		if puppet and puppet.has_method("set_physics_process"):
			puppet.set_physics_process(true)
	else:
		if puppet and puppet.has_method("set_physics_process"):
			puppet.set_physics_process(false)
		var anim: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
		if anim:
			if m == Mode.IN_PLACE_RUN or m == Mode.RUN_FORWARD:
				anim.play("run")
			else:
				anim.play("walk")
	if m == Mode.IN_PLACE_WALK or m == Mode.IN_PLACE_RUN:
		puppet.position = Vector2(576, base_ground_y)
	elif m == Mode.PROJECTILE_DEMO:
		puppet.position = Vector2(360, base_ground_y)
		reset_target_dummy()
	elif m == Mode.SUPER_DEMO:
		puppet.position = Vector2(280, base_ground_y)
		reset_target_dummy()
	elif m == Mode.AUDIO_PREVIEW:
		puppet.position = Vector2(360, base_ground_y)
		audio_preview_timer = 0.0
		audio_preview_step = 0
		reset_target_dummy()
		if puppet.has_method("change_state"):
			puppet.change_state(puppet.State.IDLE)
	_update_ui()

# Synchronized Audio-Visual Presentation Sequence
# Every sound is triggered strictly via the character's animation frames and state transitions!
func _process_audio_preview_mode(delta: float) -> void:
	audio_preview_timer += delta
	var cycle_len = 9.6
	var t = fmod(audio_preview_timer, cycle_len)

	var inp = 0.0
	var run = false
	var atk = false
	var jmp = false
	var sup = false

	# Phase 1 (0.0s - 1.6s): Attack with authentic throwing SFX & reload
	if t >= 0.50 and t < 0.55:
		atk = true
	# Phase 2 (1.6s - 3.2s): Jump & Land with authentic common SFX
	elif t >= 2.0 and t < 2.05:
		jmp = true
	# Phase 3 (3.2s - 5.8s): Super Invisibility with authentic invisibility vanish SFX & VO
	elif t >= 3.4 and t < 3.45:
		sup = true
	elif t >= 3.6 and t < 4.8:
		inp = 1.0 # Walk invisibly across stage
	elif t >= 4.8 and t < 5.2:
		inp = 0.0
	elif t >= 5.2 and t < 5.25:
		# Attack while invisible to demonstrate uncloak SFX + combat break!
		atk = true
	# Phase 4 (5.8s - 7.2s): Super Invisibility Natural Expiry & Decloak SFX
	elif t >= 6.2 and t < 6.25:
		sup = true # Second Super activation
	elif t >= 6.8 and t < 6.85:
		if puppet and "super_timer" in puppet:
			puppet.super_timer = 0.01 # Fast-forward to natural uncloak SFX
	# Phase 5 (7.2s - 8.4s): Hit Recoil and Hurt VO
	elif t >= 7.6 and t < 7.65:
		if puppet and puppet.has_method("trigger_hit"):
			puppet.trigger_hit()
	# Phase 6 (8.4s - 9.6s): Authentic Start / Leading VO Line
	elif t >= 8.6 and t < 8.65:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").trigger_event("START")

	if "input_dir" in puppet:
		puppet.input_dir = inp
	if "wants_run" in puppet:
		puppet.wants_run = run
	if "wants_attack" in puppet and atk:
		puppet.wants_attack = true
	if "wants_jump" in puppet and jmp:
		puppet.wants_jump = true
	if "wants_super" in puppet and sup:
		puppet.wants_super = true

	# Keep puppet in good view
	if puppet.position.x < 180:
		puppet.position.x = 180
	elif puppet.position.x > 750:
		puppet.position.x = 750

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_mode(Mode.IN_PLACE_WALK)
			KEY_2:
				set_mode(Mode.IN_PLACE_RUN)
			KEY_3:
				set_mode(Mode.LOCOMOTION_DEMO)
			KEY_4:
				set_mode(Mode.JUMP_DEMO)
			KEY_5:
				set_mode(Mode.PROJECTILE_DEMO)
			KEY_6:
				set_mode(Mode.SUPER_DEMO)
			KEY_7:
				set_mode(Mode.AUDIO_PREVIEW)
			KEY_8:
				set_mode(Mode.INTERACTIVE)
			KEY_J:
				trigger_attack()
			KEY_L, KEY_U:
				trigger_super()
			KEY_SPACE:
				trigger_jump()
			KEY_K:
				trigger_hit()
			KEY_M:
				toggle_audio_mute()

func toggle_audio_mute() -> void:
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.toggle_mute()
		_update_stats()

func reset_target_dummy() -> void:
	if dummy and dummy.has_method("reset_dummy"):
		dummy.reset_dummy()

func trigger_jump() -> void:
	if puppet and "wants_jump" in puppet:
		puppet.wants_jump = true

func trigger_attack() -> void:
	if puppet and "wants_attack" in puppet:
		puppet.wants_attack = true

func trigger_super() -> void:
	if puppet and "wants_super" in puppet:
		puppet.wants_super = true

func trigger_hit() -> void:
	if puppet and "wants_hit" in puppet:
		puppet.wants_hit = true

func toggle_ground_line() -> void:
	show_ground_line = not show_ground_line
	if ground_line:
		ground_line.visible = show_ground_line

func set_anim_speed(scale: float) -> void:
	if puppet:
		var anim: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
		if anim:
			anim.speed_scale = scale

func _update_ui() -> void:
	if not mode_label:
		return
	match current_mode:
		Mode.IN_PLACE_WALK:
			mode_label.text = "MODE: Walk In Place (Stationary Stride)"
			mode_label.modulate = Color(0.3, 0.85, 1.0)
		Mode.IN_PLACE_RUN:
			mode_label.text = "MODE: Run In Place (Stationary Sprint)"
			mode_label.modulate = Color(1.0, 0.55, 0.2)
		Mode.WALK_FORWARD:
			mode_label.text = "MODE: Walk Forward (160 px/s Synchronized)"
			mode_label.modulate = Color(0.4, 0.95, 0.5)
		Mode.RUN_FORWARD:
			mode_label.text = "MODE: Run Forward (300 px/s Synchronized)"
			mode_label.modulate = Color(1.0, 0.85, 0.2)
		Mode.LOCOMOTION_DEMO:
			mode_label.text = "MODE: Locomotion Demo (IDLE->WALK->RUN->STOP->TURN)"
			mode_label.modulate = Color(0.85, 0.65, 1.0)
		Mode.JUMP_DEMO:
			mode_label.text = "MODE: Jump Demo (Standing/Walking/Running Jumps -> Land -> Stop)"
			mode_label.modulate = Color(0.35, 1.0, 0.75)
		Mode.ATTACK_DEMO:
			mode_label.text = "MODE: Combat Demo (Standing/Moving/Rapid Attacks -> Interruption)"
			mode_label.modulate = Color(1.0, 0.35, 0.45)
		Mode.PROJECTILE_DEMO:
			mode_label.text = "MODE: Projectile Demo (4-Blade Spinner Burst • Real Collision • Target Recoil • Despawn)"
			mode_label.modulate = Color(0.15, 0.95, 0.85)
		Mode.SUPER_DEMO:
			mode_label.text = "MODE: Super Demo (Invisibility • Full Locomotion • Expiry • Attack Interrupt)"
			mode_label.modulate = Color(0.65, 0.45, 1.0)
		Mode.AUDIO_PREVIEW:
			mode_label.text = "MODE: Synchronized Audio Showcase (Authentic Attack SFX • Super Invisibility SFX & VO • Jump/Land SFX • Reload)"
			mode_label.modulate = Color(1.0, 0.45, 0.85)
		Mode.INTERACTIVE:
			mode_label.text = "MODE: Interactive (A/D = Move, Shift = Run, Space = Jump, J = Attack, L = Super, M = Mute)"
			mode_label.modulate = Color(1.0, 0.85, 0.4)

func _update_stats() -> void:
	if not stats_label or not puppet:
		return

	var anim: AnimationPlayer = puppet.find_child("AnimPlayer", true, false)
	var a_name = anim.current_animation if anim else "None"
	var a_pos = anim.current_animation_position if anim else 0.0
	var a_len = anim.current_animation_length if anim else 0.0

	var state_str = "N/A"
	if "current_state" in puppet and "STATE_NAMES" in puppet:
		state_str = puppet.STATE_NAMES.get(puppet.current_state, str(puppet.current_state))

	var super_str = "NONE"
	var super_time_left = 0.0
	var is_vis_str = "TRUE (100%)"
	if "super_state" in puppet and "SUPER_STATE_NAMES" in puppet:
		super_str = puppet.SUPER_STATE_NAMES.get(puppet.super_state, str(puppet.super_state))
	if "super_timer" in puppet:
		super_time_left = puppet.super_timer
	if "is_super_visible" in puppet:
		is_vis_str = "TRUE (100%)" if puppet.is_super_visible else "GHOST (8%)"

	var vel_x = puppet.velocity.x if "velocity" in puppet else 0.0
	var vel_y = puppet.velocity.y if "velocity" in puppet else 0.0
	var facing_str = "RIGHT (+1)"
	if "facing_direction" in puppet:
		facing_str = "RIGHT (+1)" if puppet.facing_direction > 0 else "LEFT (-1)"

	var active_projs = get_tree().get_nodes_in_group("projectiles").size()
	var spawn_str = "%.2fs (BLADES: 4)" % last_projectile_spawn_time if last_projectile_spawn_time >= 0.0 else "None"
	var hit_str = "%.2fs (DMG: %.0f)" % [last_hit_time, last_hit_damage] if last_hit_time >= 0.0 else "None"
	var dummy_hp_str = "%d / %d" % [int(dummy.current_hp), int(dummy.max_hp)] if dummy else "N/A"

	var last_audio_ev = "None"
	var last_audio_fl = "None"
	var is_muted_str = "ACTIVE"
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		last_audio_ev = am.last_audio_event
		last_audio_fl = am.last_audio_file
		is_muted_str = "MUTED" if am.is_muted else "ACTIVE"

	stats_label.text = "STATE: %s | SUPER: %s (%.2fs) | VISIBILITY: %s | FACING: %s | GROUNDED: %s\nANIM: %s (%.2fs/%.2fs) | PROJS: %d | LAST SPAWN: %s | LAST HIT: %s | TARGET HP: %s\nLAST AUDIO EVENT: %s | LAST AUDIO FILE: %s | SFX: %s\nSUPER EVENT: %s | BURST RATE: 33 Hz | RANGE: 550 px | VEL: (%+.1f, %+.1f) px/s" % [
		state_str, super_str, super_time_left, is_vis_str, facing_str, "TRUE" if puppet.is_grounded() else "FALSE",
		a_name, a_pos, a_len, active_projs, spawn_str, hit_str, dummy_hp_str,
		last_audio_ev, last_audio_fl, is_muted_str,
		last_super_event,
		vel_x, vel_y
	]
