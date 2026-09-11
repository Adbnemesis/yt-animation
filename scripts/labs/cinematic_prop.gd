extends Node2D
class_name CinematicProp

# ============================================================================
# CINEMATIC PROP (LAB) — a world-space environment object (Part 15/16/17)
# Projects itself through the shared camera; occlusion follows depth via
# z_index (no hardcoded layer flips).
# ============================================================================

@export var prop_height_px: float = 120.0 # visual height in world units
@export var body_color: Color = Color(0.42, 0.34, 0.26)
@export var accent_color: Color = Color(0.3, 0.24, 0.18)

var world_pos := Vector2.ZERO
var elevation: float = 0.0
var camera: CinematicCamera = null

func setup(cam: CinematicCamera, pos: Vector2, height: float, color: Color) -> void:
	camera = cam
	world_pos = pos
	prop_height_px = height
	body_color = color
	accent_color = color.darkened(0.25)

func _ready() -> void:
	if has_node("Body"):
		return
	# built from code when not authored in a scene: draw a simple block
	var body := Polygon2D.new()
	body.name = "Body"
	add_child(body)

func _physics_process(_delta: float) -> void:
	_apply_camera()

func _apply_camera() -> void:
	if camera == null:
		return
	var p := camera.project(world_pos, elevation)
	position = p.pos
	var s := maxf(p.scale, 0.01)
	scale = Vector2(s, s)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
