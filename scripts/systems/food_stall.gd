# food_stall.gd
# Interactive food stall — press E to open the food menu.
# Extends the section browse system with a food-specific menu UI.
class_name FoodStall
extends Node2D

const FloorConfig = preload("res://scripts/world/floor_config.gd")

signal interact_requested(stall_id: String)

var _stall_def: FloorConfig.FoodStallDef
var _zone: FloorConfig.Zone
var _player_near: bool = false

func configure(stall_def: FloorConfig.FoodStallDef, zone: FloorConfig.Zone) -> void:
	_stall_def = stall_def
	_zone = zone

	# Interaction zone (Area2D at the counter)
	var area := Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(_zone.w * 16, _zone.h * 16)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(_zone.w * 8, _zone.h * 8)
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func _on_body_entered(body) -> void:
	if body is Player:
		_player_near = true
		interact_requested.emit(_stall_def.id)

func _on_body_exited(body) -> void:
	if body is Player:
		_player_near = false

func is_player_near() -> bool:
	return _player_near

func get_stall_id() -> String:
	return _stall_def.id

func get_stall_def() -> FloorConfig.FoodStallDef:
	return _stall_def

func get_zone() -> FloorConfig.Zone:
	return _zone
