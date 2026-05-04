# toast_manager.gd
# Sliding toast notifications — events slide in from the right, auto-dismiss.
extends CanvasLayer

const MAX_TOASTS := 4
const TOAST_H := 20.0
const TOAST_SPACING := 4.0
const TOAST_W := 160.0
const ANIM_DURATION := 0.25

var _toasts: Array = []   # Array of {label: Label, timer: Timer, alpha: float}

func _ready() -> void:
	pass

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

func show_toast(text: String, color: Color = Color(0.10, 0.10, 0.14, 0.92), duration: float = 2.5) -> void:
	if _toasts.size() >= MAX_TOASTS:
		_dismiss_oldest()
	_build_toast(text, color, duration)

# Convenience helpers
func toast_info(text: String)    -> void: show_toast(text, Color(0.10, 0.14, 0.22, 0.92))
func toast_success(text: String)  -> void: show_toast(text, Color(0.08, 0.18, 0.10, 0.92))
func toast_warn(text: String)    -> void: show_toast(text, Color(0.20, 0.16, 0.06, 0.92))
func toast_error(text: String)    -> void: show_toast(text, Color(0.22, 0.06, 0.06, 0.92))
func toast_xp(text: String)      -> void: show_toast(text, Color(0.18, 0.14, 0.06, 0.92))

# ─────────────────────────────────────────────────────────────────
# Implementation
# ─────────────────────────────────────────────────────────────────

func _build_toast(text: String, color: Color, duration: float) -> void:
	var pan_x := 320.0 - TOAST_W - 4.0   # right edge
	var pan_y := 4.0 + _toasts.size() * (TOAST_H + TOAST_SPACING)

	# Background panel
	var pan := ColorRect.new()
	pan.position = Vector2(pan_x + TOAST_W, pan_y)  # start off-screen right
	pan.size = Vector2(TOAST_W, TOAST_H)
	pan.color = color
	pan.z_index = 500
	add_child(pan)

	# Left accent bar
	var bar := ColorRect.new()
	bar.position = Vector2(pan_x + TOAST_W, pan_y)
	bar.size = Vector2(3, TOAST_H)
	bar.color = Color(0.85, 0.75, 0.30)
	bar.z_index = 501
	add_child(bar)

	# Label
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(pan_x + TOAST_W + 6, pan_y + 3)
	lbl.size = Vector2(TOAST_W - 8, TOAST_H - 4)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.85))
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.z_index = 502
	add_child(lbl)

	var entry := {"pan": pan, "bar": bar, "lbl": lbl, "target_x": pan_x, "y": pan_y, "alpha": 1.0, "dismiss_timer": 0.0, "duration": duration, "dismissing": false}
	_toasts.append(entry)

	# Animate in
	_animate_in(entry)

func _animate_in(entry) -> void:
	# Tween slide in from right
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(entry["pan"], "position:x", entry["target_x"], ANIM_DURATION).set_ease(Tween.EASE_OUT)
	t.tween_property(entry["bar"], "position:x", entry["target_x"], ANIM_DURATION).set_ease(Tween.EASE_OUT)
	t.tween_property(entry["lbl"], "position:x", entry["target_x"] + 6, ANIM_DURATION).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	for entry in _toasts:
		if entry["dismissing"]:
			continue
		entry["dismiss_timer"] += delta
		if entry["dismiss_timer"] >= entry["duration"]:
			_dismiss_toast(entry)

func _dismiss_toast(entry) -> void:
	if entry["dismissing"]:
		return
	entry["dismissing"] = true

	var t := create_tween()
	t.set_parallel(true)
	var off_x := 320.0 + 10.0
	t.tween_property(entry["pan"], "position:x", off_x, ANIM_DURATION).set_ease(Tween.EASE_IN)
	t.tween_property(entry["bar"], "position:x", off_x, ANIM_DURATION).set_ease(Tween.EASE_IN)
	t.tween_property(entry["lbl"], "position:x", off_x, ANIM_DURATION).set_ease(Tween.EASE_IN)
	t.tween_callback(_cleanup_toast.bind(entry)).set_delay(ANIM_DURATION)

func _dismiss_oldest() -> void:
	if _toasts.size() > 0:
		_dismiss_toast(_toasts[0])

func _cleanup_toast(entry) -> void:
	entry["pan"].queue_free()
	entry["bar"].queue_free()
	entry["lbl"].queue_free()
	_toasts.erase(entry)
	# Re-stack remaining toasts
	_reposition_toasts()

func _reposition_toasts() -> void:
func _reposition_toasts() -> void:
	for idx in range(_toasts.size()):
		var new_y := 4.0 + idx * (TOAST_H + TOAST_SPACING)
		entry["bar"].position.y = new_y
		entry["lbl"].position.y = new_y + 3