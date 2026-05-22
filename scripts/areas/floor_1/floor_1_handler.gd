# floor_1_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 1 (Shoes Floor)
# Coordinates all area handlers for the shoes floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor1Handler

const CELL_SIZE := 16

# Zone type constants (matching FloorConfig)
const ZONE_SHOES_RACK := "shoes_rack"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const ShoesRackHandler = preload("res://scripts/areas/floor_1/shoes_rack_handler.gd")
const CommonAreaHandler = preload("res://scripts/areas/floor_1/common_area_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 1  # Floor 1 (index 1, label "1")
var _ad_index := 0  # For cycling through different ad colors/texts

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_1(zones: Array) -> void:
	"""Build all areas for Floor 1"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				CommonAreaHandler.build_common_area(_parent, zone, _floor_nodes)
			ZONE_SHOES_RACK:
				ShoesRackHandler.build_shoes_rack(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "1")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 1
static func is_floor_1_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_SHOES_RACK,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]
