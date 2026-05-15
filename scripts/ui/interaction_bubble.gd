# interaction_bubble.gd
# Visual bubble indicators showing interactive objects near the player.
# Displays floating circular bubbles with numbered keys [0-9] for quick selection.
extends Node2D

# Configuration
const MAX_BUBBLES := 10  # 0-9 keys
const BUBBLE_SPACING := 70.0  # Horizontal spacing between bubbles
const BUBBLE_BASE_Y_OFFSET := -60.0  # Base vertical offset above player
const BUBBLE_RADIUS := 22.0  # Radius of the circular ball

# Bubble data structure
class NumberedBubble:
	var control: Control
	var number: int
	var target: Node
	var label: String
	var interaction_type: String
	var world_position: Vector2

var _bubble_container: Control = null
var _player_ref: Node = null
var _bubbles: Array[NumberedBubble] = []
var _bubble_scene: PackedScene = null

func _ready() -> void:
	_create_bubble_container()

func setup(player) -> void:
	_player_ref = player

func _create_bubble_container() -> void:
	var main = get_parent()
	if main == null:
		return
	
	_bubble_container = Control.new()
	_bubble_container.name = "NumberedBubbleContainer"
	_bubble_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.add_child(_bubble_container)

# Create a circular ball bubble with number
func _create_numbered_bubble(idx: int, label_text: String, bubble_type: String, target: Node, world_pos: Vector2) -> NumberedBubble:
	var bubble = NumberedBubble.new()
	bubble.number = idx
	bubble.target = target
	bubble.label = label_text
	bubble.interaction_type = bubble_type
	bubble.world_position = world_pos
	
	# Create bubble control
	var ctrl = Control.new()
	ctrl.name = "Bubble_%d" % idx
	ctrl.custom_minimum_size = Vector2(BUBBLE_RADIUS * 2 + 8, BUBBLE_RADIUS * 2 + 8)
	
	# Ball (circle background)
	var ball = ColorRect.new()
	ball.name = "Ball"
	ball.set_anchors_preset(Control.PRESET_CENTER)
	ball.custom_minimum_size = Vector2(BUBBLE_RADIUS * 2, BUBBLE_RADIUS * 2)
	# Make it circular by setting custom minimum size and centering
	var ball_size = Vector2(BUBBLE_RADIUS * 2, BUBBLE_RADIUS * 2)
	ball.set_deferred("size", ball_size)
	
	# Determine ball color based on type
	var ball_color := Color(0.08, 0.08, 0.12, 0.95)
	var border_color := Color(0.88, 0.78, 0.42, 0.9)  # Default golden
	match bubble_type:
		"elevator":  border_color = Color(0.40, 0.80, 0.40, 0.95)  # Green
		"section":   border_color = Color(0.60, 0.60, 0.90, 0.95)  # Blue
		"stall":     border_color = Color(0.90, 0.60, 0.40, 0.95)  # Orange
		"checkout":  border_color = Color(0.40, 0.90, 0.60, 0.95)  # Light green
		"npc":       border_color = Color(0.90, 0.70, 0.90, 0.95)  # Pink
		"claw":      border_color = Color(0.90, 0.40, 0.90, 0.95)  # Purple
		"facility":  border_color = Color(0.60, 0.90, 0.90, 0.95)  # Cyan
		"stairs":     border_color = Color(0.70, 0.70, 0.70, 0.95)  # Gray
		"atm":       border_color = Color(0.50, 0.80, 0.50, 0.95)  # Teal
		"warehouse":  border_color = Color(0.80, 0.60, 0.40, 0.95)  # Brown
	
	ball.color = ball_color
	ctrl.add_child(ball)
	
	# Border ring (outer circle)
	var border = ColorRect.new()
	border.name = "Border"
	border.set_anchors_preset(Control.PRESET_CENTER)
	border.custom_minimum_size = Vector2(BUBBLE_RADIUS * 2 + 4, BUBBLE_RADIUS * 2 + 4)
	border.set_deferred("size", Vector2(BUBBLE_RADIUS * 2 + 4, BUBBLE_RADIUS * 2 + 4))
	border.color = border_color
	ctrl.add_child(border)
	
	# Move ball behind border
	ball.z_index = -1
	
	# Number label
	var num_lbl = Label.new()
	num_lbl.name = "NumLabel"
	num_lbl.text = str(idx)
	num_lbl.set_anchors_preset(Control.PRESET_CENTER)
	num_lbl.position = Vector2(-4, -8)  # Center the single digit
	num_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	num_lbl.add_theme_font_size_override("font_size", 14)
	ctrl.add_child(num_lbl)
	
	# Label below bubble
	var action_lbl = Label.new()
	action_lbl.name = "ActionLabel"
	action_lbl.text = label_text
	action_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	action_lbl.anchor_left = 0.5
	action_lbl.anchor_right = 0.5
	action_lbl.offset_top = BUBBLE_RADIUS * 2 + 6
	action_lbl.offset_left = -30
	action_lbl.offset_right = 30
	action_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_lbl.add_theme_color_override("font_color", Color(0.90, 0.88, 0.80))
	action_lbl.add_theme_font_size_override("font_size", 9)
	ctrl.add_child(action_lbl)
	
	# Highlight effect when pressed
	var highlight = ColorRect.new()
	highlight.name = "Highlight"
	highlight.set_anchors_preset(Control.PRESET_CENTER)
	highlight.custom_minimum_size = Vector2(BUBBLE_RADIUS * 2, BUBBLE_RADIUS * 2)
	highlight.set_deferred("size", Vector2(BUBBLE_RADIUS * 2, BUBBLE_RADIUS * 2))
	highlight.color = Color(1.0, 1.0, 0.6, 0.3)
	highlight.visible = false
	ctrl.add_child(highlight)
	
	bubble.control = ctrl
	return bubble

# Show all nearby interactions as numbered bubbles
func show_interactions(interactions: Array) -> void:
	if _bubble_container == null:
		return
	
	# Clear existing bubbles
	_clear_all_bubbles()
	
	# Limit to MAX_BUBBLES
	var count = mini(interactions.size(), MAX_BUBBLES)
	
	for i in range(count):
		var data = interactions[i]
		var idx: int = data.get("index", i)
		var label_text: String = data.get("label", "Unknown")
		var bubble_type: String = data.get("type", "default")
		var target: Node = data.get("target", null)
		var world_pos: Vector2 = data.get("position", Vector2.ZERO)
		
		var bubble = _create_numbered_bubble(idx, label_text, bubble_type, target, world_pos)
		_bubbles.append(bubble)
		_bubble_container.add_child(bubble.control)
	
	_update_bubble_positions()

func _update_bubble_positions() -> void:
	if _player_ref == null or _bubble_container == null:
		return
	
	var player_pos = _player_ref.global_position
	var screen_center = get_viewport().get_visible_rect().size * 0.5
	var base_pos = player_pos + Vector2(0, BUBBLE_BASE_Y_OFFSET)
	
	# Arrange bubbles in a semicircle above the player
	var count = _bubbles.size()
	if count == 0:
		return
	
	# Calculate total width
	var total_width = (count - 1) * BUBBLE_SPACING
	var start_x = base_pos.x - total_width / 2.0
	
	for i in range(count):
		var bubble = _bubbles[i]
		if bubble.control == null:
			continue
		
		# Position bubble
		var x_offset = i * BUBBLE_SPACING
		var bubble_pos = Vector2(start_x + x_offset, base_pos.y)
		
		# Convert world position to screen offset (simplified - just use player pos as center)
		bubble.control.position = bubble_pos
		bubble.control.visible = true
		
		# Pulse animation
		var t = Time.get_ticks_msec() / 1000.0
		var pulse = 1.0 + sin(t * 3.0 + i * 0.5) * 0.08
		bubble.control.scale = Vector2(pulse, pulse)

func _clear_all_bubbles() -> void:
	for bubble in _bubbles:
		if bubble.control != null:
			bubble.control.queue_free()
	_bubbles.clear()

func _process(_delta: float) -> void:
	_update_bubble_positions()
	# Animate highlight on the first bubble (most urgent)
	_pulse_highlight()

func _pulse_highlight() -> void:
	var t = Time.get_ticks_msec() / 1000.0
	var highlight_alpha = (sin(t * 5.0) + 1.0) * 0.15  # 0 to 0.3
	for bubble in _bubbles:
		if bubble.control != null:
			var highlight = bubble.control.get_node_or_null("Highlight")
			if highlight != null:
				highlight.visible = (bubble.number == 0)  # Only first bubble pulses
				highlight.color.a = highlight_alpha

# Get target node by number
func get_target_by_number(num: int) -> Node:
	for bubble in _bubbles:
		if bubble.number == num:
			return bubble.target
	return null

# Get bubble info by number
func get_bubble_info(num: int) -> Dictionary:
	for bubble in _bubbles:
		if bubble.number == num:
			return {
				"target": bubble.target,
				"label": bubble.label,
				"type": bubble.interaction_type
			}
	return {}

# Check if there are any bubbles shown
func has_interactions() -> bool:
	return _bubbles.size() > 0

# Get number of bubbles
func get_bubble_count() -> int:
	return _bubbles.size()

# Highlight a specific bubble when its key is pressed
func highlight_bubble(num: int) -> void:
	for bubble in _bubbles:
		if bubble.control != null and bubble.number == num:
			var highlight = bubble.control.get_node_or_null("Highlight")
			if highlight != null:
				highlight.visible = true
				highlight.color = Color(1.0, 0.9, 0.5, 0.5)
				# Create tween to fade out
				var tween = create_tween()
				tween.tween_property(highlight, "color:a", 0.0, 0.3)
				tween.tween_callback(func(): highlight.visible = false)

func hide_all() -> void:
	_clear_all_bubbles()

func is_showing() -> bool:
	return has_interactions()
