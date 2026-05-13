# debug_config.gd
# Debug configuration for development settings
extends Node

const CONFIG_PATH := "res://scripts/debug_config.json"

var _data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("debug_config: Could not load %s, using defaults" % CONFIG_PATH)
		_set_defaults()
		return
	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("debug_config: JSON parse error")
		_set_defaults()
		return
	_data = json.data if json.data is Dictionary else {}
	_normalize()

func _set_defaults() -> void:
	_data = {
		"regenerate_floors": [0],
		"auto_regenerate_enabled": false,
		"regenerate_npc_count": 3,
		"regenerate_robot_count": 1,
		# Entity placement filters (empty = all enabled)
		"enabled_staff_roles": [],          # [] = all roles enabled
		"enabled_customer_types": [],         # [] = all types enabled
		"enabled_humanoid_robot_roles": [],   # [] = all roles enabled
		"enabled_single_robot_roles": [],     # [] = all roles enabled
		"enabled_sections": []               # [] = all sections enabled
	}

func _normalize() -> void:
	if not _data.has("regenerate_floors"):
		_data["regenerate_floors"] = [0]
	if not _data.has("auto_regenerate_enabled"):
		_data["auto_regenerate_enabled"] = false
	if not _data.has("regenerate_npc_count"):
		_data["regenerate_npc_count"] = 3
	if not _data.has("regenerate_robot_count"):
		_data["regenerate_robot_count"] = 1
	# Entity filters
	if not _data.has("enabled_staff_roles"):
		_data["enabled_staff_roles"] = []
	if not _data.has("enabled_customer_types"):
		_data["enabled_customer_types"] = []
	if not _data.has("enabled_humanoid_robot_roles"):
		_data["enabled_humanoid_robot_roles"] = []
	if not _data.has("enabled_single_robot_roles"):
		_data["enabled_single_robot_roles"] = []
	if not _data.has("enabled_sections"):
		_data["enabled_sections"] = []

func save() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("debug_config: Could not save to %s" % CONFIG_PATH)
		return
	var json_string := JSON.stringify(_data, "\t")
	file.store_string(json_string)
	file.close()

# ── Floor Regeneration ──────────────────────────────────────────────
func get_regenerate_floors() -> Array:
	return _data.get("regenerate_floors", [0])

func set_regenerate_floors(floors: Array) -> void:
	_data["regenerate_floors"] = floors
	save()

func add_regenerate_floor(floor_idx: int) -> void:
	var floors: Array = _data.get("regenerate_floors", [])
	if floor_idx not in floors:
		floors.append(floor_idx)
		_data["regenerate_floors"] = floors
		save()

func remove_regenerate_floor(floor_idx: int) -> void:
	var floors: Array = _data.get("regenerate_floors", [])
	if floor_idx in floors:
		floors.erase(floor_idx)
		_data["regenerate_floors"] = floors
		save()

func is_auto_regenerate_enabled() -> bool:
	return _data.get("auto_regenerate_enabled", false)

func set_auto_regenerate_enabled(enabled: bool) -> void:
	_data["auto_regenerate_enabled"] = enabled
	save()

# ── NPC Count ────────────────────────────────────────────────────────
func get_regenerate_npc_count() -> int:
	return _data.get("regenerate_npc_count", 3)

func get_regenerate_robot_count() -> int:
	return _data.get("regenerate_robot_count", 1)

# ── Staff Role Filters ───────────────────────────────────────────────
# Valid roles: "CASHIER", "SHELF_STOCKER", "CLEANER", "SECURITY", "GREETER", "MANAGER", "FLOOR_STAFF", "SCAN_GO"
func get_enabled_staff_roles() -> Array:
	return _data.get("enabled_staff_roles", [])

func set_enabled_staff_roles(roles: Array) -> void:
	_data["enabled_staff_roles"] = roles
	save()

func is_staff_role_enabled(role_name: String) -> bool:
	var enabled: Array = _data.get("enabled_staff_roles", [])
	# Empty array means all roles are enabled
	if enabled.is_empty():
		return true
	return role_name in enabled

# ── Customer Type Filters ────────────────────────────────────────────
# Valid types: "SOLO", "COUPLE", "PAIR", "TWO_COUPLES", "FAMILY_BABY", "FAMILY_TODDLER", "FAMILY_KIDS", "FAMILY_EXTENDED", "THREE_FRIENDS"
func get_enabled_customer_types() -> Array:
	return _data.get("enabled_customer_types", [])

func set_enabled_customer_types(types: Array) -> void:
	_data["enabled_customer_types"] = types
	save()

func is_customer_type_enabled(type_name: String) -> bool:
	var enabled: Array = _data.get("enabled_customer_types", [])
	# Empty array means all types are enabled
	if enabled.is_empty():
		return true
	return type_name in enabled

# ── Humanoid Robot Role Filters ───────────────────────────────────────
# Valid roles: "GREETER", "CLEANER"
func get_enabled_humanoid_robot_roles() -> Array:
	return _data.get("enabled_humanoid_robot_roles", [])

func set_enabled_humanoid_robot_roles(roles: Array) -> void:
	_data["enabled_humanoid_robot_roles"] = roles
	save()

func is_humanoid_robot_role_enabled(role_name: String) -> bool:
	var enabled: Array = _data.get("enabled_humanoid_robot_roles", [])
	if enabled.is_empty():
		return true
	return role_name in enabled

# ── Single-Function Robot Role Filters ────────────────────────────────
# Valid roles: "CLEANING_ROBOT", "GUIDANCE_ROBOT", "DELIVERY_ROBOT", "SECURITY_ROBOT", "SHELF_ROBOT"
func get_enabled_single_robot_roles() -> Array:
	return _data.get("enabled_single_robot_roles", [])

func set_enabled_single_robot_roles(roles: Array) -> void:
	_data["enabled_single_robot_roles"] = roles
	save()

func is_single_robot_role_enabled(role_name: String) -> bool:
	var enabled: Array = _data.get("enabled_single_robot_roles", [])
	if enabled.is_empty():
		return true
	return role_name in enabled

# ── Section Filters ─────────────────────────────────────────────────
# Valid sections: "produce", "dairy", "bakery", "meat", "pantry", "snacks", "frozen", "drinks", "beauty", "pet", "checkout", "entrance", "food_court"
func get_enabled_sections() -> Array:
	return _data.get("enabled_sections", [])

func set_enabled_sections(sections: Array) -> void:
	_data["enabled_sections"] = sections
	save()

func is_section_enabled(section_name: String) -> bool:
	var enabled: Array = _data.get("enabled_sections", [])
	if enabled.is_empty():
		return true
	return section_name in enabled

# ── Quick Filter Helpers ─────────────────────────────────────────────
# Enable only specific staff roles (disables all others)
func enable_only_staff_roles(roles: Array) -> void:
	_data["enabled_staff_roles"] = roles
	save()

# Enable only specific customer types (disables all others)
func enable_only_customer_types(types: Array) -> void:
	_data["enabled_customer_types"] = types
	save()

# Enable only specific robot roles (disables all others)
func enable_only_robot_roles(humanoid: Array, single_func: Array) -> void:
	_data["enabled_humanoid_robot_roles"] = humanoid
	_data["enabled_single_robot_roles"] = single_func
	save()

# Enable only specific sections (disables all others)
func enable_only_sections(sections: Array) -> void:
	_data["enabled_sections"] = sections
	save()

# Reset all filters to allow all entities
func reset_all_filters() -> void:
	_data["enabled_staff_roles"] = []
	_data["enabled_customer_types"] = []
	_data["enabled_humanoid_robot_roles"] = []
	_data["enabled_single_robot_roles"] = []
	_data["enabled_sections"] = []
	save()

# Check if any filters are active
func has_active_filters() -> bool:
	return not _data.get("enabled_staff_roles", []).is_empty() \
		or not _data.get("enabled_customer_types", []).is_empty() \
		or not _data.get("enabled_humanoid_robot_roles", []).is_empty() \
		or not _data.get("enabled_single_robot_roles", []).is_empty() \
		or not _data.get("enabled_sections", []).is_empty()

# Get a summary of active filters for debugging
func get_filter_summary() -> String:
	var parts: Array = []
	var staff: Array = _data.get("enabled_staff_roles", [])
	var customers: Array = _data.get("enabled_customer_types", [])
	var humanoid: Array = _data.get("enabled_humanoid_robot_roles", [])
	var single: Array = _data.get("enabled_single_robot_roles", [])
	var sections: Array = _data.get("enabled_sections", [])
	
	if not staff.is_empty():
		parts.append("Staff: %s" % ", ".join(staff))
	if not customers.is_empty():
		parts.append("Customers: %s" % ", ".join(customers))
	if not humanoid.is_empty():
		parts.append("HumanoidRobots: %s" % ", ".join(humanoid))
	if not single.is_empty():
		parts.append("SingleRobots: %s" % ", ".join(single))
	if not sections.is_empty():
		parts.append("Sections: %s" % ", ".join(sections))
	
	if parts.is_empty():
		return "All filters OFF (all entities enabled)"
	return " | ".join(parts)
