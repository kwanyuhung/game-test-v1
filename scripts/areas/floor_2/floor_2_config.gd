# floor_2_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 2 (Fashion Floor)
# Organizes zones, NPC spawns, and Robot spawns into logical areas
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor2Config

extends Node

const CELL_SIZE := 16

# Area bounds (tiles) — derived from floor_config_data.json zones
const LADIES_X := 2
const LADIES_Y := 3
const LADIES_W := 26
const LADIES_H := 18

const MENS_X := 30
const MENS_Y := 3
const MENS_W := 26
const MENS_H := 18

const KIDS_X := 58
const KIDS_Y := 3
const KIDS_W := 20
const KIDS_H := 18

const ACTIVEWEAR_X := 2
const ACTIVEWEAR_Y := 23
const ACTIVEWEAR_W := 38
const ACTIVEWEAR_H := 14

const FORMAL_X := 42
const FORMAL_Y := 23
const FORMAL_W := 36
const FORMAL_H := 14

const TRANSIT_X := 0
const TRANSIT_Y := 2
const TRANSIT_W := 80
const TRANSIT_H := 40

# ═══════════════════════════════════════════════════════════════════════════
# ENTITY SPAWN DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════

class EntitySpawnDef:
	var entity_type: String
	var role: String
	var area: String
	var x: int  # Tile X → world px via tile_to_pixel
	var y: int  # Tile Y → world px via tile_to_pixel
	var patrol_points: Array  # WORLD PIXEL coords

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
# FACILITY / PLACE
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
		type = p_type; name = p_name; count = p_count
		x = p_x; y = p_y; w = p_w; h = p_h

class Place:
	var type: String
	var name: String
	var x: int
	var y: int
	var w: int
	var h: int
	var meta: Dictionary

	func _init(p_type: String, p_name: String, p_x: int, p_y: int, p_w: int = 0, p_h: int = 0, p_meta: Dictionary = {}) -> void:
		type = p_type; name = p_name; x = p_x; y = p_y; w = p_w; h = p_h; meta = p_meta

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
	# ─── LADIES WEAR AREA ────────────────────────────────────────────
	var ladies_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "ladies_wear", 8, 6, [
			Vector2(128, 96), Vector2(304, 96), Vector2(480, 96), Vector2(304, 96), Vector2(128, 96)
		]),
		EntitySpawnDef.new("npc_staff", "STYLIST", "ladies_wear", 16, 10, [
			Vector2(256, 160), Vector2(432, 160), Vector2(432, 240), Vector2(256, 240), Vector2(256, 160)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "ladies_wear", 12, 14, [
			Vector2(192, 224), Vector2(368, 224), Vector2(368, 304), Vector2(192, 304), Vector2(192, 224)
		]),
	]
	_areas["ladies_wear"] = AreaDef.new(
		"ladies_wear", "Ladies Wear",
		["dress_rack"],
		ladies_spawns,
		{"x": LADIES_X, "y": LADIES_Y, "w": LADIES_W, "h": LADIES_H}
	)

	# ─── MENS WEAR AREA ─────────────────────────────────────────────
	var mens_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "mens_wear", 36, 6, [
			Vector2(576, 96), Vector2(752, 96), Vector2(928, 96), Vector2(752, 96), Vector2(576, 96)
		]),
		EntitySpawnDef.new("npc_staff", "STYLIST", "mens_wear", 44, 10, [
			Vector2(704, 160), Vector2(880, 160), Vector2(880, 240), Vector2(704, 240), Vector2(704, 160)
		]),
	]
	_areas["mens_wear"] = AreaDef.new(
		"mens_wear", "Mens Wear",
		["dress_rack"],
		mens_spawns,
		{"x": MENS_X, "y": MENS_Y, "w": MENS_W, "h": MENS_H}
	)

	# ─── KIDS WEAR AREA ──────────────────────────────────────────────
	var kids_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "kids_wear", 62, 6, [
			Vector2(992, 96), Vector2(1152, 96), Vector2(1152, 160), Vector2(992, 160), Vector2(992, 96)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "kids_wear", 68, 14, [
			Vector2(1088, 224), Vector2(1216, 224), Vector2(1216, 304), Vector2(1088, 304), Vector2(1088, 224)
		]),
	]
	_areas["kids_wear"] = AreaDef.new(
		"kids_wear", "Kids Wear",
		["dress_rack"],
		kids_spawns,
		{"x": KIDS_X, "y": KIDS_Y, "w": KIDS_W, "h": KIDS_H}
	)

	# ─── ACTIVEWEAR AREA ─────────────────────────────────────────────
	var activewear_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "activewear", 8, 25, [
			Vector2(128, 400), Vector2(384, 400), Vector2(544, 400), Vector2(384, 400), Vector2(128, 400)
		]),
		EntitySpawnDef.new("npc_staff", "FITNESS_ADVISOR", "activewear", 20, 28, [
			Vector2(320, 448), Vector2(560, 448), Vector2(560, 560), Vector2(320, 560), Vector2(320, 448)
		]),
	]
	_areas["activewear"] = AreaDef.new(
		"activewear", "Activewear",
		["dress_rack"],
		activewear_spawns,
		{"x": ACTIVEWEAR_X, "y": ACTIVEWEAR_Y, "w": ACTIVEWEAR_W, "h": ACTIVEWEAR_H}
	)

	# ─── FORMAL WEAR AREA ────────────────────────────────────────────
	var formal_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "formal_wear", 48, 25, [
			Vector2(768, 400), Vector2(960, 400), Vector2(960, 544), Vector2(768, 544), Vector2(768, 400)
		]),
		EntitySpawnDef.new("npc_staff", "STYLIST", "formal_wear", 58, 30, [
			Vector2(928, 480), Vector2(1088, 480), Vector2(1088, 592), Vector2(928, 592), Vector2(928, 480)
		]),
	]
	_areas["formal_wear"] = AreaDef.new(
		"formal_wear", "Formal Wear",
		["dress_rack"],
		formal_spawns,
		{"x": FORMAL_X, "y": FORMAL_Y, "w": FORMAL_W, "h": FORMAL_H}
	)

	# ─── TRANSIT AREA ────────────────────────────────────────────────
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
		Facility.new("ad", "AD Display", 1, 68, 4, 4, 6),
	]

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 6, 2, 14, 40),
		Place.new("stairs", "Stairs", 20, 2, 6, 40),
		Place.new("ladies_wear", "Ladies Wear Section", 2, 3, 26, 18),
		Place.new("mens_wear", "Mens Wear Section", 30, 3, 26, 18),
		Place.new("kids_wear", "Kids Wear Section", 58, 3, 20, 18),
		Place.new("activewear", "Activewear Section", 2, 23, 38, 14),
		Place.new("formal_wear", "Formal Wear Section", 42, 23, 36, 14),
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

func get_npc_staff_count() -> int:
	return get_spawns_by_type("npc_staff").size()

func get_robot_humanoid_count() -> int:
	return get_spawns_by_type("robot_humanoid").size()

func get_robot_single_count() -> int:
	return get_spawns_by_type("robot_single").size()

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

func get_floor_2_summary() -> Dictionary:
	return {
		"area_count": _areas.size(),
		"entity_stats": get_entity_stats(),
		"facility_count": _facilities.size(),
		"place_count": _places.size(),
	}

func get_debug_info() -> String:
	var info := "Floor 2 Configuration (Fashion)\n"
	info += "=================================\n\n"
	var summary = get_floor_2_summary()
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
