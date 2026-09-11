extends Node2D
class_name HeroProp

# ============================================================================
# HERO PROP (2.5D) — World-space environment prop
# ----------------------------------------------------------------------------
# Fulfils Bible Parts 7, 16, 17, 44, 56, 57:
# Lives on ground plane at (world_pos.x, world_pos.y as Z).
# Ground contact shadow anchors the prop to the projected plane.
# Draw order (z_index) is a pure function of depth for correct occlusion.
# Interactive props react to projectile impacts with elastic recoil and debris.
# ============================================================================

signal hit_received(prop: Node2D)

const TEX_PILLAR := "res://assets/architecture/arch_stone_block_tall_01.png"
const TEX_CRATE := "res://assets/props/prop_crate_01.png"
const TEX_CRATE_BROKEN := "res://assets/props/prop_crate_broken_sq_01.png"
const TEX_ROCK := "res://assets/nature/nat_rock_01.png"
const TEX_SIGN := "res://assets/props/prop_sign_01.png"
const TEX_BUSH := "res://assets/nature/nat_bush_01.png"

@export var prop_type: String = "crate"
@export var is_destructible: bool = false

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, z) on ground plane
var elevation: float = 0.0
var base_scale: float = 1.0
var hit_count: int = 0

var _recoil_offset: Vector2 = Vector2.ZERO
var _initial_visual_pos: Vector2 = Vector2.ZERO

var visual: Sprite2D = null
var shadow: Polygon2D = null

func _ready() -> void:
	_ensure_components()

func setup(
	cam: CinematicCamera,
	pos: Vector2,
	p_type: String,
	p_scale: float = 1.0,
	p_elevation: float = 0.0
) -> void:
	camera = cam
	world_pos = pos
	prop_type = p_type
	base_scale = p_scale
	elevation = p_elevation
	_ensure_components()
	_apply_visual_type()
	_apply_camera()

func _ensure_components() -> void:
	if shadow == null:
		shadow = get_node_or_null("Shadow")
	if shadow == null:
		shadow = Polygon2D.new()
		shadow.name = "Shadow"
		shadow.z_index = -1
		shadow.color = Color(0.04, 0.05, 0.08, 0.45)
		_build_shadow_mesh(34.0, 10.0)
		add_child(shadow)

	if visual == null:
		visual = get_node_or_null("Visual")
	if visual == null:
		visual = Sprite2D.new()
		visual.name = "Visual"
		add_child(visual)

func _build_shadow_mesh(rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	var steps := 20
	for i in range(steps):
		var th := i * TAU / steps
		pts.append(Vector2(cos(th) * rx, sin(th) * ry))
	shadow.polygon = pts

func _apply_visual_type() -> void:
	match prop_type:
		"pillar":
			# Tall stone column for foreground occlusion
			visual.texture = load(TEX_PILLAR)
			visual.offset = Vector2(0, -visual.texture.get_height() * 0.5)
			visual.scale = Vector2(1.2, 1.4)
			_build_shadow_mesh(38.0, 12.0)
		"crate":
			visual.texture = load(TEX_CRATE)
			visual.offset = Vector2(0, -visual.texture.get_height() * 0.5)
			visual.scale = Vector2(1.2, 1.2)
			_build_shadow_mesh(32.0, 10.0)
		"rock":
			visual.texture = load(TEX_ROCK)
			visual.offset = Vector2(0, -visual.texture.get_height() * 0.5)
			visual.scale = Vector2(1.2, 1.2)
			_build_shadow_mesh(34.0, 10.0)
		"sign":
			visual.texture = load(TEX_SIGN)
			visual.offset = Vector2(0, -visual.texture.get_height() * 0.5)
			visual.scale = Vector2(1.0, 1.0)
			_build_shadow_mesh(22.0, 7.0)
		"bush":
			visual.texture = load(TEX_BUSH)
			visual.offset = Vector2(0, -visual.texture.get_height() * 0.5)
			visual.scale = Vector2(1.1, 1.1)
			_build_shadow_mesh(26.0, 9.0)

	_initial_visual_pos = visual.position

func _physics_process(delta: float) -> void:
	if _recoil_offset != Vector2.ZERO:
		_recoil_offset = _recoil_offset.move_toward(Vector2.ZERO, 140.0 * delta)
		if visual:
			visual.position = _initial_visual_pos + _recoil_offset

	_apply_camera()

var force_foreground: bool = false  # When true, z_index is not overwritten by camera projection

func _apply_camera() -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, elevation)
	position = p.pos
	var s := maxf(p.scale, 0.01) * base_scale
	scale = Vector2(s, s)
	if not force_foreground:
		z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
	visible = p.visible

func react_hit(hit_dir: Vector2 = Vector2.RIGHT) -> void:
	hit_count += 1
	_recoil_offset = hit_dir.normalized() * 14.0

	# Flash and dust
	if visual:
		var tw := create_tween()
		tw.tween_property(visual, "modulate", Color(1.8, 1.4, 1.2), 0.06)
		tw.tween_property(visual, "modulate", Color.WHITE, 0.22)

	# If crate is hit, switch to chipped/broken crate graphic on multiple impacts
	if prop_type == "crate" and hit_count >= 1:
		visual.texture = load(TEX_CRATE_BROKEN)

	hit_received.emit(self)
