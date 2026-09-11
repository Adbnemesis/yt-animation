extends Node2D
class_name MultiviewController

# ============================================================================
# MULTIVIEW CONTROLLER (LAB) — camera-relative view selection for one character
# ----------------------------------------------------------------------------
# Architecture (documented in docs/MULTIVIEW_CHARACTER_SYSTEM.md):
#
#   Character (this node, feet origin)
#   └── View Controller (this script)
#       ├── ViewFront    (view-specific artwork / rig)
#       ├── ViewFront3Q
#       ├── ViewSide     (animated production rig)
#       ├── ViewBack3Q
#       └── ViewBack
#
# The visible view is selected from a RELATIVE ANGLE between the character's
# facing and the camera bearing. Five unique artworks cover all 8 directions
# (left variants are horizontal mirrors of the right variants). The controller
# is independent of movement, physics and abilities: it only picks which
# artwork is visible and where its attack socket is.
#
# Root/pivot rule (Part 32): every view scene must be authored with the feet
# ground point at origin (0,0), so switching views never moves the character.
# ============================================================================

signal view_changed(view_name: StringName, mirrored: bool)

const FADE_TIME := 0.12

# View node names expected as children (missing ones are optional; fallback
# chains keep the system working with partial artwork sets).
const VIEW_NODES := {
	&"front": "ViewFront",
	&"front_3q": "ViewFront3Q",
	&"side": "ViewSide",
	&"back_3q": "ViewBack3Q",
	&"back": "ViewBack",
}

# Fallback chain when a view's artwork does not exist yet.
const VIEW_FALLBACK := {
	&"front": [&"front_3q", &"side"],
	&"front_3q": [&"front", &"side"],
	&"side": [&"front_3q", &"front"],
	&"back_3q": [&"back", &"side"],
	&"back": [&"back_3q", &"side"],
}

var current_view: StringName = &"front"
var current_mirror: bool = false
var relative_angle: float = 0.0 # degrees; 0 = facing camera, 180 = back to camera
var _active_nodes := {} # view_name -> Array[Node2D] currently fading/visible
var _fade_tween: Tween = null

func _ready() -> void:
	for view_name in VIEW_NODES.values():
		var node := get_node_or_null(NodePath(view_name))
		if node:
			node.visible = false
			_disable_view_physics(node)
	_apply(&"front", false, true)

# --- Public API -------------------------------------------------------------

## relative angle in degrees: 0 = character faces the camera, +180 = back.
## Positive angles turn the character toward their own right.
func set_relative_angle(deg: float) -> void:
	relative_angle = wrapf(deg, -180.0, 180.0)
	var view := _bucket_to_view(relative_angle)
	var mirror := _bucket_to_mirror(relative_angle, view)
	_apply(view, mirror)

## Direct view selection (used by the rotation and sheet tests).
func set_view(view_name: StringName, mirror: bool = false) -> void:
	_apply(view_name, mirror)

func active_node() -> Node2D:
	var list: Array = _active_nodes.get(current_view, [])
	for n in list:
		if n is Node2D and n.visible and n.modulate.a > 0.5:
			return n
	return get_node_or_null(NodePath(VIEW_NODES.get(current_view, "")))

## Attack socket in THIS node's local space (feet origin). Continuity rule
## (Parts 43/44): the socket comes from the active view's marker so projectile
## spawn points follow the artwork, never an arbitrary global anchor.
func attack_socket_local() -> Vector2:
	var node := active_node()
	if node:
		var marker: Node2D = node.find_child("AttackSocket", true, false)
		if marker == null:
			marker = node.find_child("ProjectileSpawnPoint", true, false)
		if marker:
			return node.to_local(marker.global_position)
	return Vector2(0, -60)

func has_view(view_name: StringName) -> bool:
	return has_node(NodePath(VIEW_NODES.get(view_name, "")))

# --- View selection ---------------------------------------------------------

static func _bucket_to_view(a: float) -> StringName:
	var abs_a := absf(a)
	if abs_a < 22.5:
		return &"front"
	if abs_a < 67.5:
		return &"front_3q"
	if abs_a < 112.5:
		return &"side"
	if abs_a < 157.5:
		return &"back_3q"
	return &"back"

## Which unique artwork needs mirroring so the turn direction reads correctly.
## Front/back artwork is symmetric; 3/4 and side artwork is authored turning
## toward the viewer's right, so negative angles mirror it.
static func _bucket_to_mirror(a: float, view: StringName) -> bool:
	if view == &"front" or view == &"back":
		return false
	if view == &"back_3q":
		return a > 0.0 # back view inverts the perceived direction
	return a < 0.0

func _apply(view_name: StringName, mirror: bool, instant: bool = false) -> void:
	var resolved := view_name
	var resolved_mirror := mirror
	if not has_view(resolved):
		for fallback in VIEW_FALLBACK.get(resolved, []):
			if has_view(fallback):
				resolved = fallback
				resolved_mirror = false
				break
	var node_name: String = VIEW_NODES[resolved]
	var target := get_node_or_null(NodePath(node_name))
	if target == null:
		return
	var mirrored := resolved_mirror and resolved != &"back"
	if instant:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_hide_all_instant()
		target.visible = true
		target.modulate.a = 1.0
		target.scale.x = -1.0 if mirrored else 1.0
		_active_nodes = {resolved: [target]}
	else:
		_crossfade_to(resolved, target, mirrored)
	current_view = resolved
	current_mirror = mirrored
	view_changed.emit(resolved, mirrored)

func _crossfade_to(view_name: StringName, target: Node2D, mirrored: bool) -> void:
	if current_view == view_name and current_mirror == mirrored and target.visible and target.modulate.a >= 0.99:
		return
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	target.scale.x = -1.0 if mirrored else 1.0
	target.visible = true
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(target, "modulate:a", 1.0, FADE_TIME)
	for other_view in _active_nodes:
		if other_view == view_name:
			continue
		for n in _active_nodes[other_view]:
			if is_instance_valid(n) and n != target:
				_fade_tween.tween_property(n, "modulate:a", 0.0, FADE_TIME)
				_fade_tween.chain().tween_callback(n.hide)
	_active_nodes = {view_name: [target]}

func _hide_all_instant() -> void:
	for view_name in VIEW_NODES.values():
		var node := get_node_or_null(NodePath(view_name))
		if node:
			node.visible = false
			node.modulate.a = 1.0

func _disable_view_physics(node: Node) -> void:
	if node is CharacterBody2D:
		node.set_physics_process(false)
		if "velocity" in node:
			node.velocity = Vector2.ZERO
