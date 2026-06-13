# debug_sprite_viewer.gd
# Debug room that displays all procedural sprites in the game
# Shows characters, robots, checkout counters, sections, products, etc.
class_name DebugSpriteViewer
extends CanvasLayer

const ActorData = preload("res://scripts/entities/actor_data.gd")
const PixelArtGenerator = preload("res://scripts/utils/pixel_art_generator.gd")
const NPCSprite = preload("res://scripts/entities/npc_sprite.gd")

const CELL_SIZE := 16

var _is_open := false
var _container: Control = null
var _scroll_container: ScrollContainer = null

# Sprite collections
var _sprite_entries: Array = []  # {name, texture, description}

func _ready() -> void:
	visible = false

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func open() -> void:
	_is_open = true
	visible = true
	_build_ui()

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()

func _clear_ui() -> void:
	if _container:
		_container.queue_free()
		_container = null
	_scroll_container = null

func _build_ui() -> void:
	_clear_ui()
	
	# Main container
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.add_theme_color_override("bg_color", Color(0.02, 0.02, 0.05, 0.98))
	add_child(_container)
	
	# Title
	var title := Label.new()
	title.text = "SPRITE DEBUG VIEWER"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position = Vector2(0, 10)
	title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_container.add_child(title)
	
	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Press F4 to close  |  All procedural sprites"
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.position = Vector2(0, 35)
	subtitle.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_container.add_child(subtitle)
	
	# Scroll container for sprites
	_scroll_container = ScrollContainer.new()
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.position = Vector2(0, 60)
	_scroll_container.size = Vector2(800, 540)
	_container.add_child(_scroll_container)
	
	# Inner grid container
	var grid := VBoxContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(grid)
	
	# Collect and display all sprites
	_collect_sprites()
	_display_sprites_in_grid(grid)

func _collect_sprites() -> void:
	_sprite_entries.clear()
	
	# ─── NPC Sprites ─────────────────────────────────────────────────
	_sprite_entries.append({"category": "NPC CHARACTERS", "sprites": []})
	var npc_sprites = _sprite_entries[-1]["sprites"]
	
	# NPC variations
	var appearances := [
		{"name": "Adult NPC 1", "top": Color(0.28, 0.42, 0.78), "bottom": Color(0.22, 0.22, 0.42), "skin": Color(0.88, 0.68, 0.48), "hair": Color(0.18, 0.12, 0.08), "life": ActorData.LifeStage.ADULT},
		{"name": "Adult NPC 2", "top": Color(0.78, 0.28, 0.28), "bottom": Color(0.22, 0.22, 0.42), "skin": Color(0.72, 0.52, 0.38), "hair": Color(0.62, 0.42, 0.22), "life": ActorData.LifeStage.ADULT},
		{"name": "Adult NPC 3", "top": Color(0.28, 0.68, 0.42), "bottom": Color(0.32, 0.38, 0.52), "skin": Color(0.55, 0.38, 0.28), "hair": Color(0.10, 0.10, 0.10), "life": ActorData.LifeStage.ADULT},
		{"name": "Teen NPC", "top": Color(0.88, 0.68, 0.28), "bottom": Color(0.22, 0.32, 0.22), "skin": Color(0.96, 0.80, 0.65), "hair": Color(0.28, 0.22, 0.18), "life": ActorData.LifeStage.TEEN},
		{"name": "Senior NPC", "top": Color(0.42, 0.42, 0.48), "bottom": Color(0.38, 0.38, 0.42), "skin": Color(0.88, 0.68, 0.48), "hair": Color(0.10, 0.10, 0.10), "life": ActorData.LifeStage.SENIOR},
		{"name": "Child NPC", "top": Color(0.88, 0.38, 0.28), "bottom": Color(0.32, 0.32, 0.42), "skin": Color(0.96, 0.80, 0.65), "hair": Color(0.92, 0.72, 0.35), "life": ActorData.LifeStage.CHILD},
	]
	
	for app in appearances:
		var actor: ActorData.Actor = ActorData.Actor.new()
		actor.appearance = ActorData.Appearance.new()
		actor.appearance.top.color = app["top"]
		actor.appearance.bottom.color = app["bottom"]
		actor.appearance.skin_tone = app["skin"]
		actor.appearance.hair.color = app["hair"]
		actor.appearance.shoes_color = Color(0.18, 0.18, 0.18)
		actor.appearance.hair.style = 0
		actor.appearance.has_glasses = false
		actor.appearance.shoes_style = 0
		actor.appearance.bottom.style = 0
		actor.appearance.top.style = 0
		var life: int = app["life"]
		var tex: Texture2D = NPCSprite.make_actor_texture(actor.appearance, 16, life)
		npc_sprites.append({"name": app["name"], "texture": tex})
	
	# ─── Robot Sprites ──────────────────────────────────────────────
	_sprite_entries.append({"category": "HUMANOID ROBOTS", "sprites": []})
	var humanoid_sprites = _sprite_entries[-1]["sprites"]
	
	# Create robot controller to generate textures
	var robot_ctrl = preload("res://scripts/entities/robot_controller.gd").new()
	
	# Configure each robot type and capture texture
	var staff_roles := [
		{ActorData.StaffRole.CASHIER: "Robo-Cashier"},
		{ActorData.StaffRole.SHELF_STOCKER: "Robo-Stocker"},
		{ActorData.StaffRole.CLEANER: "Robo-Cleaner"},
		{ActorData.StaffRole.SECURITY: "Robo-Security"},
		{ActorData.StaffRole.GREETER: "Robo-Greeter"},
		{ActorData.StaffRole.MANAGER: "Robo-Manager"},
	]
	
	for sr in staff_roles:
		for role in sr.keys():
			robot_ctrl.configure_humanoid(role, Vector2.ZERO)
			if robot_ctrl._sprite and robot_ctrl._sprite.texture:
				humanoid_sprites.append({"name": sr[role], "texture": robot_ctrl._sprite.texture})
	
	robot_ctrl.queue_free()
	
	# ─── SINGLE-FUNCTION Robots ──────────────────────────────────────
	_sprite_entries.append({"category": "SINGLE-FUNCTION ROBOTS", "sprites": []})
	var robot_sprites = _sprite_entries[-1]["sprites"]
	
	var robot_roles := [
		{ActorData.RobotRole.CLEANING_ROBOT: "CleanerBot"},
		{ActorData.RobotRole.GUIDANCE_ROBOT: "GuideBot"},
		{ActorData.RobotRole.DELIVERY_ROBOT: "DeliveryBot"},
		{ActorData.RobotRole.SECURITY_ROBOT: "SecurityBot"},
		{ActorData.RobotRole.SHELF_ROBOT: "ShelfBot"},
	]
	
	robot_ctrl = preload("res://scripts/entities/robot_controller.gd").new()
	for rr in robot_roles:
		for role in rr.keys():
			robot_ctrl.configure_single_function(role, Vector2.ZERO)
			if robot_ctrl._sprite and robot_ctrl._sprite.texture:
				robot_sprites.append({"name": rr[role], "texture": robot_ctrl._sprite.texture})
	robot_ctrl.queue_free()
	
	# ─── Checkout Counters ──────────────────────────────────────────
	_sprite_entries.append({"category": "CHECKOUT COUNTERS", "sprites": []})
	var checkout_sprites = _sprite_entries[-1]["sprites"]
	
	# Use PixelArtGenerator directly for checkout desk
	checkout_sprites.append({"name": "Staffed Checkout", "texture": PixelArtGenerator.make_checkout_desk()})
	checkout_sprites.append({"name": "Self-Checkout", "texture": PixelArtGenerator.make_checkout_desk()})
	checkout_sprites.append({"name": "Express Lane", "texture": PixelArtGenerator.make_checkout_desk()})
	
	# ─── Products (Sample) ───────────────────────────────────────────
	_sprite_entries.append({"category": "PRODUCTS", "sprites": []})
	var product_sprites = _sprite_entries[-1]["sprites"]
	
	var product_colors := [
		Color(0.80, 0.30, 0.30),
		Color(0.30, 0.80, 0.30),
		Color(0.30, 0.30, 0.80),
		Color(0.80, 0.80, 0.30),
		Color(0.80, 0.30, 0.80),
		Color(0.30, 0.80, 0.80),
		Color(0.90, 0.60, 0.30),
		Color(0.60, 0.90, 0.60),
	]
	
	for i in range(24):
		var shape: int = i % 7
		var col: Color = product_colors[i % product_colors.size()]
		var tex: Texture2D = PixelArtGenerator.make_product_texture(col, shape, 16)
		product_sprites.append({"name": "Product %d" % (i + 1), "texture": tex})
	
	# ─── Floor & Wall Tiles ─────────────────────────────────────────
	_sprite_entries.append({"category": "TILES & STRUCTURE", "sprites": []})
	var tile_sprites = _sprite_entries[-1]["sprites"]
	
	tile_sprites.append({"name": "Floor Tile", "texture": PixelArtGenerator.make_floor_tile()})
	tile_sprites.append({"name": "Floor Tile Alt", "texture": PixelArtGenerator.make_floor_tile_alt()})
	tile_sprites.append({"name": "Wall", "texture": PixelArtGenerator.make_wall()})
	tile_sprites.append({"name": "Shelf", "texture": PixelArtGenerator.make_shelf()})
	tile_sprites.append({"name": "Empty Shelf", "texture": PixelArtGenerator.make_shelf_empty()})
	
	# ─── Player & Cart ───────────────────────────────────────────────
	_sprite_entries.append({"category": "PLAYER & CART", "sprites": []})
	var player_sprites = _sprite_entries[-1]["sprites"]
	
	player_sprites.append({"name": "Player", "texture": PixelArtGenerator.make_player()})
	player_sprites.append({"name": "Shopping Cart", "texture": PixelArtGenerator.make_cart()})
	
	# ─── Shoes ─────────────────────────────────────────────────────
	_sprite_entries.append({"category": "SHOES", "sprites": []})
	var shoes_sprites = _sprite_entries[-1]["sprites"]
	
	var shoe_colors := [
		Color(0.82, 0.55, 0.65),  # LADIES (pinkish)
		Color(0.55, 0.6, 0.8),    # MENS (blueish)
		Color(0.7, 0.75, 0.9),    # KIDS (light blue)
		Color(0.55, 0.8, 0.65)    # SPORT (green)
	]
	var shoe_names := ["Sneaker", "Formal", "Sandal", "Boot"]
	for i in range(4):
		for style in range(4):
			var tex := PixelArtGenerator.make_shoe(shoe_colors[i], style)
			shoes_sprites.append({"name": shoe_names[style], "texture": tex})
	
	# ─── Clothing ───────────────────────────────────────────────────
	_sprite_entries.append({"category": "CLOTHING", "sprites": []})
	var clothing_sprites = _sprite_entries[-1]["sprites"]
	
	var clothing_colors := [
		Color(0.88, 0.58, 0.72),  # LADIES (pink)
		Color(0.6, 0.68, 0.88),    # MENS (blue)
		Color(0.72, 0.8, 0.95)     # KIDS (light)
	]
	var clothing_names := ["Dress", "T-Shirt", "Pants", "Jacket"]
	for i in range(3):
		for style in range(4):
			var tex := PixelArtGenerator.make_clothing(clothing_colors[i], style)
			clothing_sprites.append({"name": clothing_names[style], "texture": tex})
	
	# ─── Sports Equipment ──────────────────────────────────────────
	_sprite_entries.append({"category": "SPORTS EQUIPMENT", "sprites": []})
	var sports_sprites = _sprite_entries[-1]["sprites"]
	
	var sports_colors := [
		Color(0.55, 0.7, 0.8),   # GYM (blue)
		Color(0.65, 0.6, 0.55),   # SPORTS GEAR (brown)
		Color(0.7, 0.55, 0.55)   # TEAM (red)
	]
	var sports_names := ["Dumbbell", "Ball", "Yoga Mat", "Racket", "Helmet"]
	for i in range(3):
		for style in range(5):
			var tex := PixelArtGenerator.make_sports_equipment(sports_colors[i], style)
			sports_sprites.append({"name": sports_names[style], "texture": tex})

func _display_sprites_in_grid(grid: VBoxContainer) -> void:
	for entry in _sprite_entries:
		var category: String = entry["category"]
		var sprites: Array = entry["sprites"]
		
		# Category header
		var header := Label.new()
		header.text = "═══ %s ═══" % category
		header.add_theme_color_override("font_color", Color(0.60, 0.85, 1.0))
		header.add_theme_font_size_override("font_size", 14)
		grid.add_child(header)
		
		# Sprite grid (3 columns)
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(hbox)
		
		var col_count := 0
		for sprite_entry in sprites:
			var name: String = sprite_entry["name"]
			var tex: Texture2D = sprite_entry["texture"]
			
			if tex == null:
				continue
			
			# Create sprite display
			var sprite_display := VBoxContainer.new()
			sprite_display.custom_minimum_size = Vector2(150, 100)
			hbox.add_child(sprite_display)
			
			# Sprite
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.position = Vector2(75, 50)
			
			var sp_container := Control.new()
			sp_container.custom_minimum_size = Vector2(150, 70)
			sp_container.add_child(sp)
			sprite_display.add_child(sp_container)
			
			# Name label
			var lbl := Label.new()
			lbl.text = name
			lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sprite_display.add_child(lbl)
			
			col_count += 1
			if col_count >= 3:
				col_count = 0
				hbox = HBoxContainer.new()
				hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(hbox)
		
		# Spacer
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		grid.add_child(spacer)

# Input handling
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F4:
			toggle()
