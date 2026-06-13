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
				build_warehouse(_parent, zone, _floor_nodes)
			ZONE_TRUCK_DOCK:
				TruckDockHandler.build_truck_dock(_parent, zone, _floor_nodes)
			ZONE_FORKLIFT:
				build_forklift_zone(_parent, zone, _floor_nodes)
			ZONE_CONVEYOR:
				ConveyorHandler.build_conveyor(_parent, zone, _floor_nodes)
			ZONE_PACKING_STATION:
				build_packing_station(_parent, zone, _floor_nodes)
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

# ─── Inlined zone tile-painters ──────────────────────────────────────

static func build_warehouse(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.color = Color(0.45, 0.38, 0.32)  # Industrial concrete color
	parent.add_child(base)
	floor_nodes.append(base)

	# Add warehouse floor pattern (shelf lines)
	for i in range(zone.y + 2, zone.y + zone.h - 2, 4):
		var line := ColorRect.new()
		line.position = Vector2(zone.x * CELL_SIZE, i * CELL_SIZE)
		line.size = Vector2(zone.w * CELL_SIZE, 1)
		line.color = Color(0.35, 0.28, 0.22)
		parent.add_child(line)
		floor_nodes.append(line)

static func build_forklift_zone(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	# Yellow-ish for forklift/equipment area
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.75, 0.6, 0.2)
	parent.add_child(base)
	floor_nodes.append(base)

	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)

static func build_packing_station(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.4, 0.65, 0.45)  # Green-ish for packing
	parent.add_child(base)
	floor_nodes.append(base)

	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)
