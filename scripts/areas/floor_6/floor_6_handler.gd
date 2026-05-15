# floor_6_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 6 (Staff Area)
# Coordinates all area handlers for the staff area floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor6Handler

const CELL_SIZE := 16

# Zone type constants for Floor 6
const ZONE_LOCKER := "locker"
const ZONE_STAFF_LOUNGE := "staff_lounge"
const ZONE_TRAINING := "training"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"

# Handlers
const LockerHandler = preload("res://scripts/areas/floor_6/locker_handler.gd")
const StaffLoungeHandler = preload("res://scripts/areas/floor_6/staff_lounge_handler.gd")
const TrainingHandler = preload("res://scripts/areas/floor_6/training_handler.gd")
const StaffAreaCommonHandler = preload("res://scripts/areas/floor_6/staff_area_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 6  # Floor 6 (index 6, label "6")

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_6(zones: Array) -> void:
	"""Build all areas for Floor 6"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				StaffAreaCommonHandler.build_staff_area_common(_parent, zone, _floor_nodes)
			ZONE_LOCKER:
				LockerHandler.build_locker(_parent, zone, _floor_nodes)
			ZONE_STAFF_LOUNGE:
				StaffLoungeHandler.build_staff_lounge(_parent, zone, _floor_nodes)
			ZONE_TRAINING:
				TrainingHandler.build_training(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "6")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)

# Static helper to check if a zone belongs to Floor 6
static func is_floor_6_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_LOCKER,
		ZONE_STAFF_LOUNGE,
		ZONE_TRAINING,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS
	]