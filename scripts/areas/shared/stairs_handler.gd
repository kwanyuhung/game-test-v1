# stairs_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for STAIRS zones - staircase visualization
# ─────────────────────────────────────────────────────────────────────────────
class_name StairsHandler

const CELL_SIZE := 16

static func build_stairs(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Main stairs background
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = Color(0.28, 0.26, 0.24)
	parent.add_child(bg)
	floor_nodes.append(bg)
	
	# Draw stairs steps.
	# Old impl hardcoded 12 steps regardless of zone height — at 4 tiles tall
	# (64px) that gave ~5px steps with 1px depth, unreadable. Scale instead so
	# each step is ~8px tall (one half-tile) with a 3-step minimum.
	var n_steps: int = max(3, ch / 8)
	var step_h: int = max(2, ch / n_steps)
	var step_color_normal := Color(0.45, 0.42, 0.38)
	var step_color_dark := Color(0.35, 0.32, 0.28)
	
	for i in range(n_steps):
		var step_y: int = cy + i * step_h
		var step_l := ColorRect.new()
		step_l.position = Vector2(cx, step_y)
		step_l.size = Vector2(cw, 2)
		step_l.color = step_color_normal if i % 2 == 0 else step_color_dark
		parent.add_child(step_l)
		floor_nodes.append(step_l)
		
		# Step depth indicator
		var step_depth := ColorRect.new()
		step_depth.position = Vector2(cx, step_y + 2)
		step_depth.size = Vector2(cw, step_h - 4)
		step_depth.color = step_color_dark if i % 2 == 0 else step_color_normal.darkened(0.1)
		parent.add_child(step_depth)
		floor_nodes.append(step_depth)
	
	# Handrail left
	var rail_left := ColorRect.new()
	rail_left.position = Vector2(cx, cy)
	rail_left.size = Vector2(2, ch)
	rail_left.color = Color(0.55, 0.50, 0.45)
	parent.add_child(rail_left)
	floor_nodes.append(rail_left)
	
	# Handrail right
	var rail_right := ColorRect.new()
	rail_right.position = Vector2(cx + cw - 2, cy)
	rail_right.size = Vector2(2, ch)
	rail_right.color = Color(0.50, 0.47, 0.42)
	parent.add_child(rail_right)
	floor_nodes.append(rail_right)
	
	# "STAIRS" label
	var lbl := Label.new()
	lbl.text = "STAIRS"
	lbl.position = Vector2(cx + 0.5 * CELL_SIZE, cy + 1 * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
	lbl.add_theme_font_size_override("font_size", 7)
	parent.add_child(lbl)
	floor_nodes.append(lbl)
	
	# Direction indicators
	_add_direction_arrows(parent, floor_nodes, cx, cy, cw, ch)

static func _add_direction_arrows(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int) -> void:
	# Up arrow at top
	var arrow_up := Label.new()
	arrow_up.text = "▲ GO UP"
	arrow_up.position = Vector2(cx + 0.5 * CELL_SIZE, cy + ch - 20)
	arrow_up.add_theme_color_override("font_color", Color(0.50, 0.80, 0.50))
	arrow_up.add_theme_font_size_override("font_size", 5)
	parent.add_child(arrow_up)
	floor_nodes.append(arrow_up)
	
	# Down arrow at bottom
	var arrow_down := Label.new()
	arrow_down.text = "▼ GO DOWN"
	arrow_down.position = Vector2(cx + 0.5 * CELL_SIZE, cy + ch - 10)
	arrow_down.add_theme_color_override("font_color", Color(0.80, 0.50, 0.50))
	arrow_down.add_theme_font_size_override("font_size", 5)
	parent.add_child(arrow_down)
	floor_nodes.append(arrow_down)