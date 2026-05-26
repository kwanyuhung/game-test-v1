# floor_3_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 3 (Sports Floor)
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor3Config

extends Node

const CELL_SIZE := 16

# Area bounds (tiles)
const GYM_X := 2;   const GYM_Y := 3;   const GYM_W := 24;  const GYM_H := 16
const GEAR_X := 28; const GEAR_Y := 3;   const GEAR_W := 24;  const GEAR_H := 16
const TEAM_X := 54; const TEAM_Y := 3;   const TEAM_W := 24;  const TEAM_H := 16
const ACTIVE_X := 2; const ACTIVE_Y := 21; const ACTIVE_W := 38; const ACTIVE_H := 16
const FITNESS_X := 42; const FITNESS_Y := 21; const FITNESS_W := 36; const FITNESS_H := 16
const TRANSIT_X := 0; const TRANSIT_Y := 2; const TRANSIT_W := 80; const TRANSIT_H := 40

class EntitySpawnDef:
	var entity_type: String
	var role: String
	var area: String
	var x: int; var y: int
	var patrol_points: Array

	func _init(p_type: String, p_role: String, p_area: String, p_x: int, p_y: int, p_patrol: Array = []) -> void:
		entity_type = p_type; role = p_role; area = p_area; x = p_x; y = p_y; patrol_points = p_patrol

class AreaDef:
	var id: String; var name: String; var zone_types: Array; var spawns: Array; var world_bounds: Dictionary
	func _init(p_id, p_name, p_zone_types, p_spawns, p_bounds):
		id = p_id; name = p_name; zone_types = p_zone_types; spawns = p_spawns; world_bounds = p_bounds
	func get_center() -> Vector2:
		return Vector2((world_bounds.x + world_bounds.w / 2.0) * CELL_SIZE, (world_bounds.y + world_bounds.h / 2.0) * CELL_SIZE)
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
	var gym_spawns := [
		EntitySpawnDef.new("npc_staff", "FITNESS_ADVISOR", "gym", 8, 6, [
			Vector2(128, 96), Vector2(304, 96), Vector2(480, 96), Vector2(304, 96), Vector2(128, 96)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "gym", 14, 12, [
			Vector2(224, 192), Vector2(400, 192), Vector2(400, 272), Vector2(224, 272), Vector2(224, 192)
		]),
	]
	_areas["gym"] = AreaDef.new("gym", "Gym Equipment", ["sport_area"], gym_spawns, {"x":GYM_X,"y":GYM_Y,"w":GYM_W,"h":GYM_H})

	var gear_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "sports_gear", 34, 6, [
			Vector2(544, 96), Vector2(720, 96), Vector2(896, 96), Vector2(720, 96), Vector2(544, 96)
		]),
	]
	_areas["sports_gear"] = AreaDef.new("sports_gear", "Sports Gear", ["sport_area"], gear_spawns, {"x":GEAR_X,"y":GEAR_Y,"w":GEAR_W,"h":GEAR_H})

	var team_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "team_sports", 60, 6, [
			Vector2(960, 96), Vector2(1120, 96), Vector2(1120, 160), Vector2(960, 160), Vector2(960, 96)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "team_sports", 66, 12, [
			Vector2(1056, 192), Vector2(1184, 192), Vector2(1184, 272), Vector2(1056, 272), Vector2(1056, 192)
		]),
	]
	_areas["team_sports"] = AreaDef.new("team_sports", "Team Sports", ["sport_area"], team_spawns, {"x":TEAM_X,"y":TEAM_Y,"w":TEAM_W,"h":TEAM_H})

	var active_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "activewear", 8, 24, [
			Vector2(128, 384), Vector2(384, 384), Vector2(544, 384), Vector2(384, 384), Vector2(128, 384)
		]),
		EntitySpawnDef.new("npc_staff", "FITNESS_ADVISOR", "activewear", 20, 28, [
			Vector2(320, 448), Vector2(560, 448), Vector2(560, 560), Vector2(320, 560), Vector2(320, 448)
		]),
	]
	_areas["activewear"] = AreaDef.new("activewear", "Activewear", ["sport_area"], active_spawns, {"x":ACTIVE_X,"y":ACTIVE_Y,"w":ACTIVE_W,"h":ACTIVE_H})

	var fitness_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "fitness", 48, 24, [
			Vector2(768, 384), Vector2(960, 384), Vector2(960, 544), Vector2(768, 544), Vector2(768, 384)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "fitness", 58, 30, [
			Vector2(928, 480), Vector2(1088, 480), Vector2(1088, 560), Vector2(928, 560), Vector2(928, 480)
		]),
	]
	_areas["fitness"] = AreaDef.new("fitness", "Fitness", ["sport_area"], fitness_spawns, {"x":FITNESS_X,"y":FITNESS_Y,"w":FITNESS_W,"h":FITNESS_H})

	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 8, 15, [
			Vector2(128, 240), Vector2(320, 240), Vector2(320, 560), Vector2(128, 560), Vector2(128, 240)
		]),
	]
	_areas["transit"] = AreaDef.new("transit", "Transit", ["elevator_shaft","stairs"], transit_spawns, {"x":TRANSIT_X,"y":TRANSIT_Y,"w":TRANSIT_W,"h":TRANSIT_H})

func _setup_facilities() -> void:
	_facilities = [Facility.new("ad", "AD Display", 1, 70, 4, 6, 6)]

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 6, 2, 14, 40),
		Place.new("stairs", "Stairs", 20, 2, 6, 40),
		Place.new("gym", "Gym Equipment", 2, 3, 24, 16),
		Place.new("sports_gear", "Sports Gear", 28, 3, 24, 16),
		Place.new("team_sports", "Team Sports", 54, 3, 24, 16),
		Place.new("activewear", "Activewear", 2, 21, 38, 16),
		Place.new("fitness", "Fitness", 42, 21, 36, 16),
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
func get_floor_3_summary() -> Dictionary:
	return {"area_count": _areas.size(), "entity_stats": get_entity_stats(), "facility_count": _facilities.size(), "place_count": _places.size()}
func get_debug_info() -> String:
	var info := "Floor 3 Configuration (Sports)\n================================\n\n"
	info += "Areas: %d  Entities: %s  Facilities: %d  Places: %d\n\n" % [_areas.size(), str(get_entity_stats()), _facilities.size(), _places.size()]
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)  Bounds: x=%d y=%d w=%d h=%d\n" % [area.name, area.id, area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		for spawn in area.spawns:
			var wp := get_spawn_world_pos(spawn)
			info += "  - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, wp.x, wp.y, "" if spawn.patrol_points.is_empty() else " (patrol)"]
	return info
