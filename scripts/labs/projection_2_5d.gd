extends RefCounted
class_name Projection2_5D

# 2.5D Projection Model for the Staging Lab (EXPERIMENTAL).
#
# Mirrors the classic Godot 2.5D approach (official godot-demo-projects 2.5D
# demos): characters stay 2D sprites/cutouts, but are positioned with a 3D
# world coordinate:
#
#   x = horizontal world position (identity-mapped to screen x)
#   y = elevation above the ground (0 = grounded)
#   z = scene depth (0 = near camera, Z_FAR = deepest visible plane)
#
# Projection to 2D screen space:
#   screen_x = x
#   screen_y = GROUND_Y - z * rise_per_view - elevation
#   scale    = base_scale * lerp(1.0, scale_far(view), depth01(z))
#
# View modes alter the projection parameters so the lab can test which
# "camera angle" reads best for our paper-cutout art:
#   FRONT   - near-level camera, gentle rise, mild scale falloff
#   SIDE    - classic side-scroller with a hint of depth
#   DEG45   - 45-degree: moderate rise + stronger falloff
#   OBLIQUE - oblique: high rise + strongest falloff (most dramatic)
#
# Depth sorting is handled by the CanvasItem y-sort: deeper actors have a
# smaller screen_y and therefore draw behind nearer actors.

enum ViewMode {
	FRONT,
	SIDE,
	DEG45,
	OBLIQUE
}

const Z_NEAR := 0.0
const Z_FAR := 180.0
const GROUND_Y := 640.0

static func depth01(z: float) -> float:
	return clampf((z - Z_NEAR) / (Z_FAR - Z_NEAR), 0.0, 1.0)

static func rise_per_z(mode: int) -> float:
	match mode:
		ViewMode.FRONT:
			return 0.32
		ViewMode.DEG45:
			return 0.62
		ViewMode.OBLIQUE:
			return 0.82
	return 0.5

static func scale_far(mode: int) -> float:
	match mode:
		ViewMode.FRONT:
			return 0.62
		ViewMode.DEG45:
			return 0.54
		ViewMode.OBLIQUE:
			return 0.5
	return 0.57

static func scale_at(z: float, mode: int = ViewMode.SIDE, base: float = 1.0) -> float:
	var t := Projection2_5D.depth01(z)
	return base * lerpf(1.0, Projection2_5D.scale_far(mode), t)

static func screen_y_at(z: float, elevation: float = 0.0, mode: int = ViewMode.SIDE) -> float:
	return GROUND_Y - z * Projection2_5D.rise_per_z(mode) - elevation

# Applies projected scale to a 2D node (its origin must be the ground point).
static func apply_scale(node: Node2D, z: float, mode: int = ViewMode.SIDE, base: float = 1.0) -> void:
	var s := Projection2_5D.scale_at(z, mode, base)
	node.scale = Vector2(s, s)

# Contact-shadow opacity/size falloff with distance (stylized, cheap).
static func shadow_alpha(z: float, mode: int = ViewMode.SIDE) -> float:
	return lerpf(0.5, 0.22, Projection2_5D.depth01(z))