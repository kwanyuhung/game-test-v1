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
		FloorConfig.ZONE_ATM:           _build_zone_atm(zone)
		# Unknown types are silently skipped (extensible)

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
	for lane in lanes:
		var counter := Node2D.new()
		counter.position = Vector2(lane["x"] * CELL_SIZE, (CHECKOUT_Y + 2) * CELL_SIZE)
		counter.name = "Counter_%s" % lane["name"]
		var bg := ColorRect.new()
		bg.size = Vector2(CELL_SIZE * 8, CELL_SIZE * 3)
		bg.color = Color(0.35, 0.28, 0.38)
		counter.add_child(bg)
		var top_c := ColorRect.new()
		top_c.size = Vector2(CELL_SIZE * 8, 2)
		top_c.color = Color(0.55, 0.45, 0.60)
		counter.add_child(top_c)
		var lbl := Label.new()
		lbl.text = lane["name"]
		lbl.position = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 0.90))
		lbl.add_theme_font_size_override("font_size", 8)
		counter.add_child(lbl)
		_parent.add_child(counter)
		_checkout_counters.append(counter)

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




