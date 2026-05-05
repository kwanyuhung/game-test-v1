# section_browse.gd
# Full-screen interactive product browser for a supermarket section.
# Shows category tabs, scrollable product grid, and item detail panel.
# Press ESC to close. Number keys add directly to cart.

class_name SectionBrowse
extends CanvasLayer

const StoreData = preload("res://scripts/store_data.gd")

signal item_added(product, qty: int)
signal closed()

const CELL_SIZE := 16

const GRID_COLS := 4
const ITEM_H := 38.0
const PANEL_W := 288.0
const PANEL_H := 170.0
const DETAIL_H := 38.0

var _section_id := ""
var _all_products: Array = []
var _filtered_products: Array = []
var _subcategories: Array = []
var _active_sub: String = "ALL"
var _selected := 0
var _scroll_offset := 0
var _cart_ref = null
var _qty := 1
var _row_nodes: Array = []

var _sel_bg: ColorRect
var _name_lbl: Label
var _price_lbl: Label
var _desc_lbl: Label
var _qty_lbl: Label
var _total_lbl: Label
var _tab_btns: Array = []
var _item_nodes: Array = []
var _scroll_bg: ColorRect
var _scroll_knob: ColorRect

func _ready() -> void:
	visible = false
	# Listen for price override changes so prices update live
	var main = get_tree().get_first_node_in_group("main")
	if main != null:
		var po = main.get_node_or_null("PriceOverride")
		if po != null and po.has_signal("price_changed"):
			po.price_changed.connect(_on_price_changed)

func _on_price_changed(product_id: String, new_price: float) -> void:
	# Rebuild to show updated price
	if visible and _section_id != "":
		_build()

# Opens the browser for a given SupermarketSection node.
# Merges section products + brand products for the same section id.
func open_section(section) -> void:
	var def = section.get_def()
	var section_id = def.id
	var products = section.get_all_products()

	# Merge in brand products for this section
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
	_scroll_offset = 0
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
	_tab_btns.clear()
	_row_nodes.clear()

func close() -> void:
	visible = false
	_close_children()
	closed.emit()

func _build() -> void:
	var def = StoreData.get_section_def(_section_id)
	var pan_x := (320.0 - PANEL_W) * 0.5
	var pan_y := (180.0 - PANEL_H) * 0.5
	
	# ─── Background overlay ─────────────────────────────────────
	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.04, 0.04, 0.07, 0.88)
	add_child(ov)
	
	# ─── Main panel ────────────────────────────────────────────
	var panel := ColorRect.new()
	panel.position = Vector2(pan_x, pan_y)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.09, 0.09, 0.13, 1.0)
	add_child(panel)
	_row_nodes.append(panel)
	
	# Panel border
	var border := ColorRect.new()
	border.position = Vector2(pan_x, pan_y)
	border.size = Vector2(PANEL_W, 1)
	border.color = Color(def.light_color.r * 0.6, def.light_color.g * 0.6, def.light_color.b * 0.6, 1.0)
	add_child(border)
	_row_nodes.append(border)
	
	# ─── Header ────────────────────────────────────────────────
	var hdr_h := 16.0
	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(PANEL_W, hdr_h)
	hdr.color = Color(def.light_color.r * 0.25, def.light_color.g * 0.25, def.light_color.b * 0.25, 1.0)
	add_child(hdr)
	_row_nodes.append(hdr)
	
	var title := Label.new()
	title.text = "[ %s ]  %s" % [def.label, def.name]
	title.position = Vector2(pan_x + 4, pan_y + 2)
	title.add_theme_color_override("font_color", Color(def.light_color.r, def.light_color.g, def.light_color.b))
	title.add_theme_font_size_override("font_size", 8)
	add_child(title)
	_row_nodes.append(title)
	
	var close_lbl := Label.new()
	close_lbl.text = "[ESC] Close"
	close_lbl.position = Vector2(pan_x + PANEL_W - 52, pan_y + 3)
	close_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	close_lbl.add_theme_font_size_override("font_size", 7)
	add_child(close_lbl)
	_row_nodes.append(close_lbl)
	
	# ─── Category tabs ─────────────────────────────────────────
	var tab_y := pan_y + hdr_h + 1
	var tab_h := 12.0
	var btn_x := pan_x + 2
	for sub in _subcategories:
		var btn := _make_tab_btn(sub, btn_x, tab_y, tab_h, def)
		add_child(btn)
		_tab_btns.append(btn)
		btn_x += _tab_width(sub) + 2
	
	# Tab bottom border
	var tab_border := ColorRect.new()
	tab_border.position = Vector2(pan_x, tab_y + tab_h)
	tab_border.size = Vector2(PANEL_W, 1)
	tab_border.color = Color(0.18, 0.18, 0.22, 1.0)
	add_child(tab_border)
	_row_nodes.append(tab_border)
	
	# ─── Grid area ─────────────────────────────────────────────
	var grid_y := tab_y + tab_h + 1
	var grid_h := PANEL_H - hdr_h - tab_h - DETAIL_H - 2
	var grid_bottom := grid_y + grid_h
	
	# Scroll container background
	var scroll_bg := ColorRect.new()
	scroll_bg.position = Vector2(pan_x, grid_y)
	scroll_bg.size = Vector2(PANEL_W, grid_h)
	scroll_bg.color = Color(0.07, 0.07, 0.10, 1.0)
	add_child(scroll_bg)
	_row_nodes.append(scroll_bg)
	_scroll_bg = scroll_bg
	
	_build_grid(pan_x, grid_y, PANEL_W, grid_h, def)
	
	# ─── Scrollbar ─────────────────────────────────────────────
	var sb_x := pan_x + PANEL_W - 6
	var sb_bg := ColorRect.new()
	sb_bg.position = Vector2(sb_x, grid_y)
	sb_bg.size = Vector2(5, grid_h)
	sb_bg.color = Color(0.12, 0.12, 0.16, 1.0)
	add_child(sb_bg)
	_row_nodes.append(sb_bg)
	
	var rows_total: float = ceili(float(_filtered_products.size()) / float(GRID_COLS))
	var rows_visible: float = int(grid_h / ITEM_H)
	var max_scroll: float = maxf(0, rows_total - rows_visible)
	var vis_ratio: float = rows_visible / float(max(rows_total, 1))
	var knob_h: float = maxf(12.0, grid_h * vis_ratio)
	var knob_y: float = grid_y + (_scroll_offset / float(maxf(1, max_scroll))) * (grid_h - knob_h) if max_scroll > 0 else grid_y
	
	_scroll_knob = ColorRect.new()
	_scroll_knob.position = Vector2(sb_x + 1, knob_y)
	_scroll_knob.size = Vector2(3, knob_h)
	_scroll_knob.color = Color(def.light_color.r * 0.7, def.light_color.g * 0.7, def.light_color.b * 0.7, 0.8)
	add_child(_scroll_knob)
	_row_nodes.append(_scroll_knob)
	
	# ─── Detail panel ──────────────────────────────────────────
	var det_y := grid_bottom + 1
	var det := ColorRect.new()
	det.position = Vector2(pan_x, det_y)
	det.size = Vector2(PANEL_W, DETAIL_H)
	det.color = Color(0.06, 0.06, 0.09, 1.0)
	add_child(det)
	_row_nodes.append(det)
	
	var det_border := ColorRect.new()
	det_border.position = Vector2(pan_x, det_y)
	det_border.size = Vector2(PANEL_W, 1)
	det_border.color = Color(0.18, 0.18, 0.22, 1.0)
	add_child(det_border)
	_row_nodes.append(det_border)
	
	# Product sprite in detail
	var det_spr := Sprite2D.new()
	det_spr.position = Vector2(pan_x + 18, det_y + DETAIL_H * 0.5)
	det_spr.scale = Vector2(2.5, 2.5)
	add_child(det_spr)
	_row_nodes.append(det_spr)
	if _filtered_products.size() > 0:
		det_spr.texture = _make_prod_tex(_filtered_products[_selected])
	
	_name_lbl = Label.new()
	_name_lbl.position = Vector2(pan_x + 34, det_y + 2)
	_name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	_name_lbl.add_theme_font_size_override("font_size", 9)
	add_child(_name_lbl)
	_row_nodes.append(_name_lbl)
	
	_price_lbl = Label.new()
	_price_lbl.position = Vector2(pan_x + 34, det_y + 13)
	_price_lbl.add_theme_color_override("font_color", Color(0.90, 0.78, 0.42))
	_price_lbl.add_theme_font_size_override("font_size", 8)
	add_child(_price_lbl)
	_row_nodes.append(_price_lbl)
	
	_desc_lbl = Label.new()
	_desc_lbl.position = Vector2(pan_x + 110, det_y + 4)
	_desc_lbl.size = Vector2(100, DETAIL_H - 4)
	_desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.52))
	_desc_lbl.add_theme_font_size_override("font_size", 7)
	add_child(_desc_lbl)
	_row_nodes.append(_desc_lbl)
	
	# Quantity selector
	var qty_box_x := pan_x + PANEL_W - 74
	var minus_btn := Label.new()
	minus_btn.text = "-"
	minus_btn.position = Vector2(qty_box_x, det_y + 8)
	minus_btn.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	minus_btn.add_theme_font_size_override("font_size", 10)
	add_child(minus_btn)
	_row_nodes.append(minus_btn)
	var minus_bg := ColorRect.new()
	minus_bg.position = Vector2(qty_box_x - 2, det_y + 8)
	minus_bg.size = Vector2(10, 12)
	minus_bg.color = Color(0.18, 0.18, 0.22, 1.0)
	add_child(minus_bg)
	_row_nodes.append(minus_bg)
	
	_qty_lbl = Label.new()
	_qty_lbl.position = Vector2(qty_box_x + 12, det_y + 9)
	_qty_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.88))
	_qty_lbl.add_theme_font_size_override("font_size", 9)
	add_child(_qty_lbl)
	_row_nodes.append(_qty_lbl)
	
	var plus_btn := Label.new()
	plus_btn.text = "+"
	plus_btn.position = Vector2(qty_box_x + 28, det_y + 8)
	plus_btn.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	plus_btn.add_theme_font_size_override("font_size", 10)
	add_child(plus_btn)
	_row_nodes.append(plus_btn)
	var plus_bg := ColorRect.new()
	plus_bg.position = Vector2(qty_box_x + 26, det_y + 8)
	plus_bg.size = Vector2(10, 12)
	plus_bg.color = Color(0.18, 0.18, 0.22, 1.0)
	add_child(plus_bg)
	_row_nodes.append(plus_bg)
	
	_total_lbl = Label.new()
	_total_lbl.position = Vector2(qty_box_x + 42, det_y + 9)
	_total_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.72))
	_total_lbl.add_theme_font_size_override("font_size", 8)
	add_child(_total_lbl)
	_row_nodes.append(_total_lbl)
	
	# Add button
	var add_btn_bg := ColorRect.new()
	add_btn_bg.position = Vector2(pan_x + PANEL_W - 32, det_y + 6)
	add_btn_bg.size = Vector2(30, 14)
	add_btn_bg.color = Color(def.light_color.r * 0.45, def.light_color.g * 0.45, def.light_color.b * 0.45, 1.0)
	add_child(add_btn_bg)
	_row_nodes.append(add_btn_bg)
	
	var add_btn := Label.new()
	add_btn.text = "ADD"
	add_btn.position = Vector2(pan_x + PANEL_W - 28, det_y + 9)
	add_btn.add_theme_color_override("font_color", Color(def.light_color.r, def.light_color.g, def.light_color.b))
	add_btn.add_theme_font_size_override("font_size", 7)
	add_child(add_btn)
	_row_nodes.append(add_btn)
	
	_update_detail(pan_x, def)
	_refresh_tabs(def)
	
	# Keyboard handler
	var kb := InputEventHandler.new()
	kb.action_pressed.connect(_on_key_action)
	add_child(kb)


func _make_tab_btn(sub: String, bx: float, by: float, bh: float, def) -> Control:
	var w := _tab_width(sub)
	var c := Control.new()
	c.position = Vector2(bx, by)
	c.size = Vector2(w, bh)
	
	var bg := ColorRect.new()
	bg.name = "bg"
	bg.size = Vector2(w, bh)
	bg.color = Color(def.light_color.r * 0.3, def.light_color.g * 0.3, def.light_color.b * 0.3, 0.8) if sub == _active_sub else Color(0.10, 0.10, 0.14, 1.0)
	c.add_child(bg)
	
	var lbl := Label.new()
	lbl.name = "lbl"
	lbl.text = sub
	lbl.position = Vector2(3, 2)
	lbl.add_theme_color_override("font_color", Color(def.light_color.r, def.light_color.g, def.light_color.b) if sub == _active_sub else Color(0.48, 0.48, 0.48))
	lbl.add_theme_font_size_override("font_size", 7)
	c.add_child(lbl)
	
	c.gui_input.connect(_make_tab_input(sub))
	return c

func _make_tab_input(sub: String):
	return func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_change_subcategory(sub)

func _tab_width(sub: String) -> float:
	return 10.0 + sub.length() * 5.0 + 8.0

func _change_subcategory(sub: String) -> void:
	_active_sub = sub
	if sub == "ALL":
		_filtered_products = _all_products
	else:
		_filtered_products = StoreData.filter_by_subcategory(_section_id, sub)
	_selected = 0
	_scroll_offset = 0
	_qty = 1
	
	var pan_x := (320.0 - PANEL_W) * 0.5
	var pan_y := (180.0 - PANEL_H) * 0.5
	var def = StoreData.get_section_def(_section_id)
	var tab_y := pan_y + 16.0 + 1.0
	var tab_h := 12.0
	var grid_y := tab_y + tab_h + 1
	var grid_h := PANEL_H - 16.0 - tab_h - DETAIL_H - 2
	
	_refresh_tabs(def)
	_build_grid(pan_x, grid_y, PANEL_W, grid_h, def)
	_update_scrollbar(pan_x, grid_y, grid_h, def)
	_update_detail(pan_x, def)

func _refresh_tabs(def) -> void:
	for i in range(_tab_btns.size()):
		var btn = _tab_btns[i]
		var sub = _subcategories[i]
		var bg = btn.get_node("bg") as ColorRect
		var lbl = btn.get_node("lbl") as Label
		if sub == _active_sub:
			bg.color = Color(def.light_color.r * 0.3, def.light_color.g * 0.3, def.light_color.b * 0.3, 0.8)
			lbl.add_theme_color_override("font_color", Color(def.light_color.r, def.light_color.g, def.light_color.b))
		else:
			bg.color = Color(0.10, 0.10, 0.14, 1.0)
			lbl.add_theme_color_override("font_color", Color(0.48, 0.48, 0.48))

func _build_grid(pan_x: float, grid_y: float, grid_w: float, grid_h: float, def) -> void:
	# Clear old item nodes
	for n in _item_nodes:
		n.queue_free()
	_item_nodes.clear()
	
	var start_y := grid_y
	var row := 0
	var col := 0
	var item_w := grid_w / float(GRID_COLS)
	
	for i in range(_filtered_products.size()):
		var ix := pan_x + col * item_w + 2.0
		var iy := start_y + row * ITEM_H - _scroll_offset * ITEM_H
		
		if iy + ITEM_H < start_y or iy >= start_y + grid_h:
			# Placeholder so we track which items exist
			var placeholder = Control.new()
			placeholder.size = Vector2(item_w - 4, ITEM_H)
			add_child(placeholder)
			_item_nodes.append(placeholder)
			col += 1
			if col >= GRID_COLS:
				col = 0; row += 1
			continue
		
		var is_sel := (i == _selected)
		
		var bg := ColorRect.new()
		bg.size = Vector2(item_w - 4, ITEM_H - 2)
		bg.position = Vector2(ix, iy)
		bg.color = Color(def.light_color.r * 0.3, def.light_color.g * 0.3, def.light_color.b * 0.3, 0.7) if is_sel else Color(0.10, 0.10, 0.14, 1.0)
		add_child(bg)
		_item_nodes.append(bg)
		
		var prod = _filtered_products[i]
		
		var spr := Sprite2D.new()
		spr.position = Vector2(ix + 14, iy + ITEM_H * 0.5 - 1)
		spr.texture = _make_prod_tex(prod)
		spr.scale = Vector2(2.0, 2.0)
		add_child(spr)
		_item_nodes.append(spr)
		
		var num_lbl := Label.new()
		num_lbl.text = "%d" % ((i % 9) + 1)
		num_lbl.position = Vector2(ix + 2, iy + 1)
		num_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
		num_lbl.add_theme_font_size_override("font_size", 6)
		add_child(num_lbl)
		_item_nodes.append(num_lbl)
		
		var name_lbl := Label.new()
		name_lbl.text = prod.name
		name_lbl.position = Vector2(ix + 26, iy + 3)
		name_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
		name_lbl.add_theme_font_size_override("font_size", 7)
		name_lbl.size = Vector2(item_w - 32, 10)
		name_lbl.clip_text = true
		add_child(name_lbl)
		_item_nodes.append(name_lbl)
		
		var price_lbl := Label.new()
		price_lbl.text = "$%.2f" % _get_adjusted_price(prod.price)
		# Color code: green=sale, orange=high demand, gold=normal
		var pmult := _get_dynamic_price_mult()
		if pmult <= 0.85:
			price_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.45))
		elif pmult >= 1.15:
			price_lbl.add_theme_color_override("font_color", Color(0.90, 0.55, 0.30))
		else:
			price_lbl.add_theme_color_override("font_color", Color(0.82, 0.70, 0.38))
		price_lbl.position = Vector2(ix + 26, iy + 16)
		price_lbl.add_theme_font_size_override("font_size", 7)
		add_child(price_lbl)
		_item_nodes.append(price_lbl)
		# Dynamic price badge (SALE!, HIGH DEMAND, LIMITED)
		var dlabel := _get_dynamic_price_label()
		if dlabel != "":
			var badge := Label.new()
			badge.text = dlabel
			badge.position = Vector2(ix + item_w - 38, iy + 15)
			badge.add_theme_font_size_override("font_size", 5)
			if pmult <= 0.85:
				badge.add_theme_color_override("font_color", Color(0.30, 0.90, 0.45))
			elif pmult >= 1.15:
				badge.add_theme_color_override("font_color", Color(0.90, 0.40, 0.30))
			else:
				badge.add_theme_color_override("font_color", Color(0.90, 0.75, 0.30))
			add_child(badge)
			_item_nodes.append(badge)

		# ── Phase L: Stock bar ───────────────────────────────────────
		var stock_ratio := _get_section_stock_ratio(_section_id)
		var bar_w := item_w - 32.0
		var bar_h := 3.0
		var bar_x := ix + 26.0
		var bar_y := iy + ITEM_H - 6.0
		# Background (empty part)
		var bar_bg := ColorRect.new()
		bar_bg.size = Vector2(bar_w, bar_h)
		bar_bg.position = Vector2(bar_x, bar_y)
		bar_bg.color = Color(0.20, 0.20, 0.22)
		add_child(bar_bg)
		_item_nodes.append(bar_bg)
		# Fill (stock level)
		var fill_w := bar_w * stock_ratio
		var stock_color := Color(0.30, 0.80, 0.40)  # green = good
		if stock_ratio < 0.3:
			stock_color = Color(0.90, 0.30, 0.30)  # red = critical
		elif stock_ratio < 0.6:
			stock_color = Color(0.90, 0.70, 0.30)  # orange = low
		var bar_fill := ColorRect.new()
		bar_fill.size = Vector2(fill_w, bar_h)
		bar_fill.position = Vector2(bar_x, bar_y)
		bar_fill.color = stock_color
		add_child(bar_fill)
		_item_nodes.append(bar_fill)
		# OUT OF STOCK label
		if stock_ratio <= 0.0:
			var oos_lbl := Label.new()
			oos_lbl.text = "OUT!"
			oos_lbl.position = Vector2(bar_x + bar_w * 0.5 - 8, bar_y - 6)
			oos_lbl.add_theme_color_override("font_color", Color(0.90, 0.30, 0.30))
			oos_lbl.add_theme_font_size_override("font_size", 5)
			add_child(oos_lbl)
			_item_nodes.append(oos_lbl)

		var sub_lbl := Label.new()
		sub_lbl.text = prod.sub
		sub_lbl.position = Vector2(ix + item_w - 32, iy + 2)
		sub_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.38))
		sub_lbl.add_theme_font_size_override("font_size", 6)
		add_child(sub_lbl)
		_item_nodes.append(sub_lbl)
		
		col += 1
		if col >= GRID_COLS:
			col = 0; row += 1

func _update_scrollbar(pan_x: float, grid_y: float, grid_h: float, def) -> void:
	if _scroll_knob == null:
		return
	var rows_total: float = ceili(float(_filtered_products.size()) / float(GRID_COLS))
	var rows_visible: float = int(grid_h / ITEM_H)
	var max_scroll: float = maxf(0, rows_total - rows_visible)
	var vis_ratio: float = rows_visible / float(maxf(rows_total, 1))
	var knob_h: float = maxf(12.0, grid_h * vis_ratio)
	var knob_y: float = grid_y + (_scroll_offset / float(maxf(1, max_scroll))) * (grid_h - knob_h) if max_scroll > 0 else grid_y
	_scroll_knob.position = Vector2(pan_x + PANEL_W - 5, knob_y)
	_scroll_knob.size = Vector2(3, knob_h)

func _update_detail(pan_x: float, def) -> void:
	if _filtered_products.size() == 0:
		_name_lbl.text = "(no items)"
		_price_lbl.text = ""
		_desc_lbl.text = ""
		_qty_lbl.text = "x%d" % _qty
		_total_lbl.text = ""
		return
	
	var prod = _filtered_products[_selected]
	_name_lbl.text = prod.name
	# ── Phase R: Dynamic pricing display ─────────────────────────
	var adj_price := _get_adjusted_price(prod.price)
	var dyn_label := _get_dynamic_price_label()
	var price_str := "$%.2f" % adj_price
	if dyn_label != "":
		price_str += " [%s]" % dyn_label
	_price_lbl.text = price_str
	# Color code: green for sale, red for high demand
	if adj_price < prod.price * 0.95:
		_price_lbl.add_theme_color_override("font_color", Color(0.40, 0.90, 0.50))
	elif adj_price > prod.price * 1.05:
		_price_lbl.add_theme_color_override("font_color", Color(0.90, 0.50, 0.40))
	else:
		_price_lbl.add_theme_color_override("font_color", Color(0.90, 0.78, 0.42))
	_desc_lbl.text = prod.desc
	_qty_lbl.text = "x%d" % _qty
	var total: float = adj_price * _qty
	_total_lbl.text = "$%.2f" % total
	
	# Update detail sprite
	var det_spr := (get_node_or_null("DetailSpr") as Sprite2D)
	if det_spr == null:
		det_spr = Sprite2D.new()
		det_spr.name = "DetailSpr"
		det_spr.position = Vector2(pan_x + 18, 180.0 - PANEL_H * 0.5 - DETAIL_H * 0.5 + 1)
		det_spr.scale = Vector2(2.5, 2.5)
		add_child(det_spr)
	det_spr.texture = _make_prod_tex(prod)

func _on_key_action(action: String) -> void:
	var pan_x: float = (320.0 - PANEL_W) * 0.5
	var pan_y: float = (180.0 - PANEL_H) * 0.5
	var def = StoreData.get_section_def(_section_id)
	var tab_y: float = pan_y + 16.0 + 1.0
	var tab_h: float = 12.0
	var grid_y: float = tab_y + tab_h + 1.0
	var grid_h: float = PANEL_H - 16.0 - tab_h - DETAIL_H - 2.0
	
	match action:
		"ui_up":
			_selected = maxf(0, _selected - GRID_COLS)
			_clamp_scroll()
			_rebuild_grid(pan_x, grid_y, PANEL_W, grid_h, def)
			_update_detail(pan_x, def)
		"ui_down":
			_selected = minf(_filtered_products.size() - 1, _selected + GRID_COLS)
			_clamp_scroll()
			_rebuild_grid(pan_x, grid_y, PANEL_W, grid_h, def)
			_update_detail(pan_x, def)
		"ui_left":
			_selected = maxf(0, _selected - 1)
			_clamp_scroll()
			_rebuild_grid(pan_x, grid_y, PANEL_W, grid_h, def)
			_update_detail(pan_x, def)
		"ui_right":
			_selected = minf(_filtered_products.size() - 1, _selected + 1)
			_clamp_scroll()
			_rebuild_grid(pan_x, grid_y, PANEL_W, grid_h, def)
			_update_detail(pan_x, def)
		"ui_accept":
			_add_selected_to_cart()
		"escape":
			close()
		"page_up":
			_scroll_offset = maxf(0, _scroll_offset - 3)
			_rebuild_grid(pan_x, grid_y, PANEL_W, grid_h, def)
			_update_scrollbar(pan_x, grid_y, grid_h, def)
		"page_down":
			var rows_total: float = ceili(float(_filtered_products.size()) / float(GRID_COLS))
			var rows_visible: float = int(grid_h / ITEM_H)
			var max_scroll: float = maxf(0, rows_total - rows_visible)
			_scroll_offset = minf(max_scroll, _scroll_offset + 3)
			_rebuild_grid(pan_x, grid_y, PANEL_W, grid_h, def)
			_update_scrollbar(pan_x, grid_y, grid_h, def)
		"num_increase":
			_qty = mini(99, _qty + 1)
			_update_detail(pan_x, def)
		"num_decrease":
			_qty = maxi(1, _qty - 1)
			_update_detail(pan_x, def)
		_:
			if action.begins_with("num_"):
				var idx := action.replace("num_", "").to_int() - 1
				if idx >= 0 and idx < _filtered_products.size():
					_selected = idx
					_clamp_scroll()
					_rebuild_grid(pan_x, grid_y, PANEL_W, grid_h, def)
					_update_detail(pan_x, def)
					_add_selected_to_cart()

func _clamp_scroll() -> void:
	var rows_total: float = ceili(float(_filtered_products.size()) / float(GRID_COLS))
	var max_scroll: float = maxf(0, rows_total - 1)
	_scroll_offset = clampi(_scroll_offset, 0, max_scroll)
	# Auto-scroll to keep selection visible
	var sel_row := _selected / GRID_COLS
	if sel_row < _scroll_offset:
		_scroll_offset = sel_row
	elif sel_row > _scroll_offset + 3:
		_scroll_offset = sel_row - 3

func _add_selected_to_cart() -> void:
	if _filtered_products.size() == 0:
		return
	var prod = _filtered_products[_selected]
	# ── Phase L: Block out-of-stock items ──────────────────────────
	var ratio := _get_section_stock_ratio(_section_id)
	if ratio <= 0.0:
		return  # Silent block — stock bar already shows OUT! label
	item_added.emit(prod, _qty)
	if _cart_ref != null and _cart_ref.has_method("add_item"):
		_cart_ref.add_item(prod, _qty)
	_refresh_bottom_bar()

func _rebuild_grid(pan_x: float, grid_y: float, grid_w: float, grid_h: float, def) -> void:
	for n in _item_nodes:
		n.queue_free()
	_item_nodes.clear()
	_build_grid(pan_x, grid_y, grid_w, grid_h, def)

func _refresh_bottom_bar() -> void:
	pass

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
	var mult := _get_dynamic_price_mult()
	return base_price * mult

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
