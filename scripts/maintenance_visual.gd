# maintenance_visual.gd
# Renders visual representations of maintenance issues in the world.
# Each issue type has a distinct sprite (puddle, warning cone, etc.)
# ═══════════════════════════════════════════════════════════════════════
class_name MaintenanceVisual
extends Node2D

const MaintenanceSystem = preload("res://scripts/maintenance_system.gd")
const Issue = MaintenanceSystem.Issue

var _issue_sprites: Dictionary = {}  # issue_id → {node: Node2D, sprite: Sprite2D, issue: Issue}
var _parent: Node = null
var _cell_size: int = 16

func configure(parent: Node) -> void:
	_parent = parent

func build_issue_sprite(issue: Issue) -> Node2D:
	var node := Node2D.new()
	node.position = issue.world_pos

	var spr := Sprite2D.new()
	spr.texture = _create_issue_texture(issue.issue_type, issue.urgency)
	spr.z_index = 5

	# Urgency glow for high-priority issues
	if issue.urgency >= 3:
		spr.modulate = Color(1.2, 0.8, 0.8)

	node.add_child(spr)

	# Warning label below sprite
	var lbl := Label.new()
	lbl.text = Issue.type_emoji(issue.issue_type)
	lbl.position = Vector2(-8, -24)
	lbl.add_theme_font_size_override("font_size", 10)
	node.add_child(lbl)

	# Pulsing animation for urgent issues
	if issue.urgency >= 2:
		var tween := create_tween()
		tween.tween_property(spr, "modulate:a", 0.5, 0.8)\
			.set_trans(Tween.TRANSC_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(spr, "modulate:a", 1.0, 0.8)\
			.set_trans(Tween.TRANSC_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		tween.set_loops(-1)

	if _parent != null:
		_parent.add_child(node)
	else:
		get_parent().add_child(node)

	_issue_sprites[issue.id] = { "node": node, "sprite": spr, "issue": issue }
	return node

func remove_issue_sprite(issue_id: String) -> void:
	if not _issue_sprites.has(issue_id):
		return
	var entry: Dictionary = _issue_sprites[issue_id]
	var node: Node2D = entry["node"]
	if is_instance_valid(node):
		node.queue_free()
	_issue_sprites.erase(issue_id)

func clear_all() -> void:
	for k in _issue_sprites:
		var node: Node2D = _issue_sprites[k].get("node")
		if is_instance_valid(node):
			node.queue_free()
	_issue_sprites.clear()

# ─── Procedural Issue Textures ──────────────────────────────────────

func _create_issue_texture(issue_type: int, urgency: int) -> Texture2D:
	match issue_type:
		Issue.TYPE_SPILL:          return _make_spill_texture()
		Issue.TYPE_BROKEN_LIGHT:   return _make_broken_light_texture()
		Issue.TYPE_OUT_OF_STOCK:   return _make_stockout_texture()
		Issue.TYPE_BROKEN_MACHINE: return _make_machine_texture()
		Issue.TYPE_SECURITY_ALERT: return _make_security_texture()
		Issue.TYPE_LOST_CHILD:     return _make_lost_child_texture()
		Issue.TYPE_CLEANUP_NEEDED: return _make_cleanup_texture()
		Issue.TYPE_POWER_FLICKER:  return _make_power_texture()
	return _make_generic_texture()

func _make_spill_texture() -> Texture2D:
	var W := 28; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Blue-ish water puddle shape
	for y in range(H):
		for x in range(W):
			var dx := float(x) - W * 0.5
			var dy := float(y) - H * 0.5
			var dist := sqrt(dx * dx * 0.8 + dy * dy * 1.2)
			if dist < W * 0.45:
				var alpha := 0.7 - dist / W * 0.5
				img.set_pixel(x, y, Color(0.40, 0.65, 0.90, alpha))
	# Highlight shimmer
	for x in range(W * 0.3, W * 0.7) as int:
		for y in range(3, 8):
			img.set_pixel(x, y, Color(0.80, 0.90, 1.0, 0.4))
	return ImageTexture.create_from_image(img)

func _make_broken_light_texture() -> Texture2D:
	var W := 16; var H := 22
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Warning triangle
	var cx := W / 2; var cy := H / 2 - 2
	for y in range(H):
		for x in range(W):
			var dx := float(x) - cx
			var dy := float(y) - cy
			# Triangle shape
			if dy >= absf(dx) * 0.7 - 8 and dy < 10:
				var flicker := 0.8 if randi() % 3 == 0 else 1.0
				img.set_pixel(x, y, Color(0.95 * flicker, 0.85 * flicker, 0.20, 0.9))
	# Exclamation mark
	img.set_pixel(cx, cy - 3, Color(0.10, 0.10, 0.10))
	img.set_pixel(cx, cy, Color(0.10, 0.10, 0.10))
	img.set_pixel(cx, cy + 3, Color(0.10, 0.10, 0.10))
	return ImageTexture.create_from_image(img)

func _make_stockout_texture() -> Texture2D:
	var W := 20; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Empty box outline
	var box_col := Color(0.65, 0.55, 0.40, 0.9)
	for x in range(4, W - 4):
		img.set_pixel(x, 3, box_col); img.set_pixel(x, H - 4, box_col)
	for y in range(3, H - 3):
		img.set_pixel(4, y, box_col); img.set_pixel(W - 5, y, box_col)
	# X inside
	for i in range(-5, 6):
		if 4 + i >= 0 and 4 + i < W and 6 + absi(i) < H:
			img.set_pixel(4 + i, 6 + absi(i), Color(0.85, 0.25, 0.25, 0.8))
		if 4 + i >= 0 and 4 + i < W and 6 + absi(i) < H:
			img.set_pixel(W - 5 - i, 6 + absi(i), Color(0.85, 0.25, 0.25, 0.8))
	# Label "OUT"
	return ImageTexture.create_from_image(img)

func _make_machine_texture() -> Texture2D:
	var W := 20; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Gear shape
	var cx := W / 2; var cy := H / 2
	var gear_col := Color(0.55, 0.55, 0.60, 0.9)
	for y in range(H):
		for x in range(W):
			var dx := float(x) - cx; var dy := float(y) - cy
			var angle := atan2(dy, dx)
			var dist := sqrt(dx * dx + dy * dy)
			var gear_r := 7.0 + 2.5 * cos(angle * 6.0)
			if dist < gear_r:
				img.set_pixel(x, y, gear_col)
	# Center hole
	for y in range(H):
		for x in range(W):
			var dx := float(x) - cx; var dy := float(y) - cy
			if dx * dx + dy * dy < 4.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	# Wrench overlay
	img.set_pixel(cx - 1, cy - 1, Color(0.40, 0.35, 0.30, 0.8))
	img.set_pixel(cx + 1, cy + 1, Color(0.40, 0.35, 0.30, 0.8))
	return ImageTexture.create_from_image(img)

func _make_security_texture() -> Texture2D:
	var W := 20; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Shield shape
	var cx := W / 2
	for y in range(2, H - 2):
		var half_w := 3.0 + (y - 2) * 0.6
		for x in range(int(cx - half_w), int(cx + half_w + 1)):
			if x >= 0 and x < W:
				img.set_pixel(x, y, Color(0.90, 0.20, 0.20, 0.9))
	# Badge star
	img.set_pixel(cx, 5, Color(0.95, 0.95, 0.60, 1.0))
	img.set_pixel(cx - 1, 6, Color(0.95, 0.95, 0.60, 1.0))
	img.set_pixel(cx + 1, 6, Color(0.95, 0.95, 0.60, 1.0))
	return ImageTexture.create_from_image(img)

func _make_lost_child_texture() -> Texture2D:
	var W := 20; var H := 22
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Child silhouette
	var cx := W / 2
	# Head
	for y in range(2, 8):
		for x in range(cx - 3, cx + 4):
			var dx := float(x) - cx; var dy := float(y) - 5
			if dx * dx + dy * dy < 12.0:
				img.set_pixel(x, y, Color(0.90, 0.75, 0.60, 0.9))
	# Body
	for y in range(8, 16):
		for x in range(cx - 2, cx + 3):
			img.set_pixel(x, y, Color(0.40, 0.55, 0.85, 0.9))
	# Question marks floating above
	img.set_pixel(cx, 0, Color(0.80, 0.60, 0.20, 0.9))
	img.set_pixel(cx - 1, 1, Color(0.80, 0.60, 0.20, 0.9))
	img.set_pixel(cx, 1, Color(0.80, 0.60, 0.20, 0.9))
	img.set_pixel(cx + 1, 1, Color(0.80, 0.60, 0.20, 0.9))
	return ImageTexture.create_from_image(img)

func _make_cleanup_texture() -> Texture2D:
	var W := 20; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Broom handle
	var cx := W / 2
	for y in range(2, 16):
		img.set_pixel(cx, y, Color(0.65, 0.48, 0.28, 0.9))
	# Broom bristles at bottom
	for x in range(cx - 4, cx + 5):
		img.set_pixel(x, 15, Color(0.80, 0.72, 0.40, 0.9))
		img.set_pixel(x, 16, Color(0.80, 0.72, 0.40, 0.9))
		img.set_pixel(x, 17, Color(0.80, 0.72, 0.40, 0.9))
	# Sparkle / clean indicator
	for i in range(-2, 3):
		if absi(i) > 0:
			img.set_pixel(cx + i * 3, 5, Color(0.60, 0.90, 0.80, 0.7))
	return ImageTexture.create_from_image(img)

func _make_power_texture() -> Texture2D:
	var W := 20; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Lightning bolt
	var bolt := [
		[8, 2], [10, 2], [9, 8], [12, 8], [7, 14], [9, 14], [8, 18], [11, 18]
	]
	var prev := bolt[0]
	for pt in bolt:
		var dx := signi(pt[0] - prev[0])
		var dy := signi(pt[1] - prev[1])
		var x := prev[0]; var y := prev[1]
		while x != pt[0] or y != pt[1]:
			for wy in range(-1, 2):
				for wx in range(-1, 2):
					if x + wx >= 0 and x + wx < W and y + wy >= 0 and y + wy < H:
						img.set_pixel(x + wx, y + wy, Color(0.90, 0.85, 0.20, 0.9))
			x += dx; y += dy
		prev = pt
	# Final pixel
	for wy in range(-1, 2):
		for wx in range(-1, 2):
			if pt[0] + wx >= 0 and pt[0] + wx < W and pt[1] + wy >= 0 and pt[1] + wy < H:
				img.set_pixel(pt[0] + wx, pt[1] + wy, Color(0.90, 0.85, 0.20, 0.9))
	return ImageTexture.create_from_image(img)

func _make_generic_texture() -> Texture2D:
	var W := 16; var H := 16
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.85, 0.50, 0.20, 0.8))
	for x in range(W):
		img.set_pixel(x, 0, Color(0.65, 0.40, 0.15))
		img.set_pixel(x, H - 1, Color(0.65, 0.40, 0.15))
	for y in range(H):
		img.set_pixel(0, y, Color(0.65, 0.40, 0.15))
		img.set_pixel(W - 1, y, Color(0.65, 0.40, 0.15))
	return ImageTexture.create_from_image(img)
