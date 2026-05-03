# main.gd — Pixel Supermarket world builder
class_name Main
extends Node2D
const StoreData = preload("res://scripts/store_data.gd")

const CELL_SIZE := 16
const WORLD_W := 80
const WORLD_H := 60

var _player: Player
var _sections: Array = []
var _checkout_counters: Array = []
var _current_section_browse: Node = null
var _browse_layer: Node = null
var _hud: HUD
var _checkout_screen: Node = null
var _checkout_open := false

var _player_section: Node = null
var _cart: ShoppingCart

func _ready() -> void:
	_build_floor()
	_build_walls()
	_build_sections()
	_build_checkout()
	_spawn_player()
	_spawn_npcs()
	_setup_camera()
	_setup_hud()
	_setup_browse_layer()
	_connect_signals()
	_update_zone_label()

func _build_floor() -> void:
	var tex := _make_floor_tex()
	var rect := TextureRect.new()
	rect.texture = tex
	rect.position = Vector2.ZERO
	rect.size = Vector2(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE)
	add_child(rect)

func _make_floor_tex() -> Texture2D:
	var img := Image.create(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE, false, Image.FORMAT_RGBA8)
	# Base floor
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var cx := x / CELL_SIZE
			var cy := y / CELL_SIZE
			var checker := (cx + cy) % 2
			var col := Color(0.16, 0.16, 0.18) if checker == 0 else Color(0.20, 0.20, 0.22)
			# Subtle noise
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _build_walls() -> void:
	var wall_color := Color(0.22, 0.22, 0.26)
	# Top wall
	var top := ColorRect.new()
	top.size = Vector2(WORLD_W * CELL_SIZE, CELL_SIZE * 2)
	top.color = wall_color
	add_child(top)
	# Bottom wall
	var bot := ColorRect.new()
	bot.position = Vector2(0, (WORLD_H - 2) * CELL_SIZE)
	bot.size = Vector2(WORLD_W * CELL_SIZE, CELL_SIZE * 2)
	bot.color = wall_color
	add_child(bot)
	# Left wall
	var left := ColorRect.new()
	left.size = Vector2(CELL_SIZE * 2, WORLD_H * CELL_SIZE)
	left.color = wall_color
	add_child(left)
	# Right wall
	var right := ColorRect.new()
	right.position = Vector2((WORLD_W - 2) * CELL_SIZE, 0)
	right.size = Vector2(CELL_SIZE * 2, WORLD_H * CELL_SIZE)
	right.color = wall_color
	add_child(right)
	# Entrance opening (top-center, 6 cells wide)
	var entrance_x := (WORLD_W / 2 - 3) * CELL_SIZE
	var entrance_w := 6 * CELL_SIZE
	var entrance_top := ColorRect.new()
	entrance_top.position = Vector2(entrance_x, 0)
	entrance_top.size = Vector2(entrance_w, CELL_SIZE * 2)
	entrance_top.color = Color(0.12, 0.12, 0.14)
	add_child(entrance_top)

func _build_sections() -> void:
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
		var counter := CheckoutCounter.new()
		counter.configure(lane["x"])
		counter.position = Vector2(lane["x"] * CELL_SIZE, StoreData.CHECKOUT_Y * CELL_SIZE)
		counter.name = "Checkout_%d" % lane["x"]
		counter.checkout_interacted.connect(_on_checkout_interacted)
		add_child(counter)
		_checkout_counters.append(counter)

func _spawn_player() -> void:
	_player = Player.new()
	_player.name = "Player"
	_player.position = Vector2((WORLD_W / 2) * CELL_SIZE, 1 * CELL_SIZE)
	add_child(_player)
	_cart = _player.get_cart()
	_player.set_world(self)
	_player.interact_requested.connect(_on_player_interact)
	_player.zone_changed.connect(_on_zone_changed)

func _spawn_npcs() -> void:
	# 4 NPCs (reduced from 8 since sections are now the main content)
	var npc_tints: Array = [
		Color(1.0, 1.0, 1.0),
		Color(1.0, 0.9, 0.85),
		Color(0.9, 0.95, 1.0),
		Color(0.9, 1.0, 0.9),
	]
	for i in range(4):
		var npc := NPCController.new()
		npc.name = "NPC%d" % i
		var start_x: float = (6 + (i % 3) * 22) * CELL_SIZE
		var start_y: float = (16 + (i / 3) * 20) * CELL_SIZE
		npc.position = Vector2(start_x, start_y)
		npc.set_color_tint(npc_tints[i % npc_tints.size()])
		add_child(npc)

func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.position = Vector2(WORLD_W * CELL_SIZE / 2.0, WORLD_H * CELL_SIZE / 2.0)
	cam.zoom = Vector2(3.0, 3.0)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = WORLD_W * CELL_SIZE
	cam.limit_bottom = WORLD_H * CELL_SIZE
	
	
	cam.position_smoothing_speed = 3.0
	add_child(cam)
	cam.make_current()

func _setup_hud() -> void:
	_hud = HUD.new()
	_hud.set_cart(_cart)
	add_child(_hud)

func _setup_browse_layer() -> void:
	_browse_layer = Node.new()
	_browse_layer.name = "BrowseLayer"
	add_child(_browse_layer)

func _connect_signals() -> void:
	pass  # signals connected inline above

func _on_section_entered(section_id: String) -> void:
	for sec in _sections:
		if sec.get_def().id == section_id:
			_player_section = sec
			_hud.update_zone(sec.get_def().name + " " + sec.get_def().label)
			_hud.update_prompt("[E] Browse " + sec.get_def().name)
			break

func _on_section_exited(section_id: String) -> void:
	_player_section = null
	_hud.update_zone("")
	_hud.update_prompt("")

func _on_zone_changed(zone: String) -> void:
	if zone == "":
		_update_zone_label()

func _update_zone_label() -> void:
	pass

func _on_player_interact() -> void:
	if _checkout_open:
		_close_checkout()
		return
	if _current_section_browse != null and _current_section_browse.visible:
		_close_section_browse()
		return
	if _player_section != null:
		_open_section_browse(_player_section)

func _open_section_browse(section: Node) -> void:
	_close_section_browse()
	var def: StoreData.SectionDef = section.get_def()
	var products: Array = section.get_all_products()
	var browse := SectionBrowse.new()
	browse.name = "SectionBrowse"
	browse.open(def.id, products, _cart)
	browse.item_added.connect(_on_item_added_to_cart)
	browse.closed.connect(_on_browse_closed)
	_browse_layer.add_child(browse)
	_current_section_browse = browse
	_hud.update_prompt("[E] Close  |  [1-9] Add to cart")

func _close_section_browse() -> void:
	if _current_section_browse != null:
		_current_section_browse.close()
		_current_section_browse.queue_free()
		_current_section_browse = null
	if _player_section != null:
		_hud.update_prompt("[E] Browse " + _player_section.get_def().name)
	else:
		_hud.update_prompt("")

func _on_browse_closed() -> void:
	_current_section_browse = null
	if _player_section != null:
		_hud.update_prompt("[E] Browse " + _player_section.get_def().name)
	else:
		_hud.update_prompt("")

func _on_item_added_to_cart(product: StoreData.MarketProduct) -> void:
	_hud.update_cart_count(_cart.get_item_count())

func _on_checkout_interacted(checkout_id: int) -> void:
	if _checkout_open:
		_close_checkout()
		return
	if _cart.is_empty():
		_hud.update_prompt("Cart is empty!")
		return
	_open_checkout_screen(checkout_id)

func _open_checkout_screen(checkout_id: int) -> void:
	_checkout_open = true
	_checkout_screen = _build_checkout_screen(checkout_id)
	add_child(_checkout_screen)

func _build_checkout_screen(checkout_id: int) -> Node:
	var layer := CanvasLayer.new()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08, 0.95)
	layer.add_child(bg)
	
	var panel_w := 240.0; var panel_h := 160.0
	var px := (320.0 - panel_w) / 2.0; var py := (180.0 - panel_h) / 2.0
	
	var panel := Panel.new()
	panel.position = Vector2(px, py)
	panel.size = Vector2(panel_w, panel_h)
	panel.color = Color(0.10, 0.10, 0.14, 1.0)
	layer.add_child(panel)
	
	var title := Label.new()
	title.text = "CHECKOUT LANE %d" % checkout_id
	title.position = Vector2(px + 8, py + 6)
	title.add_theme_color_override("font_color", Color(0.91, 0.76, 0.44))
	title.add_theme_font_size_override("font_size", 10)
	layer.add_child(title)
	
	var items: Array = _cart.get_items()
	var y_off := py + 22.0
	var max_show := mini(items.size(), 8)
	for i in range(max_show):
		var p: StoreData.MarketProduct = items[i]
		var lbl := Label.new()
		lbl.text = "%-18s $%.2f" % [p.name, p.price]
		lbl.position = Vector2(px + 8, y_off + i * 10)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.72))
		lbl.add_theme_font_size_override("font_size", 8)
		layer.add_child(lbl)
	
	if items.size() > max_show:
		var more := Label.new()
		more.text = "... +%d more items" % (items.size() - max_show)
		more.position = Vector2(px + 8, y_off + max_show * 10)
		more.add_theme_color_override("font_color", Color(0.55, 0.55, 0.48))
		more.add_theme_font_size_override("font_size", 8)
		layer.add_child(more)
	
	var subtotal := _cart.get_total()
	var tax := subtotal * 0.06
	var total := subtotal + tax
	
	var sep := Label.new()
	sep.text = "────────────────────"
	sep.position = Vector2(px + 8, y_off + max_show * 10 + 8)
	sep.add_theme_color_override("font_color", Color(0.40, 0.40, 0.38))
	sep.add_theme_font_size_override("font_size", 8)
	layer.add_child(sep)
	
	var tax_lbl := Label.new()
	tax_lbl.text = "Tax (6%%):    $%.2f" % tax
	tax_lbl.position = Vector2(px + 8, y_off + max_show * 10 + 18)
	tax_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.58))
	tax_lbl.add_theme_font_size_override("font_size", 8)
	layer.add_child(tax_lbl)
	
	var total_lbl := Label.new()
	total_lbl.text = "TOTAL:       $%.2f" % total
	total_lbl.position = Vector2(px + 8, py + panel_h - 24)
	total_lbl.add_theme_color_override("font_color", Color(0.91, 0.76, 0.44))
	total_lbl.add_theme_font_size_override("font_size", 10)
	layer.add_child(total_lbl)
	
	var prompt := Label.new()
	prompt.text = "[E] Pay & Finish  |  [ESC] Cancel"
	prompt.position = Vector2(px + 8, py + panel_h - 12)
	prompt.add_theme_color_override("font_color", Color(0.55, 0.55, 0.48))
	prompt.add_theme_font_size_override("font_size", 8)
	layer.add_child(prompt)
	
	return layer

func _close_checkout() -> void:
	if _checkout_screen != null:
		_checkout_screen.queue_free()
		_checkout_screen = null
	_checkout_open = false

func _process(delta: float) -> void:
	# Handle pay action at checkout
	if _checkout_open and Input.is_action_just_pressed("interact"):
		_checkout_and_finish()
	if _checkout_open and Input.is_action_just_pressed("ui_cancel"):
		_close_checkout()
	
	# Check if player is near any section
	_update_player_section_proximity()

func _update_player_section_proximity() -> void:
	if _current_section_browse != null and _current_section_browse.visible:
		return   # browsing overrides proximity
	
	var ppos = _player.position if _player != null else Vector2.ZERO
	var nearest: Node = null
	var nearest_dist := 99999.0
	
	for sec in _sections:
		var def = sec.get_def()
		var sx: float = (def.wx + def.ww / 2.0) * CELL_SIZE
		var sy: float = (def.wy + def.wh / 2.0) * CELL_SIZE
		var dist := ppos.distance_to(Vector2(sx, sy))
		if dist < nearest_dist and dist < CELL_SIZE * 6.0:
			nearest_dist = dist
			nearest = sec
	
	if nearest != _player_section:
		if nearest != null:
			_on_section_entered(nearest.get_def().id)
		else:
			_on_section_exited("")
			_player_section = null

func _checkout_and_finish() -> void:
	var total: float = _cart.get_total()
	var tax := total * 0.06
	var grand_total := total + tax
	_cart.clear()
	_close_checkout()
	_hud.update_cart_count(0)
	# Brief thank-you flash via HUD
	_hud.update_prompt("THANK YOU! $%.2f" % grand_total)
	await get_tree().create_timer(2.5).timeout
	_hud.update_prompt("")
