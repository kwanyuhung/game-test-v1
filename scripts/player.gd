# player.gd
# Player character with shopping cart. Handles movement, cart following, and item interaction.

class_name Player
extends CharacterBody2D

const SPEED := 120.0
const CART_OFFSET := 14.0

var _sprite: Sprite2D
var _cart: ShoppingCart
var _cart_sprite: Sprite2D
var _cart_node: Node2D

var _facing_dir := Vector2.DOWN
var _interact_target: Dictionary = {}
var _interact_prompt: String = ""
var _world: Node2D = null

signal cart_count_changed(count: int)
signal interact_prompt_changed(prompt: String)
signal checkout_available

func _init() -> void:
	_sprite = Sprite2D.new()
	_cart = ShoppingCart.new()
	_cart_sprite = Sprite2D.new()
	_cart_node = Node2D.new()
	
	_cart_node.name = "CartNode"
	_cart_sprite.name = "CartSprite"
	add_child(_cart_node)
	_cart_node.add_child(_cart_sprite)
	add_child(_sprite)
	add_child(_cart)
	
	_cart.cart_updated.connect(_on_cart_updated)

func _ready() -> void:
	_sprite.texture = PixelArtGenerator.make_player(16)
	_sprite.hframes = 1
	_sprite.vframes = 1
	_sprite.position = Vector2.ZERO
	
	_cart_sprite.texture = PixelArtGenerator.make_cart()
	_cart_sprite.hframes = 1
	_cart_sprite.vframes = 1
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 10)
	col.shape = shape
	col.position = Vector2.ZERO
	add_child(col)

func _physics_process(delta: float) -> void:
	var input_dir := _read_input()
	
	if input_dir.length() > 0.1:
		_facing_dir = input_dir.normalized()
		var move_vel := _facing_dir * SPEED
		var collided := move_and_collide(move_vel * delta)
		_update_cart_position()
	
	_update_interaction_prompt()
	
	if Input.is_action_just_pressed("interact"):
		_do_interact()

func _read_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_up"):    v.y -= 1
	if Input.is_action_pressed("move_down"):  v.y += 1
	if Input.is_action_pressed("move_left"): v.x -= 1
	if Input.is_action_pressed("move_right"): v.x += 1
	return v.normalized() if v.length() > 1 else v

func _update_cart_position() -> void:
	var offset := -_facing_dir * CART_OFFSET
	var perp := Vector2(-_facing_dir.y, _facing_dir.x) * 4.0
	_cart_node.position = offset + perp
	if absf(_facing_dir.x) > 0.5:
		_cart_sprite.flip_v = false
		_cart_sprite.flip_h = _facing_dir.x < 0

func _update_interaction_prompt() -> void:
	if _world == null:
		return
	
	var best: Dictionary = {}
	var best_dist := INF
	
	for aisle in _get_aisles():
		var result: Dictionary = aisle.check_proximity(global_position)
		if result.size() > 0 and result.get("distance", INF) < best_dist:
			best = result
			best_dist = result.get("distance", INF)
	
	for counter in _get_checkout_counters():
		var d := global_position.distance_to(counter.global_position)
		if d < 36 and _cart.get_count() > 0:
			if d < best_dist:
				best = {"type": "checkout", "counter": counter}
				best_dist = d
	
	_interact_target = best
	if best.has("product"):
		_interact_prompt = "[E] Pick up %s — $%.2f" % [best["product"].name, best["product"].price]
	elif best.has("type") and best["type"] == "checkout":
		_interact_prompt = "[E] Checkout ( %d items — $%.2f )" % [_cart.get_count(), _cart.get_total()]
	else:
		_interact_prompt = ""
	
	interact_prompt_changed.emit(_interact_prompt)

func _do_interact() -> void:
	if _interact_target.has("product"):
		var aisle: SupermarketAisle = _interact_target.get("aisle_ref")
		if aisle and aisle.try_pickup(global_position):
			var product = _interact_target["product"]
			_cart.add_item(product)
	elif _interact_target.has("type") and _interact_target["type"] == "checkout":
		checkout_available.emit()

func _on_cart_updated(_items: Array) -> void:
	cart_count_changed.emit(_cart.get_count())

func set_world(world: Node2D) -> void:
	_world = world

func get_cart() -> ShoppingCart:
	return _cart

func _get_aisles() -> Array:
	if _world == null:
		return []
	var aisles: Array = []
	for child in _world.get_children():
		if child is SupermarketAisle:
			aisles.append(child)
	return aisles

func _get_checkout_counters() -> Array:
	if _world == null:
		return []
	var counters: Array = []
	for child in _world.get_children():
		if child.has_method("is_checkout_counter"):
			counters.append(child)
	return counters
