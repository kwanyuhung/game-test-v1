# locker_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for LOCKER zones on Floor 6 (Staff Area)
# Employee lockers for staff storage
# ─────────────────────────────────────────────────────────────────────────────
class_name LockerHandler

const CELL_SIZE := 16

static func build_locker(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "LOCKERS")
	var zone_color: Color = zone.meta.get("color", Color(0.50, 0.50, 0.55))
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
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.25))
	title_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(title_lbl); floor_nodes.append(title_lbl)

	# Add locker rows
	for row in range(4):
		var locker_y := cy + 16 + row * int(ch * 0.20)
		for col in range(8):
			var locker_x := cx + 12 + col * int((cw - 24) / 8.0)
			
			# Locker body
			var locker := ColorRect.new()
			locker.position = Vector2(locker_x, locker_y)
			locker.size = Vector2(10, 20)
			locker.color = zone_color.lightened(0.1)
			parent.add_child(locker); floor_nodes.append(locker)
			
			# Locker handle
			var handle := ColorRect.new()
			handle.position = Vector2(locker_x + 7, locker_y + 8)
			handle.size = Vector2(2, 4)
			handle.color = Color(0.3, 0.3, 0.3)
			parent.add_child(handle); floor_nodes.append(handle)