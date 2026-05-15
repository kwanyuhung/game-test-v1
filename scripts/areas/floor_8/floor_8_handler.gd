# floor_8_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 8 (Executive Office)
# Coordinates all area handlers for the executive office floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor8Handler

const CELL_SIZE := 16

# Zone type constants for Floor 8
const ZONE_EXEC_OFFICE := "exec_office"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"

# Handlers
const ExecOfficeHandler = preload("res://scripts/areas/floor_8/exec_office_handler.gd")
const ExecOfficeCommonHandler = preload("res://scripts/areas/floor_8/exec_office_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 8  # Floor 8 (index 8, label "8")

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_8(zones: Array) -> void:
	"""Build all areas for Floor 8"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				ExecOfficeCommonHandler.build_exec_office_common(_parent, zone, _floor_nodes)
			ZONE_EXEC_OFFICE:
				ExecOfficeHandler.build_exec_office(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "8")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)

# Static helper to check if a zone belongs to Floor 8
static func is_floor_8_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_EXEC_OFFICE,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS
	]