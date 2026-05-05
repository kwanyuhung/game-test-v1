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
const DevToolsScript = preload("res://scripts/dev_tools.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")
const MonitorPanelScript = preload("res://scripts/monitor_panel.gd")
const PriceTerminalScript = preload("res://scripts/price_terminal.gd")
const SaveSystem = preload("res://scripts/save_system.gd")
const TutorialOverlayScript = preload("res://scripts/tutorial_overlay.gd")
const DailyBonusScript = preload("res://scripts/daily_bonus.gd")
const ShoppingListScript = preload("res://scripts/shopping_list.gd")
const QuestSystemScript = preload("res://scripts/quest_system.gd")
const QuestJournalScript = preload("res://scripts/quest_journal.gd")
const SettingsPanelScript = preload("res://scripts/settings_panel.gd")
const PauseMenuScript = preload("res://scripts/pause_menu.gd")
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
var _shopping_list_visible: bool = false
var _audio: AudioManager = null

var _nearby_monitor: bool = false
var _monitor_panel: MonitorPanel = null
var _nearby_warehouse: bool = false
var _nearby_elevator: bool = false
var _nearby_parking: bool = false
var _nearby_stairs: bool = false
var _nearby_terminal: bool = false
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

func _update_floor_hud() -> void:
	var fd: FloorConfig.FloorDef = FloorConfig.get_floor(_current_floor_idx)
	if _floor_label != null and is_instance_valid(_floor_label):
		_floor_label.text = "Floor %s ??%s" % [fd.label, fd.theme.replace("_", " ").capitalize()]
	else:
		_floor_label = get_node_or_null("FloorLabelHUD")
		if _floor_label != null:
			_floor_label.text = "Floor %s ??%s" % [fd.label, fd.theme.replace("_", " ").capitalize()]

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
			# J ── Quest Journal
			KEY_J:
				_toggle_quest_journal()
			# O ── Settings
			KEY_O:
				_toggle_settings_panel()
			# P / SPACE ── Pause / Resume
			KEY_P:
				_toggle_pause()
			KEY_SPACE:
				_toggle_pause()

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
	if _player == null or _current_floor_idx != 12:
		return
	# On Floor 12 (warehouse), always show the proximity if in range
	var wh_pos := Vector2(50 * CELL_SIZE, 20 * CELL_SIZE)
	if _player.position.distance_to(wh_pos) < CELL_SIZE * 10.0:
		_nearby_warehouse = true
	var prompt_lbl = get_node_or_null("PromptLbl")
	var prompt_bg = get_node_or_null("PromptBg")
	if _nearby_warehouse and not _nearby_elevator and not _nearby_stairs:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Check Warehouse Stock"
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