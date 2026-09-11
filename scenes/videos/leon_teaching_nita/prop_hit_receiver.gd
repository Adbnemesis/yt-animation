class_name PropHitReceiver
extends Area2D

# Specialized hit-receiving Area2D for props in the training grounds.
# Ensures authoritative projectile collision detection:
# Projectile collision invokes take_hit(), transmitting the exact impact position.

signal hit_received(hit_data: RefCounted)

func _ready() -> void:
	add_to_group("hit_receiver")
	collision_layer = 4
	collision_mask = 8

func take_hit(hit_data: RefCounted) -> void:
	hit_received.emit(hit_data)
