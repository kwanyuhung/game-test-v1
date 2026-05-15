# stationery_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for STATIONERY zones on Floor 5
# Displays stationery and office supplies
# ─────────────────────────────────────────────────────────────────────────────
class_name StationeryHandler

const CELL_SIZE := 16

static func build_stationery(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "STATIONERY")
	var zone_color: Color = zone.meta.get("color", Color(0.75, 0.78, 0.90))
	var cx :int= zone.x * CELL_SIZE
	var cy :int= zone.y * CELL_SIZE
	var cw :int= zone.w * CELL_SIZE
	var ch :int= zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35)
	parent.add_child(bg); floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.25))
	title_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(title_lbl); floor_nodes.append(title_lbl)

	# Add shelf displays for stationery items
	var shelf_colors := [Color(0.70, 0.72, 0.85), Color(0.65, 0.68, 0.80), Color(0.75, 0.75, 0.88)]
	for row in range(3):
		var shelf_y := cy + 20 + row * int(ch * 0.25)
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 8, shelf_y)
		plank.size = Vector2(cw - 16, 2)
		plank.color = shelf_colors[row % shelf_colors.size()]
		parent.add_child(plank); floor_nodes.append(plank)
		
		# Add small item rectangles to represent stationery
		for col in range(6):
			var item_x := cx + 12 + col * int((cw - 24) / 6.0)
			var item := ColorRect.new()
			item.position = Vector2(item_x, shelf_y - 12)
			item.size = Vector2(8, 10)
			item.color = zone_color.lightened(0.1 + (col % 3) * 0.1)
			parent.add_child(item); floor_nodes.append(item)