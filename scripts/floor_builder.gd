extends FloorBuilder

# floor_builder.gd
# Data-driven floor renderer. Reads FloorDef + zones from floor_config.gd
# and builds all visual content. Add new zone types by implementing
# _build_<type>() and calling it from _build_zone().

const FloorConfig = preload("res://scripts/floor_config.gd")
const StoreData = preload("res://scripts/store_data.gd")
const FoodStallScript = preload("res://scripts/food_stall.gd")
const ClawMachineScript = preload("res://scripts/claw_machine.gd")

const CELL_SIZE := FloorConfig.CELL_SIZE
const WORLD_W  := FloorConfig.WORLD_W
const WORLD_H  := FloorConfig.WORLD_H

var _floor_def: FloorConfig.FloorDef
var _parent: Node
var _floor_nodes: Array = []
var _sections: Array = []
var _food_stalls: Array = []
var _claw_machines: Array = []
var _checkout_counters: Array = []
var _aisle_labels: Array = []

signal section_interacted(section_id: String)
signal stall_interacted(stall_id: String)

func _init() -> void:
	pass

# Entry point — build an entire floor.
func build(floor_def: FloorConfig.FloorDef, parent: Node) -> void:
	_floor_def = floor_def
	_parent = parent
	_floor_nodes.clear()
	_sections.clear()
	_food_stalls.clear()
	_claw_machines.clear()
	_checkout_counters.clear()
	_aisle_labels.clear()

	_build_world_bg()
	_build_zones()
	_build_section_zones()
	_build_checkout_if_needed()
	_build_floor_sign()
	_build_shaft_visuals()


func _build_world_bg() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(WORLD_W * CELL_SIZE, WORLD_H * CELL_SIZE)
	bg.position = Vector2.ZERO
	bg.color = _floor_def.ambient_color.darkened(0.75)
	_parent.add_child(bg)
	_floor_nodes.append(bg)


func _build_zones() -> void:
	for zone in _floor_def.zones:
		_build_zone(zone)

func _build_zone(zone: FloorConfig.Zone) -> void:
	match zone.type:
		FloorConfig.ZONE_WALL:         _build_zone_wall(zone)
		FloorConfig.ZONE_AISLE:        _build_zone_aisle(zone)
		FloorConfig.ZONE_LOBBY:        _build_zone_lobby(zone)
		FloorConfig.ZONE_PARKING:      _build_zone_parking(zone)
		FloorConfig.ZONE_WC:           _build_zone_wc(zone)
		FloorConfig.ZONE_INFO_DESK:    _build_zone_info_desk(zone)
		FloorConfig.ZONE_FOOD_STALL:   _build_zone_food_stall(zone)
		FloorConfig.ZONE_FOOD_COURT:   _build_zone_food_court(zone)
		FloorConfig.ZONE_COMMON:       _build_zone_common(zone)
		FloorConfig.ZONE_ROOFTOP:     _build_zone_rooftop(zone)
		FloorConfig.ZONE_ELEVATOR:     _build_zone_shaft(zone)
		FloorConfig.ZONE_STAIRS:       _build_zone_stairs(zone)
		FloorConfig.ZONE_DECOR:         _build_zone_decor(zone)
		FloorConfig.ZONE_CLAW_MACHINE:  _build_zone_claw_machine(zone)
		FloorConfig.ZONE_PET_ADOPTION:  _build_zone_pet_adoption(zone)
		FloorConfig.ZONE_WAREHOUSE:      _build_zone_warehouse(zone)
		FloorConfig.ZONE_STORAGE_SHELF:   _build_zone_storage_shelf(zone)
		FloorConfig.ZONE_ATM:           _build_zone_atm(zone)
		FloorConfig.ZONE_SHOES_RACK:    _build_zone_shoes_rack(zone)
		FloorConfig.ZONE_DRESS_RACK:    _build_zone_dress_rack(zone)
		FloorConfig.ZONE_SPORT_AREA:    _build_zone_sport_area(zone)
		FloorConfig.ZONE_OUTDOOR_AREA:  _build_zone_outdoor_area(zone)
		FloorConfig.ZONE_STATIONERY:    _build_zone_stationery(zone)
		FloorConfig.ZONE_PLANTS_AREA:   _build_zone_plants_area(zone)
		FloorConfig.ZONE_LOCKER:        _build_zone_locker(zone)
		FloorConfig.ZONE_STAFF_LOUNGE:  _build_zone_staff_lounge(zone)
		FloorConfig.ZONE_TRAINING:      _build_zone_training(zone)
		FloorConfig.ZONE_OFFICE_DESK:   _build_zone_office_desk(zone)
		FloorConfig.ZONE_EXEC_OFFICE:   _build_zone_exec_office(zone)
		FloorConfig.ZONE_AD:           _build_zone_ad(zone)
		FloorConfig.ZONE_MONITOR_ROOM:  _build_zone_monitor_room(zone)
		FloorConfig.ZONE_HOME_DECOR:       _build_zone_home_decor(zone)
		FloorConfig.ZONE_FURNITURE:         _build_zone_furniture(zone)
		FloorConfig.ZONE_OUTDOOR_LIVING:   _build_zone_outdoor_living(zone)
		FloorConfig.ZONE_ORGANIZATION:      _build_zone_organization(zone)
		FloorConfig.ZONE_LIGHTING:          _build_zone_lighting(zone)
		FloorConfig.ZONE_CUSTOMER_SERVICE:   _build_zone_customer_service(zone)
		FloorConfig.ZONE_LOYALTY_KIOSK:     _build_zone_loyalty_kiosk(zone)
		FloorConfig.ZONE_GIFT_WRAP:          _build_zone_gift_wrap(zone)
		FloorConfig.ZONE_DIGITAL_KIOSK:      _build_zone_digital_kiosk(zone)
		FloorConfig.ZONE_JUICE_BAR:          _build_zone_juice_bar(zone)
		FloorConfig.ZONE_HEALTH_FOOD:        _build_zone_health_food(zone)
		FloorConfig.ZONE_SMOOTHIE:           _build_zone_smoothie(zone)
		FloorConfig.ZONE_SALAD_BAR:          _build_zone_salad_bar(zone)
		FloorConfig.ZONE_KIDS_PLAY:          _build_zone_kids_play(zone)
		FloorConfig.ZONE_KIDS_CLOTHING:      _build_zone_kids_clothing(zone)
		FloorConfig.ZONE_NURSING_ROOM:       _build_zone_nursing_room(zone)
		FloorConfig.ZONE_FAMILY_WC:           _build_zone_family_wc(zone)
		FloorConfig.ZONE_KIDS_CLUB:          _build_zone_kids_club(zone)
		FloorConfig.ZONE_PHONE_GADGETS:    _build_zone_phone_gadgets(zone)
		FloorConfig.ZONE_SMART_HOME:       _build_zone_smart_home(zone)
		FloorConfig.ZONE_ELECTRONICS:       _build_zone_electronics(zone)
		FloorConfig.ZONE_REPAIR_COUNTER:   _build_zone_repair_counter(zone)
		FloorConfig.ZONE_CAFE_COUNTER:     _build_zone_cafe_counter(zone)
		FloorConfig.ZONE_VENDING_MACHINE:  _build_zone_vending_machine(zone)
				FloorConfig.ZONE_CANTEEN:  _build_zone_canteen(zone)
		FloorConfig.ZONE_KARAOKE:  _build_zone_karaoke(zone)
		FloorConfig.ZONE_POOL_TABLE:  _build_zone_pool_table(zone)
		FloorConfig.ZONE_DARTS_BOARD:  _build_zone_darts_board(zone)
		FloorConfig.ZONE_ENTERTAINMENT:  _build_zone_entertainment(zone)
# Unknown types are silently skipped (extensible)


