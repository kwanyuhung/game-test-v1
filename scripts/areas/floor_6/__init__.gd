# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 6 (Staff Area) Areas module
# Exports all area handler classes for Floor 6
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor6Areas

# Floor 6 handlers
const LockerHandler = preload("res://scripts/areas/floor_6/locker_handler.gd")
const StaffLoungeHandler = preload("res://scripts/areas/floor_6/staff_lounge_handler.gd")
const TrainingHandler = preload("res://scripts/areas/floor_6/training_handler.gd")
const StaffAreaCommonHandler = preload("res://scripts/areas/floor_6/staff_area_common_handler.gd")
const Floor6Handler = preload("res://scripts/areas/floor_6/floor_6_handler.gd")

# Shared handlers used by Floor 6
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")