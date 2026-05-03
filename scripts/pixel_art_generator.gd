# pixel_art_generator.gd
# Generates pixel art textures programmatically — no external assets needed.
const StoreData = preload("res://scripts/store_data.gd")
# All sprites are 16×16 or 8×8 depending on usage.

class_name PixelArtGenerator
extends Node

const SIZE := 16  # Main sprite size
const HALF := SIZE / 2

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC: Generate a product sprite at 16×16
# ─────────────────────────────────────────────────────────────────────────────
static func make_product(tex_size: int, product: StoreData.MarketProduct) -> Texture2D:
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # transparent bg
	
	var col := product.color
	var shape: int = product.shape
	
	if tex_size == 16:
		_draw_product_16(img, col, shape)
	elif tex_size == 8:
		_draw_product_8(img, col, shape)
	
	var tex := ImageTexture.create_from_image(img)
	return tex

static func _draw_product_16(img: Image, col: Color, shape: int) -> void:
	match shape:
		0:  # round (apple, cherry, grape, etc.)
			_fill_rect(img, 6, 4, 4, 4, col.darkened(0.2))
			_fill_rect(img, 5, 5, 6, 5, col)
			_fill_rect(img, 4, 6, 8, 4, col)
			_fill_rect(img, 5, 10, 6, 2, col.darkened(0.15))
			_set_pixel(img, 6, 5, col.lightened(0.35))
			_set_pixel(img, 7, 5, col.lightened(0.2))
		1:  # rectangle (bread, chips, cheese, deli)
			_fill_rect(img, 3, 4, 10, 2, col.darkened(0.25))
			_fill_rect(img, 2, 6, 12, 6, col)
			_fill_rect(img, 2, 12, 12, 2, col.darkened(0.15))
			_fill_rect(img, 3, 8, 10, 3, col.darkened(0.12))
			_set_pixel(img, 5, 9, col.lightened(0.3))
		2:  # bottle/can (drinks, small bottles)
			_fill_rect(img, 5, 2, 6, 2, col.darkened(0.2))
			_fill_rect(img, 4, 4, 8, 8, col)
			_fill_rect(img, 5, 12, 6, 2, col.darkened(0.15))
			_fill_rect(img, 5, 6, 6, 3, col.darkened(0.08))
			_set_pixel(img, 5, 5, col.lightened(0.3))
		3:  # box (cereal, cake, pie box)
			_fill_rect(img, 3, 3, 10, 2, col.darkened(0.25))
			_fill_rect(img, 2, 5, 12, 8, col)
			_fill_rect(img, 2, 13, 12, 1, col.darkened(0.2))
			_fill_rect(img, 4, 7, 8, 4, col.darkened(0.1))
		4:  # tub (yogurt, ice cream, deli salads)
			_fill_rect(img, 4, 4, 8, 1, col.darkened(0.2))
			_fill_rect(img, 3, 5, 10, 8, col)
			_fill_rect(img, 3, 13, 10, 1, col.darkened(0.2))
			_fill_rect(img, 4, 6, 8, 4, col.darkened(0.08))
			_set_pixel(img, 5, 5, col.lightened(0.3))
		5:  # tall bottle (olive oil, soy sauce, wine, medicine)
			_fill_rect(img, 5, 1, 6, 2, col.darkened(0.2))
			_fill_rect(img, 4, 3, 8, 9, col)
			_fill_rect(img, 4, 12, 8, 1, col.darkened(0.15))
			_fill_rect(img, 5, 14, 6, 1, col.darkened(0.25))
			_fill_rect(img, 5, 5, 6, 4, col.darkened(0.07))
			_set_pixel(img, 5, 4, col.lightened(0.35))
		6:  # flat pack (paper products, diapers, crackers)
			_fill_rect(img, 2, 5, 12, 1, col.darkened(0.2))
			_fill_rect(img, 1, 6, 14, 5, col)
			_fill_rect(img, 1, 11, 14, 1, col.darkened(0.25))
			_fill_rect(img, 2, 7, 10, 3, col.darkened(0.1))
			_set_pixel(img, 3, 7, col.lightened(0.3))

static func _draw_product_8(img: Image, col: Color, shape: int) -> void:
	match shape:
		0:  # tiny round
			_fill_rect(img, 2, 2, 4, 4, col.darkened(0.2))
			_fill_rect(img, 1, 3, 6, 3, col)
			_fill_rect(img, 2, 6, 4, 1, col.darkened(0.15))
		1:  # tiny rect
			_fill_rect(img, 1, 2, 6, 5, col)
			_fill_rect(img, 1, 6, 6, 1, col.darkened(0.2))
		2:  # tiny bottle
			_fill_rect(img, 2, 1, 4, 1, col.darkened(0.2))
			_fill_rect(img, 1, 2, 6, 5, col)
			_fill_rect(img, 2, 7, 4, 1, col.darkened(0.15))
		3:  # tiny box
			_fill_rect(img, 1, 1, 6, 6, col)
			_fill_rect(img, 1, 6, 6, 1, col.darkened(0.2))
		4:  # tiny tub
			_fill_rect(img, 1, 2, 6, 1, col.darkened(0.2))
			_fill_rect(img, 1, 3, 6, 4, col)
			_fill_rect(img, 1, 7, 6, 1, col.darkened(0.2))
		5:  # tiny tall bottle
			_fill_rect(img, 2, 0, 4, 1, col.darkened(0.2))
			_fill_rect(img, 1, 1, 6, 6, col)
			_fill_rect(img, 2, 7, 4, 1, col.darkened(0.2))
		6:  # tiny flat pack
			_fill_rect(img, 1, 2, 6, 1, col.darkened(0.2))
			_fill_rect(img, 0, 3, 8, 3, col)
			_fill_rect(img, 0, 6, 8, 1, col.darkened(0.2))

# ─────────────────────────────────────────────────────────────────────────────
# PLAYER sprite  (16×16, warm yellow figure)
# ─────────────────────────────────────────────────────────────────────────────
static func make_player(tex_size: int = 16) -> Texture2D:
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var body  := Color(0.91, 0.76, 0.44)   # warm tan
	var dark  := body.darkened(0.3)
	var light := body.lightened(0.3)
	
	if tex_size == 16:
		# head
		_fill_rect(img, 5, 1, 6, 2, body)
		_fill_rect(img, 4, 3, 8, 4, body)
		# body
		_fill_rect(img, 4, 7, 8, 6, body.darkened(0.1))
		_fill_rect(img, 5, 7, 6, 6, body)
		# arms
		_fill_rect(img, 2, 7, 2, 4, body)
		_fill_rect(img, 12, 7, 2, 4, body)
		# legs
		_fill_rect(img, 5, 13, 2, 3, dark)
		_fill_rect(img, 9, 13, 2, 3, dark)
		# eyes
		_set_pixel(img, 6, 4, Color.BLACK)
		_set_pixel(img, 9, 4, Color.BLACK)
		# highlight on head
		_set_pixel(img, 6, 2, light)
		_set_pixel(img, 7, 2, light)
	
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────────────────────
# SHOPPING CART sprite (20×16)
# ─────────────────────────────────────────────────────────────────────────────
static func make_cart() -> Texture2D:
	var img := Image.create(20, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var metal := Color(0.75, 0.75, 0.78)
	var dark  := metal.darkened(0.35)
	var light := metal.lightened(0.2)
	
	# cart body
	_fill_rect(img, 2, 3, 16, 9, metal)
	_fill_rect(img, 2, 3, 16, 2, light)
	_fill_rect(img, 2, 11, 16, 1, dark)
	_fill_rect(img, 2, 3, 1, 9, dark)
	_fill_rect(img, 17, 3, 1, 9, dark)
	# wire mesh lines
	_fill_rect(img, 6, 3, 1, 9, dark)
	_fill_rect(img, 10, 3, 1, 9, dark)
	_fill_rect(img, 14, 3, 1, 9, dark)
	_fill_rect(img, 2, 7, 16, 1, dark)
	# handle
	_fill_rect(img, 18, 2, 2, 3, dark)
	_fill_rect(img, 19, 1, 1, 2, metal)
	# wheels
	_fill_rect(img, 3, 13, 3, 3, dark)
	_fill_rect(img, 14, 13, 3, 3, dark)
	_fill_rect(img, 4, 14, 1, 1, light)
	_fill_rect(img, 15, 14, 1, 1, light)
	
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────────────────────
# SHELF UNIT sprite (one shelf cell, 16×16)
# ─────────────────────────────────────────────────────────────────────────────
static func make_shelf() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var wood    := Color(0.54, 0.45, 0.33)
	var wood_hi := Color(0.63, 0.53, 0.40)
	var wood_sh := Color(0.42, 0.35, 0.26)
	
	_fill_rect(img, 0, 0, 16, 16, wood)
	_fill_rect(img, 0, 0, 16, 2, wood_hi)
	_fill_rect(img, 0, 14, 16, 2, wood_sh)
	# vertical dividers hint
	_set_pixel(img, 4, 2, wood_sh)
	_set_pixel(img, 8, 2, wood_sh)
	_set_pixel(img, 12, 2, wood_sh)
	
	return ImageTexture.create_from_image(img)

static func make_shelf_empty() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var shadow := Color(0.25, 0.22, 0.18)
	_fill_rect(img, 0, 0, 16, 16, shadow)
	_fill_rect(img, 1, 1, 14, 14, Color(0.18, 0.16, 0.14))
	
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────────────────────
# CHECKOUT DESK
# ─────────────────────────────────────────────────────────────────────────────
static func make_checkout_desk() -> Texture2D:
	var img := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var desk  := Color(0.48, 0.42, 0.54)
	var hi    := desk.lightened(0.2)
	var sh    := desk.darkened(0.25)
	
	_fill_rect(img, 0, 0, 32, 16, desk)
	_fill_rect(img, 0, 0, 32, 3, hi)
	_fill_rect(img, 0, 13, 32, 3, sh)
	# register
	_fill_rect(img, 22, 3, 8, 10, sh)
	_fill_rect(img, 23, 4, 6, 8, Color(0.28, 0.28, 0.32))
	_fill_rect(img, 24, 5, 4, 4, Color(0.18, 0.68, 0.48))  # screen
	# conveyor belt
	_fill_rect(img, 1, 6, 20, 6, sh)
	_fill_rect(img, 2, 7, 18, 4, Color(0.30, 0.30, 0.34))
	
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────────────────────
# FLOOR TILE
# ─────────────────────────────────────────────────────────────────────────────
static func make_floor_tile() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.165, 0.165, 0.18))
	# subtle grid
	var line := Color(0.21, 0.21, 0.23)
	_fill_rect(img, 0, 0, 16, 1, line)
	_fill_rect(img, 0, 0, 1, 16, line)
	return ImageTexture.create_from_image(img)

static func make_floor_tile_alt() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.18, 0.20))
	var line := Color(0.22, 0.22, 0.24)
	_fill_rect(img, 0, 0, 16, 1, line)
	_fill_rect(img, 0, 0, 1, 16, line)
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────────────────────
# WALL
# ─────────────────────────────────────────────────────────────────────────────
static func make_wall() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.32, 0.28, 0.35))
	var hi := Color(0.40, 0.36, 0.44)
	var sh := Color(0.22, 0.19, 0.25)
	_fill_rect(img, 0, 0, 16, 2, hi)
	_fill_rect(img, 0, 14, 16, 2, sh)
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────────────────────
# Helper drawing primitives
# ─────────────────────────────────────────────────────────────────────────────
static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, img.get_width())
	y = clampi(y, 0, img.get_height())
	w = mini(w, img.get_width() - x)
	h = mini(h, img.get_height() - y)
	if w <= 0 or h <= 0:
		return
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

static func _set_pixel(img: Image, x: int, y: int, col: Color) -> void:
	if x < 0 or x >= img.get_width() or y < 0 or y >= img.get_height():
		return
	img.set_pixel(x, y, col)
