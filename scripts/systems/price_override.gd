# price_override.gd
class_name PriceOverride
# Singleton that stores price overrides set via the staff terminal.
# Products reference this FIRST, then fall back to store_data.gd.
# Signal: price_changed(product_id, new_price)
extends Node

const StoreData = preload("res://scripts/world/store_data.gd")

# product_id → float (override price)
var _overrides: Dictionary = {}

signal price_changed(product_id: String, new_price: float)
signal price_overrides_updated()  # broadcast when batch update happens

# 单例全局实例（关键修复）
static var singleton: PriceOverride = null

func _ready() -> void:
	# 设置全局单例实例
	singleton = self
	add_to_group("price_override")

# Get the effective price for a product (override or original)
static func get_price(product_id: String) -> float:
	if not is_instance_valid(singleton):
		return 0.0
	if singleton._overrides.has(product_id):
		return singleton._overrides[product_id]
	# Fall back to store data
	for p in StoreData.CATALOG:
		if p.id == product_id:
			return p.price
	return 0.0

# Set an override price
static func set_price(product_id: String, price: float) -> void:
	if not is_instance_valid(singleton):
		return
	if price <= 0.0:
		# Remove override (revert to original)
		if singleton._overrides.has(product_id):
			singleton._overrides.erase(product_id)
	else:
		singleton._overrides[product_id] = price
	singleton.price_changed.emit(product_id, price)

# Clear all overrides
static func clear_all() -> void:
	if not is_instance_valid(singleton):
		return
	singleton._overrides.clear()
	singleton.price_overrides_updated.emit()

# Check if a product has an override
static func has_override(product_id: String) -> bool:
	if not is_instance_valid(singleton):
		return false
	return singleton._overrides.has(product_id)

# Get all overrides as dict
static func get_all_overrides() -> Dictionary:
	if not is_instance_valid(singleton):
		return {}
	return singleton._overrides.duplicate()

# Apply a batch of overrides (for loading saves)
static func apply_batch(overrides: Dictionary) -> void:
	if not is_instance_valid(singleton):
		return
	singleton._overrides = overrides.duplicate()
	singleton.price_overrides_updated.emit()

# Get the original price from store_data (ignoring overrides)
static func get_original_price(product_id: String) -> float:
	for p in StoreData.CATALOG:
		if p.id == product_id:
			return p.price
	return 0.0

# Get product object with effective price (returns a dict-like object)
# For use in UI displays
static func get_product_display(product) -> Dictionary:
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
