extends Node2D

# Three Brawler Showcase & Test Controller
# Coordinates Leon, Nita, and Bo together to validate visual harmony,
# paper-cutout style consistency, skeleton proportions, and locomotion.

@onready var leon: Node = get_node_or_null("LeonBrawler")
@onready var nita: Node = get_node_or_null("NitaBrawler")
@onready var bo: Node = get_node_or_null("BrawlerBo")
@onready var lbl_info: Label = get_node_or_null("UI/Panel/VBox/LblInfo")

var auto_cycle: bool = true
var cycle_timer: float = 0.0
var current_step: int = 0
var expr_index: int = 0

const COMMON_EXPRESSIONS: Array[String] = [
	"neutral", "happy", "angry", "sad", "shocked", "hurt"
]

func _ready() -> void:
	_update_ui("Automated Showcase Active (Synchronizing Leon, Nita, Bo)")

func _physics_process(delta: float) -> void:
	if not auto_cycle:
		return

	cycle_timer += delta

	# Cycle sequence:
	# 0.0s - 1.5s: Idle
	# 1.5s - 3.0s: Walk forward
	# 3.0s - 4.5s: Run forward
	# 4.5s - 5.5s: Jump
	# 5.5s - 7.0s: Attack
	# 7.0s - 8.0s: Hit reaction
	# 8.0s+: Reset cycle
	if cycle_timer < 1.5:
		if current_step != 0:
			current_step = 0
			_all_move(0.0, false)
			_all_expression(COMMON_EXPRESSIONS[expr_index])
			_update_ui("Phase: IDLE (Stance & Breathing)")
	elif cycle_timer < 3.0:
		if current_step != 1:
			current_step = 1
			_all_move(1.0, false)
			_update_ui("Phase: WALK (Grounded Locomotion)")
	elif cycle_timer < 4.5:
		if current_step != 2:
			current_step = 2
			_all_move(1.0, true)
			_update_ui("Phase: RUN (Athletic Sprint)")
	elif cycle_timer < 5.5:
		if current_step != 3:
			current_step = 3
			_all_move(0.0, false)
			_all_jump()
			_update_ui("Phase: JUMP (Vertical Leap)")
	elif cycle_timer < 7.0:
		if current_step != 4:
			current_step = 4
			_all_attack()
			_update_ui("Phase: ATTACK (Signatures: Shurikens, Shockwave, Bow)")
	elif cycle_timer < 8.0:
		if current_step != 5:
			current_step = 5
			_all_hit()
			_update_ui("Phase: HIT (Recoil & Damage Reaction)")
	else:
		cycle_timer = 0.0
		current_step = -1
		expr_index = (expr_index + 1) % COMMON_EXPRESSIONS.size()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	var key = event.as_text_key_label()

	if key == "Tab":
		auto_cycle = not auto_cycle
		cycle_timer = 0.0
		_update_ui("Auto-cycle: " + ("ON" if auto_cycle else "OFF (Manual Keys: 1-7, E)"))
	elif key == "1":
		auto_cycle = false
		_all_move(0.0, false)
		_update_ui("Manual: IDLE")
	elif key == "2":
		auto_cycle = false
		_all_move(1.0, false)
		_update_ui("Manual: WALK")
	elif key == "3":
		auto_cycle = false
		_all_move(1.0, true)
		_update_ui("Manual: RUN")
	elif key == "4":
		auto_cycle = false
		_all_jump()
		_update_ui("Manual: JUMP")
	elif key == "5":
		auto_cycle = false
		_all_attack()
		_update_ui("Manual: ATTACK")
	elif key == "6":
		auto_cycle = false
		_all_hit()
		_update_ui("Manual: HIT")
	elif key == "E":
		expr_index = (expr_index + 1) % COMMON_EXPRESSIONS.size()
		_all_expression(COMMON_EXPRESSIONS[expr_index])
		_update_ui("Expression: " + COMMON_EXPRESSIONS[expr_index])

func _all_move(dir: float, sprint: bool) -> void:
	for b in [leon, nita, bo]:
		if b and b.has_method("move"):
			b.move(dir, sprint)

func _all_jump() -> void:
	for b in [leon, nita, bo]:
		if b and b.has_method("jump"):
			b.jump()

func _all_attack() -> void:
	for b in [leon, nita, bo]:
		if b and b.has_method("attack"):
			b.attack()

func _all_hit() -> void:
	var hit_res = RefCounted.new()
	hit_res.set("damage", 100.0)
	hit_res.set("force", 120.0)
	hit_res.set("direction", Vector2(-1.0, 0.0))
	for b in [leon, nita, bo]:
		if b and b.has_method("take_hit"):
			b.take_hit(hit_res)

func _all_expression(expr: String) -> void:
	for b in [leon, nita, bo]:
		if b and b.has_method("set_expression"):
			b.set_expression(expr)

func _update_ui(text: String) -> void:
	if lbl_info:
		lbl_info.text = text
