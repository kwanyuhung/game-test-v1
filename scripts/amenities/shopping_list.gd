# shopping_list.gd
class_name ShoppingList
# Player shopping list — press L to open, add items you want to find.
# Does not consume items, just tracks what player is looking for.
extends CanvasLayer

signal item_added_to_list(product_name: String)
signal closed()

const MAX_ITEMS := 10
const PANEL_W := 160.0
const PANEL_H := 130.0

var _items: Array = []  # Array of {name: String}
var _is_open := false
var _selected_idx := 0
var _list_display: VBoxContainer = null
var _panel: Control = null

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
	closed.emit()

func add_item(product_name: String) -> bool:
	if _items.size() >= MAX_ITEMS:
		return false
	if _items.any(func(e): return e["name"] == product_name):
		return false
	_items.append({"name": product_name})
	_refresh()
	item_added_to_list.emit(product_name)
	return true

func remove_item(idx: int) -> void:
	if idx >= 0 and idx < _items.size():
		_items.remove_at(idx)
		if _selected_idx >= _items.size():
			_selected_idx = maxi(0, _items.size() - 1)
		_refresh()

func get_items() -> Array:
	return _items

func _build_ui() -> void:
	_clear_ui()

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.03, 0.03, 0.06, 0.88)
	ov.gui_input.connect(_on_overlay_input)
	ov.name = "ListOverlay"
	add_child(ov)

	var pan := ColorRect.new()
	pan.name = "ListPanel"
	pan.position = Vector2((320.0 - PANEL_W) * 0.5, (180.0 - PANEL_H) * 0.5)
	pan.size = Vector2(PANEL_W, PANEL_H)
	pan.color = Color(0.09, 0.09, 0.13, 0.95)
	add_child(pan)

	var title := Label.new()
	title.text = "SHOPPING LIST"
	title.position = pan.position + Vector2(6, 4)
	title.add_theme_color_override("font_color", Color(0.90, 0.85, 0.50))
	title.add_theme_font_size_override("font_size", 9)
	title.name = "ListTitle"
	add_child(title)

	var header := Label.new()
	header.text = "Press E to add hovered product"
	header.position = pan.position + Vector2(6, 16)
	header.add_theme_color_override("font_color", Color(0.40, 0.40, 0.48))
	header.add_theme_font_size_override("font_size", 7)
	header.name = "ListHint"
	add_child(header)

	var list_container := VBoxContainer.new()
	list_container.name = "ListContainer"
	list_container.position = pan.position + Vector2(6, 28)
	list_container.size = Vector2(PANEL_W - 12, PANEL_H - 36)
	add_child(list_container)
	_list_display = list_container

func _clear_ui() -> void:
	for c in get_children():
		c.queue_free()
	_list_display = null

func _refresh() -> void:
	if _list_display == null:
		return
	for c in _list_display.get_children():
		c.queue_free()

	if _items.size() == 0:
		var empty := Label.new()
		empty.text = "(empty)"
		empty.add_theme_color_override("font_color", Color(0.35, 0.35, 0.40))
		empty.add_theme_font_size_override("font_size", 8)
		_list_display.add_child(empty)
		return

	for i in range(_items.size()):
		var entry = _items[i]
		var row := HBoxContainer.new()
		row.name = "Row_%d" % i

		var tick := Label.new()
		tick.text = "•" if i == _selected_idx else " "
		tick.add_theme_color_override("font_color", Color(0.90, 0.85, 0.40))
		tick.add_theme_font_size_override("font_size", 8)
		row.add_child(tick)

		var name_lbl := Label.new()
		name_lbl.text = entry["name"]
		name_lbl.size = Vector2(PANEL_W - 30, 10)
		name_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78))
		name_lbl.add_theme_font_size_override("font_size", 8)
		row.add_child(name_lbl)

		var del := Label.new()
		del.text = "X"
		del.add_theme_color_override("font_color", Color(0.60, 0.40, 0.40))
		del.add_theme_font_size_override("font_size", 8)
		del.gui_input.connect(_make_del_click(i))
		row.add_child(del)

		_list_display.add_child(row)

func _make_del_click(idx: int) -> Callable:
	return func(event: InputEvent):
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				remove_item(idx)

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_TAB:
				close()
			KEY_W, KEY_UP:
				_selected_idx = maxi(0, _selected_idx - 1)
				_refresh()
			KEY_S, KEY_DOWN:
				_selected_idx = mini(_items.size() - 1, _selected_idx + 1)
				_refresh()
			KEY_DELETE, KEY_BACKSPACE:
				remove_item(_selected_idx)
