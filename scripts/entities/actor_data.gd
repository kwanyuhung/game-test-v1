# actor_data.gd
# ═══════════════════════════════════════════════════════════════════════
# Actor / Person data — all characters (player + AI) share this structure.
#
# EXTENDING: To add a new role/status, just add to the enums and the
# relevant switch statements in NPCController.
# ═══════════════════════════════════════════════════════════════════════

# ─── Role ─────────────────────────────────────────────────────────
enum Role {
	CUSTOMER,       # Shopping at the supermarket
	STAFF,          # Working in the store
	ROBOT,          # AI robot staff member
}

# ─── Staff Roles (when Role == STAFF) ─────────────────────────
enum StaffRole {
	NONE,
	CASHIER,        # Operates checkout lanes
	SHELF_STOCKER,  # Restocks shelves
	CLEANER,        # Keeps the store tidy
	SECURITY,       # Patrols the store
	GREETER,        # Welcomes customers at entrance
	MANAGER,        # Walks the floor supervising
	FLOOR_STAFF,    # General floor assistance
	SCAN_GO,        # Scan & Go staff — walks alongside player, auto-scans items
	# ─── Extended roles for supermarket ───────────────────────────────────────
	SHOP_STAFF,     # General shop floor sales staff
	FOOD_STAFF,     # Food service / cafe staff
	CLEAN_STAFF,    # Cleaning staff (distict from CLEANER which auto-cleans)
	RECEPTIONIST,   # Info desk / customer service desk
	MAINTENANCE_STAFF, # Equipment / facility maintenance
	DELIVERY_STAFF, # Warehouse / delivery staff
}

# ─── Robot Type ────────────────────────────────────────────────
# Robots can be HUMANOID (look like humans, use tools, communicate)
# or SINGLE_FUNCTION (specialized machine for one task)
enum RobotType {
	HUMANOID,        # Looks like a person, uses tools, talks, does any job
	SINGLE_FUNCTION # Automated machine — cleaning, guiding, delivery, etc.
}

# ─── Robot Role (for SINGLE_FUNCTION robots) ────────────────────
enum RobotRole {
	CLEANING_ROBOT,  # Auto-cleans floors, battery-powered
	GUIDANCE_ROBOT,  # Directs customers, answers questions
	DELIVERY_ROBOT,  # Transports stock between zones
	SECURITY_ROBOT,  # Patrols and monitors
	SHELF_ROBOT,     # Auto-restock scanning
}

# ─── Customer Group Type ────────────────────────────────────────
enum CustomerGroupType {
	SOLO,           # Single shopper
	COUPLE,         # Two adults, shopping together
	PAIR,           # Two friends shopping
	TWO_COUPLES,    # Four adults (two pairs)
	FAMILY_BABY,    # Two adults + infant in cart
	FAMILY_TODDLER, # Two adults + toddler
	FAMILY_KIDS,    # Two adults + two children
	FAMILY_EXTENDED, # 2 adults + 2 kids + grandparent
	THREE_FRIENDS  # Three friends shopping together
}

# ─── Life Stage ────────────────────────────────────────────────
enum LifeStage {
	ADULT,          # 18-64
	ADULT_MID,     # 35-60 (sub-category)
	SENIOR,         # 60+ (includes 60-65+)
	TEEN,           # 13-19
	CHILD,          # 6-12
	TODDLER,        # 1-5
	INFANT,         # 0-1 (in baby cart)
}

# ─── Appearance ────────────────────────────────────────────────
class Appearance:
	static var SKINS: Array[Color] = [
		Color(0.96, 0.80, 0.65),
		Color(0.88, 0.68, 0.48),
		Color(0.72, 0.52, 0.38),
		Color(0.55, 0.38, 0.28),
		Color(0.42, 0.30, 0.22),
	]
	static var HAIR_COLORS: Array[Color] = [
		Color(0.18, 0.12, 0.08),
		Color(0.62, 0.42, 0.22),
		Color(0.92, 0.72, 0.35),
		Color(0.78, 0.32, 0.18),
		Color(0.28, 0.22, 0.18),
		Color(0.10, 0.10, 0.10),
	]
	var skin_tone: Color
	var hair_color: Color
	var hair_style: int       # 0=bob, 1=long, 2=short+neat, 3=bald/buzz
	var has_glasses: bool
	var makeup_intensity: int  # 0=none, 1=light, 2=full
	var accessory: int        # 0=none, 1=bag, 2=backpack, 3=handbag
	var shoes_color: Color
	var shoes_style: int     # 0=sneakers, 1=formal, 2=sandals, 3=boots
	var top_color: Color
	var bottom_color: Color
	var top_style: int       # 0=t-shirt, 1=shirt, 2=sweater, 3=jacket, 4=tank
	var bottom_style: int    # 0=pants, 1=skirt, 2=shorts, 3=dress

	func _init() -> void:
		skin_tone = Color(0.88, 0.68, 0.48)
		hair_color = Color(0.18, 0.12, 0.08)
		hair_style = 0
		has_glasses = false
		makeup_intensity = 0
		accessory = 0
		shoes_color = Color(0.18, 0.18, 0.18)
		shoes_style = 0
		top_color = Color(0.28, 0.42, 0.78)
		bottom_color = Color(0.22, 0.22, 0.42)
		top_style = 0
		bottom_style = 0

	static func random() -> Appearance:
		var a := Appearance.new()
		var skins := [
			Color(0.96, 0.80, 0.65),
			Color(0.88, 0.68, 0.48),
			Color(0.72, 0.52, 0.38),
			Color(0.55, 0.38, 0.28),
			Color(0.42, 0.30, 0.22),
		]
		var hairs := [
			Color(0.18, 0.12, 0.08),
			Color(0.62, 0.42, 0.22),
			Color(0.92, 0.72, 0.35),
			Color(0.78, 0.32, 0.18),
			Color(0.28, 0.22, 0.18),
			Color(0.10, 0.10, 0.10),
		]
		var tops := [
			Color(0.28, 0.42, 0.78),
			Color(0.78, 0.28, 0.28),
			Color(0.28, 0.68, 0.42),
			Color(0.88, 0.68, 0.28),
			Color(0.68, 0.28, 0.68),
			Color(0.82, 0.82, 0.82),
			Color(0.42, 0.42, 0.48),
			Color(0.82, 0.58, 0.28),
			Color(0.28, 0.62, 0.78),
			Color(0.88, 0.38, 0.28),
		]
		var bottoms := [
			Color(0.22, 0.22, 0.42),
			Color(0.42, 0.38, 0.32),
			Color(0.32, 0.38, 0.52),
			Color(0.22, 0.32, 0.22),
			Color(0.18, 0.18, 0.18),
			Color(0.58, 0.52, 0.45),
			Color(0.82, 0.28, 0.18),
			Color(0.38, 0.38, 0.55),
		]
		var shoes := [
			Color(0.18, 0.18, 0.18),
			Color(0.42, 0.35, 0.28),
			Color(0.75, 0.70, 0.65),
			Color(0.28, 0.18, 0.12),
		]
		a.skin_tone = skins[randi() % skins.size()]
		a.hair_color = hairs[randi() % hairs.size()]
		a.hair_style = randi() % 4
		a.has_glasses = (randi() % 4 == 0)
		a.makeup_intensity = randi() % 3
		a.accessory = randi() % 4
		a.shoes_color = shoes[randi() % shoes.size()]
		a.shoes_style = randi() % 4
		a.top_color = tops[randi() % tops.size()]
		a.bottom_color = bottoms[randi() % bottoms.size()]
		a.top_style = randi() % 5
		a.bottom_style = randi() % 4
		return a

# ─── Baby / Child Data ──────────────────────────────────────────
class ChildData:
	var age: int          # 0=infant, 1-5=toddler, 6-12=child
	var gender: int       # 0=boy, 1=girl, 2=neutral
	var skin_tone: Color
	var hair_color: Color
	var hair_style: int   # 0=short, 1=bob, 2=ponytail, 3=spiky
	var accessory: int    # 0=none, 1=pacifier, 2=hat, 3=bow
	var outfit_color: Color
	var cart_color: Color  # stroller/cart color

	func _init() -> void:
		skin_tone = Color(0.88, 0.68, 0.48)
		hair_color = Color(0.18, 0.12, 0.08)
		hair_style = 0
		accessory = 0
		outfit_color = Color(0.78, 0.28, 0.28)
		cart_color = Color(0.60, 0.60, 0.68)

	static func random_infant() -> ChildData:
		var c := ChildData.new()
		var skins := [
			Color(0.96, 0.80, 0.65),
			Color(0.88, 0.68, 0.48),
			Color(0.72, 0.52, 0.38),
			Color(0.55, 0.38, 0.28),
		]
		var hairs := [
			Color(0.18, 0.12, 0.08),
			Color(0.62, 0.42, 0.22),
			Color(0.28, 0.22, 0.18),
			Color(0.08, 0.08, 0.08),
		]
		var outfits := [
			Color(0.78, 0.28, 0.28),
			Color(0.28, 0.42, 0.78),
			Color(0.78, 0.68, 0.28),
			Color(0.68, 0.78, 0.38),
			Color(0.88, 0.58, 0.78),
		]
		c.skin_tone = skins[randi() % skins.size()]
		c.hair_color = hairs[randi() % hairs.size()]
		c.hair_style = randi() % 3
		c.accessory = randi() % 3
		c.outfit_color = outfits[randi() % outfits.size()]
		c.cart_color = [Color(0.60, 0.60, 0.68), Color(0.75, 0.75, 0.80), Color(0.45, 0.45, 0.55)][randi() % 3]
		return c

	static func random_toddler() -> ChildData:
		var c := random_infant()
		c.age = (randi() % 5) + 1
		return c

# ─── Staff Task ────────────────────────────────────────────────
class StaffTask:
	var task_name: String
	var floor_target: int     # Which floor (-1 = any)
	var zone_x: int
	var zone_y: int
	var urgency: int         # 0=low, 1=normal, 2=high
	var done: bool

	func _init(name: String, p_floor: int, p_x: int, p_y: int, p_urgency: int = 1) -> void:
		task_name = name; floor_target = p_floor
		zone_x = p_x; zone_y = p_y; urgency = p_urgency; done = false

# ─── Full Actor Definition ─────────────────────────────────────
class Actor:
	 # 添加速度常量
	const SPEED_ADULT: float = 60.0
	const SPEED_SENIOR: float = 40.0
	const SPEED_TEEN: float = 55.0
	const SPEED_CHILD: float = 45.0
	var id: String
	var role: Role
	var staff_role: StaffRole
	var robot_type: RobotType       # HUMANOID or SINGLE_FUNCTION (only when role==ROBOT)
	var robot_role: RobotRole        # specific role for SINGLE_FUNCTION robots
	var life_stage: LifeStage
	var appearance: Appearance
	var group_type: CustomerGroupType
	var display_name: String
	var child: ChildData          # null if no child
	var cart_item_count: int
	var energy: float             # 0..1
	var hunger: float            # 0..1 (0=full, 1=starving)
	var happiness: float          # 0..1
	var shopping_list: Array      # [{section_id, qty, fulfilled}] the customer's plan
	var has_cart: bool            # true once they've picked up a cart
	var current_floor: int
	var current_task: StaffTask  # null if no task
	var target_floor: int
	var is_active: bool
	var group_members: Array = []

	func _init() -> void:
		role = Role.CUSTOMER
		has_cart = false
		life_stage = LifeStage.ADULT
		appearance = Appearance.new()
		group_type = CustomerGroupType.SOLO
		display_name = "Shopper"
		child = null
		cart_item_count = 0
		energy = 1.0
		hunger = 0.0
		happiness = 0.8
		shopping_list = []
		has_cart = false
		current_floor = 0
		target_floor = 0
		is_active = true

	static func new_test_customer() -> Actor:
		var a := Actor.new()
		a.role = Role.CUSTOMER
		a.group_type = CustomerGroupType.SOLO
		a.appearance = Appearance.random()
		a.energy = 0.8
		a.hunger = 0.3
		a.happiness = 0.7
		a.cart_item_count = 3
		a.life_stage = LifeStage.ADULT
		a.display_name = "Test Customer"
		a._generate_shopping_list()
		return a
		
	static func new_test_staff() -> Actor:
		var a := Actor.new()
		a.role = Role.STAFF
		a.staff_role = StaffRole.FLOOR_STAFF
		a.appearance = Appearance.random()
		a.energy = 0.9
		a.hunger = 0.2
		a.happiness = 0.8
		a.current_floor = 0
		a.display_name = "Test Staff"
		return a

	static func random_customer(p_group: CustomerGroupType = CustomerGroupType.SOLO) -> Actor:
		var a := Actor.new()
		a.role = Role.CUSTOMER
		a.group_type = p_group
		a.appearance = Appearance.random()
		a.energy = randf_range(0.5, 1.0)
		a.hunger = randf_range(0.0, 0.5)
		a.happiness = randf_range(0.6, 1.0)
		a.cart_item_count = randi() % 10

		# Life stage based on group type and random chance
		match p_group:
			CustomerGroupType.FAMILY_BABY:
				a.life_stage = LifeStage.ADULT
			CustomerGroupType.FAMILY_TODDLER:
				a.life_stage = LifeStage.ADULT
			CustomerGroupType.FAMILY_KIDS:
				a.life_stage = LifeStage.ADULT
			CustomerGroupType.FAMILY_EXTENDED:
				a.life_stage = LifeStage.ADULT
			_:
				var roll := randi() % 100
				if roll < 3:
					a.life_stage = LifeStage.TEEN
				elif roll < 15:
					a.life_stage = LifeStage.SENIOR
				else:
					a.life_stage = LifeStage.ADULT

		# Generate a random name
		var first_names := ["Alex", "Jordan", "Sam", "Morgan", "Taylor", "Casey", "Riley", "Quinn", "Avery", "Blake", "Drew", "Reese", "Finley", "Sage", "River"]
		a.display_name = first_names[randi() % first_names.size()]

		# Generate shopping list
		a._generate_shopping_list()
		return a

	func _generate_shopping_list() -> void:
		var sections := ["produce", "dairy", "bakery", "meat", "pantry", "snacks", "frozen", "drinks", "beauty", "pet"]
		var item_count := randi() % 5 + 2  # 2-6 items
		shopping_list.clear()
		for i in range(item_count):
			var sec: String = sections[randi() % sections.size()]
			# Avoid duplicate sections
			var existing := shopping_list.filter(func(x): return x.get("section_id") == sec)
			if existing.is_empty():
				shopping_list.append({"section_id": sec, "qty": randi() % 3 + 1, "fulfilled": 0})

	static func random_staff(p_role: StaffRole) -> Actor:
		var a := Actor.new()
		a.role = Role.STAFF
		a.staff_role = p_role
		a.appearance = Appearance.random()
		a.energy = randf_range(0.7, 1.0)
		a.hunger = randf_range(0.0, 0.3)
		a.happiness = randf_range(0.5, 0.9)
		a.current_floor = 0

		var first_names := ["Emma", "Liam", "Olivia", "Noah", "Ava", "James", "Sophia", "Oliver", "Isabella", "Elijah", "Mia", "Lucas", "Charlotte", "Mason"]
		var last_initials := ["A", "B", "C", "D", "K", "L", "M", "N", "P", "R", "S", "T", "W", "Y"]
		a.display_name = first_names[randi() % first_names.size()] + " " + last_initials[randi() % last_initials.size()] + "."

		match p_role:
			StaffRole.CASHIER:
				a.appearance.top_color = Color(0.18, 0.35, 0.65)
				a.appearance.bottom_color = Color(0.22, 0.22, 0.38)
			StaffRole.SHELF_STOCKER:
				a.appearance.top_color = Color(0.28, 0.28, 0.28)
				a.appearance.bottom_color = Color(0.38, 0.38, 0.38)
			StaffRole.CLEANER:
				a.appearance.top_color = Color(0.22, 0.52, 0.38)
				a.appearance.bottom_color = Color(0.32, 0.32, 0.42)
			StaffRole.SECURITY:
				a.appearance.top_color = Color(0.12, 0.12, 0.16)
				a.appearance.bottom_color = Color(0.18, 0.18, 0.24)
			StaffRole.GREETER:
				a.appearance.top_color = Color(0.78, 0.28, 0.28)
				a.appearance.bottom_color = Color(0.22, 0.22, 0.42)
			StaffRole.MANAGER:
				a.appearance.top_color = Color(0.18, 0.18, 0.28)
				a.appearance.bottom_color = Color(0.32, 0.28, 0.22)
				a.appearance.top_style = 1  # shirt
				a.appearance.has_glasses = true
			StaffRole.FLOOR_STAFF:
				a.appearance.top_color = Color(0.42, 0.42, 0.48)
				a.appearance.bottom_color = Color(0.22, 0.22, 0.42)
			StaffRole.SCAN_GO:
				a.appearance.top_color = Color(0.20, 0.62, 0.82)
				a.appearance.bottom_color = Color(0.22, 0.28, 0.48)

		return a

	static func random_robot(rtype: RobotType, rrole: RobotRole = RobotRole.CLEANING_ROBOT) -> Actor:
		var a := Actor.new()
		a.role = Role.ROBOT
		a.robot_type = rtype
		a.robot_role = rrole
		a.energy = 1.0
		a.happiness = 1.0
		a.current_floor = 0

		# Humanoid robots look like humans with subtle robot features
		if rtype == RobotType.HUMANOID:
			a.appearance = Appearance.random()
			# Give humanoid robot a synthetic skin tone and robot uniform
			a.appearance.skin_tone = Color(0.82, 0.84, 0.88)  # slightly metallic skin
			match rrole:
				RobotRole.CLEANING_ROBOT:
					a.appearance.top_color = Color(0.22, 0.52, 0.38)
					a.appearance.bottom_color = Color(0.32, 0.32, 0.42)
					a.display_name = "Robo-Cleaner"
				RobotRole.GUIDANCE_ROBOT:
					a.appearance.top_color = Color(0.20, 0.62, 0.82)
					a.appearance.bottom_color = Color(0.22, 0.28, 0.48)
					a.display_name = "Robo-Guide"
				RobotRole.DELIVERY_ROBOT:
					a.appearance.top_color = Color(0.60, 0.50, 0.30)
					a.appearance.bottom_color = Color(0.48, 0.38, 0.22)
					a.display_name = "Robo-Delivery"
				RobotRole.SECURITY_ROBOT:
					a.appearance.top_color = Color(0.12, 0.12, 0.16)
					a.appearance.bottom_color = Color(0.18, 0.18, 0.24)
					a.display_name = "Robo-Security"
				RobotRole.SHELF_ROBOT:
					a.appearance.top_color = Color(0.50, 0.55, 0.65)
					a.appearance.bottom_color = Color(0.38, 0.42, 0.50)
					a.display_name = "Robo-Stocker"
		else:
			# Single-function robots are distinct machines
			match rrole:
				RobotRole.CLEANING_ROBOT:
					a.appearance.top_color = Color(0.72, 0.74, 0.78)
					a.appearance.bottom_color = Color(0.60, 0.62, 0.65)
					a.display_name = "CleanerBot"
				RobotRole.GUIDANCE_ROBOT:
					a.appearance.top_color = Color(0.70, 0.72, 0.60)
					a.appearance.bottom_color = Color(0.55, 0.58, 0.45)
					a.display_name = "GuideBot"
				RobotRole.DELIVERY_ROBOT:
					a.appearance.top_color = Color(0.60, 0.50, 0.30)
					a.appearance.bottom_color = Color(0.48, 0.38, 0.22)
					a.display_name = "DeliveryBot"
				RobotRole.SECURITY_ROBOT:
					a.appearance.top_color = Color(0.30, 0.30, 0.35)
					a.appearance.bottom_color = Color(0.20, 0.20, 0.25)
					a.display_name = "SecurityBot"
				RobotRole.SHELF_ROBOT:
					a.appearance.top_color = Color(0.50, 0.55, 0.65)
					a.appearance.bottom_color = Color(0.38, 0.42, 0.50)
					a.display_name = "ShelfBot"

		return a

	func get_status_summary() -> String:
		if role == Role.STAFF:
			var role_names := {
				StaffRole.CASHIER: "Cashier",
				StaffRole.SHELF_STOCKER: "Shelf Stocker",
				StaffRole.CLEANER: "Cleaner",
				StaffRole.SECURITY: "Security",
				StaffRole.GREETER: "Greeter",
				StaffRole.MANAGER: "Manager",
				StaffRole.FLOOR_STAFF: "Floor Staff",
				StaffRole.SCAN_GO: "Scan & Go",
			}
			return "STAFF | %s | Energy: %d%%" % [
				role_names.get(staff_role, "Worker"),
				int(energy * 100)
			]
		elif role == Role.ROBOT:
			var type_str := "SINGLE-FN" if robot_type == RobotType.SINGLE_FUNCTION else "HUMANOID"
			var role_str := ""
			match robot_role:
				RobotRole.CLEANING_ROBOT: role_str = "Cleaner"
				RobotRole.GUIDANCE_ROBOT: role_str = "Guide"
				RobotRole.DELIVERY_ROBOT: role_str = "Delivery"
				RobotRole.SECURITY_ROBOT: role_str = "Security"
				RobotRole.SHELF_ROBOT: role_str = "Stocker"
			return "ROBOT [%s] | %s" % [type_str, role_str]
		else:
			var stage_names := {
				LifeStage.ADULT: "Adult",
				LifeStage.ADULT_MID: "Adult",
				LifeStage.SENIOR: "Senior",
				LifeStage.TEEN: "Teen",
				LifeStage.CHILD: "Child",
				LifeStage.TODDLER: "Toddler",
				LifeStage.INFANT: "Infant",
			}
			return "Customer | %s | Floor %d | Cart: %d" % [
				stage_names.get(life_stage, "Person"),
				current_floor,
				cart_item_count
			]
