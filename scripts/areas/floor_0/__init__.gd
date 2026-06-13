# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 0 (Ground Floor) Areas module
# Exports all area handler classes for Floor 0
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor0Areas

# Floor 0 handlers
const LobbyHandler = preload("res://scripts/areas/floor_0/lobby_handler.gd")
const FoodStallHandler = preload("res://scripts/areas/floor_0/food_stall_handler.gd")
const ServiceAreaHandler = preload("res://scripts/areas/floor_0/service_area_handler.gd")
const WCHandler = preload("res://scripts/areas/shared/wc_handler.gd")
const WarehouseHandler = preload("res://scripts/areas/floor_0/warehouse_handler.gd")
const WarehouseTestObjects = preload("res://scripts/areas/floor_0/warehouse_test_objects.gd")
const MiscHandler = preload("res://scripts/areas/floor_0/misc_handler.gd")
const Floor0Handler = preload("res://scripts/areas/floor_0/floor_0_handler.gd")

# Shared handlers used by Floor 0
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")
