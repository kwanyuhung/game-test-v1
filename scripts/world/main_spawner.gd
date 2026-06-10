# All NPC/customer/robot spawning methods extracted from main.gd.
# Use setup(main, config) before calling any spawn methods.
extends Node

const ActorData = preload("res://scripts/entities/actor_data.gd")
const FloorManager = preload("res://scripts/world/floor_manager.gd")

var _main: Node2D = null
var _config: MainConfig = null
var _cell_size: int = 16
var _npc_count: int = 0
# Per-category spawn flags. Each test helper allows one spawn per category
# so the dev can test customers, staff, and robots independently without one
# of them blocking the others.
var _test_customer_spawned: bool = false
var _test_staff_spawned: bool = false
var _robot_spawned: bool = false

# Helper to get world Y position for a floor
func _get_floor_world_y(floor_idx: int) -> float:
	return FloorManager.get_floor_y(floor_idx)

func setup(main: Node2D, config: MainConfig) -> void:
	# 🔥 空值防护
	if main == null:
		print("致命错误：setup 传入的 main 节点为空！")
		return
	_main = main
	_config = config
	
	# CELL_SIZE 瓦片坐标转换
	var FloorConfig = preload("res://scripts/world/floor_config.gd")
	_cell_size = FloorConfig.CELL_SIZE
	
	if _config == null:
		print("警告：未传入 MainConfig 配置节点，NPC生成功能将受限")

func get_npc_count() -> int:
	return _npc_count

func set_npc_count(v: int) -> void:
	_npc_count = v

# ── Staff NPC ─────────────────────────────────────────────────────────────────
func spawn_npc_staff(role: int, floor_idx: int, pos: Vector2, patrol_points: Array = []) -> void:
	# 🔥 空值防护
	if _main == null: return
	var npc_scene = preload("res://scripts/entities/npc_controller.gd")
	var npc = npc_scene.new()
	var actor = ActorData.Actor.random_staff(role)
	actor.current_floor = floor_idx
	# Movement bounds: STANDBY anchors to spawn pos; FIXED_RANGE takes the
	# supplied patrol points. FREE leaves bounds.waypoints empty.
	_apply_movement_bounds(actor, pos, patrol_points)
	npc.configure(actor)
	npc.position = pos
	# Tell the NPC controller whether it should stay at its anchor. STANDBY
	# roles route to _start_stationary_work() in _choose_staff_behavior.
	npc._is_stationary = (actor.movement_bounds.mode == ActorData.MovementMode.STANDBY)
	npc.name = "Staff_%s_%d" % [actor.display_name.replace(" ", "_"), _npc_count]
	_main.add_child(npc)
	var npcs: Array = _main.get("_npcs")
	if npcs != null:
		npcs.append(npc)
	var chat_mgr = _main.get("_chat_manager")
	if chat_mgr != null:
		chat_mgr.register_npc(npc)
	_npc_count += 1
	print("    [Spawn] %s -> role=%d floor=%d world=(%.0f,%.0f) total_npcs=%d" % [npc.name, role, floor_idx, pos.x, pos.y, _npc_count])

# Populates the actor's movement_bounds based on its role's default mode
# plus the spawn-time data:
#   STANDBY     → anchor = pos (wherever this actor was placed)
#   FIXED_RANGE → waypoints = patrol_points (if provided) else [pos]
#   FREE        → unchanged
func _apply_movement_bounds(actor: ActorData.Actor, pos: Vector2, patrol_points: Array) -> void:
	var b: ActorData.MovementBounds = actor.movement_bounds
	match b.mode:
		ActorData.MovementMode.STANDBY:
			b.anchor = pos
		ActorData.MovementMode.FIXED_RANGE:
			if patrol_points.is_empty():
				# No waypoints supplied — fall back to a single anchor so the
				# actor still stays put, rather than roaming freely.
				b.waypoints = [pos]
			else:
				b.waypoints = patrol_points.duplicate()
		_:
			pass  # FREE — leave empty

# ── Single customer ───────────────────────────────────────────────────────────
func spawn_customer(group_type: int, floor_idx: int, pos: Vector2) -> void:
	# 🔥 空值防护
	if _main == null: return
	var npc_scene = preload("res://scripts/entities/npc_controller.gd")
	var npc = npc_scene.new()
	var actor = ActorData.Actor.random_customer(group_type)
	actor.current_floor = floor_idx
	npc.configure(actor)
	npc.position = pos
	npc.name = "Customer_%d" % _npc_count
	_main.add_child(npc)
	var npcs: Array = _main.get("_npcs")
	if npcs != null:
		npcs.append(npc)
	var chat_mgr = _main.get("_chat_manager")
	if chat_mgr != null:
		chat_mgr.register_npc(npc)
	_npc_count += 1
	print("    [Spawn] %s -> group=%d floor=%d world=(%.0f,%.0f) total_npcs=%d" % [npc.name, group_type, floor_idx, pos.x, pos.y, _npc_count])

# ── Customer group ─────────────────────────────────────────────────────────────
func spawn_customer_group(group_type: int, floor_idx: int, pos: Vector2) -> void:
	# 🔥 空值防护
	if _main == null: return
	var leader = null
	var offsets := []
	var has_baby := false
	var has_toddler := false
	var has_kids := false

	match group_type:
		ActorData.CustomerGroupType.FAMILY_BABY:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(10,-15)]
			has_baby = true
		ActorData.CustomerGroupType.FAMILY_TODDLER:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(10,-12)]
			has_toddler = true
		ActorData.CustomerGroupType.FAMILY_KIDS:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(10,-12), Vector2(30,-12)]
			has_kids = true
		ActorData.CustomerGroupType.FAMILY_EXTENDED:
			offsets = [Vector2(0,0), Vector2(22,0), Vector2(44,0), Vector2(11,-12), Vector2(33,-12), Vector2(-15,0)]
		ActorData.CustomerGroupType.COUPLE:
			offsets = [Vector2(0,0), Vector2(20,0)]
		ActorData.CustomerGroupType.PAIR:
			offsets = [Vector2(0,0), Vector2(20,0)]
		ActorData.CustomerGroupType.TWO_COUPLES:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(40,0), Vector2(60,0)]
		ActorData.CustomerGroupType.THREE_FRIENDS:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(40,0)]
		_:
			offsets = [Vector2(0,0)]

	for i in range(offsets.size()):
		var npc_scene = preload("res://scripts/entities/npc_controller.gd")
		var npc = npc_scene.new()
		var actor = ActorData.Actor.random_customer(group_type)
		actor.current_floor = floor_idx

		if i >= 2 and (has_baby or has_toddler or has_kids):
			actor.appearance.top.style = randi() % 2
			actor.appearance.bottom.style = randi() % 2
			actor.appearance.shoes_style = randi() % 2

		if has_baby and i == 2:
			actor.child = ActorData.ChildData.random_infant()
			actor.life_stage = ActorData.LifeStage.ADULT
		if has_toddler and i == 2:
			actor.child = ActorData.ChildData.random_toddler()
			actor.life_stage = ActorData.LifeStage.ADULT

		npc.configure(actor)
		npc.position = pos + offsets[i] * Vector2(1.0, 1.0)

		var member_name := "Group_%d_Member_%d" % [_npc_count, i]
		if i == 0:
			member_name = "GroupLeader_%d" % _npc_count
		npc.name = member_name
		_main.add_child(npc)
		var npcs: Array = _main.get("_npcs")
		if npcs != null:
			npcs.append(npc)
		var chat_mgr = _main.get("_chat_manager")
		if chat_mgr != null:
			chat_mgr.register_npc(npc)

		if i == 0:
			leader = npc
		elif leader != null:
			npc.set_group_leader(leader)
			var leader_actor: ActorData.Actor = leader.get_actor()
			# 🔥 直接使用（无需判断，属性已存在）
			leader_actor.group_members.append(npc)
		_npc_count += 1

# ── Random customer spawn across floor's available zones ─────────────────────
func spawn_random_customers_in_available_area(floor_idx: int, count: int) -> void:
	if _main == null: return
	var FloorConfig = preload("res://scripts/world/floor_config.gd")
	var fd = FloorConfig.get_floor(floor_idx)
	if fd == null or fd.zones.is_empty():
		return

	var floor_y: float = _get_floor_world_y(floor_idx)
	var player: Node2D = _main.get("_player")
	var player_pos: Vector2 = player.position if player != null else Vector2(-99999, -99999)
	var min_dist_sq: float = (3 * _cell_size) * (3 * _cell_size)

	var group_cycle := [
		ActorData.CustomerGroupType.SOLO,
		ActorData.CustomerGroupType.PAIR,
		ActorData.CustomerGroupType.COUPLE,
		ActorData.CustomerGroupType.FAMILY_BABY,
		ActorData.CustomerGroupType.FAMILY_TODDLER,
	]

	for i in range(count):
		var zone: Dictionary = fd.zones[randi() % fd.zones.size()]
		var zw: int = int(zone.get("w", 1))
		var zh: int = int(zone.get("h", 1))
		if zw <= 0 or zh <= 0:
			continue
		var zx: int = int(zone.get("x", 0))
		var zy: int = int(zone.get("y", 0))
		var attempts := 8
		var spawn_pos := Vector2.ZERO
		while attempts > 0:
			attempts -= 1
			var tile_x: int = zx + randi() % zw
			var tile_y: int = zy + randi() % zh
			spawn_pos = Vector2(tile_x * _cell_size, floor_y + tile_y * _cell_size)
			if spawn_pos.distance_squared_to(player_pos) >= min_dist_sq:
				break
		var gtype: int = group_cycle[i % group_cycle.size()]
		spawn_customer(gtype, floor_idx, spawn_pos)
		print("  [Customer] group=%d at world(%.0f,%.0f)" % [gtype, spawn_pos.x, spawn_pos.y])

# ── Full NPC build (staff + customers) ───────────────────────────────────────
func build_npcs() -> void:
	# 🔥 空值防护
	if _main == null || _config == null: return
	
	# Get current floor
	var current_floor: int = 0
	var fi_var = _main.get("_current_floor_idx")
	if fi_var != null:
		current_floor = int(fi_var)
	
	var staff_spawns: Dictionary = _config.get_staff_spawns()
	var staff_roles_arr: Array = _config.get_staff_roles()

	var role_map := {
		"CASHIER": ActorData.StaffRole.CASHIER,
		"SHELF_STOCKER": ActorData.StaffRole.SHELF_STOCKER,
		"CLEANER": ActorData.StaffRole.CLEANER,
		"SECURITY": ActorData.StaffRole.SECURITY,
		"GREETER": ActorData.StaffRole.GREETER,
		"MANAGER": ActorData.StaffRole.MANAGER,
		"FLOOR_STAFF": ActorData.StaffRole.FLOOR_STAFF,
		"SCAN_GO": ActorData.StaffRole.SCAN_GO,
		"SHOP_STAFF": ActorData.StaffRole.SHOP_STAFF,
		"FOOD_STAFF": ActorData.StaffRole.FOOD_STAFF,
		"CLEAN_STAFF": ActorData.StaffRole.CLEAN_STAFF,
		"RECEPTIONIST": ActorData.StaffRole.RECEPTIONIST,
		"MAINTENANCE_STAFF": ActorData.StaffRole.MAINTENANCE_STAFF,
		"DELIVERY_STAFF": ActorData.StaffRole.DELIVERY_STAFF,
		"CUSTOMER_SERVICE": ActorData.StaffRole.CUSTOMER_SERVICE,
	}

	# Role -> default floor. Used so a role's NPC lands on a sensible floor
	# rather than always F0..F4 in round-robin. Falls back to current_floor.
	var role_default_floor := {
		ActorData.StaffRole.CASHIER: 0,
		ActorData.StaffRole.SHELF_STOCKER: 0,
		ActorData.StaffRole.CLEANER: 0,
		ActorData.StaffRole.SECURITY: 0,
		ActorData.StaffRole.GREETER: 0,
		ActorData.StaffRole.MANAGER: 9,
		ActorData.StaffRole.FLOOR_STAFF: 1,
		ActorData.StaffRole.SCAN_GO: 0,
		ActorData.StaffRole.SHOP_STAFF: 1,
		ActorData.StaffRole.FOOD_STAFF: 0,
		ActorData.StaffRole.CLEAN_STAFF: 6,
		ActorData.StaffRole.RECEPTIONIST: 0,
		ActorData.StaffRole.MAINTENANCE_STAFF: 14,
		ActorData.StaffRole.DELIVERY_STAFF: 11,
		ActorData.StaffRole.CUSTOMER_SERVICE: 0,
	}

	# Spawn staff only for current floor
	for role_name in staff_roles_arr:
		var role = role_map.get(role_name, ActorData.StaffRole.CASHIER)
		var count := 2 if role == ActorData.StaffRole.SHELF_STOCKER else 1
		for c in range(count):
			var floor_idx: int = role_default_floor.get(role, current_floor)
			# Only spawn if floor matches current floor
			if floor_idx != current_floor:
				continue
			var spawns = staff_spawns.get(str(floor_idx), {"x": [30], "y": [10]})
			# Pick a random spawn point on this floor to avoid overlap clustering
			var pick := randi() % int(spawns["x"].size())
			var sx: float = float(spawns["x"][pick]) * float(_cell_size)
			var rel_y: int = int(spawns["y"][pick])
			var sy: float = _get_floor_world_y(floor_idx) + float(rel_y) * float(_cell_size)
			spawn_npc_staff(role, floor_idx, Vector2(sx, sy))

	var customer_spawns: Array = _config.get_customer_spawns()
	var group_type_map := {
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

	for spawn_data in customer_spawns:
		var gtype_str = spawn_data.get("type", "SOLO")
		var gtype = group_type_map.get(gtype_str, ActorData.CustomerGroupType.SOLO)

		# Check if this spawn is for the current floor
		var spawn_floor: int = int(spawn_data.get("floor", 0))
		var has_count: bool = spawn_data.has("count")
		var floor_range: Array = spawn_data.get("floor_range", [0, 4])
		
		# Check if this spawn config matches current floor
		var spawns_on_current_floor := false
		if has_count:
			var fmin := int(floor_range[0])
			var fmax := int(floor_range[1])
			spawns_on_current_floor = (current_floor >= fmin and current_floor <= fmax)
		else:
			spawns_on_current_floor = (spawn_floor == current_floor)
		
		if not spawns_on_current_floor:
			continue

		if spawn_data.has("count"):
			var count: int = spawn_data.get("count", 1)
			var x_range = spawn_data.get("x_range", [100, 500])
			var y_range = spawn_data.get("y_range", [100, 400])
			# 🔥 已删除重复的 var floor_range 定义
			for i in range(count):
				var floor_i: int
				if floor_range.size() >= 2:
					# 🔥 核心修复：强制转为整数，楼层不可能是小数
					var floor_min = int(floor_range[0])
					var floor_max = int(floor_range[1])
					floor_i = floor_min + (i % (floor_max - floor_min + 1))
				else:
					floor_i = int(floor_range[0])
				# 🔥 同步修复坐标的类型问题（完整兼容）
				var x_diff = int(x_range[1] - x_range[0])
				var y_diff = int(y_range[1] - y_range[0])
				var px = float(x_range[0] + randi() % x_diff)
				var py = float(y_range[0] + randi() % y_diff)
				spawn_customer(gtype, floor_i, Vector2(px, py))
		else:
			var floor_idx: int = int(spawn_data.get("floor", 0))
			var px: float = spawn_data.get("x", 300)
			var py: float = spawn_data.get("y", 200)
			spawn_customer_group(gtype, floor_idx, Vector2(px, py))
			
# ── Humanoid robot ───────────────────────────────────────────────────────────
func spawn_robot_humanoid(staff_role: ActorData.StaffRole, patrol_points: Array = [], floor_idx: int = 0) -> void:
	# 🔥 空值防护
	if _main == null: return
	var spawn_pos := Vector2.ZERO
	match staff_role:
		ActorData.StaffRole.CASHIER:    spawn_pos = Vector2(580, 320)
		ActorData.StaffRole.GREETER:     spawn_pos = Vector2(250, 120)
		ActorData.StaffRole.CLEANER:     spawn_pos = Vector2(400, 400)
		ActorData.StaffRole.SHELF_STOCKER: spawn_pos = Vector2(200, 300)
		ActorData.StaffRole.SECURITY:   spawn_pos = Vector2(100, 200)
		ActorData.StaffRole.FLOOR_STAFF: spawn_pos = Vector2(400, 250)
		ActorData.StaffRole.SCAN_GO:     spawn_pos = Vector2(350, 200)
		ActorData.StaffRole.MANAGER:     spawn_pos = Vector2(500, 300)

	var robot := preload("res://scripts/entities/robot_controller.gd").new()
	robot.configure_humanoid(staff_role, spawn_pos, patrol_points, floor_idx)
	robot.name = "Robot_Humanoid_%s" % _assigned_role_name(staff_role)
	_main.add_child(robot)
	var robots: Array = _main.get("_robots")
	if robots != null:
		robots.append(robot)
	print("    [Spawn] %s -> humanoid staff_role=%d spawn_default=(%.0f,%.0f) patrol_pts=%d" % [robot.name, staff_role, spawn_pos.x, spawn_pos.y, patrol_points.size()])

# ── Single-function robot ──────────────────────────────────────────────────────
func spawn_robot_single(rrole: ActorData.RobotRole, patrol_points: Array = [], floor_idx: int = 0) -> void:
	# 🔥 空值防护
	if _main == null: return
	var spawn_pos := Vector2.ZERO
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT:  spawn_pos = Vector2(400, 400)
		ActorData.RobotRole.GUIDANCE_ROBOT: spawn_pos = Vector2(300, 100)
		ActorData.RobotRole.SECURITY_ROBOT:  spawn_pos = Vector2(100, 200)
		ActorData.RobotRole.DELIVERY_ROBOT:  spawn_pos = Vector2(40 * _cell_size, 20 * _cell_size)
		ActorData.RobotRole.SHELF_ROBOT:     spawn_pos = Vector2(200, 300)

	var robot := preload("res://scripts/entities/robot_controller.gd").new()
	robot.configure_single_function(rrole, spawn_pos, patrol_points, floor_idx)
	# Include unique ID in name to prevent duplicates
	robot.name = "Robot_Single_%s_%d" % [_assigned_robot_role_name(rrole), _npc_count]
	_main.add_child(robot)
	var robots: Array = _main.get("_robots")
	if robots != null:
		robots.append(robot)
	_npc_count += 1
	print("    [Spawn] %s -> single robot_role=%d spawn_default=(%.0f,%.0f) patrol_pts=%d" % [robot.name, rrole, spawn_pos.x, spawn_pos.y, patrol_points.size()])

# ── Default robot batch ───────────────────────────────────────────────────────
func spawn_robots() -> void:
	if _config == null:
		print("警告：配置节点未初始化，跳过机器人生成")
		return
	
	# Get current floor
	var current_floor: int = 0
	var fi_var = _main.get("_current_floor_idx")
	if fi_var != null:
		current_floor = int(fi_var)
	
	var humanoid_roles: Array = []
	var single_roles: Array = []
	
	if _config.has_method("get_robot_humanoid_roles"):
		humanoid_roles = _config.get_robot_humanoid_roles()
	if _config.has_method("get_robot_single_roles"):
		single_roles = _config.get_robot_single_roles()
	
	var humanoid_map := {
		"GREETER": ActorData.StaffRole.GREETER,
		"CLEANER": ActorData.StaffRole.CLEANER,
	}
	var single_map := {
		"CLEANING_ROBOT": ActorData.RobotRole.CLEANING_ROBOT,
		"GUIDANCE_ROBOT": ActorData.RobotRole.GUIDANCE_ROBOT,
	}
	
	# Spawn robots only on appropriate floors (ground floor for most)
	for rname in humanoid_roles:
		var r = humanoid_map.get(rname, ActorData.StaffRole.GREETER)
		# Only spawn on ground floor for now
		if current_floor == 0:
			spawn_robot_humanoid(r)
	
	for rname in single_roles:
		var r = single_map.get(rname, ActorData.RobotRole.CLEANING_ROBOT)
		# Only spawn on ground floor for now
		if current_floor == 0:
			spawn_robot_single(r)

# ── Robot role name helpers ───────────────────────────────────────────────────
func _assigned_role_name(role: ActorData.StaffRole) -> String:
	match role:
		ActorData.StaffRole.CASHIER: return "Cashier"
		ActorData.StaffRole.SHELF_STOCKER: return "Stocker"
		ActorData.StaffRole.CLEANER: return "Cleaner"
		ActorData.StaffRole.SECURITY: return "Security"
		ActorData.StaffRole.GREETER: return "Greeter"
		ActorData.StaffRole.MANAGER: return "Manager"
		ActorData.StaffRole.FLOOR_STAFF: return "FloorStaff"
		ActorData.StaffRole.SCAN_GO: return "ScanGo"
		ActorData.StaffRole.SHOP_STAFF: return "ShopStaff"
		ActorData.StaffRole.FOOD_STAFF: return "FoodStaff"
		ActorData.StaffRole.CLEAN_STAFF: return "CleanStaff"
		ActorData.StaffRole.RECEPTIONIST: return "Receptionist"
		ActorData.StaffRole.MAINTENANCE_STAFF: return "Maintenance"
		ActorData.StaffRole.DELIVERY_STAFF: return "Delivery"
		ActorData.StaffRole.CUSTOMER_SERVICE: return "CustomerService"
	return "Unknown"

func _assigned_robot_role_name(rrole: ActorData.RobotRole) -> String:
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT: return "Cleaner"
		ActorData.RobotRole.GUIDANCE_ROBOT: return "Guide"
		ActorData.RobotRole.DELIVERY_ROBOT: return "Delivery"
		ActorData.RobotRole.SECURITY_ROBOT: return "Security"
		ActorData.RobotRole.SHELF_ROBOT: return "Shelf"
	return "Unknown"

# ── Scan & Go companion ───────────────────────────────────────────────────────
func spawn_scan_go_companion() -> void:
	if _main == null: return
	var player: Node2D = _main.get("_player")
	if player == null:
		return
	var spawn_pos := player.position + Vector2(40, 0)

	# Build a fully-formed actor via the standard factory so the appearance
	# is randomized the same way as other staff. random_staff already sets
	# SCAN_GO uniform colors (see actor_data.gd).
	var actor := ActorData.Actor.random_staff(ActorData.StaffRole.SCAN_GO)
	actor.life_stage = ActorData.LifeStage.ADULT
	var floor_idx: int = int(_main.get("_current_floor_idx"))
	actor.current_floor = floor_idx

	var npc := preload("res://scripts/entities/npc_controller.gd").new()
	# configure() must run before the override below so the sprite, label,
	# collision, and bounds are set up. Then jump straight into the
	# companion state and bind to the player.
	npc.configure(actor)
	npc._player_reference = player
	npc._state = NPCController.BehaviorState.SCAN_GO_COMPANION
	npc.position = spawn_pos
	npc.name = "ScanGoCompanion"
	_main.add_child(npc)
	var npcs: Array = _main.get("_npcs")
	if npcs != null and npcs is Array:
		npcs.append(npc)
	var chat_mgr = _main.get("_chat_manager")
	if chat_mgr != null:
		chat_mgr.register_npc(npc)

func remove_scan_go_companion() -> void:
	if _main == null: return
	var sg = _main.get_node_or_null("ScanGoCompanion")
	if sg != null:
		sg.queue_free()

func spawn_player() -> void:
	# 🔥 空值防护
	if _main == null: return
	var player: Node2D = preload("res://scripts/entities/player.gd").new()
	# Spawn at the supermarket entry corridor (tile 250, 10) — just below the entry gate
	# and inside the "Supermarket Floor" moveable area, in the corridor between the
	# trolley band (y=2-8) and the service row (y=12-40).
	var floor_y: float = _get_floor_world_y(0)  # Floor 0 world Y
	player.position = Vector2(250 * _cell_size, floor_y + 10 * _cell_size)
	_main.add_child(player)
	player.set_world(_main)
	player.cart_updated.connect(_main._logic._on_cart_updated)
	player.interact_requested.connect(_main._on_player_interact)
	player.cart_dropped.connect(_main._logic._on_cart_dropped)
	player.cart_grabbed.connect(_main._logic._on_cart_grabbed)
	#player.tab_pressed.connect(_main._on_tab_pressed)
	_main.set("_player", player)

# ── Test helpers ───────────────────────────────────────────────────────────────
func spawn_test_customers(count: int) -> void:
	if _main == null: return
	# Each test helper allows one spawn per category so a customer test
	# does not block a staff test, and vice versa.
	if _test_customer_spawned:
		print("[MainSpawner] Test customer already spawned, skipping")
		return
	_test_customer_spawned = true
	# Spawn just 1 NPC for testing
	var npc: Node = preload("res://scripts/entities/npc_controller.gd").new()
	npc.position = Vector2(300.0 + randf_range(-50, 50), 500.0 + randf_range(-30, 30))
	_main.add_child(npc)
	npc.configure(ActorData.Actor.new_test_customer())
	var npcs: Array = _main.get("_npcs")
	if npcs != null:
		npcs.append(npc)
	var chat_mgr = _main.get("_chat_manager")
	if chat_mgr != null:
		chat_mgr.register_npc(npc)

func spawn_test_staff(count: int) -> void:
	if _main == null: return
	if _test_staff_spawned:
		print("[MainSpawner] Test staff already spawned, skipping")
		return
	_test_staff_spawned = true
	# Spawn just 1 NPC for testing
	var npc: Node = preload("res://scripts/entities/npc_controller.gd").new()
	npc.position = Vector2(350.0 + randf_range(-50, 50), 300.0 + randf_range(-30, 30))
	_main.add_child(npc)
	npc.configure(ActorData.Actor.new_test_staff())
	var npcs: Array = _main.get("_npcs")
	if npcs != null:
		npcs.append(npc)
	var chat_mgr = _main.get("_chat_manager")
	if chat_mgr != null:
		chat_mgr.register_npc(npc)

# ── Truck at dock ─────────────────────────────────────────────────────────────
func spawn_truck_at_dock() -> void:
	if _main == null: return
	_main.set("_truck_arrived", true)
	var truck_dock_node: Node2D = _main.get("_truck_dock_node")
	
	# 🔥 双重加固：确保卡车节点父节点非空
	if truck_dock_node == null:
		truck_dock_node = Node2D.new()
		truck_dock_node.name = "TruckDock"
		_main.add_child(truck_dock_node)
		_main.set("_truck_dock_node", truck_dock_node)
	else:
		for ch in truck_dock_node.get_children():
			ch.queue_free()
			
	var CELL = 16
	var cargo := ColorRect.new()
	cargo.color = Color(0.50, 0.55, 0.60)
	cargo.size = Vector2(22 * CELL, 10 * CELL)
	cargo.position = Vector2(0, 35 * CELL)
	truck_dock_node.add_child(cargo)

	var cab := ColorRect.new()
	cab.color = Color(0.45, 0.42, 0.40)
	cab.size = Vector2(8 * CELL, 8 * CELL)
	cab.position = Vector2(22 * CELL, 37 * CELL)
	truck_dock_node.add_child(cab)

	var wheel_positions := [Vector2(2, 45), Vector2(10, 45), Vector2(22, 45), Vector2(28, 45)]
	for wp in wheel_positions:
		var wheel := ColorRect.new()
		wheel.color = Color(0.15, 0.15, 0.15)
		wheel.size = Vector2(5 * CELL, 2 * CELL)
		wheel.position = wp * CELL
		truck_dock_node.add_child(wheel)

	var store_lbl := Label.new()
	store_lbl.text = "PIXEL MART"
	store_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	store_lbl.add_theme_font_size_override("font_size", 10)
	store_lbl.position = Vector2(2 * CELL, 35.5 * CELL)
	truck_dock_node.add_child(store_lbl)

	var dock_lbl := Label.new()
	dock_lbl.text = "[E] Unload Truck"
	dock_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	dock_lbl.add_theme_font_size_override("font_size", 8)
	dock_lbl.position = Vector2(0, 44 * CELL)
	truck_dock_node.add_child(dock_lbl)

# ── Spawn limit helpers ────────────────────────────────────────────────────────
# Reset test-customer spawn flag (allows spawning 1 test customer again)
func reset_npc_spawn() -> void:
	_test_customer_spawned = false
	_test_staff_spawned = false
	print("[MainSpawner] Test NPC spawn limits reset")

# Reset robot spawn flag (allows spawning 1 robot again)
func reset_robot_spawn() -> void:
	_robot_spawned = false
	print("[MainSpawner] Robot spawn limit reset")

# Reset all test spawn flags
func reset_all_spawns() -> void:
	_test_customer_spawned = false
	_test_staff_spawned = false
	_robot_spawned = false
	print("[MainSpawner] All spawn limits reset")

# Check if a test NPC has been spawned
func has_npc_spawned() -> bool:
	return _test_customer_spawned or _test_staff_spawned

# Check if a robot has been spawned
func has_robot_spawned() -> bool:
	return _robot_spawned
