# robot_controller.gd
class_name RobotController
extends Node2D
# AI-controlled robot staff — counter, shelf, cleaning, security, delivery robots.
# Uses ActorData.Actor with Role.ROBOT.

const CELL_SIZE := 16

var _actor: ActorData.Actor
var _sprite: Sprite2D = null
var _shadow: Sprite2D = null
var _scan_beam: Line2D = null
var _eye_glow: Sprite2D = null

var _global_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _speed: float = 60.0
var _state: String = "idle"
var _state_timer: float = 0.0
var _anim_timer: float = 0.0

# Robot-specific
var _robot_role: ActorData.StaffRole = ActorData.StaffRole.COUNTER_ROBOT
var _battery: float = 1.0
var _work_target: Vector2 = Vector2.ZERO
var _alert_level: int = 0
var _patrol_index: int = 0
var _patrol_points: Array = []

# Signals
signal robot_work_done(role: ActorData.StaffRole, pos: Vector2)

func _ready() -> void:
	_actor = ActorData.Actor.new()
	_actor.role = ActorData.Role.ROBOT
	_actor.staff_role = _robot_role
	_actor.energy = 1.0
	_build_sprite()

func configure(robot_role: ActorData.StaffRole, start_pos: Vector2) -> void:
	_robot_role = robot_role
	_actor.staff_role = robot_role
	_global_pos = start_pos
	position = _global_pos
	_speed = _get_robot_speed()
	_build_patrol_route()
	_state = "working"

func _get_robot_speed() -> float:
	match _robot_role:
		ActorData.StaffRole.COUNTER_ROBOT: return 0.0  # stationary
		ActorData.StaffRole.SHELF_ROBOT: return 55.0
		ActorData.StaffRole.CLEANING_ROBOT: return 45.0
		ActorData.StaffRole.SECURITY_ROBOT: return 65.0
		ActorData.StaffRole.DELIVERY_ROBOT: return 50.0
	return 50.0

func _build_sprite() -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = _make_shadow_texture()
	_shadow.position = Vector2(0, 10)
	_shadow.modulate.a = 0.3
	add_child(_shadow)

	_sprite = Sprite2D.new()
	_sprite.texture = _get_robot_texture()
	_sprite.hframes = 4
	add_child(_sprite)

	_eye_glow = Sprite2D.new()
	_eye_glow.texture = _make_eye_texture()
	_eye_glow.position = Vector2(0, -10)
	_eye_glow.modulate = Color(0.2, 0.9, 1.0, 1.0)
	add_child(_eye_glow)

	# Scan beam for counter robot
	_scan_beam = Line2D.new()
	_scan_beam.default_color = Color(0.2, 0.9, 1.0, 0.4)
	_scan_beam.width = 1.0
	_scan_beam.points = [Vector2(0, 0), Vector2(20, 0)]
	_scan_beam.visible = false
	add_child(_scan_beam)

func _get_robot_texture() -> ImageTexture:
	match _robot_role:
		ActorData.StaffRole.COUNTER_ROBOT: return _make_counter_robot_texture()
		ActorData.StaffRole.SHELF_ROBOT: return _make_shelf_robot_texture()
		ActorData.StaffRole.CLEANING_ROBOT: return _make_cleaning_robot_texture()
		ActorData.StaffRole.SECURITY_ROBOT: return _make_security_robot_texture()
		ActorData.StaffRole.DELIVERY_ROBOT: return _make_delivery_robot_texture()
	return _make_counter_robot_texture()

func _make_counter_robot_texture() -> ImageTexture:
	# Boxy robot body with screen face and scanning arm
	var img := Image.create(20, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body (metallic gray)
	for x in range(4, 16):
		for y in range(8, 24):
			img.set_pixel(x, y, Color(0.55, 0.55, 0.62, 1.0))
	# Head
	for x in range(6, 14):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.50, 0.50, 0.58, 1.0))
	# Screen face (cyan glow)
	for x in range(7, 13):
		for y in range(3, 8):
			img.set_pixel(x, y, Color(0.15, 0.85, 1.0, 1.0))
	# Eyes (bright)
	img.set_pixel(8, 5, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(11, 5, Color(1.0, 1.0, 1.0, 1.0))
	# Base/wheels
	for x in range(4, 16):
		img.set_pixel(x, 25, Color(0.35, 0.35, 0.40, 1.0))
	# Antenna
	img.set_pixel(10, 0, Color(0.80, 0.80, 0.85, 1.0))
	img.set_pixel(10, 1, Color(0.80, 0.80, 0.85, 1.0))
	return ImageTexture.create_from_image(img)

func _make_shelf_robot_texture() -> ImageTexture:
	# Tall thin robot with extendable arm for stocking shelves
	var img := Image.create(18, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	for x in range(5, 13):
		for y in range(10, 26):
			img.set_pixel(x, y, Color(0.50, 0.55, 0.65, 1.0))
	# Head
	for x in range(6, 12):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.48, 0.52, 0.62, 1.0))
	# Display face (green = working)
	for x in range(7, 11):
		for y in range(4, 8):
			img.set_pixel(x, y, Color(0.20, 0.90, 0.40, 1.0))
	# Arm (right side)
	for y in range(12, 22):
		img.set_pixel(14, y, Color(0.60, 0.60, 0.70, 1.0))
	img.set_pixel(16, 20, Color(0.70, 0.70, 0.80, 1.0))  # grabber claw
	img.set_pixel(17, 21, Color(0.70, 0.70, 0.80, 1.0))
	# Wheels
	img.set_pixel(5, 27, Color(0.30, 0.30, 0.35, 1.0))
	img.set_pixel(12, 27, Color(0.30, 0.30, 0.35, 1.0))
	return ImageTexture.create_from_image(img)

func _make_cleaning_robot_texture() -> ImageTexture:
	# Flat disk-shaped robot with brushes on bottom (top-down view)
	var img := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body disk
	for x in range(2, 20):
		for y in range(2, 20):
			var dx := x - 11
			var dy := y - 11
			if dx*dx + dy*dy < 90:
				img.set_pixel(x, y, Color(0.72, 0.74, 0.78, 1.0))
	# Inner circle ( darker center)
	for x in range(6, 16):
		for y in range(6, 16):
			var dx := x - 11
			var dy := y - 11
			if dx*dx + dy*dy < 40:
				img.set_pixel(x, y, Color(0.60, 0.62, 0.65, 1.0))
	# Top handle/sensor bump
	for x in range(9, 13):
		for y in range(1, 5):
			img.set_pixel(x, y, Color(0.75, 0.75, 0.80, 1.0))
	# LED indicators (cyan)
	img.set_pixel(8, 8, Color(0.20, 0.90, 1.0, 1.0))
	img.set_pixel(13, 8, Color(0.20, 0.90, 1.0, 1.0))
	img.set_pixel(8, 14, Color(0.20, 0.90, 1.0, 1.0))
	img.set_pixel(13, 14, Color(0.20, 0.90, 1.0, 1.0))
	return ImageTexture.create_from_image(img)

func _make_security_robot_texture() -> ImageTexture:
	# Dark angular robot with red eye and antenna
	var img := Image.create(20, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body (dark metallic)
	for x in range(4, 16):
		for y in range(8, 24):
			img.set_pixel(x, y, Color(0.30, 0.30, 0.35, 1.0))
	# Head (angular)
	for x in range(5, 15):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.25, 0.25, 0.30, 1.0))
	# Red scanner eye
	for x in range(7, 13):
		for y in range(4, 7):
			img.set_pixel(x, y, Color(1.0, 0.20, 0.15, 1.0))
	# Antenna
	img.set_pixel(10, 0, Color(0.80, 0.80, 0.85, 1.0))
	img.set_pixel(10, 1, Color(0.80, 0.80, 0.85, 1.0))
	# Shoulder lights (blue = safe)
	for x in [4, 15]:
		img.set_pixel(x, 9, Color(0.20, 0.60, 1.0, 1.0))
	# Base
	for x in range(4, 16):
		img.set_pixel(x, 25, Color(0.20, 0.20, 0.25, 1.0))
	return ImageTexture.create_from_image(img)

func _make_delivery_robot_texture() -> ImageTexture:
	# Boxy robot with cargo tray on top
	var img := Image.create(22, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Body
	for x in range(4, 18):
		for y in range(10, 24):
			img.set_pixel(x, y, Color(0.60, 0.50, 0.30, 1.0))
	# Cargo tray
	for x in range(3, 19):
		for y in range(6, 11):
			img.set_pixel(x, y, Color(0.50, 0.40, 0.25, 1.0))
	# Head/screen
	for x in range(7, 15):
		for y in range(2, 7):
			img.set_pixel(x, y, Color(0.55, 0.55, 0.62, 1.0))
	# Screen (orange = delivering)
	for x in range(8, 14):
		for y in range(3, 6):
			img.set_pixel(x, y, Color(1.0, 0.55, 0.10, 1.0))
	# Wheels
	for x in [4, 17]:
		img.set_pixel(x, 23, Color(0.30, 0.30, 0.35, 1.0))
	return ImageTexture.create_from_image(img)

func _make_shadow_texture() -> ImageTexture:
	var img := Image.create(16, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(2, 14):
		for y in range(2, 7):
			img.set_pixel(x, y, Color(0.15, 0.12, 0.10, 0.5))
	return ImageTexture.create_from_image(img)

func _make_eye_texture() -> ImageTexture:
	var img := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(0.2, 0.9, 1.0, 1.0))
	img.set_pixel(6, 1, Color(0.2, 0.9, 1.0, 1.0))
	return ImageTexture.create_from_image(img)

func _build_patrol_route() -> void:
	match _robot_role:
		ActorData.StaffRole.SECURITY_ROBOT:
			_patrol_points = [
				Vector2(200, 100), Vector2(500, 100), Vector2(500, 300),
				Vector2(200, 300), Vector2(200, 500), Vector2(500, 500)
			]
		ActorData.StaffRole.SHELF_ROBOT:
			# Cycle through section positions
			_patrol_points = [
				Vector2(150, 200), Vector2(350, 200), Vector2(550, 200),
				Vector2(150, 400), Vector2(350, 400)
			]
		_:
			_patrol_points = []

func _process(delta: float) -> void:
	_anim_timer += delta
	_do_robot_behavior(delta)
	_update_sprite()

	# Eye glow pulse
	if _eye_glow:
		var pulse := 0.7 + 0.3 * sin(_anim_timer * 3.0)
		_eye_glow.modulate.a = pulse

	# Battery drain for mobile robots
	if _robot_role != ActorData.StaffRole.COUNTER_ROBOT:
		_battery -= delta * 0.002
		if _battery <= 0.0:
			_state = "returning"

func _do_robot_behavior(delta: float) -> void:
	match _robot_role:
		ActorData.StaffRole.COUNTER_ROBOT:
			_do_counter_robot(delta)
		ActorData.StaffRole.SHELF_ROBOT:
			_do_shelf_robot(delta)
		ActorData.StaffRole.CLEANING_ROBOT:
			_do_cleaning_robot(delta)
		ActorData.StaffRole.SECURITY_ROBOT:
			_do_security_robot(delta)
		ActorData.StaffRole.DELIVERY_ROBOT:
			_do_delivery_robot(delta)

func _do_counter_robot(_delta: float) -> void:
	# Counter robot stays at checkout, shows scan beam animation
	if _scan_beam:
		_scan_beam.visible = true
		var angle := _anim_timer * 2.0
		_scan_beam.points = [Vector2.ZERO, Vector2(cos(angle) * 24, sin(angle) * 24)]

func _do_shelf_robot(delta: float) -> void:
	if _state == "idle":
		_state_timer += delta
		if _state_timer >= 5.0:
			_state_timer = 0.0
			_state = "moving"
			if not _patrol_points.is_empty():
				_patrol_index = (_patrol_index + 1) % _patrol_points.size()
				_target_pos = _patrol_points[_patrol_index]
	elif _state == "moving":
		var to_target := _target_pos - _global_pos
		var dist := to_target.length()
		if dist < 8.0:
			_state = "restocking"
			_state_timer = 3.0  # restock animation duration
		else:
			var dir := to_target / dist
			_global_pos += dir * _speed * delta
			position = _global_pos

	elif _state == "restocking":
		_state_timer -= delta
		if _state_timer <= 0.0:
			_state = "idle"
			robot_work_done.emit(_robot_role, _global_pos)

func _do_cleaning_robot(delta: float) -> void:
	if _state == "working":
		# Spiral outward motion simulating floor cleaning
		var t := _anim_timer * 0.5
		var radius := 40.0 + 20.0 * sin(t * 0.3)
		var ideal_pos := _target_pos + Vector2(cos(t) * radius, sin(t) * radius * 0.5)
		var to_ideal := ideal_pos - _global_pos
		_global_pos += to_ideal * delta * 0.8
		position = _global_pos
	elif _state == "returning":
		var home := Vector2(600.0, 500.0)
		var to_home := home - _global_pos
		var dist := to_home.length()
		if dist < 10.0:
			_battery = 1.0
			_state = "working"
		else:
			var dir := to_home / dist
			_global_pos += dir * _speed * 0.7 * delta
			position = _global_pos

func _do_security_robot(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	_target_pos = _patrol_points[_patrol_index]
	var to_target := _target_pos - _global_pos
	var dist := to_target.length()
	if dist < 10.0:
		_state_timer += delta
		if _state_timer >= 2.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			# Alert flash
			_eye_glow.modulate = Color(1.0, 0.2, 0.1, 1.0)
			await Engine.get_main_loop().create_timer(0.5).timeout
			_eye_glow.modulate = Color(0.2, 0.9, 1.0, 1.0)
	else:
		var dir := to_target / dist
		_global_pos += dir * _speed * delta
		position = _global_pos

func _do_delivery_robot(delta: float) -> void:
	if _state == "idle":
		_state_timer += delta
		if _state_timer >= 8.0:
			_state_timer = 0.0
			_state = "going_to_warehouse"
	elif _state == "going_to_warehouse":
		var wh := Vector2(100.0, 300.0)
		var to_wh := wh - _global_pos
		var dist := to_wh.length()
		if dist < 12.0:
			_state = "loading"
			_state_timer = 2.0
		else:
			var dir := to_wh / dist
			_global_pos += dir * _speed * delta
			position = _global_pos
	elif _state == "loading":
		_state_timer -= delta
		if _state_timer <= 0.0:
			_state = "delivering"
			_target_pos = Vector2(300.0, 300.0)
	elif _state == "delivering":
		var to_target := _target_pos - _global_pos
		var dist := to_target.length()
		if dist < 12.0:
			_state = "returning"
			_target_pos = Vector2(600.0, 500.0)
			robot_work_done.emit(_robot_role, _global_pos)
		else:
			var dir := to_target / dist
			_global_pos += dir * _speed * delta
			position = _global_pos
	elif _state == "returning":
		var home := Vector2(600.0, 500.0)
		var to_home := home - _global_pos
		var dist := to_home.length()
		if dist < 10.0:
			_state = "idle"
			_state_timer = 0.0
		else:
			var dir := to_home / dist
			_global_pos += dir * _speed * delta
			position = _global_pos

func _update_sprite() -> void:
	if _sprite:
		# Bob animation
		var bob := sin(_anim_timer * 4.0) * 1.5
		_sprite.position.y = bob
		# Frame animation
		if _state == "moving" or _state == "delivering":
			_sprite.frame = int(_anim_timer * 4) % 4
