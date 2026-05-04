# floor_config.gd
# ????????????????????????????????????????????????????????????????????????# CENTRAL FLOOR DATA ??all floor layouts, zones, and world geometry.
#
# TO ADD A FLOOR:
#   1. Append a FloorDef to FLOOR_DEFS in this file.
#   2. Zones are rendered in order ??later zones draw on top of earlier.
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
#
# TO USE EXTERNAL JSON LAYOUTS (zero-code floor additions):
#   See floor_layouts/ directory ??each .json file defines one floor.
#   The FloorLayoutLoader class reads them at startup.
# ????????????????????????????????????????????????????????????????????????extends Node2D

# ??? World Geometry ????????????????????????????????????????????????
# All floors share the same tile grid. Change these to support larger floors.
const CELL_SIZE := 16
const WORLD_W  := 96
const WORLD_H  := 52

# Vertical layout reference for Floor G:
#   y=2..15  ??Lobby / entrance corridor
#   y=17..33 ??Food street (stalls + dining)
#   y=35..49 ??Parking lot
#   x=80..83 ??Elevator shaft
#   x=84..89 ??Stairs

# ??? Zone Type Constants ????????????????????????????????????????????
# Add new types here + handle in floor_builder.gd's _build_zone().
const ZONE_WALL          := "wall"
const ZONE_AISLE        := "aisle_floor"
const ZONE_SECTION      := "section"
const ZONE_LOBBY        := "lobby"          # entrance / reception area
const ZONE_FOOD_STALL   := "food_stall"      # vendor stall (needs meta: stall_id)
const ZONE_FOOD_COURT   := "food_court"     # open dining area with tables
const ZONE_PARKING      := "parking"        # vehicle parking zone
const ZONE_WC           := "wc"             # restroom
const ZONE_INFO_DESK    := "info_desk"      # information desk
const ZONE_ELEVATOR     := "elevator_shaft" # elevator column
const ZONE_STAIRS       := "stairs"         # stairwell
const ZONE_COMMON       := "common"         # generic open area
const ZONE_ROOFTOP      := "rooftop"       # outdoor rooftop
const ZONE_ENTRY_GATE   := "entry_gate"     # entrance turnstile/gate
const ZONE_DECOR        := "decor"          # purely decorative zone (no interaction)

# ??? Food Stall Definitions ????????????????????????????????????????
# Each stall has: id, name, cuisine, color scheme, glow color, menu.
class FoodStallDef:
	var id: String
	var name: String
	var cuisine: String
	var color: Color
	var glow_color: Color
	var menu: Array  # [{name, price, desc}, ...]

	static var ALL: Array = []

	static func _static_init() -> void:
		ALL = [
			# ?? Japanese ??
			FoodStallDef.new("jp_ramen", "Ramen House", "Japanese",
				Color(0.92, 0.55, 0.38), Color(1.00, 0.70, 0.50), [
				{"name": "Tonkotsu Ramen",   "price": 8.50, "desc": "Rich pork bone broth, chashu, soft egg."},
				{"name": "Miso Ramen",        "price": 7.80, "desc": "Fermented soybean paste, corn, butter."},
				{"name": "Shoyu Ramen",       "price": 7.50, "desc": "Classic soy sauce broth, nori, bamboo."},
				{"name": "Shio Ramen",        "price": 7.20, "desc": "Clear salt broth, ham, spring onion."},
				{"name": "Extra Chashu",      "price": 2.00, "desc": "Two slices of braised pork belly."},
				{"name": "Ajitsuke Tamago",   "price": 1.50, "desc": "Marinated soft-boiled egg."},
			]),
			FoodStallDef.new("jp_sushi", "Sushi Master", "Japanese",
				Color(0.35, 0.72, 0.80), Color(0.50, 0.90, 1.00), [
				{"name": "Salmon Nigiri (2pc)", "price": 5.00, "desc": "Fresh Atlantic salmon on seasoned rice."},
				{"name": "Tuna Nigiri (2pc)",   "price": 6.00, "desc": "Premium bluefin tuna, wasabi, ginger."},
				{"name": "Dragon Roll",           "price": 9.50, "desc": "Eel, cucumber, avocado, unagi sauce."},
				{"name": "Rainbow Roll",          "price": 10.00, "desc": "Crab, avocado, topped with assorted fish."},
				{"name": "Miso Soup",             "price": 2.00, "desc": "Traditional dashi with tofu and wakame."},
				{"name": "Edamame",               "price": 3.00, "desc": "Steamed soybeans with sea salt."},
			]),
			FoodStallDef.new("jp_takoyaki", "Takoyaki King", "Japanese",
				Color(0.88, 0.72, 0.30), Color(1.00, 0.85, 0.40), [
				{"name": "Classic Takoyaki (6pc)", "price": 5.50, "desc": "Crisp outside, creamy inside, bonito flakes."},
				{"name": "Mayo Takoyaki (6pc)",   "price": 6.00, "desc": "Drizzled with Japanese kewpie mayo."},
				{"name": "Spicy Takoyaki (6pc)",  "price": 6.20, "desc": "With sriracha mayo and chili flakes."},
				{"name": "Okonomiyaki",            "price": 7.00, "desc": "Osaka-style savory pancake, pork, cabbage."},
				{"name": "Yakisoba",               "price": 6.50, "desc": "Stir-fried noodles with vegetables and meat."},
			]),
			FoodStallDef.new("thai", "Thai Street", "Thai",
				Color(0.90, 0.55, 0.35), Color(1.00, 0.70, 0.50), [
				{"name": "Pad Thai",               "price": 7.50, "desc": "Rice noodles, prawns, peanuts, tamarind."},
				{"name": "Green Curry",            "price": 8.00, "desc": "Coconut milk, Thai basil, chicken."},
				{"name": "Tom Yum Soup",           "price": 6.50, "desc": "Spicy shrimp soup with lemongrass."},
				{"name": "Mango Sticky Rice",      "price": 5.00, "desc": "Sweet glutinous rice with ripe mango."},
				{"name": "Spring Rolls (4pc)",     "price": 4.50, "desc": "Crispy vegetable rolls with sweet chili sauce."},
			]),
			FoodStallDef.new("indian", "Curry Palace", "Indian",
				Color(0.95, 0.65, 0.25), Color(1.00, 0.80, 0.40), [
				{"name": "Butter Chicken",         "price": 9.00, "desc": "Creamy tomato curry, tandoori chicken."},
				{"name": "Lamb Rogan Josh",        "price": 10.50, "desc": "Slow-cooked lamb in aromatic spices."},
				{"name": "Paneer Tikka Masala",   "price": 8.00, "desc": "Cottage cheese in rich spiced gravy."},
				{"name": "Garlic Naan",            "price": 2.50, "desc": "Leavened flatbread, garlic butter."},
				{"name": "Samosa (2pc)",           "price": 4.00, "desc": "Crispy pastry, spiced potato and peas."},
				{"name": "Mango Lassi",            "price": 3.50, "desc": "Sweet yogurt drink with Alphonso mango."},
			]),
			FoodStallDef.new("chinese", "Wok Star", "Chinese",
				Color(0.88, 0.28, 0.22), Color(1.00, 0.40, 0.35), [
				{"name": "Kung Pao Chicken",        "price": 8.50, "desc": "Wok-tossed chicken, peanuts, chilies."},
				{"name": "Peking Duck Wrap",         "price": 12.00, "desc": "Crispy duck, pancakes, hoisin, cucumber."},
				{"name": "Dim Sum Basket (4pc)",    "price": 7.00, "desc": "Steamed shrimp dumplings, pork buns."},
				{"name": "Mapo Tofu",               "price": 7.50, "desc": "Silken tofu, fermented bean paste, minced pork."},
				{"name": "Fried Rice",              "price": 6.00, "desc": "Egg, char siu pork, green onion, soy."},
				{"name": "Hot & Sour Soup",         "price": 5.00, "desc": "Traditional Sichuan-style soup."},
			]),
			FoodStallDef.new("korean", "Seoul Kitchen", "Korean",
				Color(0.80, 0.30, 0.30), Color(0.95, 0.45, 0.45), [
				{"name": "Bulgogi BBQ",             "price": 11.00, "desc": "Marinated grilled beef, lettuce wraps."},
				{"name": "Kimchi Stew",             "price": 8.00, "desc": "Fermented cabbage, pork, tofu, gochugaru."},
				{"name": "Bibimbap",                "price": 9.50, "desc": "Rice bowl, vegetables, egg, gochujang."},
				{"name": "Korean Fried Chicken",    "price": 8.50, "desc": "Double-fried, honey glaze, sesame."},
				{"name": "Japchae",                 "price": 8.00, "desc": "Stir-fried glass noodles and vegetables."},
				{"name": "Tteokbokki",              "price": 6.00, "desc": "Spicy rice cakes in gochujang sauce."},
			]),
			FoodStallDef.new("turkish", "Anatolia Grill", "Turkish",
				Color(0.85, 0.45, 0.30), Color(0.98, 0.60, 0.40), [
				{"name": "Doner Kebab Plate",       "price": 9.50, "desc": "Sliced lamb doner, rice, salad, yogurt."},
				{"name": "Adana Kebab",             "price": 10.00, "desc": "Spicy minced lamb on skewer, flatbread."},
				{"name": "Falafel Wrap",             "price": 6.50, "desc": "Crispy chickpea fritters, tahini, pickles."},
				{"name": "Lamb Shawarma Plate",      "price": 10.50, "desc": "Slow-roasted lamb, hummus, pilaf."},
				{"name": "Baklava (2pc)",            "price": 4.00, "desc": "Layered phyllo, pistachios, honey syrup."},
				{"name": "Turkish Tea",               "price": 2.00, "desc": "Strong black tea in traditional tulip glass."},
			]),
			FoodStallDef.new("vietnamese", "Pho & Banh Mi", "Vietnamese",
				Color(0.72, 0.65, 0.30), Color(0.90, 0.85, 0.50), [
				{"name": "Beef Pho",                "price": 7.50, "desc": "Rice noodle soup, star anise beef broth."},
				{"name": "Banh Mi Classic",         "price": 6.50, "desc": "Grilled pork, pate, pickled veg, cilantro."},
				{"name": "Fresh Spring Rolls (2pc)", "price": 5.00, "desc": "Rice paper, shrimp, vermicelli, herbs."},
				{"name": "Bun Cha",                 "price": 8.00, "desc": "Grilled pork patties, noodles, nuoc cham."},
				{"name": "Vietnamese Iced Coffee",   "price": 3.50, "desc": "Strong drip coffee, condensed milk, ice."},
			]),
			FoodStallDef.new("italian", "Trattoria", "Italian",
				Color(0.78, 0.28, 0.22), Color(0.95, 0.40, 0.35), [
				{"name": "Margherita Pizza",         "price": 9.00, "desc": "San Marzano tomatoes, mozzarella, basil."},
				{"name": "Spaghetti Carbonara",     "price": 10.00, "desc": "Guanciale, egg yolk, pecorino, black pepper."},
				{"name": "Risotto ai Funghi",        "price": 11.00, "desc": "Arborio rice, porcini mushrooms, parmesan."},
				{"name": "Tiramisu",                "price": 6.00, "desc": "Espresso-soaked ladyfingers, mascarpone cream."},
				{"name": "Arancini (3pc)",           "price": 5.50, "desc": "Fried mozzarella-stuffed rice balls, marinara."},
				{"name": "Limoncellosoda",           "price": 3.00, "desc": "Sicilian lemon liqueur with sparkling water."},
			]),
			FoodStallDef.new("mexican", "El Taco Loco", "Mexican",
				Color(0.80, 0.50, 0.20), Color(0.95, 0.65, 0.35), [
				{"name": "Carne Asada Tacos (3pc)",  "price": 8.00, "desc": "Grilled steak, onion, cilantro, lime, corn."},
				{"name": "Al Pastor Burrito",         "price": 9.00, "desc": "Marinated pork, rice, beans, cheese, salsa."},
				{"name": "Chicken Quesadilla",         "price": 7.50, "desc": "Grilled chicken, melted cheese, peppers."},
				{"name": "Elote",                      "price": 3.50, "desc": "Mexican street corn, mayo, cheese, chili."},
				{"name": "Churros (3pc)",              "price": 4.50, "desc": "Fried dough sticks, cinnamon sugar, chocolate."},
				{"name": "Horchata",                   "price": 2.50, "desc": "Rice milk drink with cinnamon and vanilla."},
			]),
			FoodStallDef.new("drinks", "Bubble Tea Bar", "Drinks",
				Color(0.55, 0.80, 0.72), Color(0.70, 1.00, 0.90), [
				{"name": "Brown Sugar Milk Tea",  "price": 5.00, "desc": "Caramelized brown sugar, black tea, pearls."},
				{"name": "Taro Milk Tea",         "price": 5.00, "desc": "Creamy taro root, milk tea, ice."},
				{"name": "Matcha Latte",          "price": 5.50, "desc": "Ceremonial-grade matcha, oat milk."},
				{"name": "Passion Fruit Tea",     "price": 4.50, "desc": "Real passion fruit, jasmine green tea."},
				{"name": "Strawberry Smoothie",   "price": 5.50, "desc": "Fresh strawberries, yogurt, honey."},
				{"name": "Thai Iced Tea",         "price": 4.00, "desc": "Strong black tea, condensed milk, ice."},
			]),
		]

	static func get(stall_id: String) -> FoodStallDef:
		for fd in ALL:
			if fd.id == stall_id:
				return fd
		return ALL[0]

	static func get_all() -> Array:
		return ALL

# ??? Section Zone ?????????????????????????????????????????????????
# A retail section zone placed on a floor.
class SectionZone:
	var section_id: String  # matches StoreData section id
	var x: int
	var y: int
	var w: int
	var h: int

	func _init(p_sid: String, p_x: int, p_y: int, p_w: int, p_h: int):
		section_id = p_sid; x = p_x; y = p_y; w = p_w; h = p_h

# ??? Generic Zone ????????????????????????????????????????????????
# A rectangular zone with a type and optional metadata.
class Zone:
	var type: String
	var x: int
	var y: int
	var w: int
	var h: int
	var meta: Dictionary  # type-specific data (e.g. stall_id for food stalls)

	func _init(p_type: String, p_x: int, p_y: int, p_w: int, p_h: int, p_meta: Dictionary = {}):
		type = p_type; x = p_x; y = p_y; w = p_w; h = p_h; meta = p_meta

# ??? Floor Definition ?????????????????????????????????????????????
class FloorDef:
	var index: int
	var label: String       # "G", "1", "2", ...
	var theme: String      # "ground", "jp_food_street", "fresh_market", ...
	var ambient_color: Color
	var zones: Array       # Array[Zone] ??rendered in order
	var section_zones: Array  # Array[SectionZone] ??retail sections on this floor
	var has_checkout: bool
	var has_elevator: bool
	var has_stairs: bool
	var is_staff_only: bool
	var is_rooftop: bool

	func _init(
		p_idx: int,
		p_label: String,
		p_theme: String,
		p_ambient: Color,
		p_zones: Array,
		p_sections: Array,
		p_checkout: bool,
		p_elevator: bool,
		p_stairs: bool,
		p_staff: bool = false,
		p_rooftop: bool = false
	):
		index = p_idx; label = p_label; theme = p_theme; ambient_color = p_ambient
		zones = p_zones; section_zones = p_sections
		has_checkout = p_checkout; has_elevator = p_elevator; has_stairs = p_stairs
		is_staff_only = p_staff; is_rooftop = p_rooftop

# ????????????????????????????????????????????????????????????????????????# FACTORY HELPERS
# ????????????????????????????????????????????????????????????????????????
static func Z(typ: String, px: int, py: int, pw: int, ph: int, p_meta: Dictionary = {}) -> Zone:
	return Zone.new(typ, px, py, pw, ph, p_meta)

static func SZ(sid: String, px: int, py: int, pw: int, ph: int) -> SectionZone:
	return SectionZone.new(sid, px, py, pw, ph)

# ????????????????????????????????????????????????????????????????????????# FLOOR DEFINITIONS
# Edit zones here to change floor layouts. Zones are rendered in order.
# ????????????????????????????????????????????????????????????????????????
static var FLOOR_DEFS: Array = []

static func _static_init() -> void:

	# ??????????????????????????????????????????????????????????????????
	# FLOOR G ??Ground Level
	# Vertical layout (top ??bottom):
	#   y=2..15   ??Lobby / entrance corridor
	#   y=17..33  ??Food street (9 stalls + dining aisles)
	#   y=35..49  ??Parking lot
	#   x=80..83  ??Elevator shaft
	#   x=84..89  ??Stairs
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		0, "G", "ground", Color(0.42, 0.44, 0.40),
		[
			# ?? Lobby (y=2 to y=15) ??
			Z(ZONE_LOBBY,        0,  2, 80, 13),       # main lobby floor
			Z(ZONE_INFO_DESK,   40,  3, 16,  7),       # center info desk
			Z(ZONE_WC,          68,  3, 12,  7),       # WC on right side
			# ?? Food Street (y=17 to y=33) ??
			# Row 1 ??y=3..11 (8-tile stall + counter at bottom)
			Z(ZONE_FOOD_STALL,   2,  3, 14,  8, {"stall_id": "jp_ramen"}),
			Z(ZONE_FOOD_STALL,  18,  3, 14,  8, {"stall_id": "jp_sushi"}),
			Z(ZONE_FOOD_STALL,  34,  3, 14,  8, {"stall_id": "jp_takoyaki"}),
			Z(ZONE_FOOD_STALL,  50,  3, 14,  8, {"stall_id": "thai"}),
			Z(ZONE_FOOD_STALL,  66,  3, 14,  8, {"stall_id": "indian"}),
			# Row 2 ??y=15..23
			Z(ZONE_FOOD_STALL,   2, 15, 14,  8, {"stall_id": "chinese"}),
			Z(ZONE_FOOD_STALL,  18, 15, 14,  8, {"stall_id": "korean"}),
			Z(ZONE_FOOD_STALL,  34, 15, 14,  8, {"stall_id": "turkish"}),
			Z(ZONE_FOOD_STALL,  50, 15, 14,  8, {"stall_id": "vietnamese"}),
			Z(ZONE_FOOD_STALL,  66, 15, 14,  8, {"stall_id": "italian"}),
			# Row 3 ??y=25..33
			Z(ZONE_FOOD_STALL,   2, 25, 14,  8, {"stall_id": "mexican"}),
			Z(ZONE_FOOD_STALL,  18, 25, 14,  8, {"stall_id": "drinks"}),
			# ?? Parking (y=35 to y=49) ??
			Z(ZONE_PARKING,      2, 35, 78, 14),       # parking lot base
			# ?? Vertical shafts (right edge, all heights) ??
			Z(ZONE_ELEVATOR,    80,  2,  4, 47),       # elevator shaft
			Z(ZONE_STAIRS,      84,  2,  6, 47),       # stairs
			# Dining tables in aisle gap between row 1 & 2 stalls (y=11..15)
			Z(ZONE_DECOR,      16, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      34, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      52, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      70, 11,  4,  4, {"decor_type": "dining_table"}),
		],
		[],  # no retail sections on ground floor
		false,  # no checkout
		true,   # has_elevator
		true    # has_stairs
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 1 ??Fresh Market
	# Traditional grocery layout: Dairy / Produce / Bakery / Meat+Deli
	# Left side: dairy + produce. Right side: bakery + deli. Center: main aisle.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		1, "1", "fresh_market", Color(0.48, 0.54, 0.42),
		[
			# Main aisle corridor
			Z(ZONE_AISLE,       0,  2, 80,  1),   # top border wall gap
			Z(ZONE_AISLE,      18,  2,  2, 38),   # vertical main aisle
			Z(ZONE_AISLE,       0, 17, 80,  2),   # horizontal cross-aisle
			# Elevator / stairs
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("dairy",     2,  3, 16, 14),   # left-front: dairy fridge
			SZ("produce",  20,  3, 20, 14),   # left-back: produce
			SZ("bakery",   42,  3, 16, 14),   # right-front: bakery
			SZ("meat",     42, 19, 20, 14),   # right-back: meat + deli
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 2 ??Pantry & Dry Goods
	# Wide shelving aisles with pantry staples and spices.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		2, "2", "pantry", Color(0.46, 0.44, 0.38),
		[
			Z(ZONE_AISLE,      18,  2,  2, 38),
			Z(ZONE_AISLE,      48,  2,  2, 38),
			Z(ZONE_AISLE,       0, 17, 80,  2),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("pantry",    2,  3, 16, 14),   # pantry staples
			SZ("spices",    2, 19, 16, 14),   # spices + seasonings
			SZ("pantry",   20,  3, 28, 14),   # bulk dry goods
			SZ("snacks",   50,  3, 28, 14),   # chips + biscuits
			SZ("candy",    20, 19, 28, 14),   # candy + chocolate
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 3 ??Beverages
	# Cold drinks along the left, hot beverages on the right.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		3, "3", "beverages", Color(0.40, 0.50, 0.60),
		[
			Z(ZONE_AISLE,      18,  2,  2, 38),
			Z(ZONE_AISLE,       0, 17, 80,  2),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("drinks",    2,  3, 16, 14),   # cold drinks
			SZ("coffee",   20,  3, 16, 14),   # coffee bar
			SZ("drinks",   20, 19, 16, 14),   # cold drinks lower
			SZ("drinks",   38,  3, 16, 14),   # drinks
			SZ("drinks",   56,  3, 22, 14),   # water + juice
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 4 ??Snacks & Confectionery
	# Colourful impulse-buy layout with central display tables.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		4, "4", "snacks", Color(0.54, 0.48, 0.38),
		[
			Z(ZONE_AISLE,      18,  2,  2, 38),
			Z(ZONE_AISLE,      50,  2,  2, 38),
			Z(ZONE_AISLE,       0, 17, 80,  2),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("snacks",    2,  3, 16, 14),   # chips
			SZ("candy",    20,  3, 30, 14),   # sweets
			SZ("snacks",   52,  3, 26, 14),   # biscuits + cookies
			SZ("candy",    20, 19, 28, 14),   # chocolate
			SZ("snacks",    2, 19, 16, 14),   # nuts + dried fruit
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 5 ??Frozen Foods
	# Chest freezers on left, upright freezers on right.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		5, "5", "frozen", Color(0.36, 0.48, 0.65),
		[
			Z(ZONE_AISLE,      18,  2,  2, 38),
			Z(ZONE_AISLE,       0, 17, 80,  2),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("frozen",    2,  3, 16, 14),   # ice cream + desserts
			SZ("frozen",    2, 19, 16, 14),   # frozen meals
			SZ("frozen",   20,  3, 20, 14),   # frozen vegetables
			SZ("frozen",   42,  3, 20, 14),   # frozen fish + meat
			SZ("frozen",   64,  3, 14, 14),   # frozen pizza + bakery
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 6 ??Household & Home Care
	# Cleaning products, paper goods, storage.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		6, "6", "household", Color(0.44, 0.42, 0.40),
		[
			Z(ZONE_AISLE,      18,  2,  2, 38),
			Z(ZONE_AISLE,      50,  2,  2, 38),
			Z(ZONE_AISLE,       0, 17, 80,  2),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("clean",     2,  3, 16, 14),   # cleaning supplies
			SZ("paper",    20,  3, 28, 14),   # paper goods
			SZ("clean",    20, 19, 28, 14),   # detergents
			SZ("paper",    50,  3, 28, 14),   # paper goods
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 7 ??Health, Beauty & Pharmacy
	# Pharmacy counter at entrance, beauty products along walls.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		7, "7", "health_beauty", Color(0.50, 0.46, 0.50),
		[
			Z(ZONE_AISLE,      18,  2,  2, 38),
			Z(ZONE_AISLE,      50,  2,  2, 38),
			Z(ZONE_AISLE,       0, 17, 80,  2),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("pharm",     2,  3, 16, 14),   # pharmacy / medicines
			SZ("beauty",   20,  3, 28, 14),   # cosmetics
			SZ("beauty",   20, 19, 28, 14),   # skincare
			SZ("pharm",    50,  3, 28, 14),   # supplements + wellness
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 8 ??Toys & Sports
	# Large open floor with product display islands.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		8, "8", "toys_sports", Color(0.48, 0.52, 0.48),
		[
			Z(ZONE_AISLE,      18,  2,  2, 38),
			Z(ZONE_AISLE,       0, 17, 80,  2),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[
			SZ("toys",      2,  3, 16, 14),   # toys
			SZ("toys",     20,  3, 16, 14),   # toys
			SZ("toys",     38,  3, 40, 14),   # toys (large display)
			SZ("toys",      2, 19, 36, 14),   # toys overflow
		],
		true, true, true
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 9 ??Staff Room (restricted)
	# Simple open plan with lockers, break area.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		9, "9", "staff_room", Color(0.36, 0.36, 0.33),
		[
			Z(ZONE_COMMON,      2,  3, 76, 36),   # open staff area
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
			Z(ZONE_STAIRS,     84,  2,  6, 40),
		],
		[],
		false, true, true,
		true   # staff_only
	))

	# ??????????????????????????????????????????????????????????????????
	# FLOOR 10 ??Rooftop Caf矇
	# Open-air caf矇 with Italian, Mexican, and drinks stalls.
	# ??????????????????????????????????????????????????????????????????
	FLOOR_DEFS.append(FloorDef.new(
		10, "10", "rooftop_cafe", Color(0.62, 0.60, 0.50),
		[
			Z(ZONE_ROOFTOP,     2,  3, 78, 38),   # open rooftop floor
			Z(ZONE_FOOD_STALL,  2,  3, 14,  8, {"stall_id": "italian"}),
			Z(ZONE_FOOD_STALL, 18,  3, 14,  8, {"stall_id": "mexican"}),
			Z(ZONE_FOOD_STALL, 34,  3, 14,  8, {"stall_id": "drinks"}),
			Z(ZONE_ELEVATOR,   80,  2,  4, 40),
		],
		[],
		false, true, false,   # no checkout, has elevator, no stairs (elevator only)
		false, true           # not staff_only, is_rooftop
	))

# ??? Accessors ???????????????????????????????????????????????????

static func get_floor(idx: int) -> FloorDef:
	if idx < 0 or idx >= FLOOR_DEFS.size():
		return FLOOR_DEFS[0]
	return FLOOR_DEFS[idx]

static func floor_count() -> int:
	return FLOOR_DEFS.size()

static func get_stall_def(stall_id: String) -> FoodStallDef:
	return FoodStallDef.get(stall_id)

static func get_all_stalls() -> Array:
	return FoodStallDef.get_all()
