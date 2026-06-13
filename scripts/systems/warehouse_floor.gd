# warehouse_floor.gd
# Floor 11 warehouse zone — truck, forklift, conveyor belt control for staff.
# Factory robots are now a separate entity: scripts/entities/factory_robot.gd.
# ═══════════════════════════════════════════════════════════════════════════════

class_name WarehouseFloor
extends Node2D

const CELL_SIZE := 16
const FactoryRobotScript = preload("res://scripts/entities/factory_robot.gd")

var _zone: Dictionary = {}
var _player_ref: Node2D = null
var _is_staff: bool = false
var _player_stats: PlayerStats = null

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

# UI elements
var _ui_container: Control = null
var _status_lbl: Label = null
var _truck_sprite: Sprite2D = null
var _forklift_sprite: Sprite2D = null

# Factory Robots (visual entities on Floor 11)
var _factory_robot_1: FactoryRobotScript = null  # Checkout counter scanner
var _factory_robot_2: FactoryRobotScript = null  # Shelf scanner
var _factory_robot_3: FactoryRobotScript = null  # Cleaning robot

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
	_truck_sprite.hframes = 1
	add_child(_truck_sprite)

	# Forklift sprite
	_forklift_sprite = Sprite2D.new()
	_forklift_sprite.texture = _make_forklift_texture()
	_forklift_sprite.position = Vector2(_forklift_pos.x * CELL_SIZE, _forklift_pos.y * CELL_SIZE)
	_forklift_sprite.hframes = 1
	add_child(_forklift_sprite)

func _build_factory_robots() -> void:
	# Counter scanner — stands in place, no patrol
	_factory_robot_1 = FactoryRobotScript.new()
	_factory_robot_1.configure(
		FactoryRobotScript.Mode.COUNTER_SCANNER,
		[],
		Vector2(50 * CELL_SIZE, 45 * CELL_SIZE),
		0.0
	)
	add_child(_factory_robot_1)

	# Shelf scanner — patrols 4 corners of the warehouse zone
	_factory_robot_2 = FactoryRobotScript.new()
	_factory_robot_2.configure(
		FactoryRobotScript.Mode.SHELF_SCANNER,
		[
			Vector2(30 * CELL_SIZE, 20 * CELL_SIZE),
			Vector2(50 * CELL_SIZE, 20 * CELL_SIZE),
			Vector2(50 * CELL_SIZE, 35 * CELL_SIZE),
			Vector2(30 * CELL_SIZE, 35 * CELL_SIZE),
		],
		Vector2(30 * CELL_SIZE, 20 * CELL_SIZE),
		40.0
	)
	add_child(_factory_robot_2)

	# Cleaning robot — bounces between 2 points
	_factory_robot_3 = FactoryRobotScript.new()
	_factory_robot_3.configure(
		FactoryRobotScript.Mode.CLEANING,
		[
			Vector2(60 * CELL_SIZE, 25 * CELL_SIZE),
			Vector2(70 * CELL_SIZE, 30 * CELL_SIZE),
		],
		Vector2(60 * CELL_SIZE, 25 * CELL_SIZE),
		35.0
	)
	add_child(_factory_robot_3)

func _make_truck_texture() -> ImageTexture:
	var img := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.50, 0.38, 0.28, 1.0))  # brown truck body
	for x in range(2, 8):
		for y in range(6, 18):
			img.set_pixel(x, y, Color(0.60, 0.50, 0.38, 1.0))
	for x in range(8, 30):
		for y in range(4, 20):
			img.set_pixel(x, y, Color(0.45, 0.35, 0.25, 1.0))
	for wx in [4, 26]:
		for wy in [2, 20]:
			img.set_pixel(wx, wy, Color(0.15, 0.15, 0.15, 1.0))
	return ImageTexture.create_from_image(img)

func _make_forklift_texture() -> ImageTexture:
	var img := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(8, 16):
		for y in range(10, 28):
			img.set_pixel(x, y, Color(0.80, 0.60, 0.20, 1.0))
	for x in range(10, 14):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.50, 0.50, 0.55, 1.0))
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
	# Advance progress on every item; advance tile position when full.
	var to_remove: Array = []
	for item in _conveyor_items:
		item["progress"] += delta * _conveyor_speed
		if item["progress"] < 1.0:
			continue
		var next_pos: Vector2 = (item["tile_pos"] as Vector2) + Vector2(1, 0)
		if next_pos.x > 50.0:
			to_remove.append(item)
		else:
			item["tile_pos"] = next_pos
			item["progress"] = 0.0
	for item in to_remove:
		_conveyor_items.erase(item)

func _update_truck_animation(_delta: float) -> void:
	# Bob animation while moving (placeholder for future polish)
	pass

# ─── Staff interaction ──────────────────────────────────────────────

func set_staff_mode(staff: bool) -> void:
	_is_staff = staff
	if _ui_container:
		_ui_container.visible = staff

# ─── Player driving truck ──────────────────────────────────────────

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
