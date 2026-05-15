# floor_7_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 7 (Back Office)
# Coordinates all area handlers for the back office floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor7Handler

const CELL_SIZE := 16

# Zone type constants for Floor 7
const ZONE_OFFICE_DESK := "office_desk"
const ZONE_MONITOR_ROOM := "monitor_room"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"

# Handlers
const OfficeDeskHandler = preload("res://scripts/areas/floor_7/office_desk_handler.gd")
const MonitorRoomHandler = preload("res://scripts/areas/floor_7/monitor_room_handler.gd")
const BackOfficeCommonHandler = preload("res://scripts/areas/floor_7/back_office_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 7  # Floor 7 (index 7, label "7")

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_7(zones: Array) -> void:
	"""Build all areas for Floor 7"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				BackOfficeCommonHandler.build_back_office_common(_parent, zone, _floor_nodes)
			ZONE_OFFICE_DESK:
				OfficeDeskHandler.build_office_desk(_parent, zone, _floor_nodes)
			ZONE_MONITOR_ROOM:
				MonitorRoomHandler.build_monitor_room(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "7")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)

# Static helper to check if a zone belongs to Floor 7
static func is_floor_7_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_OFFICE_DESK,
		ZONE_MONITOR_ROOM,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS
	]