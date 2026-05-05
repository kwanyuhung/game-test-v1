# product_tooltip.gd
# Small tooltip that appears near the cursor when a product is hovered
# in the section browse or food stall browse panels.
extends CanvasLayer

var _label: Label = null
var _bg: ColorRect = null

func _ready() -> void:
	visible = false

func show_tooltip(product_name: String, price: float, section_name: String = "") -> void:
	if _label == null:
		_label = Label.new()
		_label.add_theme_font_size_override("font_size", 7)
		_label.z_index = 600
		add_child(_label)
	if _bg == null:
		_bg = ColorRect.new()
		_bg.z_index = 599
		add_child(_bg)

	var text := product_name
	if section_name != "":
		text += " [%s]" % section_name
	text += "  $%.2f" % price

	_label.text = text
	_label.visible = true
	visible = true

	var w := 80.0 + product_name.length() * 3.5
	var h := 16.0
	_bg.size = Vector2(w, h)
	_bg.color = Color(0.06, 0.06, 0.09, 0.92)

func position_near(pos: Vector2) -> void:
	if _bg != null:
		_bg.position = pos
	if _label != null:
		_label.position = pos + Vector2(3, 2)

func hide_tooltip() -> void:
	visible = false
	if _label != null:
		_label.visible = false
	if _bg != null:
		_bg.visible = false
