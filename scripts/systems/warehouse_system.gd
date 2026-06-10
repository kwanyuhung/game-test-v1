# warehouse_system.gd
# Central warehouse — receives stock, holds inventory, ships to sections.
# Sections pull from warehouse stock. When warehouse is depleted, sections
# go "out of stock". The player or staff can trigger a delivery.
# ═══════════════════════════════════════════════════════════════════════
class_name WarehouseSystem
extends Node

const StoreData = preload("res://scripts/world/store_data.gd")

# delivery_arrived is reserved for "truck has arrived at the dock" events
# (emitted by TruckDockSystem, not by this class). Receive_delivery here
# only emits stock_updated per section.
signal stock_updated(section_id: String, new_count: int)
signal low_stock_warning(section_id: String)

# ─── Warehouse Inventory ──────────────────────────────────────────
# Per-section stock levels (units in warehouse)
var _stock: Dictionary = {}
var _section_min_stock: Dictionary = {}  # reorder threshold per section
var _delivery_pending: bool = false
var _delivery_contents: Array = []  # [{section: k, qty: v}]

# Throttle: low_stock_warning only emitted once per (section_id, hour_key)
# Reset on day change. Hour key passed in via _reset_low_stock_throttle.
var _low_stock_warned: Dictionary = {}
var _low_stock_throttle_key: int = -1

# ─── Initialization ───────────────────────────────────────────────

func _ready() -> void:
	_initialize_stock()

func _initialize_stock() -> void:
	# Initialize warehouse with starting stock for each section
	# Format: {section_id: {"qty": int, "capacity": int, "min": int}}
	var section_configs := {
		"produce":  {"capacity": 200, "min": 30},
		"dairy":    {"capacity": 150, "min": 20},
		"bakery":   {"capacity": 120, "min": 15},
		"meat":     {"capacity": 100, "min": 15},
		"pantry":   {"capacity": 180, "min": 25},
		"spices":   {"capacity": 80,  "min": 10},
		"snacks":   {"capacity": 200, "min": 30},
		"candy":    {"capacity": 150, "min": 20},
		"drinks":   {"capacity": 180, "min": 25},
		"coffee":   {"capacity": 80,  "min": 10},
		"frozen":   {"capacity": 120, "min": 20},
		"clean":    {"capacity": 100, "min": 15},
		"paper":    {"capacity": 100, "min": 15},
		"pharm":    {"capacity": 60,  "min": 10},
		"beauty":   {"capacity": 80,  "min": 12},
		"toys":     {"capacity": 80,  "min": 10},
		"cafe":     {"capacity": 60,  "min": 8},
		"pet":      {"capacity": 120, "min": 20},
	}
	for sec_id in section_configs:
		var cfg: Dictionary = section_configs[sec_id]
		_stock[sec_id] = {
			"qty": int(cfg["capacity"] * randf_range(0.6, 0.9)),  # start at 60-90% capacity
			"capacity": int(cfg["capacity"]),
			"min": int(cfg["min"]),
		}
		_section_min_stock[sec_id] = int(cfg["min"])

# ─── Stock Access ─────────────────────────────────────────────────

func get_stock(section_id: String) -> int:
	if not _stock.has(section_id):
		return 0
	return int(_stock[section_id]["qty"])

# Returns all stock as a dictionary {section_id: quantity}
func get_all_stock() -> Dictionary:
	var result := {}
	for sec_id in _stock.keys():
		result[sec_id] = int(_stock[sec_id]["qty"])
	return result

func get_capacity(section_id: String) -> int:
	if not _stock.has(section_id):
		return 0
	return int(_stock[section_id]["capacity"])

func get_stock_ratio(section_id: String) -> float:
	var cap := get_capacity(section_id)
	if cap == 0:
		return 0.0
	return float(get_stock(section_id)) / float(cap)

# ─── Stock Operations ─────────────────────────────────────────────

# Called when a customer buys an item from a section
# Returns true if item was available, false if section is out of stock
func consume_stock(section_id: String, amount: int = 1) -> bool:
	if not _stock.has(section_id):
		return false
	var current := int(_stock[section_id]["qty"])
	if current < amount:
		# Check if completely empty
		if current == 0:
			stock_updated.emit(section_id, 0)
			_check_low_stock(section_id)
		return false
	_stock[section_id]["qty"] = current - amount
	stock_updated.emit(section_id, int(_stock[section_id]["qty"]))
	_check_low_stock(section_id)
	return true

# Called when warehouse receives a delivery from a truck unload.
# contents: {section_id: qty, ...}
func receive_delivery(contents: Dictionary) -> void:
	for sec_id in contents:
		if not _stock.has(sec_id):
			continue
		var current := int(_stock[sec_id]["qty"])
		var add_qty := int(contents[sec_id])
		var cap := int(_stock[sec_id]["capacity"])
		_stock[sec_id]["qty"] = mini(current + add_qty, cap)
		stock_updated.emit(sec_id, int(_stock[sec_id]["qty"]))

# Staff R-restock: instant top-up, no truck queue. Emits stock_updated only.
func direct_restock(section_id: String, qty: int) -> void:
	if not _stock.has(section_id):
		return
	var current := int(_stock[section_id]["qty"])
	var cap := int(_stock[section_id]["capacity"])
	_stock[section_id]["qty"] = mini(current + qty, cap)
	stock_updated.emit(section_id, int(_stock[section_id]["qty"]))

# ─── Reorder / Delivery ───────────────────────────────────────────

func check_and_order() -> int:
	# Returns number of sections that need restocking
	var sections_to_order: Array = []
	var all_sections := _stock.keys()
	for sec_id in all_sections:
		if get_stock(sec_id) < _section_min_stock[sec_id]:
			sections_to_order.append(sec_id)
			_emit_low_stock_throttled(sec_id)
	return sections_to_order.size()

func trigger_delivery() -> void:
	if _delivery_pending:
		return
	_delivery_pending = true
	# Generate delivery contents — top up all low sections
	var contents: Dictionary = {}
	for sec_id in _stock:
		var qty := int(_stock[sec_id]["qty"])
		var cap := int(_stock[sec_id]["capacity"])
		var reorder_amt := maxi(0, cap - qty)
		if reorder_amt > 0:
			# Deliver 70% of what's needed
			var deliver := int(reorder_amt * 0.7)
			if deliver > 0:
				contents[sec_id] = deliver
	_delivery_contents = []
	for k in contents:
		_delivery_contents.append({"section": k, "qty": contents[k]})

# Returns the pending delivery as {section_id: qty} dict and clears pending.
# Use this from TruckDockSystem.do_unload() instead of the old Array form.
func consume_pending_delivery() -> Dictionary:
	if not _delivery_pending:
		return {}
	var result: Dictionary = {}
	for entry in _delivery_contents:
		result[entry["section"]] = int(entry["qty"])
	_delivery_contents = []
	_delivery_pending = false
	return result

func is_delivery_pending() -> bool:
	return _delivery_pending

# ─── Stock Status ─────────────────────────────────────────────────

func _check_low_stock(section_id: String) -> void:
	if not _stock.has(section_id):
		return
	var qty := int(_stock[section_id]["qty"])
	var min_qty: int = int(_section_min_stock.get(section_id, 10))
	if qty <= min_qty:
		_emit_low_stock_throttled(section_id)

# Emit low_stock_warning at most once per (section_id, throttle_key).
# throttle_key is the in-game hour; reset on day change.
func _emit_low_stock_throttled(section_id: String) -> void:
	if _low_stock_throttle_key < 0:
		# No clock set yet — emit unconditionally.
		low_stock_warning.emit(section_id)
		return
	var key: String = "%d_%s" % [_low_stock_throttle_key, section_id]
	if _low_stock_warned.has(key):
		return
	_low_stock_warned[key] = true
	low_stock_warning.emit(section_id)

func reset_low_stock_throttle(hour_key: int) -> void:
	_low_stock_throttle_key = hour_key
	_low_stock_warned.clear()

func is_section_in_stock(section_id: String) -> bool:
	return get_stock(section_id) > 0

# Returns percentage fullness string for UI
func stock_status_label(section_id: String) -> String:
	var ratio := get_stock_ratio(section_id)
	if ratio <= 0.0:
		return "OUT OF STOCK"
	elif ratio < 0.3:
		return "LOW STOCK"
	elif ratio < 0.7:
		return "MODERATE"
	else:
		return "WELL STOCKED"

# ─── Player / Staff Reorder Action ───────────────────────────────

# Player presses R near a section to manually trigger a reorder
func player_request_restock(section_id: String) -> bool:
	if not _stock.has(section_id):
		return false
	if is_delivery_pending():
		return false  # delivery already in transit
	trigger_delivery()
	return true

# ─── Save / Load (called by SaveSystem via duck-typing) ───────────

# Returns a dict suitable for JSON serialization.
func get_serializable_dict() -> Dictionary:
	return {
		"stock": _stock.duplicate(true),
		"section_min_stock": _section_min_stock.duplicate(true),
		"delivery_pending": _delivery_pending,
		"delivery_contents": _delivery_contents.duplicate(true),
	}

# Restores from the dict produced by get_serializable_dict.
# Missing keys are tolerated; extra keys in the dict are ignored.
func apply_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	if "stock" in data and typeof(data["stock"]) == TYPE_DICTIONARY:
		_stock = (data["stock"] as Dictionary).duplicate(true)
	if "section_min_stock" in data and typeof(data["section_min_stock"]) == TYPE_DICTIONARY:
		_section_min_stock = (data["section_min_stock"] as Dictionary).duplicate(true)
	if "delivery_pending" in data:
		_delivery_pending = bool(data["delivery_pending"])
	if "delivery_contents" in data and typeof(data["delivery_contents"]) == TYPE_ARRAY:
		_delivery_contents = (data["delivery_contents"] as Array).duplicate(true)
