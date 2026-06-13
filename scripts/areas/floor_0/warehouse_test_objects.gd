# warehouse_test_objects.gd
# ─────────────────────────────────────────────────────────────────────────────
# Test-only visuals for the Floor G warehouse area.
# Places static truck / forklift / car / pallet / cargo sprites inside the
# existing ZONE_WAREHOUSE region on Floor 0 so the warehouse / dock systems
# can be exercised end-to-end without driving the player to Floor 11.
#
# Zone layout (Floor 0, tile coords, from floor_config_data.json):
#   WAREHOUSE      x=0,   y=140,  w=480,  h=56   (full back-of-house)
#   TRUCK_DOCK     x=0,   y=140,  w=88,   h=56   (sub-zone: left-top)
#   FORKLIFT       x=0,   y=168,  w=88,   h=28   (sub-zone: left-bottom)
#   CONVEYOR       x=88,  y=152,  w=200,  h=32
#   STORAGE_SHELF  x=300, y=140,  w=180,  h=56   (right side)
#
# Object placement (tile coords, relative to warehouse zone origin (0,140)):
#   Truck       : (6, 8)   → in TRUCK_DOCK
#   Car-1       : (40, 14) → in TRUCK_DOCK
#   Forklift    : (8, 38)  → in FORKLIFT (single forklift — no other vehicles)
#   Pallet      : (390, 40)→ in STORAGE_SHELF (1x flat pallet on the ground)
#   Cargo S/M/L : on top of the pallet (Small=0.5x, Medium=1x, Large=2x)
#   AutoDoor    : (390, 0) → top boundary of STORAGE_SHELF (faces up toward lobby)
#
# Pallet capacity: 5 (W) × 5 (L) × 3 (H) cargo cells at default size
# (= 75 cargo units max). Cargo sizes are scaled relative to one default cell.
# ─────────────────────────────────────────────────────────────────────────────
class_name WarehouseTestObjects

const CELL_SIZE := 16

# Toggle debug visualizations (bounding boxes + name labels + door trigger).
const DEBUG_MODE: bool = true

# Pallet capacity grid (cargo cells, in default-size units)
const PALLET_GRID_W := 5
const PALLET_GRID_L := 5
const PALLET_GRID_H := 3
const CARGO_DEFAULT_PX := 16     # one default-size cargo = 16 px square
const PALLET_FOOTPRINT_TILES := 5  # 5x5 tiles footprint = 80x80 px pallet

# Public entry point — call from floor_builder.gd:_build_zone_warehouse()
# after the warehouse zone tile is built.
static func build_test_objects(parent: Node, warehouse_zone: Dictionary, floor_nodes: Array) -> void:
	if warehouse_zone == null or warehouse_zone.is_empty():
		push_error("[WarehouseTestObjects] warehouse_zone is empty — nothing to build")
		return
	var zx: int = int(warehouse_zone.get("x", 0))
	var zy: int = int(warehouse_zone.get("y", 0))
	var zw: int = int(warehouse_zone.get("w", 0))
	var zh: int = int(warehouse_zone.get("h", 0))

	print("[WarehouseTestObjects] building at zone (x=%d, y=%d, w=%d, h=%d) parent=%s" % [zx, zy, zw, zh, parent.name if parent else "null"])
	print("[WarehouseTestObjects] world-px anchor = (%.0f, %.0f) (parent local); zone bottom-right at (%.0f, %.0f)" % [
		zx * CELL_SIZE, zy * CELL_SIZE,
		(zx + zw) * CELL_SIZE, (zy + zh) * CELL_SIZE,
	])

	# ── 0. Giant debug box + banner (visible from far away) ─────────────
	if DEBUG_MODE:
		_add_debug_zone_box(parent, floor_nodes, zx, zy, zw, zh)
		_add_zone_label(parent, floor_nodes, zx, zy)

	# ── 1. Truck dock (y=140..168, x=0..88) ─────────────────────────────
	var truck := _make_sprite_node("Truck", _make_truck_texture(), _tile_center(zx + 6, zy + 8), 10)
	parent.add_child(truck); floor_nodes.append(truck)
	if DEBUG_MODE:
		_add_debug_box(parent, floor_nodes, "TRUCK @ (6,148)", _tile_center(zx + 6, zy + 8), 80, 40, Color(1.0, 0.2, 0.2, 0.35))

	var car1 := _make_sprite_node("Car-Dock", _make_sedan_texture(Color(0.25, 0.45, 0.85)), _tile_center(zx + 40, zy + 14), 10)
	parent.add_child(car1); floor_nodes.append(car1)
	if DEBUG_MODE:
		_add_debug_box(parent, floor_nodes, "CAR-1 (blue) @ (40,154)", _tile_center(zx + 40, zy + 14), 60, 30, Color(0.3, 0.5, 1.0, 0.35))

	_add_label(parent, floor_nodes, "TRUCK DOCK", _tile_center(zx + 60, zy + 4), Color(1.0, 0.85, 0.4))

	# ── 2. Forklift zone (y=168..196, x=0..88) ─────────────────────────
	# Rule: exactly one (1) forklift, no cars. (Car-2 was removed.)
	var forklift := _make_sprite_node("Forklift", _make_forklift_texture(), _tile_center(zx + 8, zy + 38), 10)
	parent.add_child(forklift); floor_nodes.append(forklift)
	if DEBUG_MODE:
		_add_debug_box(parent, floor_nodes, "FORKLIFT @ (8,178) — ONLY vehicle in this zone", _tile_center(zx + 8, zy + 38), 50, 50, Color(1.0, 0.85, 0.1, 0.35))

	_add_label(parent, floor_nodes, "FORKLIFT ZONE", _tile_center(zx + 60, zy + 34), Color(0.95, 0.75, 0.2))

	# ── 3. Pallet + cargo (in STORAGE_SHELF) ────────────────────────────
	# Pallet: 5x5 tile footprint, capacity 5x5x3 cargo cells.
	# Three cargo sizes visualized on top: Small (0.5x), Medium (1x), Large (2x).
	var pallet_center := _tile_center(zx + 390, zy + 40)
	_build_pallet_with_cargo(parent, floor_nodes, pallet_center)

	# ── 4. AutoDoor at the top boundary of the STORAGE_SHELF area ───────
	# Storage shelf top is at absolute y=140 (== zy, warehouse top boundary).
	# The door's bidirectional trigger extends TRIGGER_DEPTH on BOTH sides of
	# the boundary, so the player can open the door from the lobby OR the
	# storage area. A StaticBody2D blocker physically stops the player when
	# the door is closed. Press F6 anywhere to force-toggle for testing.
	var door := AutoDoor.new()
	door.configure(2.0, 1.0, Color(0.55, 0.65, 0.78))
	door.position = _tile_center(zx + 390, zy + 0)
	if DEBUG_MODE:
		door.set_debug_visible(true)
	parent.add_child(door)
	floor_nodes.append(door)

	# Door frame label
	_add_label(parent, floor_nodes, "AUTO DOOR", door.position + Vector2(-26, -28), Color(0.65, 0.85, 1.0), 7)

	# ── 5. Banner label so testers can spot the test setup ──────────────
	_add_label(parent, floor_nodes,
		"TEST: 1 truck + 1 forklift + 1 car + 1 pallet (5x5x3) + 3 cargo sizes + 1 auto door",
		_tile_center(zx + 220, zy + 0) - Vector2(0, 36),
		Color(1.0, 0.95, 0.5), 10)

	print("[WarehouseTestObjects] DONE — added 1 truck + 1 forklift + 1 car + 1 pallet + 3 cargo (S/M/L) + 1 auto door (+ debug boxes if DEBUG_MODE)")

# ─── Pallet + cargo ─────────────────────────────────────────────────────

# Build a flat wooden pallet at `center` plus 3 cargo items of different
# sizes on top. The pallet's 5x5x3 capacity grid is visualized as a wireframe.
static func _build_pallet_with_cargo(parent: Node, floor_nodes: Array, center: Vector2) -> void:
	var footprint_px: int = PALLET_FOOTPRINT_TILES * CELL_SIZE  # 80 px
	var pallet_top_y: float = center.y - 2.0  # pallet sits just above the floor center
	var pallet_rect_y: float = center.y - footprint_px / 2.0

	# Pallet wooden platform (4 px tall)
	var pallet := ColorRect.new()
	pallet.name = "Pallet"
	pallet.color = Color(0.50, 0.36, 0.22)  # dark wood
	pallet.size = Vector2(footprint_px, 4)
	pallet.position = Vector2(center.x - footprint_px / 2.0, pallet_rect_y + footprint_px - 4)
	pallet.z_index = 7
	parent.add_child(pallet)
	floor_nodes.append(pallet)

	# Pallet plank lines (3 horizontal slits to read as wooden pallet)
	for py in range(int(pallet_rect_y + footprint_px - 12), int(pallet_rect_y + footprint_px - 1), 3):
		var plank := ColorRect.new()
		plank.color = Color(0.32, 0.22, 0.12)
		plank.size = Vector2(footprint_px, 1)
		plank.position = Vector2(center.x - footprint_px / 2.0, py)
		plank.z_index = 7
		parent.add_child(plank)
		floor_nodes.append(plank)

	# Pallet feet (3 little blocks under the platform)
	for fx in [-footprint_px / 3.0, 0.0, footprint_px / 3.0]:
		var foot := ColorRect.new()
		foot.color = Color(0.30, 0.20, 0.10)
		foot.size = Vector2(8, 6)
		foot.position = Vector2(center.x + fx - 4, pallet_rect_y + footprint_px)
		foot.z_index = 6
		parent.add_child(foot)
		floor_nodes.append(foot)

	# Capacity grid wireframe (5 W × 5 L × 3 H cells in default-size units)
	# Drawn as 3 stacked horizontal outlines (one per height level) so the
	# 3D stack depth is readable.
	if DEBUG_MODE:
		var grid_color := Color(0.30, 0.85, 1.0, 0.55)
		for level in range(PALLET_GRID_H):
			var level_y: float = pallet_rect_y + 4 - level * CARGO_DEFAULT_PX - 2
			# 4 edges of each level
			for edge in [
				[Vector2(center.x - footprint_px / 2.0, level_y),
				 Vector2(footprint_px, 1)],
				[Vector2(center.x - footprint_px / 2.0, level_y - CARGO_DEFAULT_PX + 1),
				 Vector2(footprint_px, 1)],
				[Vector2(center.x - footprint_px / 2.0, level_y - CARGO_DEFAULT_PX + 1),
				 Vector2(1, CARGO_DEFAULT_PX)],
				[Vector2(center.x + footprint_px / 2.0 - 1, level_y - CARGO_DEFAULT_PX + 1),
				 Vector2(1, CARGO_DEFAULT_PX)],
			]:
				var r := ColorRect.new()
				r.color = grid_color
				r.position = edge[0]
				r.size = edge[1]
				r.z_index = 8
				r.mouse_filter = Control.MOUSE_FILTER_IGNORE
				parent.add_child(r)
				floor_nodes.append(r)

		# Grid label
		var cap_lbl := Label.new()
		cap_lbl.text = "Pallet capacity: %d × %d × %d (= %d cells)" % [
			PALLET_GRID_W, PALLET_GRID_L, PALLET_GRID_H,
			PALLET_GRID_W * PALLET_GRID_L * PALLET_GRID_H,
		]
		cap_lbl.position = Vector2(center.x - 60, pallet_rect_y - 18)
		cap_lbl.add_theme_color_override("font_color", Color(0.30, 0.85, 1.0))
		cap_lbl.add_theme_font_size_override("font_size", 7)
		cap_lbl.z_index = 9
		parent.add_child(cap_lbl)
		floor_nodes.append(cap_lbl)

	# Three cargo sizes on top of the pallet:
	# Small (0.5x = 8 px), Medium (1x = 16 px), Large (2x = 32 px).
	# Placed side-by-side on the pallet so the size difference is obvious.
	var cargo_y: float = pallet_rect_y + footprint_px - 4 - 32  # top of pallet minus 2 cargo heights
	var cargo_positions := [
		{"name": "Cargo-Small",  "size": 0.5, "x_off": -30.0, "color": Color(0.72, 0.55, 0.32)},
		{"name": "Cargo-Medium", "size": 1.0, "x_off": 0.0,   "color": Color(0.55, 0.45, 0.30)},
		{"name": "Cargo-Large",  "size": 2.0, "x_off": 22.0,  "color": Color(0.80, 0.60, 0.40)},
	]
	for c in cargo_positions:
		var px: float = float(CARGO_DEFAULT_PX) * float(c["size"])
		var cargo := Sprite2D.new()
		cargo.name = c["name"]
		cargo.texture = _make_cargo_texture(c["size"], c["color"])
		cargo.position = Vector2(center.x + float(c["x_off"]), cargo_y - px / 2.0 + 8)
		cargo.centered = true
		cargo.z_index = 9
		parent.add_child(cargo)
		floor_nodes.append(cargo)
		if DEBUG_MODE:
			_add_debug_box(parent, floor_nodes,
				"%s (%.1fx = %dpx)" % [c["name"], float(c["size"]), int(px)],
				cargo.position, int(px), int(px), Color(0.4, 0.9, 0.4, 0.35))

	# Pallet name label
	_add_label(parent, floor_nodes, "PALLET", Vector2(center.x - 18, pallet_rect_y + footprint_px + 10), Color(0.75, 0.55, 0.35), 8)

# ─── Pallet placement-logic helper (capacity check) ────────────────────

# Returns true if `cargo_count` cargo units (at default size) fit in the
# pallet. Callers should also use this to validate per-level stacking:
# - `w` units wide, `l` units long, `h` units tall
# - All three dimensions must be <= the pallet's grid capacity
# Use this from any system that physically stacks cargo on pallets (forklift
# drop, truck unload, conveyor intake).
static func can_fit_on_pallet(w: int, l: int, h: int) -> bool:
	if w <= 0 or l <= 0 or h <= 0:
		return false
	return w <= PALLET_GRID_W and l <= PALLET_GRID_L and h <= PALLET_GRID_H

# Returns the total cargo units the pallet can hold at default size.
static func get_pallet_capacity() -> int:
	return PALLET_GRID_W * PALLET_GRID_L * PALLET_GRID_H

# ─── Helpers ─────────────────────────────────────────────────────────────

static func _tile_center(tx: int, ty: int) -> Vector2:
	return Vector2((tx + 0.5) * CELL_SIZE, (ty + 0.5) * CELL_SIZE)

static func _make_sprite_node(name: String, tex: Texture2D, world_pos: Vector2, z_idx: int = 5) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = name
	s.texture = tex
	s.position = world_pos
	s.centered = true
	s.z_index = z_idx
	return s

static func _add_label(parent: Node, floor_nodes: Array, text: String, world_pos: Vector2, color: Color, font_size: int = 9) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = world_pos
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.z_index = 12
	parent.add_child(lbl)
	floor_nodes.append(lbl)

# Semi-transparent ColorRect around each test sprite. Helps confirm the
# sprite is positioned at the right pixel even when the texture is unclear
# against the warehouse floor tile color.
static func _add_debug_box(parent: Node, floor_nodes: Array, label_text: String, center: Vector2, w: int, h: int, color: Color) -> void:
	var box := ColorRect.new()
	box.color = color
	box.size = Vector2(w, h)
	box.position = center - Vector2(w / 2.0, h / 2.0)
	box.z_index = 8
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	floor_nodes.append(box)

	# Inline label so the user can see what each box is for.
	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = center - Vector2(0, h / 2.0 + 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.z_index = 13
	parent.add_child(lbl)
	floor_nodes.append(lbl)

# Outline of the entire warehouse zone — easy to spot from a distance.
static func _add_debug_zone_box(parent: Node, floor_nodes: Array, zx: int, zy: int, zw: int, zh: int) -> void:
	var x: int = zx * CELL_SIZE
	var y: int = zy * CELL_SIZE
	var w: int = zw * CELL_SIZE
	var h: int = zh * CELL_SIZE

	# Top edge
	var top := ColorRect.new()
	top.color = Color(1.0, 0.2, 0.8, 0.8)
	top.size = Vector2(w, 3)
	top.position = Vector2(x, y)
	top.z_index = 15
	parent.add_child(top); floor_nodes.append(top)

	# Bottom edge
	var bot := ColorRect.new()
	bot.color = Color(1.0, 0.2, 0.8, 0.8)
	bot.size = Vector2(w, 3)
	bot.position = Vector2(x, y + h - 3)
	bot.z_index = 15
	parent.add_child(bot); floor_nodes.append(bot)

	# Left edge
	var left := ColorRect.new()
	left.color = Color(1.0, 0.2, 0.8, 0.8)
	left.size = Vector2(3, h)
	left.position = Vector2(x, y)
	left.z_index = 15
	parent.add_child(left); floor_nodes.append(left)

	# Right edge
	var right := ColorRect.new()
	right.color = Color(1.0, 0.2, 0.8, 0.8)
	right.size = Vector2(3, h)
	right.position = Vector2(x + w - 3, y)
	right.z_index = 15
	parent.add_child(right); floor_nodes.append(right)

static func _add_zone_label(parent: Node, floor_nodes: Array, zx: int, zy: int) -> void:
	var lbl := Label.new()
	lbl.text = "<< WAREHOUSE TEST ZONE — walk here from lobby (south) >>"
	lbl.position = Vector2((zx + 4) * CELL_SIZE, (zy - 4) * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8))
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.z_index = 16
	parent.add_child(lbl)
	floor_nodes.append(lbl)

# ─── Texture builders ──────────────────────────────────────────────────

# Box-truck silhouette: brown cargo box + cab + windshield + 6 wheels.
static func _make_truck_texture() -> ImageTexture:
	var w := 56
	var h := 28
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Cargo box (left half)
	for x in range(0, 36):
		for y in range(4, 22):
			img.set_pixel(x, y, Color(0.50, 0.38, 0.28, 1.0))
	for x in range(0, 36):
		img.set_pixel(x, 4, Color(0.65, 0.52, 0.40, 1.0))
		img.set_pixel(x, 22, Color(0.35, 0.25, 0.18, 1.0))

	# Cab (right)
	for x in range(36, 50):
		for y in range(8, 22):
			img.set_pixel(x, y, Color(0.35, 0.42, 0.55, 1.0))
	# Windshield
	for x in range(38, 48):
		for y in range(9, 14):
			img.set_pixel(x, y, Color(0.55, 0.75, 0.90, 1.0))

	# Wheels (6 small dark squares along the bottom)
	for wx in [4, 14, 24, 38, 46]:
		for wy in [23, 25]:
			for dx in range(0, 4):
				for dy in range(0, 3):
					img.set_pixel(wx + dx, wy + dy, Color(0.10, 0.10, 0.10, 1.0))

	return ImageTexture.create_from_image(img)

# Yellow forklift silhouette: body + mast + forks.
static func _make_forklift_texture() -> ImageTexture:
	var w := 28
	var h := 36
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Body (yellow)
	for x in range(8, 22):
		for y in range(14, 32):
			img.set_pixel(x, y, Color(0.90, 0.70, 0.20, 1.0))
	# Body trim (darker bottom)
	for x in range(8, 22):
		img.set_pixel(x, 31, Color(0.55, 0.42, 0.10, 1.0))
		img.set_pixel(x, 32, Color(0.55, 0.42, 0.10, 1.0))
	# Seat post
	for x in range(18, 22):
		for y in range(8, 14):
			img.set_pixel(x, y, Color(0.30, 0.30, 0.32, 1.0))
	# Mast (gray, top)
	for x in range(10, 18):
		for y in range(2, 12):
			img.set_pixel(x, y, Color(0.55, 0.55, 0.60, 1.0))
	# Forks (gray, right side, sticking out)
	for fx in [2, 4, 6]:
		for y in range(28, 32):
			for dx in range(0, 6):
				img.set_pixel(fx + dx, y, Color(0.65, 0.65, 0.70, 1.0))

	return ImageTexture.create_from_image(img)

# Sedan car (side view) — color-tinted so variants are visually distinct.
static func _make_sedan_texture(body_color: Color) -> ImageTexture:
	var w := 36
	var h := 18
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Lower body (chassis area, full width)
	for x in range(2, 34):
		for y in range(9, 14):
			img.set_pixel(x, y, body_color)

	# Upper body (cabin) — narrower, roof
	for x in range(8, 28):
		for y in range(4, 9):
			img.set_pixel(x, y, body_color)

	# Roof shine (lighter strip on top of cabin)
	for x in range(10, 26):
		img.set_pixel(x, 4, body_color.lightened(0.25))

	# Windshield (front)
	for x in range(24, 28):
		for y in range(5, 8):
			img.set_pixel(x, y, Color(0.75, 0.85, 0.95, 1.0))
	# Rear window
	for x in range(8, 12):
		for y in range(5, 8):
			img.set_pixel(x, y, Color(0.75, 0.85, 0.95, 1.0))
	# Side window strip (middle)
	for x in range(13, 23):
		img.set_pixel(x, 5, Color(0.75, 0.85, 0.95, 1.0))
		img.set_pixel(x, 6, Color(0.75, 0.85, 0.95, 1.0))

	# Body outline (darker)
	for x in range(2, 34):
		img.set_pixel(x, 14, body_color.darkened(0.4))
		img.set_pixel(x, 13, body_color.darkened(0.2))
	# Front bumper + headlights
	for x in range(30, 34):
		img.set_pixel(x, 11, Color(0.95, 0.95, 0.50, 1.0))
		img.set_pixel(x, 12, Color(0.95, 0.95, 0.50, 1.0))
	# Rear bumper + taillights
	for x in range(2, 6):
		img.set_pixel(x, 11, Color(0.85, 0.20, 0.20, 1.0))
		img.set_pixel(x, 12, Color(0.85, 0.20, 0.20, 1.0))

	# Wheels (2 — front and rear)
	for wx in [6, 26]:
		for wy in [13, 15]:
			for dx in range(0, 5):
				for dy in range(0, 4):
					img.set_pixel(wx + dx, wy + dy, Color(0.10, 0.10, 0.10, 1.0))
			# Hub (inside inner wy loop so wy is in scope)
			img.set_pixel(wx + 2, wy + 1, Color(0.65, 0.65, 0.70, 1.0))
			img.set_pixel(wx + 3, wy + 1, Color(0.65, 0.65, 0.70, 1.0))

	return ImageTexture.create_from_image(img)

# Cargo crate on a wooden pallet — three size variants.
# size: 0.5 / 1.0 / 2.0 (default is 1.0 = 16 px wide canvas).
# crate_color: optional override; otherwise uses the variant default.
static func _make_cargo_texture(size: float = 1.0, crate_color: Color = Color(-1, -1, -1, -1)) -> ImageTexture:
	# Canvas: 16 px default; if size is 2.0, scale the canvas to 32 px
	# (so a 2x cargo is genuinely 2x larger, not just zoomed).
	var base_px: int = int(round(CARGO_DEFAULT_PX * size))
	var w: int = base_px
	var h: int = base_px
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Default crate color if not overridden
	var cc: Color = crate_color
	if cc.r < 0:
		match int(round(size * 10)):
			5:
				cc = Color(0.72, 0.55, 0.32, 1.0)  # Small — lighter
			10:
				cc = Color(0.55, 0.45, 0.30, 1.0)  # Medium
			_:
				cc = Color(0.80, 0.60, 0.40, 1.0)  # Large

	# Pallet strip at the bottom (4 px tall)
	var pallet_color := Color(0.45, 0.32, 0.20, 1.0)
	var pallet_h: int = maxi(2, int(round(4 * size)))
	for y in range(h - pallet_h, h):
		for x in range(0, w):
			img.set_pixel(x, y, pallet_color)

	# Crate body (leaves a 1 px border on each side)
	var body_x0: int = maxi(1, int(round(1 * size)))
	var body_y0: int = maxi(1, int(round(1 * size)))
	var body_x1: int = w - body_x0
	var body_y1: int = h - pallet_h - 1
	for y in range(body_y0, body_y1):
		for x in range(body_x0, body_x1):
			img.set_pixel(x, y, cc)

	# Crate top (slightly lighter)
	if w >= 6:
		for x in range(body_x0, body_x1):
			img.set_pixel(x, body_y0, cc.lightened(0.15))

	# Crate frame lines (darker), only if canvas is large enough
	if w >= 8:
		var mid1: int = body_y0 + (body_y1 - body_y0) / 2
		var mid2: int = body_y0 + (body_y1 - body_y0) * 2 / 3
		for y in [mid1, mid2]:
			if y < body_y1:
				for x in range(body_x0, body_x1):
					img.set_pixel(x, y, cc.darkened(0.25))
		for x in [body_x0, body_x1 - 1]:
			for y in range(body_y0, body_y1):
				img.set_pixel(x, y, cc.darkened(0.25))

	# "X" mark on front (only if crate is large enough to show it)
	if w >= 10:
		var cx: int = w / 2
		var cy: int = (body_y0 + body_y1) / 2
		img.set_pixel(cx - 1, cy - 1, cc.darkened(0.4))
		img.set_pixel(cx + 1, cy - 1, cc.darkened(0.4))
		img.set_pixel(cx, cy, cc.darkened(0.4))
		img.set_pixel(cx - 1, cy + 1, cc.darkened(0.4))
		img.set_pixel(cx + 1, cy + 1, cc.darkened(0.4))

	return ImageTexture.create_from_image(img)
