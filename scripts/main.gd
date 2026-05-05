# main.gd
# 10-floor supermarket ??data-driven world builder.
# Uses floor_config.gd for all floor/zone data.
# Uses floor_builder.gd for rendering.
extends Node2D

const FloorConfig = preload("res://scripts/floor_config.gd")
const FloorBuilderScript = preload("res://scripts/floor_builder.gd")
const SectionBrowseScript = preload("res://scripts/section_browse.gd")
const StoreData = preload("res://scripts/store_data.gd")
const TelegramBot = preload("res://scripts/telegram_bot.gd")
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
const ToastManagerScript = preload("res://scripts/toast_manager.gd")
const FloatingTextScript = preload("res://scripts/floating_text.gd")
const FadeTransitionScript = preload("res://scripts/fade_transition.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")

const DEV_MODE := true  # Set to false to disable dev tools

const CELL_SIZE := FloorConfig.CELL_SIZE
const WORLD_W  := FloorConfig.WORLD_W
const WORLD_H  := FloorConfig.WORLD_H

var _player: Player
var _sections: Array = []
var _section_browse: SectionBrowse
var _current_section_browse = null
var _checkout_counters: Array = []
var _nearby_section: Node = null
var _nearby_checkout: Node = null
var _nearby_stall: Node = null
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
var _toasts: ToastManager = null
var _minimap_visible: bool = false
var _time_label: Label = null
var _store_status_label: Label = null
var _shopping_list_count_lbl: Label = null
var _xp_bar_bg: ColorRect = null
var _xp_bar_fill: ColorRect = null
var _floating_text: FloatingText = null
var _fade: FadeTransition = null
var _daily_bonus: DailyBonus = null
var _shopping_list: ShoppingList = null
var _shopping_list_visible: bool = false
var _quest_system: QuestSystem = null
var _quest_journal: QuestJournal = null
var _settings_panel: SettingsPanel = null
var _pause_menu: PauseMenu = null
var _stats_dashboard: StatsDashboard = null
var _shopping_list_visible: bool = false
var _audio: AudioManager = null

var _nearby_monitor: bool = false
var _monitor_panel: MonitorPanel = null
var _nearby_warehouse: bool = false
var _warehouse_mode: bool = false   # player is controlling warehouse equipment
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
var _robot_panel: Control = null   # robot management UI
var _temp_order_mode: String = ""  # "cafe" or "vending"
var _temp_order_items: Array = []

var _world_bg: ColorRect = null
var _aisle_labels: Array = []
var _telegram_bot: Node = null
var _elevator: ElevatorScript
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
	add_to_group("main")  # allow NPCs to find main node
	_telegram_bot = get_node_or_null("/root/Main/TelegramBot")

	# Build ground floor (G) first
	_current_floor_idx = 0
	_build_floor(_current_floor_idx)
	_setup_camera()
	_build_hud()
	_build_elevator()
	_build_stairs()
	_spawn_player()
	_build_npcs()
	_update_floor_hud()

	# ?? Game Clock & Maintenance System ??
	_game_clock = GameClockScript.new()
	add_child(_game_clock)
	_game_clock.hour_changed.connect(_on_hour_changed)
	_game_clock.day_changed.connect(_on_day_changed)
	_game_clock.shift_report.connect(_on_shift_report)

	# ── Price Override Singleton (Phase 6) ──
	var price_override = PriceOverrideScript.new()
	add_child(price_override)

	# ── Brand Manager ──
	_brand_manager = BrandManagerScript.new()
	_brand_manager.name = "BrandManager"
	add_child(_brand_manager)
	_brand_portal = BrandPortalScript.new()
	add_child(_brand_portal)
	_brand_portal.closed.connect(_on_brand_portal_closed)

	_maintenance_system = MaintenanceSystemScript.new()
	add_child(_maintenance_system)
	_maintenance_system.configure(_game_clock)
	_maintenance_system.issue_created.connect(_on_issue_created)
	_maintenance_system.issue_resolved.connect(_on_issue_resolved)

	_maintenance_visual = MaintenanceVisualScript.new()
	add_child(_maintenance_visual)
	_maintenance_visual.configure(self)

	# ?? Warehouse System ??
	_warehouse = WarehouseSystemScript.new()
	add_child(_warehouse)
	_warehouse.delivery_arrived.connect(_on_warehouse_delivery_arrived)
	_warehouse.low_stock_warning.connect(_on_warehouse_low_stock)

	# ?? Player Stats & Progression ??
	_player_stats = PlayerStatsScript.new()
	add_child(_player_stats)
	_player_stats.achievement_unlocked.connect(_on_achievement_unlocked)
	_player_stats.level_up.connect(_on_player_level_up)
	_player_stats.staff_rank_up.connect(_on_staff_rank_up)

	# Start chat manager
	_chat_manager = ChatManagerScript.new()
	add_child(_chat_manager)
	for npc in _npcs:
		_chat_manager.register_npc(npc)

	notify_telegram("🟢 *Game Loaded*\n10-floor supermarket — Ground (G) ready\nUse [E] near elevator to change floors")

	# ── Audio Manager ──
	_audio = get_node_or_null("/root/Main/AudioManager")

	# ── Save Hint Label ──
	_save_hint_label = Label.new()
	_save_hint_label.text = ""
	_save_hint_label.position = Vector2(120.0, 80.0)
	_save_hint_label.add_theme_color_override("font_color", Color(0.72, 0.90, 0.72))
	_save_hint_label.add_theme_font_size_override("font_size", 9)
	_save_hint_label.z_index = 200
	add_child(_save_hint_label)

	# ── Try Load Save ──
	if SaveSystem.load_game(self):
		_show_save_hint("Save loaded!")
		notify_telegram("📁 *Save loaded* — resuming game")
	else:
		notify_telegram("📋 *New game* — no save found")
		_tutorial_overlay = TutorialOverlayScript.new()
		add_child(_tutorial_overlay)
	_tutorial_overlay.dismissed.connect(_on_tutorial_dismissed)
	# ── MiniMap ──
	_minimap = MiniMapScript.new()
	add_child(_minimap)
	_minimap.set_player(_player)
	_minimap.set_floor(_current_floor_idx)
	_minimap.visible = false
	# ── Toast Manager ──
	_toasts = ToastManagerScript.new()
	add_child(_toasts)
	# ── Floating Text ──
	_floating_text = FloatingTextScript.new()
	add_child(_floating_text)
	# ── Screen Fade ──
	_fade = FadeTransitionScript.new()
	add_child(_fade)
	_daily_bonus = DailyBonusScript.new()
	add_child(_daily_bonus)
	_daily_bonus.streak_reward.connect(_on_streak_reward)
	_daily_bonus.check_and_award(self)
	_shopping_list = ShoppingListScript.new()
	add_child(_shopping_list)
	_quest_system = QuestSystemScript.new()
	add_child(_quest_system)
	_quest_journal = QuestJournalScript.new()
	add_child(_quest_journal)
	_settings_panel = SettingsPanelScript.new()
	add_child(_settings_panel)
	_pause_menu = PauseMenuScript.new()
	add_child(_pause_menu)
	_pause_menu.visible = false
	_pause_menu.paused.connect(_on_game_paused)
	_stats_dashboard = StatsDashboardScript.new()
	add_child(_stats_dashboard)
	_stats_dashboard.visible = false
	_pause_menu.resumed.connect(_on_game_resumed)
	_settings_panel.visible = false
	_settings_panel.setting_changed.connect(_on_setting_changed)
	_quest_journal.set_quest_system(_quest_system)
	_quest_journal.visible = false
	_quest_system.quest_completed.connect(_on_quest_completed)
	_quest_system.all_daily_complete.connect(_on_all_quests_complete)
	_shopping_list.visible = false
	# ── Section Browse Panel ──
	_section_browse = SectionBrowseScript.new()
	add_child(_section_browse)
	_section_browse.item_added.connect(_on_item_added_to_cart)
	_section_browse.closed.connect(_on_browse_closed)
	# ── Food Stall Browse Panel ──
	_food_stall_browse = FoodStallBrowseScript.new()
	add_child(_food_stall_browse)
	_food_stall_browse.item_added.connect(_on_item_added_to_cart)
	# Welcome toast
	_toasts.show_toast("Welcome to Pixel Supermarket!", Color(0.08, 0.14, 0.22, 0.90))
		_tutorial_overlay.show_tutorial()
		_tutorial_overlay.dismissed.connect(_on_tutorial_dismissed)
	# ── Dev Tools (dev mode only) ──
	if DEV_MODE:
		_dev_tools = DevToolsScript.new()
		_dev_tools.set_main(self)
		_dev_tools.dev_commandIssued.connect(_on_dev_command)
		_dev_tools.position = Vector2(100.0, 100.0)
		_dev_tools.z_index = 1000
		add_child(_dev_tools)

# ???????????????????????????????????????????????????????????????????????????????????????????????# FLOOR BUILDING ??data-driven via FloorBuilder
# ???????????????????????????????????????????????????????????????????????????????????????????????
func _build_floor(idx: int) -> void:
	_clear_floor_nodes()
	_current_floor_idx = idx
	if _player_stats != null:
		_player_stats.on_floor_visited(idx)
	if _time_label == null:
		_time_label = Label.new()
		_time_label.name = "TimeLabelHUD"
		_time_label.position = Vector2(268.0, 4.0)
		_time_label.add_theme_color_override("font_color", Color(0.60, 0.70, 0.90))
		_time_label.add_theme_font_size_override("font_size", 8)
		_time_label.z_index = 10
		add_child(_time_label)
	if _game_clock != null:
		var h = _game_clock.game_hour
		var m = _game_clock.game_minute
		_time_label.text = "%02d:%02d" % [h, m]
	# Store status label
	if _store_status_label == null:
		_store_status_label = Label.new()
		_store_status_label.position = Vector2(268.0, 14.0)
		_store_status_label.add_theme_color_override("font_color", Color(0.60, 0.90, 0.60))
		_store_status_label.add_theme_font_size_override("font_size", 8)
		_store_status_label.z_index = 10
		add_child(_store_status_label)
	if _game_clock != null:
		var is_open = _game_clock.is_store_open()
		_store_status_label.text = "OPEN" if is_open else "CLOSED"
		if is_open:
			_store_status_label.add_theme_color_override("font_color", Color(0.50, 0.90, 0.50))
		else:
	# Shopping list count label
	if _shopping_list_count_lbl == null:
		_shopping_list_count_lbl = Label.new()
		_shopping_list_count_lbl.position = Vector2(268.0, 24.0)
		_shopping_list_count_lbl.add_theme_color_override("font_color", Color(0.55, 0.70, 0.90))
		_shopping_list_count_lbl.add_theme_font_size_override("font_size", 7)
		_shopping_list_count_lbl.z_index = 10
		add_child(_shopping_list_count_lbl)
	if _shopping_list != null:
		var count = _shopping_list.get_items().size()
		_shopping_list_count_lbl.text = "List: %d" % count if count > 0 else ""
			_store_status_label.add_theme_color_override("font_color", Color(0.90, 0.50, 0.50))
	# XP progress bar (below cart count)
	if _xp_bar_bg == null:
		_xp_bar_bg = ColorRect.new()
		_xp_bar_bg.position = Vector2(4.0, 20.0)
		_xp_bar_bg.size = Vector2(70.0, 4.0)
		_xp_bar_bg.color = Color(0.15, 0.15, 0.20, 0.80)
		_xp_bar_bg.z_index = 10
		add_child(_xp_bar_bg)
		_xp_bar_fill = ColorRect.new()
		_xp_bar_fill.position = Vector2(4.0, 20.0)
		_xp_bar_fill.size = Vector2(0.0, 4.0)
		_xp_bar_fill.color = Color(0.40, 0.85, 0.50)
		_xp_bar_fill.z_index = 11
		add_child(_xp_bar_fill)
	if _player_stats != null:
		var progress = _player_stats.xp_progress()
		_xp_bar_fill.size.x = max(0.0, 70.0 * progress)
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
			counter.express_rejected.connect(_on_express_rejected)
		if counter.has_signal("self_checkout_error"):
			counter.self_checkout_error.connect(_on_self_checkout_error)
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
	_elevator = ElevatorScript.new()
	_elevator.name = "Elevator"
	_elevator.floor_reached.connect(_on_elevator_floor_reached)
	_elevator.travel_finished.connect(_on_elevator_travel_finished)
	add_child(_elevator)

func _build_stairs() -> void:
	# Stairs node (not animated, just visual reference + proximity)
	_stairs_node = Node2D.new()
	_stairs_node.name = "Stairs"
	add_child(_stairs_node)

func _build_parking() -> void:
	_parking_lot = ParkingLotScript.new()
	_parking_lot.name = "ParkingLot"
	add_child(_parking_lot)

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
	if _toasts != null:
		var fname := "Ground" if _current_floor_idx == 0 else ("Floor " + str(_current_floor_idx))
		_toasts.toast_info("Entered: " + fname)
	if _audio != null:
		_audio.play_floor_change()
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
func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(3.0, 3.0)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = WORLD_W * CELL_SIZE
	cam.limit_bottom = WORLD_H * CELL_SIZE
	cam.position_smoothing_speed = 3.0
	add_child(cam)
	cam.make_current()

func _build_hud() -> void:
	# Cart count top-left
	var cart_bg := ColorRect.new()
	cart_bg.position = Vector2(4.0, 4.0)
	cart_bg.size = Vector2(70.0, 16.0)
	cart_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	add_child(cart_bg)

	var cart_icon := Label.new()
	cart_icon.text = "Cart:"
	cart_icon.position = Vector2(6.0, 5.0)
	cart_icon.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	cart_icon.add_theme_font_size_override("font_size", 8)
	add_child(cart_icon)

	_cart_count_lbl = Label.new()
	_cart_count_lbl.text = "0 items  $0.00"
	_cart_count_lbl.position = Vector2(30.0, 5.0)
	_cart_count_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	_cart_count_lbl.add_theme_font_size_override("font_size", 8)
	add_child(_cart_count_lbl)

	# Zone prompt bottom center
	var prompt_bg := ColorRect.new()
	prompt_bg.name = "PromptBg"
	prompt_bg.position = Vector2(100.0, 164.0)
	prompt_bg.size = Vector2(120.0, 14.0)
	prompt_bg.color = Color(0.06, 0.06, 0.09, 0.85)
	prompt_bg.visible = false
	add_child(prompt_bg)

	var prompt_lbl := Label.new()
	prompt_lbl.name = "PromptLbl"
	prompt_lbl.text = "[E] Browse"
	prompt_lbl.position = Vector2(104.0, 166.0)
	prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.42))
	prompt_lbl.add_theme_font_size_override("font_size", 8)
	prompt_lbl.visible = false
	add_child(prompt_lbl)

	# Checkout label
	_checkout_counter_label = Label.new()
	_checkout_counter_label.text = ""
	_checkout_counter_label.position = Vector2(100.0, 150.0)
	_checkout_counter_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.72))
	_checkout_counter_label.add_theme_font_size_override("font_size", 9)
	_checkout_counter_label.visible = false
	add_child(_checkout_counter_label)

	# Tab hint bottom right
	var tab_hint := Label.new()
	tab_hint.name = "TabHint"
	tab_hint.text = "[TAB] Cart"
	tab_hint.position = Vector2(264.0, 4.0)
	tab_hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	tab_hint.add_theme_font_size_override("font_size", 7)
	add_child(tab_hint)

	# ── Checkout Receipt Panel ──
	_build_checkout_receipt_panel()

func _build_checkout_receipt_panel() -> void:
	# Receipt overlay panel (hidden until checkout)
	var panel := ColorRect.new()
	panel.name = "CheckoutReceipt"
	panel.position = Vector2(80.0, 30.0)
	panel.size = Vector2(160.0, 120.0)
	panel.color = Color(0.08, 0.08, 0.12, 0.95)
	panel.visible = false
	panel.z_index = 500
	add_child(panel)
	_checkout_receipt = panel

	var title := Label.new()
	title.text = "RECEIPT"
	title.position = Vector2(60.0, 34.0)
	title.add_theme_color_override("font_color", Color(0.90, 0.90, 0.60))
	title.add_theme_font_size_override("font_size", 10)
	panel.add_child(title)

	_checkout_receipt_items_lbl = Label.new()
	_checkout_receipt_items_lbl.text = ""
	_checkout_receipt_items_lbl.position = Vector2(8.0, 48.0)
	_checkout_receipt_items_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.70))
	_checkout_receipt_items_lbl.add_theme_font_size_override("font_size", 7)
	panel.add_child(_checkout_receipt_items_lbl)

	_checkout_total_lbl = Label.new()
	_checkout_total_lbl.text = ""
	_checkout_total_lbl.position = Vector2(8.0, 105.0)
	_checkout_total_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.60))
	_checkout_total_lbl.add_theme_font_size_override("font_size", 8)
	panel.add_child(_checkout_total_lbl)

func get_warehouse() -> Node:
	return _warehouse

func _update_floor_hud() -> void:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(_current_floor_idx)
	if _floor_label != null and is_instance_valid(_floor_label):
		_floor_label.text = "Floor %s ??%s" % [fd.label, fd.theme.replace("_", " ").capitalize()]
	else:
		_floor_label = get_node_or_null("FloorLabelHUD")
		if _floor_label != null:
			_floor_label.text = "Floor %s ??%s" % [fd.label, fd.theme.replace("_", " ").capitalize()]
	_update_staff_rank_hud()

# ???????????????????????????????????????????????????????????????????????????????????????????????# PLAYER & NPCS
# ???????????????????????????????????????????????????????????????????????????????????????????????
func _spawn_player() -> void:
	_player = Player.new()
	_player.position = Vector2(12 * CELL_SIZE, 4 * CELL_SIZE)
	add_child(_player)
	_player.set_world(self)
	_player.cart_updated.connect(_on_cart_updated)
	_player.interact_requested.connect(_on_player_interact)
	_player.tab_pressed.connect(_on_tab_pressed)
	_build_cart_panel()

func _build_npcs() -> void:
	# ??? Staff per floor ????????????????????????????????????????????
	# Staff spawn positions (x, y tile coords) per floor
	var staff_spawns := {
		0: { "x": [36, 38, 40, 20, 40, 60], "y": [10, 12, 14, 20, 20, 20] },  # Ground: lobby + food street
		1: { "x": [20, 40, 60, 20, 40], "y": [10, 10, 10, 20, 20] },  # Floor 1
		2: { "x": [20, 40, 60], "y": [10, 10, 20] },   # Pantry
		3: { "x": [30, 50, 20], "y": [10, 10, 20] },   # Beverages
		4: { "x": [20, 40, 60], "y": [10, 10, 20] },   # Snacks
	}

	var staff_roles := [
		ActorData.StaffRole.CASHIER,
		ActorData.StaffRole.SHELF_STOCKER,
		ActorData.StaffRole.CLEANER,
		ActorData.StaffRole.SECURITY,
		ActorData.StaffRole.GREETER,
		ActorData.StaffRole.MANAGER,
		ActorData.StaffRole.FLOOR_STAFF,
	]

	# Spawn 2-3 staff per role across different floors
	for role in staff_roles:
		var count := 2 if role == ActorData.StaffRole.SHELF_STOCKER else 1
		for c in range(count):
			var floor_idx := c % 5  # distribute across floors 0-4
			var spawns = staff_spawns.get(floor_idx, {"x": [30], "y": [10]})
			var sx := spawns["x"][c % spawns["x"].size()] * CELL_SIZE
			var sy := spawns["y"][c % spawns["y"].size()] * CELL_SIZE
			_spawn_npc_staff(role, floor_idx, Vector2(sx, sy))

	# ??? Customers ??diverse groups ????????????????????????????????
	# Family with baby (stroller)
	_spawn_customer_group(ActorData.CustomerGroupType.FAMILY_BABY, 0, Vector2(300, 200))
	_spawn_customer_group(ActorData.CustomerGroupType.FAMILY_BABY, 0, Vector2(600, 250))

	# Family with toddler
	_spawn_customer_group(ActorData.CustomerGroupType.FAMILY_TODDLER, 1, Vector2(200, 200))
	_spawn_customer_group(ActorData.CustomerGroupType.FAMILY_TODDLER, 0, Vector2(500, 400))

	# Two couples
	_spawn_customer_group(ActorData.CustomerGroupType.TWO_COUPLES, 1, Vector2(400, 300))
	_spawn_customer_group(ActorData.CustomerGroupType.TWO_COUPLES, 0, Vector2(200, 300))

	# Couple shopping
	_spawn_customer_group(ActorData.CustomerGroupType.COUPLE, 1, Vector2(300, 400))
	_spawn_customer_group(ActorData.CustomerGroupType.COUPLE, 3, Vector2(250, 250))
	_spawn_customer_group(ActorData.CustomerGroupType.COUPLE, 4, Vector2(350, 300))

	# Solo shoppers
	for i in range(8):
		var floor_i := i % 5
		var px := (80 + randi() % 500) as float
		var py := (80 + randi() % 400) as float
		_spawn_customer(ActorData.CustomerGroupType.SOLO, floor_i, Vector2(px, py))

	# Pair of friends
	for i in range(4):
		var floor_i := (i % 4) + 1
		var px := (100 + randi() % 400) as float
		var py := (100 + randi() % 300) as float
		_spawn_customer_group(ActorData.CustomerGroupType.PAIR, floor_i, Vector2(px, py))

	# Three friends
	_spawn_customer_group(ActorData.CustomerGroupType.THREE_FRIENDS, 1, Vector2(500, 200))
	_spawn_customer_group(ActorData.CustomerGroupType.THREE_FRIENDS, 2, Vector2(300, 350))

	# Extended family (2 adults + kids + grandparent)
	_spawn_customer_group(ActorData.CustomerGroupType.FAMILY_EXTENDED, 1, Vector2(600, 150))

	notify_telegram_npc(_npc_count)

var _npc_count: int = 0

func _spawn_npc_staff(role: int, floor_idx: int, pos: Vector2) -> void:
	var npc_scene = preload("res://scripts/npc_controller.gd")
	var npc = npc_scene.new()
	var actor = ActorData.Actor.new()
	actor = ActorData.Actor.random_staff(role)
	actor.current_floor = floor_idx
	npc.configure(actor)
	npc.position = pos
	npc.name = "Staff_%s_%d" % [actor.display_name.replace(" ", "_"), _npc_count]
	add_child(npc)
	_npcs.append(npc)
	if _chat_manager != null:
		_chat_manager.register_npc(npc)
	_npc_count += 1

func _spawn_customer(group_type: int, floor_idx: int, pos: Vector2) -> void:
	var npc_scene = preload("res://scripts/npc_controller.gd")
	var npc = npc_scene.new()
	var actor = ActorData.Actor.random_customer(group_type)
	actor.current_floor = floor_idx
	npc.configure(actor)
	npc.position = pos
	npc.name = "Customer_%d" % _npc_count
	add_child(npc)
	_npcs.append(npc)
	if _chat_manager != null:
		_chat_manager.register_npc(npc)
	_npc_count += 1

func _spawn_customer_group(group_type: int, floor_idx: int, pos: Vector2) -> void:
	# Spawn a group leader + follow members based on group type
	var leader = null
	var offsets := []
	var has_baby := false
	var has_toddler := false
	var has_kids := false

	match group_type:
		ActorData.CustomerGroupType.FAMILY_BABY:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(10,-15)]
			has_baby = true
		ActorData.CustomerGroupType.FAMILY_TODDLER:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(10,-12)]
			has_toddler = true
		ActorData.CustomerGroupType.FAMILY_KIDS:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(10,-12), Vector2(30,-12)]
			has_kids = true
		ActorData.CustomerGroupType.FAMILY_EXTENDED:
			offsets = [Vector2(0,0), Vector2(22,0), Vector2(44,0), Vector2(11,-12), Vector2(33,-12), Vector2(-15,0)]
		ActorData.CustomerGroupType.COUPLE:
			offsets = [Vector2(0,0), Vector2(20,0)]
		ActorData.CustomerGroupType.PAIR:
			offsets = [Vector2(0,0), Vector2(20,0)]
		ActorData.CustomerGroupType.TWO_COUPLES:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(40,0), Vector2(60,0)]
		ActorData.CustomerGroupType.THREE_FRIENDS:
			offsets = [Vector2(0,0), Vector2(20,0), Vector2(40,0)]
		_:
			offsets = [Vector2(0,0)]

	for i in range(offsets.size()):
		var npc_scene = preload("res://scripts/npc_controller.gd")
		var npc = npc_scene.new()
		var actor = ActorData.Actor.random_customer(group_type)
		actor.current_floor = floor_idx

		# Children get child appearance
		if i >= 2 and (has_baby or has_toddler or has_kids):
			actor.appearance.top_style = randi() % 2  # t-shirt or tank
			actor.appearance.bottom_style = randi() % 2  # shorts or pants
			actor.appearance.shoes_style = randi() % 2  # sneakers or sandals

		# Baby/toddler data
		if has_baby and i == 2:
			actor.child = ActorData.ChildData.random_infant()
			actor.life_stage = ActorData.LifeStage.ADULT  # parent, not baby
		if has_toddler and i == 2:
			actor.child = ActorData.ChildData.random_toddler()
			actor.life_stage = ActorData.LifeStage.ADULT

		npc.configure(actor)
		npc.position = pos + offsets[i] * Vector2(1.0, 1.0)

		var member_name := "Group_%d_Member_%d" % [_npc_count, i]
		if i == 0:
			member_name = "GroupLeader_%d" % _npc_count
		npc.name = member_name
		add_child(npc)
		_npcs.append(npc)

		if i == 0:
			leader = npc
		else if leader != null:
			npc.set_group_leader(leader)
			var leader_actor: ActorData.Actor = leader.get_actor()
			leader_actor.group_members.append(npc)
		_npc_count += 1

# ???????????????????????????????????????????????????????????????????????????????????????????????# GAME LOOP ??Proximity & Input
# ???????????????????????????????????????????????????????????????????????????????????????????????
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
			KEY_N:
				_toggle_minimap()
			# ? ── Tutorial
			KEY_QUESTION:
				_show_tutorial()
			# L ── Shopping List
			KEY_L:
				_toggle_shopping_list()
			# B ── Brand Portal
			KEY_B:
				_toggle_brand_portal()
			# Shift+B ── Business Mode (Manager)
			if event.shift:
				_toggle_business_mode()
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
						_handle_loyalty_key(idx, item)
					else:
						_add_order_item(idx, item)
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
	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	if _in_elevator:
		return
	_update_player_section_proximity()
	_update_checkout_proximity()
	_update_elevator_proximity()
	_update_stairs_proximity()
	_update_stall_proximity()
	_update_claw_machine_proximity()
	_update_npc_chat_proximity()
	_update_issue_proximity()
	_update_atm_proximity()
	_update_warehouse_proximity()
	_update_monitor_proximity()
	_update_terminal_proximity()
	_update_phase3_proximity()

	# Self-checkout error dismiss on E key
	if Input.is_action_just_pressed("interact") and _nearby_checkout != null:
		if _nearby_checkout.is_self_checkout():
			_nearby_checkout.dismiss_error()
			_do_checkout_interaction()

func _update_elevator_proximity() -> void:
	if _player == null or _elevator == null:
		_nearby_elevator = false
		return
	_nearby_elevator = _elevator.is_nearby(_player.position)
	_nearby_stairs = false
	_nearby_parking = false

	# Show prompt
	var prompt_bg = get_node_or_null("PromptBg")
	var prompt_lbl = get_node_or_null("PromptLbl")
	if _nearby_elevator:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Elevator"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
		_checkout_counter_label.visible = false

func _update_stall_proximity() -> void:
	_nearby_stall = null
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for stall in _floor_builder.get_food_stalls():
		var zone = stall.get_zone()
		var stall_center := Vector2(
			(zone.x + zone.w * 0.5) * CELL_SIZE,
			(zone.y + zone.h * 0.5) * CELL_SIZE
		)
		var dist := ppos.distance_to(stall_center)
		if dist < nearest_dist and dist < CELL_SIZE * 10.0:
			nearest_dist = dist
			_nearby_stall = stall

	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_stall != null and not _nearby_elevator and not _nearby_stairs:
		if prompt_lbl != null:
			var fd = _nearby_stall.get_stall_def()
			prompt_lbl.text = "[E] Order at %s" % fd.name
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

func _update_claw_machine_proximity() -> void:
	_nearby_claw_machine = null
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for machine in _floor_builder.get_claw_machines():
		var zone = machine.get_zone()
		var mc_center := Vector2(
			(zone.x + zone.w * 0.5) * CELL_SIZE,
			(zone.y + zone.h * 0.5) * CELL_SIZE
		)
		var dist := ppos.distance_to(mc_center)
		if dist < nearest_dist and dist < CELL_SIZE * 10.0:
			nearest_dist = dist
			_nearby_claw_machine = machine

	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_claw_machine != null and not _nearby_elevator and not _nearby_stairs:
		if prompt_lbl != null:
			var mid = _nearby_claw_machine.get_machine_id()
			prompt_lbl.text = "[E] Play Claw #%s" % mid.replace("claw_", "")
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

func _update_npc_chat_proximity() -> void:
	_nearby_npc_for_chat = null
	if _player == null or _npcs.is_empty():
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for npc in _npcs:
		if not is_instance_valid(npc):
			continue
		var actor: ActorData.Actor = npc.get_actor()
		if actor == null or not actor.is_active:
			continue
		var dist := ppos.distance_to(npc.global_position)
		if dist < nearest_dist and dist < CELL_SIZE * 8.0:
			nearest_dist = dist
			_nearby_npc_for_chat = npc

	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_npc_for_chat != null and not _nearby_elevator and not _nearby_stairs:
		if _chat_panel == null or not _chat_panel._is_open:
			if prompt_lbl != null:
				var actor: ActorData.Actor = _nearby_npc_for_chat.get_actor()
				var role_str := ""
				if actor.role == ActorData.Role.STAFF:
					var role_names := {
						ActorData.StaffRole.CASHIER: "Cashier",
						ActorData.StaffRole.SHELF_STOCKER: "Stocker",
						ActorData.StaffRole.CLEANER: "Cleaner",
						ActorData.StaffRole.SECURITY: "Security",
						ActorData.StaffRole.GREETER: "Greeter",
						ActorData.StaffRole.MANAGER: "Manager",
						ActorData.StaffRole.FLOOR_STAFF: "Staff",
					}
					role_str = role_names.get(actor.staff_role, "Staff")
					prompt_lbl.text = "[C] Chat with %s (%s)" % [actor.display_name, role_str]
				else:
					prompt_lbl.text = "[C] Chat with %s" % actor.display_name
				prompt_lbl.visible = true
			if prompt_bg != null:
				prompt_bg.visible = true
	else:
		# Only hide chat hint if no other prompt is showing
		pass  # don't override other prompts

# ??? Issue / Maintenance Proximity ???????????????????????????????
func _update_issue_proximity() -> void:
	_nearby_issue = false
	if _player == null or _maintenance_system == null:
		return
	var issue := _maintenance_system.get_issue_at_pos(_player.position, CELL_SIZE * 7.0)
	_nearby_issue = (issue != null)
	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if issue != null and not _nearby_elevator and not _nearby_stairs:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Fix: %s [%s]" % [issue.label, issue.assigned_to]
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
	# If player has a target issue, show direction prompt
	if _target_issue != null and _target_issue.status < 2:
		if prompt_lbl != null and not _nearby_issue:
			prompt_lbl.text = "[E] Fix: %s (Floor %d)" % [_target_issue.label, _target_issue.floor]
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

# ??? ATM Proximity ??????????????????????????????????????????????
func _update_atm_proximity() -> void:
	_nearby_atm = false
	if _player == null:
		return
	# Check if near any ATM node
	for node in get_children():
		if node.has_method("is_nearby") and node.name.begins_with("ATM_"):
			if node.is_nearby(_player.position):
				_nearby_atm = true
				break
	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_atm and not _nearby_elevator and not _nearby_stairs:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Use ATM"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

# ??? Warehouse Proximity ????????????????????????????????????????
func _update_warehouse_proximity() -> void:
	_nearby_warehouse = false
	if _player == null or _current_floor_idx != 11:
		return
	# On Floor 11 (warehouse), show interaction prompt if in range
	var wh_pos := Vector2(40 * CELL_SIZE, 20 * CELL_SIZE)
	if _player.position.distance_to(wh_pos) < CELL_SIZE * 12.0:
		_nearby_warehouse = true
	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_warehouse and not _nearby_elevator and not _nearby_stairs:
		if prompt_lbl != null:
			if _warehouse_mode:
				prompt_lbl.text = "[WASD] Drive Truck  [Q/E] Forklift  [F] Conveyor  [Space] Stop  [E] Exit"
			else:
				prompt_lbl.text = "[E] Warehouse  [R] Robot Panel"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

func _on_warehouse_delivery_arrived(contents: Dictionary) -> void:
	notify_telegram("Delivery arrived at warehouse! Stock updated for %d sections." % contents.size())

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

func _update_monitor_proximity() -> void:
	_nearby_monitor = false
	if _player == null:
		return
	# Check if player is on floor 7 or 8 (back office / exec office)
	if _current_floor_idx != 7 and _current_floor_idx != 8:
		return
	# Check if near monitor room zone
	var wh_pos := Vector2(66 * CELL_SIZE + 2 * CELL_SIZE, 3 * CELL_SIZE + 2 * CELL_SIZE)
	if _player.position.distance_to(wh_pos) < CELL_SIZE * 8.0:
		_nearby_monitor = true
	var prompt_lbl = get_node_or_null('PromptLbl')
	var prompt_bg = get_node_or_null('PromptBg')
	if _nearby_monitor and not _nearby_elevator and not _nearby_stairs:
		if prompt_lbl != null:
			prompt_lbl.text = '[E] Open Monitor Panel'
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

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
	for i in range(count):
		var npc: Node = preload("res://scripts/npc_controller.gd").new()
		npc.position = Vector2(300.0 + randf_range(-50, 50), 500.0 + randf_range(-30, 30))
		add_child(npc)
		npc.configure(ActorData.new_test_customer())
		_npcs.append(npc)
		_chat_manager.register_npc(npc)

func _spawn_test_staff(count: int) -> void:
	for i in range(count):
		var npc: Node = preload("res://scripts/npc_controller.gd").new()
		npc.position = Vector2(350.0 + randf_range(-50, 50), 300.0 + randf_range(-30, 30))
		add_child(npc)
		npc.configure(ActorData.new_test_staff())
		_npcs.append(npc)
		_chat_manager.register_npc(npc)

func _kill_all_test_npcs() -> void:
	for npc in _npcs:
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	_npcs.clear()
		prompt_lbl.visible = true

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
		# Notify telegram
		notify_telegram("? Maintenance issue fixed on Floor %d!
Type: %s" % [issue.floor, issue.label])
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
	notify_telegram("Staff rank up! Now: %s" % rank_name)

func _update_staff_rank_hud() -> void:
	if _player_stats == null:
		return
	var rank_lbl = get_node_or_null("StaffRankLbl")
	if rank_lbl != null:
		rank_lbl.text = "[%s]" % _player_stats.get_staff_rank_name()
		var progress := _player_stats.get_staff_xp_progress()
		rank_lbl.tooltip_text = "Staff XP: %d/100 progress to next rank" % int(progress * 100)

func _on_player_level_up(new_level: int) -> void:
	notify_telegram("LEVEL UP! You are now Level %d!" % new_level)
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
			notify_telegram("Store Open - 6AM!")
			if _toasts != null: _toasts.toast_success("Store Open! 6:00 AM")
		if hour == 22:  # 10pm getting quiet
			notify_telegram("Evening hours")
		if hour == 23:  # 11pm closing soon
			notify_telegram("Store closing soon - last call!")
			if _toasts != null: _toasts.toast_warn("Store Closing - 11:00 PM")

func _show_tutorial_overlay() -> void:
	if _tutorial_overlay != null:
		_tutorial_overlay.queue_free()
	_tutorial_overlay = TutorialOverlayScript.new()
	add_child(_tutorial_overlay)
	_tutorial_overlay.show_tutorial()
	_tutorial_overlay.dismissed.connect(_on_tutorial_dismissed)

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
	notify_telegram("🎯 *Daily Quest Complete!* %s +%d XP" % [desc, xp])
	SaveSystem.save_game(self)

func _on_all_quests_complete() -> void:
	if _toasts != null:
		_toasts.toast_xp("All Daily Quests Done! Epic Bonus!")
	notify_telegram("🏅 *All Daily Quests Done!* Epic bonus incoming!")
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
		"notif_telegram":
			# Telegram handled by flag in telegram_bot

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
			if prompt_lbl != null:
				prompt_lbl.text = "[E] Browse %s" % sec.get_def().name
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
		_do_checkout_interaction()
		return

	# Section browse
	if _nearby_section != null:
		_open_section_browse(_nearby_section)
		return

	# Elevator
	if _nearby_elevator:
		_elevator.open_panel()
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

	# Warehouse (Floor 11)
	if _nearby_warehouse:
		if _warehouse_mode:
			# Exit warehouse control mode
			_warehouse_mode = false
			_warehouse_floor.set_staff_mode(false) if _warehouse_floor else null
			if _toasts: _toasts.toast_info("Exited warehouse control.")
		else:
			# Enter warehouse control mode (staff only)
			if _player != null and _player.is_in_staff_mode():
				_warehouse_mode = true
				if _warehouse_floor:
					_warehouse_floor.set_staff_mode(true)
				if _toasts: _toasts.toast_success("Warehouse Control Mode — use WASD/Q/E/F to operate equipment!")
			else:
				if _toasts: _toasts.toast_warning("Staff mode required for warehouse control. Press [K] to enter staff mode.")
		return

	# Phase 3: Interactive facilities
	if _nearby_loyalty:
		# Enter loyalty/coin mode
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
		if _toasts != null: _toasts.toast_success("Gift wrapped! +10 XP bonus earned!")
		if _player_stats != null: _player_stats.add_xp(10)
		return
	if _nearby_digital_kiosk:
		if _toasts != null: _toasts.toast_info("Floor Directory: G=Lobby+Food, 1=Fresh, 2=Pantry, 3=Drinks, 4=Snacks, 5=Frozen, 6=Household, 7=H+B, 8=Arcade, 9=Staff, 10=Cafe")
		return
	if _nearby_info_desk:
		if _toasts != null: _toasts.toast_info("Welcome to Pixel Supermarket! Use elevator or stairs to navigate.")
		return
	if _temp_order_mode != "":
		_finish_order()
		return
	if _nearby_cafe:
		_open_cafe_browse()
		return
	if _nearby_vending:
		_open_vending_browse()
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
	_food_stall_browse.open(stall)

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
func _update_checkout_proximity() -> void:
	_nearby_checkout = null
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for counter in _checkout_counters:
		var cpos = counter.position
		var dist := ppos.distance_to(cpos)
		if dist < nearest_dist and dist < CELL_SIZE * 8.0:
			nearest_dist = dist
			_nearby_checkout = counter

	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_checkout != null and not _nearby_elevator and not _nearby_stairs:
		var ctype = _nearby_checkout.get_checkout_type()
		var type_str := "Checkout"
		match ctype:
			CheckoutCounter.CheckoutType.STAFFED:
				type_str = "[E] Staffed Checkout"
			CheckoutCounter.CheckoutType.SELF:
				type_str = "[E] Self-Checkout"
			CheckoutCounter.CheckoutType.EXPRESS:
				type_str = "[E] Express Checkout"
		if prompt_lbl != null:
			prompt_lbl.text = type_str
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
	else:
		if prompt_lbl != null and prompt_lbl.text == "[E] Staffed Checkout" or prompt_lbl.text == "[E] Self-Checkout" or prompt_lbl.text == "[E] Express Checkout" or prompt_lbl.text == "[E] Checkout":
			prompt_lbl.text = ""

func _on_checkout_interacted(checkout_id: int, checkout_type) -> void:
	_do_checkout_interaction()

func _do_checkout_interaction() -> void:
	if _nearby_checkout == null:
		return
	var cart: Player = _player
	if cart == null:
		return
	var items = cart.get_cart_items()
	if items.size() == 0:
		if _toasts != null: _toasts.toast_warning("Cart is empty!")
		return

	var ctype = _nearby_checkout.get_checkout_type()

	# Express lane item count check
	if ctype == CheckoutCounter.CheckoutType.EXPRESS:
		var item_count := 0
		for item in items:
			item_count += item.get("qty", 1)
		if item_count > CheckoutCounter.MAX_EXPRESS_ITEMS:
			_nearby_checkout.check_express_items(item_count)
			_on_express_rejected()
			return

	# Self-checkout random error
	if ctype == CheckoutCounter.CheckoutType.SELF:
		if _nearby_checkout.roll_self_checkout_error():
			_on_self_checkout_error()
			return

	# Proceed with checkout
	_finish_checkout()

func _finish_checkout() -> void:
	if _player == null:
		return
	var cart = _player
	var items = cart.get_cart_items()
	if items.size() == 0:
		return
	var subtotal := 0.0
	for item in items:
		var item_prod = item.get("product", item)  # support dict {product,qty} or direct product
		subtotal += item_prod.price * item.get("qty", 1)
	# Apply loyalty credit if member (100 pts = $5 off)
	var loyalty_credit := 0.0
	if stats != null and stats.is_loyalty_member():
		loyalty_credit = stats.redeem_loyalty_credit()
	var taxable := subtotal - loyalty_credit
	if taxable < 0:
		taxable = 0.0
	var tax = taxable * 0.08
	var total = taxable + tax

	# Deduct cash
	var stats = _player_stats
	if stats != null:
		stats.add_cash(-total)

	# Award XP (with brand event multipliers)
	var base_xp := max(1, int(total * 0.5))
	var brand_bonus_xp := 0
	if stats != null:
		var total_xp := 0
		for item in items:
			var item_prod = item.get("product", item)  # support both dict and product ref
			var item_xp := max(1, int(item_prod.price * item.get("qty", 1) * 0.5))
			var multiplier := 1.0
			if _brand_manager != null:
				multiplier = _brand_manager.get_xp_multiplier_for_product(item_prod.get("id", ""))
			total_xp += int(item_xp * multiplier)
			if multiplier > 1.0:
				brand_bonus_xp += int(item_xp * (multiplier - 1.0))
			# ── Phase L: Consume stock from warehouse ──────────────────
			var sec_id = item_prod.get("section", "")
			if sec_id != "" and _warehouse != null:
				var qty := item.get("qty", 1) as int
				var available := _warehouse.consume_stock(sec_id, qty)
				if not available:
					# Section ran out of stock — toast warning
					if _toasts:
						_toasts.toast_warning("%s is now out of stock!" % item_prod.get("name", "Item").to_upper())
		stats.add_xp(max(1, total_xp))
		# Award staff XP for completing checkout task
		stats.add_staff_xp(items.size(), "Checkout: %d items" % items.size())

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
	if _nearby_checkout != null and _nearby_checkout.is_staffed():
		_nearby_checkout.show_farewell_bubble()

	# Show receipt (include loyalty credit line if > 0)
	_show_checkout_receipt(items, subtotal, tax, total, brand_bonus_xp, loyalty_credit)

	# Notify
	notify_telegram("Checkout complete! $%.2f spent. Cart cleared." % total)
	if _toasts != null: _toasts.toast_success("Checkout complete! -$%.2f" % total)

	# Auto-save
	SaveSystem.save_game(self)

func _show_checkout_receipt(items: Array, subtotal: float, tax: float, total: float, brand_bonus_xp: int = 0, loyalty_credit: float = 0.0) -> void:
	# Receipt display (re-use existing receipt panel or create)
	if _checkout_receipt == null:
		return
	_checkout_receipt.visible = true
	_checkout_receipt_items_lbl.text = ""
	for item in items:
		var qty = item.get("qty", 1)
		_checkout_receipt_items_lbl.text += "%dx %s $%.2f\n" % [qty, item.name, item.price * qty]
	var receipt_text := ""
	if loyalty_credit > 0:
		receipt_text += "Loyalty Credit: -$%.2f\n" % loyalty_credit
	receipt_text += "Subtotal: $%.2f\nTax: $%.2f\nTOTAL: $%.2f" % [subtotal, tax, total]
	if brand_bonus_xp > 0:
		receipt_text += "\n[color=#FFFF00]BRAND BONUS: +%d XP![/color]" % brand_bonus_xp
	_checkout_total_lbl.text = receipt_text
	_checkout_receipt_visible = true
	await get_tree().create_timer(5.0).timeout
	if _checkout_receipt != null:
		_checkout_receipt.visible = false
		_checkout_receipt_visible = false

func _on_express_rejected() -> void:
	if _toasts != null:
		_toasts.toast_error("Express lane: max %d items only!" % CheckoutCounter.MAX_EXPRESS_ITEMS)

func _on_self_checkout_error() -> void:
	if _toasts != null:
		_toasts.toast_error("Unexpected item in bagging area! Press E to retry.")

func _on_self_checkout_cleared() -> void:
	# Retry checkout after error dismissed
	_do_checkout_interaction()

# ── Section browse ──────────────────────────────────────────────
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
		notify_telegram("Restocked: %s +%d units" % [sec_def.name, top_up])

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
		notify_telegram("Henry clocked IN to staff mode — Price Terminal available on Floor 9")
		# 30% chance to spawn a Scan & Go companion on Floor G
		if _current_floor_idx == 0 and randf() < 0.30:
			_spawn_scan_go_companion()
	else:
		_staff_blocked_floor = 9  # lock floor 9 again
		if _toasts != null: _toasts.toast_info("[STAFF MODE] Clocked out.")
		notify_telegram("Henry clocked OUT of staff mode")
		# Remove scan & go companion if active
		_remove_scan_go_companion()

func _spawn_scan_go_companion() -> void:
	# Spawn a staff NPC that follows the player and "scans" items
	var spawn_pos := _player.position + Vector2(40, 0)
	var actor := ActorData.Actor.new()
	actor.role = ActorData.Role.STAFF
	actor.staff_role = ActorData.StaffRole.SCAN_GO
	actor.life_stage = ActorData.LifeStage.ADULT
	actor.current_floor = _current_floor_idx
	actor.position = spawn_pos
	actor.speed = ActorData.SPEED_ADULT
	# Give a random appearance
	var app := ActorData.Appearance.new()
	app.skin_tone = ActorData.SKINS[randi() % ActorData.SKINS.size()]
	app.top_color = Color(0.20, 0.50, 0.80)
	app.bottom_color = Color(0.15, 0.15, 0.30)
	app.hair_color = ActorData.HAIR_COLORS[randi() % ActorData.HAIR_COLORS.size()]
	actor.appearance = app
	var npc := NPCControllerScript.new(actor)
	npc._player_reference = _player  # pass player ref for companion tracking
	npc.position = spawn_pos
	npc._state = NPCControllerScript.BehaviorState.SCAN_GO_COMPANION
	npc.name = "ScanGoCompanion"
	add_child(npc)
	if _toasts != null: _toasts.toast_info("Scan & Go assistant has joined you!")

func _remove_scan_go_companion() -> void:
	var sg = get_node_or_null("ScanGoCompanion")
	if sg != null:
		sg.queue_free()

# ── Price terminal proximity (Phase 6) ───────────────────────────
func _update_terminal_proximity() -> void:
	_nearby_terminal = false
	if _floor_builder == null or _player == null:
		return
	if _current_floor_idx != 9:
		return
	# Check if player is near the office_desk zone (terminal on Floor 9)
	var terminal_center = _floor_builder.get_office_desk_zone_center()
	if terminal_center.x < 0:
		return
	var ppos = _player.position
	if ppos.distance_to(terminal_center) < CELL_SIZE * 12.0:
		_nearby_terminal = true

	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_terminal and _player != null and _player.is_in_staff_mode():
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Price Terminal"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

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
		_build_robot_panel()
	if _robot_panel.visible:
		_robot_panel.visible = false
	else:
		if _player != null and not _player.is_in_staff_mode():
			if _toasts: _toasts.toast_warning("Staff mode required for robot management. Press [K].")
			return
		_robot_panel.visible = true
		_update_robot_panel()

func _build_robot_panel() -> void:
	_robot_panel = Control.new()
	_robot_panel.set_anchors_preset(Control.PRESET_CENTER)
	_robot_panel.size = Vector2(300, 400)
	_robot_panel.color = Color(0.10, 0.10, 0.15, 0.95)
	_robot_panel.visible = false
	add_child(_robot_panel)

	var title := Label.new()
	title.text = "ROBOT STAFF PANEL"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	title.add_theme_font_size_override("font_size", 10)
	title.position = Vector2(0, 6)
	_robot_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Staff mode only  |  [R] close"
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.add_theme_color_override("font_color", Color(0.60, 0.60, 0.70))
	subtitle.add_theme_font_size_override("font_size", 7)
	subtitle.position = Vector2(0, 18)
	_robot_panel.add_child(subtitle)

	# Scroll container for robot list
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.position = Vector2(0, 30)
	scroll.size = Vector2(300, 340)
	_robot_panel.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# ── HUMANOID ROBOTS ──
	var h_label := Label.new()
	h_label.text = "━━ HUMANOID (like human, uses tools) ━━"
	h_label.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	h_label.add_theme_font_size_override("font_size", 7)
	list.add_child(h_label)

	var humanoid_types := [
		{"staff_role": ActorData.StaffRole.GREETER, "name": "Greeter", "desc": "Welcomes & directs customers", "cost": 400},
		{"staff_role": ActorData.StaffRole.CASHIER, "name": "Cashier", "desc": "Operates checkout lane", "cost": 500},
		{"staff_role": ActorData.StaffRole.CLEANER, "name": "Cleaner", "desc": "Mops & tidies the store", "cost": 350},
		{"staff_role": ActorData.StaffRole.SHELF_STOCKER, "name": "Stocker", "desc": "Restocks shelves", "cost": 400},
		{"staff_role": ActorData.StaffRole.SECURITY, "name": "Security", "desc": "Patrols & monitors", "cost": 450},
		{"staff_role": ActorData.StaffRole.SCAN_GO, "name": "Scan & Go", "desc": "Assists player with scanning", "cost": 450},
	]
	for rt in humanoid_types:
		var btn := Button.new()
		btn.text = "[%s] %dXP  %s" % [rt["name"], rt["cost"], rt["desc"]]
		btn.add_theme_color_override("font_color", Color(0.80, 0.88, 0.90))
		btn.add_theme_color_override("bg_color", Color(0.18, 0.35, 0.45))
		btn.connect("pressed", _on_robot_humanoid_pressed.bind(rt["staff_role"], rt["cost"]))
		list.add_child(btn)

	# ── SINGLE-FUNCTION ROBOTS ──
	var s_label := Label.new()
	s_label.text = "━━ SINGLE-FUNCTION (automated machine) ━━"
	s_label.add_theme_color_override("font_color", Color(0.30, 0.90, 1.0))
	s_label.add_theme_font_size_override("font_size", 7)
	list.add_child(s_label)

	var single_types := [
		{"rrole": ActorData.RobotRole.CLEANING_ROBOT, "name": "CleanerBot", "desc": "Auto-cleans floors (battery)", "cost": 250},
		{"rrole": ActorData.RobotRole.GUIDANCE_ROBOT, "name": "GuideBot", "desc": "Answers questions", "cost": 200},
		{"rrole": ActorData.RobotRole.SHELF_ROBOT, "name": "ShelfBot", "desc": "Auto-scans shelf stock", "cost": 300},
		{"rrole": ActorData.RobotRole.SECURITY_ROBOT, "name": "SecurityBot", "desc": "Patrol robot (red eye)", "cost": 350},
		{"rrole": ActorData.RobotRole.DELIVERY_ROBOT, "name": "DeliveryBot", "desc": "Transports cargo", "cost": 400},
	]
	for rt in single_types:
		var btn := Button.new()
		btn.text = "[%s] %dXP  %s" % [rt["name"], rt["cost"], rt["desc"]]
		btn.add_theme_color_override("font_color", Color(0.80, 0.85, 0.75))
		btn.add_theme_color_override("bg_color", Color(0.25, 0.28, 0.22))
		btn.connect("pressed", _on_robot_single_pressed.bind(rt["rrole"], rt["cost"]))
		list.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = "[R] Close"
	close_btn.position = Vector2(0, 375)
	close_btn.connect("pressed", _toggle_robot_panel)
	_robot_panel.add_child(close_btn)

func _update_robot_panel() -> void:
	var active_count = _robots.size()
	# Find the subtitle label and update it
	if _robot_panel:
		for child in _robot_panel.get_children():
			if child is Label and child.text == "Staff mode only":
				child.text = "Active robots: %d" % active_count
				break

func _on_robot_humanoid_pressed(staff_role: ActorData.StaffRole, cost: int) -> void:
	if _player_stats == null:
		return
	if not _player_stats.can_use_humanoid_robots():
		var next_xp := _player_stats.get_staff_xp_for_next_rank()
		if _toasts: _toasts.toast_warning("Humanoid robots unlock at Senior rank! %d more Staff XP needed." % max(0, next_xp))
		return
	if _player_stats.get_xp() < cost:
		if _toasts: _toasts.toast_warning("Not enough XP! Need %d XP to deploy %s" % [cost, staff_role])
		return
	_player_stats.spend_xp(cost)
	_player_stats.complete_staff_task()
	_spawn_robot_humanoid(staff_role)
	if _toasts: _toasts.toast_success("Deployed HUMANOID %s! -%d XP" % [staff_role, cost])
	_update_robot_panel()

func _on_robot_single_pressed(rrole: ActorData.RobotRole, cost: int) -> void:
	if _player_stats == null:
		return
	if not _player_stats.can_use_single_function_robots():
		var next_xp := _player_stats.get_staff_xp_for_next_rank()
		if _toasts: _toasts.toast_warning("Single-function robots unlock at Worker rank! %d more Staff XP needed." % max(0, next_xp))
		return
	if _player_stats.get_xp() < cost:
		if _toasts: _toasts.toast_warning("Not enough XP! Need %d XP to deploy %s" % [cost, rrole])
		return
	_player_stats.spend_xp(cost)
	_player_stats.complete_staff_task()
	_spawn_robot_single(rrole)
	if _toasts: _toasts.toast_success("Deployed %s! -%d XP" % [rrole, cost])
	_update_robot_panel()

func _spawn_robot_humanoid(staff_role: ActorData.StaffRole) -> void:
	var spawn_pos := Vector2.ZERO
	match staff_role:
		ActorData.StaffRole.CASHIER:
			spawn_pos = Vector2(580, 320)
		ActorData.StaffRole.GREETER:
			spawn_pos = Vector2(250, 120)
		ActorData.StaffRole.CLEANER:
			spawn_pos = Vector2(400, 400)
		ActorData.StaffRole.SHELF_STOCKER:
			spawn_pos = Vector2(200, 300)
		ActorData.StaffRole.SECURITY:
			spawn_pos = Vector2(100, 200)
		ActorData.StaffRole.FLOOR_STAFF:
			spawn_pos = Vector2(400, 250)
		ActorData.StaffRole.SCAN_GO:
			spawn_pos = Vector2(350, 200)
		ActorData.StaffRole.MANAGER:
			spawn_pos = Vector2(500, 300)
	var robot := RobotControllerScript.new()
	robot.configure_humanoid(staff_role, spawn_pos)
	add_child(robot)
	_robots.append(robot)

func _spawn_robot_single(rrole: ActorData.RobotRole) -> void:
	var spawn_pos := Vector2.ZERO
	match rrole:
		ActorData.RobotRole.CLEANING_ROBOT:
			spawn_pos = Vector2(400, 400)
		ActorData.RobotRole.GUIDANCE_ROBOT:
			spawn_pos = Vector2(300, 100)
		ActorData.RobotRole.SECURITY_ROBOT:
			spawn_pos = Vector2(100, 200)
		ActorData.RobotRole.DELIVERY_ROBOT:
			spawn_pos = Vector2(40 * CELL_SIZE, 20 * CELL_SIZE)
		ActorData.RobotRole.SHELF_ROBOT:
			spawn_pos = Vector2(200, 300)
	var robot := RobotControllerScript.new()
	robot.configure_single_function(rrole, spawn_pos)
	add_child(robot)
	_robots.append(robot)

func _spawn_robots() -> void:
	# Humanoid robots (look like humans, can do any job)
	_spawn_robot_humanoid(ActorData.StaffRole.GREETER)
	_spawn_robot_humanoid(ActorData.StaffRole.CLEANER)
	# Single-function robots
	_spawn_robot_single(ActorData.RobotRole.CLEANING_ROBOT)
	_spawn_robot_single(ActorData.RobotRole.GUIDANCE_ROBOT)

func _on_brand_portal_closed() -> void:
	# Refresh any brand data that may have changed
	pass

func get_game_clock() -> Node:
	return _game_clock

# ── Phase 3: Cafe Counter Browse ────────────────────────────────
func _open_cafe_browse() -> void:
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
	_temp_order_mode = "cafe"
	_temp_order_items = items
	_toasts.toast_info("Cafe: [1]Espresso $3.50 [2]Latte $4.50 [3]Capp $4.80 [4]Americano $3.00")
	_toasts.toast_info("Muffin $2.80 [5]  Croissant $3.20 [6]  Iced $4.20 [7]  Smoothie $5.50 [8]")
	var hint := get_node_or_null("PromptLbl")
	if hint != null:
		hint.text = "[1-8] Add item  [E] finish order"

# ── Phase 3: Vending Machine Browse ─────────────────────────────
func _open_vending_browse() -> void:
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
	_temp_order_mode = "vending"
	_temp_order_items = items
	_toasts.toast_info("Vending: [1]Water $1.50 [2]Cola $2.00 [3]Juice $2.50 [4]Chips $1.80 [5]Choco $2.20 [6]Energy $3.00")
	var hint := get_node_or_null("PromptLbl")
	if hint != null:
		hint.text = "[1-6] Add item  [E] done"

func _add_order_item(idx: int, item: Dictionary) -> void:
	if _player == null:
		return
	var cart = _player.get_cart()
	if cart == null:
		return
	# Create a minimal product-like object for the cart
	var cart_item := {
		"id": _temp_order_mode + "_" + str(idx),
		"name": item.name,
		"price": item.price,
		"qty": 1
	}
	cart.add_item(cart_item)
	if _toasts != null:
		_toasts.toast_success("+1 %s $%.2f" % [item.name, item.price])
	_update_cart_ui()

func _finish_order() -> void:
	_temp_order_mode = ""
	_temp_order_items = []
	var hint := get_node_or_null("PromptLbl")
	if hint != null:
		hint.text = ""
	if _toasts != null:
		_toasts.toast_success("Done!")

func _handle_loyalty_key(idx: int, item: Dictionary) -> void:
	if _player_stats == null:
		return
	if idx == 0:	# Buy 5 coins for $2
		var cost: float = item.get("price", 2.0)
		if _player_stats.spend_cash(cost):
			_player_stats.add_coins(5)
			if _toasts != null:
				_toasts.toast_success("+5 Coins! Now have %d coins" % _player_stats.get_coins())
		else:
			if _toasts != null:
				_toasts.toast_warning("Not enough cash!")
	elif idx == 1:	# Sign up or check status
		if _player_stats.is_loyalty_member():
			var pts = _player_stats.get_loyalty_points()
			_toasts.toast_info("Loyalty: %d pts" % pts)
		else:
			if _player_stats.signup_loyalty():
				if _toasts != null:
					_toasts.toast_success("Welcome to Loyalty! 1 pt/$1 -- 100 pts = $5 credit!")

# ── Phase 3: Interactive Facilities Proximity ───────────────────
func _update_phase3_proximity() -> void:
	_nearby_loyalty = false
	_nearby_gift_wrap = false
	_nearby_digital_kiosk = false
	_nearby_info_desk = false
	_nearby_cafe = false
	_nearby_vending = false
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")

	if _floor_builder.is_near_zone_type(FloorConfig.ZONE_LOYALTY_KIOSK, ppos):
		_nearby_loyalty = true
	if _floor_builder.is_near_zone_type(FloorConfig.ZONE_GIFT_WRAP, ppos):
		_nearby_gift_wrap = true
	if _floor_builder.is_near_zone_type(FloorConfig.ZONE_DIGITAL_KIOSK, ppos):
		_nearby_digital_kiosk = true
	if _floor_builder.is_near_zone_type(FloorConfig.ZONE_INFO_DESK, ppos):
		_nearby_info_desk = true
	if _floor_builder.is_near_zone_type(FloorConfig.ZONE_CAFE_COUNTER, ppos):
		_nearby_cafe = true
	if _floor_builder.is_near_zone_type(FloorConfig.ZONE_VENDING_MACHINE, ppos):
		_nearby_vending = true

	# Update prompt if no higher-priority prompt is showing
	var show_phase3 = _nearby_loyalty or _nearby_gift_wrap or _nearby_digital_kiosk or _nearby_info_desk or _nearby_cafe or _nearby_vending
	if show_phase3 and not _nearby_elevator and not _nearby_stairs and _nearby_section == null and _nearby_checkout == null:
		var txt := "[E] "
		if _nearby_loyalty: txt += "Loyalty Sign-Up"
		elif _nearby_gift_wrap: txt += "Gift Wrap (+XP)"
		elif _nearby_digital_kiosk: txt += "Info Directory"
		elif _nearby_info_desk: txt += "Info Desk"
		elif _nearby_cafe: txt += "Cafe Menu"
		elif _nearby_vending: txt += "Vending Machine"
		if prompt_lbl != null:
			prompt_lbl.text = txt
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

func _toggle_stats_dashboard() -> void:
	if _stats_dashboard == null: return
	_stats_dashboard.toggle()
	if _stats_dashboard.visible:
		_stats_dashboard.refresh_from_stats(_player_stats)
