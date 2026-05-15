# staff_lounge_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for STAFF_LOUNGE zones on Floor 6 (Staff Area)
# Employee break room and lounge
# ─────────────────────────────────────────────────────────────────────────────
class_name StaffLoungeHandler

const CELL_SIZE := 16

static func build_staff_lounge(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "STAFF LOUNGE")
	var zone_color: Color = zone.meta.get("color", Color(0.45, 0.48, 0.52))
	var cx :int= zone.x * CELL_SIZE
	var cy :int= zone.y * CELL_SIZE
	var cw :int= zone.w * CELL_SIZE
	var ch :int= zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4)
	parent.add_child(bg); floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	title_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(title_lbl); floor_nodes.append(title_lbl)

	# Add lounge furniture (simple tables and chairs)
	_add_lounge_furniture(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_lounge_furniture(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Add some tables with chairs
	for i in range(3):
		var table_x := cx + 30 + i * int(cw * 0.28)
		var table_y := cy + int(ch * 0.4)
		
		# Table
		var table := ColorRect.new()
		table.position = Vector2(table_x, table_y)
		table.size = Vector2(30, 20)
		table.color = Color(0.45, 0.42, 0.38)
		parent.add_child(table); floor_nodes.append(table)
		
		# Chairs around table
		var chair_positions := [Vector2(-20, 0), Vector2(30, 0), Vector2(0, -20), Vector2(0, 20)]
		for chair_pos in chair_positions:
			var chair := ColorRect.new()
			chair.position = Vector2(table_x + chair_pos.x, table_y + chair_pos.y)
			chair.size = Vector2(14, 14)
			chair.color = Color(0.55, 0.52, 0.48)
			parent.add_child(chair); floor_nodes.append(chair)