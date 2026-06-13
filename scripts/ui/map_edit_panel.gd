# map_edit_panel.gd
# Dev-only side panel for editing the current floor's width / height / ambient color.
# Opened by MapEditMode (U key, DEV_MODE only).
# Save persists to user://floor_layout_override.json via FloorOverride; Cancel discards.
class_name MapEditPanel
extends CanvasLayer

signal saved(width_tiles: int, height_tiles: int, ambient_color: Color)
signal cancelled
signal reset_requested
signal input_blocked(blocked: bool)

const PANEL_W := 360.0
const PAD := 16.0
const ROW_H := 56.0
const BTN_H := 44.0

var _is_open := false
var _floor_idx := 0
var _orig_width := 0
var _orig_height := 0
var _orig_color := Color(0, 0, 0)
var _row_nodes: Array = []
var _width_slider: HSlider = null
var _height_slider: HSlider = null
var _width_label: Label = null
var _height_label: Label = null
var _color_picker: ColorPickerButton = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func open_for_floor(floor_idx: int, width_tiles: int, height_tiles: int, ambient: Color) -> void:
	_floor_idx = floor_idx
	_orig_width = width_tiles
	_orig_height = height_tiles
	_orig_color = ambient
	_is_open = true
	visible = true
	input_blocked.emit(true)
	_build()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	_clear()
	input_blocked.emit(false)

func is_open() -> bool:
	return _is_open

func _build() -> void:
	_clear()
	var viewport_rect := get_viewport().get_visible_rect()
	var vp_h := viewport_rect.size.y
	var panel_h: float = PAD * 2 + ROW_H * 3 + BTN_H * 2 + BTN_H * 0.7 + 24
	var panel_x: float = viewport_rect.size.x - PANEL_W - 12
	var panel_y: float = (vp_h - panel_h) * 0.5

	# Dim background covers the whole screen; click outside the panel to cancel.
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)
	_row_nodes.append(dim)

	# Panel body
	var panel := ColorRect.new()
	panel.position = Vector2(panel_x, panel_y)
	panel.size = Vector2(PANEL_W, panel_h)
	panel.color = Color(0.08, 0.08, 0.12, 0.98)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	_row_nodes.append(panel)

	# Border accent
	var border := ColorRect.new()
	border.position = Vector2(panel_x, panel_y)
	border.size = Vector2(PANEL_W, 3)
	border.color = Color(0.95, 0.65, 0.25)
	add_child(border)
	_row_nodes.append(border)

	# Title
	var title := Label.new()
	title.text = "MAP EDIT MODE  (Floor %d)" % _floor_idx
	title.position = Vector2(panel_x + PAD, panel_y + PAD - 4)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_row_nodes.append(title)

	var hint := Label.new()
	hint.text = "Press U to exit. Save persists to user:// override."
	hint.position = Vector2(panel_x + PAD, panel_y + PAD + 18)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	hint.add_theme_font_size_override("font_size", 11)
	add_child(hint)
	_row_nodes.append(hint)

	# Width row
	var width_y := panel_y + PAD + 50
	_width_label = _make_row("Width (tiles)", _orig_width, panel_x, width_y)
	_width_slider = HSlider.new()
	_width_slider.min_value = 32
	_width_slider.max_value = 256
	_width_slider.step = 8
	_width_slider.value = _orig_width
	_width_slider.position = Vector2(panel_x + 110, width_y + 4)
	_width_slider.size = Vector2(PANEL_W - 110 - PAD - 60, 20)
	_width_slider.value_changed.connect(_on_width_changed)
	add_child(_width_slider)
	_row_nodes.append(_width_slider)

	# Height row
	var height_y := width_y + ROW_H
	_height_label = _make_row("Height (tiles)", _orig_height, panel_x, height_y)
	_height_slider = HSlider.new()
	_height_slider.min_value = 20
	_height_slider.max_value = 80
	_height_slider.step = 4
	_height_slider.value = _orig_height
	_height_slider.position = Vector2(panel_x + 110, height_y + 4)
	_height_slider.size = Vector2(PANEL_W - 110 - PAD - 60, 20)
	_height_slider.value_changed.connect(_on_height_changed)
	add_child(_height_slider)
	_row_nodes.append(_height_slider)

	# Color row
	var color_y := height_y + ROW_H
	var color_lbl := Label.new()
	color_lbl.text = "Ambient"
	color_lbl.position = Vector2(panel_x + PAD, color_y + 6)
	color_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	color_lbl.add_theme_font_size_override("font_size", 14)
	add_child(color_lbl)
	_row_nodes.append(color_lbl)

	_color_picker = ColorPickerButton.new()
	_color_picker.color = _orig_color
	_color_picker.position = Vector2(panel_x + 110, color_y)
	_color_picker.size = Vector2(PANEL_W - 110 - PAD, 32)
	add_child(_color_picker)
	_row_nodes.append(_color_picker)

	# Buttons
	var btn_y := panel_y + panel_h - BTN_H - PAD
	var save_btn := _make_button("SAVE", panel_x + PAD, btn_y, (PANEL_W - PAD * 3) * 0.5, BTN_H, Color(0.35, 0.75, 0.45))
	save_btn.pressed.connect(_on_save_pressed)
	add_child(save_btn)
	_row_nodes.append(save_btn)

	var cancel_btn := _make_button("CANCEL", panel_x + PAD * 2 + (PANEL_W - PAD * 3) * 0.5, btn_y, (PANEL_W - PAD * 3) * 0.5, BTN_H, Color(0.65, 0.40, 0.40))
	cancel_btn.pressed.connect(_on_cancel_pressed)
	add_child(cancel_btn)
	_row_nodes.append(cancel_btn)

	var reset_btn := _make_button("RESET", panel_x + PAD, btn_y - BTN_H - 8, PANEL_W - PAD * 2, BTN_H * 0.7, Color(0.55, 0.55, 0.30))
	reset_btn.pressed.connect(_on_reset_pressed)
	add_child(reset_btn)
	_row_nodes.append(reset_btn)

func _make_row(label_text: String, value: int, px: float, py: float) -> Label:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = Vector2(px + PAD, py + 6)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 14)
	add_child(lbl)
	_row_nodes.append(lbl)

	var val := Label.new()
	val.text = str(value)
	val.position = Vector2(px + PANEL_W - PAD - 48, py + 6)
	val.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90))
	val.add_theme_font_size_override("font_size", 14)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.name = "Val"
	add_child(val)
	_row_nodes.append(val)
	return val

func _make_button(text: String, x: float, y: float, w: float, h: float, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8))
	btn.add_theme_font_size_override("font_size", 14)
	# Tint via modulate since Button doesn't expose bg color directly without a StyleBox.
	btn.modulate = color
	return btn

func _on_width_changed(v: float) -> void:
	if _width_label != null:
		_width_label.text = str(int(v))

func _on_height_changed(v: float) -> void:
	if _height_label != null:
		_height_label.text = str(int(v))

func _on_dim_input(event: InputEvent) -> void:
	# Clicking outside the panel (on the dim layer) cancels.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel_pressed()

func _on_save_pressed() -> void:
	if _width_slider == null or _height_slider == null or _color_picker == null:
		return
	var w := int(_width_slider.value)
	var h := int(_height_slider.value)
	var c := _color_picker.color
	saved.emit(w, h, c)
	close()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	close()

func _on_reset_pressed() -> void:
	reset_requested.emit()
	close()

func _clear() -> void:
	for n in _row_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_row_nodes.clear()
	_width_slider = null
	_height_slider = null
	_width_label = null
	_height_label = null
	_color_picker = null
