# supermarket_aisle.gd
# A single aisle of shelves. Manages product slots, respawning, and interaction proximity.
# Designed to be data-driven: supply a list of products and slot positions.

class_name SupermarketAisle
extends Node2D

signal interaction_available(product, global_pos: Vector2)
signal interaction_cleared()

const CELL_SIZE := 16.0

var aisle_id: String = ""
var aisle_name: String = ""
var _products: Array = []           # Product objects
var _slots: Array[Vector2i] = []    # Grid positions (local) of each slot
var _slot_states: Array[int] = []   # 0=has item, 1=empty (respawning)
var _respawn_timers: Array[float] = []
var _nearest_slot_idx: int = -1

var _slot_container: Node2D

func _init() -> void:
	_slot_container = Node2D.new()
	_slot_container.name = "SlotContainer"
	add_child(_slot_container)

func setup(p_aisle_id: String, p_aisle_name: String, products: Array, slot_positions: Array[Vector2i]) -> void:
	aisle_id = p_aisle_id
	aisle_name = p_aisle_name
	_products = products
	_slots = slot_positions
	_slot_states.resize(_slots.size())
	_respawn_timers.resize(_slots.size())
	_slot_states.fill(0)
	_respawn_timers.fill(0.0)
	
	_build_visuals()

func _build_visuals() -> void:
	# Create shelf sprite for each slot position
	for i in range(_slots.size()):
		var slot_pos: Vector2i = _slots[i]
		var slot_node := Node2D.new()
		slot_node.position = Vector2(slot_pos.x * CELL_SIZE, slot_pos.y * CELL_SIZE)
		slot_node.name = "Slot%d" % i
		
		var shelf_sprite := Sprite2D.new()
		shelf_sprite.texture = PixelArtGenerator.make_shelf()
		shelf_sprite.hframes = 1
		shelf_sprite.vframes = 1
		slot_node.add_child(shelf_sprite)
		
		var product_sprite := Sprite2D.new()
		product_sprite.name = "Product"
		product_sprite.texture = PixelArtGenerator.make_product(16, _products[i])
		product_sprite.position = Vector2(0, -4)  # sits on top of shelf
		product_sprite.hframes = 1
		product_sprite.vframes = 1
		slot_node.add_child(product_sprite)
		
		_slot_container.add_child(slot_node)

func _process(delta: float) -> void:
	# Handle respawn timers
	for i in range(_slots.size()):
		if _slot_states[i] == 1:  # empty
			_respawn_timers[i] -= delta
			if _respawn_timers[i] <= 0.0:
				_respawn(i)

func _respawn(slot_idx: int) -> void:
	_slot_states[slot_idx] = 0
	_respawn_timers[slot_idx] = 0.0
	_refresh_slot_visual(slot_idx)

func _refresh_slot_visual(slot_idx: int) -> void:
	var slot_node: Node2D = _slot_container.get_child(slot_idx)
	var product_sprite: Sprite2D = slot_node.get_node_or_null("Product")
	if product_sprite == null:
		return
	if _slot_states[slot_idx] == 0:
		product_sprite.texture = PixelArtGenerator.make_product(16, _products[slot_idx])
		product_sprite.visible = true
	else:
		product_sprite.texture = PixelArtGenerator.make_shelf_empty()
		product_sprite.visible = false

# Called by player to try picking up item at given world position
func try_pickup(world_pos: Vector2) -> bool:
	var local_pos := to_local(world_pos)
	var slot_idx := _world_to_slot(local_pos)
	
	if slot_idx < 0 or slot_idx >= _slots.size():
		return false
	if _slot_states[slot_idx] == 1:
		return false  # empty
	
	# Pickup!
	var product = _products[slot_idx]
	_slot_states[slot_idx] = 1
	_respawn_timers[slot_idx] = 30.0  # 30s respawn
	_refresh_slot_visual(slot_idx)
	return true

# Check proximity — returns product if player is adjacent to an available slot
func check_proximity(world_pos: Vector2, threshold: float = 28.0) -> Dictionary:
	var local_pos := to_local(world_pos)
	var nearest_idx := -1
	var nearest_dist := INF
	
	for i in range(_slots.size()):
		if _slot_states[i] == 1:
			continue  # skip empty
		var slot_world := Vector2(_slots[i].x * CELL_SIZE, _slots[i].y * CELL_SIZE)
		var dist := world_pos.distance_to(to_global(slot_world))
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_idx = i
	
	if nearest_idx >= 0 and nearest_dist <= threshold:
		return {"product": _products[nearest_idx], "slot_idx": nearest_idx, "distance": nearest_dist, "aisle_ref": self}
	return {}

# Get all shelf collision rects (for walkability — shelves are solid)
func get_collision_rects() -> Array:
	var rects: Array = []
	for slot_pos in _slots:
		var r := RectangleShape2D.new()
		r.size = Vector2(CELL_SIZE, CELL_SIZE)
		var mr := CollisionShape2D.new()
		mr.shape = r
		mr.position = Vector2(slot_pos.x * CELL_SIZE + CELL_SIZE/2, slot_pos.y * CELL_SIZE + CELL_SIZE/2)
		rects.append(mr)
	return rects

func _world_to_slot(local_pos: Vector2) -> int:
	var gx := int(floor(local_pos.x / CELL_SIZE))
	var gy := int(floor(local_pos.y / CELL_SIZE))
	for i in range(_slots.size()):
		if _slots[i].x == gx and _slots[i].y == gy:
			return i
	return -1
