# chat_bubble.gd
# Floating chat bubble that appears above one or two NPCs' heads.
# ═══════════════════════════════════════════════════════════════════════
# USAGE:
#   var bubble := ChatBubble.new()
#   bubble.display("Hello there!", duration_seconds)
#   add_child(bubble)
#
# For a two-NPC face-to-face conversation call set_anchor_pair(a, b)
# right after add_child — the bubble then sits at the midpoint of the
# two anchors and tracks them every frame, drawing tail lines to each.
#
# For a long-range phone call call set_anchor_single_with_line(a, b) —
# the bubble sits above anchor `a` and draws a single tail line that
# stretches all the way to the receiver `b` (who may be far away).
# ═══════════════════════════════════════════════════════════════════════
class_name ChatBubble
extends Control

const BUBBLE_LIFT := 50.0
const TAIL_COLOR := Color(0.05, 0.05, 0.10, 0.90)
# Offset above the anchor in single-anchor (phone) mode. Higher than
# BUBBLE_LIFT because there's no second anchor pulling the midpoint
# upward; we want the bubble clearly above the caller's head.
const PHONE_LIFT := 40.0

var _label: Label
var _bg: ColorRect
var _tail_a: Line2D = null
var _tail_b: Line2D = null
var _anchor_a: Node2D = null
var _anchor_b: Node2D = null
# Anchor mode: 0=none, 1=pair (face-to-face), 2=phone (single + line).
# Branched in _process to keep the position update clean.
var _anchor_mode: int = 0
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
	_anchor_mode = 1
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
	# Phone mode may have hidden _tail_b previously; make sure both
	# are visible in pair mode.
	if _tail_a != null: _tail_a.visible = true
	if _tail_b != null: _tail_b.visible = true

# Phone-call mode: bubble floats above `anchor` (the caller) and a
# single tail line stretches to `target` (the receiver). The receiver
# may be far away — the line is just a visual hint that "this NPC is
# on a call with that other NPC over there".
func set_anchor_single_with_line(anchor: Node2D, target: Node2D) -> void:
	_anchor_a = anchor
	_anchor_b = target
	_anchor_mode = 2
	# We only need one tail line for phone mode. If _tail_a was already
	# created by a previous pair-mode use, keep it. Hide _tail_b.
	if _tail_a == null:
		_tail_a = Line2D.new()
		_tail_a.width = 1.5
		_tail_a.default_color = TAIL_COLOR
		_tail_a.z_index = 199
		get_parent().add_child(_tail_a)
	if _tail_b != null:
		_tail_b.visible = false

# Renamed from show() to avoid collision with the parent's show().
func display(text: String, duration: float = 4.0) -> void:
	_timer = 0.0
	_duration = duration
	# Prefix phone-mode bubbles with a phone glyph so the visual
	# distinguishes them from face-to-face chat.
	if _anchor_mode == 2:
		_label.text = "☎ " + text
	else:
		_label.text = text
	visible = true

	# Auto-size based on text length
	var text_w :int= max(80, _label.text.length() * 4 + 20)
	var text_h := 24.0
	size = Vector2(text_w, text_h)
	_bg.size = size
	_label.size = size

	# Fade in
	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	# Refresh position now in case anchors were set right after add_child.
	_update_anchor()

func _process(delta: float) -> void:
	_timer += delta
	_update_anchor()
	if _timer >= _duration:
		# Fade out
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(Callable(self, "queue_free"))
		set_process(false)
		if _tail_a != null: _tail_a.queue_free()
		if _tail_b != null: _tail_b.queue_free()

# Position update branched by anchor mode. Pair mode keeps the bubble
# at the midpoint between the two anchors; phone mode keeps it pinned
# above the caller with a single tail line stretching to the receiver.
func _update_anchor() -> void:
	if _anchor_a == null:
		return
	if not is_instance_valid(_anchor_a):
		return
	var parent := get_parent()
	if parent == null:
		return
	var self_pos: Vector2 = parent.global_position
	var pos_a: Vector2 = _anchor_a.global_position
	if _anchor_mode == 1 and _anchor_b != null and is_instance_valid(_anchor_b):
		# Face-to-face: midpoint
		var pos_b: Vector2 = _anchor_b.global_position
		var mid: Vector2 = (pos_a + pos_b) * 0.5
		var new_global: Vector2 = mid + Vector2(0, -BUBBLE_LIFT)
		global_position = new_global
		var tip: Vector2 = Vector2(0, size.y) - (new_global - self_pos)
		if _tail_a != null and is_instance_valid(_tail_a):
			var head_a: Vector2 = pos_a + Vector2(0, -30) - self_pos
			_tail_a.points = [head_a, tip]
		if _tail_b != null and is_instance_valid(_tail_b):
			var head_b: Vector2 = pos_b + Vector2(0, -30) - self_pos
			_tail_b.points = [head_b, tip]
	elif _anchor_mode == 2 and _anchor_b != null and is_instance_valid(_anchor_b):
		# Phone: pinned above caller, line to receiver
		var new_global: Vector2 = pos_a + Vector2(0, -PHONE_LIFT)
		global_position = new_global
		var tip: Vector2 = Vector2(0, size.y) - (new_global - self_pos)
		if _tail_a != null and is_instance_valid(_tail_a):
			var head_a: Vector2 = pos_a + Vector2(0, -30) - self_pos
			var head_b: Vector2 = _anchor_b.global_position + Vector2(0, -30) - self_pos
			_tail_a.points = [head_a, tip, head_b]
