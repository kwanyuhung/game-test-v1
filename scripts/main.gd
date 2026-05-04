# main.gd
# 10-floor supermarket ??data-driven world builder.
# Uses floor_config.gd for all floor/zone data.
# Uses floor_builder.gd for rendering.
extends Node2D

const FloorConfig = preload("res://scripts/floor_config.gd")
const FloorBuilderScript = preload("res://scripts/floor_builder.gd")
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
const MonitorPanelScript = preload("res://scripts/monitor_panel.gd")

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

var _nearby_monitor: bool = false
var _monitor_panel: MonitorPanel = null
var _nearby_warehouse: bool = false
var _nearby_elevator: bool = false
var _nearby_parking: bool = false
var _nearby_stairs: bool = false
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

	notify_telegram("?貕?*Game Loaded*\n10-floor supermarket ??Ground (G) ready\nUse [E] near elevator to change floors")
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
	# Player exits at destination floor
	_rebuild_floor(_current_floor_idx)
	# Reattach player
	if _player != null:
		_player.position = Vector2(80 * CELL_SIZE + 7 * CELL_SIZE, 20 * CELL_SIZE)

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
	# Update clock display in HUD if available
	if _game_clock != null:
		var t := _game_clock.game_time_string()
		var period := _game_clock.period_name()
		# Update any clock-related prompts
		if hour == 22:  # 10pm ??store getting quiet
			notify_telegram("? Evening hours ??store traffic slowing down")
		if hour == 23:  # 11pm
			notify_telegram("? Store closing soon ??last call!")

func _on_day_changed(day_idx: int) -> void:
	notify_telegram("? Day %d begins!
Good morning at the supermarket!" % day_idx)

func _on_shift_report(report: Dictionary) -> void:
	var msg := "? Shift Report ??Day %d

Resolved: %d issues
Created: %d issues" % [
		report["day"], report["issues_resolved"], report["issues_created"]]
	notify_telegram(msg)

func _navigate_to_floor(target_floor: int) -> void:
	# Use elevator to go to target floor
	if _elevator != null:
		_elevator.request_floor(target_floor)

# ??? Issue Fix via E key ?????????????????????????????????????????
func _try_fix_nearby_issue() -> bool:
	if _maintenance_system == null or _player == null:
		return false
	# Try to fix the target issue if close enough, OR any nearby issue
	var issue_to_fix = _target_issue if _target_issue != null and _target_issue.status < 2 else null
	if issue_to_fix == null:
		issue_to_fix = _maintenance_system.get_issue_at_pos(_player.position, CELL_SIZE * 7.0)
	if issue_to_fix == null:
		return false
	if issue_to_fix.floor != _current_floor_idx:
		# Wrong floor ??navigate there first
		_navigate_to_floor(issue_to_fix.floor)
		_target_issue = issue_to_fix
		return true
	# Resolve it (takes a moment)
	_maintenance_system.resolve_issue(issue_to_fix, true)
	return true

func _update_stairs_proximity() -> void:
	if _player == null:
		return
	var stairs_pos := Vector2(85 * CELL_SIZE, 15 * CELL_SIZE)
	var dist := _player.position.distance_to(stairs_pos)
	_nearby_stairs = (dist < CELL_SIZE * 4.0)
	if _nearby_stairs and not _nearby_elevator:
		var prompt_lbl = get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Take Stairs"
			prompt_lbl.visible = true
		var prompt_bg = get_node_or_null("PromptBg")
		if prompt_bg != null:
			prompt_bg.visible = true

func _update_player_section_proximity() -> void:
	if _player == null:
		return
	var ppos = _player.position
	var nearest = null
	var nearest_dist := 99999.0

	for sec in _sections:
		var def = sec.get_def()
		var sx: float = (def.wx + def.ww * 0.5) * CELL_SIZE
		var sy: float = (def.wy + def.wh * 0.5) * CELL_SIZE
		var dist := ppos.distance_to(Vector2(sx, sy))
		if dist < nearest_dist and dist < CELL_SIZE * 9.0:
			nearest_dist = dist
			nearest = sec

	_nearby_section = nearest
	var prompt_bg = get_node_or_null("PromptBg")
	var prompt_lbl = get_node_or_null("PromptLbl")

	if nearest != null and not _nearby_elevator:
		_player.set_nearby_section(nearest)
		var def = nearest.get_def()
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Browse %s" % def.name
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
		_checkout_counter_label.visible = false
	elif not _nearby_elevator and not _nearby_stairs and not _nearby_parking:
		_player.set_nearby_section(null)
		if prompt_lbl != null:
			prompt_lbl.visible = false
		if prompt_bg != null:
			prompt_bg.visible = false

func _update_checkout_proximity() -> void:
	if _player == null:
		return
	var ppos = _player.position
	var near_checkout = null
	for counter in _checkout_counters:
		var dist := ppos.distance_to(counter.position + Vector2(CELL_SIZE * 4, CELL_SIZE * 1.5))
		if dist < CELL_SIZE * 5.0:
			near_checkout = counter
			break

	_nearby_checkout = near_checkout
	if near_checkout != null and not _nearby_elevator:
		_checkout_counter_label.text = "[E] Checkout at %s" % near_checkout.name.replace("Counter_", "")
		_checkout_counter_label.visible = true
	elif not _nearby_elevator:
		_checkout_counter_label.visible = false

# ?????? Interact ????????????????????????????????????????????????????????????????????????????????????????????????????

func _on_player_interact() -> void:
	if _checkout_receipt_visible:
		_hide_checkout_receipt()
		return
	if _current_section_browse != null and _current_section_browse.visible:
		return
	# Elevator first
	if _nearby_elevator:
		_elevator.open_panel(_player.position, _player)
		return
	# ATM
	if _nearby_atm:
		_open_atm_panel()
	# Monitor Room
	if _nearby_monitor:
		_open_monitor_panel()
		return
		return
	# Food stall order
	if _nearby_stall != null:
		_show_stall_menu(_nearby_stall)
		return
	# Claw machine play
	if _nearby_claw_machine != null:
		_start_claw_machine(_nearby_claw_machine)
		return
	# Checkout with items
	if _nearby_checkout != null:
		var cart = _player.get_cart()
		if cart.get_item_count() > 0:
			_show_checkout_receipt()
		return
	# Maintenance ??fix nearby or targeted issue
	if _nearby_issue or (_target_issue != null and _target_issue.status < 2):
		if _try_fix_nearby_issue():
			return
	# Section browse
	if _nearby_section != null:
		var def = _nearby_section.get_def()
		var prods = _nearby_section.get_all_products()
		_current_section_browse = _section_browse
		_section_browse.open(def.id, prods, _player.get_cart())
		notify_telegram_section_browse(def.name, prods.size())

func _on_stall_interact_requested(stall_id: String) -> void:
	if _floor_builder != null:
		for stall in _floor_builder.get_food_stalls():
			if stall.get_stall_id() == stall_id:
				_show_stall_menu(stall)
				break

func _on_claw_interact_requested(machine_id: String) -> void:
	if _floor_builder != null:
		for machine in _floor_builder.get_claw_machines():
			if machine.get_machine_id() == machine_id:
				_start_claw_machine(machine)
				break

func _show_stall_menu(stall: Node) -> void:
	if _food_stall_browse == null:
		_food_stall_browse = FoodStallBrowseScript.new()
		add_child(_food_stall_browse)
		_food_stall_browse.closed.connect(_on_food_stall_closed)
		_food_stall_browse.item_added.connect(_on_food_stall_item_added)
	var fd: FloorConfig.FoodStallDef = stall.get_stall_def()
	_food_stall_browse.open(fd, _player.get_cart())

func _on_food_stall_closed() -> void:
	pass

func _on_food_stall_item_added(item_name: String, qty: int, price: float) -> void:
	pass

# ??? Claw Machine ??????????????????????????????????????????????

var _claw_active: bool = false
var _active_claw_machine: ClawMachine = null

func _start_claw_machine(machine: ClawMachine) -> void:
	if machine == null:
		return
	# Set cart reference on the machine
	machine.set_cart(_player.get_cart())
	var ok = machine.start_round()
	if ok:
		_claw_active = true
		_active_claw_machine = machine
		machine.played.connect(_on_claw_round_ended)
		# Show instructions in prompt
		var prompt_lbl = get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "A/D: Move  S: Drop"

	else:
		# Could not start (no cart / already playing)
		var prompt_lbl = get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "Already playing..."

func _on_claw_round_ended(prize_name: String, won: bool) -> void:
	_claw_active = false
	_active_claw_machine = null
	var prompt_lbl = get_node_or_null("PromptLbl")
	if prompt_lbl != null:
		if won:
			prompt_lbl.text = "You won: %s!" % prize_name
		else:
			prompt_lbl.text = "No prize this time..."

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# M ??open maintenance panel
		if event.keycode == KEY_M:
			_toggle_maintenance_panel()
			return
		# P ??open stats panel
		if event.keycode == KEY_P:
			_toggle_stats_panel()
			return
		# Chat toggle ??press C near an NPC
		if event.keycode == KEY_C:
			_open_npc_chat()
			return
		# F3 ── Dev tools (dev mode only)
		if event.keycode == KEY_F3 and DEV_MODE:
			_toggle_dev_tools()
			return
		# ESC closes chat panel or maintenance panel
		if event.keycode == KEY_ESCAPE:
			if _maintenance_panel != null and _maintenance_panel.visible:
				_maintenance_panel.close()
			elif _chat_panel != null and _chat_panel._is_open:
				_chat_panel.close()
			return
			return
		# Claw machine controls only when playing
		if not _claw_active or _active_claw_machine == null:
			return
		match event.keycode:
			KEY_A, KEY_LEFT:
				_active_claw_machine.move_claw(-1)
			KEY_D, KEY_RIGHT:
				_active_claw_machine.move_claw(1)
			KEY_S, KEY_DOWN:
				_active_claw_machine.drop_claw()

func _open_npc_chat() -> void:
	if _chat_panel != null and _chat_panel.visible:
		return
	if _nearby_npc_for_chat == null:
		return
	var npc: NPCController = _nearby_npc_for_chat
	var actor: ActorData.Actor = npc.get_actor()
	var brain = npc.get("chat_brain")
	if brain == null:
		return
	_chat_panel = ChatPanelScript.new()
	add_child(_chat_panel)
	_chat_panel.open(npc, actor, brain)
	_chat_panel.closed.connect(_on_chat_closed)

func _on_chat_closed() -> void:
	_chat_panel = null

func _on_section_entered(section_id: String) -> void:
	pass

func _on_section_exited(section_id: String) -> void:
	pass

func _on_browse_closed() -> void:
	_current_section_browse = null

func _on_item_added_to_cart(product, qty: int) -> void:
	pass

func _on_cart_updated(total_count: int, unique_count: int) -> void:
	if _cart_count_lbl != null:
		var cart = _player.get_cart()
		var sub = cart.get_subtotal() if cart != null else 0.0
		_cart_count_lbl.text = "%d items  $%.2f" % [total_count, sub]
	if _cart_panel_visible:
		_refresh_cart_panel()

func _on_tab_pressed() -> void:
	if _current_section_browse != null and _current_section_browse.visible:
		return
	if _checkout_receipt_visible:
		return
	if _cart_panel_visible:
		_hide_cart_panel()
	else:
		_show_cart_panel()

# ???????????????????????????????????????????????????????????????????????????????????????????????# CART PANEL
# ???????????????????????????????????????????????????????????????????????????????????????????????
func _build_cart_panel() -> void:
	_cart_panel = CanvasLayer.new()
	_cart_panel.name = "CartPanel"
	_cart_panel.visible = false
	add_child(_cart_panel)

	_cart_items_lbl = Label.new()
	_cart_items_lbl.name = "CartItems"
	_cart_items_lbl.position = Vector2(4.0, 4.0)
	_cart_items_lbl.size = Vector2(152.0, 110.0)
	_cart_items_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
	_cart_items_lbl.add_theme_font_size_override("font_size", 8)
	_cart_items_lbl.add_theme_constant_override("line_spacing", 2)
	_cart_panel.add_child(_cart_items_lbl)

	_cart_total_lbl = Label.new()
	_cart_total_lbl.name = "CartTotal"
	_cart_total_lbl.position = Vector2(4.0, 116.0)
	_cart_total_lbl.add_theme_color_override("font_color", Color(0.90, 0.78, 0.42))
	_cart_total_lbl.add_theme_font_size_override("font_size", 8)
	_cart_panel.add_child(_cart_total_lbl)

func _show_cart_panel() -> void:
	_refresh_cart_panel()
	_cart_panel.visible = true
	_cart_panel_visible = true

func _hide_cart_panel() -> void:
	_cart_panel.visible = false
	_cart_panel_visible = false

func _refresh_cart_panel() -> void:
	if _cart_panel == null or _player == null:
		return
	var cart = _player.get_cart()
	var items = cart.get_items()
	var lines: Array = []
	lines.append("???? SHOPPING CART ????")
	if items.size() == 0:
		lines.append("(empty)")
	else:
		for entry in items:
			var prod = entry["product"]
			var qty = entry["qty"]
			var line = "%dx %s" % [qty, prod.name]
			if line.length() > 18:
				line = line.substr(0, 18)
			lines.append(line)
		var sub = cart.get_subtotal()
		lines.append("")
		lines.append("Subtotal: $%.2f" % sub)
	_cart_items_lbl.text = "\n".join(lines)
	var sub = cart.get_subtotal()
	var tax = cart.get_tax()
	var total = cart.get_total()
	_cart_total_lbl.text = "Sub: $%.2f  Tax: $%.2f\nTOTAL: $%.2f" % [sub, tax, total]

# ???????????????????????????????????????????????????????????????????????????????????????????????# CHECKOUT RECEIPT
# ???????????????????????????????????????????????????????????????????????????????????????????????
func _show_checkout_receipt() -> void:
	_checkout_receipt_visible = true
	_hide_cart_panel()

	# Track checkout stats
	var cart = _player.get_cart()
	var items = cart.get_items()
	var item_count := 0
	for entry in items:
		item_count += entry["qty"]
		var prod = entry["product"]
		if _player_stats != null:
			_player_stats.on_item_bought(prod.id, prod.price * entry["qty"])
		# Consume stock from warehouse for this section
		if _warehouse != null and prod.section != "":
			_warehouse.consume_stock(prod.section, entry["qty"])
	if _player_stats != null:
		_player_stats.on_checkout(cart.subtotal(), item_count)

	var ov := ColorRect.new()
	ov.name = "CROverlay"
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0.03, 0.03, 0.06, 0.90)
	ov.gui_input.connect(_on_receipt_input)
	add_child(ov)

	var pan_x: float = (320.0 - 220.0) * 0.5
	var pan_y: float = (180.0 - 165.0) * 0.5

	var pan := ColorRect.new()
	pan.name = "CRPanel"
	pan.position = Vector2(pan_x, pan_y)
	pan.size = Vector2(220.0, 165.0)
	pan.color = Color(0.09, 0.09, 0.13, 1.0)
	pan.gui_input.connect(_on_receipt_input)
	add_child(pan)

	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(220.0, 16.0)
	hdr.color = Color(0.22, 0.18, 0.30, 1.0)
	hdr.gui_input.connect(_on_receipt_input)
	add_child(hdr)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "?????CHECKOUT ?????
	hdr_lbl.position = Vector2(pan_x + 60.0, pan_y + 3.0)
	hdr_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.95))
	hdr_lbl.add_theme_font_size_override("font_size", 9)
	hdr_lbl.gui_input.connect(_on_receipt_input)
	add_child(hdr_lbl)

	var cart = _player.get_cart()
	var items = cart.get_items()
	var y_pos: float = pan_y + 20.0
	var line_h: float = 10.0

	for entry in items:
		var prod = entry["product"]
		var qty = entry["qty"]
		var line_lbl := Label.new()
		line_lbl.position = Vector2(pan_x + 6.0, y_pos)
		line_lbl.size = Vector2(210.0, line_h)
		line_lbl.text = "%dx %s" % [qty, prod.name]
		line_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78))
		line_lbl.add_theme_font_size_override("font_size", 8)
		line_lbl.gui_input.connect(_on_receipt_input)
		add_child(line_lbl)

		var price_lbl := Label.new()
		price_lbl.position = Vector2(pan_x + 160.0, y_pos)
		price_lbl.text = "$%.2f" % (prod.price * qty)
		price_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.78))
		price_lbl.add_theme_font_size_override("font_size", 8)
		price_lbl.gui_input.connect(_on_receipt_input)
		add_child(price_lbl)
		y_pos += line_h

	var div := ColorRect.new()
	div.position = Vector2(pan_x + 6.0, y_pos + 1.0)
	div.size = Vector2(208.0, 1.0)
	div.color = Color(0.30, 0.30, 0.35, 1.0)
	add_child(div)
	y_pos += 6.0

	var sub = cart.get_subtotal()
	var tax_amt = cart.get_tax()
	var total = cart.get_total()

	var sub_lbl := Label.new()
	sub_lbl.position = Vector2(pan_x + 110.0, y_pos)
	sub_lbl.text = "Subtotal:"
	sub_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	sub_lbl.add_theme_font_size_override("font_size", 8)
	sub_lbl.gui_input.connect(_on_receipt_input)
	add_child(sub_lbl)
	var sub_val := Label.new()
	sub_val.position = Vector2(pan_x + 160.0, y_pos)
	sub_val.text = "$%.2f" % sub
	sub_val.add_theme_color_override("font_color", Color(0.75, 0.75, 0.72))
	sub_val.add_theme_font_size_override("font_size", 8)
	sub_val.gui_input.connect(_on_receipt_input)
	add_child(sub_val)
	y_pos += line_h

	var tax_lbl := Label.new()
	tax_lbl.position = Vector2(pan_x + 110.0, y_pos)
	tax_lbl.text = "Tax (6%):"
	tax_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	tax_lbl.add_theme_font_size_override("font_size", 8)
	tax_lbl.gui_input.connect(_on_receipt_input)
	add_child(tax_lbl)
	var tax_val := Label.new()
	tax_val.position = Vector2(pan_x + 160.0, y_pos)
	tax_val.text = "$%.2f" % tax_amt
	tax_val.add_theme_color_override("font_color", Color(0.75, 0.75, 0.72))
	tax_val.add_theme_font_size_override("font_size", 8)
	tax_val.gui_input.connect(_on_receipt_input)
	add_child(tax_val)
	y_pos += line_h + 2.0

	var tot_lbl := Label.new()
	tot_lbl.position = Vector2(pan_x + 110.0, y_pos)
	tot_lbl.text = "TOTAL:"
	tot_lbl.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42))
	tot_lbl.add_theme_font_size_override("font_size", 9)
	tot_lbl.gui_input.connect(_on_receipt_input)
	add_child(tot_lbl)
	var tot_val := Label.new()
	tot_val.position = Vector2(pan_x + 160.0, y_pos)
	tot_val.text = "$%.2f" % total
	tot_val.add_theme_color_override("font_color", Color(0.95, 0.85, 0.42))
	tot_val.add_theme_font_size_override("font_size", 9)
	tot_val.gui_input.connect(_on_receipt_input)
	add_child(tot_val)
	y_pos += line_h + 8.0

	var thanks := Label.new()
	thanks.position = Vector2(pan_x + 40.0, y_pos)
	thanks.text = "THANK YOU FOR SHOPPING!"
	thanks.add_theme_color_override("font_color", Color(0.72, 0.88, 0.72))
	thanks.add_theme_font_size_override("font_size", 8)
	thanks.gui_input.connect(_on_receipt_input)
	add_child(thanks)
	y_pos += line_h + 4.0

	var done_lbl := Label.new()
	done_lbl.position = Vector2(pan_x + 60.0, y_pos)
	done_lbl.text = "[E] Done"
	done_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.48))
	done_lbl.add_theme_font_size_override("font_size", 8)
	done_lbl.gui_input.connect(_on_receipt_input)
	add_child(done_lbl)

func _hide_checkout_receipt() -> void:
	_checkout_receipt_visible = false
	for name in ["CROverlay", "CRPanel"]:
		var node = get_node_or_null("/root/Main/" + name)
		if node == null:
			node = get_node_or_null(name)
		if node != null:
			node.queue_free()
	var to_remove: Array = []
	for c in get_children():
		if c is Label or c is ColorRect:
			var nm = c.name if c is Label or c is ColorRect else ""
			if nm in ["CROverlay", "CRPanel"]:
				continue
			if c.get_parent() == self and c.position.y >= 0:
				if c is Label and c.position.x >= 40.0 and c.position.x <= 280.0:
					to_remove.append(c)
				elif c is ColorRect and c.position.x >= 40.0 and c.position.x <= 280.0:
					to_remove.append(c)
	for c in to_remove:
		c.queue_free()

func _on_receipt_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k = event as InputEventKey
		if k.keycode == KEY_E or k.keycode == KEY_ESCAPE or k.keycode == KEY_TAB:
			_finish_checkout()

func _finish_checkout() -> void:
	var cart = _player.get_cart()
	var items = cart.get_items()
	var total_count = cart.get_item_count()
	var total_amount = cart.get_total()
	_hide_checkout_receipt()
	cart.clear()
	_refresh_cart_panel()
	notify_telegram_checkout(total_amount, total_count)

# ???????????????????????????????????????????????????????????????????????????????????????????????# TELEGRAM
# ???????????????????????????????????????????????????????????????????????????????????????????????
func notify_telegram(msg: String) -> void:
	if _telegram_bot != null:
		_telegram_bot.queue_report(msg)

func notify_telegram_checkout(total: float, item_count: int) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_player_checkout(total, item_count)

func notify_telegram_section_browse(section_name: String, product_count: int) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_section_browse(section_name, product_count)

func notify_telegram_npc(count: int) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_npc_spawn(count)

func notify_telegram_error(err: String) -> void:
	if _telegram_bot != null:
		_telegram_bot.notify_game_error(err)

