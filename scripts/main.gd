# main.gd
# 10-floor supermarket world builder — Phase 1: multi-floor, elevator, parking.
# Floor G (0) = ground lobby + parking
# Floors 1-10 = retail / staff / rooftop
extends Node2D

const Floors = preload("res://scripts/floors.gd")
const StoreData = preload("res://scripts/store_data.gd")
const TelegramBot = preload("res://scripts/telegram_bot.gd")
const ElevatorScript = preload("res://scripts/elevator.gd")
const ParkingLotScript = preload("res://scripts/parking_lot.gd")

const CELL_SIZE := 16
const WORLD_W := 96
const WORLD_H := 50

var _player: Player
var _sections: Array = []
var _section_browse: SectionBrowse
var _current_section_browse = null
var _checkout_counters: Array = []
var _nearby_section: Node = null
var _nearby_checkout: Node = null
var _nearby_elevator: bool = false
var _nearby_parking: bool = false
var _nearby_stairs: bool = false
var _in_checkout: bool = false
var _cart_panel: CanvasLayer
var _cart_items_lbl: Label
var _cart_total_lbl: Label
var _cart_count_lbl: Label
var _checkout_receipt: Control
var _checkout_counter_label: Label
var _checkout_items_lbl: Label
var _checkout_total_lbl: Label
var _checkout_receipt_visible: bool = false
var _cart_panel_visible: bool = false

var _world_bg: ColorRect = null
var _aisle_labels: Array = []
var _telegram_bot: Node = null
var _elevator: ElevatorScript  # Elevator car
var _parking_lot  # Parking lot (ground floor)
var _current_floor_idx: int = 0
var _floor_nodes: Array = []    # nodes belonging to current floor (cleared on floor switch)
var _floor_ambient: Color = Color(0.18, 0.18, 0.16)
var _floor_label: Label = null
var _stairs_node: Node2D = null
var _elevator_shaft_bg: ColorRect = null
var _elevator_call_btns: Array = []
var _in_elevator: bool = false   # player is riding the elevator

const AISLE_NAMES := {
	"dairy":   "DAIRY",
	"produce": "PRODUCE",
	"bakery":  "BAKERY",
	"drinks":  "DRINKS",
	"snacks":  "SNACKS",
	"meat":    "MEAT / DELI",
	"pantry":  "PANTRY",
	"frozen":  "FROZEN",
}

func _ready() -> void:
	_telegram_bot = get_node_or_null("/root/Main/TelegramBot")

	# Build ground floor (G) first
	_current_floor_idx = 0
	_build_floor(_current_floor_idx)
	_setup_camera()
	_build_hud()
	_build_elevator()
	_build_stairs()
	_spawn_player()
	_build_npcs()
	_update_floor_hud()

	notify_telegram("🟢 *Game Loaded*\n10-floor supermarket — Ground (G) ready\nUse [E] near elevator to change floors")

# ═══════════════════════════════════════════════════════════════
# FLOOR BUILDING
# ═══════════════════════════════════════════════════════════════

func _build_floor(idx: int) -> void:
	_clear_floor_nodes()
	_current_floor_idx = idx
	var fd = Floors.ALL[idx]

	# World background
	var bg := ColorRect.new()
	bg.size = Vector2(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE)
	bg.position = Vector2.ZERO
	bg.color = Color(0.18, 0.18, 0.16)
	add_child(bg)
	_floor_nodes.append(bg)

	if idx == 0:
		_build_ground_floor()
	else:
		_build_retail_floor(idx)

	_floor_ambient = fd.color_ambient
	_apply_ambient_shift()
	_update_floor_hud()

func _clear_floor_nodes() -> void:
	for node in _floor_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_floor_nodes.clear()
	_sections.clear()
	_checkout_counters.clear()
	_aisle_labels.clear()

	# Also remove dynamic nodes by name pattern
	var to_remove: Array = []
	for c in get_children():
		var nm := c.name as String
		if nm.begins_with("Section_") or nm.begins_with("Counter_") or nm.begins_with("Floor_"):
			to_remove.append(c)
	for c in to_remove:
		c.queue_free()

# ─── Ground Floor (G) ─────────────────────────────────────────

func _build_ground_floor() -> void:
	# Lobby / entrance area at top
	_build_lobby()
	# Parking lot at bottom-left
	_build_parking()
	# Elevator shaft visual (background — the car is separate)
	_build_elevator_shaft_bg()
	# Stairs area
	_build_stairs_area()
	# Floor label on ground
	_add_floor_theme_sign()

func _build_lobby() -> void:
	# Entrance from outside → lobby floor
	var lobby_floor := ColorRect.new()
	lobby_floor.position = Vector2(0, 0)
	lobby_floor.size = Vector2(WORLD_W * CELL_SIZE, CELL_SIZE * 2)
	lobby_floor.color = Color(0.22, 0.20, 0.18)
	add_child(lobby_floor)
	_floor_nodes.append(lobby_floor)

	# Lobby info desk center
	_build_info_desk()

	# WC sign right side
	_build_wc_booth()

	# Top wall with entrance gap
	for x in range(WORLD_W):
		_set_wall(x, 1)
	for x in range(10, 16):  # entrance gap
		_unset_wall(x, 1)

	# Left & right walls
	for y in range(WORLD_H):
		_set_wall(0, y)
		_set_wall(WORLD_W - 1, y)

	# Bottom of lobby area
	for x in range(WORLD_W):
		_set_wall(x, 21)

	# Paved ground below lobby to parking
	var ground := ColorRect.new()
	ground.position = Vector2(0, 21 * CELL_SIZE)
	ground.size = Vector2(WORLD_W * CELL_SIZE, (WORLD_H - 21) * CELL_SIZE)
	ground.color = Color(0.19, 0.18, 0.17)
	add_child(ground)
	_floor_nodes.append(ground)

	# Lobby floor decorative line
	var lob_line := ColorRect.new()
	lob_line.position = Vector2(0, 21 * CELL_SIZE)
	lob_line.size = Vector2(WORLD_W * CELL_SIZE, 2)
	lob_line.color = Color(0.28, 0.26, 0.24)
	add_child(lob_line)
	_floor_nodes.append(lob_line)

func _build_info_desk() -> void:
	# Center x=44..56, y=3..9
	var desk_bg := ColorRect.new()
	desk_bg.position = Vector2(44 * CELL_SIZE, 3 * CELL_SIZE)
	desk_bg.size = Vector2(12 * CELL_SIZE, 6 * CELL_SIZE)
	desk_bg.color = Color(0.28, 0.24, 0.22)
	add_child(desk_bg)
	_floor_nodes.append(desk_bg)

	# Desk top
	var desk_top := ColorRect.new()
	desk_top.position = Vector2(44 * CELL_SIZE, 3 * CELL_SIZE)
	desk_top.size = Vector2(12 * CELL_SIZE, 2)
	desk_top.color = Color(0.55, 0.48, 0.40)
	add_child(desk_top)
	_floor_nodes.append(desk_top)

	# Info sign
	var info_sign := Label.new()
	info_sign.text = "INFORMATION"
	info_sign.position = Vector2(46 * CELL_SIZE, 4 * CELL_SIZE)
	info_sign.add_theme_color_override("font_color", Color(0.90, 0.85, 0.60))
	info_sign.add_theme_font_size_override("font_size", 8)
	add_child(info_sign)
	_floor_nodes.append(info_sign)

	# Floor directory
	var dir_lbl := Label.new()
	dir_lbl.text = "F1:Fresh  F2:Pantry\nF3:Drinks  F4:Snacks\nF5:Frozen  F6:Home\nF7:Health  F8:Toys\nF9:Staff  F10:Cafe"
	dir_lbl.position = Vector2(45 * CELL_SIZE, 5.5 * CELL_SIZE)
	dir_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55))
	dir_lbl.add_theme_font_size_override("font_size", 7)
	add_child(dir_lbl)
	_floor_nodes.append(dir_lbl)

func _build_wc_booth() -> void:
	# Right side x=72..80, y=3..9
	var wc_bg := ColorRect.new()
	wc_bg.position = Vector2(72 * CELL_SIZE, 3 * CELL_SIZE)
	wc_bg.size = Vector2(8 * CELL_SIZE, 6 * CELL_SIZE)
	wc_bg.color = Color(0.18, 0.20, 0.24)
	add_child(wc_bg)
	_floor_nodes.append(wc_bg)

	# Door
	var wc_door := ColorRect.new()
	wc_door.position = Vector2(73 * CELL_SIZE, 6 * CELL_SIZE)
	wc_door.size = Vector2(2 * CELL_SIZE, 3 * CELL_SIZE)
	wc_door.color = Color(0.50, 0.48, 0.55)
	add_child(wc_door)
	_floor_nodes.append(wc_door)

	var wc_lbl := Label.new()
	wc_lbl.text = "WC"
	wc_lbl.position = Vector2(76 * CELL_SIZE, 4.5 * CELL_SIZE)
	wc_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90))
	wc_lbl.add_theme_font_size_override("font_size", 9)
	add_child(wc_lbl)
	_floor_nodes.append(wc_lbl)

	# Accessible icon (simple wheelchair symbol)
	var acc_lbl := Label.new()
	acc_lbl.text = "[E] Use"
	acc_lbl.position = Vector2(74 * CELL_SIZE, 7.5 * CELL_SIZE)
	acc_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.60))
	acc_lbl.add_theme_font_size_override("font_size", 7)
	add_child(acc_lbl)
	_floor_nodes.append(acc_lbl)

func _build_elevator_shaft_bg() -> void:
	# Elevator shaft x=80..82, y=1..49
	var shaft := ColorRect.new()
	shaft.position = Vector2(80 * CELL_SIZE, CELL_SIZE)
	shaft.size = Vector2(2 * CELL_SIZE, 48 * CELL_SIZE)
	shaft.color = Color(0.30, 0.27, 0.25)
	add_child(shaft)
	_floor_nodes.append(shaft)
	_elevator_shaft_bg = shaft

	# Shaft border lines
	var border_l := ColorRect.new()
	border_l.position = Vector2(80 * CELL_SIZE, CELL_SIZE)
	border_l.size = Vector2(1, 48 * CELL_SIZE)
	border_l.color = Color(0.50, 0.45, 0.40)
	add_child(border_l)
	_floor_nodes.append(border_l)

	var border_r := ColorRect.new()
	border_r.position = Vector2(81 * CELL_SIZE, CELL_SIZE)
	border_r.size = Vector2(1, 48 * CELL_SIZE)
	border_r.color = Color(0.40, 0.37, 0.35)
	add_child(border_r)
	_floor_nodes.append(border_r)

	# Floor indicators in shaft
	for floor_i in range(Floors.count()):
		var fy := _floor_y_in_shaft(floor_i)
		var indicator := ColorRect.new()
		indicator.position = Vector2(80 * CELL_SIZE + CELL_SIZE * 0.25, fy)
		indicator.size = Vector2(CELL_SIZE * 1.5, 4)
		var is_current := (floor_i == _current_floor_idx)
		indicator.color = Color(0.20, 0.85, 0.45) if is_current else Color(0.40, 0.38, 0.35)
		add_child(indicator)
		_floor_nodes.append(indicator)

func _floor_y_in_shaft(floor_idx: int) -> float:
	# Maps floor index to y position in shaft visual
	# Floor 0 (G) = bottom area, Floor 10 = top
	var base_y := 42 * CELL_SIZE
	var floor_spacing := 4.0 * CELL_SIZE
	return base_y - floor_idx * floor_spacing

func _build_stairs_area() -> void:
	# Stairs at x=84..87, y=1..49
	var stair_bg := ColorRect.new()
	stair_bg.position = Vector2(84 * CELL_SIZE, CELL_SIZE)
	stair_bg.size = Vector2(4 * CELL_SIZE, 48 * CELL_SIZE)
	stair_bg.color = Color(0.28, 0.26, 0.24)
	add_child(stair_bg)
	_floor_nodes.append(stair_bg)

	# Step lines
	for i in range(12):
		var step_y := (5 + i * 4) * CELL_SIZE
		var step_line := ColorRect.new()
		step_line.position = Vector2(84 * CELL_SIZE, step_y)
		step_line.size = Vector2(4 * CELL_SIZE, 2)
		step_line.color = Color(0.45, 0.42, 0.38)
		add_child(step_line)
		_floor_nodes.append(step_line)

	# Stairs label
	var stair_lbl := Label.new()
	stair_lbl.text = "STAIRS"
	stair_lbl.position = Vector2(84 * CELL_SIZE + 4, 4 * CELL_SIZE)
	stair_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
	stair_lbl.add_theme_font_size_override("font_size", 7)
	add_child(stair_lbl)
	_floor_nodes.append(stair_lbl)

	# Up arrow (if not top floor)
	if _current_floor_idx < Floors.count() - 1:
		var up_arrow := ColorRect.new()
		up_arrow.position = Vector2(85.5 * CELL_SIZE, 8 * CELL_SIZE)
		up_arrow.size = Vector2(CELL_SIZE, 8)
		up_arrow.color = Color(0.70, 0.68, 0.60, 0.7)
		add_child(up_arrow)
		_floor_nodes.append(up_arrow)

# ─── Retail Floors (1-10) ──────────────────────────────────────

func _build_retail_floor(idx: int) -> void:
	var fd = Floors.ALL[idx]

	# Walls
	for x in range(WORLD_W):
		_set_wall(x, 1)
	for y in range(WORLD_H):
		_set_wall(0, y)
		_set_wall(WORLD_W - 1, y)
	for x in range(WORLD_W):
		_set_wall(x, WORLD_H - 1)

	# Main aisle horizontal
	for x in range(WORLD_W):
		_set_aisle_floor(x, 17)
		_set_aisle_floor(x, 18)

	# Vertical main aisle
	for y in range(2, WORLD_H - 1):
		_set_aisle_floor(18, y)
		_set_aisle_floor(19, y)

	# Section separator walls with aisle gaps
	for x in [1, 20, 42, 60, 78]:
		for y in range(17, 19):
			_set_aisle_floor(x, y)
			_set_aisle_floor(x + 1, y)

	# Elevator shaft column (right side of floor)
	_set_aisle_floor(80, 15)
	_set_aisle_floor(81, 15)
	for y in range(1, WORLD_H - 1):
		_set_aisle_floor(80, y)
		_set_aisle_floor(81, y)

	# Stairs column
	for y in range(1, WORLD_H - 1):
		_set_aisle_floor(84, y)
		_set_aisle_floor(85, y)

	# Section backgrounds for this floor
	for def in StoreData.SECTIONS:
		if def.floor == idx or (idx >= 1 and def.floor == -1):
			# Default: show all sections for floors 1-5, then filtered later
			pass
		_build_section_bg(def)

	# Section labels
	_add_aisle_signs()

	# Checkout area at y=34-37
	for x in range(WORLD_W):
		_set_aisle_floor(x, 34)
		_set_aisle_floor(x, 35)
		_set_aisle_floor(x, 36)

	# Elevator shaft visual
	var shaft := ColorRect.new()
	shaft.position = Vector2(80 * CELL_SIZE, 0)
	shaft.size = Vector2(2 * CELL_SIZE, WORLD_H * CELL_SIZE)
	shaft.color = Color(0.30, 0.27, 0.25)
	add_child(shaft)
	_floor_nodes.append(shaft)

	# Floor label sign
	_add_floor_theme_sign()

# ─── Section Building (shared) ─────────────────────────────────

func _build_section_bg(def) -> void:
	var sx: float = def.wx * CELL_SIZE
	var sy: float = def.wy * CELL_SIZE
	var sw: float = def.ww * CELL_SIZE
	var sh: float = def.wh * CELL_SIZE

	var floor_c := _get_section_floor(def.style)
	var bg := ColorRect.new()
	bg.position = Vector2(sx, sy)
	bg.size = Vector2(sw, sh)
	bg.color = floor_c
	add_child(bg)
	_floor_nodes.append(bg)

	var wc := _get_wall_color(def.style)
	var tw := ColorRect.new()
	tw.position = Vector2(sx, sy); tw.size = Vector2(sw, 2); tw.color = wc
	add_child(tw); _floor_nodes.append(tw)

	var bw := ColorRect.new()
	bw.position = Vector2(sx, sy + sh - 2); bw.size = Vector2(sw, 2); bw.color = wc.darkened(0.15)
	add_child(bw); _floor_nodes.append(bw)

	var lw := ColorRect.new()
	lw.position = Vector2(sx, sy); lw.size = Vector2(2, sh); lw.color = wc.darkened(0.1)
	add_child(lw); _floor_nodes.append(lw)

	var rw := ColorRect.new()
	rw.position = Vector2(sx + sw - 2, sy); rw.size = Vector2(2, sh); rw.color = wc.darkened(0.2)
	add_child(rw); _floor_nodes.append(rw)

	var glow := Sprite2D.new()
	glow.position = Vector2(sx + sw * 0.5, sy - 8)
	glow.texture = _make_light_glow(def.light_color)
	add_child(glow); _floor_nodes.append(glow)

	var sign := _make_sign(def)
	sign.position = Vector2(sx + sw * 0.5, sy + 6)
	add_child(sign); _floor_nodes.append(sign)

func _add_floor_theme_sign() -> void:
	var fd = Floors.ALL[_current_floor_idx]
	var sign_bg := ColorRect.new()
	sign_bg.position = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
	sign_bg.size = Vector2(6 * CELL_SIZE, 2 * CELL_SIZE)
	sign_bg.color = Color(0.08, 0.08, 0.10)
	add_child(sign_bg); _floor_nodes.append(sign_bg)

	var theme_lbl := Label.new()
	theme_lbl.text = "Floor %s — %s" % [fd.label, fd.theme.capitalize()]
	theme_lbl.position = Vector2(2.5 * CELL_SIZE, 2.3 * CELL_SIZE)
	theme_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.60))
	theme_lbl.add_theme_font_size_override("font_size", 8)
	add_child(theme_lbl); _floor_nodes.append(theme_lbl)

# ─── Section + Checkout Build (called after floor is set up) ──

func _build_sections_for_current_floor() -> void:
	_section_browse = SectionBrowse.new()
	add_child(_section_browse)
	_section_browse.item_added.connect(_on_item_added_to_cart)
	_section_browse.closed.connect(_on_browse_closed)

	for def in StoreData.SECTIONS:
		# Only show sections relevant to this floor
		# def.floor == -1 means "all floors" (legacy)
		# def.floor == current floor means specific floor
		if def.floor != _current_floor_idx and def.floor != -1:
			continue
		var sec := SupermarketSection.new()
		sec.configure(def)
		sec.position = Vector2(def.wx * CELL_SIZE, def.wy * CELL_SIZE)
		sec.name = "Section_%s" % def.id
		sec.player_entered.connect(_on_section_entered)
		sec.player_exited.connect(_on_section_exited)
		add_child(sec)
		_sections.append(sec)

func _build_checkout_for_current_floor() -> void:
	# Only ground floor (0) has staffed checkout lanes
	if _current_floor_idx != 0:
		return
	for lane in StoreData.CHECKOUT_LANES:
		var counter := Node2D.new()
		counter.position = Vector2(lane["x"] * CELL_SIZE, (StoreData.CHECKOUT_Y + 2) * CELL_SIZE)
		counter.name = "Counter_%s" % lane["name"]
		var bg := ColorRect.new()
		bg.size = Vector2(CELL_SIZE * 8, CELL_SIZE * 3)
		bg.color = Color(0.35, 0.28, 0.38)
		counter.add_child(bg)
		var top := ColorRect.new()
		top.size = Vector2(CELL_SIZE * 8, 2)
		top.color = Color(0.55, 0.45, 0.60)
		counter.add_child(top)
		var lbl := Label.new()
		lbl.text = lane["name"]
		lbl.position = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 0.90))
		lbl.add_theme_font_size_override("font_size", 8)
		counter.add_child(lbl)
		add_child(counter)
		_checkout_counters.append(counter)

# ─── Ambient Color ──────────────────────────────────────────────

func set_ambient_floor(idx: int) -> void:
	_current_floor_idx = idx
	_floor_ambient = Floors.ALL[idx].color_ambient
	_apply_ambient_shift()
	_update_floor_hud()

func _apply_ambient_shift() -> void:
	if _world_bg != null:
		_world_bg.color = _floor_ambient.darkened(0.6)

# ─── Helpers ───────────────────────────────────────────────────

func _set_wall(x: int, y: int) -> void:
	pass

func _unset_wall(x: int, y: int) -> void:
	pass

func _set_aisle_floor(x: int, y: int) -> void:
	pass

func _get_section_floor(style: int) -> Color:
	match style:
		StoreData.SectionStyle.FRIDGE:   return Color(0.14, 0.18, 0.24)
		StoreData.SectionStyle.PRODUCE:  return Color(0.14, 0.19, 0.12)
		StoreData.SectionStyle.BAKERY:  return Color(0.20, 0.15, 0.10)
		StoreData.SectionStyle.SHELF:    return Color(0.17, 0.16, 0.15)
		StoreData.SectionStyle.DELI:     return Color(0.19, 0.13, 0.13)
		StoreData.SectionStyle.FREEZER:  return Color(0.12, 0.16, 0.22)
	return Color(0.18, 0.17, 0.16)

func _get_wall_color(style: int) -> Color:
	match style:
		StoreData.SectionStyle.FRIDGE:   return Color(0.60, 0.78, 0.95)
		StoreData.SectionStyle.PRODUCE:  return Color(0.60, 0.82, 0.50)
		StoreData.SectionStyle.BAKERY:   return Color(0.82, 0.62, 0.38)
		StoreData.SectionStyle.SHELF:    return Color(0.72, 0.65, 0.55)
		StoreData.SectionStyle.DELI:     return Color(0.88, 0.55, 0.52)
		StoreData.SectionStyle.FREEZER:  return Color(0.55, 0.78, 0.95)
	return Color(0.65, 0.60, 0.50)

func _make_light_glow(col: Color) -> Texture2D:
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

func _make_sign(def) -> Sprite2D:
	var img := Image.create(80, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_sign_rect(img, 0, 0, 80, 12, _get_wall_color(def.style).darkened(0.3))
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

func _add_aisle_signs() -> void:
	for def in StoreData.SECTIONS:
		if def.id == "produce" or def.id == "meat":
			var lbl := Label.new()
			lbl.text = def.name
			lbl.position = Vector2(def.wx * CELL_SIZE + 2, (def.wy + def.wh + 1) * CELL_SIZE)
			lbl.add_theme_color_override("font_color", Color(def.light_color.r * 0.7, def.light_color.g * 0.7, def.light_color.b * 0.7, 0.8))
			lbl.add_theme_font_size_override("font_size", 8)
			lbl.z_index = 6
			add_child(lbl)
			_aisle_labels.append(lbl)
			_floor_nodes.append(lbl)

# ═══════════════════════════════════════════════════════════════
# ELEVATOR & STAIRS
# ═══════════════════════════════════════════════════════════════

func _build_elevator() -> void:
	_elevator = ElevatorScript.new()
	_elevator.name = "Elevator"
	_elevator.floor_reached.connect(_on_elevator_floor_reached)
	_elevator.travel_finished.connect(_on_elevator_travel_finished)
	add_child(_elevator)

func _build_stairs() -> void:
	# Stairs node (not animated, just visual reference + proximity)
	_stairs_node = Node2D.new()
	_stairs_node.name = "Stairs"
	add_child(_stairs_node)

func _build_parking() -> void:
	_parking_lot = ParkingLotScript.new()
	_parking_lot.name = "ParkingLot"
	add_child(_parking_lot)

# ─── Player boards elevator ────────────────────────────────────

func player_board_elevator(player, floor_idx: int) -> void:
	_in_elevator = true
	# Teleport player into elevator car
	var car_y: float = _elevator.get_car_world_y()
	_player.position = Vector2(80 * CELL_SIZE + 7 * CELL_SIZE, car_y + 5 * CELL_SIZE)

func get_elevator():
	return _elevator

# ─── Floor reached after travel ───────────────────────────────

func _on_elevator_floor_reached(floor_idx: int) -> void:
	_current_floor_idx = floor_idx

func _on_elevator_travel_finished() -> void:
	_in_elevator = false
	# Player exits at destination floor
	_rebuild_floor(_current_floor_idx)
	# Reattach player
	if _player != null:
		_player.position = Vector2(80 * CELL_SIZE + 7 * CELL_SIZE, 20 * CELL_SIZE)

func _rebuild_floor(idx: int) -> void:
	_clear_floor_nodes()
	_world_bg = null
	_build_floor(idx)
	_build_sections_for_current_floor()
	_build_checkout_for_current_floor()
	# Re-add elevator on top
	_elevator = get_node_or_null("Elevator")
	if _elevator == null:
		_build_elevator()
	_apply_ambient_shift()
	_update_floor_hud()

# ═══════════════════════════════════════════════════════════════
# CAMERA & HUD
# ═══════════════════════════════════════════════════════════════

func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(3.0, 3.0)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = WORLD_W * CELL_SIZE
	cam.limit_bottom = WORLD_H * CELL_SIZE
	cam.position_smoothing_speed = 3.0
	add_child(cam)
	cam.make_current()

func _build_hud() -> void:
	# Cart count top-left
	var cart_bg := ColorRect.new()
	cart_bg.position = Vector2(4.0, 4.0)
	cart_bg.size = Vector2(70.0, 16.0)
	cart_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	add_child(cart_bg)

	var cart_icon := Label.new()
	cart_icon.text = "Cart:"
	cart_icon.position = Vector2(6.0, 5.0)
	cart_icon.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	cart_icon.add_theme_font_size_override("font_size", 8)
	add_child(cart_icon)

	_cart_count_lbl = Label.new()
	_cart_count_lbl.text = "0 items  $0.00"
	_cart_count_lbl.position = Vector2(30.0, 5.0)
	_cart_count_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	_cart_count_lbl.add_theme_font_size_override("font_size", 8)
	add_child(_cart_count_lbl)

	# Zone prompt bottom center
	var prompt_bg := ColorRect.new()
	prompt_bg.name = "PromptBg"
	prompt_bg.position = Vector2(100.0, 164.0)
	prompt_bg.size = Vector2(120.0, 14.0)
	prompt_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	prompt_bg.visible = false
	add_child(prompt_bg)

	var prompt_lbl := Label.new()
	prompt_lbl.name = "PromptLbl"
	prompt_lbl.text = "[E] Browse"
	prompt_lbl.position = Vector2(104.0, 166.0)
	prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	prompt_lbl.add_theme_font_size_override("font_size", 8)
	prompt_lbl.visible = false
	add_child(prompt_lbl)

	# Checkout label
	_checkout_counter_label = Label.new()
	_checkout_counter_label.text = ""
	_checkout_counter_label.position = Vector2(100.0, 150.0)
	_checkout_counter_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.72))
	_checkout_counter_label.add_theme_font_size_override("font_size", 9)
	_checkout_counter_label.visible = false
	add_child(_checkout_counter_label)

	# Tab hint bottom right
	var tab_hint := Label.new()
	tab_hint.name = "TabHint"
	tab_hint.text = "[TAB] Cart"
	tab_hint.position = Vector2(264.0, 4.0)
	tab_hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	tab_hint.add_theme_font_size_override("font_size", 7)
	add_child(tab_hint)

func _update_floor_hud() -> void:
	if _floor_label != null and is_instance_valid(_floor_label):
		_floor_label.text = "Floor %s" % Floors.ALL[_current_floor_idx].label
	else:
		_floor_label = get_node_or_null("FloorLabelHUD")
		if _floor_label != null:
			_floor_label.text = "Floor %s" % Floors.ALL[_current_floor_idx].label

# ═══════════════════════════════════════════════════════════════
# PLAYER & NPCS
# ═══════════════════════════════════════════════════════════════

func _spawn_player() -> void:
	_player = Player.new()
	_player.position = Vector2(12 * CELL_SIZE, 4 * CELL_SIZE)
	add_child(_player)
	_player.set_world(self)
	_player.cart_updated.connect(_on_cart_updated)
	_player.interact_requested.connect(_on_player_interact)
	_player.tab_pressed.connect(_on_tab_pressed)
	_build_cart_panel()

func _build_npcs() -> void:
	# Only spawn NPCs on retail floors (spawn on floor 1 for now)
	var npc_scene = preload("res://scripts/npc_controller.gd")
	for i in range(6):
		var npc = npc_scene.new()
		npc.position = Vector2(20 * CELL_SIZE + randi() % (40 * CELL_SIZE), 6 * CELL_SIZE + randi() % (10 * CELL_SIZE))
		npc.name = "NPC_%d" % i
		add_child(npc)

# ═══════════════════════════════════════════════════════════════
# GAME LOOP — Proximity & Input
# ═══════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	if _in_elevator:
		return
	_update_player_section_proximity()
	_update_checkout_proximity()
	_update_elevator_proximity()
	_update_parking_proximity()
	_update_stairs_proximity()

func _update_elevator_proximity() -> void:
	if _player == null or _elevator == null:
		_nearby_elevator = false
		return
	_nearby_elevator = _elevator.is_nearby(_player.position)
	_nearby_stairs = false
	_nearby_parking = false

	# Show prompt
	var prompt_bg = get_node_or_null("PromptBg")
	var prompt_lbl = get_node_or_null("PromptLbl")
	if _nearby_elevator:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Elevator"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
		_checkout_counter_label.visible = false

func _update_parking_proximity() -> void:
	if _current_floor_idx != 0 or _player == null or _parking_lot == null:
		_nearby_parking = false
		return
	_nearby_parking = _parking_lot.is_player_near(_player.position)
	if _nearby_parking:
		var slot_idx = _parking_lot.get_nearby_slot(_player.position)
		var prompt_lbl = get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "Parking Slot %d" % (slot_idx + 1)
			prompt_lbl.visible = true
		var prompt_bg = get_node_or_null("PromptBg")
		if prompt_bg != null:
			prompt_bg.visible = true

func _update_stairs_proximity() -> void:
	if _player == null:
		return
	var stairs_pos := Vector2(85 * CELL_SIZE, 15 * CELL_SIZE)
	var dist := _player.position.distance_to(stairs_pos)
	_nearby_stairs = (dist < CELL_SIZE * 4.0)
	if _nearby_stairs and not _nearby_elevator:
		var prompt_lbl = get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Take Stairs"
			prompt_lbl.visible = true
		var prompt_bg = get_node_or_null("PromptBg")
		if prompt_bg != null:
			prompt_bg.visible = true

func _update_player_section_proximity() -> void:
	if _player == null:
		return
	var ppos = _player.position
	var nearest = null
	var nearest_dist := 99999.0

	for sec in _sections:
		var def = sec.get_def()
		var sx: float = (def.wx + def.ww * 0.5) * CELL_SIZE
		var sy: float = (def.wy + def.wh * 0.5) * CELL_SIZE
		var dist := ppos.distance_to(Vector2(sx, sy))
		if dist < nearest_dist and dist < CELL_SIZE * 9.0:
			nearest_dist = dist
			nearest = sec

	_nearby_section = nearest
	var prompt_bg = get_node_or_null("PromptBg")
	var prompt_lbl = get_node_or_null("PromptLbl")

	if nearest != null and not _nearby_elevator:
		_player.set_nearby_section(nearest)
		var def = nearest.get_def()
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Browse %s" % def.name
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
		_checkout_counter_label.visible = false
	elif not _nearby_elevator and not _nearby_stairs and not _nearby_parking:
		_player.set_nearby_section(null)
		if prompt_lbl != null:
			prompt_lbl.visible = false
		if prompt_bg != null:
			prompt_bg.visible = false

func _update_checkout_proximity() -> void:
	if _player == null:
		return
	var ppos = _player.position
	var near_checkout = null
	for counter in _checkout_counters:
		var dist := ppos.distance_to(counter.position + Vector2(CELL_SIZE * 4, CELL_SIZE * 1.5))
		if dist < CELL_SIZE * 5.0:
			near_checkout = counter
			break

	_nearby_checkout = near_checkout
	if near_checkout != null and not _nearby_elevator:
		_checkout_counter_label.text = "[E] Checkout at %s" % near_checkout.name.replace("Counter_", "")
		_checkout_counter_label.visible = true
	elif not _nearby_elevator:
		_checkout_counter_label.visible = false

# ─── Interact ──────────────────────────────────────────────────

func _on_player_interact() -> void:
	if _checkout_receipt_visible:
		_hide_checkout_receipt()
		return
	if _current_section_browse != null and _current_section_browse.visible:
		return

	# Elevator first
	if _nearby_elevator:
		_elevator.open_panel(_player.position, _player)
		return

	# Parking interaction (ground floor)
	if _nearby_parking:
		var slot_idx = _parking_lot.get_nearby_slot(_player.position)
		if slot_idx >= 0:
			_show_parking_info(slot_idx)
		return

	# Checkout with items
	if _nearby_checkout != null:
		var cart = _player.get_cart()
		if cart.get_item_count() > 0:
			_show_checkout_receipt()
			return

	# Section browse
	if _nearby_section != null:
		var def = _nearby_section.get_def()
		var prods = _nearby_section.get_all_products()
		_current_section_browse = _section_browse
		_section_browse.open(def.id, prods, _player.get_cart())
		notify_telegram_section_browse(def.name, prods.size())

func _show_parking_info(slot_idx: int) -> void:
	# Simple floating label showing slot info
	var slot_info = _parking_lot.get_slot_info(slot_idx)
	var lbl := Label.new()
	lbl.text = "Slot %d%s" % [slot_idx + 1, " [Occupied]" if slot_info.get("occupied", false) else " [Empty]"]
	lbl.position = Vector2(50.0, 80.0)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.60))
	lbl.add_theme_font_size_override("font_size", 8)
	add_child(lbl)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(lbl):
		lbl.queue_free()

func _on_section_entered(section_id: String) -> void:
	pass

func _on_section_exited(section_id: String) -> void:
	pass

func _on_browse_closed() -> void:
	_current_section_browse = null

func _on_item_added_to_cart(product, qty: int) -> void:
	pass

func _on_cart_updated(total_count: int, unique_count: int) -> void:
	if _cart_count_lbl != null:
		var cart = _player.get_cart()
		var sub = cart.get_subtotal() if cart != null else 0.0
		_cart_count_lbl.text = "%d items  $%.2f" % [total_count, sub]
	if _cart_panel_visible:
		_refresh_cart_panel()

func _on_tab_pressed() -> void:
	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	if _cart_panel_visible:
		_hide_cart_panel()
	else:
		_show_cart_panel()

# ═══════════════════════════════════════════════════════════════
# CART PANEL
# ═══════════════════════════════════════════════════════════════

func _build_cart_panel() -> void:
	_cart_panel = CanvasLayer.new()
	_cart_panel.name = "CartPanel"
	_cart_panel.visible = false
	add_child(_cart_panel)

	_cart_items_lbl = Label.new()
	_cart_items_lbl.name = "CartItems"
	_cart_items_lbl.position = Vector2(4.0, 4.0)
	_cart_items_lbl.size = Vector2(152.0, 110.0)
	_cart_items_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
	_cart_items_lbl.add_theme_font_size_override("font_size", 8)
	_cart_items_lbl.add_theme_constant_override("line_spacing", 2)
	_cart_panel.add_child(_cart_items_lbl)

	_cart_total_lbl = Label.new()
	_cart_total_lbl.name = "CartTotal"
	_cart_total_lbl.position = Vector2(4.0, 116.0)
	_cart_total_lbl.add_theme_color_override("font_color", Color(0.90, 0.78, 0.42))
	_cart_total_lbl.add_theme_font_size_override("font_size", 8)
	_cart_panel.add_child(_cart_total_lbl)

func _show_cart_panel() -> void:
	_refresh_cart_panel()
	_cart_panel.visible = true
	_cart_panel_visible = true

func _hide_cart_panel() -> void:
	_cart_panel.visible = false
	_cart_panel_visible = false

func _refresh_cart_panel() -> void:
	if _cart_panel == null or _player == null:
		return
	var cart = _player.get_cart()
	var items = cart.get_items()
	var lines: Array = []
	lines.append("── SHOPPING CART ──")
	if items.size() == 0:
		lines.append("(empty)")
	else:
		for entry in items:
			var prod = entry["product"]
			var qty = entry["qty"]
			var line = "%dx %s" % [qty, prod.name]
			if line.length() > 18:
				line = line.substr(0, 18)
			lines.append(line)
		var sub = cart.get_subtotal()
		lines.append("")
		lines.append("Subtotal: $%.2f" % sub)
	_cart_items_lbl.text = "\n".join(lines)
	var sub = cart.get_subtotal()
	var tax = cart.get_tax()
	var total = cart.get_total()
	_cart_total_lbl.text = "Sub: $%.2f  Tax: $%.2f\nTOTAL: $%.2f" % [sub, tax, total]

# ═══════════════════════════════════════════════════════════════
# CHECKOUT RECEIPT
# ═══════════════════════════════════════════════════════════════

func _show_checkout_receipt() -> void:
	_checkout_receipt_visible = true
	_hide_cart_panel()

	var ov := ColorRect.new()
	ov.name = "CROverlay"
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.03, 0.03, 0.06, 0.90)
	ov.gui_input.connect(_on_receipt_input)
	add_child(ov)

	var pan_x: float = (320.0 - 220.0) * 0.5
	var pan_y: float = (180.0 - 165.0) * 0.5

	var pan := ColorRect.new()
	pan.name = "CRPanel"
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(220.0, 165.0)
	pan.color = Color(0.09, 0.09, 0.13, 1.0)
	pan.gui_input.connect(_on_receipt_input)
	add_child(pan)

	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(220.0, 16.0)
	hdr.color = Color(0.22, 0.18, 0.30, 1.0)
	hdr.gui_input.connect(_on_receipt_input)
	add_child(hdr)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "═══ CHECKOUT ═══"
	hdr_lbl.position = Vector2(pan_x + 60.0, pan_y + 3.0)
	hdr_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.95))
	hdr_lbl.add_theme_font_size_override("font_size", 9)
	hdr_lbl.gui_input.connect(_on_receipt_input)
	add_child(hdr_lbl)

	var cart = _player.get_cart()
	var items = cart.get_items()
	var y_pos: float = pan_y + 20.0
	var line_h: float = 10.0

	for entry in items:
		var prod = entry["product"]
		var qty = entry["qty"]
		var line_lbl := Label.new()
		line_lbl.position = Vector2(pan_x + 6.0, y_pos)
		line_lbl.size = Vector2(210.0, line_h)
		line_lbl.text = "%dx %s" % [qty, prod.name]
		line_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78))
		line_lbl.add_theme_font_size_override("font_size", 8)
		line_lbl.gui_input.connect(_on_receipt_input)
		add_child(line_lbl)

		var price_lbl := Label.new()
		price_lbl.position = Vector2(pan_x + 160.0, y_pos)
		price_lbl.text = "$%.2f" % (prod.price * qty)
		price_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78))
		price_lbl.add_theme_font_size_override("font_size", 8)
		price_lbl.gui_input.connect(_on_receipt_input)
		add_child(price_lbl)
		y_pos += line_h

	var div := ColorRect.new()
	div.position = Vector2(pan_x + 6.0, y_pos + 1.0)
	div.size = Vector2(208.0, 1.0)
	div.color = Color(0.30, 0.30, 0.35, 1.0)
	add_child(div)
	y_pos += 6.0

	var sub = cart.get_subtotal()
	var tax_amt = cart.get_tax()
	var total = cart.get_total()

	var sub_lbl := Label.new()
	sub_lbl.position = Vector2(pan_x + 110.0, y_pos)
	sub_lbl.text = "Subtotal:"
	sub_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	sub_lbl.add_theme_font_size_override("font_size", 8)
	sub_lbl.gui_input.connect(_on_receipt_input)
	add_child(sub_lbl)
	var sub_val := Label.new()
	sub_val.position = Vector2(pan_x + 160.0, y_pos)
	sub_val.text = "$%.2f" % sub
	sub_val.add_theme_color_override("font_color", Color(0.75, 0.75, 0.72))
	sub_val.add_theme_font_size_override("font_size", 8)
	sub_val.gui_input.connect(_on_receipt_input)
	add_child(sub_val)
	y_pos += line_h

	var tax_lbl := Label.new()
	tax_lbl.position = Vector2(pan_x + 110.0, y_pos)
	tax_lbl.text = "Tax (6%):"
	tax_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	tax_lbl.add_theme_font_size_override("font_size", 8)
	tax_lbl.gui_input.connect(_on_receipt_input)
	add_child(tax_lbl)
	var tax_val := Label.new()
	tax_val.position = Vector2(pan_x + 160.0, y_pos)
	tax_val.text = "$%.2f" % tax_amt
	tax_val.add_theme_color_override("font_color", Color(0.75, 0.75, 0.72))
	tax_val.add_theme_font_size_override("font_size", 8)
	tax_val.gui_input.connect(_on_receipt_input)
	add_child(tax_val)
	y_pos += line_h + 2.0

	var tot_lbl := Label.new()
	tot_lbl.position = Vector2(pan_x + 110.0, y_pos)
	tot_lbl.text = "TOTAL:"
	tot_lbl.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	tot_lbl.add_theme_font_size_override("font_size", 9)
	tot_lbl.gui_input.connect(_on_receipt_input)
	add_child(tot_lbl)
	var tot_val := Label.new()
	tot_val.position = Vector2(pan_x + 160.0, y_pos)
	tot_val.text = "$%.2f" % total
	tot_val.add_theme_color_override("font_color", Color(0.95, 0.85, 0.42))
	tot_val.add_theme_font_size_override("font_size", 9)
	tot_val.gui_input.connect(_on_receipt_input)
	add_child(tot_val)
	y_pos += line_h + 8.0

	var thanks := Label.new()
	thanks.position = Vector2(pan_x + 40.0, y_pos)
	thanks.text = "THANK YOU FOR SHOPPING!"
	thanks.add_theme_color_override("font_color", Color(0.72, 0.88, 0.72))
	thanks.add_theme_font_size_override("font_size", 8)
	thanks.gui_input.connect(_on_receipt_input)
	add_child(thanks)
	y_pos += line_h + 4.0

	var done_lbl := Label.new()
	done_lbl.position = Vector2(pan_x + 60.0, y_pos)
	done_lbl.text = "[E] Done"
	done_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.48))
	done_lbl.add_theme_font_size_override("font_size", 8)
	done_lbl.gui_input.connect(_on_receipt_input)
	add_child(done_lbl)

func _hide_checkout_receipt() -> void:
	_checkout_receipt_visible = false
	for name in ["CROverlay", "CRPanel"]:
		var node = get_node_or_null("/root/Main/" + name)
		if node == null:
			node = get_node_or_null(name)
		if node != null:
			node.queue_free()
	var to_remove: Array = []
	for c in get_children():
		if c is Label or c is ColorRect:
			var nm = c.name if c is Label or c is ColorRect else ""
			if nm in ["CROverlay", "CRPanel"]:
				continue
			if c.get_parent() == self and c.position.y >= 0:
				if c is Label and c.position.x >= 40.0 and c.position.x <= 280.0:
					to_remove.append(c)
				elif c is ColorRect and c.position.x >= 40.0 and c.position.x <= 280.0:
					to_remove.append(c)
	for c in to_remove:
		c.queue_free()

func _on_receipt_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k = event as InputEventKey
		if k.keycode == KEY_E or k.keycode == KEY_ESCAPE or k.keycode == KEY_TAB:
			_finish_checkout()

func _finish_checkout() -> void:
	var cart = _player.get_cart()
	var items = cart.get_items()
	var total_count = cart.get_item_count()
	var total_amount = cart.get_total()
	_hide_checkout_receipt()
	cart.clear()
	_refresh_cart_panel()
	notify_telegram_checkout(total_amount, total_count)

# ═══════════════════════════════════════════════════════════════
# TELEGRAM
# ═══════════════════════════════════════════════════════════════

func notify_telegram(msg: String) -> void:
	if _telegram_bot != null:
		_telegram_bot.queue_report(msg)

func notify_telegram_checkout(total: float, item_count: int) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_player_checkout(total, item_count)

func notify_telegram_section_browse(section_name: String, product_count: int) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_section_browse(section_name, product_count)

func notify_telegram_npc(count: int) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_npc_spawn(count)

func notify_telegram_error(err: String) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_game_error(err)
