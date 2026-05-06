extends Node2D
class_name FloorBuilder

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")
const FoodStallScript = preload("res://scripts/food_stall.gd")
const ClawMachineScript = preload("res://scripts/claw_machine.gd")

const CELL_SIZE = 16
const WORLD_W  = 96
const WORLD_H  = 50
func _build_zone_entertainment(zone: FloorConfig.Zone) -> void:
	var bg = ColorRect.new()
	bg.color = zone.get("color", Color(0.25, 0.20, 0.35))
	bg.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_floor_node.add_child(bg)
	# Neon strip lights along ceiling
	for xi in range(0, zone.w, 6):
		var neon = ColorRect.new()
		neon.color = Color(0.6, 0.1, 0.8, 0.8)
		neon.size = Vector2(4, 2)
		neon.position = Vector2((zone.x + xi) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
		_floor_node.add_child(neon)

func _build_zone_canteen(zone: FloorConfig.Zone) -> void:
	var base = ColorRect.new()
	base.color = zone.get("color", Color(0.55, 0.50, 0.42))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_floor_node.add_child(base)
	# Long serving counter
	var counter = ColorRect.new()
	counter.color = Color(0.65, 0.60, 0.50)
	counter.size = Vector2(zone.w * CELL_SIZE, 6)
	counter.position = Vector2(zone.x * CELL_SIZE, (zone.y + 4) * CELL_SIZE)
	_floor_node.add_child(counter)
	# Counter top (food trays)
	var ctop = ColorRect.new()
	ctop.color = Color(0.75, 0.72, 0.65)
	ctop.size = Vector2(zone.w * CELL_SIZE, 2)
	ctop.position = Vector2(zone.x * CELL_SIZE, (zone.y + 4) * CELL_SIZE)
	_floor_node.add_child(ctop)
	# Tables (every 8 tiles)
	for ti in range(4, zone.w - 4, 8):
		for row in range(2):
			var table = ColorRect.new()
			table.color = Color(0.50, 0.45, 0.38)
			table.size = Vector2(6 * CELL_SIZE, 4 * CELL_SIZE)
			table.position = Vector2((zone.x + ti) * CELL_SIZE, (zone.y + 10 + row * 10) * CELL_SIZE)
			_floor_node.add_child(table)
			# Table leg
			var leg = ColorRect.new()
			leg.color = Color(0.35, 0.30, 0.25)
			leg.size = Vector2(CELL_SIZE, CELL_SIZE)
			leg.position = Vector2((zone.x + ti + 2) * CELL_SIZE, (zone.y + 13 + row * 10) * CELL_SIZE)
			_floor_node.add_child(leg)

func _build_zone_karaoke(zone: FloorConfig.Zone) -> void:
	var base = ColorRect.new()
	base.color = zone.get("color", Color(0.20, 0.15, 0.28))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_floor_node.add_child(base)
	# Individual karaoke room dividers
	var room_w = 14
	var rooms = zone.w // room_w
	for r in range(rooms):
		var room_bg = ColorRect.new()
		room_bg.color = Color(0.18 + r * 0.04, 0.12, 0.22 + r * 0.03)
		room_bg.size = Vector2((room_w - 1) * CELL_SIZE, (zone.h - 4) * CELL_SIZE)
		room_bg.position = Vector2((zone.x + 1 + r * room_w) * CELL_SIZE, (zone.y + 2) * CELL_SIZE)
		_floor_node.add_child(room_bg)
		# Room number
		var lbl = Label.new()
		lbl.text = "%d" % (r + 1)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.9))
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.position = Vector2((zone.x + 5 + r * room_w) * CELL_SIZE, (zone.y + 3) * CELL_SIZE)
		_floor_node.add_child(lbl)
		# Mic icon (speaker shape)
		var mic_bg = ColorRect.new()
		mic_bg.color = Color(0.7, 0.1, 0.6, 0.6)
		mic_bg.size = Vector2(3 * CELL_SIZE, 3 * CELL_SIZE)
		mic_bg.position = Vector2((zone.x + 5 + r * room_w) * CELL_SIZE, (zone.y + 8) * CELL_SIZE)
		_floor_node.add_child(mic_bg)

func _build_zone_pool_table(zone: FloorConfig.Zone) -> void:
	var base = ColorRect.new()
	base.color = zone.get("color", Color(0.28, 0.52, 0.38))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_floor_node.add_child(base)
	# Table surface (green felt)
	var felt = ColorRect.new()
	felt.color = Color(0.30, 0.60, 0.38)
	felt.size = Vector2(16 * CELL_SIZE, 8 * CELL_SIZE)
	felt.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_floor_node.add_child(felt)
	# Rails (cushions)
	for rail in [
		(0, -1, 16, 1),
		(0, 8, 16, 1),
		(-1, 0, 1, 8),
		(16, 0, 1, 8),
	]:
		var r = ColorRect.new()
		r.color = Color(0.40, 0.25, 0.15)
		r.size = Vector2(rail[2] * CELL_SIZE, rail[3] * CELL_SIZE)
		r.position = Vector2((zone.x + rail[0]) * CELL_SIZE, (zone.y + rail[1]) * CELL_SIZE)
		_floor_node.add_child(r)
	# Corner pockets
	for px, py in [(0,0),(15,0),(0,7),(15,7)]:
		var pocket = ColorRect.new()
		pocket.color = Color(0.05, 0.05, 0.05)
		pocket.size = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
		pocket.position = Vector2((zone.x + px) * CELL_SIZE, (zone.y + py) * CELL_SIZE)
		_floor_node.add_child(pocket)
	# Balls (colored dots)
	var ball_colors = [Color(1,1,1), Color(1,0.8,0), Color(0,0,0.8), Color(0.8,0,0), Color(0.9,0.4,0), Color(0.2,0.5,0.2), Color(0.7,0.1,0.1), Color(0.8,0.3,0.3), Color(0.1,0.1,0.5)]
	for i, (bx, by) in enumerate([(3,1),(5,2),(7,3),(4,4),(6,3),(3,5),(5,5),(2,3),(4,2)]):
		if i < len(ball_colors):
			var ball = ColorRect.new()
			ball.color = ball_colors[i]
			ball.size = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
			ball.position = Vector2((zone.x + bx) * CELL_SIZE, (zone.y + by) * CELL_SIZE)
			_floor_node.add_child(ball)

func _build_zone_darts_board(zone: FloorConfig.Zone) -> void:
	var base = ColorRect.new()
	base.color = zone.get("color", Color(0.30, 0.32, 0.25))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_floor_node.add_child(base)
	# Dartboard - concentric circles
	var cx = zone.x + zone.w // 2
	var cy = zone.y + zone.h // 2
	var radii = [8, 6, 4, 2]  # outer to inner
	var colors = [Color(0.1, 0.5, 0.1), Color(0.8, 0.8, 0.8), Color(0.8, 0.1, 0.1), Color(0.1, 0.7, 0.1)]
	for r, col in zip(radii, colors):
		var circle = ColorRect.new()
		circle.color = col
		circle.size = Vector2(r * 2 * CELL_SIZE, r * 2 * CELL_SIZE)
		circle.position = Vector2((cx - r) * CELL_SIZE, (cy - r) * CELL_SIZE)
		_floor_node.add_child(circle)
	# Bullseye
	var bull = ColorRect.new()
	bull.color = Color(0.9, 0.2, 0.2)
	bull.size = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
	bull.position = Vector2(cx * CELL_SIZE, cy * CELL_SIZE)
	_floor_node.add_child(bull)


func _build_zone_wall(zone: FloorConfig.Zone) -> void:
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = _get_wall_base_color()
	_parent.add_child(r)
	_floor_nodes.append(r)

func _build_zone_aisle(zone: FloorConfig.Zone) -> void:
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = Color(0.20, 0.19, 0.18)
	_parent.add_child(r)
	_floor_nodes.append(r)

func _build_zone_lobby(zone: FloorConfig.Zone) -> void:
	# Lobby floor — slightly warmer
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = Color(0.22, 0.20, 0.18)
	_parent.add_child(r)
	_floor_nodes.append(r)

	# Decorative lobby floor stripe
	var stripe := ColorRect.new()
	stripe.position = Vector2(zone.x * CELL_SIZE, (zone.y + zone.h - 1) * CELL_SIZE)
	stripe.size = Vector2(zone.w * CELL_SIZE, 2)
	stripe.color = Color(0.30, 0.27, 0.24)
	_parent.add_child(stripe)
	_floor_nodes.append(stripe)



func _build_zone_parking(zone: FloorConfig.Zone) -> void:
	# Parking level base — dark asphalt
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.color = Color(0.18, 0.18, 0.20)
	_parent.add_child(base)
	_floor_nodes.append(base)

	# Parking slot rows (every 4 tiles down)
	const SLOT_W := 6
	const SLOT_H := 3
	const SLOT_GAP := 1
	const NUM_SLOTS := 10
	var sx := zone.x + 2
	var sy := zone.y + 2
	var slot_idx := 0
	while sy + SLOT_H < zone.y + zone.h - 2 and slot_idx < NUM_SLOTS:
		# Slot bay
		var bay := ColorRect.new()
		bay.position = Vector2(sx * CELL_SIZE, sy * CELL_SIZE)
		bay.size = Vector2(SLOT_W * CELL_SIZE, SLOT_H * CELL_SIZE)
		bay.color = Color(0.21, 0.21, 0.23)
		_parent.add_child(bay)
		_floor_nodes.append(bay)

		# White slot lines
		for side in [sx, sx + SLOT_W - 1]:
			var line := ColorRect.new()
			line.position = Vector2(side * CELL_SIZE, sy * CELL_SIZE)
			line.size = Vector2(1, SLOT_H * CELL_SIZE)
			line.color = Color(0.80, 0.80, 0.80, 0.4)
			_parent.add_child(line)
			_floor_nodes.append(line)

		# Top/bottom lines
		var top_l := ColorRect.new()
		top_l.position = Vector2(sx * CELL_SIZE, sy * CELL_SIZE)
		top_l.size = Vector2(SLOT_W * CELL_SIZE, 1)
		top_l.color = Color(0.80, 0.80, 0.80, 0.4)
		_parent.add_child(top_l)
		_floor_nodes.append(top_l)

		var bot_l := ColorRect.new()
		bot_l.position = Vector2(sx * CELL_SIZE, (sy + SLOT_H - 1) * CELL_SIZE)
		bot_l.size = Vector2(SLOT_W * CELL_SIZE, 1)
		bot_l.color = Color(0.80, 0.80, 0.80, 0.4)
		_parent.add_child(bot_l)
		_floor_nodes.append(bot_l)

		# Slot number
		var num_lbl := Label.new()
		num_lbl.text = "%d" % (slot_idx + 1)
		num_lbl.position = Vector2((sx + SLOT_W * 0.5 - 0.5) * CELL_SIZE, (sy + SLOT_H * 0.5 - 0.5) * CELL_SIZE)
		num_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
		num_lbl.add_theme_font_size_override("font_size", 8)
		_parent.add_child(num_lbl)
		_floor_nodes.append(num_lbl)

		# 3 NPC cars in first 3 slots
		if slot_idx < 3:
			_add_parked_car(sx + SLOT_W // 2 - 1, sy + SLOT_H // 2, slot_idx)

		sx += SLOT_W + SLOT_GAP
		if sx + SLOT_W > zone.x + zone.w - 2:
			sx = zone.x + 2
			sy += SLOT_H + SLOT_GAP
		slot_idx += 1

func _add_parked_car(tile_x: int, tile_y: int, color_idx: int) -> void:
	var colors := [Color(0.75, 0.22, 0.18), Color(0.25, 0.40, 0.75), Color(0.30, 0.60, 0.30)]
	var col := colors[color_idx % 3]
	var img := Image.create(5 * CELL_SIZE, 3 * CELL_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_img(img, CELL_SIZE, CELL_SIZE >> 1, CELL_SIZE * 3, CELL_SIZE, col)
	_fill_img(img, CELL_SIZE * 3 >> 1, 0, CELL_SIZE * 2, CELL_SIZE >> 1, col.darkened(0.15))
	_fill_img(img, CELL_SIZE * 5 >> 1, CELL_SIZE >> 2, CELL_SIZE, CELL_SIZE >> 1, Color(0.50, 0.70, 0.85))
	_fill_img(img, CELL_SIZE, (CELL_SIZE * 3) >> 2, CELL_SIZE, CELL_SIZE >> 2, Color(0.12, 0.12, 0.12))
	_fill_img(img, CELL_SIZE * 3, (CELL_SIZE * 3) >> 2, CELL_SIZE, CELL_SIZE >> 2, Color(0.12, 0.12, 0.12))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.position = Vector2((tile_x + 0.5) * CELL_SIZE, (tile_y + 0.5) * CELL_SIZE)
	spr.z_index = 3
	_parent.add_child(spr)
	_floor_nodes.append(spr)

func _fill_img(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, img.get_width()); y = clampi(y, 0, img.get_height())
	w = clampi(w, 0, img.get_width() - x); h = clampi(h, 0, img.get_height() - y)
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _build_zone_wc(zone: FloorConfig.Zone) -> void:
	# WC booth background
	var bg := ColorRect.new()
	bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	bg.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	bg.color = Color(0.18, 0.20, 0.24)
	_parent.add_child(bg)
	_floor_nodes.append(bg)

	# WC door (centered on bottom edge)
	var door := ColorRect.new()
	door.position = Vector2((zone.x + 2) * CELL_SIZE, (zone.y + zone.h - 3) * CELL_SIZE)
	door.size = Vector2(2 * CELL_SIZE, 3 * CELL_SIZE)
	door.color = Color(0.50, 0.48, 0.55)
	_parent.add_child(door)
	_floor_nodes.append(door)

	# WC label
	var lbl := Label.new()
	lbl.text = "WC"
	lbl.position = Vector2((zone.x + zone.w * 0.5 - 1.5) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	lbl.add_theme_font_size_override("font_size", 9)
	_parent.add_child(lbl)
	_floor_nodes.append(lbl)

	# "Press E" hint
	var hint := Label.new()
	hint.text = "[E] Use"
	hint.position = Vector2((zone.x + 1) * CELL_SIZE, (zone.y + zone.h - 3) * CELL_SIZE + 2)
	hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.60))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint)
	_floor_nodes.append(hint)

	# Walls
	var wc := _get_wall_base_color()
	var top_w := ColorRect.new()
	top_w.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	top_w.size = Vector2(zone.w * CELL_SIZE, 2)
	top_w.color = wc
	_parent.add_child(top_w); _floor_nodes.append(top_w)
	var bot_w := ColorRect.new()
	bot_w.position = Vector2(zone.x * CELL_SIZE, (zone.y + zone.h - 2) * CELL_SIZE)
	bot_w.size = Vector2(zone.w * CELL_SIZE, 2)
	bot_w.color = wc.darkened(0.2)
	_parent.add_child(bot_w); _floor_nodes.append(bot_w)
	var l_w := ColorRect.new()
	l_w.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	l_w.size = Vector2(2, zone.h * CELL_SIZE)
	l_w.color = wc.darkened(0.1)
	_parent.add_child(l_w); _floor_nodes.append(l_w)
	var r_w := ColorRect.new()
	r_w.position = Vector2((zone.x + zone.w - 2) * CELL_SIZE, zone.y * CELL_SIZE)
	r_w.size = Vector2(2, zone.h * CELL_SIZE)
	r_w.color = wc.darkened(0.2)
	_parent.add_child(r_w); _floor_nodes.append(r_w)

func _build_zone_info_desk(zone: FloorConfig.Zone) -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	bg.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	bg.color = Color(0.28, 0.24, 0.22)
	_parent.add_child(bg)
	_floor_nodes.append(bg)

	# Desk counter top
	var top_c := ColorRect.new()
	top_c.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	top_c.size = Vector2(zone.w * CELL_SIZE, 2)
	top_c.color = Color(0.55, 0.48, 0.40)
	_parent.add_child(top_c); _floor_nodes.append(top_c)

	# Info sign
	var sign := Label.new()
	sign.text = "INFORMATION"
	sign.position = Vector2((zone.x + 1) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
	sign.add_theme_color_override("font_color", Color(0.90, 0.85, 0.60))
	sign.add_theme_font_size_override("font_size", 8)
	_parent.add_child(sign); _floor_nodes.append(sign)

	# Floor directory
	var dir := Label.new()
	dir.text = _get_floor_directory()
	dir.position = Vector2((zone.x + 1) * CELL_SIZE, (zone.y + 2.5) * CELL_SIZE)
	dir.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55))
	dir.add_theme_font_size_override("font_size", 7)
	_parent.add_child(dir); _floor_nodes.append(dir)

func _get_floor_directory() -> String:
	return "F1:Fresh  F2:Pantry\nF3:Drinks  F4:Snacks\nF5:Frozen  F6:Home\nF7:Health  F8:Arcade\nF9:Staff  F10:Cafe"

func _build_zone_food_stall(zone: FloorConfig.Zone) -> void:
	var stall_id: String = zone.meta.get("stall_id", "jp_ramen")
	var fd: FloorConfig.FoodStallDef = FloorConfig.get_stall_def(stall_id)

	# ── Stall base floor ──────────────────────────────────────────
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.color = fd.color.darkened(0.78)
	_parent.add_child(base)
	_floor_nodes.append(base)

	# ── Counter (front edge, 3 tiles tall) ───────────────────────
	var counter := ColorRect.new()
	counter.position = Vector2(zone.x * CELL_SIZE, (zone.y + zone.h - 3) * CELL_SIZE)
	counter.size = Vector2(zone.w * CELL_SIZE, 3 * CELL_SIZE)
	counter.color = fd.color.darkened(0.45)
	_parent.add_child(counter)
	_floor_nodes.append(counter)

	# Counter top ledge (bright surface)
	var counter_top := ColorRect.new()
	counter_top.position = Vector2(zone.x * CELL_SIZE, (zone.y + zone.h - 3) * CELL_SIZE)
	counter_top.size = Vector2(zone.w * CELL_SIZE, 2)
	counter_top.color = fd.color.lightened(0.25)
	_parent.add_child(counter_top)
	_floor_nodes.append(counter_top)

	# ── Product samples on counter (decorative colored squares) ──
	var sample_y := (zone.y + zone.h - 4) * CELL_SIZE
	for i in range(mini(fd.menu.size(), 4)):
		var item: Dictionary = fd.menu[i]
		var spx := (zone.x + 1 + i * 3) * CELL_SIZE
		var samp := ColorRect.new()
		samp.position = Vector2(spx, sample_y)
		samp.size = Vector2(CELL_SIZE * 2, CELL_SIZE)
		samp.color = fd.glow_color.darkened(0.3 + i * 0.1)
		_parent.add_child(samp)
		_floor_nodes.append(samp)
		# Price tag
		var price_lbl := Label.new()
		price_lbl.text = "$%.1f" % item.price
		price_lbl.position = Vector2(spx, sample_y - 10)
		price_lbl.add_theme_color_override("font_color", fd.glow_color.lightened(0.2))
		price_lbl.add_theme_font_size_override("font_size", 6)
		_parent.add_child(price_lbl)
		_floor_nodes.append(price_lbl)

	# ── Back wall (top section with menu board) ──────────────────
	var wall_h := zone.h - 3  # counter takes bottom 3 tiles
	var wc := fd.color.darkened(0.3)

	# Back wall base
	var bw_bg := ColorRect.new()
	bw_bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	bw_bg.size = Vector2(zone.w * CELL_SIZE, wall_h * CELL_SIZE)
	bw_bg.color = wc.darkened(0.1)
	_parent.add_child(bw_bg); _floor_nodes.append(bw_bg)

	# Top stripe
	var tw := ColorRect.new()
	tw.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	tw.size = Vector2(zone.w * CELL_SIZE, 2)
	tw.color = wc
	_parent.add_child(tw); _floor_nodes.append(tw)

	# Side walls
	var lw := ColorRect.new()
	lw.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	lw.size = Vector2(2, zone.h * CELL_SIZE)
	lw.color = wc.darkened(0.1)
	_parent.add_child(lw); _floor_nodes.append(lw)

	var rw := ColorRect.new()
	rw.position = Vector2((zone.x + zone.w - 2) * CELL_SIZE, zone.y * CELL_SIZE)
	rw.size = Vector2(2, zone.h * CELL_SIZE)
	rw.color = wc.darkened(0.2)
	_parent.add_child(rw); _floor_nodes.append(rw)

	# Bottom wall strip (above counter)
	var bot_wall := ColorRect.new()
	bot_wall.position = Vector2(zone.x * CELL_SIZE, (zone.y + zone.h - 1) * CELL_SIZE)
	bot_wall.size = Vector2(zone.w * CELL_SIZE, 1)
	bot_wall.color = wc.darkened(0.2)
	_parent.add_child(bot_wall); _floor_nodes.append(bot_wall)

	# ── Menu board on back wall ──────────────────────────────────
	# Small blackboard-style panel
	var board_x := (zone.x + 1) * CELL_SIZE
	var board_y := (zone.y + 1) * CELL_SIZE
	var board_w := (zone.w - 2) * CELL_SIZE
	var board_h := (wall_h - 2) * CELL_SIZE
	if board_w > 0 and board_h > 0:
		var board := ColorRect.new()
		board.position = Vector2(board_x, board_y)
		board.size = Vector2(board_w, board_h)
		board.color = Color(0.05, 0.12, 0.08)  # dark green chalkboard
		_parent.add_child(board); _floor_nodes.append(board)

		# Menu item labels on board (show first 3 items)
		for i in range(mini(fd.menu.size(), 3)):
			var item: Dictionary = fd.menu[i]
			var item_lbl := Label.new()
			item_lbl.text = "  %s  $%.1f" % [item.name, item.price]
			item_lbl.position = Vector2(board_x + 2, board_y + i * (board_h / 3) + 2)
			item_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.80))
			item_lbl.add_theme_font_size_override("font_size", 6)
			_parent.add_child(item_lbl)
			_floor_nodes.append(item_lbl)

	# ── Brand glow lantern above stall ───────────────────────────
	var glow := Sprite2D.new()
	glow.position = Vector2((zone.x + zone.w * 0.5) * CELL_SIZE, (zone.y - 7) * CELL_SIZE)
	glow.texture = _make_glow(fd.glow_color)
	_parent.add_child(glow)
	_floor_nodes.append(glow)

	# ── Stall name sign (on front of counter) ───────────────────
	var name_lbl := Label.new()
	name_lbl.text = fd.name
	name_lbl.position = Vector2((zone.x + 1) * CELL_SIZE, (zone.y + zone.h - 2.5) * CELL_SIZE)
	name_lbl.add_theme_color_override("font_color", fd.color.lightened(0.35))
	name_lbl.add_theme_font_size_override("font_size", 7)
	_parent.add_child(name_lbl); _floor_nodes.append(name_lbl)

	# Cuisine country tag
	var cuisine_lbl := Label.new()
	cuisine_lbl.text = fd.cuisine
	cuisine_lbl.position = Vector2((zone.x + 1) * CELL_SIZE, (zone.y + zone.h - 1.8) * CELL_SIZE)
	cuisine_lbl.add_theme_color_override("font_color", fd.color.lightened(0.15))
	cuisine_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(cuisine_lbl); _floor_nodes.append(cuisine_lbl)

	# ── [E] Order hint ──────────────────────────────────────────
	var hint := Label.new()
	hint.text = "[E] Order"
	hint.position = Vector2((zone.x + zone.w - 5) * CELL_SIZE, (zone.y + zone.h - 2.5) * CELL_SIZE)
	hint.add_theme_color_override("font_color", fd.glow_color.lightened(0.3))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

	# ── FoodStall interaction node ──────────────────────────────
	var stall_node := FoodStallScript.new()
	stall_node.configure(fd, zone)
	stall_node.name = "Stall_%s" % stall_id
	_parent.add_child(stall_node)
	_food_stalls.append(stall_node)

func _build_zone_food_court(zone: FloorConfig.Zone) -> void:
	# Open dining court floor
	var floor_c := ColorRect.new()
	floor_c.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	floor_c.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	floor_c.color = Color(0.24, 0.20, 0.18)
	_parent.add_child(floor_c)
	_floor_nodes.append(floor_c)

	# Central lantern row (decorative)
	for i in range(4):
		var lx := (zone.x + 10 + i * 16) * CELL_SIZE
		var ly := (zone.y + 3) * CELL_SIZE
		var lantern := Sprite2D.new()
		lantern.position = Vector2(lx, ly)
		lantern.texture = _make_lantern()
		lantern.z_index = 4
		_parent.add_child(lantern)
		_floor_nodes.append(lantern)

	# Dining tables cluster
	var table_positions := [
		Vector2i(zone.x + 20, zone.y + 10),
		Vector2i(zone.x + 32, zone.y + 10),
		Vector2i(zone.x + 44, zone.y + 10),
		Vector2i(zone.x + 20, zone.y + 22),
		Vector2i(zone.x + 32, zone.y + 22),
		Vector2i(zone.x + 44, zone.y + 22),
	]
	for tp in table_positions:
		_build_dining_table(tp.x, tp.y)

	# "Food Court" floor label
	var court_lbl := Label.new()
	court_lbl.text = "DINING COURT"
	court_lbl.position = Vector2((zone.x + zone.w * 0.5 - 5) * CELL_SIZE, (zone.y + zone.h - 3) * CELL_SIZE)
	court_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.50, 0.6))
	court_lbl.add_theme_font_size_override("font_size", 8)
	_parent.add_child(court_lbl); _floor_nodes.append(court_lbl)

func _build_dining_table(tile_x: int, tile_y: int) -> void:
	# Table top
	var top := ColorRect.new()
	top.position = Vector2(tile_x * CELL_SIZE, tile_y * CELL_SIZE)
	top.size = Vector2(3 * CELL_SIZE, 2 * CELL_SIZE)
	top.color = Color(0.52, 0.48, 0.42)
	_parent.add_child(top); _floor_nodes.append(top)

	# Chairs (small squares around table)
	var chair_offsets := [
		Vector2i(0, -1), Vector2i(2, -1),
		Vector2i(0, 2),  Vector2i(2, 2),
		Vector2i(-1, 0), Vector2i(3, 0),
	]
	for co in chair_offsets:
		var chair := ColorRect.new()
		chair.position = Vector2((tile_x + co.x) * CELL_SIZE, (tile_y + co.y) * CELL_SIZE)
		chair.size = Vector2(CELL_SIZE, CELL_SIZE)
		chair.color = Color(0.45, 0.42, 0.40)
		_parent.add_child(chair); _floor_nodes.append(chair)

func _build_zone_common(zone: FloorConfig.Zone) -> void:
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = Color(0.20, 0.19, 0.18)
	_parent.add_child(r); _floor_nodes.append(r)

func _build_zone_rooftop(zone: FloorConfig.Zone) -> void:
	# Sky-like open rooftop
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = Color(0.45, 0.60, 0.75, 1.0)
	_parent.add_child(r); _floor_nodes.append(r)

	# "ROOFTOP" large text
	var lbl := Label.new()
	lbl.text = "ROOFTOP CAFE"
	lbl.position = Vector2((zone.x + zone.w * 0.5 - 6) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.88, 0.80))
	lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(lbl); _floor_nodes.append(lbl)

	# Café tables
	for tx in range(zone.x + 4, zone.x + zone.w - 6, 10):
		for ty in range(zone.y + 6, zone.y + zone.h - 4, 8):
			_build_dining_table(tx, ty)

func _build_zone_shaft(zone: FloorConfig.Zone) -> void:
	# Elevator shaft visual column
	var shaft := ColorRect.new()
	shaft.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	shaft.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	shaft.color = Color(0.30, 0.27, 0.25)
	_parent.add_child(shaft); _floor_nodes.append(shaft)

	# Border lines
	var bl := ColorRect.new()
	bl.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	bl.size = Vector2(1, zone.h * CELL_SIZE)
	bl.color = Color(0.50, 0.45, 0.40)
	_parent.add_child(bl); _floor_nodes.append(bl)

	var br := ColorRect.new()
	br.position = Vector2((zone.x + zone.w - 1) * CELL_SIZE, zone.y * CELL_SIZE)
	br.size = Vector2(1, zone.h * CELL_SIZE)
	br.color = Color(0.40, 0.37, 0.35)
	_parent.add_child(br); _floor_nodes.append(br)

func _build_zone_stairs(zone: FloorConfig.Zone) -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	bg.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	bg.color = Color(0.28, 0.26, 0.24)
	_parent.add_child(bg); _floor_nodes.append(bg)

	# Step lines
	var n_steps := 12
	var step_h := (zone.h * CELL_SIZE) / n_steps
	for i in range(n_steps):
		var step_y := zone.y * CELL_SIZE + i * step_h
		var step_l := ColorRect.new()
		step_l.position = Vector2(zone.x * CELL_SIZE, step_y)
		step_l.size = Vector2(zone.w * CELL_SIZE, 2)
		step_l.color = Color(0.45, 0.42, 0.38)
		_parent.add_child(step_l); _floor_nodes.append(step_l)

	# "STAIRS" label
	var lbl := Label.new()
	lbl.text = "STAIRS"
	lbl.position = Vector2((zone.x + 0.5) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
	lbl.add_theme_font_size_override("font_size", 7)
	_parent.add_child(lbl); _floor_nodes.append(lbl)

# meta can specify: {decor_type: "dining_table"} or just renders as floor.
func _build_zone_decor(zone: FloorConfig.Zone) -> void:
	var decor_type: String = zone.meta.get("decor_type", "dining_table")
	match decor_type:
		"dining_table":
			_build_dining_table(zone.x, zone.y)
		"planter":
			_build_planter(zone.x, zone.y, zone.w, zone.h)
		"shelf":
			_build_prize_shelf(zone.x, zone.y, zone.w, zone.h)

		"canteen_tables":
			for ti in range(zone.w // 10):
				for row in range(2):
					_build_dining_table(zone.x + ti * 10, zone.y + row * 8)
		"arcade_machines":
			for ax in range(zone.w // 8):
				var cab := ColorRect.new()
				cab.color = Color(0.30, 0.25, 0.40)
				cab.size = Vector2(7 * CELL_SIZE, 10 * CELL_SIZE)
				cab.position = Vector2((zone.x + ax * 8) * CELL_SIZE, (zone.y + 2) * CELL_SIZE)
				_parent.add_child(cab); _floor_nodes.append(cab)
				var screen := ColorRect.new()
				screen.color = Color(0.20, 0.60, 0.80)
				screen.size = Vector2(5 * CELL_SIZE, 5 * CELL_SIZE)
				screen.position = Vector2((zone.x + ax * 8 + 1) * CELL_SIZE, (zone.y + 3) * CELL_SIZE)
				_parent.add_child(screen); _floor_nodes.append(screen)
		"lounge_seating":
			var lounge_bg := ColorRect.new()
			lounge_bg.color = Color(0.25, 0.20, 0.30)
			lounge_bg.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
			lounge_bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
			_parent.add_child(lounge_bg); _floor_nodes.append(lounge_bg)
			for sx in range(zone.w // 12):
				var seat := ColorRect.new()
				seat.color = Color(0.45, 0.30, 0.50)
				seat.size = Vector2(10 * CELL_SIZE, 6 * CELL_SIZE)
				seat.position = Vector2((zone.x + sx * 12) * CELL_SIZE, (zone.y + 2) * CELL_SIZE)
				_parent.add_child(seat); _floor_nodes.append(seat)
		"trash_bin":
			var bin := ColorRect.new()
			bin.color = Color(0.35, 0.45, 0.30)
			bin.size = Vector2(3 * CELL_SIZE, 3 * CELL_SIZE)
			bin.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
			_parent.add_child(bin); _floor_nodes.append(bin)
		_:
			# Generic floor patch
			var r := ColorRect.new()
			r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
			r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
			r.color = Color(0.22, 0.20, 0.18)
			_parent.add_child(r); _floor_nodes.append(r)

func _build_planter(px: int, py: int, pw: int, ph: int) -> void:
	# Planter box
	var box := ColorRect.new()
	box.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	box.size = Vector2(pw * CELL_SIZE, ph * CELL_SIZE)
	box.color = Color(0.20, 0.16, 0.12)
	_parent.add_child(box); _floor_nodes.append(box)
	# Green top
	var top := ColorRect.new()
	top.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	top.size = Vector2(pw * CELL_SIZE, 2)
	top.color = Color(0.30, 0.52, 0.22)
	_parent.add_child(top); _floor_nodes.append(top)

func _build_prize_shelf(px: int, py: int, pw: int, ph: int) -> void:
	# Arcade prize display shelf — back panel + 3 rows of shelves
	# Back panel
	var back := ColorRect.new()
	back.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	back.size = Vector2(pw * CELL_SIZE, ph * CELL_SIZE)
	back.color = Color(0.08, 0.08, 0.14)
	_parent.add_child(back); _floor_nodes.append(back)

	# Neon trim
	var trim_col := Color(0.50, 0.30, 0.80)  # purple neon
	var trim_top := ColorRect.new()
	trim_top.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	trim_top.size = Vector2(pw * CELL_SIZE, 2)
	trim_top.color = trim_col
	_parent.add_child(trim_top); _floor_nodes.append(trim_top)

	# Shelf rows
	var row_colors := [
		Color(0.90, 0.30, 0.30),
		Color(0.30, 0.75, 0.90),
		Color(0.90, 0.70, 0.20),
	]
	for row in range(3):
		var shelf_y := (py + 1 + row * ((ph - 1) / 3)) * CELL_SIZE
		# Shelf plank
		var shelf := ColorRect.new()
		shelf.position = Vector2(px * CELL_SIZE, shelf_y)
		shelf.size = Vector2(pw * CELL_SIZE, 2)
		shelf.color = Color(0.40, 0.35, 0.30)
		_parent.add_child(shelf); _floor_nodes.append(shelf)

		# Plush prizes on shelf
		for col in range(3):
			var prize_x := (px + 1 + col * ((pw - 2) / 3)) * CELL_SIZE
			var prize_y := shelf_y - CELL_SIZE * 2
			var spr := Sprite2D.new()
			spr.position = Vector2(prize_x + CELL_SIZE, prize_y + CELL_SIZE)
			spr.texture = _make_plush_texture(row_colors[row])
			spr.z_index = 3
			_parent.add_child(spr); _floor_nodes.append(spr)

	# "PRIZES" neon sign
	var prize_lbl := Label.new()
	prize_lbl.text = "PRIZES"
	prize_lbl.position = Vector2((px + pw * 0.5 - 2) * CELL_SIZE, (py - 2) * CELL_SIZE)
	prize_lbl.add_theme_color_override("font_color", Color(0.80, 0.40, 1.0))
	prize_lbl.add_theme_font_size_override("font_size", 9)
	_parent.add_child(prize_lbl); _floor_nodes.append(prize_lbl)

# A cozy corner with kennels/cages for adoptable pets.
# meta: {name: String, color: Color}