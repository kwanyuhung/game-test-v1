# settings_panel.gd
class_name SettingsPanel
# Game settings panel — audio volume, game speed, notification toggles.
# Press O to toggle.
extends CanvasLayer

signal setting_changed(key: String, value)

var _is_open := false
var _settings: Dictionary = {
	"bgm_volume": 0.8,
	"sfx_volume": 0.8,
	"game_speed": 1.0,
	"notif_toasts": true,
	"notif_telegram": true,
}

var _option_rows: Array = []
var _selected_idx := 0
var _music_slider_val := 0.8
var _sfx_slider_val := 0.8
var _speed_val := 1.0

func _ready() -> void:
	visible = false

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func open() -> void:
	_is_open = true
	visible = true
	_build_ui()

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()

func get_setting(key: String):
	return _settings.get(key, 0.0)

func _build_ui() -> void:
	_clear_ui()

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.02, 0.02, 0.05, 0.88)
	ov.gui_input.connect(_on_input)
	add_child(ov)

	var pan_x := 60.0
	var pan_y := 30.0
	var pan_w := 200.0
	var pan_h := 120.0

	var pan := ColorRect.new()
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(pan_w, pan_h)
	pan.color = Color(0.09, 0.09, 0.13, 0.95)
	add_child(pan)

	var title := Label.new()
	title.text = "SETTINGS"
	title.position = Vector2(pan_x + 6, pan_y + 4)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	title.add_theme_font_size_override("font_size", 9)
	add_child(title)

	var options := [
		{"label": "BGM Volume", "type": "slider", "key": "bgm", "val": _settings["bgm_volume"]},
		{"label": "SFX Volume", "type": "slider", "key": "sfx", "val": _settings["sfx_volume"]},
		{"label": "Game Speed", "type": "slider", "key": "speed", "val": _settings["game_speed"]},
		{"label": "Toasts", "type": "toggle", "key": "notif_toasts", "val": _settings["notif_toasts"]},
		{"label": "Telegram", "type": "toggle", "key": "notif_telegram", "val": _settings["notif_telegram"]},
	]
	_option_rows = options

	var y := pan_y + 20.0
	for i in range(options.size()):
		var opt = options[i]
		_draw_option(opt, i, Vector2(pan_x + 6, y))
		y += 16.0

	# Hint row
	var hint := Label.new()
	hint.text = "W/S: select  A/D: adjust  E: confirm  ESC: close"
	hint.position = Vector2(pan_x + 6, pan_y + pan_h - 14)
	hint.add_theme_color_override("font_color", Color(0.30, 0.30, 0.35))
	hint.add_theme_font_size_override("font_size", 7)
	add_child(hint)

	_update_selection()

func _draw_option(opt: Dictionary, idx: int, pos: Vector2) -> void:
	var is_sel := idx == _selected_idx
	var col := Color(0.85, 0.85, 0.70) if is_sel else Color(0.55, 0.55, 0.60)
	var prefix := "> " if is_sel else "  "

	var lbl := Label.new()
	lbl.text = prefix + opt["label"]
	lbl.position = pos
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.name = "opt_%d" % idx
	add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.name = "val_%d" % idx
	var val_text := ""
	if opt["type"] == "slider":
		val_text = "%.1f" % opt["val"]
	elif opt["type"] == "toggle":
		val_text = "ON" if opt["val"] else "OFF"
	val_lbl.text = val_text
	val_lbl.position = Vector2(pos.x + 120, pos.y)
	val_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 0.60) if opt["val"] else Color(0.85, 0.50, 0.50))
	val_lbl.add_theme_font_size_override("font_size", 8)
	add_child(val_lbl)

func _update_selection() -> void:
	for i in range(_option_rows.size()):
		var opt = _option_rows[i]
		var lbl := get_node_or_null("opt_%d" % i)
		if lbl != null:
			lbl.text = ("> " if i == _selected_idx else "  ") + opt["label"]
			lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.70) if i == _selected_idx else Color(0.55, 0.55, 0.60))

func _clear_ui() -> void:
	for c in get_children():
		c.queue_free()
	_option_rows.clear()

func _on_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_TAB:
				close()
			KEY_W, KEY_UP:
				_selected_idx = maxi(0, _selected_idx - 1)
				_update_selection()
			KEY_S, KEY_DOWN:
				_selected_idx = mini(_option_rows.size() - 1, _selected_idx + 1)
				_update_selection()
			KEY_A, KEY_LEFT:
				_adjust_selected(-0.1)
			KEY_D, KEY_RIGHT:
				_adjust_selected(0.1)
			KEY_ENTER, KEY_SPACE:
				_toggle_selected()

func _adjust_selected(delta: float) -> void:
	if _selected_idx < 0 or _selected_idx >= _option_rows.size():
		return
	var opt = _option_rows[_selected_idx]
	if opt["type"] == "slider":
		opt["val"] = clampf(opt["val"] + delta, 0.0, 1.0)
		_settings[opt["key"] + "_volume"] = opt["val"] if opt["key"] in ["bgm", "sfx"] else opt["val"]
		if opt["key"] == "speed":
			_settings["game_speed"] = opt["val"]
		setting_changed.emit(opt["key"], opt["val"])
	elif opt["type"] == "toggle":
		opt["val"] = not opt["val"]
		_settings[opt["key"]] = opt["val"]
		setting_changed.emit(opt["key"], opt["val"])
	_update_val_label(_selected_idx)

func _toggle_selected() -> void:
	if _selected_idx < 0 or _selected_idx >= _option_rows.size():
		return
	var opt = _option_rows[_selected_idx]
	if opt["type"] == "toggle":
		opt["val"] = not opt["val"]
		_settings[opt["key"]] = opt["val"]
		setting_changed.emit(opt["key"], opt["val"])
		_update_val_label(_selected_idx)

func _update_val_label(idx: int) -> void:
	if idx < 0 or idx >= _option_rows.size():
		return
	var opt = _option_rows[idx]
	var lbl := get_node_or_null("val_%d" % idx)
	if lbl == null:
		return
	if opt["type"] == "slider":
		lbl.text = "%.1f" % opt["val"]
	elif opt["type"] == "toggle":
		lbl.text = "ON" if opt["val"] else "OFF"
		lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 0.60) if opt["val"] else Color(0.85, 0.50, 0.50))
