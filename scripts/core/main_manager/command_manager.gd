# command_manager.gd
# Phase 7 rewrite: Uses GameState for all shared mutable state.
# Input routing delegates to GameState for mode/proximity flags.
class_name CommandManager
extends Node

# ── Preloads ────────────────────────────────────────────────────────
const SaveSystem = preload("res://scripts/managers/save_system.gd")

# ── Owned state ────────────────────────────────────────────────────
var _main: Node2D = null
var _game_state: GameState = null

# ── setup(main, game_state) ────────────────────────────────────────
func setup(main: Node2D, game_state: GameState) -> void:
	_main = main
	_game_state = game_state

# ── _input(event) — DUPLICATE of main.gd's _input ─────────────────
func _input(event: InputEvent) -> void:
	# Block all input when any panel is blocking
	if PanelManager.is_input_blocked():
		return
	if event is InputEventKey and event.pressed:
		# Stairs W/S ── Open-world floor navigation via stairs
		var _stairs_sys = _main.get("_stairs_system") if _main else null
		var _player = _main.get("_player") if _main else null
		var _current_floor_idx = _main.get("_current_floor_idx") if _main else 0
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
				_handle_chat()
			# F3 ── Dev Tools
			KEY_F3:
				if _main.DEV_MODE:
					PanelManager.toggle("dev_tools")
			# F5 ── Quick Save
			KEY_F5:
				SaveSystem.save_game(_main)
				var toasts = _main.get("_toasts")
				if toasts: toasts.toast_success("Game Saved!")
			# F9 ── Debug Sprite Viewer (if DEV_MODE) or Quick Load
			KEY_F9:
				var _debug_viewer = _main.get("_debug_viewer") if _main else null
				if _main.DEV_MODE and _debug_viewer != null:
					_debug_viewer.toggle()
				else:
					SaveSystem.load_game(_main)
					var toasts = _main.get("_toasts")
					if toasts: toasts.toast_info("Game Loaded!")
			# L ── Shopping List
			KEY_L:
				_main._toggle_shopping_list()
			# T ── Floor Jump Panel (Teleport)
			KEY_T:
				_main._toggle_floor_jump_panel()
			# M ── Map Panel
			KEY_M:
				PanelManager.toggle("map")
			# V ── Floor Panel (Clickable floor selector)
			KEY_V:
				PanelManager.toggle("floor")
			# X ── Renovate nearby section (staff mode)
			KEY_X:
				_main._renovate_nearby_section()
			# F ── Catch thief (when suspicious activity nearby)
			KEY_F:
				_main._attempt_catch_thief()
			# B / Shift+B ── Brand Portal or Business Mode
			KEY_B:
				if event.shift:
					_main._toggle_business_mode()
				else:
					_main._toggle_brand_portal()
			# J ── Quest Journal
			KEY_J:
				_main._toggle_quest_journal()
			# R ── Robot Panel (staff only) OR Restock section
			KEY_R:
				_handle_r_key()
			# O ── Settings
			KEY_O:
				PanelManager.toggle("settings")
			# P / SPACE ── Pause / Resume
			KEY_P:
				_main._toggle_pause()
			KEY_SPACE:
				_main._toggle_pause()
			# K ── Stats Dashboard
			KEY_K:
				_main._toggle_stats_dashboard()
		# 1-8 ── Quick order / loyalty
		if _game_state != null and _game_state.temp_order_mode != "":
			var key_map := {
				KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3,
				KEY_5: 4, KEY_6: 5, KEY_7: 6, KEY_8: 7
			}
			if event.keycode in key_map:
				var idx: int = key_map[event.keycode]
				if idx < _game_state.temp_order_items.size():
					var item: Dictionary = _game_state.temp_order_items[idx]
					var food_court_system = _main.get("_food_court_system") if _main else null
					if food_court_system:
						if _game_state.temp_order_mode == "loyalty":
							food_court_system.handle_loyalty_key(idx, item)
						else:
							food_court_system.add_order_item(idx, item)
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
				_handle_numbered_interaction(num)
				return

		# Warehouse equipment controls (active when in warehouse mode)
		if _game_state != null and _game_state.warehouse_mode:
			_handle_warehouse_input(event)

		# H ── Toggle Shelf Panel (warehouse/storage view)
		if event.keycode == KEY_H:
			_handle_h_key()

# ── Helper methods for input routing ───────────────────────────────
func _handle_stairs_input(direction: int) -> void:
	var stairs_sys = _main.get("_stairs_system") if _main else null
	var player = _main.get("_player") if _main else null
	var current_floor = _main.get("_current_floor_idx") if _main else 0
	if stairs_sys and stairs_sys.has_method("check_stairs_proximity") and player:
		var proximity_result = stairs_sys.check_stairs_proximity(player.position, current_floor)
		if proximity_result.get("in_zone", false):
			if direction == 1 and proximity_result.get("can_go_up", false):
				if not stairs_sys.is_transitioning():
					stairs_sys.start_stairs_transition(1)
			elif direction == -1 and proximity_result.get("can_go_down", false):
				if not stairs_sys.is_transitioning():
					stairs_sys.start_stairs_transition(-1)

func _handle_chat() -> void:
	_main._open_npc_chat()

func _handle_r_key() -> void:
	var nearby_section = _game_state.nearby_section if _game_state != null else null
	var player = _game_state.player if _game_state != null else null
	if nearby_section != null and player != null and player.is_in_staff_mode():
		_main._restock_nearby_section()
	else:
		_main._toggle_robot_panel()

func _handle_h_key() -> void:
	_main._toggle_shelf_panel()

# ── _handle_numbered_interaction(num) — DUPLICATE of main.gd's ───
func _handle_numbered_interaction(num: int) -> void:
	var proximity_system = _main.get("_proximity_system") if _main else null
	if proximity_system == null:
		return

	var interactions = proximity_system.get_all_nearby_interactions()

	# Find interaction with matching index
	var target_interaction = null
	for interaction in interactions:
		if interaction.get("index", -1) == num:
			target_interaction = interaction
			break

	if target_interaction == null:
		# No interaction at this number
		return

	# Highlight the bubble
	var bubble = _main.get_node_or_null("_interaction_bubble") if _main else null
	if bubble != null and bubble.has_method("highlight_bubble"):
		bubble.highlight_bubble(num)

	# Trigger the interaction based on type
	var int_type = target_interaction.get("type", "")
	var target = target_interaction.get("target")

	match int_type:
		"elevator":
			var elev = _main.get("_elevator") if _main else null
			var player = _main.get("_player") if _main else null
			if elev and player: elev.open_panel(player.position, player)
		"stairs":
			_handle_stairs_interaction()
		"checkout":
			if target != null:
				var checkout_system = _main.get("_checkout_system") if _main else null
				if checkout_system: checkout_system.do_checkout(target)
		"section":
			if target != null:
				_main._open_section_browse(target)
		"stall":
			if target != null:
				var stall_id = target.get_stall_id() if target.has_method("get_stall_id") else ""
				_main._on_stall_interact_requested(stall_id)
		"npc":
			_main._open_npc_chat()
		"claw":
			if target != null and target.has_method("start_game"):
				target.start_game()
		"facility":
			_main._handle_facility_interact()
		"atm":
			_main._open_atm_panel()
		"warehouse":
			_main._handle_warehouse_interact()
		_:
			var toasts = _main.get("_toasts") if _main else null
			if toasts:
				toasts.toast_info("Interaction [%d] not yet implemented" % num)

func _handle_stairs_interaction() -> void:
	var stairs_sys = _main.get("_stairs_system") if _main else null
	var player = _main.get("_player") if _main else null
	var current_floor = _main.get("_current_floor_idx") if _main else 0
	if stairs_sys and stairs_sys.has_method("check_stairs_proximity") and player:
		var proximity_result = stairs_sys.check_stairs_proximity(player.position, current_floor)
		if proximity_result.get("in_zone", false):
			var can_go_up = proximity_result.get("can_go_up", false)
			var can_go_down = proximity_result.get("can_go_down", false)
			# Try to go up if possible, otherwise down
			if can_go_up and not stairs_sys.is_transitioning():
				stairs_sys.start_stairs_transition(1)
			elif can_go_down and not stairs_sys.is_transitioning():
				stairs_sys.start_stairs_transition(-1)

func _handle_warehouse_input(event: InputEvent) -> void:
	# Warehouse equipment WASD/Q/E/F/H controls from main.gd
	if not (event is InputEventKey and event.pressed):
		return
	var warehouse_floor = _main.get("_warehouse_floor") if _main else null
	if warehouse_floor == null:
		return
	var dir := Vector2.ZERO
	match event.keycode:
		KEY_W: dir = Vector2(0, -1)
		KEY_S: dir = Vector2(0, 1)
		KEY_A: dir = Vector2(-1, 0)
		KEY_D: dir = Vector2(1, 0)
	if dir != Vector2.ZERO:
		warehouse_floor.drive_truck(dir)
		return
	match event.keycode:
		KEY_Q: warehouse_floor.use_forklift("lower")
		KEY_E: warehouse_floor.use_forklift("raise")
		KEY_F: warehouse_floor.toggle_conveyor()
		KEY_SPACE: warehouse_floor.stop_truck()
