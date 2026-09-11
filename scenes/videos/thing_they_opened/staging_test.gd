extends Node2D

# TEMPORARY staging validation for the facility production.
# Demonstrates the shared depth model before it ships in the final render:
#   1. Trio staged across three depth lanes (near / mid / far)
#   2. Apparent scale follows the ground plane (SceneDepth)
#   3. Ground contact shadows at every depth
#   4. Projectiles fired across lanes are occluded by floor props
#   5. Depth reversal — Leon and Bo swap lanes, scales follow
#   6. Occlusion pass behind the foreground crate cluster

@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var facility: FacilityBuilder = get_node_or_null("Environment")
@onready var leon: FacilityActorLeon = get_node_or_null("Leon")
@onready var nita: FacilityActorNita = get_node_or_null("Nita")
@onready var bo: FacilityActorBo = get_node_or_null("Bo")

const NEAR := Vector2(620, 575)
const MID := Vector2(460, 530)
const FAR := Vector2(240, 492)

func _ready() -> void:
	if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
		get_tree().process_frame.connect(_run, CONNECT_ONE_SHOT)
	else:
		RenderingServer.frame_post_draw.connect(_run, CONNECT_ONE_SHOT)

func wait_sec(seconds: float) -> void:
	var frames = int(round(seconds * 60.0))
	for i in range(frames):
		if DisplayServer.get_name() == "headless" and not OS.has_feature("movie"):
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw

func _pan(pos: Vector2, zoom: Vector2, dur: float) -> void:
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(camera, "position", pos, dur)
	tw.tween_property(camera, "zoom", zoom, dur)

func _stagger(dirs: Array) -> void:
	for i in dirs.size():
		var a = dirs[i]
		a.set_facing(1)
		a._update_depth_scale()

func _run() -> void:
	# Stage 1: Leon NEAR, Nita MID, Bo FAR
	leon.position = NEAR
	nita.position = MID
	bo.position = FAR
	_stagger([leon, nita, bo])
	await wait_sec(2.2)

	# Slow dolly right — parallax and occluders read against the lanes
	_pan(Vector2(560, 430), Vector2(0.95, 0.95), 3.0)
	bo.trigger_attack()
	await wait_sec(1.0)
	bo.trigger_attack()
	await wait_sec(2.4)

	# Stage 2: DEPTH REVERSAL — Bo takes the near lane, Leon goes deep
	_pan(Vector2(430, 430), Vector2(0.95, 0.95), 1.0)
	leon.tactical_reposition_2d(Vector2(FAR.x + 40, FAR.y), 1.2)
	bo.tactical_reposition_2d(Vector2(620, NEAR.y), 1.2)
	await wait_sec(2.6)

	# Stage 3: occlusion pass — Nita walks left behind the foreground crates
	nita.walk_to_2d(Vector2(120, MID.y + 45), 120.0)
	await wait_sec(1.6)
	_pan(Vector2(300, 430), Vector2(1.05, 1.05), 0.8)
	await wait_sec(1.4)

	# Fade out
	var overlay = ColorRect.new()
	overlay.size = Vector2(3000, 2000)
	overlay.position = Vector2(-500, -500)
	overlay.color = Color(0, 0, 0, 0)
	add_child(overlay)
	var tw = create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().quit()
