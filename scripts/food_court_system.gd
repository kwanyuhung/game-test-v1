# food_court_system.gd
# Cafe, vending, loyalty, entertainment mini-games.
extends Node

var _main: Node2D = null
var _player = null
var _player_stats = null
var _toasts = null
var _promo_manager = null

func setup(main: Node2D) -> void:
	_main = main
	_player = main.get("_player")
	_player_stats = main.get("_player_stats")
	_toasts = main.get("_toasts")
	_promo_manager = main.get("_promo_manager")

# ── Cafe ─────────────────────────────────────────────────────────
func open_cafe_browse() -> void:
	if _toasts == null:
		return
	var items := [
		{"name": "Espresso", "price": 3.50},
		{"name": "Latte", "price": 4.50},
		{"name": "Cappuccino", "price": 4.80},
		{"name": "Americano", "price": 3.00},
		{"name": "Muffin", "price": 2.80},
		{"name": "Croissant", "price": 3.20},
		{"name": "Iced Coffee", "price": 4.20},
		{"name": "Smoothie", "price": 5.50},
	]
	_main.set("_temp_order_mode", "cafe")
	_main.set("_temp_order_items", items)
	_toasts.toast_info("Cafe: [1]Espresso $3.50 [2]Latte $4.50 [3]Capp $4.80 [4]Americano $3.00")
	_toasts.toast_info("Muffin $2.80 [5]  Croissant $3.20 [6]  Iced $4.20 [7]  Smoothie $5.50 [8]")
	var hint = _main.get_node_or_null("PromptLbl")
	if hint != null:
		hint.text = "[1-8] Add item  [E] finish order"

# ── Vending ─────────────────────────────────────────────────────
func open_vending_browse() -> void:
	if _toasts == null:
		return
	var items := [
		{"name": "Water", "price": 1.50},
		{"name": "Cola", "price": 2.00},
		{"name": "Juice", "price": 2.50},
		{"name": "Chips", "price": 1.80},
		{"name": "Chocolate", "price": 2.20},
		{"name": "Energy Drink", "price": 3.00},
	]
	_main.set("_temp_order_mode", "vending")
	_main.set("_temp_order_items", items)
	_toasts.toast_info("Vending: [1]Water $1.50 [2]Cola $2.00 [3]Juice $2.50 [4]Chips $1.80 [5]Choco $2.20 [6]Energy $3.00")
	var hint = _main.get_node_or_null("PromptLbl")
	if hint != null:
		hint.text = "[1-6] Add item  [E] done"

func add_order_item(idx: int, item: Dictionary) -> void:
	if _player == null:
		return
	var cart = _player.get_cart()
	if cart == null:
		return
	var cart_item := {
		"id": _main.get("_temp_order_mode") + "_" + str(idx),
		"name": item.name,
		"price": item.price,
		"qty": 1
	}
	cart.add_item(cart_item)
	if _toasts != null:
		_toasts.toast_success("+1 %s $%.2f" % [item.name, item.price])
	_update_cart_ui()

func finish_order() -> void:
	_main.set("_temp_order_mode", "")
	_main.set("_temp_order_items", [])
	var hint = _main.get_node_or_null("PromptLbl")
	if hint != null:
		hint.text = ""
	if _toasts != null:
		_toasts.toast_success("Done!")

func _update_cart_ui() -> void:
	# Delegate to main_hud if available
	var main_hud = _main.get("_main_hud")
	if main_hud != null and main_hud.has_method("_update_cart_ui"):
		main_hud._update_cart_ui()

# ── Loyalty / Coins ──────────────────────────────────────────────
func handle_loyalty_key(idx: int, item: Dictionary) -> void:
	if _player_stats == null:
		return
	if idx == 0:
		var cost: float = item.get("price", 2.0)
		if _player_stats.spend_cash(cost):
			_player_stats.add_coins(5)
			if _toasts != null:
				_toasts.toast_success("+5 Coins! Now have %d coins" % _player_stats.get_coins())
		else:
			if _toasts != null:
				_toasts.toast_warning("Not enough cash!")
	elif idx == 1:
		if _player_stats.is_loyalty_member():
			var pts = _player_stats.get_loyalty_points()
			_toasts.toast_info("Loyalty: %d pts" % pts)
		else:
			if _player_stats.signup_loyalty():
				if _toasts != null:
					_toasts.toast_success("Welcome to Loyalty! 1 pt/$1 -- 100 pts = $5 credit!")

func toggle_loyalty_panel() -> void:
	var loyalty_panel = _main.get("_loyalty_panel")
	if loyalty_panel == null:
		return
	loyalty_panel.visible = not loyalty_panel.visible
	if loyalty_panel.visible:
		_refresh_loyalty_panel()

func _refresh_loyalty_panel() -> void:
	var loyalty_panel = _main.get("_loyalty_panel")
	if loyalty_panel == null or not _promo_manager:
		return
	for c in loyalty_panel.get_children():
		c.queue_free()
	var pan := ColorRect.new()
	pan.color = Color(0.05, 0.08, 0.15, 0.95)
	pan.size = Vector2(200, 120)
	loyalty_panel.add_child(pan)
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 8)
	var tier = _promo_manager.get_tier_name()
	var tier_col = _promo_manager.get_tier_color()
	var pts = _promo_manager.get_loyalty_points()
	var disc = int(_promo_manager.get_tier_discount() * 100)
	var mult = _promo_manager.get_tier_point_multiplier()
	var prog = _promo_manager.get_tier_progress()
	lbl.text = "%s LOYALTY\n\nPoints: %d\nDiscount: %d%%\nPoint Bonus: x%.1f\n\nProgress: %d / %d pts" % [
		tier.to_upper(), pts, disc, mult, prog["current"], prog["threshold"]]
	lbl.add_theme_color_override("font_color", tier_col)
	lbl.position = Vector2(10, 10)
	loyalty_panel.add_child(lbl)

# ── Entertainment mini-games ─────────────────────────────────────
func play_karaoke() -> void:
	var bonus_xp = 20 + randi() % 30
	if _player_stats != null:
		_player_stats.add_xp(bonus_xp)
	if _toasts != null:
		_toasts.toast_success("Karaoke! +%d XP - You are a star!" % bonus_xp)
	var telegram_bot = _main.get("_telegram_bot")
	var text = "Karaoke performed! +%d XP earned!" % bonus_xp
	if telegram_bot != null:
		telegram_bot.queue_report(text)
	else:
		var TelegramBot = load("res://scripts/telegram_bot.gd")
		TelegramBot.send_message(text)

func play_pool() -> void:
	var bonus_xp = 15 + randi() % 20
	if _player_stats != null:
		_player_stats.add_xp(bonus_xp)
	if _toasts != null:
		_toasts.toast_info("Pool shot! +%d XP for the game!" % bonus_xp)

func play_darts() -> void:
	var bonus_xp = 10 + randi() % 25
	var bonus_cash = clamp(float(randi() % 15) * 0.1, 0.5, 1.5)
	if _player_stats != null:
		_player_stats.add_xp(bonus_xp)
		_player_stats.add_cash(bonus_cash)
	if _toasts != null:
		_toasts.toast_success("Bullseye! +%d XP + $%.2f prize money!" % [bonus_xp, bonus_cash])
	var telegram_bot = _main.get("_telegram_bot")
	var text = "Darts champion! +%d XP + $%.2f prize!" % [bonus_xp, bonus_cash]
	if telegram_bot != null:
		telegram_bot.queue_report(text)
	else:
		var TelegramBot = load("res://scripts/telegram_bot.gd")
		TelegramBot.send_message(text)

# ── Promo Booth ──────────────────────────────────────────────────
func open_promo_booth() -> void:
	if _toasts != null:
		_toasts.toast_info("Daily Deals! Featured: Burger, Pizza, Fried Chicken - 1.5x XP!")
	if _player_stats != null:
		_player_stats.add_xp(5)

# ── Store News ───────────────────────────────────────────────────
func read_store_news() -> void:
	if _toasts != null:
		_toasts.toast_info("STORE TIPS: Restock low sections for bonus XP! Loyalty = bigger savings at checkout!")
		_toasts.toast_info("Press [L] for your shopping list, [J] for quests!")

# ── Loyalty entry via interact ───────────────────────────────────
func handle_loyalty_interact() -> void:
	_main.set("_temp_order_mode", "loyalty")
	_main.set("_temp_order_items", [{"name": "5 Coins", "price": 2.0}, {"name": "Sign Up Loyalty", "price": 0.0}])
	if _player_stats != null and _player_stats.is_loyalty_member():
		var pts = _player_stats.get_loyalty_points()
		_toasts.toast_info("Loyalty: %d pts | [1] Buy 5 Coins $2 | [2] Loyalty Status" % pts)
	else:
		_toasts.toast_info("Loyalty: [1] Sign Up Free | [2] Buy 5 Coins $2")
	var hint = _main.get_node_or_null("PromptLbl")
	if hint != null:
		hint.text = "[1] Coins  [2] Loyalty  [E] Done"

# ── Gift wrap toggle ────────────────────────────────────────────
func toggle_gift_wrap() -> void:
	var cart_gift_wrapped = _main.get("_cart_gift_wrapped")
	if cart_gift_wrapped:
		if _toasts != null:
			_toasts.toast_info("Cart already gift wrapped!")
	else:
		_main.set("_cart_gift_wrapped", true)
		if _toasts != null:
			_toasts.toast_success("Cart gift wrapped! +$2 tip at checkout!")
