extends Node2D
class_name RobotController

# robot_controller.gd
const ActorData = preload("res://scripts/actor_data.gd")
# AI robot staff — two types:
#   HUMANOID: looks like a human, can communicate, use tools, do any job
#   SINGLE_FUNCTION: specialized machine (cleaning, guiding, delivery, etc.)

const CELL_SIZE := 16

var _actor: ActorData.Actor
var _sprite: Sprite2D = null
var _shadow: Sprite2D = null
var _eye_glow: Sprite2D = null
var _speech_bubble: Label = null
var _tool_sprite: Sprite2D = null  # for humanoid robots holding tools

var _global_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _speed: float = 60.0
var _state: String = "idle"
var _state_timer: float = 0.0
var _anim_timer: float = 0.0
var _battery: float = 1.0
var _patrol_index: int = 0
var _patrol_points: Array = []
var _is_humanoid: bool = false

# For humanoid robots — assigned a staff role, moves like human NPCs
var _assigned_staff_role: ActorData.StaffRole = ActorData.StaffRole.FLOOR_STAFF
var _flip_h: bool = false
var _is_walking: bool = false
var _bob_offset: float = 0.0

# Signals
signal robot_work_done(role: String, pos: Vector2)

func _ready() -> void:
	_actor = ActorData.Actor.new()
	_build_sprite()

func configure_humanoid(staff_role: ActorData.StaffRole, start_pos: Vector2) -> void:
	# 🔥 核心修复：先实例化 _actor 对象（必须！）
	_actor = ActorData.Actor.new()
	
	_is_humanoid = true
	_assigned_staff_role = staff_role
	# 现在 _actor 是有效对象，可以正常赋值
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
		# 🔥 同样初始化 _actor
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

func _build_sprite() -> void:
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
	_sprite.hframes = 4
	add_child(_sprite)

	_eye_glow = Sprite2D.new()
	_eye_glow.texture = _make_robot_eye_texture()
	_eye_glow.position = Vector2(0, -10)
	_eye_glow.modulate = Color(0.25, 1.0, 0.80, 0.90)
	add_child(_eye_glow)

	# Tool sprite for humanoid robots
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
	_sprite.hframes = 4
	add_child(_sprite)

	_eye_glow = Sprite2D.new()
	_eye_glow.texture = _make_robot_eye_texture()
	_eye_glow.position = Vector2(0, -6)
	add_child(_eye_glow)

func _make_humanoid_texture() -> ImageTexture:
	# Robot with clearly robotic appearance - metallic chrome body with glowing elements
	var img: Image = Image.create(16, 28, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Head - metallic silver/chrome
	for x in range(4, 12):
		for y in range(2, 9):
			img.set_pixel(x, y, Color(0.75, 0.78, 0.82, 1.0))  # chrome metal
	
	# Metallic ridge on head (robot detail)
	for x in range(5, 11):
		img.set_pixel(x, 2, Color(0.55, 0.58, 0.62, 1.0))
	
	# Large LED eyes (cyan glow) - more prominent
	for x in [4, 5, 6, 7]:
		img.set_pixel(x, 4, Color(0.20, 1.0, 0.90, 1.0))
	for x in [8, 9, 10, 11]:
		img.set_pixel(x, 4, Color(0.20, 1.0, 0.90, 1.0))
	# Eye glow effect
	for x in [5, 6, 9, 10]:
		img.set_pixel(x, 5, Color(0.40, 1.0, 0.95, 1.0))
	
	# Robot mouth/grill
	for x in [5, 6, 7, 8, 9, 10]:
		img.set_pixel(x, 7, Color(0.30, 0.30, 0.35, 1.0))
	
	# Neck joint (chrome)
	img.set_pixel(6, 8, Color(0.65, 0.68, 0.72, 1.0))
	img.set_pixel(7, 8, Color(0.65, 0.68, 0.72, 1.0))
	img.set_pixel(8, 8, Color(0.65, 0.68, 0.72, 1.0))
	img.set_pixel(9, 8, Color(0.65, 0.68, 0.72, 1.0))
	
	# Body - metallic uniform with accent stripe
	var top_col: Color
	var bot_col: Color
	if _actor != null and _actor.appearance != null:
		top_col = _actor.appearance.top_color
		bot_col = _actor.appearance.bottom_color
	else:
		top_col = Color(0.50, 0.52, 0.58)  # default metallic gray
		bot_col = Color(0.35, 0.38, 0.45)
	
	for x in range(3, 13):
		for y in range(9, 20):
			img.set_pixel(x, y, top_col)
	
	# Chest panel (darker inset)
	for x in range(5, 11):
		for y in range(10, 15):
			img.set_pixel(x, y, Color(0.30, 0.32, 0.38, 1.0))
	
	# LED chest indicator (cyan)
	img.set_pixel(7, 12, Color(0.20, 1.0, 0.85, 1.0))
	img.set_pixel(8, 12, Color(0.20, 1.0, 0.85, 1.0))
	
	# Shoulder joints (chrome)
	for y in range(9, 12):
		img.set_pixel(2, y, Color(0.60, 0.63, 0.68, 1.0))
		img.set_pixel(13, y, Color(0.60, 0.63, 0.68, 1.0))
	
	# Arms - metallic with visible joints
	for y in range(12, 15):
		img.set_pixel(2, y, Color(0.70, 0.72, 0.76, 1.0))
		img.set_pixel(13, y, Color(0.70, 0.72, 0.76, 1.0))
	for y in range(15, 19):
		img.set_pixel(2, y, Color(0.55, 0.58, 0.62, 1.0))
		img.set_pixel(13, y, Color(0.55, 0.58, 0.62, 1.0))
	
	# Lower body
	for x in range(4, 12):
		for y in range(20, 27):
			img.set_pixel(x, y, bot_col)
	
	# Hip joint (chrome)
	for x in range(4, 12):
		img.set_pixel(x, 19, Color(0.60, 0.63, 0.68, 1.0))
	
	# Legs - metallic with knee joints
	for y in range(20, 23):
		img.set_pixel(4, y, bot_col)
		img.set_pixel(11, y, bot_col)
	# Knee joints
	img.set_pixel(4, 23, Color(0.60, 0.63, 0.68, 1.0))
	img.set_pixel(11, 23, Color(0.60, 0.63, 0.68, 1.0))
	for y in range(24, 27):
		img.set_pixel(4, y, Color(0.45, 0.48, 0.52, 1.0))
		img.set_pixel(11, y, Color(0.45, 0.48, 0.52, 1.0))
	
	# Feet - robotic boots (dark metal with cyan sole glow)
	for x in range(3, 7):
		img.set_pixel(x, 27, Color(0.25, 0.28, 0.32, 1.0))
	for x in range(9, 13):
		img.set_pixel(x, 27, Color(0.25, 0.28, 0.32, 1.0))
	# Cyan glow on bottom of feet
	img.set_pixel(4, 27, Color(0.20, 1.0, 0.85, 0.8))
	img.set_pixel(5, 27, Color(0.20, 1.0, 0.85, 0.8))
	img.set_pixel(10, 27, Color(0.20, 1.0, 0.85, 0.8))
	img.set_pixel(11, 27, Color(0.20, 1.0, 0.85, 0.8))
	
	# Antenna on head - more prominent
	img.set_pixel(8, 1, Color(0.70, 0.72, 0.76, 1.0))  # antenna base
	img.set_pixel(8, 0, Color(0.30, 0.90, 1.0, 1.0))  # glowing tip
	
	return ImageTexture.create_from_image(img)

func _make_tool_texture(staff_role: ActorData.StaffRole) -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match staff_role:
		ActorData.StaffRole.CASHIER:
			# Cash register / scanner
			for x in range(2, 6):
				for y in range(3, 7):
					img.set_pixel(x, y, Color(0.50, 0.50, 0.55, 1.0))
		ActorData.StaffRole.CLEANER:
			# Mop / broom
			for y in range(1, 7):
				img.set_pixel(3, y, Color(0.55, 0.45, 0.30, 1.0))
			img.set_pixel(3, 1, Color(0.70, 0.70, 0.75, 1.0))
		ActorData.StaffRole.SHELF_STOCKER:
			# Box / stock crate
			for x in range(2, 6):
				for y in range(3, 7):
					img.set_pixel(x, y, Color(0.60, 0.50, 0.35, 1.0))
		ActorData.StaffRole.SECURITY:
			# Radio / device
			for x in range(2, 6):
				for y in range(3, 6):
					img.set_pixel(x, y, Color(0.30, 0.30, 0.35, 1.0))
		ActorData.StaffRole.GREETER:
			# Sign / clipboard
			for x in range(2, 6):
				for y in range(2, 6):
					img.set_pixel(x, y, Color(0.80, 0.80, 0.75, 1.0))
		_:
			# Generic tool
			for x in range(3, 5):
				for y in range(2, 6):
					img.set_pixel(x, y, Color(0.60, 0.60, 0.65, 1.0))
	return ImageTexture.create_from_image(img)

func _get_machine_texture(rrole: ActorData.RobotRole) -> ImageTexture:
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT: return _make_cleaning_machine_texture()
		ActorData.RobotRole.GUIDANCE_ROBOT: return _make_guidance_machine_texture()
		ActorData.RobotRole.DELIVERY_ROBOT: return _make_delivery_machine_texture()
		ActorData.RobotRole.SECURITY_ROBOT: return _make_security_machine_texture()
		ActorData.RobotRole.SHELF_ROBOT: return _make_shelf_machine_texture()
	return _make_cleaning_machine_texture()

func _make_cleaning_machine_texture() -> ImageTexture:
	# Advanced disk-shaped cleaning robot (top-down view)
	var img := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Outer ring - metallic silver
	for x in range(2, 20):
		for y in range(2, 20):
			var dx := x - 11; var dy := y - 11
			if dx*dx + dy*dy < 88:
				img.set_pixel(x, y, Color(0.72, 0.74, 0.78, 1.0))
	
	# Inner disk - darker metallic
	for x in range(5, 17):
		for y in range(5, 17):
			var dx := x - 11; var dy := y - 11
			if dx*dx + dy*dy < 30:
				img.set_pixel(x, y, Color(0.50, 0.52, 0.56, 1.0))
	
	# Center brush indicator (cyan)
	for x in range(8, 14):
		for y in range(8, 14):
			var dx := x - 11; var dy := y - 11
			if dx*dx + dy*dy < 14:
				img.set_pixel(x, y, Color(0.20, 0.80, 0.70, 1.0))
	
	# LED status indicators (4 corners - cyan glow)
	img.set_pixel(6, 6, Color(0.20, 1.0, 0.85, 1.0))
	img.set_pixel(15, 6, Color(0.20, 1.0, 0.85, 1.0))
	img.set_pixel(6, 15, Color(0.20, 1.0, 0.85, 1.0))
	img.set_pixel(15, 15, Color(0.20, 1.0, 0.85, 1.0))
	
	# Top sensor dome (blue)
	for x in range(8, 14):
		img.set_pixel(x, 1, Color(0.30, 0.60, 0.90, 1.0))
		img.set_pixel(x, 2, Color(0.20, 0.50, 0.80, 1.0))
	
	# Bumper ring (darker)
	for x in range(0, 22):
		img.set_pixel(x, 0, Color(0.40, 0.42, 0.46, 1.0))
		img.set_pixel(x, 21, Color(0.40, 0.42, 0.46, 1.0))
	for y in range(0, 22):
		img.set_pixel(0, y, Color(0.40, 0.42, 0.46, 1.0))
		img.set_pixel(21, y, Color(0.40, 0.42, 0.46, 1.0))
	
	return ImageTexture.create_from_image(img)

func _make_guidance_machine_texture() -> ImageTexture:
	# Tall kiosk-style guide robot with large LED display
	var img := Image.create(18, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Base (heavy stable bottom)
	for x in range(3, 15):
		for y in range(26, 30):
			img.set_pixel(x, y, Color(0.45, 0.48, 0.52, 1.0))
	
	# Body (metallic kiosk)
	for x in range(2, 16):
		for y in range(10, 26):
			img.set_pixel(x, y, Color(0.60, 0.62, 0.68, 1.0))
	
	# Dark panel inset on body
	for x in range(4, 14):
		for y in range(16, 24):
			img.set_pixel(x, y, Color(0.35, 0.38, 0.42, 1.0))
	
	# Large LED display screen (bright cyan = active)
	for x in range(3, 15):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.15, 0.85, 0.75, 1.0))
	
	# Robot face on screen (white LED eyes)
	img.set_pixel(6, 5, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(11, 5, Color(1.0, 1.0, 1.0, 1.0))
	# Smile
	img.set_pixel(6, 7, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(7, 8, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(8, 8, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(9, 8, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(10, 7, Color(1.0, 1.0, 1.0, 1.0))
	
	# Status LEDs on body (cyan)
	img.set_pixel(5, 14, Color(0.20, 1.0, 0.85, 1.0))
	img.set_pixel(12, 14, Color(0.20, 1.0, 0.85, 1.0))
	
	# Antenna on top (glowing)
	img.set_pixel(9, 0, Color(0.50, 0.52, 0.58, 1.0))
	img.set_pixel(9, 1, Color(0.30, 0.90, 1.0, 1.0))
	
	return ImageTexture.create_from_image(img)

func _make_delivery_machine_texture() -> ImageTexture:
	# Boxy cargo robot with cargo bay and LED display
	var img := Image.create(24, 22, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Main cargo body (metallic blue-gray)
	for x in range(2, 22):
		for y in range(8, 20):
			img.set_pixel(x, y, Color(0.50, 0.55, 0.65, 1.0))
	
	# Darker cargo bay door
	for x in range(4, 10):
		for y in range(9, 15):
			img.set_pixel(x, y, Color(0.35, 0.38, 0.45, 1.0))
	
	# Cargo tray on top (open box style)
	for x in range(3, 21):
		for y in range(5, 9):
			img.set_pixel(x, y, Color(0.40, 0.42, 0.48, 1.0))
	# Tray sides
	for y in range(3, 9):
		img.set_pixel(3, y, Color(0.50, 0.52, 0.58, 1.0))
		img.set_pixel(20, y, Color(0.50, 0.52, 0.58, 1.0))
	
	# Robot head/screen (bright orange = delivering)
	for x in range(10, 16):
		for y in range(2, 5):
			img.set_pixel(x, y, Color(0.55, 0.55, 0.62, 1.0))
	for x in range(11, 15):
		for y in range(2, 5):
			img.set_pixel(x, y, Color(1.0, 0.50, 0.10, 1.0))
	
	# LED indicator eyes
	img.set_pixel(12, 2, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(13, 2, Color(1.0, 1.0, 1.0, 1.0))
	
	# Status panel on front (cyan)
	img.set_pixel(12, 16, Color(0.20, 1.0, 0.85, 1.0))
	img.set_pixel(13, 16, Color(0.20, 1.0, 0.85, 1.0))
	
	# Wheels (dark metal with treads)
	for x in range(1, 5):
		img.set_pixel(x, 19, Color(0.25, 0.28, 0.32, 1.0))
		img.set_pixel(x, 20, Color(0.20, 0.22, 0.25, 1.0))
	for x in range(19, 23):
		img.set_pixel(x, 19, Color(0.25, 0.28, 0.32, 1.0))
		img.set_pixel(x, 20, Color(0.20, 0.22, 0.25, 1.0))
	
	# Bumpers
	img.set_pixel(0, 12, Color(0.35, 0.38, 0.42, 1.0))
	img.set_pixel(23, 12, Color(0.35, 0.38, 0.42, 1.0))
	
	return ImageTexture.create_from_image(img)

func _make_security_machine_texture() -> ImageTexture:
	# Dark tactical patrol robot with red scanner eye
	var img := Image.create(20, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Body (dark armored metal)
	for x in range(2, 18):
		for y in range(8, 22):
			img.set_pixel(x, y, Color(0.25, 0.27, 0.32, 1.0))
	
	# Armor plates
	for x in range(4, 16):
		img.set_pixel(x, 8, Color(0.30, 0.32, 0.38, 1.0))
		img.set_pixel(x, 21, Color(0.30, 0.32, 0.38, 1.0))
	
	# Head unit (darker)
	for x in range(4, 16):
		for y in range(2, 9):
			img.set_pixel(x, y, Color(0.20, 0.22, 0.28, 1.0))
	
	# RED scanner eye (dangerous looking)
	for x in range(5, 15):
		for y in range(3, 7):
			img.set_pixel(x, y, Color(0.90, 0.15, 0.10, 1.0))
	# Eye glow center
	for x in range(7, 13):
		img.set_pixel(x, 4, Color(1.0, 0.30, 0.20, 1.0))
		img.set_pixel(x, 5, Color(1.0, 0.30, 0.20, 1.0))
	
	# Shoulder warning lights (blue flash)
	for x in [2, 17]:
		img.set_pixel(x, 9, Color(0.15, 0.50, 1.0, 1.0))
		img.set_pixel(x, 10, Color(0.15, 0.50, 1.0, 1.0))
	
	# Status indicators on chest (red)
	img.set_pixel(5, 14, Color(1.0, 0.20, 0.15, 1.0))
	img.set_pixel(6, 14, Color(1.0, 0.20, 0.15, 1.0))
	img.set_pixel(13, 14, Color(1.0, 0.20, 0.15, 1.0))
	img.set_pixel(14, 14, Color(1.0, 0.20, 0.15, 1.0))
	
	# Antenna (tall threat detector)
	img.set_pixel(10, 0, Color(0.40, 0.42, 0.48, 1.0))
	img.set_pixel(10, 1, Color(0.50, 0.52, 0.58, 1.0))
	img.set_pixel(10, 0, Color(1.0, 0.20, 0.15, 1.0))  # red tip
	
	# Heavy base/treads
	for x in range(2, 18):
		img.set_pixel(x, 22, Color(0.18, 0.20, 0.25, 1.0))
		img.set_pixel(x, 23, Color(0.15, 0.17, 0.22, 1.0))
	
	return ImageTexture.create_from_image(img)

func _make_shelf_machine_texture() -> ImageTexture:
	# Tall thin shelf-scanning robot with scanning arm
	var img := Image.create(16, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Body (metallic white/gray)
	for x in range(3, 13):
		for y in range(10, 26):
			img.set_pixel(x, y, Color(0.70, 0.72, 0.78, 1.0))
	
	# Darker panel inset
	for x in range(5, 11):
		for y in range(14, 22):
			img.set_pixel(x, y, Color(0.50, 0.52, 0.58, 1.0))
	
	# Head unit (scanner dome)
	for x in range(4, 12):
		for y in range(2, 10):
			img.set_pixel(x, y, Color(0.60, 0.62, 0.68, 1.0))
	
	# GREEN scanning laser eye
	for x in range(5, 11):
		for y in range(3, 8):
			img.set_pixel(x, y, Color(0.15, 0.85, 0.40, 1.0))
	# Bright center
	for x in range(6, 10):
		img.set_pixel(x, 5, Color(0.30, 1.0, 0.60, 1.0))
		img.set_pixel(x, 6, Color(0.30, 1.0, 0.60, 1.0))
	
	# Scanner arm (side-mounted)
	for y in range(12, 24):
		img.set_pixel(12, y, Color(0.50, 0.52, 0.58, 1.0))
	# Arm sensor head
	img.set_pixel(12, 22, Color(0.30, 0.32, 0.38, 1.0))
	img.set_pixel(13, 22, Color(0.40, 0.90, 0.50, 1.0))  # green sensor
	img.set_pixel(14, 23, Color(0.40, 0.90, 0.50, 1.0))
	img.set_pixel(15, 24, Color(0.40, 0.90, 0.50, 1.0))
	
	# Status LEDs (green = scanning)
	img.set_pixel(5, 12, Color(0.20, 1.0, 0.50, 1.0))
	img.set_pixel(10, 12, Color(0.20, 1.0, 0.50, 1.0))
	
	# Antenna
	img.set_pixel(8, 0, Color(0.55, 0.57, 0.62, 1.0))
	img.set_pixel(8, 1, Color(0.20, 0.90, 0.50, 1.0))  # green tip
	
	# Wheels/base
	img.set_pixel(3, 27, Color(0.40, 0.42, 0.48, 1.0))
	img.set_pixel(4, 27, Color(0.35, 0.37, 0.42, 1.0))
	img.set_pixel(11, 27, Color(0.40, 0.42, 0.48, 1.0))
	img.set_pixel(12, 27, Color(0.35, 0.37, 0.42, 1.0))
	
	return ImageTexture.create_from_image(img)

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

func _build_patrol_for_humanoid() -> void:
	match _assigned_staff_role:
		ActorData.StaffRole.GREETER:
			_patrol_points = [Vector2(300, 100), Vector2(320, 100), Vector2(300, 100)]
		ActorData.StaffRole.MANAGER:
			_patrol_points = [
				Vector2(200, 200), Vector2(500, 200), Vector2(500, 350),
				Vector2(200, 350), Vector2(200, 200)
			]
		ActorData.StaffRole.SECURITY:
			_patrol_points = [
				Vector2(100, 100), Vector2(700, 100), Vector2(700, 400),
				Vector2(100, 400), Vector2(100, 100)
			]
		_:
			_patrol_points = [Vector2(300, 300), Vector2(450, 300), Vector2(450, 400), Vector2(300, 400)]

func _build_patrol_for_robot(rrole: ActorData.RobotRole) -> void:
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT:
			_patrol_points = [
				Vector2(200, 300), Vector2(600, 300), Vector2(600, 450),
				Vector2(200, 450), Vector2(200, 300)
			]
		ActorData.RobotRole.GUIDANCE_ROBOT:
			_patrol_points = [
				Vector2(300, 100), Vector2(600, 100), Vector2(600, 200),
				Vector2(300, 200), Vector2(300, 100)
			]
		ActorData.RobotRole.SECURITY_ROBOT:
			_patrol_points = [
				Vector2(100, 100), Vector2(700, 100), Vector2(700, 400),
				Vector2(100, 400), Vector2(100, 100)
			]
		ActorData.RobotRole.SHELF_ROBOT:
			_patrol_points = [
				Vector2(150, 200), Vector2(350, 200), Vector2(550, 200),
				Vector2(150, 400), Vector2(350, 400)
			]
		_:
			_patrol_points = []

func _process(delta: float) -> void:
	_anim_timer += delta
	_do_behavior(delta)
	_update_sprite()

	# Eye glow pulse
	if _eye_glow:
		var pulse := 0.6 + 0.4 * sin(_anim_timer * 2.5)
		_eye_glow.modulate.a = pulse

func _do_behavior(delta: float) -> void:
	if _is_humanoid:
		_do_humanoid_behavior(delta)
	else:
		_do_machine_behavior(delta)

func _do_humanoid_behavior(delta: float) -> void:
	match _assigned_staff_role:
		ActorData.StaffRole.CASHIER:
			_do_cashier_humanoid(delta)
		ActorData.StaffRole.GREETER:
			_do_greeter_humanoid(delta)
		ActorData.StaffRole.SECURITY:
			_do_security_humanoid(delta)
		ActorData.StaffRole.CLEANER:
			_do_cleaner_humanoid(delta)
		ActorData.StaffRole.SHELF_STOCKER:
			_do_stocker_humanoid(delta)
		_:
			_do_patrol_humanoid(delta)

func _do_cashier_humanoid(_delta: float) -> void:
	# Cashier stands at position, processes items
	_state = "working"
	if _tool_sprite:
		_tool_sprite.visible = true
	_show_speech_bubble_text("Scan items...")

func _do_greeter_humanoid(delta: float) -> void:
	# Greeter waves at customers
	if _patrol_points.is_empty():
		return
	_state_timer += delta
	if _state_timer >= 4.0:
		_state_timer = 0.0
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
	var target :Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_show_speech_bubble_text("Welcome!")

func _do_security_humanoid(delta: float) -> void:
	# Security patrols like NPC security
	if _patrol_points.is_empty():
		return
	var target :Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 12.0:
		_state_timer += delta
		if _state_timer >= 2.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			_show_speech_bubble_text("All clear.")

func _do_cleaner_humanoid(delta: float) -> void:
	# Cleaner moves between spots, holds mop
	if _tool_sprite:
		_tool_sprite.visible = true
	if _patrol_points.is_empty():
		return
	var target :Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_state_timer += delta
		if _state_timer >= 3.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			_show_speech_bubble_text("Sparkling!")

func _do_stocker_humanoid(delta: float) -> void:
	# Shelf stocker moves between sections
	if _patrol_points.is_empty():
		return
	var target :Vector2 = _patrol_points[_patrol_index]
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
	var target :Vector2 = _patrol_points[_patrol_index]
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

func _do_machine_behavior(delta: float) -> void:
	match _actor.robot_role:
		ActorData.RobotRole.CLEANING_ROBOT:
			_do_cleaning_machine(delta)
		ActorData.RobotRole.GUIDANCE_ROBOT:
			_do_guidance_machine(delta)
		ActorData.RobotRole.SECURITY_ROBOT:
			_do_security_machine(delta)
		ActorData.RobotRole.DELIVERY_ROBOT:
			_do_delivery_machine(delta)
		ActorData.RobotRole.SHELF_ROBOT:
			_do_shelf_machine(delta)

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
	# Move between guidance points, show info
	if _patrol_points.is_empty():
		return
	var target :Vector2 = _patrol_points[_patrol_index]
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
	var target :Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 12.0:
		_state_timer += delta
		if _state_timer >= 2.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			# Alert flash on patrol point (use timer-based approach to avoid await issues)
			_flash_eye_alert()
			_show_speech_bubble_text("Area secure.")

func _flash_eye_alert() -> void:
	# First flash red
	_eye_glow.modulate = Color(1.0, 0.2, 0.15, 1.0)
	# Schedule return to normal color
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
	var target :Vector2 = _patrol_points[_patrol_index]
	_move_towards(target, delta)
	if _global_pos.distance_to(target) < 10.0:
		_state_timer += delta
		if _state_timer >= 5.0:
			_state_timer = 0.0
			_patrol_index = (_patrol_index + 1) % _patrol_points.size()
			robot_work_done.emit("shelf_scan", _global_pos)

func _show_speech_bubble_text(text: String) -> void:
	if _speech_bubble == null:
		_speech_bubble = Label.new()
		_speech_bubble.add_theme_color_override("font_color", Color(0.95, 0.95, 0.70))
		_speech_bubble.add_theme_font_size_override("font_size", 7)
		_speech_bubble.text = text
		add_child(_speech_bubble)
	else:
		_speech_bubble.text = text
	# Position above sprite
	_speech_bubble.position = Vector2(-20, -28)

func _update_sprite() -> void:
	if _sprite == null:
		return
	if _is_humanoid:
		_sprite.flip_h = _flip_h
		# Walk bob animation
		if _is_walking:
			_bob_offset = sin(_anim_timer * 8.0) * 2.0
		else:
			_bob_offset = 0.0
		_sprite.position.y = _bob_offset
		# Frame walk cycle
		_sprite.frame = int(_anim_timer * 3) % 4
	else:
		# Machine bob
		_sprite.position.y = sin(_anim_timer * 3.0) * 1.0
		if _state == "moving":
			_sprite.frame = int(_anim_timer * 4) % 4
