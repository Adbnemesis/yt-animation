extends Node2D

# Bo Brawler Standalone Test Arena Controller
# Provides interactive controls, telemetry overlay, and 20-cycle automated validation.

enum Mode {
	INTERACTIVE,
	AUTOMATED_CYCLE
}

@onready var bo: BrawlerBase = $BrawlerBo
@onready var lbl_mode: Label = get_node_or_null("UI/Panel/VBox/LblMode")
@onready var lbl_state: Label = get_node_or_null("UI/Panel/VBox/LblState")
@onready var lbl_health: Label = get_node_or_null("UI/Panel/VBox/LblHealth")
@onready var lbl_expr: Label = get_node_or_null("UI/Panel/VBox/LblExpr")
@onready var lbl_telemetry: Label = get_node_or_null("UI/Panel/VBox/LblTelemetry")
@onready var lbl_controls: Label = get_node_or_null("UI/Panel/VBox/LblControls")

var current_mode: Mode = Mode.INTERACTIVE
var time_elapsed: float = 0.0

# Telemetry
var last_event: String = "None"
var events_count: int = 0
var cycles_completed: int = 0
var cycle_phase: int = 0
var cycle_timer: float = 0.0

const EXPRESSIONS: Array[String] = [
	"serious", "neutral", "angry", "happy", "shocked",
	"scared", "hurt", "confused", "smug", "sad"
]
var expr_index: int = 0

var interactive_control: bool = true

func _ready() -> void:
	if bo:
		bo.game_event_emitted.connect(_on_game_event)
		bo.state_changed.connect(_on_state_changed)
	_update_ui()

func _physics_process(delta: float) -> void:
	time_elapsed += delta

	if interactive_control:
		if current_mode == Mode.INTERACTIVE:
			_process_interactive(delta)
		elif current_mode == Mode.AUTOMATED_CYCLE:
			_process_automated_cycle(delta)

	_update_ui()

func _process_interactive(_delta: float) -> void:
	if not bo:
		return

	var move_dir := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir += 1.0

	var sprint = Input.is_key_pressed(KEY_SHIFT)
	bo.move(move_dir, sprint)

	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_SPACE):
		bo.jump()

	if Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_ENTER):
		bo.attack()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	var key = event.as_text_key_label()

	# Mode toggle
	if key == "Tab":
		if current_mode == Mode.INTERACTIVE:
			current_mode = Mode.AUTOMATED_CYCLE
			cycle_phase = 0
			cycle_timer = 0.0
		else:
			current_mode = Mode.INTERACTIVE
		return

	if not bo:
		return

	# Combat simulation
	if key == "H":
		# Light hit
		var hit_res = RefCounted.new()
		hit_res.set("damage", 120.0)
		hit_res.set("force", 100.0)
		hit_res.set("direction", Vector2(-1.0, -0.2))
		bo.take_hit(hit_res)
	elif key == "K":
		# Heavy knockback hit
		var hit_res = RefCounted.new()
		hit_res.set("damage", 250.0)
		hit_res.set("force", 250.0)
		hit_res.set("direction", Vector2(-1.0, -0.4))
		bo.take_hit(hit_res)
	elif key == "X":
		bo.on_death()
	elif key == "R":
		_reset_bo()
	elif key == "E":
		# Cycle expression
		expr_index = (expr_index + 1) % EXPRESSIONS.size()
		bo.set_expression(EXPRESSIONS[expr_index])
	elif key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]:
		var idx = (key.to_int() - 1 + 10) % 10
		expr_index = idx
		bo.set_expression(EXPRESSIONS[idx])

func _process_automated_cycle(delta: float) -> void:
	cycle_timer += delta

	# 6-phase validation cycle:
	# Phase 0 (0.0s - 0.4s): Idle
	# Phase 1 (0.4s - 0.9s): Walk Right
	# Phase 2 (0.9s - 1.4s): Run Left
	# Phase 3 (1.4s - 1.9s): Jump
	# Phase 4 (1.9s - 2.4s): Attack
	# Phase 5 (2.4s - 2.8s): Hit Recoil -> Reset
	match cycle_phase:
		0:
			bo.move(0.0, false)
			if cycle_timer >= 0.4:
				cycle_phase = 1
		1:
			bo.move(1.0, false)
			if cycle_timer >= 0.9:
				cycle_phase = 2
		2:
			bo.move(-1.0, true)
			if cycle_timer >= 1.4:
				cycle_phase = 3
		3:
			bo.move(0.0, false)
			bo.jump()
			if cycle_timer >= 1.9:
				cycle_phase = 4
		4:
			bo.attack()
			if cycle_timer >= 2.4:
				cycle_phase = 5
				var hit_res = RefCounted.new()
				hit_res.set("damage", 50.0)
				hit_res.set("force", 80.0)
				hit_res.set("direction", Vector2(-1.0, 0.0))
				bo.take_hit(hit_res)
		5:
			if cycle_timer >= 2.8:
				cycles_completed += 1
				cycle_phase = 0
				cycle_timer = 0.0
				# Cycle expression each test loop
				expr_index = (expr_index + 1) % EXPRESSIONS.size()
				bo.set_expression(EXPRESSIONS[expr_index])

func _reset_bo() -> void:
	bo.position = Vector2(0, 0)
	bo.velocity = Vector2.ZERO
	if bo.hit_receiver and bo.config:
		bo.hit_receiver.configure(bo.config.max_health, bo.config.knockback_resistance)
	if bo.movement_controller:
		bo.movement_controller.change_state(BrawlerMovementController.State.IDLE)
	bo.set_expression("serious")

func _on_game_event(event_name: String, _data: Dictionary) -> void:
	last_event = event_name
	events_count += 1

func _on_state_changed(_old_s: String, _new_s: String) -> void:
	pass

func _update_ui() -> void:
	if not lbl_mode:
		return

	var m_text = "INTERACTIVE (WASD/Arrows, Shift, Space, J, H, K, X, 1-0)" if current_mode == Mode.INTERACTIVE else "AUTOMATED 20-CYCLE TEST"
	lbl_mode.text = "Mode: %s [TAB to toggle]" % m_text

	if bo and bo.movement_controller:
		var s_name = BrawlerMovementController.State.keys()[bo.movement_controller.current_state]
		lbl_state.text = "State: %s | Facing: %s | Vel: (%.0f, %.0f)" % [
			s_name,
			"RIGHT (+1)" if bo.facing_direction == 1 else "LEFT (-1)",
			bo.velocity.x,
			bo.velocity.y
		]

	if bo and bo.hit_receiver:
		lbl_health.text = "Health: %.0f / %.0f | Alive: %s" % [
			bo.hit_receiver.current_health,
			bo.hit_receiver.max_health,
			str(bo.hit_receiver.current_health > 0.0)
		]

	if bo and bo.face_controller:
		lbl_expr.text = "Expression: %s | Eyes: %s [E to cycle, 1-0 direct]" % [
			bo.face_controller.current_expression,
			bo.face_controller.current_eye_state
		]

	if lbl_telemetry:
		lbl_telemetry.text = "Events: %d (Last: %s) | Cycles: %d | Time: %.1fs" % [
			events_count,
			last_event,
			cycles_completed,
			time_elapsed
		]
