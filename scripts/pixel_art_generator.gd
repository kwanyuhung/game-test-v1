class_name PixelArtGenerator
extends Node
# pixel_art_generator.gd
# Generates pixel art textures programmatically — no external assets needed.
const StoreData = preload("res://scripts/store_data.gd")
# All sprites are 16×16 or 8×8 depending on usage.


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

# Convenience method for generating product sprites without a MarketProduct object
static func make_product_texture(col: Color, shape: int, tex_size: int = 16) -> Texture2D:
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
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
# SHOE SPRITES (16x16)
# ─────────────────────────────────────────────────────────────────────────────
static func make_shoe(col: Color, style: int = 0) -> Texture2D:
	# style: 0=sneaker, 1=formal, 2=sandal, 3=boot
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match style:
		0: _draw_sneaker(img, col)      # Sneaker
		1: _draw_formal_shoe(img, col)  # Formal shoe
		2: _draw_sandal(img, col)       # Sandal
		3: _draw_boot(img, col)         # Boot
		_: _draw_sneaker(img, col)
	return ImageTexture.create_from_image(img)

static func _draw_sneaker(img: Image, col: Color) -> void:
	var dark := col.darkened(0.3)
	var light := col.lightened(0.2)
	_fill_rect(img, 2, 10, 12, 4, dark)       # sole
	_fill_rect(img, 2, 12, 12, 2, Color(0.15, 0.15, 0.15))  # outsole
	_fill_rect(img, 3, 6, 10, 5, col)         # upper
	_fill_rect(img, 4, 7, 8, 3, light)        # tongue
	_fill_rect(img, 2, 6, 2, 4, dark)         # toe cap
	_fill_rect(img, 11, 6, 3, 3, dark)        # heel
	_set_pixel(img, 5, 8, Color.WHITE)         # lace

static func _draw_formal_shoe(img: Image, col: Color) -> void:
	var dark := col.darkened(0.4)
	_fill_rect(img, 2, 11, 12, 3, dark)      # sole
	_fill_rect(img, 2, 13, 12, 1, Color(0.1, 0.1, 0.1))  # outsole
	_fill_rect(img, 3, 7, 10, 5, col)         # upper
	_fill_rect(img, 2, 9, 12, 2, dark)        # seam
	_fill_rect(img, 4, 6, 8, 2, col.lightened(0.15))  # vamp

static func _draw_sandal(img: Image, col: Color) -> void:
	var dark := col.darkened(0.3)
	_fill_rect(img, 3, 12, 10, 2, Color(0.12, 0.10, 0.08))  # sole
	_fill_rect(img, 4, 8, 8, 1, dark)        # strap
	_fill_rect(img, 5, 6, 2, 4, dark)        # left post
	_fill_rect(img, 9, 6, 2, 4, dark)        # right post
	_fill_rect(img, 4, 11, 8, 2, col)         # footbed

static func _draw_boot(img: Image, col: Color) -> void:
	var dark := col.darkened(0.35)
	var light := col.lightened(0.15)
	_fill_rect(img, 3, 12, 10, 2, Color(0.1, 0.08, 0.06))  # outsole
	_fill_rect(img, 2, 8, 12, 5, dark)       # boot body
	_fill_rect(img, 3, 4, 10, 5, col)        # upper boot
	_fill_rect(img, 4, 5, 8, 3, light)       # shaft highlight
	_fill_rect(img, 3, 3, 10, 2, dark)       # boot top rim

# ─────────────────────────────────────────────────────────────────────────────
# CLOTHING SPRITES (16x16)
# ─────────────────────────────────────────────────────────────────────────────
static func make_clothing(col: Color, style: int = 0) -> Texture2D:
	# style: 0=dress, 1=tshirt, 2=pants, 3=jacket
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match style:
		0: _draw_dress(img, col)      # Dress
		1: _draw_tshirt(img, col)     # T-shirt
		2: _draw_pants(img, col)      # Pants
		3: _draw_jacket(img, col)     # Jacket
		_: _draw_tshirt(img, col)
	return ImageTexture.create_from_image(img)

static func _draw_dress(img: Image, col: Color) -> void:
	var dark := col.darkened(0.2)
	var light := col.lightened(0.2)
	_fill_rect(img, 5, 2, 6, 2, col)         # shoulders/top
	_fill_rect(img, 4, 4, 8, 2, col)         # bodice
	_fill_rect(img, 3, 6, 10, 6, col)         # skirt start
	_fill_rect(img, 2, 10, 12, 4, dark)      # skirt bottom
	_set_pixel(img, 7, 3, light)              # neckline detail

static func _draw_tshirt(img: Image, col: Color) -> void:
	var dark := col.darkened(0.15)
	var light := col.lightened(0.2)
	_fill_rect(img, 5, 2, 6, 2, col)         # neck
	_fill_rect(img, 4, 4, 8, 8, col)         # torso
	_fill_rect(img, 1, 4, 3, 5, col)         # left sleeve
	_fill_rect(img, 12, 4, 3, 5, col)         # right sleeve
	_fill_rect(img, 5, 2, 6, 1, dark)         # collar
	_fill_rect(img, 6, 6, 4, 1, light)       # chest stripe

static func _draw_pants(img: Image, col: Color) -> void:
	var dark := col.darkened(0.2)
	_fill_rect(img, 4, 2, 8, 3, col)         # waistband
	_fill_rect(img, 4, 5, 3, 7, col)          # left leg
	_fill_rect(img, 9, 5, 3, 7, col)          # right leg
	_fill_rect(img, 4, 5, 8, 1, dark)          # waistband shadow
	_fill_rect(img, 4, 11, 3, 1, dark)        # left hem
	_fill_rect(img, 9, 11, 3, 1, dark)        # right hem

static func _draw_jacket(img: Image, col: Color) -> void:
	var dark := col.darkened(0.25)
	var light := col.lightened(0.15)
	_fill_rect(img, 4, 2, 8, 10, col)         # body
	_fill_rect(img, 1, 3, 3, 6, col)          # left sleeve
	_fill_rect(img, 12, 3, 3, 6, col)         # right sleeve
	_fill_rect(img, 5, 2, 2, 10, dark)        # left front panel
	_fill_rect(img, 9, 2, 2, 10, dark)        # right front panel
	_fill_rect(img, 6, 4, 1, 6, Color(0.6, 0.6, 0.65))  # zipper

# ─────────────────────────────────────────────────────────────────────────────
# SPORTS EQUIPMENT SPRITES (16x16)
# ─────────────────────────────────────────────────────────────────────────────
static func make_sports_equipment(col: Color, style: int = 0) -> Texture2D:
	# style: 0=dumbbell, 1=ball, 2=yogamat, 3=racket
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match style:
		0: _draw_dumbbell(img, col)     # Dumbbell
		1: _draw_ball(img, col)         # Sports ball
		2: _draw_yogamat(img, col)      # Yoga mat roll
		3: _draw_racket(img, col)       # Tennis racket
		4: _draw_bicycle_helmet(img, col)  # Helmet
		_: _draw_dumbbell(img, col)
	return ImageTexture.create_from_image(img)

# ─────────────────────────────────────────────────────────────────────────────
# ELEVATOR SPRITES (224x160 = 14x10 cells at 16px each)
# ─────────────────────────────────────────────────────────────────────────────
static func make_elevator_car() -> Texture2D:
	# Elevator car interior without doors (doors are animated separately)
	var img := Image.create(224, 160, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Colors
	var wall_col := Color(0.48, 0.44, 0.40)      # Main wall color
	var inner_col := Color(0.60, 0.56, 0.52)     # Inner floor/wall
	var light_col := Color(0.95, 0.92, 0.80)      # Ceiling light strip
	var dark_col := Color(0.30, 0.28, 0.25)       # Dark trim
	var floor_col := Color(0.50, 0.48, 0.45)      # Floor tiles
	var rail_col := Color(0.70, 0.68, 0.65)       # Hand rails
	
	# Outer wall border (4px)
	_fill_rect(img, 0, 0, 224, 160, wall_col)
	
	# Inner area (cut out the outer wall)
	_fill_rect(img, 4, 4, 216, 152, inner_col)
	
	# Floor (bottom 20px of inner area)
	_fill_rect(img, 4, 136, 216, 20, floor_col)
	
	# Floor tile lines
	for x in range(8, 220, 32):
		_fill_rect(img, x, 136, 2, 20, dark_col)
	for y in range(140, 156, 16):
		_fill_rect(img, 4, y, 216, 2, dark_col)
	
	# Ceiling light strip
	_fill_rect(img, 8, 8, 208, 6, light_col)
	
	# Dark ceiling edge above light
	_fill_rect(img, 4, 4, 216, 4, dark_col)
	
	# Door frame (dark opening where doors slide)
	_fill_rect(img, 8, 20, 208, 116, Color(0.25, 0.22, 0.20))
	
	# Wall texture - vertical panels
	_fill_rect(img, 20, 24, 2, 100, dark_col.lightened(0.05))
	_fill_rect(img, 200, 24, 2, 100, dark_col.lightened(0.05))
	
	# Hand rail on left wall
	_fill_rect(img, 10, 70, 4, 40, rail_col)
	_fill_rect(img, 10, 68, 4, 4, Color(0.75, 0.72, 0.70))
	_fill_rect(img, 10, 108, 4, 4, Color(0.75, 0.72, 0.70))
	
	# Hand rail on right wall  
	_fill_rect(img, 210, 70, 4, 40, rail_col)
	_fill_rect(img, 210, 68, 4, 4, Color(0.75, 0.72, 0.70))
	_fill_rect(img, 210, 108, 4, 4, Color(0.75, 0.72, 0.70))
	
	# Back wall panel details
	_fill_rect(img, 100, 24, 24, 100, dark_col.lightened(0.03))
	_fill_rect(img, 104, 28, 16, 92, Color(0.42, 0.40, 0.38))
	
	return ImageTexture.create_from_image(img)

static func make_elevator_door() -> Texture2D:
	# Single elevator door panel (slides open/closed)
	var img := Image.create(96, 116, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var door_col := Color(0.55, 0.52, 0.50)      # Door panels
	var dark_col := Color(0.30, 0.28, 0.25)       # Dark trim
	
	# Main door panel
	_fill_rect(img, 0, 0, 96, 116, door_col)
	
	# Door panels (horizontal lines for decoration)
	_fill_rect(img, 0, 30, 96, 2, dark_col)
	_fill_rect(img, 0, 60, 96, 2, dark_col)
	_fill_rect(img, 0, 90, 96, 2, dark_col)
	
	# Door handle
	_fill_rect(img, 42, 52, 12, 8, dark_col.lightened(0.1))
	_fill_rect(img, 44, 54, 8, 4, Color(0.60, 0.58, 0.55))
	
	# Highlight edge
	_fill_rect(img, 0, 0, 2, 116, Color(0.62, 0.60, 0.58))
	_fill_rect(img, 94, 0, 2, 116, dark_col)
	
	return ImageTexture.create_from_image(img)

static func make_elevator_shaft() -> Texture2D:
	# Vertical shaft texture (32px wide, full height)
	var img := Image.create(32, 512, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var shaft_col := Color(0.28, 0.25, 0.22)
	var dark_col := Color(0.20, 0.18, 0.16)
	var cable_col := Color(0.35, 0.32, 0.30)
	
	# Main shaft background
	_fill_rect(img, 0, 0, 32, 512, shaft_col)
	
	# Dark edges (left and right rails)
	_fill_rect(img, 0, 0, 4, 512, dark_col)
	_fill_rect(img, 28, 0, 4, 512, dark_col)
	
	# Center cable
	_fill_rect(img, 14, 0, 4, 512, cable_col)
	
	# Cable segments (horizontal lines every 64px to simulate cable links)
	for y in range(0, 512, 64):
		_fill_rect(img, 12, y, 8, 3, dark_col)
	
	# Floor indicators (floor markers at every 160px = 10 cells)
	for i in range(4):
		var y := 32 + i * 160
		# Small indicator light
		_fill_rect(img, 13, y, 6, 4, Color(0.20, 0.95, 0.50))
	
	return ImageTexture.create_from_image(img)

static func _draw_dumbbell(img: Image, col: Color) -> void:
	var dark := col.darkened(0.3)
	var light := col.lightened(0.2)
	_fill_rect(img, 1, 6, 3, 4, dark)         # left weight
	_fill_rect(img, 12, 6, 3, 4, dark)         # right weight
	_fill_rect(img, 4, 7, 8, 2, Color(0.5, 0.5, 0.52))  # bar
	_fill_rect(img, 2, 5, 2, 6, light)        # left cap
	_fill_rect(img, 12, 5, 2, 6, light)       # right cap

static func _draw_ball(img: Image, col: Color) -> void:
	var dark := col.darkened(0.2)
	var light := col.lightened(0.3)
	_fill_rect(img, 5, 5, 6, 6, col)
	_fill_rect(img, 4, 6, 8, 4, col)
	_fill_rect(img, 6, 4, 4, 8, col)
	_fill_rect(img, 5, 5, 2, 2, light)
	_fill_rect(img, 6, 6, 1, 1, dark)         # seam

static func _draw_yogamat(img: Image, col: Color) -> void:
	var dark := col.darkened(0.25)
	var light := col.lightened(0.15)
	_fill_rect(img, 2, 8, 12, 5, col)         # main roll
	_fill_rect(img, 2, 8, 12, 2, light)       # top highlight
	_fill_rect(img, 2, 12, 12, 1, dark)       # bottom shadow
	_fill_rect(img, 13, 9, 2, 3, col.darkened(0.1))  # roll end

static func _draw_racket(img: Image, col: Color) -> void:
	var dark := Color(0.6, 0.55, 0.5)
	_fill_rect(img, 6, 2, 4, 8, col)          # frame oval
	_fill_rect(img, 7, 3, 2, 6, Color(0.9, 0.9, 0.9))  # strings
	_fill_rect(img, 7, 10, 2, 5, dark)         # handle
	_fill_rect(img, 6, 14, 4, 1, dark)         # grip

static func _draw_bicycle_helmet(img: Image, col: Color) -> void:
	var dark := col.darkened(0.3)
	var light := col.lightened(0.2)
	_fill_rect(img, 3, 5, 10, 7, col)         # dome
	_fill_rect(img, 2, 8, 12, 4, col)          # rim
	_fill_rect(img, 4, 4, 8, 2, light)         # top highlight
	_fill_rect(img, 2, 10, 12, 2, dark)        # bottom rim

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
