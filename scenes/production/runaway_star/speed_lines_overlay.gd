extends Control
class_name SpeedLinesOverlay

# ============================================================================
# SPEED LINES OVERLAY (ANIME / ACTION CARTOON VFX)
# ----------------------------------------------------------------------------
# Procedural dynamic action lines rendered on CanvasLayer.
# Features:
# - Radial mode: streaks pointing toward a focal point (e.g. Leon / Star)
# - Horizontal mode: horizontal action lines for high-speed profile sprints
# - Jittering random seed every frame for classic cel-animated kinetic energy
# ============================================================================

var is_active: bool = false
var mode: String = "radial" # "radial" or "horizontal"
var focal_point: Vector2 = Vector2(576, 324)
var intensity: float = 1.0
var line_color: Color = Color(1.0, 1.0, 1.0, 0.45)

var _active_tween: Tween = null
var _seed_offset: int = 0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	modulate.a = 0.0

func _process(_delta: float) -> void:
	if is_active and modulate.a > 0.01:
		_seed_offset += 1
		queue_redraw()

func trigger_speed_lines(duration: float = 0.6, style: String = "radial", focus_pos: Vector2 = Vector2(576, 324), target_alpha: float = 0.5) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	mode = style
	focal_point = focus_pos
	is_active = true
	
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate:a", target_alpha, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_interval(maxf(0.05, duration - 0.14))
	_active_tween.tween_property(self, "modulate:a", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.chain().tween_callback(func():
		is_active = false
		queue_redraw()
	)

func stop_speed_lines() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	create_tween().tween_property(self, "modulate:a", 0.0, 0.05).chain().tween_callback(func():
		is_active = false
		queue_redraw()
	)

func _draw() -> void:
	if not is_active or modulate.a <= 0.01:
		return
		
	var w := size.x
	var h := size.y
	if w <= 0 or h <= 0:
		w = 1152.0
		h = 648.0
		
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_offset
	
	if mode == "radial":
		var count := 32
		var inner_radius := 140.0
		var outer_radius := 720.0
		
		for i in range(count):
			var base_angle := (float(i) / count) * TAU + rng.randf_range(-0.06, 0.06)
			var length := rng.randf_range(inner_radius + 40.0, outer_radius)
			var start_dist := rng.randf_range(inner_radius, inner_radius + 90.0)
			
			var dir := Vector2(cos(base_angle), sin(base_angle))
			var p1 := focal_point + dir * start_dist
			var p2 := focal_point + dir * (start_dist + length)
			
			var thickness := rng.randf_range(1.8, 4.2)
			var col := line_color
			col.a *= rng.randf_range(0.5, 1.0)
			draw_line(p1, p2, col, thickness)
	else:
		# Horizontal action speed lines
		var lines := 24
		for i in range(lines):
			var y := rng.randf_range(20.0, h - 20.0)
			var x_start := rng.randf_range(0.0, w * 0.3)
			var x_len := rng.randf_range(w * 0.4, w * 0.9)
			var thickness := rng.randf_range(2.0, 5.0)
			var col := line_color
			col.a *= rng.randf_range(0.4, 0.9)
			draw_line(Vector2(x_start, y), Vector2(x_start + x_len, y), col, thickness)
