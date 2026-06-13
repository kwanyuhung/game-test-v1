# count_overlay.gd
# Top-right debug overlay that shows how many spawned characters are
# currently in the world, broken down by life stage and by role.
# Toggled with F3 (handled in main.gd alongside the hover debug).
#
# Source of truth: get_tree().get_nodes_in_group("hoverable") — this
# group is populated by NPCController._ready() and RobotController.
# NPCs that have been queue_freed are gone from the tree, so the count
# is naturally accurate.
extends CanvasLayer

const ActorData = preload("res://scripts/entities/actor_data.gd")

const TEXT_COLOR := Color(1.0, 0.95, 0.7)
const HEADER_COLOR := Color(0.7, 0.85, 1.0)
const SEPARATOR_COLOR := Color(0.5, 0.5, 0.6, 0.6)
const BG_COLOR := Color(0.06, 0.07, 0.10, 0.78)

var _enabled: bool = true
var _bg: ColorRect = null
var _label: Label = null
var _hint_label: Label = null

# Life stage display order — keeps the label stable frame-to-frame.
const STAGE_ORDER := [
	ActorData.LifeStage.ADULT,
	ActorData.LifeStage.SENIOR,
	ActorData.LifeStage.TEEN,
	ActorData.LifeStage.CHILD,
	ActorData.LifeStage.TODDLER,
	ActorData.LifeStage.INFANT,
]

const STAGE_LABEL := {
	ActorData.LifeStage.ADULT: "Adults",
	ActorData.LifeStage.SENIOR: "Seniors",
	ActorData.LifeStage.TEEN: "Teens",
	ActorData.LifeStage.CHILD: "Children",
	ActorData.LifeStage.TODDLER: "Toddlers",
	ActorData.LifeStage.INFANT: "Infants",
}

const ROLE_LABEL := {
	ActorData.Role.CUSTOMER: "Customers",
	ActorData.Role.STAFF: "Staff",
	ActorData.Role.ROBOT: "Robots",
}

func _ready() -> void:
	layer = 851
	add_to_group("count_overlay")
	_build_canvas()
	set_process(true)

func _build_canvas() -> void:
	# Dark background panel to make the text legible over any scene
	_bg = ColorRect.new()
	_bg.color = BG_COLOR
	_bg.z_index = 0
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Right-anchored panel: width 320, position from right edge with
	# a 12px margin. Height grows with content; we set it from the
	# label size at refresh time.
	_bg.size = Vector2(320, 140)
	_bg.position = Vector2(-332, 12)
	_bg.anchor_left = 1.0
	_bg.anchor_right = 1.0
	_bg.anchor_top = 0.0
	_bg.anchor_bottom = 0.0
	add_child(_bg)

	_label = Label.new()
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_label.add_theme_font_size_override("font_size", _font_size())
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_label.add_theme_constant_override("outline_size", 2)
	_label.z_index = 1
	_label.position = Vector2(-320, 18)
	_label.size = Vector2(308, 110)
	_label.anchor_left = 1.0
	_label.anchor_right = 1.0
	_label.anchor_top = 0.0
	_label.anchor_bottom = 0.0
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_hint_label = Label.new()
	_hint_label.text = "[F3] toggle"
	_hint_label.add_theme_color_override("font_color", HEADER_COLOR)
	_hint_label.add_theme_font_size_override("font_size", _font_size() - 1)
	_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_hint_label.add_theme_constant_override("outline_size", 2)
	_hint_label.z_index = 1
	_hint_label.position = Vector2(-100, 4)
	_hint_label.anchor_left = 1.0
	_hint_label.anchor_right = 1.0
	_hint_label.anchor_top = 0.0
	_hint_label.anchor_bottom = 0.0
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_label)

func _font_size() -> int:
	var s: float = _scale()
	return int(round(10.0 * s))

func _scale() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1.0
	return maxf(1.0, vp.get_visible_rect().size.x / 1280.0)

func _process(_delta: float) -> void:
	if not _enabled:
		return
	_refresh()

func _refresh() -> void:
	var stage_counts := {}
	for s in STAGE_ORDER:
		stage_counts[s] = 0
	var role_counts := {}
	for r in ROLE_LABEL.keys():
		role_counts[r] = 0
	var total := 0
	for n in get_tree().get_nodes_in_group("hoverable"):
		if not is_instance_valid(n):
			continue
		if not n.has_method("get_actor"):
			continue
		var actor: ActorData.Actor = n.get_actor()
		if actor == null:
			continue
		# Only count active NPCs — frozen / leaving NPCs fall out
		# of the active set but may still be in the group briefly.
		if not actor.is_active:
			continue
		if not stage_counts.has(actor.life_stage):
			stage_counts[actor.life_stage] = 0
		stage_counts[actor.life_stage] += 1
		if not role_counts.has(actor.role):
			role_counts[actor.role] = 0
		role_counts[actor.role] += 1
		total += 1

	# Build the text. The header is the total + a "by stage" line +
	# a separator + a "by role" line.
	var lines: Array = []
	lines.append("Total characters: %d" % total)

	var stage_line := ""
	for s in STAGE_ORDER:
		var c: int = stage_counts.get(s, 0)
		stage_line += "%s: %d    " % [STAGE_LABEL.get(s, "?"), c]
	lines.append(stage_line)

	# Gender breakdown — a third line for variety. Skipped if gender
	# field is unset (older Actor data without it would just be 0).
	var gender_counts := {ActorData.Gender.MALE: 0, ActorData.Gender.FEMALE: 0, ActorData.Gender.UNDISCLOSED: 0}
	for n in get_tree().get_nodes_in_group("hoverable"):
		if not is_instance_valid(n) or not n.has_method("get_actor"):
			continue
		var actor2: ActorData.Actor = n.get_actor()
		if actor2 == null or not actor2.is_active:
			continue
		if not gender_counts.has(actor2.gender):
			gender_counts[actor2.gender] = 0
		gender_counts[actor2.gender] += 1
	var gender_line := "M: %d   F: %d   ?: %d" % [
		gender_counts.get(ActorData.Gender.MALE, 0),
		gender_counts.get(ActorData.Gender.FEMALE, 0),
		gender_counts.get(ActorData.Gender.UNDISCLOSED, 0),
	]
	lines.append(gender_line)

	lines.append("─────────────────")
	var role_line := ""
	for r in ROLE_LABEL.keys():
		var c: int = role_counts.get(r, 0)
		role_line += "%s: %d   " % [ROLE_LABEL.get(r, "?"), c]
	lines.append(role_line)

	_label.text = "\n".join(lines)
	# Resize the background to match the label height so the panel
	# wraps the text tightly.
	var line_count: int = lines.size()
	var line_h: float = float(_font_size()) * 1.4
	var h: float = 18.0 + float(line_count) * line_h + 12.0
	_bg.size = Vector2(320, h)

func toggle() -> void:
	_enabled = not _enabled
	_bg.visible = _enabled
	_label.visible = _enabled
	_hint_label.visible = _enabled

func is_enabled() -> bool:
	return _enabled
