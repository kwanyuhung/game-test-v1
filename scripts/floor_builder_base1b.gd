extends Node2D
class_name FloorBuilder

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")
const FoodStallScript = preload("res://scripts/food_stall.gd")
const ClawMachineScript = preload("res://scripts/claw_machine.gd")

const CELL_SIZE = 16
const WORLD_W  = 96
const WORLD_H  = 50

func _build_zone_pet_adoption(zone: FloorConfig.Zone) -> void:
	var adopt_name: String = zone.meta.get("name", "ADOPTION")
	var adopt_color: Color = zone.meta.get("color", Color(0.60, 0.88, 0.70))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	# Back wall
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = Color(0.18, 0.28, 0.20)
	_parent.add_child(bg); _floor_nodes.append(bg)

	# Warm green trim strips
	var trim := ColorRect.new()
	trim.position = Vector2(cx, cy)
	trim.size = Vector2(cw, 3)
	trim.color = adopt_color
	_parent.add_child(trim); _floor_nodes.append(trim)

	var trim_bot := ColorRect.new()
	trim_bot.position = Vector2(cx, cy + ch - 3)
	trim_bot.size = Vector2(cw, 3)
	trim_bot.color = adopt_color
	_parent.add_child(trim_bot); _floor_nodes.append(trim_bot)

	# Adoption kennels — 3 cages (dog, cat, rabbit)
	var kennel_colors := [Color(0.70, 0.60, 0.45), Color(0.55, 0.50, 0.48), Color(0.65, 0.58, 0.52)]
	var cage_w := cw / 3.5
	for i in range(3):
		var kx := cx + 8 + i * (cage_w + 8)
		var ky := cy + 12
		var cage_h := ch - 24

		# Cage frame
		var frame := ColorRect.new()
		frame.position = Vector2(kx, ky)
		frame.size = Vector2(cage_w, cage_h)
		frame.color = kennel_colors[i]
		_parent.add_child(frame); _floor_nodes.append(frame)

		# Cage bars (vertical)
		for b in range(4):
			var bx := kx + (b + 1) * cage_w / 5.0
			var bar := ColorRect.new()
			bar.position = Vector2(bx, ky)
			bar.size = Vector2(2, cage_h)
			bar.color = Color(0.35, 0.30, 0.25)
			_parent.add_child(bar); _floor_nodes.append(bar)

		# Pet sprite inside cage
		var pet_tex := _make_pet_sprite(i)
		var pet_spr := Sprite2D.new()
		pet_spr.texture = pet_tex
		pet_spr.position = Vector2(kx + cage_w * 0.5, ky + cage_h * 0.5)
		pet_spr.z_index = 3
		_parent.add_child(pet_spr); _floor_nodes.append(pet_spr)

	# ADOPTION sign
	var sign_lbl := Label.new()
	sign_lbl.text = adopt_name
	sign_lbl.position = Vector2(cx + 4, cy - 14)
	sign_lbl.add_theme_color_override("font_color", adopt_color.lightened(0.2))
	sign_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(sign_lbl); _floor_nodes.append(sign_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Meet your new best friend!"
	sub_lbl.position = Vector2(cx + 4, cy - 6)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 0.78))
	sub_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(sub_lbl); _floor_nodes.append(sub_lbl)

	# Pet food shelves on right side
	var shelf_x := cx + cw * 0.55
	for row in range(3):
		var shelf_y := cy + 8 + row * (ch * 0.28)
		# Shelf back
		var shelf_bg := ColorRect.new()
		shelf_bg.position = Vector2(shelf_x, shelf_y)
		shelf_bg.size = Vector2(cw * 0.40, ch * 0.25)
		shelf_bg.color = Color(0.12, 0.10, 0.08)
		_parent.add_child(shelf_bg); _floor_nodes.append(shelf_bg)
		# Shelf plank
		var plank := ColorRect.new()
		plank.position = Vector2(shelf_x, shelf_y + ch * 0.22)
		plank.size = Vector2(cw * 0.40, 2)
		plank.color = Color(0.40, 0.32, 0.22)
		_parent.add_child(plank); _floor_nodes.append(plank)
		# Pet food bags
		for col in range(4):
			var item_x := shelf_x + 4 + col * (cw * 0.095)
			var item_y := shelf_y + ch * 0.05
			var bag_spr := Sprite2D.new()
			bag_spr.texture = _make_pet_food_bag_texture(row, col)
			bag_spr.position = Vector2(item_x + CELL_SIZE, item_y + CELL_SIZE * 0.5)
			bag_spr.z_index = 3
			_parent.add_child(bag_spr); _floor_nodes.append(bag_spr)

func _make_pet_sprite(pet_type: int) -> Texture2D:
	var W := 20; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	match pet_type:
		0:  # Dog — brown, floppy ears
			for y in range(6, 15):
				for x in range(4, 16):
					img.set_pixel(x, y, Color(0.62, 0.42, 0.22))
			for y in range(2, 10):
				for x in range(8, 16):
					img.set_pixel(x, y, Color(0.68, 0.48, 0.25))
			for y in range(2, 8):
				img.set_pixel(8, y, Color(0.52, 0.32, 0.18))
				img.set_pixel(7, y, Color(0.52, 0.32, 0.18))
			img.set_pixel(13, 5, Color(0.08, 0.06, 0.06))
			img.set_pixel(15, 7, Color(0.12, 0.08, 0.08))
			for y in range(4, 8):
				img.set_pixel(4 - (y - 4), y, Color(0.62, 0.42, 0.22))
		1:  # Cat — grey, pointed ears, whiskers
			for y in range(8, 15):
				for x in range(5, 15):
					img.set_pixel(x, y, Color(0.52, 0.52, 0.58))
			for y in range(2, 10):
				for x in range(6, 14):
					img.set_pixel(x, y, Color(0.55, 0.55, 0.60))
			img.set_pixel(7, 2, Color(0.55, 0.55, 0.60)); img.set_pixel(8, 1, Color(0.55, 0.55, 0.60)); img.set_pixel(9, 2, Color(0.55, 0.55, 0.60))
			img.set_pixel(11, 2, Color(0.55, 0.55, 0.60)); img.set_pixel(12, 1, Color(0.55, 0.55, 0.60)); img.set_pixel(13, 2, Color(0.55, 0.55, 0.60))
			img.set_pixel(9, 5, Color(0.10, 0.70, 0.10)); img.set_pixel(12, 5, Color(0.10, 0.70, 0.10))
			img.set_pixel(10, 7, Color(0.80, 0.55, 0.60))
			for wx in range(2, 6): img.set_pixel(wx, 7, Color(0.80, 0.80, 0.85))
			for wx in range(14, 18): img.set_pixel(wx, 7, Color(0.80, 0.80, 0.85))
		2:  # Rabbit — white, long ears, pink nose
			for y in range(10, 17):
				for x in range(6, 14):
					img.set_pixel(x, y, Color(0.95, 0.95, 0.92))
			for y in range(4, 12):
				for x in range(7, 13):
					img.set_pixel(x, y, Color(0.97, 0.97, 0.94))
			for y in range(0, 7):
				img.set_pixel(7, y, Color(0.97, 0.97, 0.94)); img.set_pixel(8, y, Color(0.97, 0.97, 0.94))
				img.set_pixel(11, y, Color(0.97, 0.97, 0.94)); img.set_pixel(12, y, Color(0.97, 0.97, 0.94))
			img.set_pixel(8, 2, Color(0.90, 0.65, 0.72)); img.set_pixel(11, 2, Color(0.90, 0.65, 0.72))
			img.set_pixel(9, 6, Color(0.90, 0.10, 0.15)); img.set_pixel(11, 6, Color(0.90, 0.10, 0.15))
			img.set_pixel(10, 9, Color(0.90, 0.58, 0.65))

	return ImageTexture.create_from_image(img)

func _make_pet_food_bag_texture(pet_idx: int, bag_idx: int) -> Texture2D:
	var W := 10; var H := 14
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bag_colors := [
		[Color(0.72, 0.42, 0.22), Color(0.55, 0.35, 0.20)],
		[Color(0.55, 0.55, 0.70), Color(0.45, 0.45, 0.60)],
		[Color(0.90, 0.82, 0.55), Color(0.78, 0.70, 0.40)],
	]
	var colors: Array = bag_colors[pet_idx % 3]
	var top_col: Color = colors[0]; var bot_col: Color = colors[1]

	for y in range(2, H):
		var t := float(y - 2) / float(H - 2)
		var c := top_col.lerp(bot_col, t)
		for x in range(2, W - 2):
			img.set_pixel(x, y, c)

	for y in range(0, 3):
		for x in range(1, W - 1):
			img.set_pixel(x, y, top_col.darkened(0.1))

	for x in range(3, W - 3):
		img.set_pixel(x, 5, Color(0.95, 0.92, 0.80))
		img.set_pixel(x, 7, Color(0.95, 0.92, 0.80))
		img.set_pixel(x, 9, Color(0.95, 0.92, 0.80))

	return ImageTexture.create_from_image(img)


# Builds a complete claw machine cabinet with prizes, claw, rail, and
# interaction zone. meta: {machine_id: String, prize_pool: int (0-3)}.

# Visual representation of the warehouse receiving dock.
# Shows shelving units, delivery doors, and stock crates.
func _build_zone_storage_shelf(zone: FloorConfig.Zone) -> void:
	# Storage shelf area - industrial metal shelving
	var shelf_color = zone.get("color", Color(0.60, 0.50, 0.40))
	var base = ColorRect.new()
	base.color = shelf_color
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_floor_node.add_child(base)
	# Draw shelf lines
	for row in range(zone.h):
		var line = ColorRect.new()
		line.color = Color(0.45, 0.38, 0.30)
		line.size = Vector2(zone.w * CELL_SIZE, 2)
		line.position = Vector2(zone.x * CELL_SIZE, (zone.y + row * 3) * CELL_SIZE)
		_floor_node.add_child(line)

func _build_zone_warehouse(zone: FloorConfig.Zone) -> void:
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	# Floor
	var floor_bg := ColorRect.new()
	floor_bg.position = Vector2(cx, cy)
	floor_bg.size = Vector2(cw, ch)
	floor_bg.color = Color(0.38, 0.32, 0.26)
	_parent.add_child(floor_bg); _floor_nodes.append(floor_bg)

	# Grid lines on floor (warehouse floor markings)
	for gx in range(cx, cx + cw, CELL_SIZE * 4):
		var line := ColorRect.new()
		line.position = Vector2(gx, cy)
		line.size = Vector2(2, ch)
		line.color = Color(0.32, 0.28, 0.22)
		_parent.add_child(line); _floor_nodes.append(line)

	# Shelving units (left side — 3 tall racks)
	var shelf_colors := [
		Color(0.50, 0.42, 0.32),
		Color(0.45, 0.38, 0.28),
		Color(0.52, 0.44, 0.34),
	]
	for rack in range(3):
		var rx := cx + 8 + rack * (cw * 0.22)
		var rack_h := ch * 0.85
		var rack_bg := ColorRect.new()
		rack_bg.position = Vector2(rx, cy + 8)
		rack_bg.size = Vector2(cw * 0.18, rack_h)
		rack_bg.color = shelf_colors[rack % shelf_colors.size()]
		_parent.add_child(rack_bg); _floor_nodes.append(rack_bg)

		# Shelf rows inside rack
		for row in range(5):
			var shelf_y := cy + 8 + row * (rack_h / 5.5)
			var shelf_plank := ColorRect.new()
			shelf_plank.position = Vector2(rx + 2, shelf_y)
			shelf_plank.size = Vector2(cw * 0.18 - 4, 2)
			shelf_plank.color = Color(0.35, 0.28, 0.20)
			_parent.add_child(shelf_plank); _floor_nodes.append(shelf_plank)

			# Crate boxes on shelf
			for col in range(3):
				var crate_x := rx + 4 + col * (cw * 0.055)
				var crate_spr := Sprite2D.new()
				crate_spr.texture = _make_crate_texture(rack, row)
				crate_spr.position = Vector2(crate_x + CELL_SIZE, shelf_y - CELL_SIZE * 0.5)
				crate_spr.z_index = 3
				_parent.add_child(crate_spr); _floor_nodes.append(crate_spr)

	# Loading dock door (right side — large door with stripes)
	var dock_x := cx + cw * 0.70
	var dock := ColorRect.new()
	dock.position = Vector2(dock_x, cy + 8)
	dock.size = Vector2(cw * 0.25, ch * 0.80)
	dock.color = Color(0.25, 0.22, 0.18)
	_parent.add_child(dock); _floor_nodes.append(dock)

	# Dock stripes (yellow/black warning)
	for st in range(0, dock.size.y as int, 16):
		var stripe := ColorRect.new()
		stripe.position = Vector2(dock_x, cy + 8 + st)
		stripe.size = Vector2(cw * 0.25, 8)
		stripe.color = Color(0.85, 0.72, 0.20) if (st / 16 % 2 == 0) else Color(0.15, 0.12, 0.08)
		_parent.add_child(stripe); _floor_nodes.append(stripe)

	# "RECEIVING DOCK" sign
	var recv_lbl := Label.new()
	recv_lbl.text = "RECEIVING DOCK"
	recv_lbl.position = Vector2(cx + 4, cy - 14)
	recv_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.20))
	recv_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(recv_lbl); _floor_nodes.append(recv_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "Stock arrives here. Press E to check warehouse stock."
	hint_lbl.position = Vector2(cx + 4, cy - 6)
	hint_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
	hint_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(hint_lbl); _floor_nodes.append(hint_lbl)

# ATM machine — standalone or in a wall niche.
# meta: {atm_id: String}
func _build_zone_atm(zone: FloorConfig.Zone) -> void:
	var atm_id: String = zone.meta.get("atm_id", "atm_1")
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE

	# ATM machine body
	var machine := ATM.new()
	machine.position = Vector2(cx + CELL_SIZE * 2, cy + CELL_SIZE * 2)
	machine.name = "ATM_%s" % atm_id
	_parent.add_child(machine)

	# Build ATM visual using a simple approach
	var body := ColorRect.new()
	body.position = Vector2(cx + CELL_SIZE * 2, cy + CELL_SIZE * 2)
	body.size = Vector2(CELL_SIZE * 3, CELL_SIZE * 4)
	body.color = Color(0.15, 0.20, 0.15)
	_parent.add_child(body); _floor_nodes.append(body)

	# Screen (bright green LCD)
	var screen := ColorRect.new()
	screen.position = Vector2(cx + CELL_SIZE * 2 + 4, cy + CELL_SIZE * 2 + 2)
	screen.size = Vector2(CELL_SIZE * 2 + 2, CELL_SIZE)
	screen.color = Color(0.08, 0.18, 0.08)
	_parent.add_child(screen); _floor_nodes.append(screen)

	# Screen glow label
	var screen_lbl := Label.new()
	screen_lbl.text = "INSERT CARD"
	screen_lbl.position = Vector2(cx + CELL_SIZE * 2 + 6, cy + CELL_SIZE * 2 + 3)
	screen_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.40))
	screen_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(screen_lbl); _floor_nodes.append(screen_lbl)

	# Card slot
	var slot := ColorRect.new()
	slot.position = Vector2(cx + CELL_SIZE * 3 + 4, cy + CELL_SIZE * 3 + 4)
	slot.size = Vector2(CELL_SIZE + 2, 3)
	slot.color = Color(0.08, 0.08, 0.08)
	_parent.add_child(slot); _floor_nodes.append(slot)

	# Cash dispenser
	var cash := ColorRect.new()
	cash.position = Vector2(cx + CELL_SIZE * 2 + 4, cy + CELL_SIZE * 4 + 2)
	cash.size = Vector2(CELL_SIZE * 2 + 2, CELL_SIZE)
	cash.color = Color(0.12, 0.18, 0.12)
	_parent.add_child(cash); _floor_nodes.append(cash)

	# Bank branding label
	var brand_lbl := Label.new()
	brand_lbl.text = "STORE BANK"
	brand_lbl.position = Vector2(cx + CELL_SIZE * 2 + 2, cy + CELL_SIZE * 2 - 10)
	brand_lbl.add_theme_color_override("font_color", Color(0.20, 0.60, 0.30))
	brand_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(brand_lbl); _floor_nodes.append(brand_lbl)

func _make_crate_texture(rack_idx: int, row_idx: int) -> Texture2D:
	var W := 12; var H := 12
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var crate_color := Color(0.65, 0.52, 0.38)
	if rack_idx % 3 == 1:
		crate_color = Color(0.55, 0.48, 0.40)
	elif rack_idx % 3 == 2:
		crate_color = Color(0.70, 0.55, 0.42)

	# Box fill
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			img.set_pixel(x, y, crate_color)

	# Box border
	for x in range(W):
		img.set_pixel(x, 0, crate_color.darkened(0.2))
		img.set_pixel(x, H - 1, crate_color.darkened(0.2))
	for y in range(H):
		img.set_pixel(0, y, crate_color.darkened(0.2))
		img.set_pixel(W - 1, y, crate_color.darkened(0.2))

	# Tape/stripe on box
	for x in range(W):
		img.set_pixel(x, H / 2, crate_color.lightened(0.2))

	return ImageTexture.create_from_image(img)
func _build_zone_claw_machine(zone: FloorConfig.Zone) -> void:
	var machine_id: String = zone.meta.get("machine_id", "claw_1")
	var prize_pool_idx: int = zone.meta.get("prize_pool", 0)

	# Define prize pools (each machine has different coloured plushies)
	var prize_pools := [
		[Color(0.90, 0.30, 0.30), Color(0.90, 0.45, 0.45), Color(0.85, 0.25, 0.25)],  # red plush
		[Color(0.30, 0.75, 0.90), Color(0.40, 0.80, 0.95), Color(0.25, 0.65, 0.85)],  # blue plush
		[Color(0.90, 0.70, 0.20), Color(0.85, 0.75, 0.25), Color(0.80, 0.60, 0.15)],  # yellow plush
		[Color(0.55, 0.90, 0.40), Color(0.88, 0.45, 0.85), Color(0.90, 0.55, 0.30)],  # mixed
	]
	var pool: Array = prize_pools[prize_pool_idx % prize_pools.size()]

	var machine := ClawMachineScript.new()
	machine.configure(zone, machine_id)
	machine.build(pool)
	machine.name = "Claw_%s" % machine_id
	_parent.add_child(machine)
	_claw_machines.append(machine)


func _build_section_zones() -> void:
	for sz: FloorConfig.SectionZone in _floor_def.section_zones:
		_build_section_zone(sz)

func _build_section_zone(sz: FloorConfig.SectionZone) -> void:
	var def = StoreData.get_section_def(sz.section_id)
	if def == null:
		return

	# Background
	var bg := ColorRect.new()
	bg.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	bg.size = Vector2(sz.w * CELL_SIZE, sz.h * CELL_SIZE)
	bg.color = _get_section_floor(def.style)
	_parent.add_child(bg); _floor_nodes.append(bg)

	# Walls
	var wc := _get_section_wall_color(def.style)
	var tw := ColorRect.new()
	tw.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	tw.size = Vector2(sz.w * CELL_SIZE, 2)
	tw.color = wc; _parent.add_child(tw); _floor_nodes.append(tw)

	var bw := ColorRect.new()
	bw.position = Vector2(sz.x * CELL_SIZE, (sz.y + sz.h - 1) * CELL_SIZE)
	bw.size = Vector2(sz.w * CELL_SIZE, 2)
	bw.color = wc.darkened(0.15); _parent.add_child(bw); _floor_nodes.append(bw)

	var lw := ColorRect.new()
	lw.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	lw.size = Vector2(2, sz.h * CELL_SIZE)
	lw.color = wc.darkened(0.1); _parent.add_child(lw); _floor_nodes.append(lw)

	var rw := ColorRect.new()
	rw.position = Vector2((sz.x + sz.w - 1) * CELL_SIZE, sz.y * CELL_SIZE)
	rw.size = Vector2(2, sz.h * CELL_SIZE)
	rw.color = wc.darkened(0.2); _parent.add_child(rw); _floor_nodes.append(rw)

	# Glow
	var glow := Sprite2D.new()
	glow.position = Vector2((sz.x + sz.w * 0.5) * CELL_SIZE, (sz.y - 6) * CELL_SIZE)
	glow.texture = _make_glow(def.light_color)
	_parent.add_child(glow); _floor_nodes.append(glow)

	# Sign
	var sign := _make_sign(def, sz.w, sz.h)
	sign.position = Vector2((sz.x + sz.w * 0.5) * CELL_SIZE, (sz.y + 1) * CELL_SIZE)
	_parent.add_child(sign); _floor_nodes.append(sign)

	# Create SupermarketSection node
	var sec := preload("res://scripts/section.gd").new()
	sec.configure(def)
	sec.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	sec.name = "Section_%s" % def.id
	_parent.add_child(sec)
	_sections.append(sec)

	# Section label at bottom
	var lbl := Label.new()
	lbl.text = def.name
	lbl.position = Vector2((sz.x + 1) * CELL_SIZE, (sz.y + sz.h + 1) * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(def.light_color.r * 0.7, def.light_color.g * 0.7, def.light_color.b * 0.7, 0.8))
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.z_index = 6
	_parent.add_child(lbl); _aisle_labels.append(lbl)


func _build_checkout_if_needed() -> void:
	if not _floor_def.has_checkout:
		return
	var lanes := StoreData.CHECKOUT_LANES
	var CHECKOUT_Y := StoreData.CHECKOUT_Y
	var counter_id := 0
	for lane in lanes:
		# Filter: only lanes valid for this floor
		var lane_floors: Array = lane.get("floors", [])
		if not lane_floors.is_empty() and not lane_floors.has(_floor_idx):
			continue

		var ctype_str: String = lane.get("type", "staffed")
		var ctype: CheckoutCounter.CheckoutType
		match ctype_str:
			"self":
				ctype = CheckoutCounter.CheckoutType.SELF
			"express":
				ctype = CheckoutCounter.CheckoutType.EXPRESS
			_:
				ctype = CheckoutCounter.CheckoutType.STAFFED

		var counter := CheckoutCounter.new()
		counter.configure(counter_id, ctype)
		counter.position = Vector2(lane["x"] * CELL_SIZE, (CHECKOUT_Y + 2) * CELL_SIZE)
		counter.name = "Counter_%s" % lane["name"]
		counter.checkout_interacted.connect(_on_checkout_interacted)
		counter.express_rejected.connect(_on_express_rejected)
		counter.self_checkout_error.connect(_on_self_checkout_error)
		counter.self_checkout_cleared.connect(_on_self_checkout_cleared)
		_parent.add_child(counter)
		_checkout_counters.append(counter)
		counter_id += 1

func _on_checkout_interacted(checkout_id: int, ctype) -> void:
	# Forward to main via signal (main listens to floor_builder parent)
	pass





func _build_floor_sign() -> void:
	var sign_bg := ColorRect.new()
	sign_bg.position = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
	sign_bg.size = Vector2(8 * CELL_SIZE, 2 * CELL_SIZE)
	sign_bg.color = Color(0.06, 0.06, 0.10, 0.85)
	_parent.add_child(sign_bg); _floor_nodes.append(sign_bg)

	var theme_lbl := Label.new()
	theme_lbl.text = "Floor %s — %s" % [_floor_def.label, _floor_def.theme.replace("_", " ").capitalize()]
	theme_lbl.position = Vector2(2.5 * CELL_SIZE, 2.3 * CELL_SIZE)
	theme_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.60))
	theme_lbl.add_theme_font_size_override("font_size", 8)
	_parent.add_child(theme_lbl); _floor_nodes.append(theme_lbl)


func _build_shaft_visuals() -> void:
	if not _floor_def.has_elevator:
		return
	# Floor indicator dots in shaft
	var shaft_x := FloorConfig.STAIRS_RIGHT_X - 6  # approx elevator x
	for floor_i in range(FloorConfig.floor_count()):
		var fy := _floor_y_in_shaft(floor_i)
		var dot := ColorRect.new()
		dot.position = Vector2((shaft_x + 0.5) * CELL_SIZE, fy)
		dot.size = Vector2(CELL_SIZE, 4)
		var is_current := (floor_i == _floor_def.index)
		dot.color = Color(0.20, 0.85, 0.45) if is_current else Color(0.40, 0.38, 0.35)
		_parent.add_child(dot); _floor_nodes.append(dot)

func _floor_y_in_shaft(floor_idx: int) -> float:
	var base_y := (WORLD_H - 6) * CELL_SIZE
	var floor_spacing := 4.0 * CELL_SIZE
	return base_y - floor_idx * floor_spacing




func _get_wall_base_color() -> Color:
	return Color(0.38, 0.35, 0.32)

func _get_section_floor(style: int) -> Color:
	match style:
		StoreData.SectionStyle.FRIDGE:   return Color(0.14, 0.18, 0.24)
		StoreData.SectionStyle.PRODUCE:  return Color(0.14, 0.19, 0.12)
		StoreData.SectionStyle.BAKERY:  return Color(0.20, 0.15, 0.10)
		StoreData.SectionStyle.SHELF:    return Color(0.17, 0.16, 0.15)
		StoreData.SectionStyle.DELI:     return Color(0.19, 0.13, 0.13)
		StoreData.SectionStyle.FREEZER:  return Color(0.12, 0.16, 0.22)
	return Color(0.18, 0.17, 0.16)

func _get_section_wall_color(style: int) -> Color:
	match style:
		StoreData.SectionStyle.FRIDGE:   return Color(0.60, 0.78, 0.95)
		StoreData.SectionStyle.PRODUCE:  return Color(0.60, 0.82, 0.50)
		StoreData.SectionStyle.BAKERY:   return Color(0.82, 0.62, 0.38)
		StoreData.SectionStyle.SHELF:    return Color(0.72, 0.65, 0.55)
		StoreData.SectionStyle.DELI:     return Color(0.88, 0.55, 0.52)
		StoreData.SectionStyle.FREEZER:  return Color(0.55, 0.78, 0.95)
	return Color(0.65, 0.60, 0.50)


func _make_glow(col: Color) -> Texture2D:
	var sz := 48
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := col.darkened(0.2)
	for y in range(sz):
		for x in range(sz):
			var d := Vector2(x - sz * 0.5, y - sz * 0.5).length() / (sz * 0.5)
			if d < 1.0:
				var a := (1.0 - d) * 0.35 * c.a
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return ImageTexture.create_from_image(img)

func _make_sign(def, w: int, h: int) -> Sprite2D:
	var img := Image.create(80, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_sign_rect(img, 0, 0, 80, 12, _get_section_wall_color(def.style).darkened(0.3))
	_fill_sign_rect(img, 0, 0, 80, 1, def.light_color.darkened(0.2))
	_fill_sign_rect(img, 0, 11, 80, 1, def.light_color.darkened(0.4))
	_fill_sign_rect(img, 0, 0, 1, 12, def.light_color.darkened(0.2))
	_fill_sign_rect(img, 79, 0, 1, 12, def.light_color.darkened(0.4))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.z_index = 5
	return spr

func _fill_sign_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, 80); y = clampi(y, 0, 12)
	w = clampi(w, 0, 80 - x); h = clampi(h, 0, 12 - y)
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _make_plush_texture(col: Color) -> Texture2D:
	# Small plush toy sprite for prize shelves
	var sz := 12
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(sz):
		for x in range(sz):
			var cx := float(x) - sz * 0.5
			var cy := float(y) - sz * 0.5
			var r := sz * 0.44
			if cx * cx + cy * cy < r * r:
				img.set_pixel(x, y, col)
	# Eyes
	for ey in [sz >> 2, sz >> 2 + 2]:
		for ex in [sz >> 2 - 1, sz - (sz >> 2) + 1]:
			if ex >= 0 and ex < sz and ey >= 0 and ey < sz:
				img.set_pixel(ex, ey, Color(0.05, 0.05, 0.05))
	return ImageTexture.create_from_image(img)

func _make_lantern() -> Texture2D:
	# Red paper lantern texture
	var sz := 20
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var red := Color(0.88, 0.25, 0.20, 0.9)
	for y in range(sz):
		for x in range(sz):
			var cx := x - sz / 2.0
			var cy := y - sz / 2.0
			var r := sz / 2.0 - 1.0
			if cx * cx + cy * cy < r * r:
				var brightness := 1.0 - (absf(cy) / r) * 0.3
				img.set_pixel(x, y, Color(red.r * brightness, red.g * brightness, red.b * brightness, red.a))
	return ImageTexture.create_from_image(img)


# Display racks for shoes — ladies, mens, kids, sport, sandals
func _build_zone_shoes_rack(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SHOES")
	var zone_color: Color = zone.meta.get("color", Color(0.70, 0.60, 0.55))
	var cx := zone.x * CELL_SIZE
	var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE
	var ch := zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3)
	_parent.add_child(bg); _floor_nodes.append(bg)

	# Section name label
	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	title_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

	# Shoe rack display — 4 shelves of shoe boxes
	var shelf_h := ch * 0.18
	for row in range(4):
		var shelf_y := cy + 8 + row * (ch * 0.22)
		# Shelf plank
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 4, shelf_y)
		plank.size = Vector2(cw - 8, 2)
		plank.color = zone_color.darkened(0.4)
		_parent.add_child(plank); _floor_nodes.append(plank)
		# Shoe boxes on shelf
		for col in range(6):
			var box_x := cx + 8 + col * ((cw - 16) / 6.0)
			var box := ColorRect.new()
			box.position = Vector2(box_x, shelf_y - 8)
			box.size = Vector2((cw - 16) / 6.5, 10)
			box.color = zone_color.darkened(0.2) if (col % 2 == 0) else zone_color.lightened(0.15)
			_parent.add_child(box); _floor_nodes.append(box)
			# Sole
			var sole := ColorRect.new()
			sole.position = Vector2(box_x + 1, shelf_y + 1)
			sole.size = Vector2((cw - 16) / 6.5 - 2, 2)
			sole.color = Color(0.20, 0.18, 0.16)
			_parent.add_child(sole); _floor_nodes.append(sole)

# Clothing racks for dresses / fashion wear