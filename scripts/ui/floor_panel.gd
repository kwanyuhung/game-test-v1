class_name FloorPanel
extends CanvasLayer

# floor_panel.gd
# Clickable floor selector panel - allows users to switch floors by clicking buttons.
# Can be toggled visible/hidden or docked to the HUD.

const FloorConfig = preload("res://scripts/world/floor_config.gd")

signal floor_selected(floor_idx: int)
signal input_blocked(bool)  # Emitted when panel opens/closes to block player input

var _current_floor: int = 0
var _panel: Control = null
var _floor_buttons: Array = []
var _owner: Node = null

func _ready() -> void:
	visible = false

func set_owner_node(owner: Node) -> void:
	_owner = owner

func set_floor(idx: int) -> void:
	_current_floor = idx
	_update_button_states()

func toggle() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()

func show_panel() -> void:
	if _panel == null:
		_create_panel()
	visible = true
	input_blocked.emit(true)

func hide_panel() -> void:
	visible = false
	input_blocked.emit(false)

func _create_panel() -> void:
	if _panel != null:
		_panel.queue_free()
	
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-160.0, -200.0)
	_panel.set_deferred("size", Vector2(320.0, 400.0))
	add_child(_panel)
	
	# Dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08, 0.95)
	_panel.add_child(bg)
	
	# Header
	var hdr := Label.new()
	hdr.text = "=== SELECT FLOOR ==="
	hdr.position = Vector2(80.0, 10.0)
	hdr.add_theme_color_override("font_color", Color(0.88, 0.82, 0.60))
	hdr.add_theme_font_size_override("font_size", 14)
	_panel.add_child(hdr)

	# Close button (X) in top-right corner
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(270.0, 8.0)
	close_btn.size = Vector2(40.0, 24.0)
	close_btn.add_theme_color_override("font_color", Color(0.90, 0.60, 0.60))
	close_btn.add_theme_color_override("bg_color", Color(0.30, 0.15, 0.15))
	close_btn.connect("pressed", hide_panel)
	_panel.add_child(close_btn)
	
	# Floor buttons - 4 columns x 4 rows for up to 16 floors
	var floor_count := FloorConfig.floor_count()
	var cols := 4
	var btn_w := 68.0
	var btn_h := 36.0
	var start_x := 12.0
	var start_y := 45.0
	var gap_x := 6.0
	var gap_y := 8.0
	
	_floor_buttons.clear()
	
	for i in range(floor_count):
		var col := i % cols
		var row := i / cols
		var bx := start_x + col * (btn_w + gap_x)
		var by := start_y + row * (btn_h + gap_y)
		
		var floor_label := "G" if i == 0 else str(i)
		
		# Button background
		var btn := ColorRect.new()
		btn.position = Vector2(bx, by)
		btn.set_deferred("size", Vector2(btn_w, btn_h))
		btn.color = Color(0.22, 0.20, 0.28)
		_panel.add_child(btn)
		
		# Floor label
		var lbl := Label.new()
		lbl.text = "Floor %s" % floor_label
		lbl.position = Vector2(bx + 4, by + 4)
		lbl.add_theme_color_override("font_color", Color(0.90, 0.88, 0.80))
		lbl.add_theme_font_size_override("font_size", 11)
		_panel.add_child(lbl)
		
		# Floor type label
		var type_lbl := Label.new()
		type_lbl.text = _get_floor_type_label(i)
		type_lbl.position = Vector2(bx + 4, by + 20)
		type_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
		type_lbl.add_theme_font_size_override("font_size", 8)
		_panel.add_child(type_lbl)
		
		# Store floor idx for button press
		btn.set_meta("floor_idx", i)
		btn.gui_input.connect(_on_floor_btn_input.bind(btn))
		_floor_buttons.append(btn)
	
	# Close hint at bottom
	var close_hint := Label.new()
	close_hint.text = "Press ESC or click outside to close"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.position = Vector2(30.0, 370.0)
	close_hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	close_hint.add_theme_font_size_override("font_size", 9)
	_panel.add_child(close_hint)
	
	# Connect panel input for clicking outside
	_panel.gui_input.connect(_on_panel_input)

func _get_floor_type_label(floor_idx: int) -> String:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(floor_idx)
	if fd == null:
		return ""
	if fd.is_staff_only:
		return "Staff Only"
	if fd.is_rooftop:
		return "Rooftop"
	return fd.label

func _on_floor_btn_input(event: InputEvent, btn: ColorRect) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx: int = btn.get_meta("floor_idx")
		_hide_panel_and_jump(idx)

func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click is outside all buttons (on the background)
		var click_pos: Vector2 = event.position
		var clicked_button := false
		for btn in _floor_buttons:
			var btn_rect := Rect2(btn.position, btn.size)
			if btn_rect.has_point(click_pos):
				clicked_button = true
				break
		# If not on a button and panel is being used, could close it
		# But let's keep it open for now to allow background clicks to deselect

func _hide_panel_and_jump(idx: int) -> void:
	hide_panel()
	floor_selected.emit(idx)
	if _owner != null and _owner.has_method("_jump_to_floor"):
		_owner._jump_to_floor(idx)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			hide_panel()

func _update_button_states() -> void:
	for btn in _floor_buttons:
		var idx: int = btn.get_meta("floor_idx")
		var is_current := (idx == _current_floor)
		btn.color = Color(0.18, 0.40, 0.25) if is_current else Color(0.22, 0.20, 0.28)
