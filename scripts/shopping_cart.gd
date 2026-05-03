# shopping_cart.gd
# Shopping cart holds selected products with quantities.
class_name ShoppingCart
extends Node

const StoreData = preload("res://scripts/store_data.gd")

# Each entry: { product: MarketProduct, qty: int }
var _items: Array = []
var _max_items := 30

signal cart_updated(item_count: int, unique_count: int)

func add_item(product, qty: int = 1) -> void:
	# Merge with existing entry if same product
	for entry in _items:
		if entry["product"].id == product.id:
			entry["qty"] += qty
			cart_updated.emit(get_total_item_count(), _items.size())
			return
	# New entry
	_items.append({"product": product, "qty": qty})
	cart_updated.emit(get_total_item_count(), _items.size())

func remove_item(product_id: String) -> void:
	for i in range(_items.size()):
		if _items[i]["product"].id == product_id:
			_items.remove_at(i)
			break
	cart_updated.emit(get_total_item_count(), _items.size())

func set_qty(product_id: String, qty: int) -> void:
	for entry in _items:
		if entry["product"].id == product_id:
			if qty <= 0:
				remove_item(product_id)
			else:
				entry["qty"] = qty
			break
	cart_updated.emit(get_total_item_count(), _items.size())

func get_items() -> Array:
	return _items

func get_total_item_count() -> int:
	var total := 0
	for entry in _items:
		total += entry["qty"]
	return total

func get_item_count() -> int:
	return _items.size()

func get_subtotal() -> float:
	var total := 0.0
	for entry in _items:
		total += entry["product"].price * entry["qty"]
	return total

func get_tax(rate: float = 0.06) -> float:
	return get_subtotal() * rate

func get_total(rate: float = 0.06) -> float:
	return get_subtotal() + get_tax(rate)

func clear() -> void:
	_items.clear()
	cart_updated.emit(0, 0)

func is_empty() -> bool:
	return _items.size() == 0
