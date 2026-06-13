# staff_access.gd
# ═══════════════════════════════════════════════════════════════════════
# Static helper that centralizes staff-area access checks. Future
# door / cashier / computer systems should call
# `StaffAccess.can_actor_access(actor, area_id)` instead of reading
# `actor.staff_card_level` directly. This keeps the access policy in
# one place — when we add manager overrides or shift-based locks,
# only this file changes.
#
# AREA IDS — convention:
#   "staff_area"        generic staff walking zones (floor 6/9)
#   "staff_lounge"      break room
#   "warehouse"         back-of-house stockroom
#   "truck_dock"        delivery vehicle bay
#   "checkout_back"     behind the cash registers
#   "utility_room"      maintenance / electrical closet
#   "food_prep"         kitchen
#   "front_desk"        customer service desk
#   "manager_office"    manager's private office
#
# These strings are matched against `Actor.staff_allowed_areas`,
# which is populated by `ActorData._assign_staff_card()` based on
# the actor's StaffRole. The `required_level` table below is the
# *minimum card level* a card must hold to enter that area; if the
# actor's `staff_allowed_areas` doesn't include the area id they
# are rejected regardless of card level.
#
# LOGIC ADDED LATER:
#   - Time-of-day shift locks (e.g. only managers after 22:00)
#   - Per-floor area definitions (currently this file is the
#     single source of truth; floor configs may eventually pass
#     their own required_level / required_role in)
#   - "Card required" NPC prop on the door volume itself
# ═══════════════════════════════════════════════════════════════════════
class_name StaffAccess
extends RefCounted

const ActorData = preload("res://scripts/entities/actor_data.gd")

# Minimum staff-card level required to enter each named area. A
# non-empty entry means: even if the area id is in the actor's
# `staff_allowed_areas`, they still need at least this card level.
# Managers (level 3) bypass both the level check and the
# allowed-area check.
const REQUIRED_LEVEL := {
	"staff_area": 1,
	"staff_lounge": 1,
	"front_desk": 1,
	"checkout_back": 1,
	"food_prep": 1,
	"warehouse": 1,
	"utility_room": 2,
	"truck_dock": 1,
	"manager_office": 3,
}

# Human-readable label for an area id — used by hover panel and any
# future "access denied" toast. Falls back to the raw id if unknown.
const AREA_LABEL := {
	"staff_area": "Staff Area",
	"staff_lounge": "Staff Lounge",
	"front_desk": "Front Desk",
	"checkout_back": "Checkout Back",
	"food_prep": "Food Prep",
	"warehouse": "Warehouse",
	"utility_room": "Utility Room",
	"truck_dock": "Truck Dock",
	"manager_office": "Manager Office",
}

# Returns true iff `actor` may enter the staff area identified by
# `area_id`. Pure check — no side effects, safe to call from _process.
static func can_actor_access(actor: ActorData.Actor, area_id: String) -> bool:
	if actor == null:
		return false
	# No card at all: deny (covers both customers and staff-with-no-card).
	if not actor.has_staff_card():
		return false
	# Managers pass everything by design.
	if actor.staff_card_level >= 3:
		return true
	# Area must be on the actor's allowed list...
	if not actor.staff_allowed_areas.has(area_id):
		return false
	# ...and meet the area's required card level.
	var req: int = int(REQUIRED_LEVEL.get(area_id, 1))
	return actor.staff_card_level >= req

# Same check but with a reason string for tooltips / toasts. Returns
# "" when access is granted; otherwise a short explanation.
static func deny_reason(actor: ActorData.Actor, area_id: String) -> String:
	if actor == null:
		return "no actor"
	if not actor.has_staff_card():
		return "no staff card"
	if actor.staff_card_level >= 3:
		return ""  # manager — always pass
	if not actor.staff_allowed_areas.has(area_id):
		return "card lacks area: " + area_id
	var req: int = int(REQUIRED_LEVEL.get(area_id, 1))
	if actor.staff_card_level < req:
		return "card Lv%d < required Lv%d" % [actor.staff_card_level, req]
	return ""

# Label for an area id, with a graceful fallback to the raw id.
static func area_label(area_id: String) -> String:
	return String(AREA_LABEL.get(area_id, area_id))
