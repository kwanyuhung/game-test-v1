# section.gd
class_name SupermarketSection
extends Node2D

const StoreData = preload("res://scripts/world/store_data.gd")

signal section_interacted(section_id: String)
signal player_entered(section_id: String)
signal player_exited(section_id: String)
signal interact_requested(section_id: String)

const CELL_SIZE := 16

# Bay/shelf layout — shared by slot generation and bay overlays so
# hover regions exactly match the rendered shelf bays.
const BAY_W := 224
const SLOTS_PER_BAY := 5
const PRODUCT_W := 12
const PRODUCT_H := 8
const SHELF_GAP := 2
const TOP_MARGIN := 4
const STACK_COUNT := 3
const STACK_OFFSET := 2
const STACK_VISUAL_H := PRODUCT_H + STACK_OFFSET * (STACK_COUNT - 1)  # 12
const SHELF_STRIP_H := 4
const ROW_GAP := 2
const LEVEL_H := STACK_VISUAL_H + SHELF_STRIP_H + ROW_GAP  # 18
const MAX_LEVELS := 5
const SLOT_PITCH := PRODUCT_W + SHELF_GAP  # 14

var _def = null
# Section_zone size from floor_config_data.json. Differs from _def.ww/wh
# (the static catalog size in StoreData.SECTIONS), so we use _layout_ww/wh
# for the Area2D and slot grid to spread products across the full zone.
var _layout_ww: int = 0
var _layout_wh: int = 0
var _slots = []
var _player_inside := false
var _interaction_area: Area2D
var _prod_sprites = []

# Per-bay hover overlays: each entry is {x, w, h, outline:[4 ColorRect], bubble:Node2D}.
# Bubble + outline only show when player is nearby AND mouse hovers that bay.
var _bay_overlays: Array = []
var _hover_bay := -1

var _frozen: bool = false

func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	if frozen:
		set_process(false)
	else:
		set_process(true)

func is_frozen() -> bool:
	return _frozen

func _init() -> void:
	pass

func configure(def) -> void:
	_def = def

func set_layout_size(ww: int, wh: int) -> void:
	_layout_ww = ww
	_layout_wh = wh

func _ready() -> void:
	_build_visuals()
	_generate_slots()

func _build_visuals() -> void:
	if _def == null:
		return

	_interaction_area = Area2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(_layout_ww * CELL_SIZE, _layout_wh * CELL_SIZE)
	var col = CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(_layout_ww * CELL_SIZE * 0.5, _layout_wh * CELL_SIZE * 0.5)
	_interaction_area.add_child(col)
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	add_child(_interaction_area)

	_build_bay_overlays()

func _compute_bay_count() -> int:
	var sec_w_px: int = _layout_ww * CELL_SIZE
	return int(sec_w_px / BAY_W)

func _compute_level_count() -> int:
	var sec_h_px: int = _layout_wh * CELL_SIZE
	var n: int = int((sec_h_px - TOP_MARGIN) / LEVEL_H)
	if n > MAX_LEVELS:
		n = MAX_LEVELS
	return n

func _build_bay_overlays() -> void:
	# One overlay per bay: green outline + floating "$" bubble.
	# Both hidden by default; shown only when player is nearby AND
	# mouse hovers that specific bay.
	var num_bays: int = _compute_bay_count()
	var num_levels: int = _compute_level_count()
	if num_bays <= 0 or num_levels <= 0:
		return
	var bay_h: int = num_levels * LEVEL_H + TOP_MARGIN
	var thickness := 2
	var color := Color(0.30, 0.95, 0.40, 0.90)
	var bubble_tex := _make_bubble_tex()

	for bay_i in range(num_bays):
		var bx: int = bay_i * BAY_W

		var top := ColorRect.new()
		top.color = color
		top.position = Vector2(bx, 0)
		top.size = Vector2(BAY_W, thickness)
		top.z_index = 50
		top.visible = false
		add_child(top)

		var bottom := ColorRect.new()
		bottom.color = color
		bottom.position = Vector2(bx, bay_h - thickness)
		bottom.size = Vector2(BAY_W, thickness)
		bottom.z_index = 50
		bottom.visible = false
		add_child(bottom)

		var left := ColorRect.new()
		left.color = color
		left.position = Vector2(bx, 0)
		left.size = Vector2(thickness, bay_h)
		left.z_index = 50
		left.visible = false
		add_child(left)

		var right := ColorRect.new()
		right.color = color
		right.position = Vector2(bx + BAY_W - thickness, 0)
		right.size = Vector2(thickness, bay_h)
		right.z_index = 50
		right.visible = false
		add_child(right)

		var bubble := Node2D.new()
		bubble.position = Vector2(bx + BAY_W * 0.5, -14)
		bubble.z_index = 60
		bubble.visible = false
		add_child(bubble)

		var ring := Sprite2D.new()
		ring.texture = bubble_tex
		ring.centered = true
		bubble.add_child(ring)

		var bubble_label := Label.new()
		bubble_label.text = "$"
		bubble_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.70))
		bubble_label.add_theme_font_size_override("font_size", 10)
		bubble_label.position = Vector2(-3, -7)
		bubble_label.z_index = 1
		bubble.add_child(bubble_label)

		_bay_overlays.append({
			"x": bx,
			"w": BAY_W,
			"h": bay_h,
			"outline": [top, bottom, left, right],
			"bubble": bubble,
		})

func _make_bubble_tex() -> ImageTexture:
	var d := 14
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := d / 2
	var cy := d / 2
	var r := d / 2 - 1
	var fill := Color(0.10, 0.12, 0.18, 0.90)
	var border := Color(0.95, 0.78, 0.30, 1.0)
	for y in range(d):
		for x in range(d):
			var dx := x - cx
			var dy := y - cy
			var dist2 := dx * dx + dy * dy
			if dist2 <= r * r:
				if dist2 >= (r - 1) * (r - 1):
					img.set_pixel(x, y, border)
				else:
					img.set_pixel(x, y, fill)
	# Small tail pointing down toward the shelf.
	for i in range(3):
		img.set_pixel(cx, d - 1 - i, border)
	return ImageTexture.create_from_image(img)

func _generate_slots() -> void:
	if _def == null:
		return

	var products_in_section = StoreData.get_products_in_section(_def.id)
	if products_in_section.size() == 0:
		return

	# Per bay (14 tiles = 224px): SLOTS_PER_BAY columns × MAX_LEVELS rows.
	# An 84-tile section fits 6 bays exactly. Each bay holds a tight 5×5
	# product grid (5 columns at SHELF_GAP px apart, 5 rows at ROW_GAP px
	# apart), centered within the bay. One continuous shelf strip per
	# (bay, level) sits behind the slots in that bay; bay dividers from
	# FloorBuilder (z=1, at 14-tile boundaries) visually separate bays.

	var slots_used_w: int = SLOTS_PER_BAY * PRODUCT_W + (SLOTS_PER_BAY - 1) * SHELF_GAP  # 68
	var bay_side_margin: int = (BAY_W - slots_used_w) / 2  # 78

	var num_bays: int = _compute_bay_count()
	var num_levels: int = _compute_level_count()
	if num_bays <= 0 or num_levels <= 0:
		return

	var shelf_tex = _make_shelf_strip_tex(slots_used_w, SHELF_STRIP_H)
	for level_i in range(num_levels):
		for bay_i in range(num_bays):
			var shelf = Sprite2D.new()
			shelf.texture = shelf_tex
			shelf.centered = false
			shelf.position = Vector2(
				bay_i * BAY_W + bay_side_margin,
				level_i * LEVEL_H + TOP_MARGIN + STACK_VISUAL_H
			)
			shelf.z_index = 2
			add_child(shelf)

	var idx := 0
	for level_i in range(num_levels):
		for bay_i in range(num_bays):
			for col_i in range(SLOTS_PER_BAY):
				var px: int = bay_i * BAY_W + bay_side_margin + col_i * SLOT_PITCH
				var py: int = level_i * LEVEL_H + TOP_MARGIN
				var product = products_in_section[idx % products_in_section.size()]
				var slot = {
					"product": product,
					"wx": px + PRODUCT_W * 0.5,
					"wy": py + PRODUCT_H * 0.5,
					"stack_offset": STACK_OFFSET,
					"stack_count": STACK_COUNT,
					"empty": false,
					"respawn_timer": 0.0,
					"sprites": [],
				}
				_slots.append(slot)
				_spawn_product_stack(slot)
				idx += 1

func _spawn_product_stack(slot) -> void:
	var prod = slot["product"]
	var tex = _make_product_tex(prod)
	for i in range(slot["stack_count"]):
		var spr = Sprite2D.new()
		spr.position = Vector2(slot["wx"], slot["wy"] + i * slot["stack_offset"])
		spr.texture = tex
		spr.z_index = 3 + i
		add_child(spr)
		slot["sprites"].append(spr)
		_prod_sprites.append(spr)

func _make_product_tex(prod):
	# 12x8 product body only — the shelf board is drawn separately per
	# (bay, level) as one continuous strip behind the 5-product row.
	var img = Image.create(12, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_product(img, prod)
	return ImageTexture.create_from_image(img)

func _make_shelf_strip_tex(width: int, h: int) -> ImageTexture:
	# Continuous wood shelf: 1px cream lip + (h-2)px dark board + 1px shadow.
	# Neutral wood color since one strip holds different products.
	var img = Image.create(width, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(width):
		img.set_pixel(x, 0, Color(0.95, 0.92, 0.85))
	var board_color = Color(0.35, 0.25, 0.15)
	for y in range(1, h - 1):
		for x in range(width):
			img.set_pixel(x, y, board_color)
	for x in range(width):
		img.set_pixel(x, h - 1, Color(0, 0, 0, 0.75))
	return ImageTexture.create_from_image(img)

func _draw_product(img, prod) -> void:
	var c = prod.color
	match prod.shape:
		0:  # cross/plus
			_fill_img(img, 5, 1, 2, 6, c)
			_fill_img(img, 2, 3, 8, 2, c)
			_fill_img(img, 5, 3, 2, 2, c.lightened(0.15))
		1:  # box
			_fill_img(img, 2, 1, 8, 7, c)
			_fill_img(img, 2, 1, 8, 1, c.lightened(0.15))
			_fill_img(img, 2, 7, 8, 1, c.darkened(0.2))
		2:  # tall bottle
			_fill_img(img, 4, 0, 4, 8, c)
			_fill_img(img, 5, 0, 2, 1, c.lightened(0.2))
			_fill_img(img, 4, 7, 4, 1, c.darkened(0.15))
		3:  # wide jar
			_fill_img(img, 1, 2, 10, 6, c)
			_fill_img(img, 1, 2, 10, 1, c.lightened(0.2))
			_fill_img(img, 1, 7, 10, 1, c.darkened(0.2))
		4:  # can
			_fill_img(img, 3, 1, 6, 7, c)
			_fill_img(img, 3, 1, 6, 1, c.lightened(0.15))
			_fill_img(img, 3, 7, 6, 1, c.darkened(0.2))
		5:  # tall slim bottle
			_fill_img(img, 4, 1, 4, 7, c)
			_fill_img(img, 5, 0, 2, 1, c.lightened(0.2))
		6:  # wide can
			_fill_img(img, 1, 1, 10, 7, c)
			_fill_img(img, 1, 1, 10, 1, c.lightened(0.15))
		7:  # small box
			_fill_img(img, 2, 2, 8, 6, c)
			_fill_img(img, 2, 2, 8, 1, c.lightened(0.15))
			_fill_img(img, 2, 7, 8, 1, c.darkened(0.2))

func _fill_img(img, x, y, w, h, col) -> void:
	x = clampi(x, 0, 12); y = clampi(y, 0, 8)
	w = clampi(w, 0, 12 - x); h = clampi(h, 0, 8 - y)
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
				for spr in slot["sprites"]:
					if spr != null:
						spr.visible = true
	_update_hover_bay()

func _update_hover_bay() -> void:
	# Overlay+bubble only when player is nearby AND mouse hovers a bay.
	# -1 means no bay is hovered.
	var new_bay := -1
	if _player_inside:
		var world_pt := _mouse_to_world()
		new_bay = _bay_at_world_point(world_pt)
	if new_bay == _hover_bay:
		return
	_set_bay_overlay_visible(_hover_bay, false)
	_set_bay_overlay_visible(new_bay, true)
	_hover_bay = new_bay

func _set_bay_overlay_visible(bay_idx: int, visible: bool) -> void:
	if bay_idx < 0 or bay_idx >= _bay_overlays.size():
		return
	var ov: Dictionary = _bay_overlays[bay_idx]
	for rect in ov["outline"]:
		if rect != null:
			rect.visible = visible
	if ov["bubble"] != null:
		ov["bubble"].visible = visible

func _bay_at_world_point(world_pt: Vector2) -> int:
	# Return index of the bay containing world_pt, or -1.
	var local := to_local(world_pt)
	for i in range(_bay_overlays.size()):
		var ov: Dictionary = _bay_overlays[i]
		if local.x < ov["x"]:
			continue
		if local.x > ov["x"] + ov["w"]:
			continue
		if local.y < 0:
			continue
		if local.y > ov["h"]:
			continue
		return i
	return -1

func _mouse_to_world() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	return vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var world_pt := _mouse_to_world()
			if _bay_at_world_point(world_pt) >= 0:
				interact_requested.emit(_def.id)
				get_viewport().set_input_as_handled()

func contains_world_point(world_pt: Vector2) -> bool:
	var local := to_local(world_pt)
	if local.x < 0 or local.y < 0:
		return false
	if local.x > _layout_ww * CELL_SIZE:
		return false
	if local.y > _layout_wh * CELL_SIZE:
		return false
	return true

func _on_body_entered(body) -> void:
	if body is Player:
		_player_inside = true
		player_entered.emit(_def.id)

func _on_body_exited(body) -> void:
	if body is Player:
		_player_inside = false
		player_exited.emit(_def.id)
		# Hide whatever bay is currently shown — player left the section.
		_set_bay_overlay_visible(_hover_bay, false)
		_hover_bay = -1

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
	for spr in slot["sprites"]:
		if spr != null:
			spr.visible = false
	return slot["product"]
