# floor_builder.gd
# ═══════════════════════════════════════════════════════════════════════
# Data-driven floor renderer. Reads FloorDef + zones from floor_config.gd
# and builds all visual content. Add new zone types by implementing
# _build_<type>() and calling it from _build_zone().
# ═══════════════════════════════════════════════════════════════════════
class_name FloorBuilder
extends Node2D

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")
const FoodStallScript = preload("res://scripts/food_stall.gd")
const ClawMachineScript = preload("res://scripts/claw_machine.gd")

const CELL_SIZE := FloorConfig.CELL_SIZE
const WORLD_W  := FloorConfig.WORLD_W
const WORLD_H  := FloorConfig.WORLD_H

var _floor_def: FloorConfig.FloorDef
var _parent: Node
var _floor_nodes: Array = []
var _sections: Array = []
var _food_stalls: Array = []
var _claw_machines: Array = []
var _checkout_counters: Array = []
var _aisle_labels: Array = []

signal section_interacted(section_id: String)
signal stall_interacted(stall_id: String)

func _init() -> void:
	pass

# Entry point — build an entire floor.
func build(floor_def: FloorConfig.FloorDef, parent: Node) -> void:
	_floor_def = floor_def
	_parent = parent
	_floor_nodes.clear()
	_sections.clear()
	_food_stalls.clear()
	_claw_machines.clear()
	_checkout_counters.clear()
	_aisle_labels.clear()

	_build_world_bg()
	_build_zones()
	_build_section_zones()
	_build_checkout_if_needed()
	_build_floor_sign()
	_build_shaft_visuals()

# ─── World Background ────────────────────────────────────────────

func _build_world_bg() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE)
	bg.position = Vector2.ZERO
	bg.color = _floor_def.ambient_color.darkened(0.75)
	_parent.add_child(bg)
	_floor_nodes.append(bg)

# ─── Zone Router ────────────────────────────────────────────────

func _build_zones() -> void:
	for zone in _floor_def.zones:
		_build_zone(zone)

func _build_zone(zone: FloorConfig.Zone) -> void:
	match zone.type:
		FloorConfig.ZONE_WALL:         _build_zone_wall(zone)
		FloorConfig.ZONE_AISLE:        _build_zone_aisle(zone)
		FloorConfig.ZONE_LOBBY:        _build_zone_lobby(zone)
		FloorConfig.ZONE_PARKING:      _build_zone_parking(zone)
		FloorConfig.ZONE_WC:           _build_zone_wc(zone)
		FloorConfig.ZONE_INFO_DESK:    _build_zone_info_desk(zone)
		FloorConfig.ZONE_FOOD_STALL:   _build_zone_food_stall(zone)
		FloorConfig.ZONE_FOOD_COURT:   _build_zone_food_court(zone)
		FloorConfig.ZONE_COMMON:       _build_zone_common(zone)
		FloorConfig.ZONE_ROOFTOP:     _build_zone_rooftop(zone)
		FloorConfig.ZONE_ELEVATOR:     _build_zone_shaft(zone)
		FloorConfig.ZONE_STAIRS:       _build_zone_stairs(zone)
		FloorConfig.ZONE_DECOR:         _build_zone_decor(zone)
		FloorConfig.ZONE_CLAW_MACHINE:  _build_zone_claw_machine(zone)
		FloorConfig.ZONE_PET_ADOPTION:  _build_zone_pet_adoption(zone)
		FloorConfig.ZONE_WAREHOUSE:      _build_zone_warehouse(zone)
		FloorConfig.ZONE_STORAGE_SHELF:   _build_zone_storage_shelf(zone)
		FloorConfig.ZONE_ATM:           _build_zone_atm(zone)
		FloorConfig.ZONE_SHOES_RACK:    _build_zone_shoes_rack(zone)
		FloorConfig.ZONE_DRESS_RACK:    _build_zone_dress_rack(zone)
		FloorConfig.ZONE_SPORT_AREA:    _build_zone_sport_area(zone)
		FloorConfig.ZONE_OUTDOOR_AREA:  _build_zone_outdoor_area(zone)
		FloorConfig.ZONE_STATIONERY:    _build_zone_stationery(zone)
		FloorConfig.ZONE_PLANTS_AREA:   _build_zone_plants_area(zone)
		FloorConfig.ZONE_LOCKER:        _build_zone_locker(zone)
		FloorConfig.ZONE_STAFF_LOUNGE:  _build_zone_staff_lounge(zone)
		FloorConfig.ZONE_TRAINING:      _build_zone_training(zone)
		FloorConfig.ZONE_OFFICE_DESK:   _build_zone_office_desk(zone)
		FloorConfig.ZONE_EXEC_OFFICE:   _build_zone_exec_office(zone)
		FloorConfig.ZONE_AD:           _build_zone_ad(zone)
		FloorConfig.ZONE_MONITOR_ROOM:  _build_zone_monitor_room(zone)
		FloorConfig.ZONE_HOME_DECOR:       _build_zone_home_decor(zone)
		FloorConfig.ZONE_FURNITURE:         _build_zone_furniture(zone)
		FloorConfig.ZONE_OUTDOOR_LIVING:   _build_zone_outdoor_living(zone)
		FloorConfig.ZONE_ORGANIZATION:      _build_zone_organization(zone)
		FloorConfig.ZONE_LIGHTING:          _build_zone_lighting(zone)
		FloorConfig.ZONE_CUSTOMER_SERVICE:   _build_zone_customer_service(zone)
		FloorConfig.ZONE_LOYALTY_KIOSK:     _build_zone_loyalty_kiosk(zone)
		FloorConfig.ZONE_GIFT_WRAP:          _build_zone_gift_wrap(zone)
		FloorConfig.ZONE_DIGITAL_KIOSK:      _build_zone_digital_kiosk(zone)
		FloorConfig.ZONE_JUICE_BAR:          _build_zone_juice_bar(zone)
		FloorConfig.ZONE_HEALTH_FOOD:        _build_zone_health_food(zone)
		FloorConfig.ZONE_SMOOTHIE:           _build_zone_smoothie(zone)
		FloorConfig.ZONE_SALAD_BAR:          _build_zone_salad_bar(zone)
		FloorConfig.ZONE_KIDS_PLAY:          _build_zone_kids_play(zone)
		FloorConfig.ZONE_KIDS_CLOTHING:      _build_zone_kids_clothing(zone)
		FloorConfig.ZONE_NURSING_ROOM:       _build_zone_nursing_room(zone)
		FloorConfig.ZONE_FAMILY_WC:           _build_zone_family_wc(zone)
		FloorConfig.ZONE_KIDS_CLUB:          _build_zone_kids_club(zone)
		FloorConfig.ZONE_PHONE_GADGETS:    _build_zone_phone_gadgets(zone)
		FloorConfig.ZONE_SMART_HOME:       _build_zone_smart_home(zone)
		FloorConfig.ZONE_ELECTRONICS:       _build_zone_electronics(zone)
		FloorConfig.ZONE_REPAIR_COUNTER:   _build_zone_repair_counter(zone)
		FloorConfig.ZONE_CAFE_COUNTER:     _build_zone_cafe_counter(zone)
		FloorConfig.ZONE_VENDING_MACHINE:  _build_zone_vending_machine(zone)
				FloorConfig.ZONE_CANTEEN:  _build_zone_canteen(zone)
		FloorConfig.ZONE_KARAOKE:  _build_zone_karaoke(zone)
		FloorConfig.ZONE_POOL_TABLE:  _build_zone_pool_table(zone)
		FloorConfig.ZONE_DARTS_BOARD:  _build_zone_darts_board(zone)
		FloorConfig.ZONE_ENTERTAINMENT:  _build_zone_entertainment(zone)
# Unknown types are silently skipped (extensible)



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

# ─── Individual Zone Builders ───────────────────────────────────

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

	# Top wall
	for tx in range(zone.x, zone.x + zone.w):
		_set_wall_tile(tx, zone.y)

	# Left & right walls
	for ty in range(zone.y, zone.y + zone.h):
		_set_wall_tile(zone.x, ty)
		_set_wall_tile(zone.x + zone.w - 1, ty)

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

# ─── Decorative Zone (dining tables, planters, etc.) ───────────────
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

# ─── Pet Adoption Zone ───────────────────────────────────────────────
# A cozy corner with kennels/cages for adoptable pets.
# meta: {name: String, color: Color}
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

# ─── Pet sprite (procedural: dog, cat, rabbit) ───────────────────────
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

# ─── Pet food bag texture ─────────────────────────────────────────────
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


# ─── Claw Machine Zone ───────────────────────────────────────────────
# Builds a complete claw machine cabinet with prizes, claw, rail, and
# interaction zone. meta: {machine_id: String, prize_pool: int (0-3)}.

# ─── Warehouse Zone ─────────────────────────────────────────────────
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

# ─── ATM Zone ─────────────────────────────────────────────────────
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

# ─── Crate texture (for warehouse shelves) ─────────────────────────
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

# ─── Section Zones ─────────────────────────────────────────────

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

# ─── Checkout Counters ─────────────────────────────────────────

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

func _on_express_rejected() -> void:
	pass

func _on_self_checkout_error() -> void:
	pass

func _on_self_checkout_cleared() -> void:
	pass

# ─── Floor Sign ─────────────────────────────────────────────────

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

# ─── Elevator Shaft Visuals ─────────────────────────────────────

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

# ─── Wall Tile Helper ──────────────────────────────────────────

func _set_wall_tile(x: int, y: int) -> void:
	# No-op if no TileMap — walls are purely decorative ColorRects
	pass

# ─── Style Helpers ─────────────────────────────────────────────

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

# ─── Texture Helpers ───────────────────────────────────────────

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


# ─── Shoes Rack Zone ─────────────────────────────────────────────────────────
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

# ─── Dress Rack Zone ─────────────────────────────────────────────────────────
# Clothing racks for dresses / fashion wear
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

# ─── Sport Area Zone ─────────────────────────────────────────────────────────
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

# ─── Outdoor Area Zone ───────────────────────────────────────────────────────
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

# ─── Stationery Zone ─────────────────────────────────────────────────────────
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

# ─── Plants Area Zone ────────────────────────────────────────────────────────
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

# ─── Locker Zone ─────────────────────────────────────────────────────────────
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

# ─── Staff Lounge Zone ───────────────────────────────────────────────────────
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

# ─── Training Room Zone ─────────────────────────────────────────────────────
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

# ─── Office Desk Zone ────────────────────────────────────────────────────────
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

# ─── Executive Office Zone ──────────────────────────────────────────────────
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


# ─── Phase G: Garden & Home Living Zones ──────────────────────────────────────

func _build_zone_home_decor(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "HOME DECOR")
	var zone_color: Color = zone.meta.get("color", Color(0.78, 0.65, 0.50))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Display shelves with decor items
	var item_colors := [Color(0.80, 0.60, 0.45), Color(0.70, 0.55, 0.60), Color(0.60, 0.70, 0.65), Color(0.90, 0.75, 0.55)]
	for row in range(4):
		var sy := cy + 14 + row * (ch * 0.22)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(6):
			var ix := cx + 6 + col * ((cw - 12) / 6.0)
			var ih := 10 + (col % 3) * 4
			var item := ColorRect.new()
			item.position = Vector2(ix, sy - ih); item.size = Vector2((cw - 12) / 7.0, ih)
			item.color = item_colors[(row + col) % item_colors.size()]
			_parent.add_child(item); _floor_nodes.append(item)

func _build_zone_furniture(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "FURNITURE")
	var zone_color: Color = zone.meta.get("color", Color(0.65, 0.55, 0.48))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Furniture display items — sofa, table, chair silhouettes
	var items := [
		{"type": "sofa", "x": 0.1, "w": 0.35, "h": 0.35, "col": Color(0.55, 0.45, 0.42)},
		{"type": "table", "x": 0.5, "w": 0.25, "h": 0.25, "col": Color(0.50, 0.40, 0.32)},
		{"type": "chair", "x": 0.78, "w": 0.15, "h": 0.30, "col": Color(0.60, 0.50, 0.44)},
	]
	for it in items:
		var ix := cx + cw * it["x"]; var iw := cw * it["w"]; var ih := ch * it["h"]
		var furn := ColorRect.new()
		furn.position = Vector2(ix, cy + ch * 0.5 - ih * 0.3)
		furn.size = Vector2(iw, ih); furn.color = it["col"]
		_parent.add_child(furn); _floor_nodes.append(furn)

func _build_zone_outdoor_living(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "OUTDOOR LIVING")
	var zone_color: Color = zone.meta.get("color", Color(0.55, 0.70, 0.52))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Umbrella table, patio chair, BBQ grill display
	var pat_colors := [Color(0.50, 0.72, 0.55), Color(0.68, 0.60, 0.48), Color(0.45, 0.58, 0.50)]
	for row in range(3):
		var ry := cy + 16 + row * (ch * 0.28)
		for col in range(3):
			var rx := cx + 8 + col * ((cw - 16) / 3.0)
			var rh := 16 + (row * 4)
			var rect := ColorRect.new()
			rect.position = Vector2(rx, ry - rh); rect.size = Vector2((cw - 16) / 3.5, rh)
			rect.color = pat_colors[(row + col) % pat_colors.size()]
			_parent.add_child(rect); _floor_nodes.append(rect)

func _build_zone_organization(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "ORGANIZATION")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.60, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Stackable storage boxes
	for row in range(3):
		var sy := cy + 14 + row * (ch * 0.28)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(5):
			var bx := cx + 6 + col * ((cw - 12) / 5.0)
			var box := ColorRect.new()
			box.position = Vector2(bx, sy - 12); box.size = Vector2((cw - 12) / 6.0, 12)
			box.color = zone_color.lightened(0.1) if (col % 2 == 0) else zone_color.darkened(0.1)
			_parent.add_child(box); _floor_nodes.append(box)

func _build_zone_lighting(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "LIGHTING")
	var zone_color: Color = zone.meta.get("color", Color(0.90, 0.85, 0.60))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.1)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Lamp displays with glow effect
	for row in range(3):
		var ly := cy + 20 + row * (ch * 0.28)
		for col in range(4):
			var lx := cx + 8 + col * ((cw - 16) / 4.0)
			var shade_h := 14 + (col % 2) * 6
			# Lamp shade
			var shade := ColorRect.new()
			shade.position = Vector2(lx, ly - shade_h); shade.size = Vector2((cw - 16) / 5.0, shade_h)
			shade.color = zone_color.lightened(0.1)
			_parent.add_child(shade); _floor_nodes.append(shade)
			# Glow
			var glow := ColorRect.new()
			glow.position = Vector2(lx + 2, ly - shade_h + 2); glow.size = Vector2((cw - 16) / 5.0 - 4, shade_h - 4)
			glow.color = Color(1.0, 0.98, 0.80, 0.6)
			_parent.add_child(glow); _floor_nodes.append(glow)

# ─── Phase I: Info Hub & Services Zones ───────────────────────────────────────

func _build_zone_customer_service(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "CUSTOMER SERVICE")
	var zone_color: Color = zone.meta.get("color", Color(0.50, 0.55, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.25); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Service counter
	var counter := ColorRect.new()
	counter.position = Vector2(cx + 4, cy + ch * 0.4); counter.size = Vector2(cw - 8, ch * 0.35)
	counter.color = Color(0.35, 0.38, 0.50); _parent.add_child(counter); _floor_nodes.append(counter)
	# Counter top
	var top := ColorRect.new()
	top.position = Vector2(cx + 4, cy + ch * 0.4); top.size = Vector2(cw - 8, 3)
	top.color = zone_color.lightened(0.2); _parent.add_child(top); _floor_nodes.append(top)
	# Computer monitor on counter
	var mon := ColorRect.new()
	mon.position = Vector2(cx + cw * 0.3, cy + ch * 0.2); mon.size = Vector2(cw * 0.4, ch * 0.2)
	mon.color = Color(0.15, 0.20, 0.30); _parent.add_child(mon); _floor_nodes.append(mon)
	var scr := ColorRect.new()
	scr.position = Vector2(cx + cw * 0.305, cy + ch * 0.205); scr.size = Vector2(cw * 0.39 - 2, ch * 0.18 - 2)
	scr.color = Color(0.20, 0.50, 0.80); _parent.add_child(scr); _floor_nodes.append(scr)

func _build_zone_loyalty_kiosk(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "LOYALTY CENTER")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.50, 0.75))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Kiosk machine
	var kiosk := ColorRect.new()
	kiosk.position = Vector2(cx + cw * 0.2, cy + ch * 0.15); kiosk.size = Vector2(cw * 0.6, ch * 0.70)
	kiosk.color = Color(0.20, 0.18, 0.28); _parent.add_child(kiosk); _floor_nodes.append(kiosk)
	# Screen
	var screen := ColorRect.new()
	screen.position = Vector2(cx + cw * 0.23, cy + ch * 0.20); screen.size = Vector2(cw * 0.54, ch * 0.45)
	screen.color = Color(0.15, 0.20, 0.60); _parent.add_child(screen); _floor_nodes.append(screen)
	# Card slot
	var slot := ColorRect.new()
	slot.position = Vector2(cx + cw * 0.35, cy + ch * 0.68); slot.size = Vector2(cw * 0.3, 4)
	slot.color = Color(0.10, 0.10, 0.15); _parent.add_child(slot); _floor_nodes.append(slot)
	# Hint text
	var hint := Label.new(); hint.text = "[E] Sign Up"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.70, 0.80, 1.0))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_gift_wrap(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "GIFT WRAPPING")
	var zone_color: Color = zone.meta.get("color", Color(0.72, 0.55, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Wrapping paper rolls display
	var roll_colors := [Color(0.90, 0.30, 0.30), Color(0.30, 0.75, 0.90), Color(0.90, 0.80, 0.30), Color(0.50, 0.90, 0.50)]
	for i in range(4):
		var rx := cx + 8 + i * ((cw - 16) / 4.0)
		var roll := ColorRect.new()
		roll.position = Vector2(rx, cy + ch * 0.25); roll.size = Vector2((cw - 16) / 5.0, ch * 0.5)
		roll.color = roll_colors[i]; _parent.add_child(roll); _floor_nodes.append(roll)
		var core := ColorRect.new()
		core.position = Vector2(rx + 2, cy + ch * 0.25); core.size = Vector2((cw - 16) / 8.0, ch * 0.5)
		core.color = Color(0.80, 0.75, 0.65); _parent.add_child(core); _floor_nodes.append(core)
	var hint := Label.new(); hint.text = "[E] Wrap Gift +XP"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.90, 0.75, 0.90))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_digital_kiosk(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "INFO KIOSK")
	var zone_color: Color = zone.meta.get("color", Color(0.40, 0.65, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 2, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Large touchscreen
	var screen := ColorRect.new()
	screen.position = Vector2(cx + 4, cy + 4); screen.size = Vector2(cw - 8, ch * 0.8)
	screen.color = Color(0.10, 0.15, 0.25); _parent.add_child(screen); _floor_nodes.append(screen)
	var display := ColorRect.new()
	display.position = Vector2(cx + 6, cy + 6); display.size = Vector2(cw - 12, ch * 0.76)
	display.color = Color(0.15, 0.35, 0.60); _parent.add_child(display); _floor_nodes.append(display)
	var hint := Label.new(); hint.text = "[E] Browse"
	hint.position = Vector2(cx + 4, cy + ch - 16)
	hint.add_theme_color_override("font_color", Color(0.60, 0.90, 1.0))
	hint.add_theme_font_size_override("font_size", 6)
	_parent.add_child(hint); _floor_nodes.append(hint)

# ─── Phase J: Juice Bar & Fresh Zones ─────────────────────────────────────────

func _build_zone_juice_bar(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "JUICE BAR")
	var zone_color: Color = zone.meta.get("color", Color(1.0, 0.75, 0.30))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Counter
	var counter := ColorRect.new()
	counter.position = Vector2(cx + 4, cy + ch * 0.55); counter.size = Vector2(cw - 8, ch * 0.3)
	counter.color = Color(0.45, 0.38, 0.30); _parent.add_child(counter); _floor_nodes.append(counter)
	# Juicer machine
	var juicer := ColorRect.new()
	juicer.position = Vector2(cx + cw * 0.3, cy + ch * 0.15); juicer.size = Vector2(cw * 0.15, ch * 0.40)
	juicer.color = Color(0.70, 0.70, 0.75); _parent.add_child(juicer); _floor_nodes.append(juicer)
	# Juice dispensers
	var disp_colors := [Color(1.0, 0.60, 0.20), Color(1.0, 0.85, 0.30), Color(0.80, 0.50, 0.30), Color(0.90, 0.40, 0.50)]
	for i in range(4):
		var dx := cx + 8 + i * ((cw - 16) / 4.0)
		var disp := ColorRect.new()
		disp.position = Vector2(dx, cy + ch * 0.20); disp.size = Vector2((cw - 16) / 5.0, ch * 0.35)
		disp.color = disp_colors[i]; _parent.add_child(disp); _floor_nodes.append(disp)
	# Cups display
	var cup := ColorRect.new()
	cup.position = Vector2(cx + cw * 0.55, cy + ch * 0.30); cup.size = Vector2(cw * 0.1, ch * 0.20)
	cup.color = Color(0.90, 0.90, 0.88); _parent.add_child(cup); _floor_nodes.append(cup)

func _build_zone_health_food(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "HEALTH FOODS")
	var zone_color: Color = zone.meta.get("color", Color(0.55, 0.82, 0.58))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	var hf_colors := [Color(0.60, 0.85, 0.65), Color(0.80, 0.90, 0.60), Color(0.90, 0.75, 0.55), Color(0.70, 0.60, 0.80)]
	for row in range(4):
		var sy := cy + 14 + row * (ch * 0.22)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(6):
			var bx := cx + 6 + col * ((cw - 12) / 6.0)
			var item := ColorRect.new()
			item.position = Vector2(bx, sy - 10); item.size = Vector2((cw - 12) / 7.0, 10)
			item.color = hf_colors[(row + col) % hf_colors.size()]
			_parent.add_child(item); _floor_nodes.append(item)

func _build_zone_smoothie(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SMOOTHIE STATION")
	var zone_color: Color = zone.meta.get("color", Color(0.80, 0.55, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Blender display
	for i in range(3):
		var bx := cx + 8 + i * ((cw - 16) / 3.0)
		var blender := ColorRect.new()
		blender.position = Vector2(bx, cy + ch * 0.3); blender.size = Vector2((cw - 16) / 4.0, ch * 0.45)
		blender.color = Color(0.55, 0.55, 0.65); _parent.add_child(blender); _floor_nodes.append(blender)
		var glass := ColorRect.new()
		glass.position = Vector2(bx + 2, cy + ch * 0.15); glass.size = Vector2((cw - 16) / 4.5, ch * 0.30)
		glass.color = [Color(0.90, 0.55, 0.75), Color(0.55, 0.85, 0.75), Color(0.85, 0.75, 0.55)][i]
		_parent.add_child(glass); _floor_nodes.append(glass)

func _build_zone_salad_bar(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SALAD BAR")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.85, 0.60))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Salad ingredient bins
	var ing_colors := [Color(0.60, 0.85, 0.45), Color(0.90, 0.70, 0.40), Color(0.85, 0.80, 0.55), Color(0.70, 0.60, 0.80), Color(0.90, 0.85, 0.60), Color(0.55, 0.80, 0.70)]
	for row in range(3):
		var sy := cy + 14 + row * (ch * 0.28)
		var trough := ColorRect.new()
		trough.position = Vector2(cx + 4, sy); trough.size = Vector2(cw - 8, ch * 0.20)
		trough.color = zone_color.darkened(0.4); _parent.add_child(trough); _floor_nodes.append(trough)
		for col in range(6):
			var bx := cx + 6 + col * ((cw - 12) / 6.0)
			var ing := ColorRect.new()
			ing.position = Vector2(bx, sy + 2); ing.size = Vector2((cw - 12) / 7.0, ch * 0.16)
			ing.color = ing_colors[(row + col) % ing_colors.size()]
			_parent.add_child(ing); _floor_nodes.append(ing)

# ─── Phase K: Kids Kingdom Zones ───────────────────────────────────────────────

func _build_zone_kids_play(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "PLAY ZONE")
	var zone_color: Color = zone.meta.get("color", Color(0.80, 0.60, 0.90))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Soft play blocks (colorful squares)
	var block_colors := [Color(0.95, 0.50, 0.50), Color(0.50, 0.85, 0.95), Color(0.95, 0.85, 0.40), Color(0.60, 0.95, 0.60), Color(0.85, 0.60, 0.95)]
	for row in range(4):
		for col in range(6):
			var bx := cx + 8 + col * ((cw - 16) / 6.0)
			var bh := 14 + (col % 2) * 6
			var block := ColorRect.new()
			block.position = Vector2(bx, cy + ch * 0.45 - row * (ch * 0.15))
			block.size = Vector2((cw - 16) / 7.0, bh)
			block.color = block_colors[(row + col) % block_colors.size()]
			_parent.add_child(block); _floor_nodes.append(block)
	# Slide representation
	var slide := ColorRect.new()
	slide.position = Vector2(cx + cw * 0.7, cy + ch * 0.1); slide.size = Vector2(cw * 0.1, ch * 0.6)
	slide.color = Color(0.60, 0.80, 0.95); _parent.add_child(slide); _floor_nodes.append(slide)
	var hint := Label.new(); hint.text = "SUPERVISED — Parents must accompany children"
	hint.position = Vector2(cx + 4, cy + ch - 16)
	hint.add_theme_color_override("font_color", Color(0.90, 0.75, 1.0))
	hint.add_theme_font_size_override("font_size", 6)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_kids_clothing(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "KIDS WEAR")
	var zone_color: Color = zone.meta.get("color", Color(0.90, 0.72, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.1)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Hanging tiny outfits on child-sized racks
	for row in range(3):
		var ry := cy + 18 + row * (ch * 0.26)
		var pole := _make_plank(Vector2(cx + 4, ry), Vector2(cw - 8, 2), Color(0.60, 0.55, 0.50)); _parent.add_child(pole); _floor_nodes.append(pole)
		for h in range(6):
			var hx := cx + 8 + h * ((cw - 16) / 6.0)
			var outfit := ColorRect.new()
			outfit.position = Vector2(hx, ry - 14); outfit.size = Vector2(12, 14)
			outfit.color = [Color(0.95, 0.70, 0.70), Color(0.70, 0.80, 0.95), Color(0.75, 0.95, 0.75), Color(0.95, 0.90, 0.60), Color(0.90, 0.75, 0.90), Color(0.60, 0.90, 0.90)][h]
			_parent.add_child(outfit); _floor_nodes.append(outfit)

func _build_zone_nursing_room(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "NURSING ROOM")
	var zone_color: Color = zone.meta.get("color", Color(0.95, 0.85, 0.90))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.25); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Nursing chair
	var chair := ColorRect.new()
	chair.position = Vector2(cx + cw * 0.25, cy + ch * 0.35); chair.size = Vector2(cw * 0.5, ch * 0.35)
	chair.color = Color(0.85, 0.70, 0.75); _parent.add_child(chair); _floor_nodes.append(chair)
	# Curtain rod
	var rod := _make_plank(Vector2(cx + 4, cy + ch * 0.3), Vector2(cw - 8, 2), Color(0.70, 0.65, 0.60)); _parent.add_child(rod); _floor_nodes.append(rod)
	var hint := Label.new(); hint.text = "[E] Private Room"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.80, 0.60, 0.75))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_family_wc(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "FAMILY WC")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.75, 0.90))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.25); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Toilet icon
	var toilet := ColorRect.new()
	toilet.position = Vector2(cx + cw * 0.3, cy + ch * 0.3); toilet.size = Vector2(cw * 0.4, ch * 0.4)
	toilet.color = Color(0.85, 0.88, 0.92); _parent.add_child(toilet); _floor_nodes.append(toilet)
	# Sink
	var sink := ColorRect.new()
	sink.position = Vector2(cx + cw * 0.25, cy + ch * 0.15); sink.size = Vector2(cw * 0.5, ch * 0.18)
	sink.color = Color(0.80, 0.85, 0.90); _parent.add_child(sink); _floor_nodes.append(sink)
	var hint := Label.new(); hint.text = "FAMILY FACILITIES"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.40, 0.65, 0.85))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_kids_club(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "KIDS CLUB")
	var zone_color: Color = zone.meta.get("color", Color(0.72, 0.80, 0.60))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.darkened(0.15)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Reception desk
	var desk := ColorRect.new()
	desk.position = Vector2(cx + cw * 0.1, cy + ch * 0.3); desk.size = Vector2(cw * 0.35, ch * 0.3)
	desk.color = Color(0.50, 0.60, 0.45); _parent.add_child(desk); _floor_nodes.append(desk)
	# Activity tables
	for i in range(3):
		var tx := cx + cw * 0.5 + i * (cw * 0.15)
		var table := ColorRect.new()
		table.position = Vector2(tx, cy + ch * 0.45); table.size = Vector2(cw * 0.12, ch * 0.25)
		table.color = Color(0.65, 0.75, 0.55); _parent.add_child(table); _floor_nodes.append(table)
	var hint := Label.new(); hint.text = "[E] Sign Kids In ($5/30min) +XP Bonus"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.50, 0.75, 0.50))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

# ─── Shared Helper ─────────────────────────────────────────────────────────────
func _make_zone_label(text: String, pos: Vector2, col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 10)
	return lbl

func _make_plank(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new(); r.position = pos; r.size = sz; r.color = col; return r

# ??? Phase H: Home Electronics & Tech Zones ?????????????????????????????????????

func _build_zone_phone_gadgets(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "PHONES & GADGETS")
	var zone_color: Color = zone.meta.get("color", Color(0.35, 0.55, 0.80))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Phone display stands
	for i in range(4):
		var px := cx + 8 + i * ((cw - 16) / 4.0)
		# Stand base
		var stand := ColorRect.new()
		stand.position = Vector2(px, cy + ch * 0.55); stand.size = Vector2((cw - 16) / 5.5, ch * 0.30)
		stand.color = Color(0.25, 0.28, 0.35); _parent.add_child(stand); _floor_nodes.append(stand)
		# Phone on stand
		var phone := ColorRect.new()
		phone.position = Vector2(px + 2, cy + ch * 0.25); phone.size = Vector2((cw - 16) / 7.0, ch * 0.30)
		phone.color = Color(0.15, 0.15, 0.20); _parent.add_child(phone); _floor_nodes.append(phone)
		# Screen glow
		var glow := ColorRect.new()
		glow.position = Vector2(px + 3, cy + ch * 0.27); glow.size = Vector2((cw - 16) / 7.5, ch * 0.22)
		glow.color = zone_color.lightened(0.3); _parent.add_child(glow); _floor_nodes.append(glow)
	# Accessory hooks below
	for i in range(6):
		var ax := cx + 6 + i * ((cw - 12) / 6.0)
		var acc := ColorRect.new()
		acc.position = Vector2(ax, cy + ch * 0.72); acc.size = Vector2((cw - 12) / 7.5, ch * 0.15)
		acc.color = [Color(0.90, 0.90, 0.95), Color(0.90, 0.85, 0.90), Color(0.85, 0.90, 0.90)][i % 3]
		_parent.add_child(acc); _floor_nodes.append(acc)

func _build_zone_smart_home(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "SMART HOME")
	var zone_color: Color = zone.meta.get("color", Color(0.40, 0.60, 0.70))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Smart device shelves ??speakers, cameras, displays
	var dev_colors := [Color(0.30, 0.30, 0.35), Color(0.35, 0.35, 0.40), Color(0.25, 0.30, 0.35), Color(0.40, 0.35, 0.30)]
	for row in range(3):
		var sy := cy + 16 + row * (ch * 0.28)
		var plank := _make_plank(Vector2(cx + 4, sy), Vector2(cw - 8, 2), zone_color.darkened(0.4)); _parent.add_child(plank); _floor_nodes.append(plank)
		for col in range(4):
			var dx := cx + 6 + col * ((cw - 12) / 4.0)
			var dh := 12 + (col % 2) * 6
			var dev := ColorRect.new()
			dev.position = Vector2(dx, sy - dh); dev.size = Vector2((cw - 12) / 5.5, dh)
			dev.color = dev_colors[(row + col) % dev_colors.size()]; _parent.add_child(dev); _floor_nodes.append(dev)
			# LED indicator dot
			var led := ColorRect.new()
			led.position = Vector2(dx + 2, sy - dh - 3); led.size = Vector2(3, 3)
			led.color = Color(0.20, 0.90, 0.50); _parent.add_child(led); _floor_nodes.append(led)

func _build_zone_electronics(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "ELECTRONICS")
	var zone_color: Color = zone.meta.get("color", Color(0.45, 0.50, 0.65))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.3)); _parent.add_child(tl); _floor_nodes.append(tl)
	# TV display wall
	var tv_bg := ColorRect.new()
	tv_bg.position = Vector2(cx + cw * 0.1, cy + ch * 0.1); tv_bg.size = Vector2(cw * 0.8, ch * 0.5)
	tv_bg.color = Color(0.10, 0.10, 0.12); _parent.add_child(tv_bg); _floor_nodes.append(tv_bg)
	var tv_screen := ColorRect.new()
	tv_screen.position = Vector2(cx + cw * 0.12, cy + ch * 0.12); tv_screen.size = Vector2(cw * 0.76, ch * 0.46)
	tv_screen.color = Color(0.15, 0.25, 0.50); _parent.add_child(tv_screen); _floor_nodes.append(tv_screen)
	# Speaker blocks
	for i in range(3):
		var sp_x := cx + 8 + i * ((cw - 16) / 3.0)
		var sp := ColorRect.new()
		sp.position = Vector2(sp_x, cy + ch * 0.65); sp.size = Vector2((cw - 16) / 4.5, ch * 0.22)
		sp.color = Color(0.25, 0.25, 0.30); _parent.add_child(sp); _floor_nodes.append(sp)

func _build_zone_repair_counter(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "REPAIR COUNTER")
	var zone_color: Color = zone.meta.get("color", Color(0.60, 0.45, 0.40))
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.30); _parent.add_child(bg); _floor_nodes.append(bg)
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), zone_color.lightened(0.2)); _parent.add_child(tl); _floor_nodes.append(tl)
	# Workbench counter
	var bench := ColorRect.new()
	bench.position = Vector2(cx + 4, cy + ch * 0.40); bench.size = Vector2(cw - 8, ch * 0.35)
	bench.color = Color(0.40, 0.35, 0.30); _parent.add_child(bench); _floor_nodes.append(bench)
	# Tool pegboard above
	var board := ColorRect.new()
	board.position = Vector2(cx + 4, cy + ch * 0.15); board.size = Vector2(cw - 8, ch * 0.22)
	board.color = Color(0.50, 0.42, 0.35); _parent.add_child(board); _floor_nodes.append(board)
	# Tool outlines
	var tool_colors := [Color(0.80, 0.60, 0.30), Color(0.70, 0.70, 0.70), Color(0.90, 0.40, 0.40), Color(0.60, 0.80, 0.60)]
	for i in range(4):
		var tx := cx + 8 + i * ((cw - 16) / 4.0)
		var tool := ColorRect.new()
		tool.position = Vector2(tx, cy + ch * 0.17); tool.size = Vector2((cw - 16) / 6.0, ch * 0.18)
		tool.color = tool_colors[i]; _parent.add_child(tool); _floor_nodes.append(tool)
	var hint := Label.new(); hint.text = "[E] Tech Support"
	hint.position = Vector2(cx + 4, cy + ch - 18)
	hint.add_theme_color_override("font_color", Color(0.90, 0.80, 0.80))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_cafe_counter(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "CAFE COUNTER")
	var items: Array = zone.meta.get("items", [])
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE

	# Warm café floor
	var bg := ColorRect.new(); bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = Color(0.60, 0.45, 0.30).darkened(0.4); _parent.add_child(bg); _floor_nodes.append(bg)

	# Zone label above
	var tl := _make_zone_label(name, Vector2(cx + 4, cy - 14), Color(0.90, 0.75, 0.50)); _parent.add_child(tl); _floor_nodes.append(tl)

	# Counter base (wooden)
	var counter := ColorRect.new()
	counter.position = Vector2(cx, cy + ch - 5 * CELL_SIZE)
	counter.size = Vector2(cw, 5 * CELL_SIZE)
	counter.color = Color(0.55, 0.38, 0.22); _parent.add_child(counter); _floor_nodes.append(counter)

	# Counter top ledge
	var counter_top := ColorRect.new()
	counter_top.position = Vector2(cx, cy + ch - 5 * CELL_SIZE)
	counter_top.size = Vector2(cw, 2)
	counter_top.color = Color(0.75, 0.55, 0.35); _parent.add_child(counter_top); _floor_nodes.append(counter_top)

	# Coffee machine (back of counter)
	var machine := ColorRect.new()
	machine.position = Vector2(cx + cw * 0.35, cy + ch * 0.20)
	machine.size = Vector2(cw * 0.30, ch * 0.55)
	machine.color = Color(0.30, 0.30, 0.35); _parent.add_child(machine); _floor_nodes.append(machine)

	# Coffee machine top detail
	var machine_top := ColorRect.new()
	machine_top.position = Vector2(cx + cw * 0.33, cy + ch * 0.18)
	machine_top.size = Vector2(cw * 0.34, 4)
	machine_top.color = Color(0.50, 0.50, 0.55); _parent.add_child(machine_top); _floor_nodes.append(machine_top)

	# Cup warming label
	var cup_lbl := Label.new(); cup_lbl.text = "CUP WARMER"
	cup_lbl.position = Vector2(cx + cw * 0.36, cy + ch * 0.22)
	cup_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	cup_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(cup_lbl); _floor_nodes.append(cup_lbl)

	# Espresso machine button area
	var btn_area := ColorRect.new()
	btn_area.position = Vector2(cx + cw * 0.40, cy + ch * 0.38)
	btn_area.size = Vector2(cw * 0.20, ch * 0.12)
	btn_area.color = Color(0.20, 0.20, 0.25); _parent.add_child(btn_area); _floor_nodes.append(btn_area)

	# Menu board on back wall
	var board_bg := ColorRect.new()
	board_bg.position = Vector2(cx + 4, cy + 2)
	board_bg.size = Vector2(cw * 0.30, ch * 0.40)
	board_bg.color = Color(0.05, 0.10, 0.05); _parent.add_child(board_bg); _floor_nodes.append(board_bg)

	# Show menu items on board
	for i in range(mini(items.size(), 4)):
		var item_lbl := Label.new()
		item_lbl.text = items[i]
		item_lbl.position = Vector2(cx + 6, cy + 3 + i * (ch * 0.10))
		item_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.70))
		item_lbl.add_theme_font_size_override("font_size", 6)
		_parent.add_child(item_lbl); _floor_nodes.append(item_lbl)

	# Warm glow above the counter (lamp)
	var glow := Sprite2D.new()
	glow.position = Vector2(cx + cw * 0.5, cy - 10 * CELL_SIZE)
	glow.texture = _make_glow(Color(1.0, 0.75, 0.40))
	_parent.add_child(glow); _floor_nodes.append(glow)

	# Hint label
	var hint := Label.new(); hint.text = "[E] Browse Menu"
	hint.position = Vector2(cx + 4, cy + ch - 4 * CELL_SIZE)
	hint.add_theme_color_override("font_color", Color(0.90, 0.80, 0.60))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

func _build_zone_vending_machine(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "VENDING")
	var items: Array = zone.meta.get("items", ["Water $1.50", "Cola $2.00"])
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE

	# Vending machine body (glass front)
	var body := ColorRect.new(); body.position = Vector2(cx, cy); body.size = Vector2(cw, ch)
	body.color = Color(0.25, 0.28, 0.32); _parent.add_child(body); _floor_nodes.append(body)

	# Glass front panel
	var glass := ColorRect.new()
	glass.position = Vector2(cx + 2, cy + 2); glass.size = Vector2(cw - 4, ch * 0.70)
	glass.color = Color(0.15, 0.18, 0.22).lightened(0.15); _parent.add_child(glass); _floor_nodes.append(glass)

	# Machine frame border
	var frame_top := ColorRect.new(); frame_top.position = Vector2(cx, cy); frame_top.size = Vector2(cw, 2)
	frame_top.color = Color(0.50, 0.50, 0.55); _parent.add_child(frame_top); _floor_nodes.append(frame_top)
	var frame_bot := ColorRect.new(); frame_bot.position = Vector2(cx, cy + ch - 2); frame_bot.size = Vector2(cw, 2)
	frame_bot.color = Color(0.40, 0.40, 0.45); _parent.add_child(frame_bot); _floor_nodes.append(frame_bot)

	# Product items inside glass (small colored rectangles)
	var item_colors := [Color(0.40, 0.70, 0.90), Color(0.85, 0.30, 0.30), Color(0.80, 0.75, 0.30),
			Color(0.90, 0.65, 0.30), Color(0.60, 0.40, 0.25), Color(0.30, 0.80, 0.50)]
	for row in range(2):
		for col in range(mini(3, items.size())):
			var ix := cx + 4 + col * ((cw - 8) / 3.0)
			var iy := cy + 4 + row * (ch * 0.35)
			var slot := ColorRect.new()
			slot.position = Vector2(ix, iy); slot.size = Vector2((cw - 8) / 3.5, ch * 0.30)
		slot.color = item_colors[(row * 3 + col) % item_colors.size()]
			_parent.add_child(slot); _floor_nodes.append(slot)

	# Coin slot / control panel at bottom
	var panel := ColorRect.new()
	panel.position = Vector2(cx + 2, cy + ch * 0.72); panel.size = Vector2(cw - 4, ch * 0.25)
	panel.color = Color(0.20, 0.22, 0.26); _parent.add_child(panel); _floor_nodes.append(panel)

	# Slot opening
	var slot := ColorRect.new()
	slot.position = Vector2(cx + cw * 0.35, cy + ch * 0.75)
	slot.size = Vector2(cw * 0.12, ch * 0.08)
	slot.color = Color(0.10, 0.10, 0.12); _parent.add_child(slot); _floor_nodes.append(slot)

	# Label above machine
	var tl := Label.new(); tl.text = name
	tl.position = Vector2(cx + 2, cy - 12)
	tl.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
	tl.add_theme_font_size_override("font_size", 8)
	_parent.add_child(tl); _floor_nodes.append(tl)

	# Hint
	var hint := Label.new(); hint.text = "[E] Buy Snacks"
	hint.position = Vector2(cx + 2, cy + ch + 2)
	hint.add_theme_color_override("font_color", Color(0.60, 0.65, 0.70))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)

# ─── Public Accessors ───────────────────────────────────────────

func get_sections() -> Array:
	return _sections

func get_food_stalls() -> Array:
	return _food_stalls

func get_claw_machines() -> Array:
	return _claw_machines

func get_checkout_counters() -> Array:
	return _checkout_counters

func get_floor_nodes() -> Array:
	return _floor_nodes

# Returns the world position of the price terminal (office_desk zone center)
func get_office_desk_zone_center() -> Vector2:
	if _floor_def == null:
		return Vector2(-1, -1)
	for zone in _floor_def.zones:
		if zone.type == FloorConfig.ZONE_OFFICE_DESK:
			var cx := (zone.x + zone.w * 0.5) * CELL_SIZE
			var cy := (zone.y + zone.h * 0.5) * CELL_SIZE
			return Vector2(cx, cy)
	return Vector2(-1, -1)

# Returns the zone center of a specific zone type (for E-key interaction proximity)
func get_zone_center_by_type(ztype: String) -> Vector2:
	if _floor_def == null:
		return Vector2(-1, -1)
	for zone in _floor_def.zones:
		if zone.type == ztype:
			var cx := (zone.x + zone.w * 0.5) * CELL_SIZE
			var cy := (zone.y + zone.h * 0.5) * CELL_SIZE
			return Vector2(cx, cy)
	return Vector2(-1, -1)

# Returns true if player is within interaction range of a zone type
func is_near_zone_type(ztype: String, player_pos: Vector2, threshold: float = 12.0) -> bool:
	var center = get_zone_center_by_type(ztype)
	if center.x < 0:
		return false
	return player_pos.distance_to(center) < CELL_SIZE * threshold









