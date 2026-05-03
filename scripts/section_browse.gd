# section_browse.gd
# Full-screen overlay showing all products in a section.
# Player browses and presses number or clicks to add to cart.

class_name SectionBrowse
extends CanvasLayer
const StoreData = preload("res://scripts/store_data.gd")

signal item_added(product: StoreData.MarketProduct)
signal closed()

const CELL_SIZE := 16

var _section_id: String = ""
var _products: Array = []
var _slot_nodes: Array = []   # slot background nodes for highlight
var _selected: int = 0
var _cart_ref: Node = null

func _ready() -> void:
	visible = false
	# Background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.05, 0.05, 0.08, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.z_index = -1
	
	var keyboard := InputEventHandler.new()
	keyboard.action_pressed.connect(_on_key_action)
	add_child(keyboard)

func open(section_id: String, products: Array, cart: Node) -> void:
	_section_id = section_id
	_products = products
	_cart_ref = cart
	_selected = 0
	
	# Clear old slot nodes
	for node in _slot_nodes:
		node.queue_free()
	_slot_nodes.clear()
	
	_build_panel()
	visible = true
	get_tree().paused = false  # keep game running

func close() -> void:
	visible = false
	for node in _slot_nodes:
		node.queue_free()
	_slot_nodes.clear()
	closed.emit()

func _build_panel() -> void:
	var def: StoreData.SectionDef = StoreData.get_section_def(_section_id)
	var panel_w: float = 280.0
	var panel_h: float = 220.0
	var margin_h: float = (320.0 - panel_w) / 2.0
	var margin_v: float = (180.0 - panel_h) / 2.0
	
	# Main panel
	var panel := Panel.new()
	panel.position = Vector2(margin_h, margin_v)
	panel.size = Vector2(panel_w, panel_h)
	panel.color = Color(0.10, 0.10, 0.14, 1.0)
	add_child(panel)
	_slot_nodes.append(panel)
	
	# Header bar
	var header := ColorRect.new()
	header.position = Vector2(margin_h, margin_v)
	header.size = Vector2(panel_w, 20.0)
	header.color = Color(def.light_color.r * 0.4, def.light_color.g * 0.4, def.light_color.b * 0.4, 1.0)
	add_child(header)
	_slot_nodes.append(header)
	
	# Section name label
	var lbl := Label.new()
	lbl.text = "%s %s" % [def.label, def.name]
	lbl.position = Vector2(margin_h + 6, margin_v + 2)
	lbl.add_theme_color_override("font_color", Color(def.light_color.r, def.light_color.g, def.light_color.b))
	add_child(lbl)
	_slot_nodes.append(lbl)
	
	# Grid of products: 4 columns, scrollable
	var cols := 4
	var item_w: float = panel_w / float(cols)
	var item_h: float = 38.0
	var start_y: float = margin_v + 22.0
	var count := _products.size()
	
	var rows_needed: int = ceili(float(count) / float(cols))
	var grid_h: float = rows_needed * item_h
	var scroll_h: float = minf(grid_h, panel_h - 44.0)
	
	var cart_count: int = 0
	if _cart_ref != null and _cart_ref.has_method("get_item_count"):
		cart_count = _cart_ref.get_item_count()
	
	for i in range(count):
		var row: int = i / cols
		var col: int = i % cols
		var ix: float = margin_h + col * item_w + 2.0
		var iy: float = start_y + row * item_h
		
		# Item background
		var item_bg := ColorRect.new()
		item_bg.position = Vector2(ix, iy)
		item_bg.size = Vector2(item_w - 4.0, item_h - 2.0)
		item_bg.color = Color(0.14, 0.14, 0.18, 1.0) if i != _selected else Color(def.light_color.r * 0.3, def.light_color.g * 0.3, def.light_color.b * 0.3, 1.0)
		add_child(item_bg)
		_slot_nodes.append(item_bg)
		
		# Product sprite
		var prod: StoreData.MarketProduct = _products[i]
		var spr := Sprite2D.new()
		spr.position = Vector2(ix + 14.0, iy + item_h / 2.0 - 1.0)
		spr.texture = _make_prod_tex(prod)
		spr.scale = Vector2(2.0, 2.0)   # 12×12 → 24×24 displayed
		add_child(spr)
		_slot_nodes.append(spr)
		
		# Number badge
		var num_lbl := Label.new()
		num_lbl.text = "%d" % (i + 1)
		num_lbl.position = Vector2(ix + 1.0, iy + 1.0)
		num_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
		num_lbl.add_theme_font_size_override("font_size", 8)
		add_child(num_lbl)
		_slot_nodes.append(num_lbl)
		
		# Name
		var name_lbl := Label.new()
		name_lbl.text = prod.name
		name_lbl.position = Vector2(ix + 26.0, iy + 4.0)
		name_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
		name_lbl.add_theme_font_size_override("font_size", 8)
		add_child(name_lbl)
		_slot_nodes.append(name_lbl)
		
		# Price
		var price_lbl := Label.new()
		price_lbl.text = "$%.2f" % prod.price
		price_lbl.position = Vector2(ix + 26.0, iy + 18.0)
		price_lbl.add_theme_color_override("font_color", Color(0.85, 0.72, 0.38))
		price_lbl.add_theme_font_size_override("font_size", 8)
		add_child(price_lbl)
		_slot_nodes.append(price_lbl)
	
	# Bottom bar
	var bottom_bar := ColorRect.new()
	bottom_bar.position = Vector2(margin_h, margin_v + panel_h - 22.0)
	bottom_bar.size = Vector2(panel_w, 22.0)
	bottom_bar.color = Color(0.08, 0.08, 0.12, 1.0)
	add_child(bottom_bar)
	_slot_nodes.append(bottom_bar)
	
	var cart_lbl := Label.new()
	cart_lbl.text = "Cart: %d items  |  [E/%d-9] Add  |  [ESC] Close" % [cart_count, (_selected % 9) + 1]
	cart_lbl.position = Vector2(margin_h + 6, margin_v + panel_h - 18.0)
	cart_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	cart_lbl.add_theme_font_size_override("font_size", 8)
	add_child(cart_lbl)
	_slot_nodes.append(cart_lbl)

func _make_prod_tex(prod: StoreData.MarketProduct) -> Texture2D:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_product(img, prod)
	return ImageTexture.create_from_image(img)

func _draw_product(img: Image, prod: StoreData.MarketProduct) -> void:
	var c := prod.color
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

func _on_key_action(action: String) -> void:
	if not visible:
		return
	if action == "escape":
		close()
		return
	if action == "ui_accept" or action == "interact":
		_add_selected_to_cart()
		return
	if action == "ui_up":
		var cols := 4
		_selected = clampi(_selected - cols, 0, _products.size() - 1)
		_refresh_selection()
		return
	if action == "ui_down":
		var cols := 4
		_selected = clampi(_selected + cols, 0, _products.size() - 1)
		_refresh_selection()
		return
	if action == "ui_left":
		_selected = clampi(_selected - 1, 0, _products.size() - 1)
		_refresh_selection()
		return
	if action == "ui_right":
		_selected = clampi(_selected + 1, 0, _products.size() - 1)
		_refresh_selection()
		return
	# Number keys 1-9 to quick-add
	for i in range(9):
		if action == "num_%d" % (i + 1):
			var idx := _selected
			if i < _products.size():
				idx = i
			if idx < _products.size():
				_add_to_cart(_products[idx])
			return

func _add_selected_to_cart() -> void:
	if _selected < _products.size():
		_add_to_cart(_products[_selected])

func _add_to_cart(product: StoreData.MarketProduct) -> void:
	if _cart_ref != null and _cart_ref.has_method("add_item"):
		_cart_ref.add_item(product)
		item_added.emit(product)
		# Refresh panel to update cart count
		_build_panel()

func _refresh_selection() -> void:
	# Rebuild just selection state (full rebuild for now)
	_build_panel()


# ─── Tiny input handler node ──────────────────────────────────────────────────
class InputEventHandler extends Node:
	signal action_pressed(action: String)
	
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed:
			var ev := event as InputEventKey
			match ev.keycode:
				KEY_ESCAPE: action_pressed.emit("escape")
				KEY_E: action_pressed.emit("ui_accept")
				KEY_W: action_pressed.emit("ui_up")
				KEY_UP: action_pressed.emit("ui_up")
				KEY_S: action_pressed.emit("ui_down")
				KEY_DOWN: action_pressed.emit("ui_down")
				KEY_A: action_pressed.emit("ui_left")
				KEY_LEFT: action_pressed.emit("ui_left")
				KEY_D: action_pressed.emit("ui_right")
				KEY_RIGHT: action_pressed.emit("ui_right")
				KEY_1: action_pressed.emit("num_1")
				KEY_2: action_pressed.emit("num_2")
				KEY_3: action_pressed.emit("num_3")
				KEY_4: action_pressed.emit("num_4")
				KEY_5: action_pressed.emit("num_5")
				KEY_6: action_pressed.emit("num_6")
				KEY_7: action_pressed.emit("num_7")
				KEY_8: action_pressed.emit("num_8")
				KEY_9: action_pressed.emit("num_9")
