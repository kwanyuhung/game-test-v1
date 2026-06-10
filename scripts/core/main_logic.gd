# main_logic.gd
# Implementation logic extracted from main.gd to keep the orchestrator slim.
# Owns floor building, panel management, signal handlers, and interaction dispatch.
# main.gd owns the input pipeline (_input, _unhandled_input, _process) and forwards
# events to this file via `_logic._method_name()`. All shared state lives on main.gd
# and is accessed here as `_main._var_name`.
extends Node

var _main: Node2D = null

func setup(main: Node2D) -> void:
	_main = main

const FloorConfigScript = preload("res://scripts/world/floor_config.gd")
const FloorBuilderScript = preload("res://scripts/world/floor_builder.gd")
const FloorManagerScript = preload("res://scripts/world/floor_manager.gd")
const WarehouseFloorScript = preload("res://scripts/systems/warehouse_floor.gd")
const SaveSystem = preload("res://scripts/managers/save_system.gd")
const ChatPanelScript = preload("res://scripts/ui/chat_panel.gd")
const ATMPanelScript = preload("res://scripts/amenities/atm_panel.gd")
const MonitorPanelScript = preload("res://scripts/ui/monitor_panel.gd")
const MaintenancePanelScript = preload("res://scripts/ui/maintenance_panel.gd")
const StatsPanelScript = preload("res://scripts/ui/stats_panel.gd")
const AchievementPopupScript = preload("res://scripts/ui/achievement_popup.gd")
const TutorialOverlayScript = preload("res://scripts/ui/tutorial_overlay.gd")
const MapPanelScript = preload("res://scripts/ui/map_panel.gd")
const FloorPanelScript = preload("res://scripts/ui/floor_panel.gd")
const PriceTerminalScript = preload("res://scripts/systems/price_terminal.gd")
const BusinessModeScript = preload("res://scripts/ui/business_mode.gd")
const ActorData = preload("res://scripts/entities/actor_data.gd")

const CELL_SIZE := FloorConfigScript.CELL_SIZE
const WORLD_W  := FloorConfigScript.WORLD_W
const WORLD_H  := FloorConfigScript.WORLD_H

const WALKABLE_ZONE_TYPES := [
	"ZONE_TROLLEY",
	"ZONE_EXIT",
	"ZONE_CHECKOUT",
	"ZONE_AISLE",
	"ZONE_CUSTOMER_SERVICE",
]

func _build_floor(idx: int) -> void:
	# If FloorManager is active, delegate to it - don't build directly into main
	if _main._floor_manager != null:
		return
	
	_clear_floor_nodes()
	_main._current_floor_idx = idx
	if _main._player_stats != null:
		_main._player_stats.on_floor_visited(idx)
	# HUD labels (time, status, shopping list, XP bar)
	_main._main_panels.build_floor_hud(idx)
	var fd: FloorConfig.FloorDef = FloorConfigScript.get_floor(idx)

	# Create a dedicated container for this floor's content
	var floor_content: Node2D = Node2D.new()
	floor_content.name = "FloorContent"
	_main.add_child(floor_content)
	
	# Use FloorBuilder to render this floor into the container
	_main._floor_builder = FloorBuilderScript.new()
	var _stairs_sys = _main.get("_stairs_system")
	_main._floor_builder.build(fd, floor_content, idx, _stairs_sys)

	# Collect built nodes and sections
	_main._floor_nodes = _main._floor_builder.get_floor_nodes()
	_main._sections = _main._floor_builder.get_sections()
	_main._checkout_counters = _main._floor_builder.get_checkout_counters()

	# Wire section signals
	for sec in _main._sections:
		if sec.has_signal("player_entered"):
			sec.player_entered.connect(_on_section_entered)
		if sec.has_signal("player_exited"):
			sec.player_exited.connect(_on_section_exited)
		if sec.has_signal("interact_requested"):
			sec.interact_requested.connect(_on_section_interact_requested)

	# Ambient
	_main._floor_ambient = fd.ambient_color
	_apply_ambient_shift()
	_update_floor_hud()

	# Build NPCs for this floor (clears old NPCs and spawns new ones for current floor)
	_build_npcs()

	# Wire stall signals
	for stall in _main._floor_builder.get_food_stalls():
		if stall.has_signal("interact_requested"):
			stall.interact_requested.connect(_on_stall_interact_requested)
	# Wire claw machine signals
	for machine in _main._floor_builder.get_claw_machines():
		if machine.has_signal("interact_requested"):
			machine.interact_requested.connect(_on_claw_interact_requested)
		if machine.has_signal("played"):
			machine.played.connect(_on_claw_played.bind(machine))
	# Setup escalators for this floor
	for esc in _main._floor_builder.get_escalators():
		esc.setup(_main)

	# Initialize warehouse floor controller (Floor 11)
	_main._warehouse_floor = WarehouseFloorScript.new()
	_main.add_child(_main._warehouse_floor)
	_main._warehouse_floor.set_staff_mode(false)

	# Spawn AI robot staff across the store
	_spawn_robots()
	# Wire checkout signals
	for counter in _main._checkout_counters:
		if counter.has_signal("checkout_interacted"):
			counter.checkout_interacted.connect(_on_checkout_interacted)
		if counter.has_signal("express_rejected"):
			counter.express_rejected.connect(_main._checkout_system._on_express_rejected)
		if counter.has_signal("self_checkout_error"):
			counter.self_checkout_error.connect(_main._checkout_system._on_self_checkout_error)
		if counter.has_signal("self_checkout_cleared"):
			counter.self_checkout_cleared.connect(_on_self_checkout_cleared)

func _clear_floor_nodes() -> void:
	# Remove the old floor content container completely
	var floor_content: Node = _main.get_node_or_null("FloorContent")
	if floor_content != null:
		_main.remove_child(floor_content)
		floor_content.queue_free()
	
	# Also try to remove any old containers from previous systems
	for i in range(20):  # Assume max 20 floors
		var old_container_name := "FloorObjects_%d" % i
		var old_container: Node = _main.get_node_or_null(old_container_name)
		if old_container != null:
			_main.remove_child(old_container)
			old_container.queue_free()
	
	# Clear all node lists
	_main._floor_nodes.clear()
	_main._sections.clear()
	_main._checkout_counters.clear()
	_main._aisle_labels.clear()

	# Remove all NPC nodes (Staff and Customers) when switching floors by name pattern
	var npcs_to_remove: Array = []
	for c in get_children():
		var nm := c.name as String
		if nm.begins_with("Staff_") or nm.begins_with("Customer_") or nm.begins_with("GroupLeader_") or nm.begins_with("Group_"):
			npcs_to_remove.append(c)
	for c in npcs_to_remove:
		_main.remove_child(c)
		c.queue_free()
	_main._npcs.clear()

	# Remove all robot nodes by reference (more robust than name pattern)
	for r in _main._robots:
		if is_instance_valid(r):
			if r.get_parent() != null:
				_main.remove_child(r)
			r.queue_free()
	_main._robots.clear()
	
	# Also remove any robot nodes by name pattern (for robots created before the fix)
	var robots_to_remove: Array = []
	for c in get_children():
		var nm := c.name as String
		if nm.begins_with("Robot_") or nm.begins_with("Robo_"):
			robots_to_remove.append(c)
	for c in robots_to_remove:
		_main.remove_child(c)
		c.queue_free()

	# Remove warehouse floor controller when switching away from floor 11
	if _main._warehouse_floor != null:
		_main.remove_child(_main._warehouse_floor)
		_main._warehouse_floor.queue_free()
		_main._warehouse_floor = null

	# Clear debug bounds tracking to prevent overlap from previous floors
	var debug_bounds = _main.get("_debug_bounds")
	if debug_bounds != null and debug_bounds.has_method("clear_all"):
		debug_bounds.clear_all()

# Get floor information for UI display
func get_floor_info() -> Dictionary:
	var fd: FloorConfig.FloorDef = FloorConfigScript.get_floor(_main._current_floor_idx)
	var info := {
		"index": _main._current_floor_idx,
		"name": fd.label if fd else "Unknown",
		"theme": fd.theme if fd else "unknown",
		"zone_count": fd.zones.size() if fd else 0,
		"section_count": _main._sections.size(),
		"npc_count": _main._npcs.size(),
		"checkout_count": _main._checkout_counters.size(),
	}
	return info

#  Ambient Color 

func set_ambient_floor(idx: int) -> void:
	_main._current_floor_idx = idx
	var fd: FloorConfig.FloorDef = FloorConfigScript.get_floor(idx)
	_main._floor_ambient = fd.ambient_color
	_apply_ambient_shift()
	_update_floor_hud()

func _apply_ambient_shift() -> void:
	if _main._world_bg != null:
		_main._world_bg.color = _main._floor_ambient.darkened(0.6)

func _build_elevator() -> void:
	if _main._main_panels != null:
		_main._main_panels.build_elevator()

func _build_parking() -> void:
	if _main._main_panels != null:
		_main._main_panels.build_parking()

#  Player boards elevator

func player_board_elevator(_player, _floor_idx: int) -> void:
	_main._in_elevator = true
	# Don't teleport: the cosmetic-bank elevator has no virtual interior to
	# move the player into. The fade-to-black during travel hides the
	# transition; the player remains where they pressed E.

func _elevator_arrival_position(floor_idx: int) -> Vector2:
	return elevator_arrival_position(floor_idx)

func elevator_arrival_position(floor_idx: int) -> Vector2:
	# World position the player materializes at after travel completes or after
	# any floor change. Tries to land 2 tiles south of the first ZONE_ELEVATOR
	# cabin so the player visibly steps out of the elevator bank. Falls back to
	# the legacy tile-6 spot for floors that don't yet define ZONE_ELEVATOR.
	var floor_y: float = FloorManagerScript.get_floor_y(floor_idx)
	var floor_def = FloorConfigScript.get_floor(floor_idx)
	if floor_def != null:
		for zone in floor_def.zones:
			if zone.get("type", "") != "ZONE_ELEVATOR":
				continue
			var cx: int = zone.get("x", 0)
			var cy: int = zone.get("y", 0)
			var cw: int = zone.get("w", 1)
			var ch: int = zone.get("h", 1)
			var px: float = (cx + cw * 0.5) * CELL_SIZE
			var py: float = floor_y + (cy + ch + 2) * CELL_SIZE
			return Vector2(px, py)
	return Vector2(6 * CELL_SIZE + 7 * CELL_SIZE, floor_y + 20 * CELL_SIZE)

#  Floor reached after travel 

func _on_elevator_floor_reached(floor_idx: int) -> void:
	_main._current_floor_idx = floor_idx

func _on_elevator_travel_finished() -> void:
	_main._in_elevator = false
	if _main._fade != null:
		_main._fade.fade_out(0.2)
		await _main.get_tree().create_timer(0.25).timeout

	# Use FloorManager for multi-floor system
	if _main._floor_manager != null:
		_main._floor_manager.on_travel_completed(_main._current_floor_idx)
		# Position player just outside the first elevator cabin on the new
		# floor (the "stepping out of the elevator" pose). Falls back to the
		# legacy tile-6 spot if the floor has no ZONE_ELEVATOR data.
		if _main._player != null:
			_main._player.position = _elevator_arrival_position(_main._current_floor_idx)
	if _camera != null:
		update_camera_limits(_main._current_floor_idx)
	else:
		_rebuild_floor(_main._current_floor_idx)
		if _main._player != null:
			_main._player.position = _elevator_arrival_position(_main._current_floor_idx)
	
	if _main._fade != null:
		_main._fade.fade_in(0.3)
	if _main._minimap != null:
		_main._minimap.set_floor(_main._current_floor_idx)
	if _main._map_panel != null:
		_main._map_panel.set_floor(_main._current_floor_idx)
	if _main._toasts != null:
		var fname := "Ground" if _main._current_floor_idx == 0 else ("Floor " + str(_main._current_floor_idx))
		_main._toasts.toast_info("Entered: " + fname)
	if _main._audio != null:
		_main._audio.play_floor_change()

func _build_sections_for_current_floor() -> void:
	if _main._main_panels != null:
		_main._main_panels.build_sections_for_current_floor()

func _build_checkout_for_current_floor() -> void:
	if _main._main_panels != null:
		_main._main_panels.build_checkout_for_current_floor()

func _rebuild_floor(idx: int) -> void:
	# If FloorManager is active, delegate to it instead of full rebuild
	if _main._floor_manager != null:
		_rebuild_floor_with_manager(idx)
		return
	
	_clear_floor_nodes()
	_main._world_bg = null
	_build_floor(idx)
	_build_sections_for_current_floor()
	_build_checkout_for_current_floor()
	# Re-add elevator on top
	_main._elevator = _main.get_node_or_null("Elevator")
	if _main._elevator == null:
		_build_elevator()
	_apply_ambient_shift()
	_update_floor_hud()

func _rebuild_floor_with_manager(idx: int) -> void:
	# FloorManager handles activation/deactivation - we just update local references
	# and ensure the current floor's content is properly linked
	var container = _main._floor_manager.get_floor_container(idx)
	if container == null:
		return
	
	# Update our local references to point to nodes in the container
	_main._sections.clear()
	_main._checkout_counters.clear()
	_main._aisle_labels.clear()
	
	# Find sections, checkout counters, etc. in the container
	for child in container.get_children():
		if child.name.begins_with("Section_"):
			_main._sections.append(child)
		elif child.name.begins_with("Counter_"):
			_main._checkout_counters.append(child)
		elif child is Label:
			_main._aisle_labels.append(child)
	
	# Update ambient and HUD
	_apply_ambient_shift()
	_update_floor_hud()

var _camera: Camera2D = null

const CAMERA_ZOOM := 0.5
const CAMERA_ZOOM_MIN := 0.25
const CAMERA_ZOOM_MAX := 2.0
const CAMERA_ZOOM_STEP := 0.1

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	_main.add_child(_camera)
	_camera.make_current()
	update_camera_limits(_main._current_floor_idx)
	var p: Node2D = _main.get("_player")
	print("[Camera] pos=%s zoom=%s limits=(top=%d, bottom=%d, left=%d, right=%d) player=%s" % [
		_camera.position, _camera.zoom, _camera.limit_top, _camera.limit_bottom, _camera.limit_left, _camera.limit_right,
		(p.position if p else Vector2.ZERO)
	])

func update_camera_limits(floor_idx: int) -> void:
	if _camera == null:
		return
	var container_y: float = FloorManagerScript.get_floor_y(floor_idx)
	var zone_bounds: Dictionary = _get_floor_zone_bounds(floor_idx)
	_camera.limit_left = 0
	_camera.limit_top = int(container_y + zone_bounds.min_y * CELL_SIZE)
	_camera.limit_right = int(WORLD_W * CELL_SIZE)
	_camera.limit_bottom = int(container_y + zone_bounds.max_y * CELL_SIZE)

func _get_floor_zone_bounds(floor_idx: int) -> Dictionary:
	var fd = FloorConfigScript.get_floor(floor_idx)
	if fd == null:
		return {"min_y": 2, "max_y": 42, "height": 40}
	var min_y = 800
	var max_y = 0
	for zone in fd.zones:
		if zone.y < min_y:
			min_y = zone.y
		if zone.y + zone.h > max_y:
			max_y = zone.y + zone.h
	return {"min_y": min_y, "max_y": max_y, "height": max_y - min_y + 4}

# Zone types the player can walk through (aisles, exits, checkout, trolley pickup)
# Every other zone type is treated as a blocked shelf/service area.

# Check if a world position is blocked by a non-walkable zone.
# Default: walkable (gaps between zones are walkable aisles).
# A position is BLOCKED only if it is inside at least one non-walkable zone AND
# not inside any walkable zone (so an aisle nested inside a parent decor zone
# still works).
func is_position_blocked(floor_idx: int, world_x: float, world_y: float) -> bool:
	var fd = FloorConfigScript.get_floor(floor_idx)
	if fd == null:
		return false

	# Zones are relative to floor container, so subtract container offset
	var container_y := FloorManagerScript.get_floor_y(floor_idx)
	var local_x := world_x
	var local_y := world_y - container_y

	var tile_x := int(local_x / CELL_SIZE)
	var tile_y := int(local_y / CELL_SIZE)

	var inside_non_walkable := false
	for zone in fd.zones:
		var zx: int = zone.get("x", 0)
		var zy: int = zone.get("y", 0)
		var zw: int = zone.get("w", 1)
		var zh: int = zone.get("h", 1)
		if tile_x >= zx and tile_x < zx + zw and tile_y >= zy and tile_y < zy + zh:
			if zone.get("type", "") in WALKABLE_ZONE_TYPES:
				# Walkable zone wins immediately (e.g., aisle inside parent decor)
				return false
			inside_non_walkable = true

	return inside_non_walkable

func get_current_floor_idx() -> int:
	return _main._current_floor_idx

func _build_hud() -> void:
	pass  # HUD built by main_hud.gd in _ready()

func _show_save_hint(msg: String) -> void:
	if _main._save_hint_label != null:
		_main._save_hint_label.text = msg
		_main._save_hint_label.visible = true
		await _main.get_tree().create_timer(2.0).timeout
		_main._save_hint_label.visible = false
func _build_checkout_receipt_panel() -> void:
	pass  # receipt panel built by main_hud.gd

func _update_floor_hud() -> void:
	if _main._main_panels != null:
		_main._main_panels.update_floor_hud()

func _spawn_player() -> void:
	_main._main_spawner.spawn_player()

func _on_cart_updated(items: Array, subtotal: float) -> void:
	var main_hud = _main.get_node_or_null("MainHUD")
	if main_hud != null and main_hud.has_method("update_cart"):
		main_hud.update_cart(items, subtotal)

func _build_npcs() -> void:
	_main._main_spawner.build_npcs()
	return
func _spawn_npc_staff(role: int, floor_idx: int, pos: Vector2) -> void:
	_main._main_spawner.spawn_npc_staff(role, floor_idx, pos)
	return
func _spawn_customer(group_type: int, floor_idx: int, pos: Vector2) -> void:
	_main._main_spawner.spawn_customer(group_type, floor_idx, pos)
	return
func _spawn_customer_group(group_type: int, floor_idx: int, pos: Vector2) -> void:
	_main._main_spawner.spawn_customer_group(group_type, floor_idx, pos)
	return
func _on_warehouse_delivery_arrived(_contents: Dictionary) -> void:
	# Spawn truck at dock on Floor G
	_main._truck_dock_system.spawn_truck()

func _on_warehouse_low_stock(section_id: String) -> void:
	var section_name := section_id.to_upper()
	if _main._current_floor_idx == 11:  # on warehouse floor
		var prompt_lbl = _main.get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "WARN: %s LOW STOCK" % section_name
			prompt_lbl.visible = true

func _open_atm_panel() -> void:
	if _main._atm_panel != null and _main._atm_panel.visible:
		return
	# Find the nearest ATM
	var nearest_atm = null
	for node in get_children():
		if node.has_method("is_nearby") and node.name.begins_with("ATM_"):
			if node.is_nearby(_main._player.position):
				nearest_atm = node
				break
	if nearest_atm == null:
		return
	_main._atm_panel = ATMPanelScript.new()
	_main.add_child(_main._atm_panel)
	_main._atm_panel.open(nearest_atm)
	_main._atm_panel.closed.connect(_on_atm_panel_closed)
	_main._atm_panel.withdraw_success.connect(_on_atm_withdraw_success)

func _on_atm_panel_closed() -> void:
	_main._atm_panel = null

func _open_monitor_panel() -> void:
	if _main._monitor_panel != null and _main._monitor_panel.visible:
		_main._monitor_panel.close()
		return
	_main._monitor_panel = MonitorPanelScript.new()
	_main.add_child(_main._monitor_panel)
	_main._monitor_panel.open(self)
	_main._monitor_panel.closed.connect(_on_monitor_panel_closed)

func _on_monitor_panel_closed() -> void:
	_main._monitor_panel = null

func _on_atm_withdraw_success(amount: float) -> void:
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	if prompt_lbl != null:
		prompt_lbl.text = "Withdrew $%.2f" % amount

func _toggle_dev_tools() -> void:
	if _main._dev_tools == null:
		return
	if _main._dev_tools.visible:
		_main._dev_tools.close()
	else:
		_main._dev_tools.open()

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
	_main._main_spawner.spawn_test_customers(count)
	return
func _spawn_test_staff(count: int) -> void:
	_main._main_spawner.spawn_test_staff(count)
	return
func _kill_all_test_npcs() -> void:
	for npc in _main._npcs:
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	_main._npcs.clear()

func _toggle_maintenance_panel() -> void:
	if _main._maintenance_panel != null and _main._maintenance_panel.visible:
		_main._maintenance_panel.close()
		return
	if _main._maintenance_system == null:
		return
	_main._maintenance_panel = MaintenancePanelScript.new()
	_main.add_child(_main._maintenance_panel)
	PanelManager.register("maintenance", _main._maintenance_panel, PanelManager.Policy.ALONE)
	_main._maintenance_panel.open(_main._maintenance_system)
	_main._maintenance_panel.closed.connect(_on_maintenance_panel_closed)
	_main._maintenance_panel.issue_selected.connect(_on_maintenance_issue_selected)

func _on_maintenance_panel_closed() -> void:
	_main._maintenance_panel = null

func is_input_blocked() -> bool:
	return PanelManager.is_input_blocked()

func _on_maintenance_issue_selected(issue) -> void:
	_main._target_issue = issue
	# Walk player to the issue's floor first if not there
	if _main._player != null and issue.floor != _main._current_floor_idx:
		_navigate_to_floor(issue.floor)

func _navigate_to_floor(floor_idx: int) -> void:
	if floor_idx == _main._current_floor_idx:
		return
	_main._current_floor_idx = floor_idx
	
	# Use FloorManager for multi-floor system if available
	if _main._floor_manager != null:
		_main._floor_manager.on_floor_changed(floor_idx)
	else:
		_rebuild_floor(floor_idx)
	
	if _main._player:
		_main._player.position = elevator_arrival_position(floor_idx)
	if _main._minimap:
		_main._minimap.set_floor(floor_idx)
	if _main._toasts:
		var fname = "Ground" if floor_idx == 0 else "Floor " + str(floor_idx)
		_main._toasts.toast_info("Moved to " + fname)

# DEBUG: Quick jump to any floor (dev mode only)
func _jump_to_floor(floor_idx: int) -> void:
	var max_floors := FloorConfigScript.floor_count()
	if floor_idx < 0 or floor_idx >= max_floors:
		if _main._toasts:
			_main._toasts.toast_warning("Invalid floor! Range: 0-%d" % (max_floors - 1))
		return

	_main._current_floor_idx = floor_idx

	# Use FloorManager for multi-floor system
	if _main._floor_manager != null:
		_main._floor_manager.on_floor_changed(floor_idx)
	else:
		_rebuild_floor(floor_idx)

	if _camera:
		update_camera_limits(floor_idx)
	if _main._player:
		# Land 2 tiles south of the first cabin on the new floor
		_main._player.position = elevator_arrival_position(floor_idx)
	if _main._minimap:
		_main._minimap.set_floor(floor_idx)
	if _main._map_panel:
		_main._map_panel.set_floor(floor_idx)
	if _main._toasts:
		var fname = "Ground" if floor_idx == 0 else ("Floor " + str(floor_idx))
		_main._toasts.toast_success("[DEBUG] Jumped to " + fname)

func _on_issue_created(issue) -> void:
	if is_instance_valid(_main._maintenance_visual):
		_main._maintenance_visual.build_issue_sprite(issue)

func _on_issue_resolved(issue, by_player: bool) -> void:
	if is_instance_valid(_main._maintenance_visual):
		_main._maintenance_visual.remove_issue_sprite(issue.id)
	if by_player and _main._player != null:
		var prompt_lbl = _main.get_node_or_null("PromptLbl")
		if prompt_lbl != null:
			prompt_lbl.text = "Issue resolved! +10 XP"
	if issue == _main._target_issue:
		_main._target_issue = null
	if by_player and _main._player_stats != null:
		_main._player_stats.on_issue_resolved(issue.label)

func _on_achievement_unlocked(ach_id: String) -> void:
	if _main._player_stats == null:
		return
	var info: Dictionary = _main._player_stats.get_achievement_info(ach_id)
	_show_achievement_popup(ach_id, info.get("name", ""), info.get("icon", "?"), info.get("xp", 20))

func _show_achievement_popup(ach_id: String, ach_name: String, icon: String, xp: int) -> void:
	var popup := AchievementPopupScript.new()
	_main.add_child(popup)
	popup.show_achievement(ach_id, ach_name, icon, xp)

func _on_staff_rank_up(new_rank: PlayerStats.StaffRank) -> void:
	var rank_name := "???"
	match new_rank:
		PlayerStats.StaffRank.TRAINEE: rank_name = "Trainee"
		PlayerStats.StaffRank.WORKER: rank_name = "Worker"
		PlayerStats.StaffRank.SENIOR: rank_name = "Senior"
		PlayerStats.StaffRank.SUPERVISOR: rank_name = "Supervisor"
		PlayerStats.StaffRank.MANAGER: rank_name = "Manager"
	if _main._toasts:
		_main._toasts.toast_success("STAFF RANK UP to %s!" % rank_name)
	_update_staff_rank_hud()

func _update_staff_rank_hud() -> void:
	if _main._main_panels != null:
		_main._main_panels.update_staff_rank_hud()

func _on_player_level_up(new_level: int) -> void:
	var prompt_lbl = _main.get_node_or_null("PromptLbl")
	if prompt_lbl != null:
		prompt_lbl.text = "LEVEL UP! You are now Level %d!" % new_level
		prompt_lbl.visible = true

func _toggle_stats_panel() -> void:
	if _main._stats_panel != null and _main._stats_panel.visible:
		_main._stats_panel.close()
		return
	if _main._player_stats == null:
		return
	_main._stats_panel = StatsPanelScript.new()
	_main.add_child(_main._stats_panel)
	PanelManager.register("stats", _main._stats_panel, PanelManager.Policy.ALONE)
	_main._stats_panel.open(_main._player_stats)
	_main._stats_panel.closed.connect(_on_stats_panel_closed)

func _on_stats_panel_closed() -> void:
	_main._stats_panel = null

func _on_hour_changed(hour: int) -> void:
	if _main._game_clock != null:
		if hour == 6:  # Store opens
			if _main._toasts != null: _main._toasts.toast_success("Store Open! 6:00 AM")
		if hour == 23:  # 11pm closing soon
			if _main._toasts != null: _main._toasts.toast_warn("Store Closing - 11:00 PM")

# ── Phase M: Staff Management — Day/Shift handlers ─────────────
func _on_day_changed() -> void:
	# Pay staff wages at end of each day
	if _main._player_stats != null:
		var wages: float = _main._player_stats.get_total_daily_wages()
		if wages > 0 and _main._player_stats.get_cash() >= wages:
			_main._player_stats.pay_staff_wages(_main._player_stats.get_cash())
			if _main._toasts:
				_main._toasts.toast_info("Daily wages paid: $%.2f" % wages)
	else:
		if _main._toasts:
			_main._toasts.toast_warn("Could not pay staff wages!")

func _on_shift_report() -> void:
	# Called every in-game shift (morning/afternoon/night)
	if _main._player_stats != null:
		_main._player_stats.on_shift_completed()
		var roster: Array = _main._player_stats.get_staff_roster()
		var active: int = roster.size()
		if _main._toasts:
			_main._toasts.toast_success("Shift complete! %d staff on duty. +30 Staff XP" % active)

func _show_tutorial_overlay() -> void:
	if _main._tutorial_overlay != null:
		_main._tutorial_overlay.queue_free()
	_main._tutorial_overlay = TutorialOverlayScript.new()
	_main.add_child(_main._tutorial_overlay)
	_main._tutorial_overlay.show_tutorial()
	_main._tutorial_overlay.dismissed.connect(_on_tutorial_dismissed)

func _on_tutorial_dismissed() -> void:
	# Optional: save a flag that tutorial was seen
	if _main._player_stats:
		_main._player_stats.set_tutorial_completed(true)

func _toggle_shopping_list() -> void:
	if _main._shopping_list == null: return
	_main._shopping_list_visible = not _main._shopping_list_visible
	if _main._shopping_list_visible:
		_main._shopping_list.open()
		_main._toasts.toast_info("Shopping List")
	else:
		_main._shopping_list.close()

func add_to_shopping_list(product_name: String) -> bool:
	if _main._shopping_list != null:
		return _main._shopping_list.add_item(product_name)
	return false

func _on_quest_completed(_quest_id: String, desc: String, xp: int) -> void:
	if _main._toasts != null:
		_main._toasts.toast_success("Quest Done! +%d XP" % xp)
	if _main._player_stats != null:
		_main._player_stats.add_xp(xp, "Daily Quest: %s" % desc)
		SaveSystem.save_game(self)

func _on_cart_dropped() -> void:
	if _main._toasts != null:
		_main._toasts.toast_info("Cart dropped. Press [G] to grab it back.")

func _on_cart_grabbed() -> void:
	if _main._toasts != null:
		_main._toasts.toast_info("Cart grabbed!")

func _on_all_quests_complete() -> void:
	if _main._toasts != null:
		_main._toasts.toast_xp("All Daily Quests Done! Epic Bonus!")
	if _main._player_stats != null:
		_main._player_stats.add_xp(50, "All Quests Bonus")

func _toggle_quest_journal() -> void:
	if _main._quest_journal == null: return
	_main._quest_journal.toggle()
	if _main._quest_journal.visible: _main._quest_journal.refresh_from_quest_system(_main._quest_system)

func _toggle_settings_panel() -> void:
	if _main._settings_panel == null: return
	_main._settings_panel.toggle()

func _on_setting_changed(key: String, value) -> void:
	match key:
		"bgm":
			if _main._audio != null: _main._audio.set_music_volume(value)
		"sfx":
			if _main._audio != null: _main._audio.set_sfx_volume(value)
		"notif_toasts":
			# Toasts are always on, just a flag
			pass
		"draw_factory_robot_1":
			_apply_factory_robot_settings()
		"draw_factory_robot_2":
			_apply_factory_robot_settings()
		"draw_factory_robot_3":
			_apply_factory_robot_settings()
		"draw_interactive":
			_apply_interactive_settings(value)

func _apply_factory_robot_settings() -> void:
	if _main._warehouse_floor == null:
		return
	var sp: Node = _main._settings_panel
	if sp == null:
		return
	var r1: bool = sp.get_setting("draw_factory_robot_1")
	var r2: bool = sp.get_setting("draw_factory_robot_2")
	var r3: bool = sp.get_setting("draw_factory_robot_3")
	_main._warehouse_floor.set_factory_robot_visibility(r1, r2, r3)

func _apply_interactive_settings(enabled: bool) -> void:
	# Control interaction bubble visibility
	var bubble: Node2D = _main.get_node_or_null("_interaction_bubble")
	if bubble != null and bubble.has_method("set_interaction_visible"):
		bubble.set_interaction_visible(enabled)

func _toggle_pause() -> void:
	if _main._current_section_browse != null and _main._current_section_browse.visible: return
	if _main._checkout_receipt_visible: return
	if _main._in_elevator: return
	if _main._pause_menu == null: return
	_main._pause_menu.toggle()

func _on_game_paused() -> void:
	if _main._toasts != null: _main._toasts.toast_info("Game Paused")

func _on_game_resumed() -> void:
	if _main._toasts != null: _main._toasts.toast_info("Game Resumed")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3-6 WIRING: Signal handlers & proximity updates that were connected
# but never implemented. These make E-key interactions actually work.
# ─────────────────────────────────────────────────────────────────────────────

# ── Section enter/exit ───────────────────────────────────────────
func _on_section_entered(section_id: String) -> void:
	# Find the section node and set it as nearby
	if _main._floor_builder == null:
		return
	for sec in _main._sections:
		if sec.get_def().id == section_id:
			_main._nearby_section = sec
			var prompt_lbl = _main.get_node_or_null("PromptLbl")
			var prompt_bg = _main.get_node_or_null("PromptBg")
			# ── Phase L: Show stock level in prompt ─────────────────
			var stock_info := ""
			if _main._warehouse != null:
				var ratio: float = _main._warehouse.get_stock_ratio(section_id)
				var pct := int(ratio * 100)
				var stock_color := "OK"
				if pct < 30: stock_color = "LOW"
				elif pct == 0: stock_color = "OUT"
				stock_info = " | Stock: %s (%d%%)" % [stock_color, pct]
			var reno_info := ""
			if _main._store_expansion != null and sec != null:
				var sec_id = sec.get_def().id
				if not _main._store_expansion.is_section_renovated(sec_id):
					var cost = _main._store_expansion.get_renovation_cost(sec_id)
					reno_info = " | [X] Renovate ($%d)" % cost
				else:
					reno_info = " | Renovated x%d" % _main._store_expansion.get_section_upgrade_level(sec_id)
			var staff_r := ""
			if _main._player != null and _main._player.is_in_staff_mode():
				staff_r = " | [R] Restock"
			if prompt_lbl != null:
				prompt_lbl.text = "[E] Browse %s%s%s%s" % [sec.get_def().name, stock_info, reno_info, staff_r]
				prompt_lbl.visible = true
			if prompt_bg != null:
				prompt_bg.visible = true
			break

func _on_section_exited(section_id: String) -> void:
	if _main._nearby_section != null and _main._nearby_section.get_def().id == section_id:
		_main._nearby_section = null

func _on_section_interact_requested(section_id: String) -> void:
	# Mouse click on a nearby section — open the buy panel.
	for sec in _main._sections:
		if sec.get_def().id == section_id:
			_open_section_browse(sec)
			return

# ── Player E-key interact ───────────────────────────────────────
func handle_player_interact() -> void:
	# Delegate to SystemManager (reads proximity from GameState)
	var sm = _main.get("_system_manager")
	if sm != null and sm.has_method("on_player_interact"):
		sm.on_player_interact()

	# Warehouse Receiving Dock (Floor G) — truck unloading
	if _main._nearby_warehouse_dock:
		_main._truck_dock_system.do_unload()
		return
	# Warehouse Control Mode (Floor 11)
	if _main._nearby_warehouse:
		_handle_warehouse_interact()
		return

	# Phase 3: Interactive facilities
	if _main._nearby_loyalty or _main._nearby_gift_wrap or _main._nearby_digital_kiosk or _main._nearby_info_desk or _main._temp_order_mode != "" or _main._nearby_cafe or _main._nearby_vending or _main._nearby_promo_booth or _main._nearby_lost_found or _main._nearby_store_news or _main._nearby_karaoke or _main._nearby_pool_table or _main._nearby_darts_board:
		_handle_facility_interact()
		return

	# Parking (Ground floor)
	if _main._nearby_parking:
		_handle_parking_interact()
		return

func _handle_facility_interact() -> void:
	if _main._nearby_loyalty:
		_main._temp_order_mode = "loyalty"
		_main._temp_order_items = [{"name": "5 Coins", "price": 2.0}, {"name": "Sign Up Loyalty", "price": 0.0}]
		if _main._player_stats != null and _main._player_stats.is_loyalty_member():
			var pts = _main._player_stats.get_loyalty_points()
			_main._toasts.toast_info("Loyalty: %d pts | [1] Buy 5 Coins $2 | [2] Loyalty Status" % pts)
		else:
			_main._toasts.toast_info("Loyalty: [1] Sign Up Free | [2] Buy 5 Coins $2")
		var hint = _main.get_node_or_null("PromptLbl")
		if hint != null:
			hint.text = "[1] Coins  [2] Loyalty  [E] Done"
		return
	if _main._nearby_gift_wrap:
		if _main._cart_gift_wrapped:
			if _main._toasts != null: _main._toasts.toast_info("Cart already gift wrapped!")
		else:
			_main._cart_gift_wrapped = true
			if _main._toasts != null: _main._toasts.toast_success("Cart gift wrapped! +$2 tip at checkout!")
		return
	if _main._nearby_digital_kiosk:
		if _main._toasts != null: _main._toasts.toast_info("Floor Directory: G=Lobby+Food, 1=Fresh, 2=Pantry, 3=Drinks, 4=Snacks, 5=Frozen, 6=Household, 7=H+B, 8=Arcade, 9=Staff, 10=Cafe")
		return
	if _main._nearby_info_desk:
		if _main._toasts != null: _main._toasts.toast_info("Welcome to Pixel Supermarket! Use elevator or stairs to navigate.")
		return
	if _main._temp_order_mode != "":
		_main._food_court_system.finish_order()
		return
	if _main._nearby_cafe:
		_main._food_court_system.open_cafe_browse()
		return
	if _main._nearby_vending:
		_main._food_court_system.open_vending_browse()
		return
	if _main._nearby_promo_booth:
		_main._food_court_system.open_promo_booth()
		return
	if _main._nearby_lost_found:
		if _main._toasts: _main._toasts.toast_info("Lost & Found: No items reported yet!")
		return
	if _main._nearby_store_news:
		_main._food_court_system.read_store_news()
		return
	if _main._nearby_karaoke:
		_main._food_court_system.play_karaoke()
		return
	if _main._nearby_pool_table:
		_main._food_court_system.play_pool()
		return
	if _main._nearby_darts_board:
		_main._food_court_system.play_darts()
		return

# ── Parking interaction ─────────────────────────────────────────
func _handle_parking_interact() -> void:
	if _main._parking_lot == null:
		return
	var slot_idx = _main._parking_lot.get_nearby_slot(_main._player.position) if _main._parking_lot.has_method("get_nearby_slot") else -1
	if slot_idx >= 0:
		var slot_info = _main._parking_lot.get_slot_info(slot_idx)
		if slot_info.get("occupied", false):
			if _main._toasts: _main._toasts.toast_info("Parking slot %d is occupied!" % (slot_idx + 1))
		else:
			if _main._toasts: _main._toasts.toast_info("Parking slot %d is free!" % (slot_idx + 1))
	else:
		if _main._toasts: _main._toasts.toast_info("You are in the parking lot area.")

# ── Food stall interaction ──────────────────────────────────────
func _on_stall_interact_requested(stall_id: String) -> void:
	if _main._floor_builder == null:
		return
	for stall in _main._floor_builder.get_food_stalls():
		if stall.get_stall_id() == stall_id:
			_open_stall_browse(stall)
			break

func _open_stall_browse(stall) -> void:
	if _main._food_stall_browse != null and _main._food_stall_browse.visible:
		return
	var stall_def = stall.get_stall_def()
	var cart = _main._player.get_cart()
	_main._food_stall_browse.open(stall_def, cart)

func _handle_warehouse_interact() -> void:
	if _main._warehouse_mode:
		_main._warehouse_mode = false
		if _main._warehouse_floor:
			_main._warehouse_floor.set_staff_mode(false)
		if _main._toasts: 
			_main._toasts.toast_info("Exited warehouse control.")
	else:
		if _main._player != null and _main._player.is_in_staff_mode():
			_main._warehouse_mode = true
			if _main._warehouse_floor:
				_main._warehouse_floor.set_staff_mode(true)
			if _main._toasts:
				_main._toasts.toast_success("Warehouse Control Mode — use WASD/Q/E/F to operate equipment!")
		else:
			if _main._toasts:
				_main._toasts.toast_warning("Staff mode required for warehouse control. Press [K] to enter staff mode.")

# ── Numbered bubble interaction (0-9 keys) ─────────────────────────────────
func _handle_numbered_interaction(num: int) -> void:
	if _main._proximity_system == null:
		return
	
	var interactions = _main._proximity_system.get_all_nearby_interactions()
	
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
	var bubble = _main.get_node_or_null("_interaction_bubble")
	if bubble != null and bubble.has_method("highlight_bubble"):
		bubble.highlight_bubble(num)
	
	# Trigger the interaction based on type
	var int_type = target_interaction.get("type", "")
	
	match int_type:
		"elevator":
			if _main._elevator != null:
				_main._elevator.open_panel(_main._player.position, _main._player)
		"stairs":
			_handle_stairs_interaction()
		"checkout":
			var target = target_interaction.get("target")
			if target != null:
				_main._checkout_system.do_checkout(target)
		"section":
			var target = target_interaction.get("target")
			if target != null:
				_open_section_browse(target)
		"stall":
			var target = target_interaction.get("target")
			if target != null:
				var stall_id = target.get_stall_id() if target.has_method("get_stall_id") else ""
				_on_stall_interact_requested(stall_id)
		"npc":
			_open_npc_chat()
		"claw":
			var target = target_interaction.get("target")
			if target != null:
				_start_claw_machine(target)
		"facility":
			_handle_facility_interact()
		"atm":
			_open_atm_panel()
		"warehouse":
			_handle_warehouse_interact()
		_:
			if _main._toasts:
				_main._toasts.toast_info("Interaction [%d] not yet implemented" % num)

func _handle_stairs_interaction() -> void:
	var _stairs_sys = _main.get("_stairs_system")
	if _stairs_sys != null and _stairs_sys.has_method("check_stairs_proximity") and _main._player != null:
		var proximity_result: Dictionary = _stairs_sys.check_stairs_proximity(_main._player.position, _main._current_floor_idx)
		if proximity_result.get("in_zone", false):
			var can_go_up: bool = proximity_result.get("can_go_up", false)
			var can_go_down: bool = proximity_result.get("can_go_down", false)
			# Try to go up if possible, otherwise down
			if can_go_up and not _stairs_sys.is_transitioning():
				_stairs_sys.start_stairs_transition(1)
			elif can_go_down and not _stairs_sys.is_transitioning():
				_stairs_sys.start_stairs_transition(-1)

func _start_claw_machine(machine) -> void:
	if machine != null and machine.has_method("start_game"):
		machine.start_game()

# ── NPC Chat interaction ─────────────────────────────────────────────
func _open_npc_chat() -> void:
	var npc = _main._proximity_system.get_nearby_npc_for_chat()
	if npc == null:
		return
	if _main._chat_panel == null:
		_main._chat_panel = ChatPanelScript.new()
		_main.add_child(_main._chat_panel)
		_main._chat_panel.closed.connect(_on_chat_panel_closed)
		PanelManager.register("chat", _main._chat_panel, PanelManager.Policy.ALONE)
	if _main._chat_panel._is_open:
		_main._chat_panel.close()
		return
	# Close all other ALONE panels before opening chat
	PanelManager.close_all_alone_panels()
	var actor = npc.get_actor()
	if actor == null:
		return
	# Use the NPC's existing chat brain (created in NPCController.configure).
	# Only create a fresh one as a fallback if the NPC somehow lacks one.
	var brain: AIChatBrain = null
	if npc.has_method("get_chat_brain"):
		brain = npc.get_chat_brain()
	if brain == null:
		brain = AIChatBrain.new()
		brain.configure(actor)
	_main._chat_panel.open(npc, actor, brain)

func _on_chat_panel_closed() -> void:
	# Chat panel closed, do any cleanup if needed
	pass

# Called by NPCController when a shoplifting alarm fires. Defined as a
# stub because AntiTheft already routes the catch-theft reward through
# the F key path; this is here only so the cross-object call doesn't
# raise "Nonexistent function" at runtime.
func on_npc_theft(_npc) -> void:
	pass

# ── Claw machine interaction ──────────────────────────────────────
func _on_claw_interact_requested() -> void:
	if _main._nearby_claw_machine != null:
		_main._nearby_claw_machine.start_game()

func _on_claw_played(prize_name: String, won: bool, _machine) -> void:
	if won and _main._player_stats != null:
		_main._player_stats.add_xp(15, "Claw machine win: %s" % prize_name)
		_main._player_stats.on_claw_win()
		if _main._toasts != null:
			_main._toasts.toast_success("You won a %s! +15 XP" % prize_name)
	else:
		if _main._toasts != null:
			_main._toasts.toast_info("No prize this time. Try again!")

# ── Checkout proximity & interaction ─────────────────────────────
func _on_checkout_interacted(_checkout_id: int, _checkout_type) -> void:
	_main._checkout_system.do_checkout(_main._nearby_checkout)

func _on_self_checkout_cleared() -> void:
	# Retry checkout after error dismissed
	_main._checkout_system.retry_checkout(_main._nearby_checkout)

# ── Section browse ──────────────────────────────────────────────
func _attempt_catch_thief() -> void:
	if _main._anti_theft == null or _main._player == null:
		return
	if _main._anti_theft.get_active_thefts() == 0:
		if _main._toasts:
			_main._toasts.toast_info("No suspicious activity detected")
		return
	# Try to catch any nearby suspicious NPC
	var reward = _main._anti_theft.catch_thief(null, true)
	if _main._toasts:
		_main._toasts.toast_success("Thief caught! +%d XP, $%.2f fine" % [reward["xp"], reward["cash"]])
	if _main._player_stats != null:
		_main._player_stats.add_xp(reward["xp"], "Caught shoplifter")
		_main._player_stats.add_cash(reward["cash"])

func _renovate_nearby_section() -> void:
	if _main._nearby_section == null or _main._store_expansion == null:
		return
	if not (_main._player != null and _main._player.is_in_staff_mode()):
		return
	var sec_id = _main._nearby_section.get_def().id
	if _main._store_expansion.is_section_renovated(sec_id):
		if _main._toasts:
			_main._toasts.toast_info("Section already renovated!")
		return
	var cost = _main._store_expansion.get_renovation_cost(sec_id)
	if _main._player_stats == null or _main._player_stats.get_cash() < cost:
		if _main._toasts:
			_main._toasts.toast_error("Need $%d to renovate!" % cost)
		return
	_main._player_stats.add_cash(-cost)
	_main._store_expansion.renovate_section(sec_id)
	if _main._toasts:
		_main._toasts.toast_success("Section renovated! +1 Rep")

func _restock_nearby_section() -> void:
	if _main._nearby_section == null or _main._warehouse == null:
		return
	var sec_def = _main._nearby_section.get_def()
	var sec_id = sec_def.id
	var current: int = _main._warehouse.get_stock(sec_id)
	var capacity: int = _main._warehouse.get_capacity(sec_id)
	if current >= capacity:
		if _main._toasts: _main._toasts.toast_info("%s is already fully stocked!" % sec_def.name.to_upper())
		return
	var top_up: int = int(capacity * 0.8) - current
	if top_up <= 0:
		top_up = capacity - current
	if top_up > 0:
		var contents := {sec_id: top_up}
		_main._warehouse.receive_delivery(contents)
		if _main._player_stats:
			_main._player_stats.complete_staff_task()
			_main._player_stats.add_staff_xp(8, "Restocked %s" % sec_def.name)
		if _main._toasts:
			_main._toasts.toast_success("Restocked %s with %d units! +8 Staff XP" % [sec_def.name, top_up])

func _open_section_browse(section) -> void:
	if _main._section_browse == null:
		return
	_main._section_browse.open_section(section)
	_main._current_section_browse = _main._section_browse

# ── Price terminal proximity (Phase 6) ───────────────────────────
func _open_price_terminal() -> void:
	if _main._price_terminal == null:
		_main._price_terminal = PriceTerminalScript.new()
		_main.add_child(_main._price_terminal)
	_main._price_terminal.open()

func _toggle_brand_portal() -> void:
	if _main._brand_portal == null:
		return
	if _main._brand_portal.visible:
		_main._brand_portal.close()
	else:
		_main._brand_portal.open("ferrero")

func _toggle_business_mode() -> void:
	if _main._player_stats == null:
		return
	if not _main._player_stats.can_open_business_mode():
		var next_xp: int = _main._player_stats.get_staff_xp_for_next_rank()
		if _main._toasts:
			if next_xp > 0:
				_main._toasts.toast_warning("Business Mode unlocks at Supervisor rank. %d more Staff XP needed!" % next_xp)
			else:
				_main._toasts.toast_warning("Business Mode unlocks at Supervisor rank. Keep earning Staff XP!")
		return
	if _main._business_mode == null:
		_build_business_mode()
	if _main._business_mode.visible:
		_main._business_mode.close()
	else:
		_main._business_mode.open(self, _main._player_stats)

func _build_business_mode() -> void:
	_main._business_mode = BusinessModeScript.new()
	_main._business_mode.visible = false
	_main.add_child(_main._business_mode)

func close_business_mode() -> void:
	if _main._business_mode:
		_main._business_mode.close()

func _toggle_robot_panel() -> void:
	if _main._robot_panel == null:
		_main._robot_panel_system.build_robot_panel()
		_main._robot_panel = _main._robot_panel_system.get_robot_panel()
		PanelManager.register("robot", _main._robot_panel_system, PanelManager.Policy.ALONE)
	if _main._robot_panel != null and _main._robot_panel.visible:
		_main._robot_panel_system.hide_panel()
	else:
		if _main._player != null and not _main._player.is_in_staff_mode():
			if _main._toasts: _main._toasts.toast_warning("Staff mode required for robot management. Press [K].")
			return
		if _main._robot_panel != null:
			_main._robot_panel_system.show_panel()
		_main._robot_panel_system._update_robot_panel()

func _spawn_robot_humanoid(staff_role: ActorData.StaffRole) -> void:
	_main._main_spawner.spawn_robot_humanoid(staff_role)
	return
func _spawn_robot_single(rrole: ActorData.RobotRole) -> void:
	_main._main_spawner.spawn_robot_single(rrole)
	return
func _spawn_robots() -> void:
	_main._main_spawner.spawn_robots()
	return
func _on_brand_portal_closed() -> void:
	# Refresh any brand data that may have changed
	pass

# ── Phase 3: Cafe Counter Browse ────────────────────────────────
func _spawn_truck_at_dock() -> void:
	_main._truck_dock_system.spawn_truck()
	return

# ── Store news bulletin board ───────────────────────────────────────────────
func _toggle_stats_dashboard() -> void:
	if _main._stats_dashboard == null: return
	_main._stats_dashboard.toggle()
	if _main._stats_dashboard.visible:
		_main._stats_dashboard.refresh_from_stats(_main._player_stats)

# ── Map Panel (M key) ──────────────────────────────────────────────
func _toggle_map_panel() -> void:
	if _main._map_panel == null:
		_main._map_panel = MapPanelScript.new()
		_main.add_child(_main._map_panel)
		_main._map_panel.set_player(_main._player)
		_main._map_panel.set_main(self)
		_main._map_panel.set_floor(_main._current_floor_idx)
		PanelManager.register("map", _main._map_panel, PanelManager.Policy.ALONE)
	_main._map_panel.toggle()

# ── Floor Panel (V key - Clickable floor selector) ───────────────────────────────────
func _toggle_floor_panel() -> void:
	if _main._floor_panel == null:
		_main._floor_panel = FloorPanelScript.new()
		_main.add_child(_main._floor_panel)
		_main._floor_panel.set_owner_node(self)
		_main._floor_panel.set_floor(_main._current_floor_idx)
		PanelManager.register("floor", _main._floor_panel, PanelManager.Policy.ALONE)
	PanelManager.toggle("floor")
	if _main._floor_panel.visible:
		_main._floor_panel.set_floor(_main._current_floor_idx)

# ── Floor Jump Panel (T key - Teleport) ──────────────────────────────────────────────
func _toggle_floor_jump_panel() -> void:
	if _main._floor_jump_panel != null and _main._floor_jump_panel.visible:
		_close_floor_jump_panel()
		return
	
	# Create the panel
	_main._floor_jump_panel = Control.new()
	_main._floor_jump_panel.set_anchors_preset(Control.PRESET_CENTER)
	_main._floor_jump_panel.position = Vector2(-150.0, -180.0)
	_main._floor_jump_panel.set_deferred("size", Vector2(300.0, 360.0))
	_main._floor_jump_panel.gui_input.connect(_on_floor_jump_panel_input)
	_main.add_child(_main._floor_jump_panel)
	
	# Dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.08, 0.95)
	_main._floor_jump_panel.add_child(bg)
	
	# Header
	var hdr := Label.new()
	hdr.text = "=== FLOOR JUMP ==="
	hdr.position = Vector2(70.0, 10.0)
	hdr.add_theme_color_override("font_color", Color(0.88, 0.82, 0.60))
	hdr.add_theme_font_size_override("font_size", 12)
	_main._floor_jump_panel.add_child(hdr)
	
	# Floor buttons - 5 columns x 3 rows for 15 floors (0-14)
	var floor_count := FloorConfigScript.floor_count()
	var cols := 5
	var btn_w := 50.0
	var btn_h := 30.0
	var start_x := 15.0
	var start_y := 40.0
	var gap_x := 5.0
	var gap_y := 5.0
	
	for i in range(floor_count):
		var col := i % cols
		var row := i / float(cols)
		var bx := start_x + col * (btn_w + gap_x)
		var by := start_y + row * (btn_h + gap_y)
		
		var floor_label := "G" if i == 0 else str(i)
		
		var btn := ColorRect.new()
		btn.position = Vector2(bx, by)
		btn.set_deferred("size", Vector2(btn_w, btn_h))
		var is_current: bool = (i == _main._current_floor_idx)
		btn.color = Color(0.18, 0.40, 0.25) if is_current else Color(0.22, 0.20, 0.28)
		_main._floor_jump_panel.add_child(btn)
		
		var lbl := Label.new()
		lbl.text = "Floor %s" % floor_label
		lbl.position = Vector2(bx + 4, by + 8)
		var lbl_color := Color(0.50, 0.95, 0.60) if is_current else Color(0.90, 0.88, 0.80)
		lbl.add_theme_color_override("font_color", lbl_color)
		lbl.add_theme_font_size_override("font_size", 10)
		_main._floor_jump_panel.add_child(lbl)
		
		# Store floor idx for button press
		btn.set_meta("floor_idx", i)
		btn.gui_input.connect(_on_floor_jump_btn_input)

func _on_floor_jump_panel_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE or k.keycode == KEY_T:
			_close_floor_jump_panel()

func _on_floor_jump_btn_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var btn := event.get_parent() as Control
		if btn != null and btn.has_meta("floor_idx"):
			var idx: int = btn.get_meta("floor_idx")
			_close_floor_jump_panel()
			_jump_to_floor(idx)

func _close_floor_jump_panel() -> void:
	if _main._floor_jump_panel != null:
		_main._floor_jump_panel.queue_free()
		_main._floor_jump_panel = null
		
# 每日签到奖励信号处理函数
func _on_streak_reward(days: int, bonus_xp: int) -> void:
	# 弹出奖励提示
	var toasts = _main.get("_toasts")
	if toasts != null:
		toasts.show_toast("🎉 每日奖励！连续签到 %d 天 +%d XP" % [days, bonus_xp], Color(0.92, 0.75, 0.25))
	
	# 🔥 修复：调用我们新增的奖励音效
	var audio = _main.get("_audio")
	if audio != null:
		audio.play_bonus()

# 商品添加到购物车（商品浏览面板信号）
func _on_item_added_to_cart(item_data: Dictionary, _count: int = 1) -> void:
	# 弹出添加成功提示
	var toasts = _main.get("_toasts")
	if toasts != null:
		toasts.show_toast("✅ 已加入购物车: " + item_data.name, Color(0.2, 0.8, 0.3))
	
	# 播放添加物品音效
	var audio = _main.get("_audio")
	if audio != null:
		audio.play_item_add()

# 商品浏览面板关闭信号
func _on_browse_closed() -> void:
	# 面板关闭时可执行逻辑（无逻辑留空即可）
	pass

# ── Shelf Panel (H key - warehouse storage view) ────────────────────
func _toggle_shelf_panel() -> void:
	if _main._shelf_panel == null:
		return
	_main._shelf_panel.toggle()
