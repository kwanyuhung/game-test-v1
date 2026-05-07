# stats_dashboard.gd
class_name StatsDashboard
# Player stats dashboard — shows level, XP, today's stats.
# Press K to toggle.
extends CanvasLayer

var _is_open := false

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

func _build_ui() -> void:
	_clear_ui()

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.02, 0.02, 0.05, 0.88)
	ov.gui_input.connect(_on_input)
	add_child(ov)

	var pan_x := 80.0
	var pan_y := 35.0
	var pan_w := 160.0
	var pan_h := 110.0

	var pan := ColorRect.new()
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(pan_w, pan_h)
	pan.color = Color(0.08, 0.08, 0.12, 0.95)
	add_child(pan)

	var title := Label.new()
	title.text = "PLAYER STATS"
	title.position = Vector2(pan_x + 6, pan_y + 4)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	title.add_theme_font_size_override("font_size", 9)
	add_child(title)

	var hint := Label.new()
	hint.text = "ESC / K to close"
	hint.position = Vector2(pan_x + 6, pan_y + pan_h - 14)
	hint.add_theme_color_override("font_color", Color(0.30, 0.30, 0.35))
	hint.add_theme_font_size_override("font_size", 7)
	add_child(hint)

func refresh_from_stats(stats) -> void:
	_clear_ui()
	_build_ui()
	if stats == null:
		return

	var pan := get_node_or_null("ColorRect")
	if pan == null:
		for c in get_children():
			if c is ColorRect and c.position.x == 80 and c.position.y == 35:
				pan = c
				break
	if pan == null:
		return

	var y :float= pan.position.y + 20.0

	var xp_next: int = stats.xp_to_next_level if stats.xp_to_next_level > 0 else 1
	var rows := [
		{"label": "Level", "value": "%d" % stats.level},
		{"label": "XP", "value": "%d / %d" % [stats.xp, xp_next]},
		{"label": "Total $", "value": "$%.2f" % stats.total_spent},
		{"label": "Checkouts", "value": "%d" % stats.total_checkouts},
		{"label": "Items Bought", "value": "%d" % stats.total_items_bought},
	]

	for row in rows:
		var lbl := Label.new()
		lbl.text = row["label"] + ": " + row["value"]
		lbl.position = Vector2(pan.position.x + 8, y)
		lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.60))
		lbl.add_theme_font_size_override("font_size", 8)
		add_child(lbl)
		y += 14.0

func _clear_ui() -> void:
	for c in get_children():
		c.queue_free()

func _on_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_ESCAPE, KEY_TAB, KEY_K]:
			close()
