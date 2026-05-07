class_name MapPanel
extends CanvasLayer

const CELL_SIZE := 16
const WORLD_W := 96
const WORLD_H := 52

# Map display scale (larger than minimap)
const MAP_SCALE := 6.0
const MAP_W := WORLD_W * CELL_SIZE / MAP_SCALE  # ~256 pixels
const MAP_H := WORLD_H * CELL_SIZE / MAP_SCALE  # ~139 pixels

var _player_ref = null
var _floor_idx := 0
var _items: Array = []  # {(x,y,label,color)}
var _item_labels: Array = []
var _player_dot: ColorRect = null
var _bg_panel: Panel = null
var _title_label: Label = null

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
	1: {  # Floor 1 - Fresh/Produce
		"produce": {"pos": Vector2(20, 15), "label": "Produce", "color": Color(0.40, 0.80, 0.40)},
		"dairy": {"pos": Vector2(50, 15), "label": "Dairy", "color": Color(0.90, 0.90, 0.90)},
		"bakery": {"pos": Vector2(80, 15), "label": "Bakery", "color": Color(0.85, 0.65, 0.40)},
		"elevator": {"pos": Vector2(75, 35), "label": "Elevator", "color": Color(0.60, 0.78, 0.95)},
		"stairs": {"pos": Vector2(85, 35), "label": "Stairs", "color": Color(0.55, 0.45, 0.60)},
	},
	2: {  # Floor 2 - Pantry
		"pantry": {"pos": Vector2(30, 20), "label": "Pantry", "color": Color(0.75, 0.55, 0.35)},
		"snacks": {"pos": Vector2(60, 20), "label": "Snacks", "color": Color(0.90, 0.70, 0.30)},
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
	# Background panel
	if _bg_panel == null:
		_bg_panel = Panel.new()
		_bg_panel.set_anchors_preset(Control.PRESET_CENTER)
		_bg_panel.custom_minimum_size = Vector2(MAP_W + 40, MAP_H + 60)
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
		_title_label.position = Vector2(0, 5)
		_title_label.size = Vector2(_bg_panel.custom_minimum_size.x, 25)
		_title_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.95))
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
	
	# Map container position (relative to panel center)
	var map_offset := Vector2(20, 40)  # Offset from panel edges
	
	# Draw map background (floor area)
	var map_bg := ColorRect.new()
	map_bg.position = map_offset
	map_bg.size = Vector2(MAP_W, MAP_H)
	map_bg.color = Color(0.15, 0.15, 0.20, 0.80)
	add_child(map_bg)
	_items.append(map_bg)
	
	# Grid lines for map
	for i in range(6):
		var grid_h := ColorRect.new()
		grid_h.position = map_offset + Vector2(0, i * (MAP_H / 5))
		grid_h.size = Vector2(MAP_W, 1)
		grid_h.color = Color(0.25, 0.25, 0.30, 0.50)
		add_child(grid_h)
		_items.append(grid_h)
		
		var grid_v := ColorRect.new()
		grid_v.position = map_offset + Vector2(i * (MAP_W / 5), 0)
		grid_v.size = Vector2(1, MAP_H)
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
		# Scale: MAP_W / WORLD_W tiles = pixels per tile
		var pixels_per_tile_x := MAP_W / float(WORLD_W)
		var pixels_per_tile_y := MAP_H / float(WORLD_H)
		
		var map_x := map_offset.x + pos.x * pixels_per_tile_x
		var map_y := map_offset.y + pos.y * pixels_per_tile_y
		
		# Item marker
		var marker := ColorRect.new()
		marker.position = Vector2(map_x - 4, map_y - 4)
		marker.size = Vector2(8, 8)
		marker.color = color
		marker.z_index = 1001
		add_child(marker)
		_items.append(marker)
		
		# Label
		var lbl := Label.new()
		lbl.text = label
		lbl.position = Vector2(map_x - 20, map_y + 6)
		lbl.size = Vector2(50, 15)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.z_index = 1001
		add_child(lbl)
		_items.append(lbl)
		_item_labels.append(lbl)
	
	# Player dot
	_player_dot = ColorRect.new()
	_player_dot.name = "MapPlayerDot"
	_player_dot.size = Vector2(6, 6)
	_player_dot.color = Color(0.95, 0.85, 0.30)  # Yellow
	_player_dot.z_index = 1002
	add_child(_player_dot)
	_items.append(_player_dot)

func _process(_delta: float) -> void:
	if not visible or _player_ref == null or _player_dot == null:
		return
	
	# Map container position
	var map_offset := Vector2(20, 40)
	var pixels_per_tile_x := MAP_W / float(WORLD_W)
	var pixels_per_tile_y := MAP_H / float(WORLD_H)
	
	# Scale player position to map coordinates
	var px :float= (_player_ref.position.x / CELL_SIZE) * pixels_per_tile_x
	var py :float= (_player_ref.position.y / CELL_SIZE) * pixels_per_tile_y
	
	_player_dot.position = map_offset + Vector2(px - 3, py - 3)
