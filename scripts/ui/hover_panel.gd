# hover_panel.gd
# Floating panel that follows the mouse and lists every NPC or robot
# currently under the cursor. Overlapping actors stack as separate
# entries; leaving the last one hides the whole panel.
#
# Controllers call show_for(self) on mouse_entered and hide_for(self)
# on mouse_exited. They must:
#   - implement get_hover_info() -> Dictionary
#   - implement contains_world_point(world_point) -> bool
#   - be in the "hoverable" group
extends CanvasLayer

const ActorData = preload("res://scripts/entities/actor_data.gd")

const ENTRY_W := 224.0
const ENTRY_H := 88.0
const ENTRY_GAP := 3.0
const SPRITE_SIZE := 32.0
const SPRITE_PAD := 4.0
const MARGIN := 14.0

# Base design resolution the constants above are tuned for.
const BASE_VIEWPORT_W := 1920.0

func _scale() -> float:
	# Scale panel dims with the viewport so a 1987x1222 window doesn't
	# render a tiny 224x44 strip in the middle of the screen.
	var vp := get_viewport()
	if vp == null:
		return 1.0
	var w: float = vp.get_visible_rect().size.x
	var s: float = w / BASE_VIEWPORT_W
	return maxf(1.0, s)

func _entry_w() -> float: return ENTRY_W * _scale()
func _entry_h() -> float: return ENTRY_H * _scale()
func _entry_gap() -> float: return ENTRY_GAP * _scale()
func _sprite_size() -> float: return SPRITE_SIZE * _scale()
func _sprite_pad() -> float: return SPRITE_PAD * _scale()
func _margin() -> float: return MARGIN * _scale()

# Each entry holds the visual children used to render one hovered actor.
class Entry:
	var target: Node
	var frame: ColorRect
	var sprite_bg: ColorRect
	var sprite: TextureRect
	var name_lbl: Label
	var role_lbl: Label
	var appearance_lbl: Label
	var ai_lbl: Label

var _entries: Array[Entry] = []
var _border: ColorRect = null
var _bg: ColorRect = null

func _ready() -> void:
	layer = 800
	visible = false
	add_to_group("hover_panel")
	set_process(true)
	_build_chrome()

func _build_chrome() -> void:
	_border = ColorRect.new()
	_border.color = Color(0.82, 0.78, 0.42, 0.95)
	_border.z_index = 0
	add_child(_border)
	_bg = ColorRect.new()
	_bg.color = Color(0.06, 0.07, 0.10, 0.94)
	_bg.z_index = 1
	add_child(_bg)

# Show the panel for a given controller. The controller's
# mouse_entered handler calls this. We also re-scan the world for any
# other hoverable whose hitbox covers the same mouse point so that
# overlapping actors all show up together.
func show_for(target: Node) -> void:
	# Poll-based picker in _process is the source of truth. We keep this
	# as a no-op-friendly entry point so existing Area2D signal handlers
	# don't error out, but actual state is rebuilt every frame.
	pass

func hide_for(target: Node) -> void:
	# See show_for: state is rebuilt from world polling every frame.
	pass

func hide_panel() -> void:
	for e in _entries:
		_free_entry(e)
	_entries.clear()
	visible = false

func _process(_delta: float) -> void:
	# Poll-based picker: scan the world for every hoverable whose hitbox
	# covers the current mouse point. We use this instead of relying on
	# Area2D mouse_entered/mouse_exited signals because those signals
	# can fire repeatedly when the mouse jitters at the edge of a small
	# CollisionShape, causing entries to flicker in and out.
	var world_pt := _mouse_to_world()
	var hit_targets: Array = []
	for n in get_tree().get_nodes_in_group("hoverable"):
		if n is Node and n.has_method("contains_world_point") and n.contains_world_point(world_pt):
			hit_targets.append(n)

	# Remove entries whose target is no longer under the mouse AND was
	# freed; keep entries that are still under the mouse.
	var i := 0
	while i < _entries.size():
		var t: Node = _entries[i].target
		if not is_instance_valid(t) or not hit_targets.has(t):
			_free_entry(_entries[i])
			_entries.remove_at(i)
		else:
			i += 1

	# Add new hits as entries.
	for t in hit_targets:
		if not _has_entry(t):
			_ensure_entry(t)

	if _entries.is_empty():
		visible = false
		return
	visible = true
	_refresh()

# ── Entry management ───────────────────────────────────────────────

func _has_entry(target: Node) -> bool:
	for e in _entries:
		if e.target == target:
			return true
	return false

func _ensure_entry(target: Node) -> void:
	if _has_entry(target):
		return
	var e := Entry.new()
	e.target = target
	e.frame = ColorRect.new()
	e.frame.color = Color(0.10, 0.11, 0.16, 0.95)
	e.frame.z_index = 2
	add_child(e.frame)

	e.sprite_bg = ColorRect.new()
	e.sprite_bg.color = Color(0.18, 0.20, 0.26, 1.0)
	e.sprite_bg.z_index = 3
	add_child(e.sprite_bg)

	e.sprite = TextureRect.new()
	e.sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	e.sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	e.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	e.sprite.z_index = 4
	add_child(e.sprite)

	var s: float = _scale()
	var name_fs: int = int(round(9.0 * s))
	var small_fs: int = int(round(7.0 * s))

	e.name_lbl = Label.new()
	e.name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.70))
	e.name_lbl.add_theme_font_size_override("font_size", name_fs)
	e.name_lbl.z_index = 4
	add_child(e.name_lbl)

	e.role_lbl = Label.new()
	e.role_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 0.95))
	e.role_lbl.add_theme_font_size_override("font_size", small_fs)
	e.role_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.role_lbl.z_index = 4
	add_child(e.role_lbl)

	e.ai_lbl = Label.new()
	e.ai_lbl.add_theme_color_override("font_color", Color(0.70, 0.95, 0.70))
	e.ai_lbl.add_theme_font_size_override("font_size", small_fs)
	e.ai_lbl.z_index = 4
	add_child(e.ai_lbl)

	e.appearance_lbl = Label.new()
	e.appearance_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.72))
	e.appearance_lbl.add_theme_font_size_override("font_size", small_fs)
	e.appearance_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	e.appearance_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	e.appearance_lbl.z_index = 4
	add_child(e.appearance_lbl)

	_entries.append(e)

func _remove_entry(target: Node) -> void:
	for i in range(_entries.size()):
		if _entries[i].target == target:
			_free_entry(_entries[i])
			_entries.remove_at(i)
			return

func _free_entry(e: Entry) -> void:
	if is_instance_valid(e.frame): e.frame.queue_free()
	if is_instance_valid(e.sprite_bg): e.sprite_bg.queue_free()
	if is_instance_valid(e.sprite): e.sprite.queue_free()
	if is_instance_valid(e.name_lbl): e.name_lbl.queue_free()
	if is_instance_valid(e.role_lbl): e.role_lbl.queue_free()
	if is_instance_valid(e.ai_lbl): e.ai_lbl.queue_free()
	if is_instance_valid(e.appearance_lbl): e.appearance_lbl.queue_free()

# ── Refresh ────────────────────────────────────────────────────────

func _refresh() -> void:
	_refresh_info()
	_refresh_font_sizes()
	_refresh_layout()

func _refresh_font_sizes() -> void:
	var s: float = _scale()
	var name_fs: int = int(round(9.0 * s))
	var small_fs: int = int(round(7.0 * s))
	for e in _entries:
		if is_instance_valid(e.name_lbl): e.name_lbl.add_theme_font_size_override("font_size", name_fs)
		if is_instance_valid(e.role_lbl): e.role_lbl.add_theme_font_size_override("font_size", small_fs)
		if is_instance_valid(e.ai_lbl): e.ai_lbl.add_theme_font_size_override("font_size", small_fs)
		if is_instance_valid(e.appearance_lbl): e.appearance_lbl.add_theme_font_size_override("font_size", small_fs)

func _refresh_info() -> void:
	for e in _entries:
		if not is_instance_valid(e.target):
			continue
		var info: Dictionary = e.target.get_hover_info()
		if info.is_empty():
			e.name_lbl.text = ""
			e.role_lbl.text = ""
			e.ai_lbl.text = ""
			e.appearance_lbl.text = ""
			e.sprite.texture = null
			continue
		e.sprite.texture = info.get("sprite", null)
		e.name_lbl.text = String(info.get("name", ""))
		e.role_lbl.text = String(info.get("role", ""))
		e.appearance_lbl.text = String(info.get("appearance", ""))
		e.ai_lbl.text = _format_ai(info)

func _format_ai(info: Dictionary) -> String:
	var mode_int: int = int(info.get("movement_mode", ActorData.MovementMode.FREE))
	var mode_name := "FREE"
	match mode_int:
		ActorData.MovementMode.FREE:
			mode_name = "FREE"
		ActorData.MovementMode.FIXED_RANGE:
			var wp := int(info.get("waypoint_count", 0))
			mode_name = "FIXED RNG" if wp == 0 else "FIXED %d wp" % wp
		ActorData.MovementMode.STANDBY:
			mode_name = "STANDBY"
	var state_text: String = String(info.get("state", ""))
	if state_text == "":
		return "AI: %s" % mode_name
	return "AI: %s  |  %s" % [mode_name, state_text]

func _refresh_layout() -> void:
	if _entries.is_empty():
		return
	var s: float = _scale()
	var ew: float = _entry_w()
	var eh: float = _entry_h()
	var eg: float = _entry_gap()
	var ss: float = _sprite_size()
	var sp: float = _sprite_pad()
	var mg: float = _margin()
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_size := get_viewport().get_visible_rect().size
	var total_h: float = float(_entries.size()) * eh + float(_entries.size() - 1) * eg
	var px: float = mouse_pos.x + mg
	var py: float = mouse_pos.y + mg
	if px + ew > screen_size.x:
		px = mouse_pos.x - ew - mg
	if py + total_h > screen_size.y:
		py = mouse_pos.y - total_h - mg
	if px < 0:
		px = 0
	if py < 0:
		py = 0

	_border.position = Vector2(px - 1, py - 1)
	_border.size = Vector2(ew + 2, total_h + 2)
	_bg.position = Vector2(px, py)
	_bg.size = Vector2(ew, total_h)

	for i in range(_entries.size()):
		var e: Entry = _entries[i]
		var ey: float = py + float(i) * (eh + eg)
		e.frame.position = Vector2(px, ey)
		e.frame.size = Vector2(ew, eh)
		e.sprite_bg.position = Vector2(px + sp, ey + sp)
		e.sprite_bg.size = Vector2(ss + sp * 2, ss + sp * 2)
		e.sprite.position = Vector2(px + sp * 2, ey + sp * 2)
		e.sprite.size = Vector2(ss, ss)
		var text_x: float = px + sp * 3 + ss
		var text_w: float = ew - (text_x - px) - 4
		# Rows: name, role, appearance (multi-line), AI.
		var name_y: float = ey + 2
		var role_y: float = name_y + eh * 0.13
		var ap_y: float = role_y + eh * 0.13
		var ai_y: float = ey + eh * 0.72
		var name_h: float = eh * 0.13
		var role_h: float = eh * 0.13
		var ap_h: float = eh * 0.59
		var ai_h: float = eh * 0.26
		e.name_lbl.position = Vector2(text_x, name_y)
		e.name_lbl.size = Vector2(text_w, name_h)
		e.role_lbl.position = Vector2(text_x, role_y)
		e.role_lbl.size = Vector2(text_w, role_h)
		e.appearance_lbl.position = Vector2(text_x, ap_y)
		e.appearance_lbl.size = Vector2(text_w, ap_h)
		e.ai_lbl.position = Vector2(text_x, ai_y)
		e.ai_lbl.size = Vector2(text_w, ai_h)

func _mouse_to_world() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	return vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()
