# floor_9_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 9 (Staff Room)
# Coordinates all area handlers for the staff room floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor9Handler

const CELL_SIZE := 16

# Zone type constants for Floor 9
const ZONE_STAFF_ROOM := "staff_room"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"

# Handlers
const StaffRoomHandler = preload("res://scripts/areas/floor_9/staff_room_handler.gd")
const StaffRoomCommonHandler = preload("res://scripts/areas/floor_9/staff_room_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 9  # Floor 9 (index 9, label "9")

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_9(zones: Array) -> void:
	"""Build all areas for Floor 9"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				StaffRoomCommonHandler.build_staff_room_common(_parent, zone, _floor_nodes)
			ZONE_STAFF_ROOM:
				StaffRoomHandler.build_staff_room(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "9")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)

# Static helper to check if a zone belongs to Floor 9
static func is_floor_9_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_STAFF_ROOM,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS
	]