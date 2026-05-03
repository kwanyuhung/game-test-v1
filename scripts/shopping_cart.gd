# shopping_cart.gd
class_name ShoppingCart
extends Node
const StoreData = preload("res://scripts/store_data.gd")

const MAX_ITEMS := 30

var _items: Array = []   # Array[StoreData.MarketProduct]

func _ready() -> void:
	pass

func add_item(product: StoreData.MarketProduct) -> bool:
	if _items.size() >= MAX_ITEMS:
		return false
	_items.append(product)
	return true

func get_items() -> Array:
	return _items

func get_item_count() -> int:
	return _items.size()

func get_total() -> float:
	var total := 0.0
	for item in _items:
		var p: StoreData.MarketProduct = item
		total += p.price
	return total

func clear() -> void:
	_items.clear()

func is_empty() -> bool:
	return _items.size() == 0
