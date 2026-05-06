# business_mode.gd
# Manager-level Business Mode — operational dashboard for running the store.
# Unlocked at StaffRank SUPERVISOR (Rank 4).
class_name BusinessMode
extends Control

const CELL_SIZE := 16

var _tabs: Array = []
var _active_tab: int = 0
var _main: Node = null
var _player_stats = null

# Business data
var _today_sales: float = 0.0
var _today_customers: int = 0
var _staff_on_duty: int = 0
var _stock_alert_count: int = 0
var _shift_schedule: Array = []  # [{shift, staff_name, role}]

func _ready() -> void:
	visible = false

func open(main_ref: Node, player_stats) -> void:
	_main = main_ref
	_player_stats = player_stats
	visible = true
	_build_ui()
	_refresh_data()

func close() -> void:
	visible = false

func _build_ui() -> void:
	# Clear existing children
	for c in get_children():
		c.queue_free()

	# Main panel
	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0.08, 0.09, 0.12, 0.97)
	add_child(panel)

	# Title bar
	var title_bar := ColorRect.new()
	title_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_bar.size = Vector2(0, 36)
	title_bar.color = Color(0.12, 0.14, 0.20)
	add_child(title_bar)

	var title_lbl := Label.new()
	title_lbl.text = "BUSINESS MODE  |  Manager Dashboard"
	title_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.position = Vector2(10, 10)
	add_child(title_lbl)

	var rank_lbl := Label.new()
	var rank_name := "???"
	if _player_stats:
		rank_name = _player_stats.get_staff_rank_name()
	rank_lbl.text = "Your Rank: %s" % rank_name
	rank_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rank_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 0.60))
	rank_lbl.add_theme_font_size_override("font_size", 8)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rank_lbl.position = Vector2(0, 12)
	add_child(rank_lbl)

	# Tab buttons
	var tab_names := ["Overview", "Shifts", "Staff", "Analytics"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = "[%d] %s" % [i + 1, tab_names[i]]
		btn.position = Vector2(10 + i * 100, 40)
		btn.size = Vector2(95, 24)
		btn.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
		btn.add_theme_color_override("bg_color", Color(0.18, 0.22, 0.28) if i != _active_tab else Color(0.20, 0.40, 0.60))
		var captured := i
		btn.pressed.connect(_on_tab_pressed.bind(captured))
		add_child(btn)
		_tabs.append(btn)

	# Content area
	var content := ScrollContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.top_anchor = 0.08
	add_child(content)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(vbox)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "[ESC] Close Business Mode"
	close_btn.position = Vector2(10, 580)
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	_draw_tab_content(vbox)

func _on_tab_pressed(tab_idx: int) -> void:
	_active_tab = tab_idx
	# Update button colors
	for i in range(_tabs.size()):
		var btn: Button = _tabs[i] as Button
		btn.add_theme_color_override("bg_color", Color(0.18, 0.22, 0.28) if i != _active_tab else Color(0.20, 0.40, 0.60))
	# Redraw content
	for c in get_children():
		if c is ScrollContainer:
			c.queue_free()
	var content := ScrollContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.top_anchor = 0.08
	add_child(content)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(vbox)
	_draw_tab_content(vbox)

func _draw_tab_content(vbox: VBoxContainer) -> void:
	match _active_tab:
		0: _draw_overview(vbox)
		1: _draw_shifts(vbox)
		2: _draw_staff(vbox)
		3: _draw_analytics(vbox)

func _refresh_data() -> void:
	_today_sales = 1200.0 + randf() * 800.0
	_today_customers = int(50 + randi() % 100)
	_staff_on_duty = 4 + randi() % 6
	_stock_alert_count = randi() % 5
	_shift_schedule = [
		{"shift": "Morning", "staff": "Alex K.", "role": "Cashier", "status": "On Duty"},
		{"shift": "Morning", "staff": "Sam L.", "role": "Stocker", "status": "On Duty"},
		{"shift": "Morning", "staff": "Robo-Greeter", "role": "HUMANOID Greeter", "status": "Active"},
		{"shift": "Afternoon", "staff": "Jordan M.", "role": "Cashier", "status": "On Duty"},
		{"shift": "Afternoon", "staff": "CleanerBot", "role": "CleanerBot", "status": "Active"},
		{"shift": "Night", "staff": "Taylor R.", "role": "Security", "status": "On Duty"},
	]

func _draw_overview(vbox: VBoxContainer) -> void:
	_add_section_header(vbox, "TODAY'S STORE OVERVIEW")

	# ── Phase N: Real satisfaction data from player_stats ────────────
	var satisfaction := 1.0
	var complaints := 0
	var total_served := 0
	var satisfaction_stars := "*****"
	var sat_bonus := ""
	if _player_stats != null:
		satisfaction = _player_stats.get_customer_satisfaction()
		complaints = _player_stats.get_today_complaints()
		total_served = _player_stats.get_total_customers_served()
		satisfaction_stars = _player_stats.get_satisfaction_stars()
		var bonus :float= _player_stats.get_satisfaction_bonus()
		sat_bonus = " (+%.0f%% XP)" % ((bonus - 1.0) * 100.0)

	var stats := [
		{"label": "Customer Satisfaction", "value": "%s%s" % [satisfaction_stars, sat_bonus], "color": Color(0.30, 0.90, 0.50)},
		{"label": "Customers Served", "value": "%d" % total_served, "color": Color(0.30, 0.60, 0.90)},
		{"label": "Complaints Today", "value": "%d" % complaints, "color": Color(0.90, 0.40, 0.30) if complaints > 0 else Color(0.50, 0.70, 0.50)},
		{"label": "Staff On Duty", "value": "%d" % _staff_on_duty, "color": Color(0.90, 0.70, 0.30)},
		{"label": "Stock Alerts", "value": "%d sections" % _stock_alert_count, "color": Color(0.90, 0.40, 0.30)},
		{"label": "Avg Transaction", "value": "$%.2f" % (_today_sales / max(1, _today_customers)), "color": Color(0.70, 0.60, 0.90)},
		{"label": "Shifts Completed Today", "value": "%d" % (3 if randi() % 2 == 0 else 2), "color": Color(0.60, 0.85, 0.70)},
	]
	for s in stats:
		_add_stat_row(vbox, s["label"], s["value"], s["color"])

	_add_spacer(vbox, 12)
	_add_section_header(vbox, "QUICK ACTIONS")

	var actions := [
		{"label": "[1] Assign Morning Shift", "action": "shift_morning"},
		{"label": "[2] View Staff Performance", "action": "staff_perf"},
		{"label": "[3] Order Emergency Stock", "action": "order_stock"},
		{"label": "[4] Run Staff Meeting", "action": "staff_meeting"},
	]
	for a in actions:
		var btn := Button.new()
		btn.text = a["label"]
		btn.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
		btn.add_theme_color_override("bg_color", Color(0.18, 0.22, 0.28))
		btn.pressed.connect(_on_quick_action.bind(a["action"]))
		vbox.add_child(btn)

	_add_spacer(vbox, 12)
	_add_section_header(vbox, "NOTIFICATIONS")

	var notifications := [
		{"text": "Low stock: Produce section needs restocking", "severity": "warn"},
		{"text": "Robo-Greeter deployed on Floor G", "severity": "info"},
		{"text": "Afternoon shift starts in 30 minutes", "severity": "normal"},
		{"text": "SecurityBot patrol route updated", "severity": "info"},
	]
	for n in notifications:
		var row := HBoxContainer.new()
		var icon := Label.new()
		match n["severity"]:
			"warn": icon.text = "[!]"; icon.add_theme_color_override("font_color", Color(1.0, 0.70, 0.30))
			"info": icon.text = "[i]"; icon.add_theme_color_override("font_color", Color(0.30, 0.70, 1.0))
			_: icon.text = "[>]"; icon.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
		row.add_child(icon)
		var lbl := Label.new()
		lbl.text = n["text"]
		lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
		lbl.add_theme_font_size_override("font_size", 8)
		row.add_child(lbl)
		vbox.add_child(row)

func _draw_shifts(vbox: VBoxContainer) -> void:
	_add_section_header(vbox, "SHIFT SCHEDULE")

	var shifts := ["Morning", "Afternoon", "Night"]
	for shift in shifts:
		var shift_header := Label.new()
		shift_header.text = "━━ %s Shift ━━" % shift
		shift_header.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
		shift_header.add_theme_font_size_override("font_size", 9)
		vbox.add_child(shift_header)
		for entry in _shift_schedule:
			if entry["shift"] == shift:
				var row := HBoxContainer.new()
				var name_lbl := Label.new()
				name_lbl.text = "  %s" % entry["staff"]
				name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
				name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(name_lbl)
				var role_lbl := Label.new()
				role_lbl.text = "%s  " % entry["role"]
				role_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.70))
				row.add_child(role_lbl)
				var status_lbl := Label.new()
				status_lbl.text = entry["status"]
				var sc := Color(0.40, 0.80, 0.50) if entry["status"] == "On Duty" else Color(0.80, 0.60, 0.30)
				status_lbl.add_theme_color_override("font_color", sc)
				row.add_child(status_lbl)
				vbox.add_child(row)

	_add_spacer(vbox, 12)
	var assign_btn := Button.new()
	assign_btn.text = "[A] Assign Staff to Shift"
	assign_btn.add_theme_color_override("font_color", Color(0.80, 0.88, 0.90))
	assign_btn.add_theme_color_override("bg_color", Color(0.18, 0.35, 0.45))
	assign_btn.pressed.connect(_on_quick_action.bind("assign_shift"))
	vbox.add_child(assign_btn)

	var shift_report := Label.new()
	shift_report.text = "\nTip: Complete staff shifts to earn +30 Staff XP and progress toward the next rank!"
	shift_report.add_theme_color_override("font_color", Color(0.50, 0.70, 0.50))
	shift_report.add_theme_font_size_override("font_size", 7)
	vbox.add_child(shift_report)

func _draw_staff(vbox: VBoxContainer) -> void:
	_add_section_header(vbox, "STAFF & ROBOT ROSTER")

	# Human staff (from player_stats)
	var human_header := Label.new()
	human_header.text = "Human Staff  (robots cost XP, humans cost wages)"
	human_header.add_theme_color_override("font_color", Color(0.70, 0.75, 0.80))
	human_header.add_theme_font_size_override("font_size", 8)
	vbox.add_child(human_header)

	var roster := []
	var total_wages := 0.0
	if _player_stats != null:
		roster = _player_stats.get_staff_roster()
		total_wages = _player_stats.get_total_daily_wages()

	if roster.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "  No staff hired yet. Use Hire Staff below."
		empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
		vbox.add_child(empty_lbl)
	else:
		for s in roster:
			var morale_pct := int(s.get("morale", 0.8) * 100.0)
			var morale_str := "OK" if morale_pct >= 70 else "LOW" if morale_pct >= 40 else "CRIT"
			var status_str := "On Duty"
			var perf := int(s.get("morale", 0.8) * 100.0)
			var row := _make_staff_row(s.get("name", "??"), s.get("role", "??"), status_str, perf, morale_str)
			vbox.add_child(row)

	_add_spacer(vbox, 8)

	var payroll_header := Label.new()
	payroll_header.text = "DAILY PAYROLL: $%.2f/day  |  %d staff" % [total_wages, roster.size()]
	payroll_header.add_theme_color_override("font_color", Color(0.90, 0.75, 0.30))
	payroll_header.add_theme_font_size_override("font_size", 9)
	vbox.add_child(payroll_header)

	var perf_bonus := 1.0
	if _player_stats != null:
		perf_bonus = _player_stats.get_staff_performance_bonus()
	var perf_lbl := Label.new()
	perf_lbl.text = "Staff morale bonus: +%.0f%% store performance" % [((perf_bonus - 1.0) * 100.0)]
	perf_lbl.add_theme_color_override("font_color", Color(0.50, 0.80, 0.50))
	perf_lbl.add_theme_font_size_override("font_size", 7)
	vbox.add_child(perf_lbl)

	_add_spacer(vbox, 10)

	var hire_btn := Button.new()
	hire_btn.text = "[H] Hire Staff"
	hire_btn.add_theme_color_override("font_color", Color(0.80, 0.90, 0.80))
	hire_btn.add_theme_color_override("bg_color", Color(0.15, 0.35, 0.20))
	hire_btn.pressed.connect(_on_hire_staff)
	vbox.add_child(hire_btn)

	var fire_btn := Button.new()
	fire_btn.text = "[F] Fire Staff"
	fire_btn.add_theme_color_override("font_color", Color(0.90, 0.70, 0.70))
	fire_btn.add_theme_color_override("bg_color", Color(0.35, 0.15, 0.15))
	fire_btn.pressed.connect(_on_fire_staff)
	vbox.add_child(fire_btn)

	_add_spacer(vbox, 8)
	var tip := Label.new()
	tip.text = "Tip: Happy staff = +20%% performance bonus. Pay wages daily!"
	tip.add_theme_color_override("font_color", Color(0.45, 0.60, 0.45))
	tip.add_theme_font_size_override("font_size", 7)
	vbox.add_child(tip)

func _make_staff_row(name: String, role: String, status: String, perf: int, morale: String = "OK") -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = "  %-18s" % name
	name_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.75))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	var role_lbl := Label.new()
	role_lbl.text = "%-22s" % role
	role_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.70))
	row.add_child(role_lbl)
	var status_lbl := Label.new()
	status_lbl.text = "%-12s" % status
	var sc := Color(0.40, 0.85, 0.50) if status == "On Duty" or status == "Active" else Color(0.55, 0.55, 0.60)
	status_lbl.add_theme_color_override("font_color", sc)
	row.add_child(status_lbl)
	var perf_lbl := Label.new()
	perf_lbl.text = "%d%%" % perf
	var pc := Color(0.40, 0.85, 0.50) if perf >= 80 else Color(0.90, 0.70, 0.30) if perf >= 60 else Color(0.90, 0.40, 0.30)
	perf_lbl.add_theme_color_override("font_color", pc)
	row.add_child(perf_lbl)
	var morale_lbl := Label.new()
	morale_lbl.text = morale
	var mc := Color(0.40, 0.85, 0.50) if morale == "OK" else Color(0.90, 0.70, 0.30) if morale == "LOW" else Color(0.90, 0.40, 0.30)
	morale_lbl.add_theme_color_override("font_color", mc)
	row.add_child(morale_lbl)
	return row

func _draw_analytics(vbox: VBoxContainer) -> void:
	_add_section_header(vbox, "OPERATIONAL ANALYTICS")

	var metrics := [
		{"label": "Busiest Hour", "value": "11:00 AM - 1:00 PM", "note": "Lunch rush"},
		{"label": "Top Section", "value": "Produce", "note": "25% of sales"},
		{"label": "Avg Dwell Time", "value": "18 min", "note": "Per customer"},
		{"label": "Cart Abandon Rate", "value": "12%%", "note": "Below target"},
		{"label": "Scan Accuracy", "value": "97.3%%", "note": "Checkout errors"},
		{"label": "Shelf Stock Rate", "value": "94%%", "note": "In-stock ratio"},
	]
	for m in metrics:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "  %-20s" % m["label"]
		lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.65))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var val := Label.new()
		val.text = "%-22s" % m["value"]
		val.add_theme_color_override("font_color", Color(0.30, 0.90, 0.60))
		row.add_child(val)
		var note := Label.new()
		note.text = "(%s)" % m["note"]
		note.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
		note.add_theme_font_size_override("font_size", 7)
		row.add_child(note)
		vbox.add_child(row)

	_add_spacer(vbox, 12)
	_add_section_header(vbox, "HOURLY TRAFFIC")

	# Simple bar chart using labels
	var hours := ["9AM", "10AM", "11AM", "12PM", "1PM", "2PM", "3PM", "4PM", "5PM", "6PM"]
	var traffic := [30, 55, 90, 100, 85, 60, 70, 80, 95, 70]
	var max_t := 100.0
	for i in range(hours.size()):
		var row := HBoxContainer.new()
		var hour_lbl := Label.new()
		hour_lbl.text = "  %-5s" % hours[i]
		hour_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
		hour_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(hour_lbl)
		var bar_lbl := Label.new()
		var bar_len := int(traffic[i] / max_t * 40.0)
		bar_lbl.text = "|" + "=".repeat(bar_len) + " ".repeat(40 - bar_len) + " %d%%" % traffic[i]
		var bar_color := Color(0.30, 0.75, 0.90) if traffic[i] >= 80 else Color(0.50, 0.55, 0.60)
		bar_lbl.add_theme_color_override("font_color", bar_color)
		bar_lbl.add_theme_font_size_override("font_size", 7)
		row.add_child(bar_lbl)
		vbox.add_child(row)

func _add_section_header(vbox: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(lbl)
	var sep := Label.new()
	sep.text = "-".repeat(50)
	sep.add_theme_color_override("font_color", Color(0.20, 0.22, 0.28))
	sep.add_theme_font_size_override("font_size", 7)
	vbox.add_child(sep)

func _add_stat_row(vbox: VBoxContainer, label: String, value: String, color: Color) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "  %-22s" % label
	lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.65))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var val := Label.new()
	val.text = value
	val.add_theme_color_override("font_color", color)
	val.add_theme_font_size_override("font_size", 10)
	row.add_child(val)
	vbox.add_child(row)

func _add_spacer(vbox: VBoxContainer, px: int) -> void:
	var spacer := Label.new()
	spacer.text = " ".repeat(1)
	spacer.add_theme_font_size_override("font_size", px)
	vbox.add_child(spacer)

func _on_quick_action(action: String) -> void:
	match action:
		"shift_morning":
			if _player_stats:
				_player_stats.complete_staff_task()
			if _main and _main._toasts:
				_main._toasts.toast_success("Morning shift assigned! +5 Staff XP")
		"order_stock":
			if _main and _main._toasts:
				_main._toasts.toast_info("Emergency stock ordered — arriving in 5 minutes!")
		"staff_meeting":
			if _player_stats:
				_player_stats.complete_staff_shift()
			if _main and _main._toasts:
				_main._toasts.toast_success("Staff meeting complete! +30 Staff XP")
		"staff_perf":
			_active_tab = 2
			_on_tab_pressed(2)
		"assign_shift":
			if _main and _main._toasts:
				_main._toasts.toast_info("Open Shifts panel to assign staff to shifts")

func _on_hire_staff() -> void:
	if _player_stats == null:
		return
	var names := ["Alex K.", "Sam L.", "Jordan M.", "Taylor R.", "Morgan P.", "Casey Q.", "Riley S.", "Drew W."]
	var roles := ["Cashier", "Stocker", "Cleaner", "Floor Staff", "Greeter"]
	var wages := [85.0, 75.0, 70.0, 65.0, 70.0]
	var idx_name := randi() % names.size()
	var idx_role := randi() % roles.size()
	var name: String = names[idx_name]  # 添加 : String
	var role: String = roles[idx_role]  # 添加 : String
	var wage: float = wages[idx_role]   # 添加 : float
	_player_stats.hire_staff(name, role, wage)
	if _main and _main._toasts:
		_main._toasts.toast_success("Hired %s as %s! ($%.2f/day)" % [name, role, wage])
	if _main:
		_main.close_business_mode()
		_main.open_business_mode()

func _on_fire_staff() -> void:
	if _player_stats == null:
		return
	var roster: Array = _player_stats.get_staff_roster()
	if roster.is_empty():
		if _main and _main._toasts:
			_main._toasts.toast_warning("No staff to fire!")
		return
	# Fire the last staff member
	var last: Dictionary = roster[roster.size() - 1]
	var name: String = last.get("name", "??")
	if _player_stats.fire_staff(name):
		if _main and _main._toasts:
			_main._toasts.toast_info("Fired %s" % name)
		if _main:
			_main.close_business_mode()
			_main.open_business_mode()

func _on_close() -> void:
	if _main:
		_main.close_business_mode()
