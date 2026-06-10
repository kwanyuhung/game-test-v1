# robot_controller.gd
# AI Robot Staff Controller - handles both HUMANOID and SINGLE_FUNCTION robots
# HUMANOID: looks like a human with robot features, can communicate and use tools
# SINGLE_FUNCTION: specialized machines (cleaning, guiding, delivery, security, shelf)
class_name RobotController
extends Node2D

const ActorData = preload("res://scripts/entities/actor_data.gd")
const FloorConfig = preload("res://scripts/world/floor_config.gd")
const FloorManagerScript = preload("res://scripts/world/floor_manager.gd")

const CELL_SIZE := 16
# Horizontal world extent — robots can roam on the current floor but not
# off the left/right edges. Vertical extent is per-floor, not whole-world.
const WORLD_PIXEL_W := 512 * CELL_SIZE

# Core state
var _actor: ActorData.Actor = null
var _sprite: Sprite2D = null
var _shadow: Sprite2D = null
var _eye_glow: Sprite2D = null
var _speech_bubble: Label = null
var _tool_sprite: Sprite2D = null

# Movement
var _global_pos := Vector2.ZERO
var _floor_idx: int = 0  # floor this robot is bound to (set by configure_*)
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

# Bounding box borders for debug/proximity display
var _top_border: ColorRect = null
var _bottom_border: ColorRect = null
var _left_border: ColorRect = null
var _right_border: ColorRect = null
var _bounds_visible: bool = true

# Mouse-hover Area2D — feeds the floating hover panel.
var _hover_area: Area2D = null

# Freeze state for FloorManager LOD system
var _frozen: bool = false

# Freeze/unfreeze for FloorManager LOD system
func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	if frozen:
		set_physics_process(false)
		set_process(false)
	else:
		set_physics_process(true)
		set_process(true)

func is_frozen() -> bool:
	return _frozen

# Signals
signal robot_work_done(role: String, pos: Vector2)

func _ready() -> void:
	_actor = ActorData.Actor.new()
	_build_shadow()
	_build_hover_area()

# ─── Configuration ───────────────────────────────────────────────────

func configure_humanoid(staff_role: ActorData.StaffRole, start_pos: Vector2, patrol_points: Array = [], floor_idx: int = 0) -> void:
	_actor = ActorData.Actor.new()
	_is_humanoid = true
	_assigned_staff_role = staff_role
	_floor_idx = floor_idx

	_actor.role = ActorData.Role.ROBOT
	_actor.robot_type = ActorData.RobotType.HUMANOID
	_actor.robot_role = ActorData.RobotRole.SHELF_ROBOT
	_actor.staff_role = staff_role
	_actor.appearance = ActorData.Appearance.random()
	_actor.display_name = "Robo-" + _get_staff_role_name(staff_role)
	_actor.energy = 1.0
	# random_staff already set a default movement_bounds.mode based on role.
	# Anchor the bounds to start_pos for STANDBY/anchor reference.
	_actor.movement_bounds.anchor = start_pos

	_global_pos = _to_world(start_pos, floor_idx)
	position = _global_pos
	_speed = _get_speed_for_role(staff_role)
	_state = "working"

	_build_humanoid_sprite()
	if patrol_points.is_empty():
		_build_patrol_for_humanoid()
		# No explicit waypoints — if the role defaulted to FIXED_RANGE,
		# fall back to STANDBY at the spawn position.
		if _actor.movement_bounds.mode == ActorData.MovementMode.FIXED_RANGE:
			_actor.movement_bounds.mode = ActorData.MovementMode.STANDBY
	else:
		_patrol_points = _offset_patrol(patrol_points, floor_idx)
		_patrol_index = 0
		# Patrol points override the default — actor is FIXED_RANGE.
		_actor.movement_bounds.mode = ActorData.MovementMode.FIXED_RANGE
		_actor.movement_bounds.waypoints = patrol_points.duplicate()

func configure_single_function(rrole: ActorData.RobotRole, start_pos: Vector2, patrol_points: Array = [], floor_idx: int = 0) -> void:
	_actor = ActorData.Actor.new()
	_is_humanoid = false
	_floor_idx = floor_idx

	_actor.role = ActorData.Role.ROBOT
	_actor.robot_type = ActorData.RobotType.SINGLE_FUNCTION
	_actor.robot_role = rrole
	_actor.energy = 1.0
	# random_robot already set a default movement_bounds.mode based on role.
	_actor.movement_bounds.anchor = start_pos

	_global_pos = _to_world(start_pos, floor_idx)
	position = _global_pos
	_speed = _get_speed_for_robot_role(rrole)
	_state = "working"

	_build_machine_sprite(rrole)
	if patrol_points.is_empty():
		_build_patrol_for_robot(rrole)
		if _actor.movement_bounds.mode == ActorData.MovementMode.FIXED_RANGE:
			_actor.movement_bounds.mode = ActorData.MovementMode.STANDBY
	else:
		_patrol_points = _offset_patrol(patrol_points, floor_idx)
		_patrol_index = 0
		_actor.movement_bounds.mode = ActorData.MovementMode.FIXED_RANGE
		_actor.movement_bounds.waypoints = patrol_points.duplicate()

# Convert a position passed in floor-local tile coordinates to world pixels.
# All spawn_pos and patrol_points are written in the old small-world style
# (e.g. (300, 100) meaning tile (300, 100) on floor 0's grid). To make the
# robot sit inside the current 512-tile world, add the floor's container_y.
func _to_world(local: Vector2, floor_idx: int) -> Vector2:
	var floor_y: float = FloorManagerScript.get_floor_y(floor_idx)
	return Vector2(local.x, floor_y + local.y)

func _offset_patrol(points: Array, floor_idx: int) -> Array:
	var out: Array = []
	for p in points:
		if p is Vector2:
			out.append(_to_world(p, floor_idx))
	return out

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
		ActorData.StaffRole.SHOP_STAFF: return "Shop Staff"
		ActorData.StaffRole.FOOD_STAFF: return "Food Staff"
		ActorData.StaffRole.CLEAN_STAFF: return "Clean Staff"
		ActorData.StaffRole.RECEPTIONIST: return "Receptionist"
		ActorData.StaffRole.MAINTENANCE_STAFF: return "Maintenance"
		ActorData.StaffRole.DELIVERY_STAFF: return "Delivery"
		ActorData.StaffRole.CUSTOMER_SERVICE: return "Customer Service"
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

func _add_bounding_box_border(border_color: Color) -> void:
	# mouse_filter IGNORE so the borders don't intercept cursor events
	# (the Area2D hover picker needs to receive them).
	# Top border
	_top_border = ColorRect.new()
	_top_border.size = Vector2(24, 1)
	_top_border.position = Vector2(-12, -12)
	_top_border.color = border_color
	_top_border.z_index = 100
	_top_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_border)
	# Bottom border
	_bottom_border = ColorRect.new()
	_bottom_border.size = Vector2(24, 1)
	_bottom_border.position = Vector2(-12, 11)
	_bottom_border.color = border_color
	_bottom_border.z_index = 100
	_bottom_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bottom_border)
	# Left border
	_left_border = ColorRect.new()
	_left_border.size = Vector2(1, 24)
	_left_border.position = Vector2(-12, -12)
	_left_border.color = border_color
	_left_border.z_index = 100
	_left_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_left_border)
	# Right border
	_right_border = ColorRect.new()
	_right_border.size = Vector2(1, 24)
	_right_border.position = Vector2(11, -12)
	_right_border.color = border_color
	_right_border.z_index = 100
	_right_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_right_border)

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
	
	# Add bounding box border for humanoid robot
	_add_bounding_box_border(Color(1.0, 0.5, 0.0, 0.8))

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
	
	# Add bounding box border for machine robot
	_add_bounding_box_border(Color(1.0, 0.5, 0.0, 0.8))

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
		top_col = _actor.appearance.top.color
		bot_col = _actor.appearance.bottom.color
	
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
		ActorData.StaffRole.CUSTOMER_SERVICE:
			# Clipboard: tan body + darker clip on top
			for x in range(2, 6):
				for y in range(3, 7):
					img.set_pixel(x, y, Color(0.78, 0.68, 0.42, 1.0))
			for x in range(2, 6):
				img.set_pixel(x, 2, Color(0.32, 0.28, 0.22, 1.0))
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
	var local_pts: Array = []
	match _assigned_staff_role:
		ActorData.StaffRole.GREETER:
			local_pts = [Vector2(300, 100), Vector2(320, 100), Vector2(300, 100)]
		ActorData.StaffRole.MANAGER:
			local_pts = [Vector2(200, 200), Vector2(500, 200), Vector2(500, 350), Vector2(200, 350), Vector2(200, 200)]
		ActorData.StaffRole.SECURITY:
			local_pts = [Vector2(100, 100), Vector2(700, 100), Vector2(700, 400), Vector2(100, 400), Vector2(100, 100)]
		_:
			local_pts = [Vector2(300, 300), Vector2(450, 300), Vector2(450, 400), Vector2(300, 400)]
	_patrol_points = _offset_patrol(local_pts, _floor_idx)
	_patrol_index = 0

func _build_patrol_for_robot(rrole: ActorData.RobotRole) -> void:
	var local_pts: Array = []
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT:
			local_pts = [Vector2(200, 300), Vector2(600, 300), Vector2(600, 450), Vector2(200, 450), Vector2(200, 300)]
		ActorData.RobotRole.GUIDANCE_ROBOT:
			local_pts = [Vector2(300, 100), Vector2(600, 100), Vector2(600, 200), Vector2(300, 200), Vector2(300, 100)]
		ActorData.RobotRole.SECURITY_ROBOT:
			local_pts = [Vector2(100, 100), Vector2(700, 100), Vector2(700, 400), Vector2(100, 400), Vector2(100, 100)]
		ActorData.RobotRole.SHELF_ROBOT:
			local_pts = [Vector2(150, 200), Vector2(350, 200), Vector2(550, 200), Vector2(150, 400), Vector2(350, 400)]
		_:
			local_pts = []
	_patrol_points = _offset_patrol(local_pts, _floor_idx)
	_patrol_index = 0

# ─── Main Loop ─────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_anim_timer += delta
	_do_behavior(delta)
	_clamp_to_world()
	_update_sprite()

	if _eye_glow:
		var pulse := 0.6 + 0.4 * sin(_anim_timer * 2.5)
		_eye_glow.modulate.a = pulse

func _do_behavior(delta: float) -> void:
	if _is_humanoid:
		_do_humanoid_behavior(delta)
	else:
		_do_machine_behavior(delta)

func _clamp_to_world() -> void:
	# Robots are bound to a single floor (set at configure time). Clamp to
	# the [min, max] world Y of that floor's zone bounds, not the whole
	# world — otherwise they can drift into other floors' areas or above
	# the world top.
	_global_pos.x = clampf(_global_pos.x, 0.0, WORLD_PIXEL_W - 1.0)
	var y_range := _floor_y_range(_floor_idx)
	_global_pos.y = clampf(_global_pos.y, y_range.x, y_range.y)
	position = _global_pos

func _floor_y_range(floor_idx: int) -> Vector2:
	if floor_idx < 0 or floor_idx >= FloorConfig.floor_count():
		return Vector2(0.0, WORLD_PIXEL_W)
	var container_y: float = FloorManagerScript.get_floor_y(floor_idx)
	var zone_bounds: Dictionary = FloorConfig.get_floor_zone_bounds(floor_idx)
	var min_world_y: float = container_y + float(zone_bounds.min_y) * CELL_SIZE
	var max_world_y: float = container_y + float(zone_bounds.max_y) * CELL_SIZE
	return Vector2(min_world_y, max_world_y)

# ─── Humanoid Behavior ─────────────────────────────────────────────

func _do_humanoid_behavior(delta: float) -> void:
	match _assigned_staff_role:
		ActorData.StaffRole.CASHIER: _do_cashier_humanoid(delta)
		ActorData.StaffRole.GREETER: _do_greeter_humanoid(delta)
		ActorData.StaffRole.SECURITY: _do_security_humanoid(delta)
		ActorData.StaffRole.CLEANER: _do_cleaner_humanoid(delta)
		ActorData.StaffRole.SHELF_STOCKER: _do_stocker_humanoid(delta)
		ActorData.StaffRole.CUSTOMER_SERVICE: _do_customer_service_humanoid(delta)
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

func _do_customer_service_humanoid(delta: float) -> void:
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
			_show_speech_bubble_text("How can I help?")

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
		if _sprite.hframes > 1:
			_sprite.frame = int(_anim_timer * 3) % _sprite.hframes
	else:
		_sprite.position.y = sin(_anim_timer * 3.0) * 1.0
		if _state == "moving" and _sprite.hframes > 1:
			_sprite.frame = int(_anim_timer * 4) % _sprite.hframes

func set_bounds_visible(visible: bool) -> void:
	_bounds_visible = visible
	if _top_border != null:
		_top_border.visible = visible
	if _bottom_border != null:
		_bottom_border.visible = visible
	if _left_border != null:
		_left_border.visible = visible
	if _right_border != null:
		_right_border.visible = visible

# Hover Panel Integration

func _build_hover_area() -> void:
	_hover_area = Area2D.new()
	_hover_area.input_pickable = true
	_hover_area.monitoring = false
	_hover_area.monitorable = false
	var hover_shape := CollisionShape2D.new()
	var hover_rect := RectangleShape2D.new()
	hover_rect.size = Vector2(20, 22)
	hover_shape.shape = hover_rect
	_hover_area.add_child(hover_shape)
	_hover_area.mouse_entered.connect(_on_hover_entered)
	_hover_area.mouse_exited.connect(_on_hover_exited)
	add_child(_hover_area)
	add_to_group("hoverable")

func _on_hover_entered() -> void:
	var panel := get_tree().get_first_node_in_group("hover_panel")
	if panel != null:
		panel.show_for(self)

func _on_hover_exited() -> void:
	var panel := get_tree().get_first_node_in_group("hover_panel")
	if panel != null:
		panel.hide_for(self)

# Used by HoverPanel to detect overlaps without re-triggering mouse events.
func contains_world_point(world_point: Vector2) -> bool:
	if _hover_area == null:
		return false
	for child in _hover_area.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var local: Vector2 = _hover_area.global_transform.affine_inverse() * world_point
			var half: Vector2 = (child.shape as RectangleShape2D).size * 0.5
			return absf(local.x) <= half.x and absf(local.y) <= half.y
	return false

func get_hover_info() -> Dictionary:
	if _actor == null:
		return {}

	var role_text := ""
	if _is_humanoid:
		role_text = "Humanoid Robot — " + _get_staff_role_name(_assigned_staff_role)
	else:
		role_text = "Machine — " + _hover_robot_role_name(_actor.robot_role)

	var appearance_lines: Array = []
	appearance_lines.append("Battery: %d%%" % int(_battery * 100.0))
	appearance_lines.append("Speed: %d" % int(_speed))
	if _is_humanoid and _tool_sprite != null and _tool_sprite.visible:
		appearance_lines.append("Tool: equipped")
	if _is_humanoid and _actor != null and _actor.appearance != null:
		var ap: ActorData.Appearance = _actor.appearance
		appearance_lines.append("Hair: %s (%s)" % [
			_hover_hair_style_name(ap.hair.style),
			_hover_color_name(ap.hair.color)
		])
		appearance_lines.append("Top: %s (%s)" % [
			_hover_top_style_name(ap.top.style),
			_hover_color_name(ap.top.color)
		])
		appearance_lines.append("Bottom: %s (%s)" % [
			_hover_bottom_style_name(ap.bottom.style),
			_hover_color_name(ap.bottom.color)
		])
		var accs: Array = []
		if ap.has_glasses:
			accs.append("glasses")
		if ap.top.accessory != null and not ap.top.accessory.is_none():
			match ap.top.accessory.type:
				ActorData.TOP_ACC_BADGE: accs.append("badge")
				ActorData.TOP_ACC_NAME_TAG: accs.append("name tag")
				ActorData.TOP_ACC_APRON: accs.append("apron")
		if not accs.is_empty():
			appearance_lines.append("Accessories: " + ", ".join(accs))

	var bounds: ActorData.MovementBounds = _actor.movement_bounds
	var mode_int: int = ActorData.MovementMode.FREE
	var waypoint_count := 0
	var anchor := Vector2.ZERO
	if bounds != null:
		mode_int = bounds.mode
		waypoint_count = bounds.waypoints.size()
		anchor = bounds.anchor
	# Fall back to the live patrol list if movement_bounds.waypoints was
	# empty (e.g. machines whose patrol is generated procedurally).
	if waypoint_count == 0 and not _patrol_points.is_empty():
		waypoint_count = _patrol_points.size()
		if mode_int == ActorData.MovementMode.STANDBY:
			mode_int = ActorData.MovementMode.FIXED_RANGE

	return {
		"name": _actor.display_name,
		"role": role_text,
		"appearance": "\n".join(appearance_lines),
		"sprite": (_sprite.texture if _sprite != null else null),
		"movement_mode": mode_int,
		"waypoint_count": waypoint_count,
		"anchor": anchor,
		"state": _state.capitalize(),
		"floor": _floor_idx,
	}

func _hover_robot_role_name(p_role: int) -> String:
	match p_role:
		ActorData.RobotRole.CLEANING_ROBOT: return "Cleaning"
		ActorData.RobotRole.GUIDANCE_ROBOT: return "Guidance"
		ActorData.RobotRole.DELIVERY_ROBOT: return "Delivery"
		ActorData.RobotRole.SECURITY_ROBOT: return "Security"
		ActorData.RobotRole.SHELF_ROBOT: return "Shelf Scan"
	return "Robot"

func _hover_hair_style_name(s: int) -> String:
	match s:
		0: return "bob"
		1: return "long"
		2: return "short"
		3: return "buzz"
	return "?"

func _hover_top_style_name(s: int) -> String:
	match s:
		0: return "t-shirt"
		1: return "shirt"
		2: return "sweater"
		3: return "jacket"
		4: return "tank"
	return "?"

func _hover_bottom_style_name(s: int) -> String:
	match s:
		0: return "pants"
		1: return "skirt"
		2: return "shorts"
		3: return "dress"
	return "?"

func _hover_color_name(c: Color) -> String:
	var r: float = c.r
	var g: float = c.g
	var b: float = c.b
	var max_c: float = maxf(r, maxf(g, b))
	var min_c: float = minf(r, minf(g, b))
	var sat: float = 0.0
	if max_c > 0.0:
		sat = (max_c - min_c) / max_c
	if sat < 0.18:
		if max_c > 0.92: return "white"
		if max_c > 0.72: return "light grey"
		if max_c > 0.45: return "grey"
		if max_c > 0.22: return "dark grey"
		return "black"
	if r > g and r > b:
		if g > 0.45 and b < 0.30: return "orange"
		if g < 0.30 and b < 0.30: return "red"
		if b > 0.40: return "magenta"
		return "pink"
	if g > r and g > b:
		if r > 0.40 and b < 0.30: return "olive"
		if b > 0.40: return "teal"
		return "green"
	if r > 0.30 and g > 0.30: return "sky blue"
	if r > 0.20: return "navy"
	return "blue"
