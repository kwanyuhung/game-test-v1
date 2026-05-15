# super_actor.gd
# Super testing character — dev mode only.
# Golden crown sprite, can walk to any NPC, interact with anyone.
# Press E near any character to trigger their interaction.
extends CharacterBody2D

const SPEED := 280.0
const CELL_SIZE := 16.0

var _target_pos: Vector2 = Vector2.ZERO
var _moving := false
var _sprite: Sprite2D = null
var _crown: Sprite2D = null
var _label: Label = null
var _nearby_npc: Node = null
var _interact_timer := 0.0
var _is_god_mode := false

func _ready() -> void:
	_build_sprite()
	_add_crown()
	_add_label()
	add_to_group("super_actor")

func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _make_super_tex()
	_sprite.position = Vector2.ZERO
	add_child(_sprite)

func _make_super_tex() -> Texture2D:
	var W := 16; var H := 24
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Body — bright cyan/blue
	var body_col := Color(0.30, 0.75, 1.00)
	# Torso
	for y in range(8, 18):
		for x in range(4, 12):
			img.set_pixel(x, y, body_col)
	# Head
	for y in range(2, 8):
		for x in range(4, 12):
			img.set_pixel(x, y, Color(0.95, 0.82, 0.65))
	# Arms
	for y in range(8, 15):
		img.set_pixel(3, y, body_col)
		img.set_pixel(12, y, body_col)
	# Legs
	for y in range(18, 23):
		img.set_pixel(5, y, Color(0.20, 0.30, 0.60))
		img.set_pixel(10, y, Color(0.20, 0.30, 0.60))

	# Eyes
	img.set_pixel(5, 4, Color(0.15, 0.15, 0.15))
	img.set_pixel(9, 4, Color(0.15, 0.15, 0.15))
	# Smile
	img.set_pixel(5, 6, Color(0.80, 0.50, 0.50))
	img.set_pixel(6, 7, Color(0.80, 0.50, 0.50))
	img.set_pixel(7, 7, Color(0.80, 0.50, 0.50))
	img.set_pixel(8, 7, Color(0.80, 0.50, 0.50))
	img.set_pixel(9, 6, Color(0.80, 0.50, 0.50))

	return ImageTexture.create_from_image(img)

func _add_crown() -> void:
	_crown = Sprite2D.new()
	_crown.texture = _make_crown_tex()
	_crown.position = Vector2(0, -20)
	_crown.z_index = 5
	add_child(_crown)

func _make_crown_tex() -> Texture2D:
	var W := 16; var H := 10
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Gold crown with red gems
	var gold := Color(1.0, 0.85, 0.20)
	var dark_gold := Color(0.80, 0.65, 0.10)
	# Crown base band
	for x in range(2, 14):
		img.set_pixel(x, 8, dark_gold)
		img.set_pixel(x, 9, gold)
	# Crown points
	for px in range(2, 5):  # left point
		img.set_pixel(px, 7 - (px - 2), gold)
	for px in range(5, 9):  # middle point (tallest)
		img.set_pixel(px, 4, gold)
	for px in range(9, 12):  # right point
		img.set_pixel(px, 7 - (11 - px), gold)
	# Gems
	img.set_pixel(3, 8, Color(1.0, 0.20, 0.20))  # red gem left
	img.set_pixel(7, 8, Color(0.20, 0.80, 1.0))  # blue gem middle
	img.set_pixel(11, 8, Color(0.20, 1.0, 0.40)) # green gem right
	# Crown outline
	var outline := Color(0.70, 0.55, 0.05)
	for x in range(2, 14):
		if img.get_pixel(x, 9) != Color(0, 0, 0, 0):
			img.set_pixel(x, 9, outline)
	return ImageTexture.create_from_image(img)

func _add_label() -> void:
	_label = Label.new()
	_label.text = "DEV"
	_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.30))
	_label.add_theme_font_size_override("font_size", 8)
	_label.z_index = 10
	add_child(_label)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1

	if direction != Vector2.ZERO:
		_moving = true
		var normalized := direction.normalized()
		var velocity := normalized * SPEED * delta
		var new_pos := position + velocity
		# Soft world bounds
		new_pos.x = clamp(new_pos.x, CELL_SIZE * 2, CELL_SIZE * 88)
		new_pos.y = clamp(new_pos.y, CELL_SIZE * 2, CELL_SIZE * 48)
		position = new_pos
		_sprite.flip_h = (normalized.x < 0)
		_label.position = Vector2(-8, -28)
	else:
		_moving = false
		_label.position = Vector2(-8, -28)

	# Animate crown bob
	if _crown != null:
		var t := Time.get_ticks_msec() / 1000.0
		_crown.offset.y = sin(t * 3.0) * 1.5

	# Check for nearby NPCs
	_detect_nearby_npc()

	# Update label position
	if _label != null:
		_label.position = Vector2(-10, -30)

func _detect_nearby_npc() -> void:
	_nearby_npc = null
	var world = get_parent()
	if world == null or not world.has_method("get_npcs"):
		return
	var npcs: Array = world.get("npcs") if "npcs" in world else []
	for npc in npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var dist := position.distance_to(npc.position)
		if dist < CELL_SIZE * 3.0:
			_nearby_npc = npc
			break

	# Update label to show nearby NPC role
	if _label != null:
		if _nearby_npc != null:
			var npc_actor = _nearby_npc.get("actor") if "_actor" in _nearby_npc else null
			if npc_actor != null:
				_label.text = "DEV > %s" % str(npc_actor.role).split(".")[-1]
			else:
				_label.text = "DEV > NPC"
		else:
			_label.text = "DEV"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_key_pressed(KEY_E):
		_interact_with_nearby()

func _interact_with_nearby() -> void:
	if _nearby_npc == null:
		notify("No NPC nearby!")
		return
	var npc = _nearby_npc
	# Try to trigger NPC behavior
	if npc.has_method("trigger_interact"):
		npc.trigger_interact()
		notify("Interacted with NPC!")
	elif npc.has_method("start_chat"):
		npc.start_chat()
		notify("Started chat with NPC!")
	else:
		notify("NPC has no interact handler")

func notify(msg: String) -> void:
	var world = get_parent()
	if world != null and world.has_method("notify"):
		world.notify("[DEV] " + msg)

func set_god_mode(enabled: bool) -> void:
	_is_god_mode = enabled
	if _sprite != null:
		if enabled:
			_sprite.modulate = Color(1.0, 1.0, 0.60)
		else:
			_sprite.modulate = Color(1.0, 1.0, 1.0)
