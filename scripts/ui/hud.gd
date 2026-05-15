# hud.gd — Heads-Up Display
class_name HUD
extends CanvasLayer

const StoreData = preload("res://scripts/world/store_data.gd")

var _cart_count_label: Label
var _zone_label: Label
var _prompt_label: Label
var _cart_panel: Panel
var _cart_open := false
var _cart_items_label: Label
var _cart_total_label: Label
var _cart_ref: Node = null

func _ready() -> void:
	_cart_count_label = Label.new()
	_cart_count_label.text = "Cart: 0"
	_cart_count_label.position = Vector2(6, 4)
	_cart_count_label.add_theme_color_override("font_color", Color(0.90, 0.78, 0.38))
	_cart_count_label.add_theme_font_size_override("font_size", 10)
	add_child(_cart_count_label)
	
	_zone_label = Label.new()
	_zone_label.text = ""
	_zone_label.position = Vector2(120.0, 4.0)
	_zone_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.72))
	_zone_label.add_theme_font_size_override("font_size", 10)
	add_child(_zone_label)
	
	_prompt_label = Label.new()
	_prompt_label.text = ""
	_prompt_label.position = Vector2(110.0, 172.0)
	_prompt_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
	_prompt_label.add_theme_font_size_override("font_size", 9)
	add_child(_prompt_label)
	
	_cart_panel = Panel.new()
	_cart_panel.position = Vector2(80.0, 30.0)
	_cart_panel.size = Vector2(160.0, 120.0)
	
	_cart_panel.visible = false
	add_child(_cart_panel)
	
	var cart_title := Label.new()
	cart_title.text = "Shopping Cart"
	cart_title.position = Vector2(90.0, 34.0)
	cart_title.add_theme_color_override("font_color", Color(0.91, 0.76, 0.44))
	cart_title.add_theme_font_size_override("font_size", 10)
	_cart_panel.add_child(cart_title)
	
	_cart_items_label = Label.new()
	_cart_items_label.text = "(empty)"
	_cart_items_label.position = Vector2(86.0, 50.0)
	_cart_items_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.58))
	_cart_items_label.add_theme_font_size_override("font_size", 8)
	_cart_panel.add_child(_cart_items_label)
	
	_cart_total_label = Label.new()
	_cart_total_label.text = "Total: $0.00"
	_cart_total_label.position = Vector2(86.0, 132.0)
	_cart_total_label.add_theme_color_override("font_color", Color(0.85, 0.72, 0.38))
	_cart_total_label.add_theme_font_size_override("font_size", 9)
	_cart_panel.add_child(_cart_total_label)

func set_cart(cart: Node) -> void:
	_cart_ref = cart

func update_cart_count(count: int) -> void:
	_cart_count_label.text = "Cart: %d" % count

func update_zone(zone_name: String) -> void:
	_zone_label.text = zone_name

func update_prompt(text: String) -> void:
	_prompt_label.text = text

func _process(_delta: float) -> void:
	if _cart_ref != null and _cart_ref.has_method("get_item_count"):
		update_cart_count(_cart_ref.get_item_count())
		if _cart_open:
			_update_cart_panel()

func _update_cart_panel() -> void:
	if _cart_ref == null:
		return
	var items: Array = _cart_ref.get_items()
	if items.size() == 0:
		_cart_items_label.text = "(empty)"
	else:
		var lines: Array = []
		for i in range(mini(items.size(), 8)):
			var p = items[i]
			lines.append("%s $%.2f" % [p.name, p.price])
		if items.size() > 8:
			lines.append("... +%d more" % (items.size() - 8))
		_cart_items_label.text = "\n".join(lines)
	var total: float = _cart_ref.get_total()
	_cart_total_label.text = "Total: $%.2f" % total

func toggle_cart_panel() -> void:
	_cart_open = not _cart_open
	_cart_panel.visible = _cart_open

func is_cart_open() -> bool:
	return _cart_open
