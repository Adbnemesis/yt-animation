class_name BoAdapter
extends RefCounted

# Thin Bo Adapter for Brawler Template
# Bridges Bo brawler instance to generic Brawler template interface
# without modifying existing systems or scenes.

const BO_CONFIG_PATH := "res://templates/brawler/brawler_config_bo.tres"

static func get_bo_config() -> BrawlerConfig:
	return load(BO_CONFIG_PATH) as BrawlerConfig

static func validate_bo(bo_node: Node) -> Dictionary:
	return BrawlerBuilder.validate_brawler(bo_node)
