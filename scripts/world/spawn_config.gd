# spawn_config.gd
# Upper-level configuration handler for all entity spawning
# Handles staff, customers, robots with enable/disable and limits
class_name SpawnConfig
extends Node

const CONFIG_PATH := "res://scripts/spawn_config.json"

var _data: Dictionary = {}

# Cached lookups
var _meta: Dictionary = {}
var _staff: Dictionary = {}
var _customers: Dictionary = {}
var _robots: Dictionary = {}
var _floors: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("SpawnConfig: Could not load %s" % CONFIG_PATH)
		return
	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("SpawnConfig: JSON parse error")
		return
	_data = json.data if json.data is Dictionary else {}
	_cache_lookups()

func _cache_lookups() -> void:
	_meta = _data.get("meta", {})
	_staff = _data.get("staff", {})
	_customers = _data.get("customers", {})
	_robots = _data.get("robots", {})
	_floors = _data.get("floors", {})

func reload() -> void:
	_load()

# ── Meta ──────────────────────────────────────────────────────────────────────
func get_version() -> String:
	return _meta.get("version", "0.0.0")

func get_description() -> String:
	return _meta.get("description", "")

# ── Global Enable ─────────────────────────────────────────────────────────────
func is_spawning_enabled() -> bool:
	return _staff.get("enabled", true) or _customers.get("enabled", true) or _robots.get("enabled", true)

func is_staff_enabled() -> bool:
	return _staff.get("enabled", true)

func is_customers_enabled() -> bool:
	return _customers.get("enabled", true)

func is_robots_enabled() -> bool:
	return _robots.get("enabled", true)

# ── Staff ─────────────────────────────────────────────────────────────────────
func get_staff_global_max() -> int:
	return _staff.get("global_max", 20)

func spawn_staff_on_current_floor() -> bool:
	return _staff.get("spawn_on_current_floor", true)

func get_all_staff_roles() -> Array:
	var roles: Array = _staff.get("roles", [])
	var result: Array = []
	for r in roles:
		if r is Dictionary and r.get("enabled", false):
			result.append(r)
	return result

func get_staff_role(name: String) -> Dictionary:
	var roles: Array = _staff.get("roles", [])
	for r in roles:
		if r is Dictionary and r.get("name", "") == name:
			return r
	return {}

func is_staff_role_enabled(name: String) -> bool:
	var role := get_staff_role(name)
	return role.get("enabled", false)

func get_staff_role_count(name: String) -> int:
	var role := get_staff_role(name)
	return role.get("count", 0)

func get_staff_role_floors(name: String) -> Array:
	var role := get_staff_role(name)
	return role.get("floors", [])

# ── Customers ─────────────────────────────────────────────────────────────────
func get_customer_global_max() -> int:
	return _customers.get("global_max", 30)

func spawn_customers_on_current_floor() -> bool:
	return _customers.get("spawn_on_current_floor", false)

func spawn_customers_on_all_floors() -> bool:
	return _customers.get("spawn_all_floors", true)

func get_random_seed() -> int:
	return _customers.get("random_seed", 0)

func get_all_customer_groups() -> Array:
	var groups: Array = _customers.get("groups", [])
	var result: Array = []
	for g in groups:
		if g is Dictionary and g.get("enabled", false):
			result.append(g)
	return result

func get_customer_group(name: String) -> Dictionary:
	var groups: Array = _customers.get("groups", [])
	for g in groups:
		if g is Dictionary and g.get("name", "") == name:
			return g
	return {}

func is_customer_group_enabled(name: String) -> bool:
	var group := get_customer_group(name)
	return group.get("enabled", false)

func get_customer_group_weight(name: String) -> int:
	var group := get_customer_group(name)
	return group.get("weight", 10)

func get_customer_group_count(name: String) -> int:
	var group := get_customer_group(name)
	return group.get("count", 0)

func get_customer_group_floors(name: String) -> Array:
	var group := get_customer_group(name)
	return group.get("floors", [])

func get_position_range(floor_idx: int) -> Dictionary:
	var ranges: Dictionary = _customers.get("position_ranges", {})
	var key := "floor_%d" % floor_idx
	var range_data: Array = ranges.get(key, [])
	if range_data.size() >= 2:
		return {"x": range_data[0], "y": range_data[1]}
	return {"x": [100, 500], "y": [100, 400]}

# ── Robots ────────────────────────────────────────────────────────────────────
func robots_on_floor_0_only() -> bool:
	return _robots.get("spawn_floor_0_only", true)

func get_all_humanoids() -> Array:
	var humanoids: Array = _robots.get("humanoids", [])
	var result: Array = []
	for h in humanoids:
		if h is Dictionary and h.get("enabled", false):
			result.append(h)
	return result

func get_all_singles() -> Array:
	var singles: Array = _robots.get("singles", [])
	var result: Array = []
	for s in singles:
		if s is Dictionary and s.get("enabled", false):
			result.append(s)
	return result

func get_humanoid(name: String) -> Dictionary:
	var humanoids: Array = _robots.get("humanoids", [])
	for h in humanoids:
		if h is Dictionary and h.get("name", "") == name:
			return h
	return {}

func get_single(name: String) -> Dictionary:
	var singles: Array = _robots.get("singles", [])
	for s in singles:
		if s is Dictionary and s.get("name", "") == name:
			return s
	return {}

func is_humanoid_enabled(name: String) -> bool:
	return get_humanoid(name).get("enabled", false)

func is_single_enabled(name: String) -> bool:
	return get_single(name).get("enabled", false)

func get_humanoid_count(name: String) -> int:
	return get_humanoid(name).get("count", 0)

func get_single_count(name: String) -> int:
	return get_single(name).get("count", 0)

func get_humanoid_pos(name: String) -> Vector2:
	var h := get_humanoid(name)
	var pos: Array = h.get("pos", [0, 0])
	return Vector2(pos[0], pos[1])

func get_single_pos(name: String) -> Vector2:
	var s := get_single(name)
	var pos: Array = s.get("pos", [0, 0])
	return Vector2(pos[0], pos[1])

# ── Floors ────────────────────────────────────────────────────────────────────
func get_floor_config(floor_idx: int) -> Dictionary:
	var key := str(floor_idx)
	return _floors.get(key, {"name": "Floor %d" % floor_idx, "staff_limit": 1, "customer_limit": 5})

func get_floor_name(floor_idx: int) -> String:
	return get_floor_config(floor_idx).get("name", "Floor %d" % floor_idx)

func get_floor_staff_limit(floor_idx: int) -> int:
	return get_floor_config(floor_idx).get("staff_limit", 1)

func get_floor_customer_limit(floor_idx: int) -> int:
	return get_floor_config(floor_idx).get("customer_limit", 5)

# ── Summary ───────────────────────────────────────────────────────────────────
func get_full_summary() -> String:
	var lines: Array = []
	lines.append("=== Spawn Configuration ===")
	lines.append("Version: %s | %s" % [get_version(), get_description()])
	lines.append("")
	lines.append("-- Staff [%s] global_max=%d --" % [str(is_staff_enabled()), get_staff_global_max()])
	for r in get_all_staff_roles():
		lines.append("  %s: count=%d floors=%s" % [r.get("name"), r.get("count"), str(r.get("floors"))])
	lines.append("")
	lines.append("-- Customers [%s] global_max=%d --" % [str(is_customers_enabled()), get_customer_global_max()])
	for g in get_all_customer_groups():
		lines.append("  %s: weight=%d count=%d floors=%s" % [g.get("name"), g.get("weight"), g.get("count"), str(g.get("floors"))])
	lines.append("")
	lines.append("-- Robots [%s] floor_0_only=%s --" % [str(is_robots_enabled()), str(robots_on_floor_0_only())])
	lines.append("  Humanoids:")
	for h in get_all_humanoids():
		lines.append("    %s: count=%d pos=%s" % [h.get("name"), h.get("count"), str(h.get("pos"))])
	lines.append("  Singles:")
	for s in get_all_singles():
		lines.append("    %s: count=%d pos=%s" % [s.get("name"), s.get("count"), str(s.get("pos"))])
	lines.append("")
	lines.append("-- Floors --")
	for i in range(5):
		var cfg := get_floor_config(i)
		lines.append("  %d: %s (staff:%d, customers:%d)" % [i, cfg.get("name"), cfg.get("staff_limit"), cfg.get("customer_limit")])
	return "\n".join(lines)
