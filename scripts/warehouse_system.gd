# warehouse_system.gd
# Central warehouse — receives stock, holds inventory, ships to sections.
# Sections pull from warehouse stock. When warehouse is depleted, sections
# go "out of stock". The player or staff can trigger a delivery.
# ═══════════════════════════════════════════════════════════════════════
class_name WarehouseSystem
extends Node

const StoreData = preload("res://scripts/store_data.gd")

signal stock_updated(section_id: String, new_count: int)
signal delivery_arrived(delivery: Dictionary)
signal low_stock_warning(section_id: String)

# ─── Warehouse Inventory ──────────────────────────────────────────
# Per-section stock levels (units in warehouse)
var _stock: Dictionary = {}
var _section_min_stock: Dictionary = {}  # reorder threshold per section
var _delivery_pending: bool = false
var _delivery_contents: Array = []

# ─── Initialization ───────────────────────────────────────────────

func _ready() -> void:
	_initialize_stock()

func _initialize_stock() -> void:
	# Initialize warehouse with starting stock for each section
	# Format: {section_id: {"qty": int, "capacity": int}}
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
			"qty": cfg["capacity"] * randf_range(0.6, 0.9),  # start at 60-90% capacity
			"capacity": cfg["capacity"],
			"min": cfg["min"],
		}
		_section_min_stock[sec_id] = cfg["min"]

# ─── Stock Access ─────────────────────────────────────────────────

func get_stock(section_id: String) -> int:
	if not _stock.has(section_id):
		return 0
	return int(_stock[section_id]["qty"])

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

# Called when warehouse receives a delivery
func receive_delivery(contents: Dictionary) -> void:
	# contents: {section_id: qty, ...}
	for sec_id in contents:
		if not _stock.has(sec_id):
			continue
		var current := int(_stock[sec_id]["qty"])
		var add_qty := int(contents[sec_id])
		var cap := int(_stock[sec_id]["capacity"])
		_stock[sec_id]["qty"] = mini(current + add_qty, cap)
		stock_updated.emit(sec_id, int(_stock[sec_id]["qty"]))
	_delivery_pending = false
	delivery_arrived.emit(contents)

# ─── Reorder / Delivery ───────────────────────────────────────────

func check_and_order() -> int:
	# Returns number of sections that need restocking
	var sections_to_order: Array = []
	var all_sections := _stock.keys()
	for sec_id in all_sections:
		if get_stock(sec_id) < _section_min_stock[sec_id]:
			sections_to_order.append(sec_id)
			low_stock_warning.emit(sec_id)
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
	# Simulate delivery arriving after a delay (handled externally via timer)

func is_delivery_pending() -> bool:
	return _delivery_pending

func get_delivery_contents() -> Array:
	return _delivery_contents

# ─── Stock Status ─────────────────────────────────────────────────

func _check_low_stock(section_id: String) -> void:
	var qty := int(_stock[section_id]["qty"])
	var min_qty :int= _section_min_stock.get(section_id, 10)
	if qty <= min_qty and qty > 0:
		low_stock_warning.emit(section_id)
	elif qty == 0:
		low_stock_warning.emit(section_id)  # emit for out-of-stock too

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
