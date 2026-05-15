extends Node2D
class_name FloorBuilder

# floor_builder.gd
# Data-driven floor renderer. Reads FloorDef + zones from floor_config.gd
# and builds all visual content. Add new zone types by implementing
# _build_<type>() and calling it from _build_zone().
#
# Floor 1 (Shoes) uses dedicated area handlers from scripts/areas/ directory
# for better modularity and maintainability.

const FloorConfig = preload("res://scripts/world/floor_config.gd")
const StoreData = preload("res://scripts/world/store_data.gd")
const FoodStallScript = preload("res://scripts/systems/food_stall.gd")
const ClawMachineScript = preload("res://scripts/amenities/claw_machine.gd")

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

const CELL_SIZE := FloorConfig.CELL_SIZE
const WORLD_W  := FloorConfig.WORLD_W
const WORLD_H  := FloorConfig.WORLD_H

var _floor_def: FloorConfig.FloorDef
var _parent: Node
var _floor_idx: int = 0
var _floor_nodes: Array = []
var _sections: Array = []
var _food_stalls: Array = []
var _claw_machines: Array = []
var _escalators: Array = []
var _checkout_counters: Array = []
var _aisle_labels: Array = []
var _stairs_system = null  # Reference to stairs system for registering stairs zones

signal section_interacted(section_id: String)
signal stall_interacted(stall_id: String)

func _init() -> void:
	pass

# Entry point — build an entire floor.
func build(floor_def: FloorConfig.FloorDef, parent: Node, floor_idx: int = 0, stairs_system = null) -> void:
	_floor_def = floor_def
	_parent = parent
	_floor_idx = floor_idx
	_stairs_system = stairs_system
	_floor_nodes.clear()
	_sections.clear()
	_food_stalls.clear()
	_claw_machines.clear()
	_escalators.clear()
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

func _build_zone(zone: Dictionary) -> void:
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
		FloorConfig.ZONE_ROOFTOP:      _build_zone_rooftop(zone)
		FloorConfig.ZONE_ELEVATOR:     _build_zone_shaft(zone)
		FloorConfig.ZONE_STAIRS:       _build_zone_stairs(zone)
		FloorConfig.ZONE_ESCALATOR:     _build_zone_escalator(zone)
		FloorConfig.ZONE_DECOR:        _build_zone_decor(zone)
		FloorConfig.ZONE_CLAW_MACHINE: _build_zone_claw_machine(zone)
		FloorConfig.ZONE_PET_ADOPTION: _build_zone_pet_adoption(zone)
		FloorConfig.ZONE_WAREHOUSE:    _build_zone_warehouse(zone)
		FloorConfig.ZONE_STORAGE_SHELF: _build_zone_storage_shelf(zone)
		FloorConfig.ZONE_ATM:          _build_zone_atm(zone)
		FloorConfig.ZONE_SHOES_RACK:   _build_zone_shoes_rack(zone)
		FloorConfig.ZONE_DRESS_RACK:   _build_zone_dress_rack(zone)
		FloorConfig.ZONE_SPORT_AREA:   _build_zone_sport_area(zone)
		FloorConfig.ZONE_OUTDOOR_AREA: _build_zone_outdoor_area(zone)
		FloorConfig.ZONE_STATIONERY:   _build_zone_stationery(zone)
		FloorConfig.ZONE_PLANTS_AREA:  _build_zone_plants_area(zone)
		FloorConfig.ZONE_LOCKER:       _build_zone_locker(zone)
		FloorConfig.ZONE_STAFF_LOUNGE: _build_zone_staff_lounge(zone)
		FloorConfig.ZONE_TRAINING:     _build_zone_training(zone)
		FloorConfig.ZONE_OFFICE_DESK:  _build_zone_office_desk(zone)
		FloorConfig.ZONE_EXEC_OFFICE:  _build_zone_exec_office(zone)
		FloorConfig.ZONE_AD:           _build_zone_ad(zone)
		FloorConfig.ZONE_MONITOR_ROOM: _build_zone_monitor_room(zone)
		FloorConfig.ZONE_HOME_DECOR:   _build_zone_home_decor(zone)
		FloorConfig.ZONE_FURNITURE:    _build_zone_furniture(zone)
		FloorConfig.ZONE_OUTDOOR_LIVING: _build_zone_outdoor_living(zone)
		FloorConfig.ZONE_ORGANIZATION: _build_zone_organization(zone)
		FloorConfig.ZONE_LIGHTING:     _build_zone_lighting(zone)
		FloorConfig.ZONE_CUSTOMER_SERVICE: _build_zone_customer_service(zone)
		FloorConfig.ZONE_LOYALTY_KIOSK: _build_zone_loyalty_kiosk(zone)
		FloorConfig.ZONE_GIFT_WRAP:    _build_zone_gift_wrap(zone)
		FloorConfig.ZONE_DIGITAL_KIOSK: _build_zone_digital_kiosk(zone)
		FloorConfig.ZONE_JUICE_BAR:    _build_zone_juice_bar(zone)
		FloorConfig.ZONE_HEALTH_FOOD:  _build_zone_health_food(zone)
		FloorConfig.ZONE_SMOOTHIE:     _build_zone_smoothie(zone)
		FloorConfig.ZONE_SALAD_BAR:    _build_zone_salad_bar(zone)
		FloorConfig.ZONE_KIDS_PLAY:    _build_zone_kids_play(zone)
		FloorConfig.ZONE_KIDS_CLOTHING: _build_zone_kids_clothing(zone)
		FloorConfig.ZONE_NURSING_ROOM: _build_zone_nursing_room(zone)
		FloorConfig.ZONE_FAMILY_WC:    _build_zone_family_wc(zone)
		FloorConfig.ZONE_KIDS_CLUB:    _build_zone_kids_club(zone)
		FloorConfig.ZONE_PHONE_GADGETS: _build_zone_phone_gadgets(zone)
		FloorConfig.ZONE_SMART_HOME:   _build_zone_smart_home(zone)
		FloorConfig.ZONE_ELECTRONICS:  _build_zone_electronics(zone)
		FloorConfig.ZONE_REPAIR_COUNTER: _build_zone_repair_counter(zone)
		FloorConfig.ZONE_CAFE_COUNTER: _build_zone_cafe_counter(zone)
		FloorConfig.ZONE_VENDING_MACHINE: _build_zone_vending_machine(zone)
		FloorConfig.ZONE_CANTEEN:      _build_zone_canteen(zone)
		FloorConfig.ZONE_KARAOKE:      _build_zone_karaoke(zone)
		FloorConfig.ZONE_POOL_TABLE:   _build_zone_pool_table(zone)
		FloorConfig.ZONE_DARTS_BOARD:  _build_zone_darts_board(zone)
		FloorConfig.ZONE_ENTERTAINMENT: _build_zone_entertainment(zone)
		FloorConfig.ZONE_PROMO_BOOTH: _build_zone_promo_booth(zone)
		FloorConfig.ZONE_WAREHOUSE_STOCK_VIEW: _build_zone_warehouse_stock_view(zone)
		FloorConfig.ZONE_STORE_NEWS: _build_zone_store_news(zone)
		FloorConfig.ZONE_LOST_FOUND: _build_zone_lost_found(zone)
		FloorConfig.ZONE_TRUCK_DOCK: _build_zone_truck_dock(zone)
		FloorConfig.ZONE_FORKLIFT: _build_zone_forklift(zone)
		FloorConfig.ZONE_CONVEYOR: _build_zone_conveyor(zone)
		# Unknown types are silently skipped (extensible)

# ═══════════════════════════════════════════════════════════════════════════════
# ZONE BUILDERS
# ═══════════════════════════════════════════════════════════════════════════════

func _build_zone_wall(zone: Dictionary) -> void:
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = _get_wall_base_color()
	_parent.add_child(r)
	_floor_nodes.append(r)

func _build_zone_aisle(zone: Dictionary) -> void:
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = Color(0.20, 0.19, 0.18)
	_parent.add_child(r)
	_floor_nodes.append(r)

func _build_zone_lobby(zone: Dictionary) -> void:
	# Delegate to LobbyHandler
	LobbyHandler.build_lobby(_parent, zone, _floor_nodes)

func _build_zone_parking(zone: Dictionary) -> void:
	var base := ColorRect.new()
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.color = Color(0.18, 0.18, 0.20)
	_parent.add_child(base)
	_floor_nodes.append(base)

	const SLOT_W := 6
	const SLOT_H := 3
	const SLOT_GAP := 1
	const NUM_SLOTS := 10
	var sx: int = zone.x + 2
	var sy: int = zone.y + 2
	var slot_idx := 0
	while sy + SLOT_H < zone.y + zone.h - 2 and slot_idx < NUM_SLOTS:
		var bay := ColorRect.new()
		bay.position = Vector2(sx * CELL_SIZE, sy * CELL_SIZE)
		bay.size = Vector2(SLOT_W * CELL_SIZE, SLOT_H * CELL_SIZE)
		bay.color = Color(0.21, 0.21, 0.23)
		_parent.add_child(bay)
		_floor_nodes.append(bay)

		for side in [sx, sx + SLOT_W - 1]:
			var line := ColorRect.new()
			line.position = Vector2(side * CELL_SIZE, sy * CELL_SIZE)
			line.size = Vector2(1, SLOT_H * CELL_SIZE)
			line.color = Color(0.80, 0.80, 0.80, 0.4)
			_parent.add_child(line)
			_floor_nodes.append(line)

		var top_l := ColorRect.new()
		top_l.position = Vector2(sx * CELL_SIZE, sy * CELL_SIZE)
		top_l.size = Vector2(SLOT_W * CELL_SIZE, 1)
		top_l.color = Color(0.80, 0.80, 0.80, 0.4)
		_parent.add_child(top_l)
		_floor_nodes.append(top_l)

		var bot_l := ColorRect.new()
		bot_l.position = Vector2(sx * CELL_SIZE, (sy + SLOT_H - 1) * CELL_SIZE)
		bot_l.size = Vector2(SLOT_W * CELL_SIZE, 1)
		bot_l.color = Color(0.80, 0.80, 0.80, 0.4)
		_parent.add_child(bot_l)
		_floor_nodes.append(bot_l)

		var num_lbl := Label.new()
		num_lbl.text = "%d" % (slot_idx + 1)
		num_lbl.position = Vector2((sx + SLOT_W * 0.5 - 0.5) * CELL_SIZE, (sy + SLOT_H * 0.5 - 0.5) * CELL_SIZE)
		num_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
		num_lbl.add_theme_font_size_override("font_size", 8)
		_parent.add_child(num_lbl)
		_floor_nodes.append(num_lbl)

		if slot_idx < 3:
			_add_parked_car(sx + SLOT_W / 2 - 1, sy + SLOT_H / 2, slot_idx)

		sx += SLOT_W + SLOT_GAP
		if sx + SLOT_W > zone.x + zone.w - 2:
			sx = zone.x + 2
			sy += SLOT_H + SLOT_GAP
		slot_idx += 1

func _add_parked_car(tile_x: int, tile_y: int, color_idx: int) -> void:
	var colors := [Color(0.75, 0.22, 0.18), Color(0.25, 0.40, 0.75), Color(0.30, 0.60, 0.30)]
	var col: Color = colors[color_idx % 3]
	var img := Image.create(5 * CELL_SIZE, 3 * CELL_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_img(img, CELL_SIZE, CELL_SIZE >> 1, CELL_SIZE * 3, CELL_SIZE, col)
	_fill_img(img, CELL_SIZE * 3 >> 1, 0, CELL_SIZE * 2, CELL_SIZE >> 1, col.darkened(0.15))
	_fill_img(img, CELL_SIZE * 5 >> 1, CELL_SIZE >> 2, CELL_SIZE, CELL_SIZE >> 1, Color(0.50, 0.70, 0.85))
	_fill_img(img, CELL_SIZE, (CELL_SIZE * 3) >> 2, CELL_SIZE, CELL_SIZE >> 2, Color(0.12, 0.12, 0.12))
	_fill_img(img, CELL_SIZE * 3, (CELL_SIZE * 3) >> 2, CELL_SIZE, CELL_SIZE >> 2, Color(0.12, 0.12, 0.12))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.position = Vector2((tile_x + 0.5) * CELL_SIZE, (tile_y + 0.5) * CELL_SIZE)
	spr.z_index = 3
	_parent.add_child(spr)
	_floor_nodes.append(spr)

func _fill_img(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, img.get_width()); y = clampi(y, 0, img.get_height())
	w = clampi(w, 0, img.get_width() - x); h = clampi(h, 0, img.get_height() - y)
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _build_zone_wc(zone: Dictionary) -> void:
	# Delegate to WCHandler
	WCHandler.build_wc(_parent, zone, _floor_nodes)

func _build_zone_info_desk(zone: Dictionary) -> void:
	# Delegate to ServiceAreaHandler
	ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, "ZONE_INFO_DESK")

func _get_floor_directory() -> String:
	return "F1:Fresh  F2:Pantry\nF3:Drinks  F4:Snacks\nF5:Frozen  F6:Home\nF7:Health  F8:Arcade\nF9:Staff  F10:Cafe"

func _build_zone_food_stall(zone: Dictionary) -> void:
	# Delegate to FoodStallHandler
	FoodStallHandler.build_food_stall(_parent, zone, _floor_nodes)

func _build_zone_food_court(zone: Dictionary) -> void:
	var floor_c := ColorRect.new()
	floor_c.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	floor_c.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	floor_c.color = Color(0.24, 0.20, 0.18)
	_parent.add_child(floor_c)
	_floor_nodes.append(floor_c)

	for i in range(4):
		var lx :int= (zone.x + 10 + i * 16) * CELL_SIZE
		var ly :int= (zone.y + 3) * CELL_SIZE
		var lantern := Sprite2D.new()
		lantern.position = Vector2(lx, ly)
		lantern.texture = _make_lantern()
		lantern.z_index = 4
		_parent.add_child(lantern)
		_floor_nodes.append(lantern)

	var table_positions := [
		Vector2i(zone.x + 20, zone.y + 10),
		Vector2i(zone.x + 32, zone.y + 10),
		Vector2i(zone.x + 44, zone.y + 10),
		Vector2i(zone.x + 20, zone.y + 22),
		Vector2i(zone.x + 32, zone.y + 22),
		Vector2i(zone.x + 44, zone.y + 22),
	]
	for tp in table_positions:
		_build_dining_table(tp.x, tp.y)

	var court_lbl := Label.new()
	court_lbl.text = "DINING COURT"
	court_lbl.position = Vector2((zone.x + zone.w * 0.5 - 5) * CELL_SIZE, (zone.y + zone.h - 3) * CELL_SIZE)
	court_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.50, 0.6))
	court_lbl.add_theme_font_size_override("font_size", 8)
	_parent.add_child(court_lbl); _floor_nodes.append(court_lbl)

func _build_dining_table(tile_x: int, tile_y: int) -> void:
	var top := ColorRect.new()
	top.position = Vector2(tile_x * CELL_SIZE, tile_y * CELL_SIZE)
	top.size = Vector2(3 * CELL_SIZE, 2 * CELL_SIZE)
	top.color = Color(0.52, 0.48, 0.42)
	_parent.add_child(top); _floor_nodes.append(top)

	var chair_offsets := [
		Vector2i(0, -1), Vector2i(2, -1),
		Vector2i(0, 2),  Vector2i(2, 2),
		Vector2i(-1, 0), Vector2i(3, 0),
	]
	for co in chair_offsets:
		var chair := ColorRect.new()
		chair.position = Vector2((tile_x + co.x) * CELL_SIZE, (tile_y + co.y) * CELL_SIZE)
		chair.size = Vector2(CELL_SIZE, CELL_SIZE)
		chair.color = Color(0.45, 0.42, 0.40)
		_parent.add_child(chair); _floor_nodes.append(chair)

func _build_zone_common(zone: Dictionary) -> void:
	# Delegate to CommonAreaHandler for better modularity
	CommonAreaHandler.build_common_area(_parent, zone, _floor_nodes)
	CommonAreaHandler.build_floor_path(_parent, zone, _floor_nodes)

func _build_zone_rooftop(zone: Dictionary) -> void:
	var r := ColorRect.new()
	r.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	r.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	r.color = Color(0.45, 0.60, 0.75, 1.0)
	_parent.add_child(r); _floor_nodes.append(r)

	var lbl := Label.new()
	lbl.text = "ROOFTOP CAFE"
	lbl.position = Vector2((zone.x + zone.w * 0.5 - 6) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(0.90, 0.88, 0.80))
	lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(lbl); _floor_nodes.append(lbl)

	for tx in range(zone.x + 4, zone.x + zone.w - 6, 10):
		for ty in range(zone.y + 6, zone.y + zone.h - 4, 8):
			_build_dining_table(tx, ty)

func _build_zone_shaft(zone: Dictionary) -> void:
	# Delegate to ElevatorHandler for better modularity
	ElevatorHandler.build_elevator(_parent, zone, _floor_nodes)
	# Add call button panel
	ElevatorHandler.build_elevator_call_button(_parent, zone, _floor_nodes, _floor_def.label)

func _build_zone_stairs(zone: Dictionary) -> void:
	# Delegate to StairsHandler for better modularity
	StairsHandler.build_stairs(_parent, zone, _floor_nodes)
	
	# Register this stairs zone with the stairs system for open-world floor navigation
	if _stairs_system != null and _stairs_system.has_method("register_stairs_zone"):
		var direction: int = 1  # Default: stairs go UP to next floor
		if zone.has("meta") and zone.meta.has("direction"):
			direction = zone.meta.direction
		_stairs_system.register_stairs_zone(_floor_idx, zone, direction)

func _build_zone_escalator(zone: Dictionary) -> void:
	var escalator_id: String = zone.meta.get("escalator_id", "escalator_%d" % _floor_idx)
	
	var esc := preload("res://scripts/systems/escalator.gd").new()
	esc.configure(zone, escalator_id, _floor_idx)
	esc.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	esc.name = "Escalator_%s" % escalator_id
	_parent.add_child(esc)
	_escalators.append(esc)

func _build_zone_decor(zone: Dictionary) -> void:
	# Delegate to MiscHandler
	MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_DECOR")

func _build_planter(px: int, py: int, pw: int, ph: int) -> void:
	var box := ColorRect.new()
	box.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	box.size = Vector2(pw * CELL_SIZE, ph * CELL_SIZE)
	box.color = Color(0.20, 0.16, 0.12)
	_parent.add_child(box); _floor_nodes.append(box)
	var top := ColorRect.new()
	top.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	top.size = Vector2(pw * CELL_SIZE, 2)
	top.color = Color(0.30, 0.52, 0.22)
	_parent.add_child(top); _floor_nodes.append(top)

func _build_prize_shelf(px: int, py: int, pw: int, ph: int) -> void:
	var back := ColorRect.new()
	back.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	back.size = Vector2(pw * CELL_SIZE, ph * CELL_SIZE)
	back.color = Color(0.08, 0.08, 0.14)
	_parent.add_child(back); _floor_nodes.append(back)

	var trim_col := Color(0.50, 0.30, 0.80)
	var trim_top := ColorRect.new()
	trim_top.position = Vector2(px * CELL_SIZE, py * CELL_SIZE)
	trim_top.size = Vector2(pw * CELL_SIZE, 2)
	trim_top.color = trim_col
	_parent.add_child(trim_top); _floor_nodes.append(trim_top)

	var row_colors := [
		Color(0.90, 0.30, 0.30),
		Color(0.30, 0.75, 0.90),
		Color(0.90, 0.70, 0.20),
	]
	for row in range(3):
		var shelf_y := (py + 1 + row * ((ph - 1) / 3)) * CELL_SIZE
		var shelf := ColorRect.new()
		shelf.position = Vector2(px * CELL_SIZE, shelf_y)
		shelf.size = Vector2(pw * CELL_SIZE, 2)
		shelf.color = Color(0.40, 0.35, 0.30)
		_parent.add_child(shelf); _floor_nodes.append(shelf)

		for col in range(3):
			var prize_x := (px + 1 + col * ((pw - 2) / 3)) * CELL_SIZE
			var prize_y := shelf_y - CELL_SIZE * 2
			var spr := Sprite2D.new()
			spr.position = Vector2(prize_x + CELL_SIZE, prize_y + CELL_SIZE)
			spr.texture = _make_plush_texture(row_colors[row])
			spr.z_index = 3
			_parent.add_child(spr); _floor_nodes.append(spr)

	var prize_lbl := Label.new()
	prize_lbl.text = "PRIZES"
	prize_lbl.position = Vector2((px + pw * 0.5 - 2) * CELL_SIZE, (py - 2) * CELL_SIZE)
	prize_lbl.add_theme_color_override("font_color", Color(0.80, 0.40, 1.0))
	prize_lbl.add_theme_font_size_override("font_size", 9)
	_parent.add_child(prize_lbl); _floor_nodes.append(prize_lbl)

func _build_zone_pet_adoption(zone: Dictionary) -> void:
	var adopt_name: String = zone.meta.get("name", "ADOPTION")
	var adopt_color: Color = zone.meta.get("color", Color(0.60, 0.88, 0.70))
	var cx :int= zone.x * CELL_SIZE
	var cy :int= zone.y * CELL_SIZE
	var cw :int= zone.w * CELL_SIZE
	var ch :int= zone.h * CELL_SIZE

	var bg := ColorRect.new()
	bg.position = Vector2(cx, cy)
	bg.size = Vector2(cw, ch)
	bg.color = Color(0.18, 0.28, 0.20)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var trim := ColorRect.new()
	trim.position = Vector2(cx, cy)
	trim.size = Vector2(cw, 3)
	trim.color = adopt_color
	_parent.add_child(trim); _floor_nodes.append(trim)

	var trim_bot := ColorRect.new()
	trim_bot.position = Vector2(cx, cy + ch - 3)
	trim_bot.size = Vector2(cw, 3)
	trim_bot.color = adopt_color
	_parent.add_child(trim_bot); _floor_nodes.append(trim_bot)

	var kennel_colors := [Color(0.70, 0.60, 0.45), Color(0.55, 0.50, 0.48), Color(0.65, 0.58, 0.52)]
	var cage_w := cw / 3.5
	for i in range(3):
		var kx := cx + 8 + i * (cage_w + 8)
		var ky := cy + 12
		var cage_h := ch - 24

		var frame := ColorRect.new()
		frame.position = Vector2(kx, ky)
		frame.size = Vector2(cage_w, cage_h)
		frame.color = kennel_colors[i]
		_parent.add_child(frame); _floor_nodes.append(frame)

		for b in range(4):
			var bx := kx + (b + 1) * cage_w / 5.0
			var bar := ColorRect.new()
			bar.position = Vector2(bx, ky)
			bar.size = Vector2(2, cage_h)
			bar.color = Color(0.35, 0.30, 0.25)
			_parent.add_child(bar); _floor_nodes.append(bar)

		var pet_tex := _make_pet_sprite(i)
		var pet_spr := Sprite2D.new()
		pet_spr.texture = pet_tex
		pet_spr.position = Vector2(kx + cage_w * 0.5, ky + cage_h * 0.5)
		pet_spr.z_index = 3
		_parent.add_child(pet_spr); _floor_nodes.append(pet_spr)

	var sign_lbl := Label.new()
	sign_lbl.text = adopt_name
	sign_lbl.position = Vector2(cx + 4, cy - 14)
	sign_lbl.add_theme_color_override("font_color", adopt_color.lightened(0.2))
	sign_lbl.add_theme_font_size_override("font_size", 10)
	_parent.add_child(sign_lbl); _floor_nodes.append(sign_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Meet your new best friend!"
	sub_lbl.position = Vector2(cx + 4, cy - 6)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 0.78))
	sub_lbl.add_theme_font_size_override("font_size", 6)
	_parent.add_child(sub_lbl); _floor_nodes.append(sub_lbl)

func _make_pet_sprite(pet_type: int) -> Texture2D:
	var W := 20; var H := 20
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	match pet_type:
		0:  # Dog
			for y in range(6, 15):
				for x in range(4, 16):
					img.set_pixel(x, y, Color(0.62, 0.42, 0.22))
			for y in range(2, 10):
				for x in range(8, 16):
					img.set_pixel(x, y, Color(0.68, 0.48, 0.25))
			for y in range(2, 8):
				img.set_pixel(8, y, Color(0.52, 0.32, 0.18))
				img.set_pixel(7, y, Color(0.52, 0.32, 0.18))
			img.set_pixel(13, 5, Color(0.08, 0.06, 0.06))
			img.set_pixel(15, 7, Color(0.12, 0.08, 0.08))
		1:  # Cat
			for y in range(8, 15):
				for x in range(5, 15):
					img.set_pixel(x, y, Color(0.52, 0.52, 0.58))
			for y in range(2, 10):
				for x in range(6, 14):
					img.set_pixel(x, y, Color(0.55, 0.55, 0.60))
			img.set_pixel(7, 2, Color(0.55, 0.55, 0.60)); img.set_pixel(8, 1, Color(0.55, 0.55, 0.60)); img.set_pixel(9, 2, Color(0.55, 0.55, 0.60))
			img.set_pixel(11, 2, Color(0.55, 0.55, 0.60)); img.set_pixel(12, 1, Color(0.55, 0.55, 0.60)); img.set_pixel(13, 2, Color(0.55, 0.55, 0.60))
			img.set_pixel(9, 5, Color(0.10, 0.70, 0.10)); img.set_pixel(12, 5, Color(0.10, 0.70, 0.10))
			img.set_pixel(10, 7, Color(0.80, 0.55, 0.60))
			for wx in range(2, 6): img.set_pixel(wx, 7, Color(0.80, 0.80, 0.85))
			for wx in range(14, 18): img.set_pixel(wx, 7, Color(0.80, 0.80, 0.85))
		2:  # Rabbit
			for y in range(10, 17):
				for x in range(6, 14):
					img.set_pixel(x, y, Color(0.95, 0.95, 0.92))
			for y in range(4, 12):
				for x in range(7, 13):
					img.set_pixel(x, y, Color(0.97, 0.97, 0.94))
			for y in range(0, 7):
				img.set_pixel(7, y, Color(0.97, 0.97, 0.94)); img.set_pixel(8, y, Color(0.97, 0.97, 0.94))
				img.set_pixel(11, y, Color(0.97, 0.97, 0.94)); img.set_pixel(12, y, Color(0.97, 0.97, 0.94))
			img.set_pixel(8, 2, Color(0.90, 0.65, 0.72)); img.set_pixel(11, 2, Color(0.90, 0.65, 0.72))
			img.set_pixel(9, 6, Color(0.90, 0.10, 0.15)); img.set_pixel(11, 6, Color(0.90, 0.10, 0.15))
			img.set_pixel(10, 9, Color(0.90, 0.58, 0.65))

	return ImageTexture.create_from_image(img)

func _build_zone_warehouse(zone: Dictionary) -> void:
	# Delegate to WarehouseHandler
	WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_WAREHOUSE")

func _make_crate_texture(rack_idx: int, row_idx: int) -> Texture2D:
	var W := 12; var H := 12
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var crate_color := Color(0.65, 0.52, 0.38)
	if rack_idx % 3 == 1:
		crate_color = Color(0.55, 0.48, 0.40)
	elif rack_idx % 3 == 2:
		crate_color = Color(0.70, 0.55, 0.42)

	for y in range(1, H - 1):
		for x in range(1, W - 1):
			img.set_pixel(x, y, crate_color)

	for x in range(W):
		img.set_pixel(x, 0, crate_color.darkened(0.2))
		img.set_pixel(x, H - 1, crate_color.darkened(0.2))
	for y in range(H):
		img.set_pixel(0, y, crate_color.darkened(0.2))
		img.set_pixel(W - 1, y, crate_color.darkened(0.2))

	for x in range(W):
		img.set_pixel(x, H / 2, crate_color.lightened(0.2))

	return ImageTexture.create_from_image(img)

func _build_zone_storage_shelf(zone: Dictionary) -> void:
	# Delegate to WarehouseHandler
	WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_STORAGE_SHELF")

func _build_zone_atm(zone: Dictionary) -> void:
	# Delegate to MiscHandler
	MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_ATM")

func _build_zone_claw_machine(zone: Dictionary) -> void:
	var machine_id: String = zone.meta.get("machine_id", "claw_1")
	var prize_pool_idx: int = zone.meta.get("prize_pool", 0)

	var prize_pools := [
		[Color(0.90, 0.30, 0.30), Color(0.90, 0.45, 0.45), Color(0.85, 0.25, 0.25)],
		[Color(0.30, 0.75, 0.90), Color(0.40, 0.80, 0.95), Color(0.25, 0.65, 0.85)],
		[Color(0.90, 0.70, 0.20), Color(0.85, 0.75, 0.25), Color(0.80, 0.60, 0.15)],
		[Color(0.55, 0.90, 0.40), Color(0.88, 0.45, 0.85), Color(0.90, 0.55, 0.30)],
	]
	var pool: Array = prize_pools[prize_pool_idx % prize_pools.size()]

	var machine := ClawMachineScript.new()
	machine.configure(zone, machine_id)
	machine.build(pool)
	machine.name = "Claw_%s" % machine_id
	_parent.add_child(machine)
	_claw_machines.append(machine)

func _build_zone_shoes_rack(zone: Dictionary) -> void:
	# Delegate to ShoesRackHandler for better modularity
	ShoesRackHandler.build_shoes_rack(_parent, zone, _floor_nodes)

func _build_zone_dress_rack(zone: Dictionary) -> void:
	# Delegate to DressRackHandler for better modularity
	DressRackHandler.build_dress_rack(_parent, zone, _floor_nodes)

func _build_zone_sport_area(zone: Dictionary) -> void:
	# Delegate to SportAreaHandler for better modularity
	SportAreaHandler.build_sport_area(_parent, zone, _floor_nodes)

func _build_zone_entertainment(zone: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = zone.meta.get("color", Color(0.25, 0.20, 0.35))
	bg.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_parent.add_child(bg); _floor_nodes.append(bg)

	for xi in range(0, zone.w, 6):
		var neon := ColorRect.new()
		neon.color = Color(0.6, 0.1, 0.8, 0.8)
		neon.size = Vector2(4, 2)
		neon.position = Vector2((zone.x + xi) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
		_parent.add_child(neon); _floor_nodes.append(neon)

func _build_zone_canteen(zone: Dictionary) -> void:
	var base := ColorRect.new()
	base.color = zone.meta.get("color", Color(0.55, 0.50, 0.42))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_parent.add_child(base); _floor_nodes.append(base)

	var counter := ColorRect.new()
	counter.color = Color(0.65, 0.60, 0.50)
	counter.size = Vector2(zone.w * CELL_SIZE, 6)
	counter.position = Vector2(zone.x * CELL_SIZE, (zone.y + 4) * CELL_SIZE)
	_parent.add_child(counter); _floor_nodes.append(counter)

	var ctop := ColorRect.new()
	ctop.color = Color(0.75, 0.72, 0.65)
	ctop.size = Vector2(zone.w * CELL_SIZE, 2)
	ctop.position = Vector2(zone.x * CELL_SIZE, (zone.y + 4) * CELL_SIZE)
	_parent.add_child(ctop); _floor_nodes.append(ctop)

	for ti in range(4, zone.w - 4, 8):
		for row in range(2):
			var table := ColorRect.new()
			table.color = Color(0.50, 0.45, 0.38)
			table.size = Vector2(6 * CELL_SIZE, 4 * CELL_SIZE)
			table.position = Vector2((zone.x + ti) * CELL_SIZE, (zone.y + 10 + row * 10) * CELL_SIZE)
			_parent.add_child(table); _floor_nodes.append(table)

func _build_zone_karaoke(zone: Dictionary) -> void:
	var base := ColorRect.new()
	base.color = zone.meta.get("color", Color(0.20, 0.15, 0.28))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_parent.add_child(base); _floor_nodes.append(base)

	var room_w := 14
	var rooms :int= zone.w / room_w
	for r in range(rooms):
		var room_bg := ColorRect.new()
		room_bg.color = Color(0.18 + r * 0.04, 0.12, 0.22 + r * 0.03)
		room_bg.size = Vector2((room_w - 1) * CELL_SIZE, (zone.h - 4) * CELL_SIZE)
		room_bg.position = Vector2((zone.x + 1 + r * room_w) * CELL_SIZE, (zone.y + 2) * CELL_SIZE)
		_parent.add_child(room_bg); _floor_nodes.append(room_bg)

		var lbl := Label.new()
		lbl.text = "%d" % (r + 1)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.9))
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.position = Vector2((zone.x + 5 + r * room_w) * CELL_SIZE, (zone.y + 3) * CELL_SIZE)
		_parent.add_child(lbl); _floor_nodes.append(lbl)

func _build_zone_pool_table(zone: Dictionary) -> void:
	var base := ColorRect.new()
	base.color = zone.meta.get("color", Color(0.28, 0.52, 0.38))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_parent.add_child(base); _floor_nodes.append(base)

	var felt := ColorRect.new()
	felt.color = Color(0.30, 0.60, 0.38)
	felt.size = Vector2(16 * CELL_SIZE, 8 * CELL_SIZE)
	felt.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_parent.add_child(felt); _floor_nodes.append(felt)

	var rails = [
		{"x": 0, "y": -1, "w": 16, "h": 1},
		{"x": 0, "y": 8, "w": 16, "h": 1},
		{"x": -1, "y": 0, "w": 1, "h": 8},
		{"x": 16, "y": 0, "w": 1, "h": 8}
	]

	for rail in rails:
		var r := ColorRect.new()
		r.color = Color(0.40, 0.25, 0.15)
		r.size = Vector2(rail.w * CELL_SIZE, rail.h * CELL_SIZE)
		r.position = Vector2((zone.x + rail.x) * CELL_SIZE, (zone.y + rail.y) * CELL_SIZE)
		_parent.add_child(r)
		_floor_nodes.append(r)

	var px_list = [0, 15, 0, 15]
	var py_list = [0, 0, 7, 7]

	for i in range(px_list.size()):
		var px = px_list[i]
		var py = py_list[i]
		var pocket := ColorRect.new()
		pocket.color = Color(0.05, 0.05, 0.05)
		pocket.size = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
		pocket.position = Vector2((zone.x + px) * CELL_SIZE, (zone.y + py) * CELL_SIZE)
		_parent.add_child(pocket)
		_floor_nodes.append(pocket)

	var ball_colors := [
		Color(1,1,1), Color(1,0.8,0), Color(0,0,0.8), 
		Color(0.8,0,0), Color(0.9,0.4,0), Color(0.2,0.5,0.2), 
		Color(0.7,0.1,0.1), Color(0.8,0.3,0.3), Color(0.1,0.1,0.5)
	]

	var ball_positions: Array[Array] = [
		[3,1], [5,2], [7,3], [4,4], 
		[6,3], [3,5], [5,5], [2,3], [4,2]
	]

	for i in range(ball_positions.size()):
		if i < ball_colors.size():
			var bx: int = ball_positions[i][0]
			var by: int = ball_positions[i][1]
			var ball := ColorRect.new()
			ball.color = ball_colors[i]
			ball.size = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
			ball.position = Vector2((zone.x + bx) * CELL_SIZE, (zone.y + by) * CELL_SIZE)
			_parent.add_child(ball)
			_floor_nodes.append(ball)

func _build_zone_darts_board(zone: Dictionary) -> void:
	var base := ColorRect.new()
	base.color = zone.meta.get("color", Color(0.30, 0.32, 0.25))
	base.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	base.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	_parent.add_child(base); _floor_nodes.append(base)

	var cx :int= zone.x + zone.w / 2
	var cy :int= zone.y + zone.h / 2
	var radii := [8, 6, 4, 2]
	var colors := [Color(0.1, 0.5, 0.1), Color(0.8, 0.8, 0.8), Color(0.8, 0.1, 0.1), Color(0.1, 0.7, 0.1)]
	for i in range(radii.size()):
		var r = radii[i]
		var col = colors[i]
		var circle := ColorRect.new()
		circle.color = col
		circle.size = Vector2(r * 2 * CELL_SIZE, r * 2 * CELL_SIZE)
		circle.position = Vector2((cx - r) * CELL_SIZE, (cy - r) * CELL_SIZE)
		_parent.add_child(circle)
		_floor_nodes.append(circle)

	var bull := ColorRect.new()
	bull.color = Color(0.9, 0.2, 0.2)
	bull.size = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
	bull.position = Vector2(cx * CELL_SIZE, cy * CELL_SIZE)
	_parent.add_child(bull); _floor_nodes.append(bull)

func _build_zone_vending_machine(zone: Dictionary) -> void:
	# Delegate to MiscHandler
	MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_VENDING_MACHINE")

# ═══════════════════════════════════════════════════════════════════════════════
# STUB ZONE BUILDERS (placeholders for future implementation)
# ═══════════════════════════════════════════════════════════════════════════════

func _build_zone_outdoor_area(zone: Dictionary) -> void:
	# Delegate to OutdoorAreaHandler for better modularity
	OutdoorAreaHandler.build_outdoor_area(_parent, zone, _floor_nodes)

func _build_zone_stationery(zone: Dictionary) -> void:
	# Delegate to StationeryHandler for better modularity
	StationeryHandler.build_stationery(_parent, zone, _floor_nodes)

func _build_zone_plants_area(zone: Dictionary) -> void:
	# Delegate to PlantsAreaHandler for better modularity
	PlantsAreaHandler.build_plants_area(_parent, zone, _floor_nodes)

func _build_zone_locker(zone: Dictionary) -> void:
	# Delegate to LockerHandler for better modularity
	LockerHandler.build_locker(_parent, zone, _floor_nodes)

func _build_zone_staff_lounge(zone: Dictionary) -> void:
	# Delegate to StaffLoungeHandler for better modularity
	StaffLoungeHandler.build_staff_lounge(_parent, zone, _floor_nodes)

func _build_zone_training(zone: Dictionary) -> void:
	# Delegate to TrainingHandler for better modularity
	TrainingHandler.build_training(_parent, zone, _floor_nodes)

func _build_zone_office_desk(zone: Dictionary) -> void:
	# Delegate to OfficeDeskHandler for better modularity
	OfficeDeskHandler.build_office_desk(_parent, zone, _floor_nodes)

func _build_zone_exec_office(zone: Dictionary) -> void:
	# Delegate to ExecOfficeHandler for better modularity
	ExecOfficeHandler.build_exec_office(_parent, zone, _floor_nodes)

func _build_zone_ad(zone: Dictionary) -> void:
	# Delegate to AdDisplayHandler for better modular display
	AdDisplayHandler.build_ad_display(_parent, zone, _floor_nodes, _floor_idx)

func _build_zone_monitor_room(zone: Dictionary) -> void:
	# Delegate to MonitorRoomHandler for better modularity
	MonitorRoomHandler.build_monitor_room(_parent, zone, _floor_nodes)

func _build_zone_home_decor(zone: Dictionary) -> void:
	_build_generic_zone(zone, "HOME DECOR", Color(0.78, 0.65, 0.50))

func _build_zone_furniture(zone: Dictionary) -> void:
	_build_generic_zone(zone, "FURNITURE", Color(0.65, 0.55, 0.48))

func _build_zone_outdoor_living(zone: Dictionary) -> void:
	_build_generic_zone(zone, "OUTDOOR LIVING", Color(0.55, 0.70, 0.52))

func _build_zone_organization(zone: Dictionary) -> void:
	_build_generic_zone(zone, "ORGANIZATION", Color(0.60, 0.60, 0.70))

func _build_zone_lighting(zone: Dictionary) -> void:
	_build_generic_zone(zone, "LIGHTING", Color(0.90, 0.85, 0.60))

func _build_zone_customer_service(zone: Dictionary) -> void:
	# Delegate to ServiceAreaHandler
	ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, "ZONE_CUSTOMER_SERVICE")

func _build_zone_loyalty_kiosk(zone: Dictionary) -> void:
	# Delegate to ServiceAreaHandler
	ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, "ZONE_LOYALTY_KIOSK")

func _build_zone_gift_wrap(zone: Dictionary) -> void:
	# Delegate to ServiceAreaHandler
	ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, "ZONE_GIFT_WRAP")

func _build_zone_digital_kiosk(zone: Dictionary) -> void:
	# Delegate to ServiceAreaHandler
	ServiceAreaHandler.build_service_area(_parent, zone, _floor_nodes, "ZONE_DIGITAL_KIOSK")

func _build_zone_juice_bar(zone: Dictionary) -> void:
	_build_generic_zone(zone, "JUICE BAR", Color(0.90, 0.70, 0.40))

func _build_zone_health_food(zone: Dictionary) -> void:
	_build_generic_zone(zone, "HEALTH FOOD", Color(0.50, 0.75, 0.55))

func _build_zone_smoothie(zone: Dictionary) -> void:
	_build_generic_zone(zone, "SMOOTHIE", Color(0.75, 0.50, 0.70))

func _build_zone_salad_bar(zone: Dictionary) -> void:
	_build_generic_zone(zone, "SALAD BAR", Color(0.60, 0.80, 0.50))

func _build_zone_kids_play(zone: Dictionary) -> void:
	_build_generic_zone(zone, "KIDS PLAY", Color(0.70, 0.60, 0.90))

func _build_zone_kids_clothing(zone: Dictionary) -> void:
	_build_generic_zone(zone, "KIDS CLOTHING", Color(0.80, 0.65, 0.70))

func _build_zone_nursing_room(zone: Dictionary) -> void:
	_build_generic_zone(zone, "NURSING ROOM", Color(0.85, 0.75, 0.80))

func _build_zone_family_wc(zone: Dictionary) -> void:
	_build_generic_zone(zone, "FAMILY WC", Color(0.70, 0.75, 0.80))

func _build_zone_kids_club(zone: Dictionary) -> void:
	_build_generic_zone(zone, "KIDS CLUB", Color(0.65, 0.55, 0.85))

func _build_zone_phone_gadgets(zone: Dictionary) -> void:
	_build_generic_zone(zone, "PHONES", Color(0.40, 0.45, 0.55))

func _build_zone_smart_home(zone: Dictionary) -> void:
	_build_generic_zone(zone, "SMART HOME", Color(0.45, 0.55, 0.65))

func _build_zone_electronics(zone: Dictionary) -> void:
	_build_generic_zone(zone, "ELECTRONICS", Color(0.35, 0.45, 0.60))

func _build_zone_repair_counter(zone: Dictionary) -> void:
	_build_generic_zone(zone, "REPAIR", Color(0.55, 0.50, 0.45))

func _build_zone_cafe_counter(zone: Dictionary) -> void:
	_build_generic_zone(zone, "CAFE", Color(0.65, 0.50, 0.40))

func _build_zone_promo_booth(zone: Dictionary) -> void:
	# Delegate to MiscHandler
	MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_PROMO_BOOTH")

func _build_zone_lost_found(zone: Dictionary) -> void:
	# Delegate to MiscHandler
	MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_LOST_FOUND")

func _build_zone_store_news(zone: Dictionary) -> void:
	# Delegate to MiscHandler
	MiscHandler.build_misc_area(_parent, zone, _floor_nodes, "ZONE_STORE_NEWS")

func _build_zone_truck_dock(zone: Dictionary) -> void:
	# Delegate to WarehouseHandler
	WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_TRUCK_DOCK")

func _build_zone_forklift(zone: Dictionary) -> void:
	# Delegate to WarehouseHandler
	WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_FORKLIFT")

func _build_zone_conveyor(zone: Dictionary) -> void:
	# Delegate to WarehouseHandler
	WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_CONVEYOR")

func _build_zone_warehouse_stock_view(zone: Dictionary) -> void:
	# Delegate to WarehouseHandler
	WarehouseHandler.build_warehouse_area(_parent, zone, _floor_nodes, "ZONE_WAREHOUSE_STOCK_VIEW")

func _build_generic_zone(zone: Dictionary, label: String, base_color: Color) -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(zone.x * CELL_SIZE, zone.y * CELL_SIZE)
	bg.size = Vector2(zone.w * CELL_SIZE, zone.h * CELL_SIZE)
	bg.color = base_color.darkened(0.35)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var title_lbl := Label.new()
	title_lbl.text = label
	title_lbl.position = Vector2((zone.x + 1) * CELL_SIZE, (zone.y + 1) * CELL_SIZE)
	title_lbl.add_theme_color_override("font_color", base_color.lightened(0.3))
	title_lbl.add_theme_font_size_override("font_size", 9)
	_parent.add_child(title_lbl); _floor_nodes.append(title_lbl)

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION ZONES & CHECKOUT
# ═══════════════════════════════════════════════════════════════════════════════

func _build_section_zones() -> void:
	for sz in _floor_def.section_zones:
		_build_section_zone(sz)

func _build_section_zone(sz: Dictionary) -> void:
	var def = StoreData.get_section_def(sz.get("id", ""))
	if def == null:
		return

	var bg := ColorRect.new()
	bg.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	bg.size = Vector2(sz.w * CELL_SIZE, sz.h * CELL_SIZE)
	bg.color = _get_section_floor(def.style)
	_parent.add_child(bg); _floor_nodes.append(bg)

	var wc := _get_section_wall_color(def.style)
	var tw := ColorRect.new()
	tw.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	tw.size = Vector2(sz.w * CELL_SIZE, 2)
	tw.color = wc; _parent.add_child(tw); _floor_nodes.append(tw)

	var bw := ColorRect.new()
	bw.position = Vector2(sz.x * CELL_SIZE, (sz.y + sz.h - 1) * CELL_SIZE)
	bw.size = Vector2(sz.w * CELL_SIZE, 2)
	bw.color = wc.darkened(0.15); _parent.add_child(bw); _floor_nodes.append(bw)

	var lw := ColorRect.new()
	lw.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	lw.size = Vector2(2, sz.h * CELL_SIZE)
	lw.color = wc.darkened(0.1); _parent.add_child(lw); _floor_nodes.append(lw)

	var rw := ColorRect.new()
	rw.position = Vector2((sz.x + sz.w - 1) * CELL_SIZE, sz.y * CELL_SIZE)
	rw.size = Vector2(2, sz.h * CELL_SIZE)
	rw.color = wc.darkened(0.2); _parent.add_child(rw); _floor_nodes.append(rw)

	var glow := Sprite2D.new()
	glow.position = Vector2((sz.x + sz.w * 0.5) * CELL_SIZE, (sz.y - 6) * CELL_SIZE)
	glow.texture = _make_glow(def.light_color)
	_parent.add_child(glow); _floor_nodes.append(glow)

	var sign := _make_sign(def, sz.w, sz.h)
	sign.position = Vector2((sz.x + sz.w * 0.5) * CELL_SIZE, (sz.y + 1) * CELL_SIZE)
	_parent.add_child(sign); _floor_nodes.append(sign)

	var sec := preload("res://scripts/world/section.gd").new()
	sec.configure(def)
	sec.position = Vector2(sz.x * CELL_SIZE, sz.y * CELL_SIZE)
	sec.name = "Section_%s" % def.id
	_parent.add_child(sec)
	_sections.append(sec)

	var lbl := Label.new()
	lbl.text = def.name
	lbl.position = Vector2((sz.x + 1) * CELL_SIZE, (sz.y + sz.h + 1) * CELL_SIZE)
	lbl.add_theme_color_override("font_color", Color(def.light_color.r * 0.7, def.light_color.g * 0.7, def.light_color.b * 0.7, 0.8))
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.z_index = 6
	_parent.add_child(lbl); _aisle_labels.append(lbl)

func _build_checkout_if_needed() -> void:
	if not _floor_def.has_checkout:
		return
	var lanes := StoreData.CHECKOUT_LANES
	var CHECKOUT_Y := StoreData.CHECKOUT_Y
	var counter_id := 0
	for lane in lanes:
		var lane_floors: Array = lane.get("floors", [])
		if not lane_floors.is_empty() and not lane_floors.has(_floor_idx):
			continue

		var ctype_str: String = lane.get("type", "staffed")
		var ctype: int  # CheckoutCounter.CheckoutType
		match ctype_str:
			"self": ctype = 1  # SELF
			"express": ctype = 2  # EXPRESS
			_: ctype = 0  # STAFFED

		var counter := preload("res://scripts/systems/checkout_counter.gd").new()
		counter.configure(counter_id, ctype)
		counter.position = Vector2(lane["x"] * CELL_SIZE, (CHECKOUT_Y + 2) * CELL_SIZE)
		counter.name = "Counter_%s" % lane["name"]
		_parent.add_child(counter)
		_checkout_counters.append(counter)
		counter_id += 1

# ═══════════════════════════════════════════════════════════════════════════════
# FLOOR SIGN & SHAFT
# ═══════════════════════════════════════════════════════════════════════════════

func _build_floor_sign() -> void:
	var sign_bg := ColorRect.new()
	sign_bg.position = Vector2(2 * CELL_SIZE, 2 * CELL_SIZE)
	sign_bg.size = Vector2(8 * CELL_SIZE, 2 * CELL_SIZE)
	sign_bg.color = Color(0.06, 0.06, 0.10, 0.85)
	_parent.add_child(sign_bg); _floor_nodes.append(sign_bg)

	var theme_lbl := Label.new()
	theme_lbl.text = "Floor %s — %s" % [_floor_def.label, _floor_def.theme.replace("_", " ").capitalize()]
	theme_lbl.position = Vector2(2.5 * CELL_SIZE, 2.3 * CELL_SIZE)
	theme_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.60))
	theme_lbl.add_theme_font_size_override("font_size", 8)
	_parent.add_child(theme_lbl); _floor_nodes.append(theme_lbl)

func _build_shaft_visuals() -> void:
	if not _floor_def.has_elevator:
		return
	var shaft_x :=  6
	var floor_config := FloorConfig.new()
	for floor_i in range(floor_config.floor_count()):
		var fy := _floor_y_in_shaft(floor_i)
		var dot := ColorRect.new()
		dot.position = Vector2((shaft_x + 0.5) * CELL_SIZE, fy)
		dot.size = Vector2(CELL_SIZE, 4)
		var is_current := (floor_i == _floor_def.index)
		dot.color = Color(0.20, 0.85, 0.45) if is_current else Color(0.40, 0.38, 0.35)
		_parent.add_child(dot); _floor_nodes.append(dot)

func _floor_y_in_shaft(floor_idx: int) -> float:
	var base_y := (WORLD_H - 6) * CELL_SIZE
	var floor_spacing := 4.0 * CELL_SIZE
	return base_y - floor_idx * floor_spacing

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

func _get_wall_base_color() -> Color:
	return Color(0.38, 0.35, 0.32)

func _get_section_floor(style: int) -> Color:
	match style:
		StoreData.SectionStyle.FRIDGE:   return Color(0.14, 0.18, 0.24)
		StoreData.SectionStyle.PRODUCE:  return Color(0.14, 0.19, 0.12)
		StoreData.SectionStyle.BAKERY:   return Color(0.20, 0.15, 0.10)
		StoreData.SectionStyle.SHELF:    return Color(0.17, 0.16, 0.15)
		StoreData.SectionStyle.DELI:     return Color(0.19, 0.13, 0.13)
		StoreData.SectionStyle.FREEZER:  return Color(0.12, 0.16, 0.22)
		StoreData.SectionStyle.SHOES_RACK: return Color(0.18, 0.15, 0.14)
		StoreData.SectionStyle.DRESS_RACK: return Color(0.16, 0.15, 0.18)
		StoreData.SectionStyle.SPORT_AREA: return Color(0.15, 0.17, 0.16)
	return Color(0.18, 0.17, 0.16)

func _get_section_wall_color(style: int) -> Color:
	match style:
		StoreData.SectionStyle.FRIDGE:   return Color(0.60, 0.78, 0.95)
		StoreData.SectionStyle.PRODUCE:  return Color(0.60, 0.82, 0.50)
		StoreData.SectionStyle.BAKERY:   return Color(0.82, 0.62, 0.38)
		StoreData.SectionStyle.SHELF:    return Color(0.72, 0.65, 0.55)
		StoreData.SectionStyle.DELI:     return Color(0.88, 0.55, 0.52)
		StoreData.SectionStyle.FREEZER:  return Color(0.55, 0.78, 0.95)
		StoreData.SectionStyle.SHOES_RACK: return Color(0.75, 0.60, 0.55)
		StoreData.SectionStyle.DRESS_RACK: return Color(0.72, 0.58, 0.68)
		StoreData.SectionStyle.SPORT_AREA: return Color(0.55, 0.72, 0.65)
	return Color(0.65, 0.60, 0.50)

func _make_glow(col: Color) -> Texture2D:
	var sz := 48
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := col.darkened(0.2)
	for y in range(sz):
		for x in range(sz):
			var d := Vector2(x - sz * 0.5, y - sz * 0.5).length() / (sz * 0.5)
			if d < 1.0:
				var a := (1.0 - d) * 0.35 * c.a
				img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return ImageTexture.create_from_image(img)

func _make_sign(def, w: int, h: int) -> Sprite2D:
	var img := Image.create(80, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_sign_rect(img, 0, 0, 80, 12, _get_section_wall_color(def.style).darkened(0.3))
	_fill_sign_rect(img, 0, 0, 80, 1, def.light_color.darkened(0.2))
	_fill_sign_rect(img, 0, 11, 80, 1, def.light_color.darkened(0.4))
	_fill_sign_rect(img, 0, 0, 1, 12, def.light_color.darkened(0.2))
	_fill_sign_rect(img, 79, 0, 1, 12, def.light_color.darkened(0.4))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.z_index = 5
	return spr

func _fill_sign_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	x = clampi(x, 0, 80); y = clampi(y, 0, 12)
	w = clampi(w, 0, 80 - x); h = clampi(h, 0, 12 - y)
	for px in range(x, x + w):
		for py in range(y, y + h):
			img.set_pixel(px, py, col)

func _make_plush_texture(col: Color) -> Texture2D:
	var sz := 12
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(sz):
		for x in range(sz):
			var cx := float(x) - sz * 0.5
			var cy := float(y) - sz * 0.5
			var r := sz * 0.44
			if cx * cx + cy * cy < r * r:
				img.set_pixel(x, y, col)
	for ey in [sz >> 2, sz >> 2 + 2]:
		for ex in [sz >> 2 - 1, sz - (sz >> 2) + 1]:
			if ex >= 0 and ex < sz and ey >= 0 and ey < sz:
				img.set_pixel(ex, ey, Color(0.05, 0.05, 0.05))
	return ImageTexture.create_from_image(img)

func _make_lantern() -> Texture2D:
	var sz := 20
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var red := Color(0.88, 0.25, 0.20, 0.9)
	for y in range(sz):
		for x in range(sz):
			var cx := x - sz / 2.0
			var cy := y - sz / 2.0
			var r := sz / 2.0 - 1.0
			if cx * cx + cy * cy < r * r:
				var brightness := 1.0 - (absf(cy) / r) * 0.3
				img.set_pixel(x, y, Color(red.r * brightness, red.g * brightness, red.b * brightness, red.a))
	return ImageTexture.create_from_image(img)

# ───────────────────────────────────────────────────────────────────────────
# 新增： proximity 检测专用 - 检查位置是否在指定类型的区域附近
# ───────────────────────────────────────────────────────────────────────────
func is_near_zone_type(zone_type: int, world_pos: Vector2) -> bool:
	# 遍历当前楼层所有区域
	for zone in _floor_def.zones:
		# 🔥 修复：强制转为字符串比较，解决类型冲突
		if str(zone.type) != str(zone_type):
			continue
		
		# 将格子坐标 → 世界坐标矩形
		var zone_world_rect = Rect2(
			zone.x * CELL_SIZE,
			zone.y * CELL_SIZE,
			zone.w * CELL_SIZE,
			zone.h * CELL_SIZE
		)
		
		# 扩大检测范围（2格距离，提升交互手感）
		var detect_rect = zone_world_rect.grow(CELL_SIZE * 2)
		# 判断玩家位置是否在区域内
		if detect_rect.has_point(world_pos):
			return true
	
	# 未找到匹配区域
	return false

# ═══════════════════════════════════════════════════════════════════════════════
# GETTERS
# ═══════════════════════════════════════════════════════════════════════════════

func get_sections() -> Array:
	return _sections

func get_escalators() -> Array:
	return _escalators

func get_food_stalls() -> Array:
	return _food_stalls

func get_claw_machines() -> Array:
	return _claw_machines

func get_checkout_counters() -> Array:
	return _checkout_counters

func get_floor_nodes() -> Array:
	return _floor_nodes

# Get center position of office desk zone (for price terminal proximity)
func get_office_desk_zone_center() -> Vector2:
	var zone = _find_zone_by_type(FloorConfig.ZONE_OFFICE_DESK)
	if zone.is_empty() or zone.has("empty"):
		return Vector2(-1, -1)  # Invalid position
	return Vector2(
		(zone.x + zone.w * 0.5) * CELL_SIZE,
		(zone.y + zone.h * 0.5) * CELL_SIZE
	)

# Find a zone by its type
func _find_zone_by_type(ztype: String) -> Dictionary:
	for zone in _floor_def.zones:
		if zone.type == ztype:
			return zone
	return {"empty": true}  # Return a marker dict instead of null
