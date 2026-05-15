# price_terminal.gd
# Price Management Terminal UI — opened from Floor 9 Staff Room terminal.
# Allows staff to view all products, filter by section, and edit prices.
class_name PriceTerminal
extends CanvasLayer

const StoreData = preload("res://scripts/world/store_data.gd")

signal closed()
signal price_saved(product_id: String, new_price: float)

const PANEL_W := 290.0
const PANEL_H := 175.0
const ITEM_H := 16.0
const GRID_COLS := 2

var _products: Array = []
var _filtered: Array = []
var _selected: int = 0
var _scroll_offset: int = 0
var _item_nodes: Array = []
var _edit_mode: bool = false
var _edit_product_id: String = ""
var _edit_new_price_str: String = ""
var _active_section_filter: String = "ALL"
var _sections: Array = ["ALL"]

var _sel_bg: ColorRect
var _name_lbl: Label
var _price_lbl: Label
var _override_lbl: Label
var _hint_lbl: Label
var _search_lbl: Label
var _search_filter_lbl: Label

func _ready() -> void:
	visible = false

func open() -> void:
	_build_product_list()
	_active_section_filter = "ALL"
	_filtered = _products.duplicate()
	_selected = 0
	_scroll_offset = 0
	_edit_mode = false
	
	_close_children()
	_build()
	visible = true

func _build_product_list() -> void:
	_products.clear()
	_sections = ["ALL"]
	var seen_sections := {}
	for p in StoreData.CATALOG:
		var entry := {
			"id": p.id,
			"name": p.name,
			"price": PriceOverride.get_price(p.id),
			"original_price": p.price,
			"has_override": PriceOverride.has_override(p.id),
			"section": p.section,
			"sub": p.sub,
		}
		_products.append(entry)
		if not seen_sections.has(p.section):
			seen_sections[p.section] = true
			_sections.append(p.section)
	_sections.sort()

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

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.03, 0.05, 0.08, 0.92)
	add_child(ov)

	var panel := ColorRect.new()
	panel.position = Vector2(pan_x, pan_y)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.07, 0.10, 0.14, 1.0)
	add_child(panel)

	var border := ColorRect.new()
	border.position = Vector2(pan_x, pan_y)
	border.size = Vector2(PANEL_W, 1)
	border.color = Color(0.50, 0.85, 1.00, 0.8)
	add_child(border)

	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(PANEL_W, 14.0)
	hdr.color = Color(0.10, 0.18, 0.25, 1.0)
	add_child(hdr)

	var title := Label.new()
	title.text = "[ PRICE MANAGEMENT TERMINAL ]"
	title.position = Vector2(pan_x + 4, pan_y + 2)
	title.add_theme_color_override("font_color", Color(0.50, 0.85, 1.00))
	title.add_theme_font_size_override("font_size", 8)
	add_child(title)

	var close_lbl := Label.new()
	close_lbl.text = "[ESC] Close"
	close_lbl.position = Vector2(pan_x + PANEL_W - 56, pan_y + 3)
	close_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
	close_lbl.add_theme_font_size_override("font_size", 7)
	add_child(close_lbl)

	var filter_y := pan_y + 14.0
	var filter_bg := ColorRect.new()
	filter_bg.position = Vector2(pan_x, filter_y)
	filter_bg.size = Vector2(PANEL_W, 12.0)
	filter_bg.color = Color(0.06, 0.09, 0.12, 1.0)
	add_child(filter_bg)

	_search_lbl = Label.new()
	_search_lbl.text = "[←→] Section  [↑↓] Navigate  [E] Edit Price  [S] Save"
	_search_lbl.position = Vector2(pan_x + 4, filter_y + 2)
	_search_lbl.add_theme_color_override("font_color", Color(0.45, 0.60, 0.70))
	_search_lbl.add_theme_font_size_override("font_size", 6)
	add_child(_search_lbl)

	_search_filter_lbl = Label.new()
	_search_filter_lbl.text = "Filter: ALL"
	_search_filter_lbl.position = Vector2(pan_x + PANEL_W - 80, filter_y + 2)
	_search_filter_lbl.add_theme_color_override("font_color", Color(0.60, 0.80, 0.90))
	_search_filter_lbl.add_theme_font_size_override("font_size", 6)
	add_child(_search_filter_lbl)

	var grid_y := filter_y + 12.0
	var grid_h := PANEL_H - 14.0 - 12.0 - 28.0
	var grid_bottom := grid_y + grid_h

	var scroll_bg := ColorRect.new()
	scroll_bg.position = Vector2(pan_x, grid_y)
	scroll_bg.size = Vector2(PANEL_W, grid_h)
	scroll_bg.color = Color(0.05, 0.07, 0.10, 1.0)
	add_child(scroll_bg)

	_build_grid(pan_x, grid_y, PANEL_W, grid_h)

	var det_y := grid_bottom + 1
	var det := ColorRect.new()
	det.position = Vector2(pan_x, det_y)
	det.size = Vector2(PANEL_W, 26.0)
	det.color = Color(0.06, 0.09, 0.12, 1.0)
	add_child(det)

	var det_border := ColorRect.new()
	det_border.position = Vector2(pan_x, det_y)
	det_border.size = Vector2(PANEL_W, 1)
	det_border.color = Color(0.20, 0.35, 0.50, 1.0)
	add_child(det_border)

	_name_lbl = Label.new()
	_name_lbl.position = Vector2(pan_x + 4, det_y + 2)
	_name_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.88))
	_name_lbl.add_theme_font_size_override("font_size", 8)
	add_child(_name_lbl)

	_price_lbl = Label.new()
	_price_lbl.position = Vector2(pan_x + 4, det_y + 12)
	_price_lbl.add_theme_color_override("font_color", Color(0.90, 0.78, 0.42))
	_price_lbl.add_theme_font_size_override("font_size", 8)
	add_child(_price_lbl)

	_override_lbl = Label.new()
	_override_lbl.position = Vector2(pan_x + 90, det_y + 12)
	_override_lbl.add_theme_color_override("font_color", Color(0.60, 0.90, 0.60))
	_override_lbl.add_theme_font_size_override("font_size", 7)
	add_child(_override_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.position = Vector2(pan_x + PANEL_W - 100, det_y + 8)
	_hint_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	_hint_lbl.add_theme_font_size_override("font_size", 6)
	add_child(_hint_lbl)

	_update_detail()
	_update_hint()

	var kb := InputEventHandler.new()
	kb.action_pressed.connect(_on_key_action)
	add_child(kb)

func _build_grid(pan_x: float, grid_y: float, grid_w: float, grid_h: float) -> void:
	for n in _item_nodes:
		n.queue_free()
	_item_nodes.clear()

	var item_w := grid_w / float(GRID_COLS)
	var start_y := grid_y
	var row := 0
	var col := 0
	var vis_rows := int(grid_h / ITEM_H)
	var vis_count := vis_rows * GRID_COLS
	var start_idx := _scroll_offset * GRID_COLS

	for i in range(start_idx, min(start_idx + vis_count, _filtered.size())):
		var ix := pan_x + col * item_w + 2.0
		var iy := start_y + row * ITEM_H

		if iy + ITEM_H > start_y + grid_h:
			break

		var is_sel := (i == _selected)
		var entry = _filtered[i]

		var bg := ColorRect.new()
		bg.size = Vector2(item_w - 4, ITEM_H - 1)
		bg.position = Vector2(ix, iy)
		bg.color = Color(0.15, 0.30, 0.45, 0.7) if is_sel else Color(0.08, 0.11, 0.15, 1.0)
		add_child(bg)
		_item_nodes.append(bg)

		var num_lbl := Label.new()
		num_lbl.text = "%d" % ((i % 9) + 1)
		num_lbl.position = Vector2(ix + 2, iy + 1)
		num_lbl.add_theme_color_override("font_color", Color(0.30, 0.30, 0.35))
		num_lbl.add_theme_font_size_override("font_size", 5)
		add_child(num_lbl)
		_item_nodes.append(num_lbl)

		var name_lbl := Label.new()
		name_lbl.text = entry["name"]
		name_lbl.position = Vector2(ix + 14, iy + 1)
		name_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
		name_lbl.add_theme_font_size_override("font_size", 7)
		name_lbl.size = Vector2(item_w - 40, 9)
		name_lbl.clip_text = true
		add_child(name_lbl)
		_item_nodes.append(name_lbl)

		var price_lbl := Label.new()
		price_lbl.text = "$%.2f" % entry["price"]
		price_lbl.position = Vector2(ix + 14, iy + 10)
		if entry["has_override"]:
			price_lbl.add_theme_color_override("font_color", Color(0.50, 0.90, 0.60))
		else:
			price_lbl.add_theme_color_override("font_color", Color(0.82, 0.70, 0.38))
		price_lbl.add_theme_font_size_override("font_size", 7)
		add_child(price_lbl)
		_item_nodes.append(price_lbl)

		if entry["has_override"]:
			var orig_lbl := Label.new()
			orig_lbl.text = "(was $%.2f)" % entry["original_price"]
			orig_lbl.position = Vector2(ix + 60, iy + 10)
			orig_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.42))
			orig_lbl.add_theme_font_size_override("font_size", 5)
			add_child(orig_lbl)
			_item_nodes.append(orig_lbl)

		col += 1
		if col >= GRID_COLS:
			col = 0; row += 1

func _update_detail() -> void:
	if _filtered.size() == 0:
		_name_lbl.text = "(no products)"
		_price_lbl.text = ""
		_override_lbl.text = ""
		return
	var entry = _filtered[_selected]
	_name_lbl.text = entry["name"]
	var effective: float = PriceOverride.get_price(entry["id"])
	var original: float = entry["original_price"]
	_price_lbl.text = "Price: $%.2f" % effective
	if entry["has_override"] or effective != original:
		_override_lbl.text = "[MODIFIED from $%.2f]" % original
	else:
		_override_lbl.text = "[original]"
	_hint_lbl.text = "[E] Edit"

func _update_hint() -> void:
	if _edit_mode:
		_hint_lbl.text = "[Enter] Save  [Esc] Cancel"
	else:
		_hint_lbl.text = "[E] Edit"

func _on_key_action(action: String) -> void:
	match action:
		"ui_up":
			_selected = max(0, _selected - GRID_COLS)
			_scroll_if_needed()
			_refresh_grid()
			_update_detail()
		"ui_down":
			_selected = min(_filtered.size() - 1, _selected + GRID_COLS)
			_scroll_if_needed()
			_refresh_grid()
			_update_detail()
		"ui_left":
			_cycle_section_filter(-1)
		"ui_right":
			_cycle_section_filter(1)
		"ui_accept":
			if _edit_mode:
				_save_edit()
			else:
				_start_edit()
		"escape":
			if _edit_mode:
				_cancel_edit()
			else:
				close()
		"num_increase":
			if _edit_mode:
				_adjust_edit_price(0.10)
		"num_decrease":
			if _edit_mode:
				_adjust_edit_price(-0.10)
		"page_up":
			_scroll_offset = max(0, _scroll_offset - 3)
			_refresh_grid()
		"page_down":
			var vis_rows := 8
			var max_scroll := int(max(0, ceil(_filtered.size() / float(GRID_COLS)) - vis_rows))
			_scroll_offset = min(max_scroll, _scroll_offset + 3)
			_refresh_grid()
		_:
			if action.begins_with("num_"):
				var idx := action.replace("num_", "").to_int() - 1
				if idx >= 0 and idx < _filtered.size():
					_selected = idx
					_scroll_if_needed()
					_refresh_grid()
					_update_detail()

func _cycle_section_filter(dir: int) -> void:
	var idx := _sections.find(_active_section_filter)
	idx = wrapi(idx + dir, 0, _sections.size())
	_active_section_filter = _sections[idx]
	_filter_by_section()
	_selected = 0
	_scroll_offset = 0
	_refresh_grid()
	_update_detail()
	_search_filter_lbl.text = "Filter: %s" % _active_section_filter

func _filter_by_section() -> void:
	if _active_section_filter == "ALL":
		_filtered = _products.duplicate()
	else:
		_filtered = _products.filter(func(e): return e["section"] == _active_section_filter)

func _scroll_if_needed() -> void:
	var vis_rows := 8
	var sel_row := _selected / GRID_COLS
	var vis_start := _scroll_offset
	var vis_end := _scroll_offset + vis_rows
	if sel_row < vis_start:
		_scroll_offset = sel_row
	elif sel_row >= vis_end:
		_scroll_offset = sel_row - vis_rows + 1

func _refresh_grid() -> void:
	var pan_x := (320.0 - PANEL_W) * 0.5
	var pan_y := (180.0 - PANEL_H) * 0.5
	var filter_y := pan_y + 14.0 + 12.0
	var grid_h := PANEL_H - 14.0 - 12.0 - 28.0
	_build_grid(pan_x, filter_y, PANEL_W, grid_h)

func _start_edit() -> void:
	if _filtered.size() == 0:
		return
	_edit_mode = true
	var entry = _filtered[_selected]
	_edit_product_id = entry["id"]
	_edit_new_price_str = "%.2f" % PriceOverride.get_price(_edit_product_id)
	_hint_lbl.text = "Type price: %s  [Enter]Save [Esc]Cancel" % _edit_new_price_str

func _adjust_edit_price(delta: float) -> void:
	var v := _edit_new_price_str.to_float() + delta
	v = max(0.01, v)
	_edit_new_price_str = "%.2f" % v
	_hint_lbl.text = "New price: $%s  [Enter]Save [Esc]Cancel" % _edit_new_price_str

func _save_edit() -> void:
	if _edit_product_id == "":
		_cancel_edit()
		return
	var new_price: float = _edit_new_price_str.to_float()
	if new_price > 0.0:
		PriceOverride.set_price(_edit_product_id, new_price)
		for i in range(_products.size()):
			if _products[i]["id"] == _edit_product_id:
				_products[i]["price"] = new_price
				_products[i]["has_override"] = PriceOverride.has_override(_edit_product_id)
		_filter_by_section()
		_selected = min(_selected, _filtered.size() - 1)
		_refresh_grid()
		_update_detail()
		price_saved.emit(_edit_product_id, new_price)
	_edit_mode = false
	_edit_product_id = ""
	_update_hint()

func _cancel_edit() -> void:
	_edit_mode = false
	_edit_product_id = ""
	_update_hint()

# ─── Tiny input handler node ──────────────────────────────────────────
class InputEventHandler extends Node:
	signal action_pressed(action: String)

	func _input(event: InputEvent) -> void:
		if not (event is InputEventKey and event.pressed):
			return
		var ev := event as InputEventKey
		match ev.keycode:
			KEY_ESCAPE: action_pressed.emit("escape")
			KEY_E: action_pressed.emit("ui_accept")
			KEY_W, KEY_UP: action_pressed.emit("ui_up")
			KEY_S, KEY_DOWN: action_pressed.emit("ui_down")
			KEY_A, KEY_LEFT: action_pressed.emit("ui_left")
			KEY_D, KEY_RIGHT: action_pressed.emit("ui_right")
			KEY_PAGEUP: action_pressed.emit("page_up")
			KEY_PAGEDOWN: action_pressed.emit("page_down")
			KEY_Q: action_pressed.emit("num_decrease")
			KEY_R: action_pressed.emit("num_increase")
			KEY_1: action_pressed.emit("num_1")
			KEY_2: action_pressed.emit("num_2")
			KEY_3: action_pressed.emit("num_3")
			KEY_4: action_pressed.emit("num_4")
			KEY_5: action_pressed.emit("num_5")
			KEY_6: action_pressed.emit("num_6")
			KEY_7: action_pressed.emit("num_7")
			KEY_8: action_pressed.emit("num_8")
			KEY_9: action_pressed.emit("num_9")
