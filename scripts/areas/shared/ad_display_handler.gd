# ad_display_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for AD (Advertisement Display) zones
# ─────────────────────────────────────────────────────────────────────────────
class_name AdDisplayHandler

const CELL_SIZE := 16

static func build_ad_display(parent: Node, zone: Dictionary, floor_nodes: Array, ad_index: int = 0) -> void:
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Get ad color from meta or use default
	var ad_color: Color = zone.get("meta", {}).get("color", _get_default_ad_color(ad_index))
	
	# Display frame
	var frame := ColorRect.new()
	frame.position = Vector2(cx, cy)
	frame.size = Vector2(cw, ch)
	frame.color = Color(0.15, 0.15, 0.18)
	parent.add_child(frame)
	floor_nodes.append(frame)
	
	# Screen area
	var screen := ColorRect.new()
	screen.position = Vector2(cx + 2, cy + 2)
	screen.size = Vector2(cw - 4, ch - 4)
	screen.color = ad_color.darkened(0.2)
	parent.add_child(screen)
	floor_nodes.append(screen)
	
	# Animated glow effect (simulated with bright border)
	var glow_top := ColorRect.new()
	glow_top.position = Vector2(cx + 2, cy + 2)
	glow_top.size = Vector2(cw - 4, 2)
	glow_top.color = ad_color.lightened(0.3)
	parent.add_child(glow_top)
	floor_nodes.append(glow_top)
	
	var glow_bottom := ColorRect.new()
	glow_bottom.position = Vector2(cx + 2, cy + ch - 4)
	glow_bottom.size = Vector2(cw - 4, 2)
	glow_bottom.color = ad_color.lightened(0.2)
	parent.add_child(glow_bottom)
	floor_nodes.append(glow_bottom)
	
	# Ad content text (rotating ads)
	var ad_texts: Array = _get_ad_texts()
	var ad_text: String = str(ad_texts[ad_index % ad_texts.size()])
	
	var lbl := Label.new()
	lbl.text = ad_text
	lbl.position = Vector2(cx + 2, cy + ch / 2 - 4)
	lbl.add_theme_color_override("font_color", ad_color.lightened(0.4))
	lbl.add_theme_font_size_override("font_size", 6)
	parent.add_child(lbl)
	floor_nodes.append(lbl)
	
	# "AD" badge
	var badge := Label.new()
	badge.text = "[AD]"
	badge.position = Vector2(cx + cw - 14, cy + 2)
	badge.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	badge.add_theme_font_size_override("font_size", 4)
	parent.add_child(badge)
	floor_nodes.append(badge)

static func _get_default_ad_color(index: int) -> Color:
	var colors := [
		Color(1.0, 0.4, 0.2),   # Orange-red
		Color(0.2, 0.6, 1.0),   # Blue
		Color(0.2, 0.8, 0.5),   # Green
		Color(0.95, 0.4, 0.8),  # Pink
		Color(0.9, 0.7, 0.2),   # Gold
	]
	return colors[index % colors.size()]

static func _get_ad_texts() -> Array:
	return [
		"SALE! 50% OFF",
		"NEW ARRIVALS",
		"BUY 1 GET 1 FREE",
		"LIMITED TIME OFFER",
		"SPECIAL DISCOUNT",
		"MEMBERS ONLY",
		"FLASH SALE TODAY",
		"TOP BRANDS"
	]

static func build_promo_board(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build a larger promotional display board"""
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Board background
	var board := ColorRect.new()
	board.position = Vector2(cx, cy)
	board.size = Vector2(cw, ch)
	board.color = Color(0.12, 0.12, 0.15)
	parent.add_child(board)
	floor_nodes.append(board)
	
	# Header bar
	var header := ColorRect.new()
	header.position = Vector2(cx, cy)
	header.size = Vector2(cw, 8)
	header.color = Color(0.8, 0.55, 0.2)
	parent.add_child(header)
	floor_nodes.append(header)
	
	# Header text
	var header_lbl := Label.new()
	header_lbl.text = "DAILY DEALS"
	header_lbl.position = Vector2(cx + 4, cy + 1)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	header_lbl.add_theme_font_size_override("font_size", 7)
	parent.add_child(header_lbl)
	floor_nodes.append(header_lbl)
	
	# Deal items
	var deals := [
		"👟 Shoes $29.99",
		"👕 Shirts $14.99",
		"🎒 Bags $39.99"
	]
	
	for i in range(mini(3, deals.size())):
		var deal_lbl := Label.new()
		deal_lbl.text = deals[i]
		deal_lbl.position = Vector2(cx + 4, cy + 12 + i * 8)
		deal_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
		deal_lbl.add_theme_font_size_override("font_size", 5)
		parent.add_child(deal_lbl)
		floor_nodes.append(deal_lbl)