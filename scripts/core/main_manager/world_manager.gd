# world_manager.gd
# Phase 7 rewrite: Uses GameState for all shared mutable state.
# This manager OWNS floor-building logic only — proximity/mode state lives in GameState.
class_name WorldManager
extends Node

# Preloads
const FloorConfigScript = preload("res://scripts/world/floor_config.gd")
const FloorBuilderScript = preload("res://scripts/world/floor_builder.gd")
const FloorManagerScript = preload("res://scripts/world/floor_manager.gd")
const FoodStallBrowseScript = preload("res://scripts/systems/food_stall_browse.gd")
const WarehouseFloorScript = preload("res://scripts/systems/warehouse_floor.gd")

const CELL_SIZE := FloorConfigScript.CELL_SIZE
const WORLD_W  := FloorConfigScript.WORLD_W
const WORLD_H  := FloorConfigScript.WORLD_H

# ── Owned state (NOT shared — this manager exclusively) ──────────────────────────
var _main: Node2D = null
var _game_state: GameState = null
var _floor_builder: FloorBuilder = null
var _food_stall_browse = null
var _sections: Array = []
var _checkout_counters: Array = []
var _floor_nodes: Array = []
var _floor_ambient: Color = Color(0.18, 0.18, 0.16)
var _aisle_labels: Array = []
var _world_bg: ColorRect = null
var _warehouse_floor: Node2D = null
# System refs (owned by SystemManager, but we hold a reference for floor ops)
var _system_manager: Node = null

# ── Signals ────────────────────────────────────────────────────────────────────
signal floor_changed(idx: int)
signal floor_rebuilt(idx: int)
signal section_entered(section_id: String)
signal section_exited(section_id: String)

# ── Setup ──────────────────────────────────────────────────────────────────────
func setup(main: Node2D, game_state: GameState) -> void:
	_main = main
	_game_state = game_state
	if _game_state == null:
		push_error("[WorldManager] GameState is null - check initialization order")
		return
	_game_state.current_floor_idx = 0
	print_debug("[WorldManager] Setup complete")

func set_system_manager(sm: Node) -> void:
	_system_manager = sm

# ── _process: noop — proximity is handled by ProximitySystem owned by SystemManager ──

# ── Floor building (OWNED by WorldManager) ────────────────────────────────────

func build_floor(idx: int) -> void:
	if _system_manager != null and has_method("_do_build_with_manager"):
		pass  # FloorManager path handled in rebuild_floor
	if _floor_builder != null:
		return  # already built

	_clear_floor_nodes()
	_game_state.current_floor_idx = idx

	var fd = FloorConfigScript.get_floor(idx)
	if fd == null:
		print_debug("[WorldManager] No floor def for floor ", idx)
		return

	# Create a dedicated container for this floor's content
	var floor_content: Node2D = Node2D.new()
	floor_content.name = "FloorContent"
	_main.add_child(floor_content)

	# Use FloorBuilder to render this floor into the container
	_floor_builder = FloorBuilderScript.new()
	var stairs_sys = _main.get_node_or_null("StairsSystem")
	_floor_builder.build(fd, floor_content, idx, stairs_sys)

	_floor_nodes = _floor_builder.get_floor_nodes()
	_sections = _floor_builder.get_sections()
	_checkout_counters = _floor_builder.get_checkout_counters()

	# Wire section signals
	for sec in _sections:
		if sec.has_signal("player_entered"):
			sec.player_entered.connect(_on_section_entered)
		if sec.has_signal("player_exited"):
			sec.player_exited.connect(_on_section_exited)
		if sec.has_signal("interact_requested"):
			sec.interact_requested.connect(_on_section_interact_requested)

	# Ambient
	_floor_ambient = fd.ambient_color
	_apply_ambient_shift()
	_update_floor_hud()

	# Food stall browse
	_food_stall_browse = FoodStallBrowseScript.new()
	_main.add_child(_food_stall_browse)

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

	# Setup escalators
	for esc in _floor_builder.get_escalators():
		if esc.has_method("setup"):
			esc.setup(_main)

	# Warehouse floor controller (Floor 11)
	_warehouse_floor = WarehouseFloorScript.new()
	_main.add_child(_warehouse_floor)
	_warehouse_floor.set_staff_mode(false)

	# Wire checkout signals
	for counter in _checkout_counters:
		if counter.has_signal("checkout_interacted"):
			counter.checkout_interacted.connect(_on_checkout_interacted)
		if counter.has_signal("express_rejected") and _system_manager != null:
			counter.express_rejected.connect(_on_checkout_interacted)  # routed via system manager
		if counter.has_signal("self_checkout_error") and _system_manager != null:
			counter.self_checkout_error.connect(_system_manager.on_self_checkout_error)
		if counter.has_signal("self_checkout_cleared"):
			counter.self_checkout_cleared.connect(_on_self_checkout_cleared)

	print_debug("[WorldManager] Built floor ", idx)

func _clear_floor_nodes() -> void:
	var floor_content: Node = _main.get_node_or_null("FloorContent")
	if floor_content != null:
		_main.remove_child(floor_content)
		floor_content.queue_free()

	for i in range(20):
		var old_container_name := "FloorObjects_%d" % i
		var old_container: Node = _main.get_node_or_null(old_container_name)
		if old_container != null:
			_main.remove_child(old_container)
			old_container.queue_free()

	_floor_nodes.clear()
	_sections.clear()
	_checkout_counters.clear()
	_aisle_labels.clear()
	_floor_builder = null

	if _warehouse_floor != null:
		_main.remove_child(_warehouse_floor)
		_warehouse_floor.queue_free()
		_warehouse_floor = null

	# Clear debug bounds tracking
	var debug_bounds = _main.get_node_or_null("DebugBounds")
	if debug_bounds != null and debug_bounds.has_method("clear_all"):
		debug_bounds.clear_all()

	print_debug("[WorldManager] Cleared floor nodes")

func rebuild_floor(idx: int) -> void:
	var floor_manager = _main.get_node_or_null("FloorManager")
	if floor_manager != null:
		_rebuild_floor_with_manager(idx)
		return

	_clear_floor_nodes()
	_world_bg = null
	_game_state.current_floor_idx = idx
	build_floor(idx)

	var main_panels = _main.get_node_or_null("MainPanels")
	if main_panels != null and main_panels.has_method("build_sections_for_current_floor"):
		main_panels.build_sections_for_current_floor()
	if main_panels != null and main_panels.has_method("build_checkout_for_current_floor"):
		main_panels.build_checkout_for_current_floor()

	var elevator = _main.get_node_or_null("Elevator")
	if elevator == null:
		if main_panels != null and main_panels.has_method("build_elevator"):
			main_panels.build_elevator()

	_apply_ambient_shift()
	_update_floor_hud()
	floor_rebuilt.emit(idx)
	print_debug("[WorldManager] Rebuilt floor ", idx)

func _rebuild_floor_with_manager(idx: int) -> void:
	var floor_manager = _main.get_node_or_null("FloorManager")
	if floor_manager == null or not floor_manager.has_method("get_floor_container"):
		return
	var container = floor_manager.get_floor_container(idx)
	if container == null:
		return

	_sections.clear()
	_checkout_counters.clear()
	_aisle_labels.clear()

	for child in container.get_children():
		if child.name.begins_with("Section_"):
			_sections.append(child)
		elif child.name.begins_with("Counter_"):
			_checkout_counters.append(child)
		elif child is Label:
			_aisle_labels.append(child)

	_apply_ambient_shift()
	_update_floor_hud()
	_game_state.current_floor_idx = idx
	floor_rebuilt.emit(idx)

func set_current_floor(idx: int) -> void:
	_game_state.current_floor_idx = idx
	floor_changed.emit(idx)

func get_floor_info() -> Dictionary:
	var fd = FloorConfigScript.get_floor(_game_state.current_floor_idx)
	var npcs: Array = []
	var player = _game_state.player
	if player != null and player.has_method("get_npcs"):
		npcs = player.get_npcs()
	return {
		"index": _game_state.current_floor_idx,
		"name": fd.label if fd else "Unknown",
		"theme": fd.theme if fd else "unknown",
		"zone_count": fd.zones.size() if fd else 0,
		"section_count": _sections.size(),
		"npc_count": npcs.size(),
		"checkout_count": _checkout_counters.size(),
	}

func set_ambient_floor(idx: int) -> void:
	_game_state.current_floor_idx = idx
	var fd = FloorConfigScript.get_floor(idx)
	_floor_ambient = fd.ambient_color
	_apply_ambient_shift()
	_update_floor_hud()
	floor_changed.emit(idx)

func _apply_ambient_shift() -> void:
	if _world_bg != null:
		_world_bg.color = _floor_ambient.darkened(0.6)

func _update_floor_hud() -> void:
	var main_panels = _main.get_node_or_null("MainPanels")
	if main_panels != null and main_panels.has_method("update_floor_hud"):
		main_panels.update_floor_hud()

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

# ── Signal handlers (read proximity from GameState) ─────────────────────────────

func _on_section_entered(section_id: String) -> void:
	for sec in _sections:
		if sec.get_def().id == section_id:
			_game_state.nearby_section = sec
			section_entered.emit(section_id)
			break

func _on_section_exited(section_id: String) -> void:
	if _game_state.nearby_section != null and _game_state.nearby_section.get_def().id == section_id:
		_game_state.nearby_section = null
		section_exited.emit(section_id)

func _on_section_interact_requested(section_id: String) -> void:
	# Mouse click on a nearby section — open the buy panel via SystemManager.
	for sec in _sections:
		if sec.get_def().id == section_id:
			var sm = _main.get("_system_manager")
			if sm != null and sm.has_method("_open_section_browse"):
				sm.call("_open_section_browse", sec)
			return

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
	var stall_def = stall.get_stall_def()
	var player = _game_state.player
	var cart = player.get_cart() if player != null else null
	_food_stall_browse.open(stall_def, cart)

func _on_claw_interact_requested() -> void:
	if _game_state.nearby_claw_machine != null:
		_game_state.nearby_claw_machine.start_game()

func _on_claw_played(prize_name: String, won: bool, _machine) -> void:
	var player_stats = _main.get_node_or_null("PlayerStats")
	var toasts = _main.get_node_or_null("ToastManager")
	if won and player_stats != null:
		player_stats.add_xp(15, "Claw machine win: %s" % prize_name)
		player_stats.on_claw_win()
		if toasts != null:
			toasts.toast_success("You won a %s! +15 XP" % prize_name)
	else:
		if toasts != null:
			toasts.toast_info("No prize this time. Try again!")

func _on_checkout_interacted(_checkout_id: int, _checkout_type) -> void:
	if _game_state.nearby_checkout != null and _system_manager != null:
		var cs = _system_manager.get_checkout_system()
		if cs != null and cs.has_method("do_checkout"):
			cs.do_checkout(_game_state.nearby_checkout)

func _on_self_checkout_cleared() -> void:
	if _game_state.nearby_checkout != null and _system_manager != null:
		var cs = _system_manager.get_checkout_system()
		if cs != null and cs.has_method("retry_checkout"):
			cs.retry_checkout(_game_state.nearby_checkout)

# ── Typed Getters ──────────────────────────────────────────────────────────────

func get_floor_idx() -> int:
	return _game_state.current_floor_idx

func get_sections() -> Array:
	return _sections

func get_checkout_counters() -> Array:
	return _checkout_counters

func get_floor_builder():
	return _floor_builder

func get_floor_nodes() -> Array:
	return _floor_nodes

func get_floor_ambient() -> Color:
	return _floor_ambient

func get_aisle_labels() -> Array:
	return _aisle_labels

func get_world_bg() -> Node:
	return _world_bg

func get_warehouse_floor() -> Node:
	return _warehouse_floor

func get_main() -> Node2D:
	return _main

func get_game_state() -> GameState:
	return _game_state
