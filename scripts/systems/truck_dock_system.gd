# truck_dock_system.gd
# Truck dock visual and unload logic.
extends Node

var _main: Node2D = null
var _warehouse = null
var _player_stats = null
var _toasts = null
var _truck_dock_node: Node2D = null
var _truck_arrived: bool = false
var _CELL_SIZE: int = 16

func setup(main: Node2D) -> void:
	_main = main
	_warehouse = main.get("_warehouse")
	_player_stats = main.get("_player_stats")
	_toasts = main.get("_toasts")

func spawn_truck() -> void:
	_truck_arrived = true
	_main.set("_truck_arrived", true)
	if _truck_dock_node == null:
		_truck_dock_node = Node2D.new()
		_truck_dock_node.name = "TruckDock"
		_main.add_child(_truck_dock_node)
	else:
		for ch in _truck_dock_node.get_children():
			ch.queue_free()
		_truck_dock_node.visible = true

	var CELL = _CELL_SIZE

	# Cargo area (large box truck body)
	var cargo := ColorRect.new()
	cargo.color = Color(0.50, 0.55, 0.60)
	cargo.size = Vector2(22 * CELL, 10 * CELL)
	cargo.position = Vector2(0, 35 * CELL)
	_truck_dock_node.add_child(cargo)

	# Cab (front of truck)
	var cab := ColorRect.new()
	cab.color = Color(0.35, 0.42, 0.55)
	cab.size = Vector2(7 * CELL, 7 * CELL)
	cab.position = Vector2(22 * CELL, 38 * CELL)
	_truck_dock_node.add_child(cab)

	# Windshield
	var windshield := ColorRect.new()
	windshield.color = Color(0.55, 0.75, 0.90)
	windshield.size = Vector2(5 * CELL, 4 * CELL)
	windshield.position = Vector2(24 * CELL, 38 * CELL)
	_truck_dock_node.add_child(windshield)

	# Wheels
	for wx in [1, 8, 16]:
		for wy in [0, 1]:
			var wheel := ColorRect.new()
			wheel.color = Color(0.15, 0.15, 0.15)
			wheel.size = Vector2(3 * CELL, 3 * CELL)
			wheel.position = Vector2((wx * CELL), (44 + wy * 2) * CELL)
			_truck_dock_node.add_child(wheel)

	if _toasts:
		_toasts.toast_info("🚚 Delivery truck arrived at dock! Press [E] to unload!")

func do_unload() -> void:
	if _warehouse == null:
		return
	if not _truck_arrived:
		# No truck yet — trigger delivery if none pending
		if not _warehouse.is_delivery_pending():
			_warehouse.trigger_delivery()
			if _toasts:
				_toasts.toast_info("Truck ordered! Will arrive shortly...")
		else:
			if _toasts:
				_toasts.toast_info("No delivery to unload.")
		return

	_truck_arrived = false
	_main.set("_truck_arrived", false)

	# Hide truck visual
	if _truck_dock_node != null:
		_truck_dock_node.visible = false

	# Receive the pending delivery
	if _warehouse.is_delivery_pending():
		var pending = _warehouse.get_delivery_contents()
		if pending.size() > 0:
			var item_count = pending.values().reduce(func(a, b): return a + b, 0)
			_warehouse.receive_delivery(pending)

			# Bonus rewards for unloading
			var bonus_xp = mini(item_count * 2, 50)
			var bonus_cash = clamp(float(item_count) * 0.1, 1.0, 10.0)
			if _player_stats != null:
				_player_stats.add_xp(bonus_xp)
				_player_stats.add_cash(bonus_cash)
			if _toasts:
				_toasts.toast_success("Truck unloaded! +%d XP + $%.2f bonus!" % [bonus_xp, bonus_cash])
		else:
			_warehouse.receive_delivery(pending)
			if _toasts:
				_toasts.toast_success("Truck unloaded! Stock updated.")
	else:
		if _toasts:
			_toasts.toast_warning("No delivery to unload.")

func is_truck_arrived() -> bool:
	return _truck_arrived
