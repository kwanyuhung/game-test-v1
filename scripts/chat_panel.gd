# chat_panel.gd
# In-game chat UI — player presses C near an NPC to open chat.
# Shows conversation history + text input field.
# ═══════════════════════════════════════════════════════════════════════
# CONTROLS:
#   C or E (near NPC)  → Open chat
#   Type message + Enter → Send
#   ESC                 → Close chat
# ═══════════════════════════════════════════════════════════════════════
class_name ChatPanel
extends CanvasLayer

signal closed()
signal input_blocked(bool)  # Emitted when panel opens/closes to block player input

const ActorData = preload("res://scripts/actor_data.gd")
const ChatBubble = preload("res://scripts/chat_bubble.gd")

const LINE_H := 24.0
const MAX_LINES := 8
const PANEL_MARGIN := 60.0

var _target_npc: Node = null
var _target_actor: ActorData.Actor = null
var _target_brain: AIChatBrain = null
var _chat_history: Array = []   # [{role: "player"|"npc", text: String}, ...]
var _input_field: LineEdit
var _history_labels: Array = []
var _panel_bg: ColorRect
var _name_label: Label
var _history_bg: ColorRect
var _npc_bubble: ChatBubble = null
var _is_open: bool = false
var _overlay: ColorRect = null
var _panel_w: float = 0.0
var _panel_h: float = 0.0
var _pan_x: float = 0.0
var _pan_y: float = 0.0

func _ready() -> void:
	visible = false

func open(npc: Node, actor: ActorData.Actor, brain: AIChatBrain) -> void:
	_target_npc = npc
	_target_actor = actor
	_target_brain = brain
	_chat_history.clear()
	_is_open = true
	_build_ui()
	visible = true
	input_blocked.emit(true)

	# NPC greeting
	var greeting := _target_brain.generate_response("hello")
	_add_npc_message(greeting)

func close() -> void:
	_is_open = false
	visible = false
	_target_npc = null
	_target_actor = null
	_target_brain = null
	_clear_children()
	input_blocked.emit(false)
	closed.emit()

func _build_ui() -> void:
	_clear_children()
	_history_labels.clear()

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var scr_w: float = viewport_rect.size.x
	var scr_h: float = viewport_rect.size.y
	
	_panel_w = scr_w - PANEL_MARGIN * 2
	_panel_h = scr_h - PANEL_MARGIN * 2
	_pan_x = PANEL_MARGIN
	_pan_y = PANEL_MARGIN
	
	var font_scale: float = scr_h / 360.0

	# Full-screen overlay that catches all input
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.02, 0.02, 0.06, 0.85)
	add_child(_overlay)

	# Main panel
	_panel_bg = ColorRect.new()
	_panel_bg.position = Vector2(_pan_x, _pan_y)
	_panel_bg.size = Vector2(_panel_w, _panel_h)
	_panel_bg.color = Color(0.04, 0.04, 0.08, 0.98)
	add_child(_panel_bg)

	# Header bar
	var hdr := ColorRect.new()
	hdr.position = Vector2(_pan_x, _pan_y)
	hdr.size = Vector2(_panel_w, 36)
	hdr.color = Color(0.12, 0.12, 0.20, 1.0)
	add_child(hdr)

	# NPC name in header
	_name_label = Label.new()
	_name_label.text = "  %s" % (_target_actor.display_name if _target_actor != null else "NPC")
	_name_label.position = Vector2(_pan_x + 8, _pan_y + 8)
	_name_label.add_theme_color_override("font_color", Color(0.70, 0.90, 1.0))
	_name_label.add_theme_font_size_override("font_size", int(16 * font_scale))
	add_child(_name_label)

	# Close hint
	var close_lbl := Label.new()
	close_lbl.text = "ESC to close"
	close_lbl.position = Vector2(_pan_x + _panel_w - 120, _pan_y + 10)
	close_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	close_lbl.add_theme_font_size_override("font_size", int(12 * font_scale))
	add_child(close_lbl)

	# History scroll area
	_history_bg = ColorRect.new()
	_history_bg.position = Vector2(_pan_x + 8, _pan_y + 44)
	_history_bg.size = Vector2(_panel_w - 16, _panel_h - 80)
	_history_bg.color = Color(0.02, 0.02, 0.05, 0.8)
	add_child(_history_bg)

	# Input field
	_input_field = LineEdit.new()
	_input_field.position = Vector2(_pan_x + 8, _pan_y + _panel_h - 32)
	_input_field.size = Vector2(_panel_w - 16, 24)
	_input_field.add_theme_color_override("font_color", Color(0.90, 0.90, 1.0))
	_input_field.add_theme_font_size_override("font_size", int(14 * font_scale))
	_input_field.add_theme_color_override("caret_color", Color(0.70, 0.90, 1.0))
	_input_field.placeholder_text = "Type message... (Enter to send)"
	_input_field.text_submitted.connect(_on_text_submitted)
	add_child(_input_field)
	_input_field.grab_focus()

	_refresh_history()

func _on_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	var msg := text.strip_edges()
	_input_field.text = ""
	_add_player_message(msg)

	# NPC responds after a short delay
	await get_tree().create_timer(0.8).timeout
	var response := _target_brain.generate_response(msg)
	_add_npc_message(response)

func _add_player_message(text: String) -> void:
	_chat_history.append({ "role": "player", "text": text })
	_refresh_history()

func _add_npc_message(text: String) -> void:
	_chat_history.append({ "role": "npc", "text": text })
	_refresh_history()
	_show_npc_bubble(text)

func _refresh_history() -> void:
	# Remove old history labels
	for lbl in _history_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_history_labels.clear()

	var start_idx: int = max(0, _chat_history.size() - MAX_LINES)
	var visible_history := _chat_history.slice(start_idx)

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var font_scale: float = viewport_rect.size.y / 360.0
	var pan_x: float = _pan_x + 10
	var pan_y: float = _pan_y + 50

	for i in range(visible_history.size()):
		var entry: Dictionary = visible_history[i]
		var lbl := Label.new()
		lbl.position = Vector2(pan_x, pan_y + i * LINE_H)
		lbl.size = Vector2(_panel_w - 20, LINE_H)

		if entry["role"] == "player":
			lbl.text = "  You: %s" % entry["text"]
			lbl.add_theme_color_override("font_color", Color(0.60, 0.90, 0.70))
		else:
			lbl.text = "  %s: %s" % [_target_actor.display_name, entry["text"]]
			lbl.add_theme_color_override("font_color", Color(0.80, 0.85, 1.0))

		lbl.add_theme_font_size_override("font_size", int(12 * font_scale))
		add_child(lbl)
		_history_labels.append(lbl)

func _show_npc_bubble(text: String) -> void:
	if _target_npc == null:
		return
	if is_instance_valid(_npc_bubble):
		_npc_bubble.queue_free()
	_npc_bubble = ChatBubble.new()
	_target_npc.get_parent().add_child(_npc_bubble)
	_npc_bubble.global_position = _target_npc.global_position + Vector2(0, -30)
	_npc_bubble.display(text, 4.0)

func _clear_children() -> void:
	for c in get_children():
		c.queue_free()
	_history_labels.clear()
	_overlay = null

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.keycode == KEY_ESCAPE:
		close()
