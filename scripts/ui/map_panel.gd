# map_panel.gd
# Full-screen floor map.
# Toggled with M (handled in main.gd → PanelManager.toggle("map")).
#
# Source of truth: FloorConfig (loaded from res://scripts/floor_config_data.json).
#   - Each floor has zones[] (x, y, w, h in tiles; meta.color / meta.name when named)
#     and sections[] (x, y, w, h in tiles; id).
#   - World geometry: CELL_SIZE=16, WORLD_W=512 tiles wide. Each floor's world Y is
#     FloorManager.get_floor_y(idx) = 32*16 - idx*40*16. The floor's tiles are
#     measured locally (0..~320 wide, 0..~160 tall).
#
# This panel:
#   1. Builds a static frame (background, title, close button, legend).
#   2. Projects the current floor's zones/sections into a sub-area of the panel.
#   3. Projects the player and all NPCs/robots that live on this floor.
#   4. Re-renders the map content whenever the floor changes (set_floor).
class_name MapPanel
extends CanvasLayer

const FloorConfig = preload("res://scripts/world/floor_config.gd")
const FloorManagerScript = preload("res://scripts/world/floor_manager.gd")

const CELL_SIZE := FloorConfig.CELL_SIZE

# Margins between zones for visual separation
const ZONE_PADDING_TILES := 0.5

# Colors
const NPC_COLOR := Color(0.70, 0.85, 0.95)
const STAFF_COLOR := Color(0.85, 0.70, 0.95)
const PLAYER_COLOR := Color(0.95, 0.85, 0.30)

# Robot marker colors by role
const ROBOT_COLORS := {
	"cleaner": Color(0.20, 0.80, 0.60),
	"guide": Color(0.90, 0.70, 0.30),
	"security": Color(0.90, 0.20, 0.20),
	"shelf": Color(0.30, 0.90, 0.40),
	"delivery": Color(0.60, 0.50, 0.90),
	"humanoid": Color(0.40, 0.80, 0.95),
	"unknown": Color(0.80, 0.80, 0.80),
}

# Per-zone-type fill color. Every zone type used in the JSON gets a visible
# color so no zone renders as an empty rectangle. Categories:
#   base     — walkable floors (ZONE_COMMON, LOBBY, etc.) drawn first as
#              a high-alpha base; specific zones are drawn on top.
#   transport— elevator / stairs / escalator
#   service  — info / customer service / kiosks / etc.
#   machines — ATM / AD / vending / claw
#   wc       — washrooms and nursing rooms
#   food     — food court / stalls / canteen / cafe
#   health   — juice / health / smoothie / salad
#   fun      — kids play / club / karaoke / pool / darts
#   tech     — phone / smart home / electronics / repair
#   retail   — category buckets for section racks (when meta has no color)
#   staff    — staff lounge / training / office / monitor / locker
#   warehouse— warehouse / truck dock / forklift / conveyor / storage / packing
#   outdoor  — rooftop / outdoor / plants / pet adoption
#   decor    — misc decor
const _ZONE_COLORS := {
	# Walkable base
	"common": Color(0.32, 0.35, 0.40, 0.85),
	"lobby": Color(0.38, 0.42, 0.40, 0.85),
	"entry_gate": Color(0.36, 0.40, 0.45, 0.85),
	# Transport
	"elevator": Color(0.50, 0.72, 0.95, 0.90),
	"stairs": Color(0.62, 0.50, 0.70, 0.90),
	"escalator": Color(0.62, 0.50, 0.70, 0.90),
	# Service desks and kiosks
	"info_desk": Color(0.65, 0.55, 0.82, 0.85),
	"customer_service": Color(0.65, 0.55, 0.82, 0.85),
	"loyalty_kiosk": Color(0.68, 0.55, 0.82, 0.85),
	"gift_wrap": Color(0.70, 0.58, 0.80, 0.85),
	"digital_kiosk": Color(0.55, 0.65, 0.85, 0.85),
	"lost_found": Color(0.62, 0.58, 0.78, 0.85),
	"store_news": Color(0.60, 0.55, 0.80, 0.85),
	# Machines
	"atm": Color(0.85, 0.68, 0.30, 0.85),
	"ad": Color(0.90, 0.55, 0.25, 0.85),
	"vending_machine": Color(0.85, 0.65, 0.30, 0.85),
	"promo_booth": Color(0.85, 0.62, 0.28, 0.85),
	"claw_machine": Color(0.92, 0.42, 0.70, 0.85),
	# WC / nursing
	"wc": Color(0.55, 0.70, 0.85, 0.85),
	"nursing_room": Color(0.75, 0.62, 0.78, 0.85),
	"family_wc": Color(0.55, 0.70, 0.85, 0.85),
	# Food
	"food_court": Color(0.85, 0.55, 0.30, 0.85),
	"food_stall": Color(0.82, 0.60, 0.40, 0.85),
	"canteen": Color(0.80, 0.52, 0.35, 0.85),
	"cafe_counter": Color(0.80, 0.50, 0.38, 0.85),
	# Health
	"juice_bar": Color(0.55, 0.80, 0.50, 0.85),
	"health_food": Color(0.55, 0.82, 0.55, 0.85),
	"smoothie": Color(0.55, 0.80, 0.50, 0.85),
	"salad_bar": Color(0.60, 0.82, 0.45, 0.85),
	# Fun / kids / entertainment
	"kids_play": Color(0.92, 0.62, 0.78, 0.85),
	"kids_club": Color(0.90, 0.60, 0.78, 0.85),
	"kids_clothing": Color(0.88, 0.65, 0.78, 0.85),
	"entertainment": Color(0.70, 0.45, 0.80, 0.85),
	"darts_board": Color(0.72, 0.45, 0.78, 0.85),
	"pool_table": Color(0.55, 0.70, 0.45, 0.85),
	"karaoke": Color(0.70, 0.40, 0.78, 0.85),
	# Tech / electronics
	"phone_gadgets": Color(0.40, 0.75, 0.85, 0.85),
	"smart_home": Color(0.40, 0.75, 0.85, 0.85),
	"electronics": Color(0.42, 0.72, 0.85, 0.85),
	"repair_counter": Color(0.85, 0.45, 0.42, 0.85),
	# Retail racks (used as fallbacks when meta has no color)
	"shoes_rack": Color(0.78, 0.58, 0.70, 0.85),
	"dress_rack": Color(0.78, 0.62, 0.78, 0.85),
	"sport_area": Color(0.55, 0.72, 0.82, 0.85),
	"stationery": Color(0.78, 0.70, 0.55, 0.85),
	"home_decor": Color(0.72, 0.62, 0.52, 0.85),
	"furniture": Color(0.70, 0.58, 0.48, 0.85),
	"outdoor_living": Color(0.55, 0.72, 0.55, 0.85),
	"organization": Color(0.65, 0.60, 0.55, 0.85),
	"lighting": Color(0.78, 0.72, 0.55, 0.85),
	# Supermarket grocery aisles (fallbacks when meta has no color)
	"fresh_produce": Color(0.55, 0.78, 0.42, 0.85),
	"meat": Color(0.92, 0.55, 0.55, 0.85),
	"seafood": Color(0.40, 0.72, 0.88, 0.85),
	"frozen": Color(0.78, 0.92, 1.00, 0.85),
	"dairy": Color(0.70, 0.88, 1.00, 0.85),
	"bakery": Color(0.95, 0.78, 0.45, 0.85),
	"beverages": Color(0.45, 0.72, 0.95, 0.85),
	"pantry": Color(0.88, 0.78, 0.55, 0.85),
	"snacks": Color(0.85, 0.62, 0.42, 0.85),
	"household": Color(0.55, 0.68, 0.62, 0.85),
	"health": Color(0.62, 0.78, 0.72, 0.85),
	"baby": Color(0.85, 0.72, 0.85, 0.85),
	# Staff / back-of-house
	"staff_lounge": Color(0.48, 0.52, 0.58, 0.85),
	"training": Color(0.50, 0.55, 0.60, 0.85),
	"office_desk": Color(0.50, 0.55, 0.60, 0.85),
	"exec_office": Color(0.55, 0.50, 0.60, 0.85),
	"monitor_room": Color(0.45, 0.52, 0.60, 0.85),
	"locker": Color(0.50, 0.55, 0.58, 0.85),
	# Warehouse
	"warehouse": Color(0.55, 0.62, 0.42, 0.85),
	"truck_dock": Color(0.55, 0.62, 0.42, 0.85),
	"forklift": Color(0.55, 0.62, 0.42, 0.85),
	"conveyor": Color(0.55, 0.62, 0.42, 0.85),
	"storage_shelf": Color(0.55, 0.62, 0.42, 0.85),
	"packing_station": Color(0.55, 0.62, 0.42, 0.85),
	"wh_stock_view": Color(0.55, 0.62, 0.42, 0.85),
	"warehouse_stock_view": Color(0.55, 0.62, 0.42, 0.85),
	# Outdoor
	"outdoor_area": Color(0.45, 0.68, 0.48, 0.85),
	"rooftop": Color(0.45, 0.68, 0.48, 0.85),
	"plants_area": Color(0.45, 0.72, 0.48, 0.85),
	"pet_adoption": Color(0.50, 0.70, 0.50, 0.85),
	"parking": Color(0.32, 0.38, 0.45, 0.85),
	# Decor
	"decor": Color(0.70, 0.60, 0.50, 0.75),
}

# Per-zone-type display name. When the JSON has meta.name we use that instead.
const _ZONE_NAMES := {
	"common": "WALKWAY",
	"lobby": "LOBBY",
	"entry_gate": "ENTRY",
	"elevator": "ELEVATOR",
	"stairs": "STAIRS",
	"escalator": "ESCALATOR",
	"info_desk": "INFO DESK",
	"customer_service": "CUSTOMER SVC",
	"loyalty_kiosk": "LOYALTY",
	"gift_wrap": "GIFT WRAP",
	"digital_kiosk": "INFO KIOSK",
	"lost_found": "LOST & FOUND",
	"store_news": "STORE NEWS",
	"atm": "ATM",
	"ad": "AD",
	"vending_machine": "VENDING",
	"promo_booth": "PROMO",
	"claw_machine": "CLAW",
	"wc": "WC",
	"nursing_room": "NURSING",
	"family_wc": "FAMILY WC",
	"food_court": "FOOD COURT",
	"food_stall": "FOOD STALL",
	"canteen": "CANTEEN",
	"cafe_counter": "CAFE",
	"juice_bar": "JUICE",
	"health_food": "HEALTH",
	"smoothie": "SMOOTHIE",
	"salad_bar": "SALAD",
	"kids_play": "KIDS PLAY",
	"kids_club": "KIDS CLUB",
	"kids_clothing": "KIDS WEAR",
	"entertainment": "ENTERTAINMENT",
	"darts_board": "DARTS",
	"pool_table": "POOL",
	"karaoke": "KARAOKE",
	"phone_gadgets": "GADGETS",
	"smart_home": "SMART HOME",
	"electronics": "ELECTRONICS",
	"repair_counter": "REPAIR",
	"shoes_rack": "SHOES",
	"dress_rack": "DRESS",
	"sport_area": "SPORT",
	"stationery": "STATIONERY",
	"home_decor": "HOME DECOR",
	"furniture": "FURNITURE",
	"outdoor_living": "OUTDOOR",
	"organization": "ORGANIZE",
	"lighting": "LIGHTING",
	# Supermarket grocery aisles
	"fresh_produce": "PRODUCE",
	"meat": "MEAT & DELI",
	"seafood": "SEAFOOD",
	"frozen": "FROZEN",
	"dairy": "DAIRY",
	"bakery": "BAKERY",
	"beverages": "BEVERAGES",
	"pantry": "PANTRY",
	"snacks": "SNACKS",
	"household": "HOUSEHOLD",
	"health": "HEALTH",
	"baby": "BABY & KIDS",
	"staff_lounge": "STAFF LOUNGE",
	"training": "TRAINING",
	"office_desk": "OFFICE",
	"exec_office": "EXEC",
	"monitor_room": "MONITOR",
	"locker": "LOCKERS",
	"warehouse": "WAREHOUSE",
	"truck_dock": "TRUCK DOCK",
	"forklift": "FORKLIFT",
	"conveyor": "CONVEYOR",
	"storage_shelf": "STORAGE",
	"packing_station": "PACKING",
	"wh_stock_view": "WAREHOUSE",
	"warehouse_stock_view": "WAREHOUSE",
	"outdoor_area": "OUTDOOR",
	"rooftop": "ROOFTOP",
	"plants_area": "PLANTS",
	"pet_adoption": "PET ADOPTION",
	"parking": "PARKING",
	"decor": "DECOR",
}

# Categories that should be drawn FIRST as the walkable base. The remaining
# zones are drawn on top of these in JSON order.
const _ZONE_BASE := {
	"common": true,
	"lobby": true,
	"entry_gate": true,
	"outdoor_area": true,
	"rooftop": true,
	"warehouse": true,
	"parking": true,
}

signal input_blocked(bool)

var _player_ref = null
var _main_ref = null
var _floor_idx := 0

# Static frame
var _root: Control = null
var _bg_panel: Panel = null
var _title_label: Label = null
var _legend_panel: Panel = null
var _hover_label: Label = null

# Map area (panel-local coordinates) where zones/sections/dots are drawn
var _map_clip: Control = null  # Container for all map children
var _map_rect: Rect2 = Rect2()  # panel-local px: where the floor is drawn
var _floor_bounds: Rect2 = Rect2()  # floor-local tiles: tight bounds of all zones
var _font_scale: float = 1.0

# Track map children for fast cleanup on re-render
var _map_children: Array = []
var _hovered_actor_dot: Control = null

func _ready() -> void:
	visible = false

# ─── Public API ─────────────────────────────────────────────────────

func set_player(player) -> void:
	_player_ref = player

func set_main(main) -> void:
	_main_ref = main

func set_floor(idx: int) -> void:
	if idx == _floor_idx and _map_children.size() > 0:
		return
	_floor_idx = idx
	if visible:
		_render()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	visible = true
	input_blocked.emit(true)
	if _root == null:
		_build_panel()
	# Render deferred so the Control layout pass has time to set sizes
	# on _map_clip (and friends) before we read them.
	call_deferred("_render")

func close() -> void:
	visible = false
	input_blocked.emit(false)
	_clear_map_children()
	_hide_hover()

# ─── Static frame ───────────────────────────────────────────────────

func _build_panel() -> void:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var scr_h: float = viewport_rect.size.y
	# Less restrictive cap so larger screens get visibly larger UI
	_font_scale = clampf(scr_h / 540.0, 0.9, 2.4)

	# Root Control (full viewport) — easier to layer than the CanvasLayer directly
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = 0
	_root.offset_top = 0
	_root.offset_right = 0
	_root.offset_bottom = 0
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Backdrop
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.offset_left = 0
	backdrop.offset_top = 0
	backdrop.offset_right = 0
	backdrop.offset_bottom = 0
	backdrop.color = Color(0.02, 0.02, 0.05, 0.85)
	_root.add_child(backdrop)

	# Background panel — fills the viewport minus a margin so the panel
	# itself auto-scales with the screen.
	var margin: float = 16 * _font_scale
	_bg_panel = Panel.new()
	_bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_panel.offset_left = margin
	_bg_panel.offset_top = margin
	_bg_panel.offset_right = -margin
	_bg_panel.offset_bottom = -margin
	_bg_panel.z_index = 5
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	bg_style.border_color = Color(0.35, 0.45, 0.60)
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 12
	bg_style.corner_radius_bottom_right = 12
	bg_style.set_border_width_all(2)
	bg_style.set_content_margin_all(8)
	_bg_panel.add_theme_stylebox_override("panel", bg_style)
	_root.add_child(_bg_panel)

	# Title — anchored across the top of the panel
	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_left = 60 * _font_scale
	_title_label.offset_top = 12 * _font_scale
	_title_label.offset_right = -60 * _font_scale
	_title_label.offset_bottom = 48 * _font_scale
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	_title_label.add_theme_font_size_override("font_size", int(22 * _font_scale))
	_title_label.z_index = 50
	_bg_panel.add_child(_title_label)

	# Close button — top-right corner, anchored
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -48 * _font_scale
	close_btn.offset_right = -12 * _font_scale
	close_btn.offset_top = 12 * _font_scale
	close_btn.offset_bottom = 48 * _font_scale
	close_btn.add_theme_color_override("font_color", Color(0.95, 0.65, 0.65))
	close_btn.add_theme_color_override("bg_color", Color(0.30, 0.15, 0.15))
	close_btn.pressed.connect(close)
	_bg_panel.add_child(close_btn)

	# Legend (anchored top-right, below close button)
	_build_legend()

	# Map clip — fills the panel area below the title, to the left of the legend.
	# All children drawn inside are in _map_clip-local coords.
	_map_clip = Control.new()
	_map_clip.name = "MapClip"
	_map_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_clip.offset_left = 20 * _font_scale
	_map_clip.offset_top = 60 * _font_scale
	_map_clip.offset_right = -200 * _font_scale  # leave room for the legend
	_map_clip.offset_bottom = -20 * _font_scale
	_map_clip.z_index = 20
	_map_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_clip.clip_contents = true
	_bg_panel.add_child(_map_clip)

	# Hover label (drawn over the map)
	_hover_label = Label.new()
	_hover_label.visible = false
	_hover_label.z_index = 200
	_hover_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	_hover_label.add_theme_font_size_override("font_size", int(12 * _font_scale))
	_hover_label.add_theme_stylebox_override("normal", _make_tooltip_style())
	_bg_panel.add_child(_hover_label)

	# Re-render on viewport resize so the map area scales with the window.
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)

	_update_title()

func _make_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.20, 0.95)
	style.border_color = Color(0.60, 0.70, 0.90)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	return style

func _build_legend() -> void:
	# Legend is anchored to the top-right of the bg_panel so it scales
	# with the screen. Children are positioned in legend-local coords.
	var legend_w: float = 170 * _font_scale
	var legend_h: float = 260 * _font_scale
	_legend_panel = Panel.new()
	_legend_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_legend_panel.offset_left = -legend_w - 20 * _font_scale
	_legend_panel.offset_right = -20 * _font_scale
	_legend_panel.offset_top = 60 * _font_scale
	_legend_panel.offset_bottom = 60 * _font_scale + legend_h
	_legend_panel.z_index = 50

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.90)
	style.border_color = Color(0.30, 0.35, 0.45)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	_legend_panel.add_theme_stylebox_override("panel", style)
	_bg_panel.add_child(_legend_panel)

	var title := Label.new()
	title.text = "LEGEND"
	title.position = Vector2(8, 4)
	title.size = Vector2(legend_w - 16, 16)
	title.add_theme_color_override("font_color", Color(0.78, 0.82, 0.92))
	title.add_theme_font_size_override("font_size", int(11 * _font_scale))
	_legend_panel.add_child(title)

	var items := [
		["You", PLAYER_COLOR],
		["Staff", STAFF_COLOR],
		["Customer", NPC_COLOR],
		["Robo-Cleaner", ROBOT_COLORS["cleaner"]],
		["Robo-Guide", ROBOT_COLORS["guide"]],
		["Robo-Security", ROBOT_COLORS["security"]],
		["Robo-Shelf", ROBOT_COLORS["shelf"]],
		["Robo-Delivery", ROBOT_COLORS["delivery"]],
		["Elevator", Color(0.60, 0.78, 0.95)],
		["Stairs", Color(0.55, 0.45, 0.60)],
	]
	var y_offset: float = 24.0
	for item in items:
		var dot := ColorRect.new()
		dot.position = Vector2(10, y_offset + 2)
		dot.size = Vector2(10, 10)
		dot.color = item[1]
		_legend_panel.add_child(dot)

		var lbl := Label.new()
		lbl.text = item[0]
		lbl.position = Vector2(26, y_offset)
		lbl.size = Vector2(legend_w - 30, 14)
		lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.90))
		lbl.add_theme_font_size_override("font_size", int(10 * _font_scale))
		_legend_panel.add_child(lbl)
		y_offset += 18

	# Hint
	var hint := Label.new()
	hint.text = "M / ESC: close"
	hint.position = Vector2(8, legend_h - 22)
	hint.size = Vector2(legend_w - 16, 14)
	hint.add_theme_color_override("font_color", Color(0.50, 0.55, 0.60))
	hint.add_theme_font_size_override("font_size", int(10 * _font_scale))
	_legend_panel.add_child(hint)

func _update_title() -> void:
	if _title_label == null:
		return
	var fd = FloorConfig.get_floor(_floor_idx)
	var floor_name := "Ground Floor" if _floor_idx == 0 else "Floor %d" % _floor_idx
	if fd != null and fd.label != null and fd.label != "":
		floor_name = "%s — %s" % [floor_name, fd.label]
	_title_label.text = "%s  •  %d zones  (M to close)" % [floor_name, _count_zones_for_floor()]

func _count_zones_for_floor() -> int:
	var fd = FloorConfig.get_floor(_floor_idx)
	return fd.zones.size() if fd != null else 0

# ─── Rendering ──────────────────────────────────────────────────────

func _on_viewport_resized() -> void:
	# Re-render with the new layout-derived size.
	if visible and _map_clip != null:
		_render()

func _get_fallback_map_size() -> Vector2:
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	return Vector2(viewport_rect.size.x - 240 * _font_scale, viewport_rect.size.y - 100 * _font_scale)

func _render() -> void:
	_clear_map_children()
	if _map_clip == null:
		return
	var fd = FloorConfig.get_floor(_floor_idx)
	if fd == null:
		return
	_update_title()

	# Children of _map_clip are in _map_clip-local coords. Use the clip's
	# current laid-out size so the map scales with the screen.
	_map_rect = Rect2(Vector2.ZERO, _map_clip.size)
	if _map_rect.size.x <= 1 or _map_rect.size.y <= 1:
		# Layout hasn't been resolved yet — try again next frame.
		_map_rect = Rect2(Vector2.ZERO, _get_fallback_map_size())

	# Compute the floor's tile bounds (tight to the actual zones) so we can
	# project them into the map area with no wasted whitespace.
	_floor_bounds = _compute_floor_bounds(fd)
	if _floor_bounds.size.x <= 0 or _floor_bounds.size.y <= 0:
		return

	# Background
	var bg := ColorRect.new()
	bg.name = "MapBg"
	bg.position = _map_rect.position
	bg.size = _map_rect.size
	bg.color = Color(0.06, 0.06, 0.10, 0.85)
	bg.z_index = 0
	_map_clip.add_child(bg)
	_map_children.append(bg)

	# Grid
	_draw_grid(fd)

	# Zones (filled rectangles)
	_draw_zones(fd)

	# Sections (outlined rectangles)
	_draw_sections(fd)

	# Actors on this floor
	_draw_actors()

func _compute_floor_bounds(fd) -> Rect2:
	var min_x := 0.0
	var min_y := 0.0
	var max_x := 0.0
	var max_y := 0.0
	var has_any := false
	for z in fd.zones:
		if z.x < min_x or not has_any: min_x = z.x
		if z.y < min_y or not has_any: min_y = z.y
		if z.x + z.w > max_x or not has_any: max_x = z.x + z.w
		if z.y + z.h > max_y or not has_any: max_y = z.y + z.h
		has_any = true
	if not has_any:
		return Rect2(0, 0, 0, 0)
	# Pad so zone borders aren't clipped
	return Rect2(min_x - 1, min_y - 1, (max_x - min_x) + 2, (max_y - min_y) + 2)

func _tile_to_map(tile_pos: Vector2) -> Vector2:
	# Floor-local tile coords -> map panel-local pixel coords
	var fx: float = (tile_pos.x - _floor_bounds.position.x) / _floor_bounds.size.x
	var fy: float = 1.0 - (tile_pos.y - _floor_bounds.position.y) / _floor_bounds.size.y
	return Vector2(
		_map_rect.position.x + fx * _map_rect.size.x,
		_map_rect.position.y + fy * _map_rect.size.y
	)

func _tile_size_to_map(tile_size: Vector2) -> Vector2:
	return Vector2(
		(tile_size.x / _floor_bounds.size.x) * _map_rect.size.x,
		(tile_size.y / _floor_bounds.size.y) * _map_rect.size.y
	)

func _draw_grid(_fd) -> void:
	# Subtle grid every 4 tiles
	var step: int = 4
	var gx_start: int = int(floor(_floor_bounds.position.x / step)) * step
	var gy_start: int = int(floor(_floor_bounds.position.y / step)) * step
	var gx_end: int = int(ceil((_floor_bounds.position.x + _floor_bounds.size.x) / step)) * step
	var gy_end: int = int(ceil((_floor_bounds.position.y + _floor_bounds.size.y) / step)) * step
	for gx in range(gx_start, gx_end + 1, step):
		var p: Vector2 = _tile_to_map(Vector2(gx, _floor_bounds.position.y))
		var line := ColorRect.new()
		line.position = Vector2(p.x, _map_rect.position.y)
		line.size = Vector2(1, _map_rect.size.y)
		line.color = Color(0.18, 0.20, 0.26, 0.40)
		line.z_index = 1
		_map_clip.add_child(line)
		_map_children.append(line)
	for gy in range(gy_start, gy_end + 1, step):
		var p2: Vector2 = _tile_to_map(Vector2(_floor_bounds.position.x, gy))
		var line2 := ColorRect.new()
		line2.position = Vector2(_map_rect.position.x, p2.y)
		line2.size = Vector2(_map_rect.size.x, 1)
		line2.color = Color(0.18, 0.20, 0.26, 0.40)
		line2.z_index = 1
		_map_clip.add_child(line2)
		_map_children.append(line2)

func _draw_zones(fd) -> void:
	# Build a draw order: base walkable zones (Lobby/Common/Parking/etc.) first,
	# then everything else on top. This way food stalls, service desks, and
	# other detail zones sit visibly on top of the lobby floor instead of
	# being hidden underneath it.
	var ordered_zones: Array = []
	for zone in fd.zones:
		var ztype: String = zone.get("type", "")
		var norm: String = _normalize_zone_type(ztype)
		if _ZONE_BASE.has(norm):
			ordered_zones.insert(0, zone)
		else:
			ordered_zones.append(zone)

	# Render zones. zmeta can be either a Dictionary (legacy) or absent (when JSON had no meta).
	for zone in ordered_zones:
		var ztype: String = zone.get("type", "")
		var zx: int = zone.get("x", 0)
		var zy: int = zone.get("y", 0)
		var zw: int = zone.get("w", 0)
		var zh: int = zone.get("h", 0)
		var zmeta: Dictionary = zone.get("meta", {})

		var color := _color_for_zone(ztype, zmeta, fd.ambient_color)
		var display_name := _name_for_zone(ztype, zmeta)
		var norm: String = _normalize_zone_type(ztype)
		# Compare against the normalized JSON keys (e.g. "elevator"), not
		# the FloorConfig constant values (e.g. "elevator_shaft"), which
		# don't always line up.
		var is_transport := norm in ["elevator", "stairs", "escalator"]
		var is_base := _ZONE_BASE.has(norm)

		# Filled rectangle
		var rect_pos: Vector2 = _tile_to_map(Vector2(zx, zy + zh))  # +zh because map Y inverts
		var rect_size: Vector2 = _tile_size_to_map(Vector2(zw, zh))
		var fill := ColorRect.new()
		fill.position = rect_pos
		fill.size = rect_size
		fill.color = color
		fill.z_index = 10
		_map_clip.add_child(fill)
		_map_children.append(fill)

		# Base layers don't get a per-zone border (their job is the floor).
		if is_base:
			continue

		# Border (thicker for transport + named zones, hairline for floor)
		var border_color := Color(color.r * 1.1, color.g * 1.1, color.b * 1.1, 0.85)
		var border_w: float = 1.0 if not is_transport and display_name == "" else 2.0
		var border := ColorRect.new()
		border.position = rect_pos
		border.size = Vector2(rect_size.x, border_w)
		border.color = border_color
		border.z_index = 11
		_map_clip.add_child(border)
		_map_children.append(border)
		var border2 := ColorRect.new()
		border2.position = Vector2(rect_pos.x, rect_pos.y + rect_size.y - border_w)
		border2.size = Vector2(rect_size.x, border_w)
		border2.color = border_color
		border2.z_index = 11
		_map_clip.add_child(border2)
		_map_children.append(border2)
		var border3 := ColorRect.new()
		border3.position = rect_pos
		border3.size = Vector2(border_w, rect_size.y)
		border3.color = border_color
		border3.z_index = 11
		_map_clip.add_child(border3)
		_map_children.append(border3)
		var border4 := ColorRect.new()
		border4.position = Vector2(rect_pos.x + rect_size.x - border_w, rect_pos.y)
		border4.size = Vector2(border_w, rect_size.y)
		border4.color = border_color
		border4.z_index = 11
		_map_clip.add_child(border4)
		_map_children.append(border4)

		# Label inside the rect, only if it fits
		if display_name != "" and rect_size.x > 30 * _font_scale and rect_size.y > 12 * _font_scale:
			var lbl := Label.new()
			lbl.text = display_name
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.position = Vector2(rect_pos.x, rect_pos.y + rect_size.y / 2 - 6 * _font_scale)
			lbl.size = Vector2(rect_size.x, 12 * _font_scale)
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
			lbl.add_theme_font_size_override("font_size", int(9 * _font_scale))
			lbl.z_index = 12
			_map_clip.add_child(lbl)
			_map_children.append(lbl)

func _draw_sections(fd) -> void:
	# Section rectangles: outlined only, drawn on top of zones
	if not "section_zones" in fd or fd.section_zones == null:
		return
	for s in fd.section_zones:
		var sx: int = s.get("x", 0)
		var sy: int = s.get("y", 0)
		var sw: int = s.get("w", 0)
		var sh: int = s.get("h", 0)
		var sid: String = s.get("id", "")
		var rect_pos: Vector2 = _tile_to_map(Vector2(sx, sy + sh))
		var rect_size: Vector2 = _tile_size_to_map(Vector2(sw, sh))
		# Outline (white-ish, semi-transparent)
		var outline_color := Color(1.0, 0.95, 0.70, 0.85)
		var border_w: float = 1.0
		var t := ColorRect.new()
		t.position = rect_pos
		t.size = Vector2(rect_size.x, border_w)
		t.color = outline_color
		t.z_index = 20
		_map_clip.add_child(t)
		_map_children.append(t)
		var b := ColorRect.new()
		b.position = Vector2(rect_pos.x, rect_pos.y + rect_size.y - border_w)
		b.size = Vector2(rect_size.x, border_w)
		b.color = outline_color
		b.z_index = 20
		_map_clip.add_child(b)
		_map_children.append(b)
		var l := ColorRect.new()
		l.position = rect_pos
		l.size = Vector2(border_w, rect_size.y)
		l.color = outline_color
		l.z_index = 20
		_map_clip.add_child(l)
		_map_children.append(l)
		var r := ColorRect.new()
		r.position = Vector2(rect_pos.x + rect_size.x - border_w, rect_pos.y)
		r.size = Vector2(border_w, rect_size.y)
		r.color = outline_color
		r.z_index = 20
		_map_clip.add_child(r)
		_map_children.append(r)
		# Section label
		if rect_size.x > 30 * _font_scale:
			var lbl := Label.new()
			lbl.text = sid.to_upper().replace("_", " ")
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.position = Vector2(rect_pos.x, rect_pos.y + 1)
			lbl.size = Vector2(rect_size.x, 10 * _font_scale)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75, 0.95))
			lbl.add_theme_font_size_override("font_size", int(8 * _font_scale))
			lbl.z_index = 21
			_map_clip.add_child(lbl)
			_map_children.append(lbl)

func _draw_actors() -> void:
	# Player
	if _player_ref != null and is_instance_valid(_player_ref):
		var ppos: Vector2 = _player_pos(_player_ref)
		_add_actor_dot(ppos, PLAYER_COLOR, "YOU", 8 * _font_scale, null, true)

	# NPCs (filtered to this floor)
	var npcs: Array = _main_ref.get("_npcs") if _main_ref != null else []
	if npcs == null:
		npcs = []
	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		if not _actor_on_current_floor(npc):
			continue
		var actor: Dictionary = _actor_meta(npc)
		var is_staff: bool = actor.get("is_staff", false)
		var color: Color = STAFF_COLOR if is_staff else NPC_COLOR
		var name_str: String = actor.get("name", "NPC")
		_add_actor_dot(npc.position, color, name_str, 5 * _font_scale, npc, false)

	# Robots
	var robots: Array = _main_ref.get("_robots") if _main_ref != null else []
	if robots == null:
		robots = []
	for robot in robots:
		if not is_instance_valid(robot):
			continue
		if not _actor_on_current_floor(robot):
			continue
		var role: String = _robot_role(robot)
		var color: Color = ROBOT_COLORS.get(role, ROBOT_COLORS["unknown"])
		var name_str: String = _robot_name(robot, role)
		_add_actor_dot(robot.position, color, name_str, 5 * _font_scale, robot, false)

func _add_actor_dot(world_pos: Vector2, color: Color, label: String, size: float, ref, is_player: bool) -> void:
	var tile_pos: Variant = _world_to_floor_tile(world_pos)
	if tile_pos == null:
		return
	if not (tile_pos is Vector2):
		return
	var map_pos: Vector2 = _tile_to_map(tile_pos)
	if not _map_rect.has_point(map_pos):
		return

	# Outer dot wrapper for hover detection
	var hit := Control.new()
	hit.name = "ActorDot"
	hit.position = Vector2(map_pos.x - size / 2, map_pos.y - size / 2)
	hit.size = Vector2(size, size)
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.z_index = 30
	_map_clip.add_child(hit)
	_map_children.append(hit)

	var dot := ColorRect.new()
	dot.name = "Dot"
	dot.position = Vector2.ZERO
	dot.size = Vector2(size, size)
	dot.color = color
	hit.add_child(dot)
	_map_children.append(dot)

	# Outline
	var outline_color := Color(0, 0, 0, 0.55)
	var outline_w: float = 1.0
	for side in [
		{"pos": Vector2(-outline_w, -outline_w), "size": Vector2(size + 2 * outline_w, outline_w)},
		{"pos": Vector2(-outline_w, size), "size": Vector2(size + 2 * outline_w, outline_w)},
		{"pos": Vector2(-outline_w, 0), "size": Vector2(outline_w, size)},
		{"pos": Vector2(size, 0), "size": Vector2(outline_w, size)},
	]:
		var b := ColorRect.new()
		b.position = side["pos"]
		b.size = side["size"]
		b.color = outline_color
		hit.add_child(b)
		_map_children.append(b)

	# Small label (player only — too noisy for everyone)
	if is_player:
		var lbl := Label.new()
		lbl.text = label
		lbl.position = Vector2(-6 * _font_scale, -14 * _font_scale)
		lbl.size = Vector2(size + 12 * _font_scale, 10 * _font_scale)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", color)
		lbl.add_theme_font_size_override("font_size", int(8 * _font_scale))
		hit.add_child(lbl)
		_map_children.append(lbl)

	# Hover handlers (skip player)
	if not is_player and ref != null:
		hit.gui_input.connect(_on_actor_hover.bind(label, hit, map_pos))

func _on_actor_hover(event: InputEvent, label: String, hit: Control, map_pos: Vector2) -> void:
	if event is InputEventMouseMotion:
		_show_hover(label, map_pos, hit)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_hide_hover()

func _show_hover(text: String, map_pos: Vector2, hit: Control) -> void:
	if _hover_label == null or _bg_panel == null:
		return
	_hover_label.text = "  %s  " % text
	_hover_label.visible = true
	# map_pos is in _map_clip-local coords. _hover_label lives on _bg_panel,
	# so convert by adding the map clip's position inside the panel.
	var clip_local_pos: Vector2 = map_pos
	if _map_clip != null:
		clip_local_pos += _map_clip.position
	var pos: Vector2 = clip_local_pos + Vector2(12 * _font_scale, -24 * _font_scale)
	var panel_size: Vector2 = _bg_panel.size if _bg_panel else Vector2(800, 600)
	pos.x = clampf(pos.x, 4, panel_size.x - 140)
	pos.y = clampf(pos.y, 30 * _font_scale, panel_size.y - 24)
	_hover_label.position = pos
	_hovered_actor_dot = hit

func _hide_hover() -> void:
	if _hover_label != null:
		_hover_label.visible = false
	_hovered_actor_dot = null

# ─── Coordinate / classification helpers ────────────────────────────

func _world_to_floor_tile(world_pos: Vector2) -> Variant:
	# World (px) -> floor-local tile coordinates.
	if _floor_idx < 0 or _floor_idx >= FloorConfig.floor_count():
		return null
	var floor_y: float = FloorManagerScript.get_floor_y(_floor_idx)
	var local_x_tiles: float = world_pos.x / CELL_SIZE
	var local_y_tiles: float = (world_pos.y - floor_y) / CELL_SIZE
	if local_y_tiles < -1 or local_y_tiles > 200:
		return null
	return Vector2(local_x_tiles, local_y_tiles)

func _actor_on_current_floor(actor) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	var floor_y: float = FloorManagerScript.get_floor_y(_floor_idx)
	# Each floor is 160 tiles tall, but actors may roam in a slightly larger area
	var top: float = floor_y - CELL_SIZE
	var bot: float = floor_y + 162 * CELL_SIZE
	return actor.position.y >= top and actor.position.y < bot

func _player_pos(player) -> Vector2:
	if player.has_method("get_global_position"):
		return player.get_global_position()
	if "global_position" in player:
		return player.global_position
	return player.position

func _actor_meta(actor) -> Dictionary:
	# Pulls display_name + role/staff from the actor's controller
	var name_str: String = ""
	var is_staff: bool = false
	if actor.has_method("get_actor"):
		var a = actor.get_actor()
		if a != null:
			name_str = str(a.display_name) if a.display_name != null else ""
			var role_val: int = int(a.role) if a.role != null else -1
			# 0=CUSTOMER, 1=STAFF, 2=ROBOT typically
			is_staff = (role_val == 1)
	if name_str == "":
		name_str = str(actor.name) if actor.name != null else "Actor"
	return {"name": name_str, "is_staff": is_staff}

func _robot_role(robot) -> String:
	if robot == null:
		return "unknown"
	if robot.has_method("get_actor"):
		var a = robot.get_actor()
		if a != null:
			match int(a.robot_role):
				0: return "cleaner"
				1: return "guide"
				2: return "delivery"
				3: return "security"
				4: return "shelf"
	var robot_name: String = str(robot.name).to_lower() if robot.name != null else ""
	if "cleaner" in robot_name: return "cleaner"
	if "guide" in robot_name: return "guide"
	if "security" in robot_name: return "security"
	if "shelf" in robot_name: return "shelf"
	if "delivery" in robot_name: return "delivery"
	if "humanoid" in robot_name or "robo-" in robot_name: return "humanoid"
	return "unknown"

func _robot_name(robot, role: String) -> String:
	if robot.has_method("get_actor"):
		var a = robot.get_actor()
		if a != null and a.display_name != null and a.display_name != "":
			return str(a.display_name)
	return "Robot-" + role.capitalize()

# ─── Zone color/name lookup ─────────────────────────────────────────

func _normalize_zone_type(ztype: String) -> String:
	# JSON stores types as "ZONE_FOO"; FloorConfig constants are "foo".
	if ztype.begins_with("ZONE_"):
		return ztype.substr(5).to_lower()
	return ztype.to_lower()

func _color_for_zone(ztype: String, zmeta: Dictionary, ambient: Color) -> Color:
	# 1. meta.color wins when present — use a high alpha so the named zone
	#    is clearly visible against the walkable base.
	if zmeta != null and zmeta.has("color"):
		var c = zmeta["color"]
		if c is Color:
			return Color(c.r, c.g, c.b, 0.92)
		if c is Array and c.size() >= 3:
			return Color(c[0], c[1], c[2], 0.92)
	# 2. Fall back to the per-type table so every zone has a visible fill.
	var norm: String = _normalize_zone_type(ztype)
	if _ZONE_COLORS.has(norm):
		return _ZONE_COLORS[norm]
	# 3. Last resort: dim ambient, but at a visible alpha.
	return Color(ambient.r * 0.9, ambient.g * 0.9, ambient.b * 0.9, 0.55)

func _name_for_zone(ztype: String, zmeta: Dictionary) -> String:
	if zmeta != null and zmeta.has("name"):
		var n: String = str(zmeta["name"])
		if n != "ad_color" and n != "":
			return n.to_upper()
	var norm: String = _normalize_zone_type(ztype)
	if _ZONE_NAMES.has(norm):
		return _ZONE_NAMES[norm]
	return ""

# ─── Cleanup ────────────────────────────────────────────────────────

func _clear_map_children() -> void:
	for c in _map_children:
		if is_instance_valid(c):
			c.queue_free()
	_map_children.clear()

# ─── Input ──────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not visible:
		return
	# Track mouse over the panel for hover-tooltips on actor dots
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var over_actor := false
	for c in _map_children:
		if not is_instance_valid(c):
			continue
		if c.name == "ActorDot":
			var r := Rect2(c.global_position, c.size)
			if r.has_point(mouse_pos):
				over_actor = true
				break
	if not over_actor:
		_hide_hover()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
			close()
