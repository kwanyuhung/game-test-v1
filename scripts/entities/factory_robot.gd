# factory_robot.gd
# Visual-only factory robot used on Floor 11 (warehouse).
# Replaces the legacy FactoryRobot1/2/3 inner classes from warehouse_floor.gd.
# Modes: COUNTER_SCANNER, SHELF_SCANNER, CLEANING, SECURITY, DELIVERY.
# ═══════════════════════════════════════════════════════════════════════
class_name FactoryRobot
extends Node2D

const CELL_SIZE := 16

enum Mode { COUNTER_SCANNER, SHELF_SCANNER, CLEANING, SECURITY, DELIVERY }

var _mode: Mode = Mode.COUNTER_SCANNER
var _sprite: Sprite2D = null
var _anim_timer: float = 0.0
var _is_active: bool = true

# Patrol state — empty list means stand in place.
var _patrol_points: Array = []
var _patrol_index: int = 0
var _pos: Vector2 = Vector2.ZERO
var _speed: float = 40.0  # tiles per second, configurable per mode

func configure(mode: Mode, patrol_points: Array = [], start_pos: Vector2 = Vector2.ZERO, speed: float = 40.0) -> void:
	_mode = mode
	_patrol_points = patrol_points
	_pos = start_pos
	_speed = speed
	position = start_pos
	if _sprite:
		_sprite.texture = _build_sprite_for_mode()
		_sprite.flip_h = false

func _ready() -> void:
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.texture = _build_sprite_for_mode()
		_sprite.hframes = 1
		add_child(_sprite)

func _build_sprite_for_mode() -> ImageTexture:
	match _mode:
		Mode.COUNTER_SCANNER:
			return _make_counter_texture()
		Mode.SHELF_SCANNER:
			return _make_shelf_texture()
		Mode.CLEANING:
			return _make_cleaning_texture()
		Mode.SECURITY:
			return _make_security_texture()
		Mode.DELIVERY:
			return _make_delivery_texture()
	return _make_counter_texture()

# ─── Patrol + animation ────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _is_active:
		return
	_anim_timer += delta
	_update_patrol(delta)
	if _sprite:
		_sprite.frame = int(_anim_timer * 2) % 4

func _update_patrol(delta: float) -> void:
	if _patrol_points.is_empty():
		return  # stand in place
	if _patrol_points.size() < 2:
		position = _patrol_points[0]
		_pos = _patrol_points[0]
		return

	var target: Vector2 = _patrol_points[_patrol_index]
	var to_target := target - _pos
	var dist := to_target.length()
	if dist < 5.0:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		return
	var dir := to_target / dist
	_pos += dir * _speed * delta
	position = _pos
	if _sprite:
		_sprite.flip_h = dir.x < 0.0

func set_active(active: bool) -> void:
	_is_active = active
	if _sprite:
		_sprite.visible = active

# ─── Texture builders (one per mode) ───────────────────────────────

func _make_counter_texture() -> ImageTexture:
	var img := Image.create(24, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	for x in range(4, 20):
		for y in range(8, 24):
			img.set_pixel(x, y, Color(0.70, 0.72, 0.78, 1.0))
	# Head
	for x in range(6, 18):
		for y in range(2, 8):
			img.set_pixel(x, y, Color(0.25, 0.28, 0.35, 1.0))
	# Scanner eye (cyan)
	for x in range(8, 16):
		for y in range(4, 6):
			img.set_pixel(x, y, Color(0.20, 1.0, 0.85, 1.0))
	# Base
	for x in range(2, 22):
		img.set_pixel(x, 26, Color(0.40, 0.42, 0.48, 1.0))
	# Beam
	for y in range(6, 10):
		img.set_pixel(12, y, Color(0.20, 1.0, 0.85, 0.6))
	return ImageTexture.create_from_image(img)

func _make_shelf_texture() -> ImageTexture:
	var img := Image.create(20, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(5, 15):
		for y in range(10, 26):
			img.set_pixel(x, y, Color(0.60, 0.62, 0.68, 1.0))
	for x in range(4, 16):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.50, 0.52, 0.58, 1.0))
	for x in range(6, 14):
		for y in range(4, 8):
			img.set_pixel(x, y, Color(0.15, 0.85, 0.40, 1.0))
	img.set_pixel(6, 12, Color(0.20, 1.0, 0.50, 1.0))
	img.set_pixel(13, 12, Color(0.20, 1.0, 0.50, 1.0))
	img.set_pixel(5, 27, Color(0.35, 0.37, 0.42, 1.0))
	img.set_pixel(14, 27, Color(0.35, 0.37, 0.42, 1.0))
	return ImageTexture.create_from_image(img)

func _make_cleaning_texture() -> ImageTexture:
	var img := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(2, 20):
		for y in range(2, 20):
			var dx := x - 11
			var dy := y - 11
			if dx * dx + dy * dy < 88:
				img.set_pixel(x, y, Color(0.72, 0.74, 0.78, 1.0))
	for x in range(5, 17):
		for y in range(5, 17):
			var dx := x - 11
			var dy := y - 11
			if dx * dx + dy * dy < 30:
				img.set_pixel(x, y, Color(0.50, 0.52, 0.56, 1.0))
	for x in range(8, 14):
		for y in range(8, 14):
			var dx := x - 11
			var dy := y - 11
			if dx * dx + dy * dy < 14:
				img.set_pixel(x, y, Color(0.20, 0.80, 0.70, 1.0))
	for pos in [Vector2i(6, 6), Vector2i(15, 6), Vector2i(6, 15), Vector2i(15, 15)]:
		img.set_pixel(pos.x, pos.y, Color(0.20, 1.0, 0.85, 1.0))
	return ImageTexture.create_from_image(img)

func _make_security_texture() -> ImageTexture:
	var img := Image.create(20, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(2, 18):
		for y in range(8, 22):
			img.set_pixel(x, y, Color(0.25, 0.27, 0.32, 1.0))
	for x in range(4, 16):
		for y in range(2, 9):
			img.set_pixel(x, y, Color(0.20, 0.22, 0.28, 1.0))
	for x in range(5, 15):
		for y in range(3, 7):
			img.set_pixel(x, y, Color(0.90, 0.15, 0.10, 1.0))
	for x in [2, 17]:
		img.set_pixel(x, 9, Color(0.15, 0.50, 1.0, 1.0))
		img.set_pixel(x, 10, Color(0.15, 0.50, 1.0, 1.0))
	for pos in [Vector2i(5, 14), Vector2i(6, 14), Vector2i(13, 14), Vector2i(14, 14)]:
		img.set_pixel(pos.x, pos.y, Color(1.0, 0.20, 0.15, 1.0))
	return ImageTexture.create_from_image(img)

func _make_delivery_texture() -> ImageTexture:
	var img := Image.create(24, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(2, 22):
		for y in range(8, 20):
			img.set_pixel(x, y, Color(0.50, 0.55, 0.65, 1.0))
	for x in range(4, 10):
		for y in range(9, 15):
			img.set_pixel(x, y, Color(0.35, 0.38, 0.45, 1.0))
	for x in range(3, 21):
		for y in range(5, 9):
			img.set_pixel(x, y, Color(0.40, 0.42, 0.48, 1.0))
	for x in range(10, 16):
		for y in range(2, 5):
			img.set_pixel(x, y, Color(1.0, 0.50, 0.10, 1.0))
	img.set_pixel(12, 2, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(13, 2, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(12, 16, Color(0.20, 1.0, 0.85, 1.0))
	img.set_pixel(13, 16, Color(0.20, 1.0, 0.85, 1.0))
	return ImageTexture.create_from_image(img)
