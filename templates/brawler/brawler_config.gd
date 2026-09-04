class_name BrawlerConfig
extends Resource

# Reusable Configuration Resource for Brawlers
# Centralizes movement, combat, ability, audio, and VFX parameters.

@export_group("Identity")
@export var character_name: String = "Generic Brawler"
@export var character_id: String = "brawler_generic"

@export_group("Locomotion & Physics")
@export var walk_speed: float = 160.0
@export var run_speed: float = 300.0
@export var jump_velocity: float = -460.0
@export var gravity: float = 1200.0
@export var acceleration: float = 1800.0
@export var friction: float = 2000.0

@export_group("Health & Combat")
@export var max_health: float = 1000.0
@export var knockback_resistance: float = 1.0 # Multiplier (1.0 = normal, 0.5 = 50% reduction)
@export var attack_duration: float = 0.36
@export var projectiles_per_burst: int = 1
@export var burst_interval: float = 0.030
@export var spread_angles: Array[float] = [0.0]
@export var projectile_scene: PackedScene = null
@export var damage_per_projectile: float = 25.0
@export var projectile_speed: float = 650.0
@export var projectile_range: float = 550.0

@export_group("Super Ability")
@export var super_duration: float = 5.0
@export var super_type: String = "custom"

@export_group("Audio & VFX Mappings")
# Maps BrawlerEvents strings to AudioManager sound IDs
@export var audio_event_map: Dictionary = {
	"ATTACK_RELEASE": "leon_atk_01",
	"PROJECTILE_SPAWN": "leon_atk_01",
	"JUMP": "springboard_jump_01",
	"LAND": "princess_land_01",
	"SUPER_START": "leon_invis_01",
	"SUPER_END": "leon_invis_end_01",
	"CHARACTER_HIT": "leon_hurt_vo_01",
	"DEATH": "leon_die_vo_01"
}
# Maps BrawlerEvents strings to VFX scene paths or names
@export var vfx_event_map: Dictionary = {
	"LAND": "DUST_PUFF",
	"PROJECTILE_SPAWN": "SPAWN_FLASH",
	"HIT": "HIT_IMPACT",
	"SUPER_START": "SMOKE_BOMB",
	"SUPER_END": "SMOKE_BOMB"
}
