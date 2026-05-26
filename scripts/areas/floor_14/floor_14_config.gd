# floor_14_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 14 (Electronics)
# STAFF ONLY + ROOFTOP FLOOR
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor14Config

extends Node

const CELL_SIZE := 16

const PHONES_X := 2; const PHONES_Y := 3; const PHONES_W := 30; const PHONES_H := 18
const SMARTHOME_X := 34; const SMARTHOME_Y := 3; const SMARTHOME_W := 30; const SMARTHOME_H := 18
const ELECTRONICS_X := 2; const ELECTRONICS_Y := 23; const ELECTRONICS_W := 38; const ELECTRONICS_H := 16
const REPAIR_X := 42; const REPAIR_Y := 23; const REPAIR_W := 36; const REPAIR_H := 16
const TRANSIT_X := 80; const TRANSIT_Y := 2; const TRANSIT_W := 10; const TRANSIT_H := 40

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
	var phones_spawns := [
		EntitySpawnDef.new("npc_staff", "SALES_STAFF", "phones_gadgets", 10, 6, [
			Vector2(160, 96), Vector2(320, 96), Vector2(480, 96), Vector2(320, 96), Vector2(160, 96)
		]),
		EntitySpawnDef.new("robot_single", "GUIDANCE_ROBOT", "phones_gadgets", 20, 12, [
			Vector2(320, 192), Vector2(480, 192), Vector2(480, 272), Vector2(320, 272), Vector2(320, 192)
		]),
	]
	_areas["phones_gadgets"] = AreaDef.new("phones_gadgets", "Phones & Gadgets", ["phone_gadgets"], phones_spawns, {"x":PHONES_X,"y":PHONES_Y,"w":PHONES_W,"h":PHONES_H})

	var smarthome_spawns := [
		EntitySpawnDef.new("npc_staff", "TECH_ADVISOR", "smart_home", 42, 6, [
			Vector2(672, 96), Vector2(832, 96), Vector2(992, 96), Vector2(832, 96), Vector2(672, 96)
		]),
		EntitySpawnDef.new("npc_staff", "DEMO_SPECIALIST", "smart_home", 54, 12, [
			Vector2(864, 192), Vector2(1024, 192), Vector2(1024, 272), Vector2(864, 272), Vector2(864, 192)
		]),
	]
	_areas["smart_home"] = AreaDef.new("smart_home", "Smart Home", ["smart_home"], smarthome_spawns, {"x":SMARTHOME_X,"y":SMARTHOME_Y,"w":SMARTHOME_W,"h":SMARTHOME_H})

	var electronics_spawns := [
		EntitySpawnDef.new("npc_staff", "SHELF_STOCKER", "electronics", 10, 26, [
			Vector2(160, 416), Vector2(384, 416), Vector2(608, 416), Vector2(384, 416), Vector2(160, 416)
		]),
		EntitySpawnDef.new("npc_staff", "SALES_STAFF", "electronics", 24, 30, [
			Vector2(384, 480), Vector2(608, 480), Vector2(608, 592), Vector2(384, 592), Vector2(384, 480)
		]),
		EntitySpawnDef.new("robot_single", "CLEANING_ROBOT", "electronics", 16, 32, [
			Vector2(256, 512), Vector2(448, 512), Vector2(448, 592), Vector2(256, 592), Vector2(256, 512)
		]),
	]
	_areas["electronics"] = AreaDef.new("electronics", "Electronics", ["electronics"], electronics_spawns, {"x":ELECTRONICS_X,"y":ELECTRONICS_Y,"w":ELECTRONICS_W,"h":ELECTRONICS_H})

	var repair_spawns := [
		EntitySpawnDef.new("npc_staff", "REPAIR_TECHNICIAN", "repair_counter", 48, 26, [
			Vector2(768, 416), Vector2(960, 416), Vector2(960, 544), Vector2(768, 544), Vector2(768, 416)
		]),
		EntitySpawnDef.new("robot_single", "MAINTENANCE_ROBOT", "repair_counter", 58, 32, [
			Vector2(928, 512), Vector2(1120, 512), Vector2(1120, 592), Vector2(928, 592), Vector2(928, 512)
		]),
	]
	_areas["repair_counter"] = AreaDef.new("repair_counter", "Repair Counter", ["repair_counter"], repair_spawns, {"x":REPAIR_X,"y":REPAIR_Y,"w":REPAIR_W,"h":REPAIR_H})

	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 82, 15, [
			Vector2(1312, 240), Vector2(1440, 240), Vector2(1440, 560), Vector2(1312, 560), Vector2(1312, 240)
		]),
	]
	_areas["transit"] = AreaDef.new("transit", "Transit", ["elevator_shaft","stairs"], transit_spawns, {"x":TRANSIT_X,"y":TRANSIT_Y,"w":TRANSIT_W,"h":TRANSIT_H})

func _setup_facilities() -> void:
	_facilities = [Facility.new("ad", "AD Display", 1, 66, 4, 6, 6)]

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 80, 2, 4, 40),
		Place.new("stairs", "Stairs", 84, 2, 6, 40),
		Place.new("phones_gadgets", "Phones & Gadgets", 2, 3, 30, 18),
		Place.new("smart_home", "Smart Home", 34, 3, 30, 18),
		Place.new("electronics", "Electronics", 2, 23, 38, 16),
		Place.new("repair_counter", "Repair Counter", 42, 23, 36, 16),
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
func get_floor_14_summary() -> Dictionary:
	return {"area_count": _areas.size(), "entity_stats": get_entity_stats(), "facility_count": _facilities.size(), "place_count": _places.size(), "is_staff_only": true, "is_rooftop": true}
func get_debug_info() -> String:
	var info := "Floor 14 Configuration (Electronics)\n"
	info += "STAFF ONLY | ROOFTOP\n========================================================\n\n"
	info += "Areas: %d  Entities: %s  Facilities: %d  Places: %d\n\n" % [_areas.size(), str(get_entity_stats()), _facilities.size(), _places.size()]
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)  Bounds: x=%d y=%d w=%d h=%d\n" % [area.name, area.id, area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		for spawn in area.spawns:
			var wp := get_spawn_world_pos(spawn)
			info += "  - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, wp.x, wp.y, "" if spawn.patrol_points.is_empty() else " (patrol)"]
	return info
