# quest_journal.gd
class_name QuestJournal
# Quest journal panel — shows today's quests and progress. Press J to toggle.
extends CanvasLayer

var _is_open := false
var _quest_system_ref = null

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
	_refresh()

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()

func set_quest_system(qs) -> void:
	_quest_system_ref = qs

func _build_ui() -> void:
	_clear_ui()

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.03, 0.03, 0.06, 0.88)
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
	title.text = "TODAY'S QUESTS"
	title.position = Vector2(pan_x + 6, pan_y + 4)
	title.add_theme_color_override("font_color", Color(0.90, 0.80, 0.40))
	title.add_theme_font_size_override("font_size", 9)
	add_child(title)

	# Close button (X)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(pan_x + pan_w - 24, pan_y + 2)
	close_btn.size = Vector2(20, 18)
	close_btn.add_theme_color_override("font_color", Color(0.90, 0.60, 0.60))
	close_btn.add_theme_color_override("bg_color", Color(0.30, 0.15, 0.15))
	close_btn.connect("pressed", close)
	add_child(close_btn)

func _refresh() -> void:
	# Remove old quest rows
	for c in get_children():
		if c is Label and c.position.y > 30:
			c.queue_free()

	if _quest_system_ref == null:
		return

	var quests = _quest_system_ref.get_daily_quests()
	var pan := get_node_or_null("JournalPanel")
	if pan == null:
		# Find the panel by its color
		for c in get_children():
			if c is ColorRect and c.position.x == 60 and c.position.y == 30:
				pan = c
				break
	if pan == null:
		return

	var y := 24.0
	for q in quests:
		var qid = q["id"]
		var desc = q["desc"]
		var target = q["target"]
		var current = _quest_system_ref.get_quest_progress(qid)
		var done = _quest_system_ref.is_completed(qid)

		var row := Label.new()
		row.position = Vector2(pan.position.x + 6, pan.position.y + y)
		row.size = Vector2(pan.size.x - 12, 12)
		if done:
			row.text = "[X] " + desc
			row.add_theme_color_override("font_color", Color(0.45, 0.80, 0.45))
		else:
			row.text = "[ ] " + desc + " (%d/%d)" % [current, target]
			row.add_theme_color_override("font_color", Color(0.65, 0.65, 0.60))
		row.add_theme_font_size_override("font_size", 8)
		add_child(row)
		y += 14.0

	var hint := Label.new()
	hint.position = Vector2(pan.position.x + 6, pan.position.y + pan.size.y - 14)
	hint.text = "ESC / J to close"
	hint.add_theme_color_override("font_color", Color(0.30, 0.30, 0.35))
	hint.add_theme_font_size_override("font_size", 7)
	add_child(hint)

func _clear_ui() -> void:
	for c in get_children():
		c.queue_free()

func _on_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_ESCAPE, KEY_TAB, KEY_J]:
			close()
