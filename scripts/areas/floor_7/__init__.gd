# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 7 (Back Office) Areas module
# Exports all area handler classes for Floor 7
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor7Areas

# Floor 7 handlers
const OfficeDeskHandler = preload("res://scripts/areas/floor_7/office_desk_handler.gd")
const MonitorRoomHandler = preload("res://scripts/areas/floor_7/monitor_room_handler.gd")
const BackOfficeCommonHandler = preload("res://scripts/areas/floor_7/back_office_common_handler.gd")
const Floor7Handler = preload("res://scripts/areas/floor_7/floor_7_handler.gd")

# Shared handlers used by Floor 7
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")