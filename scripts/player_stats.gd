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

var _total_xp: int = 300  # player starts with 300 XP to afford first robot
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
var _loyalty_points: int = 0
var _coins: int = 10  # player starts with 10 coins
var _is_loyalty_member: bool = false
var _cash: float = 200.0  # player starting cash

func add_cash(amount: float) -> void:
	_cash += amount
	if _cash < 0:
		_cash = 0.0

func spend_cash(amount: float) -> bool:
	if _cash < amount:
		return false
	_cash -= amount
	return true

func get_cash() -> float:
	return _cash

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

func spend_xp(amount: int) -> bool:
	if _total_xp < amount:
		return false
	_total_xp -= amount
	return true

func get_xp() -> int:
	return _total_xp

# ─── Staff Rank Progression ───────────────────────────────────────
# Staff rank determines which features robots and abilities unlock.
# Rank is earned through XP spent on staff activities.
enum StaffRank {
	TRAINEE      # Rank 1 - basic checkout, browse
	WORKER       # Rank 2 - single-function robots unlocked
	SENIOR       # Rank 3 - humanoid robots unlocked
	SUPERVISOR   # Rank 4 - all robots + business lite
	MANAGER      # Rank 5 - full Business Mode
}

var _staff_rank: StaffRank = StaffRank.TRAINEE
var _staff_xp: int = 50          # starting staff XP — do tasks to rank up!
var _staff_shifts_completed: int = 0
var _staff_tasks_done: int = 0
var _staff_rank_xp_thresholds := [0, 200, 500, 1000, 2000]  # XP needed per rank

signal staff_rank_up(new_rank: StaffRank)
signal staff_ability_unlocked(ability_id: String)

func add_staff_xp(amount: int, reason: String) -> void:
	_staff_xp += amount
	_check_staff_rank()
	xp_gained.emit(amount, reason)

func _check_staff_rank() -> void:
	var new_rank := StaffRank.TRAINEE
	for i in range(_staff_rank_xp_thresholds.size() - 1, -1, -1):
		if _staff_xp >= _staff_rank_xp_thresholds[i]:
			new_rank = i as StaffRank
			break
	if new_rank > _staff_rank:
		var old := _staff_rank
		_staff_rank = new_rank
		staff_rank_up.emit(new_rank)
		_unlock_staff_abilities_for_rank(new_rank, old)

func _unlock_staff_abilities_for_rank(new_rank: StaffRank, old_rank: StaffRank) -> void:
	# Emit abilities that are newly unlocked
	if new_rank >= StaffRank.WORKER and old_rank < StaffRank.WORKER:
		staff_ability_unlocked.emit("robots_single")
	if new_rank >= StaffRank.SENIOR and old_rank < StaffRank.SENIOR:
		staff_ability_unlocked.emit("robots_humanoid")
	if new_rank >= StaffRank.SUPERVISOR and old_rank < StaffRank.SUPERVISOR:
		staff_ability_unlocked.emit("business_lite")
	if new_rank >= StaffRank.MANAGER and old_rank < StaffRank.MANAGER:
		staff_ability_unlocked.emit("business_full")

func get_staff_rank() -> StaffRank:
	return _staff_rank

func get_staff_rank_name() -> String:
	match _staff_rank:
		StaffRank.TRAINEE: return "Trainee"
		StaffRank.WORKER: return "Worker"
		StaffRank.SENIOR: return "Senior"
		StaffRank.SUPERVISOR: return "Supervisor"
		StaffRank.MANAGER: return "Manager"
	return "???"

func get_staff_xp_for_next_rank() -> int:
	var idx := (_staff_rank + 1) as int
	if idx >= _staff_rank_xp_thresholds.size():
		return -1  # max rank
	return _staff_rank_xp_thresholds[idx]

func get_staff_xp_progress() -> float:
	var current_threshold := _staff_rank_xp_thresholds[_staff_rank as int]
	var next_threshold := -1
	var idx := (_staff_rank + 1) as int
	if idx < _staff_rank_xp_thresholds.size():
		next_threshold = _staff_rank_xp_thresholds[idx]
	if next_threshold < 0:
		return 1.0  # max rank
	return float(_staff_xp - current_threshold) / float(next_threshold - current_threshold)

func can_use_single_function_robots() -> bool:
	return _staff_rank >= StaffRank.WORKER

func can_use_humanoid_robots() -> bool:
	return _staff_rank >= StaffRank.SENIOR

func can_open_business_mode() -> bool:
	return _staff_rank >= StaffRank.SUPERVISOR

func complete_staff_shift() -> void:
	_staff_shifts_completed += 1
	add_staff_xp(30, "Staff shift completed")

func complete_staff_task() -> void:
	_staff_tasks_done += 1
	add_staff_xp(5, "Staff task done")

# ── Staff Wage & Morale (Phase M) ──────────────────────────────────
# Tracks hired staff members, their wages, and morale
var _hired_staff: Array = []  # [{name, role, wage, morale, shifts_worked}]
var _store_wage_bill: float = 0.0  # accumulated daily wages

func hire_staff(name: String, role: String, daily_wage: float) -> void:
	_hired_staff.append({"name": name, "role": role, "wage": daily_wage, "morale": 0.8, "shifts_worked": 0})
	_staff_shifts_completed += 1

func fire_staff(name: String) -> bool:
	for i in range(_hired_staff.size()):
		if _hired_staff[i]["name"] == name:
			_hired_staff.remove_at(i)
			return true
	return false

func get_staff_count() -> int:
	return _hired_staff.size()

func get_total_daily_wages() -> float:
	var total := 0.0
	for s in _hired_staff:
		total += s.get("wage", 0.0)
	return total

func pay_staff_wages(from_cash: float) -> float:
	# Deduct wages from cash. Returns remaining cash.
	var wages := get_total_daily_wages()
	if wages <= 0.0:
		return from_cash
	var deducted := mini(from_cash, wages)
	return from_cash - deducted

func adjust_staff_morale(staff_name: String, delta: float) -> void:
	for s in _hired_staff:
		if s["name"] == staff_name:
			s["morale"] = clampf(s["morale"] + delta, 0.0, 1.0)
			break

func get_staff_roster() -> Array:
	return _hired_staff

func on_shift_completed() -> void:
	_staff_shifts_completed += 1
	# All staff morale increases slightly on successful shift
	for s in _hired_staff:
		s["shifts_worked"] += 1
		s["morale"] = clampf(s["morale"] + 0.05, 0.0, 1.0)
	add_staff_xp(30, "Staff shift completed")

func get_staff_performance_bonus() -> float:
	# Higher morale = bonus to store performance (up to +20%)
	if _hired_staff.is_empty():
		return 1.0
	var avg_morale := 0.0
	for s in _hired_staff:
		avg_morale += s["morale"]
	avg_morale /= float(_hired_staff.size())
	return 1.0 + avg_morale * 0.2  # 1.0 to 1.2

# ── Phase N: Customer Satisfaction ────────────────────────────────
var _total_customers_served: int = 0
var _customers_satisfied: int = 0
var _customers_complained: int = 0
var _avg_satisfaction: float = 1.0
var _customer_complaints_today: int = 0

signal customer_satisfied()
signal customer_complained()

func record_customer_served(was_satisfied: bool) -> void:
	_total_customers_served += 1
	if was_satisfied:
		_customers_satisfied += 1
		customer_satisfied.emit()
	else:
		_customers_complained += 1
		_customer_complaints_today += 1
		customer_complained.emit()
	# Rolling average
	_avg_satisfaction = float(_customers_satisfied) / max(1, _total_customers_served)

func get_customer_satisfaction() -> float:
	return _avg_satisfaction

func get_satisfaction_bonus() -> float:
	# Returns XP/multiplier bonus based on satisfaction (1.0 to 1.5)
	return 1.0 + _avg_satisfaction * 0.5

func get_today_complaints() -> int:
	return _customer_complaints_today

func reset_daily_complaints() -> void:
	_customer_complaints_today = 0

func get_satisfaction_stars() -> String:
	var stars := ceili(_avg_satisfaction * 5.0)
	stars = clampi(stars, 0, 5)
	return "%s" % ["*", "**", "***", "****", "*****"][clampi(stars-1, 0, 4)]

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
	# Loyalty: earn 1 pt per $1 spent (only if member)
	if _is_loyalty_member:
		_loyalty_points += int(subtotal)

# ─── Loyalty Program ────────────────────────────────────────────────

func signup_loyalty() -> bool:
	if _is_loyalty_member:
		return false
	_is_loyalty_member = true
	return true

func is_loyalty_member() -> bool:
	return _is_loyalty_member

func get_loyalty_points() -> int:
	return _loyalty_points

# Returns credit applied (max $5 per 100 pts)
func redeem_loyalty_credit() -> float:
	if _loyalty_points < 100:
		return 0.0
	var credits := int(_loyalty_points / 100)
	_loyalty_points -= credits * 100
	return credits * 5.0

# ─── Coin System ────────────────────────────────────────────────────

func get_coins() -> int:
	return _coins

func add_coins(amount: int) -> void:
	_coins += amount

func spend_coins(amount: int) -> bool:
	if _coins < amount:
		return false
	_coins -= amount
	return true

func add_loyalty_points(amount: int) -> void:
	_loyalty_points += amount

func on_claw_win() -> void:
	_claw_wins += 1
	_check_achievements()

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

# ─── Save / Load ───────────────────────────────────────────────────

func get_serializable_dict() -> Dictionary:
	return {
		"_total_xp": _total_xp,
		"_level": _level,
		"_total_spent": _total_spent,
		"_items_bought": _items_bought,
		"_unique_items_bought": _unique_items_bought,
		"_issues_resolved": _issues_resolved,
		"_sections_browsed": _sections_browsed,
		"_checkout_count": _checkout_count,
		"_claw_wins": _claw_wins,
		"_pets_adopted": _pets_adopted,
		"_floors_visited": _floors_visited,
		"_time_played_seconds": _time_played_seconds,
		"_chats_with_npcs": _chats_with_npcs,
		"_achievements_unlocked": _achievements_unlocked,
		"_unique_products_bought": _unique_products_bought,
	}

func apply_dict(data: Dictionary) -> void:
	if "_total_xp" in data: _total_xp = data["_total_xp"]
	if "_level" in data: _level = data["_level"]
	if "_total_spent" in data: _total_spent = data["_total_spent"]
	if "_items_bought" in data: _items_bought = data["_items_bought"]
	if "_unique_items_bought" in data: _unique_items_bought = data["_unique_items_bought"]
	if "_issues_resolved" in data: _issues_resolved = data["_issues_resolved"]
	if "_sections_browsed" in data: _sections_browsed = data["_sections_browsed"]
	if "_checkout_count" in data: _checkout_count = data["_checkout_count"]
	if "_claw_wins" in data: _claw_wins = data["_claw_wins"]
	if "_pets_adopted" in data: _pets_adopted = data["_pets_adopted"]
	if "_floors_visited" in data: _floors_visited = data["_floors_visited"]
	if "_time_played_seconds" in data: _time_played_seconds = data["_time_played_seconds"]
	if "_chats_with_npcs" in data: _chats_with_npcs = data["_chats_with_npcs"]
	if "_achievements_unlocked" in data: _achievements_unlocked = data["_achievements_unlocked"]
	if "_unique_products_bought" in data: _unique_products_bought = data["_unique_products_bought"]
