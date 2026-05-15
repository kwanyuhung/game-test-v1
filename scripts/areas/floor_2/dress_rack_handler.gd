# dress_rack_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for DRESS RACK zones on Floor 2 (Fashion)
# Draws clothing display areas with racks and clothing sprites
# ─────────────────────────────────────────────────────────────────────────────
class_name DressRackHandler

const CELL_SIZE := 16

static func build_dress_rack(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "DRESSES")
	var zone_color: Color = zone.meta.get("color", Color(0.75, 0.55, 0.70))
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

	# Clothing styles: 0=dress, 1=tshirt, 2=pants, 3=jacket
	var clothing_styles := [0, 1, 2, 3]
	var clothing_colors := [
		zone_color.lightened(0.15),
		zone_color,
		zone_color.darkened(0.2),
		zone_color.darkened(0.1)
	]

	var num_racks := 3
	for rack in range(num_racks):
		var rack_y := cy + 16 + rack * (ch * 0.28)
		var pole := ColorRect.new()
		pole.position = Vector2(cx + 6, rack_y)
		pole.size = Vector2(cw - 12, 2)
		pole.color = Color(0.55, 0.52, 0.48)
		parent.add_child(pole); floor_nodes.append(pole)
		for h in range(7):
			var hanger_x := cx + 10 + h * ((cw - 20) / 7.0)
			# Create clothing sprite instead of abstract rectangle
			var cloth_sprite := Sprite2D.new()
			var style_idx := (rack + h) % clothing_styles.size()
			cloth_sprite.texture = PixelArtGenerator.make_clothing(clothing_colors[style_idx], clothing_styles[style_idx])
			cloth_sprite.position = Vector2(hanger_x + 7, rack_y - 10)
			cloth_sprite.scale = Vector2(1.2, 1.2)
			parent.add_child(cloth_sprite); floor_nodes.append(cloth_sprite)