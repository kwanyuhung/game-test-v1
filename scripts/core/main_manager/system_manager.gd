# system_manager.gd
# Phase 7 rewrite: Uses GameState for all shared state.
# This manager OWNS all systems. Proximity flags come from GameState (written by ProximitySystem).
class_name SystemManager
extends Node

# ── Preloads ────────────────────────────────────────────────────────────────────
const ProximitySystemScript = preload("res://scripts/systems/proximity_system.gd")
const CheckoutSystemScript = preload("res://scripts/systems/checkout_system.gd")
const FoodCourtSystemScript = preload("res://scripts/systems/food_court_system.gd")
const TruckDockSystemScript = preload("res://scripts/systems/truck_dock_system.gd")
const StairsSystemScript = preload("res://scripts/systems/stairs_system.gd")
const MaintenanceSystemScript = preload("res://scripts/systems/maintenance_system.gd")
const MaintenanceVisualScript = preload("res://scripts/entities/maintenance_visual.gd")
const WarehouseSystemScript = preload("res://scripts/systems/warehouse_system.gd")
const AntiTheftScriptRef = preload("res://scripts/systems/anti_theft.gd")
const DynamicPricingScriptRef = preload("res://scripts/systems/dynamic_pricing.gd")
const StoreExpansionScriptRef = preload("res://scripts/systems/store_expansion.gd")
const SupplierManagerScriptRef = preload("res://scripts/systems/supplier_manager.gd")
const PromotionManagerScriptRef = preload("res://scripts/systems/promotion_manager.gd")
const WarehouseFloorScript = preload("res://scripts/systems/warehouse_floor.gd")
const ElevatorScript = preload("res://scripts/systems/elevator.gd")
const PriceTerminalScript = preload("res://scripts/systems/price_terminal.gd")
const GameClockScript = preload("res://scripts/managers/game_clock.gd")
const PlayerStatsScript = preload("res://scripts/managers/player_stats.gd")
const ChatManagerScript = preload("res://scripts/managers/chat_manager.gd")
const BrandManagerScript = preload("res://scripts/managers/brand_manager.gd")
const BrandPortalScript = preload("res://scripts/managers/brand_portal.gd")
const BusinessModeScript = preload("res://scripts/ui/business_mode.gd")
const SaveSystem = preload("res://scripts/managers/save_system.gd")
const AudioManagerScript = preload("res://scripts/managers/audio_manager.gd")
const RobotPanelSystemScript = preload("res://scripts/managers/robot_panel_system.gd")
const StatsPanelScript = preload("res://scripts/ui/stats_panel.gd")
const MaintenancePanelScript = preload("res://scripts/ui/maintenance_panel.gd")
const ATMPanelScript = preload("res://scripts/amenities/atm_panel.gd")
const MonitorPanelScript = preload("res://scripts/ui/monitor_panel.gd")
const PriceOverrideScript = preload("res://scripts/systems/price_override.gd")
const SettingsPanelScript = preload("res://scripts/ui/settings_panel.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const StatsDashboardScript = preload("res://scripts/ui/stats_dashboard.gd")
const MapPanelScript = preload("res://scripts/ui/map_panel.gd")
const FloorPanelScript = preload("res://scripts/ui/floor_panel.gd")
const DevToolsScript = preload("res://scripts/ui/dev_tools.gd")
const ShelfPanelScript = preload("res://scripts/ui/shelf_panel.gd")
const TutorialOverlayScript = preload("res://scripts/ui/tutorial_overlay.gd")
const DailyBonusScript = preload("res://scripts/ui/daily_bonus.gd")
const QuestJournalScript = preload("res://scripts/ui/quest_journal.gd")
const AchievementPopupScript = preload("res://scripts/ui/achievement_popup.gd")
const FloatingTextScript = preload("res://scripts/ui/floating_text.gd")
const FadeTransitionScript = preload("res://scripts/ui/fade_transition.gd")
const MiniMapScript = preload("res://scripts/ui/mini_map.gd")
const InteractionBubbleScript = preload("res://scripts/ui/interaction_bubble.gd")
const ToastManagerScript = preload("res://scripts/ui/toast_manager.gd")
const QuestSystemScript = preload("res://scripts/systems/quest_system.gd")
const ShoppingListScript = preload("res://scripts/amenities/shopping_list.gd")
const ClawMachineScript = preload("res://scripts/amenities/claw_machine.gd")
const SectionBrowseScript = preload("res://scripts/world/section_browse.gd")
const FoodStallBrowseScript = preload("res://scripts/systems/food_stall_browse.gd")
const FloorConfigScript = preload("res://scripts/world/floor_config.gd")
const FloorManagerScript = preload("res://scripts/world/floor_manager.gd")

const CELL_SIZE := FloorConfigScript.CELL_SIZE

# ── References ─────────────────────────────────────────────────────────────────
var _main: Node2D = null
var _game_state: GameState = null

# ── Owned systems ──────────────────────────────────────────────────────────────
var _proximity_system: Node = null
var _checkout_system: Node = null
var _food_court_system: Node = null
var _truck_dock_system: Node = null
var _stairs_system: Node = null
var _maintenance_system: Node = null
var _maintenance_visual: Node = null
var _maintenance_panel: Node = null
var _warehouse: Node = null
var _anti_theft: Node = null
var _store_expansion: Node = null
var _dynamic_pricing: Node = null
var _supplier_manager: Node = null
var _promo_manager = null
var _elevator: Node = null
var _robot_panel_system: Node = null
var _robot_panel: Control = null
var _price_terminal: Node = null
var _business_mode: Node = null
var _brand_portal: Node = null
var _brand_manager: Node = null
var _player_stats: Node = null
var _stats_panel: Node = null
var _atm_panel: Node = null
var _monitor_panel: Node = null
var _settings_panel: Node = null
var _pause_menu: Node = null
var _stats_dashboard: Node = null
var _map_panel: Node = null
var _floor_panel: Node = null
var _floor_jump_panel: Control = null
var _interaction_bubble: Node = null
var _shopping_list: Node = null
var _toasts: Node = null
var _floating_text: Node = null
var _fade: Node = null
var _minimap: Node = null
var _daily_bonus: Node = null
var _quest_system: Node = null
var _quest_journal: Node = null
var _chat_panel: Node = null
var _chat_manager: Node = null
var _game_clock: Node = null
var _dev_tools: Node = null
var _debug_viewer: Node = null
var _shelf_panel: Node = null
var _audio: Node = null
var _tutorial_overlay: Node = null
var _save_hint_label: Node = null
var _section_browse: Node = null
var _food_stall_browse: Node = null

# ── setup(main, game_state) ────────────────────────────────────────────────────
# NOTE: Systems are created by init_all() (main_init.gd).
# This method GETS references to existing systems from _main.
func setup(main: Node2D, game_state: GameState) -> void:
	_main = main
	_game_state = game_state
	print_debug("[SystemManager] Setup started (getting existing systems)")

	# ProximitySystem — update to write to GameState
	_proximity_system = _main.get("_proximity_system")
	if _proximity_system != null and _proximity_system.has_method("setup_with_game_state"):
		_proximity_system.setup_with_game_state(_main, _game_state)

	# Get all existing systems from main
	_game_clock = _main.get("_game_clock")
	_checkout_system = _main.get("_checkout_system")
	_food_court_system = _main.get("_food_court_system")
	_truck_dock_system = _main.get("_truck_dock_system")
	_stairs_system = _main.get("_stairs_system")
	_maintenance_system = _main.get("_maintenance_system")
	_maintenance_visual = _main.get("_maintenance_visual")
	_warehouse = _main.get("_warehouse")
	_anti_theft = _main.get("_anti_theft")
	_store_expansion = _main.get("_store_expansion")
	_dynamic_pricing = _main.get("_dynamic_pricing")
	_supplier_manager = _main.get("_supplier_manager")
	_promo_manager = _main.get("_promo_manager")
	_brand_manager = _main.get("_brand_manager")
	_brand_portal = _main.get("_brand_portal")
	_price_terminal = _main.get("_price_terminal")
	_robot_panel_system = _main.get("_robot_panel_system")
	_player_stats = _main.get("_player_stats")
	_chat_manager = _main.get("_chat_manager")
	_stats_panel = _main.get("_stats_panel")
	_settings_panel = _main.get("_settings_panel")
	_pause_menu = _main.get("_pause_menu")
	_stats_dashboard = _main.get("_stats_dashboard")
	_map_panel = _main.get("_map_panel")
	_floor_panel = _main.get("_floor_panel")
	_interaction_bubble = _main.get("_interaction_bubble")
	_shopping_list = _main.get("_shopping_list")
	_toasts = _main.get("_toasts")
	_floating_text = _main.get("_floating_text")
	_fade = _main.get("_fade")
	_minimap = _main.get("_minimap")
	_daily_bonus = _main.get("_daily_bonus")
	_quest_system = _main.get("_quest_system")
	_quest_journal = _main.get("_quest_journal")
	_dev_tools = _main.get("_dev_tools")
	_shelf_panel = _main.get("_shelf_panel")
	_audio = _main.get("_audio")
	_tutorial_overlay = _main.get("_tutorial_overlay")
	_save_hint_label = _main.get("_save_hint_label")
	_section_browse = _main.get("_section_browse")
	_food_stall_browse = _main.get("_food_stall_browse")
	_elevator = _main.get("_elevator")
	_debug_viewer = _main.get("_debug_viewer")

	print_debug("[SystemManager] Setup complete")

# ── _process(delta) — main game loop ─────────────────────────────────────────────
func _process(delta: float) -> void:
	if _proximity_system != null and is_instance_valid(_proximity_system):
		_proximity_system.update_all()

	# Self-checkout error dismiss on E key — reads from GameState
	if Input.is_action_just_pressed("interact") and _game_state.nearby_checkout != null:
		var checkout: Node = _game_state.nearby_checkout
		if checkout.has_method("has_error") and checkout.has_method("dismiss_error"):
			if checkout.has_error():
				checkout.dismiss_error()
		if _checkout_system != null:
			_checkout_system.retry_checkout(checkout)

# ── E-key interact router (reads proximity from GameState) ──────────────────────────
func on_player_interact() -> void:
	var gs = _game_state
	if gs.current_section_browse != null and gs.current_section_browse.visible:
		return
	if gs.checkout_receipt_visible:
		return
	if gs.in_elevator:
		return
	if _pause_menu != null and _pause_menu.visible:
		return

	# Checkout
	if gs.nearby_checkout != null:
		if gs.nearby_checkout.has_method("has_error"):
			gs.nearby_checkout.dismiss_error()
		_checkout_system.do_checkout(gs.nearby_checkout)
		return

	# Elevator
	if gs.nearby_elevator and _elevator != null:
		var player = gs.player
		if player != null:
			_elevator.open_panel(player.position, player)
		return

	# Section browse
	if gs.nearby_section != null:
		_open_section_browse(gs.nearby_section)
		return

	# ATM
	if gs.nearby_atm:
		_open_atm_panel()
		return

	# Price terminal (staff mode)
	if gs.nearby_terminal:
		var player = gs.player
		if player != null and player.is_in_staff_mode():
			_open_price_terminal()
		return

	# Food stall
	if gs.nearby_stall != null:
		_open_stall_browse(gs.nearby_stall)
		return

	# Claw machine
	if gs.nearby_claw_machine != null:
		gs.nearby_claw_machine.start_game()
		return

	# Warehouse dock
	if gs.nearby_warehouse_dock:
		_truck_dock_system.do_unload()
		return

	# Warehouse control
	if gs.nearby_warehouse:
		_handle_warehouse_interact()
		return

	# Facility interactions
	if gs.nearby_loyalty or gs.nearby_gift_wrap or gs.nearby_digital_kiosk or gs.nearby_info_desk or gs.temp_order_mode != "" or gs.nearby_cafe or gs.nearby_vending or gs.nearby_promo_booth or gs.nearby_lost_found or gs.nearby_store_news or gs.nearby_karaoke or gs.nearby_pool_table or gs.nearby_darts_board:
		_handle_facility_interact()
		return

	# Parking
	if gs.nearby_parking:
		_handle_parking_interact()
		return

# ── Checkout signal handlers (called by WorldManager's checkout signal wiring) ──
func on_self_checkout_error() -> void:
	if _checkout_system != null and _checkout_system.has_method("_on_self_checkout_error"):
		_checkout_system.call("_on_self_checkout_error")

# ── Facility interactions ──────────────────────────────────────────────────────
func _handle_facility_interact() -> void:
	var gs = _game_state
	if gs.nearby_loyalty:
		gs.temp_order_mode = "loyalty"
		gs.temp_order_items = [{"name": "5 Coins", "price": 2.0}, {"name": "Sign Up Loyalty", "price": 0.0}]
		if _player_stats != null and _player_stats.is_loyalty_member():
			var pts = _player_stats.get_loyalty_points()
			_toasts.toast_info("Loyalty: %d pts | [1] Buy 5 Coins $2 | [2] Loyalty Status" % pts)
		else:
			_toasts.toast_info("Loyalty: [1] Sign Up Free | [2] Buy 5 Coins $2")
		var hint = _main.get_node_or_null("PromptLbl")
		if hint != null:
			hint.text = "[1] Coins  [2] Loyalty  [E] Done"
		return
	if gs.nearby_gift_wrap:
		if gs.cart_gift_wrapped:
			_toasts.toast_info("Cart already gift wrapped!")
		else:
			gs.cart_gift_wrapped = true
			_toasts.toast_success("Cart gift wrapped! +$2 tip at checkout!")
		return
	if gs.nearby_digital_kiosk:
		_toasts.toast_info("Floor Directory: G=Lobby+Food, 1=Fresh, 2=Pantry, 3=Drinks, 4=Snacks, 5=Frozen, 6=Household, 7=H+B, 8=Arcade, 9=Staff, 10=Cafe")
		return
	if gs.nearby_info_desk:
		_toasts.toast_info("Welcome to Pixel Supermarket! Use elevator or stairs to navigate.")
		return
	if gs.temp_order_mode != "":
		_food_court_system.finish_order()
		return
	if gs.nearby_cafe:
		_food_court_system.open_cafe_browse()
		return
	if gs.nearby_vending:
		_food_court_system.open_vending_browse()
		return
	if gs.nearby_promo_booth:
		_food_court_system.open_promo_booth()
		return
	if gs.nearby_lost_found:
		_toasts.toast_info("Lost & Found: No items reported yet!")
		return
	if gs.nearby_store_news:
		_food_court_system.read_store_news()
		return
	if gs.nearby_karaoke:
		_food_court_system.play_karaoke()
		return
	if gs.nearby_pool_table:
		_food_court_system.play_pool()
		return
	if gs.nearby_darts_board:
		_food_court_system.play_darts()
		return

# ── Parking ────────────────────────────────────────────────────────────────────
func _handle_parking_interact() -> void:
	var parking_lot = _main.get_node_or_null("ParkingLot")
	if parking_lot == null:
		return
	var player = _game_state.player
	if player == null:
		return
	var slot_idx = parking_lot.get_nearby_slot(player.position) if parking_lot.has_method("get_nearby_slot") else -1
	if slot_idx >= 0:
		var slot_info = parking_lot.get_slot_info(slot_idx)
		if slot_info.get("occupied", false):
			_toasts.toast_info("Parking slot %d is occupied!" % (slot_idx + 1))
		else:
			_toasts.toast_info("Parking slot %d is free!" % (slot_idx + 1))
	else:
		_toasts.toast_info("You are in the parking lot area.")

# ── Warehouse ──────────────────────────────────────────────────────────────────
func _handle_warehouse_interact() -> void:
	var gs = _game_state
	var warehouse_floor = _main.get_node_or_null("WarehouseFloor")
	if gs.warehouse_mode:
		gs.warehouse_mode = false
		if warehouse_floor:
			warehouse_floor.set_staff_mode(false)
		_toasts.toast_info("Exited warehouse control.")
	else:
		var player = gs.player
		if player != null and player.is_in_staff_mode():
			gs.warehouse_mode = true
			if warehouse_floor:
				warehouse_floor.set_staff_mode(true)
			_toasts.toast_success("Warehouse Control Mode — use WASD/Q/E/F to operate equipment!")
		else:
			_toasts.toast_warning("Staff mode required for warehouse control. Press [K] to enter staff mode.")

# ── Food stall ────────────────────────────────────────────────────────────────
func _open_stall_browse(stall) -> void:
	if _food_stall_browse != null and _food_stall_browse.visible:
		return
	var stall_def = stall.get_stall_def()
	var player = _game_state.player
	var cart = player.get_cart() if player != null else null
	_food_stall_browse.open(stall_def, cart)

# ── Section browse ──────────────────────────────────────────────────────────────
func _open_section_browse(section) -> void:
	if _section_browse == null:
		return
	_section_browse.open_section(section)
	_game_state.current_section_browse = _section_browse

# ── Claw machine ────────────────────────────────────────────────────────────────
func _on_claw_played(prize_name: String, won: bool, _machine) -> void:
	if won and _player_stats != null:
		_player_stats.add_xp(15, "Claw machine win: %s" % prize_name)
		_player_stats.on_claw_win()
		_toasts.toast_success("You won a %s! +15 XP" % prize_name)
	else:
		_toasts.toast_info("No prize this time. Try again!")

# ── Checkout ──────────────────────────────────────────────────────────────────
func _on_checkout_interacted(_checkout_id: int, _checkout_type) -> void:
	if _game_state.nearby_checkout != null:
		_checkout_system.do_checkout(_game_state.nearby_checkout)

# ── Anti-theft ────────────────────────────────────────────────────────────────
func attempt_catch_thief() -> void:
	if _anti_theft == null:
		return
	if _anti_theft.get_active_thefts() == 0:
		_toasts.toast_info("No suspicious activity detected")
		return
	var reward = _anti_theft.catch_thief(null, true)
	_toasts.toast_success("Thief caught! +%d XP, $%.2f fine" % [reward["xp"], reward["cash"]])
	if _player_stats != null:
		_player_stats.add_xp(reward["xp"], "Caught shoplifter")
		_player_stats.add_cash(reward["cash"])

# ── Renovation ────────────────────────────────────────────────────────────────
func renovate_nearby_section() -> void:
	var gs = _game_state
	if gs.nearby_section == null or _store_expansion == null:
		return
	var player = gs.player
	if player == null or not player.is_in_staff_mode():
		return
	var sec_id = gs.nearby_section.get_def().id
	if _store_expansion.is_section_renovated(sec_id):
		_toasts.toast_info("Section already renovated!")
		return
	var cost = _store_expansion.get_renovation_cost(sec_id)
	if _player_stats == null or _player_stats.get_cash() < cost:
		_toasts.toast_error("Need $%d to renovate!" % cost)
		return
	_player_stats.add_cash(-cost)
	_store_expansion.renovate_section(sec_id)
	_toasts.toast_success("Section renovated! +1 Rep")

# ── Restock ──────────────────────────────────────────────────────────────────
func restock_nearby_section() -> void:
	var gs = _game_state
	if gs.nearby_section == null or _warehouse == null:
		return
	var sec_def = gs.nearby_section.get_def()
	var sec_id = sec_def.id
	var current = _warehouse.get_stock(sec_id)
	var capacity = _warehouse.get_capacity(sec_id)
	if current >= capacity:
		_toasts.toast_info("%s is already fully stocked!" % sec_def.name.to_upper())
		return
	var top_up = int(capacity * 0.8) - current
	if top_up <= 0:
		top_up = capacity - current
	if top_up > 0:
		var contents = {sec_id: top_up}
		_warehouse.receive_delivery(contents)
		if _player_stats:
			_player_stats.complete_staff_task()
			_player_stats.add_staff_xp(8, "Restocked %s" % sec_def.name)
		_toasts.toast_success("Restocked %s with %d units! +8 Staff XP" % [sec_def.name, top_up])

# ── Stairs ────────────────────────────────────────────────────────────────────
func handle_stairs_interaction() -> void:
	var gs = _game_state
	var player = gs.player
	if _stairs_system == null or player == null:
		return
	if not _stairs_system.has_method("check_stairs_proximity"):
		return
	var proximity_result = _stairs_system.check_stairs_proximity(player.position, gs.current_floor_idx)
	if proximity_result.get("in_zone", false):
		var can_go_up: bool = proximity_result.get("can_go_up", false)
		var can_go_down: bool = proximity_result.get("can_go_down", false)
		if can_go_up and not _stairs_system.is_transitioning():
			_stairs_system.start_stairs_transition(1)
		elif can_go_down and not _stairs_system.is_transitioning():
			_stairs_system.start_stairs_transition(-1)

# ── Numbered bubble interactions ───────────────────────────────────────────────
func handle_numbered_interaction(num: int) -> void:
	if _proximity_system == null:
		return
	var interactions = _proximity_system.get_all_nearby_interactions()
	var target = null
	for interaction in interactions:
		if interaction.get("index", -1) == num:
			target = interaction
			break
	if target == null:
		return

	var gs = _game_state
	var bubble = _interaction_bubble
	if bubble != null and bubble.has_method("highlight_bubble"):
		bubble.highlight_bubble(num)

	var int_type = target.get("type", "")
	match int_type:
		"elevator":
			if _elevator != null and gs.player != null:
				_elevator.open_panel(gs.player.position, gs.player)
		"stairs":
			handle_stairs_interaction()
		"checkout":
			var t = target.get("target")
			if t != null:
				_checkout_system.do_checkout(t)
		"section":
			var t = target.get("target")
			if t != null:
				_open_section_browse(t)
		"stall":
			var t = target.get("target")
			if t != null:
				var stall_id = t.get_stall_id() if t.has_method("get_stall_id") else ""
				var floor_builder = _main.get_node_or_null("FloorBuilder")
				if floor_builder != null:
					for stall in floor_builder.get_food_stalls() if floor_builder.has_method("get_food_stalls") else []:
						if stall.get_stall_id() == stall_id:
							_open_stall_browse(stall)
							break
		"npc":
			_open_npc_chat()
		"claw":
			var t = target.get("target")
			if t != null and t.has_method("start_game"):
				t.start_game()
		"facility":
			_handle_facility_interact()
		"atm":
			_open_atm_panel()
		"warehouse":
			_handle_warehouse_interact()
		_:
			_toasts.toast_info("Interaction [%d] not yet implemented" % num)

# ── NPC Chat ──────────────────────────────────────────────────────────────────
func _open_npc_chat() -> void:
	var gs = _game_state
	var npc = gs.nearby_npc_for_chat
	if npc == null:
		return
	if _chat_panel == null:
		_chat_panel = preload("res://scripts/ui/chat_panel.gd").new()
		_main.add_child(_chat_panel)
		_chat_panel.closed.connect(_on_chat_panel_closed)
		PanelManager.register("chat", _chat_panel, PanelManager.Policy.ALONE)
	if _chat_panel.has_method("is_open") and _chat_panel._is_open:
		_chat_panel.close()
		return
	PanelManager.close_all_alone_panels()
	var actor = npc.get_actor()
	if actor == null:
		return
	var brain = npc.get("ai_brain") if npc.has("ai_brain") else null
	if brain == null:
		brain = AIChatBrain.new()
		npc.set("ai_brain", brain)
	_chat_panel.open(npc, actor, brain)

func _on_chat_panel_closed() -> void:
	pass

# ── ATM ────────────────────────────────────────────────────────────────────────
func _open_atm_panel() -> void:
	if _atm_panel != null and _atm_panel.visible:
		return
	var nearest_atm = null
	var player = _game_state.player
	for node in _main.get_children():
		if node.has_method("is_nearby") and node.name.begins_with("ATM_"):
			if player != null and node.is_nearby(player.position):
				nearest_atm = node
				break
	if nearest_atm == null:
		return
	_atm_panel = ATMPanelScript.new()
	_main.add_child(_atm_panel)
	_atm_panel.open(nearest_atm)
	_atm_panel.closed.connect(_on_atm_panel_closed)
	_atm_panel.withdraw_success.connect(_on_atm_withdraw_success)

func _on_atm_panel_closed() -> void:
	_atm_panel = null

func _on_atm_withdraw_success(amount: float) -> void:
	var lbl = _main.get_node_or_null("PromptLbl")
	if lbl != null:
		lbl.text = "Withdrew $%.2f" % amount

# ── Monitor ───────────────────────────────────────────────────────────────────
func _open_monitor_panel() -> void:
	if _monitor_panel != null and _monitor_panel.visible:
		_monitor_panel.close()
		return
	_monitor_panel = MonitorPanelScript.new()
	_main.add_child(_monitor_panel)
	_monitor_panel.open(_main)
	_monitor_panel.closed.connect(_on_monitor_panel_closed)

func _on_monitor_panel_closed() -> void:
	_monitor_panel = null

# ── Price terminal ───────────────────────────────────────────────────────────
func _open_price_terminal() -> void:
	if _price_terminal != null:
		_price_terminal.open()

# ── Dev tools ─────────────────────────────────────────────────────────────────
func toggle_dev_tools() -> void:
	if _dev_tools == null:
		return
	if _dev_tools.visible:
		_dev_tools.close()
	else:
		_dev_tools.open()

func on_dev_command(cmd: String, args: Dictionary) -> void:
	match cmd:
		"spawn_customers":
			var count: int = args.get("count", 5)
			var spawner = _main.get_node_or_null("MainSpawner")
			if spawner != null and spawner.has_method("spawn_test_customers"):
				spawner.spawn_test_customers(count)
		"spawn_staff":
			var count: int = args.get("count", 3)
			var spawner = _main.get_node_or_null("MainSpawner")
			if spawner != null and spawner.has_method("spawn_test_staff"):
				spawner.spawn_test_staff(count)
		"kill_npcs":
			var spawner = _main.get_node_or_null("MainSpawner")
			if spawner != null and spawner.has_method("kill_all_test_npcs"):
				spawner.kill_all_test_npcs()

# ── Maintenance ────────────────────────────────────────────────────────────────
func toggle_maintenance_panel() -> void:
	if _maintenance_panel != null and _maintenance_panel.visible:
		_maintenance_panel.close()
		return
	if _maintenance_system == null:
		return
	_maintenance_panel = MaintenancePanelScript.new()
	_main.add_child(_maintenance_panel)
	PanelManager.register("maintenance", _maintenance_panel, PanelManager.Policy.ALONE)
	_maintenance_panel.open(_maintenance_system)
	_maintenance_panel.closed.connect(_on_maintenance_panel_closed)
	_maintenance_panel.issue_selected.connect(_on_maintenance_issue_selected)

func _on_maintenance_panel_closed() -> void:
	_maintenance_panel = null

func _on_maintenance_issue_selected(issue) -> void:
	_game_state.target_issue = issue
	var player = _game_state.player
	if player != null and issue.floor != _game_state.current_floor_idx:
		_navigate_to_floor(issue.floor)

func _navigate_to_floor(floor_idx: int) -> void:
	if floor_idx == _game_state.current_floor_idx:
		return
	_game_state.current_floor_idx = floor_idx
	var floor_manager = _main.get_node_or_null("FloorManager")
	var player = _game_state.player
	if floor_manager != null:
		floor_manager.on_floor_changed(floor_idx)
	if player != null:
		player.position = _main.elevator_arrival_position(floor_idx)
	if _minimap != null:
		_minimap.set_floor(floor_idx)
	var fname = "Ground" if floor_idx == 0 else "Floor " + str(floor_idx)
	_toasts.toast_info("Moved to " + fname)

# ── Shopping list ──────────────────────────────────────────────────────────────
func toggle_shopping_list() -> void:
	if _shopping_list == null:
		return
	var visible = not _shopping_list.visible
	_shopping_list.visible = visible
	if visible:
		_shopping_list.open()
		_toasts.toast_info("Shopping List")
	else:
		_shopping_list.close()

func add_to_shopping_list(product_name: String) -> bool:
	if _shopping_list != null:
		return _shopping_list.add_item(product_name)
	return false

# ── Stats dashboard ────────────────────────────────────────────────────────────
func toggle_stats_dashboard() -> void:
	if _stats_dashboard == null:
		return
	_stats_dashboard.toggle()
	if _stats_dashboard.visible:
		_stats_dashboard.refresh_from_stats(_player_stats)

# ── Map panel ─────────────────────────────────────────────────────────────────
func toggle_map_panel() -> void:
	if _map_panel == null:
		_map_panel = MapPanelScript.new()
		_main.add_child(_map_panel)
		_map_panel.set_player(_game_state.player)
		_map_panel.set_main(_main)
		_map_panel.set_floor(_game_state.current_floor_idx)
		PanelManager.register("map", _map_panel, PanelManager.Policy.ALONE)
	_map_panel.toggle()

# ── Floor panel ───────────────────────────────────────────────────────────────
func toggle_floor_panel() -> void:
	if _floor_panel == null:
		_floor_panel = FloorPanelScript.new()
		_main.add_child(_floor_panel)
		_floor_panel.set_owner_node(_main)
		_floor_panel.set_floor(_game_state.current_floor_idx)
		PanelManager.register("floor", _floor_panel, PanelManager.Policy.ALONE)
	PanelManager.toggle("floor")
	if _floor_panel.visible:
		_floor_panel.set_floor(_game_state.current_floor_idx)

# ── Floor jump panel ──────────────────────────────────────────────────────────
func toggle_floor_jump_panel() -> void:
	if _floor_jump_panel != null and _floor_jump_panel.visible:
		_close_floor_jump_panel()
		return

	_floor_jump_panel = Control.new()
	_floor_jump_panel.set_anchors_preset(Control.PRESET_CENTER)
	_floor_jump_panel.position = Vector2(-150.0, -180.0)
	_floor_jump_panel.set_deferred("size", Vector2(300.0, 360.0))
	_floor_jump_panel.gui_input.connect(_on_floor_jump_panel_input)
	_main.add_child(_floor_jump_panel)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08, 0.95)
	_floor_jump_panel.add_child(bg)

	var hdr := Label.new()
	hdr.text = "=== FLOOR JUMP ==="
	hdr.position = Vector2(70.0, 10.0)
	hdr.add_theme_color_override("font_color", Color(0.88, 0.82, 0.60))
	hdr.add_theme_font_size_override("font_size", 12)
	_floor_jump_panel.add_child(hdr)

	var floor_count := FloorConfigScript.floor_count()
	var cols := 5
	var btn_w := 50.0
	var btn_h := 30.0
	var start_x := 15.0
	var start_y := 40.0
	var gap_x := 5.0
	var gap_y := 5.0

	for i in range(floor_count):
		var col = i % cols
		var row = i / float(cols)
		var bx = start_x + col * (btn_w + gap_x)
		var by = start_y + row * (btn_h + gap_y)
		var floor_label = "G" if i == 0 else str(i)
		var is_current = (i == _game_state.current_floor_idx)

		var btn := ColorRect.new()
		btn.position = Vector2(bx, by)
		btn.set_deferred("size", Vector2(btn_w, btn_h))
		btn.color = Color(0.18, 0.40, 0.25) if is_current else Color(0.22, 0.20, 0.28)
		_floor_jump_panel.add_child(btn)

		var lbl := Label.new()
		lbl.text = "Floor %s" % floor_label
		lbl.position = Vector2(bx + 4, by + 8)
		var lbl_color = Color(0.50, 0.95, 0.60) if is_current else Color(0.90, 0.88, 0.80)
		lbl.add_theme_color_override("font_color", lbl_color)
		lbl.add_theme_font_size_override("font_size", 10)
		_floor_jump_panel.add_child(lbl)

		btn.set_meta("floor_idx", i)
		btn.gui_input.connect(_on_floor_jump_btn_input)

func _on_floor_jump_panel_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k = event as InputEventKey
		if k.keycode == KEY_ESCAPE or k.keycode == KEY_T:
			_close_floor_jump_panel()

func _on_floor_jump_btn_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var btn = event.get_parent() as Control
		if btn != null and btn.has_meta("floor_idx"):
			var idx: int = btn.get_meta("floor_idx")
			_close_floor_jump_panel()
			jump_to_floor(idx)

func _close_floor_jump_panel() -> void:
	if _floor_jump_panel != null:
		_floor_jump_panel.queue_free()
		_floor_jump_panel = null

func jump_to_floor(floor_idx: int) -> void:
	var max_floors = FloorConfigScript.floor_count()
	if floor_idx < 0 or floor_idx >= max_floors:
		_toasts.toast_warning("Invalid floor! Range: 0-%d" % (max_floors - 1))
		return

	_game_state.current_floor_idx = floor_idx
	var floor_manager = _main.get_node_or_null("FloorManager")
	var camera = _main.get_node_or_null("Camera2D")
	var player = _game_state.player

	if floor_manager != null:
		floor_manager.on_floor_changed(floor_idx)
	if camera != null and camera.has_method("update_camera_limits"):
		camera.update_camera_limits(floor_idx)
	if player != null:
		player.position = _main.elevator_arrival_position(floor_idx)
	if _minimap != null:
		_minimap.set_floor(floor_idx)
	if _map_panel != null:
		_map_panel.set_floor(floor_idx)
	var fname = "Ground" if floor_idx == 0 else ("Floor " + str(floor_idx))
	_toasts.toast_success("[DEBUG] Jumped to " + fname)

# ── Brand / Business ──────────────────────────────────────────────────────────
func toggle_brand_portal() -> void:
	if _brand_portal == null:
		return
	if _brand_portal.visible:
		_brand_portal.close()
	else:
		_brand_portal.open("ferrero")

func toggle_business_mode() -> void:
	if _player_stats == null:
		return
	if not _player_stats.can_open_business_mode():
		var next_xp = _player_stats.get_staff_xp_for_next_rank()
		if next_xp > 0:
			_toasts.toast_warning("Business Mode unlocks at Supervisor rank. %d more Staff XP needed!" % next_xp)
		else:
			_toasts.toast_warning("Business Mode unlocks at Supervisor rank. Keep earning Staff XP!")
		return
	if _business_mode == null:
		_build_business_mode()
	if _business_mode.visible:
		_business_mode.close()
	else:
		_business_mode.open(_main, _player_stats)

func _build_business_mode() -> void:
	_business_mode = BusinessModeScript.new()
	_business_mode.visible = false
	_main.add_child(_business_mode)

# ── Robot panel ────────────────────────────────────────────────────────────────
func toggle_robot_panel() -> void:
	if _robot_panel_system == null:
		return
	if _robot_panel == null:
		_robot_panel_system.build_robot_panel()
		_robot_panel = _robot_panel_system.get_robot_panel()
		PanelManager.register("robot", _robot_panel_system, PanelManager.Policy.ALONE)
	if _robot_panel != null and _robot_panel.visible:
		_robot_panel_system.hide_panel()
	else:
		var player = _game_state.player
		if player != null and not player.is_in_staff_mode():
			_toasts.toast_warning("Staff mode required for robot management. Press [K].")
			return
		if _robot_panel != null:
			_robot_panel_system.show_panel()
		_robot_panel_system._update_robot_panel()

# ── Stats panel ────────────────────────────────────────────────────────────────
func toggle_stats_panel() -> void:
	if _stats_panel != null and _stats_panel.visible:
		_stats_panel.close()
		return
	if _player_stats == null:
		return
	_stats_panel = StatsPanelScript.new()
	_main.add_child(_stats_panel)
	PanelManager.register("stats", _stats_panel, PanelManager.Policy.ALONE)
	_stats_panel.open(_player_stats)
	_stats_panel.closed.connect(_on_stats_panel_closed)

func _on_stats_panel_closed() -> void:
	_stats_panel = null

# ── Pause ──────────────────────────────────────────────────────────────────────
func toggle_pause() -> void:
	var gs = _game_state
	if gs.current_section_browse != null and gs.current_section_browse.visible:
		return
	if gs.checkout_receipt_visible:
		return
	if gs.in_elevator:
		return
	if _pause_menu == null:
		return
	_pause_menu.toggle()

# ── Settings ──────────────────────────────────────────────────────────────────
func on_setting_changed(key: String, value) -> void:
	match key:
		"bgm":
			if _audio != null:
				_audio.set_music_volume(value)
		"sfx":
			if _audio != null:
				_audio.set_sfx_volume(value)
		"draw_factory_robot_1", "draw_factory_robot_2", "draw_factory_robot_3":
			_apply_factory_robot_settings()
		"draw_interactive":
			_apply_interactive_settings(value)

func _apply_factory_robot_settings() -> void:
	var warehouse_floor = _main.get_node_or_null("WarehouseFloor")
	if warehouse_floor == null or _settings_panel == null:
		return
	var r1: bool = _settings_panel.get_setting("draw_factory_robot_1")
	var r2: bool = _settings_panel.get_setting("draw_factory_robot_2")
	var r3: bool = _settings_panel.get_setting("draw_factory_robot_3")
	warehouse_floor.set_factory_robot_visibility(r1, r2, r3)

func _apply_interactive_settings(enabled: bool) -> void:
	if _interaction_bubble != null and _interaction_bubble.has_method("set_interaction_visible"):
		_interaction_bubble.set_interaction_visible(enabled)

# ── Shelf panel ────────────────────────────────────────────────────────────────
func toggle_shelf_panel() -> void:
	if _shelf_panel != null:
		_shelf_panel.toggle()

# ── Input blocked ──────────────────────────────────────────────────────────────
func is_input_blocked() -> bool:
	return PanelManager.is_input_blocked()

# ── Warehouse delivery ──────────────────────────────────────────────────────────
func on_warehouse_delivery_arrived(_contents: Dictionary) -> void:
	_truck_dock_system.spawn_truck()

func on_warehouse_low_stock(section_id: String) -> void:
	if _game_state.current_floor_idx == 12:
		var lbl = _main.get_node_or_null("PromptLbl")
		if lbl != null:
			lbl.text = "WARN: %s LOW STOCK" % section_id.to_upper()
			lbl.visible = true

# ── Signal wiring helpers ────────────────────────────────────────────────────────
func wire_maintenance_signals(maintenance_system: Node) -> void:
	if maintenance_system.has_signal("issue_created"):
		pass  # connected in main_init

func connect_maintenance_signals(maintenance_system: Node) -> void:
	if maintenance_system.has_signal("issue_resolved"):
		pass  # connected in main_init

# ── Getters ──────────────────────────────────────────────────────────────────
func get_proximity_system() -> Node:
	return _proximity_system
func get_checkout_system() -> Node:
	return _checkout_system
func get_food_court_system() -> Node:
	return _food_court_system
func get_truck_dock_system() -> Node:
	return _truck_dock_system
func get_stairs_system() -> Node:
	return _stairs_system
func get_maintenance_system() -> Node:
	return _maintenance_system
func get_warehouse() -> Node:
	return _warehouse
func get_anti_theft() -> Node:
	return _anti_theft
func get_store_expansion() -> Node:
	return _store_expansion
func get_dynamic_pricing() -> Node:
	return _dynamic_pricing
func get_supplier_manager() -> Node:
	return _supplier_manager
func get_promo_manager():
	return _promo_manager
func get_elevator() -> Node:
	return _elevator
func get_robot_panel_system() -> Node:
	return _robot_panel_system
func get_price_terminal() -> Node:
	return _price_terminal
func get_business_mode() -> Node:
	return _business_mode
func get_brand_portal() -> Node:
	return _brand_portal
func get_brand_manager() -> Node:
	return _brand_manager
func get_player_stats() -> Node:
	return _player_stats
func get_chat_manager() -> Node:
	return _chat_manager
func get_game_clock() -> Node:
	return _game_clock
func get_toasts() -> Node:
	return _toasts
func get_minimap() -> Node:
	return _minimap
func get_interaction_bubble() -> Node:
	return _interaction_bubble
func get_shopping_list() -> Node:
	return _shopping_list
func get_settings_panel() -> Node:
	return _settings_panel
func get_pause_menu() -> Node:
	return _pause_menu
func get_stats_dashboard() -> Node:
	return _stats_dashboard
func get_map_panel() -> Node:
	return _map_panel
func get_floor_panel() -> Node:
	return _floor_panel
func get_audio() -> Node:
	return _audio
func get_main() -> Node2D:
	return _main
func get_game_state() -> GameState:
	return _game_state
