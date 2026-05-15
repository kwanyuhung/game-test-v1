# warehouse_floor_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Warehouse zones on Floor 11
# ─────────────────────────────────────────────────────────────────────────────
class_name WarehouseFloorHandler

const CELL_SIZE := 16

static func build_warehouse(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build main warehouse area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.color = Color(0.45, 0.38, 0.32)  # Industrial concrete color
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add warehouse floor pattern (shelf lines)
	for i in range(zone.y + 2, zone.y + zone.h - 2, 4):
		var line := ColorRect.new()
		line.position = Vector2(zone.x * CELL_SIZE, i * CELL_SIZE)
		line.size = Vector2(zone.w * CELL_SIZE, 1)
		line.color = Color(0.35, 0.28, 0.22)
		parent.add_child(line)
		floor_nodes.append(line)

static func build_forklift_zone(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build forklift zone area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	# Yellow-ish for forklift/equipment area
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.75, 0.6, 0.2)
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

static func build_packing_station(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build packing station area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.4, 0.65, 0.45)  # Green-ish for packing
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
