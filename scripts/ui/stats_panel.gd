# stats_panel.gd
# Player statistics dashboard — press P to open.
# Shows level, XP, achievements, lifetime stats, and daily goals.
# ═══════════════════════════════════════════════════════════════════════
class_name StatsPanel
extends CanvasLayer

signal closed()

const PlayerStats = preload("res://scripts/managers/player_stats.gd")

var _stats: PlayerStats = null
var _is_open: bool = false

func _ready() -> void:
	visible = false

func open(stats: PlayerStats) -> void:
	_stats = stats
	_is_open = true
	_build_ui()
	visible = true

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()
	closed.emit()

func _clear_ui() -> void:
	for c in get_children():
		if is_instance_valid(c):
			c.queue_free()

func _build_ui() -> void:
	_clear_ui()
	if _stats == null:
		return

	var scr_w := 320.0
	var scr_h := 180.0
	var pan_x := (scr_w - 240) * 0.5
	var pan_y := (scr_h - 150) * 0.5
	var pan_w := 240.0
	var pan_h := 150.0

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(scr_w, scr_h)
	overlay.color = Color(0, 0, 0, 0.5)
	add_child(overlay)

	# Panel
	var panel := ColorRect.new()
	panel.position = Vector2(pan_x, pan_y)
	panel.size = Vector2(pan_w, pan_h)
	panel.color = Color(0.04, 0.04, 0.09, 0.97)
	add_child(panel)

	# Header
	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(pan_w, 18)
	hdr.color = Color(0.12, 0.12, 0.20)
	add_child(hdr)

	var title_lbl := Label.new()
	title_lbl.text = "  PLAYER STATS"
	title_lbl.position = Vector2(pan_x + 2, pan_y + 3)
	title_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.40))
	title_lbl.add_theme_font_size_override("font_size", 8)
	add_child(title_lbl)

	# Close button (X)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(pan_x + pan_w - 22, pan_y + 1)
	close_btn.size = Vector2(18, 16)
	close_btn.add_theme_color_override("font_color", Color(0.90, 0.60, 0.60))
	close_btn.add_theme_color_override("bg_color", Color(0.30, 0.15, 0.15))
	close_btn.connect("pressed", close)
	add_child(close_btn)

	# Content
	var summary := _stats.get_summary()
	var y := pan_y + 22
	var col1_x := pan_x + 6
	var col2_x := pan_x + 120

	# Level & XP
	_add_stat(col1_x, y, "LEVEL", "%d" % summary["level"], Color(0.90, 0.85, 0.40)); y += 12
	_add_stat(col1_x, y, "XP", "%d / %d" % [summary["xp"], summary["xp_next"]], Color(0.70, 0.80, 0.95)); y += 12
	# XP bar
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(col1_x, y)
	bar_bg.size = Vector2(120, 4)
	bar_bg.color = Color(0.15, 0.15, 0.22)
	add_child(bar_bg)
	var bar_fill := ColorRect.new()
	bar_fill.position = Vector2(col1_x, y)
	bar_fill.size = Vector2(120 * summary["xp_progress"], 4)
	bar_fill.color = Color(0.40, 0.70, 0.95)
	add_child(bar_fill)
	y += 10

	_add_stat(col1_x, y, "TOTAL SPENT", "$%.2f" % summary["total_spent"], Color(0.60, 0.90, 0.65)); y += 12
	_add_stat(col1_x, y, "ITEMS BOUGHT", "%d" % summary["items_bought"], Color(0.80, 0.80, 0.90)); y += 12
	_add_stat(col1_x, y, "UNIQUE ITEMS", "%d" % summary["unique_items"], Color(0.75, 0.70, 0.90)); y += 12
	_add_stat(col1_x, y, "CHECKOUTS", "%d" % summary["checkouts"], Color(0.80, 0.80, 0.90)); y += 12

	# Right column
	var y2 := pan_y + 22
	_add_stat(col2_x, y2, "ISSUES FIXED", "%d" % summary["issues_resolved"], Color(0.90, 0.75, 0.40)); y2 += 12
	_add_stat(col2_x, y2, "TODAY FIXED", "%d" % summary["daily_issues"], Color(0.75, 0.90, 0.50)); y2 += 12
	_add_stat(col2_x, y2, "CLAW WINS", "%d" % summary["claw_wins"], Color(0.90, 0.55, 0.85)); y2 += 12
	_add_stat(col2_x, y2, "PETS ADOPTED", "%d" % summary["pets_adopted"], Color(0.60, 0.85, 0.90)); y2 += 12
	_add_stat(col2_x, y2, "FLOORS VISITED", "%d / 12" % summary["floors_visited"], Color(0.70, 0.90, 0.80)); y2 += 12
	_add_stat(col2_x, y2, "TIME PLAYED", summary["time_played"], Color(0.80, 0.75, 0.90)); y2 += 12
	_add_stat(col2_x, y2, "NPC CHATS", "%d" % summary["chats"], Color(0.75, 0.85, 0.95)); y2 += 12

	# Achievements row
	y2 += 6
	_add_stat(col2_x, y2, "ACHIEVEMENTS",
		"%d / %d" % [summary["ach_unlocked"], summary["ach_total"]],
		Color(0.95, 0.85, 0.40)); y2 += 12

	# Achievement icons
	var ach_y := pan_y + pan_h - 16
	var ach_x := pan_x + 4
	var unlocked: Array = _stats.get_unlocked_achievements()
	var ach_ids := [
		"first_purchase", "full_cart", "issue_fixer", "hero_of_the_floor",
		"collector", "big_spender", "claw_champion", "animal_friend",
		"social_butterfly", "world_explorer", "regular_customer", "supermarket_master"
	]
	var shown := 0
	for aid in ach_ids:
		if shown >= 8:
			break
		if unlocked.has(aid):
			var info: Dictionary = _stats.get_achievement_info(aid)
			var icon_lbl := Label.new()
			icon_lbl.text = info.get("icon", "?")
			icon_lbl.position = Vector2(ach_x + shown * 14, ach_y)
			icon_lbl.add_theme_font_size_override("font_size", 10)
			add_child(icon_lbl)
			shown += 1
		else:
			shown += 1  # count locked too

func _add_stat(x: float, y: float, label: String, value: String, val_color: Color) -> void:
	var lbl := Label.new()
	lbl.text = label
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(110, 12)
	lbl.add_theme_color_override("font_color", Color(0.40, 0.42, 0.52))
	lbl.add_theme_font_size_override("font_size", 6)
	add_child(lbl)

	var val := Label.new()
	val.text = value
	val.position = Vector2(x, y + 7)
	val.size = Vector2(110, 10)
	val.add_theme_color_override("font_color", val_color)
	val.add_theme_font_size_override("font_size", 7)
	add_child(val)

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
			close()
