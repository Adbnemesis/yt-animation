extends RefCounted
class_name SceneDepth

# Unified 2.5D depth model for "The Thing They Shouldn't Have Opened".
#
# The facility floor is a perspective ground plane running from the base of
# the back wall (HORIZON_Y — the deepest walkable line) down to the front of
# the floor (NEAR_Y — closest to camera). Anything standing on the floor at
# ground line y resolves its apparent scale through ONE rule:
#
#   t      = clamp((y - HORIZON_Y) / (NEAR_Y - HORIZON_Y), 0, 1)
#   scale  = lerp(FAR_SCALE, NEAR_SCALE, t) * base_scale
#
# Every actor, enemy, and prop in this production resolves size through this
# model, so near things read larger, far things read smaller, and character
# identity (base_scale) is preserved at every depth.

const HORIZON_Y := 480.0  # base of the back wall — far edge of the floor
const NEAR_Y := 620.0     # front edge of the floor — closest to camera
const FAR_SCALE := 0.66
const NEAR_SCALE := 1.12

static func depth_factor(y: float) -> float:
	return clampf((y - HORIZON_Y) / (NEAR_Y - HORIZON_Y), 0.0, 1.0)

static func scale_at(y: float, base_scale: float = 1.0) -> float:
	return base_scale * lerpf(FAR_SCALE, NEAR_SCALE, depth_factor(y))

# Apply the depth scale to a floor-standing node (node origin = ground contact).
static func apply(node: Node2D, base_scale: float) -> void:
	var s := scale_at(node.position.y, base_scale)
	node.scale = Vector2(s, s)
