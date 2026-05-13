# AI Actor ??handles both customers and staff with full behavior systems.
class_name NPCController
extends CharacterBody2D

const ActorData = preload("res://scripts/actor_data.gd")
const AIChatBrain = preload("res://scripts/ai_chat_brain.gd")
const NPCSprite = preload("res://scripts/npc_sprite.gd")

# Speed Constants
const SPEED_CUSTOMER := 55.0
const SPEED_STAFF   := 62.0
const SPEED_SENIOR   := 38.0
const SPEED_CHILD    := 45.0
const SPEED_TEEN     := 68.0  

const CELL_SIZE := 16.0

# Floor Bounds
const BOUNDS := {
	0: { "min": Vector2(64.0, 64.0), "max": Vector2(1248.0, 752.0) },
	1: { "min": Vector2(64.0, 64.0), "max": Vector2(1248.0, 752.0) },
}

# State Machine
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
	GOING_TO_CART_PICKUP,
	AT_CART_PICKUP,
	SHOPPING_SECTION,
	GOING_TO_CHECKOUT_NPC,
	AT_CHECKOUT_NPC,
	RECEIVING_HELP,
	ASSISTING_ELDER,
	SCAN_GO_COMPANION,
	PLAYING_IN_AREA,
}

const ZONE_KIDS_PLAY := "kids_play"

# Staff Task Definitions
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
	ActorData.StaffRole.SCAN_GO: [
		{"name": "Scan & Go station", "floor": 0, "x": 500, "y": 200, "urgency": 1},
	],
}

# Instance Data
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
var _group_leader: NPCController = null   
var _group_members: Array = []            

# Elder assistance
var _needs_help_at_checkout: bool = false
var _help_received: bool = false
var _assisting_staff: NPCController = null
var _speech_bubble: Label = null

# Shopping cart
var _has_cart: bool = false
var _did_checkout: bool = false
var _cart_sprite: Sprite2D = null
var _cart_pos: Vector2 = Vector2.ZERO  
var _shopping_list_idx: int = 0         
var _at_section_target: bool = false   

# Visual
var _body_sprite: Sprite2D
var _name_label: Label
var _status_label: Label
var _shadow_sprite: Sprite2D

# 🔥 修复2：声明缺失的 _player_reference 变量（Scan&Go助手用）
var _player_reference: Node2D = null

# Bounding box borders for debug/proximity display
var _top_border: ColorRect = null
var _bottom_border: ColorRect = null
var _left_border: ColorRect = null
var _right_border: ColorRect = null
var _bounds_visible: bool = true

# Freeze state for FloorManager LOD system
var _frozen: bool = false

# Freeze/unfreeze for FloorManager LOD system
func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	if frozen:
		set_physics_process(false)
		set_process(false)
		if has_method("pause_behavior"):
			call("pause_behavior")
	else:
		set_physics_process(true)
		set_process(true)
		if has_method("resume_behavior"):
			call("resume_behavior")

func is_frozen() -> bool:
	return _frozen

# Initialization
func configure(actor: ActorData.Actor) -> void:
	_actor = actor

	_chat_brain = AIChatBrain.new()
	_chat_brain.configure(actor)

	_body_sprite = Sprite2D.new()
	_body_sprite.texture = NPCSprite.make_actor_texture(actor.appearance, 16, actor.life_stage)
	_body_sprite.z_index = 3
	add_child(_body_sprite)

	_name_label = Label.new()
	_name_label.text = actor.display_name
	_name_label.add_theme_color_override("font_color", Color(0.90, 0.90, 0.95))
	_name_label.add_theme_font_size_override("font_size", 7)
	_name_label.position = Vector2(-16, -22)
	_name_label.z_index = 10
	add_child(_name_label)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_color_override("font_color", Color(0.70, 0.85, 0.70))
	_status_label.add_theme_font_size_override("font_size", 6)
	_status_label.position = Vector2(-16, -14)
	_status_label.z_index = 10
	add_child(_status_label)

	if actor.child != null:
		_has_stroller = true
		_stroller_sprite = Sprite2D.new()
		_stroller_sprite.texture = NPCSprite.make_stroller_texture(actor.child, 20)
		_stroller_sprite.z_index = 2
		add_child(_stroller_sprite)

	if actor.role == ActorData.Role.CUSTOMER:
		_cart_sprite = Sprite2D.new()
		_cart_sprite.texture = _make_cart_texture()
		_cart_sprite.z_index = 2
		add_child(_cart_sprite)
		_update_cart_position()

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 10)
	col.shape = shape
	col.position = Vector2.ZERO
	add_child(col)

	# Bounding box debug visualization (always visible)
	var border_color := Color(1.0, 1.0, 1.0, 0.6)
	# Top border
	_top_border = ColorRect.new()
	_top_border.size = Vector2(16, 1)
	_top_border.position = Vector2(-8, -8)
	_top_border.color = border_color
	_top_border.z_index = 100
	add_child(_top_border)
	# Bottom border
	_bottom_border = ColorRect.new()
	_bottom_border.size = Vector2(16, 1)
	_bottom_border.position = Vector2(-8, 7)
	_bottom_border.color = border_color
	_bottom_border.z_index = 100
	add_child(_bottom_border)
	# Left border
	_left_border = ColorRect.new()
	_left_border.size = Vector2(1, 16)
	_left_border.position = Vector2(-8, -8)
	_left_border.color = border_color
	_left_border.z_index = 100
	add_child(_left_border)
	# Right border
	_right_border = ColorRect.new()
	_right_border.size = Vector2(1, 16)
	_right_border.position = Vector2(7, -8)
	_right_border.color = border_color
	_right_border.z_index = 100
	add_child(_right_border)

	_start_idle(randf_range(1.0, 3.0))

# Main Loop
func _physics_process(delta: float) -> void:
	_state_timer -= delta
	_update_behavior(delta)
	if _chat_brain != null:
		_chat_brain.process(delta)
	_apply_movement(delta)

	if _has_stroller and _stroller_sprite != null:
		_stroller_sprite.position = Vector2(-8, 8)

# 🔥 修复1：实现缺失的 _apply_movement 函数
func _apply_movement(delta: float) -> void:
	# 行走动画（原代码散落的动画逻辑统一放到这里）
	if _state == BehaviorState.WALKING_TO_TARGET || _state == BehaviorState.STAFF_PATROLLING:
		var t := Time.get_ticks_msec() / 1000.0
		var bob := sin(t * 8.0) * 0.03
		if _body_sprite != null:
			_body_sprite.scale = Vector2(1.0 + bob, 1.0 - bob * 0.5)
	elif _body_sprite != null && _state == BehaviorState.IDLE:
		_body_sprite.scale = Vector2(1.0, 1.0)

# Cart Helpers
func _update_cart_position() -> void:
	if _cart_sprite == null:
		return
	var cart_offset := Vector2(-12, 6)
	_cart_sprite.position = cart_offset
	_cart_sprite.flip_h = false

func _make_cart_texture() -> Texture2D:
	var W := 16; var H := 14
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(2, H - 2):
		for x in range(2, W - 2):
			img.set_pixel(x, y, Color(0.55, 0.55, 0.62))
	for y in range(3, H - 3, 2):
		for x in range(3, W - 3):
			img.set_pixel(x, y, Color(0.40, 0.40, 0.48))
	for x in range(3, W - 3, 2):
		for y in range(3, H - 3):
			img.set_pixel(x, y, Color(0.40, 0.40, 0.48))
	for x in range(W - 2, W):
		img.set_pixel(x, H * 0.5 as int, Color(0.35, 0.35, 0.40))
	img.set_pixel(3, H - 2, Color(0.20, 0.20, 0.22))
	img.set_pixel(4, H - 2, Color(0.20, 0.20, 0.22))
	img.set_pixel(W - 5, H - 2, Color(0.20, 0.20, 0.22))
	img.set_pixel(W - 4, H - 2, Color(0.20, 0.20, 0.22))
	return ImageTexture.create_from_image(img)

func _show_cart() -> void:
	if _cart_sprite != null:
		_cart_sprite.visible = true

func _hide_cart() -> void:
	if _cart_sprite != null:
		_cart_sprite.visible = false

# Behavior State Machine
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
			_do_restocking(delta)

		BehaviorState.CLEANING:
			_do_cleaning(delta)

		BehaviorState.WAITING_FOR_GROUP:
			_do_wait_for_group(delta)

		BehaviorState.ENTERING_STORE:
			_do_enter_store(delta)

		BehaviorState.LEAVING_STORE:
			_do_leave_store(delta)

		BehaviorState.RECEIVING_HELP:
			_do_receiving_help(delta)

		BehaviorState.ASSISTING_ELDER:
			_do_assisting_elder(delta)

		BehaviorState.SCAN_GO_COMPANION:
			_do_scan_go_companion(delta)

		BehaviorState.PLAYING_IN_AREA:
			_do_playing_in_area(delta)

		BehaviorState.GOING_TO_CHECKOUT_NPC:
			_do_going_to_checkout_npc(delta)

		BehaviorState.AT_CHECKOUT_NPC:
			_do_at_checkout_npc(delta)

	_update_status_label()

func _choose_next_behavior() -> void:
	if _actor.role == ActorData.Role.STAFF:
		_choose_staff_behavior()
	else:
		_choose_customer_behavior()

func _choose_customer_behavior() -> void:
	if _actor.role == ActorData.Role.CUSTOMER and not _actor.shopping_list.is_empty() and not _has_cart:
		_go_to_cart_pickup()
		return
	if _actor.role == ActorData.Role.CUSTOMER and _has_cart and _shopping_list_idx < _actor.shopping_list.size():
		_start_shopping_section()
		return
	if _actor.role == ActorData.Role.CUSTOMER and _has_cart:
		_go_to_checkout_npc()
		return
	var roll := randf()
	if _actor.life_stage == ActorData.LifeStage.TEEN:
		if roll < 0.40:
			_go_to_cart_pickup()
		elif roll < 0.70:
			_start_wander()
		elif roll < 0.85:
			_start_elevator_travel()
		else:
			_leave_store()
		return
	if _actor.life_stage == ActorData.LifeStage.SENIOR:
		if roll < 0.20:
			_start_wander()
		elif roll < 0.50:
			_start_browse()
		elif roll < 0.65:
			_start_idle(randf_range(2.0, 6.0))
		elif roll < 0.80:
			_start_elevator_travel()
		elif roll < 0.90:
			_start_idle(randf_range(1.0, 3.0))
		else:
			_leave_store()
		return
	if _actor.life_stage == ActorData.LifeStage.CHILD:
		if roll < 0.40:
			_start_playing_in_area()
		elif roll < 0.65:
			_go_to_cart_pickup()
		elif roll < 0.80:
			_start_wander()
		elif roll < 0.90:
			_start_idle(randf_range(1.0, 3.0))
		else:
			_leave_store()
		return
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

# Behavior Implementations
func _start_idle(duration: float) -> void:
	_state = BehaviorState.IDLE
	_state_timer = duration
	if _body_sprite != null:
		_body_sprite.flip_h = false

func _start_wander() -> void:
	var base_y := 64.0 + _actor.current_floor * 800.0
	var x := randf_range(64.0, 1248.0)
	var y := randf_range(base_y, base_y + 752.0)
	_target_pos = Vector2(x, y)
	_state = BehaviorState.WALKING_TO_TARGET
	_state_timer = randf_range(8.0, 15.0)

func _start_browse() -> void:
	var browse_points := [
		Vector2(120.0, 160.0),
		Vector2(380.0, 160.0),
		Vector2(680.0, 160.0),
		Vector2(900.0, 160.0),
		Vector2(500.0, 400.0),
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
	_did_checkout = true  
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

	var t := Time.get_ticks_msec() / 1000.0
	var work_bob := sin(t * 4.0) * 0.05
	if _body_sprite != null:
		_body_sprite.scale = Vector2(1.0 + work_bob, 1.0 - work_bob * 0.5)

	if _state_timer <= 0.0:
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
	var elev_pos := Vector2(80 * CELL_SIZE, 15 * CELL_SIZE)
	var to_elev := elev_pos - global_position
	var dist := to_elev.length()

	if dist > 8.0:
		var dir := to_elev / dist
		move_and_collide(dir * _get_speed() * delta)
		_flip_sprite(dir.x)
		return

	if _state_timer > 0.0:
		var t := Time.get_ticks_msec() / 1000.0
		if _body_sprite != null:
			_body_sprite.scale = Vector2(1.0 + sin(t * 6.0) * 0.02, 1.0)
		return

	if _elevator_target >= 0 and _elevator_target != _actor.current_floor:
		_actor.current_floor = _elevator_target
		_actor.target_floor = -1
	_elevator_target = -1
	_start_idle(randf_range(1.0, 3.0))

func _do_wait_for_group(delta: float) -> void:
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
	var exit_pos := Vector2(400.0, 900.0)
	var to_exit := exit_pos - global_position
	var dist := to_exit.length()

	if dist < 10.0:
		if _has_cart and not _did_checkout:
			_trigger_theft_alarm()
		_actor.is_active = false
		queue_free()
		return

	var dir := to_exit / dist
	move_and_collide(dir * _get_speed() * delta)
	_flip_sprite(dir.x)

func _trigger_theft_alarm() -> void:
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node != null:
		main_node.on_npc_theft(self)
		print("ALARM: Cart theft detected! NPC: ", _actor.display_name)

func _leave_store() -> void:
	_state = BehaviorState.LEAVING_STORE
	_state_timer = 20.0

# Cart Shopping Behaviors
const CART_PICKUP_POS := Vector2(400.0, 600.0)
const CHECKOUT_NPC_POS := Vector2(350.0, 592.0)

func _go_to_cart_pickup() -> void:
	_state = BehaviorState.GOING_TO_CART_PICKUP
	_target_pos = CART_PICKUP_POS
	_actor.target_floor = 0
	_state_timer = 20.0

func _do_going_to_cart_pickup(delta: float) -> void:
	var to_target := _target_pos - global_position
	var dist := to_target.length()
	if dist < 8.0:
		_state = BehaviorState.AT_CART_PICKUP
		_state_timer = 1.0
		return
	var dir := to_target / dist
	move_and_collide(dir * _get_speed() * delta)
	_flip_sprite(dir.x)

func _do_at_cart_pickup(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		_has_cart = true
		_actor.has_cart = true
		_show_cart()
		_state = BehaviorState.SHOPPING_SECTION
		_start_shopping_section()

func _start_shopping_section() -> void:
	if _shopping_list_idx >= _actor.shopping_list.size():
		_go_to_checkout_npc()
		return
	var entry: Dictionary = _actor.shopping_list[_shopping_list_idx]
	var section_id: String = entry["section_id"]
	var section_floors := {
		"produce": 1, "dairy": 1, "bakery": 1, "meat": 1,
		"pantry": 2, "spices": 2,
		"drinks": 3, "coffee": 3,
		"snacks": 4, "candy": 4,
		"frozen": 5,
		"clean": 6, "paper": 6,
		"pharm": 7, "beauty": 7,
		"toys": 8,
		"cafe": 10,
		"pet": 11,
	}
	var section_floor: int = section_floors.get(section_id, 1)
	var floor_base_y := 64.0 + section_floor * 800.0
	var section_x_map := {
		"produce": 300.0, "dairy": 100.0, "bakery": 700.0, "meat": 350.0,
		"pantry": 700.0, "spices": 100.0,
		"drinks": 950.0, "coffee": 700.0,
		"snacks": 100.0, "candy": 350.0,
		"frozen": 950.0,
		"clean": 700.0, "paper": 950.0,
		"pharm": 100.0, "beauty": 350.0,
		"toys": 450.0,
		"cafe": 700.0,
		"pet": 200.0,
	}
	_target_pos = Vector2(section_x_map.get(section_id, 400.0), floor_base_y + 100.0)
	_actor.target_floor = section_floor
	_state = BehaviorState.SHOPPING_SECTION
	_state_timer = randf_range(4.0, 8.0)

func _do_shopping_section(delta: float) -> void:
	_state_timer -= delta
	if _actor.current_floor != _actor.target_floor:
		_start_elevator_travel()
		return
	var to_target := _target_pos - global_position
	var dist := to_target.length()
	if dist > 10.0:
		var dir := to_target / dist
		move_and_collide(dir * _get_speed() * delta)
		_flip_sprite(dir.x)
	else:
		if _state_timer <= 0.0:
			if _shopping_list_idx < _actor.shopping_list.size():
				var entry: Dictionary = _actor.shopping_list[_shopping_list_idx]
				var qty: int = int(entry["qty"])
				_actor.cart_item_count += qty
				_shopping_list_idx += 1
			_state = BehaviorState.SHOPPING_SECTION
			_start_shopping_section()

func _go_to_checkout_npc() -> void:
	_state = BehaviorState.GOING_TO_CHECKOUT_NPC
	_target_pos = CHECKOUT_NPC_POS
	_actor.target_floor = 0
	_state_timer = 30.0

func _do_going_to_checkout_npc(delta: float) -> void:
	if _actor.current_floor != 0:
		_start_elevator_travel()
		return
	var to_target := _target_pos - global_position
	var dist := to_target.length()
	if dist < 12.0:
		_state = BehaviorState.AT_CHECKOUT_NPC
		_state_timer = randf_range(2.0, 5.0)
		return
	var dir := to_target / dist
	move_and_collide(dir * _get_speed() * delta)
	_flip_sprite(dir.x)

func _do_at_checkout_npc(delta: float) -> void:
	_state_timer -= delta
	if _actor.life_stage == ActorData.LifeStage.SENIOR and not _help_received and randf() < 0.4:
		_needs_help_at_checkout = true
		_show_speech_bubble("Need help?")
		_state = BehaviorState.RECEIVING_HELP
		_state_timer = 8.0
		_try_find_assisting_staff()
		return
	if _state_timer <= 0.0:
		_actor.cart_item_count = 0
		_has_cart = false
		_actor.has_cart = false
		_hide_cart()
		_leave_store()

# Elder Assistance
func _show_speech_bubble(text: String) -> void:
	if _speech_bubble == null:
		_speech_bubble = Label.new()
		_speech_bubble.add_theme_color_override("font_color", Color(0.95, 0.95, 0.70))
		_speech_bubble.add_theme_font_size_override("font_size", 6)
		_speech_bubble.z_index = 15
		add_child(_speech_bubble)
	_speech_bubble.text = text
	_speech_bubble.position = Vector2(-10, -28)

func _try_find_assisting_staff() -> void:
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node == null:
		return
	var npcs: Array = main_node.get("_npcs")
	for npc in npcs:
		if npc == self:
			continue
		var actor: ActorData.Actor = npc.get_actor()
		if actor == null or not actor.is_active:
			continue
		if actor.role != ActorData.Role.STAFF:
			continue
		if npc.global_position.distance_to(global_position) > 300.0:
			continue
		npc._start_assist_elder(self)
		_assisting_staff = npc
		break

func _start_assist_elder(elder: NPCController) -> void:
	_state = BehaviorState.ASSISTING_ELDER
	_target_pos = elder.global_position
	_state_timer = 6.0

func _do_receiving_help(delta: float) -> void:
	if _state_timer <= 0.0 or _assisting_staff != null:
		if _help_received:
			_hide_speech_bubble()
			_state_timer = 3.0
			_state = BehaviorState.IDLE
		else:
			_needs_help_at_checkout = false
			_hide_speech_bubble()
			_state_timer = 2.0
			_state = BehaviorState.IDLE

func _do_assisting_elder(delta: float) -> void:
	var speed := _get_speed()
	var to_target := _target_pos - global_position
	var dist := to_target.length()
	if dist > 10.0:
		var dir := to_target / dist
		move_and_collide(dir * speed * delta)
		_flip_sprite(dir.x)
		return
	_show_speech_bubble("Here, let me help!")
	_state_timer -= delta
	if _state_timer <= 0.0:
		_help_received = true
		_needs_help_at_checkout = false
		var main_node = get_tree().get_first_node_in_group("main")
		if main_node != null:
			var ps = main_node.get("_player_stats")
			if ps != null:
				ps.add_xp(5, "Elder assistance")
			var ft = main_node.get("_floating_text")
			if ft != null:
				ft.show_text(global_position, "+5 XP", Color(0.40, 0.85, 0.50))
		_hide_speech_bubble()
		_start_idle(randf_range(2.0, 4.0))

func _hide_speech_bubble() -> void:
	if _speech_bubble != null:
		_speech_bubble.text = ""

func _get_preferred_floors() -> Array:
	match _actor.life_stage:
		ActorData.LifeStage.CHILD:
			return [8, 4, 1, 0]
		ActorData.LifeStage.TEEN:
			return [4, 3, 8, 1]
		ActorData.LifeStage.SENIOR:
			return [0, 1, 10, 4]
		ActorData.LifeStage.ADULT, ActorData.LifeStage.ADULT_MID:
			return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
		_:
			return [0, 1, 4, 8]

# Helpers
func _get_speed() -> float:
	if _actor.role == ActorData.Role.STAFF:
		return SPEED_STAFF
	if _actor.life_stage == ActorData.LifeStage.SENIOR:
		return SPEED_SENIOR
	if _actor.life_stage == ActorData.LifeStage.TEEN:
		return SPEED_TEEN
	if _actor.life_stage == ActorData.LifeStage.CHILD:
		return SPEED_CHILD
	return SPEED_CUSTOMER

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

# Public API
func get_actor() -> ActorData.Actor:
	return _actor

func set_group_leader(leader: NPCController) -> void:
	_group_leader = leader

func get_group_leader() -> NPCController:
	return _group_leader

func get_group_members() -> Array:
	return _group_members

func is_active() -> bool:
	return _actor.is_active

# Kids Play Area
func _start_playing_in_area() -> void:
	var main_node = get_tree().get_first_node_in_group("main")
	var zone_center := Vector2(400.0, 200.0)
	if main_node != null:
		var fb = main_node.get("_floor_builder")
		if fb != null and fb.has_method("get_zone_center_by_type"):
			var zc: Vector2 = fb.get_zone_center_by_type(ZONE_KIDS_PLAY, _actor.current_floor)
			if zc.x >= 0:
				zone_center = zc
	_target_pos = zone_center
	_state = BehaviorState.PLAYING_IN_AREA
	_state_timer = randf_range(5.0, 10.0)

func _do_playing_in_area(delta: float) -> void:
	var speed := _get_speed()
	var to_target := _target_pos - global_position
	var dist := to_target.length()

	if dist > 6.0:
		var dir := to_target / dist
		move_and_collide(dir * speed * delta)
		_flip_sprite(dir.x)
		return

	var t := Time.get_ticks_msec() / 1000.0
	var bob := sin(t * 5.0) * 0.04
	if _body_sprite != null:
		_body_sprite.scale = Vector2(1.0 + bob, 1.0 - bob * 0.5)

	var bubble_timer := _state_timer as float
	if bubble_timer > 3.0 and bubble_timer < 3.1:
		var thoughts := ["So fun!", "Wheee!", "More toys!", "Yay!", "Again! again!"]
		_show_speech_bubble(thoughts[randi() % thoughts.size()])
	elif bubble_timer < 1.0:
		_hide_speech_bubble()

	if _state_timer <= 0.0:
		_hide_speech_bubble()
		if _body_sprite != null:
			_body_sprite.scale = Vector2(1.0, 1.0)
		if randf() < 0.4:
			_start_playing_in_area()
		else:
			_start_idle(randf_range(1.0, 3.0))

# Shelf Stocker
func _do_restocking(delta: float) -> void:
	var speed := _get_speed() * 0.7
	var to_target := _target_pos - global_position
	var dist := to_target.length()

	if dist > 6.0:
		var dir := to_target / dist
		move_and_collide(dir * speed * delta)
		_flip_sprite(dir.x)
		_state_timer = 5.0
		return

	var t := Time.get_ticks_msec() / 1000.0
	var stock_bob := sin(t * 3.5) * 0.06
	if _body_sprite != null:
		_body_sprite.scale = Vector2(1.0 + stock_bob, 1.0 - stock_bob * 0.5)

	if _state_timer <= 0.0:
		_hide_speech_bubble()
		if _body_sprite != null:
			_body_sprite.scale = Vector2(1.0, 1.0)
		var shelves := [
			Vector2(60.0 * CELL_SIZE, 12.0 * CELL_SIZE),
			Vector2(300.0 * CELL_SIZE, 12.0 * CELL_SIZE),
			Vector2(500.0 * CELL_SIZE, 12.0 * CELL_SIZE),
			Vector2(200.0 * CELL_SIZE, 20.0 * CELL_SIZE),
			Vector2(700.0 * CELL_SIZE, 12.0 * CELL_SIZE),
		]
		_target_pos = shelves[randi() % shelves.size()]
		_state_timer = randf_range(4.0, 8.0)

# Cleaner
func _do_cleaning(delta: float) -> void:
	var speed := _get_speed() * 0.6
	var to_target := _target_pos - global_position
	var dist := to_target.length()

	if dist > 6.0:
		var dir := to_target / dist
		move_and_collide(dir * speed * delta)
		_flip_sprite(dir.x)
		_state_timer = 4.0
		return

	var t := Time.get_ticks_msec() / 1000.0
	var wipe := sin(t * 4.0) * 0.04
	if _body_sprite != null:
		_body_sprite.position.x = wipe * 3.0

	if _state_timer <= 0.0:
		if _body_sprite != null:
			_body_sprite.position.x = 0.0
		var spots := [
			Vector2(160.0 * CELL_SIZE, 33.0 * CELL_SIZE),
			Vector2(320.0 * CELL_SIZE, 33.0 * CELL_SIZE),
			Vector2(480.0 * CELL_SIZE, 33.0 * CELL_SIZE),
			Vector2(200.0, 100.0),
			Vector2(600.0, 200.0),
		]
		_target_pos = spots[randi() % spots.size()]
		_state_timer = randf_range(4.0, 7.0)

# Scan & Go Companion
func _do_scan_go_companion(delta: float) -> void:
	if _player_reference == null:
		_start_idle(2.0)
		return

	var player_pos: Vector2 = _player_reference.global_position
	var to_player := player_pos - global_position
	var dist := to_player.length()

	if dist > CELL_SIZE * 3.5:
		var speed := _get_speed() * 1.2
		var dir := to_player / dist
		move_and_collide(dir * speed * delta)
		_flip_sprite(dir.x)
		return

	var t := Time.get_ticks_msec() / 1000.0
	var scan_bob := sin(t * 3.0) * 0.03
	if _body_sprite != null:
		_body_sprite.scale = Vector2(1.0 + scan_bob, 1.0 - scan_bob * 0.3)

	var secs := fmod(t, 4.0)
	if secs < 0.05:
		_show_speech_bubble("Scanning...")
	elif secs > 0.5:
		_hide_speech_bubble()

	var main_node = get_tree().get_first_node_in_group("main")
	if main_node != null:
		var nearby_checkout = main_node.get("_nearby_checkout")
		if nearby_checkout != null:
			_show_speech_bubble("All scanned! Thanks!")
			_state_timer = 2.0
			_state = BehaviorState.IDLE
			return

func set_bounds_visible(visible: bool) -> void:
	_bounds_visible = visible
	if _top_border != null:
		_top_border.visible = visible
	if _bottom_border != null:
		_bottom_border.visible = visible
	if _left_border != null:
		_left_border.visible = visible
	if _right_border != null:
		_right_border.visible = visible
