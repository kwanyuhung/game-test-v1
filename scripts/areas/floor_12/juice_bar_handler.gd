# juice_bar_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Juice Bar zones on Floor 12
# ─────────────────────────────────────────────────────────────────────────────
class_name JuiceBarHandler

const CELL_SIZE := 16

static func build_juice_bar(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build juice bar area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(1.0, 0.75, 0.3)  # Orange/yellow for juice bar
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add counter top
	var counter := ColorRect.new()
	counter.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	counter.size = Vector2(zone.w * CELL_SIZE, 2 * CELL_SIZE)
	counter.color = Color(0.9, 0.65, 0.2)
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

static func build_health_food(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build health food area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.55, 0.82, 0.58)  # Green for health food
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

static func build_smoothie(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build smoothie station area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.8, 0.55, 0.8)  # Pink/purple for smoothie
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add counter top
	var counter := ColorRect.new()
	counter.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	counter.size = Vector2(zone.w * CELL_SIZE, 2 * CELL_SIZE)
	counter.color = Color(0.7, 0.45, 0.7)
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

static func build_salad_bar(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build salad bar area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.6, 0.85, 0.6)  # Light green for salad
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
