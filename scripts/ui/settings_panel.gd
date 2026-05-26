# settings_panel.gd
class_name SettingsPanel
# Game settings panel — audio volume, game speed, notification toggles, and controls help.
# Press O to toggle.
extends CanvasLayer

signal setting_changed(key: String, value)
signal input_blocked(bool)  # Emitted when panel opens/closes to block player input

var _is_open := false
var _settings: Dictionary = {
	"language": "en",
	"bgm_volume": 0.8,
	"sfx_volume": 0.8,
	"game_speed": 1.0,
	"notif_toasts": true,
	# Draw settings - control what's rendered
	"draw_factory_robot_1": true,   # Self-checkout counter robot
	"draw_factory_robot_2": true,   # Shelf scanning robot
	"draw_factory_robot_3": true,   # Warehouse robots (cleaning/security/delivery)
	"draw_interactive": true,        # Interaction bubbles and indicators
}

var _option_rows: Array = []
var _selected_idx := 0
var _music_slider_val := 0.8
var _sfx_slider_val := 0.8
var _speed_val := 1.0

var _lang: String = "en"

# Inline translation table: key -> {"en": ..., "zh": ...}
var _i18n := {
	"settings_title":      {"en": "SETTINGS",           "zh": "设置"},
	"controls_title":      {"en": "CONTROLS",           "zh": "操作说明"},
	"bgm_volume":          {"en": "BGM Volume",         "zh": "背景音乐音量"},
	"sfx_volume":          {"en": "SFX Volume",         "zh": "音效音量"},
	"game_speed":          {"en": "Game Speed",         "zh": "游戏速度"},
	"toasts":              {"en": "Toasts",             "zh": "通知弹窗"},
	"draw_settings":       {"en": "--- Draw Settings ---", "zh": "--- 显示设置 ---"},
	"factory_robot_1":     {"en": "Factory Robot 1 (Checkout)", "zh": "机械臂 1 (收银台)"},
	"factory_robot_2":     {"en": "Factory Robot 2 (Shelf)", "zh": "机械臂 2 (货架)"},
	"factory_robot_3":     {"en": "Factory Robot 3 (Warehouse)", "zh": "机械臂 3 (仓库)"},
	"interactive_elements":{"en": "Interactive Elements","zh": "交互元素"},
	"language":            {"en": "Language",           "zh": "语言"},
	"lang_en":             {"en": "English",            "zh": "English"},
	"lang_zh":             {"en": "中文",              "zh": "中文"},
	"on":                  {"en": "ON",                "zh": "开"},
	"off":                 {"en": "OFF",               "zh": "关"},
	"nav_hint":            {"en": "W/S: select  A/D: adjust  E: confirm  ESC: close", "zh": "W/S: 选择  A/D: 调整  E: 确认  ESC: 关闭"},
	"press_o_close":       {"en": "Press O to close",   "zh": "按 O 关闭"},
	"move":                {"en": "Move player",        "zh": "移动角色"},
	"interact":            {"en": "Interact / Confirm", "zh": "交互 / 确认"},
	"drop_grab_cart":      {"en": "Drop/grab cart",     "zh": "放低/拿起购物车"},
	"toggle_staff_mode":   {"en": "Toggle staff mode",  "zh": "切换员工模式"},
	"toggle_map":          {"en": "Toggle map panel",   "zh": "切换地图面板"},
	"floor_panel":         {"en": "Floor panel",        "zh": "楼层面板"},
	"shopping_list":       {"en": "Shopping list",      "zh": "购物清单"},
	"quest_journal":       {"en": "Quest journal",      "zh": "任务日志"},
	"settings":            {"en": "Settings",           "zh": "设置"},
	"pause_game":          {"en": "Pause game",         "zh": "暂停游戏"},
	"quick_save":          {"en": "Quick save",         "zh": "快速保存"},
	"quick_load":          {"en": "Quick load",         "zh": "快速读取"},
	"robot_restock":       {"en": "Robot panel / Restock", "zh": "机械臂面板 / 补货"},
	"renovate":            {"en": "Renovate section",   "zh": "装修区域"},
	"brand_portal":        {"en": "Brand portal",       "zh": "品牌门户"},
	"business_mode":       {"en": "Business mode",      "zh": "商业模式"},
	"catch_thief":         {"en": "Catch thief",       "zh": "抓小偷"},
}

func _t(key: String) -> String:
	return _i18n.get(key, {}).get(_lang, _i18n.get(key, {}).get("en", key))

# Controls help data
var _controls := [
	{"key": "W/A/S/D", "desc": "move"},
	{"key": "E", "desc": "interact"},
	{"key": "G", "desc": "drop_grab_cart"},
	{"key": "K", "desc": "toggle_staff_mode"},
	{"key": "M", "desc": "toggle_map"},
	{"key": "V", "desc": "floor_panel"},
	{"key": "L", "desc": "shopping_list"},
	{"key": "J", "desc": "quest_journal"},
	{"key": "O", "desc": "settings"},
	{"key": "P / SPACE", "desc": "pause_game"},
	{"key": "F5", "desc": "quick_save"},
	{"key": "F9", "desc": "quick_load"},
	{"key": "R", "desc": "robot_restock"},
	{"key": "X", "desc": "renovate"},
	{"key": "B", "desc": "brand_portal"},
	{"key": "Shift+B", "desc": "business_mode"},
	{"key": "F", "desc": "catch_thief"},
]

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
	_lang = _settings.get("language", "en")
	input_blocked.emit(true)
	_build_ui()

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()
	input_blocked.emit(false)

func get_setting(key: String):
	return _settings.get(key, 0.0)

func _build_ui() -> void:
	_clear_ui()

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var scr_w: float = viewport_rect.size.x
	var scr_h: float = viewport_rect.size.y
	# Cap font_scale to prevent UI from becoming too large on big screens
	var font_scale: float = clampf(scr_h / 720.0, 0.6, 1.5)

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.02, 0.02, 0.05, 0.88)
	ov.gui_input.connect(_on_input)
	add_child(ov)

	# Settings panel (left side) - full screen with margin
	var pan_x: float = scr_w * 0.05
	var pan_y: float = scr_h * 0.05
	var pan_w: float = scr_w * 0.42
	var pan_h: float = scr_h * 0.90

	var pan := ColorRect.new()
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(pan_w, pan_h)
	pan.color = Color(0.09, 0.09, 0.13, 0.95)
	add_child(pan)

	var title := Label.new()
	title.text = _t("settings_title")
	title.position = Vector2(pan_x + 16, pan_y + 16)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	title.add_theme_font_size_override("font_size", int(22 * font_scale))
	add_child(title)

	# Close button (X) for settings panel
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(pan_x + pan_w - 40, pan_y + 12)
	close_btn.size = Vector2(28, 28)
	close_btn.add_theme_color_override("font_color", Color(0.90, 0.60, 0.60))
	close_btn.add_theme_color_override("bg_color", Color(0.30, 0.15, 0.15))
	close_btn.connect("pressed", close)
	add_child(close_btn)

	var options := [
		{"label": "language", "type": "lang", "key": "language", "val": _settings["language"]},
		{"label": "bgm_volume", "type": "slider", "key": "bgm", "val": _settings["bgm_volume"]},
		{"label": "sfx_volume", "type": "slider", "key": "sfx", "val": _settings["sfx_volume"]},
		{"label": "game_speed", "type": "slider", "key": "speed", "val": _settings["game_speed"]},
		{"label": "toasts", "type": "toggle", "key": "notif_toasts", "val": _settings["notif_toasts"]},
		{"label": "draw_settings", "type": "label", "key": "", "val": 0},
		{"label": "factory_robot_1", "type": "toggle", "key": "draw_factory_robot_1", "val": _settings["draw_factory_robot_1"]},
		{"label": "factory_robot_2", "type": "toggle", "key": "draw_factory_robot_2", "val": _settings["draw_factory_robot_2"]},
		{"label": "factory_robot_3", "type": "toggle", "key": "draw_factory_robot_3", "val": _settings["draw_factory_robot_3"]},
		{"label": "interactive_elements", "type": "toggle", "key": "draw_interactive", "val": _settings["draw_interactive"]},
	]
	_option_rows = options

	var y: float = pan_y + 50.0
	var row_height: float = 36.0 * font_scale
	for i in range(options.size()):
		var opt = options[i]
		_draw_option(opt, i, Vector2(pan_x + 16, y), font_scale)
		y += row_height

	# Hint row
	var hint := Label.new()
	hint.text = _t("nav_hint")
	hint.position = Vector2(pan_x + 16, pan_y + pan_h - 32)
	hint.add_theme_color_override("font_color", Color(0.30, 0.30, 0.35))
	hint.add_theme_font_size_override("font_size", int(14 * font_scale))
	add_child(hint)

	# Controls panel (right side) - full screen with margin
	var ctrl_x: float = scr_w * 0.52
	var ctrl_y: float = scr_h * 0.05
	var ctrl_w: float = scr_w * 0.43
	var ctrl_h: float = scr_h * 0.90

	var ctrl_pan := ColorRect.new()
	ctrl_pan.position = Vector2(ctrl_x, ctrl_y)
	ctrl_pan.size = Vector2(ctrl_w, ctrl_h)
	ctrl_pan.color = Color(0.09, 0.09, 0.13, 0.95)
	add_child(ctrl_pan)

	var ctrl_title := Label.new()
	ctrl_title.text = _t("controls_title")
	ctrl_title.position = Vector2(ctrl_x + 16, ctrl_y + 16)
	ctrl_title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	ctrl_title.add_theme_font_size_override("font_size", int(22 * font_scale))
	add_child(ctrl_title)

	# Close button (X) for controls panel
	var ctrl_close_btn := Button.new()
	ctrl_close_btn.text = "X"
	ctrl_close_btn.position = Vector2(ctrl_x + ctrl_w - 40, ctrl_y + 12)
	ctrl_close_btn.size = Vector2(28, 28)
	ctrl_close_btn.add_theme_color_override("font_color", Color(0.90, 0.60, 0.60))
	ctrl_close_btn.add_theme_color_override("bg_color", Color(0.30, 0.15, 0.15))
	ctrl_close_btn.connect("pressed", close)
	add_child(ctrl_close_btn)

	var ctrl_y_pos: float = ctrl_y + 50.0
	var ctrl_row_height: float = 32.0 * font_scale
	for ctrl in _controls:
		# Key label
		var key_lbl := Label.new()
		key_lbl.text = "[%s]" % ctrl["key"]
		key_lbl.position = Vector2(ctrl_x + 16, ctrl_y_pos)
		key_lbl.add_theme_color_override("font_color", Color(0.72, 0.88, 0.98))
		key_lbl.add_theme_font_size_override("font_size", int(14 * font_scale))
		add_child(key_lbl)

		# Description label
		var desc_lbl := Label.new()
		desc_lbl.text = tr(ctrl["desc"])
		desc_lbl.position = Vector2(ctrl_x + 160 * font_scale, ctrl_y_pos)
		desc_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
		desc_lbl.add_theme_font_size_override("font_size", int(14 * font_scale))
		add_child(desc_lbl)

		ctrl_y_pos += ctrl_row_height

	# Controls hint
	var ctrl_hint := Label.new()
	ctrl_hint.text = _t("press_o_close")
	ctrl_hint.position = Vector2(ctrl_x + 16, ctrl_y_pos + 8)
	ctrl_hint.add_theme_color_override("font_color", Color(0.30, 0.30, 0.35))
	ctrl_hint.add_theme_font_size_override("font_size", int(14 * font_scale))
	add_child(ctrl_hint)

	_update_selection()

func _draw_option(opt: Dictionary, idx: int, pos: Vector2, font_scale: float) -> void:
	var is_sel := idx == _selected_idx
	var col := Color(0.85, 0.85, 0.70) if is_sel else Color(0.55, 0.55, 0.60)
	var prefix := "> " if is_sel else "  "

	# Handle label type (divider/header)
	if opt["type"] == "label":
		var lbl := Label.new()
		lbl.text = tr(opt["label"])
		lbl.position = pos
		lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
		lbl.add_theme_font_size_override("font_size", int(14 * font_scale))
		lbl.name = "opt_%d" % idx
		add_child(lbl)
		return

	var lbl := Label.new()
	lbl.text = prefix + tr(opt["label"])
	lbl.position = pos
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", int(16 * font_scale))
	lbl.name = "opt_%d" % idx
	add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.name = "val_%d" % idx
	var val_text := ""
	if opt["type"] == "slider":
		val_text = "%.1f" % opt["val"]
	elif opt["type"] == "toggle":
		val_text = _t("on") if opt["val"] else _t("off")
	elif opt["type"] == "lang":
		val_text = "EN / 中文"
	val_lbl.text = val_text
	val_lbl.position = Vector2(pos.x + 240 * font_scale, pos.y)
	var toggle_color: Color
	if opt["type"] == "toggle":
		toggle_color = Color(0.60, 0.85, 0.60) if opt["val"] else Color(0.85, 0.50, 0.50)
	else:
		toggle_color = Color(0.60, 0.60, 0.65)
	val_lbl.add_theme_color_override("font_color", toggle_color)
	val_lbl.add_theme_font_size_override("font_size", int(16 * font_scale))
	add_child(val_lbl)

func _update_selection() -> void:
	for i in range(_option_rows.size()):
		var opt = _option_rows[i]
		var lbl := get_node_or_null("opt_%d" % i)
		if lbl != null:
			if opt["type"] == "label":
				continue  # Skip label rows
			lbl.text = ("> " if i == _selected_idx else "  ") + tr(opt["label"])
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
				# Skip label rows when navigating up
				var new_idx := _selected_idx
				while true:
					new_idx = maxi(0, new_idx - 1)
					if new_idx == 0 or _option_rows[new_idx]["type"] != "label":
						break
				_selected_idx = new_idx
				_update_selection()
			KEY_S, KEY_DOWN:
				# Skip label rows when navigating down
				var new_idx := _selected_idx
				while true:
					new_idx = mini(_option_rows.size() - 1, new_idx + 1)
					if new_idx == _option_rows.size() - 1 or _option_rows[new_idx]["type"] != "label":
						break
				_selected_idx = new_idx
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
	# Skip label rows
	if opt["type"] == "label" or opt["type"] == "lang":
		return
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
	# Skip label rows
	if opt["type"] == "label":
		return
	if opt["type"] == "lang":
		_lang = "zh" if _lang == "en" else "en"
		_settings["language"] = _lang
		setting_changed.emit("language", _lang)
		_update_val_label(_selected_idx)
	elif opt["type"] == "toggle":
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
		lbl.text = _t("on") if opt["val"] else _t("off")
		var toggle_color: Color = Color(0.60, 0.85, 0.60) if opt["val"] else Color(0.85, 0.50, 0.50)
		lbl.add_theme_color_override("font_color", toggle_color)
	elif opt["type"] == "lang":
		lbl.text = "EN / 中文"
