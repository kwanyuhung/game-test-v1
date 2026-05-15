# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 1 (Shoes Floor) Areas module
# Exports all area handler classes for Floor 1
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor1Areas

# Floor 1 handlers
const ShoesRackHandler = preload("res://scripts/areas/floor_1/shoes_rack_handler.gd")
const CommonAreaHandler = preload("res://scripts/areas/floor_1/common_area_handler.gd")
const Floor1Handler = preload("res://scripts/areas/floor_1/floor_1_handler.gd")

# Shared handlers used by Floor 1
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")