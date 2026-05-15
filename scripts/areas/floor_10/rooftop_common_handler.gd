# rooftop_common_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for common area on Floor 10 (Rooftop Cafe)
# ─────────────────────────────────────────────────────────────────────────────
class_name RooftopCommonHandler

const CELL_SIZE := 16

static func build_rooftop_common(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build rooftop common area with sky/ambient feel"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	# Sky blue-ish color for rooftop atmosphere
	base.color = Color(0.65, 0.75, 0.85)
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add subtle floor pattern for outdoor cafe feel
	var floor_pattern := ColorRect.new()
	floor_pattern.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	floor_pattern.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	floor_pattern.color = Color(0.60, 0.70, 0.80, 0.3)  # Slightly transparent overlay
	parent.add_child(floor_pattern)
	floor_nodes.append(floor_pattern)
