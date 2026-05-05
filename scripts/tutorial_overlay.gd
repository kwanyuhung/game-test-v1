# tutorial_overlay.gd
# First-time player controls tutorial — shown on new game only.
extends CanvasLayer

signal dismissed()

const CONTROLS := [
	["WASD / Arrows", "Move the player"],
	["E", "Interact (browse section / checkout)"],
	["Tab", "Toggle shopping cart panel"],
	["C", "Chat with nearby NPC"],
	["M", "Open Maintenance Panel"],
	["P", "Open Stats Dashboard"],
	["F5", "Quick save"],
	["F5", "Quick save (updated)"],
	["F9", "Quick load"],
	["N", "Toggle mini-map"],
	["L", "Shopping list"],
	["J", "Quest journal"],
	["O", "Settings panel"],
	["ESC", "Close any open panel"],
func _ready() -> void:
	visible = false

func show_tutorial() -> void:
	visible = true
	_build_tutorial_ui()

func _build_tutorial_ui() -> void:
	# Dark overlay
	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.02, 0.02, 0.05, 0.88)
	ov.gui_input.connect(_on_overlay_input)
	add_child(ov)

	# Panel
	var pan := ColorRect.new()
	pan.position = Vector2(60.0, 20.0)
	pan.size = Vector2(200.0, 140.0)
	pan.color = Color(0.08, 0.08, 0.12, 1.0)
	ov.add_child(pan)

	# Title bar
	var title_bar := ColorRect.new()
	title_bar.position = Vector2(60.0, 20.0)
	title_bar.size = Vector2(200.0, 16.0)
	title_bar.color = Color(0.20, 0.18, 0.28, 1.0)
	add_child(title_bar)

	var title := Label.new()
	title.text = "CONTROLS"
	title.position = Vector2(68.0, 22.0)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.60))
	title.add_theme_font_size_override("font_size", 9)
	add_child(title)

	var y := 42.0
	for entry in CONTROLS:
		var key := Label.new()
		key.text = entry[0]
		key.position = Vector2(68.0, y)
		key.size = Vector2(52.0, 10.0)
		key.add_theme_color_override("font_color", Color(0.85, 0.90, 0.80))
		key.add_theme_font_size_override("font_size", 8)
		add_child(key)

		var desc := Label.new()
		desc.text = entry[1]
		desc.position = Vector2(122.0, y)
		desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
		desc.add_theme_font_size_override("font_size", 8)
		add_child(desc)
		y += 11.0

	# Tip at bottom
	var tip := Label.new()
	tip.text = "Press any key to continue..."
	tip.position = Vector2(80.0, 145.0)
	tip.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
	tip.add_theme_font_size_override("font_size", 8)
	add_child(tip)

	# Blink effect using a timer
	var blink_timer := Timer.new()
	blink_timer.wait_time = 0.8
	blink_timer.autostart = true
	blink_timer.connect("timeout", _blink_tip.bind(tip))
	add_child(blink_timer)

func _blink_tip(tip: Label) -> void:
	if tip.visible:
		tip.modulate = Color(1, 1, 1, 0)
	else:
		tip.modulate = Color(1, 1, 1, 1)

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		dismiss()

func dismiss() -> void:
	if not visible:
		return
	visible = false
	# Remove all children
	for c in get_children():
		c.queue_free()
	dismissed.emit()