# food_stall_browse.gd
# Food stall order menu — shows stall info, menu items, qty selector.
# Press ESC to close. Press Enter or click to add to cart.
class_name FoodStallBrowse
extends CanvasLayer

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")

signal item_added(item_name: String, qty: int, price: float)
signal closed()

const PANEL_W := 270.0
const PANEL_H := 160.0
const ITEM_H  := 22.0

var _stall_def: FloorConfig.FoodStallDef
var _items: Array = []     # {name, price, desc}
var _selected: int = 0
var _qty: int = 1
var _cart_ref = null
var _item_nodes: Array = []

func _ready() -> void:
	visible = false

func open(stall_def: FloorConfig.FoodStallDef, cart) -> void:
	_stall_def = stall_def
	_items = stall_def.menu
	_selected = 0
	_qty = 1
	_cart_ref = cart

	_close_children()
	_build()
	visible = true

func _close_children() -> void:
	for c in get_children():
		c.queue_free()
	_item_nodes.clear()

func close() -> void:
	visible = false
	_close_children()
	closed.emit()

func _build() -> void:
	var pan_x := (320.0 - PANEL_W) * 0.5
	var pan_y := (180.0 - PANEL_H) * 0.5

	# Dark overlay
	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.03, 0.03, 0.06, 0.88)
	ov.gui_input.connect(_on_overlay_input)
	add_child(ov)

	# Panel background
	var pan := ColorRect.new()
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(PANEL_W, PANEL_H)
	pan.color = Color(0.08, 0.08, 0.12, 1.0)
	pan.gui_input.connect(_on_overlay_input)
	add_child(pan)

	# Header bar
	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(PANEL_W, 16)
	hdr.color = _stall_def.color.darkened(0.4)
	hdr.gui_input.connect(_on_overlay_input)
	add_child(hdr)

	# Stall name header
	var hdr_lbl := Label.new()
	hdr_lbl.text = "  %s  —  %s" % [_stall_def.name, _stall_def.cuisine]
	hdr_lbl.position = Vector2(pan_x + 4, pan_y + 3)
	hdr_lbl.add_theme_color_override("font_color", _stall_def.glow_color)
	hdr_lbl.add_theme_font_size_override("font_size", 9)
	hdr_lbl.gui_input.connect(_on_overlay_input)
	add_child(hdr_lbl)

	# Column headers
	var col_name := Label.new()
	col_name.text = "ITEM"
	col_name.position = Vector2(pan_x + 6, pan_y + 18)
	col_name.add_theme_color_override("font_color", Color(0.50, 0.50, 0.58))
	col_name.add_theme_font_size_override("font_size", 7)
	add_child(col_name)

	var col_price := Label.new()
	col_price.text = "PRICE"
	col_price.position = Vector2(pan_x + PANEL_W - 44, pan_y + 18)
	col_price.add_theme_color_override("font_color", Color(0.50, 0.50, 0.58))
	col_price.add_theme_font_size_override("font_size", 7)
	add_child(col_price)

	# Divider
	var div := ColorRect.new()
	div.position = Vector2(pan_x + 4, pan_y + 26)
	div.size = Vector2(PANEL_W - 8, 1)
	div.color = Color(0.30, 0.30, 0.35)
	add_child(div)

	# Menu items (scroll if needed)
	var max_visible := 5
	var scroll_h := minf(_items.size(), max_visible) * ITEM_H
	var y_pos := pan_y + 29.0

	for i in range(mini(_items.size(), max_visible)):
		var item: Dictionary = _items[i]
		var is_sel := (i == _selected)
		var row_bg: ColorRect

		if is_sel:
			row_bg = ColorRect.new()
			row_bg.position = Vector2(pan_x + 4, y_pos)
			row_bg.size = Vector2(PANEL_W - 8, ITEM_H - 1)
			row_bg.color = _stall_def.color.darkened(0.55)
			row_bg.gui_input.connect(_on_item_input.bind(i))
			add_child(row_bg)
			_item_nodes.append(row_bg)

		var name_lbl := Label.new()
		name_lbl.text = item["name"]
		name_lbl.position = Vector2(pan_x + 6, y_pos + 2)
		name_lbl.add_theme_color_override("font_color",
			_stall_def.glow_color if is_sel else Color(0.82, 0.82, 0.78))
		name_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.gui_input.connect(_on_item_input.bind(i))
		add_child(name_lbl)
		_item_nodes.append(name_lbl)

		var price_lbl := Label.new()
		price_lbl.text = "$%.2f" % item["price"]
		price_lbl.position = Vector2(pan_x + PANEL_W - 44, y_pos + 2)
		price_lbl.add_theme_color_override("font_color",
			_stall_def.glow_color if is_sel else Color(0.80, 0.78, 0.60))
		price_lbl.add_theme_font_size_override("font_size", 8)
		name_lbl.gui_input.connect(_on_item_input.bind(i))
		add_child(price_lbl)
		_item_nodes.append(price_lbl)

		# Description on selected item
		if is_sel:
			var desc_lbl := Label.new()
			desc_lbl.text = item["desc"]
			desc_lbl.position = Vector2(pan_x + 6, y_pos + ITEM_H + 2)
			desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
			desc_lbl.add_theme_font_size_override("font_size", 7)
			desc_lbl.gui_input.connect(_on_item_input.bind(i))
			add_child(desc_lbl)
			_item_nodes.append(desc_lbl)

		y_pos += ITEM_H

	# Qty selector
	y_pos = pan_y + PANEL_H - 30.0
	var qty_lbl := Label.new()
	qty_lbl.text = "QTY: %d" % _qty
	qty_lbl.position = Vector2(pan_x + 6, y_pos)
	qty_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	qty_lbl.add_theme_font_size_override("font_size", 8)
	qty_lbl.name = "QtyLbl"
	add_child(qty_lbl)
	_item_nodes.append(qty_lbl)

	# Total
	if _selected < _items.size():
		var total: float = _items[_selected]["price"] * _qty
		var tot_lbl: Label = Label.new()
		tot_lbl.text = "TOTAL: $%.2f" % total
		tot_lbl.position = Vector2(pan_x + PANEL_W - 80, y_pos)
		tot_lbl.add_theme_color_override("font_color", _stall_def.glow_color)
		tot_lbl.add_theme_font_size_override("font_size", 8)
		tot_lbl.name = "TotLbl"
		add_child(tot_lbl)
		_item_nodes.append(tot_lbl)

	# Controls hint
	var hint := Label.new()
	hint.text = "[W/S] Navigate  [E/+] Add to Cart  [ESC] Close"
	hint.position = Vector2(pan_x + 4, pan_y + PANEL_H - 10)
	hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.40))
	hint.add_theme_font_size_override("font_size", 7)
	add_child(hint)
	_item_nodes.append(hint)

func _on_overlay_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not (key_event and key_event.pressed):
		return
	
	match key_event.keycode:
		KEY_ESCAPE:
			close()
		KEY_W, KEY_UP:
			_selected = wrapi(_selected - 1, 0, _items.size())
			_refresh()
		KEY_S, KEY_DOWN:
			_selected = wrapi(_selected + 1, 0, _items.size())
			_refresh()
		KEY_E, KEY_KP_ADD, KEY_PLUS:
			_add_to_cart()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			_qty = key_event.keycode - KEY_0
			_refresh()

func _on_item_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var idx: int = (event as InputEventMouseButton).get_button_index()
		if idx == MOUSE_BUTTON_LEFT:
			var local_pos := (event as InputEventMouseButton).position
			# Rough y-to-index mapping
			var pan_y := (180.0 - PANEL_H) * 0.5
			var item_idx := int((local_pos.y - (pan_y + 29.0)) / ITEM_H)
			if item_idx >= 0 and item_idx < _items.size():
				_selected = item_idx
				_add_to_cart()
		elif idx == MOUSE_BUTTON_WHEEL_UP:
			_selected = wrapi(_selected - 1, 0, _items.size())
			_refresh()
		elif idx == MOUSE_BUTTON_WHEEL_DOWN:
			_selected = wrapi(_selected + 1, 0, _items.size())
			_refresh()

func _add_to_cart() -> void:
	if _selected < 0 or _selected >= _items.size():
		return
	var item: Dictionary = _items[_selected]
	item_added.emit(item["name"], _qty, item["price"])
	_qty = 1
	_refresh()

func _refresh() -> void:
	_close_children()
	_build()

# Override to intercept unhandled key input
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				close()
			KEY_W, KEY_UP:
				_selected = wrapi(_selected - 1, 0, _items.size())
				_refresh()
			KEY_S, KEY_DOWN:
				_selected = wrapi(_selected + 1, 0, _items.size())
				_refresh()
			KEY_E, KEY_KP_ADD, KEY_PLUS:
				_add_to_cart()
