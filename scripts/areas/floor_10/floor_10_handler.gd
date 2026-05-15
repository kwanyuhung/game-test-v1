# floor_10_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 10 (Rooftop Cafe)
# Coordinates all area handlers for the rooftop floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor10Handler

const CELL_SIZE := 16

# Zone type constants for Floor 10
const ZONE_COMMON := "common"
const ZONE_CAFE_COUNTER := "cafe_counter"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const CafeCounterHandler = preload("res://scripts/areas/floor_10/cafe_counter_handler.gd")
const RooftopCommonHandler = preload("res://scripts/areas/floor_10/rooftop_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 10
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_10(zones: Array) -> void:
	"""Build all areas for Floor 10"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				RooftopCommonHandler.build_rooftop_common(_parent, zone, _floor_nodes)
			ZONE_CAFE_COUNTER:
				CafeCounterHandler.build_cafe_counter(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "10")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 10
static func is_floor_10_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_COMMON,
		ZONE_CAFE_COUNTER,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]
