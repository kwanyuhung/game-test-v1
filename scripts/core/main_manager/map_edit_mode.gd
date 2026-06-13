# map_edit_mode.gd
# Controller for the dev-only Map Edit Mode. Toggled by U key (DEV_MODE only).
# On entry: clears all non-map objects from the current floor and opens MapEditPanel.
# On Save: persists the override file and rebuilds the floor with the new layout.
# On Cancel / toggle off: rebuilds the floor with default items.
class_name MapEditMode
extends Node

const FloorConfigScript = preload("res://scripts/world/floor_config.gd")
const FloorOverrideScript = preload("res://scripts/core/main_manager/floor_override.gd")
const MapEditPanelScript = preload("res://scripts/ui/map_edit_panel.gd")

var _main: Node2D = null
var _world_manager = null
var _game_state: GameState = null
var _panel: MapEditPanel = null
var _visualizer: Node = null
var _is_open := false
const CAMERA_PAN_SPEED := 600.0  # pixels/sec

func setup(main: Node2D, world_manager, game_state) -> void:
	_main = main
	_world_manager = world_manager
	_game_state = game_state
	_panel = MapEditPanelScript.new()
	_panel.layer = 2400
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_main.add_child(_panel)
	_panel.saved.connect(_on_panel_saved)
	_panel.cancelled.connect(_on_panel_cancelled)
	_panel.reset_requested.connect(_on_panel_reset)
	_visualizer = preload("res://scripts/core/main_manager/map_edit_visualizer.gd").new()
	_main.add_child(_visualizer)
	_visualizer.setup(_main)

func is_open() -> bool:
	return _is_open

func toggle() -> void:
	if _is_open:
		exit_edit_mode()
	else:
		enter_edit_mode()

func enter_edit_mode() -> void:
	if _is_open:
		return
	if _world_manager == null or _game_state == null or _panel == null:
		push_warning("[MapEditMode] Not initialized")
		return
	_is_open = true
	# Wipe non-map objects from the current floor for a clean editing canvas.
	_clear_current_floor_items()
	var fd = FloorConfigScript.get_floor(_game_state.current_floor_idx)
	if fd == null:
		_is_open = false
		return
	# Apply any existing override so the panel shows the persisted values.
	FloorOverrideScript.apply_to_floor_def(fd)
	_panel.open_for_floor(fd.index, fd.width_tiles, fd.height_tiles, fd.ambient_color)
	if _visualizer != null:
		_visualizer.show_for_floor(_game_state.current_floor_idx, fd.width_tiles, fd.height_tiles)

func exit_edit_mode() -> void:
	if not _is_open:
		return
	_is_open = false
	if _panel != null and _panel.is_open():
		_panel.close()
	if _visualizer != null:
		_visualizer.hide_border()
	_rebuild_current_floor()

func _on_panel_saved(width_tiles: int, height_tiles: int, ambient_color: Color) -> void:
	if _game_state == null:
		return
	var floor_idx := _game_state.current_floor_idx
	var data := FloorOverrideScript.load_override()
	var floors: Array = data.get("floors", [])
	# Drop any existing entry for this floor so we don't accumulate duplicates.
	var pruned: Array = []
	for entry in floors:
		if typeof(entry) == TYPE_DICTIONARY and int(entry.get("index", -1)) == floor_idx:
			continue
		pruned.append(entry)
	pruned.append({
		"index": floor_idx,
		"width": width_tiles,
		"height": height_tiles,
		"ambient_color": [ambient_color.r, ambient_color.g, ambient_color.b],
	})
	var new_data := {"floors": pruned}
	if not FloorOverrideScript.save_override(new_data):
		push_warning("[MapEditMode] Failed to write override file")
	_is_open = false
	if _visualizer != null:
		_visualizer.hide_border()
	_rebuild_current_floor()

func _on_panel_cancelled() -> void:
	# No override change. Just close the panel and rebuild the floor with default items.
	_is_open = false
	if _visualizer != null:
		_visualizer.hide_border()
	_rebuild_current_floor()

func _on_panel_reset() -> void:
	# Drop this floor's override entry, then rebuild with default size/color.
	if _game_state != null:
		FloorOverrideScript.remove_override_for_floor(_game_state.current_floor_idx)
		FloorConfigScript.reload_floors()
	_is_open = false
	if _visualizer != null:
		_visualizer.hide_border()
	_rebuild_current_floor()

func _clear_current_floor_items() -> void:
	if _main == null or _game_state == null:
		return
	var floor_idx := _game_state.current_floor_idx
	var floor_manager = _main.get_node_or_null("FloorManager")
	if floor_manager != null and floor_manager.has_method("get_floor_container"):
		var container = floor_manager.call("get_floor_container", floor_idx)
		if container != null and container.has_method("clear_content"):
			container.call("clear_content")
			return
	# Fallback: WorldManager path (no FloorManager).
	if _world_manager != null:
		_world_manager.call("_clear_floor_nodes")

func _rebuild_current_floor() -> void:
	if _world_manager == null or _game_state == null:
		return
	var floor_idx := _game_state.current_floor_idx
	if _world_manager.has_method("force_rebuild_floor"):
		_world_manager.force_rebuild_floor(floor_idx)
	else:
		_world_manager.rebuild_floor(floor_idx)

func _process(delta: float) -> void:
	if not _is_open:
		return
	if _main == null or _game_state == null:
		return
	var logic = _main.get("_logic")
	if logic == null:
		return
	var cam = logic.get("_camera")
	if cam == null:
		return
	# Pan the camera with WASD independent of player movement. This lets the
	# editor move the view around without dragging the player along.
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir.length() > 0.0:
		cam.position += dir.normalized() * CAMERA_PAN_SPEED * delta
		_clamp_camera_to_floor(cam)

func _clamp_camera_to_floor(cam: Camera2D) -> void:
	var fd = FloorConfigScript.get_floor(_game_state.current_floor_idx)
	if fd == null:
		return
	var floor_w: float = fd.width_tiles * FloorConfigScript.CELL_SIZE
	var floor_h: float = fd.height_tiles * FloorConfigScript.CELL_SIZE
	var half_w: float = 0.0
	var half_h: float = 0.0
	var vp := get_viewport().get_visible_rect().size
	if cam.zoom.x > 0.0:
		half_w = (vp.x * 0.5) / cam.zoom.x
		half_h = (vp.y * 0.5) / cam.zoom.y
	cam.position.x = clampf(cam.position.x, half_w, floor_w - half_w)
	cam.position.y = clampf(cam.position.y, half_h, floor_h - half_h)
