# price_override.gd
# Singleton that stores price overrides set via the staff terminal.
# Products reference this FIRST, then fall back to store_data.gd.
# Signal: price_changed(product_id, new_price)
extends Node

const StoreData = preload("res://scripts/store_data.gd")

# product_id → float (override price)
var _overrides: Dictionary = {}

signal price_changed(product_id: String, new_price: float)
signal price_overrides_updated()  # broadcast when batch update happens

func _ready() -> void:
	# Make sure this is a singleton (add to tree once)
	add_to_group("price_override")

# Get the effective price for a product (override or original)
func get_price(product_id: String) -> float:
	if _overrides.has(product_id):
		return _overrides[product_id]
	# Fall back to store data
	for p in StoreData.CATALOG:
		if p.id == product_id:
			return p.price
	return 0.0

# Set an override price
func set_price(product_id: String, price: float) -> void:
	if price <= 0.0:
		# Remove override (revert to original)
		if _overrides.has(product_id):
			_overrides.erase(product_id)
	else:
		_overrides[product_id] = price
	price_changed.emit(product_id, price)

# Clear all overrides
func clear_all() -> void:
	_overrides.clear()
	price_overrides_updated.emit()

# Check if a product has an override
func has_override(product_id: String) -> bool:
	return _overrides.has(product_id)

# Get all overrides as dict
func get_all_overrides() -> Dictionary:
	return _overrides.duplicate()

# Apply a batch of overrides (for loading saves)
func apply_batch(overrides: Dictionary) -> void:
	_overrides = overrides.duplicate()
	price_overrides_updated.emit()

# Get the original price from store_data (ignoring overrides)
func get_original_price(product_id: String) -> float:
	for p in StoreData.CATALOG:
		if p.id == product_id:
			return p.price
	return 0.0

# Get product object with effective price (returns a dict-like object)
# For use in UI displays
func get_product_display(product) -> Dictionary:
	return {
		"id": product.id,
		"name": product.name,
		"price": get_price(product.id),
		"original_price": product.price,
		"has_override": has_override(product.id),
		"section": product.section,
		"sub": product.sub,
		"desc": product.desc,
		"color": product.color,
		"shape": product.shape,
	}
