# chat_bubble.gd
# Floating chat bubble that appears above one or two NPCs' heads.
# ═══════════════════════════════════════════════════════════════════════
# USAGE:
#   var bubble := ChatBubble.new()
#   bubble.display("Hello there!", duration_seconds)
#   add_child(bubble)
#
# For a two-NPC conversation call set_anchor_pair(a, b) right after
# add_child — the bubble then sits at the midpoint of the two anchors
# and tracks them every frame, drawing tail lines to each head.
# ═══════════════════════════════════════════════════════════════════════
class_name ChatBubble
extends Control

const BUBBLE_LIFT := 50.0
const TAIL_COLOR := Color(0.05, 0.05, 0.10, 0.90)

var _label: Label
var _bg: ColorRect
var _tail_a: Line2D = null
var _tail_b: Line2D = null
var _anchor_a: Node2D = null
var _anchor_b: Node2D = null
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
	set_process(true)

# Tracks two anchor nodes. The bubble sits at the midpoint above them
# and draws two short tail lines from its bottom edge to each anchor.
func set_anchor_pair(a: Node2D, b: Node2D) -> void:
	_anchor_a = a
	_anchor_b = b
	if _tail_a == null:
		_tail_a = Line2D.new()
		_tail_a.width = 1.5
		_tail_a.default_color = TAIL_COLOR
		_tail_a.z_index = 199
		get_parent().add_child(_tail_a)
	if _tail_b == null:
		_tail_b = Line2D.new()
		_tail_b.width = 1.5
		_tail_b.default_color = TAIL_COLOR
		_tail_b.z_index = 199
		get_parent().add_child(_tail_b)

# Renamed from show() to avoid collision with the parent's show().
func display(text: String, duration: float = 4.0) -> void:
	_timer = 0.0
	_duration = duration
	_label.text = text
	visible = true

	# Auto-size based on text length
	var text_w :int= max(80, text.length() * 4 + 20)
	var text_h := 24.0
	size = Vector2(text_w, text_h)
	_bg.size = size
	_label.size = size

	# Fade in
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	# If pair anchors were set before display, refresh position now
	# (the caller may have set anchors right after add_child).
	_update_pair_anchor()

func _process(delta: float) -> void:
	_timer += delta
	_update_pair_anchor()
	if _timer >= _duration:
		# Fade out
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(self, "queue_free"))
		set_process(false)
		if _tail_a != null: _tail_a.queue_free()
		if _tail_b != null: _tail_b.queue_free()

# Reposition this bubble to the midpoint of the two anchors and
# redraw the tail lines.
func _update_pair_anchor() -> void:
	if _anchor_a == null or _anchor_b == null:
		return
	if not is_instance_valid(_anchor_a) or not is_instance_valid(_anchor_b):
		return
	var parent := get_parent()
	if parent == null:
		return
	var pos_a: Vector2 = _anchor_a.global_position
	var pos_b: Vector2 = _anchor_b.global_position
	var mid: Vector2 = (pos_a + pos_b) * 0.5
	var self_pos: Vector2 = parent.global_position
	var new_global: Vector2 = mid + Vector2(0, -BUBBLE_LIFT)
	global_position = new_global

	# Tail line endpoints are in parent-local space.
	var tip: Vector2 = Vector2(0, size.y) - (new_global - self_pos)
	if _tail_a != null and is_instance_valid(_tail_a):
		var head_a: Vector2 = pos_a + Vector2(0, -30) - self_pos
		_tail_a.points = [head_a, tip]
	if _tail_b != null and is_instance_valid(_tail_b):
		var head_b: Vector2 = pos_b + Vector2(0, -30) - self_pos
		_tail_b.points = [head_b, tip]
