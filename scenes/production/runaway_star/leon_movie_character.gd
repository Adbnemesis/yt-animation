extends Node2D
class_name LeonMovieCharacter

# ============================================================================
# LEON MOVIE CHARACTER (SINGLE-INSTANCE PRODUCTION CONTROLLER)
# ----------------------------------------------------------------------------
# The authoritative single Leon character instance for "Leon and the Runaway Star".
#
# GUARANTEES (Production Invariants):
# 1. EXACTLY ONE live Leon instance in the scene tree at all times.
# 2. Zero hidden duplicate Leons. No dormant multi-view nodes.
# 3. Dynamic View Slot: $ViewSlot holds only the single active view rig.
#    When view changes, the previous view is cleanly removed and freed, and
#    the new view is mounted.
# 4. 2.5D spatial projection: world_pos (X, Z) + elevation (Y jump).
#    Scale derives strictly from perspective camera projection (never manual).
# 5. Synchronized Footstep System: foot contact triggers distinct walk/run SFX.
# 6. Full 4-view support: Side, Front, 3/4, Back with unified actions & acting.
# ============================================================================

signal attack_released(dir_vector: Vector2, socket_pos: Vector2)
signal super_activated()
signal super_ended()
signal footstep_stepped(is_run: bool)
signal landed()

# Canonical view packed scenes
const SCENE_FRONT := preload("res://scenes/videos/leon_elevator/leon_front.tscn")
const SCENE_FRONT_3Q := preload("res://scenes/labs/characters/leon_multiview_lab/view_front_3q.tscn")
const SCENE_SIDE := preload("res://scenes/leon_side.tscn")
const SCENE_BACK := preload("res://scenes/videos/leon_elevator/leon_back.tscn")

enum LocomotionState { IDLE, WALK, RUN, STOP }

var camera: CinematicCamera = null
var world_pos: Vector2 = Vector2.ZERO # (x, z) on the ground plane
var elevation: float = 0.0           # vertical height above ground
var facing_deg: float = 0.0          # yaw angle in degrees (0 = toward +x)

var active_view_name: StringName = &""
var is_mirrored: bool = false
var locomotion_state: LocomotionState = LocomotionState.IDLE

# Locomotion motion parameters
var _walk_target: Vector2 = Vector2.ZERO
var _walk_speed: float = 140.0
var _is_moving: bool = false
var _jump_t: float = -1.0
var _jump_height: float = 46.0
var _jump_duration: float = 0.65

# Footstep stride timing
var _stride_phase: float = 0.0
var _last_step_stride: int = 0
var _afterimage_timer: float = 0.0
var has_shadow: bool = true

# View slot & active view node
@onready var view_slot: Node2D = $ViewSlot
@onready var shadow: Polygon2D = $GroundShadow

var current_view_node: Node2D = null

func _ready() -> void:
	_build_ground_shadow()
	# Default to 3/4 view for the opening scene
	set_view(&"front_3q", false)

func setup(cam: CinematicCamera, pos: Vector2, facing: float = 35.0) -> void:
	camera = cam
	world_pos = pos
	facing_deg = facing
	_apply_projection()

func _process(delta: float) -> void:
	var d := (1.0 / 60.0) if OS.has_feature("movie") else delta
	_step_movement(d)
	_step_jump(d)
	_step_footsteps(d)
	_apply_projection()

# --- 2.5D Projection --------------------------------------------------------

func _apply_projection() -> void:
	if camera == null:
		return
		
	var p := camera.project(world_pos, elevation)
	position = p.pos
	scale = Vector2.ONE * maxf(p.scale, 0.01)
	z_index = -int(clampf(p.depth, -400.0, 4000.0) * 0.25)
	
	if shadow:
		if not has_shadow:
			shadow.visible = false
		else:
			shadow.visible = true
			var ground_proj := camera.project(world_pos, 0.0)
			shadow.global_position = ground_proj.pos + Vector2(0.0, 4.0 * ground_proj.scale)
			var s := maxf(ground_proj.scale * maxf(0.2, 1.0 - elevation / 260.0), 0.01)
			shadow.scale = Vector2(s, s * 0.55)
			shadow.modulate.a = clampf(0.85 * (1.0 - elevation / 200.0), 0.0, 0.85)
			shadow.z_index = -int(clampf(ground_proj.depth, -400.0, 4000.0) * 0.25) - 1

# --- Dynamic View Switching (Single-Instance Invariant) ----------------------

## Switches visible view. Unloads previous view and mounts the requested view.
## Exactly ONE view exists in the tree at any given moment.
func set_view(view_name: StringName, mirrored: bool = false) -> void:
	if active_view_name == view_name and is_mirrored == mirrored and current_view_node != null:
		return
		
	# 1. Cleanly remove and free previous view
	if current_view_node != null and is_instance_valid(current_view_node):
		view_slot.remove_child(current_view_node)
		current_view_node.queue_free()
		current_view_node = null
		
	active_view_name = view_name
	is_mirrored = mirrored
	
	# 2. Instantiate and mount active view
	match view_name:
		&"front":
			current_view_node = SCENE_FRONT.instantiate()
		&"front_3q":
			current_view_node = SCENE_FRONT_3Q.instantiate()
		&"side":
			current_view_node = SCENE_SIDE.instantiate()
		&"back":
			current_view_node = SCENE_BACK.instantiate()
		_:
			current_view_node = SCENE_FRONT_3Q.instantiate()
			
	current_view_node.name = "ActiveView_%s" % str(view_name)
	view_slot.add_child(current_view_node)
	
	# 3. Apply mirroring (scale.x = -1)
	current_view_node.scale.x = -1.0 if mirrored else 1.0
	
	# Disable physics on CharacterBody2D if side rig is mounted
	if current_view_node is CharacterBody2D:
		current_view_node.set_physics_process(false)
		if "velocity" in current_view_node:
			current_view_node.velocity = Vector2.ZERO
			
	# Sync current locomotion state to new view
	_apply_locomotion_to_active_view()

func _apply_locomotion_to_active_view() -> void:
	if current_view_node == null:
		return
		
	match locomotion_state:
		LocomotionState.IDLE:
			if current_view_node.has_method("change_state"):
				current_view_node.change_state(0) # IDLE
			elif current_view_node.has_method("reset_to_idle"):
				current_view_node.reset_to_idle()
			var ap := _get_anim_player()
			if ap and ap.has_animation("idle"):
				ap.play("idle")
		LocomotionState.WALK:
			if current_view_node.has_method("change_state"):
				# In front controller: State.WALK = 1, 3Q: State.WALK = 2
				if active_view_name == &"front_3q" or active_view_name == &"back":
					current_view_node.change_state(2) # WALK
				else:
					current_view_node.change_state(1) # WALK
			var ap := _get_anim_player()
			if ap and ap.has_animation("walk"):
				ap.play("walk")
		LocomotionState.RUN:
			if current_view_node.has_method("change_state"):
				if active_view_name == &"front_3q" or active_view_name == &"back":
					current_view_node.change_state(3) # RUN
				else:
					current_view_node.change_state(2) # RUN
			var ap := _get_anim_player()
			if ap and ap.has_animation("run"):
				ap.play("run")
		LocomotionState.STOP:
			if current_view_node.has_method("change_state"):
				if active_view_name == &"front_3q" or active_view_name == &"back":
					current_view_node.change_state(4) # STOP
				else:
					current_view_node.change_state(3) # STOP

func _get_anim_player() -> AnimationPlayer:
	if current_view_node:
		var ap: AnimationPlayer = current_view_node.find_child("AnimPlayer", true, false)
		if ap == null:
			for child in current_view_node.find_children("*", "AnimationPlayer", true, false):
				return child
		return ap
	return null

# --- Unified Locomotion API -------------------------------------------------

func walk_to(target: Vector2, speed: float = 140.0) -> void:
	_walk_target = target
	_walk_speed = speed
	_is_moving = true
	locomotion_state = LocomotionState.WALK
	_apply_locomotion_to_active_view()

func run_to(target: Vector2, speed: float = 280.0) -> void:
	_walk_target = target
	_walk_speed = speed
	_is_moving = true
	locomotion_state = LocomotionState.RUN
	_apply_locomotion_to_active_view()

func stop_locomotion() -> void:
	_is_moving = false
	locomotion_state = LocomotionState.STOP
	_apply_locomotion_to_active_view()
	spawn_dust_puff()
	# Elastic return to idle
	get_tree().create_timer(0.35).timeout.connect(func():
		if not _is_moving:
			locomotion_state = LocomotionState.IDLE
			_apply_locomotion_to_active_view()
	)

func _step_movement(delta: float) -> void:
	if not _is_moving:
		return
		
	var to_target := _walk_target - world_pos
	var dist := to_target.length()
	if dist < 2.0:
		_is_moving = false
		locomotion_state = LocomotionState.IDLE
		_apply_locomotion_to_active_view()
		return
		
	var step := minf(_walk_speed * delta, dist)
	world_pos += to_target / dist * step
	
	if locomotion_state == LocomotionState.RUN:
		_afterimage_timer += delta
		if _afterimage_timer >= 0.08:
			_afterimage_timer = 0.0
			spawn_afterimage()

func _step_jump(delta: float) -> void:
	if _jump_t < 0.0:
		return
		
	_jump_t += delta
	if _jump_t < _jump_duration:
		elevation = _jump_height * sin((_jump_t / _jump_duration) * PI)
	else:
		elevation = 0.0
		_jump_t = -1.0
		spawn_dust_puff()
		if view_slot:
			var tw := create_tween()
			tw.tween_property(view_slot, "scale:y", 0.78, 0.06).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(view_slot, "scale:y", 1.0, 0.12).set_trans(Tween.TRANS_BACK)
		landed.emit()

func jump(height: float = 48.0, duration: float = 0.65) -> void:
	if _jump_t >= 0.0:
		return
	_jump_height = height
	_jump_duration = duration
	_jump_t = 0.0
	if view_slot:
		var tw := create_tween()
		tw.tween_property(view_slot, "scale:y", 1.25, 0.1).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(view_slot, "scale:y", 1.0, duration * 0.4)
	if current_view_node and current_view_node.has_method("trigger_jump"):
		current_view_node.trigger_jump()

## Tilts or bobs the view slot slightly for gesture tests (e.g. mimicry)
func jump_bob_view(bob_amount: float = 12.0, duration: float = 0.3) -> void:
	if view_slot == null:
		return
	var tw := create_tween()
	tw.tween_property(view_slot, "position:y", -bob_amount, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(view_slot, "position:y", 0.0, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# --- Synchronized Footstep System -------------------------------------------

func _step_footsteps(delta: float) -> void:
	if not _is_moving:
		_stride_phase = 0.0
		_last_step_stride = 0
		return
		
	var is_run := (locomotion_state == LocomotionState.RUN)
	var cadence: float = 12.0 if is_run else 6.5
	_stride_phase += delta * cadence
	
	var current_step := int(_stride_phase / PI)
	if current_step > _last_step_stride:
		_last_step_stride = current_step
		footstep_stepped.emit(is_run)

# --- Unified Combat & Actions API -------------------------------------------

func trigger_basic_attack(aim_angle_deg: float = INF) -> void:
	if current_view_node:
		if current_view_node.has_method("trigger_attack"):
			current_view_node.trigger_attack(aim_angle_deg)
		else:
			var ap := _get_anim_player()
			if ap and ap.has_animation("attack"):
				ap.play("attack")

func trigger_super(stealth_duration: float = 1.8) -> void:
	super_activated.emit()
	_spawn_smoke_vfx()
	
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.22, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(stealth_duration)
	tw.tween_callback(_spawn_smoke_vfx)
	tw.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		super_ended.emit()
	)

func set_face_expression(expr: String, eye_state: String = "open") -> void:
	if current_view_node and current_view_node.has_method("set_face_expression"):
		current_view_node.set_face_expression(expr, eye_state)
	else:
		var face: FaceController = current_view_node.find_child("Face", true, false) if current_view_node else null
		if face:
			face.set_expression(expr)
			face.set_eye_state(eye_state)

## Cross-eyed comedic payoff for Scene 22:
## Shifts both pupils inward toward the nose center.
func set_cross_eyed(enabled: bool) -> void:
	if current_view_node == null:
		return
		
	if "auto_animate" in current_view_node:
		current_view_node.auto_animate = !enabled
		
	var pupil_l: Node2D = current_view_node.find_child("PupilL", true, false)
	var pupil_r: Node2D = current_view_node.find_child("PupilR", true, false)
	
	if pupil_l and pupil_r:
		if enabled:
			# Shift left pupil right (+X), right pupil left (-X) inward toward nose
			pupil_l.position = Vector2(5.0, 1.0)
			pupil_r.position = Vector2(-2.0, 1.0)
		else:
			pupil_l.position = Vector2(2.0, 0.0)
			pupil_r.position = Vector2(2.0, 0.0)

## Gaze tracking: makes Leon's eyes follow an actor or target in world coordinates
func look_at_world(target_world: Vector2) -> void:
	if current_view_node == null:
		return
	var pupil_l: Node2D = current_view_node.find_child("PupilL", true, false)
	var pupil_r: Node2D = current_view_node.find_child("PupilR", true, false)
	if pupil_l == null or pupil_r == null:
		return
	
	var dir := (target_world - world_pos)
	var offset_x: float = clampf(dir.x * 0.02, -3.5, 3.5)
	var offset_y: float = clampf(-dir.y * 0.015, -2.0, 2.0)
	
	if is_mirrored:
		offset_x = -offset_x
		
	pupil_l.position = Vector2(2.0 + offset_x, offset_y)
	pupil_r.position = Vector2(2.0 + offset_x, offset_y)

## Spawns cartoon dust puffs at Leon's feet on skid stops, hard turns, or landings
func spawn_dust_puff(side_dir: float = 0.0) -> void:
	if get_parent() == null:
		return
	var dust := Node2D.new()
	dust.name = "FootDustPuff"
	dust.position = position + Vector2(0, 4)
	dust.z_index = z_index + 1
	get_parent().add_child(dust)
	
	for i in range(5):
		var p := Polygon2D.new()
		p.color = Color(0.85, 0.88, 0.82, 0.6) # warm dust white-cream
		var r := randf_range(4.0, 8.0)
		var pts := PackedVector2Array()
		for seg in range(8):
			var th := float(seg) / 8.0 * TAU
			pts.append(Vector2(cos(th) * r, sin(th) * r * 0.6))
		p.polygon = pts
		dust.add_child(p)
		
		var angle := randf_range(-PI * 0.85, -PI * 0.15)
		var speed := randf_range(15.0, 40.0)
		var vel := Vector2(cos(angle) * speed + side_dir * 12.0, sin(angle) * speed * 0.4)
		var tw := dust.create_tween()
		tw.tween_property(p, "position", vel, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(p, "scale", Vector2(1.5, 1.5), 0.35)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.35)
		
	dust.get_tree().create_timer(0.4).timeout.connect(dust.queue_free)

## Spawns a fading cyan ninja ghost afterimage during high-speed sprint & Super
func spawn_afterimage() -> void:
	if get_parent() == null:
		return
	var ghost := Node2D.new()
	ghost.position = position
	ghost.scale = scale
	ghost.z_index = z_index - 1
	get_parent().add_child(ghost)
	
	var poly := Polygon2D.new()
	poly.color = Color(0.2, 0.85, 0.95, 0.42)
	var pts := PackedVector2Array([
		Vector2(-20, 0), Vector2(-25, -28), Vector2(-18, -62),
		Vector2(0, -75), Vector2(18, -62), Vector2(25, -28),
		Vector2(20, 0)
	])
	poly.polygon = pts
	ghost.add_child(poly)
	
	var tw := ghost.create_tween()
	tw.tween_property(poly, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ghost, "scale", scale * 1.08, 0.22)
	tw.chain().tween_callback(ghost.queue_free)

func attack_socket_world() -> Vector2:
	if current_view_node:
		var marker: Node2D = current_view_node.find_child("AttackSocket", true, false)
		if marker == null:
			marker = current_view_node.find_child("ProjectileSpawnPoint", true, false)
		if marker:
			return marker.global_position
	return global_position + Vector2(0, -32)

func _spawn_smoke_vfx() -> void:
	var smoke := Node2D.new()
	smoke.name = "SuperSmokePuff"
	smoke.position = Vector2(0, -50)
	smoke.z_index = z_index + 12
	add_child(smoke)
	
	for i in range(14):
		var puff := Polygon2D.new()
		puff.color = Color(0.18, 0.88, 0.95, 0.85)
		var pts := PackedVector2Array([
			Vector2(-12, -12), Vector2(12, -12),
			Vector2(14, 14), Vector2(-14, 14)
		])
		puff.polygon = pts
		var angle := randf() * TAU
		var dist := randf_range(12.0, 46.0)
		var target_offset := Vector2(cos(angle), sin(angle)) * dist
		smoke.add_child(puff)
		
		var tw := smoke.create_tween()
		tw.tween_property(puff, "position", target_offset, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(puff, "scale", Vector2.ZERO, 0.42).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(puff, "modulate:a", 0.0, 0.42)
		
	get_tree().create_timer(0.5).timeout.connect(smoke.queue_free)

func look_down_at_ground() -> void:
	if current_view_node == null:
		return
	var pupil_l: Node2D = current_view_node.find_child("PupilL", true, false)
	var pupil_r: Node2D = current_view_node.find_child("PupilR", true, false)
	if pupil_l and pupil_r:
		pupil_l.position = Vector2(2.0, 3.5)
		pupil_r.position = Vector2(2.0, 3.5)

## Comedic payoff for Scene 21:
## Leon's ground shadow arm raises and slowly waves independently!
func trigger_shadow_wave(duration: float = 2.0) -> void:
	if shadow == null:
		return
	var arm: Polygon2D = shadow.get_node_or_null("ShadowArm")
	if arm == null:
		return
		
	arm.visible = true
	arm.scale = Vector2.ZERO
	arm.rotation_degrees = 0.0
	
	var tw := create_tween()
	# Arm pops out from the ground shadow with organic bounce
	tw.tween_property(arm, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(arm, "rotation_degrees", 25.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Waves back and forth prominently
	var waves := int(duration / 0.30)
	for i in range(waves):
		var target_deg: float = -35.0 if (i % 2 == 0) else 35.0
		tw.tween_property(arm, "rotation_degrees", target_deg, 0.15).set_trans(Tween.TRANS_SINE)
		
	tw.tween_property(arm, "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_QUAD)

func _build_ground_shadow() -> void:
	if shadow == null:
		shadow = Polygon2D.new()
		shadow.name = "GroundShadow"
		add_child(shadow)
		
	shadow.top_level = true
	shadow.color = Color(0.04, 0.08, 0.04, 0.85)
	
	# Stylized base ellipse (wide and solid ground contact beneath boots)
	var pts := PackedVector2Array()
	var segs := 24
	for i in range(segs):
		var th := float(i) / segs * TAU
		pts.append(Vector2(cos(th) * 44.0, sin(th) * 22.0))
	shadow.polygon = pts
	
	# Silhouette hood crest projection
	var crest := Polygon2D.new()
	crest.name = "ShadowCrest"
	crest.color = Color(0.04, 0.08, 0.04, 0.85)
	crest.polygon = PackedVector2Array([
		Vector2(-20.0, -4.0),
		Vector2(-26.0, -28.0),
		Vector2(-8.0, -48.0),
		Vector2(0.0, -58.0),  # Crest peak
		Vector2(12.0, -46.0),
		Vector2(24.0, -26.0),
		Vector2(18.0, -4.0)
	])
	shadow.add_child(crest)
	
	# Independent waving arm polygon for Scene 21
	# Positioned to the side/front of Leon's feet so it's unmistakably visible and unobstructed!
	var arm := Polygon2D.new()
	arm.name = "ShadowArm"
	arm.color = Color(0.04, 0.08, 0.04, 0.95)
	arm.position = Vector2(24.0, -2.0)
	arm.scale = Vector2.ZERO
	arm.visible = false
	arm.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(12.0, -12.0),
		Vector2(22.0, -26.0),
		Vector2(28.0, -46.0),  # Finger tips
		Vector2(20.0, -50.0),  # Thumb notch
		Vector2(14.0, -44.0),
		Vector2(10.0, -22.0),
		Vector2(4.0, -8.0)
	])
	shadow.add_child(arm)
