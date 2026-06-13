# map_edit_visualizer.gd
# Visualizes the editable map area while Map Edit Mode is open.
# Renders a bright border outlining the current floor's width × height
# (in pixels) plus a tile grid so the editor can see what they are editing.
class_name MapEditVisualizer
extends Node2D

const FloorConfigScript = preload("res://scripts/world/floor_config.gd")
const FloorManagerScript = preload("res://scripts/world/floor_manager.gd")

var _main: Node2D = null
var _border: Line2D = null
var _grid: Line2D = null
var _label: Label = null
var _current_floor_idx: int = -1

func setup(main: Node2D) -> void:
	_main = main
	_border = Line2D.new()
	_border.default_color = Color(0.95, 0.85, 0.30, 0.95)
	_border.width = 3.0
	_border.z_index = 1500
	_border.visible = false
	_main.add_child(_border)

	_grid = Line2D.new()
	_grid.default_color = Color(0.95, 0.85, 0.30, 0.18)
	_grid.width = 1.0
	_grid.z_index = 1499
	_grid.visible = false
	_main.add_child(_grid)

	_label = Label.new()
	_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.80))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_font_size_override("font_size", 14)
	_label.z_index = 1501
	_label.visible = false
	_main.add_child(_label)

func show_for_floor(floor_idx: int, width_tiles: int, height_tiles: int) -> void:
	if _border == null or _grid == null or _label == null:
		return
	_current_floor_idx = floor_idx
	var floor_w: float = width_tiles * FloorConfigScript.CELL_SIZE
	var floor_h: float = height_tiles * FloorConfigScript.CELL_SIZE
	var floor_y: float = 0.0
	if _main.has_node("FloorManager"):
		floor_y = FloorManagerScript.get_floor_y(floor_idx)
	_position_border(floor_w, floor_h, Vector2(0, floor_y))
	_position_grid(width_tiles, height_tiles, Vector2(0, floor_y))
	_label.text = "Floor %d — %d × %d tiles (%d × %d px)" % [floor_idx, width_tiles, height_tiles, int(floor_w), int(floor_h)]
	_label.position = Vector2(8, floor_y - 24)
	_label.visible = true
	_border.visible = true
	_grid.visible = true

func hide_border() -> void:
	if _border != null:
		_border.visible = false
	if _grid != null:
		_grid.visible = false
	if _label != null:
		_label.visible = false
	_current_floor_idx = -1

func _position_border(floor_w: float, floor_h: float, offset: Vector2) -> void:
	_border.clear_points()
	_border.add_point(offset + Vector2(0, 0))
	_border.add_point(offset + Vector2(floor_w, 0))
	_border.add_point(offset + Vector2(floor_w, floor_h))
	_border.add_point(offset + Vector2(0, floor_h))
	_border.add_point(offset + Vector2(0, 0))

func _position_grid(width_tiles: int, height_tiles: int, offset: Vector2) -> void:
	_grid.clear_points()
	var cell: float = FloorConfigScript.CELL_SIZE
	# Cap density so a 256-tile wide floor does not generate thousands of lines.
	var step: int = 1
	if width_tiles > 96:
		step = 4
	elif width_tiles > 48:
		step = 2
	for x in range(0, width_tiles + 1, step):
		var px: float = offset.x + x * cell
		_grid.add_point(Vector2(px, offset.y))
		_grid.add_point(Vector2(px, offset.y + height_tiles * cell))
	for y in range(0, height_tiles + 1, step):
		var py: float = offset.y + y * cell
		_grid.add_point(Vector2(offset.x, py))
		_grid.add_point(Vector2(offset.x + width_tiles * cell, py))