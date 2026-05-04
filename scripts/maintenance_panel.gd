# maintenance_panel.gd
# Player-facing maintenance task panel.
# Press M to toggle — shows all open issues, urgency, floor, description.
# Player can select an issue to go fix it (walk to location + press E).
# ═══════════════════════════════════════════════════════════════════════
class_name MaintenancePanel
extends CanvasLayer

signal closed()
signal issue_selected(issue)

const MaintenanceSystem = preload("res://scripts/maintenance_system.gd")
const Issue = MaintenanceSystem.Issue

const PANEL_W := 280.0
const PANEL_H := 160.0
const LINE_H := 16.0

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

const MAX_VISIBLE := 7

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

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()
	closed.emit()

func _build_ui() -> void:
	_clear_ui()

	var scr_w := 320.0
	var scr_h := 180.0
	var pan_x := scr_w - PANEL_W - 4
	var pan_y := (scr_h - PANEL_H) * 0.5

	# Background
	_bg = ColorRect.new()
	_bg.position = Vector2(pan_x, pan_y)
	_bg.size = Vector2(PANEL_W, PANEL_H)
	_bg.color = Color(0.04, 0.04, 0.08, 0.96)
	add_child(_bg)

	# Header bar
	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(PANEL_W, 16)
	hdr.color = Color(0.12, 0.12, 0.18)
	add_child(hdr)

	_header_lbl = Label.new()
	_header_lbl.text = "  MAINTENANCE"
	_header_lbl.position = Vector2(pan_x + 2, pan_y + 2)
	_header_lbl.add_theme_color_override("font_color", Color(0.90, 0.75, 0.30))
	_header_lbl.add_theme_font_size_override("font_size", 8)
	add_child(_header_lbl)

	_time_lbl = Label.new()
	_time_lbl.text = ""
	_time_lbl.position = Vector2(pan_x + PANEL_W - 80, pan_y + 2)
	_time_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	_time_lbl.add_theme_font_size_override("font_size", 6)
	add_child(_time_lbl)

	# Issue list area
	var list_y := pan_y + 18
	var list_bg := ColorRect.new()
	list_bg.position = Vector2(pan_x + 2, list_y)
	list_bg.size = Vector2(PANEL_W - 4, MAX_VISIBLE * LINE_H + 4)
	list_bg.color = Color(0.02, 0.02, 0.04)
	add_child(list_bg)

	_build_issue_list(pan_x, list_y)

	# Hint bar
	var hint_y := pan_y + PANEL_H - 14
	_hint_lbl = Label.new()
	_hint_lbl.text = "W/S: Navigate  |  E: Fix Issue  |  ESC: Close"
	_hint_lbl.position = Vector2(pan_x + 2, hint_y)
	_hint_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.50))
	_hint_lbl.add_theme_font_size_override("font_size", 5)
	add_child(_hint_lbl)

func _build_issue_list(pan_x: float, list_y: float) -> void:
	for lbl in _issue_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_issue_labels.clear()

	if _sel_marker != null and is_instance_valid(_sel_marker):
		_sel_marker.queue_free()

	var visible := _visible_issues.slice(_scroll_offset, _scroll_offset + MAX_VISIBLE)

	for i in range(visible.size()):
		var issue: Issue = visible[i]
		var global_i := _scroll_offset + i

		var row_bg: ColorRect
		if global_i == _selected_idx:
			row_bg = ColorRect.new()
			row_bg.position = Vector2(pan_x + 2, list_y + 2 + i * LINE_H)
			row_bg.size = Vector2(PANEL_W - 6, LINE_H - 1)
			row_bg.color = Color(0.20, 0.20, 0.35)
			add_child(row_bg)
			_sel_marker = row_bg

		var lbl := Label.new()
		lbl.position = Vector2(pan_x + 4, list_y + 3 + i * LINE_H)
		lbl.size = Vector2(PANEL_W - 10, LINE_H)

		var urgency_col: Color
		match issue.urgency:
			1: urgency_col = Color(0.50, 0.85, 0.50)
			2: urgency_col = Color(0.90, 0.80, 0.30)
			3: urgency_col = Color(0.90, 0.35, 0.35)
			_: urgency_col = Color(0.70, 0.70, 0.70)

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
		lbl.add_theme_font_size_override("font_size", 6)
		add_child(lbl)
		_issue_labels.append(lbl)

		# Description on second line
		var desc_lbl := Label.new()
		desc_lbl.position = Vector2(pan_x + 4, list_y + 3 + i * LINE_H + LINE_H * 0.6)
		desc_lbl.size = Vector2(PANEL_W - 10, LINE_H)
		desc_lbl.text = "  %s" % issue.description
		desc_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
		desc_lbl.add_theme_font_size_override("font_size", 5)
		if global_i == _selected_idx:
			add_child(desc_lbl)
			_issue_labels.append(desc_lbl)

	# Empty state
	if _visible_issues.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "  No open issues!\n  Great job!"
		empty_lbl.position = Vector2(pan_x + 4, list_y + 10)
		empty_lbl.add_theme_color_override("font_color", Color(0.50, 0.80, 0.50))
		empty_lbl.add_theme_font_size_override("font_size", 7)
		add_child(empty_lbl)
		_issue_labels.append(empty_lbl)

func _clear_ui() -> void:
	for c in get_children():
		if is_instance_valid(c):
			c.queue_free()
	_issue_labels.clear()
	_sel_marker = null

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_W, KEY_UP:
			_selected_idx = wrapi(_selected_idx - 1, -1, _visible_issues.size())
			_scroll_offset = clampi(_selected_idx - MAX_VISIBLE + 1, 0, maxi(0, _visible_issues.size() - MAX_VISIBLE))
			_build_issue_list(320.0 - PANEL_W - 4, 180.0 - PANEL_H - 4 + 18)
		KEY_S, KEY_DOWN:
			_selected_idx = wrapi(_selected_idx + 1, -1, _visible_issues.size())
			_scroll_offset = clampi(_selected_idx - MAX_VISIBLE + 1, 0, maxi(0, _visible_issues.size() - MAX_VISIBLE))
			_build_issue_list(320.0 - PANEL_W - 4, 180.0 - PANEL_H - 4 + 18)
		KEY_E, KEY_ENTER:
			_confirm_selected()
		KEY_ESCAPE:
			close()

func _confirm_selected() -> void:
	if _selected_idx < 0 or _selected_idx >= _visible_issues.size():
		return
	var issue: Issue = _visible_issues[_selected_idx]
	if issue.status >= 2:
		return
	close()
	issue_selected.emit(issue)
