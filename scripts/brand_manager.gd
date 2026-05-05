# brand_manager.gd
# ═══════════════════════════════════════════════════════════════════════════════
# Brand Partnership System — manages brand data, products, events, and ads.
# Brands are loaded from JSON files in the `brands/` directory.
# Products are merged into the store catalog at runtime.
# ═══════════════════════════════════════════════════════════════════════════════
class_name BrandManager
extends Node

const BRANDS_DIR := "res://brands/"

# brand_id → Brand data dict
var _brands: Dictionary = {}
# product_id → {product, brand_id}
var _brand_products: Dictionary = {}
# active event_id → event data
var _active_events: Dictionary = {}

signal brand_data_loaded()
signal product_added(product: Dictionary, brand_id: String)
signal event_started(event_id: String, event_name: String)
signal event_ended(event_id: String)
signal ad_updated(ad_id: String, floor: int)

func _ready() -> void:
	add_to_group("brand_manager")
	load_all_brands()

# ─── Loading ─────────────────────────────────────────────────────────────────

func load_all_brands() -> void:
	_brands.clear()
	_brand_products.clear()
	_active_events.clear()

	var dir := DirAccess.open(BRANDS_DIR)
	if dir == null:
		push_warning("BrandManager: Cannot open brands directory")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and file_name != "brands.json":
			var path := BRANDS_DIR + file_name
			var brand_data = _load_brand_file(path)
			if brand_data.size() > 0:
				var brand_id = brand_data.get("brand_id", "unknown")
				_brands[brand_id] = brand_data
				_register_products(brand_data)
				_load_active_events(brand_data)
		file_name = dir.get_next()
	dir.list_dir_end()

	brand_data_loaded.emit()

func _load_brand_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("BrandManager: Cannot read " + path)
		return {}
	var content := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_warning("BrandManager: JSON parse error in " + path)
		return {}
	return json.get_data()

func _register_products(brand_data: Dictionary) -> void:
	var brand_id = brand_data.get("brand_id", "")
	var products: Array = brand_data.get("products", [])
	for p in products:
		var product_id = p.get("product_id", "")
		if product_id == "":
			continue
		_brand_products[product_id] = {
			"product": p,
			"brand_id": brand_id,
			"brand_name": brand_data.get("name", brand_id)
		}
		product_added.emit(p, brand_id)

func _load_active_events(brand_data: Dictionary) -> void:
	var events: Array = brand_data.get("active_events", [])
	var now := Time.get_datetime_string_from_system()
	for ev: Dictionary in events:
		var start: String = ev.get("start_time", "")
		var end: String = ev.get("end_time", "")
		if start != "" and end != "":
			if now >= start and now <= end:
				_active_events[ev.get("event_id", "")] = ev
				event_started.emit(ev.get("event_id", ""), ev.get("name", ""))

# ─── Products ────────────────────────────────────────────────────────────────

func get_all_brand_products() -> Array:
	var result := []
	for entry in _brand_products.values():
		result.append(entry)
	return result

func get_brand_products(brand_id: String) -> Array:
	var result := []
	for entry in _brand_products.values():
		if entry.brand_id == brand_id:
			result.append(entry)
	return result

func get_product_brand(product_id: String) -> String:
	if _brand_products.has(product_id):
		return _brand_products[product_id].brand_id
	return ""

func get_product_data(product_id: String) -> Dictionary:
	if _brand_products.has(product_id):
		return _brand_products[product_id].product
	return {}

# ─── Events ─────────────────────────────────────────────────────────────────

func get_active_events() -> Dictionary:
	return _active_events

func is_event_active(event_id: String) -> bool:
	return _active_events.has(event_id)

func get_xp_multiplier_for_product(product_id: String) -> float:
	# Check if any active event applies to this product
	# An event applies if it's the brand's event
	var brand_id = get_product_brand(product_id)
	if brand_id == "":
		return 1.0

	for ev in _active_events.values():
		# This is simplified — check if product belongs to event's brand
		var ev_brand_id = ""
		for bdata in _brands.values():
			var ev_id = ev.get("event_id", "")
			var brand_events: Array = bdata.get("active_events", [])
			for be in brand_events:
				if be.get("event_id", "") == ev_id:
					ev_brand_id = bdata.get("brand_id", "")
					break
		if ev_brand_id == brand_id:
			return ev.get("xp_multiplier", 1.0)
	return 1.0

func get_events_for_brand(brand_id: String) -> Array:
	if not _brands.has(brand_id):
		return []
	return _brands[brand_id].get("active_events", [])

func create_event(brand_id: String, event_data: Dictionary) -> bool:
	if not _brands.has(brand_id):
		return false
	var events: Array = _brands[brand_id].get("active_events", [])
	event_data["event_id"] = brand_id + "_event_" + str(events.size())
	events.append(event_data)
	_brands[brand_id]["active_events"] = events
	_active_events[event_data["event_id"]] = event_data
	event_started.emit(event_data["event_id"], event_data.get("name", ""))
	return true

# ─── Ads ────────────────────────────────────────────────────────────────────

func get_ads_for_floor(floor_idx: int) -> Array:
	var result := []
	for brand_data in _brands.values():
		var ads: Array = brand_data.get("ads", [])
		for ad: Dictionary in ads:
			if ad.get("floor", -1) == floor_idx:
				ad["brand_id"] = brand_data.get("brand_id", "")
				ad["brand_name"] = brand_data.get("name", "")
				result.append(ad)
	return result

func place_ad(brand_id: String, ad_data: Dictionary) -> bool:
	if not _brands.has(brand_id):
		return false
	var ads: Array = _brands[brand_id].get("ads", [])
	if not ads.has(ad_data):
		ads.append(ad_data)
		_brands[brand_id]["ads"] = ads
	ad_updated.emit(ad_data.get("ad_id", ""), ad_data.get("floor", 0))
	return true

# ─── Brand CRUD ─────────────────────────────────────────────────────────────

func add_product(brand_id: String, product: Dictionary) -> bool:
	if not _brands.has(brand_id):
		return false
	var products: Array = _brands[brand_id].get("products", [])
	var product_id = product.get("product_id", brand_id + "_" + str(products.size()))
	product["product_id"] = product_id
	products.append(product)
	_brands[brand_id]["products"] = products
	_register_products(_brands[brand_id])
	return true

func remove_product(brand_id: String, product_id: String) -> bool:
	if not _brands.has(brand_id):
		return false
	var products: Array = _brands[brand_id].get("products", [])
	var remaining := []
	for p in products:
		if p.get("product_id", "") != product_id:
			remaining.append(p)
	_brands[brand_id]["products"] = remaining
	if _brand_products.has(product_id):
		_brand_products.erase(product_id)
	return true

func update_product_price(brand_id: String, product_id: String, new_price: float) -> bool:
	if not _brands.has(brand_id):
		return false
	var products: Array = _brands[brand_id].get("products", [])
	for p in products:
		if p.get("product_id", "") == product_id:
			p["price"] = new_price
			_brands[brand_id]["products"] = products
			# Sync to brand_products
			if _brand_products.has(product_id):
				_brand_products[product_id].product["price"] = new_price
			return true
	return false

func get_brand(brand_id: String) -> Dictionary:
	return _brands.get(brand_id, {})

func get_all_brands() -> Array:
	return _brands.values()

func register_brand(brand_data: Dictionary) -> bool:
	var brand_id = brand_data.get("brand_id", "")
	if brand_id == "" or _brands.has(brand_id):
		return false
	_brands[brand_id] = brand_data
	_register_products(brand_data)
	_load_active_events(brand_data)
	return true

# ─── Stats ──────────────────────────────────────────────────────────────────

func record_purchase(product_id: String, qty: int, total_price: float) -> void:
	var brand_id = get_product_brand(product_id)
	if brand_id == "" or not _brands.has(brand_id):
		return
	var stats: Dictionary = _brands[brand_id].get("stats", {})
	stats["total_purchases"] = stats.get("total_purchases", 0) + qty
	stats["revenue"] = stats.get("revenue", 0.0) + total_price
	_brands[brand_id]["stats"] = stats

func get_brand_stats(brand_id: String) -> Dictionary:
	if _brands.has(brand_id):
		return _brands[brand_id].get("stats", {})
	return {}

# ─── Persistence ────────────────────────────────────────────────────────────

func save_brand(brand_id: String) -> bool:
	if not _brands.has(brand_id):
		return false
	var path := BRANDS_DIR + brand_id + ".json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("BrandManager: Cannot write " + path)
		return false
	var json_str := JSON.stringify(_brands[brand_id], "\t")
	f.store_string(json_str)
	f.close()
	return true

func save_all_brands() -> void:
	for brand_id in _brands.keys():
		save_brand(brand_id)
