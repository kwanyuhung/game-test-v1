# interaction_bubble.gd
# Visual bubble indicator showing interactive objects near the player.
# Displays floating bubbles/badges with [E] key hints.
extends Node2D

var _bubble: Control = null
var _player_ref = null
var _interaction_target: Node = null
var _interaction_label: String = ""
var _bubble_type: String = "default"  # "elevator", "section", "stall", "checkout", "npc"

const BUBBLE_OFFSET := Vector2(0, -40)
const BUBBLE_W := 60.0
const BUBBLE_H := 24.0

func _ready() -> void:
	pass

func setup(player) -> void:
	_player_ref = player
	_create_bubble()

func _create_bubble() -> void:
	# Create bubble as a CanvasLayer child of main
	var main = get_parent()
	if main == null:
		return
	
	_bubble = Control.new()
	_bubble.set_anchors_preset(Control.PRESET_CENTER)
	_bubble.name = "InteractionBubble"
	_bubble.visible = false
	_bubble.custom_minimum_size = Vector2(BUBBLE_W, BUBBLE_H)
	main.add_child(_bubble)
	
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.12, 0.92)
	bg.name = "BubbleBg"
	_bubble.add_child(bg)
	
	# Border
	var border := ColorRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.color = Color(0.88, 0.78, 0.42, 0.8)  # Golden border
	border.name = "BubbleBorder"
	_bubble.add_child(border)

func _process(_delta: float) -> void:
	if _bubble == null or _player_ref == null:
		return
	
	# Position bubble above player
	var player_pos = _player_ref.global_position
	var world_to_screen = get_viewport().get_visible_rect().size * 0.5  # Approximate center offset
	_bubble.position = player_pos + BUBBLE_OFFSET
	
	# Pulse animation
	var t = Time.get_ticks_msec() / 1000.0
	var pulse = 1.0 + sin(t * 4.0) * 0.1
	_bubble.scale = Vector2(pulse, pulse)

func show_interaction(target: Node, label: String, interaction_type: String = "default") -> void:
	if _bubble == null:
		return
	
	_interaction_target = target
	_interaction_label = label
	_bubble_type = interaction_type
	
	# Update bubble content
	_clear_bubble_content()
	_create_bubble_content()
	
	# Update border color based on type
	var border_color := Color(0.88, 0.78, 0.42, 0.8)  # Default golden
	match _bubble_type:
		"elevator":  border_color = Color(0.40, 0.80, 0.40, 0.9)  # Green
		"section":   border_color = Color(0.60, 0.60, 0.90, 0.9)  # Blue
		"stall":     border_color = Color(0.90, 0.60, 0.40, 0.9)  # Orange
		"checkout":  border_color = Color(0.40, 0.90, 0.60, 0.9)  # Light green
		"npc":       border_color = Color(0.90, 0.70, 0.90, 0.9)  # Pink
		"claw":      border_color = Color(0.90, 0.40, 0.90, 0.9)  # Purple
		"facility":  border_color = Color(0.60, 0.90, 0.90, 0.9)  # Cyan
	
	var border = _bubble.get_node_or_null("BubbleBorder")
	if border:
		border.color = border_color
	
	# Resize bubble based on label length
	var label_len = label.length()
	var new_w = maxf(BUBBLE_W, label_len * 6.0 + 20.0)
	_bubble.custom_minimum_size = Vector2(new_w, BUBBLE_H)
	
	_bubble.visible = true

func _create_bubble_content() -> void:
	if _bubble == null:
		return
	
	# [E] key indicator
	var key_bg := ColorRect.new()
	key_bg.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	key_bg.position = Vector2(4.0, 3.0)
	key_bg.set_deferred("size", Vector2(20.0, 18.0))
	key_bg.color = Color(0.20, 0.20, 0.25, 0.9)
	_bubble.add_child(key_bg)
	
	var key_lbl := Label.new()
	key_lbl.name = "KeyLabel"
	key_lbl.text = "[E]"
	key_lbl.position = Vector2(6.0, 4.0)
	key_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.50))
	key_lbl.add_theme_font_size_override("font_size", 9)
	_bubble.add_child(key_lbl)
	
	# Interaction label
	var action_lbl := Label.new()
	action_lbl.name = "ActionLabel"
	action_lbl.text = _interaction_label
	action_lbl.position = Vector2(26.0, 5.0)
	action_lbl.add_theme_color_override("font_color", Color(0.90, 0.88, 0.80))
	action_lbl.add_theme_font_size_override("font_size", 8)
	_bubble.add_child(action_lbl)

func _clear_bubble_content() -> void:
	if _bubble == null:
		return
	for child in _bubble.get_children():
		if child.name != "BubbleBg" and child.name != "BubbleBorder":
			child.queue_free()

func hide_interaction() -> void:
	if _bubble != null:
		_bubble.visible = false
	_interaction_target = null
	_interaction_label = ""

func is_showing() -> bool:
	return _bubble != null and _bubble.visible

func get_interaction_target() -> Node:
	return _interaction_target

func set_interaction_visible(visible: bool) -> void:
	if _bubble != null:
		_bubble.visible = visible
