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
const ZONE_HOME_DECOR       := "home_decor"      # home decor (rugs, candles, vases)
const ZONE_FURNITURE        := "furniture"        # furniture display
const ZONE_OUTDOOR_LIVING   := "outdoor_living"  # outdoor / patio furniture
const ZONE_ORGANIZATION     := "organization"     # home organization / storage
const ZONE_LIGHTING        := "lighting"        # lamps and lighting fixtures
const ZONE_CUSTOMER_SERVICE := "customer_service" # customer service desk
const ZONE_LOYALTY_KIOSK    := "loyalty_kiosk"   # loyalty / membership kiosk
const ZONE_GIFT_WRAP        := "gift_wrap"       # gift wrapping station
const ZONE_DIGITAL_KIOSK    := "digital_kiosk"   # digital info kiosk / store map
			# Phase H ??Home Electronics (Ground Floor extension)
			Z(ZONE_PHONE_GADGETS,    8, 11, 18, 6, {"name": "PHONES & GADGETS", "color": Color(0.35, 0.55, 0.80)}),
			Z(ZONE_SMART_HOME,      28, 11, 18, 6, {"name": "SMART HOME", "color": Color(0.40, 0.60, 0.70)}),
			Z(ZONE_ELECTRONICS,     48, 11, 18, 6, {"name": "ELECTRONICS", "color": Color(0.45, 0.50, 0.65)}),
			Z(ZONE_REPAIR_COUNTER,   8, 18, 18, 6, {"name": "REPAIR COUNTER", "color": Color(0.60, 0.45, 0.40)}),
const ZONE_JUICE_BAR       := "juice_bar"       # fresh juice counter
const ZONE_HEALTH_FOOD      := "health_food"     # health food shelf
const ZONE_SMOOTHIE         := "smoothie"        # smoothie station
const ZONE_SALAD_BAR        := "salad_bar"       # salad / grain bowl bar
const ZONE_KIDS_PLAY        := "kids_play"       # supervised kids play zone
const ZONE_KIDS_CLOTHING    := "kids_clothing"   # kids clothing section
const ZONE_NURSING_ROOM     := "nursing_room"    # nursing / baby room
const ZONE_FAMILY_WC        := "family_wc"      # family restroom / changing
const ZONE_KIDS_CLUB        := "kids_club"       # kids club reception
const ZONE_PHONE_GADGETS   := "phone_gadgets"   # phone / gadget accessories
const ZONE_SMART_HOME     := "smart_home"     # smart home devices
const ZONE_ELECTRONICS    := "electronics"     # general electronics shelf
const ZONE_REPAIR_COUNTER := "repair_counter"  # tech repair / service counter

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

			# Phase I — Info Hub & Services
			Z(ZONE_CUSTOMER_SERVICE,  8,  3, 16, 7, {"name": "CUSTOMER SERVICE", "color": Color(0.50, 0.55, 0.70)}),
			Z(ZONE_LOYALTY_KIOSK,   26,  3, 14, 7, {"name": "LOYALTY CENTER", "color": Color(0.60, 0.50, 0.75)}),
			Z(ZONE_GIFT_WRAP,        42,  3, 14, 7, {"name": "GIFT WRAPPING", "color": Color(0.72, 0.55, 0.70)}),
			Z(ZONE_DIGITAL_KIOSK,   58, 11,  8, 7, {"name": "INFO KIOSK", "color": Color(0.40, 0.65, 0.80)}),
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
	
	
	
#
 
P
h
a
s
e
 
G
 
?
?
G
a
r
d
e
n
 
&
 
H
o
m
e
 
L
i
v
i
n
g


	
	
	
Z
(
Z
O
N
E
_
H
O
M
E
_
D
E
C
O
R
,
 
 
 
 
 
2
,
 
 
3
,
 
2
2
,
 
1
8
,
 
{
"
n
a
m
e
"
:
 
"
H
O
M
E
 
D
E
C
O
R
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
7
8
,
 
0
.
6
5
,
 
0
.
5
0
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
F
U
R
N
I
T
U
R
E
,
 
 
 
 
2
6
,
 
 
3
,
 
2
6
,
 
1
8
,
 
{
"
n
a
m
e
"
:
 
"
F
U
R
N
I
T
U
R
E
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
6
5
,
 
0
.
5
5
,
 
0
.
4
8
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
O
U
T
D
O
O
R
_
L
I
V
I
N
G
,
 
5
4
,
 
 
3
,
 
2
4
,
 
1
8
,
 
{
"
n
a
m
e
"
:
 
"
O
U
T
D
O
O
R
 
L
I
V
I
N
G
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
5
5
,
 
0
.
7
0
,
 
0
.
5
2
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
O
R
G
A
N
I
Z
A
T
I
O
N
,
 
 
 
2
,
 
2
3
,
 
3
8
,
 
1
4
,
 
{
"
n
a
m
e
"
:
 
"
O
R
G
A
N
I
Z
A
T
I
O
N
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
6
0
,
 
0
.
6
0
,
 
0
.
7
0
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
L
I
G
H
T
I
N
G
,
 
 
 
 
 
4
2
,
 
2
3
,
 
3
6
,
 
1
4
,
 
{
"
n
a
m
e
"
:
 
"
L
I
G
H
T
I
N
G
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
9
0
,
 
0
.
8
5
,
 
0
.
6
0
)
}
)
,
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

	# ── FLOOR 8 — Arcade & Claw Machines ────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		8, "8", "arcade", Color(0.22, 0.18, 0.38),
		[
			Z(ZONE_COMMON,         2,  3, 78, 38),
			Z(ZONE_KIDS_PLAY,     10,  3, 30, 20, {"name": "PLAY ZONE", "color": Color(0.40, 0.55, 0.80)}),
			# Claw machines — 4 arcade cabinets
			Z(ZONE_CLAW_MACHINE,   2,  3, 10, 14, {"machine_id": "claw_1", "prize_pool": 0}),
			Z(ZONE_CLAW_MACHINE,  14,  3, 10, 14, {"machine_id": "claw_2", "prize_pool": 1}),
			Z(ZONE_CLAW_MACHINE,   2, 20, 10, 14, {"machine_id": "claw_3", "prize_pool": 2}),
			Z(ZONE_CLAW_MACHINE,  14, 20, 10, 14, {"machine_id": "claw_4", "prize_pool": 3}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[],
		false, false, true, true, true
	))

	# ── FLOOR 9 — Staff Room ───────────────────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		9, "9", "staff_room", Color(0.38, 0.42, 0.50),
		[
			Z(ZONE_COMMON,         2,  3, 78, 38),
			Z(ZONE_OFFICE_DESK,   10,  3, 30, 20, {"name": "PRICE TERMINAL", "terminal": true, "color": Color(0.40, 0.55, 0.65)}),
			Z(ZONE_STAFF_LOUNGE,  42,  3, 34, 20, {"name": "STAFF AREA", "color": Color(0.45, 0.45, 0.50)}),
			Z(ZONE_TRAINING,       2, 25, 78, 14, {"name": "OPERATIONS CENTER", "color": Color(0.38, 0.48, 0.55)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
		],
		[],
		false, false, true, true, true  # is_staff_only=true (6th arg)
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
	
#
 
?

?

 
F
l
o
o
r
 
1
2
 
?
?
J
u
i
c
e
 
B
a
r
 
&
 
F
r
e
s
h
 
(
P
h
a
s
e
 
J
)
 
?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?

?



	
F
L
O
O
R
_
D
E
F
S
.
a
p
p
e
n
d
(
F
l
o
o
r
D
e
f
.
n
e
w
(


	
	
1
2
,
 
"
1
2
"
,
 
"
j
u
i
c
e
_
b
a
r
"
,
 
C
o
l
o
r
(
0
.
5
5
,
 
0
.
7
2
,
 
0
.
5
8
)
,


	
	
[


	
	
	
Z
(
Z
O
N
E
_
C
O
M
M
O
N
,
 
 
 
 
 
 
 
 
 
2
,
 
 
3
,
 
7
8
,
 
3
8
)
,


	
	
	
Z
(
Z
O
N
E
_
J
U
I
C
E
_
B
A
R
,
 
 
 
 
 
2
,
 
 
3
,
 
3
0
,
 
2
0
,
 
{
"
n
a
m
e
"
:
 
"
J
U
I
C
E
 
B
A
R
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
1
.
0
,
 
0
.
7
5
,
 
0
.
3
0
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
H
E
A
L
T
H
_
F
O
O
D
,
 
 
3
4
,
 
 
3
,
 
3
0
,
 
2
0
,
 
{
"
n
a
m
e
"
:
 
"
H
E
A
L
T
H
 
F
O
O
D
S
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
5
5
,
 
0
.
8
2
,
 
0
.
5
8
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
S
M
O
O
T
H
I
E
,
 
 
 
 
 
 
2
,
 
2
5
,
 
3
0
,
 
1
4
,
 
{
"
n
a
m
e
"
:
 
"
S
M
O
O
T
H
I
E
 
S
T
A
T
I
O
N
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
8
0
,
 
0
.
5
5
,
 
0
.
8
0
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
S
A
L
A
D
_
B
A
R
,
 
 
 
 
3
4
,
 
2
5
,
 
3
0
,
 
1
4
,
 
{
"
n
a
m
e
"
:
 
"
S
A
L
A
D
 
B
A
R
"
,
 
"
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
6
0
,
 
0
.
8
5
,
 
0
.
6
0
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
A
D
,
 
 
 
 
 
 
 
 
 
 
 
6
6
,
 
 
4
,
 
 
4
,
 
 
6
,
 
{
"
a
d
_
i
d
"
:
 
"
o
r
g
a
n
i
c
"
,
 
"
a
d
_
t
e
x
t
"
:
 
"
1
0
0
%
 
O
R
G
A
N
I
C
!
"
,
 
"
a
d
_
c
o
l
o
r
"
:
 
C
o
l
o
r
(
0
.
4
0
,
 
0
.
9
0
,
 
0
.
5
0
)
}
)
,


	
	
	
Z
(
Z
O
N
E
_
E
L
E
V
A
T
O
R
,
 
 
 
 
8
0
,
 
 
2
,
 
 
4
,
 
4
0
)
,


	
	
	
Z
(
Z
O
N
E
_
S
T
A
I
R
S
,
 
 
 
 
 
 
8
4
,
 
 
2
,
 
 
6
,
 
4
0
)
,


	
	
]
,


	
	
[
S
Z
(
"
j
u
i
c
e
"
,
 
2
,
 
 
3
,
 
3
0
,
 
2
0
)
,


	
	
 
S
Z
(
"
h
e
a
l
t
h
"
,
 
3
4
,
 
 
3
,
 
3
0
,
 
2
0
)
]
,


	
	
t
r
u
e
,
 
f
a
l
s
e
,
 
t
r
u
e
,
 
t
r
u
e


	
)
)
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

	# ── Floor 12 — Juice Bar & Fresh (Phase J) ─────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		12, "12", "juice_bar", Color(0.55, 0.72, 0.58),
		[
			Z(ZONE_COMMON,         2,  3, 78, 38),
			Z(ZONE_JUICE_BAR,     2,  3, 30, 20, {"name": "JUICE BAR", "color": Color(1.0, 0.75, 0.30)}),
			Z(ZONE_HEALTH_FOOD,  34,  3, 30, 20, {"name": "HEALTH FOODS", "color": Color(0.55, 0.82, 0.58)}),
			Z(ZONE_SMOOTHIE,      2, 25, 30, 14, {"name": "SMOOTHIE STATION", "color": Color(0.80, 0.55, 0.80)}),
			Z(ZONE_SALAD_BAR,    34, 25, 30, 14, {"name": "SALAD BAR", "color": Color(0.60, 0.85, 0.60)}),
			Z(ZONE_AD,           66,  4,  4,  6, {"ad_id": "organic", "ad_text": "100% ORGANIC!", "ad_color": Color(0.40, 0.90, 0.50)}),
			Z(ZONE_ELEVATOR,    80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[SZ("juice", 2,  3, 30, 20),
		 SZ("health", 34,  3, 30, 20)],
		true, false, true, true
	))

	# ── Floor 13 — Kids Kingdom (Phase K) ───────────────────────────────────────
	FLOOR_DEFS.append(FloorDef.new(
		13, "13", "kids_kingdom", Color(0.72, 0.58, 0.80),
	# ?? Floor 14 ??Electronics Megastore (Phase H) ???????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		14, "14", "electronics", Color(0.35, 0.45, 0.65),
		[
			Z(ZONE_COMMON,           2,  3, 78, 38),
			Z(ZONE_PHONE_GADGETS,    2,  3, 30, 18, {"name": "PHONES & GADGETS", "color": Color(0.35, 0.55, 0.80)}),
			Z(ZONE_SMART_HOME,      34,  3, 30, 18, {"name": "SMART HOME", "color": Color(0.40, 0.60, 0.70)}),
			Z(ZONE_ELECTRONICS,      2, 23, 38, 16, {"name": "ELECTRONICS", "color": Color(0.45, 0.50, 0.65)}),
			Z(ZONE_REPAIR_COUNTER,  42, 23, 36, 16, {"name": "REPAIR COUNTER", "color": Color(0.60, 0.45, 0.40)}),
			Z(ZONE_AD,             66,  4,  4,  6, {"ad_id": "tech_sale", "ad_text": "TECH SALE!", "ad_color": Color(0.30, 0.60, 1.0)}),
			Z(ZONE_ELEVATOR,       80,  2,  4, 40),
			Z(ZONE_STAIRS,        84,  2,  6, 40),
		],
		[],
		true, false, true, true
	))
		[
			Z(ZONE_COMMON,          2,  3, 78, 38),
			Z(ZONE_KIDS_PLAY,       2,  3, 32, 22, {"name": "PLAY ZONE", "color": Color(0.80, 0.60, 0.90)}),
			Z(ZONE_KIDS_CLOTHING,  36,  3, 26, 18, {"name": "KIDS WEAR", "color": Color(0.90, 0.72, 0.80)}),
			Z(ZONE_NURSING_ROOM,    2, 27, 18, 12, {"name": "NURSING ROOM", "color": Color(0.95, 0.85, 0.90)}),
			Z(ZONE_FAMILY_WC,      22, 27, 14, 12, {"name": "FAMILY WC", "color": Color(0.60, 0.75, 0.90)}),
			Z(ZONE_KIDS_CLUB,      38, 27, 38, 12, {"name": "KIDS CLUB", "color": Color(0.72, 0.80, 0.60)}),
			Z(ZONE_AD,            64,  4,  4,  6, {"ad_id": "weekend_deal", "ad_text": "FAMILY DAY!", "ad_color": Color(0.95, 0.50, 0.80)}),
			Z(ZONE_ELEVATOR,     80,  2,  4, 40),
			Z(ZONE_STAIRS,      84,  2,  6, 40),
		],
		[SZ("kids_clothing", 36,  3, 26, 18)],
		true, false, true, true
	))


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






