# shelf_panel.gd
# Warehouse Shelf Panel - displays storage shelves with items placed by factory robots
# Players can view the shelf contents
class_name ShelfPanel
extends CanvasLayer

const PixelArtGenerator = preload("res://scripts/pixel_art_generator.gd")

const CELL_SIZE := 16
const SHELF_SLOTS_X := 8   # slots per shelf row
const SHELF_SLOTS_Y := 6   # rows of shelves
const SLOT_SIZE := 20      # pixels per slot

var _is_open := false
var _container: Control = null
var _shelf_grid: GridContainer = null
var _slots: Array = []  # Array of {sprite: Sprite2D, item: Dictionary}

# Warehouse inventory reference
var _warehouse_inventory: Dictionary = {}

signal closed()

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
	closed.emit()

func _clear_ui() -> void:
	if _container:
		_container.queue_free()
		_container = null
	_shelf_grid = null
	_slots.clear()

func _build_ui() -> void:
	_clear_ui()
	
	# Main container - dark semi-transparent background
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.add_theme_color_override("bg_color", Color(0.02, 0.02, 0.05, 0.95))
	add_child(_container)
	
	# Title
	var title := Label.new()
	title.text = "WAREHOUSE STORAGE SHELVES"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.position = Vector2(0, 10)
	title.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_container.add_child(title)
	
	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Items stored by factory robots  |  Press [E] or [ESC] to close"
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.position = Vector2(0, 35)
	subtitle.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_container.add_child(subtitle)
	
	# Shelf grid container
	var grid_container := Control.new()
	grid_container.position = Vector2(40, 60)
	grid_container.size = Vector2(720, 480)
	_container.add_child(grid_container)
	
	# Create scroll container for shelves
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size = Vector2(720, 480)
	grid_container.add_child(scroll)
	
	# Inner panel for shelf grid
	var inner := Control.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner)
	
	# Shelf grid - vertical arrangement of shelves
	_shelf_grid = GridContainer.new()
	_shelf_grid.columns = 1  # One shelf row per entry
	_shelf_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_shelf_grid)
	
	# Build the shelf visual
	_build_shelf_visual()
	
	# Load current inventory
	_update_shelf_from_inventory()

func _build_shelf_visual() -> void:
	_slots.clear()
	
	# Create shelf rows
	for row in range(SHELF_SLOTS_Y):
		# Shelf row container (horizontal box)
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.custom_minimum_size.y = SLOT_SIZE + 8
		_shelf_grid.add_child(hbox)
		
		# Shelf background
		var shelf_bg := ColorRect.new()
		shelf_bg.color = Color(0.25, 0.22, 0.18)
		shelf_bg.custom_minimum_size.y = SLOT_SIZE + 4
		shelf_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(shelf_bg)
		
		# Create individual slots
		for col in range(SHELF_SLOTS_X):
			var slot_container := Control.new()
			slot_container.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
			slot_container.name = "slot_%d_%d" % [row, col]
			hbox.add_child(slot_container)
			
			# Create empty slot sprite
			var slot_sprite := Sprite2D.new()
			slot_sprite.texture = _make_empty_slot_texture()
			slot_sprite.position = Vector2(SLOT_SIZE / 2, SLOT_SIZE / 2)
			slot_container.add_child(slot_sprite)
			
			_slots.append({
				"row": row,
				"col": col,
				"container": slot_container,
				"sprite": slot_sprite,
				"item": null
			})

func _make_empty_slot_texture() -> Texture2D:
	var img := Image.create(SLOT_SIZE, SLOT_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # transparent
	
	# Draw a simple box outline for empty slot
	var box_color := Color(0.35, 0.32, 0.28, 0.5)
	for x in range(SLOT_SIZE):
		img.set_pixel(x, 0, box_color)
		img.set_pixel(x, SLOT_SIZE - 1, box_color)
	for y in range(SLOT_SIZE):
		img.set_pixel(0, y, box_color)
		img.set_pixel(SLOT_SIZE - 1, y, box_color)
	
	return ImageTexture.create_from_image(img)

func _update_shelf_from_inventory() -> void:
	# Get warehouse inventory from warehouse system
	var main = get_tree().root.get_node_or_null("Main")
	if main == null:
		return
	
	var warehouse = main.get_node_or_null("Warehouse")
	if warehouse == null or not warehouse.has_method("get_all_stock"):
		return
	
	var stock: Dictionary = warehouse.get_all_stock()
	
	# Map stock to shelf slots
	var slot_idx := 0
	for section_id in stock.keys():
		var qty: int = stock[section_id]
		if qty <= 0:
			continue
		
		# Create product info for this item
		var item_info := {
			"section": section_id,
			"quantity": qty,
			"color": _get_section_color(section_id)
		}
		
		# Place in slot
		if slot_idx < _slots.size():
			_place_item_in_slot(slot_idx, item_info)
			slot_idx += 1
		
		# Add more slots if needed (stack items)
		while qty > 1 and slot_idx < _slots.size():
			qty -= 1
			slot_idx += 1

func _get_section_color(section_id: String) -> Color:
	# Return color based on section type
	match section_id:
		"produce": return Color(0.72, 0.92, 0.56)   # Green
		"dairy": return Color(0.70, 0.88, 1.00)    # Blue
		"bakery": return Color(0.98, 0.82, 0.52)   # Yellow
		"meat": return Color(0.95, 0.72, 0.68)     # Red
		"frozen": return Color(0.78, 0.92, 1.00)   # Light blue
		"drinks": return Color(0.60, 0.85, 0.95)  # Cyan
		"snacks": return Color(0.95, 0.90, 0.80)   # Cream
		"beauty": return Color(0.88, 0.72, 0.80)   # Pink
		"shoes_ladies": return Color(0.82, 0.55, 0.65)  # Pink
		"shoes_mens": return Color(0.55, 0.60, 0.80)    # Blue
		"shoes_kids": return Color(0.70, 0.75, 0.90)   # Light blue
		"gym": return Color(0.55, 0.75, 0.65)           # Teal
		"sports_gear": return Color(0.45, 0.65, 0.85)    # Steel blue
		_: return Color(0.75, 0.65, 0.55)  # Brown

func _place_item_in_slot(slot_idx: int, item_info: Dictionary) -> void:
	if slot_idx >= _slots.size():
		return
	
	var slot: Dictionary = _slots[slot_idx]
	slot["item"] = item_info
	
	# Create product sprite
	var product_sprite := Sprite2D.new()
	product_sprite.texture = _make_product_sprite_texture(item_info["color"])
	product_sprite.position = Vector2(SLOT_SIZE / 2, SLOT_SIZE / 2)
	slot["container"].add_child(product_sprite)
	slot["sprite"] = product_sprite

func _make_product_sprite_texture(color: Color) -> Texture2D:
	# Create a small box/bucket sprite representing stored items
	var img := Image.create(SLOT_SIZE - 4, SLOT_SIZE - 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Draw a simple crate/box
	var dark := color.darkened(0.3)
	var light := color.lightened(0.2)
	
	# Main box body
	for x in range(2, SLOT_SIZE - 6):
		for y in range(2, SLOT_SIZE - 6):
			img.set_pixel(x, y, color)
	
	# Top highlight
	for x in range(2, SLOT_SIZE - 6):
		img.set_pixel(x, 2, light)
		img.set_pixel(x, 3, light)
	
	# Bottom shadow
	for x in range(2, SLOT_SIZE - 6):
		img.set_pixel(x, SLOT_SIZE - 7, dark)
		img.set_pixel(x, SLOT_SIZE - 6, dark)
	
	# Left shadow
	for y in range(2, SLOT_SIZE - 6):
		img.set_pixel(2, y, dark)
	
	# Right highlight
	for y in range(2, SLOT_SIZE - 6):
		img.set_pixel(SLOT_SIZE - 7, y, light)
	
	return ImageTexture.create_from_image(img)

# Called by factory robots to add item to shelf
func add_item_to_shelf(section_id: String, quantity: int = 1) -> void:
	var color := _get_section_color(section_id)
	var item_info := {
		"section": section_id,
		"quantity": quantity,
		"color": color
	}
	
	# Find an empty slot
	for slot in _slots:
		if slot["item"] == null:
			_place_item_in_slot(_slots.find(slot), item_info)
			return
	
	# If no empty slots, create overflow display
	_update_shelf_from_inventory()

# Input handling
func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			close()
