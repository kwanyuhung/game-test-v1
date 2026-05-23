# floor_0_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Ground Floor (Floor G - Index 0)
# Coordinates all area handlers for the lobby/food court floor
# Uses Floor0Config for structured zone and spawn organization
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor0Handler

const CELL_SIZE := 16

# ─── Zone Type Constants ────────────────────────────────────────────────
# Using Floor0Config zone constants for consistency
const ZONE_LOBBY := Floor0Config.ZONE_LOBBY
const ZONE_INFO_DESK := Floor0Config.ZONE_INFO_DESK
const ZONE_WC := Floor0Config.ZONE_WC
const ZONE_AD := Floor0Config.ZONE_AD
const ZONE_ATM := Floor0Config.ZONE_ATM
const ZONE_CUSTOMER_SERVICE := Floor0Config.ZONE_CUSTOMER_SERVICE
const ZONE_LOYALTY_KIOSK := Floor0Config.ZONE_LOYALTY_KIOSK
const ZONE_GIFT_WRAP := Floor0Config.ZONE_GIFT_WRAP
const ZONE_DIGITAL_KIOSK := Floor0Config.ZONE_DIGITAL_KIOSK
const ZONE_FOOD_STALL := Floor0Config.ZONE_FOOD_STALL
const ZONE_WAREHOUSE := Floor0Config.ZONE_WAREHOUSE
const ZONE_TRUCK_DOCK := Floor0Config.ZONE_TRUCK_DOCK
const ZONE_FORKLIFT := Floor0Config.ZONE_FORKLIFT
const ZONE_CONVEYOR := Floor0Config.ZONE_CONVEYOR
const ZONE_STORAGE_SHELF := Floor0Config.ZONE_STORAGE_SHELF
const ZONE_ELEVATOR := Floor0Config.ZONE_ELEVATOR
const ZONE_STAIRS := Floor0Config.ZONE_STAIRS
const ZONE_ESCALATOR := Floor0Config.ZONE_ESCALATOR
const ZONE_DECOR := Floor0Config.ZONE_DECOR
const ZONE_VENDING_MACHINE := Floor0Config.ZONE_VENDING_MACHINE
const ZONE_PROMO_BOOTH := Floor0Config.ZONE_PROMO_BOOTH
const ZONE_WAREHOUSE_STOCK_VIEW := Floor0Config.ZONE_WAREHOUSE_STOCK_VIEW
const ZONE_LOST_FOUND := Floor0Config.ZONE_LOST_FOUND
const ZONE_STORE_NEWS := Floor0Config.ZONE_STORE_NEWS

# Area constants
const AREA_LOBBY := Floor0Config.AREA_LOBBY
const AREA_FOOD_COURT := Floor0Config.AREA_FOOD_COURT
const AREA_WAREHOUSE := Floor0Config.AREA_WAREHOUSE
const AREA_TRANSIT := Floor0Config.AREA_TRANSIT

# ─── Handler Preloads ────────────────────────────────────────────────────
const LobbyHandler = preload("res://scripts/areas/floor_0/lobby_handler.gd")
const FoodStallHandler = preload("res://scripts/areas/floor_0/food_stall_handler.gd")
const ServiceAreaHandler = preload("res://scripts/areas/floor_0/service_area_handler.gd")
const WCHandler = preload("res://scripts/areas/shared/wc_handler.gd")
const WarehouseHandler = preload("res://scripts/areas/floor_0/warehouse_handler.gd")
const MiscHandler = preload("res://scripts/areas/floor_0/misc_handler.gd")
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")

# ─── Floor 0 Configuration Reference ────────────────────────────────────
var _floor_config: Floor0Config

# ─── Instance State ─────────────────────────────────────────────────────
var _parent: Node
var _floor_nodes: Array
var _floor_idx: int = 0  # Ground floor (index 0, label "G")
var _ad_index := 0  # For cycling through different ad colors/texts

func _init(parent: Node, floor_nodes: Array) -> void:
	_parent = parent
	_floor_nodes = floor_nodes
	_floor_config = Floor0Config.new()

# ─── Main Building Interface ─────────────────────────────────────────────

func build_floor_0(zones: Array) -> void:
	"""Build all areas for Ground Floor"""
	for zone in zones:
		match zone.type:
			ZONE_LOBBY:
				LobbyHandler.build_lobby(_parent, zone, _floor_nodes)
			ZONE_WC:
				WCHandler.build_wc(_parent, zone, _floor_nodes)
			ZONE_AD:
				AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
				_ad_index += 1
			ZONE_ATM:
				MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_ATM")
			ZONE_CUSTOMER_SERVICE, ZONE_LOYALTY_KIOSK, ZONE_GIFT_WRAP, ZONE_DIGITAL_KIOSK:
				ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, zone.type)
			ZONE_INFO_DESK:
				ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, "ZONE_INFO_DESK")
			ZONE_FOOD_STALL:
				FoodStallHandler.build_food_stall(_parent, zone, _floor_nodes)
			ZONE_WAREHOUSE:
				WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_WAREHOUSE")
			ZONE_TRUCK_DOCK:
				WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_TRUCK_DOCK")
			ZONE_FORKLIFT:
				WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_FORKLIFT")
			ZONE_CONVEYOR:
				WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_CONVEYOR")
			ZONE_STORAGE_SHELF:
				WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_STORAGE_SHELF")
			ZONE_WAREHOUSE_STOCK_VIEW:
				WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_WAREHOUSE_STOCK_VIEW")
			ZONE_ELEVATOR:
				ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
				ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, "G")
			ZONE_STAIRS:
				StairsHandler.build_stairs(_parent, zone, _floor_nodes)
			ZONE_ESCALATOR:
				# Escalator uses its own script
				pass
			ZONE_DECOR:
				MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_DECOR")
			ZONE_VENDING_MACHINE:
				MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_VENDING_MACHINE")
			ZONE_PROMO_BOOTH:
				MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_PROMO_BOOTH")
			ZONE_LOST_FOUND:
				MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_LOST_FOUND")
			ZONE_STORE_NEWS:
				MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_STORE_NEWS")

# ─── Area-Based Building ─────────────────────────────────────────────────
# Build all zones belonging to a specific area

func build_area(area_id: String, zones: Array) -> void:
	"""Build only zones belonging to the specified area"""
	var area = _floor_config.get_area(area_id)
	if area == null:
		return
	
	for zone in zones:
		if zone.type in area.zone_types:
			# Route to appropriate builder
			_build_zone_for_area(zone, area_id)

func _build_zone_for_area(zone: Dictionary, area_id: String) -> void:
	"""Build a single zone, routed based on area context"""
	match zone.type:
		ZONE_LOBBY:
			LobbyHandler.build_lobby(_parent, zone, _floor_nodes)
		ZONE_WC:
			WCHandler.build_wc(_parent, zone, _floor_nodes)
		ZONE_AD:
			AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _ad_index)
			_ad_index += 1
		ZONE_ATM:
			MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_ATM")
		ZONE_CUSTOMER_SERVICE, ZONE_LOYALTY_KIOSK, ZONE_GIFT_WRAP, ZONE_DIGITAL_KIOSK:
			ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, zone.type)
		ZONE_INFO_DESK:
			ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, "ZONE_INFO_DESK")
		ZONE_FOOD_STALL:
			FoodStallHandler.build_food_stall(_parent, zone, _floor_nodes)
		ZONE_DECOR:
			MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_DECOR")
		ZONE_VENDING_MACHINE:
			MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_VENDING_MACHINE")
		ZONE_PROMO_BOOTH:
			MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_PROMO_BOOTH")
		ZONE_LOST_FOUND:
			MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_LOST_FOUND")
		ZONE_STORE_NEWS:
			MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_STORE_NEWS")

# ─── Spawn Point Access ─────────────────────────────────────────────────
# Get spawn points for NPCs and robots organized by area

func get_lobby_spawns() -> Array:
	return _floor_config.get_spawns_by_area(AREA_LOBBY)

func get_food_court_spawns() -> Array:
	return _floor_config.get_spawns_by_area(AREA_FOOD_COURT)

func get_warehouse_spawns() -> Array:
	return _floor_config.get_spawns_by_area(AREA_WAREHOUSE)

func get_transit_spawns() -> Array:
	return _floor_config.get_spawns_by_area(AREA_TRANSIT)

func get_all_spawns() -> Array:
	var all_spawns := []
	all_spawns.append_array(get_lobby_spawns())
	all_spawns.append_array(get_food_court_spawns())
	all_spawns.append_array(get_warehouse_spawns())
	all_spawns.append_array(get_transit_spawns())
	return all_spawns

func get_spawn_world_pos(spawn: Floor0Config.EntitySpawnDef) -> Vector2:
	return _floor_config.get_spawn_world_pos(spawn)

# ─── NPC Staff Spawn Helpers ────────────────────────────────────────────

func get_npc_staff_spawns() -> Array:
	return _floor_config.get_npc_staff_spawns()

func get_npc_spawns_by_role(role: String) -> Array:
	return _floor_config.get_spawns_by_role("npc_staff", role)

func get_greeter_spawns() -> Array:
	return get_npc_spawns_by_role("GREETER")

func get_customer_service_spawns() -> Array:
	return get_npc_spawns_by_role("CUSTOMER_SERVICE")

func get_shelf_stocker_spawns() -> Array:
	return get_npc_spawns_by_role("SHELF_STOCKER")

func get_floor_staff_spawns() -> Array:
	return get_npc_spawns_by_role("FLOOR_STAFF")

# ─── Robot Spawn Helpers ────────────────────────────────────────────────

func get_robot_spawns() -> Array:
	return _floor_config.get_robot_spawns()

func get_humanoid_robot_spawns() -> Array:
	return _floor_config.get_humanoid_robot_spawns()

func get_single_robot_spawns() -> Array:
	return _floor_config.get_single_robot_spawns()

func get_robot_spawns_by_role(role: String) -> Array:
	var result := []
	result.append_array(_floor_config.get_spawns_by_role("robot_humanoid", role))
	result.append_array(_floor_config.get_spawns_by_role("robot_single", role))
	return result

func get_cleaning_robot_spawns() -> Array:
	return get_robot_spawns_by_role("CLEANING_ROBOT")

func get_guidance_robot_spawns() -> Array:
	return get_robot_spawns_by_role("GUIDANCE_ROBOT")

func get_security_robot_spawns() -> Array:
	return get_robot_spawns_by_role("SECURITY_ROBOT")

func get_delivery_robot_spawns() -> Array:
	return get_robot_spawns_by_role("DELIVERY_ROBOT")

func get_shelf_robot_spawns() -> Array:
	return get_robot_spawns_by_role("SHELF_ROBOT")

# ─── Area Information ───────────────────────────────────────────────────

func get_area(area_id: String) -> Floor0Config.AreaDef:
	return _floor_config.get_area(area_id)

func get_all_areas() -> Array:
	return _floor_config.get_all_areas()

func get_area_by_zone_type(zone_type: String) -> Floor0Config.AreaDef:
	return _floor_config.get_area_by_zone_type(zone_type)

func get_area_by_point(px: int, py: int) -> Floor0Config.AreaDef:
	return _floor_config.get_area_by_point(px, py)

func get_lobby_area() -> Floor0Config.AreaDef:
	return _floor_config.get_area(AREA_LOBBY)

func get_food_court_area() -> Floor0Config.AreaDef:
	return _floor_config.get_area(AREA_FOOD_COURT)

func get_warehouse_area() -> Floor0Config.AreaDef:
	return _floor_config.get_area(AREA_WAREHOUSE)

func get_transit_area() -> Floor0Config.AreaDef:
	return _floor_config.get_area(AREA_TRANSIT)

# ─── Zone Type Utilities ────────────────────────────────────────────────

func get_all_zone_types() -> Array:
	return _floor_config.get_all_zone_types()

func is_floor_0_zone(zone_type: String) -> bool:
	return _floor_config.is_floor_0_zone(zone_type)

func get_zone_types_for_area(area_id: String) -> Array:
	var area = _floor_config.get_area(area_id)
	if area:
		return area.zone_types
	return []

# ─── Debug Interface ────────────────────────────────────────────────────

func get_debug_info() -> String:
	return _floor_config.get_debug_info()

# ─── Static Helpers ─────────────────────────────────────────────────────
# For compatibility with existing code that uses static is_floor_0_zone()

static func is_zone_type_floor_0(zone_type: String) -> bool:
	# Delegate to Floor0Config for accurate zone checking
	var config = Floor0Config.new()
	return config.is_floor_0_zone(zone_type)
