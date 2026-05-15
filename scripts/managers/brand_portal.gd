# brand_portal.gd
# ═══════════════════════════════════════════════════════════════════════════════
# Brand Partner Portal — a dashboard UI where brand partners can:
# - View their products, events, ads, and stats
# - Add/edit/remove products
# - Create promotional events
# - Place ads on floors
# - See real-time store view with floor time and NPCs
#
# Open with: press [B] in-game (or via Dev Tools)
# ═══════════════════════════════════════════════════════════════════════════════
class_name BrandPortal
extends CanvasLayer

const BrandManager = preload("res://scripts/managers/brand_manager.gd")

const PANEL_W := 310.0
const PANEL_H := 200.0
const TABS := ["Products", "Events", "Ads", "Stats"]

var _brand_id: String = ""
var _active_tab: int = 0
var _items: Array = []
var _selected_item: int = -1
var _scroll_offset: int = 0
var _item_nodes: Array = []
var _edit_mode: bool = false

# Edit form fields
var _edit_name: String = ""
var _edit_price: float = 0.0
var _edit_section: String = "snacks"
var _edit_desc: String = ""
var _edit_event_name: String = ""
var _edit_xp_mult: float = 2.0
var _edit_ad_text: String = ""
var _edit_ad_floor: int = 4

var _bg: ColorRect
var _title_lbl: Label
var _tab_lbls: Array = []
var _content_lbl: Label
var _hint_lbl: Label
var _item_count_lbl: Label

# Brand store view
var _store_view: TextureRect
var _store_time_lbl: Label
var _store_npc_count_lbl: Label

signal closed()

func _ready() -> void:
	visible = false

func open(brand_id: String = "") -> void:
	_brand_id = brand_id
	_active_tab = 0
	_edit_mode = false
	_selected_item = -1
	_scroll_offset = 0
	_build()
	visible = true

func close() -> void:
	visible = false
	_closed_cleanup()
	closed.emit()

func _closed_cleanup() -> void:
	for n in _item_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_item_nodes.clear()

func _build() -> void:
	_close_children()
	_item_nodes.clear()

	_bg = ColorRect.new()
	_bg.size = Vector2(PANEL_W, PANEL_H)
	_bg.color = Color(0.08, 0.08, 0.12, 0.97)
	_bg.z_index = 800
	add_child(_bg)

	# Title bar
	_title_lbl = Label.new()
	_title_lbl.text = _get_title()
	_title_lbl.position = Vector2(8.0, 6.0)
	_title_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.50))
	_title_lbl.add_theme_font_size_override("font_size", 10)
	_bg.add_child(_title_lbl)
	_item_nodes.append(_title_lbl)

	# Tab buttons
	var tab_y := 20.0
	for i in range(TABS.size()):
		var tab_bg := ColorRect.new()
		tab_bg.name = "TabBg_%d" % i
		tab_bg.position = Vector2(4.0 + i * 76.0, tab_y)
		tab_bg.size = Vector2(74.0, 14.0)
		tab_bg.color = Color(0.20, 0.22, 0.30, 0.9) if i != _active_tab else Color(0.30, 0.25, 0.10, 0.9)
		_bg.add_child(tab_bg)
		_item_nodes.append(tab_bg)

		var tab_lbl := Label.new()
		tab_lbl.text = TABS[i]
		tab_lbl.position = Vector2(6.0 + i * 76.0, tab_y + 2.0)
		tab_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.70))
		tab_lbl.add_theme_font_size_override("font_size", 7)
		tab_bg.add_child(tab_lbl)

	# Brand store view (mini floor preview)
	_build_store_view()

	# Content area
	_build_content()

	# Bottom hint
	_hint_lbl = Label.new()
	_hint_lbl.text = _get_hint()
	_hint_lbl.position = Vector2(4.0, PANEL_H - 16.0)
	_hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	_hint_lbl.add_theme_font_size_override("font_size", 6)
	_bg.add_child(_hint_lbl)
	_item_nodes.append(_hint_lbl)

func _build_store_view() -> void:
	# Small preview of current floor / store
	var view_bg := ColorRect.new()
	view_bg.name = "StoreView"
	view_bg.position = Vector2(PANEL_W - 108.0, 6.0)
	view_bg.size = Vector2(104.0, 60.0)
	view_bg.color = Color(0.10, 0.12, 0.18, 0.9)
	_bg.add_child(view_bg)
	_item_nodes.append(view_bg)

	var view_lbl := Label.new()
	view_lbl.name = "StoreViewLbl"
	view_lbl.text = "STORE PREVIEW"
	view_lbl.position = Vector2(PANEL_W - 106.0, 8.0)
	view_lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.70))
	view_lbl.add_theme_font_size_override("font_size", 6)
	_bg.add_child(view_lbl)
	_item_nodes.append(view_lbl)

	_store_time_lbl = Label.new()
	_store_time_lbl.text = "Time: --:--"
	_store_time_lbl.position = Vector2(PANEL_W - 106.0, 18.0)
	_store_time_lbl.add_theme_color_override("font_color", Color(0.70, 0.80, 0.90))
	_store_time_lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(_store_time_lbl)
	_item_nodes.append(_store_time_lbl)

	_store_npc_count_lbl = Label.new()
	_store_npc_count_lbl.text = "NPCs: --"
	_store_npc_count_lbl.position = Vector2(PANEL_W - 106.0, 28.0)
	_store_npc_count_lbl.add_theme_color_override("font_color", Color(0.70, 0.80, 0.90))
	_store_npc_count_lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(_store_npc_count_lbl)
	_item_nodes.append(_store_npc_count_lbl)

	# Floor selector
	var floor_lbl := Label.new()
	floor_lbl.text = "Floor: [W/S] navigate"
	floor_lbl.position = Vector2(PANEL_W - 106.0, 40.0)
	floor_lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.55))
	floor_lbl.add_theme_font_size_override("font_size", 6)
	_bg.add_child(floor_lbl)
	_item_nodes.append(floor_lbl)

	var brand_lbl := Label.new()
	brand_lbl.text = "Brand: %s" % (_brand_id if _brand_id != "" else "All Brands")
	brand_lbl.position = Vector2(PANEL_W - 106.0, 50.0)
	brand_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.80))
	brand_lbl.add_theme_font_size_override("font_size", 6)
	_bg.add_child(brand_lbl)
	_item_nodes.append(brand_lbl)

func _process(delta: float) -> void:
	if not visible:
		return
	# Update store view time from game clock
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node != null and main_node.has_method("get_game_clock"):
		var clock = main_node.get_game_clock()
		if clock != null:
			var t = clock.get_time_string()
			_store_time_lbl.text = "Time: %s" % t
		var npcs = main_node.get("npc_count")
		if npcs != null:
			_store_npc_count_lbl.text = "NPCs: %d" % npcs

func _build_content() -> void:
	match _active_tab:
		0: _build_products_tab()
		1: _build_events_tab()
		2: _build_ads_tab()
		3: _build_stats_tab()

func _close_children() -> void:
	for c in get_children():
		if is_instance_valid(c):
			c.queue_free()

# ─── Products Tab ────────────────────────────────────────────────────────────

func _build_products_tab() -> void:
	var brand_mgr = _get_brand_manager()
	var products: Array
	if _brand_id == "":
		products = brand_mgr.get_all_brand_products()
	else:
		products = brand_mgr.get_brand_products(_brand_id)

	_items = products
	_item_count_lbl = Label.new()
	_item_count_lbl.text = "%d products  |  [E] Add  [Del] Remove" % products.size()
	_item_count_lbl.position = Vector2(4.0, 38.0)
	_item_count_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70))
	_item_count_lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(_item_count_lbl)
	_item_nodes.append(_item_count_lbl)

	if _edit_mode:
		_build_product_edit_form()
		return

	# List products
	var y := 52.0
	var max_visible := 8
	for i in range(_scroll_offset, min(_scroll_offset + max_visible, products.size())):
		var entry = products[i]
		var p: Dictionary = entry.product if entry.has("product") else entry
		var brand_nm: String = entry.brand_name if entry.has("brand_name") else ""
		var is_selected := i == _selected_item

		var item_bg := ColorRect.new()
		item_bg.position = Vector2(4.0, y)
		item_bg.size = Vector2(PANEL_W - 8.0, 16.0)
		item_bg.color = Color(0.20, 0.22, 0.30, 0.8) if not is_selected else Color(0.35, 0.28, 0.10, 0.8)
		_bg.add_child(item_bg)
		_item_nodes.append(item_bg)

		var name_lbl := Label.new()
		name_lbl.text = p.get("name", "?")
		name_lbl.position = Vector2(6.0, y + 2.0)
		name_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.65))
		name_lbl.add_theme_font_size_override("font_size", 7)
		_bg.add_child(name_lbl)
		_item_nodes.append(name_lbl)

		var price_lbl := Label.new()
		price_lbl.text = "$%.2f" % p.get("price", 0.0)
		price_lbl.position = Vector2(6.0, y + 10.0)
		price_lbl.add_theme_color_override("font_color", Color(0.60, 0.80, 0.60))
		price_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(price_lbl)
		_item_nodes.append(price_lbl)

		var sec_lbl := Label.new()
		sec_lbl.text = "[%s]" % p.get("section", "?").to_upper()
		sec_lbl.position = Vector2(80.0, y + 10.0)
		sec_lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.70))
		sec_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(sec_lbl)
		_item_nodes.append(sec_lbl)

		if brand_nm != "":
			var b_lbl := Label.new()
			b_lbl.text = brand_nm
			b_lbl.position = Vector2(160.0, y + 10.0)
			b_lbl.add_theme_color_override("font_color", Color(0.70, 0.60, 0.40))
			b_lbl.add_theme_font_size_override("font_size", 6)
			_bg.add_child(b_lbl)
			_item_nodes.append(b_lbl)

		if p.get("limited_edition", false):
			var le_lbl := Label.new()
			le_lbl.text = "LIMITED!"
			le_lbl.position = Vector2(240.0, y + 10.0)
			le_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.20))
			le_lbl.add_theme_font_size_override("font_size", 6)
			_bg.add_child(le_lbl)
			_item_nodes.append(le_lbl)

		y += 18.0

func _build_product_edit_form() -> void:
	var y := 52.0

	var form_lbl := Label.new()
	form_lbl.text = "ADD PRODUCT"
	form_lbl.position = Vector2(4.0, y)
	form_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.50))
	form_lbl.add_theme_font_size_override("font_size", 8)
	_bg.add_child(form_lbl)
	_item_nodes.append(form_lbl)
	y += 14.0

	# Name
	_draw_form_field("Name:", _edit_name, Vector2(4.0, y), 160.0)
	y += 14.0
	# Price
	_draw_form_field("Price:", "$%.2f" % _edit_price, Vector2(4.0, y), 80.0)
	y += 14.0
	# Section
	_draw_form_field("Section:", _edit_section, Vector2(4.0, y), 100.0)
	y += 14.0
	# Description
	_draw_form_field("Desc:", _edit_desc.left(20), Vector2(4.0, y), 200.0)
	y += 14.0

	var hint := Label.new()
	hint.text = "Type to edit fields. [Enter] confirm  [Esc] cancel"
	hint.position = Vector2(4.0, y)
	hint.add_theme_color_override("font_color", Color(0.40, 0.45, 0.55))
	hint.add_theme_font_size_override("font_size", 6)
	_bg.add_child(hint)
	_item_nodes.append(hint)

func _draw_form_field(label: String, value: String, pos: Vector2, max_w: float) -> void:
	var lbl := Label.new()
	lbl.text = label
	lbl.position = pos
	lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.65))
	lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(lbl)
	_item_nodes.append(lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.position = Vector2(pos.x + 40.0, pos.y)
	val_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.65))
	val_lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(val_lbl)
	_item_nodes.append(val_lbl)

# ─── Events Tab ─────────────────────────────────────────────────────────────

func _build_events_tab() -> void:
	var brand_mgr = _get_brand_manager()
	var events: Array
	if _brand_id == "":
		events = []
		for b in brand_mgr.get_all_brands():
			for ev in b.get("active_events", []):
				events.append({"event": ev, "brand_id": b.get("brand_id", ""), "brand_name": b.get("name", "")})
	else:
		events = brand_mgr.get_events_for_brand(_brand_id)

	_items = events
	_item_count_lbl = Label.new()
	_item_count_lbl.text = "%d events  |  [E] Create new" % events.size()
	_item_count_lbl.position = Vector2(4.0, 38.0)
	_item_count_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70))
	_item_count_lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(_item_count_lbl)
	_item_nodes.append(_item_count_lbl)

	var y := 54.0
	for i in range(_scroll_offset, min(_scroll_offset + 6, events.size())):
		var ev: Dictionary
		var brand_nm := ""
		if events[i].has("event"):
			ev = events[i]["event"]
			brand_nm = events[i].get("brand_name", "")
		else:
			ev = events[i]

		var is_active = brand_mgr.is_event_active(ev.get("event_id", ""))

		var ev_bg := ColorRect.new()
		ev_bg.position = Vector2(4.0, y)
		ev_bg.size = Vector2(PANEL_W - 8.0, 22.0)
		ev_bg.color = Color(0.15, 0.20, 0.15, 0.8) if is_active else Color(0.18, 0.18, 0.22, 0.8)
		_bg.add_child(ev_bg)
		_item_nodes.append(ev_bg)

		var status := "ACTIVE" if is_active else "INACTIVE"
		var status_col := Color(0.40, 0.90, 0.50) if is_active else Color(0.50, 0.50, 0.55)

		var name_lbl := Label.new()
		name_lbl.text = ev.get("name", "?")
		name_lbl.position = Vector2(6.0, y + 2.0)
		name_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.65))
		name_lbl.add_theme_font_size_override("font_size", 7)
		_bg.add_child(name_lbl)
		_item_nodes.append(name_lbl)

		var stat_lbl := Label.new()
		stat_lbl.text = status
		stat_lbl.position = Vector2(PANEL_W - 50.0, y + 2.0)
		stat_lbl.add_theme_color_override("font_color", status_col)
		stat_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(stat_lbl)
		_item_nodes.append(stat_lbl)

		var xp_lbl := Label.new()
		xp_lbl.text = "%.0fx XP  |  %s" % [ev.get("xp_multiplier", 1.0), ev.get("ad_text", "")]
		xp_lbl.position = Vector2(6.0, y + 12.0)
		xp_lbl.add_theme_color_override("font_color", Color(0.60, 0.70, 0.80))
		xp_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(xp_lbl)
		_item_nodes.append(xp_lbl)

		if brand_nm != "":
			var b_lbl := Label.new()
			b_lbl.text = brand_nm
			b_lbl.position = Vector2(160.0, y + 12.0)
			b_lbl.add_theme_color_override("font_color", Color(0.70, 0.60, 0.40))
			b_lbl.add_theme_font_size_override("font_size", 6)
			_bg.add_child(b_lbl)
			_item_nodes.append(b_lbl)

		y += 24.0

	if events.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "No events yet.\nPress [E] to create one!"
		empty_lbl.position = Vector2(4.0, 60.0)
		empty_lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.55))
		empty_lbl.add_theme_font_size_override("font_size", 7)
		_bg.add_child(empty_lbl)
		_item_nodes.append(empty_lbl)

# ─── Ads Tab ────────────────────────────────────────────────────────────────

func _build_ads_tab() -> void:
	var brand_mgr = _get_brand_manager()
	var ads: Array
	if _brand_id == "":
		ads = []
		for b in brand_mgr.get_all_brands():
			for ad: Dictionary in b.get("ads", []):
				ad["_brand_name"] = b.get("name", "")
				ads.append(ad)
	else:
		var b = brand_mgr.get_brand(_brand_id)
		ads = b.get("ads", [])

	_items = ads
	_item_count_lbl = Label.new()
	_item_count_lbl.text = "%d ads placed  |  [E] Place new ad" % ads.size()
	_item_count_lbl.position = Vector2(4.0, 38.0)
	_item_count_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70))
	_item_count_lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(_item_count_lbl)
	_item_nodes.append(_item_count_lbl)

	var y := 54.0
	for i in range(_scroll_offset, min(_scroll_offset + 6, ads.size())):
		var ad: Dictionary = ads[i]
		var floor_nm := _get_floor_name(ad.get("floor", 0))

		var ad_bg := ColorRect.new()
		ad_bg.position = Vector2(4.0, y)
		ad_bg.size = Vector2(PANEL_W - 8.0, 20.0)
		ad_bg.color = Color(0.18, 0.15, 0.22, 0.8)
		_bg.add_child(ad_bg)
		_item_nodes.append(ad_bg)

		var txt_lbl := Label.new()
		txt_lbl.text = "\"%s\"" % ad.get("text", "?")
		txt_lbl.position = Vector2(6.0, y + 2.0)
		txt_lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 0.60))
		txt_lbl.add_theme_font_size_override("font_size", 7)
		_bg.add_child(txt_lbl)
		_item_nodes.append(txt_lbl)

		var floor_lbl := Label.new()
		floor_lbl.text = floor_nm
		floor_lbl.position = Vector2(PANEL_W - 60.0, y + 2.0)
		floor_lbl.add_theme_color_override("font_color", Color(0.50, 0.65, 0.80))
		floor_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(floor_lbl)
		_item_nodes.append(floor_lbl)

		var sub_lbl := Label.new()
		sub_lbl.text = ad.get("subtext", "")
		sub_lbl.position = Vector2(6.0, y + 11.0)
		sub_lbl.add_theme_color_override("font_color", Color(0.50, 0.55, 0.65))
		sub_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(sub_lbl)
		_item_nodes.append(sub_lbl)

		y += 22.0

	if ads.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "No ads placed.\nPress [E] to advertise!"
		empty_lbl.position = Vector2(4.0, 60.0)
		empty_lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.55))
		empty_lbl.add_theme_font_size_override("font_size", 7)
		_bg.add_child(empty_lbl)
		_item_nodes.append(empty_lbl)

# ─── Stats Tab ─────────────────────────────────────────────────────────────

func _build_stats_tab() -> void:
	var brand_mgr = _get_brand_manager()
	var brands: Array = brand_mgr.get_all_brands()

	_item_count_lbl = Label.new()
	_item_count_lbl.text = "Brand Performance Overview"
	_item_count_lbl.position = Vector2(4.0, 38.0)
	_item_count_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70))
	_item_count_lbl.add_theme_font_size_override("font_size", 7)
	_bg.add_child(_item_count_lbl)
	_item_nodes.append(_item_count_lbl)

	var y := 54.0
	for b in brands:
		var bid: String = b.get("brand_id", "")
		var stats: Dictionary = b.get("stats", {})
		var products: Array = b.get("products", [])
		var revenue: float = stats.get("revenue", 0.0)
		var purchases: int = stats.get("total_purchases", 0)

		var row_bg := ColorRect.new()
		row_bg.position = Vector2(4.0, y)
		row_bg.size = Vector2(PANEL_W - 8.0, 30.0)
		row_bg.color = Color(0.15, 0.18, 0.22, 0.8)
		_bg.add_child(row_bg)
		_item_nodes.append(row_bg)

		var name_lbl := Label.new()
		name_lbl.text = b.get("name", bid)
		name_lbl.position = Vector2(6.0, y + 2.0)
		name_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.50))
		name_lbl.add_theme_font_size_override("font_size", 8)
		_bg.add_child(name_lbl)
		_item_nodes.append(name_lbl)

		var prod_lbl := Label.new()
		prod_lbl.text = "%d products" % products.size()
		prod_lbl.position = Vector2(6.0, y + 14.0)
		prod_lbl.add_theme_color_override("font_color", Color(0.50, 0.60, 0.70))
		prod_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(prod_lbl)
		_item_nodes.append(prod_lbl)

		var rev_lbl := Label.new()
		rev_lbl.text = "$%.2f revenue" % revenue
		rev_lbl.position = Vector2(100.0, y + 14.0)
		rev_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 0.60))
		rev_lbl.add_theme_font_size_override("font_size", 7)
		_bg.add_child(rev_lbl)
		_item_nodes.append(rev_lbl)

		var pur_lbl := Label.new()
		pur_lbl.text = "%d units sold" % purchases
		pur_lbl.position = Vector2(210.0, y + 14.0)
		pur_lbl.add_theme_color_override("font_color", Color(0.60, 0.70, 0.80))
		pur_lbl.add_theme_font_size_override("font_size", 6)
		_bg.add_child(pur_lbl)
		_item_nodes.append(pur_lbl)

		y += 34.0
		if y > PANEL_H - 40.0:
			break

	if brands.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "No brands registered yet."
		empty_lbl.position = Vector2(4.0, 60.0)
		empty_lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.55))
		empty_lbl.add_theme_font_size_override("font_size", 7)
		_bg.add_child(empty_lbl)
		_item_nodes.append(empty_lbl)

# ─── Input ──────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_B:
				close()
				return
			KEY_E:
				_handle_e()
				return
			KEY_W, KEY_UP:
				_navigate(-1)
				return
			KEY_S, KEY_DOWN:
				_navigate(1)
				return
			KEY_TAB:
				_switch_tab()
				return

func _handle_e() -> void:
	if _active_tab == 0 and not _edit_mode:
		# Add product mode
		_edit_mode = true
		_edit_name = "New Product"
		_edit_price = 3.99
		_edit_section = "snacks"
		_edit_desc = "Description"
		_build()
	elif _active_tab == 1 and not _edit_mode:
		# Create event — simplified: toggle demo event
		var brand_mgr = _get_brand_manager()
		if _brand_id != "":
			brand_mgr.create_event(_brand_id, {
				"name": "New Promo Event",
				"description": "Special promotion!",
				"xp_multiplier": 2.0,
				"start_time": "2026-05-01T00:00",
				"end_time": "2026-05-31T23:59",
				"ad_text": "SALE!",
				"ad_color": "#ff6600",
				"floor": 4,
				"promo_npc_enabled": false
			})
			brand_mgr.save_brand(_brand_id)
			_build()

func _navigate(dir: int) -> void:
	if _items.size() == 0:
		return
	_selected_item = clampi(_selected_item + dir, 0, _items.size() - 1)
	var max_visible := 8 if _active_tab == 0 else 6
	if _selected_item >= _scroll_offset + max_visible:
		_scroll_offset = _selected_item - max_visible + 1
	if _selected_item < _scroll_offset:
		_scroll_offset = _selected_item
	_scroll_offset = clampi(_scroll_offset, 0, maxi(0, _items.size() - max_visible))
	_build()

func _switch_tab() -> void:
	_active_tab = (_active_tab + 1) % TABS.size()
	_edit_mode = false
	_selected_item = -1
	_scroll_offset = 0
	_build()

# ─── Helpers ────────────────────────────────────────────────────────────────

func _get_brand_manager() -> BrandManager:
	var root = get_tree().root
	var main = root.get_node_or_null("Main")
	if main == null:
		return null
	var bm = main.get_node_or_null("BrandManager")
	if bm != null and bm is BrandManager:
		return bm
	# Try group
	for n in get_tree().get_nodes_in_group("brand_manager"):
		if n is BrandManager:
			return n
	return null

func _get_floor_name(floor_idx: int) -> String:
	var names := {
		0: "Ground", 1: "Floor 1", 2: "Floor 2", 3: "Floor 3",
		4: "Floor 4", 5: "Floor 5", 6: "Floor 6", 7: "Floor 7",
		8: "Floor 8", 9: "Floor 9", 10: "Floor 10"
	}
	return names.get(floor_idx, "Floor %d" % floor_idx)

func _get_title() -> String:
	var brand_name := _brand_id
	if _brand_id != "":
		var bm = _get_brand_manager()
		if bm != null:
			var b = bm.get_brand(_brand_id)
			brand_name = b.get("name", _brand_id)
	return "BRAND PORTAL | %s  [B/ESC] close" % brand_name.to_upper()

func _get_hint() -> String:
	match _active_tab:
		0: return "[W/S] navigate  [E] add product  [TAB] switch tab  [Del] remove"
		1: return "[W/S] navigate  [E] create event  [TAB] switch tab"
		2: return "[W/S] navigate  [E] place ad  [TAB] switch tab"
		3: return "[TAB] switch tab"
	return "[TAB] switch tabs  [ESC] close"
