# map_panel.gd
# Full-screen floor map with NPC/robot markers and hover tooltips
class_name MapPanel
extends CanvasLayer

const CELL_SIZE := 16
const WORLD_W := 96
const WORLD_H := 52

# Map display scale
const MAP_SCALE := 6.0

# Robot marker colors by type
const ROBOT_COLORS := {
	"cleaner": Color(0.20, 0.80, 0.60),      # Cyan
	"guide": Color(0.90, 0.70, 0.30),        # Orange
	"security": Color(0.90, 0.20, 0.20),     # Red
	"shelf": Color(0.30, 0.90, 0.40),        # Green
	"delivery": Color(0.60, 0.50, 0.90),    # Purple
	"humanoid": Color(0.40, 0.80, 0.95),    # Light blue
	"unknown": Color(0.80, 0.80, 0.80),     # Gray
}

var _player_ref = null
var _main_ref = null
var _floor_idx := 0
var _items: Array = []
var _item_labels: Array = []
var _robot_dots: Array = []
var _robot_tooltips: Dictionary = {}  # dot -> label
var _player_dot: ColorRect = null
var _bg_panel: Panel = null
var _title_label: Label = null
var _map_container: Control = null
var _hover_label: Label = null
var _map_w: float = 256.0
var _map_h: float = 139.0
var _map_offset: Vector2 = Vector2(20, 40)
var _font_scale: float = 1.0
var _hovered_robot_dot: ColorRect = null

# Floor item definitions
const FLOOR_ITEMS := {
	0: {  # Ground floor
		"parking": {"pos": Vector2(5, 8), "label": "Parking", "color": Color(0.30, 0.40, 0.60)},
		"food_court": {"pos": Vector2(15, 20), "label": "Food Court", "color": Color(0.85, 0.55, 0.30)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
		"checkout": {"pos": Vector2(50, 40), "label": "Checkout", "color": Color(0.30, 0.80, 0.40)},
		"atm": {"pos": Vector2(40, 30), "label": "ATM", "color": Color(0.90, 0.85, 0.30)},
		"loyalty": {"pos": Vector2(30, 35), "label": "Loyalty", "color": Color(0.90, 0.40, 0.70)},
		"info": {"pos": Vector2(60, 25), "label": "Info Desk", "color": Color(0.60, 0.60, 0.80)},
	},
	1: {  # Floor 1 - Shoes
		"ladies_shoes": {"pos": Vector2(10, 12), "label": "Ladies Shoes", "color": Color(0.82, 0.55, 0.65)},
		"mens_shoes": {"pos": Vector2(40, 12), "label": "Mens Shoes", "color": Color(0.55, 0.60, 0.80)},
		"kids_shoes": {"pos": Vector2(70, 12), "label": "Kids Shoes", "color": Color(0.70, 0.75, 0.90)},
		"sport_shoes": {"pos": Vector2(10, 30), "label": "Sport Shoes", "color": Color(0.55, 0.80, 0.65)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	2: {  # Floor 2 - Fashion/Wear
		"ladies_wear": {"pos": Vector2(10, 12), "label": "Ladies Wear", "color": Color(0.88, 0.58, 0.72)},
		"mens_wear": {"pos": Vector2(40, 12), "label": "Mens Wear", "color": Color(0.60, 0.68, 0.88)},
		"kids_wear": {"pos": Vector2(70, 12), "label": "Kids Wear", "color": Color(0.90, 0.75, 0.60)},
		"activewear": {"pos": Vector2(10, 30), "label": "Activewear", "color": Color(0.55, 0.80, 0.65)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	3: {  # Floor 3 - Drinks
		"drinks": {"pos": Vector2(40, 20), "label": "Drinks", "color": Color(0.40, 0.60, 0.90)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	4: {  # Floor 4 - Snacks
		"snacks2": {"pos": Vector2(35, 20), "label": "Snacks", "color": Color(0.90, 0.60, 0.20)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	5: {  # Floor 5 - Frozen
		"frozen": {"pos": Vector2(40, 20), "label": "Frozen", "color": Color(0.50, 0.80, 0.95)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	6: {  # Floor 6 - Household
		"household": {"pos": Vector2(40, 20), "label": "Household", "color": Color(0.60, 0.50, 0.70)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	7: {  # Floor 7 - Health & Beauty
		"hb": {"pos": Vector2(40, 20), "label": "Health & Beauty", "color": Color(0.90, 0.50, 0.70)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	8: {  # Floor 8 - Arcade
		"arcade": {"pos": Vector2(40, 20), "label": "Arcade", "color": Color(0.90, 0.30, 0.90)},
		"claw": {"pos": Vector2(60, 25), "label": "Claw Machine", "color": Color(0.95, 0.75, 0.30)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	9: {  # Floor 9 - Staff Area
		"staff": {"pos": Vector2(40, 20), "label": "Staff Room", "color": Color(0.40, 0.40, 0.45)},
		"warehouse_entrance": {"pos": Vector2(60, 30), "label": "Warehouse", "color": Color(0.60, 0.50, 0.40)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	11: {  # Floor 11 - Warehouse
		"warehouse": {"pos": Vector2(40, 25), "label": "Warehouse", "color": Color(0.70, 0.55, 0.35)},
		"dock": {"pos": Vector2(80, 25), "label": "Truck Dock", "color": Color(0.50, 0.60, 0.40)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
}

func _ready() -> void:
	visible = false

func set_player(player) -> void:
	_player_ref = player

func set_main(main) -> void:
	_main_ref = main

func set_floor(idx: int) -> void:
	_floor_idx = idx
	_update_title()
	_build_items()

func toggle() -> void:
	visible = not visible
	if visible:
		_build_panel()
		_build_items()
	else:
		_clear_items()

func open() -> void:
	visible = true
	_build_panel()
	_build_items()

func close() -> void:
	visible = false
	_clear_items()

func _build_panel() -> void:
	# Compute dynamic map size based on screen
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var scr_w: float = viewport_rect.size.x
	var scr_h: float = viewport_rect.size.y
	_font_scale = clampf(scr_h / 720.0, 0.6, 1.5)
	
	# Dynamic map dimensions - scale to fill more of screen
	_map_w = scr_w * 0.50
	_map_h = scr_h * 0.70
	
	# Background panel
	if _bg_panel == null:
		_bg_panel = Panel.new()
		_bg_panel.set_anchors_preset(Control.PRESET_CENTER)
		_bg_panel.custom_minimum_size = Vector2(_map_w + 100 * _font_scale, _map_h + 120 * _font_scale)
		_bg_panel.position = -_bg_panel.custom_minimum_size / 2
		_bg_panel.z_index = 1000
		
		# Style
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
		style.border_color = Color(0.35, 0.45, 0.60)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.set_border_width_all(2)
		style.set_content_margin_all(12)
		_bg_panel.add_theme_stylebox_override("panel", style)
		
		add_child(_bg_panel)
		
		# Title
		_title_label = Label.new()
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.position = Vector2(0, 8 * _font_scale)
		_title_label.size = Vector2(_bg_panel.custom_minimum_size.x, 30 * _font_scale)
		_title_label.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95))
		_title_label.add_theme_font_size_override("font_size", int(18 * _font_scale))
		_title_label.z_index = 500
		_bg_panel.add_child(_title_label)
		
		# Hover tooltip label (hidden by default)
		_hover_label = Label.new()
		_hover_label.visible = false
		_hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hover_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
		_hover_label.add_theme_font_size_override("font_size", int(12 * _font_scale))
		_hover_label.add_theme_stylebox_override("normal", _make_tooltip_style())
		_hover_label.z_index = 600
		_bg_panel.add_child(_hover_label)
		
		# Legend panel
		_build_legend()
	
	# Calculate map offset relative to the background panel (centered)
	var panel_size: Vector2 = _bg_panel.custom_minimum_size
	var title_height: float = 45 * _font_scale
	var legend_width: float = 140 * _font_scale
	_map_offset = Vector2(
		(panel_size.x - _map_w - legend_width) / 2.0,
		title_height
	)

func _make_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.20, 0.95)
	style.border_color = Color(0.60, 0.70, 0.90)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	return style

func _build_legend() -> void:
	var legend_panel := Panel.new()
	legend_panel.name = "LegendPanel"
	legend_panel.z_index = 500  # Ensure legend is on top of map elements
	var lx := _bg_panel.custom_minimum_size.x - 140 * _font_scale
	var ly := 45 * _font_scale
	legend_panel.position = Vector2(lx, ly)
	legend_panel.custom_minimum_size = Vector2(120 * _font_scale, 130 * _font_scale)
	
	var legend_style := StyleBoxFlat.new()
	legend_style.bg_color = Color(0.12, 0.12, 0.18, 0.90)
	legend_style.border_color = Color(0.30, 0.35, 0.45)
	legend_style.corner_radius_top_left = 8
	legend_style.corner_radius_top_right = 8
	legend_style.corner_radius_bottom_left = 8
	legend_style.corner_radius_bottom_right = 8
	legend_style.set_border_width_all(1)
	legend_style.set_content_margin_all(8)
	legend_panel.add_theme_stylebox_override("panel", legend_style)
	
	_bg_panel.add_child(legend_panel)
	
	var legend_title := Label.new()
	legend_title.text = "LEGEND"
	legend_title.position = Vector2(8, 4)
	legend_title.size = Vector2(100, 16)
	legend_title.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85))
	legend_title.add_theme_font_size_override("font_size", int(10 * _font_scale))
	legend_panel.add_child(legend_title)
	
	var y_offset := 22
	var legend_items := [
		["You", Color(0.95, 0.85, 0.30)],
		["Cleaner", ROBOT_COLORS["cleaner"]],
		["Guide", ROBOT_COLORS["guide"]],
		["Security", ROBOT_COLORS["security"]],
		["Shelf", ROBOT_COLORS["shelf"]],
		["Delivery", ROBOT_COLORS["delivery"]],
	]
	
	for item in legend_items:
		var dot := ColorRect.new()
		dot.position = Vector2(10, y_offset + 2)
		dot.size = Vector2(8, 8)
		dot.color = item[1]
		legend_panel.add_child(dot)
		
		var lbl := Label.new()
		lbl.text = item[0]
		lbl.position = Vector2(24, y_offset)
		lbl.size = Vector2(80, 14)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.82, 0.88))
		lbl.add_theme_font_size_override("font_size", int(9 * _font_scale))
		legend_panel.add_child(lbl)
		y_offset += 16

func _update_title() -> void:
	if _title_label != null:
		var floor_name := "Ground Floor"
		if _floor_idx > 0:
			floor_name = "Floor %d" % _floor_idx
		_title_label.text = "📍 %s Map  (Press M to close)" % floor_name

func _clear_items() -> void:
	for item in _items:
		item.queue_free()
	_items.clear()
	for lbl in _item_labels:
		lbl.queue_free()
	_item_labels.clear()
	_clear_robot_dots()

func _clear_robot_dots() -> void:
	for dot in _robot_dots:
		dot.queue_free()
	_robot_dots.clear()
	_robot_tooltips.clear()

func _get_robots_for_current_floor() -> Array:
	if _main_ref == null:
		return []
	
	var robots: Array = _main_ref.get("_robots")
	if robots == null:
		return []
	
	var floor_robots: Array = []
	var floor_y: float = _get_floor_y(_floor_idx)
	var floor_height: float = 160.0  # Approximate floor height
	
	for robot in robots:
		if not is_instance_valid(robot):
			continue
		var robot_pos: Vector2 = robot.position if "position" in robot else Vector2.ZERO
		# Check if robot is on this floor (by Y position)
		if abs(robot_pos.y - floor_y) < floor_height:
			floor_robots.append(robot)
	
	return floor_robots

func _get_floor_y(floor_idx: int) -> float:
	var base_y := 32 * CELL_SIZE  # 512 pixels for floor 0
	var floor_offset := floor_idx * 160.0  # FLOOR_Y_OFFSET = 160
	return base_y - floor_offset

func _get_robot_color(robot) -> Color:
	if robot == null:
		return ROBOT_COLORS["unknown"]
	
	var robot_name: String = str(robot.name) if robot.name != null else ""
	var name_lower := robot_name.to_lower()
	
	if "cleaner" in name_lower or "cleaning" in name_lower:
		return ROBOT_COLORS["cleaner"]
	elif "guide" in name_lower or "guidance" in name_lower:
		return ROBOT_COLORS["guide"]
	elif "security" in name_lower:
		return ROBOT_COLORS["security"]
	elif "shelf" in name_lower:
		return ROBOT_COLORS["shelf"]
	elif "delivery" in name_lower or "cargo" in name_lower:
		return ROBOT_COLORS["delivery"]
	elif "humanoid" in name_lower or "robo-" in name_lower:
		return ROBOT_COLORS["humanoid"]
	
	# Check actor robot_role if available
	if robot.has_method("get_actor"):
		var actor = robot.get_actor()
		if actor != null and actor.robot_role != null:
			match actor.robot_role:
				1: return ROBOT_COLORS["cleaner"]      # CLEANING_ROBOT
				2: return ROBOT_COLORS["delivery"]    # DELIVERY_ROBOT
				3: return ROBOT_COLORS["security"]    # SECURITY_ROBOT
				4: return ROBOT_COLORS["guide"]       # GUIDANCE_ROBOT
				5: return ROBOT_COLORS["shelf"]       # SHELF_ROBOT
	
	return ROBOT_COLORS["unknown"]

func _get_robot_display_name(robot) -> String:
	if robot == null:
		return "Unknown"
	
	# Try to get display name from actor
	if robot.has_method("get_actor"):
		var actor = robot.get_actor()
		if actor != null and actor.display_name != null:
			return str(actor.display_name)
	
	# Fallback to robot name with cleaning
	var robot_name: String = str(robot.name) if robot.name != null else "Robot"
	var name := robot_name.replace("Robot_", "").replace("Robot", "").replace("_", " ")
	if name.is_empty():
		name = "Robot"
	return name.capitalize()

func _build_items() -> void:
	# Ensure panel is built first (needed when called from set_floor before open)
	if _bg_panel == null:
		_build_panel()
	_clear_items()
	
	# Get floor items
	var floor_data = FLOOR_ITEMS.get(_floor_idx, {})
	
	# Draw map container background
	var map_bg := ColorRect.new()
	map_bg.name = "MapBackground"
	map_bg.position = _map_offset
	map_bg.size = Vector2(_map_w, _map_h)
	map_bg.color = Color(0.12, 0.12, 0.18, 0.85)
	map_bg.z_index = 100
	_bg_panel.add_child(map_bg)
	_items.append(map_bg)
	
	# Border around map
	var map_border := ColorRect.new()
	map_border.name = "MapBorder"
	map_border.position = _map_offset - Vector2(2, 2)
	map_border.size = Vector2(_map_w + 4, _map_h + 4)
	map_border.color = Color(0.30, 0.40, 0.55, 0.60)
	map_border.z_index = 99
	_bg_panel.add_child(map_border)
	_items.append(map_border)
	
	# Grid pattern for map
	for i in range(7):
		var grid_h := ColorRect.new()
		grid_h.position = _map_offset + Vector2(0, i * (_map_h / 6))
		grid_h.size = Vector2(_map_w, 1)
		grid_h.color = Color(0.20, 0.22, 0.28, 0.40)
		grid_h.z_index = 101
		_bg_panel.add_child(grid_h)
		_items.append(grid_h)
		
		var grid_v := ColorRect.new()
		grid_v.position = _map_offset + Vector2(i * (_map_w / 6), 0)
		grid_v.size = Vector2(1, _map_h)
		grid_v.color = Color(0.20, 0.22, 0.28, 0.40)
		grid_v.z_index = 101
		_bg_panel.add_child(grid_v)
		_items.append(grid_v)
	
	# Draw floor shops/facilities
	for key in floor_data.keys():
		var item: Dictionary = floor_data[key]
		var pos: Vector2 = item["pos"]
		var label: String = item["label"]
		var color: Color = item["color"]
		
		# Convert world position to map position
		var pixels_per_tile_x := _map_w / float(WORLD_W)
		var pixels_per_tile_y := _map_h / float(WORLD_H)
		
		var map_x := _map_offset.x + pos.x * pixels_per_tile_x
		var map_y := _map_offset.y + pos.y * pixels_per_tile_y
		
		# Shop/facility marker (rounded square)
		var marker := ColorRect.new()
		marker.name = "Shop_" + key
		marker.position = Vector2(map_x - 5 * _font_scale, map_y - 5 * _font_scale)
		marker.size = Vector2(10 * _font_scale, 10 * _font_scale)
		marker.color = color
		marker.z_index = 102
		_bg_panel.add_child(marker)
		_items.append(marker)
		
		# Shop label
		var lbl := Label.new()
		lbl.text = label
		var label_width: float = maxf(40.0, float(label.length()) * 5.5 * _font_scale)
		lbl.position = Vector2(map_x - label_width / 2.0, map_y + 8.0 * _font_scale)
		lbl.size = Vector2(label_width, 14.0 * _font_scale)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.82, 0.88))
		lbl.add_theme_font_size_override("font_size", int(9.0 * _font_scale))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.z_index = 102
		_bg_panel.add_child(lbl)
		_items.append(lbl)
		_item_labels.append(lbl)
	
	# Draw robots on the map
	_draw_robots_on_map()
	
	# Player dot
	_player_dot = ColorRect.new()
	_player_dot.name = "MapPlayerDot"
	_player_dot.size = Vector2(8 * _font_scale, 8 * _font_scale)
	_player_dot.color = Color(0.95, 0.85, 0.30)  # Yellow
	_player_dot.z_index = 200
	_bg_panel.add_child(_player_dot)
	_items.append(_player_dot)
	
	# Player label
	var player_lbl := Label.new()
	player_lbl.name = "PlayerLabel"
	player_lbl.text = "YOU"
	player_lbl.position = Vector2(0, 0)
	player_lbl.size = Vector2(30, 12)
	player_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.30))
	player_lbl.add_theme_font_size_override("font_size", int(8 * _font_scale))
	player_lbl.z_index = 201
	_bg_panel.add_child(player_lbl)
	_items.append(player_lbl)
	_item_labels.append(player_lbl)

func _draw_robots_on_map() -> void:
	var robots: Array = _get_robots_for_current_floor()
	var pixels_per_tile_x := _map_w / float(WORLD_W)
	var pixels_per_tile_y := _map_h / float(WORLD_H)
	
	for robot in robots:
		if not is_instance_valid(robot):
			continue
		
		var robot_pos: Vector2 = robot.position if "position" in robot else Vector2.ZERO
		var map_x := _map_offset.x + (robot_pos.x / CELL_SIZE) * pixels_per_tile_x / float(WORLD_W) * float(WORLD_W)
		map_x = _map_offset.x + (robot_pos.x / CELL_SIZE) * pixels_per_tile_x
		var map_y := _map_offset.y + (robot_pos.y / CELL_SIZE) * pixels_per_tile_y
		
		# Clamp to map bounds
		map_x = clampf(map_x, _map_offset.x + 5, _map_offset.x + _map_w - 5)
		map_y = clampf(map_y, _map_offset.y + 5, _map_offset.y + _map_h - 5)
		
		var robot_color: Color = _get_robot_color(robot)
		var robot_name: String = _get_robot_display_name(robot)
		
		# Robot dot marker (larger, clickable area)
		var dot := ColorRect.new()
		dot.name = "RobotDot_" + robot.name
		dot.position = Vector2(map_x - 5 * _font_scale, map_y - 5 * _font_scale)
		dot.size = Vector2(10 * _font_scale, 10 * _font_scale)
		dot.color = robot_color
		dot.z_index = 150
		
		# Add mouse filter for hover detection
		var dot_control := Control.new()
		dot_control.name = "RobotDotControl_" + robot.name
		dot_control.position = dot.position
		dot_control.size = dot.size
		dot_control.z_index = 151
		dot_control.mouse_filter = Control.MOUSE_FILTER_PASS
		dot_control.gui_input.connect(_on_robot_dot_input.bind(robot, robot_name, dot))
		_bg_panel.add_child(dot_control)
		_items.append(dot_control)
		
		# Store reference
		_robot_dots.append(dot_control)
		_robot_tooltips[dot_control] = {"robot": robot, "name": robot_name, "dot": dot}
		
		# Visual dot
		dot.position = Vector2(0, 0)
		dot_control.add_child(dot)
		
		# Add pulsing ring effect for robots
		var ring := ColorRect.new()
		ring.name = "RobotRing"
		ring.position = Vector2(-2 * _font_scale, -2 * _font_scale)
		ring.size = Vector2(14 * _font_scale, 14 * _font_scale)
		ring.color = Color(robot_color.r, robot_color.g, robot_color.b, 0.30)
		ring.z_index = 149
		dot_control.add_child(ring)

func _on_robot_dot_input(event: InputEvent, robot, robot_name: String, dot: ColorRect) -> void:
	if event is InputEventMouseMotion:
		_show_robot_tooltip(robot_name, dot)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Clicked on robot - could show more info
			pass

func _show_robot_tooltip(robot_name: String, dot: ColorRect) -> void:
	if _hover_label == null:
		return
	
	_hover_label.text = "  %s  " % robot_name
	_hover_label.visible = true
	
	# Position tooltip near the dot (use local position within _bg_panel)
	var dot_control: Control = dot.get_parent()
	if dot_control == null:
		return
	
	var dot_local_pos: Vector2 = dot_control.position + dot.size / 2.0
	var hover_pos: Vector2 = dot_local_pos + Vector2(15 * _font_scale, -10 * _font_scale)
	
	# Keep tooltip within bounds (using local coordinates)
	var panel_size: Vector2 = _bg_panel.custom_minimum_size if _bg_panel else Vector2(400, 300)
	if hover_pos.x + 100 > panel_size.x:
		hover_pos.x = dot_local_pos.x - 100
	if hover_pos.y < 40:
		hover_pos.y = dot_local_pos.y + 20
	
	_hover_label.position = hover_pos

func _hide_robot_tooltip() -> void:
	if _hover_label != null:
		_hover_label.visible = false

func _process(_delta: float) -> void:
	if not visible or _player_ref == null or _player_dot == null:
		return
	
	# Get player global position (use global_position to handle any parent transforms)
	var player_pos: Vector2
	if _player_ref.has_method("get_global_position"):
		player_pos = _player_ref.get_global_position()
	else:
		player_pos = _player_ref.global_position if "global_position" in _player_ref else _player_ref.position
	
	# Scale player position to map coordinates
	var pixels_per_tile_x := _map_w / float(WORLD_W)
	var pixels_per_tile_y := _map_h / float(WORLD_H)
	
	var px :float= (player_pos.x / CELL_SIZE) * pixels_per_tile_x
	var py :float= (player_pos.y / CELL_SIZE) * pixels_per_tile_y
	
	# Clamp player position to map bounds
	px = clampf(px, 5, _map_w - 5)
	py = clampf(py, 5, _map_h - 5)
	
	_player_dot.position = _map_offset + Vector2(px - 4 * _font_scale, py - 4 * _font_scale)
	
	# Update player label position
	var player_lbl := find_child("PlayerLabel", false, false)
	if player_lbl != null:
		player_lbl.position = _player_dot.position + Vector2(-8, -15)
	
	# Check if mouse is over any robot dot
	var mouse_pos := get_viewport().get_mouse_position()
	var over_robot := false
	
	for dot_control in _robot_dots:
		if is_instance_valid(dot_control):
			var dot_rect := Rect2(dot_control.global_position, dot_control.size)
			if dot_rect.has_point(mouse_pos):
				var tooltip_data = _robot_tooltips.get(dot_control)
				if tooltip_data != null:
					_show_robot_tooltip(tooltip_data["name"], tooltip_data["dot"])
					over_robot = true
					break
	
	if not over_robot:
		_hide_robot_tooltip()
