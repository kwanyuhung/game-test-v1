# checkout_counter.gd
# Phase 5: Extended with checkout type variants (staffed / self / express)
class_name CheckoutCounter
extends Area2D

# ─── Checkout Types ──────────────────────────────────────────────
enum CheckoutType {
	STAFFED   # Standard lane with cashier NPC
	SELF       # Self-checkout kiosk
	EXPRESS    # Express lane — max 10 items
}

const MAX_EXPRESS_ITEMS := 10
const SELF_ERROR_CHANCE := 0.10  # 10% chance of "unexpected item" error

var _checkout_id: int
var _checkout_type: CheckoutType = CheckoutType.STAFFED
var _sprite: Sprite2D
var _type_sprite: Sprite2D  # extra sprite for type-specific signage
var _cashier_sprite: Sprite2D  # only shown for staffed lanes
var _error_panel: ColorRect  # self-checkout error overlay
var _error_label: Label
var _has_error: bool = false
var _error_timer: float = 0.0
var _is_waving: bool = false
var _wave_timer: float = 0.0
var _thought_bubble: ColorRect
var _thought_label: Label

signal checkout_interacted(checkout_id: int, checkout_type: CheckoutType)
signal express_rejected()        # emitted when too many items for express
signal self_checkout_error()     # emitted on self-checkout error
signal self_checkout_cleared()   # emitted after player dismisses error

func configure(id: int, ctype: CheckoutType = CheckoutType.STAFFED) -> void:
	_checkout_id = id
	_checkout_type = ctype

func get_checkout_type() -> CheckoutType:
	return _checkout_type

func get_checkout_id() -> int:
	return _checkout_id

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _make_checkout_tex()
	add_child(_sprite)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48.0, 24.0)
	col.shape = shape
	col.position = Vector2(24.0, 12.0)
	add_child(col)

	body_entered.connect(_on_body_entered)

	# Build type-specific sign sprite
	_type_sprite = Sprite2D.new()
	_type_sprite.texture = _make_type_sign_tex()
	_type_sprite.position = Vector2(0, -14)
	add_child(_type_sprite)

	# Cashier NPC sprite (staffed lanes only)
	_cashier_sprite = Sprite2D.new()
	_cashier_sprite.texture = _make_cashier_tex()
	_cashier_sprite.position = Vector2(24.0, -18)
	_cashier_sprite.z_index = 2
	_cashier_sprite.visible = (_checkout_type == CheckoutType.STAFFED)
	add_child(_cashier_sprite)

	# Self-checkout error panel (hidden initially)
	_error_panel = ColorRect.new()
	_error_panel.size = Vector2(56, 20)
	_error_panel.position = Vector2(-4, -32)
	_error_panel.color = Color(0.8, 0.1, 0.1, 0.9)
	_error_panel.visible = false
	add_child(_error_panel)

	_error_label = Label.new()
	_error_label.text = "UNEXPECTED ITEM\nIN BAGGING AREA"
	_error_label.position = Vector2(-4, -30)
	_error_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_error_label.add_theme_font_size_override("font_size", 6)
	_error_label.visible = false
	add_child(_error_label)

	# Thought bubble for cashier farewell (staffed lanes only)
	_thought_bubble = ColorRect.new()
	_thought_bubble.size = Vector2(50, 16)
	_thought_bubble.position = Vector2(26.0, -36)
	_thought_bubble.color = Color(1.0, 1.0, 0.85, 0.95)
	_thought_bubble.visible = false
	_thought_bubble.z_index = 10
	add_child(_thought_bubble)

	_thought_label = Label.new()
	_thought_label.text = ""
	_thought_label.position = Vector2(27.0, -34)
	_thought_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.1))
	_thought_label.add_theme_font_size_override("font_size", 7)
	_thought_label.visible = false
	_thought_label.z_index = 11
	add_child(_thought_label)

func _make_checkout_tex() -> Texture2D:
	var img := Image.create(48, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	match _checkout_type:
		CheckoutType.STAFFED:
			# Counter base (purple-grey like original)
			_fill(0, 8, 48, 16, Color(0.48, 0.42, 0.54), img)
			_fill(0, 8, 48, 2, Color(0.58, 0.52, 0.64), img)
			# Conveyor belt
			_fill(0, 18, 48, 4, Color(0.35, 0.35, 0.38), img)
			# Register
			_fill(4, 2, 16, 12, Color(0.42, 0.48, 0.55), img)
			_fill(4, 2, 16, 2, Color(0.52, 0.58, 0.65), img)
			# Screen
			_fill(6, 4, 12, 6, Color(0.20, 0.35, 0.20), img)
			# Belt lines
			for x in range(0, 48, 6):
				_fill(x, 19, 2, 2, Color(0.50, 0.50, 0.52), img)

		CheckoutType.SELF:
			# Self-checkout — blue-tinted
			_fill(0, 8, 48, 16, Color(0.30, 0.40, 0.52), img)
			_fill(0, 8, 48, 2, Color(0.42, 0.52, 0.65), img)
			# Conveyor belt (narrower)
			_fill(0, 18, 48, 4, Color(0.28, 0.28, 0.32), img)
			# Self-scan kiosk panel
			_fill(4, 2, 20, 14, Color(0.35, 0.48, 0.58), img)
			_fill(4, 2, 20, 2, Color(0.45, 0.58, 0.70), img)
			# Scanner screen (green when idle)
			_fill(6, 4, 16, 6, Color(0.15, 0.45, 0.15), img)
			# Belt lines
			for x in range(0, 48, 6):
				_fill(x, 19, 2, 2, Color(0.42, 0.42, 0.45), img)

		CheckoutType.EXPRESS:
			# Express — shorter counter, orange-tinted
			_fill(0, 10, 48, 14, Color(0.55, 0.45, 0.28), img)
			_fill(0, 10, 48, 2, Color(0.70, 0.58, 0.38), img)
			# Conveyor belt
			_fill(0, 18, 48, 4, Color(0.35, 0.32, 0.28), img)
			# Smaller register
			_fill(4, 2, 14, 12, Color(0.62, 0.52, 0.38), img)
			_fill(4, 2, 14, 2, Color(0.75, 0.62, 0.45), img)
			# Screen
			_fill(6, 4, 10, 6, Color(0.20, 0.35, 0.20), img)
			# Belt lines
			for x in range(0, 48, 6):
				_fill(x, 19, 2, 2, Color(0.50, 0.45, 0.40), img)

	return ImageTexture.create_from_image(img)

func _make_type_sign_tex() -> Texture2D:
	var img := Image.create(48, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	match _checkout_type:
		CheckoutType.STAFFED:
			_fill(2, 2, 44, 6, Color(0.18, 0.35, 0.65), img)
			_draw_text("STAFFED", 5, 3, Color(0.90, 0.95, 1.0), img)
		CheckoutType.SELF:
			_fill(2, 2, 44, 6, Color(0.15, 0.45, 0.45), img)
			_draw_text("SELF-CHECK", 4, 3, Color(0.80, 1.0, 0.90), img)
		CheckoutType.EXPRESS:
			_fill(2, 2, 44, 6, Color(0.75, 0.38, 0.18), img)
			_draw_text("EXPRESS 10", 4, 3, Color(1.0, 0.95, 0.80), img)
			_draw_text("ITEMS OR LESS", 3, 7, Color(1.0, 0.88, 0.70), img)

	return ImageTexture.create_from_image(img)

func _make_cashier_tex() -> Texture2D:
	# Tiny 8x12 cashier NPC sprite (behind the counter)
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body (blue shirt)
	_fill(2, 4, 4, 6, Color(0.18, 0.35, 0.65), img)
	# Head
	_fill(2, 1, 4, 3, Color(0.88, 0.68, 0.48), img)
	# Hair
	_fill(2, 0, 4, 1, Color(0.28, 0.18, 0.10), img)
	return ImageTexture.create_from_image(img)

func _fill(x: int, y: int, w: int, h: int, col: Color, img: Image) -> void:
	x = clampi(x, 0, 48); y = clampi(y, 0, 24)
	w = clampi(w, 0, 48 - x); h = clampi(h, 0, 24 - y)
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _draw_text(text: String, tx: int, ty: int, col: Color, img: Image) -> void:
	# Very simple pixel-font drawer (3x5 chars)
	var char_map := {
		"A": [[1,1,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"B": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,1,0]],
		"C": [[1,1,1],[1,0,0],[1,0,0],[1,0,0],[1,1,1]],
		"D": [[1,1,0],[1,0,1],[1,0,1],[1,0,1],[1,1,0]],
		"E": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,1,1]],
		"F": [[1,1,1],[1,0,0],[1,1,0],[1,0,0],[1,0,0]],
		"G": [[1,1,1],[1,0,0],[1,0,1],[1,0,1],[1,1,1]],
		"H": [[1,0,1],[1,0,1],[1,1,1],[1,0,1],[1,0,1]],
		"I": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[1,1,1]],
		"J": [[0,0,1],[0,0,1],[0,0,1],[1,0,1],[1,1,1]],
		"K": [[1,0,1],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
		"L": [[1,0,0],[1,0,0],[1,0,0],[1,0,0],[1,1,1]],
		"M": [[1,0,1],[1,1,1],[1,0,1],[1,0,1],[1,0,1]],
		"N": [[1,0,1],[1,1,1],[1,1,1],[1,0,1],[1,0,1]],
		"O": [[1,1,1],[1,0,1],[1,0,1],[1,0,1],[1,1,1]],
		"P": [[1,1,1],[1,0,1],[1,1,1],[1,0,0],[1,0,0]],
		"R": [[1,1,0],[1,0,1],[1,1,0],[1,0,1],[1,0,1]],
		"S": [[1,1,1],[1,0,0],[1,1,1],[0,0,1],[1,1,1]],
		"T": [[1,1,1],[0,1,0],[0,1,0],[0,1,0],[0,1,0]],
		"U": [[1,0,1],[1,0,1],[1,0,1],[1,0,1],[1,1,1]],
		"V": [[1,0,1],[1,0,1],[1,0,1],[1,0,1],[0,1,0]],
		"W": [[1,0,1],[1,0,1],[1,0,1],[1,1,1],[1,0,1]],
		"X": [[1,0,1],[1,0,1],[0,1,0],[1,0,1],[1,0,1]],
		"Y": [[1,0,1],[1,0,1],[0,1,0],[0,1,0],[0,1,0]],
		"0": [[1,1,1],[1,0,1],[1,0,1],[1,0,1],[1,1,1]],
		"1": [[0,1,0],[1,1,0],[0,1,0],[0,1,0],[1,1,1]],
		"2": [[1,1,1],[0,0,1],[1,1,1],[1,0,0],[1,1,1]],
		"3": [[1,1,1],[0,0,1],[1,1,1],[0,0,1],[1,1,1]],
		"4": [[1,0,1],[1,0,1],[1,1,1],[0,0,1],[0,0,1]],
		"5": [[1,1,1],[1,0,0],[1,1,1],[0,0,1],[1,1,1]],
		"6": [[1,1,1],[1,0,0],[1,1,1],[1,0,1],[1,1,1]],
		"7": [[1,1,1],[0,0,1],[0,0,1],[0,0,1],[0,0,1]],
		"8": [[1,1,1],[1,0,1],[1,1,1],[1,0,1],[1,1,1]],
		"9": [[1,1,1],[1,0,1],[1,1,1],[0,0,1],[1,1,1]],
		" ": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]],
		"-": [[0,0,0],[0,0,0],[1,1,1],[0,0,0],[0,0,0]],
		".": [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,1,0]],
	}
	var px := tx
	for ch in text.to_upper():
		var bitmap = char_map.get(ch, char_map[" "])
		for row in range(bitmap.size()):
			for col_i in range(bitmap[row].size()):
				if bitmap[row][col_i]:
					var py := ty + row
					if px + col_i < 48 and py < 10:
						img.set_pixel(px + col_i, py, col)
		px += 4

func _physics_process(delta: float) -> void:
	# Error flash animation
	if _has_error:
		_error_timer += delta
		var flash := sin(_error_timer * 8.0) * 0.5 + 0.5
		_error_panel.color = Color(0.8 + flash * 0.2, 0.1, 0.1, 0.9)

	# Idle cashier animation for staffed lanes
	if _checkout_type == CheckoutType.STAFFED and _cashier_sprite != null:
		var t := Time.get_ticks_msec() / 1000.0
		var bob := sin(t * 2.0) * 0.03
		_cashier_sprite.scale = Vector2(1.0, 1.0 + bob)

	# Wave animation when checkout_interacted fires for staffed lanes
	if _is_waving:
		_wave_timer += delta
		var wave_angle := sin(_wave_timer * 6.0) * 0.26  # ±15 degrees in radians
		_cashier_sprite.rotation = wave_angle
		if _wave_timer >= 1.0:
			_is_waving = false
			_wave_timer = 0.0
			_cashier_sprite.rotation = 0.0

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Trigger wave animation for staffed lanes
		if _checkout_type == CheckoutType.STAFFED and _cashier_sprite != null:
			_is_waving = true
			_wave_timer = 0.0
		checkout_interacted.emit(_checkout_id, _checkout_type)

# Called by main to check if express lane allows this many items
func check_express_items(item_count: int) -> bool:
	if _checkout_type != CheckoutType.EXPRESS:
		return true
	if item_count > MAX_EXPRESS_ITEMS:
		express_rejected.emit()
		return false
	return true

# Called during self-checkout completion to trigger random error
func roll_self_checkout_error() -> bool:
	if _checkout_type != CheckoutType.SELF:
		return false
	if randf() < SELF_ERROR_CHANCE:
		_trigger_self_error()
		return true
	return false

func _trigger_self_error() -> void:
	_has_error = true
	_error_timer = 0.0
	_error_panel.visible = true
	_error_label.visible = true
	self_checkout_error.emit()

# Player presses E to dismiss self-checkout error and retry
func dismiss_error() -> void:
	if _has_error:
		_has_error = false
		_error_timer = 0.0
		_error_panel.visible = false
		_error_label.visible = false
		self_checkout_cleared.emit()

# Returns true if this lane has a self-checkout error
func has_error() -> bool:
	return _has_error

# Returns true if this lane is a staffed lane
func is_staffed() -> bool:
	return _checkout_type == CheckoutType.STAFFED

# Returns true if this lane is a self-checkout lane
func is_self_checkout() -> bool:
	return _checkout_type == CheckoutType.SELF

# Returns true if this is an express lane
func is_express() -> bool:
	return _checkout_type == CheckoutType.EXPRESS

# Shows a farewell thought bubble from the cashier at staffed lanes
func show_farewell_bubble() -> void:
	if _checkout_type != CheckoutType.STAFFED:
		return
	var farewells := ["Thanks!", "Come again!", "Have a great day!", "Bye!", "See you!"]
	var msg := farewells[randi() % farewells.size()]
	_thought_label.text = msg
	_thought_bubble.visible = true
	_thought_label.visible = true
	# Auto-hide after 2 seconds
	await _thought_bubble.get_tree().create_timer(2.0).timeout
	_thought_bubble.visible = false
	_thought_label.visible = false
