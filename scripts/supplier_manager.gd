# Phase S: Supplier Relations
class_name SupplierManagerScript
extends Node

var _suppliers: Array = [
	{"id": "fresh_farm",     "name": "FreshFarm Co.",     "sections": ["produce","dairy"],   "base_cost_mult": 1.0,  "reliability": 0.95},
	{"id": "golden_grain",   "name": "GoldenGrain Baker",  "sections": ["bakery"],             "base_cost_mult": 1.1,  "reliability": 0.90},
	{"id": "polar_drinks",   "name": "Polar Beverages",    "sections": ["drinks"],             "base_cost_mult": 0.9,  "reliability": 0.98},
	{"id": "snack_nation",   "name": "SnackNation",        "sections": ["snacks"],             "base_cost_mult": 0.95, "reliability": 0.85},
	{"id": "meat_king",      "name": "MeatKing Direct",    "sections": ["meat"],               "base_cost_mult": 1.15, "reliability": 0.92},
	{"id": "frost_logistics","name": "FrostLogistics",     "sections": ["frozen"],             "base_cost_mult": 1.2,  "reliability": 0.88},
]
var _contracts: Dictionary = {}
var _pending_orders: Array = []

signal supplier_order_arrived(supplier_name: String)
signal new_contract_signed(supplier_id: String)

func get_suppliers() -> Array:
	return _suppliers

func get_supplier_by_id(sid: String):
	for s in _suppliers:
		if s["id"] == sid:
			return s
	return null

func sign_contract(supplier_id: String) -> bool:
	if _contracts.has(supplier_id):
		return false
	_contracts[supplier_id] = {"level": 1, "favor": 0.6}
	new_contract_signed.emit(supplier_id)
	return true

func upgrade_contract(supplier_id: String) -> bool:
	if not _contracts.has(supplier_id):
		return false
	var c = _contracts[supplier_id]
	var lvl = c["level"] as int
	if lvl >= 3:
		return false
	c["level"] = lvl + 1
	c["favor"] = minf(c["favor"] + 0.1, 1.0)
	new_contract_signed.emit(supplier_id)
	return true

func get_contract_level(supplier_id: String) -> int:
	return _contracts.get(supplier_id, {}).get("level", 0)

func get_favor(supplier_id: String) -> float:
	return _contracts.get(supplier_id, {}).get("favor", 0.5)

func get_contract_cost(supplier_id: String) -> int:
	var lvl = get_contract_level(supplier_id)
	if lvl == 0: return 500
	if lvl == 1: return 1000
	return 2000

func get_cost_multiplier(supplier_id: String) -> float:
	var sup = get_supplier_by_id(supplier_id)
	if sup == null:
		return 1.0
	var base = sup.get("base_cost_mult", 1.0)
	var lvl_disc = 1.0 - (get_contract_level(supplier_id) * 0.05)
	var favor_disc = 1.0 - (get_favor(supplier_id) * 0.10)
	return maxf(base * lvl_disc * favor_disc, 0.6)

func order_stock(supplier_id: String, section_id: String, quantity: int, cost_per_unit: float) -> bool:
	var sup = get_supplier_by_id(supplier_id)
	if sup == null or not _contracts.has(supplier_id):
		return false
	var mult = get_cost_multiplier(supplier_id)
	var total_cost = cost_per_unit * quantity * mult
	var reliability = sup.get("reliability", 0.9)
	var days = 2 if reliability >= 0.95 else 3
	_pending_orders.append({"supplier_id": supplier_id, "section_id": section_id, "quantity": quantity, "cost": total_cost, "days": days, "rel": reliability})
	return true

func process_orders() -> void:
	var arrived = []
	for o in _pending_orders:
		o["days"] -= 1
		if o["days"] <= 0 and randf() <= o["rel"]:
			arrived.append(o)
	_pending_orders = _pending_orders.filter(func(o): return o not in arrived)
	for o in arrived:
		var sup = get_supplier_by_id(o["supplier_id"])
		supplier_order_arrived.emit(sup["name"] if sup else "??")

func get_pending_orders() -> Array:
	return _pending_orders
