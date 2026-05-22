# floor_manager.gd
# Unified multi-floor system for Pixel Supermarket.
# All floors exist in world space, positioned vertically with FLOOR_TILE_SPACING apart.
# Only the current floor is fully active (others frozen for performance).
extends Node

const FloorConfig = preload("res://scripts/world/floor_config.gd")
const DebugConfig = preload("res://scripts/utils/debug_config.gd")
const CELL_SIZE := FloorConfig.CELL_SIZE

# Floor spacing: 10 tiles (160 pixels) between floor origins
const FLOOR_TILE_SPACING := 10
const FLOOR_Y_OFFSET := FLOOR_TILE_SPACING * CELL_SIZE  # 160 pixels

# Floor 0 base Y position (tile 32 = 512 pixels from top)
const FLOOR_0_BASE_Y := 32 * CELL_SIZE  # 512 pixels

# Static method to get floor Y position (used by elevator.gd and other systems)
static func get_floor_y(floor_idx: int) -> float:
	return FLOOR_0_BASE_Y - (floor_idx * FLOOR_Y_OFFSET)

var _main: Node2D = null
var _current_floor_idx: int = 0
var _floor_containers: Dictionary = {}  # floor_idx -> FloorContainer
var _built_floors: Dictionary = {}      # floor_idx -> bool
var _npcs_spawned: Dictionary = {}       # floor_idx -> bool
var _robots_spawned: Dictionary = {}     # floor_idx -> bool
var _player: Node = null
var _debug_config: Node = null
var _sections: Array = []                # Current floor's sections
var _checkout_counters: Array = []      # Current floor's checkout counters

signal floor_activated(floor_idx: int)
signal floor_deactivated(floor_idx: int)

func setup(main: Node2D) -> void:
	_main = main
	_player = main.get("_player")
	_current_floor_idx = main.get("_current_floor_idx")

	# Remove old FloorContent if it exists
	var old_floor_content = main.get_node_or_null("FloorContent")
	if old_floor_content != null:
		main.remove_child(old_floor_content)
		old_floor_content.queue_free()

	# Create containers for all floors
	_create_floor_containers()

	# Pre-build all floors
	preload_all_floors()

	# Activate current floor
	_show_floor(_current_floor_idx)

func _create_floor_containers() -> void:
	var floor_count := FloorConfig.floor_count()

	for i in range(floor_count):
		var container := FloorContainer.new()
		container.name = "FloorContainer_%d" % i
		container.floor_index = i
		container.position = Vector2(0, get_floor_y(i))
		container.visible = false
		container.process_mode = Node.PROCESS_MODE_DISABLED
		_main.add_child(container)
		_floor_containers[i] = container

func get_floor_container(idx: int) -> Node2D:
	return _floor_containers.get(idx)

func get_current_floor_container() -> Node2D:
	return _floor_containers.get(_current_floor_idx)

func mark_initial_spawn_complete() -> void:
	_npcs_spawned[0] = true
	_robots_spawned[0] = true
	print("[FloorManager] Marked floor 0 as having NPCs/robots already spawned")

func _is_spawning_allowed_for_floor(floor_idx: int) -> bool:
	if _debug_config == null:
		_debug_config = DebugConfig.new()
		_debug_config._load()

	var allowed_floors: Array = _debug_config.get_regenerate_floors()
	if allowed_floors.is_empty():
		return true
	return floor_idx in allowed_floors

func on_floor_changed(new_floor_idx: int) -> void:
	if new_floor_idx == _current_floor_idx:
		return

	# Hide old floor
	_hide_floor(_current_floor_idx)

	_current_floor_idx = new_floor_idx
	_main.set("_current_floor_idx", new_floor_idx)

	# Show new floor
	_show_floor(new_floor_idx)

func _show_floor(floor_idx: int) -> void:
	var container: Node2D = _floor_containers.get(floor_idx)
	if container == null:
		push_error("[FloorManager] No container for floor %d" % floor_idx)
		return

	# Activate container
	container.visible = true
	container.process_mode = Node.PROCESS_MODE_INHERIT
	container.set_floor_active(true)

	# Update player bounds for this floor
	if _player != null and _player.has_method("set_floor_bounds"):
		_player.set_floor_bounds(floor_idx)

	# Update ambient color
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd != null and _main.has_method("set_ambient_floor"):
		_main.set_ambient_floor(floor_idx)

	# Collect current floor's sections and checkout counters
	_sections = container.get_sections()
	_checkout_counters = container.get_checkout_counters()

	# Spawn NPCs and robots if not already done
	if not _npcs_spawned.has(floor_idx):
		if _is_spawning_allowed_for_floor(floor_idx):
			spawn_floor_npcs(floor_idx, container)
		_npcs_spawned[floor_idx] = true

	if not _robots_spawned.has(floor_idx):
		if _is_spawning_allowed_for_floor(floor_idx):
			spawn_floor_robots(floor_idx, container)
		_robots_spawned[floor_idx] = true

	# Update HUD
	if _main.has_method("_update_floor_hud"):
		_main._update_floor_hud()

	# Update main's references to current floor's objects
	_main.set("_sections", _sections)
	_main.set("_checkout_counters", _checkout_counters)
	_main.set("_floor_builder", container)

	# Update proximity system with new floor's objects
	var prox = _main.get("_proximity_system")
	if prox != null and prox.has_method("refresh_from_floor_manager"):
		prox.refresh_from_floor_manager()

	floor_activated.emit(floor_idx)
	print("[FloorManager] Showing floor %d" % floor_idx)

func _hide_floor(floor_idx: int) -> void:
	var container: Node2D = _floor_containers.get(floor_idx)
	if container == null:
		return

	container.set_floor_active(false)
	container.process_mode = Node.PROCESS_MODE_DISABLED
	container.visible = false

	floor_deactivated.emit(floor_idx)
	print("[FloorManager] Hiding floor %d" % floor_idx)

func preload_all_floors() -> void:
	var floor_count := FloorConfig.floor_count()

	for i in range(floor_count):
		var container: Node2D = _floor_containers[i]
		if container == null:
			continue

		container.position = Vector2(0, get_floor_y(i))

		if not _built_floors.has(i):
			_build_floor_in_container(i, container)
			_built_floors[i] = true

		container.set_floor_active(false)

	print("[FloorManager] Pre-built %d floors" % floor_count)

func _build_floor_in_container(floor_idx: int, container: Node2D) -> void:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		push_error("[FloorManager] No floor def for floor %d" % floor_idx)
		return

	container.clear_content()

	var stairs_sys = _main.get("_stairs_system")

	var builder_script = preload("res://scripts/world/floor_builder.gd")
	var builder: Node = builder_script.new()
	container.add_child(builder)
	builder.build(fd, container, floor_idx, stairs_sys)

	var sections: Array = builder.get_sections()
	var food_stalls: Array = builder.get_food_stalls()
	var claw_machines: Array = builder.get_claw_machines()
	var escalators: Array = builder.get_escalators()
	var checkout_counters: Array = builder.get_checkout_counters()
	var floor_nodes: Array = builder.get_floor_nodes()

	builder.reparent(container)
	builder.free()

	container.store_objects(sections, food_stalls, claw_machines, escalators, checkout_counters, floor_nodes)
	print("[FloorManager] Built floor %d" % floor_idx)

func _get_floor_spawn_config(floor_idx: int) -> Dictionary:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return {}

	var theme := fd.theme
	var staff_roles := [0, 1, 2]
	var staff_count := 3
	var customer_types := [0, 1, 2]
	var customer_count := 3

	match theme:
		"lobby":
			staff_roles = [0, 3, 4, 5]
			staff_count = 4
			customer_types = [0, 1, 2, 3, 4, 5, 6]
			customer_count = 5
		"shoes", "fashion", "sport":
			staff_roles = [0, 1, 6]
			staff_count = 3
			customer_types = [1, 2, 3, 4, 6]
			customer_count = 4

	return {
		"staff_roles": staff_roles,
		"staff_count": staff_count,
		"customer_types": customer_types,
		"customer_count": customer_count
	}

func spawn_floor_npcs(floor_idx: int, container: Node2D) -> void:
	var main_spawner = _main.get("_main_spawner")
	if main_spawner == null:
		print("[FloorManager] Warning: main_spawner not found")
		return

	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return

	var floor_y: float = get_floor_y(floor_idx)
	var config := _get_floor_spawn_config(floor_idx)
	var staff_roles: Array = config.get("staff_roles", [0, 1, 2])
	var staff_count: int = config.get("staff_count", 3)
	var customer_types: Array = config.get("customer_types", [0, 1, 2])
	var customer_count: int = config.get("customer_count", 3)

	print("[FloorManager] Spawning NPCs for Floor %d: %d staff, %d customers" % [floor_idx, staff_count, customer_count])

	var staff_spawn_x := [100.0, 300.0, 500.0, 700.0, 900.0]
	var staff_spawn_y := [200.0, 350.0, 450.0]

	for i in range(staff_count):
		var role_idx: int = staff_roles[i % staff_roles.size()]
		var pos_x: float = staff_spawn_x[i % staff_spawn_x.size()]
		var pos_y: float = staff_spawn_y[i % staff_spawn_y.size()]
		var pos := Vector2(pos_x + randf_range(-30, 30), floor_y + pos_y + randf_range(-20, 20))
		main_spawner.spawn_npc_staff(role_idx, floor_idx, pos)

	var customer_spawn_x := [150.0, 350.0, 550.0, 750.0, 950.0]
	var customer_spawn_y := [250.0, 400.0, 500.0]

	for i in range(customer_count):
		var group_type: int = customer_types[i % customer_types.size()]
		var pos_x: float = customer_spawn_x[i % customer_spawn_x.size()]
		var pos_y: float = customer_spawn_y[i % customer_spawn_y.size()]
		var pos := Vector2(pos_x + randf_range(-40, 40), floor_y + pos_y + randf_range(-30, 30))
		main_spawner.spawn_customer_group(group_type, floor_idx, pos)

func spawn_floor_robots(floor_idx: int, container: Node2D) -> void:
	var main_spawner = _main.get("_main_spawner")
	if main_spawner == null:
		print("[FloorManager] Warning: main_spawner not found")
		return

	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return

	var floor_y: float = get_floor_y(floor_idx)
	print("[FloorManager] Spawning robots for Floor %d" % floor_idx)

	var robots: Array = _main.get("_robots")

	# Cleaning robot on every floor
	var cleaner_pos := Vector2(800.0, floor_y + 400.0) + Vector2(randf_range(-50, 50), randf_range(-30, 30))
	var has_cleaner := false
	if robots != null:
		for r in robots:
			if r.name.begins_with("Robot_Cleaner_Floor%d" % floor_idx):
				has_cleaner = true
				break
	if not has_cleaner:
		main_spawner.spawn_robot_single(0)
		var all_robots = _main.get("_robots")
		if all_robots != null and all_robots.size() > 0:
			var newest = all_robots[all_robots.size() - 1]
			newest.position = cleaner_pos
			newest.name = "Robot_Cleaner_Floor%d" % floor_idx

	# Guidance robot on ground floor
	if floor_idx == 0:
		var guide_pos := Vector2(400.0, floor_y + 150.0) + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var has_guide := false
		if robots != null:
			for r in robots:
				if r.name.begins_with("Robot_Guide_Floor0"):
					has_guide = true
					break
		if not has_guide:
			main_spawner.spawn_robot_single(1)
			var all_robots = _main.get("_robots")
			if all_robots != null and all_robots.size() > 0:
				var newest = all_robots[all_robots.size() - 1]
				newest.position = guide_pos
				newest.name = "Robot_Guide_Floor0"

	# Security robot on lobby
	var sec_pos := Vector2(150.0, floor_y + 200.0) + Vector2(randf_range(-30, 30), randf_range(-20, 20))
	var has_security := false
	if robots != null:
		for r in robots:
			if r.name.begins_with("Robot_Security_Floor0"):
				has_security = true
				break
	if not has_security:
		main_spawner.spawn_robot_single(3)
		var all_robots = _main.get("_robots")
		if all_robots != null and all_robots.size() > 0:
			var newest = all_robots[all_robots.size() - 1]
			newest.position = sec_pos
			newest.name = "Robot_Security_Floor0"

	# Shelf robot on shopping floors
	if fd.has_shopping and floor_idx > 0:
		var shelf_pos := Vector2(200.0, floor_y + 300.0) + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var has_shelf := false
		if robots != null:
			for r in robots:
				if r.name.begins_with("Robot_Shelf_Floor%d" % floor_idx):
					has_shelf = true
					break
		if not has_shelf:
			main_spawner.spawn_robot_single(4)
			var all_robots = _main.get("_robots")
			if all_robots != null and all_robots.size() > 0:
				var newest = all_robots[all_robots.size() - 1]
				newest.position = shelf_pos
				newest.name = "Robot_Shelf_Floor%d" % floor_idx

func get_distance_to_floor(floor_idx: int) -> int:
	return abs(floor_idx - _current_floor_idx)

func is_floor_active(floor_idx: int) -> bool:
	return floor_idx == _current_floor_idx

func is_floor_visible(floor_idx: int) -> bool:
	return floor_idx == _current_floor_idx

func get_current_floor_index() -> int:
	return _current_floor_idx

func on_travel_completed(to_floor: int) -> void:
	on_floor_changed(to_floor)

# Get sections for current floor (for proximity system)
func get_sections() -> Array:
	return _sections

# Get checkout counters for current floor
func get_checkout_counters() -> Array:
	return _checkout_counters


# FloorContainer class
class FloorContainer extends Node2D:
	var floor_index: int = 0
	var _is_active: bool = false
	var _sections: Array = []
	var _food_stalls: Array = []
	var _claw_machines: Array = []
	var _escalators: Array = []
	var _checkout_counters: Array = []
	var _floor_nodes: Array = []

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_DISABLED

	func clear_content() -> void:
		for node in get_children():
			node.queue_free()
		_sections.clear()
		_food_stalls.clear()
		_claw_machines.clear()
		_escalators.clear()
		_checkout_counters.clear()
		_floor_nodes.clear()

	func set_floor_active(active: bool) -> void:
		if _is_active == active:
			return
		_is_active = active
		if active:
			unfreeze_all()
		else:
			freeze_all()

	func is_floor_active() -> bool:
		return _is_active

	func freeze_all() -> void:
		for node in get_children():
			_freeze_node(node)

	func unfreeze_all() -> void:
		for node in get_children():
			_unfreeze_node(node)

	func _freeze_node(node: Node) -> void:
		if node is ColorRect or node is Label or node is Sprite2D:
			return
		if node.name.begins_with("Staff_") or node.name.begins_with("Customer_") or node.name.begins_with("Robot_"):
			if node.has_method("set_frozen"):
				node.set_frozen(true)
			elif node.has_method("set_process"):
				node.set_process(false)
			if node.has_method("set_physics_process"):
				node.set_physics_process(false)
		elif node.name.begins_with("Section_"):
			if node.has_method("set_frozen"):
				node.set_frozen(true)

	func _unfreeze_node(node: Node) -> void:
		if node is ColorRect or node is Label or node is Sprite2D:
			return
		if node.name.begins_with("Staff_") or node.name.begins_with("Customer_") or node.name.begins_with("Robot_"):
			if node.has_method("set_frozen"):
				node.set_frozen(false)
			elif node.has_method("set_process"):
				node.set_process(true)
			if node.has_method("set_physics_process"):
				node.set_physics_process(true)
		elif node.name.begins_with("Section_"):
			if node.has_method("set_frozen"):
				node.set_frozen(false)

	func get_sections() -> Array:
		return _sections

	func get_food_stalls() -> Array:
		return _food_stalls

	func get_claw_machines() -> Array:
		return _claw_machines

	func get_escalators() -> Array:
		return _escalators

	func get_checkout_counters() -> Array:
		return _checkout_counters

	func store_objects(
		sections: Array,
		food_stalls: Array,
		claw_machines: Array,
		escalators: Array,
		checkout_counters: Array,
		floor_nodes: Array
	) -> void:
		_sections = sections.duplicate()
		_food_stalls = food_stalls.duplicate()
		_claw_machines = claw_machines.duplicate()
		_escalators = escalators.duplicate()
		_checkout_counters = checkout_counters.duplicate()
		_floor_nodes = floor_nodes.duplicate()
