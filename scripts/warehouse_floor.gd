# warehouse.gd
# Floor 11 warehouse zone — truck, forklift, conveyor belt control for staff.
class_name WarehouseFloor
extends Node2D

const CELL_SIZE := 16

var _zone: Dictionary = {}
var _player_ref: Node2D = null
var _is_staff: bool = false
var _player_stats = null

# Truck state
var _truck_pos := Vector2.ZERO       # tile position
var _truck_moving := false
var _truck_dir := Vector2.ZERO

# Forklift state
var _forklift_pos := Vector2.ZERO
var _forklift_load := false           # has a pallet
var _forklift_height := 0.0           # 0.0 to 1.0 (height of forks)

# Conveyor belt
var _conveyor_running := false
var _conveyor_items: Array = []        # [{tile_pos, progress}]
var _conveyor_speed := 30.0            # tiles per second

# Packing station
var _packing_slots: Array = []        # packed boxes ready

# UI elements
var _ui_container: Control = null
var _status_lbl: Label = null
var _truck_sprite: Sprite2D = null
var _forklift_sprite: Sprite2D = null
var _conveyor_sprites: Array = []

signal truck_delivered(items: int)

func _init() -> void:
	_zone = {
		"name": "Warehouse",
		"zone_type": FloorConfig.ZONE_WAREHOUSE,
		"x": 2, "y": 3, "w": 78, "h": 38,
	}

func configure(zone: Dictionary) -> void:
	_zone = zone
	_build_ui()
	_build_sprites()

func _build_ui() -> void:
	_ui_container = Control.new()
	_ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui_container)

	_status_lbl = Label.new()
	_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	_status_lbl.add_theme_font_size_override("font_size", 8)
	_status_lbl.position = Vector2(4, 4)
	_status_lbl.text = "[WASD] Move Truck   [E] Use Forklift   [Space] Stop   [F] Start Conveyor"
	_ui_container.add_child(_status_lbl)

func _build_sprites() -> void:
	# Truck sprite (top-down view, brown/beige delivery truck)
	_truck_sprite = Sprite2D.new()
	_truck_sprite.texture = _make_truck_texture()
	_truck_sprite.position = Vector2(_truck_pos.x * CELL_SIZE, _truck_pos.y * CELL_SIZE)
	_truck_sprite.hframes = 4
	add_child(_truck_sprite)

	# Forklift sprite
	_forklift_sprite = Sprite2D.new()
	_forklift_sprite.texture = _make_forklift_texture()
	_forklift_sprite.position = Vector2(_forklift_pos.x * CELL_SIZE, _forklift_pos.y * CELL_SIZE)
	_forklift_sprite.hframes = 4
	add_child(_forklift_sprite)

func _make_truck_texture() -> ImageTexture:
	var img := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.50, 0.38, 0.28, 1.0))  # brown truck body
	# Cab
	for x in range(2, 8):
		for y in range(6, 18):
			img.set_pixel(x, y, Color(0.60, 0.50, 0.38, 1.0))
	# Cargo area
	for x in range(8, 30):
		for y in range(4, 20):
			img.set_pixel(x, y, Color(0.45, 0.35, 0.25, 1.0))
	# Wheels
	for wx in [4, 26]:
		for wy in [2, 20]:
			img.set_pixel(wx, wy, Color(0.15, 0.15, 0.15, 1.0))
	return ImageTexture.create_from_image(img)

func _make_forklift_texture() -> ImageTexture:
	var img := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	for x in range(8, 16):
		for y in range(10, 28):
			img.set_pixel(x, y, Color(0.80, 0.60, 0.20, 1.0))
	# Mast
	for x in range(10, 14):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.50, 0.50, 0.55, 1.0))
	# Forks
	for x in range(4, 10):
		img.set_pixel(x, 28, Color(0.60, 0.60, 0.65, 1.0))
		img.set_pixel(x, 30, Color(0.60, 0.60, 0.65, 1.0))
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	if not _is_staff:
		return
	_update_conveyor(delta)
	_update_truck_animation(delta)

func _update_conveyor(delta: float) -> void:
	if not _conveyor_running:
		return
	for item in _conveyor_items:
		item["progress"] += delta * _conveyor_speed
		if item["progress"] >= 1.0:
			# Item reached end of conveyor
			var tile_pos = item["tile_pos"] as Vector2
			item["tile_pos"] = Vector2(tile_pos.x + 1, tile_pos.y)
			item["progress"] = 0.0
			if tile_pos.x > 50:
				# Delivered to packing — remove item, increment count
				_packing_slots.append({"box": true})
				_conveyor_items.erase(item)

func _update_truck_animation(_delta: float) -> void:
	if _truck_sprite != null and _truck_moving:
		# Bob animation while moving
		pass

# ─── Staff interaction ──────────────────────────────────────────────

func set_staff_mode(staff: bool) -> void:
	_is_staff = staff
	if _ui_container:
		_ui_container.visible = staff

func is_in_truck_dock(pos: Vector2) -> bool:
	var dock_rect := Rect2(2 * CELL_SIZE, 3 * CELL_SIZE, 20 * CELL_SIZE, 14 * CELL_SIZE)
	return dock_rect.has_point(pos)

func is_at_forklift(pos: Vector2) -> bool:
	var fl_rect := Rect2(2 * CELL_SIZE, 19 * CELL_SIZE, 20 * CELL_SIZE, 12 * CELL_SIZE)
	return fl_rect.has_point(pos)

func is_at_conveyor(pos: Vector2) -> bool:
	var cv_rect := Rect2(24 * CELL_SIZE, 3 * CELL_SIZE, 30 * CELL_SIZE, 12 * CELL_SIZE)
	return cv_rect.has_point(pos)

func is_at_packing_station(pos: Vector2) -> bool:
	var pk_rect := Rect2(24 * CELL_SIZE, 19 * CELL_SIZE, 30 * CELL_SIZE, 12 * CELL_SIZE)
	return pk_rect.has_point(pos)

# ─── Player driving truck ──────────────────────────────────────────

func enter_truck_dock() -> bool:
	return _is_staff

func drive_truck(dir: Vector2) -> void:
	if not _is_staff:
		return
	_truck_pos += dir
	_truck_pos.x = clamp(_truck_pos.x, 2, 76)
	_truck_pos.y = clamp(_truck_pos.y, 3, 34)
	_truck_moving = true
	_truck_dir = dir
	if _truck_sprite:
		_truck_sprite.position = Vector2(_truck_pos.x * CELL_SIZE, _truck_pos.y * CELL_SIZE)
		if dir.x < 0:
			_truck_sprite.flip_h = true
		elif dir.x > 0:
			_truck_sprite.flip_h = false

func stop_truck() -> void:
	_truck_moving = false

# ─── Forklift controls ─────────────────────────────────────────────

func use_forklift(action: String) -> void:
	if not _is_staff:
		return
	match action:
		"raise":
			_forklift_height = clamp(_forklift_height + 0.1, 0.0, 1.0)
		"lower":
			_forklift_height = clamp(_forklift_height - 0.1, 0.0, 1.0)
		"pickup":
			_forklift_load = true
		"drop":
			if _forklift_load:
				_forklift_load = false
				# Drop pallet at current position
				truck_delivered.emit(5)  # 5 items worth
	_update_forklift_sprite()

func _update_forklift_sprite() -> void:
	if _forklift_sprite:
		var frame := int(_forklift_height * 3.0)
		_forklift_sprite.frame = clamp(frame, 0, 3)

# ─── Conveyor controls ─────────────────────────────────────────────

func toggle_conveyor() -> void:
	_conveyor_running = not _conveyor_running
	_update_status_label()

func add_conveyor_item() -> void:
	if _conveyor_items.size() < 8:
		_conveyor_items.append({"tile_pos": Vector2(24, 8), "progress": 0.0})

func _update_status_label() -> void:
	if _status_lbl:
		var truck_status := "Truck: (%.0f, %.0f)" % [_truck_pos.x, _truck_pos.y]
		var conveyor_status := "Conveyor: %s" % ("RUNNING" if _conveyor_running else "OFF")
		_status_lbl.text = "STAFF | %s | %s | [WASD] Truck | [Q/E] Forklift | [F] Conveyor | [P] Packing" % [
			truck_status, conveyor_status]

# ─── Self-checkout robot ────────────────────────────────────────────

class CounterRobot:
	extends Node
	var _counter_ref: Node = null
	var _scan_speed: float = 1.5   # 1.5x faster than human

	func configure(counter) -> void:
		_counter_ref = counter

	func auto_scan_item(item_name: String) -> void:
		# Robots scan 50% faster, no errors
		await Engine.get_main_loop().create_timer(0.6 / _scan_speed).timeout
		if _counter_ref and _counter_ref.has_method("robot_scan_item"):
			_counter_ref.robot_scan_item(item_name)

# ─── Shelf robot ────────────────────────────────────────────────────

class ShelfRobot:
	extends Node
	var _current_section: Node = null
	var _restock_timer: float = 0.0
	var _restock_interval: float = 15.0  # seconds between auto-restock

	func _process(delta: float) -> void:
		_restock_timer += delta
		if _restock_timer >= _restock_interval:
			_restock_timer = 0.0
			_restock_section()

	func _restock_section() -> void:
		if _current_section and _current_section.has_method("auto_restock"):
			_current_section.auto_restock()

# ─── Cleaning robot ─────────────────────────────────────────────────

class CleaningRobot:
	extends Node
	var _clean_target: Vector2 = Vector2.ZERO
	var _battery: float = 1.0

	func _process(delta: float) -> void:
		_battery -= delta * 0.005  # slow battery drain
		if _battery <= 0.0:
			_return_to_charging_station()

	func start_cleaning(from_pos: Vector2, to_pos: Vector2) -> void:
		_clean_target = to_pos
		# Move to target and "clean" (wipe animation)
		pass

	func _return_to_charging_station() -> void:
		_battery = 1.0

# ─── Security robot ─────────────────────────────────────────────────

class SecurityRobot:
	extends Node
	var _patrol_route: Array = []
	var _patrol_index: int = 0
	var _alert_level: int = 0

	func configure(route: Array) -> void:
		_patrol_route = route

	func _process(delta: float) -> void:
		# Patrol between points
		if _patrol_route.is_empty():
			return
		_patrol_index = (_patrol_index + 1) % _patrol_route.size()

# ─── Delivery robot ────────────────────────────────────────────────
# 🔥 修复：添加仓库父类引用，解决信号访问报错
class DeliveryRobot:
	extends Node
	var _cargo: Array = []
	var _destination: Vector2 = Vector2.ZERO
	var _state: String = "idle"  # idle, going_to_warehouse, loading, delivering, returning
	var _warehouse: WarehouseFloor = null  # 新增：存储外部仓库类引用

	# 修复：传入仓库引用，绑定信号
	func start_delivery(from: Vector2, to: Vector2, items: Array, warehouse_ref: WarehouseFloor) -> void:
		_cargo = items
		_destination = to
		_state = "going_to_warehouse"
		_warehouse = warehouse_ref  # 绑定父类

	func _process(delta: float) -> void:
		match _state:
			"going_to_warehouse":
				_state = "loading"
			"loading":
				if _cargo.is_empty():
					# 修复：通过父类引用发射信号
					if _warehouse:
						_warehouse.truck_delivered.emit(5)
					_state = "returning"
				else:
					await Engine.get_main_loop().create_timer(1.0).timeout
					_cargo.pop_back()
			"returning":
				_state = "idle"
