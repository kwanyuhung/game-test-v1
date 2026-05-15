# electronics_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Electronics zones on Floor 14
# ─────────────────────────────────────────────────────────────────────────────
class_name ElectronicsHandler

const CELL_SIZE := 16

static func build_phone_gadgets(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build phone and gadgets area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.35, 0.55, 0.8)  # Blue for phones/gadgets
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add display shelves
	var shelf_spacing := 6
	for y in range(zone.y + 2, zone.y + zone.h - 2, shelf_spacing):
		var shelf := ColorRect.new()
		shelf.position = Vector2(zone.x * CELL_SIZE, y * CELL_SIZE)
		shelf.size = Vector2(zone.w * CELL_SIZE, 1 * CELL_SIZE)
		shelf.color = Color(0.25, 0.45, 0.7)
		parent.add_child(shelf)
		floor_nodes.append(shelf)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)

static func build_smart_home(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build smart home area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.4, 0.6, 0.7)  # Teal for smart home
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)

static func build_electronics(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build general electronics area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.45, 0.5, 0.65)  # Blue-gray for electronics
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add display counters
	var counter_spacing := 8
	for x in range(zone.x + 4, zone.x + zone.w - 4, counter_spacing):
		var counter := ColorRect.new()
		counter.position = Vector2(x * CELL_SIZE, zone.y + 2 * CELL_SIZE)
		counter.size = Vector2(4 * CELL_SIZE, 4 * CELL_SIZE)
		counter.color = Color(0.35, 0.4, 0.55)
		parent.add_child(counter)
		floor_nodes.append(counter)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)

static func build_repair_counter(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build repair counter area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.6, 0.45, 0.4)  # Brown for repair area
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add counter top
	var counter := ColorRect.new()
	counter.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	counter.size = Vector2(zone.w * CELL_SIZE, 2 * CELL_SIZE)
	counter.color = Color(0.5, 0.35, 0.3)
	parent.add_child(counter)
	floor_nodes.append(counter)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)
