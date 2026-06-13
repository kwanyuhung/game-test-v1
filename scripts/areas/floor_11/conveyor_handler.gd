# conveyor_handler.gd
# ─────────────────────────────────────────────────────────────────────────────
# Handler for Conveyor zone on Floor 11
# ─────────────────────────────────────────────────────────────────────────────
class_name ConveyorHandler

const CELL_SIZE := 16

static func build_conveyor(parent: Node, zone: Dictionary, floor_nodes: Array) -> void:
	"""Build conveyor belt (track) area — background is transparent; only the
	metallic rails and chunky belt segments are drawn. Belt segments are scaled
	up (4 cells wide, 2-cell spacing) to read as a real industrial track."""
	var x_px: int = zone.x * CELL_SIZE
	var y_px: int = zone.y * CELL_SIZE
	var w_px: int = zone.w * CELL_SIZE
	var h_px: int = zone.h * CELL_SIZE

	# Top + bottom rails (thin metallic edges)
	var rail_color := Color(0.55, 0.55, 0.60)
	for rail_y in [y_px, y_px + h_px - 2]:
		var rail := ColorRect.new()
		rail.position = Vector2(x_px, rail_y)
		rail.size = Vector2(w_px, 2)
		rail.color = rail_color
		parent.add_child(rail)
		floor_nodes.append(rail)

	# Belt segments (scaled up: 4 cells wide, 2-cell spacing)
	var belt_color := Color(0.35, 0.35, 0.40)
	var belt_highlight := Color(0.50, 0.50, 0.55)
	var belt_w := 4 * CELL_SIZE        # 64 px wide
	var belt_step := 2 * CELL_SIZE     # 32 px between starts (overlap = chained)
	for x in range(x_px, x_px + w_px, belt_step):
		var seg := ColorRect.new()
		seg.position = Vector2(x, y_px + 4)
		seg.size = Vector2(belt_w, h_px - 8)
		seg.color = belt_color
		parent.add_child(seg)
		floor_nodes.append(seg)
		# Highlight on top of each segment
		var hl := ColorRect.new()
		hl.position = Vector2(x, y_px + 4)
		hl.size = Vector2(belt_w, 2)
		hl.color = belt_highlight
		parent.add_child(hl)
		floor_nodes.append(hl)

	# Direction arrow at the right end
	var arrow := Label.new()
	arrow.text = "▶▶▶"
	arrow.position = Vector2(x_px + w_px - 50, y_px + h_px / 2 - 6)
	arrow.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	arrow.add_theme_font_size_override("font_size", 10)
	parent.add_child(arrow)
	floor_nodes.append(arrow)

	# Label
	if zone.has("meta") and zone.meta.has("name"):
		var label := Label.new()
		label.text = zone.meta.name
		label.position = Vector2(x_px + 4, y_px - 12)
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		floor_nodes.append(label)
