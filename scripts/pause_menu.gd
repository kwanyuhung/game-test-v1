# pause_menu.gd
# Pause overlay — press P or SPACE to pause/resume the game clock.
extends CanvasLayer

var _is_paused := false
var _resume_btn: Label = null

signal paused()
signal resumed()

func _ready() -> void:
	visible = false

func toggle() -> void:
	if _is_paused:
		resume()
	else:
		pause()

func pause() -> void:
	if _is_paused: return
	_is_paused = true
	visible = true
	get_tree().paused = true
	paused.emit()
	_build_ui()

func resume() -> void:
	if not _is_paused: return
	_is_paused = false
	visible = false
	get_tree().paused = false
	resumed.emit()
	_clear_ui()

func is_paused() -> bool:
	return _is_paused

func _build_ui() -> void:
	_clear_ui()

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.02, 0.02, 0.06, 0.90)
	ov.gui_input.connect(_on_input)
	add_child(ov)

	var pan_x := 80.0
	var pan_y := 50.0
	var pan_w := 160.0
	var pan_h := 80.0

	var pan := ColorRect.new()
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(pan_w, pan_h)
	pan.color = Color(0.08, 0.08, 0.12, 0.95)
	add_child(pan)

	var title := Label.new()
	title.text = "PAUSED"
	title.position = Vector2(pan_x + 50, pan_y + 8)
	title.add_theme_color_override("font_color", Color(0.90, 0.90, 0.95))
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_font_style_override("font_style", Label.TEXT_SERVER_SETTINGS_FONT_BOLD)
	add_child(title)

	var hint := Label.new()
	hint.text = "P or SPACE to resume"
	hint.position = Vector2(pan_x + 20, pan_y + 32)
	hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	hint.add_theme_font_size_override("font_size", 8)
	add_child(hint)

	var tip := Label.new()
	tip.text = "Use F5/F9 to save/load"
	tip.position = Vector2(pan_x + 20, pan_y + 50)
	tip.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
	tip.add_theme_font_size_override("font_size", 7)
	add_child(tip)

func _clear_ui() -> void:
	for c in get_children():
		c.queue_free()

func _on_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_P, KEY_SPACE, KEY_ESCAPE]:
			resume()
