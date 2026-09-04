class_name BrawlerBuilder
extends RefCounted

# Reusable Assembly & Validation Pipeline for 2D Brawlers
# Validates node hierarchy, bone structure, attachment points, and animation tracks.

const EXPECTED_BONES := [
	"root",
	"torso",
	"head",
	"arm_L_upper",
	"arm_L_lower",
	"hand_L",
	"arm_R_upper",
	"arm_R_lower",
	"hand_R",
	"leg_L_upper",
	"leg_L_lower",
	"foot_L",
	"leg_R_upper",
	"leg_R_lower",
	"foot_R"
]

const REQUIRED_ANIMATIONS := [
	"idle",
	"walk",
	"run",
	"attack",
	"hit"
]

const REQUIRED_ATTACHMENT_POINTS := [
	"HitPoint",
	"HeadPoint",
	"ProjectileSpawn"
]

# Validates any Brawler scene against the standard interface
static func validate_brawler(brawler_node: Node) -> Dictionary:
	var result := {
		"valid": true,
		"missing_nodes": [],
		"missing_bones": [],
		"missing_animations": [],
		"missing_attachments": [],
		"warnings": []
	}

	if not (brawler_node is CharacterBody2D):
		result.missing_nodes.append("Root must be CharacterBody2D")
		result.valid = false

	if not brawler_node.has_node("CollisionShape2D"):
		result.missing_nodes.append("CollisionShape2D")
		result.valid = false

	if not brawler_node.has_node("Visuals"):
		result.missing_nodes.append("Visuals")
		result.valid = false

	var vfx_pts = brawler_node.get_node_or_null("VFXAttachmentPoints")
	if not vfx_pts:
		result.missing_nodes.append("VFXAttachmentPoints")
		result.valid = false
	else:
		for pt in REQUIRED_ATTACHMENT_POINTS:
			if not vfx_pts.has_node(pt):
				result.missing_attachments.append(pt)
				result.warnings.append("Optional/Recommended attachment point missing: " + pt)

	var anim = brawler_node.get_node_or_null("AnimPlayer") as AnimationPlayer
	if not anim:
		result.missing_nodes.append("AnimPlayer")
		result.valid = false
	else:
		for a in REQUIRED_ANIMATIONS:
			if not anim.has_animation(a):
				result.missing_animations.append(a)
				result.valid = false

	# Check bone naming convention if Skeleton2D is present
	var skeleton = brawler_node.find_child("Skeleton*", true, false)
	if skeleton:
		for b in EXPECTED_BONES:
			if not skeleton.find_child(b, true, false):
				result.missing_bones.append(b)
				result.warnings.append("Standard bone not found: " + b)

	return result
