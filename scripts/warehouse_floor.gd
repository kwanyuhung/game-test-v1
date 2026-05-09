# warehouse_floor.gd
# Floor 11 warehouse zone — truck, forklift, conveyor belt control for staff.
# ═══════════════════════════════════════════════════════════════════════════════

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

# Factory Robots
var _factory_robot_1: FactoryRobot1 = null  # Checkout counter robot
var _factory_robot_2: FactoryRobot2 = null  # Shelf scanning robot
var _factory_robot_3: FactoryRobot3 = null  # Warehouse robots (cleaning/security/delivery)

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
	_build_factory_robots()

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

func _build_factory_robots() -> void:
	# Factory Robot 1: Checkout Counter Robot
	_factory_robot_1 = FactoryRobot1.new()
	add_child(_factory_robot_1)
	
	# Factory Robot 2: Shelf Scanning Robot
	_factory_robot_2 = FactoryRobot2.new()
	add_child(_factory_robot_2)
	
	# Factory Robot 3: Warehouse Robot (cleaning mode by default)
	_factory_robot_3 = FactoryRobot3.new()
	_factory_robot_3.configure(FactoryRobot3.RobotMode.CLEANING)
	add_child(_factory_robot_3)

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

# ─── Factory Robot Visibility Control ─────────────────────────────

func set_factory_robot_visibility(draw_r1: bool, draw_r2: bool, draw_r3: bool) -> void:
	if _factory_robot_1:
		_factory_robot_1.set_active(draw_r1)
	if _factory_robot_2:
		_factory_robot_2.set_active(draw_r2)
	if _factory_robot_3:
		_factory_robot_3.set_active(draw_r3)

# ─── Factory Robot 1: Self-checkout Counter Robot ──────────────────
# Appears at checkout lanes, auto-scans items faster than humans

class FactoryRobot1 extends Node2D:
	var _sprite: Sprite2D = null
	var _scan_anim_timer: float = 0.0
	var _is_active: bool = true

	func _init() -> void:
		position = Vector2(50 * WarehouseFloor.CELL_SIZE, 45 * WarehouseFloor.CELL_SIZE)

	func _ready() -> void:
		_build_sprite()

	func _build_sprite() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = _make_counter_robot_texture()
		_sprite.hframes = 4
		add_child(_sprite)

	func _make_counter_robot_texture() -> ImageTexture:
		var img := Image.create(24, 28, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		
		# Body (metallic silver)
		for x in range(4, 20):
			for y in range(8, 24):
				img.set_pixel(x, y, Color(0.70, 0.72, 0.78, 1.0))
		
		# Head unit (dark screen)
		for x in range(6, 18):
			for y in range(2, 8):
				img.set_pixel(x, y, Color(0.25, 0.28, 0.35, 1.0))
		
		# Scanner eye (cyan glow)
		for x in range(8, 16):
			for y in range(4, 6):
				img.set_pixel(x, y, Color(0.20, 1.0, 0.85, 1.0))
		
		# Base platform
		for x in range(2, 22):
			img.set_pixel(x, 26, Color(0.40, 0.42, 0.48, 1.0))
		
		# Scanner beam indicator
		for y in range(6, 10):
			img.set_pixel(12, y, Color(0.20, 1.0, 0.85, 0.6))
		
		return ImageTexture.create_from_image(img)

	func _process(delta: float) -> void:
		if not _is_active:
			return
		_scan_anim_timer += delta
		if _sprite:
			_sprite.frame = int(_scan_anim_timer * 2) % 4

	func set_active(active: bool) -> void:
		_is_active = active
		if _sprite:
			_sprite.visible = active

# ─── Factory Robot 2: Shelf Scanning Robot ─────────────────────────
# Patrols aisles, scans shelf inventory

class FactoryRobot2 extends Node2D:
	var _sprite: Sprite2D = null
	var _patrol_pos: Vector2 = Vector2.ZERO
	var _patrol_target: Vector2 = Vector2.ZERO
	var _anim_timer: float = 0.0
	var _is_active: bool = true
	var _patrol_points: Array = []

	func _init() -> void:
		position = Vector2(30 * WarehouseFloor.CELL_SIZE, 20 * WarehouseFloor.CELL_SIZE)
		_patrol_pos = position
		_patrol_target = Vector2(50 * WarehouseFloor.CELL_SIZE, 20 * WarehouseFloor.CELL_SIZE)
		_patrol_points = [
			Vector2(30 * WarehouseFloor.CELL_SIZE, 20 * WarehouseFloor.CELL_SIZE),
			Vector2(50 * WarehouseFloor.CELL_SIZE, 20 * WarehouseFloor.CELL_SIZE),
			Vector2(50 * WarehouseFloor.CELL_SIZE, 35 * WarehouseFloor.CELL_SIZE),
			Vector2(30 * WarehouseFloor.CELL_SIZE, 35 * WarehouseFloor.CELL_SIZE),
		]

	func _ready() -> void:
		_build_sprite()

	func _build_sprite() -> void:
		_sprite = Sprite2D.new()
		_sprite.texture = _make_shelf_robot_texture()
		_sprite.hframes = 4
		add_child(_sprite)

	func _make_shelf_robot_texture() -> ImageTexture:
		var img := Image.create(20, 30, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		
		# Body (tall narrow)
		for x in range(5, 15):
			for y in range(10, 26):
				img.set_pixel(x, y, Color(0.60, 0.62, 0.68, 1.0))
		
		# Scanner dome head
		for x in range(4, 16):
			for y in range(2, 10):
				img.set_pixel(x, y, Color(0.50, 0.52, 0.58, 1.0))
		
		# Green scanning laser eye
		for x in range(6, 14):
			for y in range(4, 8):
				img.set_pixel(x, y, Color(0.15, 0.85, 0.40, 1.0))
		
		# Status LEDs (green)
		img.set_pixel(6, 12, Color(0.20, 1.0, 0.50, 1.0))
		img.set_pixel(13, 12, Color(0.20, 1.0, 0.50, 1.0))
		
		# Wheels/base
		img.set_pixel(5, 27, Color(0.35, 0.37, 0.42, 1.0))
		img.set_pixel(14, 27, Color(0.35, 0.37, 0.42, 1.0))
		
		return ImageTexture.create_from_image(img)

	func _process(delta: float) -> void:
		if not _is_active:
			return
		_anim_timer += delta
		# Move towards patrol target
		var to_target := _patrol_target - _patrol_pos
		var dist := to_target.length()
		if dist < 5.0:
			# Reached target, move to next patrol point
			var idx := _patrol_points.find(_patrol_target)
			_patrol_target = _patrol_points[(idx + 1) % _patrol_points.size()]
		else:
			var dir := to_target / dist
			_patrol_pos += dir * 40.0 * delta
			position = _patrol_pos
			if dir.x < 0:
				_sprite.flip_h = true
			else:
				_sprite.flip_h = false
		if _sprite:
			_sprite.frame = int(_anim_timer * 3) % 4

	func set_active(active: bool) -> void:
		_is_active = active
		if _sprite:
			_sprite.visible = active

# ─── Factory Robot 3: Warehouse Robots (Cleaning/Security/Delivery) ──
# Multiple robot types for warehouse operations

class FactoryRobot3 extends Node2D:
	enum RobotMode { CLEANING, SECURITY, DELIVERY }
	var _mode: RobotMode = RobotMode.CLEANING
	var _sprite: Sprite2D = null
	var _anim_timer: float = 0.0
	var _is_active: bool = true
	var _pos: Vector2 = Vector2.ZERO
	var _target: Vector2 = Vector2.ZERO

	func _init() -> void:
		_mode = RobotMode.CLEANING
		position = Vector2(60 * WarehouseFloor.CELL_SIZE, 25 * WarehouseFloor.CELL_SIZE)
		_pos = position
		_target = Vector2(70 * WarehouseFloor.CELL_SIZE, 30 * WarehouseFloor.CELL_SIZE)

	func configure(mode: RobotMode) -> void:
		_mode = mode
		_build_sprite()

	func _ready() -> void:
		_build_sprite()

	func _build_sprite() -> void:
		if _sprite:
			_sprite.queue_free()
		_sprite = Sprite2D.new()
		match _mode:
			RobotMode.CLEANING:
				_sprite.texture = _make_cleaning_robot_texture()
			RobotMode.SECURITY:
				_sprite.texture = _make_security_robot_texture()
			RobotMode.DELIVERY:
				_sprite.texture = _make_delivery_robot_texture()
		_sprite.hframes = 4
		add_child(_sprite)

	func _make_cleaning_robot_texture() -> ImageTexture:
		var img := Image.create(22, 22, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		
		# Disk-shaped cleaning robot
		for x in range(2, 20):
			for y in range(2, 20):
				var dx := x - 11; var dy := y - 11
				if dx*dx + dy*dy < 88:
					img.set_pixel(x, y, Color(0.72, 0.74, 0.78, 1.0))
		
		# Inner disk
		for x in range(5, 17):
			for y in range(5, 17):
				var dx := x - 11; var dy := y - 11
				if dx*dx + dy*dy < 30:
					img.set_pixel(x, y, Color(0.50, 0.52, 0.56, 1.0))
		
		# Brush center (cyan)
		for x in range(8, 14):
			for y in range(8, 14):
				var dx := x - 11; var dy := y - 11
				if dx*dx + dy*dy < 14:
					img.set_pixel(x, y, Color(0.20, 0.80, 0.70, 1.0))
		
		# LED indicators
		img.set_pixel(6, 6, Color(0.20, 1.0, 0.85, 1.0))
		img.set_pixel(15, 6, Color(0.20, 1.0, 0.85, 1.0))
		img.set_pixel(6, 15, Color(0.20, 1.0, 0.85, 1.0))
		img.set_pixel(15, 15, Color(0.20, 1.0, 0.85, 1.0))
		
		return ImageTexture.create_from_image(img)

	func _make_security_robot_texture() -> ImageTexture:
		var img := Image.create(20, 24, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		
		# Dark armored body
		for x in range(2, 18):
			for y in range(8, 22):
				img.set_pixel(x, y, Color(0.25, 0.27, 0.32, 1.0))
		
		# Head unit
		for x in range(4, 16):
			for y in range(2, 9):
				img.set_pixel(x, y, Color(0.20, 0.22, 0.28, 1.0))
		
		# RED scanner eye
		for x in range(5, 15):
			for y in range(3, 7):
				img.set_pixel(x, y, Color(0.90, 0.15, 0.10, 1.0))
		
		# Shoulder warning lights (blue)
		for x in [2, 17]:
			img.set_pixel(x, 9, Color(0.15, 0.50, 1.0, 1.0))
			img.set_pixel(x, 10, Color(0.15, 0.50, 1.0, 1.0))
		
		# Red status LEDs
		img.set_pixel(5, 14, Color(1.0, 0.20, 0.15, 1.0))
		img.set_pixel(6, 14, Color(1.0, 0.20, 0.15, 1.0))
		img.set_pixel(13, 14, Color(1.0, 0.20, 0.15, 1.0))
		img.set_pixel(14, 14, Color(1.0, 0.20, 0.15, 1.0))
		
		return ImageTexture.create_from_image(img)

	func _make_delivery_robot_texture() -> ImageTexture:
		var img := Image.create(24, 22, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		
		# Main cargo body
		for x in range(2, 22):
			for y in range(8, 20):
				img.set_pixel(x, y, Color(0.50, 0.55, 0.65, 1.0))
		
		# Darker cargo bay
		for x in range(4, 10):
			for y in range(9, 15):
				img.set_pixel(x, y, Color(0.35, 0.38, 0.45, 1.0))
		
		# Cargo tray on top
		for x in range(3, 21):
			for y in range(5, 9):
				img.set_pixel(x, y, Color(0.40, 0.42, 0.48, 1.0))
		
		# Robot head (orange = delivering)
		for x in range(10, 16):
			for y in range(2, 5):
				img.set_pixel(x, y, Color(1.0, 0.50, 0.10, 1.0))
		
		# LED eyes
		img.set_pixel(12, 2, Color(1.0, 1.0, 1.0, 1.0))
		img.set_pixel(13, 2, Color(1.0, 1.0, 1.0, 1.0))
		
		# Status panel (cyan)
		img.set_pixel(12, 16, Color(0.20, 1.0, 0.85, 1.0))
		img.set_pixel(13, 16, Color(0.20, 1.0, 0.85, 1.0))
		
		return ImageTexture.create_from_image(img)

	func _process(delta: float) -> void:
		if not _is_active:
			return
		_anim_timer += delta
		# Simple patrol movement
		var to_target := _target - _pos
		var dist := to_target.length()
		if dist < 5.0:
			# Swap target
			_target = Vector2(60 * WarehouseFloor.CELL_SIZE, 25 * WarehouseFloor.CELL_SIZE) if _target == Vector2(70 * WarehouseFloor.CELL_SIZE, 30 * WarehouseFloor.CELL_SIZE) else Vector2(70 * WarehouseFloor.CELL_SIZE, 30 * WarehouseFloor.CELL_SIZE)
		else:
			var dir := to_target / dist
			_pos += dir * 35.0 * delta
			position = _pos
			if dir.x < 0:
				_sprite.flip_h = true
			else:
				_sprite.flip_h = false
		if _sprite:
			_sprite.frame = int(_anim_timer * 2) % 4

	func set_active(active: bool) -> void:
		_is_active = active
		if _sprite:
			_sprite.visible = active

# ─── Legacy robot classes (kept for compatibility) ─────────────────

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

class DeliveryRobot:
	extends Node
	var _cargo: Array = []
	var _destination: Vector2 = Vector2.ZERO
	var _state: String = "idle"  # idle, going_to_warehouse, loading, delivering, returning
	var _warehouse_ref: WarehouseFloor = null

	func start_delivery(from: Vector2, to: Vector2, items: Array, warehouse_ref: WarehouseFloor) -> void:
		_cargo = items
		_destination = to
		_state = "going_to_warehouse"
		_warehouse_ref = warehouse_ref

	func _process(delta: float) -> void:
		match _state:
			"going_to_warehouse":
				_state = "loading"
			"loading":
				if _cargo.is_empty():
					if _warehouse_ref:
						_warehouse_ref.truck_delivered.emit(5)
					_state = "returning"
				else:
					await Engine.get_main_loop().create_timer(1.0).timeout
					_cargo.pop_back()
			"returning":
				_state = "idle"
