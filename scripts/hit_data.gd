class_name HitData
extends RefCounted

var damage: float = 100.0
var direction: Vector2 = Vector2.RIGHT
var force: float = 120.0
var source: Node = null
var attack_type: String = "LEON_BASIC"
var hit_position: Vector2 = Vector2.ZERO

static func create(
	p_damage: float = 100.0,
	p_direction: Vector2 = Vector2.RIGHT,
	p_force: float = 120.0,
	p_source: Node = null,
	p_attack_type: String = "LEON_BASIC",
	p_hit_position: Vector2 = Vector2.ZERO
) -> HitData:
	var h = HitData.new()
	h.damage = p_damage
	h.direction = p_direction.normalized() if p_direction != Vector2.ZERO else Vector2.RIGHT
	h.force = p_force
	h.source = p_source
	h.attack_type = p_attack_type
	h.hit_position = p_hit_position
	return h
