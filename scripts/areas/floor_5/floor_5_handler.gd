# floor_5_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 5 (Stationery)
# Coordinates all area handlers for the stationery & plants floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor5Handler

const CELL_SIZE := 16

# Zone type constants for Floor 5
const ZONE_STATIONERY := "stationery"
const ZONE_PLANTS_AREA := "plants_area"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const StationeryHandler = preload("res://scripts/areas/floor_5/stationery_handler.gd")
const PlantsAreaHandler = preload("res://scripts/areas/floor_5/plants_area_handler.gd")
const StationeryCommonHandler = preload("res://scripts/areas/floor_5/stationery_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 5  # Floor 5 (index 5, label "5")
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_5(zones: Array) -> void:
	"""Build all areas for Floor 5"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				StationeryCommonHandler.build_stationery_common(_parent, zone, _floor_nodes)
			ZONE_STATIONERY:
				StationeryHandler.build_stationery(_parent, zone, _floor_nodes)
			ZONE_PLANTS_AREA:
				PlantsAreaHandler.build_plants_area(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "5")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 5
static func is_floor_5_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_STATIONERY,
		ZONE_PLANTS_AREA,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]