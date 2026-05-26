# robot_panel_system.gd
# Robot management UI panel — all building and signal handling.
extends Node

signal input_blocked(bool)  # Emitted when panel opens/closes to block player input

const ActorData = preload("res://scripts/entities/actor_data.gd")

const PANEL_MARGIN := 60.0

var _main: Node2D = null
var _robot_panel: Control = null
var _player_stats: Node = null
var _toasts: Node = null
var _player: Node = null
var _overlay: ColorRect = null

func setup(main: Node2D) -> void:
	_main = main
	_player_stats = main.get("_player_stats")
	_toasts = main.get("_toasts")
	_player = main.get("_player")

func build_robot_panel() -> Control:
	if _robot_panel != null:
		return _robot_panel
	
	var viewport_rect: Rect2 = _main.get_viewport_rect()
	var scr_w: float = viewport_rect.size.x
	var scr_h: float = viewport_rect.size.y
	var font_scale: float = scr_h / 360.0
	
	_robot_panel = Control.new()
	_robot_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_robot_panel.offset_left = PANEL_MARGIN
	_robot_panel.offset_top = PANEL_MARGIN
	_robot_panel.offset_right = -PANEL_MARGIN
	_robot_panel.offset_bottom = -PANEL_MARGIN
	_robot_panel.color = Color(0.10, 0.10, 0.15, 0.98)
	_robot_panel.visible = false
	_main.add_child(_robot_panel)

	# Overlay to catch input
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.02, 0.02, 0.06, 0.85)
	_overlay.gui_input.connect(_on_overlay_input)
	_robot_panel.add_child(_overlay)

	var title := Label.new()
	title.text = "ROBOT STAFF PANEL"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	title.add_theme_font_size_override("font_size", int(18 * font_scale))
	title.position = Vector2(0, 10)
	_robot_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Staff mode only  |  [R] close"
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
	subtitle.add_theme_font_size_override("font_size", int(12 * font_scale))
	subtitle.position = Vector2(0, 36)
	_robot_panel.add_child(subtitle)

	# Close button (X) in top-right corner
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-45, 8)
	close_btn.size = Vector2(36, 28)
	close_btn.add_theme_color_override("font_color", Color(0.90, 0.60, 0.60))
	close_btn.add_theme_color_override("bg_color", Color(0.30, 0.15, 0.15))
	close_btn.connect("pressed", _on_close_pressed)
	_robot_panel.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.position = Vector2(0, 60)
	scroll.offset_right = -10
	scroll.offset_bottom = -50
	_robot_panel.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var h_label := Label.new()
	h_label.text = "-- HUMANOID (like human, uses tools) --"
	h_label.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	h_label.add_theme_font_size_override("font_size", int(12 * font_scale))
	list.add_child(h_label)

	var humanoid_types := [
		{"staff_role": 3, "name": "Greeter",    "desc": "Welcomes & directs customers", "cost": 400},
		{"staff_role": 0, "name": "Cashier",    "desc": "Operates checkout lane",      "cost": 500},
		{"staff_role": 2, "name": "Cleaner",    "desc": "Mops & tidies the store",       "cost": 350},
		{"staff_role": 1, "name": "Stocker",     "desc": "Restocks shelves",              "cost": 400},
		{"staff_role": 4, "name": "Security",    "desc": "Patrols & monitors",             "cost": 450},
		{"staff_role": 6, "name": "Scan & Go",   "desc": "Assists player with scanning",  "cost": 450},
	]
	for rt in humanoid_types:
		var btn := Button.new()
		btn.text = "[%s] %dXP  %s" % [rt["name"], rt["cost"], rt["desc"]]
		btn.add_theme_color_override("font_color", Color(0.80, 0.88, 0.90))
		btn.add_theme_color_override("bg_color", Color(0.18, 0.35, 0.45))
		btn.connect("pressed", _on_robot_humanoid_pressed.bind(rt["staff_role"], rt["cost"]))
		list.add_child(btn)

	var s_label := Label.new()
	s_label.text = "-- SINGLE-FUNCTION (automated machine) --"
	s_label.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	s_label.add_theme_font_size_override("font_size", int(12 * font_scale))
	list.add_child(s_label)

	var single_types := [
		{"rrole": 0, "name": "CleanerBot",   "desc": "Auto-cleans floors (battery)", "cost": 250},
		{"rrole": 1, "name": "GuideBot",      "desc": "Answers questions",             "cost": 200},
		{"rrole": 2, "name": "ShelfBot",     "desc": "Auto-scans shelf stock",         "cost": 300},
		{"rrole": 3, "name": "SecurityBot",  "desc": "Patrol robot (red eye)",         "cost": 350},
		{"rrole": 4, "name": "DeliveryBot",  "desc": "Transports cargo",               "cost": 400},
	]
	for rt in single_types:
		var btn := Button.new()
		btn.text = "[%s] %dXP  %s" % [rt["name"], rt["cost"], rt["desc"]]
		btn.add_theme_color_override("font_color", Color(0.80, 0.85, 0.75))
		btn.add_theme_color_override("bg_color", Color(0.25, 0.28, 0.22))
		btn.connect("pressed", _on_robot_single_pressed.bind(rt["rrole"], rt["cost"]))
		list.add_child(btn)

	var close_bottom_btn := Button.new()
	close_bottom_btn.text = "[R] Close"
	close_bottom_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	close_bottom_btn.position = Vector2(0, -45)
	close_bottom_btn.size = Vector2(0, 40)
	close_bottom_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_bottom_btn.connect("pressed", _on_close_pressed)
	_robot_panel.add_child(close_bottom_btn)

	_main.set("_robot_panel", _robot_panel)
	return _robot_panel

func show_panel() -> void:
	if _robot_panel != null:
		_robot_panel.visible = true
		input_blocked.emit(true)

func hide_panel() -> void:
	if _robot_panel != null:
		_robot_panel.visible = false
		input_blocked.emit(false)

func _on_overlay_input(event: InputEvent) -> void:
	# Consume all input events
	pass

func _input(event: InputEvent) -> void:
	if _robot_panel == null or not _robot_panel.visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			hide_panel()

func _on_close_pressed() -> void:
	hide_panel()

func _on_robot_humanoid_pressed(staff_role: int, cost: int) -> void:
	if _player_stats == null:
		return
	var stats: Node = _player_stats
	if not stats.can_use_humanoid_robots():
		var next_xp: int = stats.get_staff_xp_for_next_rank()
		var msg: String = "Humanoid robots unlock at Senior rank! %d more Staff XP needed." % max(0, next_xp)
		if _toasts: _toasts.toast_warning(msg)
		return
	if stats.get_xp() < cost:
		var msg: String = "Not enough XP! Need %d XP to deploy." % cost
		if _toasts: _toasts.toast_warning(msg)
		return
	stats.spend_xp(cost)
	stats.complete_staff_task()
	_main.spawn_robot_humanoid(staff_role as ActorData.StaffRole)
	var role_names: Dictionary = {0:"Cashier",1:"Stocker",2:"Cleaner",3:"Greeter",4:"Security",5:"Manager",6:"FloorStaff",7:"ScanGo"}
	var rname: String = role_names.get(staff_role, "Robot")
	if _toasts: _toasts.toast_success("Deployed HUMANOID %s! -%d XP" % [rname, cost])
	_update_robot_panel()

func _on_robot_single_pressed(rrole: int, cost: int) -> void:
	if _player_stats == null:
		return
	var stats: Node = _player_stats
	if not stats.can_use_single_function_robots():
		var next_xp: int = stats.get_staff_xp_for_next_rank()
		var msg: String = "Single-function robots unlock at Worker rank! %d more Staff XP needed." % max(0, next_xp)
		if _toasts: _toasts.toast_warning(msg)
		return
	if stats.get_xp() < cost:
		var msg: String = "Not enough XP! Need %d XP to deploy." % cost
		if _toasts: _toasts.toast_warning(msg)
		return
	stats.spend_xp(cost)
	stats.complete_staff_task()
	_main.spawn_robot_single(rrole as ActorData.RobotRole)
	var role_names: Dictionary = {0:"CleanerBot",1:"GuideBot",2:"ShelfBot",3:"SecurityBot",4:"DeliveryBot"}
	var rname: String = role_names.get(rrole, "Robot")
	if _toasts: _toasts.toast_success("Deployed %s! -%d XP" % [rname, cost])
	_update_robot_panel()

func _update_robot_panel() -> void:
	if _robot_panel == null:
		return
	var active_count: int = 0
	var robots: Array = _main.get("_robots")
	if robots != null:
		active_count = robots.size()
	for child in _robot_panel.get_children():
		if child is Label and child.text.begins_with("Active robots:"):
			child.text = "Active robots: %d" % active_count
			break

func get_spawns_by_type(t: String) -> Array:
	var robots: Array = _main.get("_robots") if _main else []
	if robots == null:
		return []
	var result: Array = []
	for r in robots:
		if t == "humanoid" and r.get("_is_humanoid") == true:
			result.append(r)
		elif t == "single" and r.has("_is_humanoid") and r.get("_is_humanoid") == false:
			result.append(r)
	return result
