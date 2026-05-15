# truck_dock_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Truck Dock zone on Floor 11
# ─────────────────────────────────────────────────────────────────────────────
class_name TruckDockHandler

const CELL_SIZE := 16

static func build_truck_dock(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build truck dock area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.5, 0.4, 0.3)  # Brownish for dock
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
