# stairs_system.gd
# Real open-world stairs system — player can walk between floors via stairs.
# Press W/UP to go up stairs, S/DOWN to go down stairs when in stairs zone.
extends Node

const FloorConfig = preload("res://scripts/floor_config.gd")
const CELL_SIZE := 16

var _main: Node2D = null
var _player: Node = null
var _current_floor_idx: int = 0
var _stairs_zones: Array = []  # [{floor_idx, zone, direction}]
var _is_in_stairs_zone: bool = false
var _stairs_direction: int = 0  # -1 = down, +1 = up, 0 = not in zone
var _is_transitioning: bool = false
var _transition_progress: float = 0.0
var _transition_from_floor: int = 0
var _transition_to_floor: int = 0
var _stairs_entry_pos: Vector2 = Vector2.ZERO

const TRANSITION_DURATION := 1.5  # seconds to walk up/down stairs

func setup(main: Node2D) -> void:
	_main = main
	_player = main.get("_player")
	_current_floor_idx = main.get("_current_floor_idx")

# Called when floor is built to register stairs zones
func register_stairs_zone(floor_idx: int, zone: Dictionary, direction: int) -> void:
	# direction: 1 = stairs go UP to next floor, -1 = stairs go DOWN to prev floor
	_stairs_zones.append({
		"floor_idx": floor_idx,
		"zone": zone,
		"direction": direction
	})

func clear_stairs_zones() -> void:
	_stairs_zones.clear()

func _process(delta: float) -> void:
	if _is_transitioning:
		_update_transition(delta)

func _update_transition(delta: float) -> void:
	_transition_progress += delta / TRANSITION_DURATION
	
	if _transition_progress >= 1.0:
		_complete_transition()
	else:
		# Animate player walking up/down stairs
		if _player != null:
			var t := ease(_transition_progress, 0.5)  # ease in-out
			var start_y := _stairs_entry_pos.y
			var end_y: float
			if _stairs_direction > 0:
				# Going UP - player Y decreases (world goes up)
				end_y = start_y - 800  # Approximate stairs height
			else:
				# Going DOWN - player Y increases
				end_y = start_y + 800
			_player.position.y = lerpf(start_y, end_y, t)

func _complete_transition() -> void:
	_is_transitioning = false
	_transition_progress = 0.0
	
	# Actually change the floor
	_main.set("_current_floor_idx", _transition_to_floor)
	_current_floor_idx = _transition_to_floor
	
	# Rebuild the floor
	_main._rebuild_floor(_transition_to_floor)
	
	# Position player at the stairs entrance on new floor
	if _player != null:
		_player.position = _stairs_entry_pos
	
	# Show toast
	if _main.get("_toasts") != null:
		var fname := "Ground" if _transition_to_floor == 0 else ("Floor " + str(_transition_to_floor))
		_main.get("_toasts").toast_info("Arrived at: " + fname)

# Check if player is in any stairs zone
func check_stairs_proximity(player_pos: Vector2, current_floor: int) -> Dictionary:
	var result := {"in_zone": false, "direction": 0, "can_go_up": false, "can_go_down": false}
	
	for stairs in _stairs_zones:
		if stairs["floor_idx"] != current_floor:
			continue
		var zone: Dictionary = stairs["zone"]
		var zone_rect := Rect2(
			zone.x * CELL_SIZE,
			zone.y * CELL_SIZE,
			zone.w * CELL_SIZE,
			zone.h * CELL_SIZE
		)
		if zone_rect.has_point(player_pos):
			result["in_zone"] = true
			result["direction"] = stairs["direction"]
			
			# Check if can go up/down
			if current_floor < FloorConfig.floor_count() - 1:
				result["can_go_up"] = true
			if current_floor > 0:
				result["can_go_down"] = true
			break
	
	return result

# Start transitioning to a different floor via stairs
func start_stairs_transition(direction: int) -> void:
	if _is_transitioning:
		return
	if _player == null:
		return
	
	var current_floor: int = _main.get("_current_floor_idx")
	
	# Validate direction
	if direction > 0 and current_floor >= FloorConfig.floor_count() - 1:
		return
	if direction < 0 and current_floor <= 0:
		return
	
	# Store transition info
	_is_transitioning = true
	_transition_progress = 0.0
	_transition_from_floor = current_floor
	_transition_to_floor = current_floor + direction
	_stairs_direction = direction
	_stairs_entry_pos = _player.position
	
	# Show toast
	if _main.get("_toasts") != null:
		var to_name := "Ground" if _transition_to_floor == 0 else ("Floor " + str(_transition_to_floor))
		var dir_str := "up" if direction > 0 else "down"
		_main.get("_toasts").toast_info("Walking " + dir_str + " to " + to_name + "...")

# Check if currently transitioning
func is_transitioning() -> bool:
	return _is_transitioning

# Get stairs zones for current floor for rendering/debugging
func get_stairs_zones_for_floor(floor_idx: int) -> Array:
	var result := []
	for stairs in _stairs_zones:
		if stairs["floor_idx"] == floor_idx:
			result.append(stairs)
	return result
