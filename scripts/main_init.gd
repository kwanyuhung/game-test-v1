# main_init.gd
# All game system initialization extracted from main.gd _ready().
# main.gd's _ready() calls init_all(self) once.
extends Node

var _main: Node2D = null

func setup(main: Node2D) -> void:
	_main = main

# ── init_all: replaces the full body of main.gd's _ready() ──────────────────
func init_all() -> void:
	var m = _main
	m.add_to_group("main")

	var config = preload("res://scripts/main_config.gd").new()
	m.add_child(config)
	
	# ── Core world builder ──────────────────────────────────────────────────────
	m.set("_main_panels", preload("res://scripts/main_panels.gd").new())
	m.get("_main_panels").setup(m)

	m.set("_main_spawner", preload("res://scripts/main_spawner.gd").new())
	m.add_child(m.get("_main_spawner"))
	# FIX: Call setup() on main_spawner so _main reference is set
	m.get("_main_spawner").setup(m, config)


	# Build ground floor first
	m.set("_current_floor_idx", 0)
	# Spawn player first so NPCs can reference it
	m._spawn_player()
	m._build_floor(0)
	m._setup_camera()
	m._build_hud()
	m.get("_main_panels").build_elevator()
	m.get("_main_panels").build_stairs()
	# NPCs are now built inside _build_floor() for each floor
	m.get("_main_panels").update_floor_hud()

	# ── Game Clock ──────────────────────────────────────────────────────────────
	var game_clock = preload("res://scripts/game_clock.gd").new()
	m.add_child(game_clock)
	game_clock.hour_changed.connect(m._on_hour_changed)
	game_clock.day_changed.connect(m._on_day_changed)
	game_clock.shift_report.connect(m._on_shift_report)
	m.set("_game_clock", game_clock)

	# ── Price Override ──────────────────────────────────────────────────────────
	m.add_child(preload("res://scripts/price_override.gd").new())

	# ── Brand Manager ───────────────────────────────────────────────────────────
	var brand_manager = preload("res://scripts/brand_manager.gd").new()
	brand_manager.name = "BrandManager"
	m.add_child(brand_manager)
	m.set("_brand_manager", brand_manager)

	# ── Promotion & Loyalty ────────────────────────────────────────────────────
	var promo_manager = preload("res://scripts/promotion_manager.gd").new()
	promo_manager.name = "PromotionManager"
	m.add_child(promo_manager)
	m.set("_promo_manager", promo_manager)

	# ── Store Expansion ─────────────────────────────────────────────────────────
	var store_expansion = preload("res://scripts/store_expansion.gd").new()
	store_expansion.name = "StoreExpansion"
	m.add_child(store_expansion)
	m.set("_store_expansion", store_expansion)

	# ── Anti-Theft ──────────────────────────────────────────────────────────────
	var anti_theft = preload("res://scripts/anti_theft.gd").new()
	anti_theft.name = "AntiTheft"
	m.add_child(anti_theft)
	m.set("_anti_theft", anti_theft)

	# ── Dynamic Pricing ────────────────────────────────────────────────────────
	var dynamic_pricing = preload("res://scripts/dynamic_pricing.gd").new()
	dynamic_pricing.name = "DynamicPricing"
	m.add_child(dynamic_pricing)
	m.set("_dynamic_pricing", dynamic_pricing)

	# ── Supplier Manager ───────────────────────────────────────────────────────
	var supplier_manager = preload("res://scripts/supplier_manager.gd").new()
	supplier_manager.name = "SupplierManager"
	m.add_child(supplier_manager)
	m.set("_supplier_manager", supplier_manager)

	# ── Brand Portal ───────────────────────────────────────────────────────────
	var brand_portal = preload("res://scripts/brand_portal.gd").new()
	m.add_child(brand_portal)
	brand_portal.closed.connect(m._on_brand_portal_closed)
	m.set("_brand_portal", brand_portal)

	# ── Maintenance System ─────────────────────────────────────────────────────
	var maintenance_system = preload("res://scripts/maintenance_system.gd").new()
	m.add_child(maintenance_system)
	maintenance_system.configure(game_clock)
	maintenance_system.issue_created.connect(m._on_issue_created)
	maintenance_system.issue_resolved.connect(m._on_issue_resolved)
	m.set("_maintenance_system", maintenance_system)

	# ── Maintenance Visual ─────────────────────────────────────────────────────
	var maintenance_visual = preload("res://scripts/maintenance_visual.gd").new()
	m.add_child(maintenance_visual)
	maintenance_visual.configure(m)
	m.set("_maintenance_visual", maintenance_visual)

	# ── Warehouse System ────────────────────────────────────────────────────────
	var warehouse = preload("res://scripts/warehouse_system.gd").new()
	m.add_child(warehouse)
	warehouse.delivery_arrived.connect(m._on_warehouse_delivery_arrived)
	warehouse.low_stock_warning.connect(m._on_warehouse_low_stock)
	m.set("_warehouse", warehouse)

	# ── Player Stats ───────────────────────────────────────────────────────────
	var player_stats = preload("res://scripts/player_stats.gd").new()
	m.add_child(player_stats)
	player_stats.achievement_unlocked.connect(m._on_achievement_unlocked)
	player_stats.level_up.connect(m._on_player_level_up)
	player_stats.staff_rank_up.connect(m._on_staff_rank_up)
	m.set("_player_stats", player_stats)

	# ── Chat Manager ───────────────────────────────────────────────────────────
	var chat_manager = preload("res://scripts/chat_manager.gd").new()
	m.add_child(chat_manager)
	m.set("_chat_manager", chat_manager)
	var npcs: Array = m.get("_npcs")
	for npc in npcs:
		chat_manager.register_npc(npc)

	# ── Extracted Systems ─────────────────────────────────────────────────────
	var proximity_system = preload("res://scripts/proximity_system.gd").new()
	m.add_child(proximity_system)
	proximity_system.setup(m)
	m.set("_proximity_system", proximity_system)

	var checkout_system = preload("res://scripts/checkout_system.gd").new()
	m.add_child(checkout_system)
	checkout_system.setup(m)
	m.set("_checkout_system", checkout_system)

	var food_court_system = preload("res://scripts/food_court_system.gd").new()
	m.add_child(food_court_system)
	food_court_system.setup(m)
	m.set("_food_court_system", food_court_system)

	var truck_dock_system = preload("res://scripts/truck_dock_system.gd").new()
	m.add_child(truck_dock_system)
	truck_dock_system.setup(m)
	m.set("_truck_dock_system", truck_dock_system)

	# ── Stairs System (open-world floor navigation) ─────────────────────────────────
	var stairs_system = preload("res://scripts/stairs_system.gd").new()
	m.add_child(stairs_system)
	stairs_system.setup(m)
	m.set("_stairs_system", stairs_system)

	# ── Floor Manager (multi-floor LOD system) ────────────────────────────────────
	var floor_manager = preload("res://scripts/floor_manager.gd").new()
	m.add_child(floor_manager)
	floor_manager.setup(m)
	m.set("_floor_manager", floor_manager)

	# ── Audio Manager (singleton) ─────────────────────────────────────────────
	m.set("_audio", m.get_node_or_null("/root/Main/AudioManager"))

	# ── Save Hint Label ─────────────────────────────────────────────────────────
	var save_hint_label = Label.new()
	save_hint_label.text = ""
	save_hint_label.position = Vector2(120.0, 80.0)
	save_hint_label.add_theme_color_override("font_color", Color(0.72, 0.90, 0.72))
	save_hint_label.add_theme_font_size_override("font_size", 9)
	save_hint_label.z_index = 200
	m.add_child(save_hint_label)
	m.set("_save_hint_label", save_hint_label)

	# ── Save System load ───────────────────────────────────────────────────────
	var save_sys = preload("res://scripts/save_system.gd")
	if save_sys.load_game(m):
		m._show_save_hint("Save loaded!")
	else:
		var tutorial_overlay = preload("res://scripts/tutorial_overlay.gd").new()
		m.add_child(tutorial_overlay)
		tutorial_overlay.dismissed.connect(m._on_tutorial_dismissed)
		m.set("_tutorial_overlay", tutorial_overlay)

	# ── MiniMap ────────────────────────────────────────────────────────────────
	var minimap = preload("res://scripts/mini_map.gd").new()
	m.add_child(minimap)
	var player: Node2D = m.get("_player")
	if player:
		minimap.set_player(player)
	minimap.set_floor(0)
	minimap.visible = false
	m.set("_minimap", minimap)

	# ── Toast Manager ─────────────────────────────────────────────────────────
	var toasts = preload("res://scripts/toast_manager.gd").new()
	m.add_child(toasts)
	m.set("_toasts", toasts)

	# ── Floating Text ──────────────────────────────────────────────────────────
	var floating_text = preload("res://scripts/floating_text.gd").new()
	m.add_child(floating_text)
	m.set("_floating_text", floating_text)

	# ── Screen Fade ────────────────────────────────────────────────────────────
	var fade = preload("res://scripts/fade_transition.gd").new()
	m.add_child(fade)
	m.set("_fade", fade)

	# ── Daily Bonus ────────────────────────────────────────────────────────────
	var daily_bonus = preload("res://scripts/daily_bonus.gd").new()
	m.add_child(daily_bonus)
	daily_bonus.streak_reward.connect(m._on_streak_reward)
	daily_bonus.check_and_award(m)
	m.set("_daily_bonus", daily_bonus)

	# ── Shopping List ──────────────────────────────────────────────────────────
	var shopping_list = preload("res://scripts/shopping_list.gd").new()
	m.add_child(shopping_list)
	m.set("_shopping_list", shopping_list)

	# ── Loyalty Panel ─────────────────────────────────────────────────────────
	var loyalty_panel = Node2D.new()
	loyalty_panel.name = "LoyaltyPanel"
	loyalty_panel.visible = false
	m.add_child(loyalty_panel)
	m.set("_loyalty_panel", loyalty_panel)

	# ── Quest System & Journal ─────────────────────────────────────────────────
	var quest_system = preload("res://scripts/quest_system.gd").new()
	m.add_child(quest_system)
	quest_system.quest_completed.connect(m._on_quest_completed)
	quest_system.all_daily_complete.connect(m._on_all_quests_complete)
	m.set("_quest_system", quest_system)

	var quest_journal = preload("res://scripts/quest_journal.gd").new()
	m.add_child(quest_journal)
	quest_journal.set_quest_system(quest_system)
	quest_journal.visible = false
	m.set("_quest_journal", quest_journal)

	# ── Settings Panel ────────────────────────────────────────────────────────
	var settings_panel = preload("res://scripts/settings_panel.gd").new()
	m.add_child(settings_panel)
	settings_panel.visible = false
	settings_panel.setting_changed.connect(m._on_setting_changed)
	m.set("_settings_panel", settings_panel)

	# ── Pause Menu ────────────────────────────────────────────────────────────
	var pause_menu = preload("res://scripts/pause_menu.gd").new()
	m.add_child(pause_menu)
	pause_menu.visible = false
	pause_menu.paused.connect(m._on_game_paused)
	pause_menu.resumed.connect(m._on_game_resumed)
	m.set("_pause_menu", pause_menu)

	# ── Stats Dashboard ────────────────────────────────────────────────────────
	var stats_dashboard = preload("res://scripts/stats_dashboard.gd").new()
	m.add_child(stats_dashboard)
	stats_dashboard.visible = false
	m.set("_stats_dashboard", stats_dashboard)

	# ── Interaction Bubble ─────────────────────────────────────────────────────
	var interaction_bubble = preload("res://scripts/interaction_bubble.gd").new()
	interaction_bubble.name = "InteractionBubble"
	m.add_child(interaction_bubble)
	m.set("_interaction_bubble", interaction_bubble)
	# Setup bubble with player reference after player is spawned
	interaction_bubble.setup(m.get("_player"))

	# ── Debug Bounds System ───────────────────────────────────────────────────
	var debug_bounds = preload("res://scripts/debug_bounds.gd").new()
	debug_bounds.name = "DebugBounds"
	m.add_child(debug_bounds)
	debug_bounds.setup(m)
	m.set("_debug_bounds", debug_bounds)

	# ── Section Browse ────────────────────────────────────────────────────────
	var section_browse = preload("res://scripts/section_browse.gd").new()
	m.add_child(section_browse)
	section_browse.item_added.connect(m._on_item_added_to_cart)
	section_browse.closed.connect(m._on_browse_closed)
	m.set("_section_browse", section_browse)

	# ── Food Stall Browse ─────────────────────────────────────────────────────
	var food_stall_browse = preload("res://scripts/food_stall_browse.gd").new()
	m.add_child(food_stall_browse)
	food_stall_browse.item_added.connect(m._on_item_added_to_cart)
	m.set("_food_stall_browse", food_stall_browse)

	# Welcome toast
	toasts.show_toast("Welcome to Pixel Supermarket!", Color(0.08, 0.14, 0.22, 0.90))

	# ── Dev Tools ────────────────────────────────────────────────────────────
	if m.DEV_MODE:
		var dev_tools = preload("res://scripts/dev_tools.gd").new()
		dev_tools.set_main(m)
		dev_tools.dev_commandIssued.connect(m._on_dev_command)
		dev_tools.position = Vector2(100.0, 100.0)
		dev_tools.z_index = 1000
		m.add_child(dev_tools)

	# ── Debug Sprite Viewer ──────────────────────────────────────────────────
	var debug_viewer = preload("res://scripts/debug_sprite_viewer.gd").new()
	debug_viewer.layer = 3000
	m.add_child(debug_viewer)
	m.set("_debug_viewer", debug_viewer)

	# ── Shelf Panel ─────────────────────────────────────────────────────────
	var shelf_panel = preload("res://scripts/shelf_panel.gd").new()
	shelf_panel.layer = 2500
	shelf_panel.visible = false
	m.add_child(shelf_panel)
	m.set("_shelf_panel", shelf_panel)
