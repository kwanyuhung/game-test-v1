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
\tvisible = false

func open(main_ref: Node, player_stats) -> void:
\t_main = main_ref
\t_player_stats = player_stats
\tvisible = true
\t_build_ui()
\t_refresh_data()

func close() -> void:
\tvisible = false

func _build_ui() -> void:
\t# Clear existing children
\tfor c in get_children():
\t\tc.queue_free()

\t# Main panel
\tvar panel := ColorRect.new()
\tpanel.set_anchors_preset(Control.PRESET_FULL_RECT)
\tpanel.color = Color(0.08, 0.09, 0.12, 0.97)
\tadd_child(panel)

\t# Title bar
\tvar title_bar := ColorRect.new()
\ttitle_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
\ttitle_bar.size = Vector2(0, 36)
\ttitle_bar.color = Color(0.12, 0.14, 0.20)
\tadd_child(title_bar)

\tvar title_lbl := Label.new()
\ttitle_lbl.text = "BUSINESS MODE  |  Manager Dashboard"
\ttitle_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
\ttitle_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
\ttitle_lbl.add_theme_font_size_override("font_size", 11)
\ttitle_lbl.position = Vector2(10, 10)
\tadd_child(title_lbl)

\tvar rank_lbl := Label.new()
\tvar rank_name := "???"
\tif _player_stats:
\t\trank_name = _player_stats.get_staff_rank_name()
\trank_lbl.text = "Your Rank: %s" % rank_name
\trank_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
\trank_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 0.60))
\trank_lbl.add_theme_font_size_override("font_size", 8)
\trank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
\trank_lbl.position = Vector2(0, 12)
\tadd_child(rank_lbl)

\t# Tab buttons
\tvar tab_names := ["Overview", "Shifts", "Staff", "Analytics"]
\tfor i in range(tab_names.size()):
\t\tvar btn := Button.new()
\t\tbtn.text = "[%d] %s" % [i + 1, tab_names[i]]
\t\tbtn.position = Vector2(10 + i * 100, 40)
\t\tbtn.size = Vector2(95, 24)
\t\tbtn.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
\t\tbtn.add_theme_color_override("bg_color", Color(0.18, 0.22, 0.28) if i != _active_tab else Color(0.20, 0.40, 0.60))
\t\tvar captured := i
\t\tbtn.pressed.connect(_on_tab_pressed.bind(captured))
\t\tadd_child(btn)
\t\t_tabs.append(btn)

\t# Content area
\tvar content := ScrollContainer.new()
\tcontent.set_anchors_preset(Control.PRESET_FULL_RECT)
\tcontent.top_anchor = 0.08
\tadd_child(content)

\tvar vbox := VBoxContainer.new()
\tvbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tcontent.add_child(vbox)

\t# Close button
\tvar close_btn := Button.new()
\tclose_btn.text = "[ESC] Close Business Mode"
\tclose_btn.position = Vector2(10, 580)
\tclose_btn.connect("pressed", _on_close)
\tadd_child(close_btn)

\t_draw_tab_content(vbox)

func _on_tab_pressed(tab_idx: int) -> void:
\t_active_tab = tab_idx
\t# Update button colors
\tfor i in range(_tabs.size()):
\t\tvar btn: Button = _tabs[i] as Button
\t\tbtn.add_theme_color_override("bg_color", Color(0.18, 0.22, 0.28) if i != _active_tab else Color(0.20, 0.40, 0.60))
\t# Redraw content
\tfor c in get_children():
\t\tif c is ScrollContainer:
\t\t\tc.queue_free()
\tvar content := ScrollContainer.new()
\tcontent.set_anchors_preset(Control.PRESET_FULL_RECT)
\tcontent.top_anchor = 0.08
\tadd_child(content)
\tvar vbox := VBoxContainer.new()
\tvbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\tcontent.add_child(vbox)
\t_draw_tab_content(vbox)

func _draw_tab_content(vbox: VBoxContainer) -> void:
\tmatch _active_tab:
\t\t0: _draw_overview(vbox)
\t\t1: _draw_shifts(vbox)
\t\t2: _draw_staff(vbox)
\t\t3: _draw_analytics(vbox)

func _refresh_data() -> void:
\t_today_sales = 1200.0 + randf() * 800.0
\t_today_customers = int(50 + randi() % 100)
\t_staff_on_duty = 4 + randi() % 6
\t_stock_alert_count = randi() % 5
\t_shift_schedule = [
\t\t{\"shift\": \"Morning\", \"staff\": \"Alex K.\", \"role\": \"Cashier\", \"status\": \"On Duty\"},
\t\t{\"shift\": \"Morning\", \"staff\": \"Sam L.\", \"role\": \"Stocker\", \"status\": \"On Duty\"},
\t\t{\"shift\": \"Morning\", \"staff\": \"Robo-Greeter\", \"role\": \"HUMANOID Greeter\", \"status\": \"Active\"},
\t\t{\"shift\": \"Afternoon\", \"staff\": \"Jordan M.\", \"role\": \"Cashier\", \"status\": \"On Duty\"},
\t\t{\"shift\": \"Afternoon\", \"staff\": \"CleanerBot\", \"role\": \"CleanerBot\", \"status\": \"Active\"},
\t\t{\"shift\": \"Night\", \"staff\": \"Taylor R.\", \"role\": \"Security\", \"status\": \"On Duty\"},
\t]

func _draw_overview(vbox: VBoxContainer) -> void:
\t_add_section_header(vbox, "TODAY'S STORE OVERVIEW")

\tvar stats := [
\t\t{\"label\": \"Sales Today\", \"value\": \"$%.2f\" % _today_sales, \"color\": Color(0.30, 0.90, 0.50)},
\t\t{\"label\": \"Customers Served\", \"value\": \"%d\" % _today_customers, \"color\": Color(0.30, 0.60, 0.90)},
\t\t{\"label\": \"Staff On Duty\", \"value\": \"%d\" % _staff_on_duty, \"color\": Color(0.90, 0.70, 0.30)},
\t\t{\"label\": \"Stock Alerts\", \"value\": \"%d sections\" % _stock_alert_count, \"color\": Color(0.90, 0.40, 0.30)},
\t\t{\"label\": \"Avg Transaction\", \"value\": \"$%.2f\" % (_today_sales / max(1, _today_customers)), \"color\": Color(0.70, 0.60, 0.90)},
\t\t{\"label\": \"Shifts Completed Today\", \"value\": \"%d\" % (3 if randi() % 2 == 0 else 2), \"color\": Color(0.60, 0.85, 0.70)},
\t]
\tfor s in stats:
\t\t_add_stat_row(vbox, s["label"], s["value"], s["color"])

\t_add_spacer(vbox, 12)
\t_add_section_header(vbox, "QUICK ACTIONS")

\tvar actions := [
\t\t{\"label\": \"[1] Assign Morning Shift\", \"action\": \"shift_morning\"},
\t\t{\"label\": \"[2] View Staff Performance\", \"action\": \"staff_perf\"},
\t\t{\"label\": \"[3] Order Emergency Stock\", \"action\": \"order_stock\"},
\t\t{\"label\": \"[4] Run Staff Meeting\", \"action\": \"staff_meeting\"},
\t]
\tfor a in actions:
\t\tvar btn := Button.new()
\t\tbtn.text = a["label"]
\t\tbtn.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
\t\tbtn.add_theme_color_override("bg_color", Color(0.18, 0.22, 0.28))
\t\tbtn.pressed.connect(_on_quick_action.bind(a["action"]))
\t\tvbox.add_child(btn)

\t_add_spacer(vbox, 12)
\t_add_section_header(vbox, "NOTIFICATIONS")

\tvar notifications := [
\t\t{\"text\": \"Low stock: Produce section needs restocking\", \"severity\": \"warn\"},
\t\t{\"text\": \"Robo-Greeter deployed on Floor G\", \"severity\": \"info\"},
\t\t{\"text\": \"Afternoon shift starts in 30 minutes\", \"severity\": \"normal\"},
\t\t{\"text\": \"SecurityBot patrol route updated\", \"severity\": \"info\"},
\t]
\tfor n in notifications:
\t\tvar row := HBoxContainer.new()
\t\tvar icon := Label.new()
\t\tmatch n["severity"]:
\t\t\t\"warn\": icon.text = \"[!]\"; icon.add_theme_color_override("font_color", Color(1.0, 0.70, 0.30))
\t\t\t\"info\": icon.text = \"[i]\"; icon.add_theme_color_override("font_color", Color(0.30, 0.70, 1.0))
\t\t\t_: icon.text = \"[>]\"; icon.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
\t\trow.add_child(icon)
\t\tvar lbl := Label.new()
\t\tlbl.text = n["text"]
\t\tlbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
\t\tlbl.add_theme_font_size_override("font_size", 8)
\t\trow.add_child(lbl)
\t\tvbox.add_child(row)

func _draw_shifts(vbox: VBoxContainer) -> void:
\t_add_section_header(vbox, "SHIFT SCHEDULE")

\tvar shifts := [\"Morning\", \"Afternoon\", \"Night\"]
\tfor shift in shifts:
\t\tvar shift_header := Label.new()
\t\tshift_header.text = "━━ %s Shift ━━" % shift
\t\tshift_header.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
\t\tshift_header.add_theme_font_size_override("font_size", 9)
\t\tvbox.add_child(shift_header)
\t\tfor entry in _shift_schedule:
\t\t\tif entry["shift"] == shift:
\t\t\t\tvar row := HBoxContainer.new()
\t\t\t\tvar name_lbl := Label.new()
\t\t\t\tname_lbl.text = "  %s" % entry["staff"]
\t\t\t\tname_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
\t\t\t\tname_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\t\t\t\trow.add_child(name_lbl)
\t\t\t\tvar role_lbl := Label.new()
\t\t\t\trole_lbl.text = "%s  " % entry["role"]
\t\t\t\trole_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.70))
\t\t\t\trow.add_child(role_lbl)
\t\t\t\tvar status_lbl := Label.new()
\t\t\t\tstatus_lbl.text = entry["status"]
\t\t\t\tvar sc := Color(0.40, 0.80, 0.50) if entry["status"] == \"On Duty\" else Color(0.80, 0.60, 0.30)
\t\t\t\tstatus_lbl.add_theme_color_override("font_color", sc)
\t\t\t\trow.add_child(status_lbl)
\t\t\t\tvbox.add_child(row)

\t_add_spacer(vbox, 12)
\tvar assign_btn := Button.new()
\tassign_btn.text = "[A] Assign Staff to Shift"
\tassign_btn.add_theme_color_override("font_color", Color(0.80, 0.88, 0.90))
\tassign_btn.add_theme_color_override("bg_color", Color(0.18, 0.35, 0.45))
\tassign_btn.pressed.connect(_on_quick_action.bind("assign_shift"))
\tvbox.add_child(assign_btn)

\tvar shift_report := Label.new()
\tshift_report.text = "\nTip: Complete staff shifts to earn +30 Staff XP and progress toward the next rank!"
\tshift_report.add_theme_color_override("font_color", Color(0.50, 0.70, 0.50))
\tshift_report.add_theme_font_size_override("font_size", 7)
\tvbox.add_child(shift_report)

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
\tvar row := HBoxContainer.new()
\tvar name_lbl := Label.new()
\tname_lbl.text = "  %-18s" % name
\tname_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.75))
\tname_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\trow.add_child(name_lbl)
\tvar role_lbl := Label.new()
\trole_lbl.text = "%-22s" % role
\trole_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.70))
\trow.add_child(role_lbl)
\tvar status_lbl := Label.new()
\tstatus_lbl.text = "%-12s" % status
\tvar sc := Color(0.40, 0.85, 0.50) if status == \"On Duty\" or status == \"Active\" else Color(0.55, 0.55, 0.60)
\tstatus_lbl.add_theme_color_override("font_color", sc)
\trow.add_child(status_lbl)
\tvar perf_lbl := Label.new()
\tperf_lbl.text = \"%d%%\" % perf
\tvar pc := Color(0.40, 0.85, 0.50) if perf >= 80 else Color(0.90, 0.70, 0.30) if perf >= 60 else Color(0.90, 0.40, 0.30)
\tperf_lbl.add_theme_color_override("font_color", pc)
\trow.add_child(perf_lbl)
	var morale_lbl := Label.new()
	morale_lbl.text = morale
	var mc := Color(0.40, 0.85, 0.50) if morale == "OK" else Color(0.90, 0.70, 0.30) if morale == "LOW" else Color(0.90, 0.40, 0.30)
	morale_lbl.add_theme_color_override("font_color", mc)
	row.add_child(morale_lbl)
\treturn row

func _draw_analytics(vbox: VBoxContainer) -> void:
\t_add_section_header(vbox, "OPERATIONAL ANALYTICS")

\tvar metrics := [
\t\t{\"label\": \"Busiest Hour\", \"value\": \"11:00 AM - 1:00 PM\", \"note\": \"Lunch rush\"},
\t\t{\"label\": \"Top Section\", \"value\": \"Produce\", \"note\": \"25% of sales\"},
\t\t{\"label\": \"Avg Dwell Time\", \"value\": \"18 min\", \"note\": \"Per customer\"},
\t\t{\"label\": \"Cart Abandon Rate\", \"value\": \"12%%\", \"note\": \"Below target\"},
\t\t{\"label\": \"Scan Accuracy\", \"value\": \"97.3%%\", \"note\": \"Checkout errors\"},
\t\t{\"label\": \"Shelf Stock Rate\", \"value\": \"94%%\", \"note\": \"In-stock ratio\"},
\t]
\tfor m in metrics:
\t\tvar row := HBoxContainer.new()
\t\tvar lbl := Label.new()
\t\tlbl.text = \"  %-20s\" % m["label"]
\t\tlbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.65))
\t\tlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\t\trow.add_child(lbl)
\t\tvar val := Label.new()
\t\tval.text = \"%-22s\" % m["value"]
\t\tval.add_theme_color_override("font_color", Color(0.30, 0.90, 0.60))
\t\trow.add_child(val)
\t\tvar note := Label.new()
\t\tnote.text = \"(%s)\" % m["note"]
\t\tnote.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
\t\tnote.add_theme_font_size_override("font_size", 7)
\t\trow.add_child(note)
\t\tvbox.add_child(row)

\t_add_spacer(vbox, 12)
\t_add_section_header(vbox, "HOURLY TRAFFIC")

\t# Simple bar chart using labels
\tvar hours := [\"9AM\", \"10AM\", \"11AM\", \"12PM\", \"1PM\", \"2PM\", \"3PM\", \"4PM\", \"5PM\", \"6PM\"]
\tvar traffic := [30, 55, 90, 100, 85, 60, 70, 80, 95, 70]
\tvar max_t := 100.0
\tfor i in range(hours.size()):
\t\tvar row := HBoxContainer.new()
\t\tvar hour_lbl := Label.new()
\t\thour_lbl.text = \"  %-5s\" % hours[i]
\t\thour_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.65))
\t\thour_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\t\trow.add_child(hour_lbl)
\t\tvar bar_lbl := Label.new()
\t\tvar bar_len := int(traffic[i] / max_t * 40.0)
\t\tbar_lbl.text = \"|\" + \"=\".repeat(bar_len) + \" \".repeat(40 - bar_len) + \" %d%%\" % traffic[i]
\t\tvar bar_color := Color(0.30, 0.75, 0.90) if traffic[i] >= 80 else Color(0.50, 0.55, 0.60)
\t\tbar_lbl.add_theme_color_override("font_color", bar_color)
\t\tbar_lbl.add_theme_font_size_override("font_size", 7)
\t\trow.add_child(bar_lbl)
\t\tvbox.add_child(row)

func _add_section_header(vbox: VBoxContainer, text: String) -> void:
\tvar lbl := Label.new()
\tlbl.text = text
\tlbl.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
\tlbl.add_theme_font_size_override("font_size", 9)
\tvbox.add_child(lbl)
\tvar sep := Label.new()
\tsep.text = \"─\".repeat(50)
\tsep.add_theme_color_override("font_color", Color(0.20, 0.22, 0.28))
\tsep.add_theme_font_size_override("font_size", 7)
\tvbox.add_child(sep)

func _add_stat_row(vbox: VBoxContainer, label: String, value: String, color: Color) -> void:
\tvar row := HBoxContainer.new()
\tvar lbl := Label.new()
\tlbl.text = \"  %-22s\" % label
\tlbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.65))
\tlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
\trow.add_child(lbl)
\tvar val := Label.new()
\tval.text = value
\tval.add_theme_color_override("font_color", color)
\tval.add_theme_font_size_override("font_size", 10)
\trow.add_child(val)
\tvbox.add_child(row)

func _add_spacer(vbox: VBoxContainer, px: int) -> void:
\tvar spacer := Label.new()
\tspacer.text = \" \".repeat(1)
\tspacer.add_theme_font_size_override(\"font_size\", px)
\tvbox.add_child(spacer)

func _on_quick_action(action: String) -> void:
\tmatch action:
\t\t\"shift_morning\":
\t\t\tif _player_stats:\n\t\t\t\t_player_stats.complete_staff_task()\n\t\t\tif _main and _main._toasts:\n\t\t\t\t_main._toasts.toast_success(\"Morning shift assigned! +5 Staff XP\")
\t\t\"order_stock\":
\t\t\tif _main and _main._toasts:\n\t\t\t\t_main._toasts.toast_info(\"Emergency stock ordered — arriving in 5 minutes!\")
\t\t\"staff_meeting\":
\t\t\tif _player_stats:\n\t\t\t\t_player_stats.complete_staff_shift()\n\t\t\tif _main and _main._toasts:\n\t\t\t\t_main._toasts.toast_success(\"Staff meeting complete! +30 Staff XP\")
\t\t\"staff_perf\":\n\t\t\t_active_tab = 2\n\t\t\t_on_tab_pressed(2)
\t\t\"assign_shift\":
\t\t\tif _main and _main._toasts:\n\t\t\t\t_main._toasts.toast_info(\"Open Shifts panel to assign staff to shifts\")

func _on_hire_staff() -> void:
	if _player_stats == null:
		return
	var names := ["Alex K.", "Sam L.", "Jordan M.", "Taylor R.", "Morgan P.", "Casey Q.", "Riley S.", "Drew W."]
	var roles := ["Cashier", "Stocker", "Cleaner", "Floor Staff", "Greeter"]
	var wages := [85.0, 75.0, 70.0, 65.0, 70.0]
	var idx_name := randi() % names.size()
	var idx_role := randi() % roles.size()
	var name := names[idx_name]
	var role := roles[idx_role]
	var wage := wages[idx_role]
	_player_stats.hire_staff(name, role, wage)
	if _toasts:
		_toasts.toast_success("Hired %s as %s! ($%.2f/day)" % [name, role, wage])
	if _main:
		_main.close_business_mode()
		_main.open_business_mode()

func _on_fire_staff() -> void:
	if _player_stats == null:
		return
	var roster := _player_stats.get_staff_roster()
	if roster.is_empty():
		if _toasts:
			_toasts.toast_warning("No staff to fire!")
		return
	# Fire the last staff member
	var last := roster[roster.size() - 1]
	var name := last.get("name", "??")
	if _player_stats.fire_staff(name):
		if _toasts:
			_toasts.toast_info("Fired %s" % name)
		if _main:
			_main.close_business_mode()
			_main.open_business_mode()

func _on_close() -> void:
\tif _main:
\t\t_main.close_business_mode()
