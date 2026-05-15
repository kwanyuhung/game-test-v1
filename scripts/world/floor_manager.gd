# floor_manager.gd
# Manages multiple floors with LOD-style freezing for distant floors.
# All floors are pre-built but only floors within ACTIVE_RANGE are fully active.
extends Node

const FloorConfig = preload("res://scripts/world/floor_config.gd")
const DebugConfig = preload("res://scripts/utils/debug_config.gd")
const CELL_SIZE := 16

# How many floors around the current one should be fully active
const ACTIVE_RANGE := 0  # Only current floor is active
# How many additional floors to keep visible (for transitions/immersion)
# Changed from ACTIVE_RANGE + 1 to show ALL floors by default
# Set to -1 to show all floors, or a specific number for partial visibility
const VISIBLE_RANGE := -1  # -1 means show ALL floors

# Floor Y offset - each floor is positioned 10 tiles (160 pixels) apart
# Floor 0 at y=512 (32 tiles), Floor 1 at y=352 (22 tiles), etc.
const FLOOR_TILE_SPACING := 10  # tiles between floor origins
const FLOOR_Y_OFFSET := FLOOR_TILE_SPACING * CELL_SIZE  # 160 pixels

var _main: Node2D = null
var _current_floor_idx: int = 0
var _floor_containers: Dictionary = {}  # floor_idx -> FloorContainer
var _built_floors: Dictionary = {}     # floor_idx -> bool (has been built)
var _npcs_spawned: Dictionary = {}    # floor_idx -> bool (NPCs spawned)
var _robots_spawned: Dictionary = {}    # floor_idx -> bool (robots spawned)
var _player: Node = null
var _debug_config: Node = null  # Reference to debug config for floor restrictions

signal floor_activated(floor_idx: int)
signal floor_deactivated(floor_idx: int)

# Calculate the world Y position for a given floor index
func get_floor_y(floor_idx: int) -> float:
	# Floor 0 at tile y=32 (512 pixels), each floor above is 10 tiles higher
	# So floor_idx=0 -> y=512, floor_idx=1 -> y=352, floor_idx=2 -> y=192, etc.
	var base_y := 32 * CELL_SIZE  # 512 pixels for floor 0
	var floor_offset := floor_idx * FLOOR_Y_OFFSET
	return base_y - floor_offset

func setup(main: Node2D) -> void:
	_main = main
	_player = main.get("_player")
	_current_floor_idx = main.get("_current_floor_idx")
	
	# Clean up any existing FloorContent node from old _build_floor system
	var old_floor_content = main.get_node_or_null("FloorContent")
	if old_floor_content != null:
		main.remove_child(old_floor_content)
		old_floor_content.queue_free()
	
	# Create floor container nodes for all floors
	_create_floor_containers()
	
	# Build initial floors around current position
	_update_active_floors(_current_floor_idx)

func _create_floor_containers() -> void:
	var floor_count := FloorConfig.floor_count()
	
	for i in range(floor_count):
		var container := FloorContainer.new()
		container.name = "FloorContainer_%d" % i
		container.floor_index = i
		# Position each floor at its correct Y coordinate
		container.position = Vector2(0, get_floor_y(i))
		container.visible = false
		container.process_mode = Node.PROCESS_MODE_DISABLED
		_main.add_child(container)
		_floor_containers[i] = container

func get_floor_container(idx: int) -> Node2D:
	return _floor_containers.get(idx)

# Called by main_init.gd after _build_floor(0) has already spawned NPCs/robots
# to prevent floor_manager from spawning duplicates when setup() calls _update_active_floors()
func mark_initial_spawn_complete() -> void:
	# Mark floor 0 as having NPCs and robots already spawned
	# Note: spawn_robots() only spawns on current_floor == 0, so only floor 0 is affected
	_npcs_spawned[0] = true
	_robots_spawned[0] = true
	print("[FloorManager] Marked floor 0 as having NPCs/robots already spawned")

func get_current_floor_container() -> Node2D:
	return _floor_containers.get(_current_floor_idx)

# Check if NPCs/robots should be spawned on a floor based on debug_config
func _is_spawning_allowed_for_floor(floor_idx: int) -> bool:
	# Always use our own instance to ensure we read fresh data from JSON
	# This is important because dev_tools may have modified the config file
	if _debug_config == null:
		_debug_config = DebugConfig.new()
		_debug_config._load()
	
	# Check if this floor is in the allowed regenerate_floors list
	var allowed_floors: Array = _debug_config.get_regenerate_floors()
	if allowed_floors.is_empty():
		# No floors specified, allow all (backward compatibility)
		return true
	
	return floor_idx in allowed_floors

# Called when player changes floors (via elevator, stairs, escalator, or debug)
func on_floor_changed(new_floor_idx: int) -> void:
	if new_floor_idx == _current_floor_idx:
		return
	
	_current_floor_idx = new_floor_idx
	
	# Update which floors are active/visible
	_update_active_floors(new_floor_idx)
	
	# Update main's current floor index
	_main.set("_current_floor_idx", new_floor_idx)

func _update_active_floors(current_idx: int) -> void:
	var floor_count := FloorConfig.floor_count()
	
	# Track which floors become inactive so we can clean them up
	var previously_active_floors := []
	for idx in _npcs_spawned.keys():
		if is_floor_active(idx):
			previously_active_floors.append(idx)
	
	for i in range(floor_count):
		var container: Node2D = _floor_containers[i]
		if container == null:
			continue
			
		# Ensure floor is at correct Y position
		container.position = Vector2(0, get_floor_y(i))
		
		var distance: int = abs(i - current_idx)
		var should_be_active: bool = distance <= ACTIVE_RANGE
		# -1 means show ALL floors
		var should_be_visible: bool = VISIBLE_RANGE < 0 or distance <= VISIBLE_RANGE
		
		# Build floor if not yet built and within visible range (-1 = build all)
		if (VISIBLE_RANGE < 0 or distance <= VISIBLE_RANGE) and not _built_floors.has(i):
			_build_floor_in_container(i, container)
			_built_floors[i] = true
		
		# Spawn NPCs when floor becomes active (only if allowed by debug_config)
		if should_be_active and not _npcs_spawned.has(i) and _is_spawning_allowed_for_floor(i):
			spawn_floor_npcs(i, container)
			_npcs_spawned[i] = true
		elif should_be_active and not _npcs_spawned.has(i):
			# Floor is active but not in debug_config, mark as spawned to skip
			_npcs_spawned[i] = true
			print("[FloorManager] Skipping NPC spawn for Floor %d (not in regenerate_floors config)" % i)
		
		# Spawn robots when floor becomes active (only if allowed by debug_config)
		if should_be_active and not _robots_spawned.has(i) and _is_spawning_allowed_for_floor(i):
			spawn_floor_robots(i, container)
			_robots_spawned[i] = true
		elif should_be_active and not _robots_spawned.has(i):
			# Floor is active but not in debug_config, mark as spawned to skip
			_robots_spawned[i] = true
			print("[FloorManager] Skipping robot spawn for Floor %d (not in regenerate_floors config)" % i)
		
		# Update active state
		container.set_floor_active(should_be_active)
		
		# Update visibility
		container.visible = should_be_visible
		
		# Update process mode
		if should_be_active:
			container.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			container.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Clean up entities from floors that became inactive
	for idx in previously_active_floors:
		if not is_floor_active(idx):
			print("[FloorManager] Floor %d became inactive, cleaning up entities" % idx)
			clear_floor_entities(idx)

func _build_floor_in_container(floor_idx: int, container: Node2D) -> void:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return
	
	# Clear any existing nodes in container
	container.clear_content()
	
	# Get stairs system reference
	var stairs_sys = _main.get("_stairs_system")
	
	# Use FloorBuilder to build into this container
	var builder_script = preload("res://scripts/world/floor_builder.gd")
	var builder: Node = builder_script.new()
	builder.build(fd, container, floor_idx, stairs_sys)
	
	# Collect objects from builder before it's freed
	var sections: Array = builder.get_sections()
	var food_stalls: Array = builder.get_food_stalls()
	var claw_machines: Array = builder.get_claw_machines()
	var escalators: Array = builder.get_escalators()
	var checkout_counters: Array = builder.get_checkout_counters()
	var floor_nodes: Array = builder.get_floor_nodes()
	
	# Transfer ownership to container
	builder.reparent(container)
	builder.free()
	
	# Store the objects in the container for later access
	container.store_objects(sections, food_stalls, claw_machines, escalators, checkout_counters, floor_nodes)

# Get floor-specific spawn configuration
func _get_floor_spawn_config(floor_idx: int) -> Dictionary:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return {}
	
	var theme := fd.theme
	
	# Different floors have different staff roles based on their theme
	var staff_roles := []
	var staff_count := 3
	
	match theme:
		"lobby":
			staff_roles = [0, 3, 4, 5]  # CASHIER, GREETER, SECURITY, MANAGER
			staff_count = 4
		"shoes":
			staff_roles = [0, 1, 6]  # CASHIER, SHELF_STOCKER, FLOOR_STAFF
			staff_count = 3
		"fashion":
			staff_roles = [0, 1, 6]  # CASHIER, SHELF_STOCKER, FLOOR_STAFF
			staff_count = 4
		"sport":
			staff_roles = [0, 1, 6]  # CASHIER, SHELF_STOCKER, FLOOR_STAFF
			staff_count = 3
		"outdoor":
			staff_roles = [0, 1, 6]  # CASHIER, SHELF_STOCKER, FLOOR_STAFF
			staff_count = 3
		_:
			staff_roles = [0, 1, 2]  # CASHIER, SHELF_STOCKER, CLEANER
			staff_count = 3
	
	# Customer group types vary by floor type
	var customer_types := [0, 1, 2]  # SOLO, COUPLE, PAIR
	var customer_count := 3 + floor_idx
	
	match theme:
		"lobby":
			customer_types = [0, 1, 2, 3, 4, 5, 6]  # All types including families
			customer_count = 5
		"shoes", "fashion", "sport":
			customer_types = [1, 2, 3, 4, 6]  # COUPLE, PAIR, families, friends
			customer_count = 4
		_:
			customer_types = [0, 1, 2]
			customer_count = 3
	
	return {
		"staff_roles": staff_roles,
		"staff_count": staff_count,
		"customer_types": customer_types,
		"customer_count": customer_count
	}

# Spawn NPCs for a specific floor
func spawn_floor_npcs(floor_idx: int, container: Node2D) -> void:
	var main_spawner = _main.get("_main_spawner")
	if main_spawner == null:
		print("[FloorManager] Warning: main_spawner not found, cannot spawn NPCs")
		return
	
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return
	
	# Get floor Y position (world coordinate)
	var floor_y: float = get_floor_y(floor_idx)
	
	# Get spawn configuration for this floor
	var config := _get_floor_spawn_config(floor_idx)
	var staff_roles: Array = config.get("staff_roles", [0, 1, 2])
	var staff_count: int = config.get("staff_count", 3)
	var customer_types: Array = config.get("customer_types", [0, 1, 2])
	var customer_count: int = config.get("customer_count", 3)
	
	print("[FloorManager] Spawning NPCs for Floor %d (theme: %s): %d staff, %d customers" % [floor_idx, fd.theme, staff_count, customer_count])
	
	# Spawn staff NPCs
	var staff_spawn_area_x := [100.0, 300.0, 500.0, 700.0, 900.0]
	var staff_spawn_area_y := [floor_y + 200.0, floor_y + 350.0, floor_y + 450.0]
	
	for i in range(staff_count):
		var role_idx: int = staff_roles[i % staff_roles.size()]
		var pos_x: float = staff_spawn_area_x[i % staff_spawn_area_x.size()]
		var pos_y: float = staff_spawn_area_y[i % staff_spawn_area_y.size()]
		var pos := Vector2(pos_x + randf_range(-30, 30), pos_y + randf_range(-20, 20))
		
		main_spawner.spawn_npc_staff(role_idx, floor_idx, pos)
	
	# Spawn customer groups
	var customer_spawn_area_x := [150.0, 350.0, 550.0, 750.0, 950.0]
	var customer_spawn_area_y := [floor_y + 250.0, floor_y + 400.0, floor_y + 500.0]
	
	for i in range(customer_count):
		var group_type: int = customer_types[i % customer_types.size()]
		var pos_x: float = customer_spawn_area_x[i % customer_spawn_area_x.size()]
		var pos_y: float = customer_spawn_area_y[i % customer_spawn_area_y.size()]
		var pos := Vector2(pos_x + randf_range(-40, 40), pos_y + randf_range(-30, 30))
		
		main_spawner.spawn_customer_group(group_type, floor_idx, pos)

# Spawn robots for a specific floor
func spawn_floor_robots(floor_idx: int, container: Node2D) -> void:
	var main_spawner = _main.get("_main_spawner")
	if main_spawner == null:
		print("[FloorManager] Warning: main_spawner not found, cannot spawn robots")
		return
	
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return
	
	# Get floor Y position (world coordinate)
	var floor_y: float = get_floor_y(floor_idx)
	
	print("[FloorManager] Spawning robots for Floor %d (theme: %s)" % [floor_idx, fd.theme])
	
	# Check if robots already exist for this floor before spawning
	var robots: Array = _main.get("_robots")
	
	# Spawn cleaning robot on EVERY floor
	var cleaner_pos := Vector2(800.0, floor_y + 400.0) + Vector2(randf_range(-50, 50), randf_range(-30, 30))
	# Check if cleaning robot already exists for this floor
	var has_cleaner := false
	if robots != null:
		for r in robots:
			if r.name.begins_with("Robot_Cleaner_Floor%d" % floor_idx) or r.name.begins_with("Robot_Single_Cleaner"):
				has_cleaner = true
				break
	if not has_cleaner:
		main_spawner.spawn_robot_single(0)  # CLEANING_ROBOT
		# Find the robot we just spawned (it has the newest name with _npc_count)
		var all_robots = _main.get("_robots")
		if all_robots != null and all_robots.size() > 0:
			var newest_robot = all_robots[all_robots.size() - 1]
			newest_robot.position = cleaner_pos
			newest_robot.name = "Robot_Cleaner_Floor%d" % floor_idx
			print("[FloorManager] Spawned cleaning robot at %s" % str(cleaner_pos))
	
	# Spawn guidance robot (only on ground floor - lobby)
	if floor_idx == 0:
		var guide_pos := Vector2(400.0, floor_y + 150.0) + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var has_guide := false
		if robots != null:
			for r in robots:
				if r.name.begins_with("Robot_Guide_Floor0") or r.name.begins_with("Robot_Single_Guide"):
					has_guide = true
					break
		if not has_guide:
			main_spawner.spawn_robot_single(1)  # GUIDANCE_ROBOT
			var all_robots = _main.get("_robots")
			if all_robots != null and all_robots.size() > 0:
				var newest_robot = all_robots[all_robots.size() - 1]
				newest_robot.position = guide_pos
				newest_robot.name = "Robot_Guide_Floor0"
				print("[FloorManager] Spawned guidance robot at %s" % str(guide_pos))
	
	# Spawn shelf stocking robot on floors with shopping
	if fd.has_shopping and floor_idx > 0:
		var shelf_pos := Vector2(200.0, floor_y + 300.0) + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var has_shelf := false
		if robots != null:
			for r in robots:
				if r.name.begins_with("Robot_Shelf_Floor%d" % floor_idx) or r.name.begins_with("Robot_Single_Shelf"):
					has_shelf = true
					break
		if not has_shelf:
			main_spawner.spawn_robot_single(4)  # SHELF_ROBOT
			var all_robots = _main.get("_robots")
			if all_robots != null and all_robots.size() > 0:
				var newest_robot = all_robots[all_robots.size() - 1]
				newest_robot.position = shelf_pos
				newest_robot.name = "Robot_Shelf_Floor%d" % floor_idx
				print("[FloorManager] Spawned shelf robot at %s" % str(shelf_pos))
	
	# Spawn security robot on lobby floor
	if floor_idx == 0:
		var sec_pos := Vector2(150.0, floor_y + 200.0) + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var has_security := false
		if robots != null:
			for r in robots:
				if r.name.begins_with("Robot_Security_Floor0") or r.name.begins_with("Robot_Single_Security"):
					has_security = true
					break
		if not has_security:
			main_spawner.spawn_robot_single(3)  # SECURITY_ROBOT
			var all_robots = _main.get("_robots")
			if all_robots != null and all_robots.size() > 0:
				var newest_robot = all_robots[all_robots.size() - 1]
				newest_robot.position = sec_pos
				newest_robot.name = "Robot_Security_Floor0"
				print("[FloorManager] Spawned security robot at %s" % str(sec_pos))

# Regenerate NPCs for a floor (call when floor changes to refresh)
func regenerate_floor_npcs(floor_idx: int) -> void:
	_npcs_spawned.erase(floor_idx)
	var container: Node2D = _floor_containers.get(floor_idx)
	if container != null and is_floor_active(floor_idx):
		spawn_floor_npcs(floor_idx, container)
		_npcs_spawned[floor_idx] = true

# Regenerate robots for a floor (call when floor changes to refresh)
func regenerate_floor_robots(floor_idx: int) -> void:
	_robots_spawned.erase(floor_idx)
	var container: Node2D = _floor_containers.get(floor_idx)
	if container != null and is_floor_active(floor_idx):
		spawn_floor_robots(floor_idx, container)
		_robots_spawned[floor_idx] = true

# Clear all NPCs and robots from a floor
func clear_floor_entities(floor_idx: int) -> void:
	var container: Node2D = _floor_containers.get(floor_idx)
	if container == null:
		return
	
	# Remove NPC nodes from container
	var to_remove := []
	for child in container.get_children():
		if child.name.begins_with("Staff_") or child.name.begins_with("Customer_") or child.name.begins_with("GroupLeader_"):
			to_remove.append(child)
		elif child.name.begins_with("Robot_") or child.name.begins_with("Robo_"):
			to_remove.append(child)
	
	for node in to_remove:
		container.remove_child(node)
		node.queue_free()
	
	# Also remove NPCs/robots from _main that belong to this floor
	# They were spawned directly to _main, not to container
	_cleanup_main_entities_for_floor(floor_idx)
	
	_npcs_spawned.erase(floor_idx)
	_robots_spawned.erase(floor_idx)

# Clean up entities from _main that belong to a specific floor
func _cleanup_main_entities_for_floor(floor_idx: int) -> void:
	if _main == null:
		return
	
	# Get all NPCs from _main's _npcs array that belong to this floor
	var npcs: Array = _main.get("_npcs")
	if npcs != null:
		var to_remove := []
		for npc in npcs:
			if is_instance_valid(npc):
				# Check if this NPC belongs to the target floor
				# NPCs track their floor via actor.current_floor - this is the most reliable check
				if npc.has_method("get_actor"):
					var actor = npc.get_actor()
					if actor != null and actor.current_floor == floor_idx:
						to_remove.append(npc)
		
		for npc in to_remove:
			npcs.erase(npc)
			if npc.get_parent() == _main:
				_main.remove_child(npc)
			npc.queue_free()
	
	# Clean up robots from _main's _robots array
	var robots: Array = _main.get("_robots")
	if robots != null:
		var to_remove := []
		for robot in robots:
			if is_instance_valid(robot):
				# Robots have floor info in their name (Robot_Cleaner_Floor0, etc.)
				# Check for floor-specific naming pattern
				var robot_name = robot.name if robot.name != null else ""
				if robot_name.find("Floor%d" % floor_idx) >= 0:
					to_remove.append(robot)
				# Also check old-style naming without floor suffix
				elif robot_name.begins_with("Robot_Single_Cleaner") or robot_name.begins_with("Robot_Single_Guide") or robot_name.begins_with("Robot_Single_Shelf") or robot_name.begins_with("Robot_Single_Security"):
					to_remove.append(robot)
				elif robot_name.begins_with("Robot_Humanoid_"):
					to_remove.append(robot)
		
		for robot in to_remove:
			robots.erase(robot)
			if robot.get_parent() == _main:
				_main.remove_child(robot)
			robot.queue_free()
	
	print("[FloorManager] Cleaned up entities for floor %d from _main" % floor_idx)

func get_distance_to_floor(floor_idx: int) -> int:
	return abs(floor_idx - _current_floor_idx)

func is_floor_active(floor_idx: int) -> bool:
	return abs(floor_idx - _current_floor_idx) <= ACTIVE_RANGE

func is_floor_visible(floor_idx: int) -> bool:
	# -1 means all floors are visible
	if VISIBLE_RANGE < 0:
		return true
	return abs(floor_idx - _current_floor_idx) <= VISIBLE_RANGE

func get_current_floor_index() -> int:
	return _current_floor_idx

# Pre-build all floors (call this during loading screen or at game start)
func preload_all_floors() -> void:
	var floor_count := FloorConfig.floor_count()
	
	for i in range(floor_count):
		var container: Node2D = _floor_containers[i]
		if container == null:
			continue
		
		# Position floor at correct Y coordinate
		container.position = Vector2(0, get_floor_y(i))
		
		if not _built_floors.has(i):
			_build_floor_in_container(i, container)
			_built_floors[i] = true
		
		# Set to inactive initially (only current floor's range will be activated)
		container.set_floor_active(false)
	
	# Now activate floors around current
	_update_active_floors(_current_floor_idx)

# Get all NPCs on a specific floor for AI updates
func get_floor_npcs(floor_idx: int) -> Array:
	var container: Node2D = _floor_containers.get(floor_idx)
	if container == null:
		return []
	
	var npcs: Array = []
	for child in container.get_children():
		if child.name.begins_with("Staff_") or child.name.begins_with("Customer_") or child.name.begins_with("Robot_"):
			npcs.append(child)
	return npcs

# Get all dynamic objects on a floor that should be frozen when inactive
func get_floor_dynamic_objects(floor_idx: int) -> Array:
	var container: Node2D = _floor_containers.get(floor_idx)
	if container == null:
		return []
	
	var dynamics: Array = []
	for child in container.get_children():
		if child.name.begins_with("Staff_") or child.name.begins_with("Customer_") or child.name.begins_with("Robot_"):
			dynamics.append(child)
		elif child.name.begins_with("Section_"):
			# Sections have internal state
			dynamics.append(child)
	return dynamics

# Freeze all dynamic objects on a floor
func freeze_floor(floor_idx: int) -> void:
	var container: Node2D = _floor_containers.get(floor_idx)
	if container == null:
		return
	
	container.freeze_all()
	floor_deactivated.emit(floor_idx)

# Unfreeze all dynamic objects on a floor
func unfreeze_floor(floor_idx: int) -> void:
	var container: Node2D = _floor_containers.get(floor_idx)
	if container == null:
		return
	
	container.unfreeze_all()
	floor_activated.emit(floor_idx)

# Called by elevator/stairs/escalator when travel starts
func on_travel_started(from_floor: int, to_floor: int) -> void:
	# Could pre-warm nearby floors here if needed
	pass

# Called by elevator/stairs/escalator when travel completes
func on_travel_completed(to_floor: int) -> void:
	on_floor_changed(to_floor)


# FloorContainer class - represents a single floor's content with freeze capability
class FloorContainer extends Node2D:
	var floor_index: int = 0
	var _is_active: bool = false
	var _dynamic_nodes: Array = []
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
		_dynamic_nodes.clear()
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
		# Skip static nodes
		if node is ColorRect or node is Label or node is Sprite2D:
			return
		
		# Freeze NPCs and robots
		if node.name.begins_with("Staff_") or node.name.begins_with("Customer_") or node.name.begins_with("Robot_"):
			if node.has_method("set_frozen"):
				node.set_frozen(true)
			elif node.has_method("set_process"):
				node.set_process(false)
			if node.has_method("set_physics_process"):
				node.set_physics_process(false)
		
		# Freeze section containers
		elif node.name.begins_with("Section_"):
			if node.has_method("set_frozen"):
				node.set_frozen(true)
	
	func _unfreeze_node(node: Node) -> void:
		# Skip static nodes
		if node is ColorRect or node is Label or node is Sprite2D:
			return
		
		# Unfreeze NPCs and robots
		if node.name.begins_with("Staff_") or node.name.begins_with("Customer_") or node.name.begins_with("Robot_"):
			if node.has_method("set_frozen"):
				node.set_frozen(false)
			elif node.has_method("set_process"):
				node.set_process(true)
			if node.has_method("set_physics_process"):
				node.set_physics_process(true)
		
		# Unfreeze section containers
		elif node.name.begins_with("Section_"):
			if node.has_method("set_frozen"):
				node.set_frozen(false)
	
	# Get all NPC references for this floor
	func get_npcs() -> Array:
		var npcs: Array = []
		for child in get_children():
			if child.name.begins_with("Staff_") or child.name.begins_with("Customer_") or child.name.begins_with("GroupLeader_"):
				npcs.append(child)
		return npcs
	
	# Get all robot references for this floor
	func get_robots() -> Array:
		var robots: Array = []
		for child in get_children():
			if child.name.begins_with("Robot_") or child.name.begins_with("Robo_"):
				robots.append(child)
		return robots
	
	# Get all section references for this floor
	func get_sections() -> Array:
		return _sections
	
	# Get all food stall references for this floor
	func get_food_stalls() -> Array:
		return _food_stalls
	
	# Get all claw machine references for this floor
	func get_claw_machines() -> Array:
		return _claw_machines
	
	# Get all escalator references for this floor
	func get_escalators() -> Array:
		return _escalators
	
	# Get all checkout counter references for this floor
	func get_checkout_counters() -> Array:
		return _checkout_counters
	
	# Store objects built by FloorBuilder into this container
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
