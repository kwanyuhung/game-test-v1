# checkout_system.gd
# All checkout logic — finish_checkout, receipt display, error handling.
extends Node

var _main: Node2D = null
var _player = null
var _player_stats = null
var _dynamic_pricing = null
var _brand_manager = null
var _promo_manager = null
var _warehouse = null
var _toasts = null

# UI refs (labels on main)
var _checkout_receipt = null
var _checkout_items_lbl = null
var _checkout_total_lbl = null
var _checkout_counter_label = null

var _checkout_receipt_visible: bool = false

func setup(main: Node2D) -> void:
	_main = main
	_player = main.get("_player")
	_player_stats = main.get("_player_stats")
	_dynamic_pricing = main.get("_dynamic_pricing")
	_brand_manager = main.get("_brand_manager")
	_promo_manager = main.get("_promo_manager")
	_warehouse = main.get("_warehouse")
	_toasts = main.get("_toasts")
	# Cache UI refs
	_checkout_receipt = main.get("_checkout_receipt")
	_checkout_items_lbl = main.get("_checkout_items_lbl")
	_checkout_total_lbl = main.get("_checkout_total_lbl")
	_checkout_counter_label = main.get("_checkout_counter_label")

func do_checkout(nearby_checkout) -> void:
	# Express lane item count check
	var ctype = nearby_checkout.get_checkout_type()
	var items = _player.get_cart_items()
	if items.size() == 0:
		if _toasts != null:
			_toasts.toast_warning("Cart is empty!")
		return

	if ctype == 2:  # EXPRESS
		var item_count := 0
		for item in items:
			item_count += item.get("qty", 1)
		if item_count > 12:  # MAX_EXPRESS_ITEMS
			nearby_checkout.check_express_items(item_count)
			_on_express_rejected()
			return

	# Self-checkout random error
	if ctype == 1:  # SELF
		if nearby_checkout.roll_self_checkout_error():
			_on_self_checkout_error()
			return

	_finish_checkout(nearby_checkout)

func _finish_checkout(nearby_checkout) -> void:
	if _player == null:
		return
	var cart = _player
	var items = cart.get_cart_items()
	if items.size() == 0:
		return

	var subtotal := 0.0
	for item in items:
		var item_prod = item.get("product", item)
		var base_price := item_prod.price
		var sec_id = item_prod.get("section", "")
		var adj_price := base_price
		if sec_id != "" and _dynamic_pricing != null:
			adj_price = _dynamic_pricing.get_adjusted_price(base_price, sec_id, _warehouse)
		subtotal += adj_price * item.get("qty", 1)

	# Apply loyalty credit if member (100 pts = $5 off)
	var loyalty_credit := 0.0
	if _player_stats != null and _player_stats.is_loyalty_member():
		loyalty_credit = _player_stats.redeem_loyalty_credit()

	# Loyalty tier discount
	var tier_discount := 0.0
	if _promo_manager != null:
		tier_discount = _promo_manager.get_loyalty_discount(subtotal)

	var taxable := subtotal - loyalty_credit - tier_discount
	if taxable < 0:
		taxable = 0.0
	var tax = taxable * 0.08
	var total = taxable + tax

	# Deduct cash
	if _player_stats != null:
		_player_stats.add_cash(-total)

	# Award XP (with brand event multipliers)
	var base_xp := max(1, int(total * 0.5))
	var brand_bonus_xp := 0
	if _player_stats != null:
		var total_xp := 0
		for item in items:
			var item_prod = item.get("product", item)
			var item_xp := max(1, int(item_prod.price * item.get("qty", 1) * 0.5))
			var multiplier := 1.0
			if _brand_manager != null:
				multiplier = _brand_manager.get_xp_multiplier_for_product(item_prod.get("id", ""))
			total_xp += int(item_xp * multiplier)
			if multiplier > 1.0:
				brand_bonus_xp += int(item_xp * (multiplier - 1.0))
			# Consume stock from warehouse
			var sec_id = item_prod.get("section", "")
			if sec_id != "" and _warehouse != null:
				var qty = item.get("qty", 1) as int
				var available = _warehouse.consume_stock(sec_id, qty)
				if not available:
					if _toasts:
						_toasts.toast_warning("%s is now out of stock!" % item_prod.get("name", "Item").to_upper())

		# Customer satisfaction bonus
		var satisfaction_mult := 1.0
		if _player_stats.has_method("get_satisfaction_bonus"):
			satisfaction_mult = _player_stats.get_satisfaction_bonus()
			_player_stats.record_customer_served(true)

		# Promotion manager XP multiplier
		var promo_mult := 1.0
		if _promo_manager != null:
			promo_mult = _promo_manager.get_checkout_xp_multiplier()

		var final_xp := max(1, int(total_xp * satisfaction_mult * promo_mult))
		_player_stats.add_xp(final_xp)
		if satisfaction_mult > 1.05 or promo_mult > 1.0:
			if _toasts:
				_toasts.toast_success("Satisfied customer! +%d XP (%.0f%% bonus)" % [final_xp, (satisfaction_mult - 1.0) * 100])

		# Gift wrap bonus at checkout
		var cart_gift_wrapped = _main.get("_cart_gift_wrapped")
		if cart_gift_wrapped:
			_main.set("_cart_gift_wrapped", false)
			_player_stats.add_xp(15)
			_player_stats.add_cash(2.0)
			if _toasts:
				_toasts.toast_success("Gift wrap bonus! +15 XP + $2 tip!")

		# Checkout savings display
		var savings := 0.0
		var mn = _main.get_node_or_null("/root/Main")
		if mn != null:
			var dp = mn.get_node_or_null("DynamicPricing")
			var wh = null
			if mn.has_method("get_warehouse"):
				wh = mn.get_warehouse()
			for entry in cart.get_items():
				var prod = entry["product"]
				var qty = entry["qty"]
				var adj = prod.price
				if dp != null and wh != null and dp.has_method("get_price_multiplier_for_section"):
					adj = prod.price * dp.get_price_multiplier_for_section(prod.section, wh)
				savings += (prod.price - adj) * qty
		if savings > 0.01 and _toasts != null:
			_toasts.toast_success("You saved $%.2f on this shop!" % savings)

		# Award staff XP
		_player_stats.add_staff_xp(items.size(), "Checkout: %d items" % items.size())

	# Earn loyalty points
	if _promo_manager != null:
		var pts = _promo_manager.get_checkout_point_bonus(total)
		_promo_manager.add_loyalty_points(pts)
		if pts > 0:
			if _toasts:
				_toasts.toast_info("+%d Loyalty Points!" % pts)

	# Record brand stats
	if _brand_manager != null:
		for item in items:
			var item_prod = item.get("product", item)
			var qty = item.get("qty", 1)
			var item_total = item_prod.price * qty
			_brand_manager.record_purchase(item_prod.get("id", ""), qty, item_total)

	# Clear cart
	cart.clear_cart()

	# Show farewell bubble at staffed lanes
	if nearby_checkout.is_staffed():
		nearby_checkout.show_farewell_bubble()

	# Show receipt
	_show_checkout_receipt(items, subtotal, tax, total, brand_bonus_xp, loyalty_credit)

	# Notify
	var telegram_bot = _main.get("_telegram_bot")
	if telegram_bot != null:
		telegram_bot.queue_report("Checkout complete! $%.2f spent. Cart cleared." % total)
	else:
		var TelegramBot = load("res://scripts/telegram_bot.gd")
		TelegramBot.send_message("Checkout complete! $%.2f spent. Cart cleared." % total)
	if _toasts != null:
		_toasts.toast_success("Checkout complete! -$%.2f" % total)

	# Auto-save
	var SaveSystem = load("res://scripts/save_system.gd")
	SaveSystem.save_game(_main)

func _show_checkout_receipt(items: Array, subtotal: float, tax: float, total: float, brand_bonus_xp: int = 0, loyalty_credit: float = 0.0) -> void:
	if _checkout_receipt == null:
		return
	_checkout_receipt.visible = true
	_checkout_items_lbl.text = ""
	for item in items:
		var qty = item.get("qty", 1)
		_checkout_items_lbl.text += "%dx %s $%.2f\n" % [qty, item.name, item.price * qty]
	var receipt_text := ""
	if loyalty_credit > 0:
		receipt_text += "Loyalty Credit: -$%.2f\n" % loyalty_credit
	receipt_text += "Subtotal: $%.2f\nTax: $%.2f\nTOTAL: $%.2f" % [subtotal, tax, total]
	if brand_bonus_xp > 0:
		receipt_text += "\n[color=#FFFF00]BRAND BONUS: +%d XP![/color]" % brand_bonus_xp
	_checkout_total_lbl.text = receipt_text
	_checkout_receipt_visible = true
	_main.set("_checkout_receipt_visible", true)
	await _main.get_tree().create_timer(5.0).timeout
	if _checkout_receipt != null:
		_checkout_receipt.visible = false
		_checkout_receipt_visible = false
		_main.set("_checkout_receipt_visible", false)

func _on_express_rejected() -> void:
	if _toasts != null:
		_toasts.toast_error("Express lane: max 12 items only!")

func _on_self_checkout_error() -> void:
	if _toasts != null:
		_toasts.toast_error("Unexpected item in bagging area! Press E to retry.")

func retry_checkout(nearby_checkout) -> void:
	# Called after self-checkout error is dismissed
	do_checkout(nearby_checkout)

func get_receipt_visible() -> bool:
	return _checkout_receipt_visible
