# kids_kingdom_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Kids Kingdom zones on Floor 13
# ─────────────────────────────────────────────────────────────────────────────
class_name KidsKingdomHandler

const CELL_SIZE := 16

static func build_kids_play(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build kids play zone area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.6, 0.8, 0.9)  # Light blue for play zone
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add play area decorations (circles for play equipment)
	for y in range(zone.y + 4, zone.y + zone.h - 4, 6):
		for x in range(zone.x + 4, zone.x + zone.w - 4, 6):
			var play_item := ColorRect.new()
			play_item.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			play_item.size = Vector2(4 * CELL_SIZE, 4 * CELL_SIZE)
			play_item.color = Color(0.5, 0.7, 0.8, 0.5)
			play_item.set("custom_minimum_size", Vector2(4 * CELL_SIZE, 4 * CELL_SIZE))
			parent.add_child(play_item)
			floor_nodes.append(play_item)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)

static func build_kids_club(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build kids club area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.9, 0.6, 0.8)  # Pink for kids club
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)

static func build_nursing_room(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build nursing room area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.85, 0.75, 0.9)  # Soft purple for nursing room
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)

static func build_family_wc(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build family WC area"""
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	if zone.has("meta") and zone.meta.has("color"):
		base.color = Color(zone.meta.color[0], zone.meta.color[1], zone.meta.color[2])
	else:
		base.color = Color(0.7, 0.65, 0.8)  # Light purple for family WC
	parent.add_child(base)
	floor_nodes.append(base)
	
	# Add label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(zone.x * CELL_SIZE + 4, zone.y * CELL_SIZE + 2 * CELL_SIZE)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)
