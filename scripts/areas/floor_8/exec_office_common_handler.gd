# exec_office_common_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for COMMON zones on Floor 8 (Executive Office)
# General walking/floor areas with executive office styling
# ─────────────────────────────────────────────────────────────────────────────
class_name ExecOfficeCommonHandler

const CELL_SIZE := 16

static func build_exec_office_common(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var cx: int = zone.x * CELL_SIZE
	var cy: int = zone.y * CELL_SIZE
	var cw: int = zone.w * CELL_SIZE
	var ch: int = zone.h * CELL_SIZE
	
	# Base floor with elegant executive feel
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = Color(0.20, 0.20, 0.24)
	parent.add_child(bg)
	floor_nodes.append(bg)
	
	# Subtle floor pattern
	var tile_color := Color(0.18, 0.18, 0.22)
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