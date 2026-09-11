extends Node2D
class_name CinematicCamera

# ============================================================================
# CINEMATIC CAMERA (LAB) — the general 2.5D spatial model
# ----------------------------------------------------------------------------
# The world is a ground plane (x = lateral, z = depth). The camera has a
# ground position, a height, a yaw (orbit), a pitch (low/high angle) and a
# zoom. Characters and props project themselves through project() every
# frame — nothing is hand-scaled per shot (Part 36).
#
# Two projection modes (Part 24):
#   ORTHO        cabinet-style affine: constant x scale, linear depth rise.
#   PERSPECTIVE  true divide: k = focal / (focal + depth) applied to x, y
#                ground drop AND apparent scale.
#
# Camera-relative view selection: project() also returns the bearing from the
# camera to the object, which the MultiviewController converts into artwork
# views (Part 7).
# ============================================================================

enum ProjMode { ORTHO, PERSPECTIVE }

const PPU := 1.0 # world units -> screen pixels at zoom 1

@export var mode: ProjMode = ProjMode.PERSPECTIVE
@export var cam_x: float = 0.0
@export var cam_z: float = -260.0
@export var cam_height: float = 150.0
@export var yaw_deg: float = 0.0 # orbit: 0 = looking toward +z
@export var pitch_deg: float = 0.0 # + = high angle (horizon drops), - = low angle
@export var zoom: float = 1.0
@export var focal: float = 520.0 # perspective focal length (world units)
@export var ortho_rise: float = 0.62 # screen px of ground drop per depth unit
@export var horizon_y: float = 340.0 # screen y of the horizon at pitch 0
@export var screen_center_x: float = 576.0 # screen x of the camera axis

func project(world: Vector2, elevation: float = 0.0) -> Dictionary:
	var rel := world - Vector2(cam_x, cam_z)
	var yaw := deg_to_rad(yaw_deg)
	var fwd := Vector2(sin(yaw), cos(yaw)) # camera view direction on ground
	var right_dir := Vector2(cos(yaw), -sin(yaw))
	var depth := rel.dot(fwd)
	var right := rel.dot(right_dir)
	var pitch_px := pitch_deg * 2.2
	var horizon := horizon_y + pitch_px
	var k: float
	var screen_x: float
	var ground_y: float
	if mode == ProjMode.PERSPECTIVE:
		var d := maxf(depth, -focal * 0.6)
		k = focal / (focal + d)
		screen_x = right * k * PPU
		# ground drop below the horizon shrinks with distance (true perspective)
		ground_y = horizon + cam_height * k * PPU
	else:
		k = lerpf(1.0, 0.55, clampf(depth / 900.0, 0.0, 1.0))
		screen_x = right * PPU
		ground_y = horizon + depth * ortho_rise * PPU
	var scale := k * zoom
	var pos := Vector2.ZERO
	pos.x = screen_center_x + screen_x * zoom
	pos.y = horizon + ((ground_y - horizon) - elevation * PPU * k) * zoom
	# bearing from camera to object (0 = straight ahead of the camera)
	var bearing := rad_to_deg(atan2(right, depth))
	return {
		"pos": pos,
		"scale": scale,
		"depth": depth,
		"bearing": bearing,
		"visible": depth > -focal * 0.5,
	}

## Angle (deg) between the direction an object faces and the direction from
## the object toward the camera. 0 = facing the camera, ±180 = facing away.
func relative_view_angle(world: Vector2, facing_deg: float) -> float:
	var to_cam := Vector2(cam_x, cam_z) - world
	if to_cam.length() < 0.001:
		return 0.0
	var f := Vector2.from_angle(deg_to_rad(facing_deg))
	var a := f.angle_to(to_cam)
	return rad_to_deg(a)
