# checkout_counter.gd
# A single checkout lane with desk + register.

class_name CheckoutCounter
extends Node2D

var counter_id: int = 0

func _init() -> void:
	pass

func setup(p_id: int, grid_pos: Vector2i) -> void:
	counter_id = p_id
	position = Vector2(grid_pos.x * 16.0, grid_pos.y * 16.0)
	_build_visuals()

func _build_visuals() -> void:
	var desk_sprite := Sprite2D.new()
	desk_sprite.texture = PixelArtGenerator.make_checkout_desk()
	desk_sprite.hframes = 1
	desk_sprite.vframes = 1
	# Center the 32×16 sprite on the grid cell
	desk_sprite.position = Vector2(16, 8)
	add_child(desk_sprite)
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 16)
	col.shape = shape
	col.position = Vector2(16, 8)  # Center of the desk
	add_child(col)

func is_checkout_counter() -> bool:
	return true
