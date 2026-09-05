class_name FaceControllerNitaBrawler
extends FaceControllerBase

# Nita Face Controller — Brawler Framework Compatible
# Extends FaceControllerBase so BrawlerBase can use the standard interface.
# Contains Nita-specific texture maps and expression logic from the production rig.
# Does NOT modify the standalone FaceControllerNita used in video production.

# Override the base class texture dictionaries with Nita's authentic assets
func _ready() -> void:
	# Nita mouth textures
	mouth_textures = {
		"neutral": preload("res://assets/nita/face/mouth_neutral.svg"),
		"grin": preload("res://assets/nita/face/mouth_grin.svg"),
		"happy": preload("res://assets/nita/face/mouth_happy.svg"),
		"angry": preload("res://assets/nita/face/mouth_angry.svg"),
		"shocked": preload("res://assets/nita/face/mouth_shocked.svg"),
		"hurt": preload("res://assets/nita/face/mouth_hurt.svg"),
		"smug": preload("res://assets/nita/face/mouth_grin.svg"),
		"sad": preload("res://assets/nita/face/mouth_neutral.svg")
	}

	# Nita eye textures (base class uses a single dictionary for both eyes)
	eye_textures = {
		"open": preload("res://assets/nita/face/eye_L.svg"),
		"blink": preload("res://assets/nita/face/eyes_blink.svg"),
		"closed": preload("res://assets/nita/face/eyes_blink.svg"),
		"happy": preload("res://assets/nita/face/eyes_happy.svg"),
		"wide": preload("res://assets/nita/face/eyes_wide.svg"),
		"angry": preload("res://assets/nita/face/eyes_angry.svg")
	}

	# Nita's right eye textures (for asymmetric eyes)
	_eye_textures_r = {
		"open": preload("res://assets/nita/face/eye_R.svg"),
		"blink": preload("res://assets/nita/face/eyes_blink.svg"),
		"closed": preload("res://assets/nita/face/eyes_blink.svg"),
		"happy": preload("res://assets/nita/face/eyes_happy.svg"),
		"wide": preload("res://assets/nita/face/eyes_wide.svg"),
		"angry": preload("res://assets/nita/face/eyes_angry.svg")
	}

	default_expression = "grin"
	default_eye_state = "open"

	# Call parent _ready after textures are configured
	super._ready()

# Nita has asymmetric eyes (different L/R textures), so override the base eye application
var _eye_textures_r: Dictionary = {}

func _apply_eye_state(state: String) -> void:
	if not eye_textures.has(state):
		return

	var tex_l = eye_textures[state]
	if eye_l and eye_l is Sprite2D:
		eye_l.texture = tex_l

	# Use right-eye specific texture if available, otherwise mirror left
	var tex_r = _eye_textures_r.get(state, tex_l) if _eye_textures_r.size() > 0 else tex_l
	if eye_r and eye_r is Sprite2D:
		eye_r.texture = tex_r

	var hide_pupils = (state in ["blink", "closed"])
	if pupil_l: pupil_l.visible = not hide_pupils
	if pupil_r: pupil_r.visible = not hide_pupils

# Override set_expression to add Nita-specific expression→eye linkage
func set_expression(expr: String) -> void:
	_ensure_nodes()
	current_expression = expr

	# Apply mouth texture
	var key = expr if mouth_textures.has(expr) else "grin"
	if mouth and mouth is Sprite2D:
		mouth.texture = mouth_textures[key]

	# Apply expression-linked eye states (Nita's fierce personality)
	match expr:
		"neutral", "grin", "smug":
			_apply_eye_state("open")
			_reset_brows()
		"happy":
			_apply_eye_state("happy")
			_reset_brows()
		"angry":
			_apply_eye_state("angry")
			_angle_brows(0.22)
		"shocked":
			_apply_eye_state("wide")
			_angle_brows(-0.12)
		"hurt":
			_apply_eye_state("blink")
			_angle_brows(0.20)
		"sad":
			_apply_eye_state("closed")
			_reset_brows()
		_:
			_apply_eye_state("open")
			_reset_brows()

	expression_changed.emit(current_expression)

func _reset_brows() -> void:
	if brow_l: brow_l.rotation = 0.0
	if brow_r: brow_r.rotation = 0.0

func _angle_brows(angle: float) -> void:
	if brow_l: brow_l.rotation = angle
	if brow_r: brow_r.rotation = -angle
