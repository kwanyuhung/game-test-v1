# floor_5_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 5 (Stationery + Plants Floor)
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor5Config

extends Node

const CELL_SIZE := 16

const STATIONERY_X := 2;   const STATIONERY_Y := 3;   const STATIONERY_W := 36;  const STATIONERY_H := 18
const OFFICE_X := 40;     const OFFICE_Y := 3;       const OFFICE_W := 38;      const OFFICE_H := 18
const INDOOR_X := 2;      const INDOOR_Y := 23;      const INDOOR_W := 38;      const INDOOR_H := 14
const GARDEN_X := 42;     const GARDEN_Y := 23;      const GARDEN_W := 36;      const GARDEN_H := 14
const TRANSIT_X := 80;    const TRANSIT_Y := 2;       const TRANSIT_W := 10;     const TRANSIT_H := 40

class EntitySpawnDef:
	var entity_type: String; var role: String; var area: String; var x: int; var y: int; var patrol_points: Array
	func _init(p_type: String, p_role: String, p_area: String, p_x: int, p_y: int, p_patrol: Array = []) -> void:
		entity_type = p_type; role = p_role; area = p_area; x = p_x; y = p_y; patrol_points = p_patrol

class AreaDef:
	var id: String; var name: String; var zone_types: Array; var spawns: Array; var world_bounds: Dictionary
	func _init(p_id, p_name, p_zone_types, p_spawns, p_bounds):
		id = p_id; name = p_name; zone_types = p_zone_types; spawns = p_spawns; world_bounds = p_bounds
	func contains_point(px: int, py: int) -> bool:
		return px >= world_bounds.x and px < world_bounds.x + world_bounds.w and py >= world_bounds.y and py < world_bounds.y + world_bounds.h

class Facility:
	var type: String; var name: String; var count: int; var x: int; var y: int; var w: int; var h: int
	func _init(p_type, p_name, p_count, p_x=0, p_y=0, p_w=0, p_h=0):
		type = p_type; name = p_name; count = p_count; x = p_x; y = p_y; w = p_w; h = p_h

class Place:
	var type: String; var name: String; var x: int; var y: int; var w: int; var h: int; var meta: Dictionary
	func _init(p_type, p_name, p_x, p_y, p_w=0, p_h=0, p_meta={}):
		type = p_type; name = p_name; x = p_x; y = p_y; w = p_w; h = p_h; meta = p_meta

var _areas: Dictionary = {}; var _facilities: Array = []; var _places: Array = []

func _init() -> void:
	_setup_areas(); _setup_facilities(); _setup_places()

func _setup_areas() -> void:
	var stationery_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "stationery", 10, 6, [
			Vector2(160, 96), Vector2(384, 96), Vector2(576, 96), Vector2(384, 96), Vector2(160, 96)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "stationery", 20, 12, [
			Vector2(320, 192), Vector2(544, 192), Vector2(544, 272), Vector2(320, 272), Vector2(320, 192)
		]),
	]
	_areas["stationery"] = AreaDef.new("stationery", "Stationery", ["stationery"], stationery_spawns, {"x":STATIONERY_X,"y":STATIONERY_Y,"w":STATIONERY_W,"h":STATIONERY_H})

	var office_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "office_supplies", 48, 6, [
			Vector2(768, 96), Vector2(992, 96), Vector2(1216, 96), Vector2(992, 96), Vector2(768, 96)
		]),
		EntitySpawnDef.new("npc_staff", "CUSTOMER_SERVICE", "office_supplies", 58, 12, [
			Vector2(928, 192), Vector2(1152, 192), Vector2(1152, 272), Vector2(928, 272), Vector2(928, 192)
		]),
	]
	_areas["office_supplies"] = AreaDef.new("office_supplies", "Office Supplies", ["stationery"], office_spawns, {"x":OFFICE_X,"y":OFFICE_Y,"w":OFFICE_W,"h":OFFICE_H})

	var indoor_spawns := [
		EntitySpawnDef.new("npc_staff", "FLORIST", "indoor_plants", 8, 25, [
			Vector2(128, 400), Vector2(384, 400), Vector2(544, 400), Vector2(384, 400), Vector2(128, 400)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "indoor_plants", 20, 30, [
			Vector2(320, 480), Vector2(560, 480), Vector2(560, 576), Vector2(320, 576), Vector2(320, 480)
		]),
	]
	_areas["indoor_plants"] = AreaDef.new("indoor_plants", "Indoor Plants", ["plants_area"], indoor_spawns, {"x":INDOOR_X,"y":INDOOR_Y,"w":INDOOR_W,"h":INDOOR_H})

	var garden_spawns := [
		EntitySpawnDef.new("npc_staff", "FLORIST", "garden_plants", 48, 25, [
			Vector2(768, 400), Vector2(960, 400), Vector2(960, 544), Vector2(768, 544), Vector2(768, 400)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "garden_plants", 58, 30, [
			Vector2(928, 480), Vector2(1088, 480), Vector2(1088, 560), Vector2(928, 560), Vector2(928, 480)
		]),
	]
	_areas["garden_plants"] = AreaDef.new("garden_plants", "Garden Plants", ["plants_area"], garden_spawns, {"x":GARDEN_X,"y":GARDEN_Y,"w":GARDEN_W,"h":GARDEN_H})

	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 82, 15, [
			Vector2(1312, 240), Vector2(1440, 240), Vector2(1440, 560), Vector2(1312, 560), Vector2(1312, 240)
		]),
	]
	_areas["transit"] = AreaDef.new("transit", "Transit", ["elevator_shaft","stairs"], transit_spawns, {"x":TRANSIT_X,"y":TRANSIT_Y,"w":TRANSIT_W,"h":TRANSIT_H})

func _setup_facilities() -> void:
	_facilities = [Facility.new("ad", "AD Display", 1, 72, 4, 6, 6)]

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 80, 2, 4, 40),
		Place.new("stairs", "Stairs", 84, 2, 6, 40),
		Place.new("stationery", "Stationery Section", 2, 3, 36, 18),
		Place.new("office_supplies", "Office Supplies", 40, 3, 38, 18),
		Place.new("indoor_plants", "Indoor Plants", 2, 23, 38, 14),
		Place.new("garden_plants", "Garden Plants", 42, 23, 36, 14),
	]

func tile_to_pixel(tx: int, ty: int) -> Vector2: return Vector2(tx * CELL_SIZE, ty * CELL_SIZE)
func pixel_to_tile(px: int, py: int) -> Vector2: return Vector2(px / CELL_SIZE, py / CELL_SIZE)
func tile_to_world(tx: int, ty: int) -> Vector2: return tile_to_pixel(tx, ty)
func get_spawn_world_pos(spawn: EntitySpawnDef) -> Vector2: return tile_to_world(spawn.x, spawn.y)

func get_area(area_id: String) -> AreaDef: return _areas.get(area_id)
func get_all_areas() -> Array: return _areas.values()
func get_spawns_by_area(area_id: String) -> Array:
	var a = _areas.get(area_id); return a.spawns if a else []
func get_spawns_by_type(t: String) -> Array:
	var r := []
	for a in _areas.values():
		for s in a.spawns:
			if s.entity_type == t:
				r.append(s)
	return r
func get_npc_staff_spawns() -> Array: return get_spawns_by_type("npc_staff")
func get_robot_spawns() -> Array:
	var r := []; r.append_array(get_spawns_by_type("robot_humanoid")); r.append_array(get_spawns_by_type("robot_single")); return r
func get_npc_staff_count() -> int: return get_spawns_by_type("npc_staff").size()
func get_robot_humanoid_count() -> int: return get_spawns_by_type("robot_humanoid").size()
func get_robot_single_count() -> int: return get_spawns_by_type("robot_single").size()
func get_total_npc_count() -> int: return get_npc_staff_count()
func get_total_robot_count() -> int: return get_robot_humanoid_count() + get_robot_single_count()
func get_total_entity_count() -> int: return get_total_npc_count() + get_total_robot_count()
func get_entity_stats() -> Dictionary:
	return {"npc_staff": get_npc_staff_count(), "robot_humanoid": get_robot_humanoid_count(), "robot_single": get_robot_single_count(),
		"total_npc": get_total_npc_count(), "total_robot": get_total_robot_count(), "total_entities": get_total_entity_count()}
func get_facilities() -> Array: return _facilities
func get_places() -> Array: return _places
func get_floor_5_summary() -> Dictionary:
	return {"area_count": _areas.size(), "entity_stats": get_entity_stats(), "facility_count": _facilities.size(), "place_count": _places.size()}
func get_debug_info() -> String:
	var info := "Floor 5 Configuration (Stationery + Plants)\n=========================================\n\n"
	info += "Areas: %d  Entities: %s  Facilities: %d  Places: %d\n\n" % [_areas.size(), str(get_entity_stats()), _facilities.size(), _places.size()]
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)  Bounds: x=%d y=%d w=%d h=%d\n" % [area.name, area.id, area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		for spawn in area.spawns:
			var wp := get_spawn_world_pos(spawn)
			info += "  - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, wp.x, wp.y, "" if spawn.patrol_points.is_empty() else " (patrol)"]
	return info
