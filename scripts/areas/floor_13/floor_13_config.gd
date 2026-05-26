# floor_13_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 13 (Kids Kingdom)
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor13Config

extends Node

const CELL_SIZE := 16

const PLAY_X := 2; const PLAY_Y := 3; const PLAY_W := 28; const PLAY_H := 20
const CLUB_X := 32; const CLUB_Y := 3; const CLUB_W := 24; const CLUB_H := 20
const NURSERY_X := 58; const NURSERY_Y := 3; const NURSERY_W := 20; const NURSERY_H := 12
const FAMILY_WC_X := 58; const FAMILY_WC_Y := 17; const FAMILY_WC_W := 20; const FAMILY_WC_H := 12
const TRANSIT_X := 78; const TRANSIT_Y := 2; const TRANSIT_W := 9; const TRANSIT_H := 40

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
	var play_spawns := [
		EntitySpawnDef.new("npc_staff", "PLAY_ATTENDANT", "play_zone", 10, 8, [
			Vector2(160, 128), Vector2(288, 128), Vector2(416, 128), Vector2(288, 128), Vector2(160, 128)
		]),
		EntitySpawnDef.new("npc_staff", "ENTERTAINMENT_STAFF", "play_zone", 18, 14, [
			Vector2(288, 224), Vector2(416, 224), Vector2(416, 320), Vector2(288, 320), Vector2(288, 224)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "play_zone", 14, 18, [
			Vector2(224, 288), Vector2(352, 288), Vector2(352, 368), Vector2(224, 368), Vector2(224, 288)
		]),
	]
	_areas["play_zone"] = AreaDef.new("play_zone", "Play Zone", ["kids_play"], play_spawns, {"x":PLAY_X,"y":PLAY_Y,"w":PLAY_W,"h":PLAY_H})

	var club_spawns := [
		EntitySpawnDef.new("npc_staff", "KIDS_CLUB_HOST", "kids_club", 38, 8, [
			Vector2(608, 128), Vector2(768, 128), Vector2(768, 224), Vector2(608, 224), Vector2(608, 128)
		]),
		EntitySpawnDef.new("robot_single", "ENTERTAINMENT_ROBOT", "kids_club", 44, 14, [
			Vector2(704, 224), Vector2(864, 224), Vector2(864, 320), Vector2(704, 320), Vector2(704, 224)
		]),
	]
	_areas["kids_club"] = AreaDef.new("kids_club", "Kids Club", ["kids_club"], club_spawns, {"x":CLUB_X,"y":CLUB_Y,"w":CLUB_W,"h":CLUB_H})

	var nursery_spawns := [
		EntitySpawnDef.new("npc_staff", "NURSERY_ATTENDANT", "nursery", 64, 6, [
			Vector2(1024, 96), Vector2(1184, 96), Vector2(1184, 160), Vector2(1024, 160), Vector2(1024, 96)
		]),
	]
	_areas["nursery"] = AreaDef.new("nursery", "Nursing Room", ["nursing_room"], nursery_spawns, {"x":NURSERY_X,"y":NURSERY_Y,"w":NURSERY_W,"h":NURSERY_H})

	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 80, 15, [
			Vector2(1280, 240), Vector2(1408, 240), Vector2(1408, 560), Vector2(1280, 560), Vector2(1280, 240)
		]),
	]
	_areas["transit"] = AreaDef.new("transit", "Transit", ["elevator_shaft","stairs"], transit_spawns, {"x":TRANSIT_X,"y":TRANSIT_Y,"w":TRANSIT_W,"h":TRANSIT_H})

func _setup_facilities() -> void:
	_facilities = []

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 83, 2, 4, 40),
		Place.new("stairs", "Stairs", 78, 2, 4, 40),
		Place.new("play_zone", "Play Zone", 2, 3, 28, 20),
		Place.new("kids_club", "Kids Club", 32, 3, 24, 20),
		Place.new("nursery", "Nursing Room", 58, 3, 20, 12),
		Place.new("family_wc", "Family WC", 58, 17, 20, 12),
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
func get_floor_13_summary() -> Dictionary:
	return {"area_count": _areas.size(), "entity_stats": get_entity_stats(), "facility_count": _facilities.size(), "place_count": _places.size()}
func get_debug_info() -> String:
	var info := "Floor 13 Configuration (Kids Kingdom)\n"
	info += "========================================================\n\n"
	info += "Areas: %d  Entities: %s  Facilities: %d  Places: %d\n\n" % [_areas.size(), str(get_entity_stats()), _facilities.size(), _places.size()]
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)  Bounds: x=%d y=%d w=%d h=%d\n" % [area.name, area.id, area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		for spawn in area.spawns:
			var wp := get_spawn_world_pos(spawn)
			info += "  - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, wp.x, wp.y, "" if spawn.patrol_points.is_empty() else " (patrol)"]
	return info
