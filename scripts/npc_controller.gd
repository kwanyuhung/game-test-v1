# npc_controller.gd
# AI customer that wanders around the supermarket.
# Picks random waypoints, walks to them, pauses, then repeats.

class_name NPCController
extends CharacterBody2D

const SPEED: float = 55.0
const PAUSE_DURATION_MIN: float = 1.5
const PAUSE_DURATION_MAX: float = 4.0

const BOUNDS_MIN := Vector2(64.0, 64.0)
const BOUNDS_MAX := Vector2(1248.0, 752.0)

var _sprite: Sprite2D = null
var _sprite_gen: NPCSprite = null
var _current_waypoint: Vector2 = Vector2.ZERO
var _is_paused: bool = false
var _pause_timer: float = 0.0

enum State { WALKING, PAUSED }
var _state: State = State.WALKING

func _init() -> void:
	_sprite_gen = NPCSprite.new()
	_sprite = Sprite2D.new()
	if _sprite_gen != null:
		var tex: Texture2D = _sprite_gen.get_texture()
		if tex != null:
			_sprite.texture = tex
	_sprite.hframes = 1
	_sprite.vframes = 1
	add_child(_sprite)
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 10)
	col.shape = shape
	col.position = Vector2.ZERO
	add_child(col)
	
	_pick_waypoint()

func _physics_process(delta: float) -> void:
	match _state:
		State.WALKING:
			_walk_to_waypoint(delta)
		State.PAUSED:
			_pause_timer -= delta
			if _pause_timer <= 0.0:
				_state = State.WALKING
				_pick_waypoint()

func _walk_to_waypoint(delta: float) -> void:
	var to_way: Vector2 = _current_waypoint - global_position
	var dist: float = to_way.length()
	
	if dist < 4.0:
		_state = State.PAUSED
		_pause_timer = randf() * (PAUSE_DURATION_MAX - PAUSE_DURATION_MIN) + PAUSE_DURATION_MIN
		return
	
	var dir: Vector2
	if to_way.x != 0.0 or to_way.y != 0.0:
		dir = to_way / dist
	else:
		dir = Vector2.ZERO
	
	move_and_collide(dir * SPEED * delta)
	
	if _sprite != null:
		if absf(dir.x) > 0.3:
			_sprite.flip_h = dir.x < 0.0
		# Slight walking bob
		var t: float = Time.get_ticks_msec() / 1000.0
		var bob: float = sin(t * 8.0) * 0.03
		_sprite.scale = Vector2(1.0 + bob, 1.0 - bob * 0.5)

func _pick_waypoint() -> void:
	var x: float = randf_range(BOUNDS_MIN.x, BOUNDS_MAX.x)
	var y: float = randf_range(BOUNDS_MIN.y, BOUNDS_MAX.y)
	
	var aisle_zones_x: Array = [64.0, 384.0, 704.0, 1024.0]
	var aisle_zones_y: Array = [112.0, 336.0, 528.0]
	
	if randf() < 0.7:
		var idx_x: int = randi() % aisle_zones_x.size()
		var idx_y: int = randi() % aisle_zones_y.size()
		var ax: float = aisle_zones_x[idx_x]
		var ay: float = aisle_zones_y[idx_y]
		x = randf_range(ax - 80.0, ax + 80.0)
		y = randf_range(ay - 60.0, ay + 60.0)
	
	x = clampf(x, BOUNDS_MIN.x, BOUNDS_MAX.x)
	y = clampf(y, BOUNDS_MIN.y, BOUNDS_MAX.y)
	
	_current_waypoint = Vector2(x, y)

func set_color_tint(tint: Color) -> void:
	if _sprite != null:
		_sprite.modulate = tint.lightened(0.1)
