# juice_bar_common_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for common area on Floor 12 (Juice Bar)
# ─────────────────────────────────────────────────────────────────────────────
class_name JuiceBarCommonHandler

const CELL_SIZE := 16

static func build_juice_bar_common(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build juice bar common area with fresh/healthy atmosphere"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	# Light green/yellow for fresh healthy feel
	base.color = Color(0.55, 0.72, 0.58, 0.3)
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add floor tiles pattern
	var tile_size := 4
	for y in range(zone.y, zone.y + zone.h, tile_size):
		for x in range(zone.x, zone.x + zone.w, tile_size):
			var tile := ColorRect.new()
			tile.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			tile.size = Vector2((tile_size - 1) * CELL_SIZE, (tile_size - 1) * CELL_SIZE)
			tile.color = Color(0.5, 0.67, 0.53, 0.2)
			parent.add_child(tile)
			floor_nodes.append(tile)
