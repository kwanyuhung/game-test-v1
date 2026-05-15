# fade_transition.gd
class_name FadeTransition
# Screen fade overlay for smooth floor transitions.
extends CanvasLayer

var _overlay: ColorRect = null

func _ready() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.z_index = 1000
	add_child(_overlay)

func fade_out(duration: float = 0.2, then: Callable = Callable()) -> void:
	var t := create_tween()
	t.tween_property(_overlay, "color:a", 1.0, duration)
	t.tween_callback(then)

func fade_in(duration: float = 0.3) -> void:
	var t := create_tween()
	t.tween_property(_overlay, "color:a", 0.0, duration)

func flash(color: Color = Color(1, 1, 1, 0.4), duration: float = 0.15) -> void:
	_overlay.color = Color(color.r, color.g, color.b, color.a)
	var t := create_tween()
	t.tween_property(_overlay, "color:a", 0.0, duration)
