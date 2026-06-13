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
	CUSTOMER_SERVICE, # Lobby service desks: info, loyalty, gift wrap, digital kiosk
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

# ─── Movement Mode ────────────────────────────────────────────
# Constrains where an actor can move:
#   FREE        — roam anywhere (default)
#   FIXED_RANGE — patrol between waypoints (warehouse, customer service cluster)
#   STANDBY     — fixed at single anchor (cashier, receptionist)
enum MovementMode {
	FREE,
	FIXED_RANGE,
	STANDBY,
}

# ─── Life Stage ────────────────────────────────────────────────
enum LifeStage {
	ADULT,          # 18-64
	SENIOR,         # 60+ (includes 60-65+)
	TEEN,           # 13-19
	CHILD,          # 6-12
	TODDLER,        # 1-5
	INFANT,         # 0-1 (in baby cart)
}

# ─── Gender ────────────────────────────────────────────────────
# 0=male, 1=female, 2=undisclosed. Used to bias appearance generation
# (hair style / bottom style / first-name pool) and shown in hover panel.
enum Gender {
	MALE,
	FEMALE,
	UNDISCLOSED,
}

# ─── Item Type ─────────────────────────────────────────────────
# Held items that an NPC spawned with. Each item has its own visual
# rendering in NPCSprite and (potentially) an action-gated BehaviorState.
# Stored on Actor.inventory as a typed array; multi-slot is allowed but
# most actors will have 0-1 items.
enum ItemType {
	NONE,           # 0 — sentinel, never stored in inventory
	PHONE,          # 1 — held in right hand; unlocks phone-call action
	SKATEBOARD,     # 2 — at feet; faster movement
	LAPTOP,         # 3 — held in left hand; pauses for "work" behavior
	EARPHONES,      # 4 — on head; suppresses chat triggers
	CANE,           # 5 — held in left hand; senior-only; cosmetic
	STAFF_CARD,     # 6 — clipped to chest; grants access to staff areas + use of staff items (cashier, computer, etc.)
}

# Short symbols for compact display in the hover panel and debug overlay.
# Returns "M" / "F" / "—" rather than the full word.
static func gender_short(g: int) -> String:
	match g:
		Gender.MALE: return "M"
		Gender.FEMALE: return "F"
		_: return "—"

# Short label for an item type. Used by hover panel and count overlay.
static func item_name(it: int) -> String:
	match it:
		ItemType.PHONE: return "phone"
		ItemType.SKATEBOARD: return "skateboard"
		ItemType.LAPTOP: return "laptop"
		ItemType.EARPHONES: return "earphones"
		ItemType.CANE: return "cane"
		ItemType.STAFF_CARD: return "staff card"
		_: return "?"

# ─── Accessory ────────────────────────────────────────────────
# Generic accessory slot. `type` is 0 (none) or a slot-specific value;
# `color` is the primary tint; `variant` is a sub-style within the type.
class Accessory:
	var type: int       # 0=none, otherwise meaning depends on parent slot
	var color: Color
	var variant: int    # sub-style — e.g. bow size, backpack strap, etc.

	func _init() -> void:
		type = 0
		color = Color.WHITE
		variant = 0

	func is_none() -> bool:
		return type == 0

	static func none() -> Accessory:
		return Accessory.new()

	static func make(p_type: int, p_color: Color, p_variant: int = 0) -> Accessory:
		var a := Accessory.new()
		a.type = p_type
		a.color = p_color
		a.variant = p_variant
		return a

# Hair-accessory types (HairPart.accessory.type)
const HAIR_ACC_NONE       := 0
const HAIR_ACC_HAIRBAND   := 1   # cloth band around head
const HAIR_ACC_BOW        := 2   # decorative bow
const HAIR_ACC_HAT        := 3   # cap or beanie
const HAIR_ACC_HAIRNET    := 4   # food-safety hairnet
const HAIR_ACC_HEADBAND   := 5   # sport headband

# Top-accessory types (TopPart.accessory.type)
const TOP_ACC_NONE        := 0
const TOP_ACC_BAG         := 1   # satchel/messenger bag
const TOP_ACC_BACKPACK    := 2
const TOP_ACC_HANDBAG     := 3
const TOP_ACC_NECKTIE     := 4
const TOP_ACC_NAME_TAG    := 5
const TOP_ACC_SCARF       := 6
const TOP_ACC_APRON       := 7
const TOP_ACC_BADGE       := 8

# Bottom-accessory types (BottomPart.accessory.type)
const BOTTOM_ACC_NONE     := 0
const BOTTOM_ACC_BELT     := 1
const BOTTOM_ACC_HOLSTER  := 2   # tool holster
const BOTTOM_ACC_CHAIN    := 3

# ─── Hair Part ────────────────────────────────────────────────
class HairPart:
	var style: int      # 0=bob, 1=long, 2=short+neat, 3=bald/buzz
	var color: Color
	var accessory: Accessory

	func _init() -> void:
		style = 0            # bob default
		color = Color(0.18, 0.12, 0.08)
		accessory = Accessory.none()

	static func random() -> HairPart:
		var h := HairPart.new()
		var hairs := [
			Color(0.18, 0.12, 0.08),
			Color(0.62, 0.42, 0.22),
			Color(0.92, 0.72, 0.35),
			Color(0.78, 0.32, 0.18),
			Color(0.28, 0.22, 0.18),
			Color(0.10, 0.10, 0.10),
		]
		h.color = hairs[randi() % hairs.size()]
		h.style = randi() % 8
		# ~12% chance of a non-empty hair accessory
		if randi() % 100 < 12:
			var t := randi() % 3 + 1   # 1=hairband, 2=bow, 5=headband
			var palette := [
				Color(0.92, 0.42, 0.55), Color(0.38, 0.62, 0.88),
				Color(0.88, 0.68, 0.32), Color(0.62, 0.42, 0.92),
			]
			h.accessory = Accessory.make(t, palette[randi() % palette.size()], randi() % 3)
		return h

# ─── Top Part ─────────────────────────────────────────────────
class TopPart:
	var style: int      # 0=t-shirt, 1=shirt, 2=sweater, 3=jacket, 4=tank
	var color: Color
	var accessory: Accessory

	func _init() -> void:
		style = 0          # t-shirt default
		color = Color(0.28, 0.42, 0.78)
		accessory = Accessory.none()

	static func random() -> TopPart:
		var t := TopPart.new()
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
		t.color = tops[randi() % tops.size()]
		t.style = randi() % 5
		# ~15% chance of a body accessory
		if randi() % 100 < 15:
			var r := randi() % 100
			if r < 30:
				t.accessory = Accessory.make(TOP_ACC_BAG, Color(0.32, 0.22, 0.18))
			elif r < 55:
				t.accessory = Accessory.make(TOP_ACC_BACKPACK, Color(0.22, 0.28, 0.42))
			elif r < 75:
				t.accessory = Accessory.make(TOP_ACC_HANDBAG, Color(0.62, 0.32, 0.42), randi() % 2)
			elif r < 88:
				t.accessory = Accessory.make(TOP_ACC_NECKTIE, Color(0.18, 0.18, 0.55))
			else:
				t.accessory = Accessory.make(TOP_ACC_SCARF, Color(0.78, 0.32, 0.32))
		return t

# ─── Bottom Part ──────────────────────────────────────────────
class BottomPart:
	var style: int      # 0=pants, 1=skirt, 2=shorts, 3=dress
	var color: Color
	var accessory: Accessory

	func _init() -> void:
		style = 0          # pants default
		color = Color(0.22, 0.22, 0.42)
		accessory = Accessory.none()

	static func random() -> BottomPart:
		var b := BottomPart.new()
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
		b.color = bottoms[randi() % bottoms.size()]
		b.style = randi() % 4
		# ~10% chance of a belt
		if randi() % 100 < 10:
			b.accessory = Accessory.make(BOTTOM_ACC_BELT, Color(0.22, 0.18, 0.12))
		return b

# ─── Appearance ────────────────────────────────────────────────
# Composes three independent part objects (hair/top/bottom), each
# holding its own Accessory. Face/feet fields stay flat.
class Appearance:
	var skin_tone: Color
	var shoes_color: Color
	var shoes_style: int     # 0=sneakers, 1=formal, 2=sandals, 3=boots
	var has_glasses: bool
	var makeup_intensity: int  # 0=none, 1=light, 2=full
	var hair: HairPart
	var top: TopPart
	var bottom: BottomPart

	func _init() -> void:
		skin_tone = Color(0.88, 0.68, 0.48)
		shoes_color = Color(0.18, 0.18, 0.18)
		shoes_style = 0
		has_glasses = false
		makeup_intensity = 0
		hair = HairPart.new()
		top = TopPart.new()
		bottom = BottomPart.new()

	# Random appearance with optional gender bias on hair style:
	#   gender_bias == Gender.MALE        → style pool {2=short, 3=buzz, 7=curly}
	#   gender_bias == Gender.FEMALE      → style pool {0=bob, 1=long, 4=ponytail, 5=braids, 6=bun, 7=curly}
	#   gender_bias == Gender.UNDISCLOSED → any of 0-7
	#   gender_bias == -1                 → any of 0-7 (back-compat default)
	static func random(gender_bias: int = -1) -> Appearance:
		var a := Appearance.new()
		var skins := [
			Color(0.98, 0.85, 0.72),  # 極淺 (added for more range)
			Color(0.96, 0.80, 0.65),  # very light
			Color(0.88, 0.68, 0.48),  # light
			Color(0.78, 0.58, 0.42),  # 暖中
			Color(0.72, 0.52, 0.38),  # medium
			Color(0.55, 0.38, 0.28),  # tan
			Color(0.42, 0.30, 0.22),  # deep
			Color(0.32, 0.22, 0.16),  # 很深
			Color(0.58, 0.40, 0.32),  # 冷中 — 微偏紅
		]
		var shoes := [
			Color(0.18, 0.18, 0.18),
			Color(0.42, 0.35, 0.28),
			Color(0.75, 0.70, 0.65),
			Color(0.28, 0.18, 0.12),
		]
		a.skin_tone = skins[randi() % skins.size()]
		a.shoes_color = shoes[randi() % shoes.size()]
		a.shoes_style = randi() % 4
		a.has_glasses = (randi() % 4 == 0)
		a.makeup_intensity = randi() % 3
		a.hair = HairPart.random()
		# Re-roll hair style into the gender-biased pool. Keep the color
		# and any accessory roll that HairPart.random already produced.
		var style_pool: Array = []
		match gender_bias:
			Gender.MALE:
				style_pool = [2, 2, 3, 3, 7, 7]   # short / buzz / curly, weighted
			Gender.FEMALE:
				style_pool = [0, 0, 1, 1, 4, 5, 6, 7]
			_:
				style_pool = [0, 1, 2, 3, 4, 5, 6, 7]
		a.hair.style = style_pool[randi() % style_pool.size()]
		a.top = TopPart.random()
		a.bottom = BottomPart.random()
		return a

# ─── Baby / Child Data ──────────────────────────────────────────
class ChildData:
	var age: int          # 0=infant, 1-5=toddler, 6-12=child
	var gender: int       # 0=boy, 1=girl, 2=neutral
	var skin_tone: Color
	var hair_color: Color
	var hair_style: int   # 0=short, 1=bob, 2=ponytail, 3=spiky (baby-specific, distinct from HairPart)
	var hair_accessory: Accessory  # hat / bow — replaces the old int accessory
	var outfit: TopPart   # top garment (color used as the unified outfit color)
	var dress: BottomPart # style locked to 3 (dress) for the lower half
	var cart_color: Color # stroller/cart color

	func _init() -> void:
		skin_tone = Color(0.88, 0.68, 0.48)
		hair_color = Color(0.18, 0.12, 0.08)
		hair_style = 0
		hair_accessory = Accessory.none()
		outfit = TopPart.new()
		dress = BottomPart.new()
		dress.style = 3  # dress — locked for babies
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
		c.skin_tone = skins[randi() % skins.size()]
		c.hair_color = hairs[randi() % hairs.size()]
		c.hair_style = randi() % 3
		# Babies draw a single outfit color, so use TopPart just for the color.
		c.outfit = TopPart.random()
		c.outfit.accessory = Accessory.none()  # baby outfits have no top accessory
		c.dress = BottomPart.random()
		c.dress.style = 3  # dress — locked
		c.dress.accessory = Accessory.none()
		# 20% chance of a hat
		if randi() % 100 < 20:
			c.hair_accessory = Accessory.make(HAIR_ACC_HAT, c.outfit.color.lightened(0.2))
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

# ─── Movement Bounds ──────────────────────────────────────────
# Restricts where an actor can move. Three modes:
#   FREE        — roam anywhere (default, legacy behavior)
#   FIXED_RANGE — patrol between a set of waypoints (e.g. warehouse staff,
#                 customer service desk cluster)
#   STANDBY     — stay at a single anchor point, no movement
#                 (e.g. cashier at checkout lane, receptionist at desk)
class MovementBounds:
	var mode: int            # MovementMode enum
	var anchor: Vector2      # For STANDBY — single position
	var waypoints: Array     # For FIXED_RANGE — list of Vector2
	var arrival_radius: float  # Distance for "arrived" check

	func _init() -> void:
		mode = MovementMode.FREE
		anchor = Vector2.ZERO
		waypoints = []
		arrival_radius = 16.0

	static func standby(p_anchor: Vector2) -> MovementBounds:
		var b := MovementBounds.new()
		b.mode = MovementMode.STANDBY
		b.anchor = p_anchor
		return b

	static func fixed_range(p_waypoints: Array) -> MovementBounds:
		var b := MovementBounds.new()
		b.mode = MovementMode.FIXED_RANGE
		b.waypoints = p_waypoints.duplicate()
		return b

# ─── Full Actor Definition ─────────────────────────────────────
class Actor:
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
	var movement_bounds: MovementBounds  # Where the actor is allowed to move
	var gender: int          # Gender enum — biases appearance and name pool
	var inventory: Array = []  # ItemType list — see enum above
	# Staff-card credentials. 0 = no card; 1+ = clearance level.
	# `staff_allowed_areas` lists the staff-area ids (e.g. "staff_area",
	# "staff_lounge", "warehouse") the actor can enter. Used by future
	# cashier / computer / door systems via can_access_staff_area().
	var staff_card_level: int = 0
	var staff_allowed_areas: Array = []   # Array[String] of area ids

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
		current_floor = 0
		target_floor = 0
		is_active = true
		movement_bounds = MovementBounds.new()
		gender = Gender.UNDISCLOSED
		inventory = []
		staff_card_level = 0
		staff_allowed_areas = []

	# Inventory helpers — used by brain / chat / hover panel.
	func has_item(item: int) -> bool:
		return inventory.has(item)

	func add_item(item: int) -> void:
		if item == ItemType.NONE:
			return
		if not inventory.has(item):
			inventory.append(item)

	# Staff-card helpers. `has_staff_card()` is just shorthand for
	# `level > 0`; `can_access_staff_area(area_id)` is the single
	# check that door/cashier/computer systems should call.
	func has_staff_card() -> bool:
		return staff_card_level > 0

	func can_access_staff_area(area_id: String) -> bool:
		if not has_staff_card():
			return false
		# Managers (level 3+) can access every registered staff area.
		if staff_card_level >= 3:
			return true
		return staff_allowed_areas.has(area_id)

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

	# Default movement bounds for a role. STANDBY roles need a spawn-supplied
	# anchor; FIXED_RANGE roles need spawn-supplied waypoints. Spawn code
	# populates the missing fields after construction.
	static func _default_bounds_for_role(p_role: StaffRole) -> MovementBounds:
		var b := MovementBounds.new()
		match p_role:
			StaffRole.CASHIER, StaffRole.SCAN_GO, \
			StaffRole.GREETER, StaffRole.RECEPTIONIST:
				# Fixed at one spot. Spawn code sets the anchor.
				b.mode = MovementMode.STANDBY
			StaffRole.SHELF_STOCKER, StaffRole.DELIVERY_STAFF, \
			StaffRole.SHOP_STAFF, StaffRole.FOOD_STAFF, \
			StaffRole.CUSTOMER_SERVICE:
				# Patrol a defined set of waypoints. Spawn code fills them in.
				b.mode = MovementMode.FIXED_RANGE
			_:
				# CLEANER, CLEAN_STAFF, FLOOR_STAFF, SECURITY, MANAGER,
				# MAINTENANCE_STAFF — free to roam.
				b.mode = MovementMode.FREE
		return b

	# Default staff-card credentials by role. Each entry is a
	# [card_level, [allowed_area_ids]] pair. The area ids are matched
	# against the `area_id` field on doors / area volumes registered
	# by the floor configs (e.g. "staff_area", "staff_lounge",
	# "warehouse", "truck_dock", "manager_office").
	#
	# Card level 3 (MANAGER) is special: the manager bypasses this
	# table and is granted access to every registered staff area.
	static func _staff_card_defaults(p_role: StaffRole) -> Array:
		match p_role:
			StaffRole.MANAGER:
				return [3, []]
			StaffRole.SECURITY, StaffRole.MAINTENANCE_STAFF:
				return [2, ["staff_area", "staff_lounge", "utility_room"]]
			StaffRole.DELIVERY_STAFF:
				return [2, ["staff_area", "warehouse", "truck_dock"]]
			StaffRole.CASHIER, StaffRole.SCAN_GO:
				return [1, ["staff_area", "checkout_back"]]
			StaffRole.SHELF_STOCKER:
				return [1, ["staff_area", "warehouse"]]
			StaffRole.FOOD_STAFF:
				return [1, ["staff_area", "food_prep"]]
			StaffRole.RECEPTIONIST, StaffRole.CUSTOMER_SERVICE:
				return [1, ["staff_area", "front_desk"]]
			_:
				# CLEANER, CLEAN_STAFF, FLOOR_STAFF, GREETER, SHOP_STAFF
				return [1, ["staff_area"]]

	# Apply the default card credentials to a freshly-built staff Actor.
	# Mutates `a` in place. Called from random_staff() after the role's
	# appearance has been set up.
	static func _assign_staff_card(a: Actor, p_role: StaffRole) -> void:
		var defs: Array = _staff_card_defaults(p_role)
		a.staff_card_level = int(defs[0])
		a.staff_allowed_areas = (defs[1] as Array).duplicate()
		if a.staff_card_level > 0:
			a.add_item(ItemType.STAFF_CARD)

	static func random_customer(p_group: CustomerGroupType = CustomerGroupType.SOLO) -> Actor:
		var a := Actor.new()
		a.role = Role.CUSTOMER
		a.group_type = p_group
		a.gender = _roll_gender()
		a.appearance = Appearance.random(a.gender)
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
				if roll < 7:
					a.life_stage = LifeStage.TEEN
				elif roll < 19:
					a.life_stage = LifeStage.SENIOR
				else:
					a.life_stage = LifeStage.ADULT

		# Generate a random name from a pool sized to gender
		a.display_name = _pick_name(a.gender)

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

	# Gender roll: ~45/45/10 male/female/undisclosed.
	static func _roll_gender() -> int:
		var r := randi() % 100
		if r < 45:
			return Gender.MALE
		if r < 90:
			return Gender.FEMALE
		return Gender.UNDISCLOSED

	# Pick a first name from a pool sized to the actor's gender. Female
	# pool is biased toward the FEMALE enum value, but a small overlap with
	# the neutral pool keeps the names from feeling mechanically fixed.
	static func _pick_name(g: int) -> String:
		var neutral := ["Alex", "Jordan", "Sam", "Morgan", "Taylor", "Casey", "Riley", "Quinn", "Avery", "Blake", "Drew", "Reese", "Finley", "Sage", "River"]
		var female := ["Emma", "Olivia", "Sophia", "Ava", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn", "Luna", "Camila", "Aria"]
		var male := ["Liam", "Noah", "James", "Oliver", "Elijah", "Lucas", "Mason", "Ethan", "Logan", "Henry", "Jackson", "Aiden"]
		match g:
			Gender.FEMALE:
				# 80% female pool, 20% neutral for variety.
				if randf() < 0.8:
					return female[randi() % female.size()]
				return neutral[randi() % neutral.size()]
			Gender.MALE:
				if randf() < 0.8:
					return male[randi() % male.size()]
				return neutral[randi() % neutral.size()]
			_:
				return neutral[randi() % neutral.size()]

	static func random_staff(p_role: StaffRole) -> Actor:
		var a := Actor.new()
		a.role = Role.STAFF
		a.staff_role = p_role
		a.gender = _roll_gender()
		# Staff roles set hair style manually per role, but bottom/top
		# color palettes are still drawn from the gender pool via the
		# random call below. Pass gender for consistency.
		a.appearance = Appearance.random(a.gender)
		a.energy = randf_range(0.7, 1.0)
		a.hunger = randf_range(0.0, 0.3)
		a.happiness = randf_range(0.5, 0.9)
		a.current_floor = 0
		# Default movement mode by role. The spawn code may override the
		# bounds (anchor / waypoints) after the actor is created.
		a.movement_bounds = _default_bounds_for_role(p_role)

		var first_names := ["Emma", "Liam", "Olivia", "Noah", "Ava", "James", "Sophia", "Oliver", "Isabella", "Elijah", "Mia", "Lucas", "Charlotte", "Mason"]
		var last_initials := ["A", "B", "C", "D", "K", "L", "M", "N", "P", "R", "S", "T", "W", "Y"]
		a.display_name = first_names[randi() % first_names.size()] + " " + last_initials[randi() % last_initials.size()] + "."

		# Staff uniforms are role-controlled — clear random accessories
		# inherited from Appearance.random() before applying role defaults.
		a.appearance.hair.accessory = Accessory.none()
		a.appearance.top.accessory = Accessory.none()
		a.appearance.bottom.accessory = Accessory.none()

		# Issue a staff card with credentials based on the role. Card
		# level: 1 = floor staff, 2 = area lead, 3 = manager. Allowed
		# areas come from a role-keyed default table; managers (level 3)
		# bypass the table and can enter every registered staff area.
		_assign_staff_card(a, p_role)

		match p_role:
			StaffRole.CASHIER:
				a.appearance.top.color = Color(0.18, 0.35, 0.65)
				a.appearance.bottom.color = Color(0.22, 0.22, 0.38)
				a.appearance.top.style = 1  # shirt
				a.appearance.hair.style = 2  # short+neat
				a.appearance.hair.color = Color(0.18, 0.12, 0.08)  # black
				a.appearance.top.accessory = Accessory.make(TOP_ACC_NAME_TAG, Color(0.95, 0.95, 0.95))
			StaffRole.SHELF_STOCKER:
				a.appearance.top.color = Color(0.28, 0.28, 0.28)
				a.appearance.bottom.color = Color(0.38, 0.38, 0.38)
				a.appearance.hair.style = 2  # short+neat
				a.appearance.hair.color = Color(0.62, 0.42, 0.22)  # brown
			StaffRole.CLEANER:
				a.appearance.top.color = Color(0.22, 0.52, 0.38)
				a.appearance.bottom.color = Color(0.32, 0.32, 0.42)
				a.appearance.hair.style = 2  # short+neat
				a.appearance.hair.color = Color(0.28, 0.22, 0.18)  # dark brown
				a.appearance.top.accessory = Accessory.make(TOP_ACC_APRON, Color(0.65, 0.32, 0.32))
			StaffRole.SECURITY:
				a.appearance.top.color = Color(0.12, 0.12, 0.16)
				a.appearance.bottom.color = Color(0.18, 0.18, 0.24)
				a.appearance.hair.style = 3  # buzz cut — authoritative
				a.appearance.hair.color = Color(0.10, 0.10, 0.10)  # jet black
				a.appearance.top.accessory = Accessory.make(TOP_ACC_BADGE, Color(0.85, 0.78, 0.18))
			StaffRole.GREETER:
				a.appearance.top.color = Color(0.78, 0.28, 0.28)
				a.appearance.bottom.color = Color(0.22, 0.22, 0.42)
				a.appearance.hair.style = 0  # bob — friendly
				a.appearance.hair.color = Color(0.92, 0.72, 0.35)  # warm blonde
				a.appearance.hair.accessory = Accessory.make(HAIR_ACC_BOW, Color(0.92, 0.32, 0.52))
			StaffRole.MANAGER:
				a.appearance.top.color = Color(0.18, 0.18, 0.28)
				a.appearance.bottom.color = Color(0.32, 0.28, 0.22)
				a.appearance.top.style = 1  # shirt
				a.appearance.has_glasses = true
				a.appearance.hair.style = 2  # short+neat — professional
				a.appearance.hair.color = Color(0.47, 0.39, 0.38)  # salt-and-pepper dark
				a.appearance.top.accessory = Accessory.make(TOP_ACC_NECKTIE, Color(0.18, 0.18, 0.55))
			StaffRole.FLOOR_STAFF:
				a.appearance.top.color = Color(0.42, 0.42, 0.48)
				a.appearance.bottom.color = Color(0.22, 0.22, 0.42)
				a.appearance.hair.style = 2  # short+neat
				a.appearance.hair.color = Color(0.62, 0.42, 0.22)  # brown
				a.appearance.top.accessory = Accessory.make(TOP_ACC_NAME_TAG, Color(0.95, 0.95, 0.95))
			StaffRole.SCAN_GO:
				a.appearance.top.color = Color(0.20, 0.62, 0.82)
				a.appearance.bottom.color = Color(0.22, 0.28, 0.48)
				a.appearance.hair.style = 1  # long — modern tech vibe
				a.appearance.hair.color = Color(0.28, 0.22, 0.18)  # dark
				a.appearance.top.accessory = Accessory.make(TOP_ACC_BADGE, Color(0.20, 0.62, 0.82))
			StaffRole.SHOP_STAFF:
				a.appearance.top.color = Color(0.55, 0.40, 0.62)
				a.appearance.bottom.color = Color(0.22, 0.22, 0.32)
				a.appearance.top.style = 1  # shirt
				a.appearance.hair.style = 1  # long — fashion retail
				a.appearance.hair.color = Color(0.78, 0.32, 0.18)  # auburn
				a.appearance.top.accessory = Accessory.make(TOP_ACC_SCARF, Color(0.78, 0.42, 0.32))
			StaffRole.FOOD_STAFF:
				a.appearance.top.color = Color(0.85, 0.42, 0.22)
				a.appearance.bottom.color = Color(0.95, 0.92, 0.85)
				a.appearance.hair.accessory = Accessory.make(HAIR_ACC_HAIRNET, Color(0.95, 0.92, 0.85))
				a.appearance.hair.style = 2  # short+neat under hairnet
				a.appearance.hair.color = Color(0.18, 0.12, 0.08)  # black
				a.appearance.top.accessory = Accessory.make(TOP_ACC_APRON, Color(0.95, 0.92, 0.85))
			StaffRole.CLEAN_STAFF:
				a.appearance.top.color = Color(0.40, 0.65, 0.45)
				a.appearance.bottom.color = Color(0.32, 0.32, 0.42)
				a.appearance.hair.style = 2  # short+neat
				a.appearance.hair.color = Color(0.47, 0.39, 0.38)  # dark
				a.appearance.top.accessory = Accessory.make(TOP_ACC_APRON, Color(0.40, 0.65, 0.45))
			StaffRole.RECEPTIONIST:
				a.appearance.top.color = Color(0.32, 0.52, 0.72)
				a.appearance.bottom.color = Color(0.22, 0.22, 0.38)
				a.appearance.top.style = 1  # shirt
				a.appearance.hair.style = 0  # bob — polished
				a.appearance.hair.color = Color(0.28, 0.22, 0.18)  # dark brown
				a.appearance.top.accessory = Accessory.make(TOP_ACC_NECKTIE, Color(0.32, 0.52, 0.72))
			StaffRole.MAINTENANCE_STAFF:
				a.appearance.top.color = Color(0.72, 0.52, 0.18)
				a.appearance.bottom.color = Color(0.35, 0.28, 0.20)
				a.appearance.top.style = 2  # sweater
				a.appearance.hair.style = 3  # buzz — utility worker
				a.appearance.hair.color = Color(0.47, 0.39, 0.38)  # dark
				a.appearance.bottom.accessory = Accessory.make(BOTTOM_ACC_HOLSTER, Color(0.18, 0.12, 0.08))
			StaffRole.DELIVERY_STAFF:
				a.appearance.top.color = Color(0.82, 0.62, 0.32)
				a.appearance.bottom.color = Color(0.42, 0.32, 0.22)
				a.appearance.top.accessory = Accessory.make(TOP_ACC_BACKPACK, Color(0.22, 0.28, 0.42))
				a.appearance.hair.style = 3  # buzz — hands-on worker
				a.appearance.hair.color = Color(0.18, 0.12, 0.08)  # black
				a.appearance.bottom.accessory = Accessory.make(BOTTOM_ACC_BELT, Color(0.22, 0.18, 0.12))
			StaffRole.CUSTOMER_SERVICE:
				a.appearance.top.color = Color(0.20, 0.55, 0.62)  # teal — service-industry calm
				a.appearance.bottom.color = Color(0.22, 0.32, 0.38)
				a.appearance.top.style = 1  # shirt — polished service uniform
				a.appearance.hair.style = 0  # bob — approachable
				a.appearance.hair.color = Color(0.18, 0.12, 0.08)  # dark
				a.appearance.top.accessory = Accessory.make(TOP_ACC_NAME_TAG, Color(0.95, 0.95, 0.95))

		return a

	static func random_robot(rtype: RobotType, rrole: RobotRole = RobotRole.CLEANING_ROBOT) -> Actor:
		var a := Actor.new()
		a.role = Role.ROBOT
		a.robot_type = rtype
		a.robot_role = rrole
		a.gender = _roll_gender()
		a.energy = 1.0
		a.happiness = 1.0
		a.current_floor = 0
		# Default robot movement mode. Warehouse-bound robots are FIXED_RANGE;
		# roaming robots (cleaning, guidance, security) are FREE. Spawn code
		# populates the waypoints/anchor.
		match rrole:
			RobotRole.DELIVERY_ROBOT, RobotRole.SHELF_ROBOT:
				a.movement_bounds.mode = MovementMode.FIXED_RANGE
			_:
				a.movement_bounds.mode = MovementMode.FREE

		# Humanoid robots look like humans with subtle robot features
		if rtype == RobotType.HUMANOID:
			a.appearance = Appearance.random(a.gender)
			# Give humanoid robot a synthetic skin tone and robot uniform
			a.appearance.skin_tone = Color(0.82, 0.84, 0.88)  # slightly metallic skin
			# Clear random civilian accessories — robot uniforms are role-controlled
			a.appearance.hair.accessory = Accessory.none()
			a.appearance.top.accessory = Accessory.none()
			a.appearance.bottom.accessory = Accessory.none()
			match rrole:
				RobotRole.CLEANING_ROBOT:
					a.appearance.top.color = Color(0.22, 0.52, 0.38)
					a.appearance.bottom.color = Color(0.32, 0.32, 0.42)
					a.display_name = "Robo-Cleaner"
				RobotRole.GUIDANCE_ROBOT:
					a.appearance.top.color = Color(0.20, 0.62, 0.82)
					a.appearance.bottom.color = Color(0.22, 0.28, 0.48)
					a.display_name = "Robo-Guide"
				RobotRole.DELIVERY_ROBOT:
					a.appearance.top.color = Color(0.60, 0.50, 0.30)
					a.appearance.bottom.color = Color(0.48, 0.38, 0.22)
					a.display_name = "Robo-Delivery"
				RobotRole.SECURITY_ROBOT:
					a.appearance.top.color = Color(0.12, 0.12, 0.16)
					a.appearance.bottom.color = Color(0.18, 0.18, 0.24)
					a.display_name = "Robo-Security"
				RobotRole.SHELF_ROBOT:
					a.appearance.top.color = Color(0.50, 0.55, 0.65)
					a.appearance.bottom.color = Color(0.38, 0.42, 0.50)
					a.display_name = "Robo-Stocker"
		else:
			# Single-function robots are distinct machines
			match rrole:
				RobotRole.CLEANING_ROBOT:
					a.appearance.top.color = Color(0.72, 0.74, 0.78)
					a.appearance.bottom.color = Color(0.60, 0.62, 0.65)
					a.display_name = "CleanerBot"
				RobotRole.GUIDANCE_ROBOT:
					a.appearance.top.color = Color(0.70, 0.72, 0.60)
					a.appearance.bottom.color = Color(0.55, 0.58, 0.45)
					a.display_name = "GuideBot"
				RobotRole.DELIVERY_ROBOT:
					a.appearance.top.color = Color(0.60, 0.50, 0.30)
					a.appearance.bottom.color = Color(0.48, 0.38, 0.22)
					a.display_name = "DeliveryBot"
				RobotRole.SECURITY_ROBOT:
					a.appearance.top.color = Color(0.30, 0.30, 0.35)
					a.appearance.bottom.color = Color(0.20, 0.20, 0.25)
					a.display_name = "SecurityBot"
				RobotRole.SHELF_ROBOT:
					a.appearance.top.color = Color(0.50, 0.55, 0.65)
					a.appearance.bottom.color = Color(0.38, 0.42, 0.50)
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
				StaffRole.SHOP_STAFF: "Shop Staff",
				StaffRole.FOOD_STAFF: "Food Staff",
				StaffRole.CLEAN_STAFF: "Clean Staff",
				StaffRole.RECEPTIONIST: "Receptionist",
				StaffRole.MAINTENANCE_STAFF: "Maintenance",
				StaffRole.DELIVERY_STAFF: "Delivery",
				StaffRole.CUSTOMER_SERVICE: "Customer Service",
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
