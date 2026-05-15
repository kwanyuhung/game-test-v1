# monitor_room_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for MONITOR_ROOM zones on Floor 7 (Back Office)
# Security and surveillance monitor room
# ─────────────────────────────────────────────────────────────────────────────
class_name MonitorRoomHandler

const CELL_SIZE := 16

static func build_monitor_room(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "MONITOR ROOM")
	var zone_color: Color = zone.meta.get("color", Color(0.40, 0.42, 0.50))
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

	# Add monitoring screens
	_add_monitoring_screens(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_monitoring_screens(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Large monitoring wall with multiple screens
	for row in range(2):
		for col in range(4):
			var screen_x := cx + 15 + col * int((cw - 30) / 4.0)
			var screen_y := cy + 25 + row * 35
			
			var screen := ColorRect.new()
			screen.position = Vector2(screen_x, screen_y)
			screen.size = Vector2(22, 28)
			screen.color = Color(0.10, 0.12, 0.15)
			parent.add_child(screen); floor_nodes.append(screen)
			
			# Screen glow
			var glow := ColorRect.new()
			glow.position = Vector2(screen_x + 2, screen_y + 2)
			glow.size = Vector2(18, 24)
			glow.color = Color(0.15, 0.35, 0.40)
			parent.add_child(glow); floor_nodes.append(glow)