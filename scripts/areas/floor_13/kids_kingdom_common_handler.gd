# kids_kingdom_common_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for common area on Floor 13 (Kids Kingdom)
# ─────────────────────────────────────────────────────────────────────────────
class_name KidsKingdomCommonHandler

const CELL_SIZE := 16

static func build_kids_kingdom_common(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build kids kingdom common area with colorful/playful atmosphere"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	# Light purple/pink for kids area
	base.color = Color(0.72, 0.58, 0.8, 0.2)
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add colorful floor pattern
	var colors := [
		Color(0.9, 0.6, 0.8, 0.15),  # Pink
		Color(0.6, 0.8, 0.9, 0.15),  # Blue
		Color(0.9, 0.9, 0.6, 0.15),  # Yellow
		Color(0.6, 0.9, 0.7, 0.15)   # Green
	]
	var color_idx := 0
	var tile_size := 6
	for y in range(zone.y, zone.y + zone.h, tile_size):
		for x in range(zone.x, zone.x + zone.w, tile_size):
			var tile := ColorRect.new()
			tile.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			tile.size = Vector2((tile_size - 1) * CELL_SIZE, (tile_size - 1) * CELL_SIZE)
			tile.color = colors[color_idx % colors.size()]
			parent.add_child(tile)
			floor_nodes.append(tile)
			color_idx += 1
