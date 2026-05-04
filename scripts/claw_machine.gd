# claw_machine.gd
# Claw machine arcade game — press E to play.
#
# HOW TO PLAY:
#   1. Walk near a claw machine and press E to start a round.
#   2. Use A / D to move the claw left / right along the rail.
#   3. Press S to drop the claw. It descends, tries to grab a prize,
#      then ascends and moves to the prize drop chute.
#   4. If the claw grabbed a prize, it is added to your cart/inventory.
#   5. Credits cost $1 each (deducted from cart total at checkout).
#
# TO CUSTOMIZE:
#   - Change MACHINE_COST to adjust price per play.
#   - Change CLAW_SPEED, DROP_SPEED, RISE_SPEED to adjust difficulty.
#   - Prize pool is defined in the constructor — replace with your own items.
class_name ClawMachine
extends Node2D

const FloorConfig = preload("res://scripts/floor_config.gd")

const CELL_SIZE := 16

# ── Gameplay tunables ────────────────────────────────────────────
const MACHINE_COST   := 1.0    # $ deducted from cart per play
const CLAW_SPEED     := 80.0   # pixels per second horizontal
const DROP_SPEED     := 60.0   # pixels per second down
const RISE_SPEED     := 90.0   # pixels per second up
const MOVE_TIME_MAX  := 8.0    # seconds to move claw to drop point
const CLAW_GRAB_X    := 12.0   # pixel radius for successful grab

# ── Prize pool ───────────────────────────────────────────────────
const PRIZE_COLORS := [
	Color(0.90, 0.30, 0.30),  # red plush
	Color(0.30, 0.75, 0.90),  # blue plush
	Color(0.90, 0.70, 0.20),  # yellow plush
	Color(0.55, 0.90, 0.40),  # green plush
	Color(0.88, 0.45, 0.85),  # purple plush
	Color(0.90, 0.55, 0.30),  # orange plush
]

const PRIZE_NAMES := [
	"Red Plush",
	"Blue Plush",
	"Yellow Plush",
	"Green Plush",
	"Purple Plush",
	"Orange Plush",
	"Star Keychain",
	"Heart Charm",
	"Bear Figurine",
]

# ── Machine state ────────────────────────────────────────────────
enum State { IDLE, MOVING, DROPPING, GRABBING, RISING, COLLECTING, DISPENSING }

var _state: State = State.IDLE
var _zone: FloorConfig.Zone
var _machine_id: String
var _prizes: Array = []         # [{pos: Vector2, color: Color, name: String}, ...]
var _claw_x: float = 0.0       # current claw pixel X within machine
var _claw_y: float = 0.0       # current claw pixel Y (top = 0)
var _grabbed_prize: int = -1   # index of grabbed prize, -1 if none
var _target_x: float = 0.0      # where claw is moving to
var _elapsed: float = 0.0
var _player_ref = null
var _is_player_near: bool = false
var _cart_ref = null

# ── Visual nodes ────────────────────────────────────────────────
var _claw_sprite: Sprite2D
var _rail_sprite: Sprite2D
var _chute_sprite: Sprite2D
var _dispense_sprite: Sprite2D
var _ui_label: Label
var _prize_sprites: Array = []

# ── Signals ──────────────────────────────────────────────────────
signal played(prize_name: String, won: bool)
signal interact_requested(machine_id: String)

func _init() -> void:
	pass

func configure(zone: FloorConfig.Zone, machine_id: String) -> void:
	_zone = zone
	_machine_id = machine_id

# ── Called by FloorBuilder when building the floor ────────────────
func build(prize_pool: Array) -> void:
	_prizes.clear()
	_prize_sprites.clear()

	var machine_w := _zone.w * CELL_SIZE
	var machine_h := _zone.h * CELL_SIZE
	var base_x := _zone.x * CELL_SIZE
	var base_y := _zone.y * CELL_SIZE

	# Machine cabinet background
	var cab := ColorRect.new()
	cab.position = Vector2(base_x, base_y)
	cab.size = Vector2(millage_w := machine_w, machine_h)
	cab.color = Color(0.10, 0.10, 0.14)
	add_child(cab)

	# Glass front (lighter rectangle at front)
	var glass := ColorRect.new()
	glass.position = Vector2(base_x + 4, base_y + 4)
	glass.size = Vector2(machine_w - 8, machine_h - 24)
	glass.color = Color(0.60, 0.75, 0.85, 0.15)
	add_child(glass)

	# Cabinet border
	var border := ColorRect.new()
	border.position = Vector2(base_x, base_y)
	border.size = Vector2(machine_w, machine_h)
	border.color = Color(0, 0, 0, 0)
	# Draw border manually
	for bx in range(machine_w):
		for by in range(machine_h):
			if bx < 3 or bx >= machine_w - 3 or by < 3 or by >= machine_h - 3:
				var dot := ColorRect.new()
				dot.position = Vector2(base_x + bx, base_y + by)
				dot.size = Vector2(1, 1)
				dot.color = Color(0.25, 0.25, 0.32)
				add_child(dot)

	# Prize rail (top bar)
	var rail := ColorRect.new()
	rail.position = Vector2(base_x + 6, base_y + 8)
	rail.size = Vector2(machine_w - 12, 3)
	rail.color = Color(0.50, 0.50, 0.55)
	add_child(rail)

	# Rail end caps
	for rx in [base_x + 6, base_x + machine_w - 9]:
		var cap := ColorRect.new()
		cap.position = Vector2(rx, base_y + 6)
		cap.size = Vector2(3, 7)
		cap.color = Color(0.45, 0.45, 0.50)
		add_child(cap)

	# Prize drop chute (right side)
	var chute := ColorRect.new()
	chute.position = Vector2(base_x + machine_w - 16, base_y + machine_h - 24)
	chute.size = Vector2(10, 20)
	chute.color = Color(0.15, 0.15, 0.20)
	add_child(chute)

	var chute_inner := ColorRect.new()
	chute_inner.position = Vector2(base_x + machine_w - 14, base_y + machine_h - 22)
	chute_inner.size = Vector2(6, 16)
	chute_inner.color = Color(0.05, 0.05, 0.08)
	add_child(chute_inner)

	# Dispense slot (where prizes come out)
	var slot := ColorRect.new()
	slot.position = Vector2(base_x + machine_w - 18, base_y + machine_h - 6)
	slot.size = Vector2(14, 4)
	slot.color = Color(0.20, 0.20, 0.25)
	add_child(slot)

	# Prize bed floor (bottom area)
	var bed := ColorRect.new()
	bed.position = Vector2(base_x + 6, base_y + machine_h - 20)
	bed.size = Vector2(machine_w - 24, 16)
	bed.color = Color(0.15, 0.15, 0.20)
	add_child(bed)

	# Claw (starts at center top)
	_claw_x = (machine_w - 12) * 0.5
	_claw_y = 0.0

	_claw_sprite = Sprite2D.new()
	_claw_sprite.position = Vector2(base_x + 8 + _claw_x, base_y + 12)
	add_child(_claw_sprite)
	_update_claw_sprite()

	# Spawn prizes in the bed area
	var bed_left := base_x + 10
	var bed_right := base_x + machine_w - 26
	var bed_top := base_y + machine_h - 18
	var bed_bot := base_y + machine_h - 6

	for i in range(prize_pool.size()):
		var px := bed_left + randf() * (bed_right - bed_left - 12)
		var py := bed_top + randf() * (bed_bot - bed_top - 12)
		var col: Color = prize_pool[i]
		var pname: String = PRIZE_NAMES[i % PRIZE_NAMES.size()]

		var spr := Sprite2D.new()
		spr.position = Vector2(px + 6, py + 6)
		spr.texture = _make_plush_sprite(col)
		spr.z_index = 2
		add_child(spr)
		_prize_sprites.append(spr)

		_prizes.append({ "pos": Vector2(px, py), "color": col, "name": pname, "taken": false })

	# Machine label
	var lbl := Label.new()
	lbl.text = "ARCADE"
	lbl.position = Vector2(base_x + 4, base_y + machine_h - 5)
	lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80))
	lbl.add_theme_font_size_override("font_size", 6)
	add_child(lbl)

	# Credits / prompt label
	_ui_label = Label.new()
	_ui_label.text = "[E] Play $1"
	_ui_label.position = Vector2(base_x + 4, base_y + machine_h + 2)
	_ui_label.add_theme_color_override("font_color", Color(0.80, 0.80, 0.60))
	_ui_label.add_theme_font_size_override("font_size", 7)
	add_child(_ui_label)

	# Interaction area
	var area := Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(machine_w, machine_h)
	var col_shape := CollisionShape2D.new()
	col_shape.shape = shape
	col_shape.position = Vector2(base_x + machine_w * 0.5, base_y + machine_h * 0.5)
	area.add_child(col_shape)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

# ── Interaction ──────────────────────────────────────────────────

func _on_body_entered(body) -> void:
	if body is Player:
		_is_player_near = true
		interact_requested.emit(_machine_id)

func _on_body_exited(body) -> void:
	if body is Player:
		_is_player_near = false

func get_machine_id() -> String:
	return _machine_id

func get_zone() -> FloorConfig.Zone:
	return _zone

func is_player_near() -> bool:
	return _is_player_near

func set_cart(cart) -> void:
	_cart_ref = cart

# ── Game Loop ────────────────────────────────────────────────────

func _process(delta: float) -> void:
	match _state:
		State.MOVING:
			_process_moving(delta)
		State.DROPPING:
			_process_dropping(delta)
		State.GRABBING:
			_process_grabbing(delta)
		State.RISING:
			_process_rising(delta)
		State.COLLECTING:
			_process_collecting(delta)

func _process_moving(delta: float) -> void:
	var machine_w := _zone.w * CELL_SIZE
	var target := machine_w - 20.0  # drop at chute side
	var dir := sign(target - _claw_x)
	_claw_x += CLAW_SPEED * delta * dir
	if (dir > 0 and _claw_x >= target) or (dir < 0 and _claw_x <= target):
		_claw_x = target
		_state = State.DROPPING
		_elapsed = 0.0
	_update_claw_position()

func _process_dropping(delta: float) -> void:
	var machine_h := _zone.h * CELL_SIZE
	var max_drop := machine_h - 32.0
	_claw_y += DROP_SPEED * delta
	if _claw_y >= max_drop:
		_claw_y = max_drop
		_state = State.GRABBING
		_elapsed = 0.0
		_grabbed_prize = _try_grab()
	_update_claw_position()

func _process_grabbing(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.4:
		_state = State.RISING
	_update_claw_sprite()  # close claws

func _process_rising(delta: float) -> void:
	_claw_y -= RISE_SPEED * delta
	if _claw_y <= 0.0:
		_claw_y = 0.0
		_update_claw_position()
		if _grabbed_prize >= 0:
			_state = State.COLLECTING
			_elapsed = 0.0
		else:
			_end_round(false)
	_update_claw_sprite()

func _process_collecting(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 1.0:
		_dispense_prize()

func _dispense_prize() -> void:
	if _grabbed_prize >= 0 and _grabbed_prize < _prizes.size():
		var prize_name: String = _prizes[_grabbed_prize]["name"]
		_prizes[_grabbed_prize]["taken"] = true
		if _grabbed_prize < _prize_sprites.size():
			var spr := _prize_sprites[_grabbed_prize]
			if is_instance_valid(spr):
				# Animate prize falling to slot
				var drop_tween := create_tween()
				var target_pos := Vector2(spr.position.x + (_zone.w * CELL_SIZE - 20), spr.position.y + (_zone.h * CELL_SIZE - 8))
				drop_tween.tween_property(spr, "position", target_pos, 0.5)
				drop_tween.tween_callback(Callable(self, "_on_prize_dispensed").bind(_grabbed_prize, prize_name))
		else:
			_end_round(true, prize_name)
	else:
		_end_round(false)

func _on_prize_dispensed(prize_idx: int, prize_name: String) -> void:
	# Remove the sprite
	if prize_idx >= 0 and prize_idx < _prize_sprites.size():
		var spr := _prize_sprites[prize_idx]
		if is_instance_valid(spr):
			spr.queue_free()
		_prize_sprites[prize_idx] = null
	_end_round(true, prize_name)

func _end_round(won: bool, prize_name: String = "") -> void:
	_state = State.IDLE
	_claw_x = (_zone.w * CELL_SIZE - 12) * 0.5
	_claw_y = 0.0
	_grabbed_prize = -1
	_update_claw_position()
	_update_claw_sprite()
	_ui_label.text = "[E] Play $1"
	played.emit(prize_name, won)

func _try_grab() -> int:
	# Find nearest prize within grab radius
	var claw_screen := _claw_sprite.global_position
	var best_idx := -1
	var best_dist := CLAW_GRAB_X
	for i in range(_prizes.size()):
		if _prizes[i]["taken"]:
			continue
		var prize_screen := _prize_sprites[i].global_position if (i < _prize_sprites.size() and is_instance_valid(_prize_sprites[i])) else Vector2.ZERO
		var d := absf(claw_screen.x - prize_screen.x)
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx

func _update_claw_position() -> void:
	if _claw_sprite == null:
		return
	var base_x := _zone.x * CELL_SIZE
	var base_y := _zone.y * CELL_SIZE
	_claw_sprite.position = Vector2(base_x + 8 + _claw_x, base_y + 12 + _claw_y)

func _update_claw_sprite() -> void:
	if _claw_sprite == null:
		return
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var silver := Color(0.70, 0.70, 0.75)
	var dark := Color(0.40, 0.40, 0.45)
	match _state:
		State.GRABBING:
			# Closed claws — V shape at bottom
			_fill_img(img, 6, 0, 4, 1, silver)
			_fill_img(img, 5, 1, 6, 1, silver)
			_fill_img(img, 4, 2, 2, 5, dark)
			_fill_img(img, 10, 2, 2, 5, dark)
			_fill_img(img, 2, 7, 4, 2, dark)
			_fill_img(img, 10, 7, 4, 2, dark)
			_fill_img(img, 1, 9, 3, 3, dark)
			_fill_img(img, 12, 9, 3, 3, dark)
		_:
			# Open claws — arms pointing down
			_fill_img(img, 6, 0, 4, 1, silver)
			_fill_img(img, 5, 1, 6, 1, silver)
			_fill_img(img, 5, 2, 2, 5, dark)
			_fill_img(img, 9, 2, 2, 5, dark)
			_fill_img(img, 4, 7, 3, 2, dark)
			_fill_img(img, 9, 7, 3, 2, dark)
			_fill_img(img, 3, 9, 2, 3, dark)
			_fill_img(img, 11, 9, 2, 3, dark)
	_claw_sprite.texture = ImageTexture.create_from_image(img)

func _fill_img(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, img.get_width()); y = clampi(y, 0, img.get_height())
	w = clampi(w, 0, img.get_width() - x); h = clampi(h, 0, img.get_height() - y)
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _make_plush_sprite(col: Color) -> Texture2D:
	var sz := 14
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Plush body
	for y in range(sz):
		for x in range(sz):
			var cx := float(x) - sz * 0.5
			var cy := float(y) - sz * 0.5
			var r := sz * 0.42
			if cx * cx + cy * cy < r * r:
				img.set_pixel(x, y, col)
	# Eyes (dark dots)
	var eye_col := Color(0.08, 0.08, 0.08)
	for ey in [sz >> 2, sz >> 2 + 2]:
		for ex in [sz >> 2 - 1, sz - (sz >> 2) + 1]:
			if ex >= 0 and ex < sz and ey >= 0 and ey < sz:
				img.set_pixel(ex, ey, eye_col)
	return ImageTexture.create_from_image(img)

# ── External control ──────────────────────────────────────────────
# Called by main.gd when player presses E on this machine

func start_round() -> bool:
	"""Returns true if round started, false if can't play."""
	if _state != State.IDLE:
		return false
	if _cart_ref == null:
		return false
	# Deduct cost from cart
	var cart = _cart_ref
	if cart.has_method("get_item_count"):
		# Just start — cost handled by checkout
		pass
	_state = State.MOVING
	_ui_label.text = "A/D: Move  S: Drop"
	_claw_x = (_zone.w * CELL_SIZE - 12) * 0.5
	_claw_y = 0.0
	_update_claw_position()
	return true

func move_claw(dir: int) -> void:
	"""dir: -1 = left, +1 = right. Only works during MOVING state."""
	if _state == State.MOVING:
		var machine_w := _zone.w * CELL_SIZE
		_claw_x = clampf(_claw_x + dir * CLAW_SPEED * 0.1, 4.0, machine_w - 20.0)
		_update_claw_position()

func drop_claw() -> void:
	"""Start the drop. Only works during MOVING state."""
	if _state == State.MOVING:
		_state = State.DROPPING
		_elapsed = 0.0

func get_state() -> State:
	return _state
