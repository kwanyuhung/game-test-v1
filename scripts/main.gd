# main.gd
# 10-floor supermarket ??data-driven world builder.
# Uses floor_config.gd for all floor/zone data.
# Uses floor_builder.gd for rendering.
extends Node2D

const FloorConfig = preload("res://scripts/floor_config.gd")
const FloorBuilderScript = preload("res://scripts/floor_builder.gd")
const SectionBrowseScript = preload("res://scripts/section_browse.gd")
const StoreData = preload("res://scripts/store_data.gd")
const ElevatorScript = preload("res://scripts/elevator.gd")
const FoodStallBrowseScript = preload("res://scripts/food_stall_browse.gd")
const ClawMachine = preload("res://scripts/claw_machine.gd")
const ActorData = preload("res://scripts/actor_data.gd")
const ChatManagerScript = preload("res://scripts/chat_manager.gd")
const ChatPanelScript = preload("res://scripts/chat_panel.gd")
const GameClockScript = preload("res://scripts/game_clock.gd")
const MaintenanceSystemScript = preload("res://scripts/maintenance_system.gd")
const MaintenanceVisualScript = preload("res://scripts/maintenance_visual.gd")
const MaintenancePanelScript = preload("res://scripts/maintenance_panel.gd")
const PlayerStatsScript = preload("res://scripts/player_stats.gd")
const StatsPanelScript = preload("res://scripts/stats_panel.gd")
const AchievementPopupScript = preload("res://scripts/achievement_popup.gd")
const WarehouseSystemScript = preload("res://scripts/warehouse_system.gd")
const ATMPanelScript = preload("res://scripts/atm_panel.gd")
const CheckoutCounterScript = preload("res://scripts/checkout_counter.gd")
const DevToolsScript = preload("res://scripts/dev_tools.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")
const MonitorPanelScript = preload("res://scripts/monitor_panel.gd")
const PriceTerminalScript = preload("res://scripts/price_terminal.gd")
const PriceOverrideScript = preload("res://scripts/price_override.gd")
const BrandManagerScript = preload("res://scripts/brand_manager.gd")
const BrandPortalScript = preload("res://scripts/brand_portal.gd")
const BusinessModeScript = preload("res://scripts/business_mode.gd")
const SaveSystem = preload("res://scripts/save_system.gd")
const TutorialOverlayScript = preload("res://scripts/tutorial_overlay.gd")
const RobotControllerScript = preload("res://scripts/robot_controller.gd")
const WarehouseFloorScript = preload("res://scripts/warehouse_floor.gd")
const DailyBonusScript = preload("res://scripts/daily_bonus.gd")
const ShoppingListScript = preload("res://scripts/shopping_list.gd")
const QuestSystemScript = preload("res://scripts/quest_system.gd")
const QuestJournalScript = preload("res://scripts/quest_journal.gd")
const SettingsPanelScript = preload("res://scripts/settings_panel.gd")
const PauseMenuScript = preload("res://scripts/pause_menu.gd")
const StatsDashboardScript = preload("res://scripts/stats_dashboard.gd")
const MiniMapScript = preload("res://scripts/mini_map.gd")
const MapPanelScript = preload("res://scripts/map_panel.gd")
const ToastManagerScript = preload("res://scripts/toast_manager.gd")
const FloatingTextScript = preload("res://scripts/floating_text.gd")
const FadeTransitionScript = preload("res://scripts/fade_transition.gd")
const ProximitySystemScript = preload("res://scripts/proximity_system.gd")
const CheckoutSystemScript = preload("res://scripts/checkout_system.gd")
const FoodCourtSystemScript = preload("res://scripts/food_court_system.gd")
const TruckDockSystemScript = preload("res://scripts/truck_dock_system.gd")
const StoreExpansionScript = preload("res://scripts/store_expansion.gd")
const AntiTheftScript = preload("res://scripts/anti_theft.gd")
const DynamicPricingScript = preload("res://scripts/dynamic_pricing.gd")
const SupplierManagerScript = preload("res://scripts/supplier_manager.gd")
const RobotPanelSystemScript = preload("res://scripts/robot_panel_system.gd")
const PromotionManagerScript = preload("res://scripts/promotion_manager.gd")
const MainSpawnerScript = preload("res://scripts/main_spawner.gd")
const MainInitScript = preload("res://scripts/main_init.gd")

const DEV_MODE := true  # Set to false to disable dev tools

const CELL_SIZE := FloorConfig.CELL_SIZE
const WORLD_W  := FloorConfig.WORLD_W
const WORLD_H  := FloorConfig.WORLD_H

var _proximity_system: Node = null
var _checkout_system: Node = null
var _food_court_system: Node = null
var _truck_dock_system: Node = null

var _player: Player
var _sections: Array = []
var _section_browse: SectionBrowse
var _current_section_browse = null
var _checkout_counters: Array = []
var _nearby_section: Node = null
var _nearby_checkout: Node = null
var _nearby_stall: Node = null
var _nearby_karaoke: bool = false         # Floor 17 karaoke room
var _nearby_pool_table: bool = false      # Floor 17 pool table
var _nearby_darts_board: bool = false    # Floor 17 darts board
var _nearby_claw_machine: ClawMachine = null
var _nearby_npc_for_chat: NPCController = null
var _npcs: Array = []
var _chat_panel: ChatPanel = null
var _chat_manager: ChatManager = null
var _game_clock: GameClock = null
var _maintenance_system: MaintenanceSystem = null
var _maintenance_visual: MaintenanceVisual = null
var _maintenance_panel: MaintenancePanel = null
var _nearby_issue: bool = false
var _target_issue: Object = null  # Issue the player is heading to resolve
var _player_stats: PlayerStats = null
var _stats_panel: StatsPanel = null
var _warehouse: WarehouseSystem = null
var _nearby_atm: bool = false
var _atm_panel: ATMPanel = null
var _audio: AudioManager = null
var _save_hint_label: Label = null
var _tutorial_overlay: TutorialOverlay = null
var _minimap: MiniMap = null
var _map_panel: MapPanel = null
var _toasts: ToastManager = null
var _minimap_visible: bool = false
var _time_label: Label = null
var _store_status_label: Label = null
var _shopping_list_count_lbl: Label = null
var _cart_gift_wrapped: bool = false  # Phase G: gift wrap applied to cart
var _xp_bar_bg: ColorRect = null
var _xp_bar_fill: ColorRect = null
var _floating_text: FloatingText = null
var _fade: FadeTransition = null
var _daily_bonus: DailyBonus = null
var _shopping_list: ShoppingList = null
var _loyalty_panel: Node2D = null
var _shopping_list_visible: bool = false
var _quest_system: QuestSystem = null
var _quest_journal: QuestJournal = null
var _settings_panel: SettingsPanel = null
var _pause_menu: PauseMenu = null
var _stats_dashboard: StatsDashboard = null

var _nearby_monitor: bool = false
var _monitor_panel: MonitorPanel = null
var _nearby_warehouse: bool = false
var _nearby_warehouse_dock: bool = false  # Floor G receiving dock
var _warehouse_mode: bool = false
var _truck_dock_node: Node2D = null       # Truck visual at receiving dock
var _truck_arrived: bool = false          # Truck currently at dock
var _dock_stock_label: Label = null       # Shows warehouse stock summary   # player is controlling warehouse equipment
var _warehouse_floor: Node2D = null
var _nearby_elevator: bool = false
var _nearby_parking: bool = false
var _nearby_stairs: bool = false
var _nearby_terminal: bool = false
var _nearby_loyalty: bool = false
var _nearby_gift_wrap: bool = false
var _nearby_digital_kiosk: bool = false
var _nearby_info_desk: bool = false
var _nearby_cafe: bool = false
var _nearby_promo_booth: bool = false  # Floor G promo booth
var _nearby_lost_found: bool = false
var _nearby_store_news: bool = false      # Floor G lost & found
var _nearby_vending: bool = false
var _in_checkout: bool = false
var _cart_panel: CanvasLayer
var _cart_items_lbl: Label
var _cart_total_lbl: Label
var _cart_count_lbl: Label
var _checkout_receipt: Control
var _checkout_counter_label: Label
var _checkout_items_lbl: Label
var _checkout_total_lbl: Label
var _checkout_receipt_visible: bool = false
var _cart_panel_visible: bool = false
var _price_terminal: PriceTerminal = null
var _staff_blocked_floor: int = -1
var _brand_manager: BrandManager = null
var _brand_portal: BrandPortal = null
var _business_mode: BusinessMode = null
var _robots: Array = []           # active AI robot staff NPCs
var _robot_panel_system: Node = null
var _robot_panel: Control = null   # robot management UI
var _temp_order_mode: String = ""  # "cafe" or "vending"
var _temp_order_items: Array = []

var _world_bg: ColorRect = null
var _aisle_labels: Array = []
var _elevator: ElevatorScript
var _main_panels: Node = null
var _main_spawner: Node = null
var _main_init: Node = null
var _promo_manager = null
var _store_expansion = null
var _anti_theft = null
var _dynamic_pricing = null
var _supplier_manager = null
var _dev_tools = null
var _stairs_node: Node2D = null
var _parking_lot: Node = null
var _current_floor_idx: int = 0
var _floor_nodes: Array = []
var _floor_ambient: Color = Color(0.18, 0.18, 0.16)
var _floor_label: Label = null
var _floor_builder: FloorBuilder
var _food_stall_browse: FoodStallBrowse
var _in_elevator: bool = false

const AISLE_NAMES := {
	"dairy":   "DAIRY",
	"produce": "PRODUCE",
	"bakery":  "BAKERY",
	"drinks":  "DRINKS",
	"snacks":  "SNACKS",
	"meat":    "MEAT / DELI",
	"pantry":  "PANTRY",
	"frozen":  "FROZEN",
}

func _ready() -> void:
	_main_init = preload("res://scripts/main_init.gd").new()
	add_child(_main_init)
	_main_init.setup(self)
	_main_init.init_all()
	# Note: _build_floor(0) is already called inside init_all()
func _build_floor(idx: int) -> void:
	_clear_floor_nodes()
	_current_floor_idx = idx
	if _player_stats != null:
		_player_stats.on_floor_visited(idx)
	# HUD labels (time, status, shopping list, XP bar)
	_main_panels.build_floor_hud(idx)
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(idx)

	# Use FloorBuilder to render this floor
	_floor_builder = FloorBuilderScript.new()
	_floor_builder.build(fd, self)

	# Collect built nodes and sections
	_floor_nodes = _floor_builder.get_floor_nodes()
	_sections = _floor_builder.get_sections()
	_checkout_counters = _floor_builder.get_checkout_counters()

	# Wire section signals
	for sec in _sections:
		if sec.has_signal("player_entered"):
			sec.player_entered.connect(_on_section_entered)
		if sec.has_signal("player_exited"):
			sec.player_exited.connect(_on_section_exited)

	# Ambient
	_floor_ambient = fd.ambient_color
	_apply_ambient_shift()
	_update_floor_hud()

	# Wire stall signals
	for stall in _floor_builder.get_food_stalls():
		if stall.has_signal("interact_requested"):
			stall.interact_requested.connect(_on_stall_interact_requested)
	# Wire claw machine signals
	for machine in _floor_builder.get_claw_machines():
		if machine.has_signal("interact_requested"):
			machine.interact_requested.connect(_on_claw_interact_requested)
		if machine.has_signal("played"):
			machine.played.connect(_on_claw_played.bind(machine))

	# Initialize warehouse floor controller (Floor 11)
	_warehouse_floor = WarehouseFloorScript.new()
	add_child(_warehouse_floor)
	_warehouse_floor.set_staff_mode(false)

	# Spawn AI robot staff across the store
	_spawn_robots()
	# Wire checkout signals
	for counter in _checkout_counters:
		if counter.has_signal("checkout_interacted"):
			counter.checkout_interacted.connect(_on_checkout_interacted)
		if counter.has_signal("express_rejected"):
			counter.express_rejected.connect(_checkout_system._on_express_rejected)
		if counter.has_signal("self_checkout_error"):
			counter.self_checkout_error.connect(_checkout_system._on_self_checkout_error)
		if counter.has_signal("self_checkout_cleared"):
			counter.self_checkout_cleared.connect(_on_self_checkout_cleared)

func _clear_floor_nodes() -> void:
	for node in _floor_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_floor_nodes.clear()
	_sections.clear()
	_checkout_counters.clear()
	_aisle_labels.clear()

	# Remove builder-rendered nodes by pattern
	var to_remove: Array = []
	for c in get_children():
		var nm := c.name as String
		if nm.begins_with("Section_") or nm.begins_with("Counter_") or nm.begins_with("Stall_") or nm.begins_with("Floor_") or nm.begins_with("Claw_"):
			to_remove.append(c)
	for c in to_remove:
		c.queue_free()

# ?????? Ambient Color ????????????????????????????????????????????????????????????????????????????????????????????

func set_ambient_floor(idx: int) -> void:
	_current_floor_idx = idx
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(idx)
	_floor_ambient = fd.ambient_color
	_apply_ambient_shift()
	_update_floor_hud()

func _apply_ambient_shift() -> void:
	if _world_bg != null:
		_world_bg.color = _floor_ambient.darkened(0.6)

# ???????????????????????????????????????????????????????????????????????????????????????????????# ELEVATOR & STAIRS
# ???????????????????????????????????????????????????????????????????????????????????????????????
func _build_elevator() -> void:
	if _main_panels != null:
		_main_panels.build_elevator()



func _build_parking() -> void:
	if _main_panels != null:
		_main_panels.build_parking()

# ?????? Player boards elevator ????????????????????????????????????????????????????????????????????????

func player_board_elevator(player, floor_idx: int) -> void:
	_in_elevator = true
	# Teleport player into elevator car
	var car_y: float = _elevator.get_car_world_y()
	_player.position = Vector2(80 * CELL_SIZE + 7 * CELL_SIZE, car_y + 5 * CELL_SIZE)

func get_elevator():
	return _elevator

# ?????? Floor reached after travel ??????????????????????????????????????????????????????????????

func _on_elevator_floor_reached(floor_idx: int) -> void:
	_current_floor_idx = floor_idx

func _on_elevator_travel_finished() -> void:
	_in_elevator = false
	if _fade != null:
		_fade.fade_out(0.2)
		await get_tree().create_timer(0.25).timeout
	_rebuild_floor(_current_floor_idx)
	if _player != null:
		_player.position = Vector2(80 * CELL_SIZE + 7 * CELL_SIZE, 20 * CELL_SIZE)
	if _fade != null:
		_fade.fade_in(0.3)
	if _minimap != null:
		_minimap.set_floor(_current_floor_idx)
	if _map_panel != null:
		_map_panel.set_floor(_current_floor_idx)
	if _toasts != null:
		var fname := "Ground" if _current_floor_idx == 0 else ("Floor " + str(_current_floor_idx))
		_toasts.toast_info("Entered: " + fname)
	if _audio != null:
		_audio.play_floor_change()

func _build_sections_for_current_floor() -> void:
	if _main_panels != null:
		_main_panels.build_sections_for_current_floor()

func _build_checkout_for_current_floor() -> void:
	if _main_panels != null:
		_main_panels.build_checkout_for_current_floor()

func _rebuild_floor(idx: int) -> void:
	_clear_floor_nodes()
	_world_bg = null
	_build_floor(idx)
	_build_sections_for_current_floor()
	_build_checkout_for_current_floor()
	# Re-add elevator on top
	_elevator = get_node_or_null("Elevator")
	if _elevator == null:
		_build_elevator()
	_apply_ambient_shift()
	_update_floor_hud()

# ???????????????????????????????????????????????????????????????????????????????????????????????# CAMERA & HUD
# ???????????????????????????????????????????????????????????????????????????????????????????????
var _camera: Camera2D = null

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.zoom = Vector2(3.0, 3.0)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = WORLD_W * CELL_SIZE
	_camera.limit_bottom = WORLD_H * CELL_SIZE
	_camera.position_smoothing_speed = 5.0
	add_child(_camera)
	_camera.make_current()

func _build_hud() -> void:
	pass  # HUD built by main_hud.gd in _ready()
func _build_checkout_receipt_panel() -> void:
	pass  # receipt panel built by main_hud.gd
func get_warehouse() -> Node:
	return _warehouse

func _update_floor_hud() -> void:
	if _main_panels != null:
		_main_panels.update_floor_hud()

# ???????????????????????????????????????????????????????????????????????????????????????????????# PLAYER & NPCS
# ???????????????????????????????????????????????????????????????????????????????????????????????
func _spawn_player() -> void:
	_main_spawner.spawn_player()

func _on_cart_updated(items: Array, subtotal: float) -> void:
	var main_hud = get_node_or_null("MainHUD")
	if main_hud != null and main_hud.has_method("update_cart"):
		main_hud.update_cart(items, subtotal)

func _build_npcs() -> void:
	_main_spawner.build_npcs()
	return
func _spawn_npc_staff(role: int, floor_idx: int, pos: Vector2) -> void:
	_main_spawner.spawn_npc_staff(role, floor_idx, pos)
	return
func _spawn_customer(group_type: int, floor_idx: int, pos: Vector2) -> void:
	_main_spawner.spawn_customer(group_type, floor_idx, pos)
	return
func _spawn_customer_group(group_type: int, floor_idx: int, pos: Vector2) -> void:
	_main_spawner.spawn_customer_group(group_type, floor_idx, pos)
	return
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# F5 ── Quick Save
			KEY_F5:
				SaveSystem.save_game(self)
				if _toasts != null: _toasts.toast_success("Game Saved!")
			# F9 ── Quick Load
			KEY_F9:
				SaveSystem.load_game(self)
				if _toasts != null: _toasts.toast_info("Game Loaded!")
			# N ── Mini-map
			#KEY_N:
				#_toggle_minimap()
			# ? ── Tutorial
			#KEY_QUESTION:
				#_show_tutorial()
			# L ── Shopping List
			KEY_L:
				_toggle_shopping_list()
			# M ── Map Panel
			KEY_M:
				_toggle_map_panel()
			# X ── Renovate nearby section (staff mode)
			KEY_X:
				_renovate_nearby_section()
			# F ── Catch thief (when suspicious activity nearby)
			KEY_F:
				_attempt_catch_thief()
			# B / Shift+B ── Brand Portal or Business Mode
			KEY_B:
				if event.shift:
					_toggle_business_mode()
				else:
					_toggle_brand_portal()
			# J ── Quest Journal
			KEY_J:
				_toggle_quest_journal()
			# R ── Robot Panel (staff only) OR Restock section
			KEY_R:
				# If near a section and in staff mode, restock it
				if _nearby_section != null and _player != null and _player.is_in_staff_mode():
					_restock_nearby_section()
				else:
					_toggle_robot_panel()
			# O ── Settings
			KEY_O:
				_toggle_settings_panel()
			# P / SPACE ── Pause / Resume
			KEY_P:
				_toggle_pause()
			KEY_SPACE:
				_toggle_pause()
			# K ── Stats Dashboard
			KEY_K:
				_toggle_stats_dashboard()
		# 1-8 ── Quick order / loyalty
		if _temp_order_mode != "":
			var key_map := {
				KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3,
				KEY_5: 4, KEY_6: 5, KEY_7: 6, KEY_8: 7
			}
			if event.keycode in key_map:
				var idx: int = key_map[event.keycode]
				if idx < _temp_order_items.size():
					var item: Dictionary = _temp_order_items[idx]
					if _temp_order_mode == "loyalty":
						_food_court_system.handle_loyalty_key(idx, item)
					else:
						_food_court_system.add_order_item(idx, item)
				return

		# Warehouse equipment controls (active when in warehouse mode)
		if _warehouse_mode and _warehouse_floor != null:
			var dir := Vector2.ZERO
			if event.keycode == KEY_W: dir = Vector2(0, -1)
			elif event.keycode == KEY_S: dir = Vector2(0, 1)
			elif event.keycode == KEY_A: dir = Vector2(-1, 0)
			elif event.keycode == KEY_D: dir = Vector2(1, 0)
			if dir != Vector2.ZERO:
				_warehouse_floor.drive_truck(dir)
				return
			if event.keycode == KEY_Q:
				_warehouse_floor.use_forklift("lower")
				return
			if event.keycode == KEY_E:
				_warehouse_floor.use_forklift("raise")
				return
			if event.keycode == KEY_F:
				_warehouse_floor.toggle_conveyor()
				return
			if event.keycode == KEY_SPACE:
				_warehouse_floor.stop_truck()
				return

func _process(_delta: float) -> void:
	# Camera follow player
	if _camera != null and _player != null:
		_camera.global_position = _player.global_position
	
	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	if _in_elevator:
		return
	_proximity_system.update_all()

	# Self-checkout error dismiss on E key
	if Input.is_action_just_pressed("interact") and _nearby_checkout != null:
		if _nearby_checkout.is_self_checkout():
			_nearby_checkout.dismiss_error()
		_checkout_system.retry_checkout(_nearby_checkout)

func _on_warehouse_delivery_arrived(contents: Dictionary) -> void:
	# Spawn truck at dock on Floor G
	_truck_dock_system.spawn_truck()

func _on_warehouse_low_stock(section_id: String) -> void:
	var section_name := section_id.to_upper()
	var msg := "Low stock warning: %s section needs restocking!" % section_name
	if _current_floor_idx == 12:  # on warehouse floor
		var prompt_lbl = get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "WARN: %s LOW STOCK" % section_name
			prompt_lbl.visible = true

func _open_atm_panel() -> void:
	if _atm_panel != null and _atm_panel.visible:
		return
	# Find the nearest ATM
	var nearest_atm = null
	for node in get_children():
		if node.has_method("is_nearby") and node.name.begins_with("ATM_"):
			if node.is_nearby(_player.position):
				nearest_atm = node
				break
	if nearest_atm == null:
		return
	_atm_panel = ATMPanelScript.new()
	add_child(_atm_panel)
	_atm_panel.open(nearest_atm)
	_atm_panel.closed.connect(_on_atm_panel_closed)
	_atm_panel.withdraw_success.connect(_on_atm_withdraw_success)

func _on_atm_panel_closed() -> void:
	_atm_panel = null

func _open_monitor_panel() -> void:
	if _monitor_panel != null and _monitor_panel.visible:
		_monitor_panel.close()
		return
	_monitor_panel = MonitorPanelScript.new()
	add_child(_monitor_panel)
	_monitor_panel.open(self)
	_monitor_panel.closed.connect(_on_monitor_panel_closed)

func _on_monitor_panel_closed() -> void:
	_monitor_panel = null


func _on_atm_withdraw_success(amount: float) -> void:
	var prompt_lbl = get_node_or_null("PromptLbl")
	if prompt_lbl != null:
		prompt_lbl.text = "Withdrew $%.2f" % amount

func _toggle_dev_tools() -> void:
	if _dev_tools == null:
		return
	if _dev_tools.visible:
		_dev_tools.close()
	else:
		_dev_tools.open()

func _on_dev_command(cmd: String, args: Dictionary) -> void:
	match cmd:
		"spawn_customers":
			var count: int = args.get("count", 5)
			_spawn_test_customers(count)
		"spawn_staff":
			var count: int = args.get("count", 3)
			_spawn_test_staff(count)
		"kill_npcs":
			_kill_all_test_npcs()

func _spawn_test_customers(count: int) -> void:
	_main_spawner.spawn_test_customers(count)
	return
func _spawn_test_staff(count: int) -> void:
	_main_spawner.spawn_test_staff(count)
	return
func _kill_all_test_npcs() -> void:
	for npc in _npcs:
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	_npcs.clear()

func _toggle_maintenance_panel() -> void:
	if _maintenance_panel != null and _maintenance_panel.visible:
		_maintenance_panel.close()
		return
	if _maintenance_system == null:
		return
	_maintenance_panel = MaintenancePanelScript.new()
	add_child(_maintenance_panel)
	_maintenance_panel.open(_maintenance_system)
	_maintenance_panel.closed.connect(_on_maintenance_panel_closed)
	_maintenance_panel.issue_selected.connect(_on_maintenance_issue_selected)

func _on_maintenance_panel_closed() -> void:
	_maintenance_panel = null

func _on_maintenance_issue_selected(issue) -> void:
	_target_issue = issue
	# Walk player to the issue's floor first if not there
	if _player != null and issue.floor != _current_floor_idx:
		_navigate_to_floor(issue.floor)

func _navigate_to_floor(floor_idx: int) -> void:
	if floor_idx == _current_floor_idx:
		return
	_current_floor_idx = floor_idx
	_rebuild_floor(floor_idx)
	if _player:
		_player.position = Vector2(80 * CELL_SIZE + 7 * CELL_SIZE, 20 * CELL_SIZE)
	if _minimap:
		_minimap.set_floor(floor_idx)
	if _toasts:
		var fname = "Ground" if floor_idx == 0 else "Floor " + str(floor_idx)
		_toasts.toast_info("Moved to " + fname)

func _on_issue_created(issue) -> void:
	if is_instance_valid(_maintenance_visual):
		_maintenance_visual.build_issue_sprite(issue)

func _on_issue_resolved(issue, by_player: bool) -> void:
	if is_instance_valid(_maintenance_visual):
		_maintenance_visual.remove_issue_sprite(issue.id)
	if by_player and _player != null:
		var prompt_lbl = get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "Issue resolved! +10 XP"
	if issue == _target_issue:
		_target_issue = null
	if by_player and _player_stats != null:
		_player_stats.on_issue_resolved(issue.label)

func _on_achievement_unlocked(ach_id: String) -> void:
	if _player_stats == null:
		return
	var info: Dictionary = _player_stats.get_achievement_info(ach_id)
	_show_achievement_popup(ach_id, info.get("name", ""), info.get("icon", "?"), info.get("xp", 20))

func _show_achievement_popup(ach_id: String, name: String, icon: String, xp: int) -> void:
	var popup := AchievementPopupScript.new()
	add_child(popup)
	popup.show_achievement(ach_id, name, icon, xp)

func _on_staff_rank_up(new_rank: PlayerStats.StaffRank) -> void:
	var rank_name := "???"
	match new_rank:
		PlayerStats.StaffRank.TRAINEE: rank_name = "Trainee"
		PlayerStats.StaffRank.WORKER: rank_name = "Worker"
		PlayerStats.StaffRank.SENIOR: rank_name = "Senior"
		PlayerStats.StaffRank.SUPERVISOR: rank_name = "Supervisor"
		PlayerStats.StaffRank.MANAGER: rank_name = "Manager"
	if _toasts:
		_toasts.toast_success("STAFF RANK UP to %s!" % rank_name)
	_update_staff_rank_hud()

func _update_staff_rank_hud() -> void:
	if _main_panels != null:
		_main_panels.update_staff_rank_hud()

func _on_player_level_up(new_level: int) -> void:
	var prompt_lbl = get_node_or_null("PromptLbl")
	if prompt_lbl != null:
		prompt_lbl.text = "LEVEL UP! You are now Level %d!" % new_level
		prompt_lbl.visible = true

func _toggle_stats_panel() -> void:
	if _stats_panel != null and _stats_panel.visible:
		_stats_panel.close()
		return
	if _player_stats == null:
		return
	_stats_panel = StatsPanelScript.new()
	add_child(_stats_panel)
	_stats_panel.open(_player_stats)
	_stats_panel.closed.connect(_on_stats_panel_closed)

func _on_stats_panel_closed() -> void:
	_stats_panel = null

func _on_hour_changed(hour: int) -> void:
	if _game_clock != null:
		var t := _game_clock.game_time_string()
		var period := _game_clock.period_name()
		if hour == 6:  # Store opens
			if _toasts != null: _toasts.toast_success("Store Open! 6:00 AM")
		if hour == 23:  # 11pm closing soon
			if _toasts != null: _toasts.toast_warn("Store Closing - 11:00 PM")

# ── Phase M: Staff Management — Day/Shift handlers ─────────────
func _on_day_changed() -> void:
	# Pay staff wages at end of each day
	if _player_stats != null:
		var wages := _player_stats.get_total_daily_wages()
		if wages > 0 and _player_stats.get_cash() >= wages:
			var remaining := _player_stats.pay_staff_wages(_player_stats.get_cash())
			if _toasts:
				_toasts.toast_info("Daily wages paid: $%.2f" % wages)
	else:
		if _toasts:
			_toasts.toast_warn("Could not pay staff wages!")

func _on_shift_report() -> void:
	# Called every in-game shift (morning/afternoon/night)
	if _player_stats != null:
		_player_stats.on_shift_completed()
		var roster := _player_stats.get_staff_roster()
		var active := roster.size()
		if _toasts:
			_toasts.toast_success("Shift complete! %d staff on duty. +30 Staff XP" % active)

func _show_tutorial_overlay() -> void:
	if _tutorial_overlay != null:
		_tutorial_overlay.queue_free()
	_tutorial_overlay = TutorialOverlayScript.new()
	add_child(_tutorial_overlay)
	_tutorial_overlay.show_tutorial()
	_tutorial_overlay.dismissed.connect(_on_tutorial_dismissed)

func _on_tutorial_dismissed() -> void:
	# Optional: save a flag that tutorial was seen
	if _player_stats:
		_player_stats.set_tutorial_completed(true)

func _toggle_shopping_list() -> void:
	if _shopping_list == null: return
	_shopping_list_visible = not _shopping_list_visible
	if _shopping_list_visible:
		_shopping_list.open()
		_toasts.toast_info("Shopping List")
	else:
		_shopping_list.close()

func add_to_shopping_list(product_name: String) -> bool:
	if _shopping_list != null:
		return _shopping_list.add_item(product_name)
	return false

func _on_quest_completed(quest_id: String, desc: String, xp: int) -> void:
	if _toasts != null:
		_toasts.toast_success("Quest Done! +%d XP" % xp)
	if _player_stats != null:
		_player_stats.add_xp(xp, "Daily Quest: %s" % desc)
		SaveSystem.save_game(self)

func _on_cart_dropped() -> void:
	if _toasts != null:
		_toasts.toast_info("Cart dropped. Press [G] to grab it back.")

func _on_cart_grabbed() -> void:
	if _toasts != null:
		_toasts.toast_info("Cart grabbed!")

func _on_all_quests_complete() -> void:
	if _toasts != null:
		_toasts.toast_xp("All Daily Quests Done! Epic Bonus!")
	if _player_stats != null:
		_player_stats.add_xp(50, "All Quests Bonus")

func _toggle_quest_journal() -> void:
	if _quest_journal == null: return
	_quest_journal.toggle()
	if _quest_journal.visible: _quest_journal.refresh_from_quest_system(_quest_system)

func _toggle_settings_panel() -> void:
	if _settings_panel == null: return
	_settings_panel.toggle()

func _on_setting_changed(key: String, value) -> void:
	match key:
		"bgm":
			if _audio != null: _audio.set_music_volume(value)
		"sfx":
			if _audio != null: _audio.set_sfx_volume(value)
		"notif_toasts":
			# Toasts are always on, just a flag
			pass

func _toggle_pause() -> void:
	if _current_section_browse != null and _current_section_browse.visible: return
	if _checkout_receipt_visible: return
	if _in_elevator: return
	if _pause_menu == null: return
	_pause_menu.toggle()

func _on_game_paused() -> void:
	if _toasts != null: _toasts.toast_info("Game Paused")

func _on_game_resumed() -> void:
	if _toasts != null: _toasts.toast_info("Game Resumed")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3-6 WIRING: Signal handlers & proximity updates that were connected
# but never implemented. These make E-key interactions actually work.
# ─────────────────────────────────────────────────────────────────────────────

# ── Section enter/exit ───────────────────────────────────────────
func _on_section_entered(section_id: String) -> void:
	# Find the section node and set it as nearby
	if _floor_builder == null:
		return
	for sec in _sections:
		if sec.get_def().id == section_id:
			_nearby_section = sec
			var prompt_lbl = get_node_or_null("PromptLbl")
			var prompt_bg = get_node_or_null("PromptBg")
			# ── Phase L: Show stock level in prompt ─────────────────
			var stock_info := ""
			if _warehouse != null:
				var ratio := _warehouse.get_stock_ratio(section_id)
				var pct := int(ratio * 100)
				var stock_color := "OK"
				if pct < 30: stock_color = "LOW"
				elif pct == 0: stock_color = "OUT"
				stock_info = " | Stock: %s (%d%%)" % [stock_color, pct]
			var reno_info := ""
			if _store_expansion != null and sec != null:
				var sec_id = sec.get_def().id
				if not _store_expansion.is_section_renovated(sec_id):
					var cost = _store_expansion.get_renovation_cost(sec_id)
					reno_info = " | [X] Renovate ($%d)" % cost
				else:
					reno_info = " | Renovated x%d" % _store_expansion.get_section_upgrade_level(sec_id)
			var staff_r := ""
			if _player != null and _player.is_in_staff_mode():
				staff_r = " | [R] Restock"
			if prompt_lbl != null:
				prompt_lbl.text = "[E] Browse %s%s%s%s" % [sec.get_def().name, stock_info, reno_info, staff_r]
				prompt_lbl.visible = true
			if prompt_bg != null:
				prompt_bg.visible = true
			break

func _on_section_exited(section_id: String) -> void:
	if _nearby_section != null and _nearby_section.get_def().id == section_id:
		_nearby_section = null

# ── Player E-key interact ───────────────────────────────────────
func _on_player_interact() -> void:
	# Priority: UI panels > checkout > section > elevator > ATM > stall > claw
	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	if _in_elevator:
		return
	if _pause_menu != null and _pause_menu.visible:
		return

	# Checkout
	if _nearby_checkout != null:
		# Dismiss self-checkout error on E, then retry
		if _nearby_checkout.has_error():
			_nearby_checkout.dismiss_error()
		_checkout_system.do_checkout(_nearby_checkout)
		return

	# Section browse
	if _nearby_section != null:
		_open_section_browse(_nearby_section)
		return

	# Elevator
	if _nearby_elevator and _elevator != null:
		_elevator.open_panel(_player.position, _player)
		return

	# ATM
	if _nearby_atm:
		_open_atm_panel()
		return

	# Price terminal (staff mode)
	if _nearby_terminal and _player != null and _player.is_in_staff_mode():
		_open_price_terminal()
		return

	# Food stall (already emits interact_requested on body enter,
	# but handle E as fallback)
	if _nearby_stall != null:
		_open_stall_browse(_nearby_stall)
		return

	# Claw machine
	if _nearby_claw_machine != null:
		_nearby_claw_machine.start_game()
		return

	# Warehouse Receiving Dock (Floor G) — truck unloading
	if _nearby_warehouse_dock:
		_truck_dock_system.do_unload()
		return
	# Warehouse Control Mode (Floor 11)
	if _nearby_warehouse:
		_handle_warehouse_interact()
		return

	# Phase 3: Interactive facilities
	if _nearby_loyalty or _nearby_gift_wrap or _nearby_digital_kiosk or _nearby_info_desk or _temp_order_mode != "" or _nearby_cafe or _nearby_vending or _nearby_promo_booth or _nearby_lost_found or _nearby_store_news or _nearby_karaoke or _nearby_pool_table or _nearby_darts_board:
		_handle_facility_interact()
		return

# ── Facility interactions (loyalty, gift wrap, kiosk, cafe, etc.) ──
func _handle_facility_interact() -> void:
	if _nearby_loyalty:
		_temp_order_mode = "loyalty"
		_temp_order_items = [{"name": "5 Coins", "price": 2.0}, {"name": "Sign Up Loyalty", "price": 0.0}]
		if _player_stats != null and _player_stats.is_loyalty_member():
			var pts = _player_stats.get_loyalty_points()
			_toasts.toast_info("Loyalty: %d pts | [1] Buy 5 Coins $2 | [2] Loyalty Status" % pts)
		else:
			_toasts.toast_info("Loyalty: [1] Sign Up Free | [2] Buy 5 Coins $2")
		var hint = get_node_or_null("PromptLbl")
		if hint != null:
			hint.text = "[1] Coins  [2] Loyalty  [E] Done"
		return
	if _nearby_gift_wrap:
		if _cart_gift_wrapped:
			if _toasts != null: _toasts.toast_info("Cart already gift wrapped!")
		else:
			_cart_gift_wrapped = true
			if _toasts != null: _toasts.toast_success("Cart gift wrapped! +$2 tip at checkout!")
		return
	if _nearby_digital_kiosk:
		if _toasts != null: _toasts.toast_info("Floor Directory: G=Lobby+Food, 1=Fresh, 2=Pantry, 3=Drinks, 4=Snacks, 5=Frozen, 6=Household, 7=H+B, 8=Arcade, 9=Staff, 10=Cafe")
		return
	if _nearby_info_desk:
		if _toasts != null: _toasts.toast_info("Welcome to Pixel Supermarket! Use elevator or stairs to navigate.")
		return
	if _temp_order_mode != "":
		_food_court_system.finish_order()
		return
	if _nearby_cafe:
		_food_court_system.open_cafe_browse()
		return
	if _nearby_vending:
		_food_court_system.open_vending_browse()
		return
	if _nearby_promo_booth:
		_food_court_system.open_promo_booth()
		return
	if _nearby_lost_found:
		if _toasts: _toasts.toast_info("Lost & Found: No items reported yet!")
		return
	if _nearby_store_news:
		_food_court_system.read_store_news()
		return
	if _nearby_karaoke:
		_food_court_system.play_karaoke()
		return
	if _nearby_pool_table:
		_food_court_system.play_pool()
		return
	if _nearby_darts_board:
		_food_court_system.play_darts()
		return

# ── Food stall interaction ──────────────────────────────────────
func _on_stall_interact_requested(stall_id: String) -> void:
	if _floor_builder == null:
		return
	for stall in _floor_builder.get_food_stalls():
		if stall.get_stall_id() == stall_id:
			_open_stall_browse(stall)
			break

func _open_stall_browse(stall) -> void:
	if _food_stall_browse != null and _food_stall_browse.visible:
		return
	#_food_stall_browse.open(stall)

func _handle_warehouse_interact() -> void:
	if _warehouse_mode:
		_warehouse_mode = false
		_warehouse_floor.set_staff_mode(false) if _warehouse_floor else null
		if _toasts: _toasts.toast_info("Exited warehouse control.")
	else:
		if _player != null and _player.is_in_staff_mode():
			_warehouse_mode = true
			if _warehouse_floor:
				_warehouse_floor.set_staff_mode(true)
			if _toasts: _toasts.toast_success("Warehouse Control Mode — use WASD/Q/E/F to operate equipment!")
		else:
			if _toasts: _toasts.toast_warning("Staff mode required for warehouse control. Press [K] to enter staff mode.")

# ── Claw machine interaction ──────────────────────────────────────
func _on_claw_interact_requested() -> void:
	if _nearby_claw_machine != null:
		_nearby_claw_machine.start_game()

func _on_claw_played(prize_name: String, won: bool, machine) -> void:
	if won and _player_stats != null:
		_player_stats.add_xp(15, "Claw machine win: %s" % prize_name)
		_player_stats.on_claw_win()
		if _toasts != null:
			_toasts.toast_success("You won a %s! +15 XP" % prize_name)
	else:
		if _toasts != null:
			_toasts.toast_info("No prize this time. Try again!")

# ── Checkout proximity & interaction ─────────────────────────────
func _on_checkout_interacted(checkout_id: int, checkout_type) -> void:
	_checkout_system.do_checkout(_nearby_checkout)

func _on_self_checkout_cleared() -> void:
	# Retry checkout after error dismissed
	_checkout_system.retry_checkout(_nearby_checkout)

# ── Section browse ──────────────────────────────────────────────
func _attempt_catch_thief() -> void:
	if _anti_theft == null or _player == null:
		return
	if _anti_theft.get_active_thefts() == 0:
		if _toasts:
			_toasts.toast_info("No suspicious activity detected")
		return
	# Try to catch any nearby suspicious NPC
	var reward = _anti_theft.catch_thief(null, true)
	if _toasts:
		_toasts.toast_success("Thief caught! +%d XP, $%.2f fine" % [reward["xp"], reward["cash"]])
	if _player_stats != null:
		_player_stats.add_xp(reward["xp"], "Caught shoplifter")
		_player_stats.add_cash(reward["cash"])

func _renovate_nearby_section() -> void:
	if _nearby_section == null or _store_expansion == null:
		return
	if not (_player != null and _player.is_in_staff_mode()):
		return
	var sec_id = _nearby_section.get_def().id
	if _store_expansion.is_section_renovated(sec_id):
		if _toasts:
			_toasts.toast_info("Section already renovated!")
		return
	var cost = _store_expansion.get_renovation_cost(sec_id)
	if _player_stats == null or _player_stats.get_cash() < cost:
		if _toasts:
			_toasts.toast_error("Need $%d to renovate!" % cost)
		return
	_player_stats.add_cash(-cost)
	_store_expansion.renovate_section(sec_id)
	if _toasts:
		_toasts.toast_success("Section renovated! +1 Rep")

func _restock_nearby_section() -> void:
	if _nearby_section == null or _warehouse == null:
		return
	var sec_def = _nearby_section.get_def()
	var sec_id = sec_def.id
	var current := _warehouse.get_stock(sec_id)
	var capacity := _warehouse.get_capacity(sec_id)
	if current >= capacity:
		if _toasts: _toasts.toast_info("%s is already fully stocked!" % sec_def.name.to_upper())
		return
	var top_up := int(capacity * 0.8) - current
	if top_up <= 0:
		top_up = capacity - current
	if top_up > 0:
		var contents := {sec_id: top_up}
		_warehouse.receive_delivery(contents)
		if _player_stats:
			_player_stats.complete_staff_task()
			_player_stats.add_staff_xp(8, "Restocked %s" % sec_def.name)
		if _toasts:
			_toasts.toast_success("Restocked %s with %d units! +8 Staff XP" % [sec_def.name, top_up])

func _open_section_browse(section) -> void:
	if _section_browse == null:
		return
	_section_browse.open_section(section)
	_current_section_browse = _section_browse

# ── Staff mode (Phase 6) ────────────────────────────────────────
func can_toggle_staff_mode() -> bool:
	return _current_floor_idx == 9

func show_staff_only_hint() -> void:
	if _toasts != null:
		_toasts.toast_info("Staff Only — Press K on Floor 9 to clock in")

func on_staff_mode_toggled(is_staff: bool) -> void:
	if is_staff:
		_staff_blocked_floor = -1  # can access all floors when staff
		if _toasts != null: _toasts.toast_success("[STAFF MODE] Clocked in!")
		# 30% chance to spawn a Scan & Go companion on Floor G
		if _current_floor_idx == 0 and randf() < 0.30:
			_spawn_scan_go_companion()
	else:
		_staff_blocked_floor = 9  # lock floor 9 again
		if _toasts != null: _toasts.toast_info("[STAFF MODE] Clocked out.")
		# Remove scan & go companion if active
		_remove_scan_go_companion()

func _spawn_scan_go_companion() -> void:
	_main_spawner.spawn_scan_go_companion()
	return
func _remove_scan_go_companion() -> void:
	_main_spawner.remove_scan_go_companion()

# ── Price terminal proximity (Phase 6) ───────────────────────────
func _open_price_terminal() -> void:
	if _price_terminal == null:
		_price_terminal = PriceTerminalScript.new()
		add_child(_price_terminal)
	_price_terminal.open()

func _toggle_brand_portal() -> void:
	if _brand_portal == null:
		return
	if _brand_portal.visible:
		_brand_portal.close()
	else:
		_brand_portal.open("ferrero")

func _toggle_business_mode() -> void:
	if _player_stats == null:
		return
	if not _player_stats.can_open_business_mode():
		var rank_name := _player_stats.get_staff_rank_name()
		var next_xp := _player_stats.get_staff_xp_for_next_rank()
		if _toasts:
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
		_business_mode.open(self, _player_stats)

func _build_business_mode() -> void:
	_business_mode = BusinessModeScript.new()
	_business_mode.visible = false
	add_child(_business_mode)

func close_business_mode() -> void:
	if _business_mode:
		_business_mode.close()

func _toggle_robot_panel() -> void:
	if _robot_panel == null:
		_robot_panel_system.build_robot_panel()
		_robot_panel = _robot_panel_system.get_robot_panel()
	if _robot_panel != null and _robot_panel.visible:
		_robot_panel.visible = false
	else:
		if _player != null and not _player.is_in_staff_mode():
			if _toasts: _toasts.toast_warning("Staff mode required for robot management. Press [K].")
			return
		if _robot_panel != null:
			_robot_panel.visible = true
		_robot_panel_system._update_robot_panel()

func _spawn_robot_humanoid(staff_role: ActorData.StaffRole) -> void:
	_main_spawner.spawn_robot_humanoid(staff_role)
	return
func _spawn_robot_single(rrole: ActorData.RobotRole) -> void:
	_main_spawner.spawn_robot_single(rrole)
	return
func _spawn_robots() -> void:
	_main_spawner.spawn_robots()
	return
func _on_brand_portal_closed() -> void:
	# Refresh any brand data that may have changed
	pass

func get_game_clock() -> Node:
	return _game_clock

# ── Phase 3: Cafe Counter Browse ────────────────────────────────
func _spawn_truck_at_dock() -> void:
	_truck_dock_system.spawn_truck()
	return

# ── Store news bulletin board ───────────────────────────────────────────────
func _toggle_stats_dashboard() -> void:
	if _stats_dashboard == null: return
	_stats_dashboard.toggle()
	if _stats_dashboard.visible:
		_stats_dashboard.refresh_from_stats(_player_stats)

# ── Map Panel (M key) ──────────────────────────────────────────────
func _toggle_map_panel() -> void:
	if _map_panel == null:
		_map_panel = MapPanelScript.new()
		add_child(_map_panel)
		_map_panel.set_player(_player)
		_map_panel.set_floor(_current_floor_idx)
	_map_panel.toggle()
		
# 每日签到奖励信号处理函数
func _on_streak_reward(days: int, bonus_xp: int) -> void:
	# 弹出奖励提示
	var toasts = get("_toasts")
	if toasts != null:
		toasts.show_toast("🎉 每日奖励！连续签到 %d 天 +%d XP" % [days, bonus_xp], Color(0.92, 0.75, 0.25))
	
	# 🔥 修复：调用我们新增的奖励音效
	var audio = get("_audio")
	if audio != null:
		audio.play_bonus()

# 商品添加到购物车（商品浏览面板信号）
func _on_item_added_to_cart(item_data: Dictionary, count: int = 1) -> void:
	# 弹出添加成功提示
	var toasts = get("_toasts")
	if toasts != null:
		toasts.show_toast("✅ 已加入购物车: " + item_data.name, Color(0.2, 0.8, 0.3))
	
	# 播放添加物品音效
	var audio = get("_audio")
	if audio != null:
		audio.play_item_add()

# 商品浏览面板关闭信号
func _on_browse_closed() -> void:
	# 面板关闭时可执行逻辑（无逻辑留空即可）
	pass
