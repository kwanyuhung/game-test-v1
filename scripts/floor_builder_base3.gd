extends Node2D
class_name FloorBuilder

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")
const FoodStallScript = preload("res://scripts/food_stall.gd")
const ClawMachineScript = preload("res://scripts/claw_machine.gd")

const CELL_SIZE = 16
const WORLD_W  = 96
const WORLD_H  = 50

var _parent: Node2D
var _floor_nodes: Array = []
var _sections: Array = []
var _food_stalls: Array = []
var _claw_machines: Array = []
var _checkout_counters: Array = []
var _floor_def  # FloorConfig 类型

func _build_zone_vending_machine(zone: FloorConfig.Zone) -> void:
	var name: String = zone.meta.get("name", "VENDING")
	var items: Array = zone.meta.get("items", ["Water $1.50", "Cola $2.00"])
	var cx := zone.x * CELL_SIZE; var cy := zone.y * CELL_SIZE
	var cw := zone.w * CELL_SIZE; var ch := zone.h * CELL_SIZE

	# Vending machine body (glass front)
	var body := ColorRect.new(); body.position = Vector2(cx, cy); body.size = Vector2(cw, ch)
	body.color = Color(0.25, 0.28, 0.32); _parent.add_child(body); _floor_nodes.append(body)

	# Glass front panel
	var glass := ColorRect.new()
	glass.position = Vector2(cx + 2, cy + 2); glass.size = Vector2(cw - 4, ch * 0.70)
	glass.color = Color(0.15, 0.18, 0.22).lightened(0.15); _parent.add_child(glass); _floor_nodes.append(glass)

	# Machine frame border
	var frame_top := ColorRect.new(); frame_top.position = Vector2(cx, cy); frame_top.size = Vector2(cw, 2)
	frame_top.color = Color(0.50, 0.50, 0.55); _parent.add_child(frame_top); _floor_nodes.append(frame_top)
	var frame_bot := ColorRect.new(); frame_bot.position = Vector2(cx, cy + ch - 2); frame_bot.size = Vector2(cw, 2)
	frame_bot.color = Color(0.40, 0.40, 0.45); _parent.add_child(frame_bot); _floor_nodes.append(frame_bot)

	# Product items inside glass (small colored rectangles)
	var item_colors := [Color(0.40, 0.70, 0.90), Color(0.85, 0.30, 0.30), Color(0.80, 0.75, 0.30),
			Color(0.90, 0.65, 0.30), Color(0.60, 0.40, 0.25), Color(0.30, 0.80, 0.50)]
	for row in range(2):
		for col in range(mini(3, items.size())):
			var ix := cx + 4 + col * ((cw - 8) / 3.0)
			var iy := cy + 4 + row * (ch * 0.35)
			var slot := ColorRect.new()
			slot.position = Vector2(ix, iy); slot.size = Vector2((cw - 8) / 3.5, ch * 0.30)
			slot.color = item_colors[(row * 3 + col) % item_colors.size()]
			_parent.add_child(slot); _floor_nodes.append(slot)

	# Coin slot / control panel at bottom
	var panel := ColorRect.new()
	panel.position = Vector2(cx + 2, cy + ch * 0.72); panel.size = Vector2(cw - 4, ch * 0.25)
	panel.color = Color(0.20, 0.22, 0.26); _parent.add_child(panel); _floor_nodes.append(panel)

	# Slot opening
	var slot := ColorRect.new()
	slot.position = Vector2(cx + cw * 0.35, cy + ch * 0.75)
	slot.size = Vector2(cw * 0.12, ch * 0.08)
	slot.color = Color(0.10, 0.10, 0.12); _parent.add_child(slot); _floor_nodes.append(slot)

	# Label above machine
	var tl := Label.new(); tl.text = name
	tl.position = Vector2(cx + 2, cy - 12)
	tl.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
	tl.add_theme_font_size_override("font_size", 8)
	_parent.add_child(tl); _floor_nodes.append(tl)

	# Hint
	var hint := Label.new(); hint.text = "[E] Buy Snacks"
	hint.position = Vector2(cx + 2, cy + ch + 2)
	hint.add_theme_color_override("font_color", Color(0.60, 0.65, 0.70))
	hint.add_theme_font_size_override("font_size", 7)
	_parent.add_child(hint); _floor_nodes.append(hint)


func get_sections() -> Array:
	return _sections

func get_food_stalls() -> Array:
	return _food_stalls

func get_claw_machines() -> Array:
	return _claw_machines

func get_checkout_counters() -> Array:
	return _checkout_counters

func get_floor_nodes() -> Array:
	return _floor_nodes

# Returns the world position of the price terminal (office_desk zone center)
func get_office_desk_zone_center() -> Vector2:
	if _floor_def == null:
		return Vector2(-1, -1)
	for zone in _floor_def.zones:
		if zone.type == FloorConfig.ZONE_OFFICE_DESK:
			var cx := (zone.x + zone.w * 0.5) * CELL_SIZE
			var cy := (zone.y + zone.h * 0.5) * CELL_SIZE
			return Vector2(cx, cy)
	return Vector2(-1, -1)

# Returns the zone center of a specific zone type (for E-key interaction proximity)
func get_zone_center_by_type(ztype: String) -> Vector2:
	if _floor_def == null:
		return Vector2(-1, -1)
	for zone in _floor_def.zones:
		if zone.type == ztype:
			var cx := (zone.x + zone.w * 0.5) * CELL_SIZE
			var cy := (zone.y + zone.h * 0.5) * CELL_SIZE
			return Vector2(cx, cy)
	return Vector2(-1, -1)

# Returns true if player is within interaction range of a zone type
func is_near_zone_type(ztype: String, player_pos: Vector2, threshold: float = 12.0) -> bool:
	var center = get_zone_center_by_type(ztype)
	if center.x < 0:
		return false
	return player_pos.distance_to(center) < CELL_SIZE * threshold
