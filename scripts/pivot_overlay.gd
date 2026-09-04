extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var harness = get_parent()
	if not harness or not ("show_pivots" in harness) or not harness.show_pivots:
		return
	if not ("bones" in harness):
		return

	for b_name in harness.bones.keys():
		var b = harness.bones[b_name]
		if not is_instance_valid(b) or not (b is Node2D):
			continue
		var l_pos = to_local(b.global_position)
		# Outer yellow ring
		draw_arc(l_pos, 12.0, 0.0, TAU, 28, Color(1.0, 0.85, 0.2, 0.95), 2.5)
		# Inner red joint point
		draw_circle(l_pos, 6.0, Color(1.0, 0.25, 0.25, 0.95))

		var p = b.get_parent()
		if p and (p is Bone2D):
			draw_line(to_local(p.global_position), l_pos, Color(0.2, 0.85, 1.0, 0.85), 3.0)
