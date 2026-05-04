# parking_lot.gd
# Ground-floor outdoor parking area — player can "park" their car or just observe.
# Parking slots are on the LEFT side of the ground floor (x=2..39, y=38..49).
# Accessed via: const ParkingLot = preload("res://scripts/parking_lot.gd")

class_name ParkingLot
extends Node2D

const CELL_SIZE := 16
const SLOT_W := 5    # tiles wide per slot
const SLOT_H := 3    # tiles tall per slot
const NUM_SLOTS := 8  # how many car slots

# Parking slot row origin (tile coords)
const ORIGIN_X := 2
const ORIGIN_Y := 38

var _slots: Array = []       # Array of {x, y, occupied, car_sprite}
var _player_near_slot: int = -1

signal slot_interacted(slot_idx: int)

func _ready() -> void:
	_build_parking_area()

func _build_parking_area() -> void:
	# Asphalt ground
	var asphalt := ColorRect.new()
	asphalt.position = Vector2(ORIGIN_X * CELL_SIZE, ORIGIN_Y * CELL_SIZE)
	asphalt.size = Vector2((ORIGIN_X + SLOT_W * NUM_SLOTS + 2) * CELL_SIZE, (SLOT_H + 2) * CELL_SIZE)
	asphalt.color = Color(0.20, 0.20, 0.22)
	add_child(asphalt)

	# Parking lot border/wall bottom
	var border_bot := ColorRect.new()
	border_bot.position = Vector2(ORIGIN_X * CELL_SIZE, (ORIGIN_Y + SLOT_H + 1) * CELL_SIZE)
	border_bot.size = Vector2((SLOT_W * NUM_SLOTS + 2) * CELL_SIZE, 3 * CELL_SIZE)
	border_bot.color = Color(0.25, 0.20, 0.15)
	add_child(border_bot)

	# Entrance road arrow (pointing up toward lobby)
	var arrow := _make_arrow_tex()
	for i in range(NUM_SLOTS):
		var sx := ORIGIN_X + 2 + i * SLOT_W
		var sy := ORIGIN_Y

		# Slot bay (painted rectangle)
		var bay := ColorRect.new()
		bay.position = Vector2(sx * CELL_SIZE, sy * CELL_SIZE)
		bay.size = Vector2(SLOT_W * CELL_SIZE, SLOT_H * CELL_SIZE)
		bay.color = Color(0.22, 0.22, 0.24)
		add_child(bay)

		# Slot line (white border)
		var line_top := ColorRect.new()
		line_top.position = Vector2(sx * CELL_SIZE, sy * CELL_SIZE)
		line_top.size = Vector2(SLOT_W * CELL_SIZE, 1)
		line_top.color = Color(0.80, 0.80, 0.80, 0.6)
		add_child(line_top)

		var line_bot := ColorRect.new()
		line_bot.position = Vector2(sx * CELL_SIZE, (sy + SLOT_H - 1) * CELL_SIZE)
		line_bot.size = Vector2(SLOT_W * CELL_SIZE, 1)
		line_bot.color = Color(0.80, 0.80, 0.80, 0.6)
		add_child(line_bot)

		var line_left := ColorRect.new()
		line_left.position = Vector2(sx * CELL_SIZE, sy * CELL_SIZE)
		line_left.size = Vector2(1, SLOT_H * CELL_SIZE)
		line_left.color = Color(0.80, 0.80, 0.80, 0.6)
		add_child(line_left)

		var line_right := ColorRect.new()
		line_right.position = Vector2((sx + SLOT_W - 1) * CELL_SIZE, sy * CELL_SIZE)
		line_right.size = Vector2(1, SLOT_H * CELL_SIZE)
		line_right.color = Color(0.80, 0.80, 0.80, 0.6)
		add_child(line_right)

		# Slot number
		var num_lbl := Label.new()
		num_lbl.text = "%d" % (i + 1)
		num_lbl.position = Vector2(sx * CELL_SIZE + CELL_SIZE * 0.5, sy * CELL_SIZE + CELL_SIZE * 0.3)
		num_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
		num_lbl.add_theme_font_size_override("font_size", 7)
		add_child(num_lbl)

		_slots.append({
			"x": sx,
			"y": sy,
			"slot_idx": i,
			"occupied": false,
			"car_sprite": null,
		})

	# Put 3 parked cars (NPC cars) in first 3 slots
	for i in range(3):
		_add_car_to_slot(i, _make_car_sprite(i))

func _make_arrow_tex() -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Draw upward arrow
	var cx := 12
	for y in range(4, 20):
		var w := 1
		if y < 8:
			w = 1
		elif y < 14:
			w = 3
		else:
			w = 5
		for x in range(cx - w, cx + w + 1):
			if x >= 0 and x < 24 and y >= 0 and y < 24:
				img.set_pixel(x, y, Color(0.70, 0.68, 0.60, 0.5))
	# Arrow head
	for x in range(8, 17):
		var y := 20
		if x < 12:
			y = 20 - (12 - x)
		elif x > 12:
			y = 20 - (x - 12)
		if y >= 4 and y < 24 and x >= 0 and x < 24:
			img.set_pixel(x, y, Color(0.70, 0.68, 0.60, 0.5))
	return ImageTexture.create_from_image(img)

func _make_car_sprite(color_idx: int) -> Sprite2D:
	var colors := [
		Color(0.75, 0.22, 0.18),  # red
		Color(0.25, 0.40, 0.75),  # blue
		Color(0.30, 0.60, 0.30),  # green
	]
	var col: Color = colors[color_idx % colors.size()]
	var img := Image.create(5 * CELL_SIZE, 3 * CELL_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Car body
	_fill_rect(img, CELL_SIZE, CELL_SIZE * 0.5, CELL_SIZE * 3, CELL_SIZE, col)
	# Roof
	_fill_rect(img, CELL_SIZE * 1.5, 0, CELL_SIZE * 2, CELL_SIZE * 0.5, col.darkened(0.15))
	# Windshield
	_fill_rect(img, CELL_SIZE * 2.5, CELL_SIZE * 0.5, CELL_SIZE * 0.8, CELL_SIZE * 0.5, Color(0.50, 0.70, 0.85))
	# Wheels
	_fill_rect(img, CELL_SIZE * 0.8, CELL_SIZE * 1.2, CELL_SIZE * 0.8, CELL_SIZE * 0.4, Color(0.15, 0.15, 0.15))
	_fill_rect(img, CELL_SIZE * 3.2, CELL_SIZE * 1.2, CELL_SIZE * 0.8, CELL_SIZE * 0.4, Color(0.15, 0.15, 0.15))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.z_index = 3
	return spr

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, img.get_width()); y = clampi(y, 0, img.get_height())
	w = clampi(w, 0, img.get_width() - x); h = clampi(h, 0, img.get_height() - y)
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _add_car_to_slot(slot_idx: int, car_sprite: Sprite2D) -> void:
	var slot: Dictionary = _slots[slot_idx]
	slot["occupied"] = true
	slot["car_sprite"] = car_sprite
	car_sprite.position = Vector2(
		(slot["x"] + 0.5) * CELL_SIZE,
		(slot["y"] + 0.5) * CELL_SIZE
	)
	add_child(car_sprite)

# ─── Player Interaction ─────────────────────────────────────────

func get_nearby_slot(world_pos: Vector2) -> int:
	var best := -1
	var best_dist := 99999.0
	for slot in _slots:
		var slot_center := Vector2(
			(slot["x"] + SLOT_W * 0.5) * CELL_SIZE,
			(slot["y"] + SLOT_H * 0.5) * CELL_SIZE
		)
		var dist := world_pos.distance_to(slot_center)
		if dist < CELL_SIZE * 4.0 and dist < best_dist:
			best_dist = dist
			best = slot["slot_idx"]
	return best

func is_player_near(world_pos: Vector2) -> bool:
	return get_nearby_slot(world_pos) >= 0

func get_slot_info(slot_idx: int) -> Dictionary:
	if slot_idx < 0 or slot_idx >= _slots.size():
		return {}
	return _slots[slot_idx]

func slot_count() -> int:
	return NUM_SLOTS
