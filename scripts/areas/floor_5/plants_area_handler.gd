# plants_area_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for PLANTS AREA zones on Floor 5
# Displays indoor and garden plants
# ─────────────────────────────────────────────────────────────────────────────
class_name PlantsAreaHandler

const CELL_SIZE := 16

static func build_plants_area(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "PLANTS")
	var zone_color: Color = zone.meta.get("color", Color(0.55, 0.82, 0.60))
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

	# Add plant displays
	_add_plant_displays(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_plant_displays(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Add rows of plant pots
	for row in range(3):
		var plant_y := cy + 30 + row * int(ch * 0.22)
		for col in range(4):
			var plant_x := cx + 20 + col * int((cw - 40) / 4.0)
			
			# Pot
			var pot := ColorRect.new()
			pot.position = Vector2(plant_x, plant_y)
			pot.size = Vector2(16, 12)
			pot.color = Color(0.60, 0.45, 0.30)
			parent.add_child(pot); floor_nodes.append(pot)
			
			# Plant foliage
			var foliage := ColorRect.new()
			foliage.position = Vector2(plant_x - 2, plant_y - 14)
			foliage.size = Vector2(20, 16)
			foliage.color = zone_color.lightened(0.1 + (row % 2) * 0.1)
			parent.add_child(foliage); floor_nodes.append(foliage)