class_name NitaAdapter
extends RefCounted

# Thin Nita Adapter for Brawler Template
# Bridges existing production Nita instance to generic Brawler template interface
# without modifying Nita's original scripts or scenes.

const NITA_CONFIG_PATH := "res://templates/brawler/brawler_config_nita.tres"

static func get_nita_config() -> BrawlerConfig:
	return load(NITA_CONFIG_PATH) as BrawlerConfig

static func validate_nita(nita_node: Node) -> Dictionary:
	return BrawlerBuilder.validate_brawler(nita_node)
