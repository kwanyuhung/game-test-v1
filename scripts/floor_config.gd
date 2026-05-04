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
extends Node

# ── World geometry ──────────────────────────────────────────────
const CELL_SIZE := 16
const WORLD_W   := 96   # tiles
const WORLD_H   := 800  # total world height (all floors stacked)
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
const ZONE_COMMON        := "common"
const ZONE_ROOFTOP       := "rooftop"
const ZONE_ENTRY_GATE    := "entry_gate"
const ZONE_CLAW_MACHINE  := "claw_machine"
const ZONE_DECOR         := "decor"
const ZONE_PET_ADOPTION  := "pet_adoption"
const ZONE_WAREHOUSE     := "warehouse"
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

# ── Zone helper ─────────────────────────────────────────────────
static func Z(ztype: String, x: int, y: int, w: int, h: int, meta: Dictionary = {}) -> Dictionary:
	return {"type": ztype, "x": x, "y": y, "w": w, "h": h, "meta": meta}

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
		return Vector2i(80, 15)

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

	static func get(sid: String) -> Dictionary:
		return _stalls.get(sid, {"name": sid, "cuisine": "Other", "color": Color(0.7, 0.7, 0.7), "glow": Color(0.8, 0.8, 0.8)})

	static func get_all() -> Array:
		return _stalls.values()

# ── Floor Definitions ──────────────────────────────────────────
var FLOOR_DEFS := []

func _init() -> void:
	_init_floors()

func _init_floors() -> void:
	FLOOR_DEFS = []

	# ── FLOOR G — Ground Level ─────────────────────────────────────────────────
	# Vertical layout: Lobby (y=2..15) | Food Street (y=17..33) | Parking (y=35..49)
	FLOOR_DEFS.append(FloorDef.new(
		0, "G", "lobby", Color(0.42, 0.44, 0.40),
		[
			# Lobby (y=2 to y=15)
			Z(ZONE_LOBBY,        0,  2, 80, 13),
			Z(ZONE_INFO_DESK,   40,  3, 16,  7),
			Z(ZONE_WC,          68,  3, 12,  7),
			# Ad billboards in lobby
			Z(ZONE_AD,         56,  3,  4,  5, {"ad_id": "summer_sale", "ad_text": "SUMMER SALE!", "ad_color": Color(1.0, 0.40, 0.20)}),
			Z(ZONE_AD,         56,  9,  4,  5, {"ad_id": "members_only", "ad_text": "MEMBERS ONLY", "ad_color": Color(0.20, 0.60, 1.0)}),
			# ATMs
			Z(ZONE_ATM,        58,  4,  4,  5),
			Z(ZONE_ATM,        58, 28,  4,  5),
			# Food Street Row 1 (y=3..11)
			Z(ZONE_FOOD_STALL,   2,  3, 14,  8, {"stall_id": "jp_ramen"}),
			Z(ZONE_FOOD_STALL,  18,  3, 14,  8, {"stall_id": "jp_sushi"}),
			Z(ZONE_FOOD_STALL,  34,  3, 14,  8, {"stall_id": "jp_takoyaki"}),
			Z(ZONE_FOOD_STALL,  50,  3, 14,  8, {"stall_id": "thai"}),
			Z(ZONE_FOOD_STALL,  66,  3, 14,  8, {"stall_id": "indian"}),
			# Food Street Row 2 (y=15..23)
			Z(ZONE_FOOD_STALL,   2, 15, 14,  8, {"stall_id": "chinese"}),
			Z(ZONE_FOOD_STALL,  18, 15, 14,  8, {"stall_id": "korean"}),
			Z(ZONE_FOOD_STALL,  34, 15, 14,  8, {"stall_id": "turkish"}),
			Z(ZONE_FOOD_STALL,  50, 15, 14,  8, {"stall_id": "vietnamese"}),
			Z(ZONE_FOOD_STALL,  66, 15, 14,  8, {"stall_id": "italian"}),
			# Food Street Row 3 (y=25..33)
			Z(ZONE_FOOD_STALL,   2, 25, 14,  8, {"stall_id": "mexican"}),
			Z(ZONE_FOOD_STALL,  18, 25, 14,  8, {"stall_id": "drinks"}),
			# Parking (y=35 to y=49)
			Z(ZONE_PARKING,      2, 35, 78, 14),
			# Vertical shafts
			Z(ZONE_ELEVATOR,    80,  2,  4, 47),
			Z(ZONE_STAIRS,      84,  2,  6, 47),
			# Dining tables in aisle gap (y=11..15)
			Z(ZONE_DECOR,      16, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      34, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      52, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      70, 11,  4,  4, {"decor_type": "dining_table"}),
		],
		[],
		false, false, true, true
	))

	# ── FLOOR 1 — Shoes ─────────────────────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		1, "1", "shoes", Color(0.52, 0.45, 0.40),
		[
			Z(ZONE_COMMON,        2,  3, 78, 38),
			Z(ZONE_SHOES_RACK,    2,  3, 24, 16, {"name": "LADIES SHOES", "color": Color(0.82, 0.55, 0.65)}),
			Z(ZONE_SHOES_RACK,   28,  3, 24, 16, {"name": "MENS SHOES", "color": Color(0.55, 0.60, 0.80)}),
			Z(ZONE_SHOES_RACK,   54,  3, 24, 16, {"name": "KIDS SHOES", "color": Color(0.70, 0.75, 0.90)}),
			Z(ZONE_SHOES_RACK,    2, 21, 38, 16, {"name": "SPORT SHOES", "color": Color(0.55, 0.80, 0.65)}),
			Z(ZONE_SHOES_RACK,   42, 21, 36, 16, {"name": "SANDALS", "color": Color(0.85, 0.72, 0.52)}),
			Z(ZONE_AD,           66,  4,  4,  6, {"ad_id": "sport_promo", "ad_text": "SPORT SALE!", "ad_color": Color(0.20, 0.80, 0.50)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[SZ("shoes_ladies", 2,  3, 24, 16),
		 SZ("shoes_mens",  28,  3, 24, 16),
		 SZ("shoes_kids",  54,  3, 24, 16)],
		true, true, true, true
	))

	# ── FLOOR 2 — Dresses / Fashion ─────────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		2, "2", "fashion", Color(0.55, 0.42, 0.52),
		[
			Z(ZONE_COMMON,        2,  3, 78, 38),
			Z(ZONE_DRESS_RACK,    2,  3, 26, 18, {"name": "LADIES WEAR", "color": Color(0.88, 0.58, 0.72)}),
			Z(ZONE_DRESS_RACK,   30,  3, 26, 18, {"name": "MENS WEAR", "color": Color(0.60, 0.68, 0.88)}),
			Z(ZONE_DRESS_RACK,   58,  3, 20, 18, {"name": "KIDS WEAR", "color": Color(0.72, 0.80, 0.95)}),
			Z(ZONE_DRESS_RACK,    2, 23, 38, 14, {"name": "ACTIVEWEAR", "color": Color(0.55, 0.82, 0.72)}),
			Z(ZONE_DRESS_RACK,   42, 23, 36, 14, {"name": "FORMAL WEAR", "color": Color(0.50, 0.50, 0.60)}),
			Z(ZONE_AD,           68,  4,  4,  6, {"ad_id": "fashion_week", "ad_text": "NEW LOOKS!", "ad_color": Color(0.95, 0.40, 0.80)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[SZ("ladies_wear", 2,  3, 26, 18),
		 SZ("mens_wear",  30,  3, 26, 18),
		 SZ("kids_wear",  58,  3, 20, 18)],
		true, true, true, true
	))

	# ── FLOOR 3 — Sport & Active ───────────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		3, "3", "sport", Color(0.40, 0.50, 0.55),
		[
			Z(ZONE_COMMON,        2,  3, 78, 38),
			Z(ZONE_SPORT_AREA,    2,  3, 24, 16, {"name": "GYM EQUIPMENT", "color": Color(0.55, 0.70, 0.80)}),
			Z(ZONE_SPORT_AREA,   28,  3, 24, 16, {"name": "SPORTS GEAR", "color": Color(0.65, 0.60, 0.55)}),
			Z(ZONE_SPORT_AREA,   54,  3, 24, 16, {"name": "TEAM SPORTS", "color": Color(0.70, 0.55, 0.55)}),
			Z(ZONE_SPORT_AREA,    2, 21, 38, 16, {"name": "ACTIVEWEAR", "color": Color(0.55, 0.78, 0.68)}),
			Z(ZONE_SPORT_AREA,   42, 21, 36, 16, {"name": "FITNESS", "color": Color(0.60, 0.75, 0.82)}),
			Z(ZONE_AD,           70,  4,  4,  6, {"ad_id": "sport_promo", "ad_text": "GEAR UP!", "ad_color": Color(0.20, 0.70, 0.90)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[SZ("gym", 2,  3, 24, 16),
		 SZ("sports_gear", 28,  3, 24, 16),
		 SZ("activewear", 2, 21, 38, 16)],
		true, true, true, true
	))

	# ── FLOOR 4 — Outdoor (Fishing, Hiking, Running) ────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		4, "4", "outdoor", Color(0.42, 0.55, 0.45),
		[
			Z(ZONE_COMMON,        2,  3, 78, 38),
			Z(ZONE_OUTDOOR_AREA,  2,  3, 24, 16, {"name": "FISHING", "color": Color(0.52, 0.70, 0.85)}),
			Z(ZONE_OUTDOOR_AREA, 28,  3, 24, 16, {"name": "HIKING", "color": Color(0.60, 0.75, 0.55)}),
			Z(ZONE_OUTDOOR_AREA, 54,  3, 24, 16, {"name": "RUNNING", "color": Color(0.85, 0.60, 0.50)}),
			Z(ZONE_OUTDOOR_AREA,  2, 21, 38, 16, {"name": "CAMPING", "color": Color(0.68, 0.60, 0.48)}),
			Z(ZONE_OUTDOOR_AREA, 42, 21, 36, 16, {"name": "CYCLING", "color": Color(0.55, 0.65, 0.72)}),
			Z(ZONE_AD,           70,  4,  4,  6, {"ad_id": "outdoor_sale", "ad_text": "ADVENTURE!", "ad_color": Color(0.40, 0.80, 0.45)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[SZ("fishing", 2,  3, 24, 16),
		 SZ("hiking",  28,  3, 24, 16),
		 SZ("running", 54,  3, 24, 16)],
		true, true, true, true
	))

	# ── FLOOR 5 — Stationery & Plants ──────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		5, "5", "stationery", Color(0.48, 0.55, 0.45),
		[
			Z(ZONE_COMMON,        2,  3, 78, 38),
			Z(ZONE_STATIONERY,    2,  3, 36, 18, {"name": "STATIONERY", "color": Color(0.75, 0.78, 0.90)}),
			Z(ZONE_STATIONERY,   40,  3, 38, 18, {"name": "OFFICE SUPPLIES", "color": Color(0.70, 0.75, 0.82)}),
			Z(ZONE_PLANTS_AREA,   2, 23, 38, 14, {"name": "INDOOR PLANTS", "color": Color(0.55, 0.82, 0.60)}),
			Z(ZONE_PLANTS_AREA,  42, 23, 36, 14, {"name": "GARDEN PLANTS", "color": Color(0.68, 0.82, 0.52)}),
			Z(ZONE_AD,           72,  4,  4,  6, {"ad_id": "new_arrivals", "ad_text": "BACK TO SCHOOL!", "ad_color": Color(0.60, 0.75, 1.0)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[SZ("stationery", 2,  3, 36, 18),
		 SZ("plants",     2, 23, 38, 14)],
		true, true, true, true
	))

	# ── FLOOR 6 — Staff Areas (Locker Room, Lounge, Training) ──────────────────
	FLOOR_DEFS.append(FloorDef.new(
		6, "6", "staff_area", Color(0.38, 0.38, 0.40),
		[
			Z(ZONE_COMMON,        2,  3, 78, 38),
			Z(ZONE_LOCKER,         2,  3, 30, 20, {"name": "LOCKER ROOM", "color": Color(0.45, 0.45, 0.50)}),
			Z(ZONE_STAFF_LOUNGE,  34,  3, 30, 20, {"name": "STAFF LOUNGE", "color": Color(0.52, 0.48, 0.44)}),
			Z(ZONE_TRAINING,       2, 25, 50, 14, {"name": "TRAINING ROOM", "color": Color(0.40, 0.48, 0.55)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[],
		false, false, true, true, true
	))

	# ── FLOOR 7 — Back Office (Admin, HR, Open Office) ───────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		7, "7", "back_office", Color(0.40, 0.42, 0.45),
		[
			Z(ZONE_COMMON,        2,  3, 78, 38),
			Z(ZONE_OFFICE_DESK,   2,  3, 38, 18, {"name": "ADMIN OFFICE", "color": Color(0.48, 0.52, 0.58)}),
			Z(ZONE_OFFICE_DESK,  42,  3, 36, 18, {"name": "HR DEPARTMENT", "color": Color(0.55, 0.50, 0.58)}),
			Z(ZONE_OFFICE_DESK,   2, 23, 78, 14, {"name": "OPEN OFFICE", "color": Color(0.45, 0.50, 0.55)}),
			Z(ZONE_MONITOR_ROOM, 66,  3, 12, 35, {"name": "MONITORING ROOM", "color": Color(0.20, 0.25, 0.30)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[],
		false, false, true, true, true
	))

	# ── FLOOR 8 — Executive Office ───────────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		8, "8", "exec_office", Color(0.35, 0.35, 0.40),
		[
			Z(ZONE_COMMON,         2,  3, 78, 38),
			Z(ZONE_EXEC_OFFICE,    2,  3, 38, 20, {"name": "EXEC OFFICE", "color": Color(0.42, 0.42, 0.48)}),
			Z(ZONE_EXEC_OFFICE,   42,  3, 36, 20, {"name": "BOARD ROOM", "color": Color(0.50, 0.48, 0.55)}),
			Z(ZONE_EXEC_OFFICE,    2, 25, 78, 12, {"name": "SECRETARIES", "color": Color(0.45, 0.45, 0.52)}),
			Z(ZONE_MONITOR_ROOM, 66,  3, 12, 35, {"name": "MONITORING ROOM", "color": Color(0.20, 0.22, 0.28)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[],
		false, false, true, true, true
	))

	# ── FLOOR 9 — Rooftop Café ──────────────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		9, "9", "rooftop", Color(0.65, 0.60, 0.50),
		[
			Z(ZONE_ROOFTOP,       2,  3, 78, 38),
			Z(ZONE_FOOD_COURT,    2,  3, 50, 20),
			Z(ZONE_FOOD_STALL,    2,  3, 14,  8, {"stall_id": "jp_ramen"}),
			Z(ZONE_FOOD_STALL,   18,  3, 14,  8, {"stall_id": "jp_sushi"}),
			Z(ZONE_FOOD_STALL,   34,  3, 14,  8, {"stall_id": "jp_takoyaki"}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
		],
		[SZ("cafe", 2, 3, 50, 20)],
		true, false, true, false, false, true
	))

	# ── FLOOR 10 — Pet Paradise ──────────────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		10, "10", "pet_paradise", Color(0.42, 0.70, 0.55),
		[
			Z(ZONE_COMMON,         2,  3, 78, 38),
			Z(ZONE_PET_ADOPTION,   2,  3, 22, 20, {"name": "ADOPTION", "color": Color(0.60, 0.88, 0.70)}),
			Z(ZONE_AD,            72,  4,  4,  6, {"ad_id": "pet_special", "ad_text": "ADOPT ME!", "ad_color": Color(0.60, 0.90, 0.60)}),
			Z(ZONE_ELEVATOR,     80,  2,  4, 40),
			Z(ZONE_STAIRS,       84,  2,  6, 40),
		],
		[SZ("pet", 2,  3, 22, 20)],
		true, false, true
	))

	# ── FLOOR 11 — Warehouse & Receiving Dock ─────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		11, "11", "warehouse", Color(0.55, 0.45, 0.38),
		[
			Z(ZONE_WAREHOUSE,     2,  3, 78, 38),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
		],
		[],
		false, false, true, false
	))

# ── Accessors ─────────────────────────────────────────────────────────────────

static func get_floor(idx: int) -> FloorDef:
	if idx < 0 or idx >= FLOOR_DEFS.size():
		return FLOOR_DEFS[0]
	return FLOOR_DEFS[idx]

static func floor_count() -> int:
	return FLOOR_DEFS.size()

static func get_stall_def(stall_id: String) -> Dictionary:
	return FoodStallDef.get(stall_id)

static func get_all_stalls() -> Array:
	return FoodStallDef.get_all()
