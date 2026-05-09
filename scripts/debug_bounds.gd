# debug_bounds.gd
# Debug bounding box visualization system like Unity Gizmos.
# Press F3 to toggle debug bounds display.
extends Node2D

var _main: Node2D = null
var _debug_enabled: bool = false
var _bounds_layer: Node2D = null
var _labels_layer: Node2D = null
var _f3_was_pressed: bool = false

# Color palette for different object types (white/light colors for visibility)
const COLORS = {
	"elevator": Color(1.0, 1.0, 1.0, 0.7),     # White
	"escalator": Color(1.0, 1.0, 1.0, 0.7),    # White
	"section": Color(1.0, 1.0, 1.0, 0.7),      # White
	"stall": Color(1.0, 1.0, 1.0, 0.7),        # White
	"checkout": Color(1.0, 1.0, 1.0, 0.7),     # White
	"npc": Color(1.0, 1.0, 1.0, 0.7),          # White
	"facility": Color(1.0, 1.0, 1.0, 0.7),     # White
	"zone": Color(1.0, 1.0, 1.0, 0.5),         # White
	"spawn": Color(1.0, 1.0, 1.0, 0.7),        # White
}

# Track all debug bounds
var _tracked_objects: Array = []

class TrackedObject:
	var node: Node
	var bounds_rect: Rect2
	var object_type: String
	var label: String
	var color: Color
	
	func _init(n: Node, r: Rect2, t: String, l: String, c: Color):
		node = n
		bounds_rect = r
		object_type = t
		label = l
		color = c

func _ready() -> void:
	# Create layers for debug visualization
	_bounds_layer = Node2D.new()
	_bounds_layer.name = "DebugBoundsLayer"
	_bounds_layer.z_index = 1000  # Draw on top
	add_child(_bounds_layer)
	
	_labels_layer = Node2D.new()
	_labels_layer.name = "DebugLabelsLayer"
	_labels_layer.z_index = 1001
	add_child(_labels_layer)

func setup(main: Node2D) -> void:
	_main = main

func _process(_delta: float) -> void:
	if _debug_enabled:
		_update_debug_view()
	
	# Toggle debug with F3 (check each frame to avoid input issues)
	if Input.is_key_pressed(KEY_F3) and not _f3_was_pressed:
		_f3_was_pressed = true
		_debug_enabled = !_debug_enabled
		_refresh_debug_view()
		print("Debug Bounds: ", "ON" if _debug_enabled else "OFF")
	elif not Input.is_key_pressed(KEY_F3):
		_f3_was_pressed = false

# ── Add objects to debug visualization ──────────────────────────────────────

func track_object(node: Node, bounds: Rect2, obj_type: String, label: String = "") -> void:
	var color = COLORS.get(obj_type, Color(1, 1, 1, 0.5))
	var tracked = TrackedObject.new(node, bounds, obj_type, label, color)
	_tracked_objects.append(tracked)
	if _debug_enabled:
		_draw_bounds_immediate(tracked)

func track_zone(x: int, y: int, w: int, h: int, label: String = "") -> void:
	var rect = Rect2(x * 16, y * 16, w * 16, h * 16)
	var color = COLORS.get("zone", Color(0.6, 0.6, 0.8, 0.4))
	var tracked = TrackedObject.new(null, rect, "zone", label, color)
	_tracked_objects.append(tracked)
	if _debug_enabled:
		_draw_bounds_immediate(tracked)

func track_elevator(elevator) -> void:
	if elevator == null:
		return
	var pos = elevator.global_position if elevator.has_method("global_position") else elevator.position
	var size = Vector2(48, 64)  # Default elevator size
	var rect = Rect2(pos - Vector2(24, 0), size)
	track_object(elevator, rect, "elevator", "Elevator")

func track_escalator(escalator) -> void:
	if escalator == null:
		return
	var zone = escalator.get_zone() if escalator.has_method("get_zone") else null
	if zone == null:
		return
	var rect = Rect2(zone.x * 16, zone.y * 16, zone.w * 16, zone.h * 16)
	var info = escalator.get_escalator_info() if escalator.has_method("get_escalator_info") else {}
	var label = "Escalator %s" % info.get("id", "unknown")
	track_object(escalator, rect, "escalator", label)

func track_section(section) -> void:
	if section == null:
		return
	var rect = Rect2()
	if section.has_method("get_zone"):
		var zone = section.get_zone()
		rect = Rect2(zone.x * 16, zone.y * 16, zone.w * 16, zone.h * 16)
		var name = ""
		if section.has_method("get_def"):
			var def = section.get_def()
			if def.has("name"):
				name = def.name
		track_object(section, rect, "section", name)

func track_stall(stall) -> void:
	if stall == null:
		return
	if stall.has_method("get_zone"):
		var zone = stall.get_zone()
		var rect = Rect2(zone.x * 16, zone.y * 16, zone.w * 16, zone.h * 16)
		var name = "Food Stall"
		if stall.has_method("get_stall_def"):
			var fd = stall.get_stall_def()
			name = fd.get("name", "Food Stall")
		track_object(stall, rect, "stall", name)

func track_checkout(counter) -> void:
	if counter == null:
		return
	var pos = counter.global_position if counter.has_method("global_position") else counter.position
	var rect = Rect2(pos - Vector2(32, 24), Vector2(64, 48))
	var name = "Checkout"
	if counter.has_method("get_checkout_type"):
		var ct = counter.get_checkout_type()
		match ct:
			0: name = "Staffed"
			1: name = "Self-Checkout"
			2: name = "Express"
	track_object(counter, rect, "checkout", name)

func track_npc(npc) -> void:
	if npc == null:
		return
	var pos = npc.global_position if npc.has_method("global_position") else npc.position
	var rect = Rect2(pos - Vector2(12, 0), Vector2(24, 32))
	var name = "NPC"
	if npc.has_method("get_actor"):
		var actor = npc.get_actor()
		if actor != null:
			name = actor.display_name
	track_object(npc, rect, "npc", name)

func track_spawn_point(pos: Vector2, label: String = "") -> void:
	var rect = Rect2(pos - Vector2(16, 0), Vector2(32, 32))
	var obj = TrackedObject.new(null, rect, "spawn", label, COLORS.spawn)
	_tracked_objects.append(obj)
	if _debug_enabled:
		_draw_bounds_immediate(obj)

func clear_all() -> void:
	_tracked_objects.clear()
	_clear_debug_layers()

# ── Debug drawing ────────────────────────────────────────────────────────────

func _refresh_debug_view() -> void:
	_clear_debug_layers()
	if _debug_enabled:
		for tracked in _tracked_objects:
			if is_instance_valid(tracked.node) or tracked.object_type == "zone" or tracked.object_type == "spawn":
				_draw_bounds_immediate(tracked)

func _update_debug_view() -> void:
	# Update positions for tracked objects that are nodes
	for tracked in _tracked_objects:
		if tracked.node != null and is_instance_valid(tracked.node):
			if tracked.node.has_method("global_position"):
				var pos = tracked.node.global_position
				var size = tracked.bounds_rect.size
				tracked.bounds_rect.position = pos - size * 0.5

func _clear_debug_layers() -> void:
	for child in _bounds_layer.get_children():
		child.queue_free()
	for child in _labels_layer.get_children():
		child.queue_free()

func _draw_bounds_immediate(tracked: TrackedObject) -> void:
	# Draw wireframe box
	var rect = tracked.bounds_rect
	var points = [
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x, rect.position.y + rect.size.y),
	]
	
	# Draw 4 edges
	for i in range(4):
		var from = points[i]
		var to = points[(i + 1) % 4]
		_draw_line(from, to, tracked.color)
	
	# Draw corner dots
	for p in points:
		_draw_dot(p, tracked.color)
	
	# Draw center cross
	var center = rect.position + rect.size * 0.5
	_draw_line(center + Vector2(-4, 0), center + Vector2(4, 0), tracked.color)
	_draw_line(center + Vector2(0, -4), center + Vector2(0, 4), tracked.color)
	
	# Draw label
	if tracked.label != "":
		_draw_label(center + Vector2(0, -12), tracked.label, tracked.color)

func _draw_line(from: Vector2, to: Vector2, color: Color, width: float = 1.0) -> void:
	var line = Line2D.new()
	line.points = [from, to]
	line.default_color = color
	line.width = width
	line.z_index = 1000
	_bounds_layer.add_child(line)

func _draw_dot(pos: Vector2, color: Color, size: float = 3.0) -> void:
	var dot = ColorRect.new()
	dot.position = pos - Vector2(size * 0.5, size * 0.5)
	dot.size = Vector2(size, size)
	dot.color = color
	dot.z_index = 1001
	_bounds_layer.add_child(dot)

func _draw_label(pos: Vector2, text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.global_position = pos
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 10)
	label.z_index = 1002
	_labels_layer.add_child(label)

# ── Quick debug helpers ──────────────────────────────────────────────────────

func debug_floor_bounds(floor_idx: int) -> void:
	if _main == null:
		return
	var floor_builder = _main.get("_floor_builder")
	if floor_builder == null:
		return
	
	# Get floor Y offset
	var floor_y = floor_idx * 800 * 16  # 800 tiles per floor
	
	# Track all sections on this floor
	if floor_builder.has_method("get_sections"):
		for section in floor_builder.get_sections():
			track_section(section)
	
	# Track all food stalls
	if floor_builder.has_method("get_food_stalls"):
		for stall in floor_builder.get_food_stalls():
			track_stall(stall)
	
	# Track checkout counters
	var checkout_counters = _main.get("_checkout_counters")
	if checkout_counters:
		for counter in checkout_counters:
			track_checkout(counter)
	
	# Track NPCs
	var npcs = _main.get("_npcs")
	if npcs:
		for npc in npcs:
			track_npc(npc)
	
	# Track elevator
	var elevator = _main.get("_elevator")
	if elevator:
		track_elevator(elevator)
	
	# Mark floor boundary
	var floor_rect = Rect2(0, floor_y, 100 * 16, 800 * 16)  # 100x800 tile floor
	track_zone(0, floor_idx * 800, 100, 800, "Floor %d" % floor_idx)

func is_enabled() -> bool:
	return _debug_enabled
