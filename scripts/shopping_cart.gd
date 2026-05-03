# shopping_cart.gd
# Manages the player's shopping cart — items, total, max capacity.

class_name ShoppingCart
extends Node

signal cart_updated(items: Array)

const MAX_ITEMS := 20

var _items: Array[Dictionary] = []  # Each entry: {id, product}

func add_item(product) -> bool:
	if _items.size() >= MAX_ITEMS:
		return false
	_items.append({"id": product.id, "product": product})
	cart_updated.emit(_items)
	return true

func remove_item(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	_items.remove_at(index)
	cart_updated.emit(_items)

func clear() -> void:
	_items.clear()
	cart_updated.emit(_items)

func get_items() -> Array:
	return _items

func get_count() -> int:
	return _items.size()

func get_total() -> float:
	var total := 0.0
	for entry in _items:
		total += entry["product"].price
	return total

func is_empty() -> bool:
	return _items.is_empty()
