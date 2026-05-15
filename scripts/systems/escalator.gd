# escalator.gd
# Es escalator system — automatically moves player up/down between floors.
# Uses Area2D for player detection and continuous movement while on escalator.
extends Node2D

const FloorConfig = preload("res://scripts/world/floor_config.gd")
const CELL_SIZE := 16

# Escalator properties
var _escalator_id: String = "escalator_0"
var _direction: int = 1  # 1 = up, -1 = down
var _floor_idx: int = 0  # Which floor this escalator is on
var _target_floor: int = 1  # Which floor it connects to

# Movement settings
const MOVE_SPEED := 120.0  # Pixels per second - escalator belt speed
const FLOOR_TRANSITION_THRESHOLD := 100.0  # Distance before triggering floor change

# Zone bounds
var _zone_rect: Rect2 = Rect2(0, 0, 0, 0)

# State
var _player_on_escalator: bool = false
var _is_transitioning: bool = false
var _transition_progress: float = 0.0
var _entry_pos: Vector2 = Vector2.ZERO
var _main: Node2D = null
var _player: Node = null

# Visual components
var _escalator_area: Area2D = null
var _collision_shape: CollisionShape2D = null
var _visual: Node2D = null

func _init() -> void:
	pass

# Configure escalator with zone data
func configure(zone: Dictionary, escalator_id: String, floor_idx: int) -> void:
	_escalator_id = escalator_id
	_floor_idx = floor_idx
	
	# Get direction from meta or default to up
	if zone.has("meta") and zone.meta.has("direction"):
		_direction = zone.meta.direction
	else:
		_direction = 1  # Default to going up
	
	# Calculate target floor
	_target_floor = _floor_idx + _direction
	
	# Create zone rect for detection
	_zone_rect = Rect2(
		zone.x * CELL_SIZE,
		zone.y * CELL_SIZE,
		zone.w * CELL_SIZE,
		zone.h * CELL_SIZE
	)

func _ready() -> void:
	_build_visuals()

func _build_visuals() -> void:
	# Escalator track visual
	var track := ColorRect.new()
	track.position = _zone_rect.position
	track.size = _zone_rect.size
	track.color = Color(0.35, 0.32, 0.30)
	add_child(track)
	
	# Escalator belt visual with animated steps
	_build_escalator_belt()
	
	# Side rails
	_build_side_rails()
	
	# Direction arrows
	_build_direction_arrows()
	
	# Create Area2D for player detection
	_escalator_area = Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = _zone_rect.size
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = shape
	_collision_shape.position = _zone_rect.position + _zone_rect.size * 0.5
	_escalator_area.add_child(_collision_shape)
	_escalator_area.body_entered.connect(_on_body_entered)
	_escalator_area.body_exited.connect(_on_body_exited)
	add_child(_escalator_area)

func _build_escalator_belt() -> void:
	# Create animated escalator steps/moving belt
	var belt := Node2D.new()
	belt.name = "Belt"
	
	# Step markers on the belt
	var num_steps := 8
	var step_height := _zone_rect.size.y / num_steps
	
	for i in range(num_steps):
		var step := ColorRect.new()
		step.size = Vector2(_zone_rect.size.x - 8, 3)
		step.position = Vector2(4, i * step_height)
		step.color = Color(0.55, 0.52, 0.48) if (i % 2 == 0) else Color(0.45, 0.42, 0.38)
		belt.add_child(step)
	
	add_child(belt)

func _build_side_rails() -> void:
	# Left rail
	var left_rail := ColorRect.new()
	left_rail.position = _zone_rect.position
	left_rail.size = Vector2(3, _zone_rect.size.y)
	left_rail.color = Color(0.60, 0.58, 0.55)
	add_child(left_rail)
	
	# Right rail
	var right_rail := ColorRect.new()
	right_rail.position = Vector2(_zone_rect.end.x - 3, _zone_rect.position.y)
	right_rail.size = Vector2(3, _zone_rect.size.y)
	right_rail.color = Color(0.60, 0.58, 0.55)
	add_child(right_rail)

func _build_direction_arrows() -> void:
	# Up/Down arrows indicating direction
	var arrow_y: float
	var arrow_color: Color
	
	if _direction > 0:
		# Going UP
		arrow_y = _zone_rect.position.y + 20
		arrow_color = Color(0.30, 0.85, 0.45)
	else:
		# Going DOWN
		arrow_y = _zone_rect.end.y - 30
		arrow_color = Color(0.85, 0.45, 0.30)
	
	# Arrow indicator
	var arrow := Label.new()
	arrow.text = "▲" if _direction > 0 else "▼"
	arrow.position = Vector2(_zone_rect.position.x + _zone_rect.size.x * 0.5 - 8, arrow_y)
	arrow.add_theme_color_override("font_color", arrow_color)
	arrow.add_theme_font_size_override("font_size", 16)
	add_child(arrow)
	
	# Label
	var lbl := Label.new()
	lbl.text = "ESCALATOR"
	lbl.position = Vector2(_zone_rect.position.x + 4, _zone_rect.position.y - 16)
	lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
	lbl.add_theme_font_size_override("font_size", 8)
	add_child(lbl)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player_on_escalator = true
		_player = body
		if _main != null and _main.has_method("on_escalator_entered"):
			_main.on_escalator_entered(_escalator_id, _floor_idx)

func _on_body_exited(body: Node) -> void:
	if body is Player:
		_player_on_escalator = false
		if _main != null and _main.has_method("on_escalator_exited"):
			_main.on_escalator_exited(_escalator_id, _floor_idx)

func setup(main: Node2D) -> void:
	_main = main
	_player = main.get("_player")

func _process(delta: float) -> void:
	if _is_transitioning:
		_update_transition(delta)
		return
	
	# Auto-move player when on escalator
	if _player_on_escalator and _player != null and not _is_transitioning:
		# Check if player can still use escalator
		if not _can_use_escalator():
			return
		
		# Move player in escalator direction
		var move_amount := MOVE_SPEED * delta * _direction
		_player.position.y -= move_amount  # Negative because Y increases downward
		
		# Check if player has reached transition point
		_check_transition()

func _can_use_escalator() -> bool:
	if _main == null:
		return false
	
	var current_floor: int = _main.get("_current_floor_idx")
	
	# Check if escalator connects to the current floor
	if current_floor != _floor_idx:
		return false
	
	# Check bounds
	if _direction > 0 and _floor_idx >= FloorConfig.floor_count() - 1:
		return false  # Can't go up from top floor
	if _direction < 0 and _floor_idx <= 0:
		return false  # Can't go down from ground floor
	
	return true

func _check_transition() -> void:
	if _player == null:
		return
	
	# Check if player has moved far enough on escalator to trigger floor change
	var entry_y: float = _entry_pos.y if _entry_pos != Vector2.ZERO else _player.position.y
	var current_y: float = _player.position.y
	var distance_moved := absf(current_y - entry_y)
	
	if distance_moved >= FLOOR_TRANSITION_THRESHOLD:
		_start_floor_transition()

func _start_floor_transition() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	_transition_progress = 0.0
	_entry_pos = _player.position
	
	# Show toast
	if _main != null and _main.get("_toasts") != null:
		var from_name := "Ground" if _floor_idx == 0 else ("Floor " + str(_floor_idx))
		var to_name := "Ground" if _target_floor == 0 else ("Floor " + str(_target_floor))
		var dir_str := "up" if _direction > 0 else "down"
		_main.get("_toasts").toast_info("Escalator going " + dir_str + " to " + to_name)

func _update_transition(delta: float) -> void:
	_transition_progress += delta * 2.0  # 0.5 second transition
	
	if _transition_progress >= 1.0:
		_complete_transition()
	else:
		# Smooth transition animation
		if _player != null:
			var t := ease(_transition_progress, 0.5)
			var start_y := _entry_pos.y
			var target_y: float
			if _direction > 0:
				target_y = start_y - _zone_rect.size.y * 0.5
			else:
				target_y = start_y + _zone_rect.size.y * 0.5
			_player.position.y = lerpf(start_y, target_y, t)

func _complete_transition() -> void:
	_is_transitioning = false
	_transition_progress = 0.0
	
	# Actually change the floor
	if _main != null:
		_main.set("_current_floor_idx", _target_floor)
		
		# Use FloorManager if available
		var floor_manager = _main.get("_floor_manager")
		if floor_manager != null:
			floor_manager.on_travel_completed(_target_floor)
		elif _main.has_method("_rebuild_floor"):
			_main._rebuild_floor(_target_floor)
		
		# Position player at escalator entrance on new floor
		if _player != null:
			# Adjust Y position based on direction
			var new_y: float
			if _direction > 0:
				# Arrived from below - position at top of escalator zone
				new_y = _zone_rect.position.y + 50
			else:
				# Arrived from above - position at bottom of escalator zone
				new_y = _zone_rect.end.y - 50
			
			_player.position = Vector2(_player.position.x, new_y)
		
		# Show arrival toast
		if _main.get("_toasts") != null:
			var fname := "Ground" if _target_floor == 0 else ("Floor " + str(_target_floor))
			_main.get("_toasts").toast_info("Arrived at: " + fname)

# Get escalator info for debug/proximity system
func get_escalator_info() -> Dictionary:
	return {
		"id": _escalator_id,
		"floor_idx": _floor_idx,
		"target_floor": _target_floor,
		"direction": _direction,
		"zone_rect": _zone_rect,
		"is_active": _player_on_escalator
	}

# Check if player is nearby
func is_nearby(world_pos: Vector2) -> bool:
	return _zone_rect.grow(CELL_SIZE * 2).has_point(world_pos)

# Get zone rect for debug visualization
func get_zone() -> Dictionary:
	return {
		"x": _zone_rect.position.x / CELL_SIZE,
		"y": _zone_rect.position.y / CELL_SIZE,
		"w": _zone_rect.size.x / CELL_SIZE,
		"h": _zone_rect.size.y / CELL_SIZE
	}
