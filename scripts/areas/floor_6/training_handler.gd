# training_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for TRAINING zones on Floor 6 (Staff Area)
# Staff training room
# ─────────────────────────────────────────────────────────────────────────────
class_name TrainingHandler

const CELL_SIZE := 16

static func build_training(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	var name: String = zone.meta.get("name", "TRAINING")
	var zone_color: Color = zone.meta.get("color", Color(0.42, 0.45, 0.50))
	var cx :int= zone.x * CELL_SIZE
	var cy :int= zone.y * CELL_SIZE
	var cw :int= zone.w * CELL_SIZE
	var ch :int= zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy); bg.size = Vector2(cw, ch)
	bg.color = zone_color.darkened(0.4)
	parent.add_child(bg); floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = name
	title_lbl.position = Vector2(cx + 4, cy - 14)
	title_lbl.add_theme_color_override("font_color", zone_color.lightened(0.3))
	title_lbl.add_theme_font_size_override("font_size", 10)
	parent.add_child(title_lbl); floor_nodes.append(title_lbl)

	# Add training room elements (projector screen, chairs)
	_add_training_elements(parent, floor_nodes, cx, cy, cw, ch, zone_color)

static func _add_training_elements(parent: Node, floor_nodes: Array, cx: int, cy: int, cw: int, ch: int, zone_color: Color) -> void:
	# Projector screen at front
	var screen := ColorRect.new()
	screen.position = Vector2(cx + cw/2 - 40, cy + 10)
	screen.size = Vector2(80, 40)
	screen.color = Color(0.15, 0.15, 0.18)
	parent.add_child(screen); floor_nodes.append(screen)
	
	# Rows of chairs
	for row in range(3):
		var row_y := cy + 60 + row * 25
		for col in range(6):
			var chair_x := cx + 30 + col * int((cw - 60) / 6.0)
			var chair := ColorRect.new()
			chair.position = Vector2(chair_x, row_y)
			chair.size = Vector2(12, 12)
			chair.color = Color(0.50, 0.48, 0.45)
			parent.add_child(chair); floor_nodes.append(chair)