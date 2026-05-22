# misc_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for miscellaneous Ground Floor zones:
# ATM, Vending Machine, Lost & Found, Store News, Promo Booth
# ─────────────────────────────────────────────────────────────────────────────
class_name MiscHandler

const CELL_SIZE := 16

# Misc zone types
enum MiscType {
	ATM,
	VENDING_MACHINE,
	LOST_FOUND,
	STORE_NEWS,
	PROMO_BOOTH,
	DECOR,
}

static func build_misc_area(parent: Node, zone: Dictionary, floor_nodes: Array, area_type: String) -> void:
	var meta: Dictionary = zone.get("meta", {})
	var zone_name: String = meta.get("name", "ZONE")
	var zone_color: Color = meta.get("color", Color(0.5, 0.5, 0.5))
	
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	match area_type:
		"ZONE_ATM":
			_build_atm(parent, floor_nodes, cx, cy, zone_name)
		"ZONE_VENDING_MACHINE":
			_build_vending_machine(parent, floor_nodes, cx, cy, cw, ch, zone_name)
		"ZONE_LOST_FOUND":
			_build_lost_found(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_STORE_NEWS":
			_build_store_news(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_PROMO_BOOTH":
			_build_promo_booth(parent, floor_nodes, cx, cy, cw, ch, zone_color, zone_name)
		"ZONE_DECOR":
			_build_decor(parent, floor_nodes, cx, cy, cw, ch, meta)

static func _build_atm(parent: Node, floor_nodes: Array, cx: int, cy: int, zone_name: String) -> void:
	# ATM body
	var body := ColorRect.new()
	body.position = Vector2(cx + 32, cy + 32)
	body.size = Vector2(48, 64)
	body.color = Color(0.15, 0.20, 0.15)
	parent.add_child(body)
	floor_nodes.append(body)
	
	# Screen
	var screen := ColorRect.new()
	screen.position = Vector2(cx + 36, cy + 38)
	screen.size = Vector2(40, 30)
	screen.color = Color(0.08, 0.18, 0.08)
	parent.add_child(screen)
	floor_nodes.append(screen)
	
	# Screen text
	var screen_lbl := Label.new()
	screen_lbl.text = "INSERT CARD"
	screen_lbl.position = Vector2(cx + 38, cy + 44)
	screen_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.40))
	screen_lbl.add_theme_font_size_override("font_size", 6)
	parent.add_child(screen_lbl)
	floor_nodes.append(screen_lbl)
	
	# Card slot
	var slot := ColorRect.new()
	slot.position = Vector2(cx + 52, cy + 72)
	slot.size = Vector2(16, 4)
	slot.color = Color(0.08, 0.08, 0.08)
	parent.add_child(slot)
	floor_nodes.append(slot)
	
	# Cash dispenser
	var cash := ColorRect.new()
	cash.position = Vector2(cx + 38, cy + 80)
	cash.size = Vector2(32, 16)
	cash.color = Color(0.12, 0.18, 0.12)
	parent.add_child(cash)
	floor_nodes.append(cash)
	
	# Bank brand
	var brand_lbl := Label.new()
	brand_lbl.text = "STORE BANK"
	brand_lbl.position = Vector2(cx + 36, cy + 20)
	brand_lbl.add_theme_color_override("font_color", Color(0.20, 0.60, 0.30))
	brand_lbl.add_theme_font_size_override("font_size", 6)
	parent.add_child(brand_lbl)
	floor_nodes.append(brand_lbl)

static func _build_vending_machine(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_name: String) -> void:
	# Machine body
	var body := ColorRect.new()
	body.position = Vector2(cx, cy)
	body.size = Vector2(cw, ch)
	body.color = Color(0.25, 0.28, 0.32)
	parent.add_child(body)
	floor_nodes.append(body)
	
	# Glass front
	var glass := ColorRect.new()
	glass.position = Vector2(cx + 8, cy + 8)
	glass.size = Vector2(cw - 16, int(ch * 0.70))
	glass.color = Color(0.15, 0.18, 0.22).lightened(0.15)
	parent.add_child(glass)
	floor_nodes.append(glass)
	
	# Frame top
	var frame_top := ColorRect.new()
	frame_top.position = Vector2(cx, cy)
	frame_top.size = Vector2(cw, 4)
	frame_top.color = Color(0.50, 0.50, 0.55)
	parent.add_child(frame_top)
	floor_nodes.append(frame_top)
	
	# Item slots
	var item_colors := [Color(0.40, 0.70, 0.90), Color(0.85, 0.30, 0.30), Color(0.80, 0.75, 0.30),
			Color(0.90, 0.65, 0.30), Color(0.60, 0.40, 0.25), Color(0.30, 0.80, 0.50)]
	for row in range(2):
		for col in range(3):
			var ix: int = cx + 12 + col * int((cw - 24) / 3.0)
			var iy: int = cy + 12 + row * int(ch * 0.35)
			var slot := ColorRect.new()
			slot.position = Vector2(ix, iy)
			slot.size = Vector2(int((cw - 24) / 3.5), int(ch * 0.30))
			slot.color = item_colors[(row * 3 + col) % item_colors.size()]
			parent.add_child(slot)
			floor_nodes.append(slot)
	
	# Control panel
	var panel := ColorRect.new()
	panel.position = Vector2(cx + 8, cy + int(ch * 0.72))
	panel.size = Vector2(cw - 16, int(ch * 0.25))
	panel.color = Color(0.20, 0.22, 0.26)
	parent.add_child(panel)
	floor_nodes.append(panel)
	
	# Machine label
	var tl := Label.new()
	tl.text = zone_name
	tl.position = Vector2(cx + 8, cy - 14)
	tl.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
	tl.add_theme_font_size_override("font_size", 8)
	parent.add_child(tl)
	floor_nodes.append(tl)

static func _build_lost_found(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# Counter background
	var counter := ColorRect.new()
	counter.position = Vector2(cx, cy)
	counter.size = Vector2(cw, ch)
	counter.color = zone_color.darkened(0.5)
	parent.add_child(counter)
	floor_nodes.append(counter)
	
	# Counter desk
	var desk := ColorRect.new()
	desk.position = Vector2(cx, cy + ch - 35)
	desk.size = Vector2(cw, 35)
	desk.color = zone_color.darkened(0.3)
	parent.add_child(desk)
	floor_nodes.append(desk)
	
	# Header
	var header := ColorRect.new()
	header.position = Vector2(cx, cy)
	header.size = Vector2(cw, 20)
	header.color = zone_color.darkened(0.2)
	parent.add_child(header)
	floor_nodes.append(header)
	
	# Sign
	var sign_lbl := Label.new()
	sign_lbl.text = zone_name
	sign_lbl.position = Vector2(cx + 8, cy + 4)
	sign_lbl.add_theme_color_override("font_color", zone_color.lightened(0.4))
	sign_lbl.add_theme_font_size_override("font_size", 8)
	parent.add_child(sign_lbl)
	floor_nodes.append(sign_lbl)
	
	# Lost box icon
	var box := ColorRect.new()
	box.position = Vector2(cx + cw - 50, cy + 35)
	box.size = Vector2(35, 30)
	box.color = zone_color.lightened(0.2)
	parent.add_child(box)
	floor_nodes.append(box)

static func _build_store_news(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# News board
	var board := ColorRect.new()
	board.position = Vector2(cx, cy)
	board.size = Vector2(cw, ch)
	board.color = Color(0.12, 0.15, 0.18)
	parent.add_child(board)
	floor_nodes.append(board)
	
	# Header
	var header := ColorRect.new()
	header.position = Vector2(cx, cy)
	header.size = Vector2(cw, 20)
	header.color = zone_color.darkened(0.2)
	parent.add_child(header)
	floor_nodes.append(header)
	
	# Header text
	var header_lbl := Label.new()
	header_lbl.text = zone_name
	header_lbl.position = Vector2(cx + 8, cy + 4)
	header_lbl.add_theme_color_override("font_color", zone_color.lightened(0.4))
	header_lbl.add_theme_font_size_override("font_size", 8)
	parent.add_child(header_lbl)
	floor_nodes.append(header_lbl)
	
	# News items
	var news_items := ["🎉 GRAND OPENING!", "🛍️ NEW STORES ADDED", "⭐ LOYALTY REWARDS UP"]
	for i in range(mini(3, news_items.size())):
		var news_lbl := Label.new()
		news_lbl.text = news_items[i]
		news_lbl.position = Vector2(cx + 8, cy + 28 + i * 16)
		news_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
		news_lbl.add_theme_font_size_override("font_size", 6)
		parent.add_child(news_lbl)
		floor_nodes.append(news_lbl)

static func _build_promo_booth(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color, zone_name: String) -> void:
	# Booth background
	var booth := ColorRect.new()
	booth.position = Vector2(cx, cy)
	booth.size = Vector2(cw, ch)
	booth.color = zone_color.darkened(0.4)
	parent.add_child(booth)
	floor_nodes.append(booth)
	
	# Header bar
	var header := ColorRect.new()
	header.position = Vector2(cx, cy)
	header.size = Vector2(cw, 24)
	header.color = zone_color
	parent.add_child(header)
	floor_nodes.append(header)
	
	# Header text
	var header_lbl := Label.new()
	header_lbl.text = zone_name
	header_lbl.position = Vector2(cx + 8, cy + 6)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	header_lbl.add_theme_font_size_override("font_size", 9)
	parent.add_child(header_lbl)
	floor_nodes.append(header_lbl)
	
	# Promo items
	var promo_items := ["🔥 DEALS", "🎁 FREEBIES", "💰 SAVE BIG"]
	for i in range(mini(3, promo_items.size())):
		var promo_lbl := Label.new()
		promo_lbl.text = promo_items[i]
		promo_lbl.position = Vector2(cx + 8, cy + 32 + i * 14)
		promo_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
		promo_lbl.add_theme_font_size_override("font_size", 6)
		parent.add_child(promo_lbl)
		floor_nodes.append(promo_lbl)

static func _build_decor(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, meta: Dictionary) -> void:
	var decor_type: String = meta.get("name", "dining_table")
	match decor_type:
		"dining_table":
			_build_dining_table(parent, floor_nodes, cx, cy)
		_:
			# Default decor
			var decor := ColorRect.new()
			decor.position = Vector2(cx, cy)
			decor.size = Vector2(cw, ch)
			decor.color = Color(0.22, 0.20, 0.18)
			parent.add_child(decor)
			floor_nodes.append(decor)

static func _build_dining_table(parent: Node, floor_nodes: Array, cx: int, cy: int) -> void:
	# Table top
	var top := ColorRect.new()
	top.position = Vector2(cx, cy)
	top.size = Vector2(64, 40)
	top.color = Color(0.52, 0.48, 0.42)
	parent.add_child(top)
	floor_nodes.append(top)
	
	# Chairs around table
	var chair_offsets := [
		Vector2i(-16, 0), Vector2i(48, 0),
		Vector2i(-16, 32), Vector2i(48, 32),
		Vector2i(0, -16), Vector2i(32, -16),
		Vector2i(0, 40), Vector2i(32, 40),
	]
	for offset in chair_offsets:
		var chair := ColorRect.new()
		chair.position = Vector2(cx + offset.x, cy + offset.y)
		chair.size = Vector2(16, 16)
		chair.color = Color(0.45, 0.42, 0.40)
		parent.add_child(chair)
		floor_nodes.append(chair)
