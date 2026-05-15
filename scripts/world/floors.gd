# floors.gd
# Floor definitions for the 10-floor building.
# Single source of truth — imported by main.gd, store_data.gd, etc.
# Accessed via: const Floors = preload("res://scripts/world/floors.gd")

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
		index = p_index
		label = p_label
		theme = p_theme
		wx = 0  # All floors start at x=0
		color_ambient = p_color
		has_shopping = p_shopping
		has_checkout = p_checkout
		has_elevator = p_elevator
		has_stairs = p_stairs
		is_staff_only = p_staff
		is_rooftop = p_rooftop

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
		FloorDef.new(0, "G", "lobby",
			Color(0.42, 0.44, 0.40),
			false, false, true, true),

		# Floor 1 — Shoes
		FloorDef.new(1, "1", "shoes",
			Color(0.52, 0.45, 0.40),
			true, true, true, true),

		# Floor 2 — Dresses / Fashion
		FloorDef.new(2, "2", "fashion",
			Color(0.55, 0.42, 0.52),
			true, true, true, true),

		# Floor 3 — Sport & Active
		FloorDef.new(3, "3", "sport",
			Color(0.40, 0.50, 0.55),
			true, true, true, true),

		# Floor 4 — Outdoor (Fishing, Hiking, Running)
		FloorDef.new(4, "4", "outdoor",
			Color(0.42, 0.55, 0.45),
			true, true, true, true),

		# Floor 5 — Stationery & Plants
		FloorDef.new(5, "5", "stationery",
			Color(0.48, 0.55, 0.45),
			true, true, true, true),

		# Floor 6 — Staff Areas (locker room, break room, training)
		FloorDef.new(6, "6", "staff_area",
			Color(0.38, 0.38, 0.40),
			false, false, true, true, true),

		# Floor 7 — Back Office
		FloorDef.new(7, "7", "back_office",
			Color(0.40, 0.42, 0.45),
			false, false, true, true, true),

		# Floor 8 — Executive Office
		FloorDef.new(8, "8", "exec_office",
			Color(0.35, 0.35, 0.40),
			false, false, true, true, true),

		# Floor 9 — Staff Room (price management terminal, staff locker)
		FloorDef.new(9, "9", "staff_room",
			Color(0.38, 0.42, 0.50),
			false, false, true, true, true),

		# Floor 10 — Pet Paradise
		FloorDef.new(10, "10", "pet_paradise",
			Color(0.42, 0.70, 0.55),
			true, false, true, true),

		# Floor 11 — Warehouse & Receiving Dock
		FloorDef.new(11, "11", "warehouse",
			Color(0.55, 0.45, 0.38),
			false, false, true, false),
		
		# Floor 12 — Juice Bar & Fresh (Phase J)
		FloorDef.new(12, "12", "juice_bar",
			Color(0.55, 0.72, 0.58),
			true, false, true, true),

		# Floor 13 — Kids Kingdom (Phase K)
		FloorDef.new(13, "13", "kids_kingdom",
			Color(0.72, 0.58, 0.80),
			true, false, true, true),

		# Floor 14 — Electronics Megastore (Phase H)
		FloorDef.new(14, "14", "electronics",
			Color(0.35, 0.45, 0.65),
			true, false, true, true),
	]

# Floor index → FloorDef
static func floor_at(idx: int) -> FloorDef:
	if idx < 0 or idx >= ALL.size():
		return ALL[0]
	return ALL[idx]

# How many total floors
static func count() -> int:
	return ALL.size()
