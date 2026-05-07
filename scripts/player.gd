# player.gd
class_name Player
extends CharacterBody2D

const SPEED := 90.0
const CELL_SIZE := 16

var _cart: ShoppingCart
var _cart_sprite: Sprite2D
var _cart_offset: Vector2 = Vector2(0, 12)
var _world_ref = null
var _nearby_section = null
var _current_zone := ""
var _sprite: Sprite2D
var _staff_mode: bool = false
var _staff_badge: Label = null
var _staff_sprite_normal: bool = true  # true = normal, false = uniform
var _has_cart: bool = true  # true = cart is with player, false = cart is left behind
var _dropped_cart_pos: Vector2 = Vector2.ZERO  # Where cart was dropped
var _cart_sprite_anchor: Node2D = null  # Anchor for dropped cart sprite

signal cart_updated(count: int)
signal zone_changed(zone_name: String)
signal interact_requested
signal tab_pressed
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
		# Hide shopping cart in staff mode
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
	_fill(6, 1, 4, 1, Color(0.96, 0.80, 0.65), img)
	_fill(5, 2, 6, 3, Color(0.96, 0.80, 0.65), img)
	_fill(6, 5, 4, 1, Color(0.85, 0.65, 0.50), img)
	_set_pixel(7, 3, Color(0.15, 0.10, 0.08), img)
	_set_pixel(9, 3, Color(0.15, 0.10, 0.08), img)
	_fill(4, 6, 8, 5, Color(0.91, 0.76, 0.44), img)
	_fill(3, 7, 2, 3, Color(0.91, 0.76, 0.44), img)
	_fill(11, 7, 2, 3, Color(0.91, 0.76, 0.44), img)
	_fill(5, 6, 6, 1, Color(0.98, 0.88, 0.58), img)
	_fill(5, 11, 3, 3, Color(0.25, 0.25, 0.45), img)
	_fill(8, 11, 3, 3, Color(0.25, 0.25, 0.45), img)
	_fill(4, 13, 4, 2, Color(0.35, 0.25, 0.20), img)
	_fill(8, 13, 4, 2, Color(0.35, 0.25, 0.20), img)
	_fill(4, 15, 8, 1, Color(0, 0, 0, 0.18), img)
	return ImageTexture.create_from_image(img)

func _make_staff_tex() -> Texture2D:
	# Same as player but shirt is blue (uniform)
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill(6, 1, 4, 1, Color(0.96, 0.80, 0.65), img)
	_fill(5, 2, 6, 3, Color(0.96, 0.80, 0.65), img)
	_fill(6, 5, 4, 1, Color(0.85, 0.65, 0.50), img)
	_set_pixel(7, 3, Color(0.15, 0.10, 0.08), img)
	_set_pixel(9, 3, Color(0.15, 0.10, 0.08), img)
	_fill(4, 6, 8, 5, Color(0.40, 0.60, 0.90), img)  # Blue shirt instead of yellow
	_fill(3, 7, 2, 3, Color(0.40, 0.60, 0.90), img)
	_fill(11, 7, 2, 3, Color(0.40, 0.60, 0.90), img)
	_fill(5, 6, 6, 1, Color(0.98, 0.88, 0.58), img)
	_fill(5, 11, 3, 3, Color(0.25, 0.25, 0.45), img)
	_fill(8, 11, 3, 3, Color(0.25, 0.25, 0.45), img)
	_fill(4, 13, 4, 2, Color(0.35, 0.25, 0.20), img)
	_fill(8, 13, 4, 2, Color(0.35, 0.25, 0.20), img)
	_fill(4, 15, 8, 1, Color(0, 0, 0, 0.18), img)
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
	x = clampi(x, 0, 20); y = clampi(y, 0, 14)
	w = clampi(w, 0, 20 - x); h = clampi(h, 0, 14 - y)
	if w <= 0 or h <= 0:
		return
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _set_pixel(x: int, y: int, col: Color, img: Image) -> void:
	if x < 0 or x >= 20 or y < 0 or y >= 14:
		return
	img.set_pixel(x, y, col)

func _physics_process(delta: float) -> void:
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		var new_pos = position + input_dir * SPEED * delta
		new_pos.x = clampf(new_pos.x, 20.0, 1260.0)
		new_pos.y = clampf(new_pos.y, 20.0, 740.0)
		position = new_pos
		
		var cart_target = position + _cart_offset
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
		tab_pressed.emit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		_toggle_staff_mode_input()
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		toggle_cart()

func _toggle_staff_mode_input() -> void:
	# Only allow toggling on floor 9 or near staff area
	if _world_ref != null and _world_ref.has_method("can_toggle_staff_mode"):
		if _world_ref.can_toggle_staff_mode():
			var was_staff = _staff_mode
			toggle_staff_mode()
			if _world_ref.has_method("on_staff_mode_toggled"):
				_world_ref.on_staff_mode_toggled(_staff_mode)
		else:
			# Show "Staff Only" hint if on floor 9 or near staff area
			if _world_ref.has_method("show_staff_only_hint"):
				_world_ref.show_staff_only_hint()

func set_nearby_section(section) -> void:
	_nearby_section = section
	if section != null:
		var def = section.get_def()
		_current_zone = def.name
		zone_changed.emit(_current_zone)
	else:
		_current_zone = ""
		zone_changed.emit("")

func get_nearby_section():
	return _nearby_section

func get_cart():
	return _cart

func get_current_zone() -> String:
	return _current_zone

# ── Cart Drop / Grab (G key) ─────────────────────────────────────────
func has_cart() -> bool:
	return _has_cart

func drop_cart() -> void:
	if not _has_cart:
		return
	# Remember where we dropped the cart
	_dropped_cart_pos = global_position + _cart_offset
	
	# Hide cart sprite attached to player
	if _cart_sprite != null:
		_cart_sprite.visible = false
	
	# Create a standalone cart sprite where we dropped it
	_drop_cart_sprite()
	
	_has_cart = false
	cart_dropped.emit()

func grab_cart() -> void:
	if _has_cart:
		return
	
	# Remove the dropped cart sprite
	if _cart_sprite_anchor != null:
		_cart_sprite_anchor.queue_free()
		_cart_sprite_anchor = null
	
	# Show cart sprite attached to player
	if _cart_sprite != null:
		_cart_sprite.visible = true
	
	_has_cart = true
	cart_grabbed.emit()

func _drop_cart_sprite() -> void:
	# Create a Node2D to hold the dropped cart sprite
	_cart_sprite_anchor = Node2D.new()
	_cart_sprite_anchor.name = "DroppedCart"
	_cart_sprite_anchor.global_position = _dropped_cart_pos
	get_parent().add_child(_cart_sprite_anchor)
	
	# Add cart sprite to anchor
	var dropped_sprite := Sprite2D.new()
	dropped_sprite.texture = _make_cart_tex()
	dropped_sprite.position = Vector2.ZERO
	dropped_sprite.z_index = -1  # Below player
	_cart_sprite_anchor.add_child(dropped_sprite)

func toggle_cart() -> void:
	if _has_cart:
		drop_cart()
	else:
		grab_cart()
