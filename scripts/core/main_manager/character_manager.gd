# CharacterManager — Phase 7 rewrite: Uses GameState for shared player reference.
class_name CharacterManager
extends Node

# Preloads
const MainSpawnerScript = preload("res://scripts/world/main_spawner.gd")
const PlayerScript = preload("res://scripts/entities/player.gd")
const NPCControllerScript = preload("res://scripts/entities/npc_controller.gd")
const RobotControllerScript = preload("res://scripts/entities/robot_controller.gd")
const ActorDataScript = preload("res://scripts/entities/actor_data.gd")
const SectionBrowseScript = preload("res://scripts/world/section_browse.gd")

# Owned state
var _main: Node2D = null
var _game_state: GameState = null
var _main_spawner: Node = null
var _player: Player = null
var _npcs: Array = []
var _robots: Array = []
var _section_browse: SectionBrowse = null
var _current_section_browse = null

# Signal proxies (emit these so listeners don't need to reach into main.gd)
signal player_spawned(player: Player)
signal npcs_spawned(npcs: Array)
signal robots_spawned(robots: Array)

func setup(main: Node2D, game_state: GameState) -> void:
	_main = main
	_game_state = game_state
	print_debug("[CharacterManager] Setting up (getting existing systems)...")

	# Get existing MainSpawner (created by init_all)
	_main_spawner = _main.get("_main_spawner")

	# Get existing SectionBrowse (created by init_all)
	_section_browse = _main.get("_section_browse")

	# Wire SectionBrowse signals back to main (if section browse exists)
	if _section_browse != null:
		if not _section_browse.item_added.is_connected(_main._logic._on_item_added_to_cart):
			_section_browse.item_added.connect(_main._logic._on_item_added_to_cart)
		if not _section_browse.closed.is_connected(_main._logic._on_browse_closed):
			_section_browse.closed.connect(_main._logic._on_browse_closed)

	print_debug("[CharacterManager] Setup complete")

# ── Player ───────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	if _main_spawner:
		_main_spawner.spawn_player()
		# MainSpawner sets _main._player directly, sync our reference
		_player = _main.get("_player") if _main.has_method("get") else null
		if _game_state != null:
			_game_state.player = _player
		emit_signal("player_spawned", _player)

# ── NPCs ─────────────────────────────────────────────────────────────────────

func _build_npcs() -> void:
	if _main_spawner:
		_main_spawner.build_npcs()
		# Sync NPCs array from main
		var main_npcs = _main.get("_npcs") if _main.has_method("get") else null
		if main_npcs != null:
			_npcs = main_npcs as Array

func _spawn_npc_staff(role: int, floor_idx: int, pos: Vector2) -> void:
	if _main_spawner:
		_main_spawner.spawn_npc_staff(role, floor_idx, pos)

func _spawn_customer(group_type: int, floor_idx: int, pos: Vector2) -> void:
	if _main_spawner:
		_main_spawner.spawn_customer(group_type, floor_idx, pos)

func _spawn_customer_group(group_type: int, floor_idx: int, pos: Vector2) -> void:
	if _main_spawner:
		_main_spawner.spawn_customer_group(group_type, floor_idx, pos)

# ── Robots ───────────────────────────────────────────────────────────────────

func _spawn_robots() -> void:
	if _main_spawner:
		_main_spawner.spawn_robots()
		# Sync robots array from main
		var main_robots = _main.get("_robots") if _main.has_method("get") else null
		if main_robots != null:
			_robots = main_robots as Array

func _spawn_robot_humanoid(staff_role: int) -> void:
	if _main_spawner:
		_main_spawner.spawn_robot_humanoid(staff_role)

func _spawn_robot_single(robot_role: int) -> void:
	if _main_spawner:
		_main_spawner.spawn_robot_single(robot_role)

func _spawn_scan_go_companion() -> void:
	if _main_spawner:
		_main_spawner.spawn_scan_go_companion()

func _remove_scan_go_companion() -> void:
	if _main_spawner:
		_main_spawner.remove_scan_go_companion()

# ── Dev helpers ───────────────────────────────────────────────────────────────

func _spawn_test_customers(count: int) -> void:
	if _main_spawner:
		_main_spawner.spawn_test_customers(count)

func _spawn_test_staff(count: int) -> void:
	if _main_spawner:
		_main_spawner.spawn_test_staff(count)

func _kill_all_test_npcs() -> void:
	for npc in _npcs:
		if npc != null and is_instance_valid(npc):
			npc.queue_free()
	_npcs.clear()
	# Also clear in main
	var main_npcs = _main.get("_npcs") if _main.has_method("get") else null
	if main_npcs != null and main_npcs is Array:
		main_npcs.clear()

# ── Trucks ────────────────────────────────────────────────────────────────────

func _spawn_truck_at_dock() -> void:
	var truck_dock = _main.get("_truck_dock_system") if _main else null
	if truck_dock and truck_dock.has_method("spawn_truck"):
		truck_dock.spawn_truck()

# ── Section browse ────────────────────────────────────────────────────────────

func open_section_browse(section) -> void:
	if _section_browse != null:
		_section_browse.open_section(section)
		_current_section_browse = _section_browse

# ── Getters ───────────────────────────────────────────────────────────────────

func get_player() -> Player:
	return _player

func get_npcs() -> Array:
	return _npcs

func get_robots() -> Array:
	return _robots

func get_main_spawner() -> Node:
	return _main_spawner

func get_section_browse():
	return _section_browse

func get_current_section_browse():
	return _current_section_browse
