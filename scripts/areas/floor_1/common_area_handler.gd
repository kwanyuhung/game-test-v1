# common_area_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for COMMON zones - general walking/floor areas
# ─────────────────────────────────────────────────────────────────────────────
class_name CommonAreaHandler

const CELL_SIZE := 16

static func build_common_area(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Base floor
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = Color(0.20, 0.19, 0.18)
	parent.add_child(bg)
	floor_nodes.append(bg)
	
	# Add subtle floor pattern (tile lines)
	var tile_color := Color(0.18, 0.17, 0.16)
	var tile_size: int = CELL_SIZE * 4
	
	for ty in range(cy, cy + ch, tile_size):
		var line_h := ColorRect.new()
		line_h.position = Vector2(cx, ty)
		line_h.size = Vector2(cw, 1)
		line_h.color = tile_color
		parent.add_child(line_h)
		floor_nodes.append(line_h)
	
	for tx in range(cx, cx + cw, tile_size):
		var line_v := ColorRect.new()
		line_v.position = Vector2(tx, cy)
		line_v.size = Vector2(1, ch)
		line_v.color = tile_color
		parent.add_child(line_v)
		floor_nodes.append(line_v)
	
	# Add ambient lighting effect at edges
	var edge_light := ColorRect.new()
	edge_light.position = Vector2(cx, cy)
	edge_light.size = Vector2(cw, 2)
	edge_light.color = Color(0.25, 0.24, 0.22, 0.5)
	parent.add_child(edge_light)
	floor_nodes.append(edge_light)

static func build_floor_path(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build pathway lines on the common floor area"""
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Center aisle line
	var aisle_color := Color(0.22, 0.21, 0.20, 0.6)
	
	# Horizontal center aisle
	var center_aisle_h := ColorRect.new()
	center_aisle_h.position = Vector2(cx, cy + ch / 2 - 2)
	center_aisle_h.size = Vector2(cw, 4)
	center_aisle_h.color = aisle_color
	parent.add_child(center_aisle_h)
	floor_nodes.append(center_aisle_h)
	
	# Vertical aisle (if zone is wide enough)
	if cw > ch:
		var center_aisle_v := ColorRect.new()
		center_aisle_v.position = Vector2(cx + cw / 2 - 2, cy)
		center_aisle_v.size = Vector2(4, ch)
		center_aisle_v.color = aisle_color
		parent.add_child(center_aisle_v)
		floor_nodes.append(center_aisle_v)