# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 9 (Staff Room) Areas module
# Exports all area handler classes for Floor 9
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor9Areas

# Floor 9 handlers
const StaffRoomHandler = preload("res://scripts/areas/floor_9/staff_room_handler.gd")
const StaffRoomCommonHandler = preload("res://scripts/areas/floor_9/staff_room_common_handler.gd")
const Floor9Handler = preload("res://scripts/areas/floor_9/floor_9_handler.gd")

# Shared handlers used by Floor 9
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")