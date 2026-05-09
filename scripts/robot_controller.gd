# robot_controller.gd
# AI Robot Staff Controller - handles both HUMANOID and SINGLE_FUNCTION robots
# HUMANOID: looks like a human with robot features, can communicate and use tools
# SINGLE_FUNCTION: specialized machines (cleaning, guiding, delivery, security, shelf)
class_name RobotController
extends Node2D

const ActorData = preload("res://scripts/actor_data.gd")

const CELL_SIZE := 16

# Core state
var _actor: ActorData.Actor = null
var _sprite: Sprite2D = null
var _shadow: Sprite2D = null
var _eye_glow: Sprite2D = null
var _speech_bubble: Label = null
var _tool_sprite: Sprite2D = null

# Movement
var _global_pos := Vector2.ZERO
var _speed: float = 60.0
var _state: String = "idle"
var _state_timer: float = 0.0
var _anim_timer: float = 0.0
var _battery: float = 1.0
var _patrol_index: int = 0
var _patrol_points: Array = []
var _flip_h: bool = false
var _is_walking: bool = false
var _bob_offset: float = 0.0

# Robot type
var _is_humanoid: bool = false
var _assigned_staff_role: ActorData.StaffRole = ActorData.StaffRole.FLOOR_STAFF

# Signals
signal robot_work_done(role: String, pos: Vector2)

func _ready() -> void:
	_actor = ActorData.Actor.new()
	_build_shadow()

# ─── Configuration ───────────────────────────────────────────────────

func configure_humanoid(staff_role: ActorData.StaffRole, start_pos: Vector2) -> void:
	_actor = ActorData.Actor.new()
	_is_humanoid = true
	_assigned_staff_role = staff_role
	
	_actor.role = ActorData.Role.ROBOT
	_actor.robot_type = ActorData.RobotType.HUMANOID
	_actor.robot_role = ActorData.RobotRole.SHELF_ROBOT
	_actor.staff_role = staff_role
	_actor.appearance = ActorData.Appearance.random()
	_actor.display_name = "Robo-" + _get_staff_role_name(staff_role)
	_actor.energy = 1.0
	
	_global_pos = start_pos
	position = _global_pos
	_speed = _get_speed_for_role(staff_role)
	_state = "working"
	
	_build_humanoid_sprite()
	_build_patrol_for_humanoid()

func configure_single_function(rrole: ActorData.RobotRole, start_pos: Vector2) -> void:
	_actor = ActorData.Actor.new()
	_is_humanoid = false
	
	_actor.role = ActorData.Role.ROBOT
	_actor.robot_type = ActorData.RobotType.SINGLE_FUNCTION
	_actor.robot_role = rrole
	_actor.energy = 1.0
	
	_global_pos = start_pos
	position = _global_pos
	_speed = _get_speed_for_robot_role(rrole)
	_state = "working"
	
	_build_machine_sprite(rrole)
	_build_patrol_for_robot(rrole)

# ─── Speed Configuration ──────────────────────────────────────────────

func _get_staff_role_name(role: ActorData.StaffRole) -> String:
	match role:
		ActorData.StaffRole.CASHIER: return "Cashier"
		ActorData.StaffRole.SHELF_STOCKER: return "Stocker"
		ActorData.StaffRole.CLEANER: return "Cleaner"
		ActorData.StaffRole.SECURITY: return "Security"
		ActorData.StaffRole.GREETER: return "Greeter"
		ActorData.StaffRole.MANAGER: return "Manager"
		ActorData.StaffRole.FLOOR_STAFF: return "Floor Staff"
		ActorData.StaffRole.SCAN_GO: return "Scan & Go"
	return "Worker"

func _get_speed_for_role(role: ActorData.StaffRole) -> float:
	match role:
		ActorData.StaffRole.CASHIER: return 0.0
		ActorData.StaffRole.MANAGER: return 65.0
		ActorData.StaffRole.SECURITY: return 70.0
		ActorData.StaffRole.GREETER: return 0.0
		_: return 55.0

func _get_speed_for_robot_role(rrole: ActorData.RobotRole) -> float:
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT: return 45.0
		ActorData.RobotRole.GUIDANCE_ROBOT: return 50.0
		ActorData.RobotRole.DELIVERY_ROBOT: return 55.0
		ActorData.RobotRole.SECURITY_ROBOT: return 65.0
		ActorData.RobotRole.SHELF_ROBOT: return 55.0
	return 50.0

# ─── Sprite Building ────────────────────────────────────────────────

func _build_shadow() -> void:
	_shadow = Sprite2D.new()
	_shadow.texture = _make_shadow_texture()
	_shadow.position = Vector2(0, 10)
	_shadow.modulate.a = 0.3
	add_child(_shadow)

func _build_humanoid_sprite() -> void:
	if _sprite:
		_sprite.queue_free()
	
	_sprite = Sprite2D.new()
	_sprite.texture = _make_humanoid_texture()
	_sprite.hframes = 1
	add_child(_sprite)
	
	_eye_glow = Sprite2D.new()
	_eye_glow.texture = _make_robot_eye_texture()
	_eye_glow.position = Vector2(0, -10)
	_eye_glow.modulate = Color(0.25, 1.0, 0.80, 0.90)
	add_child(_eye_glow)
	
	_tool_sprite = Sprite2D.new()
	_tool_sprite.texture = _make_tool_texture(_assigned_staff_role)
	_tool_sprite.position = Vector2(8, 0)
	_tool_sprite.visible = false
	add_child(_tool_sprite)

func _build_machine_sprite(rrole: ActorData.RobotRole) -> void:
	if _sprite:
		_sprite.queue_free()
	
	_sprite = Sprite2D.new()
	_sprite.texture = _get_machine_texture(rrole)
	_sprite.hframes = 1
	add_child(_sprite)
	
	_eye_glow = Sprite2D.new()
	_eye_glow.texture = _make_robot_eye_texture()
	_eye_glow.position = Vector2(0, -6)
	add_child(_eye_glow)

# ─── HUMANOID Robot Texture (16x24) ──────────────────────────────

func _make_humanoid_texture() -> ImageTexture:
	var img: Image = Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Color palette
	var skin := Color(0.75, 0.78, 0.82, 1.0)  # metallic chrome
	var dark_metal := Color(0.45, 0.48, 0.52, 1.0)
	var cyan_glow := Color(0.20, 1.0, 0.90, 1.0)
	
	# Head - chrome dome
	for x in range(4, 12):
		for y in range(2, 8):
			img.set_pixel(x, y, skin)
	
	# LED eyes
	for x in [4, 5, 10, 11]:
		img.set_pixel(x, 4, cyan_glow)
	
	# Body - metallic uniform
	var top_col := Color(0.50, 0.52, 0.58)
	var bot_col := Color(0.35, 0.38, 0.45)
	if _actor != null and _actor.appearance != null:
		top_col = _actor.appearance.top_color
		bot_col = _actor.appearance.bottom_color
	
	for x in range(3, 13):
		for y in range(8, 16):
			img.set_pixel(x, y, top_col)
	
	# Chest panel with LED indicator
	for x in range(5, 11):
		for y in range(9, 12):
			img.set_pixel(x, y, dark_metal)
	img.set_pixel(7, 10, cyan_glow)
	img.set_pixel(8, 10, cyan_glow)
	
	# Arms
	for y in range(8, 14):
		img.set_pixel(2, y, skin)
		img.set_pixel(13, y, skin)
	
	# Legs
	for x in range(4, 12):
		for y in range(16, 22):
			img.set_pixel(x, y, bot_col)
	
	# Feet with cyan soles
	for x in range(3, 7):
		img.set_pixel(x, 22, dark_metal)
		img.set_pixel(x, 23, Color(0.20, 1.0, 0.85, 0.6))
	for x in range(9, 13):
		img.set_pixel(x, 22, dark_metal)
		img.set_pixel(x, 23, Color(0.20, 1.0, 0.85, 0.6))
	
	return ImageTexture.create_from_image(img)

# ─── TOOL Textures (8x8) ─────────────────────────────────────────

func _make_tool_texture(staff_role: ActorData.StaffRole) -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match staff_role:
		ActorData.StaffRole.CASHIER:
			for x in range(2, 6):
				for y in range(3, 7):
					img.set_pixel(x, y, Color(0.50, 0.50, 0.55, 1.0))
		ActorData.StaffRole.CLEANER:
			for y in range(1, 7):
				img.set_pixel(3, y, Color(0.55, 0.45, 0.30, 1.0))
			img.set_pixel(3, 1, Color(0.70, 0.70, 0.75, 1.0))
		ActorData.StaffRole.SHELF_STOCKER:
			for x in range(2, 6):
				for y in range(3, 7):
					img.set_pixel(x, y, Color(0.60, 0.50, 0.35, 1.0))
		ActorData.StaffRole.SECURITY:
			for x in range(2, 6):
				for y in range(3, 6):
					img.set_pixel(x, y, Color(0.30, 0.30, 0.35, 1.0))
		ActorData.StaffRole.GREETER:
			for x in range(2, 6):
				for y in range(2, 6):
					img.set_pixel(x, y, Color(0.80, 0.80, 0.75, 1.0))
		_:
			for x in range(3, 5):
				for y in range(2, 6):
					img.set_pixel(x, y, Color(0.60, 0.60, 0.65, 1.0))
	return ImageTexture.create_from_image(img)

# ─── SINGLE_FUNCTION Robot Textures ────────────────────────────────

func _get_machine_texture(rrole: ActorData.RobotRole) -> ImageTexture:
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT: return _make_cleaning_texture()
		ActorData.RobotRole.GUIDANCE_ROBOT: return _make_guidance_texture()
		ActorData.RobotRole.DELIVERY_ROBOT: return _make_delivery_texture()
		ActorData.RobotRole.SECURITY_ROBOT: return _make_security_texture()
		ActorData.RobotRole.SHELF_ROBOT: return _make_shelf_texture()
	return _make_cleaning_texture()

func _make_cleaning_texture() -> ImageTexture:
	# Disk-shaped floor cleaner (20x20)
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var silver := Color(0.72, 0.74, 0.78, 1.0)
	var dark := Color(0.50, 0.52, 0.56, 1.0)
	var cyan := Color(0.20, 0.80, 0.70, 1.0)
	
	# Outer ring
	for x in range(2, 18):
		for y in range(2, 18):
			var dx := x - 10; var dy := y - 10
			if dx*dx + dy*dy < 64:
				img.set_pixel(x, y, silver)
	
	# Inner disk
	for x in range(5, 15):
		for y in range(5, 15):
			var dx := x - 10; var dy := y - 10
			if dx*dx + dy*dy < 25:
				img.set_pixel(x, y, dark)
	
	# Center brush
	for x in range(7, 13):
		for y in range(7, 13):
			var dx := x - 10; var dy := y - 10
			if dx*dx + dy*dy < 12:
				img.set_pixel(x, y, cyan)
	
	# LED corners
	img.set_pixel(5, 5, cyan)
	img.set_pixel(14, 5, cyan)
	img.set_pixel(5, 14, cyan)
	img.set_pixel(14, 14, cyan)
	
	return ImageTexture.create_from_image(img)

func _make_guidance_texture() -> ImageTexture:
	# Kiosk guide robot (16x28)
	var img := Image.create(16, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var metal := Color(0.60, 0.62, 0.68, 1.0)
	var dark := Color(0.35, 0.38, 0.42, 1.0)
	var screen := Color(0.15, 0.85, 0.75, 1.0)
	
	# Base
	for x in range(3, 13):
		for y in range(24, 28):
			img.set_pixel(x, y, metal)
	
	# Body
	for x in range(2, 14):
		for y in range(10, 24):
			img.set_pixel(x, y, metal)
	
	# Dark panel
	for x in range(4, 12):
		for y in range(14, 20):
			img.set_pixel(x, y, dark)
	
	# Screen head
	for x in range(3, 13):
		for y in range(2, 10):
			img.set_pixel(x, y, screen)
	
	# Face
	img.set_pixel(5, 5, Color.WHITE)
	img.set_pixel(10, 5, Color.WHITE)
	img.set_pixel(5, 7, Color.WHITE)
	img.set_pixel(10, 7, Color.WHITE)
	
	# Antenna
	img.set_pixel(8, 0, Color(0.30, 0.90, 1.0, 1.0))
	
	return ImageTexture.create_from_image(img)

func _make_delivery_texture() -> ImageTexture:
	# Cargo robot (22x18)
	var img := Image.create(22, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var body := Color(0.50, 0.55, 0.65, 1.0)
	var dark := Color(0.35, 0.38, 0.45, 1.0)
	var orange := Color(1.0, 0.50, 0.10, 1.0)
	
	# Main body
	for x in range(2, 20):
		for y in range(6, 16):
			img.set_pixel(x, y, body)
	
	# Cargo bay
	for x in range(4, 10):
		for y in range(7, 12):
			img.set_pixel(x, y, dark)
	
	# Head
	for x in range(10, 16):
		for y in range(2, 6):
			img.set_pixel(x, y, orange)
	
	# Wheels
	for x in range(1, 5):
		img.set_pixel(x, 15, Color(0.25, 0.28, 0.32, 1.0))
	for x in range(17, 21):
		img.set_pixel(x, 15, Color(0.25, 0.28, 0.32, 1.0))
	
	# Status LED
	img.set_pixel(12, 12, Color(0.20, 1.0, 0.85, 1.0))
	
	return ImageTexture.create_from_image(img)

func _make_security_texture() -> ImageTexture:
	# Patrol security robot (18x22)
	var img := Image.create(18, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var armor := Color(0.25, 0.27, 0.32, 1.0)
	var red := Color(0.90, 0.15, 0.10, 1.0)
	var blue := Color(0.15, 0.50, 1.0, 1.0)
	
	# Body
	for x in range(2, 16):
		for y in range(8, 20):
			img.set_pixel(x, y, armor)
	
	# Head
	for x in range(4, 14):
		for y in range(2, 8):
			img.set_pixel(x, y, Color(0.20, 0.22, 0.28, 1.0))
	
	# Red scanner eye
	for x in range(5, 13):
		for y in range(3, 7):
			img.set_pixel(x, y, red)
	
	# Warning lights
	img.set_pixel(2, 9, blue)
	img.set_pixel(15, 9, blue)
	
	# Status LEDs
	img.set_pixel(5, 14, Color(1.0, 0.20, 0.15, 1.0))
	img.set_pixel(12, 14, Color(1.0, 0.20, 0.15, 1.0))
	
	# Antenna
	img.set_pixel(9, 0, red)
	
	return ImageTexture.create_from_image(img)

func _make_shelf_texture() -> ImageTexture:
	# Shelf scanner robot (14x26)
	var img := Image.create(14, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var body := Color(0.70, 0.72, 0.78, 1.0)
	var green := Color(0.15, 0.85, 0.40, 1.0)
	
	# Body
	for x in range(3, 11):
		for y in range(10, 22):
			img.set_pixel(x, y, body)
	
	# Scanner dome head
	for x in range(4, 10):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.60, 0.62, 0.68, 1.0))
	
	# Green laser eye
	for x in range(5, 9):
		for y in range(4, 8):
			img.set_pixel(x, y, green)
	
	# Scanner arm
	for y in range(12, 20):
		img.set_pixel(10, y, Color(0.50, 0.52, 0.58, 1.0))
	img.set_pixel(11, 18, green)
	
	# Wheels
	img.set_pixel(3, 23, Color(0.40, 0.42, 0.48, 1.0))
	img.set_pixel(10, 23, Color(0.40, 0.42, 0.48, 1.0))
	
	return ImageTexture.create_from_image(img)

# ─── Utility Textures ──────────────────────────────────────────────

func _make_robot_eye_texture() -> ImageTexture:
	var img := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.set_pixel(1, 1, Color(0.25, 1.0, 0.80, 1.0))
	img.set_pixel(6, 1, Color(0.25, 1.0, 0.80, 1.0))
	return ImageTexture.create_from_image(img)

func _make_shadow_texture() -> ImageTexture:
	var img := Image.create(16, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(2, 14):
		for y in range(2, 7):
			img.set_pixel(x, y, Color(0.15, 0.12, 0.10, 0.5))
	return ImageTexture.create_from_image(img)

# ─── Patrol Routes ─────────────────────────────────────────────────

func _build_patrol_for_humanoid() -> void:
	match _assigned_staff_role:
		ActorData.StaffRole.GREETER:
			_patrol_points = [Vector2(300, 100), Vector2(320, 100), Vector2(300, 100)]
		ActorData.StaffRole.MANAGER:
			_patrol_points = [Vector2(200, 200), Vector2(500, 200), Vector2(500, 350), Vector2(200, 350), Vector2(200, 200)]
		ActorData.StaffRole.SECURITY:
			_patrol_points = [Vector2(100, 100), Vector2(700, 100), Vector2(700, 400), Vector2(100, 400), Vector2(100, 100)]
		_:
			_patrol_points = [Vector2(300, 300), Vector2(450, 300), Vector2(450, 400), Vector2(300, 400)]

func _build_patrol_for_robot(rrole: ActorData.RobotRole) -> void:
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT:
			_patrol_points = [Vector2(200, 300), Vector2(600, 300), Vector2(600, 450), Vector2(200, 450), Vector2(200, 300)]
		ActorData.RobotRole.GUIDANCE_ROBOT:
			_patrol_points = [Vector2(300, 100), Vector2(600, 100), Vector2(600, 200), Vector2(300, 200), Vector2(300, 100)]
		ActorData.RobotRole.SECURITY_ROBOT:
			_patrol_points = [Vector2(100, 100), Vector2(700, 100), Vector2(700, 400), Vector2(100, 400), Vector2(100, 100)]
		ActorData.RobotRole.SHELF_ROBOT:
			_patrol_points = [Vector2(150, 200), Vector2(350, 200), Vector2(550, 200), Vector2(150, 400), Vector2(350, 400)]
		_:
			_patrol_points = []

# ─── Main Loop ─────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_anim_timer += delta
	_do_behavior(delta)
	_update_sprite()

	if _eye_glow:
		var pulse := 0.6 + 0.4 * sin(_anim_timer * 2.5)
		_eye_glow.modulate.a = pulse

func _do_behavior(delta: float) -> void:
	if _is_humanoid:
		_do_humanoid_behavior(delta)
	else:
		_do_machine_behavior(delta)

# ─── Humanoid Behavior ─────────────────────────────────────────────

func _do_humanoid_behavior(delta: float) -> void:
	match _assigned_staff_role:
		ActorData.StaffRole.CASHIER: _do_cashier_humanoid(delta)
		ActorData.StaffRole.GREETER: _do_greeter_humanoid(delta)
		ActorData.StaffRole.SECURITY: _do_security_humanoid(delta)
		ActorData.StaffRole.CLEANER: _do_cleaner_humanoid(delta)
		ActorData.StaffRole.SHELF_STOCKER: _do_stocker_humanoid(delta)
		_: _do_patrol_humanoid(delta)

func _do_cashier_humanoid(_delta: float) -> void:
	_state = "working"
	if _tool_sprite:
		_tool_sprite.visible = true
	_show_speech_bubble_text("Scan items...")

func _do_greeter_humanoid(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	_state_timer += delta
	if _state_timer >= 4.0:
		_state_timer = 0.0
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_show_speech_bubble_text("Welcome!")

func _do_security_humanoid(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 12.0:
		_state_timer += delta
		if _state_timer >= 2.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			_show_speech_bubble_text("All clear.")

func _do_cleaner_humanoid(delta: float) -> void:
	if _tool_sprite:
		_tool_sprite.visible = true
	if _patrol_points.is_empty():
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_state_timer += delta
		if _state_timer >= 3.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			_show_speech_bubble_text("Sparkling!")

func _do_stocker_humanoid(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_state_timer += delta
		if _state_timer >= 4.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			_show_speech_bubble_text("Stocking...")

func _do_patrol_humanoid(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()

func _move_towards(target: Vector2, delta: float) -> void:
	var to_target := target - _global_pos
	var dist := to_target.length()
	if dist < 4.0:
		_is_walking = false
		return
	_is_walking = true
	var dir := to_target / dist
	_global_pos += dir * _speed * delta
	position = _global_pos
	if dir.x < 0:
		_flip_h = true
	elif dir.x > 0:
		_flip_h = false

# ─── Machine Behavior ───────────────────────────────────────────────

func _do_machine_behavior(delta: float) -> void:
	match _actor.robot_role:
		ActorData.RobotRole.CLEANING_ROBOT: _do_cleaning_machine(delta)
		ActorData.RobotRole.GUIDANCE_ROBOT: _do_guidance_machine(delta)
		ActorData.RobotRole.SECURITY_ROBOT: _do_security_machine(delta)
		ActorData.RobotRole.DELIVERY_ROBOT: _do_delivery_machine(delta)
		ActorData.RobotRole.SHELF_ROBOT: _do_shelf_machine(delta)

func _do_cleaning_machine(delta: float) -> void:
	if _battery <= 0.0:
		_state = "charging"
		_battery = 0.0
		return
	if _state == "charging":
		_battery += delta * 0.02
		if _battery >= 1.0:
			_battery = 1.0
			_state = "working"
		return
	# Spiral cleaning motion
	var t := _anim_timer * 0.4
	var radius := 50.0 + 30.0 * sin(t * 0.5)
	var center := Vector2(400.0, 350.0)
	var ideal := center + Vector2(cos(t) * radius, sin(t) * radius * 0.6)
	var to_ideal := ideal - _global_pos
	_global_pos += to_ideal * delta * 0.5
	position = _global_pos
	_battery -= delta * 0.003

func _do_guidance_machine(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 15.0:
		_state_timer += delta
		if _state_timer >= 5.0:
			_state_timer = 0.0
			_show_speech_bubble_text("How can I help?")
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()

func _do_security_machine(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 12.0:
		_state_timer += delta
		if _state_timer >= 2.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			_flash_eye_alert()
			_show_speech_bubble_text("Area secure.")

func _flash_eye_alert() -> void:
	_eye_glow.modulate = Color(1.0, 0.2, 0.15, 1.0)
	var t := Timer.new()
	t.timeout.connect(_restore_eye_color)
	t.wait_time = 0.4
	t.one_shot = true
	add_child(t)
	t.start()

func _restore_eye_color() -> void:
	if _eye_glow != null:
		_eye_glow.modulate = Color(0.25, 1.0, 0.80, 0.90)

func _do_delivery_machine(delta: float) -> void:
	match _state:
		"idle":
			_state_timer += delta
			if _state_timer >= 6.0:
				_state_timer = 0.0
				_state = "to_warehouse"
		"to_warehouse":
			var wh := Vector2(100.0, 300.0)
			var d := _move_towards_vec(wh, delta)
			if d < 15.0:
				_state = "loading"
				_state_timer = 2.0
		"loading":
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = "to_destination"
				_target_pos = Vector2(400.0, 300.0)
		"to_destination":
			var d := _move_towards_vec(_target_pos, delta)
			if d < 15.0:
				_state = "unloading"
				_state_timer = 1.5
		"unloading":
			_state_timer -= delta
			if _state_timer <= 0.0:
				_state = "returning"
		"returning":
			var home := Vector2(600.0, 500.0)
			var d := _move_towards_vec(home, delta)
			if d < 15.0:
				_state = "idle"
				_state_timer = 0.0

var _target_pos := Vector2.ZERO

func _move_towards_vec(target: Vector2, delta: float) -> float:
	var to_target := target - _global_pos
	var dist := to_target.length()
	if dist < 5.0:
		return dist
	var dir := to_target / dist
	_global_pos += dir * _speed * delta
	position = _global_pos
	if dir.x < 0:
		_flip_h = true
	elif dir.x > 0:
		_flip_h = false
	return dist

func _do_shelf_machine(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_state_timer += delta
		if _state_timer >= 5.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			robot_work_done.emit("shelf_scan", _global_pos)

# ─── Speech Bubble ──────────────────────────────────────────────────

func _show_speech_bubble_text(text: String) -> void:
	if _speech_bubble == null:
		_speech_bubble = Label.new()
		_speech_bubble.add_theme_color_override("font_color", Color(0.95, 0.95, 0.70))
		_speech_bubble.add_theme_font_size_override("font_size", 7)
		_speech_bubble.text = text
		add_child(_speech_bubble)
	else:
		_speech_bubble.text = text
	_speech_bubble.position = Vector2(-20, -28)

# ─── Sprite Animation ──────────────────────────────────────────────

func _update_sprite() -> void:
	if _sprite == null:
		return
	if _is_humanoid:
		_sprite.flip_h = _flip_h
		if _is_walking:
			_bob_offset = sin(_anim_timer * 8.0) * 2.0
		else:
			_bob_offset = 0.0
		_sprite.position.y = _bob_offset
		_sprite.frame = int(_anim_timer * 3) % 4
	else:
		_sprite.position.y = sin(_anim_timer * 3.0) * 1.0
		if _state == "moving":
			_sprite.frame = int(_anim_timer * 4) % 4
