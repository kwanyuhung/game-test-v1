# hud.gd
# Heads-Up Display - interaction prompt, cart badge, zone name.

class_name HUD
extends CanvasLayer

signal tab_pressed
signal checkout_complete

var _interact_label: Label
var _cart_badge: Label
var _zone_label: Label

var _cart_instance: Control = null
var _checkout_instance: Control = null
var _checkout_visible := false

func _ready() -> void:
	_interact_label = Label.new()
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_interact_label.add_theme_font_size_override("font_size", 12)
	_interact_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.91))
	_interact_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_interact_label.offset_top = -36
	_interact_label.size = Vector2(320, 20)
	add_child(_interact_label)
	
	_cart_badge = Label.new()
	_cart_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_cart_badge.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_cart_badge.add_theme_font_size_override("font_size", 14)
	_cart_badge.add_theme_color_override("font_color", Color(0.94, 0.94, 0.91))
	_cart_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_cart_badge.offset_left = 8
	_cart_badge.offset_top = 8
	_cart_badge.offset_right = 120
	_cart_badge.offset_bottom = 30
	add_child(_cart_badge)
	update_cart_badge(0)
	
	_zone_label = Label.new()
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_zone_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_zone_label.add_theme_font_size_override("font_size", 11)
	_zone_label.add_theme_color_override("font_color", Color(0.70, 0.70, 0.65))
	_zone_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_zone_label.offset_left = -120
	_zone_label.offset_top = 8
	_zone_label.offset_right = -8
	_zone_label.offset_bottom = 30
	add_child(_zone_label)
	
	var hint := Label.new()
	hint.text = "WASD: Move   E: Interact   TAB: Cart   ESC: Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.42))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 8
	hint.offset_bottom = -8
	hint.offset_right = 300
	hint.offset_top = -28
	add_child(hint)

func update_cart_badge(count: int) -> void:
	_cart_badge.text = "[Cart: %d]" % count

func update_interact_prompt(text: String) -> void:
	_interact_label.text = text

func update_zone(zone_name: String) -> void:
	_zone_label.text = zone_name

func show_cart(cart: ShoppingCart) -> void:
	if _cart_instance != null:
		_cart_instance.queue_free()
	_cart_instance = _build_cart_panel(cart)
	_cart_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_cart_instance)

func hide_cart() -> void:
	if _cart_instance != null:
		_cart_instance.queue_free()
		_cart_instance = null

func show_checkout(cart: ShoppingCart) -> void:
	if _checkout_instance != null:
		_checkout_instance.queue_free()
	_checkout_instance = _build_checkout_screen(cart)
	_checkout_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_checkout_instance)
	_checkout_visible = true

func hide_checkout() -> void:
	if _checkout_instance != null:
		_checkout_instance.queue_free()
		_checkout_instance = null
	_checkout_visible = false

func _build_cart_panel(cart: ShoppingCart) -> Control:
	var panel := Panel.new()
	panel.color = Color(0.10, 0.10, 0.12, 0.92)
	panel.offset_left = 60
	panel.offset_top = 30
	panel.offset_right = 260
	panel.offset_bottom = 230
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var header := Label.new()
	header.text = " SHOPPING CART "
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.94, 0.94, 0.91))
	vbox.add_child(header)
	
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", Color(0.35, 0.35, 0.38))
	vbox.add_child(sep)
	
	var items := cart.get_items()
	if items.is_empty():
		var empty := Label.new()
		empty.text = " (empty)"
		empty.add_theme_color_override("font_color", Color(0.50, 0.50, 0.48))
		vbox.add_child(empty)
	else:
		for entry in items:
			var lbl := Label.new()
			lbl.text = " %s  $%.2f" % [entry["product"].name, entry["product"].price]
			lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
			lbl.add_theme_font_size_override("font_size", 13)
			vbox.add_child(lbl)
	
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("separator_color", Color(0.35, 0.35, 0.38))
	vbox.add_child(sep2)
	
	var total := Label.new()
	total.text = " TOTAL: $%.2f" % cart.get_total()
	total.add_theme_color_override("font_color", Color(0.35, 0.90, 0.55))
	total.add_theme_font_size_override("font_size", 15)
	vbox.add_child(total)
	
	var hint1 := Label.new()
	hint1.text = " [E] Checkout    [TAB] Close"
	hint1.add_theme_color_override("font_color", Color(0.45, 0.45, 0.42))
	hint1.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint1)
	
	return panel

func _build_checkout_screen(cart: ShoppingCart) -> Control:
	var panel := Panel.new()
	panel.color = Color(0.08, 0.08, 0.10, 0.97)
	panel.offset_left = 80
	panel.offset_top = 25
	panel.offset_right = 240
	panel.offset_bottom = 235
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = " -- CHECKOUT -- "
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.94, 0.94, 0.91))
	vbox.add_child(title)
	
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator_color", Color(0.40, 0.40, 0.44))
	vbox.add_child(sep)
	
	var store := Label.new()
	store.text = " PIXEL MART"
	store.add_theme_color_override("font_color", Color(0.60, 0.85, 0.60))
	store.add_theme_font_size_override("font_size", 14)
	vbox.add_child(store)
	
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("separator_color", Color(0.30, 0.30, 0.33))
	vbox.add_child(sep2)
	
	for entry in cart.get_items():
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = " %s" % entry["product"].name
		name_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78))
		name_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(name_lbl)
		var price_lbl := Label.new()
		price_lbl.text = "$%.2f" % entry["product"].price
		price_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78))
		price_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(price_lbl)
		vbox.add_child(row)
	
	var sep3 := HSeparator.new()
	sep3.add_theme_color_override("separator_color", Color(0.40, 0.40, 0.44))
	vbox.add_child(sep3)
	
	var subtotal := cart.get_total()
	var tax := Label.new()
	tax.text = " Subtotal: $%.2f" % subtotal
	tax.add_theme_color_override("font_color", Color(0.68, 0.68, 0.65))
	tax.add_theme_font_size_override("font_size", 13)
	vbox.add_child(tax)
	
	var total_row := Label.new()
	total_row.text = " TOTAL: $%.2f" % subtotal
	total_row.add_theme_color_override("font_color", Color(0.35, 0.90, 0.55))
	total_row.add_theme_font_size_override("font_size", 17)
	vbox.add_child(total_row)
	
	var sep4 := HSeparator.new()
	sep4.add_theme_color_override("separator_color", Color(0.30, 0.30, 0.33))
	vbox.add_child(sep4)
	
	var thanks := Label.new()
	thanks.text = " THANK YOU FOR SHOPPING!"
	thanks.add_theme_color_override("font_color", Color(0.55, 0.88, 0.60))
	thanks.add_theme_font_size_override("font_size", 12)
	vbox.add_child(thanks)
	
	var hint := Label.new()
	hint.text = " [E] Pay & Exit"
	hint.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)
	
	return panel

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_cart"):
		tab_pressed.emit()
	if event.is_action_pressed("pause"):
		hide_cart()
		hide_checkout()
	if event.is_action_just_pressed("interact") and _checkout_visible:
		checkout_complete.emit()
