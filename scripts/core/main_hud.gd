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

func _get_font_scale() -> float:
	var base_height := 720.0
	return get_viewport().get_visible_rect().size.y / base_height

func _build_cart_ui(owner: Node2D) -> void:
	var font_scale := _get_font_scale()

	var cart_bg := ColorRect.new()
	cart_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cart_bg.offset_left = 4
	cart_bg.offset_top = 4
	cart_bg.offset_right = 74
	cart_bg.offset_bottom = 20
	cart_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	owner.add_child(cart_bg)

	var cart_icon := Label.new()
	cart_icon.text = "Cart:"
	cart_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cart_icon.offset_left = 6
	cart_icon.offset_top = 5
	cart_icon.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	cart_icon.add_theme_font_size_override("font_size", int(8 * font_scale))
	owner.add_child(cart_icon)

	_cart_count_lbl = Label.new()
	_cart_count_lbl.text = "0 items  $0.00"
	_cart_count_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_cart_count_lbl.offset_left = 30
	_cart_count_lbl.offset_top = 5
	_cart_count_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	_cart_count_lbl.add_theme_font_size_override("font_size", int(8 * font_scale))
	owner.add_child(_cart_count_lbl)

	# Tab hint bottom right
	var tab_hint := Label.new()
	tab_hint.name = "TabHint"
	tab_hint.text = "[TAB] Cart"
	tab_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tab_hint.offset_left = -76
	tab_hint.offset_top = 4
	tab_hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	tab_hint.add_theme_font_size_override("font_size", int(7 * font_scale))
	owner.add_child(tab_hint)

# ── Zone prompt (bottom center) ────────────────────────────────────────────────

func _build_zone_prompt(owner: Node2D) -> void:
	var font_scale := _get_font_scale()

	var prompt_bg := ColorRect.new()
	prompt_bg.name = "PromptBg"
	prompt_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_bg.offset_left = -60
	prompt_bg.offset_top = -18
	prompt_bg.offset_right = 60
	prompt_bg.offset_bottom = -4
	prompt_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	prompt_bg.visible = false
	owner.add_child(prompt_bg)

	var prompt_lbl := Label.new()
	prompt_lbl.name = "PromptLbl"
	prompt_lbl.text = "[E] Browse"
	prompt_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_lbl.offset_left = -40
	prompt_lbl.offset_top = -14
	prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	prompt_lbl.add_theme_font_size_override("font_size", int(8 * font_scale))
	prompt_lbl.visible = false
	owner.add_child(prompt_lbl)

# ── Checkout counter label ─────────────────────────────────────────────────────

func _build_checkout_label(owner: Node2D) -> void:
	var font_scale := _get_font_scale()

	_checkout_counter_label = Label.new()
	_checkout_counter_label.text = ""
	_checkout_counter_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_checkout_counter_label.offset_left = -100
	_checkout_counter_label.offset_right = 100
	_checkout_counter_label.offset_top = -34
	_checkout_counter_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.72))
	_checkout_counter_label.add_theme_font_size_override("font_size", int(9 * font_scale))
	_checkout_counter_label.visible = false
	owner.add_child(_checkout_counter_label)

# ── Checkout Receipt Panel ─────────────────────────────────────────────────────

func _build_checkout_receipt_panel(owner: Node2D) -> void:
	var font_scale := _get_font_scale()

	# Receipt panel - positioned center-left area
	var panel := ColorRect.new()
	panel.name = "CheckoutReceipt"
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 85
	panel.offset_top = 28
	panel.offset_right = 215  # 130 width
	panel.offset_bottom = 168  # 140 height
	panel.color = Color(0.08, 0.08, 0.12, 0.92)
	panel.visible = false
	owner.add_child(panel)
	_checkout_receipt = panel

	var title := Label.new()
	title.text = "── RECEIPT ──"
	title.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	title.offset_left = 7
	title.offset_top = 4
	title.add_theme_color_override("font_color", Color(0.90, 0.85, 0.55))
	title.add_theme_font_size_override("font_size", int(8 * font_scale))
	panel.add_child(title)

	var items_lbl := Label.new()
	items_lbl.name = "ReceiptItems"
	items_lbl.text = ""
	items_lbl.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	items_lbl.offset_left = 5
	items_lbl.offset_top = 18
	items_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.60))
	items_lbl.add_theme_font_size_override("font_size", int(7 * font_scale))
	panel.add_child(items_lbl)

	var total_lbl := Label.new()
	total_lbl.name = "ReceiptTotal"
	total_lbl.text = ""
	total_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	total_lbl.offset_left = 5
	total_lbl.offset_top = -10
	total_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.55))
	total_lbl.add_theme_font_size_override("font_size", int(8 * font_scale))
	panel.add_child(total_lbl)

	# Cart panel (canvas layer for cart UI)
	_cart_panel = CanvasLayer.new()
	_cart_panel.name = "CartPanel"
	_cart_panel.visible = false
	owner.add_child(_cart_panel)

	# Cart panel - centered on screen, sized proportionally
	var cart_bg := ColorRect.new()
	cart_bg.name = "CartBg"
	cart_bg.set_anchors_preset(Control.PRESET_CENTER)
	cart_bg.offset_left = -100
	cart_bg.offset_top = -90
	cart_bg.offset_right = 100
	cart_bg.offset_bottom = 90
	cart_bg.color = Color(0.07, 0.07, 0.10, 0.92)
	_cart_panel.add_child(cart_bg)

	var cart_title := Label.new()
	cart_title.name = "CartTitle"
	cart_title.text = "Shopping Cart"
	cart_title.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	cart_title.offset_left = 4
	cart_title.offset_top = 4
	cart_title.add_theme_color_override("font_color", Color(0.88, 0.82, 0.55))
	cart_title.add_theme_font_size_override("font_size", int(11 * font_scale))
	_cart_panel.add_child(cart_title)

	_cart_items_lbl = Label.new()
	_cart_items_lbl.name = "CartItems"
	_cart_items_lbl.text = ""
	_cart_items_lbl.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_cart_items_lbl.offset_left = 4
	_cart_items_lbl.offset_top = 22
	_cart_items_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.56))
	_cart_items_lbl.add_theme_font_size_override("font_size", int(9 * font_scale))
	_cart_panel.add_child(_cart_items_lbl)

	_cart_total_lbl = Label.new()
	_cart_total_lbl.name = "CartTotal"
	_cart_total_lbl.text = "Total: $0.00"
	_cart_total_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_cart_total_lbl.offset_left = 4
	_cart_total_lbl.offset_top = -15
	_cart_total_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.55))
	_cart_total_lbl.add_theme_font_size_override("font_size", int(11 * font_scale))
	_cart_panel.add_child(_cart_total_lbl)
