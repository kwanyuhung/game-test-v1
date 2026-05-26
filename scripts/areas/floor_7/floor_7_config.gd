# floor_7_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# Structured configuration for Floor 7 (Back Office)
# STAFF ONLY FLOOR
# ─────────────────────────────────────────────────────────────────────────────
class_name Floor7Config

extends Node

const CELL_SIZE := 16

const ADMIN_X := 2;   const ADMIN_Y := 3;  const ADMIN_W := 38;  const ADMIN_H := 18
const HR_X := 42;     const HR_Y := 3;      const HR_W := 36;     const HR_H := 18
const OPEN_X := 2;    const OPEN_Y := 23;   const OPEN_W := 78;    const OPEN_H := 14
const MONITOR_X := 66; const MONITOR_Y := 3; const MONITOR_W := 12; const MONITOR_H := 35
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
	var admin_spawns := [
		EntitySpawnDef.new("npc_staff", "ADMIN_STAFF", "admin_office", 12, 6, [
			Vector2(192, 96), Vector2(384, 96), Vector2(576, 96), Vector2(384, 96), Vector2(192, 96)
		]),
		EntitySpawnDef.new("robot_single", "OFFICE_ROBOT", "admin_office", 20, 12, [
			Vector2(320, 192), Vector2(544, 192), Vector2(544, 272), Vector2(320, 272), Vector2(320, 192)
		]),
	]
	_areas["admin_office"] = AreaDef.new("admin_office", "Admin Office", ["office_desk"], admin_spawns, {"x":ADMIN_X,"y":ADMIN_Y,"w":ADMIN_W,"h":ADMIN_H})

	var hr_spawns := [
		EntitySpawnDef.new("npc_staff", "HR_STAFF", "hr_department", 48, 6, [
			Vector2(768, 96), Vector2(960, 96), Vector2(1152, 96), Vector2(960, 96), Vector2(768, 96)
		]),
		EntitySpawnDef.new("npc_staff", "RECRUITER", "hr_department", 58, 12, [
			Vector2(928, 192), Vector2(1120, 192), Vector2(1120, 272), Vector2(928, 272), Vector2(928, 192)
		]),
	]
	_areas["hr_department"] = AreaDef.new("hr_department", "HR Department", ["office_desk"], hr_spawns, {"x":HR_X,"y":HR_Y,"w":HR_W,"h":HR_H})

	var open_spawns := [
		EntitySpawnDef.new("npc_staff", "OFFICE_WORKER", "open_office", 20, 26, [
			Vector2(320, 416), Vector2(640, 416), Vector2(960, 416), Vector2(640, 416), Vector2(320, 416)
		]),
		EntitySpawnDef.new("npc_staff", "OFFICE_WORKER", "open_office", 50, 28, [
			Vector2(800, 448), Vector2(1120, 448), Vector2(1120, 560), Vector2(800, 560), Vector2(800, 448)
		]),
		EntitySpawnDef.new("robot_single", "OFFICE_ROBOT", "open_office", 35, 30, [
			Vector2(560, 480), Vector2(800, 480), Vector2(800, 592), Vector2(560, 592), Vector2(560, 480)
		]),
	]
	_areas["open_office"] = AreaDef.new("open_office", "Open Office", ["office_desk"], open_spawns, {"x":OPEN_X,"y":OPEN_Y,"w":OPEN_W,"h":OPEN_H})

	var monitor_spawns := [
		EntitySpawnDef.new("npc_staff", "SECURITY_MONITOR", "monitoring_room", 70, 10, [
			Vector2(1120, 160), Vector2(1216, 160), Vector2(1216, 448), Vector2(1120, 448), Vector2(1120, 160)
		]),
		EntitySpawnDef.new("robot_humanoid", "SECURITY", "monitoring_room", 72, 20, [
			Vector2(1152, 320), Vector2(1280, 320), Vector2(1280, 448), Vector2(1152, 448), Vector2(1152, 320)
		]),
	]
	_areas["monitoring_room"] = AreaDef.new("monitoring_room", "Monitoring Room", ["monitor_room"], monitor_spawns, {"x":MONITOR_X,"y":MONITOR_Y,"w":MONITOR_W,"h":MONITOR_H})

	var transit_spawns := [
		EntitySpawnDef.new("robot_single", "SECURITY_ROBOT", "transit", 82, 15, [
			Vector2(1312, 240), Vector2(1440, 240), Vector2(1440, 560), Vector2(1312, 560), Vector2(1312, 240)
		]),
	]
	_areas["transit"] = AreaDef.new("transit", "Transit", ["elevator_shaft","stairs"], transit_spawns, {"x":TRANSIT_X,"y":TRANSIT_Y,"w":TRANSIT_W,"h":TRANSIT_H})

func _setup_facilities() -> void:
	_facilities = []

func _setup_places() -> void:
	_places = [
		Place.new("elevator", "Elevator", 80, 2, 4, 40),
		Place.new("stairs", "Stairs", 84, 2, 6, 40),
		Place.new("admin_office", "Admin Office", 2, 3, 38, 18),
		Place.new("hr_department", "HR Department", 42, 3, 36, 18),
		Place.new("open_office", "Open Office", 2, 23, 78, 14),
		Place.new("monitoring_room", "Monitoring Room", 66, 3, 12, 35),
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
func get_floor_7_summary() -> Dictionary:
	return {"area_count": _areas.size(), "entity_stats": get_entity_stats(), "facility_count": _facilities.size(), "place_count": _places.size(), "is_staff_only": true}
func get_debug_info() -> String:
	var info := "Floor 7 Configuration (Back Office)\n"
	info += "STAFF ONLY\n========================================================\n\n"
	info += "Areas: %d  Entities: %s  Facilities: %d  Places: %d\n\n" % [_areas.size(), str(get_entity_stats()), _facilities.size(), _places.size()]
	info += "=== AREAS ===\n"
	for area_id in _areas.keys():
		var area: AreaDef = _areas[area_id]
		info += "Area: %s (%s)  Bounds: x=%d y=%d w=%d h=%d\n" % [area.name, area.id, area.world_bounds.x, area.world_bounds.y, area.world_bounds.w, area.world_bounds.h]
		for spawn in area.spawns:
			var wp := get_spawn_world_pos(spawn)
			info += "  - %s/%s at tile(%d,%d) → world(%.0f,%.0f)%s\n" % [spawn.entity_type, spawn.role, spawn.x, spawn.y, wp.x, wp.y, "" if spawn.patrol_points.is_empty() else " (patrol)"]
	return info
