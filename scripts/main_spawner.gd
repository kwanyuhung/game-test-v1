# main_spawner.gd
# All NPC/customer/robot spawning methods extracted from main.gd.
# Use setup(main, config) before calling any spawn methods.
extends Node

const ActorData = preload("res://scripts/actor_data.gd") 

var _main: Node2D = null
var _config: Node = null
var _cell_size: int = 16
var _npc_count: int = 0

func setup(main: Node2D, config: Node) -> void:
	_main = main
	_config = config
	# CELL_SIZE is needed for tile→world conversion
	var FloorConfig = preload("res://scripts/floor_config.gd")
	_cell_size = FloorConfig.CELL_SIZE

func get_npc_count() -> int:
	return _npc_count

func set_npc_count(v: int) -> void:
	_npc_count = v

# ── Staff NPC ─────────────────────────────────────────────────────────────────

func spawn_npc_staff(role: int, floor_idx: int, pos: Vector2) -> void:
	var npc_scene = preload("res://scripts/npc_controller.gd")
	var npc = npc_scene.new()
	var actor = ActorData.Actor.random_staff(role)
	actor.current_floor = floor_idx
	npc.configure(actor)
	npc.position = pos
	npc.name = "Staff_%s_%d" % [actor.display_name.replace(" ", "_"), _npc_count]
	_main.add_child(npc)
	var npcs: Array = _main.get("_npcs")
	if npcs != null:
		npcs.append(npc)
	var chat_mgr = _main.get("_chat_manager")
	if chat_mgr != null:
		chat_mgr.register_npc(npc)
	_npc_count += 1

# ── Single customer ───────────────────────────────────────────────────────────

func spawn_customer(group_type: int, floor_idx: int, pos: Vector2) -> void:
	var npc_scene = preload("res://scripts/npc_controller.gd")
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

# ── Customer group ─────────────────────────────────────────────────────────────

func spawn_customer_group(group_type: int, floor_idx: int, pos: Vector2) -> void:
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
		var npc_scene = preload("res://scripts/npc_controller.gd")
		var npc = npc_scene.new()
		var actor = ActorData.Actor.random_customer(group_type)
		actor.current_floor = floor_idx

		# Children get child appearance
		if i >= 2 and (has_baby or has_toddler or has_kids):
			actor.appearance.top_style = randi() % 2
			actor.appearance.bottom_style = randi() % 2
			actor.appearance.shoes_style = randi() % 2

		# Baby/toddler data
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

		if i == 0:
			leader = npc
		elif leader != null: 
			npc.set_group_leader(leader)
			var leader_actor: ActorData.Actor = leader.get_actor()
			leader_actor.group_members.append(npc)
		_npc_count += 1

# ── Full NPC build (staff + customers) ───────────────────────────────────────

func build_npcs() -> void:
	var staff_spawns: Dictionary = _config.get_staff_spawns()
	var staff_roles_arr: Array = _config.get_staff_roles()

	# Map string role names to ActorData.StaffRole enum values
	var role_map := {
		"CASHIER": ActorData.StaffRole.CASHIER,
		"SHELF_STOCKER": ActorData.StaffRole.SHELF_STOCKER,
		"CLEANER": ActorData.StaffRole.CLEANER,
		"SECURITY": ActorData.StaffRole.SECURITY,
		"GREETER": ActorData.StaffRole.GREETER,
		"MANAGER": ActorData.StaffRole.MANAGER,
		"FLOOR_STAFF": ActorData.StaffRole.FLOOR_STAFF,
	}

	for role_name in staff_roles_arr:
		var role = role_map.get(role_name, ActorData.StaffRole.CASHIER)
		var count := 2 if role == ActorData.StaffRole.SHELF_STOCKER else 1
		for c in range(count):
			var floor_idx := c % 5
			var spawns = staff_spawns.get(str(floor_idx), {"x": [30], "y": [10]})
			var sx = spawns["x"][c % spawns["x"].size()] * _cell_size
			var sy = spawns["y"][c % spawns["y"].size()] * _cell_size
			spawn_npc_staff(role, floor_idx, Vector2(sx, sy))

	# Customers from config
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

		if spawn_data.has("count"):
			# Random-position batch spawn
			var count: int = spawn_data.get("count", 1)
			var x_range = spawn_data.get("x_range", [100, 500])
			var y_range = spawn_data.get("y_range", [100, 400])
			var floor_range = spawn_data.get("floor_range", [0, 4])
			for i in range(count):
				var floor_i: int
				if floor_range.size() >= 2:
					floor_i = floor_range[0] + (i % (floor_range[1] - floor_range[0] + 1))
				else:
					floor_i = floor_range[0]
				var px = (x_range[0] + randi() % (x_range[1] - x_range[0])) as float
				var py = (y_range[0] + randi() % (y_range[1] - y_range[0])) as float
				spawn_customer(gtype, floor_i, Vector2(px, py))
		else:
			# Fixed position spawn
			var floor_idx: int = spawn_data.get("floor", 0)
			var px: float = spawn_data.get("x", 300)
			var py: float = spawn_data.get("y", 200)
			spawn_customer_group(gtype, floor_idx, Vector2(px, py))

# ── Humanoid robot ───────────────────────────────────────────────────────────

func spawn_robot_humanoid(staff_role: ActorData.StaffRole) -> void:
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

	var robot := preload("res://scripts/robot_controller.gd").new()
	robot.configure_humanoid(staff_role, spawn_pos)
	_main.add_child(robot)
	var robots: Array = _main.get("_robots")
	if robots != null:
		robots.append(robot)

# ── Single-function robot ──────────────────────────────────────────────────────

func spawn_robot_single(rrole: ActorData.RobotRole) -> void:
	var spawn_pos := Vector2.ZERO
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT:  spawn_pos = Vector2(400, 400)
		ActorData.RobotRole.GUIDANCE_ROBOT: spawn_pos = Vector2(300, 100)
		ActorData.RobotRole.SECURITY_ROBOT:  spawn_pos = Vector2(100, 200)
		ActorData.RobotRole.DELIVERY_ROBOT:  spawn_pos = Vector2(40 * _cell_size, 20 * _cell_size)
		ActorData.RobotRole.SHELF_ROBOT:     spawn_pos = Vector2(200, 300)

	var robot := preload("res://scripts/robot_controller.gd").new()
	robot.configure_single_function(rrole, spawn_pos)
	_main.add_child(robot)
	var robots: Array = _main.get("_robots")
	if robots != null:
		robots.append(robot)

# ── Default robot batch ───────────────────────────────────────────────────────

func spawn_robots() -> void:
	var humanoid_roles: Array = _config.get_robot_humanoid_roles()
	var single_roles: Array = _config.get_robot_single_roles()
	var humanoid_map := {
		"GREETER": ActorData.StaffRole.GREETER,
		"CLEANER": ActorData.StaffRole.CLEANER,
	}
	var single_map := {
		"CLEANING_ROBOT": ActorData.RobotRole.CLEANING_ROBOT,
		"GUIDANCE_ROBOT": ActorData.RobotRole.GUIDANCE_ROBOT,
	}
	for rname in humanoid_roles:
		var r = humanoid_map.get(rname, ActorData.StaffRole.GREETER)
		spawn_robot_humanoid(r)
	for rname in single_roles:
		var r = single_map.get(rname, ActorData.RobotRole.CLEANING_ROBOT)
		spawn_robot_single(r)

# ── Scan & Go companion ───────────────────────────────────────────────────────

func spawn_scan_go_companion() -> void:
	var player: Node2D = _main.get("_player")
	if player == null:
		return
	var spawn_pos := player.position + Vector2(40, 0)
	var actor := ActorData.Actor.new()
	actor.role = ActorData.Role.STAFF
	actor.staff_role = ActorData.StaffRole.SCAN_GO
	actor.life_stage = ActorData.LifeStage.ADULT
	var floor_idx: int = _main.get("_current_floor_idx")
	actor.current_floor = floor_idx
	actor.position = spawn_pos
	actor.speed = ActorData.SPEED_ADULT
	var app := ActorData.Appearance.new()
	app.skin_tone = ActorData.SKINS[randi() % ActorData.SKINS.size()]
	app.top_color = Color(0.20, 0.50, 0.80)
	app.bottom_color = Color(0.15, 0.15, 0.30)
	app.hair_color = ActorData.HAIR_COLORS[randi() % ActorData.HAIR_COLORS.size()]
	actor.appearance = app
	var npc := preload("res://scripts/npc_controller.gd").new()
	npc._player_reference = player
	npc.position = spawn_pos
	npc._state = preload("res://scripts/npc_controller.gd").BehaviorState.SCAN_GO_COMPANION
	npc.name = "ScanGoCompanion"
	_main.add_child(npc)
	var npcs: Array = _main.get("_npcs")
	if npcs != null and npcs is Array:
		npcs.append(npc)

func remove_scan_go_companion() -> void:
	var sg = _main.get_node_or_null("ScanGoCompanion")
	if sg != null:
		sg.queue_free()

func spawn_player() -> void:
	var player: Node2D = preload("res://scripts/player.gd").new()
	player.position = Vector2(12 * 16, 4 * 16)  # 12*CELL_SIZE, 4*CELL_SIZE
	_main.add_child(player)
	player.set_world(_main)
	player.cart_updated.connect(_main._on_cart_updated)
	player.interact_requested.connect(_main._on_player_interact)
	player.tab_pressed.connect(_main._on_tab_pressed)
	_main.set("_player", player)

# ── Test helpers ───────────────────────────────────────────────────────────────

func spawn_test_customers(count: int) -> void:
	for i in range(count):
		var npc: Node = preload("res://scripts/npc_controller.gd").new()
		npc.position = Vector2(300.0 + randf_range(-50, 50), 500.0 + randf_range(-30, 30))
		_main.add_child(npc)
		npc.configure(ActorData.new_test_customer())
		var npcs: Array = _main.get("_npcs")
		if npcs != null:
			npcs.append(npc)
		var chat_mgr = _main.get("_chat_manager")
		if chat_mgr != null:
			chat_mgr.register_npc(npc)

func spawn_test_staff(count: int) -> void:
	for i in range(count):
		var npc: Node = preload("res://scripts/npc_controller.gd").new()
		npc.position = Vector2(350.0 + randf_range(-50, 50), 300.0 + randf_range(-30, 30))
		_main.add_child(npc)
		npc.configure(ActorData.new_test_staff())
		var npcs: Array = _main.get("_npcs")
		if npcs != null:
			npcs.append(npc)
		var chat_mgr = _main.get("_chat_manager")
		if chat_mgr != null:
			chat_mgr.register_npc(npc)

# ── Truck at dock ─────────────────────────────────────────────────────────────

func spawn_truck_at_dock() -> void:
	_main.set("_truck_arrived", true)
	var truck_dock_node: Node2D = _main.get("_truck_dock_node")
	if truck_dock_node == null:
		truck_dock_node = Node2D.new()
		truck_dock_node.name = "TruckDock"
		_main.add_child(truck_dock_node)
		_main.set("_truck_dock_node", truck_dock_node)
	else:
		for ch in truck_dock_node.get_children():
			ch.queue_free()
	var CELL = 16
	# Cargo area
	var cargo := ColorRect.new()
	cargo.color = Color(0.50, 0.55, 0.60)
	cargo.size = Vector2(22 * CELL, 10 * CELL)
	cargo.position = Vector2(0, 35 * CELL)
	truck_dock_node.add_child(cargo)
	# Cab
	var cab := ColorRect.new()
	cab.color = Color(0.45, 0.42, 0.40)
	cab.size = Vector2(8 * CELL, 8 * CELL)
	cab.position = Vector2(22 * CELL, 37 * CELL)
	truck_dock_node.add_child(cab)
	# Wheels
	var wheel_positions := [Vector2(2, 45), Vector2(10, 45), Vector2(22, 45), Vector2(28, 45)]
	for wp in wheel_positions:
		var wheel := ColorRect.new()
		wheel.color = Color(0.15, 0.15, 0.15)
		wheel.size = Vector2(5 * CELL, 2 * CELL)
		wheel.position = wp * CELL
		truck_dock_node.add_child(wheel)
	# Store text
	var store_lbl := Label.new()
	store_lbl.text = "PIXEL MART"
	store_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
	store_lbl.add_theme_font_size_override("font_size", 10)
	store_lbl.position = Vector2(2 * CELL, 35.5 * CELL)
	truck_dock_node.add_child(store_lbl)
	# Label
	var dock_lbl := Label.new()
	dock_lbl.text = "[E] Unload Truck"
	dock_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	dock_lbl.add_theme_font_size_override("font_size", 8)
	dock_lbl.position = Vector2(0, 44 * CELL)
	truck_dock_node.add_child(dock_lbl)
