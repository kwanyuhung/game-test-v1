# floor_manager.gd
# Manages multiple floors with LOD-style freezing for distant floors.
# All floors are pre-built but only floors within ACTIVE_RANGE are fully active.
extends Node

const FloorConfig = preload("res://scripts/floor_config.gd")
const CELL_SIZE := 16

# How many floors around the current one should be fully active
const ACTIVE_RANGE := 2
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
var _player: Node = null

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

func get_current_floor_container() -> Node2D:
	return _floor_containers.get(_current_floor_idx)

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
		
		# Update active state
		container.set_floor_active(should_be_active)
		
		# Update visibility
		container.visible = should_be_visible
		
		# Update process mode
		if should_be_active:
			container.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			container.process_mode = Node.PROCESS_MODE_DISABLED

func _build_floor_in_container(floor_idx: int, container: Node2D) -> void:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return
	
	# Clear any existing nodes in container
	container.clear_content()
	
	# Get stairs system reference
	var stairs_sys = _main.get("_stairs_system")
	
	# Use FloorBuilder to build into this container
	var builder_script = preload("res://scripts/floor_builder.gd")
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
