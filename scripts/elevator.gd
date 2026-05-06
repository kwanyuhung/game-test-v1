# elevator.gd
# Elevator car — animates between floors, shows floor selector UI.
# Spawned as a child of the world root.
class_name Elevator
extends Node2D

const Floors = preload("res://scripts/floors.gd")
const CELL_SIZE := 16

# Elevator shaft anchor positions in world pixels
# x = same for all floors, y per floor
const SHAFT_X := 80 * CELL_SIZE
const FLOOR_Y := {
	0: 32 * CELL_SIZE,   # Ground
	1: 22 * CELL_SIZE,   # Floor 1
	2: 12 * CELL_SIZE,   # Floor 2
	3:  2 * CELL_SIZE,   # Floor 3
	4: -8 * CELL_SIZE,   # Floor 4
	5: -18 * CELL_SIZE,  # Floor 5
	6: -28 * CELL_SIZE,  # Floor 6
	7: -38 * CELL_SIZE,  # Floor 7
	8: -48 * CELL_SIZE,  # Floor 8
	9: -58 * CELL_SIZE,  # Floor 9
	10: -68 * CELL_SIZE, # Floor 10 (rooftop)
}

const CAR_W := 14 * CELL_SIZE
const CAR_H := 10 * CELL_SIZE
const DOOR_W := 5 * CELL_SIZE

signal floor_reached(floor_idx: int)
signal travel_finished

var _car: ColorRect
var _door_left: ColorRect
var _door_right: ColorRect
var _floor_label: Label
var _target_floor: int = 0
var _current_floor: int = 0
var _is_traveling: bool = false
var _travel_progress: float = 0.0
var _travel_from_y: float = 0.0
var _travel_to_y: float = 0.0
var _travel_duration: float = 1.8  # seconds for full floor jump
var _door_open: bool = true
var _door_t: float = 0.0
var _panel: Control = null
var _player_ref = null
var _nearby: bool = false

func _ready() -> void:
	_current_floor = 0
	_target_floor = 0

	# Shaft track (vertical line behind car)
	var shaft := ColorRect.new()
	shaft.position = Vector2(SHAFT_X - 1, 0)
	shaft.size = Vector2(2, 800)
	shaft.color = Color(0.28, 0.25, 0.22)
	add_child(shaft)

	# Car body
	_car = ColorRect.new()
	_car.size = Vector2(CAR_W, CAR_H)
	_car.color = Color(0.48, 0.44, 0.40)
	add_child(_car)

	# Car inner floor
	var inner := ColorRect.new()
	inner.position = Vector2(2, 2)
	inner.size = Vector2(CAR_W - 4, CAR_H - 4)
	inner.color = Color(0.60, 0.56, 0.52)
	_car.add_child(inner)

	# Ceiling light strip
	var light_strip := ColorRect.new()
	light_strip.position = Vector2(2, 2)
	light_strip.size = Vector2(CAR_W - 4, 3)
	light_strip.color = Color(0.95, 0.92, 0.80)
	_car.add_child(light_strip)

	# Doors
	_door_left = ColorRect.new()
	_door_left.position = Vector2(2, 2)
	_door_left.size = Vector2(DOOR_W, CAR_H - 4)
	_door_left.color = Color(0.55, 0.52, 0.50)
	_car.add_child(_door_left)

	_door_right = ColorRect.new()
	_door_right.position = Vector2(CAR_W - DOOR_W - 2, 2)
	_door_right.size = Vector2(DOOR_W, CAR_H - 4)
	_door_right.color = Color(0.55, 0.52, 0.50)
	_car.add_child(_door_right)

	# Floor indicator on car
	_floor_label = Label.new()
	_floor_label.text = "G"
	_floor_label.position = Vector2(CAR_W * 0.5 - 8, CAR_H * 0.5 - 8)
	_floor_label.add_theme_color_override("font_color", Color(0.20, 0.95, 0.50))
	_floor_label.add_theme_font_size_override("font_size", 12)
	_car.add_child(_floor_label)

	_position_car_at_floor(_current_floor)
	_Update_ambient_for_floor(_current_floor)

# Position car at a given floor (instant, no animation)
func _position_car_at_floor(idx: int) -> void:
	_car.position = Vector2(SHAFT_X, FLOOR_Y[idx])
	_floor_label.text = Floors.floor_at(idx).label

func _process(delta: float) -> void:
	# Door animation
	if _door_open and _door_t < 1.0:
		_door_t = minf(_door_t + delta * 4.0, 1.0)
	elif !_door_open and _door_t > 0.0:
		_door_t = maxf(_door_t - delta * 4.0, 0.0)
	_update_door_visuals()

	# Travel animation
	if _is_traveling:
		_travel_progress += delta / _travel_duration
		if _travel_progress >= 1.0:
			_travel_progress = 1.0
			_is_traveling = false
			_current_floor = _target_floor
			_car.position.y = _travel_to_y
			_floor_label.text = Floors.floor_at(_current_floor).label
			_Update_ambient_for_floor(_current_floor)
			floor_reached.emit(_current_floor)
			_door_open = false
			travel_finished.emit()
		else:
			# Ease in-out
			var t := _ease(_travel_progress, 0.5)
			_car.position.y = lerpf(_travel_from_y, _travel_to_y, t)

func _ease(x: float, k: float) -> float:
	# Simple ease-in-out
	if x < 0.5:
		return pow(2.0 * x, k) * 0.5
	else:
		return 1.0 - pow(2.0 * (1.0 - x), k) * 0.5

func _update_door_visuals() -> void:
	var open_offset := _door_t * (DOOR_W * 0.6)
	_door_left.position.x = 2 + open_offset
	_door_right.position.x = CAR_W - DOOR_W - 2 - open_offset

func _Update_ambient_for_floor(idx: int) -> void:
	# Tell the main world to shift ambient
	var main = get_parent()
	if main and main.has_method("set_ambient_floor"):
		main.set_ambient_floor(idx)

# ─── Public API ────────────────────────────────────────────────

func get_car_world_y() -> float:
	return _car.position.y

func is_nearby(world_pos: Vector2) -> bool:
	var car_center := Vector2(SHAFT_X + CAR_W * 0.5, _car.position.y + CAR_H * 0.5)
	return world_pos.distance_to(car_center) < CELL_SIZE * 5.0

func is_traveling() -> bool:
	return _is_traveling

func get_current_floor() -> int:
	return _current_floor

func open_panel(world_pos: Vector2, player) -> void:
	if _is_traveling:
		return
	_player_ref = player
	_show_floor_panel()

func is_floor_staff_only(floor_idx: int) -> bool:
	# Floor 9 is the Staff Room
	return floor_idx == 9

func close_panel() -> void:
	if _panel != null:
		_panel.queue_free()
		_panel = null
	_player_ref = null

func call_to_floor(idx: int) -> void:
	if idx == _current_floor or _is_traveling:
		return
	# Check staff-only floor access
	var is_blocked := false
	if is_floor_staff_only(idx):
		if _player_ref != null and _player_ref.has_method("is_in_staff_mode"):
			if not _player_ref.is_in_staff_mode():
				is_blocked = true
		else:
			is_blocked = true
	if is_blocked:
		# Show staff-only message (emit signal to main)
		var main = get_parent()
		if main and main.has_method("on_elevator_staff_blocked"):
			main.on_elevator_staff_blocked(idx)
		return
	_target_floor = idx
	_travel_from_y = FLOOR_Y[_current_floor]
	_travel_to_y = FLOOR_Y[_target_floor]
	_travel_progress = 0.0
	_is_traveling = true
	_door_open = false
	# Calculate travel time based on distance
	var floors_diff := absf(_target_floor - _current_floor)
	_travel_duration = 0.6 + floors_diff * 0.8
	close_panel()

# ─── Floor Selector Panel ──────────────────────────────────────

func _show_floor_panel() -> void:
	close_panel()

	var cam := get_viewport().get_camera_2d()
	var cam_offset := Vector2(160.0, 90.0)  # center of game view
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(50.0, 30.0)
	panel.size = Vector2(220.0, 120.0)
	panel.gui_input.connect(_on_panel_input)
	add_child(panel)
	_panel = panel

	# Dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.06, 0.09, 0.92)
	panel.add_child(bg)

	# Header
	var hdr := Label.new()
	hdr.text = "=== ELEVATOR ==="
	hdr.position = Vector2(55.0, 4.0)
	hdr.add_theme_color_override("font_color", Color(0.88, 0.82, 0.60))
	hdr.add_theme_font_size_override("font_size", 9)
	panel.add_child(hdr)

	# Floor buttons — grid 3x4
	var floor_defs := Floors.ALL
	var cols := 3
	var btn_w := 60.0
	var btn_h := 20.0
	var start_x := 14.0
	var start_y := 20.0

	for i in range(floor_defs.size()):
		var fd = floor_defs[i]
		var col := i % cols
		var row := i / cols
		var bx := start_x + col * (btn_w + 6)
		var by := start_y + row * (btn_h + 4)

		var btn := ColorRect.new()
		btn.position = Vector2(bx, by)
		btn.size = Vector2(btn_w, btn_h)
		var is_current := (i == _current_floor)
		var is_staff_only: bool = fd.is_staff_only 
		# Check if player can access (staff mode check)
		var player_is_staff := false
		if _player_ref != null and _player_ref.has_method("is_in_staff_mode"):
			player_is_staff = _player_ref.is_in_staff_mode()
		var is_blocked := is_staff_only and not player_is_staff
		btn.color = Color(0.22, 0.20, 0.28) if !is_current else Color(0.18, 0.40, 0.25)
		if is_blocked:
			btn.color = Color(0.15, 0.12, 0.18)
		panel.add_child(btn)

		var lbl := Label.new()
		lbl.text = "Floor %s" % fd.label
		if is_blocked:
			lbl.text = "Floor %s [LOCKED]" % fd.label
		lbl.position = Vector2(bx + 4, by + 4)
		var lbl_color := Color(0.90, 0.88, 0.80) if !is_current and !is_blocked else Color(0.50, 0.95, 0.60)
		if is_blocked:
			lbl_color = Color(0.45, 0.35, 0.40)
		lbl.add_theme_color_override("font_color", lbl_color)
		lbl.add_theme_font_size_override("font_size", 8)
		panel.add_child(lbl)

		# Store floor idx for button press
		btn.set_meta("floor_idx", i)

		# Input on btn
		var btn_child := btn as Control
		btn_child.gui_input.connect(_on_floor_btn_input)

	# Hint
	var hint := Label.new()
	hint.text = "[E] Board  [1-9,G] Select floor  [ESC] Close"
	hint.position = Vector2(6.0, 106.0)
	hint.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
	hint.add_theme_font_size_override("font_size", 7)
	panel.add_child(hint)

func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE:
			close_panel()
		elif k.keycode == KEY_E:
			# Board the elevator
			close_panel()
			if _player_ref:
				var main = get_parent()
				if main and main.has_method("player_board_elevator"):
					main.player_board_elevator(_player_ref, _current_floor)

func _on_floor_btn_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var btn := event.get_parent() as Control
		if btn != null and btn.has_meta("floor_idx"):
			var idx: int = btn.get_meta("floor_idx")
			if idx != _current_floor and not _is_traveling:
				call_to_floor(idx)
			elif idx == _current_floor:
				close_panel()
				if _player_ref:
					var main = get_parent()
					if main and main.has_method("player_board_elevator"):
						main.player_board_elevator(_player_ref, _current_floor)
