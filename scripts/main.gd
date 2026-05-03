# main.gd
# Supermarket world builder and game loop.
extends Node2D

const StoreData = preload("res://scripts/store_data.gd")

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

var _world_bg = null
var _aisle_labels: Array = []

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
	_build_world()
	_setup_camera()
	_build_hud()
	_build_sections()
	_build_checkout()
	_spawn_player()
	_build_npcs()

func _build_world() -> void:
	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE)
	bg.position = Vector2.ZERO
	bg.color = Color(0.18, 0.16, 0.14)
	add_child(bg)
	
	# Floor tiles (checkerboard variation)
	var floor := ColorRect.new()
	floor.size = Vector2(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE)
	floor.color = Color(0.19, 0.18, 0.16)
	add_child(floor)
	
	# Top wall
	for x in range(WORLD_W):
		_set_wall(x, 1)
	# Side walls
	for y in range(WORLD_H):
		_set_wall(0, y)
		_set_wall(WORLD_W - 1, y)
	# Bottom wall
	for x in range(WORLD_W):
		_set_wall(x, WORLD_H - 1)
	
	# Section dividers (main aisle horizontal at y=17)
	for x in range(WORLD_W):
		_set_aisle_floor(x, 17)
		_set_aisle_floor(x, 18)
	
	# Vertical main aisle (between x=18 and x=19)
	for y in range(2, WORLD_H - 1):
		_set_aisle_floor(18, y)
		_set_aisle_floor(19, y)
	
	# Entrance gap in top wall
	for x in range(10, 14):
		_unset_wall(x, 1)
	# Floor in entrance
	for x in range(10, 14):
		for y in range(0, 2):
			_set_aisle_floor(x, y)
	
	# Checkout area walls
	for x in range(WORLD_W):
		_set_wall(x, 34)
	
	# Section separator walls (between upper and lower sections, gaps at aisles)
	for x in [1, 20, 42, 60, 78]:
		for y in range(17, 19):
			_set_aisle_floor(x, y)
			_set_aisle_floor(x + 1, y)
	
	# Build section backgrounds
	for def in StoreData.SECTIONS:
		_build_section_bg(def)
	
	# Section aisle labels
	_add_aisle_signs()
	
	# Checkout area floor
	for x in range(WORLD_W):
		for y in range(35, 38):
			_set_aisle_floor(x, y)

func _set_wall(x: int, y: int) -> void:
	pass  # handled by TileMap if needed

func _unset_wall(x: int, y: int) -> void:
	pass

func _set_aisle_floor(x: int, y: int) -> void:
	pass

func _build_section_bg(def) -> void:
	var sx: float = def.wx * CELL_SIZE
	var sy: float = def.wy * CELL_SIZE
	var sw: float = def.ww * CELL_SIZE
	var sh: float = def.wh * CELL_SIZE
	
	# Floor color by style
	var floor_c := _get_section_floor(def.style)
	var bg := ColorRect.new()
	bg.position = Vector2(sx, sy)
	bg.size = Vector2(sw, sh)
	bg.color = floor_c
	add_child(bg)
	
	# Section border / walls
	var wc := _get_wall_color(def.style)
	var tw := ColorRect.new()
	tw.position = Vector2(sx, sy)
	tw.size = Vector2(sw, 2)
	tw.color = wc
	add_child(tw)
	
	var bw := ColorRect.new()
	bw.position = Vector2(sx, sy + sh - 2)
	bw.size = Vector2(sw, 2)
	bw.color = wc.darkened(0.15)
	add_child(bw)
	
	var lw := ColorRect.new()
	lw.position = Vector2(sx, sy)
	lw.size = Vector2(2, sh)
	lw.color = wc.darkened(0.1)
	add_child(lw)
	
	var rw := ColorRect.new()
	rw.position = Vector2(sx + sw - 2, sy)
	rw.size = Vector2(2, sh)
	rw.color = wc.darkened(0.2)
	add_child(rw)
	
	# Section glow light
	var glow := Sprite2D.new()
	glow.position = Vector2(sx + sw * 0.5, sy - 8)
	glow.texture = _make_light_glow(def.light_color)
	add_child(glow)
	
	# Section name sign
	var sign := _make_sign(def)
	sign.position = Vector2(sx + sw * 0.5, sy + 6)
	add_child(sign)

func _get_section_floor(style: int) -> Color:
	match style:
		StoreData.SectionStyle.FRIDGE:   return Color(0.14, 0.18, 0.24)
		StoreData.SectionStyle.PRODUCE:  return Color(0.14, 0.19, 0.12)
		StoreData.SectionStyle.BAKERY:   return Color(0.20, 0.15, 0.10)
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
	# Sign background
	_fill_sign_rect(img, 0, 0, 80, 12, _get_wall_color(def.style).darkened(0.3))
	# Sign border
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
	# Aisle labels between upper and lower sections
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

func _build_sections() -> void:
	_section_browse = SectionBrowse.new()
	add_child(_section_browse)
	_section_browse.item_added.connect(_on_item_added_to_cart)
	_section_browse.closed.connect(_on_browse_closed)
	
	for def in StoreData.SECTIONS:
		var sec := SupermarketSection.new()
		sec.configure(def)
		sec.position = Vector2(def.wx * CELL_SIZE, def.wy * CELL_SIZE)
		sec.name = "Section_%s" % def.id
		sec.player_entered.connect(_on_section_entered)
		sec.player_exited.connect(_on_section_exited)
		add_child(sec)
		_sections.append(sec)

func _build_checkout() -> void:
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
	var npc_scene = preload("res://scripts/npc_controller.gd")
	for i in range(6):
		var npc = npc_scene.new()
		npc.position = Vector2(20 * CELL_SIZE + randi() % (40 * CELL_SIZE), 6 * CELL_SIZE + randi() % (10 * CELL_SIZE))
		npc.name = "NPC_%d" % i
		add_child(npc)

func _process(_delta: float) -> void:
	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	_update_player_section_proximity()
	_update_checkout_proximity()

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
	if nearest != null:
		_checkout_counter_label.visible = false
	
	var prompt_bg = get_node_or_null("PromptBg")
	var prompt_lbl = get_node_or_null("PromptLbl")
	
	if nearest != null:
		_player.set_nearby_section(nearest)
		var def = nearest.get_def()
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Browse %s" % def.name
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
	else:
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
	if near_checkout != null:
		_checkout_counter_label.text = "[E] Checkout at %s" % near_checkout.name.replace("Counter_", "")
		_checkout_counter_label.visible = true
	else:
		_checkout_counter_label.visible = false

func _on_player_interact() -> void:
	# Priority: 1) checkout receipt open → close it, 2) section browse
	if _checkout_receipt_visible:
		_hide_checkout_receipt()
		return
	if _current_section_browse != null and _current_section_browse.visible:
		return
	# Priority: 1) near checkout with items → open checkout
	if _nearby_checkout != null:
		var cart = _player.get_cart()
		if cart.get_item_count() > 0:
			_show_checkout_receipt()
			return
	# 2) near section → open section browse
	if _nearby_section != null:
		var def = _nearby_section.get_def()
		var prods = _nearby_section.get_all_products()
		_current_section_browse = _section_browse
		_section_browse.open(def.id, prods, _player.get_cart())

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
	# Cart items list
	_cart_items_lbl = Label.new()
	_cart_items_lbl.name = "CartItems"
	_cart_items_lbl.position = Vector2(4.0, 4.0)
	_cart_items_lbl.size = Vector2(152.0, 110.0)
	_cart_items_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
	_cart_items_lbl.add_theme_font_size_override("font_size", 8)
	_cart_items_lbl.add_theme_constant_override("line_spacing", 2)
	_cart_panel.add_child(_cart_items_lbl)
	# Total
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

	# Dark overlay
	var ov := ColorRect.new()
	ov.name = "CROverlay"
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.03, 0.03, 0.06, 0.90)
	ov.gui_input.connect(_on_receipt_input)
	add_child(ov)

	# Receipt panel — centered, 220x165
	var pan_x: float = (320.0 - 220.0) * 0.5
	var pan_y: float = (180.0 - 165.0) * 0.5

	var pan := ColorRect.new()
	pan.name = "CRPanel"
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(220.0, 165.0)
	pan.color = Color(0.09, 0.09, 0.13, 1.0)
	pan.gui_input.connect(_on_receipt_input)
	add_child(pan)

	# Header
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

	# Items
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

	# Divider
	var div := ColorRect.new()
	div.position = Vector2(pan_x + 6.0, y_pos + 1.0)
	div.size = Vector2(208.0, 1.0)
	div.color = Color(0.30, 0.30, 0.35, 1.0)
	add_child(div)
	y_pos += 6.0

	# Totals
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

	# Total line
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

	# Thank you
	var thanks := Label.new()
	thanks.position = Vector2(pan_x + 40.0, y_pos)
	thanks.text = "THANK YOU FOR SHOPPING!"
	thanks.add_theme_color_override("font_color", Color(0.72, 0.88, 0.72))
	thanks.add_theme_font_size_override("font_size", 8)
	thanks.gui_input.connect(_on_receipt_input)
	add_child(thanks)
	y_pos += line_h + 4.0

	# Done prompt
	var done_lbl := Label.new()
	done_lbl.position = Vector2(pan_x + 60.0, y_pos)
	done_lbl.text = "[E] Done"
	done_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.48))
	done_lbl.add_theme_font_size_override("font_size", 8)
	done_lbl.gui_input.connect(_on_receipt_input)
	add_child(done_lbl)

func _hide_checkout_receipt() -> void:
	_checkout_receipt_visible = false
	# Remove all receipt nodes
	for name in ["CROverlay", "CRPanel"]:
		var node = get_node_or_null("/root/Main/" + name)
		if node == null:
			node = get_node_or_null(name)
		if node != null:
			node.queue_free()
	# Remove all nodes added during receipt
	var to_remove: Array = []
	for c in get_children():
		if c is Label or c is ColorRect:
			var nm = c.name if c is Label or c is ColorRect else ""
			if nm in ["CROverlay", "CRPanel"]:
				continue
			if c.get_parent() == self and c.position.y >= 0:
				# Heuristic: receipt nodes are in the center of screen
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
	_hide_checkout_receipt()
	var cart = _player.get_cart()
	cart.clear()
	_refresh_cart_panel()
