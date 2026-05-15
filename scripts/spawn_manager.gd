# spawn_manager.gd
# High-level spawn coordinator that uses SpawnConfig + MainSpawner
# Handles spawn limits, floor filtering, and weighted random selection
extends Node

const ActorData = preload("res://scripts/actor_data.gd")

var _spawn_config: SpawnConfig = null
var _main_spawner: Node = null
var _main: Node2D = null
var _current_floor: int = 0
var _npc_count: int = 0
var _robot_count: int = 0

const _staff_role_map := {
	"CASHIER": ActorData.StaffRole.CASHIER,
	"SHELF_STOCKER": ActorData.StaffRole.SHELF_STOCKER,
	"CLEANER": ActorData.StaffRole.CLEANER,
	"SECURITY": ActorData.StaffRole.SECURITY,
	"GREETER": ActorData.StaffRole.GREETER,
	"MANAGER": ActorData.StaffRole.MANAGER,
	"FLOOR_STAFF": ActorData.StaffRole.FLOOR_STAFF,
}

const _customer_group_map := {
	"FAMILY_BABY": ActorData.CustomerGroupType.FAMILY_BABY,
	"FAMILY_TODDLER": ActorData.CustomerGroupType.FAMILY_TODDLER,
	"FAMILY_KIDS": ActorData.CustomerGroupType.FAMILY_KIDS,
	"FAMILY_EXTENDED": ActorData.CustomerGroupType.FAMILY_EXTENDED,
	"COUPLE": ActorData.CustomerGroupType.COUPLE,
	"PAIR": ActorData.CustomerGroupType.PAIR,
	"TWO_COUPLES": ActorData.CustomerGroupType.TWO_COUPLES,
	"THREE_FRIENDS": ActorData.CustomerGroupType.THREE_FRIENDS,
	"SOLO": ActorData.CustomerGroupType.SOLO,
}

const _humanoid_map := {
	"GREETER": ActorData.StaffRole.GREETER,
	"CLEANER": ActorData.StaffRole.CLEANER,
}

const _single_map := {
	"CLEANING_ROBOT": ActorData.RobotRole.CLEANING_ROBOT,
	"GUIDANCE_ROBOT": ActorData.RobotRole.GUIDANCE_ROBOT,
	"SECURITY_ROBOT": ActorData.RobotRole.SECURITY_ROBOT,
	"DELIVERY_ROBOT": ActorData.RobotRole.DELIVERY_ROBOT,
	"SHELF_ROBOT": ActorData.RobotRole.SHELF_ROBOT,
}

func setup(spawn_config: SpawnConfig, main_spawner: Node, main: Node2D) -> void:
	_spawn_config = spawn_config
	_main_spawner = main_spawner
	_main = main

func set_current_floor(floor_idx: int) -> void:
	_current_floor = floor_idx

# ── Build All ─────────────────────────────────────────────────────────────────
func build_all() -> void:
	if _spawn_config == null or not _spawn_config.is_spawning_enabled():
		print("[SpawnManager] Spawning disabled or config missing")
		return
	
	_npc_count = 0
	_robot_count = 0
	
	_build_staff()
	_build_customers()
	_build_robots()
	
	print("[SpawnManager] Complete: %d NPCs, %d robots" % [_npc_count, _robot_count])

func _build_staff() -> void:
	if not _spawn_config.is_staff_enabled():
		return
	
	var roles = _spawn_config.get_all_staff_roles()
	var floor_limit = _spawn_config.get_floor_staff_limit(_current_floor)
	var spawned = 0
	
	for role_data in roles:
		if spawned >= floor_limit:
			break
		var name: String = role_data.get("name", "")
		var floors: Array = role_data.get("floors", [])
		if not _current_floor in floors:
			continue
		
		var count: int = role_data.get("count", 1)
		var role_enum = _staff_role_map.get(name, ActorData.StaffRole.CASHIER)
		
		for i in range(count):
			var spawn_pos := _get_staff_spawn_pos(name, i)
			_main_spawner.spawn_npc_staff(role_enum, _current_floor, spawn_pos)
			_npc_count += 1
			spawned += 1
			print("[SpawnManager] Staff: %s #%d on floor %d at %s" % [name, i, _current_floor, spawn_pos])

func _build_customers() -> void:
	if not _spawn_config.is_customers_enabled():
		return
	
	var groups = _spawn_config.get_all_customer_groups()
	var total_limit = _spawn_config.get_customer_global_max()
	var floor_limit = _spawn_config.get_floor_customer_limit(_current_floor)
	var spawned = 0
	
	# Build weighted list
	var weighted: Array = []
	for g in groups:
		var gname: String = g.get("name", "")
		var weight: int = g.get("weight", 10)
		var floors: Array = g.get("floors", [])
		var count: int = g.get("count", 1)
		
		var valid = _spawn_config.spawn_customers_on_all_floors() or (_current_floor in floors)
		if valid:
			for i in range(count):
				weighted.append({"name": gname, "weight": weight})
	
	weighted.shuffle()
	
	var pos_range := _spawn_config.get_position_range(_current_floor)
	var x_range: Array = pos_range.get("x", [100, 500])
	var y_range: Array = pos_range.get("y", [100, 400])
	
	for entry in weighted:
		if _npc_count >= total_limit:
			break
		if spawned >= floor_limit:
			break
		
		var gname: String = entry.get("name")
		var genum = _customer_group_map.get(gname, ActorData.CustomerGroupType.SOLO)
		var spawn_pos := Vector2(
			x_range[0] + randi() % (x_range[1] - x_range[0]),
			y_range[0] + randi() % (y_range[1] - y_range[0])
		)
		
		_main_spawner.spawn_customer_group(genum, _current_floor, spawn_pos)
		_npc_count += 1
		spawned += 1
		print("[SpawnManager] Customer: %s on floor %d at %s" % [gname, _current_floor, spawn_pos])

func _build_robots() -> void:
	if not _spawn_config.is_robots_enabled():
		return
	
	if _spawn_config.robots_on_floor_0_only() and _current_floor != 0:
		return
	
	# Humanoids
	for h in _spawn_config.get_all_humanoids():
		var hname: String = h.get("name", "")
		var count: int = h.get("count", 0)
		var pos: Vector2 = _spawn_config.get_humanoid_pos(hname)
		var role_enum = _humanoid_map.get(hname, ActorData.StaffRole.GREETER)
		
		for i in range(count):
			_main_spawner.spawn_robot_humanoid(role_enum)
			_robot_count += 1
			print("[SpawnManager] Robot: humanoid %s #%d at %s" % [hname, i, pos])
	
	# Singles
	for s in _spawn_config.get_all_singles():
		var sname: String = s.get("name", "")
		var count: int = s.get("count", 0)
		var pos: Vector2 = _spawn_config.get_single_pos(sname)
		var role_enum = _single_map.get(sname, ActorData.RobotRole.CLEANING_ROBOT)
		
		for i in range(count):
			_main_spawner.spawn_robot_single(role_enum)
			_robot_count += 1
			print("[SpawnManager] Robot: single %s #%d at %s" % [sname, i, pos])

func _get_staff_spawn_pos(role_name: String, index: int) -> Vector2:
	var defaults := {
		"CASHIER": Vector2(580, 320),
		"GREETER": Vector2(250, 120),
		"CLEANER": Vector2(400, 400),
		"SHELF_STOCKER": Vector2(200, 300),
		"SECURITY": Vector2(100, 200),
		"FLOOR_STAFF": Vector2(400, 250),
		"MANAGER": Vector2(500, 300),
	}
	var base = defaults.get(role_name, Vector2(300, 300))
	return base + Vector2(index * 30, 0)

# ── Single Spawn ───────────────────────────────────────────────────────────────
func spawn_single_npc(type: String = "staff") -> void:
	match type:
		"staff":   _main_spawner.spawn_test_staff(1)
		"customer": _main_spawner.spawn_test_customers(1)
		"scan_go":  _main_spawner.spawn_scan_go_companion()

# ── Stats ─────────────────────────────────────────────────────────────────────
func get_npc_count() -> int:
	return _npc_count

func get_robot_count() -> int:
	return _robot_count

func get_summary() -> String:
	return _spawn_config.get_full_summary() if _spawn_config else "SpawnConfig not initialized"
