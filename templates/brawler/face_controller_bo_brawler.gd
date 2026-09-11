class_name FaceControllerBoBrawler
extends FaceControllerBase

# Bo Face Controller — Profile (Side-View) Brawler Framework Compatible
# Extends FaceControllerBase to interface with BrawlerBase.
# Connects Bo's authentic side-view profile expressions matching assets/brawlers/bo/references/bo_view_side.svg
# Features a SINGLE visible profile eye, chiseled warrior brow, and stoic mouth states.

func _init() -> void:
	_init_textures()

var head_bone: Bone2D = null

func _ready() -> void:
	if mouth_textures.is_empty():
		_init_textures()
	super._ready()
	_sync_with_head()
	# Ensure second eye is never visible in side view
	if eye_r:
		eye_r.visible = false

func _sync_with_head() -> void:
	if not is_instance_valid(head_bone):
		head_bone = get_node_or_null("../Skeleton/root/torso/neck/head") as Bone2D
	if head_bone:
		global_transform = head_bone.global_transform

func _process(delta: float) -> void:
	_sync_with_head()
	super._process(delta)

func _init_textures() -> void:
	# Bo approved profile mouth textures
	mouth_textures = {
		"neutral": preload("res://assets/brawlers/bo/side/face/mouth_stoic.svg"),
		"focused": preload("res://assets/brawlers/bo/side/face/mouth_stoic.svg"),
		"serious": preload("res://assets/brawlers/bo/side/face/mouth_stoic.svg"),
		"happy": preload("res://assets/brawlers/bo/side/face/mouth_smile.svg"),
		"smile": preload("res://assets/brawlers/bo/side/face/mouth_smile.svg"),
		"angry": preload("res://assets/brawlers/bo/side/face/mouth_shout.svg"),
		"shout": preload("res://assets/brawlers/bo/side/face/mouth_shout.svg"),
		"shocked": preload("res://assets/brawlers/bo/side/face/mouth_shout.svg"),
		"hurt": preload("res://assets/brawlers/bo/side/face/mouth_hurt.svg"),
		"grimace": preload("res://assets/brawlers/bo/side/face/mouth_grimace.svg"),
		"sad": preload("res://assets/brawlers/bo/side/face/mouth_hurt.svg"),
		"scared": preload("res://assets/brawlers/bo/side/face/mouth_grimace.svg"),
		"confused": preload("res://assets/brawlers/bo/side/face/mouth_grimace.svg"),
		"smug": preload("res://assets/brawlers/bo/side/face/mouth_stoic.svg"),
		"fierce": preload("res://assets/brawlers/bo/side/face/mouth_shout.svg")
	}

	# Bo profile eye textures (Single profile eye)
	eye_textures = {
		"open": preload("res://assets/brawlers/bo/side/face/eye_open.svg"),
		"blink": preload("res://assets/brawlers/bo/side/face/eye_blink.svg"),
		"closed": preload("res://assets/brawlers/bo/side/face/eye_blink.svg"),
		"happy": preload("res://assets/brawlers/bo/side/face/eye_happy.svg"),
		"wide": preload("res://assets/brawlers/bo/side/face/eye_wide.svg"),
		"angry": preload("res://assets/brawlers/bo/side/face/eye_angry.svg"),
		"fierce": preload("res://assets/brawlers/bo/side/face/eye_angry.svg")
	}

	default_expression = "focused"
	default_eye_state = "open"

func _apply_eye_state(state: String) -> void:
	if not eye_textures.has(state):
		return

	var tex = eye_textures[state]
	# Update single profile eye
	if eye_l and eye_l is Sprite2D:
		eye_l.texture = tex
		eye_l.visible = true

	# Ensure far eye is ALWAYS hidden in profile view
	if eye_r and eye_r is Sprite2D:
		eye_r.visible = false

	var hide_pupils = (state in ["blink", "closed"])
	if pupil_l: pupil_l.visible = not hide_pupils
	if pupil_r: pupil_r.visible = false

func set_expression(expr: String) -> void:
	_ensure_nodes()
	if mouth_textures.is_empty():
		_init_textures()
	current_expression = expr

	# Apply mouth texture
	var tex = mouth_textures.get(expr, mouth_textures.get("neutral", null))
	if mouth and mouth is Sprite2D and tex != null:
		mouth.texture = tex

	# Apply Bo's warrior expression-to-eye linkage in profile
	match expr:
		"neutral", "serious", "focused", "smug":
			_apply_eye_state("open")
			_reset_brows()
		"happy", "smile":
			_apply_eye_state("happy")
			_reset_brows()
		"angry", "fierce":
			_apply_eye_state("angry")
			_angle_brows(0.20)
		"sad", "hurt":
			_apply_eye_state("blink")
			_angle_brows(-0.15)
		"shocked", "scared":
			_apply_eye_state("wide")
			_angle_brows(-0.10)
		"grimace":
			_apply_eye_state("angry")
			_angle_brows(0.15)
		_:
			_apply_eye_state("open")
			_reset_brows()

	expression_changed.emit(current_expression)

func _reset_brows() -> void:
	if brow_l and brow_l is Sprite2D:
		brow_l.rotation = 0.0
		brow_l.position = Vector2.ZERO
	if brow_r:
		brow_r.visible = false

func _angle_brows(angle: float) -> void:
	if brow_l and brow_l is Sprite2D:
		brow_l.rotation = angle
		brow_l.position = Vector2(0, angle * 3.0)
	if brow_r:
		brow_r.visible = false
