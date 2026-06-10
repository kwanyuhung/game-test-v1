# hover_debug_overlay.gd
# Visual debug aid for the hover picker. Toggle with F8.
#
# On-screen elements while enabled:
#   * Red crosshair + world-coord label following the mouse.
#   * A rect for every node in the "hoverable" group showing its
#     hover Area2D's actual screen-space shape:
#       - orange thin border = not currently under the mouse
#       - green thick border + faint fill = currently under the mouse
#   * Top-left summary line: mouse screen/world, hit count, panel
#     state (visible / hidden / entry count). A red warning appears
#     when hits > 0 but the HoverPanel is hidden, so you can tell
#     whether the picker is working or the panel is the failure.
extends CanvasLayer

const HIT_COLOR := Color(0.4, 1.0, 0.5, 0.95)
const HIT_FILL := Color(0.4, 1.0, 0.5, 0.15)
const ALL_COLOR := Color(1.0, 0.55, 0.2, 0.55)
const CROSS_COLOR := Color(1.0, 0.3, 0.3, 0.95)
const TEXT_COLOR := Color(1.0, 0.95, 0.7)
const WARN_COLOR := Color(1.0, 0.4, 0.4)

var _enabled: bool = true
var _draw_node: Control = null
var _corner_label: Label = null
var _mouse_label: Label = null
var _hint_label: Label = null

func _ready() -> void:
	layer = 850
	add_to_group("hover_debug_overlay")
	_build_canvas()

func _build_canvas() -> void:
	_draw_node = Control.new()
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.draw.connect(_on_draw)
	add_child(_draw_node)

	_corner_label = _make_label()
	_corner_label.position = Vector2(8, 8)
	add_child(_corner_label)

	_mouse_label = _make_label()
	add_child(_mouse_label)

	_hint_label = _make_label()
	_hint_label.text = "[F8] toggle hover debug"
	_hint_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_hint_label.position = Vector2(8, 30)
	add_child(_hint_label)

	set_process(true)

func _make_label() -> Label:
	var l := Label.new()
	var s: float = _scale()
	l.add_theme_color_override("font_color", TEXT_COLOR)
	l.add_theme_font_size_override("font_size", int(round(9.0 * s)))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("outline_size", 3)
	l.z_index = 100
	return l

func _scale() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1.0
	return maxf(1.0, vp.get_visible_rect().size.x / 1920.0)

func _process(_delta: float) -> void:
	if not _enabled:
		return
	_draw_node.queue_redraw()
	var vp := get_viewport()
	if vp == null:
		return
	var mouse_screen: Vector2 = vp.get_mouse_position()
	var mouse_world: Vector2 = vp.get_canvas_transform().affine_inverse() * mouse_screen
	_mouse_label.position = mouse_screen + Vector2(16, 14)
	_mouse_label.text = "(%d, %d)" % [int(mouse_world.x), int(mouse_world.y)]

	var hits: Array = []
	for n in get_tree().get_nodes_in_group("hoverable"):
		if n is Node and n.has_method("contains_world_point") and n.contains_world_point(mouse_world):
			hits.append(n.name)

	var panel := get_tree().get_first_node_in_group("hover_panel")
	var panel_state := "none"
	var entry_count := 0
	var entry_names: Array = []
	if panel != null:
		panel_state = "visible" if panel.visible else "hidden"
		entry_count = panel._entries.size()
		for e in panel._entries:
			if is_instance_valid(e.target):
				entry_names.append(e.target.name)

	var warn := ""
	if hits.size() > 0 and not (panel != null and panel.visible and entry_count > 0):
		warn = "  HIT-BUT-PANEL-HIDDEN"
	_corner_label.text = "screen=(%d,%d)  world=(%d,%d)  hits=%d  panel=%s  entries=%d %s" % [
		int(mouse_screen.x), int(mouse_screen.y),
		int(mouse_world.x), int(mouse_world.y),
		hits.size(), panel_state, entry_count, warn
	]

func _on_draw() -> void:
	if not _enabled:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var canvas_xform: Transform2D = vp.get_canvas_transform()
	var mouse_screen: Vector2 = vp.get_mouse_position()
	var mouse_world: Vector2 = canvas_xform.affine_inverse() * mouse_screen

	_draw_node.draw_line(mouse_screen + Vector2(-14, 0), mouse_screen + Vector2(14, 0), CROSS_COLOR, 1.5)
	_draw_node.draw_line(mouse_screen + Vector2(0, -14), mouse_screen + Vector2(0, 14), CROSS_COLOR, 1.5)
	_draw_node.draw_circle(mouse_screen, 2.5, CROSS_COLOR)

	# Outline the hover panel's actual rect (drawn in screen space) so we
	# can see if it's positioned where the layout code thinks it is.
	var panel := get_tree().get_first_node_in_group("hover_panel")
	if panel != null and panel.visible:
		var bg: ColorRect = panel.get("_bg")
		if bg != null and is_instance_valid(bg):
			var pr := Rect2(bg.position, bg.size)
			_draw_node.draw_rect(pr, Color(1, 0.2, 1, 0.9), false, 2.0)

	for n in get_tree().get_nodes_in_group("hoverable"):
		var area: Area2D = n.get("_hover_area")
		if area == null:
			continue
		var shape_node: CollisionShape2D = null
		for child in area.get_children():
			if child is CollisionShape2D:
				shape_node = child
				break
		if shape_node == null or shape_node.shape == null or not (shape_node.shape is RectangleShape2D):
			continue
		var size: Vector2 = (shape_node.shape as RectangleShape2D).size
		var top_left_world: Vector2 = area.global_position - size * 0.5
		var top_left_screen: Vector2 = canvas_xform * top_left_world
		var size_screen: Vector2 = canvas_xform.basis_xform(size).abs()
		var rect := Rect2(top_left_screen, size_screen)
		var is_hit: bool = n.has_method("contains_world_point") and n.contains_world_point(mouse_world)
		var border_color := HIT_COLOR if is_hit else ALL_COLOR
		var fill_color := HIT_FILL if is_hit else Color(0, 0, 0, 0)
		_draw_node.draw_rect(rect, border_color, false, 1.5)
		if fill_color.a > 0.0:
			_draw_node.draw_rect(rect, fill_color, true)

func toggle() -> void:
	_enabled = not _enabled
	_draw_node.visible = _enabled
	_corner_label.visible = _enabled
	_mouse_label.visible = _enabled
	_hint_label.visible = _enabled
	if not _enabled:
		_draw_node.queue_redraw()

func is_enabled() -> bool:
	return _enabled
