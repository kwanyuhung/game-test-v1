# floors.gd
# Floor definitions for the 10-floor building.
# Single source of truth — imported by main.gd, store_data.gd, etc.
# Accessed via: const Floors = preload("res://scripts/floors.gd")

class FloorDef:
	var index: int          # 0 = Ground, 1 = Floor 1 ... 9 = Floor 10
	var label: String       # Display name e.g. "G", "1", "2"... "10"
	var theme: String       # e.g. "lobby", "fresh", "pantry"...
	var wx: int             # World x origin (always 0, all floors same grid)
	var color_ambient: Color  # Ambient lighting tint for this floor
	var has_shopping: bool  # True if this floor has retail sections
	var has_checkout: bool  # True if this floor has checkout counters
	var has_elevator: bool  # Elevator shaft reaches this floor
	var has_stairs: bool    # Staircase reaches this floor
	var is_staff_only: bool # Requires staff mode to access
	var is_rooftop: bool    # Rooftop floor (open air)

	func _init(
		p_index: int,
		p_label: String,
		p_theme: String,
		p_color: Color,
		p_shopping: bool,
		p_checkout: bool,
		p_elevator: bool,
		p_stairs: bool,
		p_staff: bool = false,
		p_rooftop: bool = false
	):
		index = p_index; label = p_label; theme = p_theme
		color_ambient = p_color; has_shopping = p_shopping
		has_checkout = p_checkout; has_elevator = p_elevator
		has_stairs = p_stairs; is_staff_only = p_staff; is_rooftop = p_rooftop

	# World Y of the elevator shaft within this floor's grid
	func elevator_tile() -> Vector2i:
		return Vector2i(80, 15)  # x=80, y=15 in tile coords

	# World Y of the staircase within this floor's grid
	func stairs_tile() -> Vector2i:
		return Vector2i(84, 15)

	# Parking row (only Ground floor)
	func parking_origin() -> Vector2i:
		return Vector2i(2, 38)

static var ALL: Array = []
static var CURRENT: int = 0

static func _static_init() -> void:
	ALL = [
		# Ground Floor G (index 0)
		# Parking lot outside (bottom-left), Lobby, Elevator/Stairs, WC, Info desk
		FloorDef.new(0, "G", "lobby",
			Color(0.40, 0.42, 0.38),  # overcast outdoor ambient
			false, false, true, true),

		# Floor 1 — Fresh Market
		FloorDef.new(1, "1", "fresh",
			Color(0.50, 0.55, 0.45),
			true, true, true, true),

		# Floor 2 — Pantry & Dry Goods
		FloorDef.new(2, "2", "pantry",
			Color(0.48, 0.45, 0.40),
			true, true, true, true),

		# Floor 3 — Beverages
		FloorDef.new(3, "3", "beverages",
			Color(0.42, 0.50, 0.60),
			true, true, true, true),

		# Floor 4 — Snacks & Candy
		FloorDef.new(4, "4", "snacks",
			Color(0.55, 0.48, 0.38),
			true, true, true, true),

		# Floor 5 — Frozen Foods
		FloorDef.new(5, "5", "frozen",
			Color(0.38, 0.48, 0.65),
			true, true, true, true),

		# Floor 6 — Household
		FloorDef.new(6, "6", "household",
			Color(0.45, 0.42, 0.40),
			true, true, true, true),

		# Floor 7 — Health & Beauty
		FloorDef.new(7, "7", "health",
			Color(0.52, 0.48, 0.50),
			true, true, true, true),

		# Floor 8 — Toys & Play
		FloorDef.new(8, "8", "toys",
			Color(0.60, 0.55, 0.40),
			true, true, true, true),

		# Floor 9 — Staff Room (staff only)
		FloorDef.new(9, "9", "staff",
			Color(0.38, 0.38, 0.35),
			false, false, true, true, true),

		# Floor 10 — Rooftop Café
		FloorDef.new(10, "10", "rooftop",
			Color(0.65, 0.60, 0.50),
			true, false, true, false, false, true),

		# Floor 11 — Pet Paradise
		FloorDef.new(11, "11", "pet_paradise",
			Color(0.42, 0.70, 0.55),
			true, false, true, true),

		# Floor 12 — Warehouse & Receiving Dock
		FloorDef.new(12, "12", "warehouse",
			Color(0.55, 0.45, 0.38),
			false, false, true, false),
	]

# Floor index → FloorDef
static func floor_at(idx: int) -> FloorDef:
	if idx < 0 or idx >= ALL.size():
		return ALL[0]
	return ALL[idx]

# How many total floors
static func count() -> int:
	return ALL.size()
