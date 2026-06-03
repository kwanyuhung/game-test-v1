# floor_0_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 0 (Ground Floor)
# Organizes zones, NPC spawns, and Robot spawns into logical areas
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor0Config

extends Node

# ═══════════════════════════════════════════════════════════════════════════
# PLAYER MOVEABLE AREA
# Defines where the player (user) can move on Floor 0
# ═══════════════════════════════════════════════════════════════════════════

class MoveableArea:
	var name: String
	var x: int
	var y: int
	var w: int
	var h: int
	var description: String

	func _init(p_name: String, p_x: int, p_y: int, p_w: int, p_h: int, p_desc: String = "") -> void:
		name = p_name
		x = p_x
		y = p_y
		w = p_w
		h = p_h
		description = p_desc

	func contains_point(px: int, py: int) -> bool:
		return px >= x and px < x + w and py >= y and py < y + h

	func center() -> Vector2:
		return Vector2(x + w / 2, y + h / 2) * CELL_SIZE

	func area_tiles() -> int:
		return w * h

# ═══════════════════════════════════════════════════════════════════════════
# FACILITY DEFINITIONS
# Countable amenities on Floor 0
# ═══════════════════════════════════════════════════════════════════════════

class Facility:
	var type: String
	var name: String
	var count: int
	var x: int
	var y: int
	var w: int
	var h: int

	func _init(p_type: String, p_name: String, p_count: int, p_x: int = 0, p_y: int = 0, p_w: int = 0, p_h: int = 0) -> void:
		type = p_type
		name = p_name
		count = p_count
		x = p_x
		y = p_y
		w = p_w
		h = p_h

	func bounds() -> Dictionary:
		return {"x": x, "y": y, "w": w, "h": h}

# Facility type constants
const FACILITY_ATM := "atm"
const FACILITY_WC := "wc"
const FACILITY_VENDING_MACHINE := "vending_machine"
const FACILITY_AD := "ad_display"
const FACILITY_PROMO_BOOTH := "promo_booth"
const FACILITY_LOST_FOUND := "lost_found"
const FACILITY_STORE_NEWS := "store_news"

# ═══════════════════════════════════════════════════════════════════════════
# PLACE DEFINITIONS
# Named locations / points of interest on Floor 0
# ═══════════════════════════════════════════════════════════════════════════

class Place:
	var type: String
	var name: String
	var x: int
	var y: int
	var w: int
	var h: int
	var meta: Dictionary

	func _init(p_type: String, p_name: String, p_x: int, p_y: int, p_w: int = 0, p_h: int = 0, p_meta: Dictionary = {}) -> void:
		type = p_type
		name = p_name
		x = p_x
		y = p_y
		w = p_w
		h = p_h
		meta = p_meta

# Place type constants
const PLACE_INFO_DESK := "info_desk"
const PLACE_CUSTOMER_SERVICE := "customer_service"
const PLACE_LOYALTY_KIOSK := "loyalty_kiosk"
const PLACE_GIFT_WRAP := "gift_wrap"
const PLACE_DIGITAL_KIOSK := "digital_kiosk"
const PLACE_FOOD_STALL := "food_stall"
const PLACE_ELEVATOR := "elevator"
const PLACE_STAIRS := "stairs"
const PLACE_ESCALATOR := "escalator"
const PLACE_ENTRY_GATE := "entry_gate"

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
	var x: int  # Tile X position (→world px via tile_to_world)
	var y: int  # Tile Y position (→world px via tile_to_world)
	var patrol_points: Array  # Patrol waypoints in WORLD PIXEL coords (not tiles)

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
	# NOTE: spawn x/y are in TILES, patrol_points are in WORLD PIXELS
	# tile (35,5) → pixel (560,80) via tile_to_pixel()
	var lobby_spawns := [
		# NPC Staff spawns (7 total)
		EntitySpawnDef.new("npc_staff", "GREETER", AREA_LOBBY, 35, 5, [
			Vector2(560, 80), Vector2(640, 80), Vector2(720, 80), Vector2(640, 80), Vector2(560, 80)
		]),
		EntitySpawnDef.new("npc_staff", "RECEPTIONIST", AREA_LOBBY, 12, 5, [
			Vector2(192, 80), Vector2(272, 80), Vector2(272, 140), Vector2(192, 140), Vector2(192, 80)
		]),
		EntitySpawnDef.new("npc_staff", "SHOP_STAFF", AREA_LOBBY, 28, 5, [
			Vector2(448, 80), Vector2(528, 80), Vector2(528, 140), Vector2(448, 140), Vector2(448, 80)
		]),
		EntitySpawnDef.new("npc_staff", "INFO_DESK", AREA_LOBBY, 40, 3, [
			Vector2(640, 48), Vector2(720, 48), Vector2(720, 96), Vector2(640, 96), Vector2(640, 48)
		]),
		EntitySpawnDef.new("npc_staff", "SHOP_STAFF", AREA_LOBBY, 3, 3, [
			Vector2(48, 48), Vector2(112, 48), Vector2(112, 96), Vector2(48, 96), Vector2(48, 48)
		]),
		EntitySpawnDef.new("npc_staff", "RECEPTIONIST", AREA_LOBBY, 22, 3, [
			Vector2(352, 48), Vector2(416, 48), Vector2(416, 96), Vector2(352, 96), Vector2(352, 48)
		]),
		EntitySpawnDef.new("npc_staff", "SHOP_STAFF", AREA_LOBBY, 36, 3, [
			Vector2(576, 48), Vector2(656, 48), Vector2(656, 96), Vector2(576, 96), Vector2(576, 48)
		]),

		# Robot spawns (2 total)
		EntitySpawnDef.new("robot_humanoid", "GREETER_BOT", AREA_LOBBY, 25, 6, [
			Vector2(400, 96), Vector2(480, 96), Vector2(480, 160), Vector2(400, 160), Vector2(400, 96)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", AREA_LOBBY, 30, 10, [
			Vector2(480, 160), Vector2(640, 160), Vector2(640, 240), Vector2(480, 240), Vector2(480, 160)
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
	# NOTE: spawn x/y are TILES → pixel via tile_to_pixel(); patrol_points are PIXELS
	var food_court_spawns := [
		# NPC Staff spawns (3 total)
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", AREA_FOOD_COURT, 5, 6, [
			Vector2(80, 96), Vector2(320, 96), Vector2(560, 96), Vector2(80, 300)
		]),
		EntitySpawnDef.new("npc_staff", "FLOOR_STAFF", AREA_FOOD_COURT, 40, 20, [
			Vector2(640, 320), Vector2(800, 320), Vector2(800, 480), Vector2(640, 480), Vector2(640, 320)
		]),
		EntitySpawnDef.new("npc_staff", "CLEAN_STAFF", AREA_FOOD_COURT, 20, 18, [
			Vector2(320, 288), Vector2(480, 288), Vector2(480, 400), Vector2(320, 400), Vector2(320, 288)
		]),

		# Robot spawns (1 total)
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", AREA_FOOD_COURT, 40, 15, [
			Vector2(640, 240), Vector2(960, 240), Vector2(960, 480), Vector2(640, 480), Vector2(640, 240)
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
	# NOTE: spawn x/y are TILES → pixel via tile_to_pixel(); patrol_points are PIXELS
	var warehouse_spawns := [
		# NPC Staff spawns (3 total)
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", AREA_WAREHOUSE, 10, 40, [
			Vector2(160, 640), Vector2(320, 640), Vector2(480, 640), Vector2(640, 640), Vector2(160, 800)
		]),
		EntitySpawnDef.new("npc_staff", "FLOOR_STAFF", AREA_WAREHOUSE, 50, 42, [
			Vector2(800, 672), Vector2(960, 672), Vector2(1120, 672), Vector2(1280, 672), Vector2(800, 672)
		]),
		EntitySpawnDef.new("npc_staff", "MANAGER", AREA_WAREHOUSE, 60, 42, [
			Vector2(960, 672), Vector2(1120, 672), Vector2(1120, 800), Vector2(960, 800), Vector2(960, 672)
		]),

		# Robot spawns (3 total)
		EntitySpawnDef.new("robot_single", "DELIVERY_ROBOT", AREA_WAREHOUSE, 10, 38, [
			Vector2(160, 608), Vector2(640, 608), Vector2(640, 752), Vector2(160, 752), Vector2(160, 608)
		]),
		EntitySpawnDef.new("robot_single", "SHELF_ROBOT", AREA_WAREHOUSE, 90, 40, [
			Vector2(1440, 640), Vector2(1600, 640), Vector2(1760, 640), Vector2(1440, 800), Vector2(1440, 640)
		]),
		EntitySpawnDef.new("robot_humanoid", "SECURITY", AREA_WAREHOUSE, 30, 39, [
			Vector2(480, 624), Vector2(640, 624), Vector2(640, 752), Vector2(480, 752), Vector2(480, 624)
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
	# Elevator, stairs, escalator — mainly for navigation, minimal spawns
	# NOTE: spawn x/y are TILES → pixel via tile_to_pixel(); patrol_points are PIXELS
	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", AREA_TRANSIT, 8, 20, [
			Vector2(128, 320), Vector2(320, 320), Vector2(320, 560), Vector2(128, 560), Vector2(128, 320)
		]),
		EntitySpawnDef.new("robot_humanoid", "SECURITY", AREA_TRANSIT, 12, 25, [
			Vector2(192, 400), Vector2(400, 400), Vector2(400, 640), Vector2(192, 640), Vector2(192, 400)
		]),
	]

	_areas[AREA_TRANSIT] = AreaDef.new(
		AREA_TRANSIT,
		"Transit",
		[ZONE_ELEVATOR, ZONE_STAIRS, ZONE_ESCALATOR],
		transit_spawns,
		{"x": TRANSIT_X, "y": TRANSIT_Y, "w": TRANSIT_W, "h": TRANSIT_H}
	)

	# ─── PLAYER MOVEABLE AREAS ─────────────────────────────────────────
	_setup_player_areas()

	# ─── FACILITIES ────────────────────────────────────────────────────
	_setup_facilities()

	# ─── PLACES ────────────────────────────────────────────────────────
	_setup_places()

# ═══════════════════════════════════════════════════════════════════════════
# PLAYER MOVEABLE AREAS SETUP
# ═══════════════════════════════════════════════════════════════════════════

var _player_moveable_areas: Array = []

func _setup_player_areas() -> void:
	_player_moveable_areas = [
		# Lobby - main customer area (accessible to all)
		MoveableArea.new("Lobby Main", 0, 2, 80, 13,
			"Main lobby area with info desk, customer service, loyalty kiosk"),

		# Food Court - customer dining area
		MoveableArea.new("Food Court", 0, 2, 80, 33,
			"Food court with 10 stalls and dining tables"),

		# Warehouse - staff only area
		MoveableArea.new("Warehouse", 0, 35, 120, 14,
			"Warehouse floor with truck dock, conveyor, storage (staff only)"),

		# Elevator shaft - accessible via elevator
		MoveableArea.new("Elevator Area", 6, 2, 14, 47,
			"Elevator shaft area"),

		# Stairs - accessible via stairs
		MoveableArea.new("Stairs Area", 20, 2, 6, 47,
			"Staircase area"),

		# Escalator - accessible via escalator
		MoveableArea.new("Escalator Area", 26, 2, 6, 47,
			"Escalator area"),
	]

# ═══════════════════════════════════════════════════════════════════════════
# FACILITIES SETUP
# ═══════════════════════════════════════════════════════════════════════════

var _facilities: Array = []

func _setup_facilities() -> void:
	_facilities = [
		Facility.new(FACILITY_ATM, "ATM Machine", 2, 58, 4, 6, 6),
		Facility.new(FACILITY_WC, "Restroom", 2, 68, 3, 6, 6),
		Facility.new(FACILITY_VENDING_MACHINE, "Vending Machine", 2, 70, 3, 6, 6),
		Facility.new(FACILITY_AD, "AD Display", 4, 56, 3, 6, 6),
		Facility.new(FACILITY_PROMO_BOOTH, "Promo Booth", 1, 3, 3, 6, 6),
		Facility.new(FACILITY_LOST_FOUND, "Lost & Found", 1, 22, 3, 6, 6),
		Facility.new(FACILITY_STORE_NEWS, "Store News Board", 1, 36, 3, 6, 6),
	]

# ═══════════════════════════════════════════════════════════════════════════
# PLACES SETUP
# Named points of interest on Floor 0
# ═══════════════════════════════════════════════════════════════════════════

var _places: Array = []

func _setup_places() -> void:
	_places = [
		# Info & Service Places
		Place.new(PLACE_INFO_DESK, "Info Desk", 40, 3, 16, 7),
		Place.new(PLACE_CUSTOMER_SERVICE, "Customer Service", 8, 3, 16, 7),
		Place.new(PLACE_LOYALTY_KIOSK, "Loyalty Center", 26, 3, 14, 7),
		Place.new(PLACE_GIFT_WRAP, "Gift Wrapping", 42, 3, 14, 7),
		Place.new(PLACE_DIGITAL_KIOSK, "Digital Kiosk", 58, 11, 8, 7),

		# Transit Places
		Place.new(PLACE_ELEVATOR, "Elevator", 6, 2, 14, 47),
		Place.new(PLACE_STAIRS, "Stairs", 20, 2, 6, 47),
		Place.new(PLACE_ESCALATOR, "Escalator", 26, 2, 6, 47),
		Place.new(PLACE_ENTRY_GATE, "Entry Gate", 38, 3, 6, 5),

		# Food Stalls (10 stalls in 3 rows)
		Place.new(PLACE_FOOD_STALL, "Ramen (jp_ramen)", 2, 3, 14, 8, {"cuisine": "Japanese"}),
		Place.new(PLACE_FOOD_STALL, "Sushi (jp_sushi)", 18, 3, 14, 8, {"cuisine": "Japanese"}),
		Place.new(PLACE_FOOD_STALL, "Takoyaki (jp_takoyaki)", 34, 3, 14, 8, {"cuisine": "Japanese"}),
		Place.new(PLACE_FOOD_STALL, "Thai Food", 50, 3, 14, 8, {"cuisine": "Thai"}),
		Place.new(PLACE_FOOD_STALL, "Indian", 66, 3, 14, 8, {"cuisine": "Indian"}),
		Place.new(PLACE_FOOD_STALL, "Chinese", 2, 15, 14, 8, {"cuisine": "Chinese"}),
		Place.new(PLACE_FOOD_STALL, "Korean", 18, 15, 14, 8, {"cuisine": "Korean"}),
		Place.new(PLACE_FOOD_STALL, "Turkish", 34, 15, 14, 8, {"cuisine": "Turkish"}),
		Place.new(PLACE_FOOD_STALL, "Vietnamese", 50, 15, 14, 8, {"cuisine": "Vietnamese"}),
		Place.new(PLACE_FOOD_STALL, "Italian", 66, 15, 14, 8, {"cuisine": "Italian"}),
		Place.new(PLACE_FOOD_STALL, "Mexican", 2, 25, 14, 8, {"cuisine": "Mexican"}),
		Place.new(PLACE_FOOD_STALL, "Drinks", 18, 25, 14, 8, {"cuisine": "Beverages"}),
	]

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

# Coordinate conversion helpers
# Floor 0 config uses 1/4 scale relative to floor_config_data.json (JSON's lobby is 320x52, cfg is 80x13)
const COORD_SCALE := 4

# tile_to_pixel: converts tile coords to world pixel coords (tile * CELL_SIZE)
func tile_to_pixel(tile_x: int, tile_y: int) -> Vector2:
	return Vector2(tile_x * CELL_SIZE, tile_y * CELL_SIZE)

# pixel_to_tile: converts world pixel coords back to tile coords
func pixel_to_tile(px: int, py: int) -> Vector2:
	return Vector2(px / CELL_SIZE, py / CELL_SIZE)

# Get world position from tile position
func tile_to_world(tile_x: int, tile_y: int) -> Vector2:
	return Vector2(tile_x * CELL_SIZE * COORD_SCALE, tile_y * CELL_SIZE * COORD_SCALE)

# Get spawn world position
func get_spawn_world_pos(spawn: EntitySpawnDef) -> Vector2:
	return tile_to_world(spawn.x, spawn.y)

# Get patrol points scaled to world pixel coords
func get_patrol_world_points(spawn: EntitySpawnDef) -> Array:
	var out: Array = []
	for pp in spawn.patrol_points:
		out.append(Vector2(pp.x * COORD_SCALE, pp.y * COORD_SCALE))
	return out

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
# PLAYER MOVEABLE AREA API
# ═══════════════════════════════════════════════════════════════════════════

func get_player_moveable_areas() -> Array:
	return _player_moveable_areas

func get_player_moveable_area_count() -> int:
	return _player_moveable_areas.size()

func get_player_area_by_name(name: String) -> MoveableArea:
	for area in _player_moveable_areas:
		if area.name == name:
			return area
	return null

func get_player_area_by_point(px: int, py: int) -> MoveableArea:
	for area in _player_moveable_areas:
		if area.contains_point(px, py):
			return area
	return null

func get_total_player_moveable_tiles() -> int:
	var total := 0
	for area in _player_moveable_areas:
		total += area.area_tiles()
	return total

func can_player_move_to(px: int, py: int) -> bool:
	return get_player_area_by_point(px, py) != null

# ═══════════════════════════════════════════════════════════════════════════
# FACILITY API
# ═══════════════════════════════════════════════════════════════════════════

func get_facilities() -> Array:
	return _facilities

func get_facility_count() -> int:
	return _facilities.size()

func get_facility_by_type(facility_type: String) -> Array:
	var result := []
	for f in _facilities:
		if f.type == facility_type:
			result.append(f)
	return result

func get_facility_total_count(facility_type: String) -> int:
	var total := 0
	for f in _facilities:
		if f.type == facility_type:
			total += f.count
	return total

func get_all_facility_counts() -> Dictionary:
	var counts := {}
	for f in _facilities:
		if not counts.has(f.type):
			counts[f.type] = 0
		counts[f.type] += f.count
	return counts

# ═══════════════════════════════════════════════════════════════════════════
# PLACE API
# ═══════════════════════════════════════════════════════════════════════════

func get_places() -> Array:
	return _places

func get_place_count() -> int:
	return _places.size()

func get_places_by_type(place_type: String) -> Array:
	var result := []
	for p in _places:
		if p.type == place_type:
			result.append(p)
	return result

func get_place_total_count(place_type: String) -> int:
	return get_places_by_type(place_type).size()

func get_food_stall_count() -> int:
	return get_place_total_count(PLACE_FOOD_STALL)

func get_all_place_counts() -> Dictionary:
	var counts := {}
	for p in _places:
		if not counts.has(p.type):
			counts[p.type] = 0
		counts[p.type] += 1
	return counts

# ═══════════════════════════════════════════════════════════════════════════
# NPC / ENTITY STATS API
# ═══════════════════════════════════════════════════════════════════════════

func get_npc_staff_count() -> int:
	return get_spawns_by_type("npc_staff").size()

func get_npc_customer_count() -> int:
	return get_spawns_by_type("npc_customer").size()

func get_robot_humanoid_count() -> int:
	return get_spawns_by_type("robot_humanoid").size()

func get_robot_single_count() -> int:
	return get_spawns_by_type("robot_single").size()

func get_total_npc_count() -> int:
	return get_npc_staff_count() + get_npc_customer_count()

func get_total_robot_count() -> int:
	return get_robot_humanoid_count() + get_robot_single_count()

func get_total_entity_count() -> int:
	return get_total_npc_count() + get_total_robot_count()

func get_entity_stats() -> Dictionary:
	return {
		"npc_staff": get_npc_staff_count(),
		"npc_customer": get_npc_customer_count(),
		"robot_humanoid": get_robot_humanoid_count(),
		"robot_single": get_robot_single_count(),
		"total_npc": get_total_npc_count(),
		"total_robot": get_total_robot_count(),
		"total_entities": get_total_entity_count(),
	}

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY STATS
# ═══════════════════════════════════════════════════════════════════════════

func get_floor_0_summary() -> Dictionary:
	return {
		"player_moveable_areas": get_player_moveable_area_count(),
		"total_player_tiles": get_total_player_moveable_tiles(),
		"facility_count": get_facility_count(),
		"facility_totals": get_all_facility_counts(),
		"place_count": get_place_count(),
		"place_totals": get_all_place_counts(),
		"food_stall_count": get_food_stall_count(),
		"entity_stats": get_entity_stats(),
	}

# ═══════════════════════════════════════════════════════════════════════════
# DEBUG HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func get_debug_info() -> String:
	var info := "Floor 0 Configuration\n"
	info += "=======================\n\n"

	# Summary Stats
	var summary = get_floor_0_summary()
	info += "=== SUMMARY ===\n"
	info += "Player Moveable Areas: %d (total %d tiles)\n" % [summary["player_moveable_areas"], summary["total_player_tiles"]]
	info += "Facilities: %d\n" % [summary["facility_count"]]
	info += "  - %s\n" % [str(summary["facility_totals"])]
	info += "Places: %d\n" % [summary["place_count"]]
	info += "  - %s\n" % [str(summary["place_totals"])]
	info += "Food Stalls: %d\n" % [summary["food_stall_count"]]
	info += "Entities: %s\n" % [str(summary["entity_stats"])]
	info += "\n"

	# Areas
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)\n" % [area.name, area.id]
		info += "  Bounds: x=%d y=%d w=%d h=%d\n" % [area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		info += "  Zones: %s\n" % [str(area.zone_types)]
		info += "  Spawns:\n"
		for spawn in area.spawns:
			var patrol_str = "" if spawn.patrol_points.is_empty() else " (patrol)"
			var world_pos := get_spawn_world_pos(spawn)
			info += "    - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, world_pos.x, world_pos.y, patrol_str]
		info += "\n"

	# Player Moveable Areas
	info += "=== PLAYER MOVEABLE AREAS ===\n"
	for area in _player_moveable_areas:
		info += "  %s: (%d,%d) %dx%d - %s\n" % [area.name, area.x, area.y, area.w, area.h, area.description]

	# Facilities
	info += "\n=== FACILITIES ===\n"
	for f in _facilities:
		info += "  %s (%s): x=%d y=%d %dx%d\n" % [f.name, f.type, f.x, f.y, f.w, f.h]

	# Places
	info += "\n=== PLACES ===\n"
	for p in _places:
		info += "  %s (%s): (%d,%d)\n" % [p.name, p.type, p.x, p.y]

	return info
