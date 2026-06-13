# floor_override.gd
# Dev-only override for floor layout. Persists to user://floor_layout_override.json
# so map edits survive game restarts without touching source-controlled JSON.
# Applied to FloorDef at WorldManager.build_floor() time, just before FloorBuilder
# consumes the def.
class_name FloorOverride
extends Node

const OVERRIDE_PATH := "user://floor_layout_override.json"

static var _cached: Dictionary = {}
static var _loaded := false

static func load_override() -> Dictionary:
	if _loaded:
		return _cached
	_loaded = true
	_cached = {}
	if not FileAccess.file_exists(OVERRIDE_PATH):
		return _cached
	var f = FileAccess.open(OVERRIDE_PATH, FileAccess.READ)
	if f == null:
		push_warning("[FloorOverride] Cannot open %s" % OVERRIDE_PATH)
		return _cached
	var json_str := f.get_as_text()
	f.close()
	var j = JSON.new()
	if j.parse(json_str) != OK:
		push_warning("[FloorOverride] JSON parse error in %s" % OVERRIDE_PATH)
		return _cached
	var data = j.get_data()
	if typeof(data) == TYPE_DICTIONARY and data.has("floors"):
		_cached = data
	return _cached

static func save_override(data: Dictionary) -> bool:
	var f = FileAccess.open(OVERRIDE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[FloorOverride] Cannot write %s: %s" % [OVERRIDE_PATH, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	_cached = data
	_loaded = true
	return true

static func clear_override() -> void:
	if FileAccess.file_exists(OVERRIDE_PATH):
		DirAccess.remove_absolute(OVERRIDE_PATH)
	_cached = {}
	_loaded = true

# Mutates the FloorDef in-place. No-op if no override entry for this floor index.
static func apply_to_floor_def(fd) -> void:
	if fd == null:
		return
	var data := load_override()
	var floors = data.get("floors", [])
	print("[DEBUG] apply_to_floor_def fd.index=%s data=%s" % [fd.index, str(data)])
	if not (floors is Array):
		return
	for entry in floors:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if int(entry.get("index", -1)) != fd.index:
			continue
		if entry.has("width"):
			fd.width_tiles = int(entry["width"])
		if entry.has("height"):
			fd.height_tiles = int(entry["height"])
		if entry.has("ambient_color") and typeof(entry["ambient_color"]) == TYPE_ARRAY:
			var c = entry["ambient_color"]
			if c.size() >= 3:
				fd.ambient_color = Color(float(c[0]), float(c[1]), float(c[2]))
		print("[DEBUG] apply_to_floor_def APPLIED fd.index=%s w=%d h=%d" % [fd.index, fd.width_tiles, fd.height_tiles])
		return

static func get_override_for_floor(idx: int) -> Dictionary:
	var data := load_override()
	for entry in data.get("floors", []):
		if typeof(entry) == TYPE_DICTIONARY and int(entry.get("index", -1)) == idx:
			return entry
	return {}

static func remove_override_for_floor(idx: int) -> bool:
	var data := load_override()
	var floors = data.get("floors", [])
	if not (floors is Array):
		return false
	var pruned: Array = []
	var removed := false
	for entry in floors:
		if typeof(entry) == TYPE_DICTIONARY and int(entry.get("index", -1)) == idx:
			removed = true
			continue
		pruned.append(entry)
	if not removed:
		return false
	if pruned.is_empty():
		clear_override()
		return true
	var new_data := {"floors": pruned}
	return save_override(new_data)

static func has_any_override() -> bool:
	var data := load_override()
	return data.has("floors") and (data["floors"] as Array).size() > 0
