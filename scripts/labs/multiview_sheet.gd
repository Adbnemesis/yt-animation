extends Node2D

# ============================================================================
# MULTIVIEW SHEET (LAB) — side-by-side view consistency sheet (Part 4/31)
# Instantiates every available view of one multiview character in a row.
# Rendered via Movie Maker for visual QC of view consistency.
# ============================================================================

@export var character_scene: String = ""

const VIEW_ORDER: Array[StringName] = [&"front", &"front_3q", &"side", &"back_3q", &"back"]
const VIEW_LABELS := {
	&"front": "FRONT",
	&"front_3q": "FRONT 3/4",
	&"side": "SIDE",
	&"back_3q": "BACK 3/4",
	&"back": "BACK",
}

func _ready() -> void:
	if character_scene.is_empty():
		return
	var packed: PackedScene = load(character_scene)
	if packed == null:
		return
	var model: MultiviewController = packed.instantiate()
	var font := ThemeDB.fallback_font
	var x := 140.0
	for view_name in VIEW_ORDER:
		var node_name: String = MultiviewController.VIEW_NODES[view_name]
		var view := model.get_node_or_null(NodePath(node_name))
		if view == null:
			continue
		view = view.duplicate()
		add_child(view)
		view.position = Vector2(x, 560)
		view.visible = true
		view.modulate = Color.WHITE
		var lbl := Label.new()
		lbl.text = VIEW_LABELS.get(view_name, String(view_name))
		lbl.position = Vector2(x - 55, 590)
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		add_child(lbl)
		x += 222.0
	model.queue_free()
