# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 5 (Stationery) Areas module
# Exports all area handler classes for Floor 5
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor5Areas

# Floor 5 handlers
const StationeryHandler = preload("res://scripts/areas/floor_5/stationery_handler.gd")
const PlantsAreaHandler = preload("res://scripts/areas/floor_5/plants_area_handler.gd")
const StationeryCommonHandler = preload("res://scripts/areas/floor_5/stationery_common_handler.gd")
const Floor5Handler = preload("res://scripts/areas/floor_5/floor_5_handler.gd")

# Shared handlers used by Floor 5
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")