# floor_11_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 11 (Warehouse / Logistics)
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor11Config

extends Node

const CELL_SIZE := 16

const TRUCK_X := 2; const TRUCK_Y := 3; const TRUCK_W := 20; const TRUCK_H := 14
const FORKLIFT_X := 2; const FORKLIFT_Y := 19; const FORKLIFT_W := 20; const FORKLIFT_H := 12
const CONVEYOR_X := 24; const CONVEYOR_Y := 3; const CONVEYOR_W := 30; const CONVEYOR_H := 12
const PACKING_X := 24; const PACKING_Y := 19; const PACKING_W := 30; const PACKING_H := 12
const TRANSIT_X := 80; const TRANSIT_Y := 2; const TRANSIT_W := 4; const TRANSIT_H := 40

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
	var truck_spawns := [
		EntitySpawnDef.new("npc_staff", "DOCK_WORKER", "truck_dock", 8, 6, [
			Vector2(128, 96), Vector2(256, 96), Vector2(384, 96), Vector2(256, 96), Vector2(128, 96)
		]),
		EntitySpawnDef.new("robot_single", "DELIVERY_ROBOT", "truck_dock", 14, 10, [
			Vector2(224, 160), Vector2(352, 160), Vector2(352, 224), Vector2(224, 224), Vector2(224, 160)
		]),
	]
	_areas["truck_dock"] = AreaDef.new("truck_dock", "Truck Dock", ["truck_dock"], truck_spawns, {"x":TRUCK_X,"y":TRUCK_Y,"w":TRUCK_W,"h":TRUCK_H})

	var forklift_spawns := [
		EntitySpawnDef.new("npc_staff", "FORKLIFT_OPERATOR", "forklift_zone", 8, 22, [
			Vector2(128, 352), Vector2(256, 352), Vector2(384, 352), Vector2(256, 352), Vector2(128, 352)
		]),
	]
	_areas["forklift_zone"] = AreaDef.new("forklift_zone", "Forklift Zone", ["forklift"], forklift_spawns, {"x":FORKLIFT_X,"y":FORKLIFT_Y,"w":FORKLIFT_W,"h":FORKLIFT_H})

	var conveyor_spawns := [
		EntitySpawnDef.new("npc_staff", "CONVEYOR_OPERATOR", "conveyor_belt", 30, 6, [
			Vector2(480, 96), Vector2(640, 96), Vector2(800, 96), Vector2(640, 96), Vector2(480, 96)
		]),
		EntitySpawnDef.new("robot_single", "MAINTENANCE_ROBOT", "conveyor_belt", 40, 8, [
			Vector2(640, 128), Vector2(832, 128), Vector2(832, 208), Vector2(640, 208), Vector2(640, 128)
		]),
	]
	_areas["conveyor_belt"] = AreaDef.new("conveyor_belt", "Conveyor Belt", ["conveyor"], conveyor_spawns, {"x":CONVEYOR_X,"y":CONVEYOR_Y,"w":CONVEYOR_W,"h":CONVEYOR_H})

	var packing_spawns := [
		EntitySpawnDef.new("npc_staff", "PACKING_STAFF", "packing_station", 30, 22, [
			Vector2(480, 352), Vector2(640, 352), Vector2(800, 352), Vector2(640, 352), Vector2(480, 352)
		]),
		EntitySpawnDef.new("robot_single", "PACKING_ROBOT", "packing_station", 40, 26, [
			Vector2(640, 416), Vector2(832, 416), Vector2(832, 512), Vector2(640, 512), Vector2(640, 416)
		]),
	]
	_areas["packing_station"] = AreaDef.new("packing_station", "Packing Station", ["packing_station"], packing_spawns, {"x":PACKING_X,"y":PACKING_Y,"w":PACKING_W,"h":PACKING_H})

	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 82, 15, [
			Vector2(1312, 240), Vector2(1440, 240), Vector2(1440, 560), Vector2(1312, 560), Vector2(1312, 240)
		]),
	]
	_areas["transit"] = AreaDef.new("transit", "Transit", ["elevator_shaft"], transit_spawns, {"x":TRANSIT_X,"y":TRANSIT_Y,"w":TRANSIT_W,"h":TRANSIT_H})

func _setup_facilities() -> void:
	_facilities = [Facility.new("ad", "AD Display", 1, 60, 4, 6, 6)]

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 80, 2, 4, 40),
		Place.new("truck_dock", "Truck Dock", 2, 3, 20, 14),
		Place.new("forklift_zone", "Forklift Zone", 2, 19, 20, 12),
		Place.new("conveyor_belt", "Conveyor Belt", 24, 3, 30, 12),
		Place.new("packing_station", "Packing Station", 24, 19, 30, 12),
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
func get_floor_11_summary() -> Dictionary:
	return {"area_count": _areas.size(), "entity_stats": get_entity_stats(), "facility_count": _facilities.size(), "place_count": _places.size()}
func get_debug_info() -> String:
	var info := "Floor 11 Configuration (Warehouse)\n"
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
