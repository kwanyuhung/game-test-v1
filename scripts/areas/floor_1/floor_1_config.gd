# floor_1_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 1 (Shoes Floor)
# Organizes zones, NPC spawns, and Robot spawns into logical areas
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor1Config

extends Node

# ═══════════════════════════════════════════════════════════════════════════
# FLOOR 1 LAYOUT CONSTANTS
# All positions in tile coordinates (CELL_SIZE = 16px)
# ═══════════════════════════════════════════════════════════════════════════

const CELL_SIZE := 16

# Area bounds (tiles) — derived from floor_config_data.json zones
const LADIES_X := 2
const LADIES_Y := 3
const LADIES_W := 24
const LADIES_H := 16

const MENS_X := 28
const MENS_Y := 3
const MENS_W := 24
const MENS_H := 16

const KIDS_X := 54
const KIDS_Y := 3
const KIDS_W := 24
const KIDS_H := 16

const SPORT_X := 2
const SPORT_Y := 21
const SPORT_W := 38
const SPORT_H := 16

const SANDALS_X := 42
const SANDALS_Y := 21
const SANDALS_W := 36
const SANDALS_H := 16

const TRANSIT_X := 0
const TRANSIT_Y := 2
const TRANSIT_W := 80
const TRANSIT_H := 40

# ═══════════════════════════════════════════════════════════════════════════
# ENTITY SPAWN DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════

class EntitySpawnDef:
	var entity_type: String  # "npc_staff", "npc_customer", "robot_humanoid", "robot_single"
	var role: String  # e.g., "CASHIER", "SHELF_STOCKER" or robot role
	var area: String  # Which area this spawn belongs to
	var x: int  # Tile X position (→world px via tile_to_pixel)
	var y: int  # Tile Y position (→world px via tile_to_pixel)
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
# ═══════════════════════════════════════════════════════════════════════════

class AreaDef:
	var id: String
	var name: String
	var zone_types: Array
	var spawns: Array
	var world_bounds: Dictionary

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
# FACILITY DEFINITIONS
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

	const FACILITY_AD := "ad"
	const FACILITY_VENDING_MACHINE := "vending_machine"

# ═══════════════════════════════════════════════════════════════════════════
# PLACE DEFINITIONS
# Named points of interest on Floor 1
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

	const PLACE_ELEVATOR := "elevator"
	const PLACE_STAIRS := "stairs"

# ═══════════════════════════════════════════════════════════════════════════
# AREA INSTANCES
# ═══════════════════════════════════════════════════════════════════════════

var _areas: Dictionary = {}
var _facilities: Array = []
var _places: Array = []

func _init() -> void:
	_setup_areas()
	_setup_facilities()
	_setup_places()

func _setup_areas() -> void:
	# ─── LADIES SHOES AREA ────────────────────────────────────────────
	var ladies_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "ladies_shoes", 8, 6, [
			Vector2(128, 96), Vector2(256, 96), Vector2(384, 96), Vector2(256, 96), Vector2(128, 96)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "ladies_shoes", 14, 10, [
			Vector2(224, 160), Vector2(352, 160), Vector2(352, 240), Vector2(224, 240), Vector2(224, 160)
		]),
	]
	_areas["ladies_shoes"] = AreaDef.new(
		"ladies_shoes", "Ladies Shoes",
		["shoes_rack"],
		ladies_spawns,
		{"x": LADIES_X, "y": LADIES_Y, "w": LADIES_W, "h": LADIES_H}
	)

	# ─── MENS SHOES AREA ─────────────────────────────────────────────
	var mens_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "mens_shoes", 34, 6, [
			Vector2(544, 96), Vector2(672, 96), Vector2(800, 96), Vector2(672, 96), Vector2(544, 96)
		]),
		EntitySpawnDef.new("npc_staff", "CUSTOMER_SERVICE", "mens_shoes", 40, 10, [
			Vector2(640, 160), Vector2(768, 160), Vector2(768, 240), Vector2(640, 240), Vector2(640, 160)
		]),
	]
	_areas["mens_shoes"] = AreaDef.new(
		"mens_shoes", "Mens Shoes",
		["shoes_rack"],
		mens_spawns,
		{"x": MENS_X, "y": MENS_Y, "w": MENS_W, "h": MENS_H}
	)

	# ─── KIDS SHOES AREA ─────────────────────────────────────────────
	var kids_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "kids_shoes", 60, 6, [
			Vector2(960, 96), Vector2(1088, 96), Vector2(1088, 160), Vector2(960, 160), Vector2(960, 96)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "kids_shoes", 66, 12, [
			Vector2(1056, 192), Vector2(1152, 192), Vector2(1152, 272), Vector2(1056, 272), Vector2(1056, 192)
		]),
	]
	_areas["kids_shoes"] = AreaDef.new(
		"kids_shoes", "Kids Shoes",
		["shoes_rack"],
		kids_spawns,
		{"x": KIDS_X, "y": KIDS_Y, "w": KIDS_W, "h": KIDS_H}
	)

	# ─── SPORT SHOES AREA ────────────────────────────────────────────
	var sport_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "sport_shoes", 8, 24, [
			Vector2(128, 384), Vector2(384, 384), Vector2(544, 384), Vector2(384, 384), Vector2(128, 384)
		]),
		EntitySpawnDef.new("npc_staff", "FITNESS_ADVISOR", "sport_shoes", 20, 28, [
			Vector2(320, 448), Vector2(480, 448), Vector2(480, 560), Vector2(320, 560), Vector2(320, 448)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "sport_shoes", 30, 26, [
			Vector2(480, 416), Vector2(640, 416), Vector2(640, 544), Vector2(480, 544), Vector2(480, 416)
		]),
	]
	_areas["sport_shoes"] = AreaDef.new(
		"sport_shoes", "Sport Shoes",
		["shoes_rack"],
		sport_spawns,
		{"x": SPORT_X, "y": SPORT_Y, "w": SPORT_W, "h": SPORT_H}
	)

	# ─── SANDALS AREA ────────────────────────────────────────────────
	var sandals_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "sandals", 48, 24, [
			Vector2(768, 384), Vector2(960, 384), Vector2(960, 544), Vector2(768, 544), Vector2(768, 384)
		]),
	]
	_areas["sandals"] = AreaDef.new(
		"sandals", "Sandals",
		["shoes_rack"],
		sandals_spawns,
		{"x": SANDALS_X, "y": SANDALS_Y, "w": SANDALS_W, "h": SANDALS_H}
	)

	# ─── TRANSIT AREA (elevator + stairs) ───────────────────────────
	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 8, 15, [
			Vector2(128, 240), Vector2(320, 240), Vector2(320, 560), Vector2(128, 560), Vector2(128, 240)
		]),
	]
	_areas["transit"] = AreaDef.new(
		"transit", "Transit",
		["elevator_shaft", "stairs"],
		transit_spawns,
		{"x": TRANSIT_X, "y": TRANSIT_Y, "w": TRANSIT_W, "h": TRANSIT_H}
	)

func _setup_facilities() -> void:
	_facilities = [
		Facility.new("ad", "AD Display", 1, 66, 4, 4, 6),
	]

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 6, 2, 14, 40),
		Place.new("stairs", "Stairs", 20, 2, 6, 40),
		Place.new("ladies_shoes", "Ladies Shoes Section", 2, 3, 24, 16),
		Place.new("mens_shoes", "Mens Shoes Section", 28, 3, 24, 16),
		Place.new("kids_shoes", "Kids Shoes Section", 54, 3, 24, 16),
		Place.new("sport_shoes", "Sport Shoes Section", 2, 21, 38, 16),
		Place.new("sandals", "Sandals Section", 42, 21, 36, 16),
	]

# ═══════════════════════════════════════════════════════════════════════════
# COORDINATE CONVERSION
# ═══════════════════════════════════════════════════════════════════════════

func tile_to_pixel(tile_x: int, tile_y: int) -> Vector2:
	return Vector2(tile_x * CELL_SIZE, tile_y * CELL_SIZE)

func pixel_to_tile(px: int, py: int) -> Vector2:
	return Vector2(px / CELL_SIZE, py / CELL_SIZE)

func tile_to_world(tile_x: int, tile_y: int) -> Vector2:
	return tile_to_pixel(tile_x, tile_y)

func get_spawn_world_pos(spawn: EntitySpawnDef) -> Vector2:
	return tile_to_world(spawn.x, spawn.y)

# ═══════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════

func get_area(area_id: String) -> AreaDef:
	return _areas.get(area_id, null)

func get_all_areas() -> Array:
	return _areas.values()

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

func get_npc_staff_spawns() -> Array:
	return get_spawns_by_type("npc_staff")

func get_robot_spawns() -> Array:
	var result := []
	result.append_array(get_spawns_by_type("robot_humanoid"))
	result.append_array(get_spawns_by_type("robot_single"))
	return result

func get_robot_humanoid_count() -> int:
	return get_spawns_by_type("robot_humanoid").size()

func get_robot_single_count() -> int:
	return get_spawns_by_type("robot_single").size()

func get_npc_staff_count() -> int:
	return get_spawns_by_type("npc_staff").size()

func get_total_npc_count() -> int:
	return get_npc_staff_count()

func get_total_robot_count() -> int:
	return get_robot_humanoid_count() + get_robot_single_count()

func get_total_entity_count() -> int:
	return get_total_npc_count() + get_total_robot_count()

func get_entity_stats() -> Dictionary:
	return {
		"npc_staff": get_npc_staff_count(),
		"robot_humanoid": get_robot_humanoid_count(),
		"robot_single": get_robot_single_count(),
		"total_npc": get_total_npc_count(),
		"total_robot": get_total_robot_count(),
		"total_entities": get_total_entity_count(),
	}

func get_facilities() -> Array:
	return _facilities

func get_places() -> Array:
	return _places

func get_places_by_type(place_type: String) -> Array:
	var result := []
	for p in _places:
		if p.type == place_type:
			result.append(p)
	return result

func get_floor_1_summary() -> Dictionary:
	return {
		"area_count": _areas.size(),
		"entity_stats": get_entity_stats(),
		"facility_count": _facilities.size(),
		"place_count": _places.size(),
	}

func get_debug_info() -> String:
	var info := "Floor 1 Configuration (Shoes)\n"
	info += "==============================\n\n"
	var summary = get_floor_1_summary()
	info += "Areas: %d\n" % [_areas.size()]
	info += "Entities: %s\n" % [str(summary["entity_stats"])]
	info += "Facilities: %d\n" % [_facilities.size()]
	info += "Places: %d\n\n" % [_places.size()]
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)\n" % [area.name, area.id]
		info += "  Bounds: x=%d y=%d w=%d h=%d\n" % [area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		for spawn in area.spawns:
			var patrol_str = "" if spawn.patrol_points.is_empty() else " (patrol)"
			var world_pos := get_spawn_world_pos(spawn)
			info += "    - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, world_pos.x, world_pos.y, patrol_str]
		info += "\n"
	return info
