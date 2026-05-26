# floor_config.gd
# ─────────────────────────────────────────────────────────────────────────────
# CENTRAL FLOOR DATA — all floor layouts, zones, and world geometry.
#
# TO ADD A FLOOR:
#   1. Append a FloorDef to FLOOR_DEFS in this file.
#   2. Zones are rendered in order — later zones draw on top of earlier.
#   3. Use Z() for generic zones, SZ() for retail section zones.
#
# TO ADD A ZONE TYPE:
#   1. Add a ZONE_* constant above.
#   2. Add a _build_zone_<type>() function in floor_builder.gd.
#   3. Add the case to _build_zone() match statement in floor_builder.gd.
#
# TO CHANGE WORLD SIZE:
#   Change WORLD_W, WORLD_H, CELL_SIZE below. All zone coordinates
#   are tile-based so they automatically scale.
# ─────────────────────────────────────────────────────────────────────────────
class_name FloorConfig

extends Node

static var _static_floors: Array = []
static var _initialized := false

# ── World geometry ──────────────────────────────────────────────
const CELL_SIZE := 16
const WORLD_W   := 512   # tiles (4x larger for more walking space)
const WORLD_H   := 3200  # total world height (all floors stacked)
const WORLD_PIXEL_H := WORLD_W * CELL_SIZE   # 1536

# ── Zone type constants ─────────────────────────────────────────
const ZONE_WALL          := "wall"
const ZONE_AISLE         := "aisle_floor"
const ZONE_SECTION       := "section"
const ZONE_LOBBY         := "lobby"
const ZONE_FOOD_STALL    := "food_stall"
const ZONE_FOOD_COURT    := "food_court"
const ZONE_PARKING       := "parking"
const ZONE_WC            := "wc"
const ZONE_INFO_DESK     := "info_desk"
const ZONE_ELEVATOR      := "elevator_shaft"
const ZONE_STAIRS        := "stairs"
const ZONE_ESCALATOR     := "escalator"
const ZONE_COMMON        := "common"
const ZONE_ROOFTOP       := "rooftop"
const ZONE_ENTRY_GATE    := "entry_gate"
const ZONE_CLAW_MACHINE  := "claw_machine"
const ZONE_DECOR         := "decor"
const ZONE_PET_ADOPTION  := "pet_adoption"
const ZONE_WAREHOUSE       := "warehouse"
const ZONE_TRUCK_DOCK     := "truck_dock"
const ZONE_FORKLIFT       := "forklift"
const ZONE_STORAGE_SHELF    := "storage_shelf"
const ZONE_CONVEYOR       := "conveyor"
const ZONE_PACKING_STATION := "packing_station"
const ZONE_ATM           := "atm"
const ZONE_AD            := "ad"
const ZONE_SHOES_RACK    := "shoes_rack"
const ZONE_DRESS_RACK    := "dress_rack"
const ZONE_SPORT_AREA    := "sport_area"
const ZONE_OUTDOOR_AREA  := "outdoor_area"
const ZONE_STATIONERY    := "stationery"
const ZONE_PLANTS_AREA   := "plants_area"
const ZONE_LOCKER        := "locker"
const ZONE_STAFF_LOUNGE  := "staff_lounge"
const ZONE_TRAINING      := "training"
const ZONE_OFFICE_DESK   := "office_desk"
const ZONE_EXEC_OFFICE   := "exec_office"
const ZONE_MONITOR_ROOM  := "monitor_room"
const ZONE_HOME_DECOR       := "home_decor"
const ZONE_FURNITURE        := "furniture"
const ZONE_OUTDOOR_LIVING   := "outdoor_living"
const ZONE_ORGANIZATION     := "organization"
const ZONE_LIGHTING        := "lighting"
const ZONE_CUSTOMER_SERVICE := "customer_service"
const ZONE_LOYALTY_KIOSK    := "loyalty_kiosk"
const ZONE_GIFT_WRAP        := "gift_wrap"
const ZONE_DIGITAL_KIOSK    := "digital_kiosk"
const ZONE_JUICE_BAR       := "juice_bar"
const ZONE_HEALTH_FOOD      := "health_food"
const ZONE_SMOOTHIE         := "smoothie"
const ZONE_SALAD_BAR        := "salad_bar"
const ZONE_KIDS_PLAY        := "kids_play"
const ZONE_KIDS_CLOTHING    := "kids_clothing"
const ZONE_NURSING_ROOM     := "nursing_room"
const ZONE_FAMILY_WC        := "family_wc"
const ZONE_KIDS_CLUB        := "kids_club"
const ZONE_ENTERTAINMENT   := "entertainment"
const ZONE_DARTS_BOARD     := "darts_board"
const ZONE_POOL_TABLE      := "pool_table"
const ZONE_KARAOKE         := "karaoke"
const ZONE_CANTEEN         := "canteen"
const ZONE_PHONE_GADGETS   := "phone_gadgets"
const ZONE_SMART_HOME     := "smart_home"
const ZONE_ELECTRONICS    := "electronics"
const ZONE_REPAIR_COUNTER := "repair_counter"
const ZONE_CAFE_COUNTER    := "cafe_counter"
const ZONE_PROMO_BOOTH        := "promo_booth"
const ZONE_WAREHOUSE_STOCK_VIEW := "wh_stock_view"
const ZONE_STORE_NEWS          := "store_news"
const ZONE_LOST_FOUND           := "lost_found"
const ZONE_VENDING_MACHINE := "vending_machine"

# ── Zone class ───────────────────────────────────────────────────
class Zone:
	var type: String
	var x: int
	var y: int
	var w: int
	var h: int
	var meta: Dictionary

	func _init(p_type: String = "", p_x: int = 0, p_y: int = 0, p_w: int = 0, p_h: int = 0, p_meta: Dictionary = {}) -> void:
		type = p_type
		x = p_x
		y = p_y
		w = p_w
		h = p_h
		meta = p_meta

	func _from_dict(d: Dictionary) -> Zone:
		type = d.get("type", "")
		x = d.get("x", 0)
		y = d.get("y", 0)
		w = d.get("w", 0)
		h = d.get("h", 0)
		meta = d.get("meta", {})
		return self

	func to_dict() -> Dictionary:
		return {"type": type, "x": x, "y": y, "w": w, "h": h, "meta": meta}

	static func from_dict(d: Dictionary) -> Zone:
		return Zone.new()._from_dict(d)

# ── Zone helper ─────────────────────────────────────────────────
static func Z(ztype: String, x: int, y: int, w: int, h: int, meta: Dictionary = {}) -> Dictionary:
	return Zone.new(ztype, x, y, w, h, meta).to_dict()

static func SZ(section_id: String, x: int, y: int, w: int, h: int) -> Dictionary:
	return {"type": ZONE_SECTION, "section_id": section_id, "x": x, "y": y, "w": w, "h": h}

# ── FloorDef class ───────────────────────────────────────────────
class FloorDef:
	var index: int
	var label: String
	var theme: String
	var ambient_color: Color
	var zones: Array
	var section_zones: Array
	var has_shopping: bool
	var has_checkout: bool
	var has_elevator: bool
	var has_stairs: bool
	var is_staff_only: bool
	var is_rooftop: bool

	func _init(
		p_idx: int, p_label: String, p_theme: String, p_ambient: Color,
		p_zones: Array, p_sections: Array,
		p_shopping: bool, p_checkout: bool, p_elevator: bool, p_stairs: bool,
		p_staff: bool = false, p_rooftop: bool = false
	):
		index = p_idx; label = p_label; theme = p_theme; ambient_color = p_ambient
		zones = p_zones; section_zones = p_sections
		has_shopping = p_shopping; has_checkout = p_checkout
		has_elevator = p_elevator; has_stairs = p_stairs
		is_staff_only = p_staff; is_rooftop = p_rooftop

	func elevator_tile() -> Vector2i:
		# Must match SHAFT_X in elevator.gd (tile 6)
		return Vector2i(6, 15)

	func stairs_tile() -> Vector2i:
		return Vector2i(84, 15)

	func parking_origin() -> Vector2i:
		return Vector2i(2, 38)

# ── Food Stall Definitions ──────────────────────────────────────
class FoodStallDef:
	static var _stalls := {}

	static func _static_init() -> void:
		_stalls["jp_ramen"]   = {"name": "Ramen", "cuisine": "Japanese", "color": Color(0.90, 0.70, 0.50), "glow": Color(1.0, 0.85, 0.60)}
		_stalls["jp_sushi"]   = {"name": "Sushi", "cuisine": "Japanese", "color": Color(0.80, 0.55, 0.40), "glow": Color(1.0, 0.70, 0.55)}
		_stalls["jp_takoyaki"]= {"name": "Takoyaki", "cuisine": "Japanese", "color": Color(0.85, 0.75, 0.55), "glow": Color(1.0, 0.90, 0.60)}
		_stalls["thai"]       = {"name": "Thai Food", "cuisine": "Thai", "color": Color(0.85, 0.70, 0.55), "glow": Color(1.0, 0.80, 0.50)}
		_stalls["indian"]     = {"name": "Indian", "cuisine": "Indian", "color": Color(0.90, 0.70, 0.50), "glow": Color(1.0, 0.75, 0.40)}
		_stalls["chinese"]    = {"name": "Chinese", "cuisine": "Chinese", "color": Color(0.85, 0.65, 0.45), "glow": Color(1.0, 0.80, 0.45)}
		_stalls["korean"]     = {"name": "Korean", "cuisine": "Korean", "color": Color(0.80, 0.60, 0.50), "glow": Color(1.0, 0.70, 0.55)}
		_stalls["turkish"]    = {"name": "Turkish", "cuisine": "Turkish", "color": Color(0.85, 0.60, 0.45), "glow": Color(1.0, 0.75, 0.45)}
		_stalls["vietnamese"] = {"name": "Vietnamese", "cuisine": "Vietnamese", "color": Color(0.80, 0.70, 0.50), "glow": Color(0.90, 1.0, 0.55)}
		_stalls["italian"]    = {"name": "Italian", "cuisine": "Italian", "color": Color(0.85, 0.55, 0.45), "glow": Color(1.0, 0.65, 0.45)}
		_stalls["mexican"]    = {"name": "Mexican", "cuisine": "Mexican", "color": Color(0.85, 0.60, 0.40), "glow": Color(1.0, 0.70, 0.35)}
		_stalls["drinks"]     = {"name": "Drinks", "cuisine": "Beverages", "color": Color(0.60, 0.80, 0.90), "glow": Color(0.70, 1.0, 1.0)}
		_stalls["canteen_rice"]       = {"name": "Rice & Congee", "cuisine": "Chinese", "color": Color(0.85, 0.75, 0.60), "glow": Color(1.0, 0.90, 0.70)}
		_stalls["canteen_noodle"]     = {"name": "Noodle Bar", "cuisine": "Asian", "color": Color(0.80, 0.70, 0.55), "glow": Color(1.0, 0.85, 0.60)}
		_stalls["canteen_meat"]       = {"name": "Grill Station", "cuisine": "International", "color": Color(0.85, 0.60, 0.50), "glow": Color(1.0, 0.75, 0.60)}
		_stalls["canteen_veg"]        = {"name": "Veggie Corner", "cuisine": "Vegetarian", "color": Color(0.60, 0.85, 0.60), "glow": Color(0.80, 1.0, 0.80)}
		_stalls["canteen_drinks"]     = {"name": "Drinks Bar", "cuisine": "Beverages", "color": Color(0.60, 0.80, 0.90), "glow": Color(0.70, 1.0, 1.0)}
		_stalls["canteen_fruit"]      = {"name": "Fruit Station", "cuisine": "Fresh", "color": Color(0.80, 0.55, 0.40), "glow": Color(1.0, 0.75, 0.55)}
		_stalls["burger_king_style"]  = {"name": "Burger Bar", "cuisine": "American", "color": Color(0.85, 0.65, 0.40), "glow": Color(1.0, 0.85, 0.50)}
		_stalls["pizza_hut_style"]     = {"name": "Pizza Corner", "cuisine": "Italian", "color": Color(0.85, 0.55, 0.45), "glow": Color(1.0, 0.65, 0.45)}
		_stalls["fried_chicken_style"] = {"name": "Fried Chicken", "cuisine": "American", "color": Color(0.85, 0.70, 0.45), "glow": Color(1.0, 0.85, 0.50)}
		_stalls["hot_dog_style"]       = {"name": "Hot Dog Stand", "cuisine": "American", "color": Color(0.85, 0.60, 0.50), "glow": Color(1.0, 0.75, 0.55)}
		_stalls["ice_cream_style"]    = {"name": "Ice Cream Parlor", "cuisine": "Dessert", "color": Color(0.80, 0.70, 0.85), "glow": Color(0.95, 0.85, 1.0)}

	static func get_stall(sid: String) -> Dictionary:
		return _stalls.get(sid, {"name": sid, "cuisine": "Other", "color": Color(0.7, 0.7, 0.7), "glow": Color(0.8, 0.8, 0.8)})

	static func get_all_stalls() -> Array:
		return _stalls.values()

# ── Floor Definitions ──────────────────────────────────────────
var FLOOR_DEFS := []

func _init() -> void:
	_init_floors()

func _init_floors() -> void:
	FLOOR_DEFS = []
	var f = FileAccess.open("res://scripts/floor_config_data.json", FileAccess.READ)
	if f == null:
		push_error("Failed to open floor_config_data.json")
		return
	var json_str = f.get_as_text()
	f.close()
	var j = JSON.new()
	j.parse(json_str)
	var data = j.get_data()
	if typeof(data) != TYPE_ARRAY:
		push_error("Invalid floor_config_data.json format")
		return
	for floor_json in data:
		var ambient = Color(floor_json["ambient_color"][0], floor_json["ambient_color"][1], floor_json["ambient_color"][2])
		var zones = []
		for z in floor_json["zones"]:
			var zone = {"type": z["type"], "x": z["x"], "y": z["y"], "w": z["w"], "h": z["h"]}
			if z.has("meta"):
				var meta = {}
				if z["meta"].has("color"):
					var c = z["meta"]["color"]
					meta["color"] = Color(c[0], c[1], c[2])
				if z["meta"].has("name"):
					meta["name"] = z["meta"]["name"]
				for k in z["meta"].keys():
					if k not in ["color", "name"]:
						meta[k] = z["meta"][k]
				zone["meta"] = meta
			zones.append(zone)
		var section_zones = []
		for s in floor_json.get("sections", []):
			section_zones.append({"id": s["id"], "x": s["x"], "y": s["y"], "w": s["w"], "h": s["h"]})
		FLOOR_DEFS.append(FloorDef.new(
			floor_json["id"], floor_json["label"], floor_json["theme"], ambient,
			zones, section_zones,
			floor_json.get("has_shopping", true),
			floor_json.get("has_checkout", true),
			floor_json.get("has_elevator", true),
			floor_json.get("has_stairs", true),
			floor_json.get("is_staff_only", false),
			floor_json.get("is_rooftop", false)
		))

static func _ensure_initialized() -> void:
	if not _initialized:
		var temp = FloorConfig.new()
		temp._init_floors()
		_static_floors = temp.FLOOR_DEFS
		_initialized = true

static func get_floor(idx: int) -> FloorDef:
	_ensure_initialized()
	if idx < 0 or idx >= _static_floors.size():
		return _static_floors[0]
	return _static_floors[idx]

static func floor_count() -> int:
	_ensure_initialized()
	return _static_floors.size()

static func get_stall_def(stall_id: String) -> Dictionary:
	return FoodStallDef.get_stall(stall_id)

# Tile mapping for TileMap-based rendering
# Returns {"tile_id": int, "layer": int} for a given zone type
# IMPORTANT: tile_id corresponds to TileSet source index, not tile ID
# -1 means skip TileMap (special sprite-based handler)
# TileSet source indices (updated with blocked at 0):
# 0=blocked, 1=atm, 2=floor_common, 3=floor_shoes, 4=floor_sport
# 5=floor_storage_shelf, 6=floor_truck_dock, 7=floor_warehouse, 8=floor_wc
# 9=kiosk, 10=plant, 11=promo_booth, 12=table, 13=floor_conveyor
# 14=vending_machine, 15=floor_dress, 16=floor_food_court, 17=floor_forklift
# 18=floor_lobby, 19=floor_parking, 20=floor_pet_adoption, 21=floor_rooftop
static func get_tile_for_zone(zone_type: String) -> Dictionary:
	# Strip ZONE_ prefix if present (JSON has "ZONE_LOBBY", mapping uses "lobby")
	var normalized_type = zone_type
	if zone_type.begins_with("ZONE_"):
		normalized_type = zone_type.substr(5).to_lower()

	var mapping = {
		# Walkable floor tiles
		"lobby": {"tile_id": 18, "layer": 0},          # floor_lobby
		"common": {"tile_id": 2, "layer": 0},           # floor_common
		"food_court": {"tile_id": 16, "layer": 0},      # floor_food_court
		"food_stall": {"tile_id": 2, "layer": 0},       # floor_common (walkable)
		"warehouse": {"tile_id": 7, "layer": 0},        # floor_warehouse
		"wc": {"tile_id": 8, "layer": 0},              # floor_wc
		# Non-walkable (blocked) - use black tile
		"elevator_shaft": {"tile_id": 0, "layer": 0},  # blocked
		"stairs": {"tile_id": 0, "layer": 0},          # blocked
		"escalator": {"tile_id": 0, "layer": 0},       # blocked
		# Decor items
		"decor": {"tile_id": 12, "layer": 2},          # table (layer 2 = decor)
		"vending_machine": {"tile_id": 14, "layer": 0}, # vending_machine
		"promo_booth": {"tile_id": 11, "layer": 0},   # promo_booth
		"ad": {"tile_id": 9, "layer": 0},              # kiosk
		"atm": {"tile_id": 1, "layer": 0},             # atm
		"customer_service": {"tile_id": 9, "layer": 0}, # kiosk
		"info_desk": {"tile_id": 9, "layer": 0},       # kiosk
		"loyalty_kiosk": {"tile_id": 9, "layer": 0},  # kiosk
		"gift_wrap": {"tile_id": 9, "layer": 0},      # kiosk
		"digital_kiosk": {"tile_id": 9, "layer": 0},  # kiosk
		"parking": {"tile_id": 19, "layer": 0},        # floor_parking
		"rooftop": {"tile_id": 21, "layer": 0},        # floor_rooftop
		"section": {"tile_id": 2, "layer": 0},         # floor_common
		"pet_adoption": {"tile_id": 20, "layer": 0},   # floor_pet_adoption
		"claw_machine": {"tile_id": 0, "layer": 0},    # blocked (machine)
		"truck_dock": {"tile_id": 6, "layer": 0},     # floor_truck_dock
		"forklift": {"tile_id": 17, "layer": 0},      # floor_forklift
		"conveyor": {"tile_id": 13, "layer": 0},       # floor_conveyor
		"storage_shelf": {"tile_id": 5, "layer": 0},  # floor_storage_shelf
		"warehouse_stock_view": {"tile_id": 7, "layer": 0},   # floor_warehouse (alias)
		"wh_stock_view": {"tile_id": 7, "layer": 0},   # floor_warehouse (alias)
		"lost_found": {"tile_id": 11, "layer": 0},     # promo_booth
		"store_news": {"tile_id": 9, "layer": 0},      # kiosk
		"shoes_rack": {"tile_id": 3, "layer": 0},     # floor_shoes
		"dress_rack": {"tile_id": 15, "layer": 0},    # floor_dress
		"sport_area": {"tile_id": 4, "layer": 0},     # floor_sport
		"outdoor_area": {"tile_id": 21, "layer": 0},  # floor_rooftop
		"stationery": {"tile_id": 2, "layer": 0},     # floor_common
		"plants_area": {"tile_id": 10, "layer": 0},   # plant
		"locker": {"tile_id": 0, "layer": 0},        # blocked (lockers)
		"staff_lounge": {"tile_id": 2, "layer": 0},  # floor_common
		"training": {"tile_id": 2, "layer": 0},       # floor_common
		"office_desk": {"tile_id": 0, "layer": 0},   # blocked (desks)
		"exec_office": {"tile_id": 0, "layer": 0},   # blocked (desks)
		"monitor_room": {"tile_id": 0, "layer": 0},   # blocked (equipment)
		"home_decor": {"tile_id": 0, "layer": 0},    # blocked (shelves)
		"furniture": {"tile_id": 0, "layer": 0},     # blocked (shelves)
		"outdoor_living": {"tile_id": 21, "layer": 0}, # floor_rooftop
		"organization": {"tile_id": 0, "layer": 0},   # blocked (shelves)
		"lighting": {"tile_id": 0, "layer": 0},       # blocked (displays)
		"juice_bar": {"tile_id": 2, "layer": 0},     # floor_common
		"health_food": {"tile_id": 2, "layer": 0},   # floor_common
		"smoothie": {"tile_id": 2, "layer": 0},      # floor_common
		"salad_bar": {"tile_id": 2, "layer": 0},     # floor_common
		"kids_play": {"tile_id": 2, "layer": 0},     # floor_common
		"kids_clothing": {"tile_id": 15, "layer": 0}, # floor_dress
		"nursing_room": {"tile_id": 8, "layer": 0},  # floor_wc
		"family_wc": {"tile_id": 8, "layer": 0},     # floor_wc
		"kids_club": {"tile_id": 2, "layer": 0},     # floor_common
		"phone_gadgets": {"tile_id": 0, "layer": 0}, # blocked (displays)
		"smart_home": {"tile_id": 0, "layer": 0},    # blocked (displays)
		"electronics": {"tile_id": 0, "layer": 0},    # blocked (shelves)
		"repair_counter": {"tile_id": 0, "layer": 0}, # blocked (counter)
		"cafe_counter": {"tile_id": 0, "layer": 0},  # blocked (counter)
		"canteen": {"tile_id": 2, "layer": 0},       # floor_common
		"karaoke": {"tile_id": 2, "layer": 0},       # floor_common
		"pool_table": {"tile_id": 0, "layer": 0},    # blocked (table)
		"darts_board": {"tile_id": 0, "layer": 0},   # blocked (board)
		"entertainment": {"tile_id": 2, "layer": 0}, # floor_common
		"aisle_floor": {"tile_id": 2, "layer": 0},   # floor_common
		# Additional zone types from JSON
		"entry_gate": {"tile_id": 2, "layer": 0},    # floor_common
		"packing_station": {"tile_id": 0, "layer": 0}, # blocked (station)
	}
	var result = mapping.get(normalized_type, null)
	if result != null:
		return result
	# Default: floor_common for walkable areas
	return {"tile_id": 2, "layer": 0}

# Get zone bounds for a floor (used for camera limits)
static func get_floor_zone_bounds(floor_idx: int) -> Dictionary:
	_ensure_initialized()
	var fd = get_floor(floor_idx)
	if fd == null:
		return {"min_y": 2, "max_y": 42, "height": 40}
	var min_y = 800
	var max_y = 0
	for zone in fd.zones:
		if zone.y < min_y:
			min_y = zone.y
		if zone.y + zone.h > max_y:
			max_y = zone.y + zone.h
	return {"min_y": min_y, "max_y": max_y, "height": max_y - min_y + 4}
