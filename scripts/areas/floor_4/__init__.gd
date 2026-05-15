# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 4 (Outdoor) Areas module
# Exports all area handler classes for Floor 4
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor4Areas

# Floor 4 handlers
const OutdoorAreaHandler = preload("res://scripts/areas/floor_4/outdoor_area_handler.gd")
const OutdoorCommonHandler = preload("res://scripts/areas/floor_4/outdoor_common_handler.gd")
const Floor4Handler = preload("res://scripts/areas/floor_4/floor_4_handler.gd")

# Shared handlers used by Floor 4
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")