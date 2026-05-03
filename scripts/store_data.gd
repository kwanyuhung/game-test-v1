# store_data.gd
# Product catalog and section layout data.
# Accessed via: const StoreData = preload("res://scripts/store_data.gd")

enum SectionStyle { FRIDGE, PRODUCE, BAKERY, SHELF, DELI, FREEZER }

class SectionDef:
	var id: String
	var name: String
	var wx: int
	var wy: int
	var ww: int
	var wh: int
	var style: int
	var light_color: Color
	var label: String

	func _init(p_id: String, p_name: String, p_wx: int, p_wy: int, p_ww: int, p_wh: int, p_style: int, p_light: Color, p_label: String):
		id=p_id; name=p_name; wx=p_wx; wy=p_wy; ww=p_ww; wh=p_wh; style=p_style; light_color=p_light; label=p_label

class MarketProduct:
	var id: String
	var name: String
	var price: float
	var color: Color
	var shape: int
	var section: String
	var sub: String

	func _init(i: String, n: String, p: float, c: Color, s: int, sec: String, sub_cat: String):
		id=i; name=n; price=p; color=c; shape=s; section=sec; sub=sub_cat

static var SECTIONS: Array = []
static var CATALOG: Array = []
static var CHECKOUT_Y: int = 37
static var CHECKOUT_LANES: Array = []

static func _static_init() -> void:
	SECTIONS = [
		SectionDef.new("dairy",   "DAIRY",      2,  3, 18, 14, SectionStyle.FRIDGE,   Color(0.70, 0.88, 1.00),  "D"),
		SectionDef.new("produce", "PRODUCE",   22,  3, 18, 14, SectionStyle.PRODUCE,  Color(0.72, 0.92, 0.56),  "P"),
		SectionDef.new("bakery",  "BAKERY",    42,  3, 18, 14, SectionStyle.BAKERY,   Color(0.98, 0.82, 0.52),  "B"),
		SectionDef.new("drinks",  "DRINKS",    62,  3, 16, 14, SectionStyle.FRIDGE,   Color(0.60, 0.82, 1.00),  "R"),
		SectionDef.new("snacks",  "SNACKS",     2, 19, 18, 14, SectionStyle.SHELF,    Color(0.95, 0.90, 0.80),  "S"),
		SectionDef.new("meat",    "MEAT/DELI", 22, 19, 18, 14, SectionStyle.DELI,     Color(0.95, 0.72, 0.68),  "M"),
		SectionDef.new("pantry",  "PANTRY",    42, 19, 18, 14, SectionStyle.SHELF,    Color(0.90, 0.85, 0.75),  "T"),
		SectionDef.new("frozen",  "FROZEN",    62, 19, 16, 14, SectionStyle.FREEZER,  Color(0.78, 0.92, 1.00),  "F"),
	]
	CHECKOUT_LANES = [
		{"x": 20, "name": "LANE 1"},
		{"x": 38, "name": "LANE 2"},
		{"x": 56, "name": "LANE 3"},
	]
	CATALOG = [
		MarketProduct.new("apple_fuji",    "Fuji Apple",        1.20, Color(0.90, 0.30, 0.20), 0, "produce", "Fruits"),
		MarketProduct.new("apple_gala",    "Gala Apple",        1.10, Color(0.95, 0.40, 0.25), 0, "produce", "Fruits"),
		MarketProduct.new("banana",        "Banana",            0.60, Color(0.98, 0.90, 0.30), 5, "produce", "Fruits"),
		MarketProduct.new("orange",        "Orange",            0.80, Color(0.95, 0.55, 0.10), 0, "produce", "Fruits"),
		MarketProduct.new("lemon",         "Lemon",             0.70, Color(0.98, 0.95, 0.30), 0, "produce", "Fruits"),
		MarketProduct.new("lime",          "Lime",              0.65, Color(0.50, 0.88, 0.40), 0, "produce", "Fruits"),
		MarketProduct.new("grapes_red",    "Red Grapes",        2.50, Color(0.72, 0.20, 0.60), 0, "produce", "Fruits"),
		MarketProduct.new("grapes_green",  "Green Grapes",      2.80, Color(0.65, 0.85, 0.45), 0, "produce", "Fruits"),
		MarketProduct.new("strawberry",    "Strawberry Pack",   3.20, Color(0.92, 0.22, 0.30), 0, "produce", "Fruits"),
		MarketProduct.new("blueberry",     "Blueberry Pack",    4.50, Color(0.30, 0.30, 0.90), 0, "produce", "Fruits"),
		MarketProduct.new("watermelon",    "Watermelon",         5.00, Color(0.38, 0.78, 0.35), 0, "produce", "Fruits"),
		MarketProduct.new("mango",         "Mango",             1.50, Color(0.95, 0.78, 0.20), 0, "produce", "Fruits"),
		MarketProduct.new("papaya",        "Papaya",            2.20, Color(0.98, 0.70, 0.30), 0, "produce", "Fruits"),
		MarketProduct.new("kiwi",          "Kiwi",              0.90, Color(0.42, 0.72, 0.30), 0, "produce", "Fruits"),
		MarketProduct.new("peach",         "Peach",             1.30, Color(0.98, 0.72, 0.50), 0, "produce", "Fruits"),
		MarketProduct.new("pear",          "Pear",              1.00, Color(0.82, 0.90, 0.45), 0, "produce", "Fruits"),
		MarketProduct.new("carrot",        "Carrot",            0.90, Color(0.98, 0.55, 0.15), 1, "produce", "Vegetables"),
		MarketProduct.new("broccoli",      "Broccoli",          1.80, Color(0.25, 0.62, 0.28), 0, "produce", "Vegetables"),
		MarketProduct.new("tomato",        "Tomato",            1.20, Color(0.92, 0.22, 0.22), 0, "produce", "Vegetables"),
		MarketProduct.new("cucumber",      "Cucumber",         0.80, Color(0.38, 0.72, 0.38), 1, "produce", "Vegetables"),
		MarketProduct.new("lettuce",       "Lettuce",           1.50, Color(0.60, 0.88, 0.45), 0, "produce", "Vegetables"),
		MarketProduct.new("spinach",       "Baby Spinach",      2.20, Color(0.28, 0.62, 0.28), 0, "produce", "Vegetables"),
		MarketProduct.new("cabbage",       "Cabbage",           1.10, Color(0.65, 0.82, 0.55), 0, "produce", "Vegetables"),
		MarketProduct.new("onion",         "Onion",             0.70, Color(0.85, 0.72, 0.60), 0, "produce", "Vegetables"),
		MarketProduct.new("potato",        "Potato",            0.80, Color(0.82, 0.65, 0.45), 0, "produce", "Vegetables"),
		MarketProduct.new("sweet_potato",  "Sweet Potato",      1.20, Color(0.85, 0.48, 0.30), 1, "produce", "Vegetables"),
		MarketProduct.new("garlic",        "Garlic",            0.50, Color(0.90, 0.85, 0.72), 0, "produce", "Vegetables"),
		MarketProduct.new("bell_pepper",   "Bell Pepper",       1.60, Color(0.92, 0.28, 0.22), 0, "produce", "Vegetables"),
		MarketProduct.new("corn",          "Corn",              0.90, Color(0.98, 0.92, 0.40), 0, "produce", "Vegetables"),
		MarketProduct.new("mushroom",      "Mushroom Pack",     2.50, Color(0.82, 0.72, 0.60), 0, "produce", "Vegetables"),
		MarketProduct.new("celery",        "Celery",            1.30, Color(0.80, 0.95, 0.72), 1, "produce", "Vegetables"),
		MarketProduct.new("basil",         "Fresh Basil",       1.80, Color(0.28, 0.68, 0.28), 0, "produce", "Herbs"),
		MarketProduct.new("cilantro",       "Cilantro Bunch",   0.90, Color(0.38, 0.72, 0.30), 0, "produce", "Herbs"),
		MarketProduct.new("parsley",       "Parsley",           0.80, Color(0.28, 0.65, 0.28), 0, "produce", "Herbs"),
		MarketProduct.new("milk_whole",    "Whole Milk 1L",    2.80, Color(0.95, 0.95, 0.88), 5, "dairy", "Milk"),
		MarketProduct.new("milk_skim",     "Skim Milk 1L",      2.80, Color(0.92, 0.95, 1.00), 5, "dairy", "Milk"),
		MarketProduct.new("milk_oat",      "Oat Milk 1L",       3.50, Color(0.90, 0.82, 0.60), 5, "dairy", "Milk"),
		MarketProduct.new("milk_almond",   "Almond Milk 1L",    3.20, Color(0.85, 0.78, 0.60), 5, "dairy", "Milk"),
		MarketProduct.new("cheese_cheddar","Cheddar Block",    4.50, Color(0.95, 0.72, 0.20), 3, "dairy", "Cheese"),
		MarketProduct.new("cheese_mozz",   "Mozzarella",        3.80, Color(0.95, 0.95, 0.82), 3, "dairy", "Cheese"),
		MarketProduct.new("cheese_brie",   "Brie",              5.50, Color(0.92, 0.88, 0.70), 3, "dairy", "Cheese"),
		MarketProduct.new("cheese_parm",   "Parmesan",          6.20, Color(0.88, 0.82, 0.60), 3, "dairy", "Cheese"),
		MarketProduct.new("yogurt_plain",  "Plain Yogurt 500g", 3.20, Color(0.95, 0.92, 0.85), 4, "dairy", "Yogurt"),
		MarketProduct.new("yogurt_straw",  "Strawberry Yogurt", 3.50, Color(0.95, 0.60, 0.72), 4, "dairy", "Yogurt"),
		MarketProduct.new("yogurt_blue",   "Blueberry Yogurt",   3.50, Color(0.55, 0.55, 0.90), 4, "dairy", "Yogurt"),
		MarketProduct.new("yogurt_greek",  "Greek Yogurt",       4.00, Color(0.95, 0.92, 0.88), 4, "dairy", "Yogurt"),
		MarketProduct.new("butter",        "Butter 250g",       3.20, Color(0.95, 0.88, 0.55), 3, "dairy", "Butter"),
		MarketProduct.new("cream",         "Heavy Cream 500ml", 3.80, Color(0.98, 0.95, 0.88), 5, "dairy", "Butter"),
		MarketProduct.new("cottage",       "Cottage Cheese",    3.50, Color(0.95, 0.95, 0.88), 4, "dairy", "Cheese"),
		MarketProduct.new("cream_cheese",  "Cream Cheese",      3.80, Color(0.95, 0.92, 0.90), 3, "dairy", "Cheese"),
		MarketProduct.new("egg_dozen",     "Eggs 12pk",         4.20, Color(0.95, 0.88, 0.72), 0, "dairy", "Eggs"),
		MarketProduct.new("egg_half",      "Eggs 6pk",          2.20, Color(0.92, 0.85, 0.72), 0, "dairy", "Eggs"),
		MarketProduct.new("bread_white",   "White Sliced",      2.50, Color(0.92, 0.80, 0.58), 3, "bakery", "Bread"),
		MarketProduct.new("bread_wheat",   "Whole Wheat",       3.20, Color(0.72, 0.52, 0.28), 3, "bakery", "Bread"),
		MarketProduct.new("bread_sourdough","Sourdough Loaf",  4.50, Color(0.88, 0.72, 0.45), 3, "bakery", "Bread"),
		MarketProduct.new("bread_baguette","Baguette",          2.20, Color(0.90, 0.78, 0.55), 1, "bakery", "Bread"),
		MarketProduct.new("bread_rye",     "Rye Bread",         3.80, Color(0.65, 0.42, 0.25), 3, "bakery", "Bread"),
		MarketProduct.new("croissant",     "Croissant",          2.80, Color(0.92, 0.72, 0.35), 0, "bakery", "Pastries"),
		MarketProduct.new("pain_choco",    "Pain au Chocolat",   3.20, Color(0.58, 0.38, 0.22), 1, "bakery", "Pastries"),
		MarketProduct.new("donut_choco",   "Chocolate Donut",    1.80, Color(0.62, 0.38, 0.22), 0, "bakery", "Pastries"),
		MarketProduct.new("donut_glaze",   "Glazed Donut",      1.60, Color(0.92, 0.80, 0.65), 0, "bakery", "Pastries"),
		MarketProduct.new("muffin_blue",   "Blueberry Muffin",   2.50, Color(0.55, 0.48, 0.82), 0, "bakery", "Pastries"),
		MarketProduct.new("muffin_choco",   "Chocolate Muffin",   2.50, Color(0.62, 0.38, 0.22), 0, "bakery", "Pastries"),
		MarketProduct.new("cake_choco",    "Chocolate Cake",    12.00, Color(0.52, 0.32, 0.18), 3, "bakery", "Cakes"),
		MarketProduct.new("cake_cheese",   "Cheesecake Slice",   5.50, Color(0.95, 0.90, 0.75), 3, "bakery", "Cakes"),
		MarketProduct.new("tart_apple",    "Apple Tart",         6.00, Color(0.88, 0.68, 0.45), 3, "bakery", "Pastries"),
		MarketProduct.new("bun_kaiser",    "Kaiser Roll",       1.20, Color(0.88, 0.70, 0.48), 0, "bakery", "Bread"),
		MarketProduct.new("bun_hamburger", "Hamburger Buns 4pk",2.20, Color(0.90, 0.75, 0.52), 3, "bakery", "Bread"),
		MarketProduct.new("bun_hotdog",    "Hot Dog Buns 6pk",  2.00, Color(0.88, 0.78, 0.58), 1, "bakery", "Bread"),
		MarketProduct.new("pita_white",    "Pita Bread",        2.20, Color(0.90, 0.82, 0.62), 3, "bakery", "Bread"),
		MarketProduct.new("naan",          "Naan Bread",        2.80, Color(0.88, 0.72, 0.50), 1, "bakery", "Bread"),
		MarketProduct.new("tortilla",      "Flour Tortilla 10pk",2.50,Color(0.92, 0.85, 0.68), 3, "bakery", "Bread"),
		MarketProduct.new("focaccia",      "Focaccia",           4.00, Color(0.88, 0.75, 0.50), 3, "bakery", "Bread"),
		MarketProduct.new("cinnamon_roll", "Cinnamon Roll",     3.50, Color(0.82, 0.62, 0.38), 0, "bakery", "Pastries"),
		MarketProduct.new("water_sparkling","Sparkling Water 1L",1.20,Color(0.72, 0.92, 1.00), 5, "drinks", "Water"),
		MarketProduct.new("water_still",   "Still Water 1L",    0.80, Color(0.82, 0.95, 1.00), 5, "drinks", "Water"),
		MarketProduct.new("water_vitamin",  "Vitamin Water",      2.20, Color(0.98, 0.82, 0.38), 5, "drinks", "Water"),
		MarketProduct.new("juice_orange",  "Orange Juice 1L",   3.20, Color(0.98, 0.62, 0.15), 5, "drinks", "Juice"),
		MarketProduct.new("juice_apple",   "Apple Juice 1L",    2.80, Color(0.78, 0.90, 0.48), 5, "drinks", "Juice"),
		MarketProduct.new("juice_grape",   "Grape Juice 1L",    3.00, Color(0.52, 0.18, 0.58), 5, "drinks", "Juice"),
		MarketProduct.new("juice_tomato",  "Tomato Juice 1L",   2.50, Color(0.90, 0.28, 0.22), 5, "drinks", "Juice"),
		MarketProduct.new("soda_cola",     "Cola 330ml",        2.20, Color(0.52, 0.28, 0.18), 2, "drinks", "Soda"),
		MarketProduct.new("soda_sprite",   "Lemon-Lime Soda",   2.20, Color(0.88, 0.95, 0.52), 2, "drinks", "Soda"),
		MarketProduct.new("soda_pepsi",    "Pepsi 330ml",       2.20, Color(0.22, 0.22, 0.68), 2, "drinks", "Soda"),
		MarketProduct.new("soda_orange",   "Orange Soda",       2.20, Color(0.98, 0.55, 0.10), 2, "drinks", "Soda"),
		MarketProduct.new("energy_redbull","Red Bull 250ml",    3.50, Color(0.88, 0.72, 0.28), 2, "drinks", "Energy"),
		MarketProduct.new("energy_monster","Monster 500ml",     3.80, Color(0.32, 0.62, 0.28), 5, "drinks", "Energy"),
		MarketProduct.new("energy_pocari", "Pocari Sweat",     3.20, Color(0.72, 0.88, 0.98), 5, "drinks", "Energy"),
		MarketProduct.new("tea_green",     "Green Tea Bottle",   2.50, Color(0.52, 0.82, 0.52), 5, "drinks", "Tea"),
		MarketProduct.new("tea_black",     "Black Tea Bottle",  2.20, Color(0.68, 0.48, 0.28), 5, "drinks", "Tea"),
		MarketProduct.new("tea_peach",     "Peach Tea",         2.80, Color(0.98, 0.68, 0.58), 5, "drinks", "Tea"),
		MarketProduct.new("coffee_latte",  "Canned Latte",      3.20, Color(0.82, 0.72, 0.60), 5, "drinks", "Coffee"),
		MarketProduct.new("coffee_espresso","Canned Espresso",   3.00, Color(0.45, 0.32, 0.22), 5, "drinks", "Coffee"),
		MarketProduct.new("coconut_water", "Coconut Water",     3.50, Color(0.92, 0.90, 0.82), 5, "drinks", "Water"),
		MarketProduct.new("kombucha",      "Kombucha 330ml",    4.50, Color(0.52, 0.78, 0.45), 2, "drinks", "Health"),
		MarketProduct.new("chips_classic", "Classic Chips 150g", 3.80, Color(0.98, 0.82, 0.28), 3, "snacks", "Chips"),
		MarketProduct.new("chips_bbq",     "BBQ Chips 150g",    3.80, Color(0.72, 0.38, 0.18), 3, "snacks", "Chips"),
		MarketProduct.new("chips_sour",    "Sour Cream Chips",  3.80, Color(0.88, 0.82, 0.45), 3, "snacks", "Chips"),
		MarketProduct.new("chips_lays",    "Lays Original",     3.50, Color(0.95, 0.75, 0.28), 3, "snacks", "Chips"),
		MarketProduct.new("popcorn",       "Microwave Popcorn",   2.80, Color(0.90, 0.82, 0.60), 3, "snacks", "Chips"),
		MarketProduct.new("cookie_choco",  "Chocolate Cookies",  3.20, Color(0.62, 0.42, 0.22), 3, "snacks", "Cookies"),
		MarketProduct.new("cookie_oreo",   "Oreo Cookies",      3.80, Color(0.18, 0.18, 0.18), 3, "snacks", "Cookies"),
		MarketProduct.new("cookie_oat",    "Oatmeal Cookies",   3.20, Color(0.78, 0.65, 0.42), 3, "snacks", "Cookies"),
		MarketProduct.new("cracker_salt",  "Saltine Crackers",   2.50, Color(0.90, 0.85, 0.72), 3, "snacks", "Crackers"),
		MarketProduct.new("cracker_cheese","Cheese Crackers",   2.80, Color(0.95, 0.78, 0.22), 3, "snacks", "Crackers"),
		MarketProduct.new("candy_gummy",   "Gummy Bears 100g",  2.80, Color(0.92, 0.28, 0.38), 0, "snacks", "Candy"),
		MarketProduct.new("candy_sour",    "Sour Straps",       2.50, Color(0.72, 0.92, 0.28), 7, "snacks", "Candy"),
		MarketProduct.new("candy_lifesavers","Life Savers",      2.20, Color(0.18, 0.68, 0.88), 0, "snacks", "Candy"),
		MarketProduct.new("choco_dark",    "Dark Chocolate 100g",4.50, Color(0.38, 0.22, 0.12), 6, "snacks", "Chocolate"),
		MarketProduct.new("choco_milk",    "Milk Chocolate 100g",3.20,Color(0.72, 0.52, 0.28), 6, "snacks", "Chocolate"),
		MarketProduct.new("choco_white",   "White Chocolate",    3.50, Color(0.95, 0.90, 0.80), 6, "snacks", "Chocolate"),
		MarketProduct.new("nuts_mixed",    "Mixed Nuts 200g",    5.50, Color(0.72, 0.58, 0.38), 0, "snacks", "Nuts"),
		MarketProduct.new("nuts_peanut",   "Roasted Peanuts",    3.20, Color(0.82, 0.62, 0.38), 0, "snacks", "Nuts"),
		MarketProduct.new("nuts_almond",   "Roasted Almonds",    5.00, Color(0.78, 0.65, 0.48), 0, "snacks", "Nuts"),
		MarketProduct.new("pretzel",       "Pretzel Twists",     2.80, Color(0.88, 0.72, 0.48), 0, "snacks", "Crackers"),
		MarketProduct.new("granola_bar",   "Granola Bar 6pk",   4.20, Color(0.82, 0.62, 0.32), 6, "snacks", "Bars"),
		MarketProduct.new("fruit_bar",     "Fruit & Grain Bar",  3.80, Color(0.95, 0.55, 0.28), 6, "snacks", "Bars"),
		MarketProduct.new("pudding",       "Chocolate Pudding",  1.50, Color(0.58, 0.38, 0.22), 4, "snacks", "Dessert"),
		MarketProduct.new("jelly",         "Grape Jelly 500g",   3.20, Color(0.52, 0.18, 0.58), 3, "snacks", "Pantry"),
		MarketProduct.new("honey",         "Honey Bear 340g",    5.50, Color(0.92, 0.72, 0.28), 5, "snacks", "Pantry"),
		MarketProduct.new("marshmallow",   "Marshmallows 90g",   2.50, Color(0.95, 0.92, 0.92), 0, "snacks", "Dessert"),
		MarketProduct.new("chicken_breast","Chicken Breast 500g", 8.50, Color(0.92, 0.80, 0.68), 1, "meat", "Chicken"),
		MarketProduct.new("chicken_thigh","Chicken Thighs 500g",  7.20, Color(0.88, 0.68, 0.52), 1, "meat", "Chicken"),
		MarketProduct.new("chicken_wing", "Chicken Wings 600g",  7.80, Color(0.90, 0.75, 0.58), 1, "meat", "Chicken"),
		MarketProduct.new("beef_steak",   "Beef Steak 300g",    12.50, Color(0.72, 0.28, 0.22), 1, "meat", "Beef"),
		MarketProduct.new("beef_ground",  "Ground Beef 500g",    9.20, Color(0.68, 0.25, 0.20), 1, "meat", "Beef"),
		MarketProduct.new("beef_roast",    "Beef Roast 800g",   15.00, Color(0.62, 0.30, 0.22), 1, "meat", "Beef"),
		MarketProduct.new("pork_chop",    "Pork Chops 500g",    8.80, Color(0.88, 0.68, 0.62), 1, "meat", "Pork"),
		MarketProduct.new("pork_belly",   "Pork Belly 600g",   10.50, Color(0.90, 0.72, 0.65), 1, "meat", "Pork"),
		MarketProduct.new("bacon",         "Bacon 300g",         9.50, Color(0.82, 0.38, 0.28), 1, "meat", "Pork"),
		MarketProduct.new("ham_sliced",    "Sliced Ham 200g",    6.20, Color(0.95, 0.72, 0.62), 7, "meat", "Deli"),
		MarketProduct.new("turkey_sliced", "Sliced Turkey 200g",  6.80, Color(0.88, 0.72, 0.60), 7, "meat", "Deli"),
		MarketProduct.new("salami",        "Salami Sliced 150g", 5.50, Color(0.88, 0.38, 0.28), 7, "meat", "Deli"),
		MarketProduct.new("sausage_pork",  "Pork Sausages 400g",  6.50, Color(0.82, 0.45, 0.32), 0, "meat", "Sausage"),
		MarketProduct.new("sausage_chicken","Chicken Sausages",   6.80, Color(0.90, 0.68, 0.52), 0, "meat", "Sausage"),
		MarketProduct.new("hotdog",        "Hot Dogs 8pk",        4.50, Color(0.90, 0.60, 0.42), 0, "meat", "Sausage"),
		MarketProduct.new("fish_salmon",   "Salmon Fillet 300g", 14.00, Color(0.88, 0.55, 0.45), 1, "meat", "Fish"),
		MarketProduct.new("fish_white",    "White Fish Fillet",  10.00, Color(0.88, 0.88, 0.82), 1, "meat", "Fish"),
		MarketProduct.new("shrimp",        "Shrimp 300g",        12.50, Color(0.95, 0.75, 0.65), 0, "meat", "Fish"),
		MarketProduct.new("tofu",          "Firm Tofu 400g",      2.80, Color(0.95, 0.92, 0.78), 3, "meat", "Vegetarian"),
		MarketProduct.new("tempeh",        "Tempeh 200g",         4.20, Color(0.72, 0.52, 0.32), 3, "meat", "Vegetarian"),
		MarketProduct.new("lamb_chop",     "Lamb Chops 400g",     15.00, Color(0.72, 0.32, 0.28), 1, "meat", "Lamb"),
		MarketProduct.new("duck_breast",   "Duck Breast 350g",   16.00, Color(0.65, 0.38, 0.32), 1, "meat", "Duck"),
		MarketProduct.new("chorizo",       "Chorizo 200g",        5.80, Color(0.88, 0.28, 0.22), 0, "meat", "Deli"),
		MarketProduct.new("rice_jasmine",  "Jasmine Rice 1kg",    3.80, Color(0.92, 0.90, 0.78), 3, "pantry", "Rice"),
		MarketProduct.new("rice_basmati",  "Basmati Rice 1kg",    4.20, Color(0.88, 0.85, 0.72), 3, "pantry", "Rice"),
		MarketProduct.new("rice_brown",    "Brown Rice 1kg",      4.00, Color(0.68, 0.52, 0.38), 3, "pantry", "Rice"),
		MarketProduct.new("pasta_spaghetti","Spaghetti 500g",     1.80, Color(0.92, 0.85, 0.68), 1, "pantry", "Pasta"),
		MarketProduct.new("pasta_penne",   "Penne 500g",         1.80, Color(0.90, 0.82, 0.65), 1, "pantry", "Pasta"),
		MarketProduct.new("pasta_fusilli", "Fusilli 500g",       1.80, Color(0.88, 0.80, 0.62), 1, "pantry", "Pasta"),
		MarketProduct.new("pasta_lasagna", "Lasagna Sheets",      2.20, Color(0.92, 0.88, 0.72), 3, "pantry", "Pasta"),
		MarketProduct.new("cereal_corn",   "Corn Flakes 500g",   3.50, Color(0.98, 0.90, 0.45), 3, "pantry", "Cereal"),
		MarketProduct.new("cereal_granola","Granola 400g",        5.20, Color(0.72, 0.55, 0.32), 3, "pantry", "Cereal"),
		MarketProduct.new("cereal_oat",    "Rolled Oats 500g",    2.80, Color(0.82, 0.72, 0.55), 3, "pantry", "Cereal"),
		MarketProduct.new("oil_olive",     "Olive Oil 500ml",     6.50, Color(0.72, 0.88, 0.45), 5, "pantry", "Oil"),
		MarketProduct.new("oil_vegetable", "Vegetable Oil 1L",    3.20, Color(0.90, 0.82, 0.50), 5, "pantry", "Oil"),
		MarketProduct.new("oil_coconut",   "Coconut Oil 300ml",   5.50, Color(0.95, 0.92, 0.80), 5, "pantry", "Oil"),
		MarketProduct.new("sauce_tomato",  "Tomato Sauce 400g",  2.20, Color(0.88, 0.22, 0.18), 3, "pantry", "Sauce"),
		MarketProduct.new("sauce_hot",     "Hot Sauce 150ml",   3.80, Color(0.88, 0.18, 0.12), 5, "pantry", "Sauce"),
		MarketProduct.new("sauce_soy",     "Soy Sauce 200ml",   2.50, Color(0.28, 0.18, 0.12), 5, "pantry", "Sauce"),
		MarketProduct.new("sauce_bbq",     "BBQ Sauce 400ml",   3.50, Color(0.52, 0.28, 0.18), 5, "pantry", "Sauce"),
		MarketProduct.new("sauce_fish",    "Fish Sauce 200ml",   3.20, Color(0.85, 0.88, 0.80), 5, "pantry", "Sauce"),
		MarketProduct.new("sauce_salsa",   "Salsa 400g",        2.80, Color(0.88, 0.28, 0.18), 3, "pantry", "Sauce"),
		MarketProduct.new("soup_chicken",  "Chicken Noodle Soup",  2.20, Color(0.95, 0.82, 0.55), 3, "pantry", "Soup"),
		MarketProduct.new("soup_tomato",   "Tomato Soup",          2.20, Color(0.90, 0.28, 0.22), 3, "pantry", "Soup"),
		MarketProduct.new("soup_mushroom", "Mushroom Soup",        2.50, Color(0.72, 0.58, 0.45), 3, "pantry", "Soup"),
		MarketProduct.new("soup_veg",      "Vegetable Soup",        2.20, Color(0.72, 0.62, 0.38), 3, "pantry", "Soup"),
		MarketProduct.new("beans_baked",   "Baked Beans 400g",    1.80, Color(0.72, 0.38, 0.22), 3, "pantry", "Beans"),
		MarketProduct.new("beans_black",   "Black Beans 400g",    1.80, Color(0.22, 0.18, 0.12), 3, "pantry", "Beans"),
		MarketProduct.new("beans_kidney",  "Kidney Beans 400g",   1.80, Color(0.78, 0.22, 0.22), 3, "pantry", "Beans"),
		MarketProduct.new("chickpeas",     "Chickpeas 400g",     1.80, Color(0.72, 0.58, 0.38), 3, "pantry", "Beans"),
		MarketProduct.new("lentils",       "Red Lentils 500g",   2.20, Color(0.92, 0.48, 0.28), 3, "pantry", "Beans"),
		MarketProduct.new("flour_white",   "All-Purpose Flour 1kg",2.50,Color(0.95, 0.92, 0.88), 3, "pantry", "Baking"),
		MarketProduct.new("flour_whole",   "Whole Wheat Flour 1kg",2.80,Color(0.72, 0.55, 0.35), 3, "pantry", "Baking"),
		MarketProduct.new("sugar_white",   "White Sugar 1kg",    2.20, Color(0.95, 0.95, 0.92), 3, "pantry", "Baking"),
		MarketProduct.new("sugar_brown",   "Brown Sugar 500g",    2.50, Color(0.72, 0.52, 0.32), 3, "pantry", "Baking"),
		MarketProduct.new("choco_chips",   "Chocolate Chips 300g", 3.20, Color(0.52, 0.32, 0.18), 0, "pantry", "Baking"),
		MarketProduct.new("vanilla",       "Vanilla Extract",     4.50, Color(0.88, 0.80, 0.58), 5, "pantry", "Baking"),
		MarketProduct.new("baking_powder", "Baking Powder 200g",   2.00, Color(0.92, 0.90, 0.88), 3, "pantry", "Baking"),
		MarketProduct.new("spice_salt",    "Table Salt 500g",     1.20, Color(0.90, 0.90, 0.88), 3, "pantry", "Spices"),
		MarketProduct.new("spice_pepper",  "Black Pepper 100g",   2.50, Color(0.22, 0.18, 0.15), 0, "pantry", "Spices"),
		MarketProduct.new("spice_cumin",   "Ground Cumin 100g",  2.80, Color(0.72, 0.52, 0.32), 0, "pantry", "Spices"),
		MarketProduct.new("spice_paprika", "Paprika 100g",        2.80, Color(0.92, 0.38, 0.18), 0, "pantry", "Spices"),
		MarketProduct.new("spice_oregano", "Dried Oregano 50g",  2.20, Color(0.38, 0.55, 0.28), 0, "pantry", "Spices"),
		MarketProduct.new("spice_cinnamon","Ground Cinnamon 100g",  3.00, Color(0.72, 0.48, 0.32), 0, "pantry", "Spices"),
		MarketProduct.new("spice_ginger",  "Ground Ginger 80g",  2.80, Color(0.82, 0.68, 0.48), 0, "pantry", "Spices"),
		MarketProduct.new("curry_powder",  "Curry Powder 100g",   2.80, Color(0.92, 0.78, 0.28), 0, "pantry", "Spices"),
		MarketProduct.new("stock_chicken", "Chicken Stock 500ml",  2.20, Color(0.90, 0.78, 0.55), 5, "pantry", "Stock"),
		MarketProduct.new("stock_beef",    "Beef Stock 500ml",   2.20, Color(0.58, 0.32, 0.22), 5, "pantry", "Stock"),
		MarketProduct.new("stock_veg",     "Vegetable Stock 500ml",2.00,Color(0.58, 0.52, 0.32), 5, "pantry", "Stock"),
		MarketProduct.new("icecream_van",  "Vanilla Ice Cream 500ml",6.50,Color(0.98,0.95,0.88), 4, "frozen", "Ice Cream"),
		MarketProduct.new("icecream_choco","Chocolate Ice Cream",  6.50, Color(0.42, 0.28, 0.18), 4, "frozen", "Ice Cream"),
		MarketProduct.new("icecream_straw","Strawberry Ice Cream", 6.50, Color(0.95, 0.62, 0.72), 4, "frozen", "Ice Cream"),
		MarketProduct.new("icecream_mint", "Mint Choc Chip Ice Cream",6.80,Color(0.58,0.88,0.68), 4, "frozen", "Ice Cream"),
		MarketProduct.new("popsicle",      "Fruit Popsicles 6pk",  4.00, Color(0.98, 0.55, 0.28), 0, "frozen", "Ice Cream"),
		MarketProduct.new("frozen_pizza",  "Frozen Pizza",          7.50, Color(0.92, 0.55, 0.28), 3, "frozen", "Meals"),
		MarketProduct.new("frozen_burger", "Frozen Hamburgers 4pk",8.80, Color(0.72, 0.48, 0.28), 3, "frozen", "Meals"),
		MarketProduct.new("frozen_chicken","Frozen Chicken Nuggets", 6.80, Color(0.92, 0.78, 0.55), 0, "frozen", "Meals"),
		MarketProduct.new("frozen_fish",   "Frozen Fish Fillets",  10.00, Color(0.88, 0.85, 0.78), 1, "frozen", "Meals"),
		MarketProduct.new("frozen_veg",    "Mixed Vegetables 500g", 2.80, Color(0.52, 0.72, 0.38), 3, "frozen", "Vegetables"),
		MarketProduct.new("frozen_corn",    "Frozen Corn 500g",     2.50, Color(0.98, 0.92, 0.42), 0, "frozen", "Vegetables"),
		MarketProduct.new("frozen_broccoli","Frozen Broccoli 400g", 2.80, Color(0.28, 0.62, 0.32), 0, "frozen", "Vegetables"),
		MarketProduct.new("frozen_spinach", "Frozen Spinach 300g",  2.50, Color(0.28, 0.62, 0.28), 0, "frozen", "Vegetables"),
		MarketProduct.new("frozen_waffle", "Frozen Waffles 10pk",  4.20, Color(0.90, 0.78, 0.52), 3, "frozen", "Breakfast"),
		MarketProduct.new("frozen_pancake","Frozen Pancakes 8pk",   4.00, Color(0.92, 0.80, 0.58), 3, "frozen", "Breakfast"),
		MarketProduct.new("ice_cube",       "Ice Cubes 1kg",        1.50, Color(0.80, 0.92, 1.00), 0, "frozen", "Other"),
		MarketProduct.new("frozen_rice",    "Frozen Rice 400g",     3.50, Color(0.92, 0.90, 0.80), 3, "frozen", "Meals"),
		MarketProduct.new("frozen_dumpling","Frozen Dumplings 300g",5.50, Color(0.90, 0.82, 0.62), 0, "frozen", "Meals"),
		MarketProduct.new("frozen_bread",   "Frozen Garlic Bread",   3.80, Color(0.88, 0.72, 0.45), 1, "frozen", "Meals"),
		MarketProduct.new("frozen_shrimp",  "Frozen Shrimp 300g",  11.00, Color(0.95, 0.75, 0.65), 0, "frozen", "Seafood"),
		MarketProduct.new("frozen_tofu",    "Frozen Tofu 300g",    2.50, Color(0.95, 0.92, 0.80), 3, "frozen", "Vegetarian"),
		MarketProduct.new("mochi",          "Mochi Ice Cream 6pk", 5.50, Color(0.95, 0.90, 0.80), 0, "frozen", "Ice Cream"),
	]

static func get_section_def(section_id: String):
	for s in SECTIONS:
		if s.id == section_id:
			return s
	return SECTIONS[0]

static func get_products_in_section(section_id: String):
	var result = []
	for p in CATALOG:
		if p.section == section_id:
			result.append(p)
	return result

static func get_section_for_pos(wx: int, wy: int):
	for s in SECTIONS:
		if wx >= s.wx and wx < s.wx + s.ww and wy >= s.wy and wy < s.wy + s.wh:
			return s
	return null
