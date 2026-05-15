# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Shared Areas module
# Exports area handler classes shared across multiple floors
# ─────────────────────────────────────────────────────────────────────────────

class_name SharedAreas

const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")