# floor_13_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Floor 13 (Kids Kingdom)
# Coordinates all area handlers for the kids kingdom floor
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor13Handler

const CELL_SIZE := 16

# Zone type constants for Floor 13
const ZONE_COMMON := "common"
const ZONE_KIDS_PLAY := "kids_play"
const ZONE_KIDS_CLUB := "kids_club"
const ZONE_NURSING_ROOM := "nursing_room"
const ZONE_WC := "wc"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"

# Handlers
const KidsKingdomHandler = preload("res://scripts/areas/floor_13/kids_kingdom_handler.gd")
const KidsKingdomCommonHandler = preload("res://scripts/areas/floor_13/kids_kingdom_common_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")

var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 13

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes

func build_floor_13(zones: Array) -> void:
	"""Build all areas for Floor 13"""
	for zone in zones:
		match zone.type:
			ZONE_COMMON:
				KidsKingdomCommonHandler.build_kids_kingdom_common(_parent, zone, _floor_nodes)
			ZONE_KIDS_PLAY:
				KidsKingdomHandler.build_kids_play(_parent, zone, _floor_nodes)
			ZONE_KIDS_CLUB:
				KidsKingdomHandler.build_kids_club(_parent, zone, _floor_nodes)
			ZONE_NURSING_ROOM:
				KidsKingdomHandler.build_nursing_room(_parent, zone, _floor_nodes)
			ZONE_WC:
				KidsKingdomHandler.build_family_wc(_parent, zone, _floor_nodes)
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "13")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)

# Static helper to check if a zone belongs to Floor 13
static func is_floor_13_zone(zone_type: String) -> bool:
	return zone_type in [
		ZONE_COMMON,
		ZONE_KIDS_PLAY,
		ZONE_KIDS_CLUB,
		ZONE_NURSING_ROOM,
		ZONE_WC,
		ZONE_ELEVATOR,
		ZONE_STAIRS
	]
