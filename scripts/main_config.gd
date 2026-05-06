# main_config.gd
# Loads main_config.json and provides typed access to all game config data.
extends Node

const CONFIG_PATH := "res://scripts/main_config.json"

var _data: Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("main_config: Could not load %s" % CONFIG_PATH)
		return
	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("main_config: JSON parse error")
		return
	_data = json.data if json.data is Dictionary else {}

func get_aisle_names() -> Dictionary:
	return _data.get("aisle_names", {})

func get_staff_spawns() -> Dictionary:
	return _data.get("staff_spawns", {})

func get_customer_spawns() -> Array:
	return _data.get("customer_spawns", [])

func get_staff_roles() -> Array:
	return _data.get("staff_roles", [])

func get_robot_humanoid_roles() -> Array:
	return _data.get("robot_humanoid_roles", [])

func get_robot_single_roles() -> Array:
	return _data.get("robot_single_roles", [])

func get_cafe_items() -> Array:
	return _data.get("cafe_items", [])

func get_vending_items() -> Array:
	return _data.get("vending_items", [])
