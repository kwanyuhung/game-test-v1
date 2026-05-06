# main_hud.gd
# All HUD-building methods extracted from main.gd.
# Usage: var hud = main_hud.new() ; add_child(hud) ; hud.build_hud(owner)
# The hud attaches to `owner` (main) to add its child nodes.
extends Node

# References set during build_hud()
var _cart_count_lbl: Label = null
var _checkout_counter_label: Label = null
var _checkout_receipt: Control = null
var _cart_panel: CanvasLayer = null
var _cart_items_lbl: Label = null
var _cart_total_lbl: Label = null

func build_hud(owner: Node2D) -> void:
	_build_cart_ui(owner)
	_build_zone_prompt(owner)
	_build_checkout_label(owner)
	_build_checkout_receipt_panel(owner)

# ── Cart UI (top-left) ─────────────────────────────────────────────────────────

func _build_cart_ui(owner: Node2D) -> void:
	var cart_bg := ColorRect.new()
	cart_bg.position = Vector2(4.0, 4.0)
	cart_bg.size = Vector2(70.0, 16.0)
	cart_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	owner.add_child(cart_bg)

	var cart_icon := Label.new()
	cart_icon.text = "Cart:"
	cart_icon.position = Vector2(6.0, 5.0)
	cart_icon.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	cart_icon.add_theme_font_size_override("font_size", 8)
	owner.add_child(cart_icon)

	_cart_count_lbl = Label.new()
	_cart_count_lbl.text = "0 items  $0.00"
	_cart_count_lbl.position = Vector2(30.0, 5.0)
	_cart_count_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	_cart_count_lbl.add_theme_font_size_override("font_size", 8)
	owner.add_child(_cart_count_lbl)

	# Tab hint bottom right
	var tab_hint := Label.new()
	tab_hint.name = "TabHint"
	tab_hint.text = "[TAB] Cart"
	tab_hint.position = Vector2(264.0, 4.0)
	tab_hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	tab_hint.add_theme_font_size_override("font_size", 7)
	owner.add_child(tab_hint)

# ── Zone prompt (bottom center) ────────────────────────────────────────────────

func _build_zone_prompt(owner: Node2D) -> void:
	var prompt_bg := ColorRect.new()
	prompt_bg.name = "PromptBg"
	prompt_bg.position = Vector2(100.0, 164.0)
	prompt_bg.size = Vector2(120.0, 14.0)
	prompt_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	prompt_bg.visible = false
	owner.add_child(prompt_bg)

	var prompt_lbl := Label.new()
	prompt_lbl.name = "PromptLbl"
	prompt_lbl.text = "[E] Browse"
	prompt_lbl.position = Vector2(104.0, 166.0)
	prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	prompt_lbl.add_theme_font_size_override("font_size", 8)
	prompt_lbl.visible = false
	owner.add_child(prompt_lbl)

# ── Checkout counter label ─────────────────────────────────────────────────────

func _build_checkout_label(owner: Node2D) -> void:
	_checkout_counter_label = Label.new()
	_checkout_counter_label.text = ""
	_checkout_counter_label.position = Vector2(100.0, 150.0)
	_checkout_counter_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.72))
	_checkout_counter_label.add_theme_font_size_override("font_size", 9)
	_checkout_counter_label.visible = false
	owner.add_child(_checkout_counter_label)

# ── Checkout Receipt Panel ─────────────────────────────────────────────────────

func _build_checkout_receipt_panel(owner: Node2D) -> void:
	var panel := ColorRect.new()
	panel.name = "CheckoutReceipt"
	panel.position = Vector2(85.0, 28.0)
	panel.size = Vector2(130.0, 140.0)
	panel.color = Color(0.08, 0.08, 0.12, 0.92)
	panel.visible = false
	owner.add_child(panel)
	_checkout_receipt = panel

	var title := Label.new()
	title.text = "── RECEIPT ──"
	title.position = Vector2(92.0, 32.0)
	title.add_theme_color_override("font_color", Color(0.90, 0.85, 0.55))
	title.add_theme_font_size_override("font_size", 8)
	panel.add_child(title)

	var items_lbl := Label.new()
	items_lbl.name = "ReceiptItems"
	items_lbl.text = ""
	items_lbl.position = Vector2(90.0, 46.0)
	items_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.60))
	items_lbl.add_theme_font_size_override("font_size", 7)
	panel.add_child(items_lbl)

	var total_lbl := Label.new()
	total_lbl.name = "ReceiptTotal"
	total_lbl.text = ""
	total_lbl.position = Vector2(90.0, 130.0)
	total_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.55))
	total_lbl.add_theme_font_size_override("font_size", 8)
	panel.add_child(total_lbl)

	# Cart panel (canvas layer for cart UI)
	_cart_panel = CanvasLayer.new()
	_cart_panel.name = "CartPanel"
	_cart_panel.visible = false
	owner.add_child(_cart_panel)

	var cart_bg := ColorRect.new()
	cart_bg.name = "CartBg"
	cart_bg.position = Vector2(80.0, 20.0)
	cart_bg.size = Vector2(140.0, 120.0)
	cart_bg.color = Color(0.07, 0.07, 0.10, 0.92)
	_cart_panel.add_child(cart_bg)

	var cart_title := Label.new()
	cart_title.name = "CartTitle"
	cart_title.text = "Shopping Cart"
	cart_title.position = Vector2(84.0, 24.0)
	cart_title.add_theme_color_override("font_color", Color(0.88, 0.82, 0.55))
	cart_title.add_theme_font_size_override("font_size", 8)
	_cart_panel.add_child(cart_title)

	_cart_items_lbl = Label.new()
	_cart_items_lbl.name = "CartItems"
	_cart_items_lbl.text = ""
	_cart_items_lbl.position = Vector2(84.0, 38.0)
	_cart_items_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.56))
	_cart_items_lbl.add_theme_font_size_override("font_size", 7)
	_cart_panel.add_child(_cart_items_lbl)

	_cart_total_lbl = Label.new()
	_cart_total_lbl.name = "CartTotal"
	_cart_total_lbl.text = "Total: $0.00"
	_cart_total_lbl.position = Vector2(84.0, 110.0)
	_cart_total_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.55))
	_cart_total_lbl.add_theme_font_size_override("font_size", 8)
	_cart_panel.add_child(_cart_total_lbl)
