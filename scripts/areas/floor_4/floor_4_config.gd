# floor_4_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 4 (Outdoor Floor)
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor4Config

extends Node

const CELL_SIZE := 16

const FISHING_X := 2;   const FISHING_Y := 3;   const FISHING_W := 24;  const FISHING_H := 16
const HIKING_X := 28;   const HIKING_Y := 3;   const HIKING_W := 24;  const HIKING_H := 16
const RUNNING_X := 54;  const RUNNING_Y := 3;   const RUNNING_W := 24;  const RUNNING_H := 16
const CAMPING_X := 2;   const CAMPING_Y := 21;  const CAMPING_W := 38;  const CAMPING_H := 16
const CYCLING_X := 42;  const CYCLING_Y := 21;  const CYCLING_W := 36;  const CYCLING_H := 16
const TRANSIT_X := 80;  const TRANSIT_Y := 2;   const TRANSIT_W := 10;  const TRANSIT_H := 40

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
	var fishing_spawns := [
		EntitySpawnDef.new("npc_staff", "EXPERT", "fishing", 8, 6, [
			Vector2(128, 96), Vector2(304, 96), Vector2(480, 96), Vector2(304, 96), Vector2(128, 96)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "fishing", 14, 12, [
			Vector2(224, 192), Vector2(400, 192), Vector2(400, 272), Vector2(224, 272), Vector2(224, 192)
		]),
	]
	_areas["fishing"] = AreaDef.new("fishing", "Fishing", ["outdoor_area"], fishing_spawns, {"x":FISHING_X,"y":FISHING_Y,"w":FISHING_W,"h":FISHING_H})

	var hiking_spawns := [
		EntitySpawnDef.new("npc_staff", "EXPERT", "hiking", 34, 6, [
			Vector2(544, 96), Vector2(720, 96), Vector2(896, 96), Vector2(720, 96), Vector2(544, 96)
		]),
	]
	_areas["hiking"] = AreaDef.new("hiking", "Hiking", ["outdoor_area"], hiking_spawns, {"x":HIKING_X,"y":HIKING_Y,"w":HIKING_W,"h":HIKING_H})

	var running_spawns := [
		EntitySpawnDef.new("npc_staff", "FITNESS_ADVISOR", "running", 60, 6, [
			Vector2(960, 96), Vector2(1120, 96), Vector2(1120, 160), Vector2(960, 160), Vector2(960, 96)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "running", 66, 12, [
			Vector2(1056, 192), Vector2(1184, 192), Vector2(1184, 272), Vector2(1056, 272), Vector2(1056, 192)
		]),
	]
	_areas["running"] = AreaDef.new("running", "Running", ["outdoor_area"], running_spawns, {"x":RUNNING_X,"y":RUNNING_Y,"w":RUNNING_W,"h":RUNNING_H})

	var camping_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "camping", 8, 24, [
			Vector2(128, 384), Vector2(384, 384), Vector2(544, 384), Vector2(384, 384), Vector2(128, 384)
		]),
		EntitySpawnDef.new("npc_staff", "EXPERT", "camping", 20, 28, [
			Vector2(320, 448), Vector2(560, 448), Vector2(560, 560), Vector2(320, 560), Vector2(320, 448)
		]),
	]
	_areas["camping"] = AreaDef.new("camping", "Camping", ["outdoor_area"], camping_spawns, {"x":CAMPING_X,"y":CAMPING_Y,"w":CAMPING_W,"h":CAMPING_H})

	var cycling_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "cycling", 48, 24, [
			Vector2(768, 384), Vector2(960, 384), Vector2(960, 544), Vector2(768, 544), Vector2(768, 384)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "cycling", 58, 30, [
			Vector2(928, 480), Vector2(1088, 480), Vector2(1088, 560), Vector2(928, 560), Vector2(928, 480)
		]),
	]
	_areas["cycling"] = AreaDef.new("cycling", "Cycling", ["outdoor_area"], cycling_spawns, {"x":CYCLING_X,"y":CYCLING_Y,"w":CYCLING_W,"h":CYCLING_H})

	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 82, 15, [
			Vector2(1312, 240), Vector2(1440, 240), Vector2(1440, 560), Vector2(1312, 560), Vector2(1312, 240)
		]),
	]
	_areas["transit"] = AreaDef.new("transit", "Transit", ["elevator_shaft","stairs"], transit_spawns, {"x":TRANSIT_X,"y":TRANSIT_Y,"w":TRANSIT_W,"h":TRANSIT_H})

func _setup_facilities() -> void:
	_facilities = [Facility.new("ad", "AD Display", 1, 70, 4, 6, 6)]

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 80, 2, 4, 40),
		Place.new("stairs", "Stairs", 84, 2, 6, 40),
		Place.new("fishing", "Fishing Gear", 2, 3, 24, 16),
		Place.new("hiking", "Hiking Gear", 28, 3, 24, 16),
		Place.new("running", "Running Gear", 54, 3, 24, 16),
		Place.new("camping", "Camping Gear", 2, 21, 38, 16),
		Place.new("cycling", "Cycling Gear", 42, 21, 36, 16),
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
func get_floor_4_summary() -> Dictionary:
	return {"area_count": _areas.size(), "entity_stats": get_entity_stats(), "facility_count": _facilities.size(), "place_count": _places.size()}
func get_debug_info() -> String:
	var info := "Floor 4 Configuration (Outdoor)\n================================\n\n"
	info += "Areas: %d  Entities: %s  Facilities: %d  Places: %d\n\n" % [_areas.size(), str(get_entity_stats()), _facilities.size(), _places.size()]
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)  Bounds: x=%d y=%d w=%d h=%d\n" % [area.name, area.id, area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		for spawn in area.spawns:
			var wp := get_spawn_world_pos(spawn)
			info += "  - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, wp.x, wp.y, "" if spawn.patrol_points.is_empty() else " (patrol)"]
	return info
