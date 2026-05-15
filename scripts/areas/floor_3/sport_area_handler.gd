# sport_area_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for SPORT AREA zones on Floor 3
# Draws sports equipment display areas with shelves and sports item sprites
# ─────────────────────────────────────────────────────────────────────────────
class_name SportAreaHandler

const CELL_SIZE := 16

static func build_sport_area(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "SPORT")
	var zone_color: Color = zone.meta.get("color", Color(0.50, 0.65, 0.75))
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
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	title_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(title_lbl); floor_nodes.append(title_lbl)

	# Sports equipment styles: 0=dumbbell, 1=ball, 2=yogamat, 3=racket, 4=helmet
	var equipment_styles := [0, 1, 2, 3, 4]
	var equip_colors := [
		Color(0.45, 0.58, 0.68),
		Color(0.80, 0.45, 0.45),  # red ball
		Color(0.55, 0.78, 0.68),  # green mat
		Color(0.90, 0.85, 0.40),   # yellow racket
		Color(0.35, 0.45, 0.65)    # blue helmet
	]

	var shelf_colors := [Color(0.45, 0.58, 0.68), Color(0.58, 0.52, 0.62), Color(0.52, 0.68, 0.58)]
	for row in range(3):
		var shelf_y := cy + 12 + row * (ch * 0.28)
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 4, shelf_y)
		plank.size = Vector2(cw - 8, 2)
		plank.color = shelf_colors[row % 3].darkened(0.3)
		parent.add_child(plank); floor_nodes.append(plank)
		# Place sports equipment on shelf
		for col in range(5):
			var equip_x := cx + 10 + col * ((cw - 20) / 5.0)
			var equip_sprite := Sprite2D.new()
			var style_idx := (row + col) % equipment_styles.size()
			equip_sprite.texture = PixelArtGenerator.make_sports_equipment(equip_colors[style_idx], equipment_styles[style_idx])
			equip_sprite.position = Vector2(equip_x + 8, shelf_y - 8)
			equip_sprite.scale = Vector2(1.0, 1.0)
			parent.add_child(equip_sprite); floor_nodes.append(equip_sprite)