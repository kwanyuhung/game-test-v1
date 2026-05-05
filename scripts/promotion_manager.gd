# scripts/promotion_manager.gd
# Phase O: Promotions, Events & Loyalty Tiers
class_name PromotionManagerScript
extends Node

enum LoyaltyTier { BRONZE, SILVER, GOLD, PLATINUM }

var _loyalty_tier := LoyaltyTier.BRONZE
var _loyalty_points: int = 0
var _active_promotions: Array = []  # [{type, product_id, bonus, expires_in_hours}]
var _double_xp_event: bool = false
var _double_points_event: bool = false

signal promotion_started(promo_desc: String)
signal loyalty_tier_upgraded(new_tier: LoyaltyTier)

func _ready() -> void:
	pass

# ── Loyalty Points ────────────────────────────────────────────────
func add_loyalty_points(pts: int) -> void:
	_loyalty_points += pts
	_check_tier_upgrade()

func get_loyalty_points() -> int:
	return _loyalty_points

func get_loyalty_tier() -> LoyaltyTier:
	return _loyalty_tier

func get_tier_name() -> String:
	match _loyalty_tier:
		LoyaltyTier.BRONZE:  return "Bronze"
		LoyaltyTier.SILVER:  return "Silver"
		LoyaltyTier.GOLD:    return "Gold"
		LoyaltyTier.PLATINUM: return "Platinum"
	return "Bronze"

func get_tier_color() -> Color:
	match _loyalty_tier:
		LoyaltyTier.BRONZE:   return Color(0.80, 0.55, 0.20)
		LoyaltyTier.SILVER:   return Color(0.75, 0.75, 0.80)
		LoyaltyTier.GOLD:     return Color(1.00, 0.85, 0.00)
		LoyaltyTier.PLATINUM: return Color(0.60, 0.80, 1.00)
	return Color(0.80, 0.55, 0.20)

func get_tier_discount() -> float:
	# Discount applied at checkout
	match _loyalty_tier:
		LoyaltyTier.BRONZE:   return 0.01
		LoyaltyTier.SILVER:   return 0.03
		LoyaltyTier.GOLD:     return 0.05
		LoyaltyTier.PLATINUM: return 0.10
	return 0.01

func get_tier_point_multiplier() -> float:
	# Extra points earned per $ spent
	match _loyalty_tier:
		LoyaltyTier.BRONZE:   return 1.0
		LoyaltyTier.SILVER:   return 1.5
		LoyaltyTier.GOLD:     return 2.0
		LoyaltyTier.PLATINUM: return 3.0
	return 1.0

func _check_tier_upgrade() -> void:
	var old := _loyalty_tier
	if _loyalty_points >= 5000:
		_loyalty_tier = LoyaltyTier.PLATINUM
	elif _loyalty_points >= 2000:
		_loyalty_tier = LoyaltyTier.GOLD
	elif _loyalty_points >= 500:
		_loyalty_tier = LoyaltyTier.SILVER
	else:
		_loyalty_tier = LoyaltyTier.BRONZE
	if _loyalty_tier > old:
		loyalty_tier_upgraded.emit(_loyalty_tier)

# ── XP & Point Event Boosts ──────────────────────────────────────
func is_double_xp_active() -> bool:
	return _double_xp_event

func is_double_points_active() -> bool:
	return _double_points_event

func activate_double_xp(hours: int = 24) -> void:
	_double_xp_event = true
	promotion_started.emit("2X XP for %d hours!" % hours)

func activate_double_points(hours: int = 24) -> void:
	_double_points_event = true
	promotion_started.emit("2X Loyalty Points for %d hours!" % hours)

# ── Checkout Integration ─────────────────────────────────────────
func get_checkout_xp_multiplier() -> float:
	# Base 1.0 + satisfaction bonus + event bonus
	var m := 1.0
	if _double_xp_event:
		m *= 2.0
	return m

func get_checkout_point_bonus(total_spent: float) -> int:
	# Earn 1 pt per $1, multiplied by tier and event
	var base := int(total_spent)
	var mult := get_tier_point_multiplier()
	if _double_points_event:
		mult *= 2.0
	return int(base * mult)

func get_loyalty_discount(subtotal: float) -> float:
	return subtotal * get_tier_discount()

func get_tier_progress() -> Dictionary:
	# Returns {current, next, threshold} for progress bar
	var thresholds := [0, 500, 2000, 5000]
	var tier_idx := _loyalty_tier as int
	var current_pts := _loyalty_points
	var next_thresh: int
	if tier_idx >= thresholds.size() - 1:
		next_thresh = thresholds[-1]
	else:
		next_thresh = thresholds[tier_idx + 1]
	var prev_thresh := thresholds[clampi(tier_idx, 0, thresholds.size()-1)]
	var progress := (float(current_pts - prev_thresh) / max(1, next_thresh - prev_thresh)) if next_thresh > prev_thresh else 1.0
	return {"current": current_pts, "next": next_thresh, "threshold": next_thresh, "progress": clampf(progress, 0.0, 1.0)}

# ── Promotions ──────────────────────────────────────────────────
func get_active_promotions() -> Array:
	return _active_promotions

func get_xp_multiplier_for_product(product_id: String) -> float:
	var mult := 1.0
	for promo in _active_promotions:
		if promo.get("product_id", "") == product_id and promo.get("type", "") == "xp_boost":
			mult = max(mult, promo.get("bonus", 1.0))
	return mult
