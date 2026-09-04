class_name BrawlerHitReceiver
extends Area2D

# Modular Hit Receiver & Damage/Knockback Component for Brawlers

signal hit_received(hit_data: RefCounted)
signal health_changed(new_hp: float, max_hp: float)
signal died()

@export var max_health: float = 1000.0
var current_health: float = 1000.0
var knockback_resistance: float = 1.0

var brawler: CharacterBody2D = null

func _ready() -> void:
	add_to_group("hit_receiver")
	brawler = get_parent() as CharacterBody2D
	current_health = max_health

func configure(max_hp: float, kb_res: float) -> void:
	max_health = max_hp
	current_health = max_hp
	knockback_resistance = kb_res
	health_changed.emit(current_health, max_health)

func take_hit(hit_data: RefCounted) -> void:
	var damage = hit_data.damage if "damage" in hit_data else 100.0
	var direction = hit_data.direction if "direction" in hit_data else Vector2.RIGHT
	var force = hit_data.force if "force" in hit_data else 120.0

	current_health = max(0.0, current_health - damage)
	health_changed.emit(current_health, max_health)

	# Apply knockback to character body if available
	if brawler:
		var effective_force = force * knockback_resistance
		brawler.velocity = direction * effective_force

		# Notify brawler controller to transition to HIT or KNOCKBACK state
		if brawler.has_method("on_hit_received"):
			brawler.on_hit_received(hit_data)

	hit_received.emit(hit_data)

	if current_health <= 0.0:
		died.emit()
		if brawler and brawler.has_method("on_death"):
			brawler.on_death()
