# warehouse_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for WAREHOUSE zone on Ground Floor
# Warehouse floor with shelves, truck dock, forklift zone, conveyor belt
# ─────────────────────────────────────────────────────────────────────────────
class_name WarehouseHandler

const CELL_SIZE := 16

# Warehouse zone types
enum WarehouseType {
	WAREHOUSE_FLOOR,
	TRUCK_DOCK,
	FORKLIFT_ZONE,
	CONVEYOR,
	STORAGE_SHELF,
	STOCK_VIEW,
}

static func build_warehouse_area(parent: Node, zone: Dictionary, floor_nodes: Array, area_type: String) -> void:
	var meta: Dictionary = zone.get("meta", {})
	var zone_name: String = meta.get("name", "WAREHOUSE")
	var zone_color: Color = meta.get("color", Color(0.55, 0.45, 0.38))
	
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	match area_type:
		"ZONE_WAREHOUSE":
			_build_warehouse_floor(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_TRUCK_DOCK":
			_build_truck_dock(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_FORKLIFT":
			_build_forklift_zone(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_CONVEYOR":
			_build_conveyor(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_STORAGE_SHELF":
			_build_storage_shelf(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_WAREHOUSE_STOCK_VIEW":
			_build_stock_view(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)

static func _build_warehouse_floor(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# Main warehouse floor
	var floor_bg := ColorRect.new()
	floor_bg.position = Vector2(cx, cy)
	floor_bg.size = Vector2(cw, ch)
	floor_bg.color = Color(0.38, 0.32, 0.26)
	parent.add_child(floor_bg)
	floor_nodes.append(floor_bg)
	
	# Grid lines
	for gx in range(cx, cx + cw, CELL_SIZE * 4):
		var line := ColorRect.new()
		line.position = Vector2(gx, cy)
		line.size = Vector2(2, ch)
		line.color = Color(0.32, 0.28, 0.22)
		parent.add_child(line)
		floor_nodes.append(line)
	
	# Warehouse name sign
	var recv_lbl := Label.new()
	recv_lbl.text = zone_name
	recv_lbl.position = Vector2(cx + 8, cy - 14)
	recv_lbl.add_theme_color_override("font_color", zone_color.lightened(0.2))
	recv_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(recv_lbl)
	floor_nodes.append(recv_lbl)
	
	# Add shelves
	var shelf_colors := [Color(0.50, 0.42, 0.32), Color(0.45, 0.38, 0.28), Color(0.52, 0.44, 0.34)]
	for rack in range(3):
		var rx: int = cx + 80 + rack * int(cw * 0.22)
		var rack_h: int = int(ch * 0.85)
		var rack_bg := ColorRect.new()
		rack_bg.position = Vector2(rx, cy + 20)
		rack_bg.size = Vector2(int(cw * 0.18), rack_h)
		rack_bg.color = shelf_colors[rack % shelf_colors.size()]
		parent.add_child(rack_bg)
		floor_nodes.append(rack_bg)
		
		for row in range(5):
			var shelf_y: int = cy + 20 + row * int(rack_h / 5.5)
			var shelf_plank := ColorRect.new()
			shelf_plank.position = Vector2(rx + 4, shelf_y)
			shelf_plank.size = Vector2(int(cw * 0.18) - 8, 3)
			shelf_plank.color = Color(0.35, 0.28, 0.20)
			parent.add_child(shelf_plank)
			floor_nodes.append(shelf_plank)

static func _build_truck_dock(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# Dock floor
	var dock := ColorRect.new()
	dock.position = Vector2(cx, cy)
	dock.size = Vector2(cw, ch)
	dock.color = Color(0.25, 0.22, 0.18)
	parent.add_child(dock)
	floor_nodes.append(dock)
	
	# Safety stripes
	for st in range(0, ch, 16):
		var stripe := ColorRect.new()
		stripe.position = Vector2(cx, cy + st)
		stripe.size = Vector2(cw, 8)
		stripe.color = Color(0.85, 0.72, 0.20) if (st / 16 % 2 == 0) else Color(0.15, 0.12, 0.08)
		parent.add_child(stripe)
		floor_nodes.append(stripe)
	
	# Dock label
	var dock_lbl := Label.new()
	dock_lbl.text = zone_name
	dock_lbl.position = Vector2(cx + 8, cy - 14)
	dock_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	dock_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(dock_lbl)
	floor_nodes.append(dock_lbl)

static func _build_forklift_zone(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# Zone floor
	var zone_bg := ColorRect.new()
	zone_bg.position = Vector2(cx, cy)
	zone_bg.size = Vector2(cw, ch)
	zone_bg.color = zone_color.darkened(0.5)
	parent.add_child(zone_bg)
	floor_nodes.append(zone_bg)
	
	# Hazard markings
	var hazard := Label.new()
	hazard.text = "⚠ " + zone_name + " ⚠"
	hazard.position = Vector2(cx + 8, cy + 8)
	hazard.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	hazard.add_theme_font_size_override("font_size", 8)
	parent.add_child(hazard)
	floor_nodes.append(hazard)
	
	# Forklift icon
	var forklift := ColorRect.new()
	forklift.position = Vector2(cx + cw / 2 - 20, cy + ch / 2 - 15)
	forklift.size = Vector2(40, 30)
	forklift.color = Color(0.9, 0.7, 0.2)
	parent.add_child(forklift)
	floor_nodes.append(forklift)
	
	# Forks
	var forks := ColorRect.new()
	forks.position = Vector2(cx + cw / 2 + 15, cy + ch / 2 - 5)
	forks.size = Vector2(20, 6)
	forks.color = Color(0.5, 0.5, 0.5)
	parent.add_child(forks)
	floor_nodes.append(forks)

static func _build_conveyor(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# Conveyor base
	var conveyor := ColorRect.new()
	conveyor.position = Vector2(cx, cy)
	conveyor.size = Vector2(cw, ch)
	conveyor.color = Color(0.45, 0.45, 0.50)
	parent.add_child(conveyor)
	floor_nodes.append(conveyor)
	
	# Conveyor belt lines (moving effect)
	var belt_color := Color(0.35, 0.35, 0.40)
	for i in range(0, cw, 20):
		var line := ColorRect.new()
		line.position = Vector2(cx + i, cy)
		line.size = Vector2(10, ch)
		line.color = belt_color
		parent.add_child(line)
		floor_nodes.append(line)
	
	# Belt arrows (direction)
	var arrow_lbl := Label.new()
	arrow_lbl.text = "→ → →"
	arrow_lbl.position = Vector2(cx + cw / 2 - 20, cy + ch / 2 - 6)
	arrow_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	arrow_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(arrow_lbl)
	floor_nodes.append(arrow_lbl)
	
	# Label
	var conv_lbl := Label.new()
	conv_lbl.text = zone_name
	conv_lbl.position = Vector2(cx + 8, cy - 14)
	conv_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	conv_lbl.add_theme_font_size_override("font_size", 9)
	parent.add_child(conv_lbl)
	floor_nodes.append(conv_lbl)

static func _build_storage_shelf(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# Shelf base
	var base := ColorRect.new()
	base.color = zone_color
	base.size = Vector2(cw, ch)
	base.position = Vector2(cx, cy)
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Shelf rows
	for row in range(0, ch, 20):
		var line := ColorRect.new()
		line.color = Color(0.45, 0.38, 0.30)
		line.size = Vector2(cw, 3)
		line.position = Vector2(cx, cy + row)
		parent.add_child(line)
		floor_nodes.append(line)
	
	# Label
	var shelf_lbl := Label.new()
	shelf_lbl.text = zone_name
	shelf_lbl.position = Vector2(cx + 8, cy - 14)
	shelf_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	shelf_lbl.add_theme_font_size_override("font_size", 9)
	parent.add_child(shelf_lbl)
	floor_nodes.append(shelf_lbl)

static func _build_stock_view(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# View screen background
	var screen := ColorRect.new()
	screen.position = Vector2(cx, cy)
	screen.size = Vector2(cw, ch)
	screen.color = Color(0.15, 0.18, 0.15)
	parent.add_child(screen)
	floor_nodes.append(screen)
	
	# Stock bars
	var stock_data := [85, 62, 45, 78, 55, 92, 40, 70]
	for i in range(stock_data.size()):
		var bar_h: int = int(stock_data[i] * ch / 100)
		var bar := ColorRect.new()
		bar.position = Vector2(cx + 10 + i * 12, cy + ch - bar_h - 10)
		bar.size = Vector2(10, bar_h)
		bar.color = zone_color.lightened(0.2 + (i % 3) * 0.15)
		parent.add_child(bar)
		floor_nodes.append(bar)
	
	# Label
	var view_lbl := Label.new()
	view_lbl.text = zone_name
	view_lbl.position = Vector2(cx + 8, cy + 8)
	view_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	view_lbl.add_theme_font_size_override("font_size", 7)
	parent.add_child(view_lbl)
	floor_nodes.append(view_lbl)
