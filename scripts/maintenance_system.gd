# maintenance_system.gd
# Handles all store maintenance issues — spawn, queue, assign, resolve.
# Issues appear on floors and can be fixed by staff or the player.
# ═══════════════════════════════════════════════════════════════════════
# ISSUE TYPES:
#   SPILL         — Wet floor sign needed, slip hazard
#   BROKEN_LIGHT  — Flickering light, reduces floor ambiance
#   OUT_OF_STOCK  — Section running low on popular items
#   BROKEN_MACHINE — Claw machine / stall equipment malfunction
#   SECURITY_ALERT— Suspicious activity detected
#   LOST_CHILD    — A child is separated from their family
#   CLEANUP_NEEDED— Mess in food court or bathroom
#   POWER_FLICKER — Electrical issue, dims part of floor
# ═══════════════════════════════════════════════════════════════════════
class_name MaintenanceSystem
extends Node

signal issue_created(issue: Issue)
signal issue_resolved(issue: Issue, by_player: bool)
signal issue_assigned(issue: Issue, assignee_name: String)

const GameClock = preload("res://scripts/game_clock.gd")

# ─── Issue Definition ────────────────────────────────────────────────

class Issue:
	var id: String
	var issue_type: int
	var floor: int
	var world_pos: Vector2       # pixel position in world
	var description: String
	var urgency: int             # 1=low, 2=medium, 3=high
	var status: int              # 0=open, 1=assigned, 2=resolved
	var assigned_to: String      # staff name or "player"
	var created_hour: int
	var time_to_resolve: float   # seconds it takes to fix
	var sprite_scene: PackedScene  # which visual sprite to show
	var label: String           # short display name

	static const TYPE_SPILL         := 0
	static const TYPE_BROKEN_LIGHT := 1
	static const TYPE_OUT_OF_STOCK  := 2
	static const TYPE_BROKEN_MACHINE:= 3
	static const TYPE_SECURITY_ALERT:= 4
	static const TYPE_LOST_CHILD    := 5
	static const TYPE_CLEANUP_NEEDED:= 6
	static const TYPE_POWER_FLICKER := 7

	static func type_name(t: int) -> String:
		match t:
			TYPE_SPILL:          return "Wet Floor Spill"
			TYPE_BROKEN_LIGHT:   return "Broken Light"
			TYPE_OUT_OF_STOCK:   return "Stock Runout"
			TYPE_BROKEN_MACHINE: return "Machine Malfunction"
			TYPE_SECURITY_ALERT: return "Security Alert"
			TYPE_LOST_CHILD:     return "Lost Child"
			TYPE_CLEANUP_NEEDED: return "Cleanup Required"
			TYPE_POWER_FLICKER:  return "Power Flicker"
		return "Unknown"

	static func type_emoji(t: int) -> String:
		match t:
			TYPE_SPILL:          return "💧"
			TYPE_BROKEN_LIGHT:   return "💡"
			TYPE_OUT_OF_STOCK:   return "📦"
			TYPE_BROKEN_MACHINE: return "⚙️"
			TYPE_SECURITY_ALERT: return "🚨"
			TYPE_LOST_CHILD:     return "👶"
			TYPE_CLEANUP_NEEDED: return "🧹"
			TYPE_POWER_FLICKER:  return "⚡"
		return "🔧"

	static func urgency_name(u: int) -> String:
		match u:
			1: return "Low"
			2: return "Medium"
			3: return "Urgent"
		return "Unknown"

	static func time_for_type(t: int) -> float:
		match t:
			TYPE_SPILL:          return 8.0
			TYPE_BROKEN_LIGHT:   return 15.0
			TYPE_OUT_OF_STOCK:   return 20.0
			TYPE_BROKEN_MACHINE: return 30.0
			TYPE_SECURITY_ALERT: return 12.0
			TYPE_LOST_CHILD:     return 25.0
			TYPE_CLEANUP_NEEDED: return 18.0
			TYPE_POWER_FLICKER:  return 22.0
		return 15.0

	static func urgency_for_type(t: int) -> int:
		match t:
			TYPE_SPILL:          return 2  # medium — safety issue
			TYPE_BROKEN_LIGHT:   return 1  # low
			TYPE_OUT_OF_STOCK:   return 1  # low
			TYPE_BROKEN_MACHINE: return 2  # medium
			TYPE_SECURITY_ALERT: return 3  # high
			TYPE_LOST_CHILD:     return 3  # high
			TYPE_CLEANUP_NEEDED: return 1  # low
			TYPE_POWER_FLICKER:  return 2  # medium
		return 1

# ─── State ─────────────────────────────────────────────────────────

var _issues: Array[Issue] = []
var _issue_counter: int = 0
var _spawn_timer: float = 0.0
var _spawn_interval: float = 45.0  # new issue every ~45 seconds
var _clock: GameClock = null
var _active_issues: Array[Issue] = []  # non-resolved issues
var _max_concurrent_issues: int = 5

func configure(clock: GameClock) -> void:
	_clock = clock

func _process(delta: float) -> void:
	if _clock == null:
		return
	# Don't spawn issues at night (store is quiet)
	if _clock.is_night():
		return

	_spawn_timer += delta
	var adjusted_interval := _spawn_interval * randf_range(0.7, 1.3)
	if _spawn_timer >= adjusted_interval:
		_spawn_timer = 0.0
		if _active_issues.size() < _max_concurrent_issues:
			_spawn_random_issue()

# ─── Issue Spawning ─────────────────────────────────────────────────

func _spawn_random_issue() -> void:
	var all_types := [
		Issue.TYPE_SPILL, Issue.TYPE_BROKEN_LIGHT, Issue.TYPE_OUT_OF_STOCK,
		Issue.TYPE_BROKEN_MACHINE, Issue.TYPE_CLEANUP_NEEDED,
	]
	# Only spawn high-urgency at specific hours
	if _clock.game_hour() >= 17 and _clock.game_hour() <= 21:
		all_types += [Issue.TYPE_SECURITY_ALERT, Issue.TYPE_LOST_CHILD]

	var issue_type: int = all_types[randi() % all_types.size()]
	var floor: int = _choose_issue_floor(issue_type)
	var pos := _random_pos_for_floor(floor)

	var issue := Issue.new()
	issue.id = "ISSUE_%04d" % _issue_counter
	_issue_counter += 1
	issue.issue_type = issue_type
	issue.floor = floor
	issue.world_pos = pos
	issue.urgency = Issue.urgency_for_type(issue_type)
	issue.time_to_resolve = Issue.time_for_type(issue_type)
	issue.created_hour = _clock.game_hour()
	issue.status = 0  # open
	issue.label = Issue.type_name(issue_type)
	issue.description = _generate_description(issue_type, floor)

	_issues.append(issue)
	_active_issues.append(issue)
	if _clock != null:
		_clock.record_issue_created()
	issue_created.emit(issue)

func _choose_issue_floor(issue_type: int) -> int:
	# Weighted floor selection — more issues on busy floors
	var weights := {
		0: 3,   # ground — most traffic
		1: 3,   # floor 1 — fresh market
		2: 2,
		3: 2,
		4: 2,
		5: 1,
		6: 1,
		7: 1,
		8: 2,   # arcade — claw machine issues possible
		9: 0,   # staff room — no issues
		10: 1,  # rooftop — fewer issues
		11: 2,  # pet floor — stock/machine issues
	}
	var total := 0
	for k in weights:
		if issue_type == Issue.TYPE_SECURITY_ALERT or issue_type == Issue.TYPE_LOST_CHILD:
			total += weights[k]  # can happen anywhere
		elif k == 0 or k == 1 or k == 8 or k == 11:
			total += weights[k]
		else:
			total += 0

	var roll := randi() % max(1, total)
	var cumulative := 0
	for k in weights:
		var w := weights[k]
		if issue_type == Issue.TYPE_SECURITY_ALERT or issue_type == Issue.TYPE_LOST_CHILD:
			pass
		elif k != 0 and k != 1 and k != 8 and k != 11:
			continue
		cumulative += w
		if roll < cumulative:
			return k
	return 0

func _random_pos_for_floor(floor: int) -> Vector2:
	var x_range := { "min": 100.0, "max": 700.0 }
	var y_range := { "min": 80.0, "max": 500.0 }
	match floor:
		0: y_range = {"min": 80.0, "max": 400.0}   # lobby / food street
		1: y_range = {"min": 80.0, "max": 400.0}   # fresh market
		8: y_range = {"min": 80.0, "max": 200.0}   # arcade
		11: y_range = {"min": 80.0, "max": 300.0}  # pet floor
	return Vector2(
		randf_range(x_range["min"], x_range["max"]),
		randf_range(y_range["min"], y_range["max"])
	)

func _generate_description(t: int, floor: int) -> String:
	var floor_name := "Floor %d" % floor
	if floor == 0: floor_name = "Ground Floor"
	if floor == 11: floor_name = "Pet Paradise"
	match t:
		Issue.TYPE_SPILL:
			return "A customer spilled a drink near the %s. Needs immediate attention!" % floor_name
		Issue.TYPE_BROKEN_LIGHT:
			return "A light fixture is flickering near the %s entrance." % floor_name
		Issue.TYPE_OUT_OF_STOCK:
			return "Popular items are running low in the %s section." % floor_name
		Issue.TYPE_BROKEN_MACHINE:
			return "The claw machine in the arcade is jammed and won't dispense prizes."
		Issue.TYPE_SECURITY_ALERT:
			return "Motion detected near the %s exit after hours." % floor_name
		Issue.TYPE_LOST_CHILD:
			return "A child has been separated from their parents near %s!" % floor_name
		Issue.TYPE_CLEANUP_NEEDED:
			return "The food court tables need wiping down in the %s area." % floor_name
		Issue.TYPE_POWER_FLICKER:
			return "Electrical flickering reported near the %s elevator bank." % floor_name
	return "Maintenance issue reported in %s." % floor_name

# ─── Issue Access ───────────────────────────────────────────────────

func get_active_issues() -> Array[Issue]:
	return _active_issues

func get_open_issues() -> Array[Issue]:
	return _active_issues.filter(func(iss): return iss.status == 0)

func get_issues_on_floor(floor_idx: int) -> Array[Issue]:
	return _active_issues.filter(func(iss): return iss.floor == floor_idx and iss.status < 2)

func get_issue_at_pos(pos: Vector2, range_threshold: float = 60.0) -> Issue:
	var nearest: Issue = null
	var nearest_dist := 99999.0
	for iss in _active_issues:
		if iss.status >= 2:
			continue
		var d := pos.distance_to(iss.world_pos)
		if d < nearest_dist and d < range_threshold:
			nearest_dist = d
			nearest = iss
	return nearest

# ─── Issue Assignment ───────────────────────────────────────────────

func assign_issue_to_staff(issue: Issue, staff_name: String) -> bool:
	if issue.status != 0:
		return false
	issue.status = 1
	issue.assigned_to = staff_name
	issue_assigned.emit(issue, staff_name)
	return true

func assign_issue_to_player(issue: Issue) -> bool:
	if issue.status != 0:
		return false
	issue.status = 1
	issue.assigned_to = "player"
	issue_assigned.emit(issue, "You")
	return true

# ─── Issue Resolution ───────────────────────────────────────────────

func resolve_issue(issue: Issue, by_player: bool = false) -> void:
	if issue.status >= 2:
		return
	issue.status = 2
	_active_issues.erase(issue)
	if _clock != null:
		_clock.record_issue_resolved()
	issue_resolved.emit(issue, by_player)

# Player resolves the issue they're standing on
func try_player_resolve(pos: Vector2) -> bool:
	var issue := get_issue_at_pos(pos, 60.0)
	if issue == null:
		return false
	resolve_issue(issue, true)
	return true

# ─── Auto-resolve for testing ──────────────────────────────────────

func force_resolve_all() -> void:
	for iss in _active_issues:
		if iss.status < 2:
			resolve_issue(iss, false)
