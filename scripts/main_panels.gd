# main_panels.gd
# UI panel builders extracted from main.gd to reduce its size.
# Usage: var _main_panels = preload("res://scripts/main_panels.gd").new()
#        _main_panels.setup(self)   # call once
#        _main_panels.build_all()   # call from _ready
extends Node

var _main: Node2D = null

func setup(main: Node2D) -> void:
	_main = main

# ── Elevator ──────────────────────────────────────────────────────────────────
func build_elevator() -> void:
	var elevator = preload("res://scripts/elevator.gd").new()
	elevator.name = "Elevator"
	elevator.floor_reached.connect(_main._on_elevator_floor_reached)
	elevator.travel_finished.connect(_main._on_elevator_travel_finished)
	_main.add_child(elevator)
	_main.set("_elevator", elevator)

# ── Stairs ────────────────────────────────────────────────────────────────────
func build_stairs() -> void:
	var stairs_node = Node2D.new()
	stairs_node.name = "Stairs"
	_main.add_child(stairs_node)
	_main.set("_stairs_node", stairs_node)

# ── Parking ───────────────────────────────────────────────────────────────────
func build_parking() -> void:
	var parking_lot = preload("res://scripts/parking_lot.gd").new()
	parking_lot.name = "ParkingLot"
	_main.add_child(parking_lot)
	_main.set("_parking_lot", parking_lot)

# ── Checkout for current floor (stub — floor builder handles this) ─────────────
func build_checkout_for_current_floor() -> void:
	pass  # checkout counters are built by floor_builder in _build_floor

# ── Sections for current floor (stub — floor builder handles this) ─────────────
func build_sections_for_current_floor() -> void:
	pass  # sections are built by floor_builder in _build_floor

# ── Floor HUD: time, status, shopping list count, XP bar ─────────────────────
func build_floor_hud(idx: int) -> void:
	var time_label = _main.get("_time_label")
	var store_status_label = _main.get("_store_status_label")
	var shopping_list_count_lbl = _main.get("_shopping_list_count_lbl")
	var xp_bar_bg = _main.get("_xp_bar_bg")
	var xp_bar_fill = _main.get("_xp_bar_fill")
	var game_clock = _main.get("_game_clock")
	var player_stats = _main.get("_player_stats")
	var shopping_list = _main.get("_shopping_list")

	if time_label == null:
		time_label = Label.new()
		time_label.name = "TimeLabelHUD"
		time_label.position = Vector2(268.0, 4.0)
		time_label.add_theme_color_override("font_color", Color(0.60, 0.70, 0.90))
		time_label.add_theme_font_size_override("font_size", 8)
		time_label.z_index = 10
		_main.add_child(time_label)
		_main.set("_time_label", time_label)

	if game_clock != null:
		var h = game_clock.game_hour
		var m = game_clock.game_minute
		time_label.text = "%02d:%02d" % [h, m]

	if store_status_label == null:
		store_status_label = Label.new()
		store_status_label.position = Vector2(268.0, 14.0)
		store_status_label.add_theme_color_override("font_color", Color(0.60, 0.90, 0.60))
		store_status_label.add_theme_font_size_override("font_size", 8)
		store_status_label.z_index = 10
		_main.add_child(store_status_label)
		_main.set("_store_status_label", store_status_label)

	if game_clock != null:
		var is_open = game_clock.is_store_open()
		store_status_label.text = "OPEN" if is_open else "CLOSED"
		if is_open:
			store_status_label.add_theme_color_override("font_color", Color(0.50, 0.90, 0.50))
		else:
			store_status_label.add_theme_color_override("font_color", Color(0.90, 0.50, 0.50))

	if shopping_list_count_lbl == null:
		shopping_list_count_lbl = Label.new()
		shopping_list_count_lbl.position = Vector2(268.0, 24.0)
		shopping_list_count_lbl.add_theme_color_override("font_color", Color(0.55, 0.70, 0.90))
		shopping_list_count_lbl.add_theme_font_size_override("font_size", 7)
		shopping_list_count_lbl.z_index = 10
		_main.add_child(shopping_list_count_lbl)
		_main.set("_shopping_list_count_lbl", shopping_list_count_lbl)

	if shopping_list != null:
		var count = shopping_list.get_items().size()
		shopping_list_count_lbl.text = "List: %d" % count if count > 0 else ""

	if xp_bar_bg == null:
		xp_bar_bg = ColorRect.new()
		xp_bar_bg.position = Vector2(4.0, 20.0)
		xp_bar_bg.size = Vector2(70.0, 4.0)
		xp_bar_bg.color = Color(0.15, 0.15, 0.20, 0.80)
		xp_bar_bg.z_index = 10
		_main.add_child(xp_bar_bg)
		_main.set("_xp_bar_bg", xp_bar_bg)

	if xp_bar_fill == null:
		xp_bar_fill = ColorRect.new()
		xp_bar_fill.position = Vector2(4.0, 20.0)
		xp_bar_fill.size = Vector2(0.0, 4.0)
		xp_bar_fill.color = Color(0.40, 0.85, 0.50)
		xp_bar_fill.z_index = 11
		_main.add_child(xp_bar_fill)
		_main.set("_xp_bar_fill", xp_bar_fill)

	if player_stats != null:
		var progress = player_stats.xp_progress()
		xp_bar_fill.size.x = max(0.0, 70.0 * progress)

# ── Floor HUD update ───────────────────────────────────────────────────────────
func update_floor_hud() -> void:
	var floor_label = _main.get("_floor_label")
	var fd = preload("res://scripts/floor_config.gd").get_floor(_main._current_floor_idx)
	if floor_label != null and is_instance_valid(floor_label):
		floor_label.text = "Floor %s · %s" % [fd.label, fd.theme.replace("_", " ").capitalize()]
	else:
		var existing = _main.get_node_or_null("FloorLabelHUD")
		if existing != null:
			_main.set("_floor_label", existing)
			existing.text = "Floor %s · %s" % [fd.label, fd.theme.replace("_", " ").capitalize()]
	update_staff_rank_hud()

# ── Staff rank HUD ────────────────────────────────────────────────────────────
func update_staff_rank_hud() -> void:
	var player_stats = _main.get("_player_stats")
	if player_stats == null:
		return
	var rank_lbl = _main.get_node_or_null("StaffRankLbl")
	if rank_lbl != null:
		rank_lbl.text = "[%s]" % player_stats.get_staff_rank_name()
		var progress = player_stats.get_staff_xp_progress()
		rank_lbl.tooltip_text = "Staff XP: %d/100 progress to next rank" % int(progress * 100)

# ── Build all panels (called from _ready) ─────────────────────────────────────
func build_all() -> void:
	build_elevator()
	build_stairs()
	build_parking()
	update_floor_hud()
