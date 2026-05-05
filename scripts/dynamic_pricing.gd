# scripts/dynamic_pricing.gd
# Phase R: Dynamic Pricing — stock level affects product prices
class_name DynamicPricingScript
extends Node

# Price modifiers per section: 0.8 (20% off at full stock) to 1.3 (+30% at empty)
# Formula: modifier = 1.3 - (stock_ratio * 0.5)
# At 100% stock: 1.3 - 0.5 = 0.8 (20% discount)
# At 50% stock:  1.3 - 0.25 = 1.05 (5% markup)
# At 0% stock:   1.3 - 0.0 = 1.30 (30% markup)

func _ready() -> void:
	pass

func get_price_multiplier_for_section(section_id: String, warehouse_ref) -> float:
	if warehouse_ref == null:
		return 1.0
	var ratio := 1.0
	if warehouse_ref.has_method("get_stock_ratio"):
		ratio = warehouse_ref.get_stock_ratio(section_id)
	# Clamp ratio to 0-1
	ratio = clampf(ratio, 0.0, 1.0)
	# Linear interpolation: high stock = discount, low stock = premium
	# ratio 1.0 (full) → 0.8 discount, ratio 0.0 (empty) → 1.3 premium
	var modifier := 1.3 - (ratio * 0.5)
	return modifier  # range: 0.8 to 1.3

func get_adjusted_price(base_price: float, section_id: String, warehouse_ref) -> float:
	var mult := get_price_multiplier_for_section(section_id, warehouse_ref)
	return base_price * mult

func get_price_label(section_id: String, warehouse_ref) -> String:
	var mult := get_price_multiplier_for_section(section_id, warehouse_ref)
	if mult <= 0.85:
		return "SALE!"
	elif mult >= 1.15:
		return "HIGH DEMAND"
	elif mult >= 1.05:
		return "LIMITED"
	return ""

func get_section_discount_pct(section_id: String, warehouse_ref) -> int:
	var mult := get_price_multiplier_for_section(section_id, warehouse_ref)
	var discount := roundi((1.0 - mult) * 100)
	return discount  # positive = discount, negative = markup
