class_name LeonAdapter
extends RefCounted

# Thin Leon Adapter for Brawler Template
# Bridges existing production Leon instance to generic Brawler template interface
# without modifying Leon's original scripts or scenes.

const LEON_CONFIG_PATH := "res://templates/brawler/brawler_config_leon.tres"

static func get_leon_config() -> BrawlerConfig:
	return load(LEON_CONFIG_PATH) as BrawlerConfig

static func validate_leon(leon_node: Node) -> Dictionary:
	return BrawlerBuilder.validate_brawler(leon_node)
