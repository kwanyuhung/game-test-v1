# service_area_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for service-related zones: Info Desk, Customer Service, 
# Loyalty Kiosk, Gift Wrap, Digital Kiosk
# ─────────────────────────────────────────────────────────────────────────────
class_name ServiceAreaHandler

const CELL_SIZE := 16

# Service zone types
enum ServiceType {
	INFO_DESK,
	CUSTOMER_SERVICE,
	LOYALTY_KIOSK,
	GIFT_WRAP,
	DIGITAL_KIOSK,
}

static func get_service_info(zone_type: String, meta: Dictionary) -> Dictionary:
	match zone_type:
		"ZONE_INFO_DESK":
			return {"name": "INFORMATION", "color": Color(0.55, 0.48, 0.40)}
		"ZONE_CUSTOMER_SERVICE":
			return {"name": meta.get("name", "CUSTOMER SERVICE"), "color": meta.get("color", Color(0.5, 0.55, 0.7))}
		"ZONE_LOYALTY_KIOSK":
			return {"name": meta.get("name", "LOYALTY CENTER"), "color": meta.get("color", Color(0.6, 0.5, 0.75))}
		"ZONE_GIFT_WRAP":
			return {"name": meta.get("name", "GIFT WRAPPING"), "color": meta.get("color", Color(0.72, 0.55, 0.7))}
		"ZONE_DIGITAL_KIOSK":
			return {"name": meta.get("name", "INFO KIOSK"), "color": meta.get("color", Color(0.4, 0.65, 0.8))}
		_:
			return {"name": "SERVICE", "color": Color(0.5, 0.5, 0.5)}

static func build_service_area(parent: Node, zone: Dictionary, floor_nodes: Array, zone_type: String) -> void:
	var meta: Dictionary = zone.get("meta", {})
	var info: Dictionary = get_service_info(zone_type, meta)
	
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	var zone_color: Color = info.color
	
	# Base floor
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.6)
	parent.add_child(bg)
	floor_nodes.append(bg)
	
	# Counter/desk area
	var desk := ColorRect.new()
	desk.position = Vector2(cx, cy + ch - 30)
	desk.size = Vector2(cw, 30)
	desk.color = zone_color.darkened(0.3)
	parent.add_child(desk)
	floor_nodes.append(desk)
	
	# Desk top edge
	var desk_top := ColorRect.new()
	desk_top.position = Vector2(cx, cy + ch - 30)
	desk_top.size = Vector2(cw, 3)
	desk_top.color = zone_color.lightened(0.2)
	parent.add_child(desk_top)
	floor_nodes.append(desk_top)
	
	# Header bar
	var header := ColorRect.new()
	header.position = Vector2(cx, cy)
	header.size = Vector2(cw, 20)
	header.color = zone_color.darkened(0.2)
	parent.add_child(header)
	floor_nodes.append(header)
	
	# Service name sign
	var sign_lbl := Label.new()
	sign_lbl.text = info.name
	sign_lbl.position = Vector2(cx + 8, cy + 4)
	sign_lbl.add_theme_color_override("font_color", zone_color.lightened(0.4))
	sign_lbl.add_theme_font_size_override("font_size", 9)
	parent.add_child(sign_lbl)
	floor_nodes.append(sign_lbl)
	
	# Add specific decorations based on service type
	match zone_type:
		"ZONE_INFO_DESK":
			_add_info_desk_extras(parent, floor_nodes, cx, cy, cw, ch, zone_color)
		"ZONE_LOYALTY_KIOSK":
			_add_loyalty_extras(parent, floor_nodes, cx, cy, cw, ch, zone_color)
		"ZONE_DIGITAL_KIOSK":
			_add_digital_kiosk_extras(parent, floor_nodes, cx, cy, cw, ch, zone_color)
		"ZONE_GIFT_WRAP":
			_add_gift_wrap_extras(parent, floor_nodes, cx, cy, cw, ch, zone_color)
	
	# "Press E to interact" hint
	var hint := Label.new()
	hint.text = "[E] Interact"
	hint.position = Vector2(cx + 8, cy + ch - 20)
	hint.add_theme_color_override("font_color", zone_color.lightened(0.3))
	hint.add_theme_font_size_override("font_size", 6)
	parent.add_child(hint)
	floor_nodes.append(hint)

static func _add_info_desk_extras(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Directory board
	var dir_bg := ColorRect.new()
	dir_bg.position = Vector2(cx + 20, cy + 30)
	dir_bg.size = Vector2(cw - 40, 50)
	dir_bg.color = Color(0.1, 0.1, 0.12)
	parent.add_child(dir_bg)
	floor_nodes.append(dir_bg)
	
	var dir_lbl := Label.new()
	dir_lbl.text = "F1: Shoes  F2: Fashion\nF3: Sport  F4: Outdoor\nF5: Stationery  F6: Staff"
	dir_lbl.position = Vector2(cx + 24, cy + 34)
	dir_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	dir_lbl.add_theme_font_size_override("font_size", 6)
	parent.add_child(dir_lbl)
	floor_nodes.append(dir_lbl)

static func _add_loyalty_extras(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Card reader icon
	var reader := ColorRect.new()
	reader.position = Vector2(cx + cw - 40, cy + 30)
	reader.size = Vector2(25, 35)
	reader.color = zone_color.darkened(0.3)
	parent.add_child(reader)
	floor_nodes.append(reader)
	
	var reader_screen := ColorRect.new()
	reader_screen.position = Vector2(cx + cw - 38, cy + 32)
	reader_screen.size = Vector2(21, 15)
	reader_screen.color = Color(0.2, 0.6, 0.8)
	parent.add_child(reader_screen)
	floor_nodes.append(reader_screen)
	
	var points_lbl := Label.new()
	points_lbl.text = "★ 2,450 pts"
	points_lbl.position = Vector2(cx + 10, cy + 35)
	points_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	points_lbl.add_theme_font_size_override("font_size", 7)
	parent.add_child(points_lbl)
	floor_nodes.append(points_lbl)

static func _add_digital_kiosk_extras(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Screen area
	var screen := ColorRect.new()
	screen.position = Vector2(cx + 10, cy + 25)
	screen.size = Vector2(cw - 20, ch - 60)
	screen.color = Color(0.1, 0.15, 0.2)
	parent.add_child(screen)
	floor_nodes.append(screen)
	
	# Touch icons
	var icon_colors := [Color(0.8, 0.3, 0.3), Color(0.3, 0.8, 0.3), Color(0.3, 0.3, 0.8), Color(0.8, 0.8, 0.3)]
	for i in range(4):
		var icon := ColorRect.new()
		icon.position = Vector2(cx + 15 + (i % 2) * 40, cy + 30 + int(i / 2) * 30)
		icon.size = Vector2(30, 25)
		icon.color = icon_colors[i]
		parent.add_child(icon)
		floor_nodes.append(icon)

static func _add_gift_wrap_extras(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Wrapping paper rolls
	var roll1 := ColorRect.new()
	roll1.position = Vector2(cx + 20, cy + 30)
	roll1.size = Vector2(25, 20)
	roll1.color = Color(0.8, 0.2, 0.2)  # Red
	parent.add_child(roll1)
	floor_nodes.append(roll1)
	
	var roll2 := ColorRect.new()
	roll2.position = Vector2(cx + 50, cy + 30)
	roll2.size = Vector2(25, 20)
	roll2.color = Color(0.2, 0.6, 0.3)  # Green
	parent.add_child(roll2)
	floor_nodes.append(roll2)
	
	var roll3 := ColorRect.new()
	roll3.position = Vector2(cx + 80, cy + 30)
	roll3.size = Vector2(25, 20)
	roll3.color = Color(0.3, 0.3, 0.8)  # Blue
	parent.add_child(roll3)
	floor_nodes.append(roll3)
	
	# Ribbon bow icon
	var bow := ColorRect.new()
	bow.position = Vector2(cx + cw - 50, cy + 35)
	bow.size = Vector2(30, 20)
	bow.color = Color(0.9, 0.7, 0.2)  # Gold
	parent.add_child(bow)
	floor_nodes.append(bow)