# outdoor_area_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for OUTDOOR AREA zones on Floor 4
# Displays outdoor gear and equipment
# ─────────────────────────────────────────────────────────────────────────────
class_name OutdoorAreaHandler

const CELL_SIZE := 16

static func build_outdoor_area(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	# Delegate to generic zone builder with outdoor theme
	_build_generic_outdoor_zone(parent, zone, floor_nodes)

static func _build_generic_outdoor_zone(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "OUTDOOR")
	var zone_color: Color = zone.meta.get("color", Color(0.45, 0.60, 0.40))
	var cx :int= zone.x * CELL_SIZE
	var cy :int= zone.y * CELL_SIZE
	var cw :int= zone.w * CELL_SIZE
	var ch :int= zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.35)
	parent.add_child(bg); floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.25))
	title_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(title_lbl); floor_nodes.append(title_lbl)

	# Add nature-inspired decorations
	_add_nature_elements(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_nature_elements(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Add some decorative elements suggesting outdoor/nature theme
	var shelf_colors := [Color(0.45, 0.60, 0.40), Color(0.55, 0.70, 0.50), Color(0.35, 0.50, 0.35)]
	for row in range(3):
		var shelf_y := cy + 20 + row * int(ch * 0.25)
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 8, shelf_y)
		plank.size = Vector2(cw - 16, 2)
		plank.color = shelf_colors[row % shelf_colors.size()]
		parent.add_child(plank); floor_nodes.append(plank)