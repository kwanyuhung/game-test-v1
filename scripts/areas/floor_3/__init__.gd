# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 3 (Sport) Areas module
# Exports all area handler classes for Floor 3
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor3Areas

# Floor 3 handlers
const SportAreaHandler = preload("res://scripts/areas/floor_3/sport_area_handler.gd")
const SportCommonHandler = preload("res://scripts/areas/floor_3/sport_common_handler.gd")
const Floor3Handler = preload("res://scripts/areas/floor_3/floor_3_handler.gd")

# Shared handlers used by Floor 3
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")