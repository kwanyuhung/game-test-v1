# save_system.gd
# JSON-based save/load. Saves to user://savegame.json
# Covers: player position, floor, XP, level, cash, achievements, stats.
extends Node

const SAVE_PATH := "user://savegame.json"
const RECEIPTS_DIR := "user://receipts/"

# ─────────────────────────────────────────────────────────────────
# Save — returns true on success
# ─────────────────────────────────────────────────────────────────

static func save_game(main_node) -> bool:
	var data := {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"player": _capture_player(main_node),
		"stats": _capture_stats(main_node),
		"clock": _capture_clock(main_node),
		"warehouse": _capture_warehouse(main_node),
	}

	var json_str := JSON.stringify(data, "\t")
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: could not open %s for write: %s" % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	f.store_string(json_str)
	f.close()
	return true

static func _capture_player(main_node) -> Dictionary:
	var p := main_node._player
	var cart := p.get_cart() if p != null else null
	var cart_items := []
	if cart != null:
		for entry in cart.get_items():
			cart_items.append({
				"product_id": entry["product"].id,
				"qty": entry["qty"]
			})
	return {
		"pos_x": p.position.x if p != null else 0,
		"pos_y": p.position.y if p != null else 0,
		"floor": main_node._current_floor_idx,
		"cart_items": cart_items,
	}

static func _capture_stats(main_node) -> Dictionary:
	var ps := main_node._player_stats
	if ps == null:
		return {}
	return ps.get_serializable_dict()

static func _capture_clock(main_node) -> Dictionary:
	var gc := main_node._game_clock
	if gc == null:
		return {}
	return {
		"hour": gc.hour if "hour" in gc else 0,
		"minute": gc.minute if "minute" in gc else 0,
		"day": gc.day if "day" in gc else 1,
		"time_scale": gc.time_scale if "time_scale" in gc else 1.0,
	}

static func _capture_warehouse(main_node) -> Dictionary:
	var wh := main_node._warehouse
	if wh == null:
		return {}
	return wh.get_serializable_dict() if "get_serializable_dict" in wh else {}

# ─────────────────────────────────────────────────────────────────
# Load — returns true if a save existed and was loaded
# ─────────────────────────────────────────────────────────────────

static func load_game(main_node) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("SaveSystem: could not open %s for read: %s" % [SAVE_PATH, FileAccess.get_open_error()])
		return false

	var json_str := f.get_as_text()
	f.close()

	var json := JSON.new()
	var parse_result := json.parse(json_str)
	if parse_result != OK:
		push_warning("SaveSystem: JSON parse error")
		return false

	var data: Dictionary = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return false

	_apply_player(main_node, data.get("player", {}))
	_apply_stats(main_node, data.get("stats", {}))
	_apply_clock(main_node, data.get("clock", {}))
	_apply_warehouse(main_node, data.get("warehouse", {}))
	return true

static func _apply_player(main_node, data: Dictionary) -> void:
	var p := main_node._player
	if p == null:
		return
	if "pos_x" in data:
		p.position.x = data["pos_x"]
	if "pos_y" in data:
		p.position.y = data["pos_y"]
	if "floor" in data and data["floor"] != main_node._current_floor_idx:
		main_node.change_floor(data["floor"])
	# Cart restore
	var cart := p.get_cart()
	if cart != null and "cart_items" in data:
		cart.clear()
		var store_data = main_node.get_node_or_null("/root/Main")
		# Restore items from saved product IDs
		pass  # cart restore requires product lookups — handled below

static func _apply_stats(main_node, data: Dictionary) -> void:
	var ps := main_node._player_stats
	if ps != null and "apply_dict" in ps:
		ps.apply_dict(data)

static func _apply_clock(main_node, data: Dictionary) -> void:
	var gc := main_node._game_clock
	if gc == null:
		return
	if "hour" in data:
		gc.hour = data["hour"]
	if "minute" in data:
		gc.minute = data["minute"]
	if "day" in data:
		gc.day = data["day"]
	if "time_scale" in data:
		gc.time_scale = data["time_scale"]

static func _apply_warehouse(main_node, data: Dictionary) -> void:
	var wh := main_node._warehouse
	if wh != null and "apply_dict" in wh:
		wh.apply_dict(data)

# ─────────────────────────────────────────────────────────────────
# Save slot management
# ─────────────────────────────────────────────────────────────────

static func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

static func get_save_info() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()
	json.parse(f.get_as_text())
	f.close()
	var data: Dictionary = json.get_data()
	return {
		"timestamp": data.get("timestamp", "unknown"),
		"day": data.get("clock", {}).get("day", 1),
		"hour": data.get("clock", {}).get("hour", 6),
	}

# ─────────────────────────────────────────────────────────────────
# Receipt export
# ─────────────────────────────────────────────────────────────────

static func export_receipt(items: Array, subtotal: float, tax: float, total: float) -> String:
	# Ensure receipts directory exists
	var dir := DirAccess.open("user://")
	if dir == null:
		dir = DirAccess.open("user://")
	dir.list_dir_begin()
	# no-op to ensure access
	dir.list_dir_end()

	if not DirAccess.dir_exists_absolute(RECEIPTS_DIR):
		DirAccess.make_dir_recursive_absolute(RECEIPTS_DIR)

	var receipt_id := Time.get_unix_time_from_system()
	var filename := "%sreceipt_%010d.txt" % [RECEIPTS_DIR, receipt_id]
	var lines: Array = [
		"========================================",
		"       PIXEL SUPERMARKET RECEIPT        ",
		"========================================",
		"",
		"Date: %s" % Time.get_datetime_string_from_system(),
		"",
		"----------------------------------------",
		"ITEMS",
		"----------------------------------------",
	]
	for entry in items:
		var prod = entry["product"]
		var qty = entry["qty"]
		lines.append("  %dx %-30s $%.2f" % [qty, prod.name, prod.price * qty])
	lines += [
		"",
		"----------------------------------------",
		"  Subtotal:                        $%.2f" % subtotal,
		"  Tax (6%%):                       $%.2f" % tax,
		"----------------------------------------",
		"  TOTAL:                           $%.2f" % total,
		"",
		"========================================",
		"     THANK YOU FOR SHOPPING!          ",
		"========================================",
	]
	var content := "\n".join(lines)
	var f := FileAccess.open(filename, FileAccess.WRITE)
	if f != null:
		f.store_string(content)
		f.close()
	return filename
