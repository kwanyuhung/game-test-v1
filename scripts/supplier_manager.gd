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

# 🔥 修复：显式声明返回值类型
func get_supplier_by_id(sid: String) -> Dictionary:
	for s in _suppliers:
		if s["id"] == sid:
			return s
	return {}  # 不返回null，返回空字典，彻底杜绝null

func sign_contract(supplier_id: String) -> bool:
	if _contracts.has(supplier_id):
		return false
	_contracts[supplier_id] = {"level": 1, "favor": 0.6}
	new_contract_signed.emit(supplier_id)
	return true

func upgrade_contract(supplier_id: String) -> bool:
	if not _contracts.has(supplier_id):
		return false
	var c: Dictionary = _contracts[supplier_id]
	var lvl: int = c["level"]
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
	var lvl: int = get_contract_level(supplier_id)
	if lvl == 0: return 500
	if lvl == 1: return 1000
	return 2000

func get_cost_multiplier(supplier_id: String) -> float:
	var sup: Dictionary = get_supplier_by_id(supplier_id)
	var base: float = sup.get("base_cost_mult", 1.0)
	var lvl_disc: float = 1.0 - (get_contract_level(supplier_id) * 0.05)
	var favor_disc: float = 1.0 - (get_favor(supplier_id) * 0.10)
	return maxf(base * lvl_disc * favor_disc, 0.6)

func order_stock(supplier_id: String, section_id: String, quantity: int, cost_per_unit: float) -> bool:
	var sup: Dictionary = get_supplier_by_id(supplier_id)
	if not _contracts.has(supplier_id):
		return false
	var mult: float = get_cost_multiplier(supplier_id)
	var total_cost: float = cost_per_unit * quantity * mult
	var reliability: float = sup.get("reliability", 0.9)
	var days: int = 2 if reliability >= 0.95 else 3
	_pending_orders.append({
		"supplier_id": supplier_id, 
		"section_id": section_id, 
		"quantity": quantity, 
		"cost": total_cost, 
		"days": days, 
		"rel": reliability
	})
	return true

# 🔥 终极修复：全类型声明 + 无null + 全安全访问
func process_orders() -> void:
	var arrived: Array = []
	var remaining_orders: Array = []
	
	# 遍历订单，强制声明类型为Dictionary，永远不会是null
	for o in _pending_orders:
		# 跳过无效数据
		if not o is Dictionary:
			continue
		
		# 安全递减天数
		var days_left: int = o.get("days", 0)
		days_left -= 1
		o["days"] = days_left
		
		# 安全判断送达条件
		var rel: float = o.get("rel", 0.0)
		if days_left <= 0 and randf() <= rel:
			arrived.append(o)
		else:
			remaining_orders.append(o)
	
	# 更新待处理订单
	_pending_orders = remaining_orders
	
	# 处理已送达订单，全安全访问
	for o in arrived:
		if not o is Dictionary:
			continue
		# 安全获取供应商ID
		var sup_id: String = o.get("supplier_id", "")
		var sup: Dictionary = get_supplier_by_id(sup_id)
		# 安全获取名称
		var sup_name: String = sup.get("name", "??")
		supplier_order_arrived.emit(sup_name)

func get_pending_orders() -> Array:
	return _pending_orders
