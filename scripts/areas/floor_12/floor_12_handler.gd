# floor_12_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 12 (Juice Bar)
# Coordinates all area handlers for the juice bar floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor12Handler

const CELL_SIZE := 16

# Zone type constants for Floor 12
const ZONE_COMMON := "common"
const ZONE_JUICE_BAR := "juice_bar"
const ZONE_HEALTH_FOOD := "health_food"
const ZONE_SMOOTHIE := "smoothie"
const ZONE_SALAD_BAR := "salad_bar"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_AD := "ad"

# Handlers
const JuiceBarHandler = preload("res://scripts/areas/floor_12/juice_bar_handler.gd")
const JuiceBarCommonHandler = preload("res://scripts/areas/floor_12/juice_bar_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 12
var _ad_index := 0

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_12(zones: Array) -> void:
	"""Build all areas for Floor 12"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				JuiceBarCommonHandler.build_juice_bar_common(_parent, zone, _floor_nodes)
			ZONE_JUICE_BAR:
				JuiceBarHandler.build_juice_bar(_parent, zone, _floor_nodes)
			ZONE_HEALTH_FOOD:
				JuiceBarHandler.build_health_food(_parent, zone, _floor_nodes)
			ZONE_SMOOTHIE:
				JuiceBarHandler.build_smoothie(_parent, zone, _floor_nodes)
			ZONE_SALAD_BAR:
				JuiceBarHandler.build_salad_bar(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "12")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1

# Static helper to check if a zone belongs to Floor 12
static func is_floor_12_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_COMMON,
		ZONE_JUICE_BAR,
		ZONE_HEALTH_FOOD,
		ZONE_SMOOTHIE,
		ZONE_SALAD_BAR,
		ZONE_ELEVATOR,
		ZONE_STAIRS,
		ZONE_AD
	]
