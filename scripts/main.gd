# main.gd
# Sets up the entire supermarket world: floor, walls, aisles, checkout, player, camera, HUD.

class_name Main
extends Node2D

const CELL_SIZE := 16.0
const WORLD_W := 80   # cells
const WORLD_H := 60   # cells

# Grid offsets for aisles (local to world)
# Each aisle is a pair of shelf rows with a walkway between them
var _player: Player = null
var _camera: Camera2D = null
var _hud: HUD = null

# Zone label
var _current_zone: String = ""

func _ready() -> void:
	_build_floor()
	_build_walls()
	_build_aisles()
	_build_checkout()
	_spawn_npcs()
	_spawn_player()
	_setup_camera()
	_setup_hud()
	_connect_signals()

	_update_zone_label()

func _build_floor() -> void:
	# Single textured rect using a procedural checker texture - only 1 Node
	var tex := _make_floor_tex()
	var rect := TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.stretch_mode = TextureRect.STRETCH_TILE
	rect.size = Vector2(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE)
	rect.z_index = -10
	add_child(rect)

func _make_floor_tex() -> Texture2D:
	# 32×32 pixel tile, repeated - tiny texture, big savings
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.165, 0.165, 0.18)
	var c2 := Color(0.18, 0.18, 0.20)
	var lc := Color(0.21, 0.21, 0.23)
	for px in range(32):
		for py in range(32):
			img.set_pixel(px, py, c1 if (px / 16 + py / 16) % 2 < 1 else c2)
	for i in range(32):
		img.set_pixel(i, 0, lc)
		img.set_pixel(i, 16, lc)
		img.set_pixel(0, i, lc)
		img.set_pixel(16, i, lc)
	var tex := ImageTexture.create_from_image(img)
	return tex

func _build_walls() -> void:
	# Top and bottom walls
	for x in range(0, WORLD_W):
		var top := Sprite2D.new()
		top.texture = PixelArtGenerator.make_wall()
		top.position = Vector2(x * CELL_SIZE, 0)
		top.z_index = -5
		add_child(top)

		var bottom := Sprite2D.new()
		bottom.texture = PixelArtGenerator.make_wall()
		bottom.position = Vector2(x * CELL_SIZE, (WORLD_H - 1) * CELL_SIZE)
		bottom.z_index = -5
		add_child(bottom)

	# Left and right walls
	for y in range(1, WORLD_H - 1):
		var left := Sprite2D.new()
		left.texture = PixelArtGenerator.make_wall()
		left.position = Vector2(0, y * CELL_SIZE)
		left.z_index = -5
		add_child(left)

		var right := Sprite2D.new()
		right.texture = PixelArtGenerator.make_wall()
		right.position = Vector2((WORLD_W - 1) * CELL_SIZE, y * CELL_SIZE)
		right.z_index = -5
		add_child(right)

func _build_aisles() -> void:
	# 12 aisles arranged in 4 columns × 3 rows
	# Each aisle = 2 parallel shelf rows (12 slots each row)
	# Layout: 4 cols, 3 rows
	var aisle_configs: Array = [
		# 4 cols × 3 rows, aisle_id, display_name, start_x, shelf1_y, shelf2_y
		["aisle_produce",   "AISLE 1 - PRODUCE",     4,   5,   9],
		["aisle_dairy",     "AISLE 2 - DAIRY",       24,   5,   9],
		["aisle_drinks",    "AISLE 3 - DRINKS",      44,   5,   9],
		["aisle_bakery",    "AISLE 4 - BAKERY",      64,   5,   9],
		["aisle_snacks",    "AISLE 5 - SNACKS",       4,  20,  24],
		["aisle_meat",      "AISLE 6 - MEAT",        24,  20,  24],
		["aisle_deli",      "AISLE 7 - DELI",        44,  20,  24],
		["aisle_frozen",    "AISLE 8 - FROZEN",      64,  20,  24],
		["aisle_pantry",    "AISLE 9 - PANTRY",       4,  35,  39],
		["aisle_hbc",       "AISLE 10 - HEALTH",      24,  35,  39],
		["aisle_household", "AISLE 11 - HOUSEHOLD",  44,  35,  39],
		["aisle_baby",      "AISLE 12 - BABY",       64,  35,  39],
	]

	for cfg in aisle_configs:
		var aisle_id: String = cfg[0]
		var aisle_name: String = cfg[1]
		var sx: int = cfg[2]    # start x (cell)
		var y1: int = cfg[3]    # shelf row 1 y (cell)
		var y2: int = cfg[4]    # shelf row 2 y (cell)

		var products: Array = ProductData.get_aisle_products(aisle_id)

		# Build slot positions - 10 slots per shelf row
		var slots1: Array[Vector2i] = []
		var slots2: Array[Vector2i] = []
		for i in range(10):
			slots1.append(Vector2i(sx + i * 2, y1))
			slots2.append(Vector2i(sx + i * 2, y2))

		# Shelf visual (background) - spanning the whole aisle (10 slots × 2 cells = 20 cells wide)
		var shelf_bg := Sprite2D.new()
		var bg_tex := _make_shelf_background(20 * CELL_SIZE, CELL_SIZE)
		shelf_bg.texture = bg_tex
		shelf_bg.position = Vector2(sx * CELL_SIZE, y1 * CELL_SIZE)
		shelf_bg.z_index = -2
		add_child(shelf_bg)

		var shelf_bg2 := Sprite2D.new()
		shelf_bg2.texture = bg_tex
		shelf_bg2.position = Vector2(sx * CELL_SIZE, y2 * CELL_SIZE)
		shelf_bg2.z_index = -2
		add_child(shelf_bg2)

		# Aisle sign above shelf row 1
		var sign := _make_aisle_sign(aisle_name)
		sign.position = Vector2(sx * CELL_SIZE, (y1 - 2) * CELL_SIZE)
		add_child(sign)

		# Create aisle nodes (for interaction - each shelf cell is a slot)
		var all_slots: Array[Vector2i] = []
		all_slots.append_array(slots1)
		all_slots.append_array(slots2)

		var aisle := SupermarketAisle.new()
		aisle.name = aisle_id
		# Merge products for both rows
		var all_products: Array = []
		all_products.append_array(products)
		all_products.append_array(products)
		aisle.setup(aisle_id, aisle_name, all_products, all_slots)
		aisle.position = Vector2.ZERO
		add_child(aisle)

		# Add collision shapes for shelves
		_add_shelf_collision(sx, y1, 20, 1)
		_add_shelf_collision(sx, y2, 20, 1)

func _make_shelf_background(w: float, h: float) -> Texture2D:
	var img := Image.create(int(w), int(h), false, Image.FORMAT_RGBA8)
	var wood := Color(0.42, 0.36, 0.28)
	img.fill(wood)
	var hi := Color(0.52, 0.45, 0.35)
	var lo := Color(0.30, 0.26, 0.20)
	for x in range(0, int(w)):
		img.set_pixel(x, 0, hi)
		img.set_pixel(x, int(h) - 1, lo)
	return ImageTexture.create_from_image(img)

func _make_aisle_sign(text: String) -> Sprite2D:
	# Create a simple sign board texture
	var img := Image.create(80, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.25, 0.22, 0.30))
	var border := Color(0.55, 0.50, 0.62)
	for x in range(0, 80):
		img.set_pixel(x, 0, border)
		img.set_pixel(x, 11, border)
	for y in range(0, 12):
		img.set_pixel(0, y, border)
		img.set_pixel(79, y, border)
	var tex := ImageTexture.create_from_image(img)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	return sprite

func _add_shelf_collision(gx: int, gy: int, w: int, h: int) -> void:
	var body := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w * CELL_SIZE, h * CELL_SIZE)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = Vector2(gx * CELL_SIZE + w * CELL_SIZE / 2, gy * CELL_SIZE + h * CELL_SIZE / 2)
	body.add_child(cs)
	body.z_index = -1
	add_child(body)

func _build_checkout() -> void:
	# 4 checkout lanes spread across the bottom
	var checkout_x_positions := [4, 24, 44, 64]
	for i in range(checkout_x_positions.size()):
		var cx: int = checkout_x_positions[i]
		var counter := CheckoutCounter.new()
		counter.setup(i, Vector2i(cx, 41))
		add_child(counter)
		# Collision: 2 cells wide, 1 cell tall
		_add_shelf_collision(cx, 41, 2, 1)
	
	# Checkout area label
	var sign := _make_aisle_sign("CHECKOUT")
	sign.position = Vector2(4 * CELL_SIZE, 39 * CELL_SIZE)
	add_child(sign)

const NPC_COUNT := 8

func _spawn_npcs() -> void:
	# Spawn AI customers wandering the store
	var npc_tints: Array[Color] = [
		Color(1.0, 1.0, 1.0),
		Color(1.0, 0.9, 0.85),
		Color(0.9, 0.95, 1.0),
		Color(0.9, 1.0, 0.9),
	]
	
	for i in range(NPC_COUNT):
		var npc := NPCController.new()
		npc.name = "NPC%d" % i
		# Spread starting positions across the store
		var start_x: float = (8 + (i % 4) * 18) * CELL_SIZE
		var start_y: float = (6 + (i / 4) * 18) * CELL_SIZE
		npc.position = Vector2(start_x, start_y)
		# Apply tint for variety
		var tint: Color = npc_tints[i % npc_tints.size()]
		npc.set_color_tint(tint)
		add_child(npc)

func _spawn_player() -> void:
	_player = Player.new()
	_player.name = "Player"
	# Start near entrance (top-center of map)
	_player.position = Vector2((WORLD_W / 2) * CELL_SIZE, 3 * CELL_SIZE)
	add_child(_player)
	_player.set_world(self)

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "Camera"
	_camera.zoom = Vector2(3.0, 3.0)  # 3× zoom for pixel art feel
	_camera.position = _player.position
	_camera.position_smoothing_speed = 8.0
	_camera.position_smoothing_enabled = true
	add_child(_camera)

func _setup_hud() -> void:
	_hud = HUD.new()
	_hud.name = "HUD"
	add_child(_hud)

func _connect_signals() -> void:
	_player.cart_count_changed.connect(_on_cart_count_changed)
	_player.interact_prompt_changed.connect(_on_interact_prompt_changed)
	_player.checkout_available.connect(_on_checkout_available)
	_hud.tab_pressed.connect(_on_tab_pressed)
	_hud.checkout_complete.connect(_on_checkout_complete)

func _process(_delta: float) -> void:
	if _camera != null and _player != null:
		_camera.position = _camera.position.lerp(_player.position, 0.12)
	_update_zone_label()

func _update_zone_label() -> void:
	if _player == null or _hud == null:
		return

	var zone := _detect_zone(_player.global_position)
	if zone != _current_zone:
		_current_zone = zone
		_hud.update_zone(zone)

func _detect_zone(pos: Vector2) -> String:
	var cell_y := int(floor(pos.y / CELL_SIZE))
	var cell_x := int(floor(pos.x / CELL_SIZE))

	# Match zone by y-range then x-range (same layout as aisle_configs)
	var zones := [
		["AISLE 1 - PRODUCE",   4,  5,  9],
		["AISLE 2 - DAIRY",     24,  5,  9],
		["AISLE 3 - DRINKS",    44,  5,  9],
		["AISLE 4 - BAKERY",    64,  5,  9],
		["AISLE 5 - SNACKS",    4,  20, 24],
		["AISLE 6 - MEAT",      24, 20, 24],
		["AISLE 7 - DELI",      44, 20, 24],
		["AISLE 8 - FROZEN",    64, 20, 24],
		["AISLE 9 - PANTRY",    4,  35, 39],
		["AISLE 10 - HEALTH",    24, 35, 39],
		["AISLE 11 - HOUSEHOLD",44, 35, 39],
		["AISLE 12 - BABY",     64, 35, 39],
	]
	for z in zones:
		var name: String = z[0]
		var sx: int = z[1]
		var y1: int = z[2]
		var y2: int = z[3]
		if cell_y >= y1 and cell_y <= y2 and cell_x >= sx and cell_x < sx + 20:
			return name

	if cell_y >= 41:
		return "CHECKOUT"
	if cell_y <= 4:
		return "ENTRANCE"
	return ""

func _on_cart_count_changed(count: int) -> void:
	if _hud:
		_hud.update_cart_badge(count)

func _on_interact_prompt_changed(prompt: String) -> void:
	if _hud:
		_hud.update_interact_prompt(prompt)

func _on_checkout_available() -> void:
	if _hud:
		_hud.show_checkout(_player.get_cart())

func _on_tab_pressed() -> void:
	if _hud:
		_hud.show_cart(_player.get_cart())

func _on_checkout_complete() -> void:
	if _player != null:
		_player.get_cart().clear()
	if _hud != null:
		_hud.hide_checkout()
