# maintenance_panel.gd
# Player-facing maintenance task panel.
# Press M to toggle — shows all open issues, urgency, floor, description.
# Player can select an issue to go fix it (walk to location + press E).
# ═══════════════════════════════════════════════════════════════════════
class_name MaintenancePanel
extends CanvasLayer

signal closed()
signal issue_selected(issue)
signal input_blocked(bool)  # Emitted when panel opens/closes to block player input

const MaintenanceSystem = preload("res://scripts/systems/maintenance_system.gd")
const Issue = MaintenanceSystem.Issue

const LINE_H := 36.0
const MAX_VISIBLE := 15
const PANEL_MARGIN := 10.0  # Minimal margin from screen edges

var _system: MaintenanceSystem
var _visible_issues: Array[Issue] = []
var _selected_idx: int = -1
var _is_open: bool = false

var _bg: ColorRect
var _header_lbl: Label
var _time_lbl: Label
var _issue_labels: Array = []
var _sel_marker: ColorRect
var _hint_lbl: Label
var _scroll_offset: int = 0
var _overlay: ColorRect = null

func _ready() -> void:
	visible = false

func open(system: MaintenanceSystem) -> void:
	_system = system
	_is_open = true
	_visible_issues = system.get_open_issues()
	_selected_idx = -1
	_scroll_offset = 0
	_build_ui()
	visible = true
	input_blocked.emit(true)

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()
	input_blocked.emit(false)
	closed.emit()

func _build_ui() -> void:
	_clear_ui()

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var scr_w: float = viewport_rect.size.x
	var scr_h: float = viewport_rect.size.y
	
	# Calculate panel size (full screen with margin)
	var pan_w: float = scr_w - PANEL_MARGIN * 2
	var pan_h: float = scr_h - PANEL_MARGIN * 2
	var pan_x: float = PANEL_MARGIN
	var pan_y: float = PANEL_MARGIN
	
	# Calculate font scale based on screen height
	var font_scale: float = scr_h / 360.0  # Base resolution is 360px height
	
	# Full-screen overlay that catches all input
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.02, 0.02, 0.06, 0.85)
	_overlay.gui_input.connect(_on_overlay_input)
	add_child(_overlay)

	# Main panel background
	_bg = ColorRect.new()
	_bg.position = Vector2(pan_x, pan_y)
	_bg.size = Vector2(pan_w, pan_h)
	_bg.color = Color(0.08, 0.08, 0.12, 0.98)
	add_child(_bg)

	# Header bar
	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(pan_w, 32)
	hdr.color = Color(0.12, 0.12, 0.20)
	add_child(hdr)

	_header_lbl = Label.new()
	_header_lbl.text = "  MAINTENANCE ISSUES"
	_header_lbl.position = Vector2(pan_x + 12, pan_y + 8)
	_header_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.30))
	_header_lbl.add_theme_font_size_override("font_size", int(20 * font_scale))
	add_child(_header_lbl)

	_time_lbl = Label.new()
	_time_lbl.text = "Press M or ESC to close"
	_time_lbl.position = Vector2(pan_x + pan_w - 280, pan_y + 10)
	_time_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	_time_lbl.add_theme_font_size_override("font_size", int(14 * font_scale))
	add_child(_time_lbl)

	# Issue list area
	var list_y := pan_y + 44
	var list_h := pan_h - 80
	var list_bg := ColorRect.new()
	list_bg.position = Vector2(pan_x + 8, list_y)
	list_bg.size = Vector2(pan_w - 16, list_h)
	list_bg.color = Color(0.02, 0.02, 0.06, 0.80)
	add_child(list_bg)

	_build_issue_list(pan_x, list_y, pan_w, font_scale)

	# Hint bar
	var hint_y := pan_y + pan_h - 36
	_hint_lbl = Label.new()
	_hint_lbl.text = "W/S or Arrow Keys: Navigate  |  E or Enter: Select Issue  |  ESC: Close Panel"
	_hint_lbl.position = Vector2(pan_x + 20, hint_y)
	_hint_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.60))
	_hint_lbl.add_theme_font_size_override("font_size", int(16 * font_scale))
	add_child(_hint_lbl)

func _on_overlay_input(event: InputEvent) -> void:
	# Consume all input events to prevent them from reaching the player
	pass

func _build_issue_list(pan_x: float, list_y: float, pan_w: float, font_scale: float) -> void:
	for lbl in _issue_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_issue_labels.clear()

	if _sel_marker != null and is_instance_valid(_sel_marker):
		_sel_marker.queue_free()

	var visible_list := _visible_issues.slice(_scroll_offset, _scroll_offset + MAX_VISIBLE)
	var row_height := LINE_H

	for i in range(visible_list.size()):
		var issue: Issue = visible_list[i]
		var global_i := _scroll_offset + i

		var row_bg: ColorRect
		if global_i == _selected_idx:
			row_bg = ColorRect.new()
			row_bg.position = Vector2(pan_x + 10, list_y + 4 + i * row_height)
			row_bg.size = Vector2(pan_w - 24, row_height - 2)
			row_bg.color = Color(0.25, 0.22, 0.40)
			add_child(row_bg)
			_sel_marker = row_bg

		var lbl := Label.new()
		lbl.position = Vector2(pan_x + 16, list_y + 6 + i * row_height)
		lbl.size = Vector2(pan_w - 32, row_height)

		var urgency_col: Color
		match issue.urgency:
			1: urgency_col = Color(0.50, 0.90, 0.50)
			2: urgency_col = Color(0.95, 0.85, 0.30)
			3: urgency_col = Color(0.95, 0.35, 0.35)
			_: urgency_col = Color(0.75, 0.75, 0.75)

		var status_icon := "○"
		if issue.status == 1:
			status_icon = "◐"

		lbl.text = "%s [%s] Floor %d — %s" % [
			status_icon,
			Issue.type_emoji(issue.issue_type),
			issue.floor,
			issue.label
		]
		lbl.add_theme_color_override("font_color", urgency_col)
		lbl.add_theme_font_size_override("font_size", int(16 * font_scale))
		add_child(lbl)
		_issue_labels.append(lbl)

		# Description on second line
		var desc_lbl := Label.new()
		desc_lbl.position = Vector2(pan_x + 16, list_y + 6 + i * row_height + row_height * 0.65)
		desc_lbl.size = Vector2(pan_w - 32, row_height)
		desc_lbl.text = "  %s" % issue.description
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
		desc_lbl.add_theme_font_size_override("font_size", int(14 * font_scale))
		if global_i == _selected_idx:
			add_child(desc_lbl)
			_issue_labels.append(desc_lbl)

	# Empty state
	if _visible_issues.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "  No open issues!\n  Great job!"
		empty_lbl.position = Vector2(pan_x + 20, list_y + 30)
		empty_lbl.add_theme_color_override("font_color", Color(0.50, 0.90, 0.50))
		empty_lbl.add_theme_font_size_override("font_size", int(20 * font_scale))
		add_child(empty_lbl)
		_issue_labels.append(empty_lbl)

func _clear_ui() -> void:
	for c in get_children():
		if is_instance_valid(c):
			c.queue_free()
	_issue_labels.clear()
	_sel_marker = null
	_overlay = null

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_W, KEY_UP:
			_selected_idx = wrapi(_selected_idx - 1, -1, _visible_issues.size())
			_scroll_offset = clampi(_selected_idx - MAX_VISIBLE + 1, 0, maxi(0, _visible_issues.size() - MAX_VISIBLE))
			_refresh_list()
		KEY_S, KEY_DOWN:
			_selected_idx = wrapi(_selected_idx + 1, -1, _visible_issues.size())
			_scroll_offset = clampi(_selected_idx - MAX_VISIBLE + 1, 0, maxi(0, _visible_issues.size() - MAX_VISIBLE))
			_refresh_list()
		KEY_E, KEY_ENTER:
			_confirm_selected()
		KEY_ESCAPE:
			close()

func _refresh_list() -> void:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var scr_h: float = viewport_rect.size.y
	var font_scale: float = scr_h / 360.0
	var pan_w: float = viewport_rect.size.x - PANEL_MARGIN * 2
	var pan_x: float = PANEL_MARGIN
	var list_y: float = PANEL_MARGIN + 44
	_build_issue_list(pan_x, list_y, pan_w, font_scale)

func _confirm_selected() -> void:
	if _selected_idx < 0 or _selected_idx >= _visible_issues.size():
		return
	var issue: Issue = _visible_issues[_selected_idx]
	if issue.status >= 2:
		return
	close()
	issue_selected.emit(issue)
