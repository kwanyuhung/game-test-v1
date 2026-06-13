# main.gd
# 10-floor supermarket data-driven world builder.
# Uses floor_config.gd for all floor/zone data.
# Uses floor_builder.gd for rendering.
extends Node2D

const FloorConfigScript = preload("res://scripts/world/floor_config.gd")
const FloorBuilderScript = preload("res://scripts/world/floor_builder.gd")
const SectionBrowseScript = preload("res://scripts/world/section_browse.gd")
const StoreData = preload("res://scripts/world/store_data.gd")
const ElevatorScript = preload("res://scripts/systems/elevator.gd")
const FloorManagerScript = preload("res://scripts/world/floor_manager.gd")
const FoodStallBrowseScript = preload("res://scripts/systems/food_stall_browse.gd")
const ClawMachineScript = preload("res://scripts/amenities/claw_machine.gd")
const ActorData = preload("res://scripts/entities/actor_data.gd")
const ChatManagerScript = preload("res://scripts/managers/chat_manager.gd")
const ChatPanelScript = preload("res://scripts/ui/chat_panel.gd")
const GameClockScript = preload("res://scripts/managers/game_clock.gd")
const MaintenanceSystemScript = preload("res://scripts/systems/maintenance_system.gd")
const MaintenanceVisualScript = preload("res://scripts/entities/maintenance_visual.gd")
const MaintenancePanelScript = preload("res://scripts/ui/maintenance_panel.gd")
const PlayerStatsScript = preload("res://scripts/managers/player_stats.gd")
const StatsPanelScript = preload("res://scripts/ui/stats_panel.gd")
const AchievementPopupScript = preload("res://scripts/ui/achievement_popup.gd")
const WarehouseSystemScript = preload("res://scripts/systems/warehouse_system.gd")
const ATMPanelScript = preload("res://scripts/amenities/atm_panel.gd")
const CheckoutCounterScript = preload("res://scripts/systems/checkout_counter.gd")
const DevToolsScript = preload("res://scripts/ui/dev_tools.gd")
const AudioManagerScript = preload("res://scripts/managers/audio_manager.gd")
const MonitorPanelScript = preload("res://scripts/ui/monitor_panel.gd")
const PriceTerminalScript = preload("res://scripts/systems/price_terminal.gd")
const PriceOverrideScript = preload("res://scripts/systems/price_override.gd")
const BrandManagerScript = preload("res://scripts/managers/brand_manager.gd")
const BrandPortalScript = preload("res://scripts/managers/brand_portal.gd")
const BusinessModeScript = preload("res://scripts/ui/business_mode.gd")
const SaveSystem = preload("res://scripts/managers/save_system.gd")
const TutorialOverlayScript = preload("res://scripts/ui/tutorial_overlay.gd")
const RobotControllerScript = preload("res://scripts/entities/robot_controller.gd")
const WarehouseFloorScript = preload("res://scripts/systems/warehouse_floor.gd")
const DailyBonusScript = preload("res://scripts/ui/daily_bonus.gd")
const ShoppingListScript = preload("res://scripts/amenities/shopping_list.gd")
const QuestSystemScript = preload("res://scripts/systems/quest_system.gd")
const QuestJournalScript = preload("res://scripts/ui/quest_journal.gd")
const SettingsPanelScript = preload("res://scripts/ui/settings_panel.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const StatsDashboardScript = preload("res://scripts/ui/stats_dashboard.gd")
const MiniMapScript = preload("res://scripts/ui/mini_map.gd")
const MapPanelScript = preload("res://scripts/ui/map_panel.gd")
const FloorPanelScript = preload("res://scripts/ui/floor_panel.gd")
const ToastManagerScript = preload("res://scripts/ui/toast_manager.gd")
const FloatingTextScript = preload("res://scripts/ui/floating_text.gd")
const FadeTransitionScript = preload("res://scripts/ui/fade_transition.gd")
const ProximitySystemScript = preload("res://scripts/systems/proximity_system.gd")
const CheckoutSystemScript = preload("res://scripts/systems/checkout_system.gd")
const FoodCourtSystemScript = preload("res://scripts/systems/food_court_system.gd")
const TruckDockSystemScript = preload("res://scripts/systems/truck_dock_system.gd")
const StoreExpansionScriptRef = preload("res://scripts/systems/store_expansion.gd")
const AntiTheftScriptRef = preload("res://scripts/systems/anti_theft.gd")
const DynamicPricingScriptRef = preload("res://scripts/systems/dynamic_pricing.gd")
const SupplierManagerScriptRef = preload("res://scripts/systems/supplier_manager.gd")
const RobotPanelSystemScript = preload("res://scripts/managers/robot_panel_system.gd")
const PromotionManagerScriptRef = preload("res://scripts/systems/promotion_manager.gd")
const MainSpawnerScript = preload("res://scripts/world/main_spawner.gd")
const MainInitScript = preload("res://scripts/core/main_init.gd")
const InteractionBubbleScript = preload("res://scripts/ui/interaction_bubble.gd")

const DEV_MODE := true  # Set to false to disable dev tools

const CELL_SIZE := FloorConfigScript.CELL_SIZE
const WORLD_W  := FloorConfigScript.WORLD_W
const WORLD_H  := FloorConfigScript.WORLD_H

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
var _debug_viewer: CanvasLayer = null
var _shelf_panel: CanvasLayer = null
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
var _interaction_bubble: InteractionBubbleScript = null
var _floor_jump_panel: Control = null
var _floor_panel: FloorPanel = null

var _nearby_monitor: bool = false
var _monitor_panel: MonitorPanel = null
var _nearby_warehouse: bool = false
var _nearby_warehouse_dock: bool = false  # Floor G receiving dock
var _warehouse_mode: bool = false
var _truck_dock_node: Node2D = null
var _truck_arrived: bool = false
var _warehouse_floor: Node2D = null
var _nearby_elevator: bool = false
var _nearby_parking: bool = false
var _nearby_terminal: bool = false
var _nearby_loyalty: bool = false
var _nearby_gift_wrap: bool = false
var _nearby_digital_kiosk: bool = false
var _nearby_info_desk: bool = false
var _nearby_cafe: bool = false
var _nearby_promo_booth: bool = false
var _nearby_lost_found: bool = false
var _nearby_store_news: bool = false
var _nearby_vending: bool = false
var _checkout_counter_label: Label = null
var _checkout_items_lbl: Label = null
var _checkout_total_lbl: Label = null
var _checkout_receipt_visible: bool = false
var _price_terminal: PriceTerminal = null
var _brand_manager: BrandManager = null
var _brand_portal: BrandPortal = null
var _business_mode: BusinessMode = null
var _robots: Array = []
var _robot_panel_system: Node = null
var _robot_panel: Control = null
var _map_edit_mode: MapEditMode = null
var _temp_order_mode: String = ""
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
var _floor_manager: Node = null
var _current_floor_idx: int = 0
var _floor_nodes: Array = []
var _floor_ambient: Color = Color(0.18, 0.18, 0.16)
var _floor_label: Label = null

func set_nearby_npc_for_chat(val: NPCController) -> void:
	_nearby_npc_for_chat = val
func get_nearby_npc_for_chat() -> NPCController:
	return _nearby_npc_for_chat

func set_nearby_issue(val: bool) -> void:
	_nearby_issue = val
func is_nearby_issue() -> bool:
	return _nearby_issue

func set_save_hint_label(val: Label) -> void:
	_save_hint_label = val
func get_save_hint_label() -> Label:
	return _save_hint_label

# Dynamic variable getters
func get_chat_manager() -> ChatManager:
	return _chat_manager

func is_minimap_visible() -> bool:
	return _minimap_visible
func get_time_label() -> Label:
	return _time_label
func get_store_status_label() -> Label:
	return _store_status_label
func get_shopping_list_count_lbl() -> Label:
	return _shopping_list_count_lbl
func get_xp_bar_bg() -> ColorRect:
	return _xp_bar_bg
func get_xp_bar_fill() -> ColorRect:
	return _xp_bar_fill
func get_floating_text() -> FloatingText:
	return _floating_text
func get_daily_bonus() -> DailyBonus:
	return _daily_bonus
func get_loyalty_panel() -> Node2D:
	return _loyalty_panel
func get_interaction_bubble() -> Node:
	return _interaction_bubble
func is_nearby_monitor() -> bool:
	return _nearby_monitor
func get_truck_dock_node() -> Node2D:
	return _truck_dock_node
func is_truck_arrived() -> bool:
	return _truck_arrived
func get_checkout_counter_label() -> Label:
	return _checkout_counter_label
func get_checkout_items_lbl() -> Label:
	return _checkout_items_lbl
func get_checkout_total_lbl() -> Label:
	return _checkout_total_lbl
func get_brand_manager() -> BrandManager:
	return _brand_manager
func get_promo_manager():
	return _promo_manager
func get_dynamic_pricing():
	return _dynamic_pricing
func get_supplier_manager():
	return _supplier_manager
func get_stairs_node() -> Node2D:
	return _stairs_node
func get_floor_label() -> Label:
	return _floor_label

# Additional getters for core systems
func get_proximity_system() -> Node:
	return _proximity_system
func get_checkout_system() -> Node:
	return _checkout_system
func get_food_court_system() -> Node:
	return _food_court_system
func get_truck_dock_system() -> Node:
	return _truck_dock_system
func get_player() -> Player:
	return _player
func get_sections() -> Array:
	return _sections
func get_checkout_counters() -> Array:
	return _checkout_counters
func get_npcs() -> Array:
	return _npcs
func get_game_clock() -> GameClock:
	return _game_clock
func get_maintenance_system() -> MaintenanceSystem:
	return _maintenance_system
func get_player_stats() -> PlayerStats:
	return _player_stats
func get_warehouse() -> WarehouseSystem:
	return _warehouse
func get_minimap() -> MiniMap:
	return _minimap
func get_map_panel() -> MapPanel:
	return _map_panel
func get_toasts() -> ToastManager:
	return _toasts
func get_elevator() -> ElevatorScript:
	return _elevator
func get_floor_manager() -> Node:
	return _floor_manager
func get_main_panels() -> Node:
	return _main_panels
func get_main_spawner() -> Node:
	return _main_spawner
func get_floor_jump_panel() -> Control:
	return _floor_jump_panel
func get_floor_panel() -> FloorPanel:
	return _floor_panel
func get_monitor_panel() -> MonitorPanel:
	return _monitor_panel
func get_price_terminal() -> PriceTerminal:
	return _price_terminal
func get_stats_dashboard() -> StatsDashboard:
	return _stats_dashboard
func get_settings_panel() -> SettingsPanel:
	return _settings_panel
func get_quest_system() -> QuestSystem:
	return _quest_system
func get_shopping_list() -> ShoppingList:
	return _shopping_list
func get_robots() -> Array:
	return _robots
func is_in_elevator() -> bool:
	return _in_elevator

var _floor_builder: FloorBuilder
var _food_stall_browse: FoodStallBrowse
var _in_elevator: bool = false

var _logic: Node = null

func _ready() -> void:
	_logic = preload("res://scripts/core/main_logic.gd").new()
	_logic.name = "MainLogic"
	add_child(_logic)
	_logic.setup(self)
	_main_init = preload("res://scripts/core/main_init.gd").new()
	add_child(_main_init)
	_main_init.setup(self)
	_main_init.init_all()
	# Note: _build_floor(0) is already called inside init_all()
	_logic._setup_camera()  # Initialize camera after systems are ready

func _input(event: InputEvent) -> void:
	# Block all input when any panel is blocking
	if PanelManager.is_input_blocked():
		return
	if event is InputEventKey and event.pressed:
		# Stairs W/S ── Open-world floor navigation via stairs
		var _stairs_sys = get("_stairs_system")
		if _stairs_sys != null and _stairs_sys.has_method("check_stairs_proximity") and _player != null:
			var proximity_result: Dictionary = _stairs_sys.check_stairs_proximity(_player.position, _current_floor_idx)
			if proximity_result.get("in_zone", false):
				if event.keycode == KEY_W or event.keycode == KEY_UP:
					var can_go_up: bool = proximity_result.get("can_go_up", false)
					if can_go_up and not _stairs_sys.is_transitioning():
						_stairs_sys.start_stairs_transition(1)  # +1 = up
					return
				elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
					var can_go_down: bool = proximity_result.get("can_go_down", false)
					if can_go_down and not _stairs_sys.is_transitioning():
						_stairs_sys.start_stairs_transition(-1)  # -1 = down
					return
		
		match event.keycode:
			# C ── Chat with nearby NPC
			KEY_C:
				_logic._open_npc_chat()
			# F1 ── Dev Tools
			KEY_F1:
				if DEV_MODE:
					PanelManager.toggle("dev_tools")
			# F2 ── Quick Save
			KEY_F2:
				SaveSystem.save_game(self)
				if _toasts != null: _toasts.toast_success("Game Saved!")
			# F3 ── Hover debug overlay + count overlay (toggle both)
			KEY_F3:
				var dbg := get_tree().get_first_node_in_group("hover_debug_overlay")
				if dbg != null:
					dbg.toggle()
				var cnt := get_tree().get_first_node_in_group("count_overlay")
				if cnt != null:
					cnt.toggle()
			# F4 ── Debug Sprite Viewer (if DEV_MODE) or Quick Load
			KEY_F4:
				if DEV_MODE and _debug_viewer != null:
					_debug_viewer.toggle()
				else:
					SaveSystem.load_game(self)
					if _toasts != null: _toasts.toast_info("Game Loaded!")
			# L ── Shopping List
			KEY_L:
				_logic._toggle_shopping_list()
			# T ── Floor Jump Panel (Teleport)
			KEY_T:
				_logic._toggle_floor_jump_panel()
			# M ── Map Panel
			KEY_M:
				PanelManager.toggle("map")
			# V ── Floor Panel (Clickable floor selector)
			KEY_V:
				PanelManager.toggle("floor")
			# Q ── Floor Panel (same as V, alt binding for quick floor change)
			KEY_Q:
				PanelManager.toggle("floor")
			# X ── Renovate nearby section (staff mode)
			KEY_X:
				_logic._renovate_nearby_section()
			# F ── Catch thief (when suspicious activity nearby)
			KEY_F:
				_logic._attempt_catch_thief()
			# B / Shift+B ── Brand Portal or Business Mode
			KEY_B:
				if event.shift:
					_logic._toggle_business_mode()
				else:
					_logic._toggle_brand_portal()
			# J ── Quest Journal
			KEY_J:
				_logic._toggle_quest_journal()
			# R ── Robot Panel (staff only) OR Restock section
			KEY_R:
				# If near a section and in staff mode, restock it
				if _nearby_section != null and _player != null and _player.is_in_staff_mode():
					_logic._restock_nearby_section()
				else:
					_logic._toggle_robot_panel()
			# O ── Settings
			KEY_O:
				PanelManager.toggle("settings")
			# P ── Pause / Resume
			KEY_P:
				_logic._toggle_pause()
			# U ── Map Edit Mode (DEV_MODE only)
			KEY_U:
				if DEV_MODE and _map_edit_mode != null:
					_map_edit_mode.toggle()
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

		# 0-9 ── Numbered bubble interactions
		if not PanelManager.is_input_blocked():
			var num_key_map := {
				KEY_0: 0, KEY_1: 1, KEY_2: 2, KEY_3: 3,
				KEY_4: 4, KEY_5: 5, KEY_6: 6, KEY_7: 7,
				KEY_8: 8, KEY_9: 9
			}
			if event.keycode in num_key_map and not (event.shift_pressed or event.ctrl_pressed or event.alt_pressed):
				var num: int = num_key_map[event.keycode]
				_logic._handle_numbered_interaction(num)
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
		
		# H ── Toggle Shelf Panel (warehouse/storage view)
			if event.keycode == KEY_H:
				_logic._toggle_shelf_panel()

func _unhandled_input(event: InputEvent) -> void:
	var cam = _logic._camera if _logic != null else null
	if cam == null:
		return
	if PanelManager.is_input_blocked():
		return
	if event is InputEventMouseButton and event.pressed:
		var zoom: Vector2 = cam.zoom
		var new_zoom: float = zoom.x
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			new_zoom = clampf(zoom.x + _logic.CAMERA_ZOOM_STEP, _logic.CAMERA_ZOOM_MIN, _logic.CAMERA_ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			new_zoom = clampf(zoom.x - _logic.CAMERA_ZOOM_STEP, _logic.CAMERA_ZOOM_MIN, _logic.CAMERA_ZOOM_MAX)
		if not is_equal_approx(new_zoom, zoom.x):
			cam.zoom = Vector2(new_zoom, new_zoom)
			if _player != null and not _in_elevator:
				cam.position = _player.position

func _process(_delta: float) -> void:
	# Center camera on player when not in elevator. Map Edit Mode drives the
	# camera via WASD, so let it own the camera while it is open.
	if _map_edit_mode != null and _map_edit_mode.is_open():
		return
	var cam = _logic._camera if _logic != null else null
	if cam != null and _player != null and not _in_elevator:
		cam.position = _player.position

	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	if _in_elevator:
		return

	# Delegate proximity updates to SystemManager
	var sm = get("_system_manager")
	if sm != null and sm.has_method("_process"):
		sm._process(_delta)

func _on_player_interact() -> void:
	_logic.handle_player_interact()

func is_input_blocked() -> bool:
	return PanelManager.is_input_blocked()

func add_to_shopping_list(product_name: String) -> bool:
	if _shopping_list != null:
		return _shopping_list.add_item(product_name)
	return false

# ── Passthrough wrappers for external callers ──────────────────────────────
# External code (player.gd, elevator.gd, floor_manager.gd, escalator.gd,
# stairs_system.gd, system_manager.gd, main_init.gd, main_panels.gd, npc_controller.gd)
# calls these on the main node; delegate to _logic.

func _spawn_player() -> void:
	_logic._spawn_player()

func _show_save_hint(msg: String) -> void:
	_logic._show_save_hint(msg)

func _build_floor(idx: int) -> void:
	_logic._build_floor(idx)

func _rebuild_floor(idx: int) -> void:
	_logic._rebuild_floor(idx)

func _update_floor_hud() -> void:
	_logic._update_floor_hud()

func set_ambient_floor(idx: int) -> void:
	_logic.set_ambient_floor(idx)

func is_position_blocked(floor_idx: int, world_x: float, world_y: float) -> bool:
	return _logic.is_position_blocked(floor_idx, world_x, world_y)

func elevator_arrival_position(floor_idx: int) -> Vector2:
	return _logic.elevator_arrival_position(floor_idx)

func get_floor_info() -> Dictionary:
	return _logic.get_floor_info()

func get_current_floor_idx() -> int:
	return _current_floor_idx

func player_board_elevator(player, floor_idx: int) -> void:
	_logic.player_board_elevator(player, floor_idx)

func close_business_mode() -> void:
	_logic.close_business_mode()

func on_npc_theft(npc) -> void:
	_logic.on_npc_theft(npc)

func add_to_shopping_list_helper(name: String) -> bool:
	return add_to_shopping_list(name)
