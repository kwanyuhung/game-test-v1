# player.gd
class_name Player
extends CharacterBody2D

const SPEED := 90.0
const CELL_SIZE := 16
const WORLD_PIXEL_W := 512 * CELL_SIZE   # matches FloorConfig.WORLD_W
const WORLD_PIXEL_H := 3200 * CELL_SIZE  # matches FloorConfig.WORLD_H (all floors)

var _min_x := 0.0
var _max_x := 2048.0
var _min_y := 0.0
var _max_y := 8192.0  # Large default, will be updated by set_floor_bounds

var _cart: ShoppingCart
var _cart_sprite: Sprite2D
var _cart_offset: Vector2 = Vector2(0, 12)
var _world_ref = null
var _nearby_section = null
var _current_zone := ""
var _sprite: Sprite2D
var _staff_mode: bool = false
var _staff_badge: Label = null
var _staff_sprite_normal: bool = true
var _has_cart: bool = true
var _dropped_cart_pos: Vector2 = Vector2.ZERO
var _cart_sprite_anchor: Node2D = null
var _bounding_box: ColorRect = null
var _bounding_visible: bool = true
var _top_border: ColorRect = null
var _bottom_border: ColorRect = null
var _left_border: ColorRect = null
var _right_border: ColorRect = null

# Blocked-state logging throttle — spamming the editor Output at 60 Hz
# freezes the editor. Log only on state change and once per 500 ms while
# still blocked.
const _BLOCKED_LOG_INTERVAL_MS := 500
var _was_blocked: bool = false
var _last_blocked_log_ms: int = -1

# Debug: check point markers (4 corners of collision box)
var _check_points: Array = []
var _check_point_labels: Array = []

signal cart_updated(count: int)
signal zone_changed(zone_name: String)
signal interact_requested
signal staff_mode_changed(is_staff: bool)
signal cart_grabbed
signal cart_dropped

func _init() -> void:
	_cart = ShoppingCart.new()
	add_child(_cart)

func set_world(world) -> void:
	_world_ref = world

func _ready() -> void:
	_build_sprite()
	_build_cart_sprite()
	_build_staff_badge()

func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _make_player_tex()
	_sprite.hframes = 1
	_sprite.vframes = 1
	add_child(_sprite)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10, 10)
	col.shape = shape
	col.position = Vector2.ZERO
	add_child(col)

	# Debug: visible collision box (RED = collision area)
	_bounding_box = ColorRect.new()
	_bounding_box.size = Vector2(12, 12)  # Match collision shape
	_bounding_box.position = Vector2(-6, -6)
	_bounding_box.color = Color(1.0, 0.0, 0.0, 0.3)  # Red, semi-transparent
	_bounding_box.z_index = 100
	add_child(_bounding_box)

	# Red border around collision box
	var border_color := Color(1.0, 0.0, 0.0, 0.9)
	_top_border = ColorRect.new()
	_top_border.size = Vector2(12, 2)
	_top_border.position = Vector2(-6, -6)
	_top_border.color = border_color
	_top_border.z_index = 101
	add_child(_top_border)

	_bottom_border = ColorRect.new()
	_bottom_border.size = Vector2(12, 2)
	_bottom_border.position = Vector2(-6, 6)
	_bottom_border.color = border_color
	_bottom_border.z_index = 101
	add_child(_bottom_border)

	_left_border = ColorRect.new()
	_left_border.size = Vector2(2, 12)
	_left_border.position = Vector2(-6, -6)
	_left_border.color = border_color
	_left_border.z_index = 101
	add_child(_left_border)

	_right_border = ColorRect.new()
	_right_border.size = Vector2(2, 12)
	_right_border.position = Vector2(6, -6)
	_right_border.color = border_color
	_right_border.z_index = 101
	add_child(_right_border)

	# Create 4 check point markers (dots at corners of collision box)
	var check_offsets := [
		Vector2(-6, -6),  # top-left
		Vector2(6, -6),   # top-right
		Vector2(-6, 6),   # bottom-left
		Vector2(6, 6),    # bottom-right
	]
	for offset in check_offsets:
		var dot := ColorRect.new()
		dot.size = Vector2(4, 4)
		dot.position = offset - Vector2(2, 2)
		dot.color = Color(1.0, 0.5, 0.0, 0.8)  # Orange dots
		dot.z_index = 102
		add_child(dot)
		_check_points.append(dot)

func _build_cart_sprite() -> void:
	_cart_sprite = Sprite2D.new()
	_cart_sprite.texture = _make_cart_tex()
	_cart_sprite.position = _cart_offset
	add_child(_cart_sprite)

func _build_staff_badge() -> void:
	_staff_badge = Label.new()
	_staff_badge.name = "StaffBadge"
	_staff_badge.text = ""
	_staff_badge.position = Vector2(-14.0, -24.0)
	_staff_badge.add_theme_color_override("font_color", Color(0.50, 0.85, 1.00))
	_staff_badge.add_theme_font_size_override("font_size", 6)
	_staff_badge.z_index = 12
	_staff_badge.visible = false
	add_child(_staff_badge)

func toggle_staff_mode() -> bool:
	_staff_mode = not _staff_mode
	_staff_sprite_normal = not _staff_mode
	if _staff_mode:
		_sprite.texture = _make_staff_tex()
		if _staff_badge != null:
			_staff_badge.text = "[STAFF MODE]"
			_staff_badge.visible = true
		if _cart_sprite != null:
			_cart_sprite.visible = false
	else:
		_sprite.texture = _make_player_tex()
		if _staff_badge != null:
			_staff_badge.text = ""
			_staff_badge.visible = false
		if _cart_sprite != null:
			_cart_sprite.visible = true
	staff_mode_changed.emit(_staff_mode)
	return _staff_mode

func is_in_staff_mode() -> bool:
	return _staff_mode

func set_staff_mode(val: bool) -> void:
	if _staff_mode != val:
		toggle_staff_mode()

func _make_player_tex() -> Texture2D:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	_fill(5, 1, 6, 1, Color(0.30, 0.20, 0.15), img)
	_fill(4, 2, 8, 1, Color(0.30, 0.20, 0.15), img)

	_fill(5, 2, 6, 4, Color(0.96, 0.80, 0.65), img)
	_fill(4, 3, 1, 2, Color(0.96, 0.80, 0.65), img)
	_fill(11, 3, 1, 2, Color(0.96, 0.80, 0.65), img)

	_set_pixel(6, 3, Color(0.15, 0.10, 0.08), img)
	_set_pixel(6, 3, Color(1.0, 1.0, 1.0, 0.8), img)
	_set_pixel(9, 3, Color(0.15, 0.10, 0.08), img)
	_set_pixel(9, 3, Color(1.0, 1.0, 1.0, 0.8), img)

	_set_pixel(7, 5, Color(0.80, 0.50, 0.50), img)
	_set_pixel(8, 5, Color(0.80, 0.50, 0.50), img)

	_fill(7, 6, 2, 1, Color(0.96, 0.80, 0.65), img)

	_fill(4, 7, 8, 4, Color(0.91, 0.76, 0.44), img)
	_fill(3, 7, 1, 3, Color(0.91, 0.76, 0.44), img)
	_fill(12, 7, 1, 3, Color(0.91, 0.76, 0.44), img)

	_fill(6, 7, 4, 1, Color(0.98, 0.88, 0.58), img)

	_fill(3, 9, 1, 2, Color(0.96, 0.80, 0.65), img)
	_fill(12, 9, 1, 2, Color(0.96, 0.80, 0.65), img)

	_fill(5, 11, 2, 3, Color(0.25, 0.35, 0.60), img)
	_fill(9, 11, 2, 3, Color(0.25, 0.35, 0.60), img)

	_fill(5, 11, 6, 1, Color(0.45, 0.30, 0.20), img)

	_fill(4, 14, 4, 2, Color(0.40, 0.28, 0.22), img)
	_fill(8, 14, 4, 2, Color(0.40, 0.28, 0.22), img)

	_fill(4, 15, 4, 1, Color(0.25, 0.18, 0.15), img)
	_fill(8, 15, 4, 1, Color(0.25, 0.18, 0.15), img)

	return ImageTexture.create_from_image(img)

func _make_staff_tex() -> Texture2D:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	_fill(5, 1, 6, 1, Color(0.30, 0.20, 0.15), img)
	_fill(4, 2, 8, 1, Color(0.30, 0.20, 0.15), img)

	_fill(5, 2, 6, 4, Color(0.96, 0.80, 0.65), img)
	_fill(4, 3, 1, 2, Color(0.96, 0.80, 0.65), img)
	_fill(11, 3, 1, 2, Color(0.96, 0.80, 0.65), img)

	_set_pixel(6, 3, Color(0.15, 0.10, 0.08), img)
	_set_pixel(9, 3, Color(0.15, 0.10, 0.08), img)

	_set_pixel(7, 5, Color(0.80, 0.50, 0.50), img)
	_set_pixel(8, 5, Color(0.80, 0.50, 0.50), img)

	_fill(7, 6, 2, 1, Color(0.96, 0.80, 0.65), img)

	_fill(4, 7, 8, 4, Color(0.30, 0.50, 0.80), img)
	_fill(3, 7, 1, 3, Color(0.30, 0.50, 0.80), img)
	_fill(12, 7, 1, 3, Color(0.30, 0.50, 0.80), img)

	_fill(6, 7, 4, 1, Color(0.40, 0.58, 0.85), img)

	_fill(8, 8, 3, 2, Color(0.90, 0.90, 0.85), img)
	_fill(9, 9, 1, 1, Color(0.30, 0.30, 0.35), img)

	_fill(3, 9, 1, 2, Color(0.96, 0.80, 0.65), img)
	_fill(12, 9, 1, 2, Color(0.96, 0.80, 0.65), img)

	_fill(5, 11, 2, 3, Color(0.25, 0.25, 0.35), img)
	_fill(9, 11, 2, 3, Color(0.25, 0.25, 0.35), img)

	_fill(5, 11, 6, 1, Color(0.35, 0.25, 0.20), img)

	_fill(4, 14, 4, 2, Color(0.25, 0.20, 0.18), img)
	_fill(8, 14, 4, 2, Color(0.25, 0.20, 0.18), img)

	_fill(4, 15, 4, 1, Color(0.15, 0.12, 0.10), img)
	_fill(8, 15, 4, 1, Color(0.15, 0.12, 0.10), img)

	return ImageTexture.create_from_image(img)

func _make_cart_tex() -> Texture2D:
	var img = Image.create(20, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill(2, 2, 16, 1, Color(0.65, 0.65, 0.70), img)
	_fill(2, 9, 16, 1, Color(0.65, 0.65, 0.70), img)
	_fill(2, 3, 1, 6, Color(0.65, 0.65, 0.70), img)
	_fill(17, 3, 1, 6, Color(0.65, 0.65, 0.70), img)
	_fill(1, 1, 2, 1, Color(0.75, 0.28, 0.28), img)
	_fill(1, 1, 1, 4, Color(0.75, 0.28, 0.28), img)
	_set_pixel(3, 11, Color(0.30, 0.30, 0.30), img)
	_set_pixel(16, 11, Color(0.30, 0.30, 0.30), img)
	return ImageTexture.create_from_image(img)

func _fill(x: int, y: int, w: int, h: int, col: Color, img: Image) -> void:
	if w <= 0 or h <= 0:
		return
	for px in range(x, x + w):
		for py in range(y, y + h):
			if px >= 0 and px < 16 and py >= 0 and py < 16:
				img.set_pixel(px, py, col)

func _set_pixel(x: int, y: int, col: Color, img: Image) -> void:
	if x >= 0 and x < 16 and y >= 0 and y < 16:
		img.set_pixel(x, y, col)

func _log_blocked(new_pos: Vector2, floor_idx: int) -> void:
	# Always log when transitioning from unblocked → blocked.
	# While still blocked, log at most once per _BLOCKED_LOG_INTERVAL_MS.
	var now_ms := Time.get_ticks_msec()
	var state_changed := not _was_blocked
	var interval_elapsed := now_ms - _last_blocked_log_ms >= _BLOCKED_LOG_INTERVAL_MS
	if not state_changed and not interval_elapsed:
		return
	_was_blocked = true
	_last_blocked_log_ms = now_ms
	var tile_x := int(new_pos.x / CELL_SIZE)
	var tile_y := int(new_pos.y / CELL_SIZE)
	print("[Player] BLOCKED at world(%.0f, %.0f) tile(%d, %d) floor=%d" % [new_pos.x, new_pos.y, tile_x, tile_y, floor_idx])

func _physics_process(delta: float) -> void:
	if _world_ref != null and _world_ref.has_method("is_input_blocked"):
		if _world_ref.is_input_blocked():
			return

	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		var new_pos = position + input_dir * SPEED * delta

		# Clamp to the world rectangle first. Without this, a player holding
		# left/up against the world edge drifts to negative tile coordinates
		# (e.g. tile x=-1), and is_position_blocked() reports "not inside any
		# zone" — producing a BLOCKED log at the edge of the world rather than
		# at the boundary of the walkable area.
		new_pos.x = clampf(new_pos.x, 0.0, WORLD_PIXEL_W - 1.0)
		new_pos.y = clampf(new_pos.y, 0.0, WORLD_PIXEL_H - 1.0)

		# Check if new position is in a blocked zone
		var can_move := true
		var floor_idx: int = 0
		if _world_ref != null and _world_ref.has_method("is_position_blocked"):
			if _world_ref.has_method("get_current_floor_idx"):
				floor_idx = _world_ref.get_current_floor_idx()
			# Check only center point first
			if _world_ref.is_position_blocked(floor_idx, new_pos.x, new_pos.y):
				can_move = false
				_log_blocked(new_pos, floor_idx)

		if can_move:
			position = new_pos
			_was_blocked = false
		else:
			# Sliding against the wall: keep the player at the last valid
			# position. The earlier code "Move blocked from tile A to tile B"
			# ran every frame and flooded the editor Output panel.
			pass

	_cart_sprite.position = _cart_sprite.position.lerp(_cart_offset, 0.15)

	if absf(input_dir.x) > 0.1:
		_sprite.flip_h = input_dir.x < 0.0

	var t = Time.get_ticks_msec() / 1000.0
	var bob = sin(t * 10.0) * 0.04
	_sprite.scale = Vector2(1.0, 1.0 + bob)

	if Input.is_action_just_pressed("interact"):
		interact_requested.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		toggle_cart()
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		toggle_cart()

func set_nearby_section(section) -> void:
	_nearby_section = section
	if section != null:
		var def = section.get_def()
		_current_zone = def.name
		zone_changed.emit(_current_zone)
	else:
		_current_zone = ""

func set_floor_bounds(floor_idx: int) -> void:
	var CELL = 16
	var FLOOR_Y_OFFSET = 10 * CELL  # 160 pixels per floor (vertical spacing between floors)
	var FLOOR_0_BASE_Y = 32 * CELL  # 512 pixels for floor 0 base
	var WORLD_W = 128 * CELL  # 2048 pixels

	var floor_y = FLOOR_0_BASE_Y - (floor_idx * FLOOR_Y_OFFSET)

	# Get actual zone bounds from floor config
	var zone_bounds: Dictionary = _get_floor_zone_bounds(floor_idx)
	var zone_min_y: float = zone_bounds.min_y * CELL  # tile to pixel
	var zone_max_y: float = zone_bounds.max_y * CELL  # tile to pixel

	_min_x = CELL * 2.0
	_max_x = WORLD_W - CELL * 2.0
	# Use actual zone height for movement bounds
	_min_y = floor_y + zone_min_y + CELL * 2.0
	_max_y = floor_y + zone_max_y - CELL * 2.0

func _get_floor_zone_bounds(floor_idx: int) -> Dictionary:
	var FloorConfig = preload("res://scripts/world/floor_config.gd")
	var fd = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return {"min_y": 2, "max_y": 42}
	var min_y = 800
	var max_y = 0
	for zone in fd.zones:
		if zone.y < min_y:
			min_y = zone.y
		if zone.y + zone.h > max_y:
			max_y = zone.y + zone.h
	return {"min_y": min_y, "max_y": max_y}

func get_nearby_section():
	return _nearby_section

func get_cart():
	return _cart

func get_current_zone() -> String:
	return _current_zone

func has_cart() -> bool:
	return _has_cart

func drop_cart() -> void:
	if not _has_cart:
		return
	_dropped_cart_pos = global_position + _cart_offset

	if _cart_sprite != null:
		_cart_sprite.visible = false

	_drop_cart_sprite()

	_has_cart = false
	cart_dropped.emit()

func grab_cart() -> void:
	if _has_cart:
		return

	if _cart_sprite_anchor != null:
		_cart_sprite_anchor.queue_free()
		_cart_sprite_anchor = null

	if _cart_sprite != null:
		_cart_sprite.visible = true

	_has_cart = true
	cart_grabbed.emit()

func _drop_cart_sprite() -> void:
	_cart_sprite_anchor = Node2D.new()
	_cart_sprite_anchor.name = "DroppedCart"
	_cart_sprite_anchor.global_position = _dropped_cart_pos
	get_parent().add_child(_cart_sprite_anchor)

	var dropped_sprite := Sprite2D.new()
	dropped_sprite.texture = _make_cart_tex()
	dropped_sprite.position = Vector2.ZERO
	dropped_sprite.z_index = -1
	_cart_sprite_anchor.add_child(dropped_sprite)

func toggle_cart() -> void:
	if _has_cart:
		drop_cart()
	else:
		grab_cart()

func set_bounds_visible(visible: bool) -> void:
	_bounding_visible = visible
	if _bounding_box != null:
		_bounding_box.visible = visible
	if _top_border != null:
		_top_border.visible = visible
	if _bottom_border != null:
		_bottom_border.visible = visible
	if _left_border != null:
		_left_border.visible = visible
	if _right_border != null:
		_right_border.visible = visible
