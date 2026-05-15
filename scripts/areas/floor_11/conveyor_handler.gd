# conveyor_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Conveyor zone on Floor 11
# ─────────────────────────────────────────────────────────────────────────────
class_name ConveyorHandler

const CELL_SIZE := 16

static func build_conveyor(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build conveyor belt area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.6, 0.6, 0.65)  # Metallic gray
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add conveyor belt lines
	var belt_spacing := 4
	for x in range(zone.x + 2, zone.x + zone.w - 2, belt_spacing):
		var belt_line := ColorRect.new()
		belt_line.position = Vector2(x * CELL_SIZE, zone.y * CELL_SIZE)
		belt_line.size = Vector2(2, zone.h * CELL_SIZE)
		belt_line.color = Color(0.4, 0.4, 0.45)
		parent.add_child(belt_line)
		floor_nodes.append(belt_line)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)
