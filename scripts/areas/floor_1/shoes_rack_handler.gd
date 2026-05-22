# shoes_rack_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for SHOES RACK zones on Floor 1
# Draws shoe display areas with shelves and shoe sprites
# ─────────────────────────────────────────────────────────────────────────────
class_name ShoesRackHandler

const CELL_SIZE := 16

# Zone categories for shoes floor
enum ShoeCategory {
	LADIES,
	MENS,
	KIDS,
	SPORT,
	SANDALS
}

static func get_category_info(category: ShoeCategory) -> Dictionary:
	match category:
		ShoeCategory.LADIES:
			return {"name": "LADIES SHOES", "color": Color(0.82, 0.55, 0.65)}
		ShoeCategory.MENS:
			return {"name": "MENS SHOES", "color": Color(0.55, 0.6, 0.8)}
		ShoeCategory.KIDS:
			return {"name": "KIDS SHOES", "color": Color(0.7, 0.75, 0.9)}
		ShoeCategory.SPORT:
			return {"name": "SPORT SHOES", "color": Color(0.55, 0.8, 0.65)}
		ShoeCategory.SANDALS:
			return {"name": "SANDALS", "color": Color(0.85, 0.72, 0.52)}
		_:
			return {"name": "SHOES", "color": Color(0.7, 0.6, 0.55)}

static func detect_category(zone_name: String) -> ShoeCategory:
	var lower := zone_name.to_lower()
	if lower.contains("ladies") or lower.contains("women"):
		return ShoeCategory.LADIES
	elif lower.contains("mens") or lower.contains("men"):
		return ShoeCategory.MENS
	elif lower.contains("kids") or lower.contains("children"):
		return ShoeCategory.KIDS
	elif lower.contains("sport") or lower.contains("athletic"):
		return ShoeCategory.SPORT
	elif lower.contains("sandal"):
		return ShoeCategory.SANDALS
	return ShoeCategory.LADIES

static func build_shoes_rack(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var zone_name: String = zone.get("meta", {}).get("name", "SHOES")
	var zone_color: Color = zone.get("meta", {}).get("color", Color(0.70, 0.60, 0.55))
	
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Detect category from zone name
	var category := detect_category(zone_name)
	var info := get_category_info(category)
	zone_color = info.color
	
	# Background
	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.3)
	parent.add_child(bg)
	floor_nodes.append(bg)
	
	# Title label
	var title_lbl := Label.new()
	title_lbl.text = info.name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	title_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(title_lbl)
	floor_nodes.append(title_lbl)
	
	# Build shelves with shoes
	var shoe_styles := [0, 1, 2, 3]  # 0=sneaker, 1=formal, 2=sandal, 3=boot
	var shoe_colors := [
		zone_color.lightened(0.2),
		zone_color,
		zone_color.darkened(0.15),
		Color(0.35, 0.28, 0.22)
	]
	
	for row in range(4):
		var shelf_y: int = cy + 8 + row * int(ch * 0.22)
		var plank := ColorRect.new()
		plank.position = Vector2(cx + 4, shelf_y)
		plank.size = Vector2(cw - 8, 2)
		plank.color = zone_color.darkened(0.4)
		parent.add_child(plank)
		floor_nodes.append(plank)
		
		for col in range(6):
			var box_x: int = cx + 8 + col * int((cw - 16) / 6.0)
			var shoe_sprite := Sprite2D.new()
			shoe_sprite.texture = _make_shoe(zone_color, row % 4)
			shoe_sprite.position = Vector2(box_x + int((cw - 16) / 12.0), shelf_y - 6)
			shoe_sprite.scale = Vector2(1.0, 1.0)
			parent.add_child(shoe_sprite)
			floor_nodes.append(shoe_sprite)
	
	# Add category-specific decorations
	_add_category_decorations(parent, floor_nodes, cx, cy, cw, ch, category, zone_color)

static func _add_category_decorations(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, category: ShoeCategory, zone_color: Color) -> void:
	match category:
		ShoeCategory.LADIES:
			# Add a mirror/vanity area
			var mirror_bg := ColorRect.new()
			mirror_bg.position = Vector2(cx + cw - 40, cy + 20)
			mirror_bg.size = Vector2(30, 50)
			mirror_bg.color = Color(0.2, 0.18, 0.22)
			parent.add_child(mirror_bg)
			floor_nodes.append(mirror_bg)
			
			var mirror_frame := ColorRect.new()
			mirror_frame.position = Vector2(cx + cw - 38, cy + 22)
			mirror_frame.size = Vector2(26, 46)
			mirror_frame.color = Color(0.85, 0.75, 0.8)
			parent.add_child(mirror_frame)
			floor_nodes.append(mirror_frame)
		
		ShoeCategory.SPORT:
			# Add sports equipment display
			var display_bg := ColorRect.new()
			display_bg.position = Vector2(cx + 8, cy + ch - 30)
			display_bg.size = Vector2(60, 20)
			display_bg.color = zone_color.darkened(0.2)
			parent.add_child(display_bg)
			floor_nodes.append(display_bg)
			
			var label := Label.new()
			label.text = "ATHLETIC GEAR"
			label.position = Vector2(cx + 12, cy + ch - 26)
			label.add_theme_color_override("font_color", zone_color.lightened(0.4))
			label.add_theme_font_size_override("font_size", 6)
			parent.add_child(label)
			floor_nodes.append(label)
		
		ShoeCategory.KIDS:
			# Add colorful kid-friendly decorations
			var play_mat := ColorRect.new()
			play_mat.position = Vector2(cx + cw - 50, cy + ch - 40)
			play_mat.size = Vector2(40, 30)
			play_mat.color = Color(0.6, 0.8, 0.6)
			parent.add_child(play_mat)
			floor_nodes.append(play_mat)
			
			var kids_sign := Label.new()
			kids_sign.text = "KIDS CORNER"
			kids_sign.position = Vector2(cx + cw - 48, cy + ch - 36)
			kids_sign.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
			kids_sign.add_theme_font_size_override("font_size", 5)
			parent.add_child(kids_sign)
			floor_nodes.append(kids_sign)

static func _make_shoe(base_color: Color, style: int) -> Texture2D:
	var W := 16
	var H := 12
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	match style:
		0:  # Sneaker
			# Sole
			for y in range(H - 3, H):
				for x in range(2, W - 2):
					img.set_pixel(x, y, Color(0.9, 0.9, 0.9))
			# Upper
			for y in range(2, H - 3):
				for x in range(2, W - 2):
					img.set_pixel(x, y, base_color)
			# Toe cap
			for y in range(3, 6):
				for x in range(W - 5, W - 2):
					img.set_pixel(x, y, base_color.lightened(0.15))
			# Laces area
			for y in range(4, 7):
				for x in range(4, W - 6):
					img.set_pixel(x, y, base_color.darkened(0.2))
		
		1:  # Formal shoe
			# Dark sole
			for y in range(H - 2, H):
				for x in range(1, W - 1):
					img.set_pixel(x, y, Color(0.15, 0.12, 0.1))
			# Upper
			for y in range(2, H - 2):
				for x in range(1, W - 1):
					img.set_pixel(x, y, base_color)
			# Toe curve
			for x in range(W - 4, W - 1):
				img.set_pixel(x, 3, base_color.darkened(0.1))
				img.set_pixel(x, 4, base_color.darkened(0.1))
		
		2:  # Sandal
			# Sole
			for y in range(H - 3, H):
				for x in range(3, W - 3):
					img.set_pixel(x, y, base_color.darkened(0.2))
			# Straps
			for x in range(4, 7):
				img.set_pixel(x, 3, base_color)
				img.set_pixel(x, 5, base_color)
			for x in range(W - 7, W - 4):
				img.set_pixel(x, 3, base_color)
				img.set_pixel(x, 5, base_color)
		
		3:  # Boot
			# Boot shaft
			for y in range(0, H - 4):
				for x in range(3, W - 3):
					img.set_pixel(x, y, base_color)
			# Boot sole
			for y in range(H - 4, H):
				for x in range(2, W - 2):
					img.set_pixel(x, y, Color(0.2, 0.15, 0.1))
			# Boot top rim
			for x in range(3, W - 3):
				img.set_pixel(x, 0, base_color.lightened(0.2))
	
	return ImageTexture.create_from_image(img)
