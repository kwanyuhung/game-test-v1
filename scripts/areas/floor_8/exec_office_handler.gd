# exec_office_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for EXEC_OFFICE zones on Floor 8 (Executive Office)
# Executive private offices
# ─────────────────────────────────────────────────────────────────────────────
class_name ExecOfficeHandler

const CELL_SIZE := 16

static func build_exec_office(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "EXEC OFFICE")
	var zone_color: Color = zone.meta.get("color", Color(0.45, 0.42, 0.50))
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

	# Add executive office furniture
	_add_exec_furniture(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_exec_furniture(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Large executive desk
	var desk := ColorRect.new()
	desk.position = Vector2(cx + cw/2 - 30, cy + 30)
	desk.size = Vector2(60, 25)
	desk.color = Color(0.35, 0.30, 0.35)
	parent.add_child(desk); floor_nodes.append(desk)
	
	# Executive chair
	var chair := ColorRect.new()
	chair.position = Vector2(cx + cw/2 - 15, cy + 55)
	chair.size = Vector2(30, 20)
	chair.color = Color(0.25, 0.22, 0.28)
	parent.add_child(chair); floor_nodes.append(chair)
	
	# Side table
	var side_table := ColorRect.new()
	side_table.position = Vector2(cx + cw - 40, cy + 30)
	side_table.size = Vector2(20, 15)
	side_table.color = Color(0.40, 0.35, 0.40)
	parent.add_child(side_table); floor_nodes.append(side_table)