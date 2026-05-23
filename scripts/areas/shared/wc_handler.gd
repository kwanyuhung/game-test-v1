# wc_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for WC (Restroom) zones
# ─────────────────────────────────────────────────────────────────────────────
class_name WCHandler

const CELL_SIZE := 16

static func build_wc(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Main floor
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = Color(0.18, 0.20, 0.24)
	parent.add_child(bg)
	floor_nodes.append(bg)
	
	# Door
	var door := ColorRect.new()
	door.position = Vector2(cx + 32, cy + ch - 48)
	door.size = Vector2(32, 48)
	door.color = Color(0.50, 0.48, 0.55)
	parent.add_child(door)
	floor_nodes.append(door)
	
	# Door handle
	var handle := ColorRect.new()
	handle.position = Vector2(cx + 56, cy + ch - 30)
	handle.size = Vector2(6, 10)
	handle.color = Color(0.7, 0.7, 0.6)
	parent.add_child(handle)
	floor_nodes.append(handle)
	
	# WC sign
	var lbl := Label.new()
	lbl.text = "WC"
	lbl.position = Vector2(cx + cw / 2 - 12, cy + 16)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	floor_nodes.append(lbl)
	
	# "Press E to use" hint
	var hint := Label.new()
	hint.text = "[E] Use"
	hint.position = Vector2(cx + 16, cy + ch - 40)
	hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.60))
	hint.add_theme_font_size_override("font_size", 7)
	parent.add_child(hint)
	floor_nodes.append(hint)
	
	# Wall borders
	var wall_color := Color(0.38, 0.35, 0.32)
	
	# Top wall
	var top_w := ColorRect.new()
	top_w.position = Vector2(cx, cy)
	top_w.size = Vector2(cw, 4)
	top_w.color = wall_color
	parent.add_child(top_w)
	floor_nodes.append(top_w)
	
	# Bottom wall
	var bot_w := ColorRect.new()
	bot_w.position = Vector2(cx, cy + ch - 4)
	bot_w.size = Vector2(cw, 4)
	bot_w.color = wall_color.darkened(0.2)
	parent.add_child(bot_w)
	floor_nodes.append(bot_w)
	
	# Left wall
	var l_w := ColorRect.new()
	l_w.position = Vector2(cx, cy)
	l_w.size = Vector2(4, ch)
	l_w.color = wall_color.darkened(0.1)
	parent.add_child(l_w)
	floor_nodes.append(l_w)
	
	# Right wall
	var r_w := ColorRect.new()
	r_w.position = Vector2(cx + cw - 4, cy)
	r_w.size = Vector2(4, ch)
	r_w.color = wall_color.darkened(0.2)
	parent.add_child(r_w)
	floor_nodes.append(r_w)
	
	# Toilet icon (simple)
	var toilet := ColorRect.new()
	toilet.position = Vector2(cx + 100, cy + 30)
	toilet.size = Vector2(24, 30)
	toilet.color = Color(0.9, 0.9, 0.92)
	parent.add_child(toilet)
	floor_nodes.append(toilet)
