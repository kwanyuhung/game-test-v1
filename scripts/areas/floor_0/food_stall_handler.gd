# food_stall_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for FOOD STALL zones on Ground Floor
# Various cuisine stalls with counter and menu boards
# ─────────────────────────────────────────────────────────────────────────────
class_name FoodStallHandler

const CELL_SIZE := 16

# Food stall definitions
static var STALL_DEFS := {
	"jp_ramen": {"name": "Ramen", "cuisine": "Japanese", "color": Color(0.90, 0.70, 0.50), "glow": Color(1.0, 0.85, 0.60)},
	"jp_sushi": {"name": "Sushi", "cuisine": "Japanese", "color": Color(0.80, 0.55, 0.40), "glow": Color(1.0, 0.70, 0.55)},
	"jp_takoyaki": {"name": "Takoyaki", "cuisine": "Japanese", "color": Color(0.85, 0.75, 0.55), "glow": Color(1.0, 0.90, 0.60)},
	"thai": {"name": "Thai Food", "cuisine": "Thai", "color": Color(0.85, 0.70, 0.55), "glow": Color(1.0, 0.80, 0.50)},
	"indian": {"name": "Indian", "cuisine": "Indian", "color": Color(0.90, 0.70, 0.50), "glow": Color(1.0, 0.75, 0.40)},
	"chinese": {"name": "Chinese", "cuisine": "Chinese", "color": Color(0.85, 0.65, 0.45), "glow": Color(1.0, 0.80, 0.45)},
	"korean": {"name": "Korean", "cuisine": "Korean", "color": Color(0.80, 0.60, 0.50), "glow": Color(1.0, 0.70, 0.55)},
	"turkish": {"name": "Turkish", "cuisine": "Turkish", "color": Color(0.85, 0.60, 0.45), "glow": Color(1.0, 0.75, 0.45)},
	"vietnamese": {"name": "Vietnamese", "cuisine": "Vietnamese", "color": Color(0.80, 0.70, 0.50), "glow": Color(0.90, 1.0, 0.55)},
	"italian": {"name": "Italian", "cuisine": "Italian", "color": Color(0.85, 0.55, 0.45), "glow": Color(1.0, 0.65, 0.45)},
	"mexican": {"name": "Mexican", "cuisine": "Mexican", "color": Color(0.85, 0.60, 0.40), "glow": Color(1.0, 0.70, 0.35)},
	"drinks": {"name": "Drinks", "cuisine": "Beverages", "color": Color(0.60, 0.80, 0.90), "glow": Color(0.70, 1.0, 1.0)},
}

static func get_stall_def(stall_id: String) -> Dictionary:
	return STALL_DEFS.get(stall_id, {"name": stall_id, "cuisine": "Other", "color": Color(0.7, 0.7, 0.7), "glow": Color(0.8, 0.8, 0.8)})

static func build_food_stall(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var stall_id: String = zone.get("meta", {}).get("name", "jp_ramen")
	var fd: Dictionary = get_stall_def(stall_id)
	
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	var base_color: Color = fd.get("color", Color(0.85, 0.70, 0.50))
	var glow_color: Color = fd.get("glow", Color(1.0, 0.85, 0.60))
	
	# Base floor
	var base := ColorRect.new()
	base.position = Vector2(cx, cy)
	base.size = Vector2(cw, ch)
	base.color = base_color.darkened(0.78)
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Counter (front of stall)
	var counter := ColorRect.new()
	counter.position = Vector2(cx, cy + ch - 48)
	counter.size = Vector2(cw, 48)
	counter.color = base_color.darkened(0.45)
	parent.add_child(counter)
	floor_nodes.append(counter)
	
	# Counter top (bright edge)
	var counter_top := ColorRect.new()
	counter_top.position = Vector2(cx, cy + ch - 48)
	counter_top.size = Vector2(cw, 4)
	counter_top.color = base_color.lightened(0.25)
	parent.add_child(counter_top)
	floor_nodes.append(counter_top)
	
	# Back wall
	var wall_h: int = ch - 48
	var wc: Color = base_color.darkened(0.3)
	
	var bw_bg := ColorRect.new()
	bw_bg.position = Vector2(cx, cy)
	bw_bg.size = Vector2(cw, wall_h)
	bw_bg.color = wc.darkened(0.1)
	parent.add_child(bw_bg)
	floor_nodes.append(bw_bg)
	
	# Top wall
	var tw := ColorRect.new()
	tw.position = Vector2(cx, cy)
	tw.size = Vector2(cw, 4)
	tw.color = wc
	parent.add_child(tw)
	floor_nodes.append(tw)
	
	# Left wall
	var lw := ColorRect.new()
	lw.position = Vector2(cx, cy)
	lw.size = Vector2(4, ch)
	lw.color = wc.darkened(0.1)
	parent.add_child(lw)
	floor_nodes.append(lw)
	
	# Right wall
	var rw := ColorRect.new()
	rw.position = Vector2(cx + cw - 4, cy)
	rw.size = Vector2(4, ch)
	rw.color = wc.darkened(0.2)
	parent.add_child(rw)
	floor_nodes.append(rw)
	
	# Bottom wall edge
	var bot_wall := ColorRect.new()
	bot_wall.position = Vector2(cx, cy + ch - 4)
	bot_wall.size = Vector2(cw, 4)
	bot_wall.color = wc.darkened(0.2)
	parent.add_child(bot_wall)
	floor_nodes.append(bot_wall)
	
	# Menu board area
	var board_x: int = cx + CELL_SIZE
	var board_y: int = cy + CELL_SIZE
	var board_w: int = cw - CELL_SIZE * 2
	var board_h: int = wall_h - CELL_SIZE * 2
	if board_w > 0 and board_h > 0:
		var board := ColorRect.new()
		board.position = Vector2(board_x, board_y)
		board.size = Vector2(board_w, board_h)
		board.color = Color(0.05, 0.12, 0.08)
		parent.add_child(board)
		floor_nodes.append(board)
		
		# Menu items (text)
		var menu_items := _get_menu_items(stall_id)
		for i in range(mini(3, menu_items.size())):
			var item_lbl := Label.new()
			item_lbl.text = menu_items[i]
			item_lbl.position = Vector2(board_x + 8, board_y + 8 + i * 14)
			item_lbl.add_theme_color_override("font_color", Color(0.80, 0.85, 0.70))
			item_lbl.add_theme_font_size_override("font_size", 6)
			parent.add_child(item_lbl)
			floor_nodes.append(item_lbl)
	
	# Glow sign above stall
	var glow_sprite := Sprite2D.new()
	glow_sprite.position = Vector2(cx + cw / 2, cy - 20)
	glow_sprite.texture = _make_glow(glow_color)
	parent.add_child(glow_sprite)
	floor_nodes.append(glow_sprite)
	
	# Stall name label
	var name_lbl := Label.new()
	name_lbl.text = fd.get("name", stall_id)
	name_lbl.position = Vector2(cx + CELL_SIZE, cy + ch - 38)
	name_lbl.add_theme_color_override("font_color", base_color.lightened(0.35))
	name_lbl.add_theme_font_size_override("font_size", 8)
	parent.add_child(name_lbl)
	floor_nodes.append(name_lbl)
	
	# Cuisine label
	var cuisine_lbl := Label.new()
	cuisine_lbl.text = fd.get("cuisine", "Food")
	cuisine_lbl.position = Vector2(cx + CELL_SIZE, cy + ch - 26)
	cuisine_lbl.add_theme_color_override("font_color", base_color.lightened(0.15))
	cuisine_lbl.add_theme_font_size_override("font_size", 6)
	parent.add_child(cuisine_lbl)
	floor_nodes.append(cuisine_lbl)
	
	# "Press E to order" hint
	var hint := Label.new()
	hint.text = "[E] Order"
	hint.position = Vector2(cx + cw - 80, cy + ch - 38)
	hint.add_theme_color_override("font_color", glow_color.lightened(0.3))
	hint.add_theme_font_size_override("font_size", 7)
	parent.add_child(hint)
	floor_nodes.append(hint)

static func _get_menu_items(stall_id: String) -> Array:
	match stall_id:
		"jp_ramen": return ["Ramen $8.99", "Gyoza $4.50", "Beer $5.00"]
		"jp_sushi": return ["Sushi Set $12.99", "Miso Soup $2.50", "Green Tea $2.00"]
		"jp_takoyaki": return ["Takoyaki $6.99", "Ikayaki $5.50", "Drinks $2.00"]
		"thai": return ["Pad Thai $9.99", "Green Curry $8.50", "Thai Iced Tea $3.00"]
		"indian": return ["Curry $8.99", "Naan $2.50", "Lassi $3.50"]
		"chinese": return ["Fried Rice $7.99", "Dumplings $5.50", "Tea $2.00"]
		"korean": return ["Bibimbap $10.99", "Kimchi $3.00", "Soju $4.00"]
		"turkish": return ["Kebab $9.99", "Baklava $4.00", "Ayran $2.50"]
		"vietnamese": return ["Pho $8.99", "Spring Rolls $4.50", "Coffee $3.00"]
		"italian": return ["Pizza $10.99", "Pasta $9.50", "Wine $5.00"]
		"mexican": return ["Tacos $7.99", "Burrito $8.50", "Horchata $3.00"]
		"drinks": return ["Coffee $3.50", "Smoothie $5.00", "Water $1.50"]
	return ["Item 1", "Item 2", "Item 3"]

static func _make_glow(col: Color) -> Texture2D:
	var sz := 48
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := col.darkened(0.2)
	for y in range(sz):
		for x in range(sz):
			var d := Vector2(x - sz * 0.5, y - sz * 0.5).length() / (sz * 0.5)
			if d < 1.0:
				var a := (1.0 - d) * 0.35 * c.a
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return ImageTexture.create_from_image(img)
