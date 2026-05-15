# electronics_common_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for common area on Floor 14 (Electronics)
# ─────────────────────────────────────────────────────────────────────────────
class_name ElectronicsCommonHandler

const CELL_SIZE := 16

static func build_electronics_common(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build electronics common area with tech atmosphere"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	# Dark blue-gray for tech feel
	base.color = Color(0.35, 0.45, 0.65)
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add subtle grid pattern
	var grid_size := 8
	for y in range(zone.y, zone.y + zone.h, grid_size):
		var h_line := ColorRect.new()
		h_line.position = Vector2(zone.x * CELL_SIZE, y * CELL_SIZE)
		h_line.size = Vector2(zone.w * CELL_SIZE, 1)
		h_line.color = Color(0.25, 0.35, 0.55, 0.5)
		parent.add_child(h_line)
		floor_nodes.append(h_line)
	
	for x in range(zone.x, zone.x + zone.w, grid_size):
		var v_line := ColorRect.new()
		v_line.position = Vector2(x * CELL_SIZE, zone.y * CELL_SIZE)
		v_line.size = Vector2(1, zone.h * CELL_SIZE)
		v_line.color = Color(0.25, 0.35, 0.55, 0.5)
		parent.add_child(v_line)
		floor_nodes.append(v_line)
