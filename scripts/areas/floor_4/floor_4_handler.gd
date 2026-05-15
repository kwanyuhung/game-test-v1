# floor_4_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 4 (Outdoor)
# Coordinates all area handlers for the outdoor gear floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor4Handler

const CELL_SIZE := 16

# Zone type constants for Floor 4
const ZONE_OUTDOOR_AREA := "outdoor_area"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const OutdoorAreaHandler = preload("res://scripts/areas/floor_4/outdoor_area_handler.gd")
const OutdoorCommonHandler = preload("res://scripts/areas/floor_4/outdoor_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 4  # Floor 4 (index 4, label "4")
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_4(zones: Array) -> void:
	"""Build all areas for Floor 4"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				OutdoorCommonHandler.build_outdoor_common(_parent, zone, _floor_nodes)
			ZONE_OUTDOOR_AREA:
				OutdoorAreaHandler.build_outdoor_area(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "4")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 4
static func is_floor_4_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_OUTDOOR_AREA,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]