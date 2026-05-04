# npc_controller.gd
# ═══════════════════════════════════════════════════════════════════════
# AI Actor — handles both customers and staff with full behavior systems.
#
# CUSTOMERS: Wander, browse sections, use elevator, shop in groups.
# STAFF: Have roles (cashier, cleaner, etc.) and task lists.
# BABIES: Sit in strollers, attached to parent actors.
#
# EXTENDING: Add new behaviors by implementing _do_<behavior_name>() and
# adding to the behavior state machine in _update_behavior().
# ═══════════════════════════════════════════════════════════════════════
class_name NPCController
extends CharacterBody2D

const ActorData = preload("res://scripts/actor_data.gd")
const AIChatBrain = preload("res://scripts/ai_chat_brain.gd")
const NPCSprite = preload("res://scripts/npc_sprite.gd")

# ─── Speed Constants ────────────────────────────────────────
const SPEED_CUSTOMER := 55.0
const SPEED_STAFF   := 62.0
const SPEED_SENIOR   := 38.0
const SPEED_CHILD    := 45.0

const CELL_SIZE := 16.0

# ─── Floor Bounds ────────────────────────────────────────────
const BOUNDS := {
	0: { "min": Vector2(64.0, 64.0), "max": Vector2(1248.0, 752.0) },  # Ground
	1: { "min": Vector2(64.0, 64.0), "max": Vector2(1248.0, 752.0) },  # Food Street / retail
}

# ─── State Machine ───────────────────────────────────────────
enum BehaviorState {
	IDLE,
	WALKING_TO_TARGET,
	BROWSING_SECTION,
	USING_ELEVATOR,
	STAFF_WORKING,
	STAFF_PATROLLING,
	RESTOCKING,
	CLEANING,
	AT_CHECKOUT,
	WAITING_FOR_GROUP,
	ENTERING_STORE,
	LEAVING_STORE,
}

# ─── Staff Task Definitions ─────────────────────────────────
const STAFF_TASK_TEMPLATES = {
	ActorData.StaffRole.CASHIER: [
		{"name": "Man checkout lane", "floor": 0, "x": 20, "y": 34, "urgency": 1},
	],
	ActorData.StaffRole.SHELF_STOCKER: [
		{"name": "Restock dairy section", "floor": 1, "x": 60, "y": 80, "urgency": 1},
		{"name": "Restock produce", "floor": 1, "x": 300, "y": 80, "urgency": 1},
		{"name": "Restock snacks", "floor": 4, "x": 200, "y": 200, "urgency": 0},
		{"name": "Restock beverages", "floor": 3, "x": 150, "y": 150, "urgency": 1},
	],
	ActorData.StaffRole.CLEANER: [
		{"name": "Clean lobby floor", "floor": 0, "x": 300, "y": 100, "urgency": 0},
		{"name": "Clean food court", "floor": 1, "x": 400, "y": 300, "urgency": 0},
		{"name": "Clean checkout area", "floor": 0, "x": 200, "y": 500, "urgency": 1},
	],
	ActorData.StaffRole.SECURITY: [
		{"name": "Patrol floor 1", "floor": 1, "x": 400, "y": 200, "urgency": 1},
		{"name": "Patrol ground floor", "floor": 0, "x": 600, "y": 400, "urgency": 1},
		{"name": "Check exits", "floor": 0, "x": 100, "y": 100, "urgency": 0},
	],
	ActorData.StaffRole.GREETER: [
		{"name": "Greet at entrance", "floor": 0, "x": 350, "y": 50, "urgency": 1},
		{"name": "Guide customer", "floor": 0, "x": 500, "y": 200, "urgency": 0},
	],
	ActorData.StaffRole.MANAGER: [
		{"name": "Floor inspection F1", "floor": 1, "x": 300, "y": 300, "urgency": 0},
		{"name": "Floor inspection G", "floor": 0, "x": 400, "y": 400, "urgency": 0},
		{"name": "Meeting at office", "floor": 9, "x": 200, "y": 200, "urgency": 0},
	],
	ActorData.StaffRole.FLOOR_STAFF: [
		{"name": "Help customer", "floor": 1, "x": 200, "y": 200, "urgency": 1},
		{"name": "Organize shelf", "floor": 1, "x": 500, "y": 300, "urgency": 0},
	],
}

# ─── Instance Data ─────────────────────────────────────────
var _actor: ActorData.Actor
var _chat_brain: AIChatBrain
var _state: BehaviorState = BehaviorState.IDLE
var _target_pos: Vector2 = Vector2.ZERO
var _elevator_target: int = -1
var _elevator_at_floor: int = 0
var _state_timer: float = 0.0
var _current_task_idx: int = 0
var _tasks: Array = []
var _has_stroller: bool = false
var _stroller_sprite: Sprite2D = null
var _group_leader: NPCController = null   # for group members
var _group_members: Array = []            # for group leaders

# Visual
var _body_sprite: Sprite2D
var _name_label: Label
var _status_label: Label
var _shadow_sprite: Sprite2D

# ─── Initialization ────────────────────────────────────────

func configure(actor: ActorData.Actor) -> void:
	_actor = actor

	# Chat brain
	_chat_brain = AIChatBrain.new()
	_chat_brain.configure(actor)

	# Build sprite from appearance
	_body_sprite = Sprite2D.new()
	_body_sprite.texture = NPCSprite.make_actor_texture(actor.appearance, 16)
	_body_sprite.z_index = 3
	add_child(_body_sprite)

	# Name label
	_name_label = Label.new()
	_name_label.text = actor.display_name
	_name_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.95))
	_name_label.add_theme_font_size_override("font_size", 7)
	_name_label.position = Vector2(-16, -22)
	_name_label.z_index = 10
	add_child(_name_label)

	# Status label (shows role/task)
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_color_override("font_color", Color(0.70, 0.85, 0.70))
	_status_label.add_theme_font_size_override("font_size", 6)
	_status_label.position = Vector2(-16, -14)
	_status_label.z_index = 10
	add_child(_status_label)

	# Stroller if baby
	if actor.child != null:
		_has_stroller = true
		_stroller_sprite = Sprite2D.new()
		_stroller_sprite.texture = NPCSprite.make_stroller_texture(actor.child, 20)
		_stroller_sprite.z_index = 2
		add_child(_stroller_sprite)

	# Collision
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 10)
	col.shape = shape
	col.position = Vector2.ZERO
	add_child(col)

	# Set initial state
	_start_idle(randf_range(1.0, 3.0))

# ─── Main Loop ─────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_state_timer -= delta
	_update_behavior(delta)
	if _chat_brain != null:
		_chat_brain.process(delta)
	_apply_movement(delta)

	# Update stroller position
	if _has_stroller and _stroller_sprite != null:
		_stroller_sprite.position = Vector2(-8, 8)

# ─── Behavior State Machine ────────────────────────────────

func _update_behavior(delta: float) -> void:
	match _state:
		BehaviorState.IDLE:
			if _state_timer <= 0.0:
				_choose_next_behavior()

		BehaviorState.WALKING_TO_TARGET:
			_do_walk_to_target(delta)

		BehaviorState.BROWSING_SECTION:
			if _state_timer <= 0.0:
				_start_idle(randf_range(0.5, 2.0))

		BehaviorState.USING_ELEVATOR:
			_do_elevator(delta)

		BehaviorState.STAFF_WORKING:
			_do_staff_work(delta)

		BehaviorState.STAFF_PATROLLING:
			_do_patrol(delta)

		BehaviorState.RESTOCKING:
			if _state_timer <= 0.0:
				_start_idle(randf_range(2.0, 5.0))

		BehaviorState.CLEANING:
			if _state_timer <= 0.0:
				_start_idle(randf_range(1.0, 3.0))

		BehaviorState.WAITING_FOR_GROUP:
			_do_wait_for_group(delta)

		BehaviorState.ENTERING_STORE:
			_do_enter_store(delta)

		BehaviorState.LEAVING_STORE:
			_do_leave_store(delta)

	# Update status label
	_update_status_label()

func _choose_next_behavior() -> void:
	if _actor.role == ActorData.Role.STAFF:
		_choose_staff_behavior()
	else:
		_choose_customer_behavior()

func _choose_customer_behavior() -> void:
	var roll := randf()
	if roll < 0.15:
		_start_wander()
	elif roll < 0.30:
		_start_browse()
	elif roll < 0.45:
		_start_elevator_travel()
	elif roll < 0.60:
		_start_idle(randf_range(1.0, 4.0))
	elif roll < 0.75:
		_start_wander()
	elif roll < 0.90:
		_start_idle(randf_range(0.5, 2.0))
	else:
		_leave_store()

func _choose_staff_behavior() -> void:
	match _actor.staff_role:
		ActorData.StaffRole.CASHIER:
			_go_to_checkout_lane()
		ActorData.StaffRole.SHELF_STOCKER:
			if randf() < 0.6:
				_start_restock_task()
			else:
				_start_patrol()
		ActorData.StaffRole.CLEANER:
			if randf() < 0.7:
				_start_clean_task()
			else:
				_start_patrol()
		ActorData.StaffRole.SECURITY:
			_start_patrol()
		ActorData.StaffRole.GREETER:
			_go_to_entrance()
		ActorData.StaffRole.MANAGER:
			if randf() < 0.4:
				_start_patrol()
			else:
				_start_idle(randf_range(3.0, 8.0))
		_:
			_start_wander()

# ─── Behavior Implementations ───────────────────────────────

func _start_idle(duration: float) -> void:
	_state = BehaviorState.IDLE
	_state_timer = duration
	if _body_sprite != null:
		_body_sprite.flip_h = false

func _start_wander() -> void:
	var bounds = _get_floor_bounds(_actor.current_floor)
	var x := randf_range(bounds["min"].x, bounds["max"].x)
	var y := randf_range(bounds["min"].y, bounds["max"].y)
	_target_pos = Vector2(x, y)
	_state = BehaviorState.WALKING_TO_TARGET
	_state_timer = randf_range(8.0, 15.0)

func _start_browse() -> void:
	var browse_points := [
		Vector2(120.0, 160.0),   # dairy section
		Vector2(380.0, 160.0),   # produce
		Vector2(680.0, 160.0),   # bakery
		Vector2(900.0, 160.0),   # meat
		Vector2(500.0, 400.0),   # central aisle
	]
	_target_pos = browse_points[randi() % browse_points.size()]
	_state = BehaviorState.WALKING_TO_TARGET
	_state_timer = randf_range(3.0, 8.0)

func _start_elevator_travel() -> void:
	var target_floor := randi() % 11
	if target_floor == _actor.current_floor:
		target_floor = (target_floor + 1) % 11
	_elevator_target = target_floor
	_actor.target_floor = target_floor
	# Walk to elevator shaft
	_target_pos = Vector2(80 * CELL_SIZE, 15 * CELL_SIZE)
	_state = BehaviorState.WALKING_TO_TARGET
	_state_timer = 10.0

func _start_restock_task() -> void:
	var templates = STAFF_TASK_TEMPLATES.get(ActorData.StaffRole.SHELF_STOCKER, [])
	if templates.is_empty():
		_start_wander()
		return
	var task: Dictionary = templates[randi() % templates.size()]
	var t := ActorData.StaffTask.new(task["name"], task["floor"], task["x"], task["y"], task["urgency"])
	_tasks.clear()
	_tasks.append(t)
	_current_task_idx = 0
	_start_staff_task()

func _start_clean_task() -> void:
	var templates = STAFF_TASK_TEMPLATES.get(ActorData.StaffRole.CLEANER, [])
	if templates.is_empty():
		_start_wander()
		return
	var task: Dictionary = templates[randi() % templates.size()]
	var t = ActorData.StaffTask.new(task["name"], task["floor"], task["x"], task["y"], task["urgency"])
	_tasks.clear()
	_tasks.append(t)
	_current_task_idx = 0
	_start_staff_task()

func _start_staff_task() -> void:
	if _current_task_idx >= _tasks.size():
		_start_idle(randf_range(5.0, 15.0))
		return
	var task: ActorData.StaffTask = _tasks[_current_task_idx]
	if task.floor_target >= 0 and task.floor_target != _actor.current_floor:
		# Go to target floor first
		_elevator_target = task.floor_target
		_actor.target_floor = task.floor_target
		_target_pos = Vector2(80 * CELL_SIZE, 15 * CELL_SIZE)
		_state = BehaviorState.WALKING_TO_TARGET
		_state_timer = 10.0
	else:
		_target_pos = Vector2(task.zone_x, task.zone_y)
		_state = BehaviorState.STAFF_WORKING
		_state_timer = randf_range(4.0, 10.0)
		task.done = true
		_current_task_idx += 1

func _start_patrol() -> void:
	var templates = STAFF_TASK_TEMPLATES.get(_actor.staff_role, [])
	if templates.is_empty():
		_start_wander()
		return
	var task: Dictionary = templates[randi() % templates.size()]
	_target_pos = Vector2(task["x"], task["y"])
	_state = BehaviorState.STAFF_PATROLLING
	_state_timer = randf_range(3.0, 7.0)

func _go_to_checkout_lane() -> void:
	var lanes := [Vector2(160.0, 34.0 * CELL_SIZE), Vector2(320.0, 34.0 * CELL_SIZE), Vector2(480.0, 34.0 * CELL_SIZE)]
	_target_pos = lanes[randi() % lanes.size()]
	_state = BehaviorState.WALKING_TO_TARGET
	_state_timer = 8.0

func _go_to_entrance() -> void:
	_target_pos = Vector2(400.0, 50.0)
	_state = BehaviorState.WALKING_TO_TARGET
	_state_timer = 10.0

func _do_walk_to_target(delta: float) -> void:
	var speed := _get_speed()
	var to_target := _target_pos - global_position
	var dist := to_target.length()

	if dist < 5.0:
		if _elevator_target >= 0:
			_state = BehaviorState.USING_ELEVATOR
			_state_timer = 3.0
			_elevator_at_floor = _actor.current_floor
		else:
			_start_idle(randf_range(1.0, 4.0))
		return

	if _state_timer <= 0.0:
		_start_idle(0.5)
		return

	var dir := to_target / dist if dist > 0.0 else Vector2.ZERO
	move_and_collide(dir * speed * delta)
	_flip_sprite(dir.x)

func _do_staff_work(delta: float) -> void:
	var speed := _get_speed()
	var to_target := _target_pos - global_position
	var dist := to_target.length()

	if dist > 5.0:
		var dir := to_target / dist
		move_and_collide(dir * speed * delta)
		_flip_sprite(dir.x)
		return

	# At task location — work animation
	var t := Time.get_ticks_msec() / 1000.0
	var work_bob := sin(t * 4.0) * 0.05
	if _body_sprite != null:
		_body_sprite.scale = Vector2(1.0 + work_bob, 1.0 - work_bob * 0.5)

	if _state_timer <= 0.0:
		# Task done, go to next or idle
		if _current_task_idx < _tasks.size():
			_start_staff_task()
		else:
			_tasks.clear()
			_start_idle(randf_range(3.0, 8.0))

func _do_patrol(delta: float) -> void:
	var speed := _get_speed() * 1.2
	var to_target := _target_pos - global_position
	var dist := to_target.length()

	if dist < 6.0:
		_start_idle(randf_range(2.0, 5.0))
		return

	if _state_timer <= 0.0:
		_start_idle(2.0)
		return

	var dir := to_target / dist if dist > 0.0 else Vector2.ZERO
	move_and_collide(dir * speed * delta)
	_flip_sprite(dir.x)

func _do_elevator(delta: float) -> void:
	# Walk to elevator position first
	var elev_pos := Vector2(80 * CELL_SIZE, 15 * CELL_SIZE)
	var to_elev := elev_pos - global_position
	var dist := to_elev.length()

	if dist > 8.0:
		var dir := to_elev / dist
		move_and_collide(dir * _get_speed() * delta)
		_flip_sprite(dir.x)
		return

	# At elevator — simulate travel
	if _state_timer > 0.0:
		# Waiting for elevator animation
		var t := Time.get_ticks_msec() / 1000.0
		if _body_sprite != null:
			_body_sprite.scale = Vector2(1.0 + sin(t * 6.0) * 0.02, 1.0)
		return

	# Elevator arrived — change floor
	if _elevator_target >= 0 and _elevator_target != _actor.current_floor:
		_actor.current_floor = _elevator_target
		_actor.target_floor = -1
	_elevator_target = -1
	_start_idle(randf_range(1.0, 3.0))

func _do_wait_for_group(delta: float) -> void:
	# Group leader waits, don't move
	if _state_timer <= 0.0:
		_state = BehaviorState.WALKING_TO_TARGET

func _do_enter_store(delta: float) -> void:
	var entrance := Vector2(400.0, 50.0)
	var to_ent := entrance - global_position
	var dist := to_ent.length()

	if dist < 10.0:
		_state = BehaviorState.WALKING_TO_TARGET
		_start_wander()
		return

	var dir := to_ent / dist
	move_and_collide(dir * _get_speed() * delta)
	_flip_sprite(dir.x)

func _do_leave_store(delta: float) -> void:
	var exit_pos := Vector2(400.0, 900.0)  # Below ground floor
	var to_exit := exit_pos - global_position
	var dist := to_exit.length()

	if dist < 10.0:
		_actor.is_active = false
		queue_free()
		return

	var dir := to_exit / dist
	move_and_collide(dir * _get_speed() * delta)
	_flip_sprite(dir.x)

func _leave_store() -> void:
	_state = BehaviorState.LEAVING_STORE
	_state_timer = 20.0

# ─── Helpers ────────────────────────────────────────────────

func _get_speed() -> float:
	if _actor.role == ActorData.Role.STAFF:
		return SPEED_STAFF
	if _actor.life_stage == ActorData.LifeStage.SENIOR:
		return SPEED_SENIOR
	if _actor.life_stage == ActorData.LifeStage.CHILD:
		return SPEED_CHILD
	return SPEED_CUSTOMER

func _get_floor_bounds(floor_idx: int) -> Dictionary:
	var base_y := 64.0 + floor_idx * 800.0
	return {
		"min": Vector2(64.0, base_y),
		"max": Vector2(1248.0, base_y + 752.0)
	}

func _apply_movement(delta: float) -> void:
	# Walking bob animation
	if _state == BehaviorState.WALKING_TO_TARGET or _state == BehaviorState.STAFF_PATROLLING:
		var t := Time.get_ticks_msec() / 1000.0
		var bob := sin(t * 8.0) * 0.03
		if _body_sprite != null:
			_body_sprite.scale = Vector2(1.0 + bob, 1.0 - bob * 0.5)
	elif _body_sprite != null and _state == BehaviorState.IDLE:
		_body_sprite.scale = Vector2(1.0, 1.0)

func _flip_sprite(dir_x: float) -> void:
	if _body_sprite != null and absf(dir_x) > 0.1:
		_body_sprite.flip_h = dir_x < 0.0

func _update_status_label() -> void:
	if _status_label == null:
		return
	match _state:
		BehaviorState.IDLE:
			_status_label.text = ""
		BehaviorState.STAFF_WORKING:
			if _tasks.size() > _current_task_idx:
				var t: ActorData.StaffTask = _tasks[_current_task_idx]
				_status_label.text = "[%s]" % t.task_name
			else:
				_status_label.text = "[working]"
		BehaviorState.STAFF_PATROLLING:
			_status_label.text = "[patrolling]"
		BehaviorState.USING_ELEVATOR:
			_status_label.text = "[elevator F%d]" % _elevator_target if _elevator_target >= 0 else ""
		BehaviorState.BROWSING_SECTION:
			_status_label.text = "[shopping]"
		BehaviorState.WAITING_FOR_GROUP:
			_status_label.text = "[waiting]"

# ─── Public API ────────────────────────────────────────────

func get_actor() -> ActorData.Actor:
	return _actor

func get_position() -> Vector2:
	return global_position

func set_group_leader(leader: NPCController) -> void:
	_group_leader = leader

func get_group_leader() -> NPCController:
	return _group_leader

func get_group_members() -> Array:
	return _group_members

func is_active() -> bool:
	return _actor.is_active

func set_position(new_pos: Vector2) -> void:
	global_position = new_pos
