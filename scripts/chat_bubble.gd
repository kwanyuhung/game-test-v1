# chat_bubble.gd
# Floating chat bubble that appears above an NPC's head.
# ═══════════════════════════════════════════════════════════════════════
# USAGE:
#   var bubble := ChatBubble.new()
#   bubble.show("Hello there!", duration_seconds)
#   add_child(bubble)
#   bubble.position = npc_position + Vector2(0, -30)
# ═══════════════════════════════════════════════════════════════════════
class_name ChatBubble
extends Control

var _label: Label
var _bg: ColorRect
var _timer: float = 0.0
var _duration: float = 4.0

func _init() -> void:
	# Dark semi-transparent background
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.05, 0.10, 0.90)
	add_child(_bg)

	# White text
	_label = Label.new()
	_label.text = ""
	_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_label.add_theme_font_size_override("font_size", 8)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

	z_index = 200

func _ready() -> void:
	size = Vector2(100, 24)

func show(text: String, duration: float = 4.0) -> void:
	_timer = 0.0
	_duration = duration
	_label.text = text
	visible = true

	# Auto-size based on text length
	var text_w := max(80, text.length() * 4 + 20)
	var text_h := 24.0
	size = Vector2(text_w, text_h)
	_bg.size = size
	_label.size = size

	# Fade in
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _duration:
		# Fade out
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(self, "queue_free"))
		set_process(false)
