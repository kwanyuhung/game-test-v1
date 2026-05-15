# floor_0_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 0 (Ground Floor)
# Organizes zones, NPC spawns, and Robot spawns into logical areas
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor0Config

extends Node

# ═══════════════════════════════════════════════════════════════════════════
# AREA DEFINITIONS
# Floor 0 is divided into logical areas for better organization
# ═══════════════════════════════════════════════════════════════════════════

# Area type constants
const AREA_LOBBY := "lobby"
const AREA_FOOD_COURT := "food_court"
const AREA_WAREHOUSE := "warehouse"
const AREA_TRANSIT := "transit"  # Elevator, stairs, escalator

# Zone type constants for Floor 0
const ZONE_LOBBY := "lobby"
const ZONE_INFO_DESK := "info_desk"
const ZONE_WC := "wc"
const ZONE_AD := "ad"
const ZONE_ATM := "atm"
const ZONE_CUSTOMER_SERVICE := "customer_service"
const ZONE_LOYALTY_KIOSK := "loyalty_kiosk"
const ZONE_GIFT_WRAP := "gift_wrap"
const ZONE_DIGITAL_KIOSK := "digital_kiosk"
const ZONE_FOOD_STALL := "food_stall"
const ZONE_WAREHOUSE := "warehouse"
const ZONE_TRUCK_DOCK := "truck_dock"
const ZONE_FORKLIFT := "forklift"
const ZONE_CONVEYOR := "conveyor"
const ZONE_STORAGE_SHELF := "storage_shelf"
const ZONE_ELEVATOR := "elevator_shaft"
const ZONE_STAIRS := "stairs"
const ZONE_ESCALATOR := "escalator"
const ZONE_DECOR := "decor"
const ZONE_VENDING_MACHINE := "vending_machine"
const ZONE_PROMO_BOOTH := "promo_booth"
const ZONE_WAREHOUSE_STOCK_VIEW := "wh_stock_view"
const ZONE_LOST_FOUND := "lost_found"
const ZONE_STORE_NEWS := "store_news"

# ═══════════════════════════════════════════════════════════════════════════
# ENTITY SPAWN DEFINITIONS
# Defines where NPCs and Robots spawn within each area
# ═══════════════════════════════════════════════════════════════════════════

class EntitySpawnDef:
	var entity_type: String  # "npc_staff", "npc_customer", "robot_humanoid", "robot_single"
	var role: String  # e.g., "CASHIER", "CLEANER", "GREETER" or robot role
	var area: String  # Which area this spawn belongs to
	var x: int  # Tile X position
	var y: int  # Tile Y position
	var patrol_points: Array  # Optional patrol waypoints
	
	func _init(p_type: String, p_role: String, p_area: String, p_x: int, p_y: int, p_patrol: Array = []) -> void:
		entity_type = p_type
		role = p_role
		area = p_area
		x = p_x
		y = p_y
		patrol_points = p_patrol

# ═══════════════════════════════════════════════════════════════════════════
# AREA DEFINITION CLASS
# Groups related zones and spawns together
# ═══════════════════════════════════════════════════════════════════════════

class AreaDef:
	var id: String
	var name: String
	var zone_types: Array  # Zone types that belong to this area
	var spawns: Array  # EntitySpawnDef instances
	var world_bounds: Dictionary  # {x, y, w, h} in tiles
	
	func _init(p_id: String, p_name: String, p_zone_types: Array, p_spawns: Array, p_bounds: Dictionary) -> void:
		id = p_id
		name = p_name
		zone_types = p_zone_types
		spawns = p_spawns
		world_bounds = p_bounds
	
	func get_center() -> Vector2:
		var cx = world_bounds.x + world_bounds.w / 2
		var cy = world_bounds.y + world_bounds.h / 2
		return Vector2(cx, cy)
	
	func contains_point(px: int, py: int) -> bool:
		return (px >= world_bounds.x and px < world_bounds.x + world_bounds.w and
				py >= world_bounds.y and py < world_bounds.y + world_bounds.h)

# ═══════════════════════════════════════════════════════════════════════════
# FLOOR 0 LAYOUT CONSTANTS
# All positions in tile coordinates (CELL_SIZE = 16px)
# ═══════════════════════════════════════════════════════════════════════════

const CELL_SIZE := 16

# Lobby area bounds (tiles)
const LOBBY_X := 0
const LOBBY_Y := 2
const LOBBY_W := 80
const LOBBY_H := 13

# Food Court area bounds (tiles) - multiple rows of stalls
const FOOD_COURT_X := 0
const FOOD_COURT_Y := 2
const FOOD_COURT_W := 80
const FOOD_COURT_H := 33

# Warehouse area bounds (tiles)
const WAREHOUSE_X := 0
const WAREHOUSE_Y := 35
const WAREHOUSE_W := 120
const WAREHOUSE_H := 14

# Transit area bounds (tiles) - elevator, stairs, escalator
const TRANSIT_X := 0
const TRANSIT_Y := 2
const TRANSIT_W := 32
const TRANSIT_H := 47

# ═══════════════════════════════════════════════════════════════════════════
# AREA INSTANCES
# Pre-configured areas with their zones and spawn points
# ═══════════════════════════════════════════════════════════════════════════

var _areas: Dictionary = {}

func _init() -> void:
	_setup_areas()

func _setup_areas() -> void:
	# ─── LOBBY AREA ───────────────────────────────────────────────────────
	# Customer service, info desk, loyalty, gift wrap, digital kiosk, AD displays, ATM
	var lobby_spawns := [
		# NPC Staff spawns
		EntitySpawnDef.new("npc_staff", "GREETER", AREA_LOBBY, 35, 5, [
			Vector2(300, 100), Vector2(350, 100), Vector2(300, 100)
		]),
		EntitySpawnDef.new("npc_staff", "CUSTOMER_SERVICE", AREA_LOBBY, 12, 5, []),
		EntitySpawnDef.new("npc_staff", "LOYALTY_KIOSK", AREA_LOBBY, 28, 5, []),
		
		# Robot spawns
		EntitySpawnDef.new("robot_humanoid", "GREETER", AREA_LOBBY, 25, 12, [
			Vector2(250, 120), Vector2(320, 120), Vector2(250, 120)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", AREA_LOBBY, 30, 10, [
			Vector2(300, 100), Vector2(600, 100), Vector2(600, 200), Vector2(300, 200)
		]),
	]
	
	_areas[AREA_LOBBY] = AreaDef.new(
		AREA_LOBBY,
		"Lobby",
		[ZONE_LOBBY, ZONE_INFO_DESK, ZONE_CUSTOMER_SERVICE, ZONE_LOYALTY_KIOSK,
		 ZONE_GIFT_WRAP, ZONE_DIGITAL_KIOSK, ZONE_AD, ZONE_ATM, ZONE_LOST_FOUND,
		 ZONE_STORE_NEWS, ZONE_DECOR, ZONE_PROMO_BOOTH],
		lobby_spawns,
		{"x": LOBBY_X, "y": LOBBY_Y, "w": LOBBY_W, "h": LOBBY_H}
	)
	
	# ─── FOOD COURT AREA ──────────────────────────────────────────────────
	# 10 food stalls in 3 rows, plus dining tables
	var food_court_spawns := [
		# NPC Staff spawns - one per food stall type
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", AREA_FOOD_COURT, 5, 6, [
			Vector2(80, 100), Vector2(320, 100), Vector2(560, 100), Vector2(80, 300)
		]),
		EntitySpawnDef.new("npc_staff", "FLOOR_STAFF", AREA_FOOD_COURT, 40, 20, [
			Vector2(200, 300), Vector2(450, 300), Vector2(200, 500), Vector2(450, 500)
		]),
		
		# Robot spawns
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", AREA_FOOD_COURT, 40, 15, [
			Vector2(200, 300), Vector2(600, 300), Vector2(600, 450), Vector2(200, 450)
		]),
	]
	
	_areas[AREA_FOOD_COURT] = AreaDef.new(
		AREA_FOOD_COURT,
		"Food Court",
		[ZONE_FOOD_STALL, ZONE_DECOR, ZONE_VENDING_MACHINE],
		food_court_spawns,
		{"x": FOOD_COURT_X, "y": FOOD_COURT_Y, "w": FOOD_COURT_W, "h": FOOD_COURT_H}
	)
	
	# ─── WAREHOUSE AREA ───────────────────────────────────────────────────
	# Truck dock, forklift zone, conveyor, storage shelves, stock view
	var warehouse_spawns := [
		# NPC Staff spawns
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", AREA_WAREHOUSE, 10, 40, [
			Vector2(80, 640), Vector2(320, 640), Vector2(560, 640), Vector2(80, 800)
		]),
		EntitySpawnDef.new("npc_staff", "FLOOR_STAFF", AREA_WAREHOUSE, 50, 42, [
			Vector2(400, 700), Vector2(600, 700), Vector2(800, 700), Vector2(1000, 700)
		]),
		
		# Robot spawns
		EntitySpawnDef.new("robot_single", "DELIVERY_ROBOT", AREA_WAREHOUSE, 10, 38, [
			Vector2(100, 600), Vector2(640, 600), Vector2(640, 750), Vector2(100, 750)
		]),
		EntitySpawnDef.new("robot_single", "SHELF_ROBOT", AREA_WAREHOUSE, 90, 40, [
			Vector2(150, 640), Vector2(350, 640), Vector2(550, 640), Vector2(150, 800)
		]),
		EntitySpawnDef.new("robot_humanoid", "MANAGER", AREA_WAREHOUSE, 60, 42, [
			Vector2(500, 700), Vector2(900, 700), Vector2(900, 850), Vector2(500, 850)
		]),
	]
	
	_areas[AREA_WAREHOUSE] = AreaDef.new(
		AREA_WAREHOUSE,
		"Warehouse",
		[ZONE_WAREHOUSE, ZONE_TRUCK_DOCK, ZONE_FORKLIFT, ZONE_CONVEYOR,
		 ZONE_STORAGE_SHELF, ZONE_WAREHOUSE_STOCK_VIEW],
		warehouse_spawns,
		{"x": WAREHOUSE_X, "y": WAREHOUSE_Y, "w": WAREHOUSE_W, "h": WAREHOUSE_H}
	)
	
	# ─── TRANSIT AREA ─────────────────────────────────────────────────────
	# Elevator, stairs, escalator - mainly for navigation, minimal spawns
	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", AREA_TRANSIT, 8, 20, [
			Vector2(100, 400), Vector2(400, 400), Vector2(400, 700), Vector2(100, 700)
		]),
		EntitySpawnDef.new("robot_humanoid", "SECURITY", AREA_TRANSIT, 12, 25, [
			Vector2(100, 400), Vector2(500, 400), Vector2(500, 700), Vector2(100, 700)
		]),
	]
	
	_areas[AREA_TRANSIT] = AreaDef.new(
		AREA_TRANSIT,
		"Transit",
		[ZONE_ELEVATOR, ZONE_STAIRS, ZONE_ESCALATOR],
		transit_spawns,
		{"x": TRANSIT_X, "y": TRANSIT_Y, "w": TRANSIT_W, "h": TRANSIT_H}
	)

# ═══════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════

func get_area(area_id: String) -> AreaDef:
	return _areas.get(area_id, null)

func get_all_areas() -> Array:
	return _areas.values()

func get_area_by_zone_type(zone_type: String) -> AreaDef:
	for area in _areas.values():
		if zone_type in area.zone_types:
			return area
	return null

func get_area_by_point(px: int, py: int) -> AreaDef:
	for area in _areas.values():
		if area.contains_point(px, py):
			return area
	return null

func get_spawns_by_area(area_id: String) -> Array:
	var area = _areas.get(area_id, null)
	if area:
		return area.spawns
	return []

func get_spawns_by_type(entity_type: String) -> Array:
	var result := []
	for area in _areas.values():
		for spawn in area.spawns:
			if spawn.entity_type == entity_type:
				result.append(spawn)
	return result

func get_spawns_by_role(entity_type: String, role: String) -> Array:
	var result := []
	for area in _areas.values():
		for spawn in area.spawns:
			if spawn.entity_type == entity_type and spawn.role == role:
				result.append(spawn)
	return result

# Get world position from tile position
func tile_to_world(tile_x: int, tile_y: int) -> Vector2:
	return Vector2(tile_x * CELL_SIZE, tile_y * CELL_SIZE)

# Get spawn world position
func get_spawn_world_pos(spawn: EntitySpawnDef) -> Vector2:
	return tile_to_world(spawn.x, spawn.y)

# Get all NPC staff spawns
func get_npc_staff_spawns() -> Array:
	return get_spawns_by_type("npc_staff")

# Get all robot spawns
func get_robot_spawns() -> Array:
	var result := []
	result.append_array(get_spawns_by_type("robot_humanoid"))
	result.append_array(get_spawns_by_type("robot_single"))
	return result

# Get humanoid robot spawns
func get_humanoid_robot_spawns() -> Array:
	return get_spawns_by_type("robot_humanoid")

# Get single-function robot spawns
func get_single_robot_spawns() -> Array:
	return get_spawns_by_type("robot_single")

# Check if a zone type belongs to Floor 0
func is_floor_0_zone(zone_type: String) -> bool:
	for area in _areas.values():
		if zone_type in area.zone_types:
			return true
	return false

# Get all zone types for Floor 0
func get_all_zone_types() -> Array:
	var types := []
	for area in _areas.values():
		for ztype in area.zone_types:
			if not ztype in types:
				types.append(ztype)
	return types

# ═══════════════════════════════════════════════════════════════════════════
# DEBUG HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func get_debug_info() -> String:
	var info := "Floor 0 Configuration\n"
	info += "=======================\n\n"
	
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)\n" % [area.name, area.id]
		info += "  Bounds: x=%d y=%d w=%d h=%d\n" % [area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		info += "  Zones: %s\n" % [str(area.zone_types)]
		info += "  Spawns:\n"
		for spawn in area.spawns:
			var patrol_str = "" if spawn.patrol_points.is_empty() else " (patrol)"
			info += "    - %s/%s at (%d, %d)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, patrol_str]
		info += "\n"
	
	return info
