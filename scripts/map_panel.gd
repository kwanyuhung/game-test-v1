class_name MapPanel
extends CanvasLayer

const CELL_SIZE := 16
const WORLD_W := 96
const WORLD_H := 52

# Map display scale (larger than minimap)
const MAP_SCALE := 6.0
# MAP_W and MAP_H are now computed dynamically based on screen size

var _player_ref = null
var _floor_idx := 0
var _items: Array = []  # {(x,y,label,color)}
var _item_labels: Array = []
var _player_dot: ColorRect = null
var _bg_panel: Panel = null
var _title_label: Label = null
var _map_w: float = 256.0
var _map_h: float = 139.0
var _map_offset: Vector2 = Vector2(20, 40)
var _font_scale: float = 1.0

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
	_map_w = scr_w * 0.45
	_map_h = scr_h * 0.65
	_map_offset = Vector2(20 * _font_scale, 40 * _font_scale)
	
	# Background panel
	if _bg_panel == null:
		_bg_panel = Panel.new()
		_bg_panel.set_anchors_preset(Control.PRESET_CENTER)
		_bg_panel.custom_minimum_size = Vector2(_map_w + 80 * _font_scale, _map_h + 80 * _font_scale)
		_bg_panel.position = -_bg_panel.custom_minimum_size / 2
		_bg_panel.z_index = 1000
		
		# Style
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.10, 0.15, 0.95)
		style.border_color = Color(0.30, 0.30, 0.40)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.set_border_width_all(2)
		style.set_content_margin_all(10)
		_bg_panel.add_theme_stylebox_override("panel", style)
		
		add_child(_bg_panel)
		
		# Title
		_title_label = Label.new()
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.position = Vector2(0, 5 * _font_scale)
		_title_label.size = Vector2(_bg_panel.custom_minimum_size.x, 30 * _font_scale)
		_title_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.95))
		_title_label.add_theme_font_size_override("font_size", int(16 * _font_scale))
		_bg_panel.add_child(_title_label)

func _update_title() -> void:
	if _title_label != null:
		var floor_name := "Ground Floor"
		if _floor_idx > 0:
			floor_name = "Floor %d" % _floor_idx
		_title_label.text = "📍 %s Map (Press M to close)" % floor_name

func _clear_items() -> void:
	for item in _items:
		item.queue_free()
	_items.clear()
	for lbl in _item_labels:
		lbl.queue_free()
	_item_labels.clear()

func _build_items() -> void:
	_clear_items()
	
	# Get floor items
	var floor_data = FLOOR_ITEMS.get(_floor_idx, {})
	
	# Draw map background (floor area)
	var map_bg := ColorRect.new()
	map_bg.position = _map_offset
	map_bg.size = Vector2(_map_w, _map_h)
	map_bg.color = Color(0.15, 0.15, 0.20, 0.80)
	add_child(map_bg)
	_items.append(map_bg)
	
	# Grid lines for map
	for i in range(6):
		var grid_h := ColorRect.new()
		grid_h.position = _map_offset + Vector2(0, i * (_map_h / 5))
		grid_h.size = Vector2(_map_w, 1)
		grid_h.color = Color(0.25, 0.25, 0.30, 0.50)
		add_child(grid_h)
		_items.append(grid_h)
		
		var grid_v := ColorRect.new()
		grid_v.position = _map_offset + Vector2(i * (_map_w / 5), 0)
		grid_v.size = Vector2(1, _map_h)
		grid_v.color = Color(0.25, 0.25, 0.30, 0.50)
		add_child(grid_v)
		_items.append(grid_v)
	
	# Draw floor items
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
		
		# Item marker (scaled with font_scale)
		var marker := ColorRect.new()
		marker.position = Vector2(map_x - 4 * _font_scale, map_y - 4 * _font_scale)
		marker.size = Vector2(8 * _font_scale, 8 * _font_scale)
		marker.color = color
		marker.z_index = 1001
		add_child(marker)
		_items.append(marker)
		
		# Label
		var lbl := Label.new()
		lbl.text = label
		lbl.position = Vector2(map_x - 20 * _font_scale, map_y + 6 * _font_scale)
		lbl.size = Vector2(50 * _font_scale, 15 * _font_scale)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))
		lbl.add_theme_font_size_override("font_size", int(10 * _font_scale))
		lbl.z_index = 1001
		add_child(lbl)
		_items.append(lbl)
		_item_labels.append(lbl)
	
	# Player dot
	_player_dot = ColorRect.new()
	_player_dot.name = "MapPlayerDot"
	_player_dot.size = Vector2(6 * _font_scale, 6 * _font_scale)
	_player_dot.color = Color(0.95, 0.85, 0.30)  # Yellow
	_player_dot.z_index = 1002
	add_child(_player_dot)
	_items.append(_player_dot)

func _process(_delta: float) -> void:
	if not visible or _player_ref == null or _player_dot == null:
		return
	
	# Scale player position to map coordinates
	var pixels_per_tile_x := _map_w / float(WORLD_W)
	var pixels_per_tile_y := _map_h / float(WORLD_H)
	
	var px :float= (_player_ref.position.x / CELL_SIZE) * pixels_per_tile_x
	var py :float= (_player_ref.position.y / CELL_SIZE) * pixels_per_tile_y
	
	_player_dot.position = _map_offset + Vector2(px - 3 * _font_scale, py - 3 * _font_scale)
