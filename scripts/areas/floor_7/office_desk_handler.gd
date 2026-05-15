# office_desk_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for OFFICE_DESK zones on Floor 7 (Back Office)
# Administrative office workstations
# ─────────────────────────────────────────────────────────────────────────────
class_name OfficeDeskHandler

const CELL_SIZE := 16

static func build_office_desk(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "OFFICE")
	var zone_color: Color = zone.meta.get("color", Color(0.50, 0.52, 0.58))
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

	# Add office desks in a grid pattern
	_add_office_desks(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_office_desks(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	for row in range(2):
		var desk_y := cy + 30 + row * int(ch * 0.35)
		for col in range(4):
			var desk_x := cx + 20 + col * int((cw - 40) / 4.0)
			
			# Desk
			var desk := ColorRect.new()
			desk.position = Vector2(desk_x, desk_y)
			desk.size = Vector2(24, 16)
			desk.color = Color(0.45, 0.42, 0.40)
			parent.add_child(desk); floor_nodes.append(desk)
			
			# Monitor on desk
			var monitor := ColorRect.new()
			monitor.position = Vector2(desk_x + 6, desk_y - 10)
			monitor.size = Vector2(12, 8)
			monitor.color = Color(0.20, 0.20, 0.25)
			parent.add_child(monitor); floor_nodes.append(monitor)