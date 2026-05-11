# section.gd
class_name SupermarketSection
extends Node2D

const StoreData = preload("res://scripts/store_data.gd")

signal section_interacted(section_id: String)
signal player_entered(section_id: String)
signal player_exited(section_id: String)

const CELL_SIZE := 16

var _def = null
var _slots = []
var _player_inside := false
var _interaction_area: Area2D
var _sprite: Sprite2D
var _light_sprite: Sprite2D
var _prod_sprites = []
var _empty_slots = []

# Bounding box borders for debug/proximity display
var _top_border: ColorRect = null
var _bottom_border: ColorRect = null
var _left_border: ColorRect = null
var _right_border: ColorRect = null
var _bounds_visible: bool = true

func _init() -> void:
	pass

func configure(def) -> void:
	_def = def

func _ready() -> void:
	_build_visuals()
	_generate_slots()

func _build_visuals() -> void:
	if _def == null:
		return
	var bg = ColorRect.new()
	bg.size = Vector2(_def.ww * CELL_SIZE, _def.wh * CELL_SIZE)
	bg.position = Vector2.ZERO
	bg.color = _get_section_floor_color()
	add_child(bg)
	
	_light_sprite = Sprite2D.new()
	_light_sprite.position = Vector2(_def.ww * CELL_SIZE * 0.5, -CELL_SIZE * 1.5)
	add_child(_light_sprite)
	
	_build_sign()
	_build_shelf_frame()
	
	_interaction_area = Area2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(_def.ww * CELL_SIZE, _def.wh * CELL_SIZE)
	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(_def.ww * CELL_SIZE * 0.5, _def.wh * CELL_SIZE * 0.5)
	_interaction_area.add_child(col)
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	add_child(_interaction_area)
	
	# Bounding box border for section
	var border_color := Color(1.0, 1.0, 1.0, 0.5)
	var sec_w: float = _def.ww * CELL_SIZE
	var sec_h: float = _def.wh * CELL_SIZE
	# Top border
	_top_border = ColorRect.new()
	_top_border.size = Vector2(sec_w, 1)
	_top_border.position = Vector2(0, 0)
	_top_border.color = border_color
	_top_border.z_index = 100
	add_child(_top_border)
	# Bottom border
	_bottom_border = ColorRect.new()
	_bottom_border.size = Vector2(sec_w, 1)
	_bottom_border.position = Vector2(0, sec_h - 1)
	_bottom_border.color = border_color
	_bottom_border.z_index = 100
	add_child(_bottom_border)
	# Left border
	_left_border = ColorRect.new()
	_left_border.size = Vector2(1, sec_h)
	_left_border.position = Vector2(0, 0)
	_left_border.color = border_color
	_left_border.z_index = 100
	add_child(_left_border)
	# Right border
	_right_border = ColorRect.new()
	_right_border.size = Vector2(1, sec_h)
	_right_border.position = Vector2(sec_w - 1, 0)
	_right_border.color = border_color
	_right_border.z_index = 100
	add_child(_right_border)

func _get_section_floor_color():
	if _def.style == StoreData.SectionStyle.FRIDGE:
		return Color(0.18, 0.22, 0.28)
	elif _def.style == StoreData.SectionStyle.PRODUCE:
		return Color(0.18, 0.22, 0.16)
	elif _def.style == StoreData.SectionStyle.BAKERY:
		return Color(0.24, 0.18, 0.12)
	elif _def.style == StoreData.SectionStyle.DELI:
		return Color(0.22, 0.14, 0.14)
	elif _def.style == StoreData.SectionStyle.FREEZER:
		return Color(0.16, 0.20, 0.26)
	return Color(0.20, 0.20, 0.22)

func _build_sign() -> void:
	var sign = Sprite2D.new()
	sign.position = Vector2(_def.ww * CELL_SIZE * 0.5, -CELL_SIZE * 0.5)
	sign.z_index = 10
	add_child(sign)

func _build_shelf_frame() -> void:
	var style_color = _get_shelf_color()
	var tw = _def.ww * CELL_SIZE
	var th = _def.wh * CELL_SIZE
	
	var top = ColorRect.new()
	top.size = Vector2(tw, CELL_SIZE)
	top.color = style_color
	add_child(top)
	
	var bot = ColorRect.new()
	bot.size = Vector2(tw, CELL_SIZE)
	bot.position = Vector2(0, th - CELL_SIZE)
	bot.color = style_color.darkened(0.2)
	add_child(bot)
	
	var left = ColorRect.new()
	left.size = Vector2(CELL_SIZE, th)
	left.color = style_color.darkened(0.15)
	add_child(left)
	
	var right = ColorRect.new()
	right.size = Vector2(CELL_SIZE, th)
	right.position = Vector2(tw - CELL_SIZE, 0)
	right.color = style_color.darkened(0.2)
	add_child(right)

func _get_shelf_color():
	if _def.style == StoreData.SectionStyle.FRIDGE:
		return Color(0.68, 0.80, 0.90)
	elif _def.style == StoreData.SectionStyle.PRODUCE:
		return Color(0.55, 0.68, 0.40)
	elif _def.style == StoreData.SectionStyle.BAKERY:
		return Color(0.80, 0.62, 0.40)
	elif _def.style == StoreData.SectionStyle.DELI:
		return Color(0.80, 0.50, 0.50)
	elif _def.style == StoreData.SectionStyle.FREEZER:
		return Color(0.60, 0.78, 0.92)
	return Color(0.68, 0.60, 0.50)

func _generate_slots() -> void:
	if _def == null:
		return
	var cols = int(_def.ww - 2)
	var rows = int(_def.wh - 2)
	var slots_count = cols * rows
	if slots_count > 32:
		slots_count = 32
	
	var products_in_section = StoreData.get_products_in_section(_def.id)
	if products_in_section.size() == 0:
		return
	
	var idx = 0
	for r in range(rows):
		if idx >= slots_count:
			break
		for c in range(cols):
			if idx >= slots_count:
				break
			var cell_x = 1 + c
			var cell_y = 1 + r
			var world_x = cell_x * CELL_SIZE + CELL_SIZE * 0.5
			var world_y = cell_y * CELL_SIZE + CELL_SIZE * 0.5
			
			var slot = {
				"product": products_in_section[idx % products_in_section.size()],
				"wx": world_x,
				"wy": world_y,
				"empty": false,
				"respawn_timer": 0.0,
				"sprite": null,
			}
			_slots.append(slot)
			_spawn_product_sprite(slot)
			idx += 1

func _spawn_product_sprite(slot) -> void:
	var prod = slot["product"]
	var spr = Sprite2D.new()
	spr.position = Vector2(slot["wx"], slot["wy"])
	var tex = _make_product_tex(prod)
	spr.texture = tex
	spr.z_index = 2
	add_child(spr)
	slot["sprite"] = spr
	_prod_sprites.append(spr)

func _make_product_tex(prod):
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_product(img, prod)
	return ImageTexture.create_from_image(img)

func _draw_product(img, prod) -> void:
	var c = prod.color
	match prod.shape:
		0:
			_fill_img(img, 5, 4, 2, 4, c)
			_fill_img(img, 4, 5, 4, 2, c)
			_fill_img(img, 5, 5, 2, 2, c.lightened(0.15))
		1:
			_fill_img(img, 3, 4, 6, 5, c)
			_fill_img(img, 3, 4, 6, 1, c.lightened(0.15))
		2:
			_fill_img(img, 4, 2, 4, 8, c)
			_fill_img(img, 5, 1, 2, 1, c.lightened(0.2))
			_fill_img(img, 4, 9, 4, 1, c.darkened(0.15))
		3:
			_fill_img(img, 2, 3, 8, 7, c)
			_fill_img(img, 2, 3, 8, 1, c.lightened(0.2))
			_fill_img(img, 2, 9, 8, 1, c.darkened(0.2))
		4:
			_fill_img(img, 3, 5, 6, 5, c)
			_fill_img(img, 4, 4, 4, 1, c.lightened(0.15))
			_fill_img(img, 3, 9, 6, 1, c.darkened(0.2))
		5:
			_fill_img(img, 4, 1, 4, 10, c)
			_fill_img(img, 5, 0, 2, 1, c.lightened(0.2))
			_fill_img(img, 4, 10, 4, 1, c.darkened(0.15))
		6:
			_fill_img(img, 2, 4, 8, 5, c)
			_fill_img(img, 2, 4, 8, 1, c.lightened(0.15))
		7:
			_fill_img(img, 3, 5, 6, 2, c)
			_fill_img(img, 4, 4, 4, 1, c.lightened(0.15))

func _fill_img(img, x, y, w, h, col) -> void:
	x = clampi(x, 0, 12); y = clampi(y, 0, 12)
	w = clampi(w, 0, 12 - x); h = clampi(h, 0, 12 - y)
	if w <= 0 or h <= 0:
		return
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _process(delta) -> void:
	for slot in _slots:
		if slot["empty"] and slot["respawn_timer"] > 0.0:
			slot["respawn_timer"] -= delta
			if slot["respawn_timer"] <= 0.0:
				slot["empty"] = false
				var spr = slot["sprite"]
				if spr != null:
					spr.visible = true

func _on_body_entered(body) -> void:
	if body is Player:
		_player_inside = true
		player_entered.emit(_def.id)

func _on_body_exited(body) -> void:
	if body is Player:
		_player_inside = false
		player_exited.emit(_def.id)

func is_player_inside() -> bool:
	return _player_inside

func get_def():
	return _def

func get_all_products():
	var result = []
	for slot in _slots:
		if not slot["empty"]:
			result.append(slot["product"])
	return result

func pickup_random_product():
	var candidates = []
	for i in range(_slots.size()):
		if not _slots[i]["empty"]:
			candidates.append(i)
	if candidates.size() == 0:
		return null
	var pick = candidates[randi() % candidates.size()]
	var slot = _slots[pick]
	slot["empty"] = true
	slot["respawn_timer"] = 30.0
	var spr = slot["sprite"]
	if spr != null:
		spr.visible = false
	return slot["product"]

func set_bounds_visible(visible: bool) -> void:
	_bounds_visible = visible
	if _top_border != null:
		_top_border.visible = visible
	if _bottom_border != null:
		_bottom_border.visible = visible
	if _left_border != null:
		_left_border.visible = visible
	if _right_border != null:
		_right_border.visible = visible
