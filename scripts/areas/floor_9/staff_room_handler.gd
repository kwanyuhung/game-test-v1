# staff_room_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for STAFF_ROOM zones on Floor 9 (Staff Room)
# Staff room with lockers and price management terminal
# ─────────────────────────────────────────────────────────────────────────────
class_name StaffRoomHandler

const CELL_SIZE := 16

static func build_staff_room(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "STAFF ROOM")
	var zone_color: Color = zone.meta.get("color", Color(0.45, 0.48, 0.55))
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

	# Add staff room elements
	_add_staff_room_elements(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_staff_room_elements(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Price management terminal
	var terminal_bg := ColorRect.new()
	terminal_bg.position = Vector2(cx + 30, cy + 30)
	terminal_bg.size = Vector2(35, 40)
	terminal_bg.color = Color(0.30, 0.32, 0.38)
	parent.add_child(terminal_bg); floor_nodes.append(terminal_bg)
	
	var terminal_screen := ColorRect.new()
	terminal_screen.position = Vector2(cx + 33, cy + 33)
	terminal_screen.size = Vector2(29, 25)
	terminal_screen.color = Color(0.15, 0.35, 0.25)
	parent.add_child(terminal_screen); floor_nodes.append(terminal_screen)
	
	# Keyboard area
	var keyboard := ColorRect.new()
	keyboard.position = Vector2(cx + 35, cy + 60)
	keyboard.size = Vector2(25, 6)
	keyboard.color = Color(0.40, 0.42, 0.45)
	parent.add_child(keyboard); floor_nodes.append(keyboard)