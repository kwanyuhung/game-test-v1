# player_stats.gd
# Tracks all player statistics, XP, level, and achievements.
# ═══════════════════════════════════════════════════════════════════════
# XP Sources:
#   First purchase:        +20 XP
#   Buy item:             +2 XP per item
#   Resolve issue:        +10 XP (staff/player)
#   Browse full section:  +5 XP
#   Adopt pet:            +50 XP
#   Win claw machine:      +15 XP
#   Restock section:       +8 XP
#   Help lost child:      +25 XP
#   Full cart checkout:   +20 XP
#
# Level Thresholds: 0, 50, 120, 220, 350, 520, 750, 1050, ...
# ═══════════════════════════════════════════════════════════════════════
class_name PlayerStats
extends Node

signal xp_gained(amount: int, reason: String)
signal level_up(new_level: int)
signal achievement_unlocked(achievement_id: String)

const XP_FIRST_PURCHASE := 20
const XP_PER_ITEM := 2
const XP_RESOLVE_ISSUE := 10
const XP_BROWSE_SECTION := 5
const XP_ADOPT_PET := 50
const XP_CLAW_WIN := 15
const XP_RESTOCK := 8
const XP_HELP_CHILD := 25
const XP_FULL_CART := 20

# ─── Persistent Stats ──────────────────────────────────────────────

var _total_xp: int = 0
var _level: int = 1
var _total_spent: float = 0.0
var _items_bought: int = 0
var _unique_items_bought: int = 0
var _issues_resolved: int = 0
var _sections_browsed: int = 0
var _checkout_count: int = 0
var _claw_wins: int = 0
var _pets_adopted: int = 0
var _distance_walked: float = 0.0  # in pixels
var _floors_visited: int = 0
var _time_played_seconds: int = 0
var _chats_with_npcs: int = 0
var _daily_issues_resolved: int = 0
var _unique_products_bought: Array = []  # product IDs

var _floors_visited_set: Array = []
var _achievements_unlocked: Array = []

var _xp_for_next_level: int:
	get: return _xp_for_level(_level + 1)
var _xp_for_current_level: int:
	get: return _xp_for_level(_level)

# ─── Level Thresholds ─────────────────────────────────────────────

static func _xp_for_level(lvl: int) -> int:
	# Quadratic scaling: 50, 120, 220, 350, 520, 750, 1050, ...
	# formula: 25*lvl^2 + 25*lvl
	return 25 * lvl * lvl + 25 * lvl

# ─── XP & Level ───────────────────────────────────────────────────

func add_xp(amount: int, reason: String) -> void:
	_total_xp += amount
	xp_gained.emit(amount, reason)
	_check_level_up()

func _check_level_up() -> void:
	var lvl := 1
	while _xp_for_level(lvl + 1) <= _total_xp:
		lvl += 1
	if lvl > _level:
		_level = lvl
		level_up.emit(_level)

# ─── Event Hooks ───────────────────────────────────────────────────

func on_item_bought(product_id: String, price: float) -> void:
	_total_spent += price
	_items_bought += 1
	if not _unique_products_bought.has(product_id):
		_unique_products_bought.append(product_id)
		_unique_items_bought += 1
	add_xp(XP_PER_ITEM, "Bought item: %s" % product_id)
	_check_achievements()

func on_checkout(subtotal: float, item_count: int) -> void:
	_checkout_count += 1
	if item_count >= 10:
		add_xp(XP_FULL_CART, "Full cart checkout (%d items)" % item_count)

func on_issue_resolved(issue_label: String) -> void:
	_issues_resolved += 1
	_daily_issues_resolved += 1
	add_xp(XP_RESOLVE_ISSUE, "Resolved issue: %s" % issue_label)
	_check_achievements()

func on_section_browsed(section_name: String) -> void:
	_sections_browsed += 1
	add_xp(XP_BROWSE_SECTION, "Browsed: %s" % section_name)

func on_claw_win() -> void:
	_claw_wins += 1
	add_xp(XP_CLAW_WIN, "Won claw machine prize")
	_check_achievements()

func on_pet_adopted() -> void:
	_pets_adopted += 1
	add_xp(XP_ADOPT_PET, "Adopted a pet!")
	_check_achievements()

func on_chat_with_npc() -> void:
	_chats_with_npcs += 1
	_check_achievements()

func on_floor_visited(floor_idx: int) -> void:
	if not _floors_visited_set.has(floor_idx):
		_floors_visited_set.append(floor_idx)
		_floors_visited = _floors_visited_set.size()
	_check_achievements()

func on_walk(pixels: float) -> void:
	_distance_walked += pixels

func add_play_time(seconds: int) -> void:
	_time_played_seconds += seconds

func reset_daily() -> void:
	_daily_issues_resolved = 0

# ─── Achievements ─────────────────────────────────────────────────

const _ACHIEVEMENTS := {
	"first_purchase":     {"name": "First Purchase",    "desc": "Made your first purchase",              "icon": "🛒", "xp": 30},
	"full_cart":          {"name": "Full Cart",          "desc": "Checkout with 10+ items",              "icon": "🛍️", "xp": 40},
	"issue_fixer":        {"name": "Issue Fixer",        "desc": "Resolved 5 maintenance issues",       "icon": "🔧", "xp": 50},
	"hero_of_the_floor":  {"name": "Hero of the Floor",  "desc": "Resolved 25 maintenance issues",      "icon": "🦸", "xp": 100},
	"collector":          {"name": "Collector",           "desc": "Bought 20 different products",        "icon": "📦", "xp": 40},
	"big_spender":        {"name": "Big Spender",         "desc": "Spent $500 total in the store",      "icon": "💳", "xp": 60},
	"claw_champion":      {"name": "Claw Champion",      "desc": "Won 5 claw machine prizes",           "icon": "🎮", "xp": 50},
	"animal_friend":      {"name": "Animal Friend",       "desc": "Adopted a pet from the store",       "icon": "🐾", "xp": 70},
	"social_butterfly":   {"name": "Social Butterfly",   "desc": "Had 10 conversations with NPCs",     "icon": "🦋", "xp": 30},
	"world_explorer":     {"name": "World Explorer",     "desc": "Visited every floor",               "icon": "🌍", "xp": 60},
	"regular_customer":   {"name": "Regular Customer",   "desc": "Made 20 checkouts",                  "icon": "⭐", "xp": 80},
	"chatty_patty":       {"name": "Chatty Patty",       "desc": "Had 50 conversations with NPCs",     "icon": "💬", "xp": 70},
	"supermarket_master": {"name": "Supermarket Master",  "desc": "Reached Level 10",                   "icon": "🏆", "xp": 150},
}

func _check_achievements() -> void:
	var checks := [
		["first_purchase",    func: bool:  return _checkout_count >= 1],
		["full_cart",         func: bool:  return _items_bought >= 10],
		["issue_fixer",       func: bool:  return _issues_resolved >= 5],
		["hero_of_the_floor", func: bool:  return _issues_resolved >= 25],
		["collector",         func: bool:  return _unique_items_bought >= 20],
		["big_spender",       func: bool:  return _total_spent >= 500.0],
		["claw_champion",     func: bool:  return _claw_wins >= 5],
		["animal_friend",     func: bool:  return _pets_adopted >= 1],
		["social_butterfly",  func: bool:  return _chats_with_npcs >= 10],
		["world_explorer",    func: bool:  return _floors_visited >= 11],
		["regular_customer",  func: bool:  return _checkout_count >= 20],
		["chatty_patty",      func: bool:  return _chats_with_npcs >= 50],
		["supermarket_master",func: bool:  return _level >= 10],
	]
	for ach in checks:
		var ach_id: String = ach[0]
		if _achievements_unlocked.has(ach_id):
			continue
		var cond: Callable = ach[1]
		if cond.call():
			_unlock_achievement(ach_id)

func _unlock_achievement(ach_id: String) -> void:
	if _achievements_unlocked.has(ach_id):
		return
	_achievements_unlocked.append(ach_id)
	var ach = _ACHIEVEMENTS.get(ach_id, {})
	var xp_reward: int = ach.get("xp", 20)
	add_xp(xp_reward, "Achievement: %s" % ach.get("name", ""))
	achievement_unlocked.emit(ach_id)

# ─── Accessors ─────────────────────────────────────────────────────

func level() -> int:
	return _level

func total_xp() -> int:
	return _total_xp

func xp_progress() -> float:
	var cur := _xp_for_current_level
	var nxt := _xp_for_next_level
	if nxt == cur:
		return 1.0
	return float(_total_xp - cur) / float(nxt - cur)

func total_spent() -> float:
	return _total_spent

func items_bought() -> int:
	return _items_bought

func issues_resolved() -> int:
	return _issues_resolved

func checkout_count() -> int:
	return _checkout_count

func claw_wins() -> int:
	return _claw_wins

func floors_visited() -> int:
	return _floors_visited

func time_played_string() -> String:
	var hrs := _time_played_seconds / 3600
	var mins := (_time_played_seconds % 3600) / 60
	return "%dh %dm" % [hrs, mins] if hrs > 0 else "%dm" % mins

func achievement_count() -> int:
	return _achievements_unlocked.size()

func total_achievements() -> int:
	return _ACHIEVEMENTS.size()

func get_unlocked_achievements() -> Array:
	return _achievements_unlocked

func get_achievement_info(ach_id: String) -> Dictionary:
	return _ACHIEVEMENTS.get(ach_id, {})

# ─── Summary for display ───────────────────────────────────────────

func get_summary() -> Dictionary:
	return {
		"level": _level,
		"xp": _total_xp,
		"xp_progress": xp_progress(),
		"xp_next": _xp_for_next_level,
		"total_spent": _total_spent,
		"items_bought": _items_bought,
		"unique_items": _unique_items_bought,
		"issues_resolved": _issues_resolved,
		"daily_issues": _daily_issues_resolved,
		"checkouts": _checkout_count,
		"claw_wins": _claw_wins,
		"pets_adopted": _pets_adopted,
		"floors_visited": _floors_visited,
		"time_played": time_played_string(),
		"chats": _chats_with_npcs,
		"ach_unlocked": _achievements_unlocked.size(),
		"ach_total": _ACHIEVEMENTS.size(),
	}
