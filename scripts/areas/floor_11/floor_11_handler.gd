# floor_11_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 11 (Warehouse)
# Coordinates all area handlers for the warehouse floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor11Handler

const CELL_SIZE := 16

# Zone type constants for Floor 11
const ZONE_WAREHOUSE := "warehouse"
const ZONE_TRUCK_DOCK := "truck_dock"
const ZONE_FORKLIFT := "forklift"
const ZONE_CONVEYOR := "conveyor"
const ZONE_PACKING_STATION := "packing_station"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_AD := "ad"

# Handlers
const WarehouseFloorHandler = preload("res://scripts/areas/floor_11/warehouse_floor_handler.gd")
const TruckDockHandler = preload("res://scripts/areas/floor_11/truck_dock_handler.gd")
const ConveyorHandler = preload("res://scripts/areas/floor_11/conveyor_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 11
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_11(zones: Array) -> void:
	"""Build all areas for Floor 11"""
	for zone in zones:
		match zone.type:
			ZONE_WAREHOUSE:
				WarehouseFloorHandler.build_warehouse(_parent, zone, _floor_nodes)
			ZONE_TRUCK_DOCK:
				TruckDockHandler.build_truck_dock(_parent, zone, _floor_nodes)
			ZONE_FORKLIFT:
				WarehouseFloorHandler.build_forklift_zone(_parent, zone, _floor_nodes)
			ZONE_CONVEYOR:
				ConveyorHandler.build_conveyor(_parent, zone, _floor_nodes)
			ZONE_PACKING_STATION:
				WarehouseFloorHandler.build_packing_station(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "11")
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 11
static func is_floor_11_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_WAREHOUSE,
		ZONE_TRUCK_DOCK,
		ZONE_FORKLIFT,
		ZONE_CONVEYOR,
		ZONE_PACKING_STATION,
		ZONE_ELEVATOR,
		ZONE_AD
	]
