# proximity_system.gd
# All zone-proximity checks consolidated.
# Called each frame by main.gd's _process().
extends Node

var _main: Node2D = null
var _floor_builder = null
var _player = null
var _checkout_counters: Array = []
var _npcs: Array = []
var _chat_panel = null

# Nearby flags (shared with main via main.set())
var nearby_elevator: bool = false
var nearby_stairs: bool = false
var nearby_section: Node = null
var nearby_checkout: Node = null
var nearby_stall: Node = null
var nearby_karaoke: bool = false
var nearby_pool_table: bool = false
var nearby_darts_board: bool = false
var nearby_claw_machine = null
var nearby_npc_for_chat = null
var nearby_issue: bool = false
var nearby_atm: bool = false
var nearby_monitor: bool = false
var nearby_warehouse: bool = false
var nearby_warehouse_dock: bool = false
var nearby_terminal: bool = false
var nearby_loyalty: bool = false
var nearby_gift_wrap: bool = false
var nearby_digital_kiosk: bool = false
var nearby_info_desk: bool = false
var nearby_cafe: bool = false
var nearby_promo_booth: bool = false
var nearby_lost_found: bool = false
var nearby_store_news: bool = false
var nearby_vending: bool = false
var nearby_parking: bool = false

# Cached refs
var _checkout_counter_label = null
var _CELL_SIZE: int = 16

func setup(main: Node2D) -> void:
	_main = main
	_floor_builder = main.get("_floor_builder")
	_player = main.get("_player")
	_checkout_counters = main.get("_checkout_counters")
	_npcs = main.get("_npcs")
	_chat_panel = main.get("_chat_panel")
	_checkout_counter_label = main.get("_checkout_counter_label")
	# Try to get CELL_SIZE from FloorConfig
	var fc = main.get_node_or_null("/root/Main/FloorConfig")
	if fc != null:
		_CELL_SIZE = fc.CELL_SIZE if fc.has_method("get") else 16

func _get_cell_size() -> int:
	return _CELL_SIZE

func update_all() -> void:
	if _main == null:
		return

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
	_update_checkout_proximity()
	_update_phase3_proximity()

func _update_elevator_proximity() -> void:
	var _elevator = _main.get("_elevator")
	nearby_elevator = false
	if _player == null or _elevator == null:
		return
	nearby_elevator = _elevator.is_nearby(_player.position)
	nearby_stairs = false
	nearby_parking = false

	var prompt_bg = _main.get_node_or_null("PromptBg")
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	if nearby_elevator:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Elevator"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
		if _checkout_counter_label != null:
			_checkout_counter_label.visible = false

	_main.set("_nearby_elevator", nearby_elevator)
	_main.set("_nearby_stairs", nearby_stairs)
	_main.set("_nearby_parking", nearby_parking)

func _update_stall_proximity() -> void:
	nearby_stall = null
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for stall in _floor_builder.get_food_stalls():
		var zone = stall.get_zone()
		var stall_center := Vector2(
			(zone.x + zone.w * 0.5) * _CELL_SIZE,
			(zone.y + zone.h * 0.5) * _CELL_SIZE
		)
		var dist := ppos.distance_to(stall_center)
		if dist < nearest_dist and dist < _CELL_SIZE * 10.0:
			nearest_dist = dist
			nearby_stall = stall

	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	if nearby_stall != null and not nearby_elevator and not nearby_stairs:
		if prompt_lbl != null:
			var fd = nearby_stall.get_stall_def()
			prompt_lbl.text = "[E] Order at %s" % fd.name
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_stall", nearby_stall)

func _update_claw_machine_proximity() -> void:
	nearby_claw_machine = null
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for machine in _floor_builder.get_claw_machines():
		var zone = machine.get_zone()
		var mc_center := Vector2(
			(zone.x + zone.w * 0.5) * _CELL_SIZE,
			(zone.y + zone.h * 0.5) * _CELL_SIZE
		)
		var dist := ppos.distance_to(mc_center)
		if dist < nearest_dist and dist < _CELL_SIZE * 10.0:
			nearest_dist = dist
			nearby_claw_machine = machine

	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	if nearby_claw_machine != null and not nearby_elevator and not nearby_stairs:
		if prompt_lbl != null:
			var mid = nearby_claw_machine.get_machine_id()
			prompt_lbl.text = "[E] Play Claw #%s" % mid.replace("claw_", "")
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_claw_machine", nearby_claw_machine)

func _update_npc_chat_proximity() -> void:
	nearby_npc_for_chat = null
	if _player == null or _npcs.is_empty():
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for npc in _npcs:
		if not is_instance_valid(npc):
			continue
		var actor = npc.get_actor()
		if actor == null or not actor.is_active:
			continue
		var dist := ppos.distance_to(npc.global_position)
		if dist < nearest_dist and dist < _CELL_SIZE * 8.0:
			nearest_dist = dist
			nearby_npc_for_chat = npc

	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	if nearby_npc_for_chat != null and not nearby_elevator and not nearby_stairs:
		if _chat_panel == null or not _chat_panel._is_open:
			if prompt_lbl != null:
				var actor = nearby_npc_for_chat.get_actor()
				var role_str := ""
				if actor.role == 1:  # ActorData.Role.STAFF
					var role_names := {
						0: "Cashier",    # CASHIER
						1: "Stocker",    # SHELF_STOCKER
						2: "Cleaner",    # CLEANER
						3: "Security",   # SECURITY
						4: "Greeter",    # GREETER
						5: "Manager",    # MANAGER
						6: "Staff",      # FLOOR_STAFF
					}
					role_str = role_names.get(actor.staff_role, "Staff")
					prompt_lbl.text = "[C] Chat with %s (%s)" % [actor.display_name, role_str]
				else:
					prompt_lbl.text = "[C] Chat with %s" % actor.display_name
				prompt_lbl.visible = true
			if prompt_bg != null:
				prompt_bg.visible = true

	_main.set("_nearby_npc_for_chat", nearby_npc_for_chat)

func _update_issue_proximity() -> void:
	nearby_issue = false
	var _maintenance_system = _main.get("_maintenance_system")
	var _target_issue = _main.get("_target_issue")
	if _player == null or _maintenance_system == null:
		return
	var issue = _maintenance_system.get_issue_at_pos(_player.position, _CELL_SIZE * 7.0)
	nearby_issue = (issue != null)
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	if issue != null and not nearby_elevator and not nearby_stairs:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Fix: %s [%s]" % [issue.label, issue.assigned_to]
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
	if _target_issue != null and _target_issue.status < 2:
		if prompt_lbl != null and not nearby_issue:
			prompt_lbl.text = "[E] Fix: %s (Floor %d)" % [_target_issue.label, _target_issue.floor]
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_issue", nearby_issue)
	_main.set("_target_issue", _target_issue)

func _update_atm_proximity() -> void:
	nearby_atm = false
	if _player == null:
		return
	for node in _main.get_children():
		if node.has_method("is_nearby") and node.name.begins_with("ATM_"):
			if node.is_nearby(_player.position):
				nearby_atm = true
				break
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	if nearby_atm and not nearby_elevator and not nearby_stairs:
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Use ATM"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_atm", nearby_atm)

func _update_warehouse_proximity() -> void:
	nearby_warehouse = false
	var _current_floor_idx = _main.get("_current_floor_idx")
	if _player == null or _current_floor_idx != 11:
		return
	var wh_pos := Vector2(40 * _CELL_SIZE, 20 * _CELL_SIZE)
	if _player.position.distance_to(wh_pos) < _CELL_SIZE * 12.0:
		nearby_warehouse = true
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	var _warehouse_mode = _main.get("_warehouse_mode")
	if nearby_warehouse and not nearby_elevator and not nearby_stairs:
		if prompt_lbl != null:
			if _warehouse_mode:
				prompt_lbl.text = "[WASD] Drive Truck  [Q/E] Forklift  [F] Conveyor  [Space] Stop  [E] Exit"
			else:
				prompt_lbl.text = "[E] Warehouse  [R] Robot Panel"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_warehouse", nearby_warehouse)

func _update_monitor_proximity() -> void:
	nearby_monitor = false
	var _current_floor_idx = _main.get("_current_floor_idx")
	if _player == null:
		return
	if _current_floor_idx != 7 and _current_floor_idx != 8:
		return
	var wh_pos := Vector2(66 * _CELL_SIZE + 2 * _CELL_SIZE, 3 * _CELL_SIZE + 2 * _CELL_SIZE)
	if _player.position.distance_to(wh_pos) < _CELL_SIZE * 8.0:
		nearby_monitor = true
	var prompt_lbl = _main.get_node_or_null('PromptLbl')
	var prompt_bg = _main.get_node_or_null('PromptBg')
	if nearby_monitor and not nearby_elevator and not nearby_stairs:
		if prompt_lbl != null:
			prompt_lbl.text = '[E] Open Monitor Panel'
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_monitor", nearby_monitor)

func _update_terminal_proximity() -> void:
	nearby_terminal = false
	var _current_floor_idx = _main.get("_current_floor_idx")
	if _floor_builder == null or _player == null:
		return
	if _current_floor_idx != 9:
		return
	var terminal_center = _floor_builder.get_office_desk_zone_center()
	if terminal_center.x < 0:
		return
	var ppos = _player.position
	if ppos.distance_to(terminal_center) < _CELL_SIZE * 12.0:
		nearby_terminal = true

	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	var _player_stats = _main.get("_player_stats")
	if nearby_terminal and _player != null and _player.is_in_staff_mode():
		if prompt_lbl != null:
			prompt_lbl.text = "[E] Price Terminal"
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_terminal", nearby_terminal)

func _update_checkout_proximity() -> void:
	nearby_checkout = null
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for counter in _checkout_counters:
		var cpos = counter.position
		var dist := ppos.distance_to(cpos)
		if dist < nearest_dist and dist < _CELL_SIZE * 8.0:
			nearest_dist = dist
			nearby_checkout = counter

	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	if nearby_checkout != null and not nearby_elevator and not nearby_stairs:
		var ctype = nearby_checkout.get_checkout_type()
		var type_str := "Checkout"
		match ctype:
			0: type_str = "[E] Staffed Checkout"    # STAFFED
			1: type_str = "[E] Self-Checkout"       # SELF
			2: type_str = "[E] Express Checkout"    # EXPRESS
		if prompt_lbl != null:
			prompt_lbl.text = type_str
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
	else:
		if prompt_lbl != null:
			var txt = prompt_lbl.text
			if txt == "[E] Staffed Checkout" or txt == "[E] Self-Checkout" or txt == "[E] Express Checkout" or txt == "[E] Checkout":
				prompt_lbl.text = ""

	_main.set("_nearby_checkout", nearby_checkout)

func _update_phase3_proximity() -> void:
	nearby_loyalty = false
	nearby_gift_wrap = false
	nearby_digital_kiosk = false
	nearby_info_desk = false
	nearby_cafe = false
	nearby_vending = false
	nearby_warehouse_dock = false
	nearby_karaoke = false
	nearby_pool_table = false
	nearby_darts_board = false
	nearby_promo_booth = false
	nearby_lost_found = false
	nearby_store_news = false

	if _floor_builder == null or _player == null:
		return

	var ppos = _player.position
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	var prompt_bg = _main.get_node_or_null("PromptBg")
	var _current_floor_idx = _main.get("_current_floor_idx")

	if _floor_builder.is_near_zone_type(17, ppos):  # ZONE_LOYALTY_KIOSK
		nearby_loyalty = true
	if _floor_builder.is_near_zone_type(18, ppos):  # ZONE_GIFT_WRAP
		nearby_gift_wrap = true
	if _floor_builder.is_near_zone_type(19, ppos):  # ZONE_DIGITAL_KIOSK
		nearby_digital_kiosk = true
	if _floor_builder.is_near_zone_type(20, ppos):  # ZONE_INFO_DESK
		nearby_info_desk = true
	if _floor_builder.is_near_zone_type(21, ppos):  # ZONE_CAFE_COUNTER
		nearby_cafe = true
	if _floor_builder.is_near_zone_type(22, ppos):  # ZONE_PROMO_BOOTH
		nearby_promo_booth = true
	if _floor_builder.is_near_zone_type(23, ppos):  # ZONE_STORE_NEWS
		nearby_store_news = true
	if _floor_builder.is_near_zone_type(24, ppos):  # ZONE_KARAOKE
		nearby_karaoke = true
	if _floor_builder.is_near_zone_type(25, ppos):  # ZONE_POOL_TABLE
		nearby_pool_table = true
	if _floor_builder.is_near_zone_type(26, ppos):  # ZONE_DARTS_BOARD
		nearby_darts_board = true
	if _floor_builder.is_near_zone_type(27, ppos):  # ZONE_LOST_FOUND
		nearby_lost_found = true
	if _floor_builder.is_near_zone_type(28, ppos):  # ZONE_VENDING_MACHINE
		nearby_vending = true

	# Floor G: warehouse receiving dock proximity
	if _floor_builder.is_near_zone_type(2, ppos) and _current_floor_idx == 0:  # ZONE_WAREHOUSE
		nearby_warehouse_dock = true

	# Update prompt if no higher-priority prompt is showing
	var show_phase3 = nearby_loyalty or nearby_gift_wrap or nearby_digital_kiosk or nearby_info_desk or nearby_cafe or nearby_vending
	if show_phase3 and not nearby_elevator and not nearby_stairs and nearby_section == null and nearby_checkout == null:
		var txt := "[E] "
		if nearby_loyalty: txt += "Loyalty Sign-Up"
		elif nearby_gift_wrap: txt += "Gift Wrap (+XP)"
		elif nearby_digital_kiosk: txt += "Info Directory [E Browse]"
		elif nearby_warehouse_dock: txt += "Truck Dock [E Unload]"
		elif nearby_warehouse: txt += "Warehouse Ctrl [E Enter]"
		elif nearby_info_desk: txt += "Info Desk"
		elif nearby_cafe: txt += "Cafe Menu"
		elif nearby_karaoke: txt += "Karaoke [E Sing]"
		elif nearby_pool_table: txt += "Pool Table [E Play]"
		elif nearby_darts_board: txt += "Darts [E Throw]"
		elif nearby_promo_booth: txt += "Daily Deals [E Browse]"
		elif nearby_lost_found: txt += "Lost & Found"
		elif nearby_store_news: txt += "Store News [E Read]"
		elif nearby_vending: txt += "Vending Machine"
		if prompt_lbl != null:
			prompt_lbl.text = txt
			prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true

	_main.set("_nearby_loyalty", nearby_loyalty)
	_main.set("_nearby_gift_wrap", nearby_gift_wrap)
	_main.set("_nearby_digital_kiosk", nearby_digital_kiosk)
	_main.set("_nearby_info_desk", nearby_info_desk)
	_main.set("_nearby_cafe", nearby_cafe)
	_main.set("_nearby_vending", nearby_vending)
	_main.set("_nearby_warehouse_dock", nearby_warehouse_dock)
	_main.set("_nearby_karaoke", nearby_karaoke)
	_main.set("_nearby_pool_table", nearby_pool_table)
	_main.set("_nearby_darts_board", nearby_darts_board)
	_main.set("_nearby_promo_booth", nearby_promo_booth)
	_main.set("_nearby_lost_found", nearby_lost_found)
	_main.set("_nearby_store_news", nearby_store_news)

# ── Accessors for main.gd to read current nearby flags ───────────────────────
func get_nearby_section(): return nearby_section
func get_nearby_checkout(): return nearby_checkout
func get_nearby_stall(): return nearby_stall
func get_nearby_elevator(): return nearby_elevator
func get_nearby_stairs(): return nearby_stairs
func get_nearby_claw_machine(): return nearby_claw_machine
func get_nearby_npc_for_chat(): return nearby_npc_for_chat
func get_nearby_issue(): return nearby_issue
func get_nearby_atm(): return nearby_atm
func get_nearby_monitor(): return nearby_monitor
func get_nearby_warehouse(): return nearby_warehouse
func get_nearby_warehouse_dock(): return nearby_warehouse_dock
func get_nearby_terminal(): return nearby_terminal
func get_nearby_loyalty(): return nearby_loyalty
func get_nearby_gift_wrap(): return nearby_gift_wrap
func get_nearby_digital_kiosk(): return nearby_digital_kiosk
func get_nearby_info_desk(): return nearby_info_desk
func get_nearby_cafe(): return nearby_cafe
func get_nearby_promo_booth(): return nearby_promo_booth
func get_nearby_lost_found(): return nearby_lost_found
func get_nearby_store_news(): return nearby_store_news
func get_nearby_vending(): return nearby_vending
func get_nearby_karaoke(): return nearby_karaoke
func get_nearby_pool_table(): return nearby_pool_table
func get_nearby_darts_board(): return nearby_darts_board
func get_nearby_parking(): return nearby_parking

func set_nearby_section(v): nearby_section = v
func set_nearby_checkout(v): nearby_checkout = v
