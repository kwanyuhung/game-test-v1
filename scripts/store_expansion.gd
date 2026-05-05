# scripts/store_expansion.gd
# Phase P: Store Expansion — renovation, upgrades, and new section unlocks
class_name StoreExpansionScript
extends Node

# Reputation level (0–10) — increases with store performance
var _reputation: int = 0
var _renovation_level: int = 0  # 0=basic, 1=standard, 2=premium
var _unlocked_sections: Array = ["dairy", "produce", "bakery", "drinks", "snacks", "meat", "pantry", "frozen"]
var _renovated_sections: Array = []  # sections that have been renovated
var _total_renovations: int = 0

# Section upgrade levels (per section)
var _section_upgrades: Dictionary = {}  # section_id -> upgrade_level (0-3)

signal reputation_changed(new_level: int)
signal section_renovated(section_id: String)
signal new_section_unlocked(section_id: String)

func _ready() -> void:
	pass

# ── Reputation ──────────────────────────────────────────────────
func get_reputation() -> int:
	return _reputation

func add_reputation(amount: int) -> void:
	var old := _reputation
	_reputation = clampi(_reputation + amount, 0, 10)
	if _reputation > old:
		reputation_changed.emit(_reputation)

func get_reputation_title() -> String:
	if _reputation >= 9: return "Legendary"
	if _reputation >= 7: return "Famous"
	if _reputation >= 5: return "Well-Known"
	if _reputation >= 3: return "Local Favorite"
	if _reputation >= 1: return "New Store"
	return "Unknown"

# ── Renovation System ────────────────────────────────────────────
func renovate_section(section_id: String) -> bool:
	if section_id in _renovated_sections:
		return false  # already renovated
	_renovated_sections.append(section_id)
	_section_upgrades[section_id] = clampi(_section_upgrades.get(section_id, 0) + 1, 0, 3)
	_total_renovations += 1
	_renovation_level = clampi(_renovation_level + 1, 0, 5)
	section_renovated.emit(section_id)
	# Renovated sections attract more customers
	add_reputation(1)
	return true

func is_section_renovated(section_id: String) -> bool:
	return section_id in _renovated_sections

func get_renovation_cost(section_id: String) -> int:
	# Base cost 200, scales with number of renovations already done
	var base := 200
	var count := _renovated_sections.size()
	return base + (count * 50)

func get_section_upgrade_level(section_id: String) -> int:
	return _section_upgrades.get(section_id, 0)

func get_renovation_bonus(section_id: String) -> float:
	# Renovated sections: +25% stock capacity, +10% customer attraction
	if not is_section_renovated(section_id):
		return 1.0
	var lvl := get_section_upgrade_level(section_id)
	return 1.0 + (lvl * 0.15)  # 1.0, 1.15, 1.30, 1.45

# ── Section Unlocks ─────────────────────────────────────────────
func unlock_section(section_id: String) -> bool:
	if section_id in _unlocked_sections:
		return false
	_unlocked_sections.append(section_id)
	_section_upgrades[section_id] = 0
	new_section_unlocked.emit(section_id)
	add_reputation(2)
	return true

func is_section_unlocked(section_id: String) -> bool:
	return section_id in _unlocked_sections

func get_unlocked_sections() -> Array:
	return _unlocked_sections.duplicate()

# ── Store Level (based on total upgrades) ────────────────────────
func get_store_level() -> int:
	# Sum of all renovation levels + reputation
	var total := _renovation_level + _reputation
	return clampi(total, 0, 10)

func get_store_level_name() -> String:
	var lvl := get_store_level()
	if lvl >= 9: return "Mega Mart"
	if lvl >= 7: return "Superstore"
	if lvl >= 5: return "Hypermarket"
	if lvl >= 3: return "Supermarket"
	if lvl >= 1: return "Corner Store"
	return "Basic"

# ── Renovation Info ─────────────────────────────────────────────
func get_total_renovations() -> int:
	return _total_renovations

func get_renovation_progress() -> Dictionary:
	# Returns progress toward next store level
	var lvl := get_store_level()
	var next_lvl := clampi(lvl + 1, 0, 10)
	var current_score := _renovation_level + _reputation
	var needed := (next_lvl - lvl) * 3  # rough estimate
	return {
		"level": lvl,
		"name": get_store_level_name(),
		"reputation": _reputation,
		"renovations": _total_renovations,
		"next_threshold": needed
	}
