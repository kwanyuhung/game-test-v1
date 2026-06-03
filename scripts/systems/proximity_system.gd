# proximity_system.gd
# Phase 7 rewrite: Uses GameState for shared state when available.
# Falls back to _main.set() for backwards compatibility.
class_name ProximitySystem
extends Node

const FloorConfig = preload("res://scripts/world/floor_config.gd")

var _main: Node2D = null
var _game_state: GameState = null
var _floor_builder = null
var _player = null
var _checkout_counters: Array = []
var _npcs: Array = []
var _chat_panel = null

# Nearby flags (shared with main via main.set() AND with GameState when available)
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
var _CELL_SIZE: int = FloorConfig.CELL_SIZE

# Track previously nearby objects for bounds visibility
var _prev_nearby_checkout: Node = null
var _prev_nearby_section: Node = null
var _prev_nearby_stall: Node = null
var _prev_nearby_npc: Node = null

# All nearby interactions for numbered bubble display
var _all_nearby_interactions: Array = []

# ── Phase 7: Write proximity to GameState when available ──────────────
func _write_nearby(key: String, value) -> void:
	_main.set(key, value)  # backwards compat
	if _game_state != null:
		_game_state.set(key, value)

func setup_with_game_state(main: Node2D, game_state: GameState) -> void:
	_game_state = game_state
	setup(main)

func setup(main: Node2D) -> void:
	_main = main
	_player = main.get("_player")
	_checkout_counters = main.get("_checkout_counters")
	_npcs = main.get("_npcs")
	_chat_panel = main.get("_chat_panel")
	_checkout_counter_label = main.get("_checkout_counter_label")
	# Register all interactive objects with debug system
	_register_debug_objects()

func refresh_from_floor_manager() -> void:
	# Called when floor changes - update references from FloorManager
	var floor_manager = _main.get("_floor_manager")
	if floor_manager != null:
		_checkout_counters = floor_manager.get_checkout_counters()
		var sections = floor_manager.get_sections()
		# Update floor_builder reference for section access
		_floor_builder = _main.get("_floor_builder")

func _register_debug_objects() -> void:
	var debug_bounds = _main.get("_debug_bounds")
	if debug_bounds == null:
		return
	
	# Register elevator
	var elevator = _main.get("_elevator")
	if elevator:
		debug_bounds.track_elevator(elevator)
	
	# Register checkout counters
	for counter in _checkout_counters:
		debug_bounds.track_checkout(counter)
	
	# Register sections
	if _floor_builder and _floor_builder.has_method("get_sections"):
		for section in _floor_builder.get_sections():
			debug_bounds.track_section(section)
	
	# Register food stalls
	if _floor_builder and _floor_builder.has_method("get_food_stalls"):
		for stall in _floor_builder.get_food_stalls():
			debug_bounds.track_stall(stall)
	
	# Register NPCs
	for npc in _npcs:
		if is_instance_valid(npc):
			debug_bounds.track_npc(npc)
	
	# Register escalators
	if _floor_builder and _floor_builder.has_method("get_escalators"):
		for esc in _floor_builder.get_escalators():
			debug_bounds.track_escalator(esc)

# Build list of all nearby interactions for numbered bubble display
func _collect_all_interactions() -> Array:
	var interactions: Array = []
	
	if _player == null:
		return interactions
	
	var ppos = _player.position
	
	# 0: Elevator
	if nearby_elevator:
		var elevator = _main.get("_elevator")
		interactions.append({
			"index": 0,
			"label": "Elevator",
			"type": "elevator",
			"target": elevator,
			"position": elevator.global_position if elevator else ppos
		})
	
	# 1: Stairs
	if nearby_stairs:
		interactions.append({
			"index": 1,
			"label": "Stairs",
			"type": "stairs",
			"target": null,
			"position": ppos
		})
	
	# 2: Checkout
	if nearby_checkout != null:
		var ctype = nearby_checkout.get_checkout_type() if nearby_checkout.has_method("get_checkout_type") else -1
		var label = "Checkout"
		if ctype == 1: label = "Self-Checkout"
		elif ctype == 0: label = "Express"
		interactions.append({
			"index": 2,
			"label": label,
			"type": "checkout",
			"target": nearby_checkout,
			"position": nearby_checkout.global_position
		})
	
	# 3: Section
	if nearby_section != null:
		var sec_name = "Section"
		if nearby_section.has_method("get_def"):
			var def = nearby_section.get_def()
			if def.has("name"):
				sec_name = def.name
		interactions.append({
			"index": 3,
			"label": sec_name,
			"type": "section",
			"target": nearby_section,
			"position": nearby_section.global_position
		})
	
	# 4: Food Stall
	if nearby_stall != null:
		var stall_name = "Food Stall"
		if nearby_stall.has_method("get_stall_def"):
			var fd = nearby_stall.get_stall_def()
			stall_name = fd.get("name", "Food Stall")
		interactions.append({
			"index": 4,
			"label": stall_name,
			"type": "stall",
			"target": nearby_stall,
			"position": nearby_stall.global_position
		})
	
	# 5: NPC
	if nearby_npc_for_chat != null:
		var npc_name = "NPC"
		if nearby_npc_for_chat.has_method("get_actor"):
			var actor = nearby_npc_for_chat.get_actor()
			if actor != null:
				npc_name = actor.display_name
		interactions.append({
			"index": 5,
			"label": "Talk: " + npc_name,
			"type": "npc",
			"target": nearby_npc_for_chat,
			"position": nearby_npc_for_chat.global_position
		})
	
	# 6: Claw Machine
	if nearby_claw_machine != null:
		var mid = nearby_claw_machine.get_machine_id() if nearby_claw_machine.has_method("get_machine_id") else "1"
		interactions.append({
			"index": 6,
			"label": "Claw #" + mid.replace("claw_", ""),
			"type": "claw",
			"target": nearby_claw_machine,
			"position": nearby_claw_machine.global_position
		})
	
	# 7: Facility (loyalty, gift wrap, kiosk, info desk, cafe, vending, promo, lost & found, news)
	if nearby_loyalty:
		interactions.append({
			"index": 7,
			"label": "Loyalty",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_gift_wrap:
		interactions.append({
			"index": 7,
			"label": "Gift Wrap",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_digital_kiosk:
		interactions.append({
			"index": 7,
			"label": "Directory",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_info_desk:
		interactions.append({
			"index": 7,
			"label": "Info Desk",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_cafe:
		interactions.append({
			"index": 7,
			"label": "Cafe",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_vending:
		interactions.append({
			"index": 7,
			"label": "Vending",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_promo_booth:
		interactions.append({
			"index": 7,
			"label": "Deals",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_lost_found:
		interactions.append({
			"index": 7,
			"label": "Lost & Found",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_store_news:
		interactions.append({
			"index": 7,
			"label": "News",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_karaoke:
		interactions.append({
			"index": 7,
			"label": "Karaoke",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_pool_table:
		interactions.append({
			"index": 7,
			"label": "Pool",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_darts_board:
		interactions.append({
			"index": 7,
			"label": "Darts",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	
	# 8: ATM
	if nearby_atm:
		interactions.append({
			"index": 8,
			"label": "ATM",
			"type": "atm",
			"target": null,
			"position": ppos
		})
	
	# 9: Warehouse/Truck Dock
	if nearby_warehouse_dock:
		interactions.append({
			"index": 9,
			"label": "Truck Dock",
			"type": "warehouse",
			"target": null,
			"position": ppos
		})
	elif nearby_warehouse:
		interactions.append({
			"index": 9,
			"label": "Warehouse",
			"type": "warehouse",
			"target": null,
			"position": ppos
		})
	elif nearby_terminal:
		interactions.append({
			"index": 9,
			"label": "Terminal",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_monitor:
		interactions.append({
			"index": 9,
			"label": "Monitor",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	elif nearby_issue:
		interactions.append({
			"index": 9,
			"label": "Fix Issue",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	
	# Parking
	if nearby_parking:
		interactions.append({
			"index": 9,
			"label": "Parking",
			"type": "facility",
			"target": null,
			"position": ppos
		})
	
	return interactions

func _update_interaction_bubble() -> void:
	var bubble = _main.get("_interaction_bubble")
	if bubble == null:
		return
	
	# Collect all nearby interactions
	_all_nearby_interactions = _collect_all_interactions()
	
	# Show all interactions as numbered bubbles
	if _all_nearby_interactions.size() > 0:
		bubble.show_interactions(_all_nearby_interactions)
	else:
		bubble.hide_all()

# Update bounding box visibility based on proximity
func _update_bounds_visibility() -> void:
	# Handle checkout counters
	if nearby_checkout != _prev_nearby_checkout:
		# Hide previous checkout bounds
		if _prev_nearby_checkout != null and is_instance_valid(_prev_nearby_checkout):
			if _prev_nearby_checkout.has_method("set_bounds_visible"):
				_prev_nearby_checkout.set_bounds_visible(false)
		# Show new checkout bounds
		if nearby_checkout != null and is_instance_valid(nearby_checkout):
			if nearby_checkout.has_method("set_bounds_visible"):
				nearby_checkout.set_bounds_visible(true)
		_prev_nearby_checkout = nearby_checkout
	
	# Handle sections
	if nearby_section != _prev_nearby_section:
		if _prev_nearby_section != null and is_instance_valid(_prev_nearby_section):
			if _prev_nearby_section.has_method("set_bounds_visible"):
				_prev_nearby_section.set_bounds_visible(false)
		if nearby_section != null and is_instance_valid(nearby_section):
			if nearby_section.has_method("set_bounds_visible"):
				nearby_section.set_bounds_visible(true)
		_prev_nearby_section = nearby_section
	
	# Handle food stalls
	if nearby_stall != _prev_nearby_stall:
		if _prev_nearby_stall != null and is_instance_valid(_prev_nearby_stall):
			if _prev_nearby_stall.has_method("set_bounds_visible"):
				_prev_nearby_stall.set_bounds_visible(false)
		if nearby_stall != null and is_instance_valid(nearby_stall):
			if nearby_stall.has_method("set_bounds_visible"):
				nearby_stall.set_bounds_visible(true)
		_prev_nearby_stall = nearby_stall
	
	# Handle NPCs for chat
	if nearby_npc_for_chat != _prev_nearby_npc:
		if _prev_nearby_npc != null and is_instance_valid(_prev_nearby_npc):
			if _prev_nearby_npc.has_method("set_bounds_visible"):
				_prev_nearby_npc.set_bounds_visible(false)
		if nearby_npc_for_chat != null and is_instance_valid(nearby_npc_for_chat):
			if nearby_npc_for_chat.has_method("set_bounds_visible"):
				nearby_npc_for_chat.set_bounds_visible(true)
		_prev_nearby_npc = nearby_npc_for_chat

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
	_update_parking_proximity()
	_update_phase3_proximity()
	# Update the unified interaction hint showing all available [E] actions
	_update_interaction_hint()
	# Update the numbered interaction bubbles above the player
	_update_interaction_bubble()
	# Update bounding box visibility based on proximity
	_update_bounds_visibility()

func _update_elevator_proximity() -> void:
	var _elevator = _main.get("_elevator")
	nearby_elevator = false
	if _player == null or _elevator == null:
		return
	nearby_elevator = _elevator.is_nearby(_player.position)

# ── Build unified interaction hint showing all available [E] interactions ──────────
func _update_interaction_hint() -> void:
	var prompt_bg = _main.get_node_or_null("PromptBg")
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	if prompt_lbl == null:
		return
	
	# Collect all available interactions
	var hints: Array = []
	
	if nearby_elevator:
		hints.append("[0] Elevator")
	if nearby_stairs:
		hints.append("[1] Stairs")
	if nearby_section != null:
		var sec_name = "Section"
		if nearby_section.has_method("get_def"):
			var def = nearby_section.get_def()
			if def.has("name"):
				sec_name = def.name
		hints.append("[3] Browse " + sec_name)
	if nearby_checkout != null:
		var checkout_type = "Checkout"
		if nearby_checkout.has_method("get_checkout_type"):
			var ctype = nearby_checkout.get_checkout_type()
			if ctype == 1: checkout_type = "Self-Checkout"
			elif ctype == 0: checkout_type = "Express Lane"
		hints.append("[2] " + checkout_type)
	if nearby_stall != null:
		hints.append("[4] Food Stall")
	if nearby_claw_machine != null:
		hints.append("[6] Claw Machine")
	if nearby_atm:
		hints.append("[8] ATM")
	if nearby_terminal:
		hints.append("[9] Price Terminal")
	if nearby_monitor:
		hints.append("[9] Monitor")
	if nearby_npc_for_chat != null:
		hints.append("[5] Talk to NPC")
	if nearby_issue:
		hints.append("[9] Fix Issue")
	if nearby_loyalty:
		hints.append("[7] Loyalty")
	if nearby_gift_wrap:
		hints.append("[7] Gift Wrap")
	if nearby_digital_kiosk:
		hints.append("[7] Directory")
	if nearby_info_desk:
		hints.append("[7] Info Desk")
	if nearby_cafe:
		hints.append("[7] Cafe")
	if nearby_vending:
		hints.append("[7] Vending")
	if nearby_promo_booth:
		hints.append("[7] Daily Deals")
	if nearby_lost_found:
		hints.append("[7] Lost & Found")
	if nearby_store_news:
		hints.append("[7] Store News")
	if nearby_karaoke:
		hints.append("[7] Karaoke")
	if nearby_pool_table:
		hints.append("[7] Pool")
	if nearby_darts_board:
		hints.append("[7] Darts")
	if nearby_warehouse_dock:
		hints.append("[9] Truck Dock")
	if nearby_warehouse:
		hints.append("[9] Warehouse")
	if nearby_parking:
		hints.append("[9] Parking")
	
	# Show all hints combined, or hide prompt if nothing nearby
	if hints.size() > 0:
		prompt_lbl.text = " | ".join(hints)
		prompt_lbl.visible = true
		if prompt_bg != null:
			prompt_bg.visible = true
	else:
		prompt_lbl.visible = false
		if prompt_bg != null:
			prompt_bg.visible = false
	
	# Sync to main.gd / GameState
	_write_nearby("_nearby_elevator", nearby_elevator)

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
		var dist :float= ppos.distance_to(stall_center)
		if dist < nearest_dist and dist < _CELL_SIZE * 10.0:
			nearest_dist = dist
			nearby_stall = stall

	_write_nearby("_nearby_stall", nearby_stall)

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
		var dist :float= ppos.distance_to(mc_center)
		if dist < nearest_dist and dist < _CELL_SIZE * 10.0:
			nearest_dist = dist
			nearby_claw_machine = machine

	_write_nearby("_nearby_claw_machine", nearby_claw_machine)

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
		var dist :float= ppos.distance_to(npc.global_position)
		if dist < nearest_dist and dist < _CELL_SIZE * 8.0:
			nearest_dist = dist
			nearby_npc_for_chat = npc

	_main.set_nearby_npc_for_chat(nearby_npc_for_chat)

func _update_issue_proximity() -> void:
	nearby_issue = false
	var _maintenance_system = _main.get("_maintenance_system")
	var _target_issue = _main.get("_target_issue")
	if _player == null or _maintenance_system == null:
		return
	var issue = _maintenance_system.get_issue_at_pos(_player.position, _CELL_SIZE * 7.0)
	nearby_issue = (issue != null)

	if _game_state != null:
		_game_state.nearby_issue = nearby_issue
		_game_state.target_issue = _target_issue
	else:
		_main.set_nearby_issue(nearby_issue)
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

	_write_nearby("_nearby_atm", nearby_atm)

func _update_warehouse_proximity() -> void:
	nearby_warehouse = false
	var _current_floor_idx = _main.get("_current_floor_idx")
	if _player == null or _current_floor_idx != 11:
		return
	var wh_pos := Vector2(40 * _CELL_SIZE, 20 * _CELL_SIZE)
	if _player.position.distance_to(wh_pos) < _CELL_SIZE * 12.0:
		nearby_warehouse = true

	_write_nearby("_nearby_warehouse", nearby_warehouse)

func _update_parking_proximity() -> void:
	nearby_parking = false
	var _current_floor_idx = _main.get("_current_floor_idx")
	if _player == null:
		return
	# Parking is only on ground floor (floor 0)
	if _current_floor_idx != 0:
		return
	var parking_lot = _main.get("_parking_lot")
	if parking_lot == null:
		return
	if parking_lot.has_method("is_player_near"):
		if parking_lot.is_player_near(_player.position):
			nearby_parking = true

	_write_nearby("_nearby_parking", nearby_parking)

func _update_stairs_proximity() -> void:
	nearby_stairs = false
	var _current_floor_idx = _main.get("_current_floor_idx")
	if _player == null:
		return
	var _stairs_system = _main.get("_stairs_system")
	if _stairs_system == null:
		return
	if not _stairs_system.has_method("check_stairs_proximity"):
		return
	var result: Dictionary = _stairs_system.check_stairs_proximity(_player.position, _current_floor_idx)
	nearby_stairs = result.get("in_zone", false)
	
	_write_nearby("_nearby_stairs", nearby_stairs)

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

	_write_nearby("_nearby_monitor", nearby_monitor)

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

	_write_nearby("_nearby_terminal", nearby_terminal)

func _update_checkout_proximity() -> void:
	nearby_checkout = null
	if _floor_builder == null or _player == null:
		return
	var ppos = _player.position
	var nearest_dist := 99999.0
	for counter in _checkout_counters:
		var cpos = counter.position
		var dist :float= ppos.distance_to(cpos)
		if dist < nearest_dist and dist < _CELL_SIZE * 8.0:
			nearest_dist = dist
			nearby_checkout = counter

	_write_nearby("_nearby_checkout", nearby_checkout)

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

	_write_nearby("_nearby_loyalty", nearby_loyalty)
	_write_nearby("_nearby_gift_wrap", nearby_gift_wrap)
	_write_nearby("_nearby_digital_kiosk", nearby_digital_kiosk)
	_write_nearby("_nearby_info_desk", nearby_info_desk)
	_write_nearby("_nearby_cafe", nearby_cafe)
	_write_nearby("_nearby_vending", nearby_vending)
	_write_nearby("_nearby_warehouse_dock", nearby_warehouse_dock)
	_write_nearby("_nearby_karaoke", nearby_karaoke)
	_write_nearby("_nearby_pool_table", nearby_pool_table)
	_write_nearby("_nearby_darts_board", nearby_darts_board)
	_write_nearby("_nearby_promo_booth", nearby_promo_booth)
	_write_nearby("_nearby_lost_found", nearby_lost_found)
	_write_nearby("_nearby_store_news", nearby_store_news)

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

# Get all nearby interactions for external access
func get_all_nearby_interactions() -> Array:
	return _all_nearby_interactions
