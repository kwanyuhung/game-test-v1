# monitor_panel.gd
# CCTV / Floor Monitoring Panel — shows live status of all floors.
# Press E near the monitor room zone on Floor 7 or 8 to open.
extends Control

signal closed()

const FloorConfig = preload("res://scripts/floor_config.gd")

var _selected_floor: int = 0
var _main: Node = null
var _update_timer := 0.0

func _ready() -> void:
	visible = false
	_build_layout()

func open(main_node: Node) -> void:
	_main = main_node
	visible = true
	z_index = 500
	_update_timer = 0.0
	_update_floor_display()

func close() -> void:
	visible = false
	closed.emit()

func _build_layout() -> void:
	# Dark full-screen overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.02, 0.06, 0.95)
	overlay.gui_input.connect(_on_overlay_input)
	add_child(overlay)

	# Title bar
	var title_bar := ColorRect.new()
	title_bar.set_anchors_preset(Control.PRESET_TOP_LINE_RECT)
	title_bar.offset_left = 0; title_bar.offset_top = 0
	title_bar.offset_right = 900; title_bar.offset_bottom = 40
	title_bar.color = Color(0.08, 0.10, 0.18, 1.0)
	add_child(title_bar)

	var title_lbl := Label.new()
	title_lbl.text = "STORE MONITORING CENTER  —  LIVE FLOOR FEEDS"
	title_lbl.set_anchors_preset(Control.PRESET_CENTER)
	title_lbl.anchor_left = 0.5; title_lbl.anchor_right = 0.5
	title_lbl.offset_left = -200; title_lbl.offset_top = 10
	title_lbl.offset_right = 200; title_lbl.offset_bottom = 34
	title_lbl.add_theme_color_override("font_color", Color(0.30, 0.85, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_lbl)

	# Status indicator
	var status_lbl := Label.new()
	status_lbl.name = "StatusLbl"
	status_lbl.text = "● LIVE"
	status_lbl.set_anchors_preset(Control.PRESET_TOP_LINE_RECT)
	status_lbl.offset_left = 10; status_lbl.offset_top = 12
	status_lbl.offset_right = 100; status_lbl.offset_bottom = 32
	status_lbl.add_theme_color_override("font_color", Color(0.20, 1.0, 0.40))
	status_lbl.add_theme_font_size_override("font_size", 10)
	add_child(status_lbl)

	# Clock display
	var clock_lbl := Label.new()
	clock_lbl.name = "ClockLbl"
	clock_lbl.text = ""
	clock_lbl.set_anchors_preset(Control.PRESET_TOP_LINE_RECT)
	clock_lbl.offset_left = 800; clock_lbl.offset_top = 12
	clock_lbl.offset_right = 890; clock_lbl.offset_bottom = 32
	clock_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 1.0))
	clock_lbl.add_theme_font_size_override("font_size", 10)
	clock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(clock_lbl)

	# Floor grid: 4 columns x 3 rows
	var grid_container := Control.new()
	grid_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid_container.offset_left = 20; grid_container.offset_top = 60
	grid_container.offset_right = -20; grid_container.offset_bottom = -60
	add_child(grid_container)

	var floors := ["G","1","2","3","4","5","6","7","8","9","10","11"]
	var floor_themes := [
		"Lobby / Ground",
		"Shoes",
		"Fashion / Dresses",
		"Sport & Active",
		"Outdoor",
		"Stationery & Plants",
		"Staff Areas",
		"Back Office",
		"Executive Office",
		"Rooftop Cafe",
		"Pet Paradise",
		"Warehouse",
	]
	var floor_colors := [
		Color(0.30, 0.50, 0.35),
		Color(0.55, 0.40, 0.35),
		Color(0.50, 0.35, 0.55),
		Color(0.35, 0.50, 0.60),
		Color(0.38, 0.60, 0.42),
		Color(0.45, 0.58, 0.42),
		Color(0.35, 0.35, 0.40),
		Color(0.38, 0.40, 0.45),
		Color(0.32, 0.32, 0.40),
		Color(0.65, 0.60, 0.48),
		Color(0.40, 0.70, 0.55),
		Color(0.55, 0.45, 0.38),
	]

	for i in range(12):
		var col := i % 4
		var row := i / 4
		var cell := Control.new()
		cell.set_anchors_preset(Control.PRESET_FULL_RECT)
		var cell_w := 1.0 / 4.0
		var cell_h := 1.0 / 3.0
		cell.anchor_left = col * cell_w
		cell.anchor_right = (col + 1) * cell_w
		cell.anchor_top = row * cell_h
		cell.anchor_bottom = (row + 1) * cell_h
		cell.offset_left = 4; cell.offset_right = -4
		cell.offset_top = 4; cell.offset_bottom = -4
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.gui_input.connect(_on_floor_cell_input.bind(i))
		grid_container.add_child(cell)

		# Screen background
		var scr_bg := ColorRect.new()
		scr_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		scr_bg.color = floor_colors[i].darkened(0.5)
		cell.add_child(scr_bg)

		# Header strip
		var hdr := ColorRect.new()
		hdr.set_anchors_preset(Control.PRESET_TOP_LINE_RECT)
		hdr.offset_left = 0; hdr.offset_top = 0
		hdr.offset_right = 0; hdr.offset_bottom = 20
		hdr.color = floor_colors[i].darkened(0.3)
		cell.add_child(hdr)

		# Floor number
		var fl_lbl := Label.new()
		fl_lbl.name = "FloorLbl_%d" % i
		fl_lbl.text = "FL %s" % floors[i]
		fl_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
		fl_lbl.offset_left = 6; fl_lbl.offset_top = 3
		fl_lbl.offset_right = 100; fl_lbl.offset_bottom = 22
		fl_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		fl_lbl.add_theme_font_size_override("font_size", 11)
		cell.add_child(fl_lbl)

		# Active dot
		var dot := ColorRect.new()
		dot.name = "Dot_%d" % i
		dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		dot.offset_left = -28; dot.offset_top = 5
		dot.offset_right = -10; dot.offset_bottom = 17
		dot.color = Color(0.20, 0.90, 0.40)
		cell.add_child(dot)

		# Theme name
		var theme_lbl := Label.new()
		theme_lbl.name = "ThemeLbl_%d" % i
		theme_lbl.text = floor_themes[i]
		theme_lbl.set_anchors_preset(Control.PRESET_TOP_LINE_RECT)
		theme_lbl.offset_left = 6; theme_lbl.offset_top = 22
		theme_lbl.offset_right = 0; theme_lbl.offset_bottom = 40
		theme_lbl.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0))
		theme_lbl.add_theme_font_size_override("font_size", 8)
		cell.add_child(theme_lbl)

		# Mini section blocks (representing different areas)
		var sections_container := Control.new()
		sections_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		sections_container.offset_top = 42; sections_container.offset_bottom = -30
		cell.add_child(sections_container)

		var section_names := _get_section_names_for_floor(i)
		for si in range(section_names.size()):
			var sec_lbl := Label.new()
			sec_lbl.text = section_names[si]
			sec_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			var sec_col := si % 2
			var sec_row := si / 2
			sec_lbl.anchor_left = sec_col * 0.5
			sec_lbl.anchor_right = (sec_col + 1) * 0.5
			sec_lbl.anchor_top = sec_row * 0.5
			sec_lbl.anchor_bottom = (sec_row + 1) * 0.5
			sec_lbl.offset_left = 4; sec_lbl.offset_right = -4
			sec_lbl.offset_top = 2; sec_lbl.offset_bottom = -2
			sec_lbl.add_theme_color_override("font_color", floor_colors[i].lightened(0.4))
			sec_lbl.add_theme_font_size_override("font_size", 7)
			sections_container.add_child(sec_lbl)

		# Stats row at bottom of cell
		var stats_lbl := Label.new()
		stats_lbl.name = "StatsLbl_%d" % i
		stats_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LINE_RECT)
		stats_lbl.offset_left = 4; stats_lbl.offset_top = -28
		stats_lbl.offset_right = -4; stats_lbl.offset_bottom = -4
		stats_lbl.add_theme_color_override("font_color", Color(0.60, 0.80, 0.60))
		stats_lbl.add_theme_font_size_override("font_size", 7)
		cell.add_child(stats_lbl)

		# Stock level bar
		var stock_bar_bg := ColorRect.new()
		stock_bar_bg.set_anchors_preset(Control.PRESET_BOTTOM_LINE_RECT)
		stock_bar_bg.offset_left = 4; stock_bar_bg.offset_top = -12
		stock_bar_bg.offset_right = -4; stock_bar_bg.offset_bottom = -4
		stock_bar_bg.color = Color(0.15, 0.15, 0.20)
		cell.add_child(stock_bar_bg)

		var stock_bar := ColorRect.new()
		stock_bar.name = "StockBar_%d" % i
		stock_bar.set_anchors_preset(Control.PRESET_BOTTOM_LINE_RECT)
		stock_bar.offset_left = 5; stock_bar.offset_top = -11
		stock_bar.offset_right = -5; stock_bar.offset_bottom = -5
		stock_bar.color = Color(0.20, 0.80, 0.40)
		cell.add_child(stock_bar)

	# Bottom bar — hint
	var bottom_bar := ColorRect.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_LINE_RECT)
	bottom_bar.offset_left = 0; bottom_bar.offset_top = -36
	bottom_bar.offset_right = 0; bottom_bar.offset_bottom = 0
	bottom_bar.color = Color(0.05, 0.06, 0.10, 1.0)
	add_child(bottom_bar)

	var hint_lbl := Label.new()
	hint_lbl.text = "[Click a floor to view details]   [ESC or E to close]"
	hint_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LINE_RECT)
	hint_lbl.offset_left = 10; hint_lbl.offset_top = -30
	hint_lbl.offset_right = -10; hint_lbl.offset_bottom = -8
	hint_lbl.add_theme_color_override("font_color", Color(0.40, 0.60, 0.80))
	hint_lbl.add_theme_font_size_override("font_size", 9)
	add_child(hint_lbl)

func _get_section_names_for_floor(floor_idx: int) -> Array:
	var sections := {
		0: ["Lobby", "Info Desk", "ATM", "Food Court"],
		1: ["Ladies Shoes", "Mens Shoes", "Kids Shoes", "Sport"],
		2: ["Ladies Wear", "Mens Wear", "Kids Wear", "Activewear"],
		3: ["Gym Equip", "Sports Gear", "Team Sports", "Fitness"],
		4: ["Fishing", "Hiking", "Running", "Camping"],
		5: ["Stationery", "Office", "Indoor Plants", "Garden"],
		6: ["Locker Room", "Lounge", "Training"],
		7: ["Admin", "HR", "Open Office", "Monitors"],
		8: ["Exec Office", "Board Room", "Secretaries"],
		9: ["Food Court", "Ramen", "Sushi", "Takoyaki"],
		10: ["Adoption", "Pet Food", "Toys"],
		11: ["Receiving", "Storage", "Loading"],
	}
	return sections.get(floor_idx, ["General"])

func _physics_process(delta: float) -> void:
	if not visible:
		return
	_update_timer += delta
	if _update_timer > 2.0:
		_update_timer = 0.0
		_update_floor_display()
	_update_clock()

func _update_clock() -> void:
	if _main == null:
		return
	var clock = _main.get_node_or_null("_game_clock")
	var lbl = get_node_or_null("ClockLbl")
	if clock != null and lbl != null:
		var time_of_day := clock.get("game_hour") if "game_hour" in clock else 12
		var day := clock.get("current_day") if "current_day" in clock else 1
		var ampm := "AM" if time_of_day < 12 else "PM"
		var hour := time_of_day % 12
		if hour == 0: hour = 12
		lbl.text = "Day %d  %02d:00 %s" % [day, hour, ampm]

func _update_floor_display() -> void:
	if _main == null:
		return
	# Update stats for each floor cell
	var customer_counts := _get_customer_counts()
	var stock_levels := _get_stock_levels()
	var issue_counts := _get_issue_counts()

	for i in range(12):
		var stats_lbl := get_node_or_null("StatsLbl_%d" % i)
		if stats_lbl != null:
			var cust := customer_counts[i]
			var issues := issue_counts[i]
			var issue_str := "  ⚠ %d issues" % issues if issues > 0 else ""
			stats_lbl.text = "👥 %d customers%s" % [cust, issue_str]

		# Update stock bar width
		var stock_bar := get_node_or_null("StockBar_%d" % i)
		if stock_bar != null:
			var level := stock_levels[i] as float
			stock_bar.size.x = max(4, (800 - 10) * level)
			stock_bar.color = Color(0.20, 0.80, 0.40) if level > 0.3 else Color(0.90, 0.50, 0.20) if level > 0.1 else Color(0.90, 0.20, 0.20)

func _get_customer_counts() -> Array:
	if _main == null:
		return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var npcs: Array = _main.get("npcs") if "npcs" in _main else []
	var counts := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	for npc in npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var floor := npc.get("current_floor") if "current_floor" in npc else 0
		if floor >= 0 and floor < 12:
			counts[floor] += 1
	return counts

func _get_stock_levels() -> Array:
	if _main == null:
		return [0.8, 0.6, 0.9, 0.5, 0.7, 0.4, 1.0, 1.0, 1.0, 0.6, 0.5, 0.3]
	var wh = _main.get_node_or_null("_warehouse")
	if wh != null and "get_stock_summary" in wh:
		var summary: Dictionary = wh.get("get_stock_summary").call()
		# Return array of stock levels (simplified)
		return [0.8, 0.6, 0.9, 0.5, 0.7, 0.4, 1.0, 1.0, 1.0, 0.6, 0.5, 0.3]
	return [0.8, 0.6, 0.9, 0.5, 0.7, 0.4, 1.0, 1.0, 1.0, 0.6, 0.5, 0.3]

func _get_issue_counts() -> Array:
	if _main == null:
		return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var maint = _main.get_node_or_null("_maintenance_system")
	if maint != null and "get_issue_counts_by_floor" in maint:
		var counts: Array = maint.get("get_issue_counts_by_floor").call()
		return counts if counts.size() == 12 else [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

func _on_floor_cell_input(event: InputEvent, floor_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_floor = floor_idx
		_show_floor_detail(floor_idx)

func _show_floor_detail(floor_idx: int) -> void:
	# For now just log it — detail panel could expand in future
	_selected_floor = floor_idx

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			close()
			get_tree().root.set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_key_pressed(KEY_ESCAPE) or event.is_key_pressed(KEY_E):
		close()
		get_tree().root.set_input_as_handled()
