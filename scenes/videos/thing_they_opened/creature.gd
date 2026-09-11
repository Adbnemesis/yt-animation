class_name FacilityCreature
extends Node2D

# Deterministic Scripted Large Creature Enemy
# 100% scripted behavior — NO AI. Attacks at predetermined story beats.
# Visual: large dark silhouette with glowing eyes, built from stone/metal textures.

const SceneDepthClass = preload("res://scenes/videos/thing_they_opened/depth_model.gd")

signal hit_received(hit_data: RefCounted)
signal destroyed()
signal emerged()
signal attack_landed(attack_type: String)

var health: float = 500.0
var max_health: float = 500.0
var is_active: bool = false
var is_destroyed: bool = false
var has_emerged: bool = false
var base_scale: float = 1.25  # identity size; depth model scales from here

@onready var body: Node2D = get_node_or_null("Body")
@onready var eye_left: ColorRect = get_node_or_null("Body/EyeL")
@onready var eye_right: ColorRect = get_node_or_null("Body/EyeR")
@onready var hit_area: Area2D = get_node_or_null("HitArea")

func _ready() -> void:
	if hit_area:
		hit_area.add_to_group("hit_receiver")
	visible = false
	modulate.a = 0.0
	_update_depth_scale()

func _update_depth_scale() -> void:
	# Apparent size follows the shared floor-plane depth model
	SceneDepthClass.apply(self, base_scale)

# --- Emergence Sequence ---

func emerge() -> void:
	if has_emerged:
		return
	has_emerged = true
	visible = true

	# Rise from behind sealed door with menacing presence
	var start_y = position.y + 80.0
	position.y = start_y
	var target_y = start_y - 80.0

	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(self, "position:y", target_y, 1.2)
	await tw.finished

	# Eyes glow activation
	_activate_eyes()
	is_active = true
	emerged.emit()

func _activate_eyes() -> void:
	if eye_left:
		eye_left.visible = true
		var tw = create_tween()
		tw.tween_property(eye_left, "modulate:a", 1.0, 0.3).from(0.0)
	if eye_right:
		eye_right.visible = true
		var tw2 = create_tween()
		tw2.tween_property(eye_right, "modulate:a", 1.0, 0.3).from(0.0)

	# Pulsing eye glow
	var pulse_tw = create_tween().set_loops(0)
	if eye_left:
		pulse_tw.tween_property(eye_left, "color:a", 0.5, 0.8).set_trans(Tween.TRANS_SINE)
		pulse_tw.tween_property(eye_left, "color:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	if eye_right:
		var pulse_tw2 = create_tween().set_loops(0)
		pulse_tw2.tween_property(eye_right, "color:a", 0.5, 0.8).set_trans(Tween.TRANS_SINE)
		pulse_tw2.tween_property(eye_right, "color:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

# --- Attacks (Scripted) ---

func slam_attack() -> void:
	if is_destroyed or not is_active:
		return

	# Wind up: body rises slightly
	var orig_y = position.y
	var tw = create_tween()
	tw.tween_property(self, "position:y", orig_y - 30.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", orig_y + 10.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", orig_y, 0.1)
	var depth_tw = create_tween()
	depth_tw.tween_method(func(_val): _update_depth_scale(), 0.0, 1.0, 0.6)
	await tw.finished
	_update_depth_scale()

	# Ground impact
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		var vm = get_tree().root.get_node("VFXManager")
		vm.spawn_vfx("HIT_IMPACT", global_position + Vector2(-40, 0))
		vm.spawn_vfx("HIT_IMPACT", global_position + Vector2(40, 0))
		vm.spawn_vfx("DUST_PUFF", global_position + Vector2(0, 0))

	attack_landed.emit("SLAM")

func swipe_attack(direction: int = -1) -> void:
	if is_destroyed or not is_active:
		return

	# Sweeping attack: body leans and swings
	if body:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD)
		tw.tween_property(body, "rotation", direction * 0.4, 0.2).set_ease(Tween.EASE_OUT)
		tw.tween_property(body, "rotation", direction * -0.1, 0.15).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(body, "rotation", 0.0, 0.2).set_ease(Tween.EASE_OUT)
		await tw.finished

	# Swipe hit zone
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		var vm = get_tree().root.get_node("VFXManager")
		vm.spawn_vfx("HIT_IMPACT", global_position + Vector2(direction * 80, -30))

	attack_landed.emit("SWIPE")

func charge_forward(distance: float = 150.0, delta_y: float = 0.0) -> void:
	if is_destroyed or not is_active:
		return

	var orig_pos = position
	var tw = create_tween()
	tw.tween_property(self, "position", Vector2(orig_pos.x - distance, orig_pos.y + delta_y), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.2)
	tw.tween_property(self, "position", orig_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var depth_tw = create_tween()
	depth_tw.tween_method(func(_val): _update_depth_scale(), 0.0, 1.0, 1.2)
	await tw.finished
	_update_depth_scale()

	attack_landed.emit("CHARGE")

# --- Damage ---

func take_hit(hit_data = null) -> void:
	if is_destroyed:
		return

	var damage = 60.0
	if hit_data and "damage" in hit_data:
		damage = hit_data.damage

	health -= damage

	_damage_react()
	hit_received.emit(hit_data)

	if health <= 0.0:
		_destroy()

func _damage_react() -> void:
	# Flash and recoil
	var orig_mod = modulate
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(2.0, 1.5, 1.5, 1.0), 0.05)
	tw.tween_property(self, "modulate", orig_mod, 0.12)

	# Recoil
	var orig_x = position.x
	var recoil_tw = create_tween()
	recoil_tw.tween_property(self, "position:x", orig_x + 15.0, 0.06)
	recoil_tw.tween_property(self, "position:x", orig_x, 0.1)

	# Hit sparks
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		get_tree().root.get_node("VFXManager").spawn_vfx("HIT_IMPACT", global_position + Vector2(0, -50))

	# Progressive damage visuals
	var health_pct = health / max_health
	if health_pct < 0.5:
		if is_inside_tree() and get_tree().root.has_node("VFXManager"):
			get_tree().root.get_node("VFXManager").spawn_vfx("DUST_PUFF", global_position + Vector2(0, -30))

func _destroy() -> void:
	is_destroyed = true
	is_active = false

	# Collapse: sinks, fades, eyes dim
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", position.y + 40.0, 1.0)
	tw.tween_property(self, "modulate:a", 0.3, 1.2)
	tw.tween_method(func(_val): _update_depth_scale(), 0.0, 1.0, 1.0)
	if body:
		tw.tween_property(body, "rotation", 0.15, 0.8)

	if eye_left:
		eye_left.color.a = 0.0
	if eye_right:
		eye_right.color.a = 0.0

	# Final debris
	if is_inside_tree() and get_tree().root.has_node("VFXManager"):
		var vm = get_tree().root.get_node("VFXManager")
		vm.spawn_vfx("DUST_PUFF", global_position + Vector2(-30, -20))
		vm.spawn_vfx("DUST_PUFF", global_position + Vector2(20, -40))
		vm.spawn_vfx("SMOKE_BOMB", global_position + Vector2(0, -30))

	destroyed.emit()
