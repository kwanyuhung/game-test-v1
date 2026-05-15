# floor_2_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 2 (Fashion)
# Coordinates all area handlers for the fashion floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor2Handler

const CELL_SIZE := 16

# Zone type constants for Floor 2
const ZONE_DRESS_RACK := "dress_rack"
const ZONE_COMMON := "common"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const DressRackHandler = preload("res://scripts/areas/floor_2/dress_rack_handler.gd")
const FashionCommonHandler = preload("res://scripts/areas/floor_2/fashion_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 2  # Floor 2 (index 2, label "2")
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_2(zones: Array) -> void:
	"""Build all areas for Floor 2"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				FashionCommonHandler.build_fashion_common(_parent, zone, _floor_nodes)
			ZONE_DRESS_RACK:
				DressRackHandler.build_dress_rack(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "2")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 2
static func is_floor_2_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_DRESS_RACK,
		ZONE_COMMON,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]