# floor_3_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 3 (Sport)
# Coordinates all area handlers for the sports floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor3Handler

const CELL_SIZE := 16

# Zone type constants for Floor 3
const ZONE_SPORT_AREA := "sport_area"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const SportAreaHandler = preload("res://scripts/areas/floor_3/sport_area_handler.gd")
const SportCommonHandler = preload("res://scripts/areas/floor_3/sport_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 3  # Floor 3 (index 3, label "3")
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_3(zones: Array) -> void:
	"""Build all areas for Floor 3"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				SportCommonHandler.build_sport_common(_parent, zone, _floor_nodes)
			ZONE_SPORT_AREA:
				SportAreaHandler.build_sport_area(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "3")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 3
static func is_floor_3_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_SPORT_AREA,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]