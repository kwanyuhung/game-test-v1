class_name UIManager
extends Node

# ── Preloads ────────────────────────────────────────────────────────
const ToastManagerScript = preload("res://scripts/ui/toast_manager.gd")
const FloatingTextScript = preload("res://scripts/ui/floating_text.gd")
const FadeTransitionScript = preload("res://scripts/ui/fade_transition.gd")
const MiniMapScript = preload("res://scripts/ui/mini_map.gd")
const DailyBonusScript = preload("res://scripts/ui/daily_bonus.gd")
const QuestSystemScript = preload("res://scripts/systems/quest_system.gd")
const QuestJournalScript = preload("res://scripts/ui/quest_journal.gd")
const ShoppingListScript = preload("res://scripts/amenities/shopping_list.gd")
const StatsDashboardScript = preload("res://scripts/ui/stats_dashboard.gd")
const MapPanelScript = preload("res://scripts/ui/map_panel.gd")
const FloorPanelScript = preload("res://scripts/ui/floor_panel.gd")
const InteractionBubbleScript = preload("res://scripts/ui/interaction_bubble.gd")
const ChatPanelScript = preload("res://scripts/ui/chat_panel.gd")
const StatsPanelScript = preload("res://scripts/ui/stats_panel.gd")
const MaintenancePanelScript = preload("res://scripts/ui/maintenance_panel.gd")
const ATMPanelScript = preload("res://scripts/amenities/atm_panel.gd")
const MonitorPanelScript = preload("res://scripts/ui/monitor_panel.gd")
const SettingsPanelScript = preload("res://scripts/ui/settings_panel.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const TutorialOverlayScript = preload("res://scripts/ui/tutorial_overlay.gd")
const DevToolsScript = preload("res://scripts/ui/dev_tools.gd")
const ShelfPanelScript = preload("res://scripts/ui/shelf_panel.gd")
const AchievementPopupScript = preload("res://scripts/ui/achievement_popup.gd")
const MainHUD = preload("res://scripts/core/main_hud.gd")
const PlayerStatsScript = preload("res://scripts/managers/player_stats.gd")

# ── Instance variables ─────────────────────────────────────────────
var _main: Node2D = null
var _game_state: GameState = null
var _toasts: Node = null
var _floating_text: Node = null
var _fade: Node = null
var _minimap: Node = null
var _daily_bonus: Node = null
var _quest_system: Node = null
var _quest_journal: Node = null
var _shopping_list: Node = null
var _stats_dashboard: Node = null
var _map_panel: Node = null
var _floor_panel: Node = null
var _interaction_bubble: Node = null
var _chat_panel: Node = null
var _achievement_popup: Node = null
var _stats_panel: Node = null
var _maintenance_panel: Node = null
var _atm_panel: Node = null
var _monitor_panel: Node = null
var _settings_panel: Node = null
var _pause_menu: Node = null
var _tutorial_overlay: Node = null
var _dev_tools: Node = null
var _shelf_panel: Node = null
var _save_hint_label: Node = null
var _time_label: Node = null
var _store_status_label: Node = null
var _shopping_list_count_lbl: Node = null
var _xp_bar_bg: Node = null
var _xp_bar_fill: Node = null
var _checkout_counter_label: Node = null
var _checkout_items_lbl: Node = null
var _checkout_total_lbl: Node = null
var _floor_label: Node = null
var _minimap_visible: bool = false
var _shopping_list_visible: bool = false
var _loyalty_panel: Node = null
var _truck_dock_node: Node = null

# ── setup(main, game_state) ──────────────────────────────────────
func setup(main: Node2D, game_state: GameState) -> void:
	_main = main
	_game_state = game_state

	# ── Create all UI components as children of main ──────────────────
	_toasts = ToastManagerScript.new()
	_main.add_child(_toasts)

	_floating_text = FloatingTextScript.new()
	_main.add_child(_floating_text)

	_fade = FadeTransitionScript.new()
	_main.add_child(_fade)

	_minimap = MiniMapScript.new()
	_main.add_child(_minimap)

	_daily_bonus = DailyBonusScript.new()
	_main.add_child(_daily_bonus)

	_quest_system = QuestSystemScript.new()
	_main.add_child(_quest_system)

	_quest_journal = QuestJournalScript.new()
	_main.add_child(_quest_journal)

	_shopping_list = ShoppingListScript.new()
	_main.add_child(_shopping_list)

	_stats_dashboard = StatsDashboardScript.new()
	_main.add_child(_stats_dashboard)

	_map_panel = MapPanelScript.new()
	_main.add_child(_map_panel)

	_floor_panel = FloorPanelScript.new()
	_main.add_child(_floor_panel)

	_interaction_bubble = InteractionBubbleScript.new()
	_main.add_child(_interaction_bubble)

	_chat_panel = ChatPanelScript.new()
	_main.add_child(_chat_panel)

	_stats_panel = StatsPanelScript.new()
	_main.add_child(_stats_panel)

	_maintenance_panel = MaintenancePanelScript.new()
	_main.add_child(_maintenance_panel)

	_atm_panel = ATMPanelScript.new()
	_main.add_child(_atm_panel)

	_monitor_panel = MonitorPanelScript.new()
	_main.add_child(_monitor_panel)

	_settings_panel = SettingsPanelScript.new()
	_main.add_child(_settings_panel)

	_pause_menu = PauseMenuScript.new()
	_main.add_child(_pause_menu)

	_tutorial_overlay = TutorialOverlayScript.new()
	_main.add_child(_tutorial_overlay)

	_dev_tools = DevToolsScript.new()
	_main.add_child(_dev_tools)

	_shelf_panel = ShelfPanelScript.new()
	_main.add_child(_shelf_panel)

	# ── Create inline HUD elements ────────────────────────────────────
	_save_hint_label = Label.new()
	_save_hint_label.name = "SaveHintLbl"
	_save_hint_label.position = Vector2(10, 60)
	_save_hint_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_save_hint_label.add_theme_font_size_override("font_size", 14)
	_save_hint_label.visible = false
	_main.add_child(_save_hint_label)

	_time_label = Label.new()
	_time_label.name = "TimeLbl"
	_time_label.position = Vector2(10, 10)
	_time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	_time_label.add_theme_font_size_override("font_size", 16)
	_main.add_child(_time_label)

	_store_status_label = Label.new()
	_store_status_label.name = "StoreStatusLbl"
	_store_status_label.position = Vector2(10, 35)
	_store_status_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	_store_status_label.add_theme_font_size_override("font_size", 14)
	_main.add_child(_store_status_label)

	_shopping_list_count_lbl = Label.new()
	_shopping_list_count_lbl.name = "ShoppingListCountLbl"
	_shopping_list_count_lbl.position = Vector2(1700, 10)
	_shopping_list_count_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	_shopping_list_count_lbl.add_theme_font_size_override("font_size", 14)
	_main.add_child(_shopping_list_count_lbl)

	# XP bar background
	_xp_bar_bg = ColorRect.new()
	_xp_bar_bg.name = "XPBarBg"
	_xp_bar_bg.position = Vector2(1700, 40)
	_xp_bar_bg.size = Vector2(200, 12)
	_xp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	_main.add_child(_xp_bar_bg)

	# XP bar fill
	_xp_bar_fill = ColorRect.new()
	_xp_bar_fill.name = "XPBarFill"
	_xp_bar_fill.position = Vector2(1700, 40)
	_xp_bar_fill.size = Vector2(0, 12)
	_xp_bar_fill.color = Color(0.3, 0.7, 0.3, 0.9)
	_main.add_child(_xp_bar_fill)

	_checkout_counter_label = Label.new()
	_checkout_counter_label.name = "CheckoutCounterLbl"
	_checkout_counter_label.position = Vector2(10, 100)
	_checkout_counter_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_checkout_counter_label.add_theme_font_size_override("font_size", 12)
	_checkout_counter_label.visible = false
	_main.add_child(_checkout_counter_label)

	_checkout_items_lbl = Label.new()
	_checkout_items_lbl.name = "CheckoutItemsLbl"
	_checkout_items_lbl.position = Vector2(10, 120)
	_checkout_items_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_checkout_items_lbl.add_theme_font_size_override("font_size", 12)
	_checkout_items_lbl.visible = false
	_main.add_child(_checkout_items_lbl)

	_checkout_total_lbl = Label.new()
	_checkout_total_lbl.name = "CheckoutTotalLbl"
	_checkout_total_lbl.position = Vector2(10, 140)
	_checkout_total_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	_checkout_total_lbl.add_theme_font_size_override("font_size", 14)
	_checkout_total_lbl.visible = false
	_main.add_child(_checkout_total_lbl)

	_floor_label = Label.new()
	_floor_label.name = "FloorLbl"
	_floor_label.position = Vector2(1700, 70)
	_floor_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_floor_label.add_theme_font_size_override("font_size", 14)
	_main.add_child(_floor_label)

	# ── Register panels with PanelManager (ALONE policy) ─────────────
	PanelManager.register("map", _map_panel, PanelManager.Policy.ALONE)
	PanelManager.register("floor", _floor_panel, PanelManager.Policy.ALONE)
	PanelManager.register("settings", _settings_panel, PanelManager.Policy.ALONE)
	PanelManager.register("pause", _pause_menu, PanelManager.Policy.ALONE)
	PanelManager.register("dev_tools", _dev_tools, PanelManager.Policy.ALONE)

	print_debug("[UIManager] Setup complete")

# ── Phase 5 Functions from tracker ────────────────────────────────

func _show_save_hint(msg: String) -> void:
	if _save_hint_label != null:
		_save_hint_label.text = msg
		_save_hint_label.visible = true
		await _main.get_tree().create_timer(2.0).timeout
		_save_hint_label.visible = false

func _show_achievement_popup(ach_id: String, ach_name: String, icon: String, xp: int) -> void:
	var popup = AchievementPopupScript.new()
	_main.add_child(popup)
	popup.show_achievement(ach_id, ach_name, icon, xp)

func _on_achievement_unlocked(ach_id: String) -> void:
	# Get player stats reference from main
	var player_stats: PlayerStatsScript = _main.get("_player_stats")
	if player_stats == null:
		return
	var info: Dictionary = player_stats.get_achievement_info(ach_id)
	_show_achievement_popup(ach_id, info.get("name", ""), info.get("icon", "?"), info.get("xp", 20))

func _on_staff_rank_up(new_rank: int) -> void:
	var rank_name := "???"
	match new_rank:
		0: rank_name = "Trainee"
		1: rank_name = "Worker"
		2: rank_name = "Senior"
		3: rank_name = "Supervisor"
		4: rank_name = "Manager"
	if _toasts != null:
		_toasts.toast_success("STAFF RANK UP to %s!" % rank_name)
	_update_staff_rank_hud()

func _update_staff_rank_hud() -> void:
	# Delegate to main_panels if available
	var main_panels = _main.get("main_panels") if _main.has_method("get_main_panels") else null
	if main_panels == null:
		main_panels = _main.get("_main_panels")
	if main_panels != null and main_panels.has_method("update_staff_rank_hud"):
		main_panels.update_staff_rank_hud()

func _on_player_level_up(new_level: int) -> void:
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	if prompt_lbl != null:
		prompt_lbl.text = "LEVEL UP! You are now Level %d!" % new_level
		prompt_lbl.visible = true

func _on_hour_changed(hour: int) -> void:
	if _toasts == null:
		return
	if hour == 6:
		_toasts.toast_success("Store Open! 6:00 AM")
	if hour == 23:
		_toasts.toast_warn("Store Closing - 11:00 PM")

func _on_day_changed() -> void:
	var player_stats: PlayerStatsScript = _main.get("_player_stats")
	if player_stats != null:
		var wages: float = player_stats.get_total_daily_wages()
		if wages > 0 and player_stats.get_cash() >= wages:
			player_stats.pay_staff_wages(player_stats.get_cash())
			if _toasts:
				_toasts.toast_info("Daily wages paid: $%.2f" % wages)
	else:
		if _toasts:
			_toasts.toast_warn("Could not pay staff wages!")

func _on_shift_report() -> void:
	var player_stats: PlayerStatsScript = _main.get("_player_stats")
	if player_stats != null:
		player_stats.on_shift_completed()
		var roster: Array = player_stats.get_staff_roster()
		var active: int = roster.size()
		if _toasts:
			_toasts.toast_success("Shift complete! %d staff on duty. +30 Staff XP" % active)

func _on_quest_completed(_quest_id: String, desc: String, xp: int) -> void:
	if _toasts != null:
		_toasts.toast_success("Quest Done! +%d XP" % xp)
	var player_stats: PlayerStatsScript = _main.get("_player_stats")
	if player_stats != null:
		player_stats.add_xp(xp, "Daily Quest: %s" % desc)

func _on_all_quests_complete() -> void:
	if _toasts != null:
		_toasts.toast_xp("All Daily Quests Done! Epic Bonus!")
	var player_stats: PlayerStatsScript = _main.get("_player_stats")
	if player_stats != null:
		player_stats.add_xp(50, "All Quests Bonus")

func _on_cart_grabbed() -> void:
	if _toasts != null:
		_toasts.toast_info("Cart grabbed!")

func _on_cart_dropped() -> void:
	if _toasts != null:
		_toasts.toast_info("Cart dropped. Press [G] to grab it back.")

func _toggle_quest_journal() -> void:
	if _quest_journal == null:
		return
	_quest_journal.toggle()
	if _quest_journal.visible:
		_quest_journal.refresh_from_quest_system(_quest_system)

func _on_issue_created(issue) -> void:
	var maintenance_visual = _main.get("_maintenance_visual")
	if maintenance_visual != null and maintenance_visual.has_method("build_issue_sprite"):
		maintenance_visual.build_issue_sprite(issue)

func _on_issue_resolved(issue, by_player: bool) -> void:
	var maintenance_visual = _main.get("_maintenance_visual")
	if maintenance_visual != null and maintenance_visual.has_method("remove_issue_sprite"):
		maintenance_visual.remove_issue_sprite(issue.id)
	if by_player:
		var prompt_lbl = _main.get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "Issue resolved! +10 XP"
	var player_stats: PlayerStatsScript = _main.get("_player_stats")
	if by_player and player_stats != null:
		player_stats.on_issue_resolved(issue.label)

func _on_streak_reward(days: int, bonus_xp: int) -> void:
	if _toasts != null:
		_toasts.show_toast("Daily reward! %d day streak +%d XP" % [days, bonus_xp], Color(0.92, 0.75, 0.25))

func _on_item_added_to_cart(item_data: Dictionary, _count: int = 1) -> void:
	if _toasts != null:
		_toasts.show_toast("Added to cart: " + item_data.get("name", "?"), Color(0.2, 0.8, 0.3))

func _on_browse_closed() -> void:
	pass

func _on_brand_portal_closed() -> void:
	pass

func _on_chat_panel_closed() -> void:
	pass

# ── Typed getters ────────────────────────────────────────────────
func get_toasts() -> Node:
	return _toasts

func get_floating_text() -> Node:
	return _floating_text

func get_fade() -> Node:
	return _fade

func get_minimap() -> Node:
	return _minimap

func get_daily_bonus() -> Node:
	return _daily_bonus

func get_quest_system() -> Node:
	return _quest_system

func get_quest_journal() -> Node:
	return _quest_journal

func get_shopping_list() -> Node:
	return _shopping_list

func get_stats_dashboard() -> Node:
	return _stats_dashboard

func get_map_panel() -> Node:
	return _map_panel

func get_floor_panel() -> Node:
	return _floor_panel

func get_interaction_bubble() -> Node:
	return _interaction_bubble

func get_chat_panel() -> Node:
	return _chat_panel

func get_stats_panel() -> Node:
	return _stats_panel

func get_maintenance_panel() -> Node:
	return _maintenance_panel

func get_atm_panel() -> Node:
	return _atm_panel

func get_monitor_panel() -> Node:
	return _monitor_panel

func get_settings_panel() -> Node:
	return _settings_panel

func get_pause_menu() -> Node:
	return _pause_menu

func get_tutorial_overlay() -> Node:
	return _tutorial_overlay

func get_dev_tools() -> Node:
	return _dev_tools

func get_shelf_panel() -> Node:
	return _shelf_panel

func get_save_hint_label() -> Node:
	return _save_hint_label

func get_time_label() -> Node:
	return _time_label

func get_store_status_label() -> Node:
	return _store_status_label

func get_shopping_list_count_lbl() -> Node:
	return _shopping_list_count_lbl

func get_xp_bar_bg() -> Node:
	return _xp_bar_bg

func get_xp_bar_fill() -> Node:
	return _xp_bar_fill

func get_checkout_counter_label() -> Node:
	return _checkout_counter_label

func get_checkout_items_lbl() -> Node:
	return _checkout_items_lbl

func get_checkout_total_lbl() -> Node:
	return _checkout_total_lbl

func get_floor_label() -> Node:
	return _floor_label

func is_minimap_visible() -> bool:
	return _minimap_visible

func is_shopping_list_visible() -> bool:
	return _shopping_list_visible

func get_loyalty_panel() -> Node:
	return _loyalty_panel

func get_truck_dock_node() -> Node:
	return _truck_dock_node
