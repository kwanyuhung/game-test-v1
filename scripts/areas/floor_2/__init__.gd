# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 2 (Fashion) Areas module
# Exports all area handler classes for Floor 2
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor2Areas

# Floor 2 handlers
const DressRackHandler = preload("res://scripts/areas/floor_2/dress_rack_handler.gd")
const FashionCommonHandler = preload("res://scripts/areas/floor_2/fashion_common_handler.gd")
const Floor2Handler = preload("res://scripts/areas/floor_2/floor_2_handler.gd")

# Shared handlers used by Floor 2
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")