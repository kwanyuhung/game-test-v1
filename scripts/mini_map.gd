# mini_map.gd
# Simple mini-map overlay — shows floor outline and player dot.
# Renders to a small canvas in the corner of the screen.
extends CanvasLayer

const CELL_SIZE := 16
const WORLD_W := 96
const WORLD_H := 52

var _player_ref = null
var _floor_sections: Array = []
var _dots: Array = []  # {(x,y,w,h,color)}
var _floor_idx := 0

func _ready() -> void:
	visible = false

func set_player(player) -> void:
	_player_ref = player

func set_floor(idx: int) -> void:
	_floor_idx = idx
	_build_dots()

func show_map() -> void:
	visible = true

func hide_map() -> void:
	visible = false

func _build_dots() -> void:
	# Clear old dot children
	for d in _dots:
		d.queue_free()
	_dots.clear()
	
	# Section dots — colored rectangles based on StoreData sections for this floor
	# Approximate section positions per floor
	var section_positions := _get_section_positions_for_floor(_floor_idx)
	for entry in section_positions:
		var dot := ColorRect.new()
		dot.position = entry["pos"]   # Vector2 in mini-map pixel coords
		dot.size = entry["size"]       # Vector2
		dot.color = entry["color"]
		dot.z_index = 10
		add_child(dot)
		_dots.append(dot)
	
	# Player dot (will be updated in _process)
	var pdot := ColorRect.new()
	pdot.name = "PlayerDot"
	pdot.size = Vector2(3, 3)
	pdot.color = Color(0.95, 0.85, 0.30)  # bright yellow
	pdot.z_index = 20
	add_child(pdot)
	_dots.append(pdot)

func _get_section_positions_for_floor(floor_idx: int) -> Array:
	# Returns array of {pos, size, color} in mini-map coordinates
	# Map size: 80×44 pixels at top-right of screen (x=236, y=2)
	var sections := []
	match floor_idx:
		0:  # Ground floor
			sections = [
				{"pos": Vector2(2, 2), "size": Vector2(14, 6), "color": Color(0.30, 0.40, 0.60)},  # parking
				{"pos": Vector2(2, 10), "size": Vector2(14, 14), "color": Color(0.55, 0.45, 0.30)},  # food stalls
				{"pos": Vector2(18, 10), "size": Vector2(10, 8), "color": Color(0.70, 0.60, 0.40)},  # lobby
				{"pos": Vector2(2, 26), "size": Vector2(10, 8), "color": Color(0.60, 0.78, 0.95)},   # elevator area
				{"pos": Vector2(14, 26), "size": Vector2(10, 8), "color": Color(0.55, 0.45, 0.60)},   # stairs area
			]
		1, 2, 3, 4, 5, 6, 7, 8:  # Retail floors
			sections = [
				{"pos": Vector2(2, 2), "size": Vector2(18, 8), "color": Color(0.60, 0.78, 0.95)},   # upper sections
				{"pos": Vector2(2, 12), "size": Vector2(18, 8), "color": Color(0.60, 0.82, 0.50)},   # middle
				{"pos": Vector2(22, 2), "size": Vector2(18, 8), "color": Color(0.82, 0.62, 0.38)},   # right upper
				{"pos": Vector2(22, 12), "size": Vector2(18, 8), "color": Color(0.72, 0.65, 0.55)},  # right lower
				{"pos": Vector2(2, 22), "size": Vector2(10, 8), "color": Color(0.55, 0.45, 0.60)},   # elevator
			]
		9:  # Staff / rooftop
			sections = [
				{"pos": Vector2(2, 2), "size": Vector2(20, 16), "color": Color(0.40, 0.40, 0.45)},
				{"pos": Vector2(24, 8), "size": Vector2(12, 10), "color": Color(0.60, 0.70, 0.50)},
			]
		_:
			sections = [
				{"pos": Vector2(2, 2), "size": Vector2(30, 20), "color": Color(0.40, 0.40, 0.45)},
			]
	return sections

func _process(_delta: float) -> void:
	if not visible or _player_ref == null:
		return
	var pdot = get_node_or_null("PlayerDot")
	if pdot == null:
		return
	# Scale player position to mini-map coordinates
	# Map area: 80×44 px representing 96×52 tiles
	var px := (_player_ref.position.x / (WORLD_W * CELL_SIZE)) * 80.0
	var py := (_player_ref.position.y / (WORLD_H * CELL_SIZE)) * 44.0
	pdot.position = Vector2(2.0 + px, 2.0 + py)
