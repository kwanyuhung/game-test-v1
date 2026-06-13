# auto_door.gd
# ─────────────────────────────────────────────────────────────────────────────
# Visual-only sliding automatic door. No collision — the player walks through
# freely. The door panel is a single rectangle that slides left-right when
# the trigger zone detects the player (or F6 forces a toggle).
#
# Visual: a colored rectangle covers the doorway when closed; when open, it
# slides to one side (positive X) into a "pocket", revealing the passage.
# Animates via _open_progress (0.0 closed, 1.0 open).
#
# Why no blocker: the user wants free movement through the doorway. The door
# is purely cosmetic + state indicator. Other systems can still gate by
# manual override (force_open / force_close).
#
# Usage:
#   var door := AutoDoor.new()
#   door.configure(2, 1, Color(0.55, 0.65, 0.78))  # 2 tiles wide, 1 tile tall
#   door.position = Vector2(door_x, door_y)
#   parent.add_child(door)
# ─────────────────────────────────────────────────────────────────────────────
class_name AutoDoor
extends Area2D

const CELL_SIZE := 16

# Tunables
const OPEN_SPEED := 8.0           # lerp speed for opening/closing
const TRIGGER_DEPTH := 32.0       # how far the trigger extends on each side of the door
const TRIGGER_SIDE_PAD := 16.0    # side padding on the trigger zone

# Toggle key for manual open/close (used by _unhandled_key_input)
const TOGGLE_KEY := KEY_F6

# Door state
var _width: float = 32.0
var _height: float = 16.0
var _panel_color: Color = Color(0.55, 0.65, 0.78)
var _is_open: bool = false
var _open_progress: float = 0.0  # 0.0 = fully closed, 1.0 = fully open

# Manual override (set by force_open / force_close / F6). When true, the
# proximity trigger is ignored and the door stays in the forced state.
var _manual_override: bool = false
var _manual_target_open: bool = false

# Visuals
var _frame_top: ColorRect = null
var _frame_bottom: ColorRect = null
var _frame_left: ColorRect = null
var _frame_right: ColorRect = null
var _panel: ColorRect = null           # single sliding rectangle
var _pocket_indicator: ColorRect = null # dark recess on the right side
var _status_indicator: ColorRect = null
var _status_label: Label = null

# Physics
var _trigger_shape: CollisionShape2D = null

# Debug overlay (toggle via set_debug_visible)
var _debug_visible: bool = false
var _debug_trigger_box: ColorRect = null
var _debug_label: Label = null

func configure(width_tiles: float = 2.0, height_tiles: float = 1.0, panel_color: Color = Color(0.55, 0.65, 0.78)) -> void:
	_width = width_tiles * CELL_SIZE
	_height = height_tiles * CELL_SIZE
	_panel_color = panel_color

func _ready() -> void:
	# Trigger — Area2D detection zone centered on the door, extending
	# TRIGGER_DEPTH on BOTH Y sides. Player entering from either the lobby
	# (above) or the storage area (below) opens the door.
	_trigger_shape = CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(_width + TRIGGER_SIDE_PAD * 2.0, _height + TRIGGER_DEPTH * 2.0)
	_trigger_shape.shape = trigger_rect
	# Center the trigger on the door's vertical span (door body sits at
	# y=-_height..0, center is at -_height/2). This way the trigger
	# reaches TRIGGER_DEPTH on each side of the boundary.
	_trigger_shape.position = Vector2(0.0, -_height / 2.0)
	add_child(_trigger_shape)

	_build_visuals()
	_build_debug_overlay()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _build_visuals() -> void:
	var frame_thickness := 2.0
	var frame_color := Color(0.30, 0.32, 0.36)

	# Frame: 4 thin rects around the door opening
	_frame_top = ColorRect.new()
	_frame_top.size = Vector2(_width, frame_thickness)
	_frame_top.position = Vector2(-_width / 2.0, -_height - frame_thickness)
	_frame_top.color = frame_color
	_frame_top.z_index = 11
	add_child(_frame_top)

	_frame_bottom = ColorRect.new()
	_frame_bottom.size = Vector2(_width, frame_thickness)
	_frame_bottom.position = Vector2(-_width / 2.0, 0.0)
	_frame_bottom.color = frame_color
	_frame_bottom.z_index = 11
	add_child(_frame_bottom)

	_frame_left = ColorRect.new()
	_frame_left.size = Vector2(frame_thickness, _height)
	_frame_left.position = Vector2(-_width / 2.0 - frame_thickness, -_height)
	_frame_left.color = frame_color
	_frame_left.z_index = 11
	add_child(_frame_left)

	_frame_right = ColorRect.new()
	_frame_right.size = Vector2(frame_thickness, _height)
	_frame_right.position = Vector2(_width / 2.0, -_height)
	_frame_right.color = frame_color
	_frame_right.z_index = 11
	add_child(_frame_right)

	# Pocket indicator (dark recess on the right where the panel slides into)
	# Purely cosmetic — gives the slide motion a visible destination.
	_pocket_indicator = ColorRect.new()
	_pocket_indicator.size = Vector2(_width, _height - frame_thickness * 2.0)
	_pocket_indicator.position = Vector2(_width / 2.0, -_height + frame_thickness)
	_pocket_indicator.color = Color(0.10, 0.12, 0.16)
	_pocket_indicator.z_index = 9
	add_child(_pocket_indicator)

	# Sliding panel — single rectangle, starts at the doorway (center).
	# When open, it slides right into the pocket (x: 0 → +_width).
	_panel = ColorRect.new()
	_panel.size = Vector2(_width - frame_thickness * 2.0, _height - frame_thickness * 2.0)
	_panel.position = Vector2(-_width / 2.0 + frame_thickness, -_height + frame_thickness)
	_panel.color = _panel_color
	_panel.z_index = 10
	add_child(_panel)

	# Status indicator (small LED-like dot above the door)
	_status_indicator = ColorRect.new()
	_status_indicator.size = Vector2(4.0, 4.0)
	_status_indicator.position = Vector2(-2.0, -_height - 8.0)
	_status_indicator.color = Color(0.85, 0.20, 0.20)  # red = closed
	_status_indicator.z_index = 12
	add_child(_status_indicator)

	_status_label = Label.new()
	_status_label.text = "AUTO DOOR"
	_status_label.position = Vector2(-22.0, -_height - 20.0)
	_status_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_status_label.add_theme_font_size_override("font_size", 6)
	_status_label.z_index = 12
	add_child(_status_label)

	_update_panel_position()

func _build_debug_overlay() -> void:
	# Trigger zone outline (semi-transparent green) — shows where the door opens
	var trigger_w: float = _width + TRIGGER_SIDE_PAD * 2.0
	var trigger_h: float = _height + TRIGGER_DEPTH * 2.0
	_debug_trigger_box = ColorRect.new()
	_debug_trigger_box.size = Vector2(trigger_w, trigger_h)
	_debug_trigger_box.position = Vector2(-trigger_w / 2.0, -_height / 2.0 - trigger_h / 2.0)
	_debug_trigger_box.color = Color(0.20, 0.95, 0.30, 0.25)
	_debug_trigger_box.z_index = 20
	_debug_trigger_box.visible = _debug_visible
	_debug_trigger_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_debug_trigger_box)

	# Status / help label
	_debug_label = Label.new()
	_debug_label.text = "[AutoDoor] F6 to toggle  |  visual-only (no blocker)"
	_debug_label.position = Vector2(-110.0, -_height / 2.0 - trigger_h / 2.0 - 14.0)
	_debug_label.add_theme_color_override("font_color", Color(0.30, 1.0, 0.40))
	_debug_label.add_theme_font_size_override("font_size", 6)
	_debug_label.z_index = 21
	_debug_label.visible = _debug_visible
	add_child(_debug_label)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == TOGGLE_KEY:
			toggle_manual()
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Animate the panel toward the target open/close state
	var target: float = 1.0 if _is_open else 0.0
	_open_progress = move_toward(_open_progress, target, OPEN_SPEED * delta)
	_update_panel_position()
	_update_status_visual()

func _update_panel_position() -> void:
	if _panel == null:
		return
	var frame_thickness := 2.0
	# Panel slides from the doorway (x=-_width/2) to the pocket (x=+_width/2)
	# as _open_progress goes 0 → 1. When fully open, the panel is hidden in
	# the pocket on the right.
	var start_x: float = -_width / 2.0 + frame_thickness
	var end_x: float = _width / 2.0 + frame_thickness
	_panel.position.x = lerp(start_x, end_x, _open_progress)
	_panel.position.y = -_height + frame_thickness

func _update_status_visual() -> void:
	if _status_indicator == null:
		return
	if _is_open:
		_status_indicator.color = Color(0.20, 0.85, 0.30)  # green = open
	else:
		_status_indicator.color = Color(0.85, 0.20, 0.20)  # red = closed

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if not _manual_override:
			_is_open = true
		if _debug_label != null:
			_debug_label.text = "[AutoDoor: OPEN — player in trigger]"

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if not _manual_override:
			_is_open = false
		if _debug_label != null:
			_debug_label.text = "[AutoDoor: CLOSED — player left]"

# ─── Public API ─────────────────────────────────────────────────────────

func is_open() -> bool:
	return _is_open

func get_open_progress() -> float:
	return _open_progress

func is_manual_override() -> bool:
	return _manual_override

# Force the door open. Bypasses the proximity trigger until force_close()
# is called. Useful for testing and for scripted events.
func force_open() -> void:
	_manual_override = true
	_manual_target_open = true
	_is_open = true
	if _debug_label != null:
		_debug_label.text = "[AutoDoor: FORCED OPEN]"

# Force the door closed. Bypasses the proximity trigger until force_open()
# is called.
func force_close() -> void:
	_manual_override = true
	_manual_target_open = false
	_is_open = false
	if _debug_label != null:
		_debug_label.text = "[AutoDoor: FORCED CLOSED]"

# Resume automatic (proximity-based) behavior. The door will respond to
# the next player entry/exit event.
func release_override() -> void:
	_manual_override = false
	if _debug_label != null:
		_debug_label.text = "[AutoDoor: AUTO mode]"

# Toggle the manual override. If override was on, switches to the opposite
# forced state. If override was off, turns it on in the current logical
# state.
func toggle_manual() -> void:
	if _manual_override:
		_manual_target_open = not _manual_target_open
		if _manual_target_open:
			force_open()
		else:
			force_close()
	else:
		# Turn on override in the door's logical state
		if _is_open:
			force_open()
		else:
			force_close()

func set_debug_visible(visible: bool) -> void:
	_debug_visible = visible
	if _debug_trigger_box != null:
		_debug_trigger_box.visible = visible
	if _debug_label != null:
		_debug_label.visible = visible
