# floor_14_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 14 (Electronics)
# Coordinates all area handlers for the electronics floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor14Handler

const CELL_SIZE := 16

# Zone type constants for Floor 14
const ZONE_COMMON := "common"
const ZONE_PHONE_GADGETS := "phone_gadgets"
const ZONE_SMART_HOME := "smart_home"
const ZONE_ELECTRONICS := "electronics"
const ZONE_REPAIR_COUNTER := "repair_counter"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const ElectronicsHandler = preload("res://scripts/areas/floor_14/electronics_handler.gd")
const ElectronicsCommonHandler = preload("res://scripts/areas/floor_14/electronics_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 14
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_14(zones: Array) -> void:
	"""Build all areas for Floor 14"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				ElectronicsCommonHandler.build_electronics_common(_parent, zone, _floor_nodes)
			ZONE_PHONE_GADGETS:
				ElectronicsHandler.build_phone_gadgets(_parent, zone, _floor_nodes)
			ZONE_SMART_HOME:
				ElectronicsHandler.build_smart_home(_parent, zone, _floor_nodes)
			ZONE_ELECTRONICS:
				ElectronicsHandler.build_electronics(_parent, zone, _floor_nodes)
			ZONE_REPAIR_COUNTER:
				ElectronicsHandler.build_repair_counter(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "14")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 14
static func is_floor_14_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_COMMON,
		ZONE_PHONE_GADGETS,
		ZONE_SMART_HOME,
		ZONE_ELECTRONICS,
		ZONE_REPAIR_COUNTER,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]
