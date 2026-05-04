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
	var floor: int  # Which floor this section appears on. -1 = all floors.

	func _init(p_id: String, p_name: String, p_wx: int, p_wy: int, p_ww: int, p_wh: int, p_style: int, p_light: Color, p_label: String, p_floor: int = -1):
		id=p_id; name=p_name; wx=p_wx; wy=p_wy; ww=p_ww; wh=p_wh; style=p_style; light_color=p_light; label=p_label; floor=p_floor

class MarketProduct:
	var id: String
	var name: String
	var price: float
	var color: Color
	var shape: int
	var section: String
	var sub: String
	var desc: String

	func _init(i: String, n: String, p: float, c: Color, s: int, sec: String, sub_cat: String, p_desc: String):
		id=i; name=n; price=p; color=c; shape=s; section=sec; sub=sub_cat; desc=p_desc

static var SECTIONS: Array = []
static var CATALOG: Array = []
static var CHECKOUT_Y: int = 37
static var CHECKOUT_LANES: Array = []

static func _static_init() -> void:
	SECTIONS = [
		# Floor 1 — Fresh Market
		SectionDef.new("dairy",   "DAIRY",      2,  3, 16, 14, SectionStyle.FRIDGE,   Color(0.70, 0.88, 1.00),  "D",  1),
		SectionDef.new("produce", "PRODUCE",   20,  3, 20, 14, SectionStyle.PRODUCE,  Color(0.72, 0.92, 0.56),  "P",  1),
		SectionDef.new("bakery",  "BAKERY",    42,  3, 16, 14, SectionStyle.BAKERY,   Color(0.98, 0.82, 0.52),  "B",  1),
		SectionDef.new("meat",    "MEAT/DELI", 20, 19, 20, 14, SectionStyle.DELI,     Color(0.95, 0.72, 0.68),  "M",  1),
		# Floor 2 — Pantry
		SectionDef.new("pantry", "PANTRY",    42, 19, 16, 14, SectionStyle.SHELF,    Color(0.90, 0.85, 0.75),  "T",  2),
		SectionDef.new("spices",  "SPICES",     2, 19, 16, 14, SectionStyle.SHELF,    Color(0.88, 0.72, 0.55),  "S",  2),
		# Floor 3 — Beverages
		SectionDef.new("drinks",  "DRINKS",    60,  3, 18, 14, SectionStyle.FRIDGE,   Color(0.60, 0.82, 1.00),  "R",  3),
		SectionDef.new("coffee",  "COFFEE",    42,  3, 16, 14, SectionStyle.FRIDGE,   Color(0.55, 0.42, 0.32),  "C",  3),
		# Floor 4 — Snacks & Candy
		SectionDef.new("snacks",  "SNACKS",     2, 19, 16, 14, SectionStyle.SHELF,    Color(0.95, 0.90, 0.80),  "S",  4),
		SectionDef.new("candy",   "CANDY",     20, 19, 16, 14, SectionStyle.SHELF,    Color(0.88, 0.60, 0.80),  "A",  4),
		# Floor 5 — Frozen
		SectionDef.new("frozen",  "FROZEN",    60, 19, 18, 14, SectionStyle.FREEZER,  Color(0.78, 0.92, 1.00),  "F",  5),
		# Floor 6 — Household
		SectionDef.new("clean",   "CLEANING",  42, 19, 16, 14, SectionStyle.SHELF,    Color(0.55, 0.70, 0.65),  "L",  6),
		SectionDef.new("paper",   "PAPER",     60, 19, 18, 14, SectionStyle.SHELF,    Color(0.88, 0.85, 0.78),  "P",  6),
		# Floor 7 — Health & Beauty
		SectionDef.new("pharm",   "PHARMACY",   2,  3, 16, 14, SectionStyle.FRIDGE,   Color(0.85, 0.65, 0.65),  "H",  7),
		SectionDef.new("beauty",  "BEAUTY",    20,  3, 20, 14, SectionStyle.SHELF,    Color(0.88, 0.72, 0.80),  "B",  7),
		# Floor 8 — Toys
		SectionDef.new("toys",    "TOYS",      20,  3, 30, 20, SectionStyle.SHELF,    Color(0.70, 0.60, 0.90),  "T",  8),
		# Floor 10 — Rooftop Café
		SectionDef.new("cafe",    "CAFE",      42,  3, 18, 14, SectionStyle.SHELF,    Color(0.72, 0.55, 0.42),  "F", 10),
		# Floor 11 — Pet Paradise
		SectionDef.new("pet",     "PET PARADISE", 2,  3, 22, 20, SectionStyle.SHELF,    Color(0.55, 0.80, 0.65),  "E", 11),
	]
	CHECKOUT_LANES = [
		{"x": 18, "name": "LANE 1"},
		{"x": 36, "name": "LANE 2"},
		{"x": 54, "name": "LANE 3"},
	]
	CATALOG = [
		# ═══════════════════ PRODUCE ═══════════════════
		MarketProduct.new("apple_fuji",    "Fuji Apple",         1.20, Color(0.90, 0.30, 0.20), 0, "produce", "Fruits",       "Crisp and sweet, perfect for snacking or baking."),
		MarketProduct.new("apple_gala",    "Gala Apple",         1.10, Color(0.95, 0.40, 0.25), 0, "produce", "Fruits",       "Mildly sweet with a delicate floral aroma."),
		MarketProduct.new("banana",        "Banana",             0.60, Color(0.98, 0.90, 0.30), 5, "produce", "Fruits",       "Rich in potassium. Great for smoothies."),
		MarketProduct.new("orange",        "Orange",             0.80, Color(0.95, 0.55, 0.10), 0, "produce", "Fruits",       "Juicy citrus fruit, packed with Vitamin C."),
		MarketProduct.new("lemon",         "Lemon",              0.70, Color(0.98, 0.95, 0.30), 0, "produce", "Fruits",       "Bright and tart. Perfect for drinks or cooking."),
		MarketProduct.new("lime",          "Lime",               0.65, Color(0.50, 0.88, 0.40), 0, "produce", "Fruits",       "Zesty green citrus for margaritas and Thai food."),
		MarketProduct.new("grapes_red",    "Red Grapes",         2.50, Color(0.72, 0.20, 0.60), 0, "produce", "Fruits",       "Seedless and sweet. Great for cheese boards."),
		MarketProduct.new("grapes_green",  "Green Grapes",       2.80, Color(0.65, 0.85, 0.45), 0, "produce", "Fruits",       "Crisp and refreshing. No seeds, all bite."),
		MarketProduct.new("strawberry",    "Strawberry Pack",    3.20, Color(0.92, 0.22, 0.30), 0, "produce", "Fruits",       "Sweet summer berries, locally sourced."),
		MarketProduct.new("blueberry",     "Blueberry Pack",     4.50, Color(0.30, 0.30, 0.90), 0, "produce", "Fruits",       "Antioxidant-rich superfood. Eat fresh or in yogurt."),
		MarketProduct.new("watermelon",    "Watermelon",          5.00, Color(0.38, 0.78, 0.35), 0, "produce", "Fruits",       "Sweet and hydrating. Ripe and ready to slice."),
		MarketProduct.new("mango",         "Mango",              1.50, Color(0.95, 0.78, 0.20), 0, "produce", "Fruits",       "Tropical sweetness. Smells like paradise."),
		MarketProduct.new("papaya",        "Papaya",             2.20, Color(0.98, 0.70, 0.30), 0, "produce", "Fruits",       "Contains papain enzyme, great for digestion."),
		MarketProduct.new("kiwi",          "Kiwi",               0.90, Color(0.42, 0.72, 0.30), 0, "produce", "Fruits",       "Fuzzy outside, bright green inside. Hairy little gem."),
		MarketProduct.new("peach",         "Peach",              1.30, Color(0.98, 0.72, 0.50), 0, "produce", "Fruits",       "Stone fruit with fuzzy skin and sweet flesh."),
		MarketProduct.new("pear",          "Pear",               1.00, Color(0.82, 0.90, 0.45), 0, "produce", "Fruits",       "Buttery and sweet. Gentle on the tummy."),
		MarketProduct.new("carrot",        "Carrot",             0.90, Color(0.98, 0.55, 0.15), 1, "produce", "Vegetables",   "Crunchy and sweet. Great raw or in stews."),
		MarketProduct.new("broccoli",      "Broccoli",           1.80, Color(0.25, 0.62, 0.28), 0, "produce", "Vegetables",   "Tree-like florets. A true superfood champion."),
		MarketProduct.new("tomato",        "Tomato",             1.20, Color(0.92, 0.22, 0.22), 0, "produce", "Vegetables",   "Vine-ripened. Essential for salads and sauces."),
		MarketProduct.new("cucumber",      "Cucumber",           0.80, Color(0.38, 0.72, 0.38), 1, "produce", "Vegetables",   "Cool and crisp. Perfect for salads or snacking."),
		MarketProduct.new("lettuce",       "Lettuce",            1.50, Color(0.60, 0.88, 0.45), 0, "produce", "Vegetables",   "Crisp romaine hearts. Base for any salad."),
		MarketProduct.new("spinach",       "Baby Spinach",       2.20, Color(0.28, 0.62, 0.28), 0, "produce", "Vegetables",   "Tender baby leaves. Iron-rich and earthy."),
		MarketProduct.new("cabbage",       "Cabbage",            1.10, Color(0.65, 0.82, 0.55), 0, "produce", "Vegetables",   "Dense and crunchy. For slaw, stir-fry or soup."),
		MarketProduct.new("onion",         "Onion",              0.70, Color(0.85, 0.72, 0.60), 0, "produce", "Vegetables",   "The foundation of nearly every savory dish."),
		MarketProduct.new("potato",        "Potato",             0.80, Color(0.82, 0.65, 0.45), 0, "produce", "Vegetables",   "Versatile starchy tuber. Mashed, baked, or fried."),
		MarketProduct.new("sweet_potato",  "Sweet Potato",       1.20, Color(0.85, 0.48, 0.30), 1, "produce", "Vegetables",   "Naturally sweet and packed with beta-carotene."),
		MarketProduct.new("garlic",        "Garlic",             0.50, Color(0.90, 0.85, 0.72), 0, "produce", "Vegetables",   "Pungent and powerful. Flavour base for any cuisine."),
		MarketProduct.new("bell_pepper",   "Bell Pepper",        1.60, Color(0.92, 0.28, 0.22), 0, "produce", "Vegetables",   "Sweet and crunchy. Red is the ripest and sweetest."),
		MarketProduct.new("corn",          "Corn",               0.90, Color(0.98, 0.92, 0.40), 0, "produce", "Vegetables",   "Sweet corn on the cob. Summer BBQ essential."),
		MarketProduct.new("mushroom",      "Mushroom Pack",      2.50, Color(0.82, 0.72, 0.60), 0, "produce", "Vegetables",   "Cremini mushrooms. Earthy umami goodness."),
		MarketProduct.new("celery",        "Celery",             1.30, Color(0.80, 0.95, 0.72), 1, "produce", "Vegetables",   "Crunchy stalks. Perfect with hummus or in stocks."),
		MarketProduct.new("basil",         "Fresh Basil",        1.80, Color(0.28, 0.68, 0.28), 0, "produce", "Herbs",        "Aromatic herb. Essential for pesto and Caprese."),
		MarketProduct.new("cilantro",       "Cilantro Bunch",    0.90, Color(0.38, 0.72, 0.30), 0, "produce", "Herbs",        "Bright and citrusy. Key in Mexican and Thai cooking."),
		MarketProduct.new("parsley",       "Parsley",            0.80, Color(0.28, 0.65, 0.28), 0, "produce", "Herbs",        "Fresh flat-leaf parsley. Brightens any dish."),
		MarketProduct.new("mint",          "Fresh Mint",         1.00, Color(0.38, 0.72, 0.48), 0, "produce", "Herbs",        "Cool and refreshing. Great for tea or mojitos."),
		MarketProduct.new("avocado",       "Avocado",            1.80, Color(0.55, 0.78, 0.42), 0, "produce", "Fruits",       "Creamy and rich. Ripe when slightly soft to touch."),

		# ═══════════════════ DAIRY ═══════════════════
		MarketProduct.new("milk_whole",    "Whole Milk 1L",      2.80, Color(0.95, 0.95, 0.88), 5, "dairy", "Milk",         "Creamy whole milk. Calcium-rich and delicious."),
		MarketProduct.new("milk_skim",     "Skim Milk 1L",       2.80, Color(0.92, 0.95, 1.00), 5, "dairy", "Milk",         "Fat-free milk. All the calcium, none of the fat."),
		MarketProduct.new("milk_oat",      "Oat Milk 1L",        3.50, Color(0.90, 0.82, 0.60), 5, "dairy", "Milk",         "Creamy plant-based milk. Great for coffee."),
		MarketProduct.new("milk_almond",   "Almond Milk 1L",     3.20, Color(0.85, 0.78, 0.60), 5, "dairy", "Milk",         "Light and nutty dairy-free alternative."),
		MarketProduct.new("milk_soy",     "Soy Milk 1L",        2.90, Color(0.90, 0.88, 0.72), 5, "dairy", "Milk",         "Protein-rich plant milk. Fortified with vitamins."),
		MarketProduct.new("cheese_cheddar","Cheddar Block",     4.50, Color(0.95, 0.72, 0.20), 3, "dairy", "Cheese",       "Sharp aged cheddar. Perfect for burgers and mac."),
		MarketProduct.new("cheese_mozz",   "Mozzarella",         3.80, Color(0.95, 0.95, 0.82), 3, "dairy", "Cheese",       "Stretchy and mild. The pizza essential."),
		MarketProduct.new("cheese_brie",   "Brie",               5.50, Color(0.92, 0.88, 0.70), 3, "dairy", "Cheese",       "Soft-ripened with a buttery, mushroomy flavor."),
		MarketProduct.new("cheese_parm",   "Parmesan",           6.20, Color(0.88, 0.82, 0.60), 3, "dairy", "Cheese",       "Aged Italian hard cheese. Umami bomb."),
		MarketProduct.new("cheese_gouda",  "Gouda",              4.80, Color(0.98, 0.85, 0.50), 3, "dairy", "Cheese",       "Sweet and creamy Dutch cheese. Smoked variety is amazing."),
		MarketProduct.new("cheese_feta",   "Feta",               4.20, Color(0.92, 0.92, 0.88), 3, "dairy", "Cheese",       "Crumbly Greek cheese. Salty and tangy."),
		MarketProduct.new("yogurt_plain",  "Plain Yogurt 500g",  3.20, Color(0.95, 0.92, 0.85), 4, "dairy", "Yogurt",       "Versatile plain yogurt. Use in baking or dips."),
		MarketProduct.new("yogurt_straw",  "Strawberry Yogurt",  3.50, Color(0.95, 0.60, 0.72), 4, "dairy", "Yogurt",       "Sweet strawberry swirl yogurt. Grab-and-go breakfast."),
		MarketProduct.new("yogurt_blue",   "Blueberry Yogurt",   3.50, Color(0.55, 0.55, 0.90), 4, "dairy", "Yogurt",       "Creamy yogurt with wild blueberry compote."),
		MarketProduct.new("yogurt_greek",  "Greek Yogurt",       4.00, Color(0.95, 0.92, 0.88), 4, "dairy", "Yogurt",       "Thick, protein-packed. Awesome with honey."),
		MarketProduct.new("yogurt_vanilla","Vanilla Greek Yogurt",3.80, Color(0.95, 0.90, 0.72), 4, "dairy", "Yogurt",       "Greek yogurt with real vanilla bean specks."),
		MarketProduct.new("butter_salted","Salted Butter 250g", 3.50, Color(0.95, 0.88, 0.50), 3, "dairy", "Butter",       "Rich and creamy. Essential for baking and toast."),
		MarketProduct.new("butter_grass","Grass-Fed Butter",    5.00, Color(0.98, 0.92, 0.60), 3, "dairy", "Butter",       "Premium butter from grass-fed cows. Golden color."),
		MarketProduct.new("cream_heavy",   "Heavy Cream 500ml",  3.80, Color(0.96, 0.94, 0.90), 4, "dairy", "Cream",        "Whipping cream. Perfect for sauces and desserts."),
		MarketProduct.new("cream_light",   "Light Cream 500ml",  2.50, Color(0.96, 0.96, 0.94), 4, "dairy", "Cream",        "Coffee cream or light cooking. All-purpose dairy."),
		MarketProduct.new("cottage_cheese","Cottage Cheese 500g",3.00, Color(0.95, 0.95, 0.90), 4, "dairy", "Cheese",       "High-protein fresh cheese. Mild and creamy."),
		MarketProduct.new("sour_cream",    "Sour Cream 500g",    2.80, Color(0.95, 0.95, 0.90), 4, "dairy", "Dairy",        "Tangy cream. Essential for baked potatoes and tacos."),
		MarketProduct.new("half_and_half","Half & Half 500ml",   2.20, Color(0.95, 0.95, 0.92), 5, "dairy", "Milk",         "Coffee cream. The perfect dairy addition to your morning cup."),
		MarketProduct.new("eggs_dozen",   "Eggs Large 12pk",     4.20, Color(0.95, 0.88, 0.72), 3, "dairy", "Eggs",         "Farm-fresh large eggs. Versatile protein source."),

		# ═══════════════════ BAKERY ═══════════════════
		MarketProduct.new("bread_white",   "White Sliced Bread", 2.50, Color(0.92, 0.82, 0.60), 3, "bakery", "Bread",       "Soft sandwich bread. The everyday staple."),
		MarketProduct.new("bread_wheat",  "Whole Wheat Bread",  3.20, Color(0.65, 0.48, 0.28), 3, "bakery", "Bread",       "Nutty wholegrain bread. High in fiber."),
		MarketProduct.new("bread_sourdough","Sourdough Loaf",    4.50, Color(0.88, 0.72, 0.42), 3, "bakery", "Bread",       "Tangy artisan sourdough with a crispy crust."),
		MarketProduct.new("bread_baguette","Baguette",           2.80, Color(0.90, 0.78, 0.55), 3, "bakery", "Bread",       "Long French bread. Crusty outside, airy inside."),
		MarketProduct.new("bread_rye",    "Rye Bread",           3.50, Color(0.72, 0.52, 0.28), 3, "bakery", "Bread",       "Dense and tangy. Classic for sandwiches."),
		MarketProduct.new("bread_olive",  "Olive Focaccia",     4.80, Color(0.78, 0.88, 0.48), 3, "bakery", "Bread",       "Flat bread studded with olives and herbs."),
		MarketProduct.new("rolls_dinner",  "Dinner Rolls 6pk",  3.00, Color(0.95, 0.85, 0.62), 3, "bakery", "Bread",       "Soft buttery rolls. Perfect with any meal."),
		MarketProduct.new("bagel_plain",  "Plain Bagels 4pk",    3.80, Color(0.85, 0.68, 0.45), 0, "bakery", "Bread",       "Chewy boiled-then-baked rings. Toast and top."),
		MarketProduct.new("croissant",    "Butter Croissant",   2.50, Color(0.95, 0.80, 0.42), 6, "bakery", "Pastries",    "Flaky and buttery. Parisian breakfast perfection."),
		MarketProduct.new("pain_choco",   "Pain au Chocolat",    3.20, Color(0.42, 0.28, 0.18), 6, "bakery", "Pastries",    "Flaky pastry with dark chocolate strips inside."),
		MarketProduct.new("muffin_blue",  "Blueberry Muffin",   2.80, Color(0.55, 0.55, 0.90), 4, "bakery", "Pastries",    "Soft muffin bursting with blueberries."),
		MarketProduct.new("muffin_choc",  "Chocolate Muffin",   2.80, Color(0.42, 0.28, 0.18), 4, "bakery", "Pastries",    "Double chocolate. Rich and indulgent."),
		MarketProduct.new("cake_choco",    "Chocolate Cake Slice",3.50, Color(0.42, 0.28, 0.18), 3, "bakery", "Cakes",       "Moist chocolate layer cake with ganache."),
		MarketProduct.new("cake_vanilla", "Vanilla Cake Slice",  3.20, Color(0.95, 0.92, 0.78), 3, "bakery", "Cakes",       "Light and fluffy vanilla sponge with buttercream."),
		MarketProduct.new("cheesecake",    "NY Cheesecake Slice",4.00, Color(0.98, 0.95, 0.88), 3, "bakery", "Cakes",       "Creamy, dense, and impossibly rich. New York style."),
		MarketProduct.new("tart_lemon",   "Lemon Tart",          3.80, Color(0.98, 0.95, 0.30), 3, "bakery", "Pastries",    "Tangy lemon curd in a crisp pastry shell."),
		MarketProduct.new("donut_glaze",  "Glazed Donut",        1.50, Color(0.95, 0.82, 0.60), 0, "bakery", "Pastries",    "Light and airy yeast donut with sweet glaze."),
		MarketProduct.new("donut_choco",   "Chocolate Donut",    1.50, Color(0.42, 0.28, 0.18), 0, "bakery", "Pastries",    "Fried ring dipped in rich chocolate frosting."),
		MarketProduct.new("cinnamon_roll","Cinnamon Roll",       3.00, Color(0.85, 0.65, 0.38), 4, "bakery", "Pastries",    "Warm spiral of cinnamon sugar. Addictively good."),
		MarketProduct.new("bread_brioche","Brioche Loaf",         5.00, Color(0.95, 0.78, 0.42), 3, "bakery", "Bread",       "Rich buttery French bread. Slightly sweet."),
		MarketProduct.new("pita_white",    "White Pita 4pk",     2.50, Color(0.95, 0.88, 0.72), 3, "bakery", "Bread",       "Soft flatbread. Stuff it or dip it."),
		MarketProduct.new("tortilla_10",  "Flour Tortilla 10\"",2.80, Color(0.95, 0.90, 0.78), 3, "bakery", "Bread",       "Large flour tortillas. Wrap, roll, or fold."),
		MarketProduct.new("naan",          "Garlic Naan 2pk",     3.20, Color(0.88, 0.72, 0.45), 3, "bakery", "Bread",       "Soft Indian flatbread with garlic butter."),

		# ═══════════════════ DRINKS ═══════════════════
		MarketProduct.new("water_sparkling","Sparkling Water 1L", 1.20, Color(0.80, 0.92, 1.00), 5, "drinks", "Water",       "Crisp carbonated water. Zero sugar, all bubbles."),
		MarketProduct.new("water_still",  "Spring Water 1L",    0.80, Color(0.78, 0.90, 1.00), 5, "drinks", "Water",       "Pure mountain spring water. Clean and refreshing."),
		MarketProduct.new("juice_orange", "Orange Juice 1L",     3.50, Color(0.98, 0.65, 0.10), 5, "drinks", "Juice",       "Fresh-squeezed style OJ. Morning vitamin boost."),
		MarketProduct.new("juice_apple",  "Apple Juice 1L",      3.00, Color(0.90, 0.78, 0.42), 5, "drinks", "Juice",       "Sweet and crisp. Kids' favourite."),
		MarketProduct.new("juice_grape",  "Grape Juice 1L",      3.20, Color(0.55, 0.18, 0.72), 5, "drinks", "Juice",       "Rich purple grape. Tastes like Welch's."),
		MarketProduct.new("juice_cran",   "Cranberry Juice 1L",  3.80, Color(0.72, 0.18, 0.28), 5, "drinks", "Juice",       "Tart and tangy. Great mixed with other juices."),
		MarketProduct.new("soda_cola",    "Cola 2L",             2.20, Color(0.38, 0.22, 0.18), 5, "drinks", "Soda",        "Classic cola. Ice cold is the only way."),
		MarketProduct.new("soda_sprite",   "Lemon-Lime Soda 2L", 2.20, Color(0.88, 0.98, 0.48), 5, "drinks", "Soda",        "Clear and citrusy. Ultra refreshing."),
		MarketProduct.new("soda_orange",  "Orange Soda 2L",      2.20, Color(0.98, 0.58, 0.10), 5, "drinks", "Soda",        "Bright and sweet orange fizz."),
		MarketProduct.new("soda_rootbeer","Root Beer 2L",         2.20, Color(0.72, 0.52, 0.32), 5, "drinks", "Soda",        "Creamy and sassafras-y.Pairs with vanilla ice cream."),
		MarketProduct.new("soda_grape",   "Grape Soda 2L",       2.20, Color(0.55, 0.18, 0.72), 5, "drinks", "Soda",        "Bold purple fizz. Fun and fruity."),
		MarketProduct.new("energy_redbull","Red Bull 250ml",     3.50, Color(0.95, 0.78, 0.18), 5, "drinks", "Energy",      "Wings in a can. Gives you that edge."),
		MarketProduct.new("energy_monster","Monster Energy 500ml",3.80, Color(0.38, 0.62, 0.28), 5, "drinks", "Energy",      "Big bold energy. Not for the caffeine-sensitive."),
		MarketProduct.new("coffee_blend", "House Blend Coffee",  8.50, Color(0.38, 0.25, 0.18), 5, "drinks", "Coffee",      "Pre-ground medium roast. Consistent and smooth."),
		MarketProduct.new("coffee_espresso","Espresso Beans 250g",9.00, Color(0.35, 0.22, 0.15), 5, "drinks", "Coffee",      "Italian roast espresso beans. Dark and bold."),
		MarketProduct.new("tea_earlgrey", "Earl Grey Tea 20pk",  3.50, Color(0.92, 0.88, 0.72), 5, "drinks", "Tea",         "Bergamot-infused black tea. Elegant and aromatic."),
		MarketProduct.new("tea_green",    "Green Tea 20pk",      3.20, Color(0.55, 0.78, 0.52), 5, "drinks", "Tea",         "Gentle Japanese green tea. Light and grassy."),
		MarketProduct.new("tea_chamomile","Chamomile Tea 20pk",  3.80, Color(0.95, 0.90, 0.60), 5, "drinks", "Tea",         "Soothing herbal tea. Perfect before bed."),
		MarketProduct.new("lemonade",     "Lemonade 1L",         2.50, Color(0.98, 0.95, 0.50), 5, "drinks", "Juice",       "Homemade-style lemonade. Sweet and tart."),
		MarketProduct.new("iced_tea",     "Iced Tea 1L",         2.00, Color(0.88, 0.72, 0.48), 5, "drinks", "Tea",         "Bottled iced tea. Lightly sweetened."),
		MarketProduct.new("kombucha",      "Kombucha 500ml",      4.50, Color(0.38, 0.72, 0.62), 5, "drinks", "Juice",       "Fermented tea. Probiotic and slightly effervescent."),

		# ═══════════════════ SNACKS ═══════════════════
		MarketProduct.new("chips_salted", "Salted Chips 200g",   3.20, Color(0.95, 0.82, 0.42), 3, "snacks", "Chips",       "Classic salted potato chips. Crispy and addictive."),
		MarketProduct.new("chips_bbq",    "BBQ Chips 200g",     3.20, Color(0.72, 0.32, 0.18), 3, "snacks", "Chips",       "Smoky BBQ seasoned chips. Tangy and savory."),
		MarketProduct.new("chips_sour",   "Sour Cream & Onion",  3.20, Color(0.90, 0.95, 0.78), 3, "snacks", "Chips",       "Cool sour cream with chive. Crowd pleaser."),
		MarketProduct.new("chips_choco",  "Chocolate Chips 200g",3.50, Color(0.42, 0.28, 0.18), 3, "snacks", "Chips",       "Sweet chocolate-dusted chips. Dessert chip."),
		MarketProduct.new("tortilla_chips","Tortilla Chips 300g", 3.00, Color(0.92, 0.82, 0.52), 3, "snacks", "Chips",       "Sturdy corn chips. Made for salsa and guac."),
		MarketProduct.new("pretzels",     "Pretzel Twists 200g", 2.80, Color(0.78, 0.58, 0.32), 3, "snacks", "Chips",       "Salted soft pretzels. Beer best friend."),
		MarketProduct.new("popcorn_butter","Butter Popcorn 150g",2.50, Color(0.98, 0.90, 0.50), 3, "snacks", "Chips",       "Movie theater style butter popcorn in a bag."),
		MarketProduct.new("cookies_choc", "Chocolate Cookies 200g",3.20, Color(0.42, 0.28, 0.18), 3, "snacks", "Cookies",     "Chewy chocolate chip cookies. Straight from the oven taste."),
		MarketProduct.new("cookies_oat",  "Oatmeal Raisin 200g", 3.00, Color(0.72, 0.55, 0.32), 3, "snacks", "Cookies",     "Chewy oatmeal cookies with raisins and cinnamon."),
		MarketProduct.new("cookies_sugar","Sugar Cookies 200g",   2.80, Color(0.95, 0.88, 0.72), 3, "snacks", "Cookies",     "Sweet and crumbly. Great with milk."),
		MarketProduct.new("cookies_thin", "Wafer Cookies 300g",   3.50, Color(0.95, 0.92, 0.80), 3, "snacks", "Cookies",     "Layered vanilla wafers. Light and crispy."),
		MarketProduct.new("candy_gummy",  "Gummy Bears 150g",     2.50, Color(0.92, 0.28, 0.28), 0, "snacks", "Candy",       "Chewy fruity bears. One is never enough."),
		MarketProduct.new("candy_sour",   "Sour Worms 150g",     2.80, Color(0.98, 0.88, 0.28), 0, "snacks", "Candy",       "Tart sugar-coated sour gummy worms."),
		MarketProduct.new("candy_choc",   "Milk Chocolate Bar",   2.50, Color(0.55, 0.38, 0.22), 3, "snacks", "Chocolate",   "Smooth milk chocolate. The classic treat."),
		MarketProduct.new("candy_dark",   "Dark Chocolate 70%",   3.50, Color(0.28, 0.18, 0.12), 3, "snacks", "Chocolate",   "Rich and bittersweet. Cocoa-forward."),
		MarketProduct.new("chocolate盒",  "Chocolate Box 12pk",   8.00, Color(0.55, 0.35, 0.20), 3, "snacks", "Chocolate",   "Assorted chocolate truffles. Gift-worthy."),
		MarketProduct.new("nuts_mixed",   "Mixed Nuts 300g",     6.50, Color(0.75, 0.58, 0.35), 0, "snacks", "Nuts",        "Roasted and salted. Healthy snacking."),
		MarketProduct.new("nuts_almonds", "Roasted Almonds 200g",5.50, Color(0.78, 0.62, 0.42), 0, "snacks", "Nuts",        "Crunchy roasted almonds. High in protein."),
		MarketProduct.new("nuts_peanuts", "Roasted Peanuts 300g",3.50, Color(0.82, 0.55, 0.32), 0, "snacks", "Nuts",        "Salted peanuts. The ballgame classic."),
		MarketProduct.new("nuts_pistachio","Pistachios 200g",    7.50, Color(0.62, 0.88, 0.52), 0, "snacks", "Nuts",        "In-shell roasted pistachios. Addictive and fun."),
		MarketProduct.new("granola_bar",  "Granola Bars 6pk",    3.80, Color(0.85, 0.68, 0.42), 3, "snacks", "Bars",        "Oat and honey cereal bars. On-the-go energy."),
		MarketProduct.new("fruit_snack",  "Dried Mango 150g",    4.50, Color(0.98, 0.72, 0.28), 0, "snacks", "Nuts",        "Sweet dried mango slices. Tropical treat."),
		MarketProduct.new("hummus",       "Hummus 200g",         3.50, Color(0.85, 0.78, 0.52), 4, "snacks", "Dips",        "Creamy chickpea dip. Great with pita."),
		MarketProduct.new("salsa",        "Salsa Medium 400g",  2.80, Color(0.92, 0.22, 0.22), 4, "snacks", "Dips",        "Tomato salsa with jalape\u00f1o. Medium heat."),
		MarketProduct.new("guac",         "Guacamole 200g",       4.00, Color(0.55, 0.78, 0.42), 4, "snacks", "Dips",        "Fresh avocado dip. Eat within 24 hours."),

		# ═══════════════════ MEAT / DELI ═══════════════════
		MarketProduct.new("chicken_breast","Chicken Breast 500g", 5.80, Color(0.95, 0.82, 0.72), 3, "meat", "Chicken",     "Boneless skinless chicken breast. Lean protein."),
		MarketProduct.new("chicken_thigh","Chicken Thighs 500g",  4.50, Color(0.88, 0.52, 0.38), 3, "meat", "Chicken",     "Juicier than breast. Great for braising."),
		MarketProduct.new("chicken_wings","Chicken Wings 600g",  5.50, Color(0.95, 0.78, 0.60), 3, "meat", "Chicken",     "Fresh chicken wings. Bake or deep fry."),
		MarketProduct.new("beef_steak",   "Beef Steak 300g",     8.50, Color(0.72, 0.28, 0.28), 3, "meat", "Beef",        "Prime cut sirloin steak. Marbled and tender."),
		MarketProduct.new("beef_mince",   "Beef Mince 500g",     5.20, Color(0.80, 0.32, 0.28), 3, "meat", "Beef",        "Ground beef 20% fat. Perfect for burgers."),
		MarketProduct.new("beef_roast",   "Beef Roast 800g",     9.50, Color(0.75, 0.32, 0.25), 3, "meat", "Beef",        "Slow-cook roast beef. Fall-apart tender."),
		MarketProduct.new("pork_chop",    "Pork Chops 400g",     5.50, Color(0.90, 0.72, 0.68), 3, "meat", "Pork",        "Bone-in pork chops. Pan-fry to juicy perfection."),
		MarketProduct.new("bacon",        "Bacon 300g",          6.50, Color(0.88, 0.52, 0.42), 3, "meat", "Pork",        "Smoky streaky bacon. The breakfast essential."),
		MarketProduct.new("sausage_pork", "Pork Sausages 400g",  4.80, Color(0.82, 0.52, 0.38), 3, "meat", "Pork",        "Grill sausages. British banger style."),
		MarketProduct.new("ham_sliced",   "Sliced Ham 200g",     4.50, Color(0.92, 0.62, 0.52), 3, "meat", "Pork",        "Deli sliced ham. For sandwiches and quiches."),
		MarketProduct.new("salmon_fillet","Fresh Salmon 300g",  10.50, Color(0.92, 0.58, 0.48), 3, "meat", "Fish",        "Fresh Atlantic salmon fillet. Omega-3 rich."),
		MarketProduct.new("tuna_steak",   "Tuna Steak 250g",     11.00, Color(0.55, 0.42, 0.48), 3, "meat", "Fish",        "Sushi-grade tuna. Flash-frozen for freshness."),
		MarketProduct.new("shrimp",       "Tiger Shrimp 300g",   9.50, Color(0.98, 0.72, 0.60), 0, "meat", "Fish",        "Peeled and deveined. Quick weeknight protein."),
		MarketProduct.new("cod_fillet",   "Cod Fillet 400g",     7.50, Color(0.92, 0.90, 0.85), 3, "meat", "Fish",        "White flaky fish. Classic fish and chips fish."),
		MarketProduct.new("salami",       "Genoa Salami 150g",   5.00, Color(0.80, 0.35, 0.25), 3, "meat", "Deli",        "Cured Italian salami. Bold and garlicky."),
		MarketProduct.new("prosciutto",   "Prosciutto 100g",     7.50, Color(0.88, 0.55, 0.52), 3, "meat", "Deli",        "Thin-sliced Italian ham. Wraps around melon."),
		MarketProduct.new("turkey_breast","Turkey Breast 200g",  5.50, Color(0.95, 0.82, 0.72), 3, "meat", "Deli",        "Lean deli turkey. Low-fat protein option."),
		MarketProduct.new("beef_roastbeef","Roast Beef 200g",    6.00, Color(0.72, 0.32, 0.28), 3, "meat", "Deli",        "Thinly sliced roast beef. Classic deli flavor."),
		MarketProduct.new("lamb_chop",    "Lamb Chops 300g",     9.00, Color(0.75, 0.42, 0.42), 3, "meat", "Lamb",        "New Zealand lamb chops. Herb-crusted."),
		MarketProduct.new("duck_breast",  "Duck Breast 350g",     8.50, Color(0.80, 0.42, 0.42), 3, "meat", "Poultry",     "Rich and fatty duck breast. Sear until crispy."),

		# ═══════════════════ PANTRY ═══════════════════
		MarketProduct.new("rice_jasmine", "Jasmine Rice 1kg",    3.50, Color(0.95, 0.95, 0.88), 3, "pantry", "Rice",        "Fragrant Thai jasmine rice. Fluffy when cooked."),
		MarketProduct.new("rice_basmati", "Basmati Rice 1kg",    3.80, Color(0.92, 0.90, 0.80), 3, "pantry", "Rice",        "Long-grain Indian rice. Dry and fluffy."),
		MarketProduct.new("rice_brown",   "Brown Rice 1kg",      4.00, Color(0.72, 0.58, 0.38), 3, "pantry", "Rice",        "Whole grain rice. Nutty and chewy."),
		MarketProduct.new("pasta_spaghetti","Spaghetti 500g",    1.80, Color(0.95, 0.88, 0.62), 3, "pantry", "Pasta",       "Classic spaghetti. The Italian staple."),
		MarketProduct.new("pasta_penne", "Penne 500g",          1.80, Color(0.95, 0.88, 0.62), 3, "pantry", "Pasta",       "Tube pasta. Holds sauce beautifully."),
		MarketProduct.new("pasta_fusilli","Fusilli 500g",         1.80, Color(0.95, 0.88, 0.62), 3, "pantry", "Pasta",       "Spiral pasta. Sauce clings to every twist."),
		MarketProduct.new("pasta_lasagna","Lasagna Sheets 500g", 2.20, Color(0.95, 0.90, 0.72), 3, "pantry", "Pasta",       "Flat pasta sheets. Layer with rag\u00f9 and b\u00e9chamel."),
		MarketProduct.new("noodles_instant","Instant Noodles 5pk",2.50, Color(0.88, 0.72, 0.42), 5, "pantry", "Pasta",       "Quick-cook ramen. Cup or bowl, 3 minutes."),
		MarketProduct.new("flour_white",  "White Flour 1kg",     1.80, Color(0.95, 0.95, 0.92), 3, "pantry", "Baking",      "All-purpose white flour. Foundation of baking."),
		MarketProduct.new("flour_whole",  "Whole Wheat Flour 1kg",2.20, Color(0.72, 0.58, 0.38), 3, "pantry", "Baking",      "Fiber-rich wholemeal flour. Nutty and dense."),
		MarketProduct.new("sugar_white",  "White Sugar 1kg",     2.00, Color(0.95, 0.95, 0.95), 3, "pantry", "Baking",      "Refined white sugar. Essential sweetener."),
		MarketProduct.new("sugar_brown",  "Brown Sugar 500g",     2.20, Color(0.72, 0.52, 0.32), 3, "pantry", "Baking",      "Moist brown sugar. Caramelizes beautifully."),
		MarketProduct.new("cocoa_powder", "Cocoa Powder 200g",   3.50, Color(0.35, 0.22, 0.15), 3, "pantry", "Baking",      "Unsweetened cocoa. Rich chocolate flavor."),
		MarketProduct.new("oil_olive",    "Extra Virgin Olive Oil 500ml",6.50, Color(0.72, 0.88, 0.48), 5, "pantry", "Oil",        "Cold-pressed EVOO. The gold of the kitchen."),
		MarketProduct.new("oil_vegetable","Vegetable Oil 1L",     2.50, Color(0.88, 0.88, 0.42), 5, "pantry", "Oil",         "Neutral cooking oil. High smoke point."),
		MarketProduct.new("oil_coconut",  "Coconut Oil 300ml",    4.50, Color(0.95, 0.95, 0.88), 5, "pantry", "Oil",         "Solid at room temp. Great for baking and curry."),
		MarketProduct.new("ketchup",      "Tomato Ketchup 500g", 2.50, Color(0.88, 0.18, 0.18), 5, "pantry", "Condiments",  "Classic tomato ketchup. Fries' best friend."),
		MarketProduct.new("mustard_yellow","Yellow Mustard 300g",2.00, Color(0.98, 0.88, 0.28), 5, "pantry", "Condiments",  "Sharp and tangy. Hot dog essential."),
		MarketProduct.new("mayo",         "Mayonnaise 400g",     3.50, Color(0.98, 0.95, 0.88), 5, "pantry", "Condiments",  "Creamy mayo. Sandwich base and aioli foundation."),
		MarketProduct.new("bbq_sauce",    "BBQ Sauce 400ml",     3.20, Color(0.42, 0.25, 0.15), 5, "pantry", "Condiments",  "Smoky sweet BBQ. Brush on ribs or dip chicken."),
		MarketProduct.new("soy_sauce",    "Soy Sauce 300ml",     2.50, Color(0.28, 0.18, 0.12), 5, "pantry", "Condiments",  "Fermented soybean sauce. Umami in a bottle."),
		MarketProduct.new("hot_sauce",    "Hot Sauce 150ml",     3.80, Color(0.80, 0.18, 0.18), 5, "pantry", "Condiments",  "Louisiana-style hot sauce. Add heat to everything."),
		MarketProduct.new("honey",         "Honey 500g",          5.50, Color(0.95, 0.78, 0.28), 5, "pantry", "Condiments",  "Pure wildflower honey. Natural sweetener."),
		MarketProduct.new("maple_syrup",  "Maple Syrup 250ml",   7.50, Color(0.78, 0.48, 0.18), 5, "pantry", "Condiments",  "Real Canadian maple syrup. Worth every penny."),
		MarketProduct.new("cereal_corn",   "Corn Flakes 500g",    3.50, Color(0.98, 0.90, 0.42), 3, "pantry", "Breakfast",   "Crunchy corn cereal. Milk turns it into breakfast."),
		MarketProduct.new("cereal_oat",   "Oat Granola 600g",    4.50, Color(0.75, 0.58, 0.38), 3, "pantry", "Breakfast",   "Clusters and oats. Yogurt's perfect companion."),
		MarketProduct.new("cereal_choco",  "Chocolate cereal 400g",3.20, Color(0.42, 0.28, 0.18), 3, "pantry", "Breakfast",   "Chocolate-flavored sweetened cereal. Kids love it."),
		MarketProduct.new("oats_rolled",  "Rolled Oats 1kg",     2.80, Color(0.82, 0.68, 0.52), 3, "pantry", "Breakfast",   "Old-fashioned oats. Overnight oats or porridge."),
		MarketProduct.new("jam_straw",    "Strawberry Jam 350g", 3.50, Color(0.92, 0.22, 0.30), 4, "pantry", "Condiments",  "Sweet strawberry preserve. On toast or PB&J."),
		MarketProduct.new("peanut_butter","Peanut Butter 500g", 4.50, Color(0.78, 0.52, 0.28), 4, "pantry", "Condiments",  "Creamy peanut butter. No sugar added."),
		MarketProduct.new("almond_butter","Almond Butter 300g", 7.50, Color(0.75, 0.58, 0.38), 4, "pantry", "Condiments",  "Smooth almond butter. Nutty and luxurious."),
		MarketProduct.new("beans_kidney", "Kidney Beans 400g",   1.50, Color(0.72, 0.28, 0.28), 3, "pantry", "Canned",      "Canned red kidney beans. Chili base ingredient."),
		MarketProduct.new("beans_baked",  "Baked Beans 400g",    1.50, Color(0.65, 0.42, 0.28), 3, "pantry", "Canned",      "Tomato sauce baked beans. Classic breakfast side."),
		MarketProduct.new("tomatoes_crush","Crushed Tomatoes 400g",1.80, Color(0.88, 0.18, 0.18), 3, "pantry", "Canned",      "Italian crushed tomatoes. Pizza sauce base."),
		MarketProduct.new("tuna_canned",  "Tuna in Brine 150g",  2.00, Color(0.85, 0.82, 0.78), 3, "pantry", "Canned",      "Canned skipjack tuna. Protein in a can."),
		MarketProduct.new("corn_canned",  "Sweet Corn 400g",      1.50, Color(0.98, 0.92, 0.40), 3, "pantry", "Canned",      "Sweet whole kernel corn. Quick side dish."),
		MarketProduct.new("soup_chicken", "Chicken Noodle Soup", 2.20, Color(0.95, 0.85, 0.52), 5, "pantry", "Soup",        "Comfort in a can. Chicken noodle classic."),
		MarketProduct.new("soup_tomato",  "Tomato Soup",          2.20, Color(0.92, 0.28, 0.22), 5, "pantry", "Soup",        "Creamy tomato soup. Pairs with grilled cheese."),
		MarketProduct.new("soup_mushroom","Cream of Mushroom",   2.20, Color(0.82, 0.72, 0.60), 5, "pantry", "Soup",        "Rich creamy mushroom soup. Use as a sauce base."),
		MarketProduct.new("soup_beef",    "Beef & Vegetable Soup",2.50, Color(0.72, 0.42, 0.32), 5, "pantry", "Soup",        "Hearty beef and veg. Warming and filling."),

		# ═══════════════════ FROZEN ═══════════════════
		MarketProduct.new("icecream_van", "Vanilla Ice Cream 500ml",4.50, Color(0.98, 0.95, 0.88), 4, "frozen", "Ice Cream",  "Classic French vanilla. The base for everything."),
		MarketProduct.new("icecream_choc","Chocolate Ice Cream 500ml",4.50, Color(0.35, 0.22, 0.15), 4, "frozen", "Ice Cream",  "Rich Belgian chocolate ice cream."),
		MarketProduct.new("icecream_straw","Strawberry Ice Cream 500ml",4.50, Color(0.92, 0.60, 0.68), 4, "frozen", "Ice Cream",  "Sweet strawberry with real fruit swirl."),
		MarketProduct.new("icecream_mint","Mint Choc Chip 500ml",    4.80, Color(0.55, 0.88, 0.65), 4, "frozen", "Ice Cream",  "Cool mint with dark chocolate chips."),
		MarketProduct.new("icecream_cookies","Cookie Dough 500ml",  4.80, Color(0.85, 0.68, 0.42), 4, "frozen", "Ice Cream",  "Edible cookie dough chunks in vanilla ice cream."),
		MarketProduct.new("frozen_pizza", "Margherita Pizza 400g",  5.50, Color(0.92, 0.22, 0.22), 3, "frozen", "Meals",      "Wood-fired style frozen pizza. Crisp base."),
		MarketProduct.new("frozen_pepperoni","Pepperoni Pizza 400g",5.50, Color(0.80, 0.28, 0.18), 3, "frozen", "Meals",      "Loaded pepperoni pizza. Movie night winner."),
		MarketProduct.new("frozen_burger","Beef Burgers 2pk",       5.00, Color(0.72, 0.42, 0.28), 3, "frozen", "Meals",      "Pre-formed beef patties. Grill straight from frozen."),
		MarketProduct.new("frozen_chicken","Chicken Nuggets 400g",   4.50, Color(0.95, 0.78, 0.52), 3, "frozen", "Meals",      "Crispy breaded nuggets. Air fry for best results."),
		MarketProduct.new("frozen_fries", "Chips 1kg",               2.80, Color(0.98, 0.90, 0.42), 3, "frozen", "Meals",      "Shoestring fries. Golden and crispy."),
		MarketProduct.new("frozen_waffles","Waffles 10pk",           3.50, Color(0.92, 0.82, 0.55), 3, "frozen", "Breakfast",  "Homestyle frozen waffles. Toast and serve."),
		MarketProduct.new("frozen_broccoli","Frozen Broccoli 500g", 2.20, Color(0.28, 0.62, 0.30), 0, "frozen", "Vegetables", "Flash-frozen florets. Nutritious and convenient."),
		MarketProduct.new("frozen_peas",  "Frozen Peas 500g",       1.80, Color(0.42, 0.72, 0.32), 0, "frozen", "Vegetables", "Garden peas frozen at peak freshness."),
		MarketProduct.new("frozen_corn",  "Frozen Sweet Corn 500g",  1.80, Color(0.98, 0.92, 0.40), 0, "frozen", "Vegetables", "Sweet corn kernels. Quick side or salad addition."),
		MarketProduct.new("frozen_spinach","Frozen Spinach 300g",   2.00, Color(0.28, 0.58, 0.28), 0, "frozen", "Vegetables", "Pre-chopped spinach. Cooks down to almost nothing."),
		MarketProduct.new("fish_fingers", "Fish Fingers 12pk",      4.50, Color(0.92, 0.90, 0.72), 3, "frozen", "Fish",       "Breaded fish rectangles. Child-approved."),
		MarketProduct.new("frozen_shrimp","Cooked Shrimp 300g",     8.00, Color(0.98, 0.72, 0.60), 0, "frozen", "Fish",       "Pre-cooked peeled shrimp. Thaw and serve."),
		MarketProduct.new("ice_pop",      "Fruit Ice Pops 6pk",     3.00, Color(0.50, 0.88, 0.60), 5, "frozen", "Ice Cream",  "Colorful frozen fruit juice bars. Refreshing."),
		MarketProduct.new("frozen_dumpling","Dumplings 20pk",       6.00, Color(0.92, 0.88, 0.72), 0, "frozen", "Meals",      "Steamed or pan-fried dumplings. Quick meal."),
		MarketProduct.new("frozen_rice",  "Frozen Fried Rice 600g", 4.00, Color(0.95, 0.88, 0.55), 3, "frozen", "Meals",      "Fully cooked fried rice. Microwave in 4 mins."),
		MarketProduct.new("frozen_bread", "Frozen Garlic Bread 300g",2.80, Color(0.88, 0.72, 0.45), 3, "frozen", "Meals",      "Slice and bake garlic bread. Pizza combo."),

		# ═══════════════════ PET SUPPLIES ═══════════════════
		# Dog Food
		MarketProduct.new("dog_food_adult",  "Dog Food Adult 3kg",    18.00, Color(0.72, 0.42, 0.22), 3, "pet", "Dog Food",    "Complete nutrition for adult dogs. All breeds."),
		MarketProduct.new("dog_food_puppy",  "Dog Food Puppy 2kg",    16.50, Color(0.55, 0.35, 0.20), 3, "pet", "Dog Food",    "Growth formula for puppies up to 12 months."),
		MarketProduct.new("dog_food_senior", "Dog Food Senior 3kg",   19.00, Color(0.65, 0.45, 0.30), 3, "pet", "Dog Food",    "Light formula for senior dogs 7+ years."),
		MarketProduct.new("dog_treats",      "Training Treats 200g",   5.50, Color(0.88, 0.62, 0.32), 0, "pet", "Dog Food",    "Small bite-sized rewards. No artificial colours."),
		MarketProduct.new("dog_chews",       "Dental Chews 12pk",       7.00, Color(0.92, 0.80, 0.55), 0, "pet", "Dog Food",    "Helps reduce tartar. Veterinarian approved."),
		MarketProduct.new("dog_wet_food",    "Wet Dog Food 12x400g",   14.00, Color(0.62, 0.38, 0.25), 3, "pet", "Dog Food",    "Grain-free wet food. Cuts in jelly."),
		# Cat Food
		MarketProduct.new("cat_food_adult",  "Cat Food Adult 2kg",    14.00, Color(0.55, 0.55, 0.70), 3, "pet", "Cat Food",    "Complete dry food for adult cats. Hairball control."),
		MarketProduct.new("cat_food_kitten", "Cat Food Kitten 1.5kg", 13.00, Color(0.48, 0.48, 0.62), 3, "pet", "Cat Food",    "High-protein formula for growing kittens."),
		MarketProduct.new("cat_wet_food",   "Wet Cat Food 24x85g",    12.00, Color(0.50, 0.48, 0.60), 3, "pet", "Cat Food",    "Mixed flavours — tuna, chicken, salmon."),
		MarketProduct.new("cat_treats",      "Cat Treats 60g",         4.50, Color(0.72, 0.55, 0.72), 0, "pet", "Cat Food",    "Crunchy seaweed and chicken flavoured treats."),
		MarketProduct.new("cat_litter",      "Clumping Cat Litter 5L",  8.50, Color(0.80, 0.78, 0.72), 0, "pet", "Cat Food",    "Easy-scoop clumping litter. Odour control."),
		# Bird & Small Animal
		MarketProduct.new("bird_seed",       "Bird Seed Mix 1kg",       6.00, Color(0.92, 0.82, 0.45), 0, "pet", "Bird Food",   "Sunflower, millet, and cracked corn mix."),
		MarketProduct.new("bird_toy",        "Swinging Perch Toy",       5.00, Color(0.55, 0.80, 0.45), 0, "pet", "Bird Food",   "Natural wood perch with bell. For parakeets."),
		MarketProduct.new("hamster_food",   "Hamster Mix 500g",        4.00, Color(0.85, 0.68, 0.42), 0, "pet", "Small Pet",   "Complete hamster food with seeds and grains."),
		MarketProduct.new("guinea_pig_food","Guinea Pig Food 1kg",     6.50, Color(0.58, 0.78, 0.48), 0, "pet", "Small Pet",   "With added Vitamin C. Timothy hay based."),
		MarketProduct.new("rabbit_food",    "Rabbit Food 1kg",         6.00, Color(0.62, 0.68, 0.55), 0, "pet", "Small Pet",   "High-fiber complete food for adult rabbits."),
		MarketProduct.new("fish_food_flake","Fish Flakes 250ml",       5.50, Color(0.88, 0.55, 0.30), 0, "pet", "Fish Food",   "Complete flakes for tropical freshwater fish."),
		MarketProduct.new("fish_food_pellet","Fish Pellets 500ml",     7.00, Color(0.30, 0.58, 0.80), 0, "pet", "Fish Food",   "Sinking pellets for goldfish and cichlids."),
		# Pet Toys & Accessories
		MarketProduct.new("dog_ball",         "Tennis Ball 2pk",         4.00, Color(0.88, 0.88, 0.20), 0, "pet", "Pet Toys",     "Bright yellow tennis balls. Bounce-friendly."),
		MarketProduct.new("dog_rope_toy",   "Rope Tug Toy",            6.50, Color(0.45, 0.68, 0.85), 0, "pet", "Pet Toys",     "Cotton rope. Great for tug-of-war."),
		MarketProduct.new("dog_leash",       "Nylon Dog Leash 1.5m",    9.00, Color(0.22, 0.22, 0.45), 0, "pet", "Pet Toys",     "Adjustable nylon leash. Reflective stitching."),
		MarketProduct.new("dog_collar",      "Dog Collar Medium",       7.50, Color(0.60, 0.30, 0.30), 0, "pet", "Pet Toys",     "Padded neoprene collar. Quick-release buckle."),
		MarketProduct.new("cat_brush",       "Cat Grooming Brush",      8.00, Color(0.80, 0.80, 0.88), 0, "pet", "Pet Toys",     "Self-cleaning slicker brush. Reduces shedding."),
		MarketProduct.new("cat_tree",        "Cat Tree Tower",          45.00, Color(0.65, 0.48, 0.32), 3, "pet", "Pet Toys",     "Multi-level cat tree with scratching posts."),
		MarketProduct.new("pet_bed_small",  "Pet Bed Small 50cm",     22.00, Color(0.52, 0.52, 0.62), 3, "pet", "Pet Toys",     "Machine-washable fleece bed. Non-slip base."),
		MarketProduct.new("pet_bed_large",  "Pet Bed Large 80cm",     35.00, Color(0.48, 0.48, 0.58), 3, "pet", "Pet Toys",     "Orthopedic memory foam bed for large dogs."),
		MarketProduct.new("pet_carrier",    "Pet Carrier Medium",      28.00, Color(0.40, 0.48, 0.62), 3, "pet", "Pet Toys",     "Airline-approved. Ventilated sides."),
		MarketProduct.new("aquarium_small", "Desktop Aquarium 10L",   38.00, Color(0.20, 0.65, 0.80), 3, "pet", "Pet Toys",     "Complete starter kit with LED light and filter."),
		MarketProduct.new("fish_tank_20g",  "Fish Tank 20 Gallon",    55.00, Color(0.18, 0.58, 0.72), 3, "pet", "Pet Toys",     "Rectangular glass tank. Filter not included."),
		MarketProduct.new("water_bottle_pet","Water Bottle 500ml",     6.00, Color(0.40, 0.75, 0.90), 0, "pet", "Pet Toys",     "Portable water bottle with attached bowl. For dogs."),
		MarketProduct.new("pet_food_bin",   "Pet Food Storage Bin",   12.00, Color(0.55, 0.48, 0.38), 3, "pet", "Pet Toys",     "Airtight container. Keeps food fresh. 10kg cap."),
		MarketProduct.new("pet_wipes",      "Pet Grooming Wipes 100ct", 7.50, Color(0.72, 0.82, 0.90), 0, "pet", "Pet Toys",     "Fragrance-free grooming wipes. Safe for paws."),
		MarketProduct.new("poop_bags",      "Poop Bags 120ct",          5.00, Color(0.60, 0.52, 0.48), 0, "pet", "Pet Toys",     "Biodegradable waste bags with dispenser."),
	]

static func get_section_def(sid: String) -> SectionDef:
	for s in SECTIONS:
		if s.id == sid:
			return s
	return null

static func get_products_in_section(sid: String) -> Array:
	var result = []
	for p in CATALOG:
		if p.section == sid:
			result.append(p)
	return result

static func get_subcategories(sid: String) -> Array:
	var subs = {}
	for p in CATALOG:
		if p.section == sid:
			subs[p.sub] = true
	var keys = []
	for k in subs:
		keys.append(k)
	keys.sort()
	return keys

static func filter_by_subcategory(sid: String, sub: String) -> Array:
	var result = []
	for p in CATALOG:
		if p.section == sid and p.sub == sub:
			result.append(p)
	return result
