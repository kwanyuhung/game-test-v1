# elevator_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for ELEVATOR zones - elevator shaft visualization
# ─────────────────────────────────────────────────────────────────────────────
class_name ElevatorHandler

const CELL_SIZE := 16

static func build_elevator(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Main shaft background
	var shaft := ColorRect.new()
	shaft.position = Vector2(cx, cy)
	shaft.size = Vector2(cw, ch)
	shaft.color = Color(0.30, 0.27, 0.25)
	parent.add_child(shaft)
	floor_nodes.append(shaft)
	
	# Left wall
	var bl := ColorRect.new()
	bl.position = Vector2(cx, cy)
	bl.size = Vector2(2, ch)
	bl.color = Color(0.50, 0.45, 0.40)
	parent.add_child(bl)
	floor_nodes.append(bl)
	
	# Right wall
	var br := ColorRect.new()
	br.position = Vector2(cx + cw - 2, cy)
	br.size = Vector2(2, ch)
	br.color = Color(0.40, 0.37, 0.35)
	parent.add_child(br)
	floor_nodes.append(br)
	
	# Add elevator door frame
	var door_frame := ColorRect.new()
	door_frame.position = Vector2(cx + cw / 2 - 8, cy + 10)
	door_frame.size = Vector2(16, 30)
	door_frame.color = Color(0.45, 0.42, 0.38)
	parent.add_child(door_frame)
	floor_nodes.append(door_frame)
	
	# Door left panel
	var door_left := ColorRect.new()
	door_left.position = Vector2(cx + cw / 2 - 6, cy + 12)
	door_left.size = Vector2(6, 26)
	door_left.color = Color(0.55, 0.52, 0.48)
	parent.add_child(door_left)
	floor_nodes.append(door_left)
	
	# Door right panel
	var door_right := ColorRect.new()
	door_right.position = Vector2(cx + cw / 2 + 2, cy + 12)
	door_right.size = Vector2(6, 26)
	door_right.color = Color(0.55, 0.52, 0.48)
	parent.add_child(door_right)
	floor_nodes.append(door_right)
	
	# Elevator indicator light
	var indicator := ColorRect.new()
	indicator.position = Vector2(cx + cw / 2 - 3, cy + 4)
	indicator.size = Vector2(6, 4)
	indicator.color = Color(0.2, 0.85, 0.45)  # Green light
	parent.add_child(indicator)
	floor_nodes.append(indicator)
	
	# Floor indicator arrows
	var arrow_up := Label.new()
	arrow_up.text = "^"
	arrow_up.position = Vector2(cx + cw / 2 - 2, cy + 5)
	arrow_up.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	arrow_up.add_theme_font_size_override("font_size", 8)
	parent.add_child(arrow_up)
	floor_nodes.append(arrow_up)

static func build_elevator_call_button(parent: Node, zone: Dictionary, floor_nodes: Array, floor_label: String = "G") -> void:
	"""Build elevator call button panel"""
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	
	# Button panel background
	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(cx - 4, cy + 20)
	panel_bg.size = Vector2(12, 20)
	panel_bg.color = Color(0.25, 0.25, 0.28)
	parent.add_child(panel_bg)
	floor_nodes.append(panel_bg)
	
	# Up button
	var btn_up := ColorRect.new()
	btn_up.position = Vector2(cx - 2, cy + 22)
	btn_up.size = Vector2(8, 6)
	btn_up.color = Color(0.4, 0.8, 0.4)
	parent.add_child(btn_up)
	floor_nodes.append(btn_up)
	
	# Down button
	var btn_down := ColorRect.new()
	btn_down.position = Vector2(cx - 2, cy + 30)
	btn_down.size = Vector2(8, 6)
	btn_down.color = Color(0.8, 0.4, 0.4)
	parent.add_child(btn_down)
	floor_nodes.append(btn_down)
	
	# Floor label
	var lbl := Label.new()
	lbl.text = floor_label
	lbl.position = Vector2(cx - 1, cy + 38)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lbl.add_theme_font_size_override("font_size", 6)
	parent.add_child(lbl)
	floor_nodes.append(lbl)