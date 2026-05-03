# npc_sprite.gd
# Generates randomized pixel art NPC sprites from body-part palettes.
# Each NPC has 3 layers: head, upper body, lower body.
# All 16×16, fully programmatic — no external files.

class_name NPCSprite
extends Node

const SKIN_TONES := [
	Color(0.96, 0.80, 0.65),
	Color(0.88, 0.68, 0.48),
	Color(0.72, 0.52, 0.38),
	Color(0.55, 0.38, 0.28),
	Color(0.42, 0.30, 0.22),
]

const HAIR_COLORS := [
	Color(0.18, 0.12, 0.08),
	Color(0.62, 0.42, 0.22),
	Color(0.92, 0.72, 0.35),
	Color(0.78, 0.32, 0.18),
	Color(0.28, 0.22, 0.18),
	Color(0.18, 0.28, 0.18),
]

const SHIRT_COLORS := [
	Color(0.28, 0.42, 0.78),
	Color(0.78, 0.28, 0.28),
	Color(0.28, 0.68, 0.42),
	Color(0.88, 0.68, 0.28),
	Color(0.68, 0.28, 0.68),
	Color(0.88, 0.88, 0.88),
	Color(0.42, 0.42, 0.48),
	Color(0.82, 0.58, 0.28),
	Color(0.28, 0.62, 0.78),
	Color(0.88, 0.38, 0.28),
]

const PANTS_COLORS := [
	Color(0.22, 0.22, 0.42),
	Color(0.42, 0.38, 0.32),
	Color(0.32, 0.38, 0.52),
	Color(0.22, 0.32, 0.22),
	Color(0.18, 0.18, 0.18),
	Color(0.58, 0.52, 0.45),
	Color(0.82, 0.28, 0.18),
]

var _skin: Color
var _hair: Color
var _shirt: Color
var _pants: Color
var _head_type: int
var _hair_type: int
var _shirt_type: int
var _pants_type: int

func _init() -> void:
	_skin = SKIN_TONES[randi() % SKIN_TONES.size()]
	_hair = HAIR_COLORS[randi() % HAIR_COLORS.size()]
	_shirt = SHIRT_COLORS[randi() % SHIRT_COLORS.size()]
	_pants = PANTS_COLORS[randi() % PANTS_COLORS.size()]
	_head_type = randi() % 4
	_hair_type = randi() % 4
	_shirt_type = randi() % 3
	_pants_type = randi() % 3

func get_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_shadow(img)
	_draw_lower_body(img)
	_draw_upper_body(img)
	_draw_head(img)
	_draw_hair(img)
	return ImageTexture.create_from_image(img)

func _draw_shadow(img: Image) -> void:
	var sh := Color(0, 0, 0, 0.18)
	_fill_img(img, 4, 14, 8, 2, sh)

func _draw_lower_body(img: Image) -> void:
	match _pants_type:
		0:
			_fill_img(img, 1, 10, 5, 2, _pants.darkened(0.15))
			_fill_img(img, 2, 11, 3, 3, _pants)
			_fill_img(img, 10, 11, 3, 3, _pants)
			_fill_img(img, 3, 12, 2, 2, _pants.darkened(0.1))
			_fill_img(img, 10, 12, 2, 2, _pants.darkened(0.1))
		1:
			_fill_img(img, 2, 10, 5, 2, _pants)
			_fill_img(img, 9, 10, 5, 2, _pants)
			_fill_img(img, 3, 11, 2, 3, _pants.darkened(0.1))
			_fill_img(img, 10, 11, 2, 3, _pants.darkened(0.1))
		2:
			_fill_img(img, 3, 10, 10, 1, _pants.darkened(0.1))
			_fill_img(img, 2, 11, 12, 3, _pants)
			_fill_img(img, 1, 13, 14, 1, _pants.darkened(0.2))

func _draw_upper_body(img: Image) -> void:
	match _shirt_type:
		0:
			_fill_img(img, 3, 6, 10, 5, _shirt.darkened(0.1))
			_fill_img(img, 4, 7, 8, 4, _shirt)
			_fill_img(img, 1, 7, 2, 3, _shirt)
			_fill_img(img, 13, 7, 2, 3, _shirt)
			_fill_img(img, 5, 6, 6, 1, _shirt.lightened(0.15))
		1:
			_fill_img(img, 3, 6, 10, 5, _shirt)
			_fill_img(img, 4, 7, 8, 4, _shirt)
			_fill_img(img, 1, 7, 2, 3, _shirt.darkened(0.1))
			_fill_img(img, 13, 7, 2, 3, _shirt.darkened(0.1))
			_fill_img(img, 5, 7, 1, 4, _shirt.darkened(0.15))
			_set_img(img, 7, 7, Color(0.88, 0.78, 0.58))
			_set_img(img, 7, 9, Color(0.88, 0.78, 0.58))
		2:
			_fill_img(img, 2, 6, 12, 5, _shirt.darkened(0.08))
			_fill_img(img, 3, 7, 10, 4, _shirt)
			_fill_img(img, 1, 7, 2, 3, _shirt.darkened(0.12))
			_fill_img(img, 13, 7, 2, 3, _shirt.darkened(0.12))
			_fill_img(img, 5, 5, 6, 1, _shirt.darkened(0.15))
			_fill_img(img, 3, 10, 10, 1, _shirt.darkened(0.15))

func _draw_head(img: Image) -> void:
	match _head_type:
		0:
			_fill_img(img, 5, 1, 6, 1, _skin.darkened(0.1))
			_fill_img(img, 4, 2, 8, 4, _skin)
			_fill_img(img, 5, 6, 6, 1, _skin.darkened(0.1))
		1:
			_fill_img(img, 5, 0, 6, 1, _skin.darkened(0.1))
			_fill_img(img, 4, 1, 8, 5, _skin)
			_fill_img(img, 5, 6, 6, 1, _skin.darkened(0.1))
		2:
			_fill_img(img, 4, 1, 8, 1, _skin.darkened(0.1))
			_fill_img(img, 3, 2, 10, 4, _skin)
			_fill_img(img, 4, 6, 8, 1, _skin.darkened(0.1))
		3:
			_fill_img(img, 4, 1, 8, 1, _skin.darkened(0.1))
			_fill_img(img, 3, 2, 10, 4, _skin)
			_fill_img(img, 4, 6, 8, 1, _skin.darkened(0.1))

	_set_img(img, 6, 4, Color.WHITE)
	_set_img(img, 9, 4, Color.WHITE)
	_set_img(img, 6, 4, Color(0.18, 0.12, 0.08))
	_set_img(img, 9, 4, Color(0.18, 0.12, 0.08))
	_set_img(img, 5, 3, Color.WHITE.lightened(0.5))
	_set_img(img, 8, 3, Color.WHITE.lightened(0.5))
	if randi() % 3 == 0:
		_set_img(img, 7, 6, _skin.darkened(0.3))
		_set_img(img, 8, 6, _skin.darkened(0.3))
	else:
		_set_img(img, 7, 6, _skin.darkened(0.2))

func _draw_hair(img: Image) -> void:
	var h := _hair.darkened(0.1)
	match _hair_type:
		0:
			_fill_img(img, 5, 0, 6, 1, h)
			_fill_img(img, 4, 1, 2, 2, h)
			_fill_img(img, 10, 1, 2, 2, h)
			_fill_img(img, 3, 2, 3, 2, _hair)
			_fill_img(img, 10, 2, 3, 2, _hair)
			_fill_img(img, 4, 1, 8, 1, _hair.lightened(0.1))
		1:
			_fill_img(img, 3, 0, 10, 1, h)
			_fill_img(img, 3, 1, 10, 3, _hair)
			_fill_img(img, 2, 2, 2, 3, _hair.darkened(0.1))
			_fill_img(img, 12, 2, 2, 3, _hair.darkened(0.1))
		2:
			_fill_img(img, 3, 0, 10, 1, h)
			_fill_img(img, 3, 1, 10, 3, _hair)
			_fill_img(img, 2, 2, 2, 5, _hair.darkened(0.1))
			_fill_img(img, 12, 2, 2, 5, _hair.darkened(0.1))
			_fill_img(img, 3, 4, 10, 2, _hair)
		3:
			_fill_img(img, 5, 0, 6, 1, h.darkened(0.05))
			_fill_img(img, 4, 1, 8, 1, h)

func _fill_img(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, 16); y = clampi(y, 0, 16)
	w = clampi(w, 0, 16 - x); h = clampi(h, 0, 16 - y)
	if w <= 0 or h <= 0:
		return
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _set_img(img: Image, x: int, y: int, col: Color) -> void:
	if x < 0 or x >= 16 or y < 0 or y >= 16:
		return
	img.set_pixel(x, y, col)
