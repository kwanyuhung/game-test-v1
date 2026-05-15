# cafe_counter_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Cafe Counter zone on Floor 10 (Rooftop Cafe)
# ─────────────────────────────────────────────────────────────────────────────
class_name CafeCounterHandler

const CELL_SIZE := 16

static func build_cafe_counter(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build cafe counter area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.color = Color(0.75, 0.55, 0.35)  # Warm wood color for cafe
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add counter top details
	var counter_top := ColorRect.new()
	counter_top.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	counter_top.size = Vector2(zone.w * CELL_SIZE, 2 * CELL_SIZE)
	counter_top.color = Color(0.85, 0.65, 0.45)
	parent.add_child(counter_top)
	floor_nodes.append(counter_top)
	
	# Add name label if meta exists
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)
