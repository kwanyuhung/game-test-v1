# lobby_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for LOBBY zone on Ground Floor
# Main entrance area with decorative elements
# ─────────────────────────────────────────────────────────────────────────────
class_name LobbyHandler

const CELL_SIZE := 16

static func build_lobby(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var cx: int = int(zone.x) * CELL_SIZE
	var cy: int = int(zone.y) * CELL_SIZE
	var cw: int = int(zone.w) * CELL_SIZE
	var ch: int = int(zone.h) * CELL_SIZE
	
	# Main lobby floor
	var floor := ColorRect.new()
	floor.position = Vector2(cx, cy)
	floor.size = Vector2(cw, ch)
	floor.color = Color(0.22, 0.20, 0.18)
	parent.add_child(floor)
	floor_nodes.append(floor)
	
	# Decorative floor pattern (marble-like tiles)
	var tile_color := Color(0.24, 0.22, 0.20)
	var tile_size: int = CELL_SIZE * 4
	
	for ty in range(cy, cy + ch, tile_size):
		var line_h := ColorRect.new()
		line_h.position = Vector2(cx, ty)
		line_h.size = Vector2(cw, 1)
		line_h.color = tile_color
		parent.add_child(line_h)
		floor_nodes.append(line_h)
	
	for tx in range(cx, cx + cw, tile_size):
		var line_v := ColorRect.new()
		line_v.position = Vector2(tx, cy)
		line_v.size = Vector2(1, ch)
		line_v.color = tile_color
		parent.add_child(line_v)
		floor_nodes.append(line_v)
	
	# Entrance mat/rug area
	var rug := ColorRect.new()
	rug.position = Vector2(cx + cw / 2 - 40, cy + ch - 30)
	rug.size = Vector2(80, 20)
	rug.color = Color(0.35, 0.25, 0.20)
	parent.add_child(rug)
	floor_nodes.append(rug)
	
	# Welcome text
	var welcome := Label.new()
	welcome.text = "WELCOME"
	welcome.position = Vector2(cx + cw / 2 - 30, cy + 10)
	welcome.add_theme_color_override("font_color", Color(0.80, 0.75, 0.60))
	welcome.add_theme_font_size_override("font_size", 12)
	parent.add_child(welcome)
	floor_nodes.append(welcome)
	
	# Floor stripe at edge
	var stripe := ColorRect.new()
	stripe.position = Vector2(cx, cy + ch - 4)
	stripe.size = Vector2(cw, 4)
	stripe.color = Color(0.30, 0.27, 0.24)
	parent.add_child(stripe)
	floor_nodes.append(stripe)
	
	# Potted plants at corners
	_add_potted_plant(parent, floor_nodes, cx + 20, cy + 20)
	_add_potted_plant(parent, floor_nodes, cx + cw - 40, cy + 20)
	_add_potted_plant(parent, floor_nodes, cx + 20, cy + ch - 50)
	_add_potted_plant(parent, floor_nodes, cx + cw - 40, cy + ch - 50)

static func _add_potted_plant(parent: Node, floor_nodes: Array, px: int, py: int) -> void:
	# Pot
	var pot := ColorRect.new()
	pot.position = Vector2(px, py)
	pot.size = Vector2(16, 12)
	pot.color = Color(0.50, 0.35, 0.25)
	parent.add_child(pot)
	floor_nodes.append(pot)
	
	# Plant leaves (simple green area)
	var plant := ColorRect.new()
	plant.position = Vector2(px - 2, py - 16)
	plant.size = Vector2(20, 18)
	plant.color = Color(0.25, 0.50, 0.20)
	parent.add_child(plant)
	floor_nodes.append(plant)
