# map_panel.gd
# Full-screen floor map with NPC/robot markers and hover tooltips
class_name MapPanel
extends CanvasLayer

const FloorConfig = preload("res://scripts/world/floor_config.gd")

const CELL_SIZE := 16
const FLOOR_TILE_SPACING := 10
const FLOOR_Y_OFFSET := FLOOR_TILE_SPACING * CELL_SIZE  # 160 pixels per floor
# Floor 0 base Y = tile 32 = 512 pixels
const FLOOR_0_BASE_Y := 32 * CELL_SIZE  # 512 pixels
# Actual zone height per floor: 40 tiles = 640 pixels
const FLOOR_ZONE_H := 40 * CELL_SIZE  # 640 pixels per floor
# Margin from floor base to topmost zone (30 tiles above base tile 32)
const FLOOR_TOP_MARGIN_TILES := 30
const FLOOR_TOP_MARGIN := FLOOR_TOP_MARGIN_TILES * CELL_SIZE  # 480 pixels

# World dimensions
const WORLD_W_TILES := 128  # tiles
const WORLD_W := WORLD_W_TILES * CELL_SIZE  # 2048 pixels

# Robot marker colors by type
const ROBOT_COLORS := {
	"cleaner": Color(0.20, 0.80, 0.60),
	"guide": Color(0.90, 0.70, 0.30),
	"security": Color(0.90, 0.20, 0.20),
	"shelf": Color(0.30, 0.90, 0.40),
	"delivery": Color(0.60, 0.50, 0.90),
	"humanoid": Color(0.40, 0.80, 0.95),
	"unknown": Color(0.80, 0.80, 0.80),
}

var _player_ref = null
var _main_ref = null
var _floor_idx := 0
var _items: Array = []
var _item_labels: Array = []
var _robot_dots: Array = []
var _robot_tooltips: Dictionary = {}
var _player_dot: ColorRect = null
var _bg_panel: Panel = null
var _title_label: Label = null
var _map_container: Control = null
var _hover_label: Label = null
var _hovered_robot_dot: ColorRect = null

# Map dimensions (calculated dynamically)
var _map_w: float = 0.0
var _map_h: float = 0.0
var _map_offset: Vector2 = Vector2.ZERO
var _font_scale: float = 1.0

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
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var scr_w: float = viewport_rect.size.x
	var scr_h: float = viewport_rect.size.y
	_font_scale = clampf(scr_h / 720.0, 0.6, 1.5)

	# Calculate map dimensions (fills ~50% width, 70% height)
	_map_w = scr_w * 0.50
	_map_h = scr_h * 0.70

	var panel_w: float = _map_w + 160 * _font_scale  # Extra space for legend
	var panel_h: float = _map_h + 80 * _font_scale  # Extra space for title

	# Remove old panel if exists
	if _bg_panel != null:
		_bg_panel.queue_free()
		_bg_panel = null

	# Create background panel
	_bg_panel = Panel.new()
	_bg_panel.set_anchors_preset(Control.PRESET_CENTER)
	_bg_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	_bg_panel.position = -_bg_panel.custom_minimum_size / 2
	_bg_panel.z_index = 1000

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
	_title_label.size = Vector2(panel_w, 30 * _font_scale)
	_title_label.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95))
	_title_label.add_theme_font_size_override("font_size", int(18 * _font_scale))
	_title_label.z_index = 500
	_bg_panel.add_child(_title_label)

	# Calculate map offset (centered, below title)
	_map_offset = Vector2(20 * _font_scale, 50 * _font_scale)

	# Hover tooltip
	_hover_label = Label.new()
	_hover_label.visible = false
	_hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hover_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	_hover_label.add_theme_font_size_override("font_size", int(12 * _font_scale))
	_hover_label.add_theme_stylebox_override("normal", _make_tooltip_style())
	_hover_label.z_index = 600
	_bg_panel.add_child(_hover_label)

	_build_legend()

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
	legend_panel.z_index = 500

	var legend_x: float = _map_offset.x + _map_w + 15 * _font_scale
	var legend_y: float = _map_offset.y
	legend_panel.position = Vector2(legend_x, legend_y)
	legend_panel.custom_minimum_size = Vector2(120 * _font_scale, 150 * _font_scale)

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

	var y_offset := 22.0
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
		y_offset += 18

func _update_title() -> void:
	if _title_label != null:
		var floor_name := "Ground Floor"
		if _floor_idx > 0:
			floor_name = "Floor %d" % _floor_idx
		_title_label.text = "%s Map  (Press M to close)" % floor_name

func _clear_items() -> void:
	for item in _items:
		if is_instance_valid(item):
			item.queue_free()
	_items.clear()
	for lbl in _item_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_item_labels.clear()
	_clear_robot_dots()

func _clear_robot_dots() -> void:
	for dot in _robot_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	_robot_dots.clear()
	_robot_tooltips.clear()

func _get_floor_base_y(floor_idx: int) -> float:
	return FLOOR_0_BASE_Y - (floor_idx * FLOOR_Y_OFFSET)

func _get_floor_zone_items(floor_idx: int) -> Dictionary:
	# Load floor items (elevator, stairs, section zones) from FloorConfig
	# Returns dict: zone_id -> {pos: Vector2(tile_x, tile_y), label, color}
	var items := {}
	var floor_def = FloorConfig.get_floor(floor_idx)
	if floor_def == null:
		return items

	for zone in floor_def.zones:
		var ztype: String = zone.get("type", "")
		var zx: int = zone.get("x", 0)
		var zy: int = zone.get("y", 0)
		var zw: int = zone.get("w", 0)
		var zh: int = zone.get("h", 0)
		var zmeta: Dictionary = zone.get("meta", {})

		# Elevator: elevator_shaft zone
		if ztype == "elevator_shaft":
			var center_x := zx + zw / 2
			var center_y := zy + zh / 2
			items["elevator"] = {
				"pos": Vector2(center_x, center_y),
				"label": zmeta.get("name", "Elevator"),
				"color": Color(0.60, 0.78, 0.95),
			}
		# Stairs: stairs zone
		elif ztype == "stairs":
			var center_x := zx + zw / 2
			var center_y := zy + zh / 2
			items["stairs"] = {
				"pos": Vector2(center_x, center_y),
				"label": zmeta.get("name", "Stairs"),
				"color": Color(0.55, 0.45, 0.60),
			}
		# Other named zones (food_stall, checkout, etc.) from meta
		elif zmeta.get("name", "") != "":
			var zone_name: String = zmeta.get("name", "")
			var center_x := zx + zw / 2
			var center_y := zy + zh / 2
			# Assign colors based on zone name/content
			var zone_color := Color(0.70, 0.65, 0.55)
			if "food" in zone_name.to_lower() or "cafe" in zone_name.to_lower():
				zone_color = Color(0.85, 0.55, 0.30)
			elif "check" in zone_name.to_lower():
				zone_color = Color(0.30, 0.80, 0.40)
			elif "dock" in zone_name.to_lower() or "warehouse" in zone_name.to_lower():
				zone_color = Color(0.50, 0.60, 0.40)
			items[zone_name] = {
				"pos": Vector2(center_x, center_y),
				"label": zone_name,
				"color": zone_color,
			}

	return items

func _get_robots_for_current_floor() -> Array:
	if _main_ref == null:
		return []

	var robots: Array = _main_ref.get("_robots")
	if robots == null:
		return []

	var floor_base_y: float = _get_floor_base_y(_floor_idx)
	var floor_robots: Array = []

	for robot in robots:
		if not is_instance_valid(robot):
			continue
		var robot_pos: Vector2 = robot.position if "position" in robot else Vector2.ZERO
		# Check if robot is on this floor
		if robot_pos.y >= floor_base_y and robot_pos.y < floor_base_y + FLOOR_ZONE_H:
			floor_robots.append(robot)

	return floor_robots

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

	if robot.has_method("get_actor"):
		var actor = robot.get_actor()
		if actor != null and actor.robot_role != null:
			match actor.robot_role:
				1: return ROBOT_COLORS["cleaner"]
				2: return ROBOT_COLORS["delivery"]
				3: return ROBOT_COLORS["security"]
				4: return ROBOT_COLORS["guide"]
				5: return ROBOT_COLORS["shelf"]

	return ROBOT_COLORS["unknown"]

func _get_robot_display_name(robot) -> String:
	if robot == null:
		return "Unknown"

	if robot.has_method("get_actor"):
		var actor = robot.get_actor()
		if actor != null and actor.display_name != null:
			return str(actor.display_name)

	var robot_name: String = str(robot.name) if robot.name != null else "Robot"
	var name := robot_name.replace("Robot_", "").replace("Robot", "").replace("_", " ")
	if name.is_empty():
		name = "Robot"
	return name.capitalize()

func _world_to_map(world_pos: Vector2, floor_idx: int) -> Vector2:
	# Convert world position to map position
	# X: 0 to WORLD_W (2048px) -> proportional to _map_w
	# Y: relative to floor visual area (40-tile zone height = 640px)
	# World Y increases downward; map Y increases upward (top of floor = top of map)

	var floor_base_y: float = _get_floor_base_y(floor_idx)
	# Floor visual spans 40 tiles: top at floor_base_y - 30*16, bottom at floor_base_y + 10*16
	var floor_top_world_y: float = floor_base_y - FLOOR_TOP_MARGIN  # 32 for floor 0
	var floor_bottom_world_y: float = floor_base_y + FLOOR_ZONE_H  # 1152 for floor 0
	var total_span: float = floor_bottom_world_y - floor_top_world_y  # 1120 for floor 0

	# Clamp world Y to floor bounds
	var clamped_y: float = clampf(world_pos.y, floor_top_world_y, floor_bottom_world_y)

	# Map X: proportional across full map width
	var map_x: float = _map_offset.x + (world_pos.x / float(WORLD_W)) * _map_w
	# Map Y: proportional within floor visual area (inverted: top of floor -> top of map)
	var relative_y: float = (clamped_y - floor_top_world_y) / float(total_span)
	var map_y: float = _map_offset.y + (1.0 - relative_y) * _map_h

	return Vector2(map_x, map_y)

func _build_items() -> void:
	if _bg_panel == null:
		_build_panel()
	_clear_items()

	var floor_data: Dictionary = _get_floor_zone_items(_floor_idx)

	# Map background
	var map_bg := ColorRect.new()
	map_bg.name = "MapBackground"
	map_bg.position = _map_offset
	map_bg.size = Vector2(_map_w, _map_h)
	map_bg.color = Color(0.12, 0.12, 0.18, 0.85)
	map_bg.z_index = 100
	_bg_panel.add_child(map_bg)
	_items.append(map_bg)

	# Map border
	var map_border := ColorRect.new()
	map_border.name = "MapBorder"
	map_border.position = _map_offset - Vector2(2, 2)
	map_border.size = Vector2(_map_w + 4, _map_h + 4)
	map_border.color = Color(0.30, 0.40, 0.55, 0.60)
	map_border.z_index = 99
	_bg_panel.add_child(map_border)
	_items.append(map_border)

	# Grid lines
	var grid_cols := 8
	var grid_rows := 4
	for i in range(grid_cols + 1):
		var grid_v := ColorRect.new()
		grid_v.position = _map_offset + Vector2(i * _map_w / grid_cols, 0)
		grid_v.size = Vector2(1, _map_h)
		grid_v.color = Color(0.20, 0.22, 0.28, 0.30)
		grid_v.z_index = 101
		_bg_panel.add_child(grid_v)
		_items.append(grid_v)

	for i in range(grid_rows + 1):
		var grid_h := ColorRect.new()
		grid_h.position = _map_offset + Vector2(0, i * _map_h / grid_rows)
		grid_h.size = Vector2(_map_w, 1)
		grid_h.color = Color(0.20, 0.22, 0.28, 0.30)
		grid_h.z_index = 101
		_bg_panel.add_child(grid_h)
		_items.append(grid_h)

	# Draw floor items
	for key in floor_data.keys():
		var item: Dictionary = floor_data[key]
		var pos: Vector2 = item["pos"]
		var label: String = item["label"]
		var color: Color = item["color"]

		# Convert tile position to world then to map
		var world_pos := Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)
		var map_pos: Vector2 = _world_to_map(world_pos, _floor_idx)

		# Scale marker size based on font_scale
		var marker_size := 10 * _font_scale

		# Shop marker
		var marker := ColorRect.new()
		marker.name = "Shop_" + key
		marker.position = map_pos - Vector2(marker_size / 2, marker_size / 2)
		marker.size = Vector2(marker_size, marker_size)
		marker.color = color
		marker.z_index = 102
		_bg_panel.add_child(marker)
		_items.append(marker)

		# Shop label
		var lbl := Label.new()
		lbl.text = label
		var label_width: float = maxf(40.0, float(label.length()) * 5.5 * _font_scale)
		lbl.position = Vector2(map_pos.x - label_width / 2.0, map_pos.y - 18.0 * _font_scale)
		lbl.size = Vector2(label_width, 14.0 * _font_scale)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.82, 0.88))
		lbl.add_theme_font_size_override("font_size", int(9.0 * _font_scale))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.z_index = 102
		_bg_panel.add_child(lbl)
		_items.append(lbl)
		_item_labels.append(lbl)

	# Draw robots
	_draw_robots_on_map()

	# Player dot
	_player_dot = ColorRect.new()
	_player_dot.name = "MapPlayerDot"
	_player_dot.size = Vector2(8 * _font_scale, 8 * _font_scale)
	_player_dot.color = Color(0.95, 0.85, 0.30)
	_player_dot.z_index = 200
	_bg_panel.add_child(_player_dot)
	_items.append(_player_dot)

	# Player label
	var player_lbl := Label.new()
	player_lbl.name = "PlayerLabel"
	player_lbl.text = "YOU"
	player_lbl.size = Vector2(30, 12)
	player_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.30))
	player_lbl.add_theme_font_size_override("font_size", int(8 * _font_scale))
	player_lbl.z_index = 201
	_bg_panel.add_child(player_lbl)
	_items.append(player_lbl)
	_item_labels.append(player_lbl)

func _draw_robots_on_map() -> void:
	var robots: Array = _get_robots_for_current_floor()

	for robot in robots:
		if not is_instance_valid(robot):
			continue

		var robot_pos: Vector2 = robot.position if "position" in robot else Vector2.ZERO
		var map_pos: Vector2 = _world_to_map(robot_pos, _floor_idx)

		var robot_color: Color = _get_robot_color(robot)
		var robot_name: String = _get_robot_display_name(robot)

		var marker_size := 10 * _font_scale

		# Robot dot
		var dot := ColorRect.new()
		dot.name = "RobotDot_" + robot.name
		dot.position = map_pos - Vector2(marker_size / 2, marker_size / 2)
		dot.size = Vector2(marker_size, marker_size)
		dot.color = robot_color
		dot.z_index = 150

		var dot_control := Control.new()
		dot_control.name = "RobotDotControl_" + robot.name
		dot_control.position = dot.position
		dot_control.size = dot.size
		dot_control.z_index = 151
		dot_control.mouse_filter = Control.MOUSE_FILTER_PASS
		dot_control.gui_input.connect(_on_robot_dot_input.bind(robot, robot_name, dot))
		_bg_panel.add_child(dot_control)
		_items.append(dot_control)

		_robot_dots.append(dot_control)
		_robot_tooltips[dot_control] = {"robot": robot, "name": robot_name, "dot": dot}

		dot.position = Vector2.ZERO
		dot_control.add_child(dot)

		# Pulsing ring effect
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
			pass

func _show_robot_tooltip(robot_name: String, dot: ColorRect) -> void:
	if _hover_label == null:
		return

	_hover_label.text = "  %s  " % robot_name
	_hover_label.visible = true

	var dot_control: Control = dot.get_parent()
	if dot_control == null:
		return

	var dot_local_pos: Vector2 = dot_control.position + dot_control.size / 2.0
	var hover_pos: Vector2 = dot_local_pos + Vector2(15 * _font_scale, -10 * _font_scale)

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

	var player_pos: Vector2
	if _player_ref.has_method("get_global_position"):
		player_pos = _player_ref.get_global_position()
	else:
		player_pos = _player_ref.global_position if "global_position" in _player_ref else _player_ref.position

	var map_pos: Vector2 = _world_to_map(player_pos, _floor_idx)

	# Clamp to map bounds
	map_pos.x = clampf(map_pos.x, _map_offset.x + 5, _map_offset.x + _map_w - 5)
	map_pos.y = clampf(map_pos.y, _map_offset.y + 5, _map_offset.y + _map_h - 5)

	_player_dot.position = map_pos - Vector2(4 * _font_scale, 4 * _font_scale)

	var player_lbl: Label = find_child("PlayerLabel", false, false)
	if player_lbl != null:
		player_lbl.position = _player_dot.position + Vector2(-10 * _font_scale, -14 * _font_scale)

	# Check mouse hover on robot dots
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var over_robot := false

	for dot_control in _robot_dots:
		if is_instance_valid(dot_control):
			var dot_rect := Rect2(dot_control.global_position, dot_control.size)
			if dot_rect.has_point(mouse_pos):
				var tooltip_data: Dictionary = _robot_tooltips.get(dot_control)
				if tooltip_data != null:
					_show_robot_tooltip(tooltip_data["name"], tooltip_data["dot"])
					over_robot = true
					break

	if not over_robot:
		_hide_robot_tooltip()