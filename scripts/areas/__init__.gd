# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Areas module initialization
# Exports all area handler classes for Floor 0 (Ground) and Floor 1
# Structured into floor-specific directories for better organization
# ─────────────────────────────────────────────────────────────────────────────

class_name Areas

# Floor 0 (Ground) handlers
const LobbyHandler = preload("res://scripts/areas/floor_0/lobby_handler.gd")
const FoodStallHandler = preload("res://scripts/areas/floor_0/food_stall_handler.gd")
const ServiceAreaHandler = preload("res://scripts/areas/floor_0/service_area_handler.gd")
const WCHandler = preload("res://scripts/areas/floor_0/wc_handler.gd")
const WarehouseHandler = preload("res://scripts/areas/floor_0/warehouse_handler.gd")
const MiscHandler = preload("res://scripts/areas/floor_0/misc_handler.gd")
const Floor0Handler = preload("res://scripts/areas/floor_0/floor_0_handler.gd")

# Floor 1 handlers
const ShoesRackHandler = preload("res://scripts/areas/floor_1/shoes_rack_handler.gd")
const CommonAreaHandler = preload("res://scripts/areas/floor_1/common_area_handler.gd")
const Floor1Handler = preload("res://scripts/areas/floor_1/floor_1_handler.gd")

# Floor 2 handlers
const DressRackHandler = preload("res://scripts/areas/floor_2/dress_rack_handler.gd")
const FashionCommonHandler = preload("res://scripts/areas/floor_2/fashion_common_handler.gd")
const Floor2Handler = preload("res://scripts/areas/floor_2/floor_2_handler.gd")

# Floor 3 handlers
const SportAreaHandler = preload("res://scripts/areas/floor_3/sport_area_handler.gd")
const SportCommonHandler = preload("res://scripts/areas/floor_3/sport_common_handler.gd")
const Floor3Handler = preload("res://scripts/areas/floor_3/floor_3_handler.gd")

# Floor 4 handlers
const OutdoorAreaHandler = preload("res://scripts/areas/floor_4/outdoor_area_handler.gd")
const OutdoorCommonHandler = preload("res://scripts/areas/floor_4/outdoor_common_handler.gd")
const Floor4Handler = preload("res://scripts/areas/floor_4/floor_4_handler.gd")

# Floor 5 handlers
const StationeryHandler = preload("res://scripts/areas/floor_5/stationery_handler.gd")
const PlantsAreaHandler = preload("res://scripts/areas/floor_5/plants_area_handler.gd")
const StationeryCommonHandler = preload("res://scripts/areas/floor_5/stationery_common_handler.gd")
const Floor5Handler = preload("res://scripts/areas/floor_5/floor_5_handler.gd")

# Floor 6 handlers
const LockerHandler = preload("res://scripts/areas/floor_6/locker_handler.gd")
const StaffLoungeHandler = preload("res://scripts/areas/floor_6/staff_lounge_handler.gd")
const TrainingHandler = preload("res://scripts/areas/floor_6/training_handler.gd")
const StaffAreaCommonHandler = preload("res://scripts/areas/floor_6/staff_area_common_handler.gd")
const Floor6Handler = preload("res://scripts/areas/floor_6/floor_6_handler.gd")

# Floor 7 handlers
const OfficeDeskHandler = preload("res://scripts/areas/floor_7/office_desk_handler.gd")
const MonitorRoomHandler = preload("res://scripts/areas/floor_7/monitor_room_handler.gd")
const BackOfficeCommonHandler = preload("res://scripts/areas/floor_7/back_office_common_handler.gd")
const Floor7Handler = preload("res://scripts/areas/floor_7/floor_7_handler.gd")

# Floor 8 handlers
const ExecOfficeHandler = preload("res://scripts/areas/floor_8/exec_office_handler.gd")
const ExecOfficeCommonHandler = preload("res://scripts/areas/floor_8/exec_office_common_handler.gd")
const Floor8Handler = preload("res://scripts/areas/floor_8/floor_8_handler.gd")

# Floor 9 handlers
const StaffRoomHandler = preload("res://scripts/areas/floor_9/staff_room_handler.gd")
const StaffRoomCommonHandler = preload("res://scripts/areas/floor_9/staff_room_common_handler.gd")
const Floor9Handler = preload("res://scripts/areas/floor_9/floor_9_handler.gd")

# Floor 10 handlers (Rooftop Cafe)
const Floor10Handler = preload("res://scripts/areas/floor_10/floor_10_handler.gd")
const CafeCounterHandler = preload("res://scripts/areas/floor_10/cafe_counter_handler.gd")
const RooftopCommonHandler = preload("res://scripts/areas/floor_10/rooftop_common_handler.gd")

# Floor 11 handlers (Warehouse)
const Floor11Handler = preload("res://scripts/areas/floor_11/floor_11_handler.gd")
const WarehouseFloorHandler = preload("res://scripts/areas/floor_11/warehouse_floor_handler.gd")
const TruckDockHandler = preload("res://scripts/areas/floor_11/truck_dock_handler.gd")
const ConveyorHandler = preload("res://scripts/areas/floor_11/conveyor_handler.gd")

# Floor 12 handlers (Juice Bar)
const Floor12Handler = preload("res://scripts/areas/floor_12/floor_12_handler.gd")
const JuiceBarHandler = preload("res://scripts/areas/floor_12/juice_bar_handler.gd")
const JuiceBarCommonHandler = preload("res://scripts/areas/floor_12/juice_bar_common_handler.gd")

# Floor 13 handlers (Kids Kingdom)
const Floor13Handler = preload("res://scripts/areas/floor_13/floor_13_handler.gd")
const KidsKingdomHandler = preload("res://scripts/areas/floor_13/kids_kingdom_handler.gd")
const KidsKingdomCommonHandler = preload("res://scripts/areas/floor_13/kids_kingdom_common_handler.gd")

# Floor 14 handlers (Electronics)
const Floor14Handler = preload("res://scripts/areas/floor_14/floor_14_handler.gd")
const ElectronicsHandler = preload("res://scripts/areas/floor_14/electronics_handler.gd")
const ElectronicsCommonHandler = preload("res://scripts/areas/floor_14/electronics_common_handler.gd")

# Shared handlers
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")
const AdDisplayHandler = preload("res://scripts/areas/shared/ad_display_handler.gd")
