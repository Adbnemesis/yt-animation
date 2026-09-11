extends ProjectileBase
class_name BoProjectile

# Bo's Arrow Projectile (Basic Attack)
# Reuses the universal ProjectileBase framework for deterministic movement,
# range/lifetime expiration, and exactly-one-hit collision. Adds only
# Bo-specific behavior:
#   - tuning synced from Bo's single BrawlerConfig source of truth
#   - arrow visual aligned to the captured firing direction
#   - Bo-specific impact audio hook on projectile collision

const BoAdapterClass := preload("res://templates/brawler/bo_adapter.gd")
const CHARACTER_ID := "bo"

func _ready() -> void:
	# Single source of truth for speed / range / damage: Bo's BrawlerConfig.
	var cfg := BoAdapterClass.get_bo_config()
	if cfg:
		speed = cfg.projectile_speed
		max_range = cfg.projectile_range
		damage = cfg.damage_per_projectile
	attack_type = "BO_BASIC"
	spin_speed = 0.0

	super._ready()
	hit_target.connect(_on_hit_target)

func initialize(origin_pos: Vector2, aim_dir: Vector2, p_source: Node = null) -> void:
	super.initialize(origin_pos, aim_dir, p_source)
	_align_visual()

func _align_visual() -> void:
	# The approved Bo arrow artwork points toward +X; rotate to the captured
	# firing direction. The direction never changes after spawn.
	if visual:
		visual.rotation = direction.angle()

func _on_hit_target(_target: Node, _hit_data: RefCounted) -> void:
	# Impact audio fires ONLY from the projectile collision (causality:
	# arrow must actually reach the target before any hit feedback).
	if is_inside_tree() and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").trigger_event("HIT", {
			"character": CHARACTER_ID,
			"position": global_position
		})