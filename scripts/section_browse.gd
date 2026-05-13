# section_browse.gd
# Full-screen interactive product browser for a supermarket section.
# Shows category tabs, scrollable product grid, and item detail panel.
# Supports both keyboard (WASD/Arrows + E/ESC) and mouse (click + scroll) input.

class_name SectionBrowse
extends CanvasLayer

const StoreData = preload("res://scripts/store_data.gd")

signal item_added(product, qty: int)
signal closed()

# Layout constants
const BASE_GRID_COLS := 6
const ITEM_H := 72.0
const DETAIL_H := 90.0
const HEADER_H := 48.0
const TAB_H := 36.0
const SCROLLBAR_W := 14.0
const PADDING := 12.0
const ITEM_MARGIN := 6.0

var _section_id := ""
var _all_products: Array = []
var _filtered_products: Array = []
var _subcategories: Array = []
var _active_sub := "ALL"
var _selected := 0
var _scroll_offset := 0.0
var _cart_ref = null
var _qty := 1
var _row_nodes: Array = []

# Layout dimensions
var _panel_w := 0.0
var _panel_h := 0.0
var _grid_cols := BASE_GRID_COLS
var _item_w := 0.0
var _grid_x := 0.0
var _grid_y := 0.0
var _grid_w := 0.0
var _grid_h := 0.0
var _pan_x := 0.0
var _pan_y := 0.0

# UI references for mouse handling
var _tab_btns: Array = []
var _item_nodes: Array = []
var _item_bounds: Array = []  # Array of {rect, index} for click detection
var _scroll_knob: ColorRect
var _def = null

# Mouse state
var _is_dragging_scroll := false
var _last_mouse_y := 0.0

func _ready() -> void:
	visible = false
	var main = get_tree().get_first_node_in_group("main")
	if main != null:
		var po = main.get_node_or_null("PriceOverride")
		if po != null and po.has_signal("price_changed"):
			po.price_changed.connect(_on_price_changed)

func _on_price_changed(product_id: String, new_price: float) -> void:
	if visible and _section_id != "":
		_build()

func open_section(section) -> void:
	var def = section.get_def()
	var section_id = def.id
	var products = section.get_all_products()

	var main = get_tree().root.get_node_or_null("Main")
	if main != null:
		var bm = main.get_node_or_null("BrandManager")
		if bm != null and bm.has_method("get_all_brand_products"):
			var brand_prods = bm.get_all_brand_products()
			for entry in brand_prods:
				var p: Dictionary = entry.product if entry.has("product") else entry
				if p.get("section", "") == section_id:
					products.append(p)

	var cart = null
	if main != null:
		var pl = main.get_node_or_null("Player")
		if pl != null:
			cart = pl.get_cart()
	open(section_id, products, cart)

func open(section_id: String, products: Array, cart) -> void:
	_section_id = section_id
	_all_products = products
	_cart_ref = cart
	_selected = 0
	_scroll_offset = 0.0
	_qty = 1
	_filtered_products = products
	_subcategories = ["ALL"] + StoreData.get_subcategories(section_id)
	_active_sub = "ALL"
	
	_close_children()
	_build()
	visible = true

func _close_children() -> void:
	for c in get_children():
		c.queue_free()
	_item_nodes.clear()
	_item_bounds.clear()
	_tab_btns.clear()
	_row_nodes.clear()
	_is_dragging_scroll = false

func close() -> void:
	visible = false
	_close_children()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Handle mouse wheel for scrolling
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_scroll_offset = maxf(0, _scroll_offset - 3)
			_rebuild_grid()
			_update_scrollbar()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var rows_total := ceili(float(_filtered_products.size()) / float(_grid_cols))
			var rows_visible := int(_grid_h / ITEM_H)
			var max_scroll := maxf(0, rows_total - rows_visible)
			_scroll_offset = minf(max_scroll, _scroll_offset + 3)
			_rebuild_grid()
			_update_scrollbar()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if _is_dragging_scroll:
				_is_dragging_scroll = false
	elif event is InputEventMouseMotion:
		if _is_dragging_scroll:
			var delta: float = event.position.y - _last_mouse_y
			_last_mouse_y = event.position.y
			var rows_total: float = ceili(float(_filtered_products.size()) / float(_grid_cols))
			var rows_visible: float = int(_grid_h / ITEM_H)
			var max_scroll: float = maxf(0, rows_total - rows_visible)
			if max_scroll > 0:
				var scroll_delta: float = (delta / _grid_h) * max_scroll
				_scroll_offset = clampf(_scroll_offset + scroll_delta, 0, max_scroll)
				_rebuild_grid()
				_update_scrollbar()

func _build() -> void:
	_def = StoreData.get_section_def(_section_id)
	
	var vp_rect = get_viewport().get_visible_rect()
	var vp_w = vp_rect.size.x
	var vp_h = vp_rect.size.y
	
	_panel_w = vp_w - (PADDING * 2)
	_panel_h = vp_h - (PADDING * 2)
	
	_pan_x = PADDING
	_pan_y = PADDING
	
	var tab_y := _pan_y + HEADER_H + 4
	var grid_y := tab_y + TAB_H + 4
	var grid_bottom := _pan_y + _panel_h - DETAIL_H - 4
	
	_grid_y = grid_y
	_grid_x = _pan_x + PADDING
	_grid_w = _panel_w - SCROLLBAR_W - PADDING * 3
	_grid_h = grid_bottom - grid_y
	
	_grid_cols = maxi(BASE_GRID_COLS, int(_grid_w / 150.0))
	_grid_cols = mini(_grid_cols, 8)
	_item_w = _grid_w / float(_grid_cols)

	# ─── Background overlay ─────────────────────────────────────
	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.04, 0.04, 0.07, 0.93)
	add_child(ov)
	
	# ─── Main panel ────────────────────────────────────────────
	var panel := ColorRect.new()
	panel.position = Vector2(_pan_x, _pan_y)
	panel.size = Vector2(_panel_w, _panel_h)
	panel.color = Color(0.09, 0.09, 0.13, 1.0)
	add_child(panel)
	_row_nodes.append(panel)
	
	# Panel border glow
	var border := ColorRect.new()
	border.position = Vector2(_pan_x, _pan_y)
	border.size = Vector2(_panel_w, 3)
	border.color = Color(_def.light_color.r * 0.7, _def.light_color.g * 0.7, _def.light_color.b * 0.7, 1.0)
	add_child(border)
	_row_nodes.append(border)
	
	# ─── Header ────────────────────────────────────────────────
	var hdr := ColorRect.new()
	hdr.position = Vector2(_pan_x, _pan_y)
	hdr.size = Vector2(_panel_w, HEADER_H)
	hdr.color = Color(_def.light_color.r * 0.2, _def.light_color.g * 0.2, _def.light_color.b * 0.2, 1.0)
	add_child(hdr)
	_row_nodes.append(hdr)
	
	var title := Label.new()
	title.text = "[ %s ]  %s" % [_def.label, _def.name]
	title.position = Vector2(_pan_x + 16, _pan_y + 10)
	title.add_theme_color_override("font_color", Color(_def.light_color.r, _def.light_color.g, _def.light_color.b))
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)
	_row_nodes.append(title)
	
	# Close button with hover area
	var close_btn := _make_clickable_btn(Rect2(_pan_x + _panel_w - 120, _pan_y + 8, 100, 32), "Close [ESC]", Color(0.50, 0.50, 0.50), 16)
	close_btn.gui_input.connect(func(e): 
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: 
			close()
	)
	add_child(close_btn)
	_row_nodes.append(close_btn)
	
	# ─── Category tabs ─────────────────────────────────────────
	var btn_x := _pan_x + 12
	for sub in _subcategories:
		var btn := _make_tab_btn(sub, btn_x, tab_y, TAB_H, _def)
		add_child(btn)
		_tab_btns.append(btn)
		btn_x += _tab_width(sub) + 8
	
	# Tab bottom border
	var tab_border := ColorRect.new()
	tab_border.position = Vector2(_pan_x, tab_y + TAB_H)
	tab_border.size = Vector2(_panel_w, 2)
	tab_border.color = Color(0.25, 0.25, 0.30, 1.0)
	add_child(tab_border)
	_row_nodes.append(tab_border)
	
	# ─── Grid area ─────────────────────────────────────────────
	var scroll_bg := ColorRect.new()
	scroll_bg.position = Vector2(_grid_x, _grid_y)
	scroll_bg.size = Vector2(_grid_w, _grid_h)
	scroll_bg.color = Color(0.06, 0.06, 0.09, 1.0)
	scroll_bg.gui_input.connect(_on_grid_bg_input)
	add_child(scroll_bg)
	_row_nodes.append(scroll_bg)
	
	_build_grid()
	
	# ─── Scrollbar ─────────────────────────────────────────────
	var sb_x := _pan_x + _panel_w - SCROLLBAR_W - 8
	var sb_bg := ColorRect.new()
	sb_bg.position = Vector2(sb_x, _grid_y)
	sb_bg.size = Vector2(SCROLLBAR_W, _grid_h)
	sb_bg.color = Color(0.12, 0.12, 0.16, 1.0)
	sb_bg.gui_input.connect(_on_scrollbar_input)
	add_child(sb_bg)
	_row_nodes.append(sb_bg)
	
	_update_scrollbar()
	
	# ─── Detail panel ──────────────────────────────────────────
	var det_y := grid_bottom + 2
	var det := ColorRect.new()
	det.position = Vector2(_pan_x, det_y)
	det.size = Vector2(_panel_w, DETAIL_H)
	det.color = Color(0.05, 0.05, 0.08, 1.0)
	add_child(det)
	_row_nodes.append(det)
	
	var det_border := ColorRect.new()
	det_border.position = Vector2(_pan_x, det_y)
	det_border.size = Vector2(_panel_w, 2)
	det_border.color = Color(0.25, 0.25, 0.30, 1.0)
	add_child(det_border)
	_row_nodes.append(det_border)
	
	# Product sprite
	var det_spr := Sprite2D.new()
	det_spr.name = "DetailSpr"
	det_spr.position = Vector2(_pan_x + 60, det_y + DETAIL_H * 0.5)
	det_spr.scale = Vector2(4.5, 4.5)
	add_child(det_spr)
	_row_nodes.append(det_spr)
	
	# Name label
	var name_lbl := Label.new()
	name_lbl.name = "NameLbl"
	name_lbl.position = Vector2(_pan_x + 120, det_y + 12)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90))
	name_lbl.add_theme_font_size_override("font_size", 22)
	add_child(name_lbl)
	_row_nodes.append(name_lbl)
	
	# Price label
	var price_lbl := Label.new()
	price_lbl.name = "PriceLbl"
	price_lbl.position = Vector2(_pan_x + 120, det_y + 42)
	price_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	price_lbl.add_theme_font_size_override("font_size", 18)
	add_child(price_lbl)
	_row_nodes.append(price_lbl)
	
	# Description label
	var desc_lbl := Label.new()
	desc_lbl.name = "DescLbl"
	desc_lbl.position = Vector2(_pan_x + 380, det_y + 16)
	desc_lbl.size = Vector2(_panel_w - 600, DETAIL_H - 20)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.52))
	desc_lbl.add_theme_font_size_override("font_size", 15)
	add_child(desc_lbl)
	_row_nodes.append(desc_lbl)
	
	# Quantity controls
	var qty_box_x := _pan_x + _panel_w - 280
	
	# Minus button
	var minus_btn := _make_clickable_btn(Rect2(qty_box_x, det_y + 20, 44, 44), "-", Color(0.75, 0.75, 0.75), 28)
	minus_btn.gui_input.connect(_on_minus_input)
	add_child(minus_btn)
	_row_nodes.append(minus_btn)
	
	# Quantity label
	var qty_lbl := Label.new()
	qty_lbl.name = "QtyLbl"
	qty_lbl.position = Vector2(qty_box_x + 52, det_y + 24)
	qty_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90))
	qty_lbl.add_theme_font_size_override("font_size", 22)
	add_child(qty_lbl)
	_row_nodes.append(qty_lbl)
	
	# Plus button
	var plus_btn := _make_clickable_btn(Rect2(qty_box_x + 100, det_y + 20, 44, 44), "+", Color(0.75, 0.75, 0.75), 28)
	plus_btn.gui_input.connect(_on_plus_input)
	add_child(plus_btn)
	_row_nodes.append(plus_btn)
	
	# Total label
	var total_lbl := Label.new()
	total_lbl.name = "TotalLbl"
	total_lbl.position = Vector2(qty_box_x + 156, det_y + 24)
	total_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.75))
	total_lbl.add_theme_font_size_override("font_size", 20)
	add_child(total_lbl)
	_row_nodes.append(total_lbl)
	
	# ADD button
	var add_btn_bg := ColorRect.new()
	add_btn_bg.position = Vector2(_pan_x + _panel_w - 110, det_y + 18)
	add_btn_bg.size = Vector2(95, 48)
	add_btn_bg.color = Color(_def.light_color.r * 0.4, _def.light_color.g * 0.4, _def.light_color.b * 0.4, 1.0)
	add_child(add_btn_bg)
	_row_nodes.append(add_btn_bg)
	
	var add_btn := _make_clickable_btn(Rect2(_pan_x + _panel_w - 110, det_y + 18, 95, 48), "ADD", Color(_def.light_color.r, _def.light_color.g, _def.light_color.b), 20)
	add_btn.gui_input.connect(_on_add_input)
	add_child(add_btn)
	_row_nodes.append(add_btn)
	
	_update_detail()
	_refresh_tabs()

func _make_clickable_btn(rect: Rect2, text: String, color: Color, font_size: int) -> Control:
	var c := Control.new()
	c.position = Vector2(rect.position.x, rect.position.y)
	c.size = Vector2(rect.size.x, rect.size.y)
	
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, (rect.size.y - font_size) * 0.5 - 2)
	lbl.size = Vector2(rect.size.x, font_size + 4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	c.add_child(lbl)
	
	return c

func _on_grid_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = event.position + Vector2(_grid_x, _grid_y - _scroll_offset * ITEM_H)
		# Check which item was clicked
		for bounds in _item_bounds:
			var r: Rect2 = bounds.rect
			var idx: int = bounds.index
			if r.has_point(click_pos):
				_selected = idx
				_clamp_scroll()
				_rebuild_grid()
				_update_detail()
				return

func _on_scrollbar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging_scroll = true
				_last_mouse_y = event.position.y
			else:
				_is_dragging_scroll = false

func _on_minus_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_qty = maxi(1, _qty - 1)
		_update_detail()

func _on_plus_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_qty = mini(99, _qty + 1)
		_update_detail()

func _on_add_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_add_selected_to_cart()

func _make_tab_btn(sub: String, bx: float, by: float, bh: float, def) -> Control:
	var w := _tab_width(sub)
	var c := Control.new()
	c.position = Vector2(bx, by)
	c.size = Vector2(w, bh)
	c.gui_input.connect(_make_tab_input(sub, c, def))
	
	var bg := ColorRect.new()
	bg.name = "bg"
	bg.size = Vector2(w, bh)
	bg.color = Color(def.light_color.r * 0.35, def.light_color.g * 0.35, def.light_color.b * 0.35, 0.85) if sub == _active_sub else Color(0.12, 0.12, 0.16, 1.0)
	c.add_child(bg)
	
	var lbl := Label.new()
	lbl.name = "lbl"
	lbl.text = sub
	lbl.position = Vector2(10, 8)
	lbl.add_theme_color_override("font_color", Color(def.light_color.r, def.light_color.g, def.light_color.b) if sub == _active_sub else Color(0.50, 0.50, 0.50))
	lbl.add_theme_font_size_override("font_size", 15)
	c.add_child(lbl)
	
	return c

func _make_tab_input(sub: String, btn: Control, def):
	return func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_change_subcategory(sub)

func _tab_width(sub: String) -> float:
	return 28.0 + sub.length() * 13.0 + 20.0

func _change_subcategory(sub: String) -> void:
	_active_sub = sub
	if sub == "ALL":
		_filtered_products = _all_products
	else:
		_filtered_products = StoreData.filter_by_subcategory(_section_id, sub)
	_selected = 0
	_scroll_offset = 0.0
	_qty = 1
	
	_refresh_tabs()
	_build_grid()
	_update_scrollbar()
	_update_detail()

func _refresh_tabs() -> void:
	for i in range(_tab_btns.size()):
		var btn = _tab_btns[i]
		var sub = _subcategories[i]
		var bg = btn.get_node("bg") as ColorRect
		var lbl = btn.get_node("lbl") as Label
		if sub == _active_sub:
			bg.color = Color(_def.light_color.r * 0.35, _def.light_color.g * 0.35, _def.light_color.b * 0.35, 0.85)
			lbl.add_theme_color_override("font_color", Color(_def.light_color.r, _def.light_color.g, _def.light_color.b))
		else:
			bg.color = Color(0.12, 0.12, 0.16, 1.0)
			lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))

func _build_grid() -> void:
	for n in _item_nodes:
		n.queue_free()
	_item_nodes.clear()
	_item_bounds.clear()
	
	var row := 0
	var col := 0
	
	for i in range(_filtered_products.size()):
		var ix := _grid_x + col * _item_w + ITEM_MARGIN
		var iy := _grid_y + row * ITEM_H - _scroll_offset * ITEM_H
		
		var item_rect := Rect2(ix, iy, _item_w - ITEM_MARGIN * 2, ITEM_H - ITEM_MARGIN)
		
		# Track bounds for click detection
		_item_bounds.append({"rect": item_rect, "index": i})
		
		# Skip items outside visible area
		if iy + ITEM_H < _grid_y or iy >= _grid_y + _grid_h:
			col += 1
			if col >= _grid_cols:
				col = 0
				row += 1
			continue
		
		var is_sel := (i == _selected)
		
		# Item background
		var bg := ColorRect.new()
		bg.size = Vector2(_item_w - ITEM_MARGIN * 2, ITEM_H - ITEM_MARGIN)
		bg.position = Vector2(ix, iy)
		bg.color = Color(_def.light_color.r * 0.4, _def.light_color.g * 0.4, _def.light_color.b * 0.4, 0.9) if is_sel else Color(0.11, 0.11, 0.15, 1.0)
		bg.gui_input.connect(_make_item_input(i))
		add_child(bg)
		_item_nodes.append(bg)
		
		var prod = _filtered_products[i]
		
		# Product sprite
		var spr := Sprite2D.new()
		spr.position = Vector2(ix + 32, iy + ITEM_H * 0.5)
		spr.texture = _make_prod_tex(prod)
		spr.scale = Vector2(4.0, 4.0)
		add_child(spr)
		_item_nodes.append(spr)
		
		# Number badge
		var num_lbl := Label.new()
		num_lbl.text = "%d" % ((i % 9) + 1)
		num_lbl.position = Vector2(ix + 6, iy + 6)
		num_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		num_lbl.add_theme_font_size_override("font_size", 13)
		add_child(num_lbl)
		_item_nodes.append(num_lbl)
		
		# Product name
		var name_lbl := Label.new()
		name_lbl.text = prod.name
		name_lbl.position = Vector2(ix + 68, iy + 10)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.size = Vector2(_item_w - 80, 22)
		name_lbl.clip_text = true
		add_child(name_lbl)
		_item_nodes.append(name_lbl)
		
		# Price
		var price_lbl := Label.new()
		price_lbl.text = "$%.2f" % _get_adjusted_price(prod.price)
		var pmult := _get_dynamic_price_mult()
		if pmult <= 0.85:
			price_lbl.add_theme_color_override("font_color", Color(0.35, 0.92, 0.50))
		elif pmult >= 1.15:
			price_lbl.add_theme_color_override("font_color", Color(0.92, 0.58, 0.35))
		else:
			price_lbl.add_theme_color_override("font_color", Color(0.88, 0.75, 0.42))
		price_lbl.position = Vector2(ix + 68, iy + 34)
		price_lbl.add_theme_font_size_override("font_size", 15)
		add_child(price_lbl)
		_item_nodes.append(price_lbl)
		
		# Dynamic price badge
		var dlabel := _get_dynamic_price_label()
		if dlabel != "":
			var badge := Label.new()
			badge.text = dlabel
			badge.position = Vector2(ix + _item_w - 90, iy + 32)
			badge.add_theme_font_size_override("font_size", 12)
			if pmult <= 0.85:
				badge.add_theme_color_override("font_color", Color(0.35, 0.92, 0.50))
			elif pmult >= 1.15:
				badge.add_theme_color_override("font_color", Color(0.92, 0.42, 0.35))
			else:
				badge.add_theme_color_override("font_color", Color(0.92, 0.78, 0.35))
			add_child(badge)
			_item_nodes.append(badge)
		
		# Stock bar
		var stock_ratio := _get_section_stock_ratio(_section_id)
		var bar_w := _item_w - 88.0
		var bar_h := 5.0
		var bar_x := ix + 68.0
		var bar_y := iy + ITEM_H - 14.0
		
		var bar_bg := ColorRect.new()
		bar_bg.size = Vector2(bar_w, bar_h)
		bar_bg.position = Vector2(bar_x, bar_y)
		bar_bg.color = Color(0.20, 0.20, 0.22)
		add_child(bar_bg)
		_item_nodes.append(bar_bg)
		
		var fill_w := bar_w * stock_ratio
		var stock_color := Color(0.35, 0.82, 0.45)
		if stock_ratio < 0.3:
			stock_color = Color(0.92, 0.35, 0.35)
		elif stock_ratio < 0.6:
			stock_color = Color(0.92, 0.72, 0.35)
		
		var bar_fill := ColorRect.new()
		bar_fill.size = Vector2(fill_w, bar_h)
		bar_fill.position = Vector2(bar_x, bar_y)
		bar_fill.color = stock_color
		add_child(bar_fill)
		_item_nodes.append(bar_fill)
		
		if stock_ratio <= 0.0:
			var oos_lbl := Label.new()
			oos_lbl.text = "OUT!"
			oos_lbl.position = Vector2(bar_x + bar_w * 0.5 - 18, bar_y - 12)
			oos_lbl.add_theme_color_override("font_color", Color(0.92, 0.35, 0.35))
			oos_lbl.add_theme_font_size_override("font_size", 11)
			add_child(oos_lbl)
			_item_nodes.append(oos_lbl)
		
		# Subcategory label
		var sub_lbl := Label.new()
		sub_lbl.text = prod.sub
		sub_lbl.position = Vector2(ix + _item_w - 78, iy + 6)
		sub_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.42))
		sub_lbl.add_theme_font_size_override("font_size", 12)
		add_child(sub_lbl)
		_item_nodes.append(sub_lbl)
		
		col += 1
		if col >= _grid_cols:
			col = 0
			row += 1

func _make_item_input(index: int):
	return func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_selected = index
			_clamp_scroll()
			_rebuild_grid()
			_update_detail()

func _update_scrollbar() -> void:
	if _scroll_knob == null:
		return
	var rows_total := ceili(float(_filtered_products.size()) / float(_grid_cols))
	var rows_visible := int(_grid_h / ITEM_H)
	var max_scroll := maxf(0, rows_total - rows_visible)
	var vis_ratio := rows_visible / float(maxf(rows_total, 1))
	var knob_h := maxf(24.0, _grid_h * vis_ratio)
	var knob_y := _grid_y + (_scroll_offset / float(maxf(1, max_scroll))) * (_grid_h - knob_h) if max_scroll > 0 else _grid_y
	var sb_x := _pan_x + _panel_w - SCROLLBAR_W - 8
	_scroll_knob.position = Vector2(sb_x + 2, knob_y)
	_scroll_knob.size = Vector2(SCROLLBAR_W - 4, knob_h)

func _update_detail() -> void:
	var name_lbl := get_node_or_null("NameLbl") as Label
	var price_lbl := get_node_or_null("PriceLbl") as Label
	var desc_lbl := get_node_or_null("DescLbl") as Label
	var qty_lbl := get_node_or_null("QtyLbl") as Label
	var total_lbl := get_node_or_null("TotalLbl") as Label
	var det_spr := get_node_or_null("DetailSpr") as Sprite2D
	
	if name_lbl == null or price_lbl == null or desc_lbl == null or qty_lbl == null or total_lbl == null:
		return
	
	if _filtered_products.size() == 0:
		name_lbl.text = "(no items)"
		price_lbl.text = ""
		desc_lbl.text = ""
		qty_lbl.text = "x%d" % _qty
		total_lbl.text = ""
		return
	
	var prod = _filtered_products[_selected]
	name_lbl.text = prod.name
	
	var adj_price := _get_adjusted_price(prod.price)
	var dyn_label := _get_dynamic_price_label()
	var price_str := "$%.2f" % adj_price
	if dyn_label != "":
		price_str += " [%s]" % dyn_label
	price_lbl.text = price_str
	
	if adj_price < prod.price * 0.95:
		price_lbl.add_theme_color_override("font_color", Color(0.45, 0.92, 0.55))
	elif adj_price > prod.price * 1.05:
		price_lbl.add_theme_color_override("font_color", Color(0.92, 0.55, 0.45))
	else:
		price_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	
	desc_lbl.text = prod.desc
	qty_lbl.text = "x%d" % _qty
	var total := adj_price * _qty
	total_lbl.text = "$%.2f" % total
	
	if det_spr != null:
		det_spr.texture = _make_prod_tex(prod)

func _on_key_action(action: String) -> void:
	match action:
		"ui_up":
			_selected = maxi(0, _selected - _grid_cols)
			_clamp_scroll()
			_rebuild_grid()
			_update_detail()
		"ui_down":
			_selected = mini(_filtered_products.size() - 1, _selected + _grid_cols)
			_clamp_scroll()
			_rebuild_grid()
			_update_detail()
		"ui_left":
			_selected = maxi(0, _selected - 1)
			_clamp_scroll()
			_rebuild_grid()
			_update_detail()
		"ui_right":
			_selected = mini(_filtered_products.size() - 1, _selected + 1)
			_clamp_scroll()
			_rebuild_grid()
			_update_detail()
		"ui_accept":
			_add_selected_to_cart()
		"escape":
			close()
		"page_up":
			_scroll_offset = maxf(0, _scroll_offset - 5)
			_rebuild_grid()
			_update_scrollbar()
		"page_down":
			var rows_total := ceili(float(_filtered_products.size()) / float(_grid_cols))
			var rows_visible := int(_grid_h / ITEM_H)
			var max_scroll := maxf(0, rows_total - rows_visible)
			_scroll_offset = minf(max_scroll, _scroll_offset + 5)
			_rebuild_grid()
			_update_scrollbar()
		"num_increase":
			_qty = mini(99, _qty + 1)
			_update_detail()
		"num_decrease":
			_qty = maxi(1, _qty - 1)
			_update_detail()
		_:
			if action.begins_with("num_"):
				var idx := action.replace("num_", "").to_int() - 1
				if idx >= 0 and idx < _filtered_products.size():
					_selected = idx
					_clamp_scroll()
					_rebuild_grid()
					_update_detail()
					_add_selected_to_cart()

func _clamp_scroll() -> void:
	var rows_total := ceili(float(_filtered_products.size()) / float(_grid_cols))
	var max_scroll := maxf(0, rows_total - 1)
	_scroll_offset = clampf(_scroll_offset, 0, max_scroll)
	var sel_row := _selected / _grid_cols
	if sel_row < int(_scroll_offset):
		_scroll_offset = float(sel_row)
	elif sel_row > int(_scroll_offset) + 4:
		_scroll_offset = float(sel_row - 4)

func _add_selected_to_cart() -> void:
	if _filtered_products.size() == 0:
		return
	var prod = _filtered_products[_selected]
	var ratio := _get_section_stock_ratio(_section_id)
	if ratio <= 0.0:
		return
	item_added.emit(prod, _qty)
	if _cart_ref != null and _cart_ref.has_method("add_item"):
		_cart_ref.add_item(prod, _qty)

func _rebuild_grid() -> void:
	for n in _item_nodes:
		n.queue_free()
	_item_nodes.clear()
	_item_bounds.clear()
	_build_grid()

func _get_dynamic_price_mult() -> float:
	var main = get_parent()
	if main == null or not main.has_method("get_warehouse"):
		main = get_tree().root.get_node_or_null("Main")
	if main == null:
		return 1.0
	var dp = main.get_node_or_null("DynamicPricing")
	if dp != null and dp.has_method("get_price_multiplier_for_section"):
		return dp.get_price_multiplier_for_section(_section_id, main.get_warehouse())
	return 1.0

func _get_adjusted_price(base_price: float) -> float:
	return base_price * _get_dynamic_price_mult()

func _get_dynamic_price_label() -> String:
	var mult := _get_dynamic_price_mult()
	if mult <= 0.85:
		return "SALE!"
	elif mult >= 1.15:
		return "HIGH DEMAND"
	elif mult >= 1.05:
		return "LIMITED"
	return ""

func _get_section_stock_ratio(section_id: String) -> float:
	var main = get_parent()
	if main == null or not main.has_method("get_warehouse"):
		main = get_tree().root.get_node_or_null("Main")
	if main == null:
		return 1.0
	var wh = main.get_warehouse()
	if wh != null and wh.has_method("get_stock_ratio"):
		return wh.get_stock_ratio(section_id)
	return 1.0

func _make_prod_tex(prod) -> Texture2D:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_product(img, prod)
	return ImageTexture.create_from_image(img)

func _draw_product(img: Image, prod) -> void:
	var c: Color = prod.color
	match prod.shape:
		0: _fill(5,4,2,4,c,img); _fill(4,5,4,2,c,img); _fill(5,5,2,2,c.lightened(0.15),img)
		1: _fill(3,4,6,5,c,img); _fill(3,4,6,1,c.lightened(0.15),img)
		2: _fill(4,2,4,8,c,img); _fill(5,1,2,1,c.lightened(0.2),img); _fill(4,9,4,1,c.darkened(0.15),img)
		3: _fill(2,3,8,7,c,img); _fill(2,3,8,1,c.lightened(0.2),img); _fill(2,9,8,1,c.darkened(0.2),img)
		4: _fill(3,5,6,5,c,img); _fill(4,4,4,1,c.lightened(0.15),img); _fill(3,9,6,1,c.darkened(0.2),img)
		5: _fill(4,1,4,10,c,img); _fill(5,0,2,1,c.lightened(0.2),img); _fill(4,10,4,1,c.darkened(0.15),img)
		6: _fill(2,4,8,5,c,img); _fill(2,4,8,1,c.lightened(0.15),img)
		7: _fill(3,5,6,2,c,img); _fill(4,4,4,1,c.lightened(0.15),img)

func _fill(x: int, y: int, w: int, h: int, col: Color, img: Image) -> void:
	x=clampi(x,0,12); y=clampi(y,0,12); w=clampi(w,0,12-x); h=clampi(h,0,12-y)
	if w<=0 or h<=0: return
	for px in range(x,x+w):
		for py in range(y,y+h):
			img.set_pixel(px,py,col)

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
