extends Node2D
class_name FloorBuilder

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")
const FoodStallScript = preload("res://scripts/food_stall.gd")
const ClawMachineScript = preload("res://scripts/claw_machine.gd")

const CELL_SIZE = 16
const WORLD_W  = 96
const WORLD_H  = 50

func _build_zone_dress_rack(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "DRESSES")
	var zone_color: Color = zone.meta.get("color", Color(0.75, 0.55, 0.70))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.25))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Clothing racks — horizontal poles with hangers
	var num_racks := 3
	for rack in range(num_racks):
		var rack_y := cy + 16 + rack * (ch * 0.28)
		# Pole
		var pole := ColorRect.new()
		pole.position = Vector2(cx + 6, rack_y)
		pole.size = Vector2(cw - 12, 2)
		pole.color = Color(0.55, 0.52, 0.48)
		_parent.add_child(pole); _floor_nodes.append(pole)
		# Hangers with garment shapes
		for h in range(7):
			var hanger_x := cx + 10 + h * ((cw - 20) / 7.0)
			var garment_h := 20 + (rack % 2) * 8
			var garment := ColorRect.new()
			garment.position = Vector2(hanger_x, rack_y - garment_h)
			garment.size = Vector2(14, garment_h)
			garment.color = zone_color.lightened(0.1) if (h % 2 == 0) else zone_color.darkened(0.1)
			_parent.add_child(garment); _floor_nodes.append(garment)
			# Hanger hook
			var hook := ColorRect.new()
			hook.position = Vector2(hanger_x + 5, rack_y - garment_h - 3)
			hook.size = Vector2(4, 4)
			hook.color = Color(0.50, 0.48, 0.44)
			_parent.add_child(hook); _floor_nodes.append(hook)

	# Price tags decoration
	for t in range(4):
		var tag_x := cx + cw * 0.15 + t * (cw * 0.22)
		var tag := Label.new()
		tag.text = "$%d" % ([29, 49, 79, 39][t])
		tag.position = Vector2(tag_x, cy + ch - 18)
		tag.add_theme_color_override("font_color", Color(0.90, 0.85, 0.75))
		tag.add_theme_font_size_override("font_size", 6)
		_parent.add_child(tag); _floor_nodes.append(tag)

# Sports equipment — gym, team sports, fitness
func _build_zone_sport_area(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SPORT")
	var zone_color: Color = zone.meta.get("color", Color(0.50, 0.65, 0.75))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Display shelves for sports equipment
	var shelf_colors := [Color(0.45, 0.58, 0.68), Color(0.58, 0.52, 0.62), Color(0.52, 0.68, 0.58)]
	for row in range(3):
		var shelf_y := cy + 12 + row * (ch * 0.28)
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 4, shelf_y)
		plank.size = Vector2(cw - 8, 2)
		plank.color = shelf_colors[row % 3].darkened(0.3)
		_parent.add_child(plank); _floor_nodes.append(plank)
		# Equipment boxes
		for col in range(5):
			var eq_x := cx + 8 + col * ((cw - 16) / 5.0)
			var box := ColorRect.new()
			box.position = Vector2(eq_x, shelf_y - 14)
			box.size = Vector2((cw - 16) / 5.5, 14)
			box.color = shelf_colors[row % 3]
			_parent.add_child(box); _floor_nodes.append(box)
			# Icon stripe
			var stripe := ColorRect.new()
			stripe.position = Vector2(eq_x + 2, shelf_y - 8)
			stripe.size = Vector2((cw - 16) / 5.5 - 4, 3)
			stripe.color = shelf_colors[row % 3].lightened(0.25)
			_parent.add_child(stripe); _floor_nodes.append(stripe)

# Fishing, hiking, running, camping, cycling gear
func _build_zone_outdoor_area(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "OUTDOOR")
	var zone_color: Color = zone.meta.get("color", Color(0.50, 0.72, 0.55))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.38)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.25))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Outdoor gear display — tall shelving with mixed equipment
	for row in range(3):
		var shelf_y := cy + 14 + row * (ch * 0.27)
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 4, shelf_y)
		plank.size = Vector2(cw - 8, 2)
		plank.color = zone_color.darkened(0.45)
		_parent.add_child(plank); _floor_nodes.append(plank)
		# Gear items of varying heights (simulate rods, packs, boots)
		var item_colors := [zone_color.darkened(0.1), zone_color, zone_color.darkened(0.25), zone_color.lightened(0.1)]
		for col in range(5):
			var item_x := cx + 8 + col * ((cw - 16) / 5.0)
			var item_h := 12 + (col % 3) * 5
			var item := ColorRect.new()
			item.position = Vector2(item_x, shelf_y - item_h)
			item.size = Vector2((cw - 16) / 6.0, item_h)
			item.color = item_colors[col % item_colors.size()]
			_parent.add_child(item); _floor_nodes.append(item)

# Office and school supplies — notebooks, pens, desk accessories
func _build_zone_stationery(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "STATIONERY")
	var zone_color: Color = zone.meta.get("color", Color(0.72, 0.76, 0.88))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.darkened(0.2))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Stationery shelf — colorful small items
	var item_types := [
		Color(0.60, 0.72, 0.95),  # blue - pens
		Color(0.95, 0.72, 0.60),  # orange - notebooks
		Color(0.72, 0.90, 0.72),  # green - desk items
		Color(0.92, 0.85, 0.60),  # yellow - sticky notes
	]
	for row in range(4):
		var shelf_y := cy + 12 + row * (ch * 0.22)
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 4, shelf_y)
		plank.size = Vector2(cw - 8, 2)
		plank.color = zone_color.darkened(0.45)
		_parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(8):
			var item_x := cx + 6 + col * ((cw - 12) / 8.0)
			var item := ColorRect.new()
			item.position = Vector2(item_x, shelf_y - 10)
			item.size = Vector2((cw - 12) / 9.0, 10)
			item.color = item_types[(row + col) % item_types.size()]
			_parent.add_child(item); _floor_nodes.append(item)

# Indoor plants, garden plants, pots, soil
func _build_zone_plants_area(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "PLANTS")
	var zone_color: Color = zone.meta.get("color", Color(0.52, 0.80, 0.58))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.darkened(0.15))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Plant display — rows of potted plants with varying heights
	var plant_colors := [
		Color(0.40, 0.72, 0.35),  # dark green
		Color(0.55, 0.85, 0.45), # medium green
		Color(0.70, 0.90, 0.55),  # light green
		Color(0.60, 0.50, 0.35),  # brown (soil/pots)
	]
	for row in range(3):
		var row_y := cy + 18 + row * (ch * 0.26)
		for col in range(6):
			var pot_x := cx + 8 + col * ((cw - 16) / 6.0)
			var plant_h := 16 + (col % 3) * 8
			# Pot
			var pot := ColorRect.new()
			pot.position = Vector2(pot_x, row_y)
			pot.size = Vector2((cw - 16) / 6.8, 8)
			pot.color = plant_colors[3]
			_parent.add_child(pot); _floor_nodes.append(pot)
			# Plant
			var plant := ColorRect.new()
			plant.position = Vector2(pot_x + 1, row_y - plant_h)
			plant.size = Vector2((cw - 16) / 6.8 - 2, plant_h)
			plant.color = plant_colors[(row + col) % 3]
			_parent.add_child(plant); _floor_nodes.append(plant)

# Staff locker room — rows of metal lockers
func _build_zone_locker(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "LOCKER ROOM")
	var zone_color: Color = zone.meta.get("color", Color(0.45, 0.45, 0.50))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.2)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.35))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Rows of lockers
	for row in range(5):
		var row_y := cy + 8 + row * (ch * 0.17)
		for col in range(8):
			var lx := cx + 6 + col * ((cw - 12) / 8.0)
			var locker := ColorRect.new()
			locker.position = Vector2(lx, row_y)
			locker.size = Vector2((cw - 12) / 8.5, ch * 0.14)
			locker.color = zone_color.lightened(0.1) if (col % 2 == 0) else zone_color.darkened(0.1)
			_parent.add_child(locker); _floor_nodes.append(locker)
			# Vent slits
			for v in range(3):
				var slit := ColorRect.new()
				slit.position = Vector2(lx + 3, row_y + 2 + v * 2)
				slit.size = Vector2((cw - 12) / 8.5 - 6, 1)
				slit.color = zone_color.darkened(0.3)
				_parent.add_child(slit); _floor_nodes.append(slit)
			# Lock
			var lock_dot := ColorRect.new()
			lock_dot.position = Vector2(lx + (cw - 12) / 17.0, row_y + ch * 0.14 - 4)
			lock_dot.size = Vector2(3, 3)
			lock_dot.color = Color(0.80, 0.72, 0.40)
			_parent.add_child(lock_dot); _floor_nodes.append(lock_dot)

# Staff break room — sofas, tables, vending machines
func _build_zone_staff_lounge(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "STAFF LOUNGE")
	var zone_color: Color = zone.meta.get("color", Color(0.52, 0.48, 0.44))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.15)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.35))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Sofa
	var sofa := ColorRect.new()
	sofa.position = Vector2(cx + cw * 0.1, cy + ch * 0.35)
	sofa.size = Vector2(cw * 0.35, ch * 0.25)
	sofa.color = Color(0.55, 0.45, 0.42)
	_parent.add_child(sofa); _floor_nodes.append(sofa)
	# Sofa back
	var sofa_back := ColorRect.new()
	sofa_back.position = Vector2(cx + cw * 0.1, cy + ch * 0.25)
	sofa_back.size = Vector2(cw * 0.35, ch * 0.12)
	sofa_back.color = Color(0.48, 0.40, 0.38)
	_parent.add_child(sofa_back); _floor_nodes.append(sofa_back)

	# Coffee table
	var table := ColorRect.new()
	table.position = Vector2(cx + cw * 0.5, cy + ch * 0.45)
	table.size = Vector2(cw * 0.2, ch * 0.15)
	table.color = Color(0.45, 0.38, 0.32)
	_parent.add_child(table); _floor_nodes.append(table)

	# Vending machine
	var vm := ColorRect.new()
	vm.position = Vector2(cx + cw * 0.78, cy + ch * 0.2)
	vm.size = Vector2(cw * 0.15, ch * 0.55)
	vm.color = Color(0.40, 0.38, 0.42)
	_parent.add_child(vm); _floor_nodes.append(vm)
	var vm_screen := ColorRect.new()
	vm_screen.position = Vector2(cx + cw * 0.79, cy + ch * 0.22)
	vm_screen.size = Vector2(cw * 0.13, ch * 0.2)
	vm_screen.color = Color(0.20, 0.40, 0.30)
	_parent.add_child(vm_screen); _floor_nodes.append(vm_screen)

# Staff training room — projector screen, chairs, whiteboards
func _build_zone_training(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "TRAINING ROOM")
	var zone_color: Color = zone.meta.get("color", Color(0.40, 0.48, 0.55))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.15)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.35))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Projector screen
	var screen_bg := ColorRect.new()
	screen_bg.position = Vector2(cx + cw * 0.2, cy + ch * 0.1)
	screen_bg.size = Vector2(cw * 0.5, ch * 0.4)
	screen_bg.color = Color(0.90, 0.95, 1.0)
	_parent.add_child(screen_bg); _floor_nodes.append(screen_bg)
	var screen_border := ColorRect.new()
	screen_border.position = Vector2(cx + cw * 0.2 - 2, cy + ch * 0.1 - 2)
	screen_border.size = Vector2(cw * 0.5 + 4, ch * 0.4 + 4)
	screen_border.color = Color(0.50, 0.50, 0.55)
	_parent.add_child(screen_border); _floor_nodes.append(screen_border)

	# Rows of training chairs
	for row in range(3):
		var chair_y := cy + ch * 0.58 + row * (ch * 0.12)
		for col in range(8):
			var chair_x := cx + cw * 0.15 + col * (cw * 0.08)
			var chair := ColorRect.new()
			chair.position = Vector2(chair_x, chair_y)
			chair.size = Vector2(cw * 0.06, ch * 0.08)
			chair.color = Color(0.50, 0.48, 0.55)
			_parent.add_child(chair); _floor_nodes.append(chair)

	# Whiteboard
	var wb := ColorRect.new()
	wb.position = Vector2(cx + cw * 0.75, cy + ch * 0.15)
	wb.size = Vector2(cw * 0.18, ch * 0.45)
	wb.color = Color(0.95, 0.97, 0.95)
	_parent.add_child(wb); _floor_nodes.append(wb)

# Open plan office with desks
func _build_zone_office_desk(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "OFFICE")
	var zone_color: Color = zone.meta.get("color", Color(0.48, 0.52, 0.58))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.18)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.35))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Desk grid
	for row in range(3):
		for col in range(5):
			var desk_x := cx + 8 + col * ((cw - 16) / 5.0)
			var desk_y := cy + 14 + row * (ch * 0.27)
			# Desk surface
			var desk := ColorRect.new()
			desk.position = Vector2(desk_x, desk_y)
			desk.size = Vector2((cw - 16) / 5.5, ch * 0.2)
			desk.color = zone_color.lightened(0.1)
			_parent.add_child(desk); _floor_nodes.append(desk)
			# Monitor
			var monitor := ColorRect.new()
			monitor.position = Vector2(desk_x + (cw - 16) / 11.0, desk_y - 10)
			monitor.size = Vector2((cw - 16) / 6.5, 10)
			monitor.color = Color(0.20, 0.22, 0.25)
			_parent.add_child(monitor); _floor_nodes.append(monitor)
			# Monitor screen glow
			var glow := ColorRect.new()
			glow.position = Vector2(desk_x + (cw - 16) / 11.0 + 1, desk_y - 9)
			glow.size = Vector2((cw - 16) / 6.5 - 2, 7)
			glow.color = Color(0.30, 0.45, 0.65)
			_parent.add_child(glow); _floor_nodes.append(glow)

# Executive suites — large desks, leather chairs, dark wood aesthetic
func _build_zone_exec_office(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "EXEC OFFICE")
	var zone_color: Color = zone.meta.get("color", Color(0.42, 0.42, 0.48))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.12)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.4))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Executive desk (large, dark)
	var ex_desk := ColorRect.new()
	ex_desk.position = Vector2(cx + cw * 0.25, cy + ch * 0.3)
	ex_desk.size = Vector2(cw * 0.5, ch * 0.35)
	ex_desk.color = Color(0.30, 0.25, 0.22)
	_parent.add_child(ex_desk); _floor_nodes.append(ex_desk)
	# Desk surface highlight
	var desk_top := ColorRect.new()
	desk_top.position = Vector2(cx + cw * 0.25, cy + ch * 0.3)
	desk_top.size = Vector2(cw * 0.5, 3)
	desk_top.color = Color(0.40, 0.35, 0.30)
	_parent.add_child(desk_top); _floor_nodes.append(desk_top)
	# Executive chair
	var chair := ColorRect.new()
	chair.position = Vector2(cx + cw * 0.38, cy + ch * 0.62)
	chair.size = Vector2(cw * 0.2, ch * 0.18)
	chair.color = Color(0.25, 0.22, 0.28)
	_parent.add_child(chair); _floor_nodes.append(chair)

	# Bookshelf on side wall
	for row in range(5):
		var shelf_y := cy + 12 + row * (ch * 0.14)
		var shelf := ColorRect.new()
		shelf.position = Vector2(cx + cw * 0.78, shelf_y)
		shelf.size = Vector2(cw * 0.18, 2)
		shelf.color = Color(0.35, 0.28, 0.22)
		_parent.add_child(shelf); _floor_nodes.append(shelf)
		for b in range(4):
			var book_x := cx + cw * 0.79 + b * (cw * 0.038)
			var book_h := 8 + (b % 3) * 5
			var book := ColorRect.new()
			book.position = Vector2(book_x, shelf_y - book_h)
			book.size = Vector2(cw * 0.032, book_h)
			book.color = [Color(0.65, 0.35, 0.35), Color(0.35, 0.50, 0.65), Color(0.55, 0.60, 0.42), Color(0.60, 0.50, 0.38)][b % 4]
			_parent.add_child(book); _floor_nodes.append(book)

	# Plant decor in corner
	var plant_pot := ColorRect.new()
	plant_pot.position = Vector2(cx + cw * 0.06, cy + ch * 0.65)
	plant_pot.size = Vector2(cw * 0.08, ch * 0.12)
	plant_pot.color = Color(0.55, 0.40, 0.30)
	_parent.add_child(plant_pot); _floor_nodes.append(plant_pot)
	var plant_leaves := ColorRect.new()
	plant_leaves.position = Vector2(cx + cw * 0.05, cy + ch * 0.42)
	plant_leaves.size = Vector2(cw * 0.10, ch * 0.25)
	plant_leaves.color = Color(0.38, 0.65, 0.35)
	_parent.add_child(plant_leaves); _floor_nodes.append(plant_leaves)

# ??? Ad Billboard Zone ?????????????????????????????????????????????????????????
# Wall advertisement poster ??colorful promotional display
# meta: {ad_id: String, ad_text: String, ad_color: Color}
func _get_brand_ad_for_zone(zone: FloorConfig.Zone) -> Array:
	# Returns brand ad data for this zone's floor, if any
	var main = get_tree().get_first_node_in_group("main")
	if main == null:
		return []
	var bm = main.get_node_or_null("BrandManager")
	if bm == null or not bm.has_method("get_ads_for_floor"):
		return []
	return bm.get_ads_for_floor(_floor_idx)

func _build_zone_ad(zone: FloorConfig.Zone) -> void:
	var ad_id: String = zone.meta.get("ad_id", "generic_ad")
	var ad_text: String = zone.meta.get("ad_text", "SALE!")
	var ad_color: Color = zone.meta.get("ad_color", Color(1.0, 0.40, 0.20))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	# Override from brand manager if an ad is scheduled for this floor
	var brand_ads = _get_brand_ad_for_zone(zone)
	if brand_ads.size() > 0:
		var ba = brand_ads[0]
		ad_text = ba.get("text", ad_text)
		ad_color = ba.get("color", ad_color)

	# Backlit billboard frame
	var frame := ColorRect.new()
	frame.position = Vector2(cx, cy)
	frame.size = Vector2(cw, ch)
	frame.color = Color(0.08, 0.08, 0.10)
	_parent.add_child(frame); _floor_nodes.append(frame)

	# Inner glow background
	var glow_bg := ColorRect.new()
	glow_bg.position = Vector2(cx + 3, cy + 3)
	glow_bg.size = Vector2(cw - 6, ch - 6)
	glow_bg.color = ad_color.darkened(0.35)
	_parent.add_child(glow_bg); _floor_nodes.append(glow_bg)

	# Ad banner — main color block
	var banner := ColorRect.new()
	banner.position = Vector2(cx + 4, cy + 4)
	banner.size = Vector2(cw - 8, ch * 0.60)
	banner.color = ad_color
	_parent.add_child(banner); _floor_nodes.append(banner)

	# Ad text line 1 (big)
	var ad_lbl := Label.new()
	ad_lbl.text = ad_text
	ad_lbl.position = Vector2(cx + 4, cy + 4)
	ad_lbl.size = Vector2(cw - 8, ch * 0.55)
	ad_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.40))
	ad_lbl.add_theme_font_size_override("font_size", clampi(cw / 10, 8, 16))
	ad_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_parent.add_child(ad_lbl); _floor_nodes.append(ad_lbl)

	# Sub-text (promo details)
	var sub_texts := {
		"summer_sale": "UP TO 50% OFF",
		"fresh_market": "FRESH DAILY",
		"new_arrivals": "JUST LANDED",
		"members_only": "JOIN TODAY",
		"weekend_deal": "BUY 1 GET 1 FREE",
		"organic": "100% ORGANIC",
		"locally_made": "LOCAL PRODUCERS",
		"pet_special": "PET OF THE WEEK",
		"sport_promo": "GEAR UP!",
		"outdoor_sale": "ADVENTURE AWAITS",
		"fashion_week": "NEW COLLECTION",
		"staff_hiring": "NOW HIRING!",
		"express_checkout": "10 ITEMS OR LESS",
		"self_checkout": "SELF-SCAN & GO",
		"parking_info": "FIRST 2 HOURS FREE",
	}
	var sub := sub_texts.get(ad_id, "LIMITED TIME")
	var sub_lbl := Label.new()
	sub_lbl.text = sub
	sub_lbl.position = Vector2(cx + 4, cy + ch * 0.62)
	sub_lbl.size = Vector2(cw - 8, ch * 0.30)
	sub_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	sub_lbl.add_theme_font_size_override("font_size", clampi(cw / 14, 6, 10))
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_parent.add_child(sub_lbl); _floor_nodes.append(sub_lbl)

	# Corner decorations (flashing light effect simulated with bright corners)
	var corner_color := ad_color.lightened(0.4)
	for c_x in [cx + 2, cx + cw - 6]:
		for c_y in [cy + 2, cy + ch - 6]:
			var dot := ColorRect.new()
			dot.position = Vector2(c_x, c_y)
			dot.size = Vector2(4, 4)
			dot.color = corner_color
			_parent.add_child(dot); _floor_nodes.append(dot)

	# Ad ID label (small, bottom corner)
	var id_lbl := Label.new()
	id_lbl.text = "#%s" % ad_id
	id_lbl.position = Vector2(cx + 2, cy + ch - 12)
	id_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	id_lbl.add_theme_font_size_override("font_size", 5)
	_parent.add_child(id_lbl); _floor_nodes.append(id_lbl)


# Monitor Room / CCTV Room Zone
# Bank of screens showing floor status indicators.
# On Floor 7 (Back Office) and Floor 8 (Executive Office).
func _build_zone_monitor_room(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get('name', 'MONITORING')
	var zone_color: Color = zone.meta.get('color', Color(0.20, 0.25, 0.30))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	# Dark room background
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.1)
	_parent.add_child(bg)
	_floor_nodes.append(bg)

	# Room name label
	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override('font_color', Color(0.30, 0.80, 1.0))
	title_lbl.add_theme_font_size_override('font_size', 9)
	_parent.add_child(title_lbl)
	_floor_nodes.append(title_lbl)

	# SUBTITLE
	var sub_lbl := Label.new()
	sub_lbl.text = 'LIVE FEED - ALL FLOORS'
	sub_lbl.position = Vector2(cx + 4, cy - 6)
	sub_lbl.add_theme_color_override('font_color', Color(0.20, 0.60, 0.50))
	sub_lbl.add_theme_font_size_override('font_size', 6)
	_parent.add_child(sub_lbl)
	_floor_nodes.append(sub_lbl)

	# 4x3 grid of monitor screens (12 floors)
	var screen_w := (cw - 20) / 4.0
	var screen_h := (ch - 24) / 3.5
	var floors := ['G','1','2','3','4','5','6','7','8','9','10','11']
	var screen_colors := [
		Color(0.30, 0.50, 0.35),  # G - lobby green
		Color(0.55, 0.40, 0.35),  # 1 - shoes brown
		Color(0.50, 0.35, 0.55),  # 2 - fashion purple
		Color(0.35, 0.50, 0.60),  # 3 - sport blue
		Color(0.38, 0.60, 0.42),  # 4 - outdoor green
		Color(0.45, 0.58, 0.42),  # 5 - stationery green
		Color(0.35, 0.35, 0.40),  # 6 - staff grey
		Color(0.38, 0.40, 0.45),  # 7 - back office blue-grey
		Color(0.32, 0.32, 0.40),  # 8 - exec dark
		Color(0.65, 0.60, 0.48),  # 9 - rooftop warm
		Color(0.40, 0.70, 0.55),  # 10 - pet green
		Color(0.55, 0.45, 0.38),  # 11 - warehouse brown
	]

	for i in range(12):
		var col := i % 4
		var row := i / 4
		var sx := cx + 8 + col * screen_w
		var sy := cy + 16 + row * screen_h

		# Screen bezel (dark frame)
		var bezel := ColorRect.new()
		bezel.position = Vector2(sx - 2, sy - 2)
		bezel.size = Vector2(screen_w + 4, screen_h + 4)
		bezel.color = Color(0.08, 0.08, 0.10)
		_parent.add_child(bezel)
		_floor_nodes.append(bezel)

		# Screen display
		var scr := ColorRect.new()
		scr.position = Vector2(sx, sy)
		scr.size = Vector2(screen_w, screen_h)
		scr.color = screen_colors[i].darkened(0.4)
		_parent.add_child(scr)
		_floor_nodes.append(scr)

		# Scanline effect (horizontal lines on screen)
		for sl in range(0, screen_h as int, 3):
			var scan := ColorRect.new()
			scan.position = Vector2(sx, sy + sl)
			scan.size = Vector2(screen_w, 1)
			scan.color = Color(0, 0, 0, 0.15)
			_parent.add_child(scan)
			_floor_nodes.append(scan)

		# Floor label
		var fl := Label.new()
		fl.text = 'FL %s' % floors[i]
		fl.position = Vector2(sx + 2, sy + 2)
		fl.add_theme_color_override('font_color', Color(0.90, 0.95, 1.0))
		fl.add_theme_font_size_override('font_size', 6)
		_parent.add_child(fl)
		_floor_nodes.append(fl)

		# Status dot (green = active)
		var dot := ColorRect.new()
		dot.position = Vector2(sx + screen_w - 8, sy + 3)
		dot.size = Vector2(4, 4)
		dot.color = Color(0.20, 0.90, 0.40)  # green active dot
		_parent.add_child(dot)
		_floor_nodes.append(dot)

		# Mini map hints (simple colored blocks representing sections)
		for bx in range(3):
			for by in range(2):
				var dot2 := ColorRect.new()
				dot2.position = Vector2(sx + 4 + bx * (screen_w * 0.28), sy + screen_h * 0.5 + by * (screen_h * 0.22))
				dot2.size = Vector2(screen_w * 0.22, screen_h * 0.18)
				dot2.color = screen_colors[i].lightened(0.2)
				_parent.add_child(dot2)
				_floor_nodes.append(dot2)

		# Customer count (simulated)
		var cust_lbl := Label.new()
		cust_lbl.text = '%d customers' % [12, 8, 15, 6, 9, 11, 0, 0, 0, 7, 4, 2][i]
		cust_lbl.position = Vector2(sx + 2, sy + screen_h - 10)
		cust_lbl.add_theme_color_override('font_color', Color(0.70, 0.85, 0.70))
		cust_lbl.add_theme_font_size_override('font_size', 5)
		_parent.add_child(cust_lbl)
		_floor_nodes.append(cust_lbl)

	# Console desk at bottom
	var desk := ColorRect.new()
	desk.position = Vector2(cx + 4, cy + ch - 14)
	desk.size = Vector2(cw - 8, 10)
	desk.color = Color(0.15, 0.15, 0.20)
	_parent.add_child(desk)
	_floor_nodes.append(desk)

	# Console lights
	var light_colors := [Color(0.20, 0.90, 0.40), Color(0.90, 0.80, 0.20), Color(0.90, 0.40, 0.20)]
	for li in range(3):
		var light := ColorRect.new()
		light.position = Vector2(cx + 8 + li * 10, cy + ch - 12)
		light.size = Vector2(6, 6)
		light.color = light_colors[li]
		_parent.add_child(light)
		_floor_nodes.append(light)

	# Interaction hint
	var hint := Label.new()
	hint.text = '[E] Open Monitor Panel'
	hint.position = Vector2(cx + cw - 60, cy + ch - 12)
	hint.add_theme_color_override('font_color', Color(0.40, 0.70, 1.0))
	hint.add_theme_font_size_override('font_size', 6)
	_parent.add_child(hint)
	_floor_nodes.append(hint)


