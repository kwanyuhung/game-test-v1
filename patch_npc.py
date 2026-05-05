with open(r'C:\Users\user\Documents\game-test\scripts\npc_controller.gd', 'r', encoding='utf-8') as f:
    content = f.read()

old = '''func _do_at_checkout_npc(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		# Checkout done! Leave store
		_actor.cart_item_count = 0
		_has_cart = false
		_actor.has_cart = false
		_hide_cart()
		_leave_store()

func _get_floor_for_section(section_id: String) -> int:'''

new = '''func _do_at_checkout_npc(delta: float) -> void:
	_state_timer -= delta
	# Seniors may need help at checkout
	if _actor.life_stage == ActorData.LifeStage.SENIOR and not _help_received and randf() < 0.4:
		_needs_help_at_checkout = true
		_show_speech_bubble("Need help?")
		_state = BehaviorState.RECEIVING_HELP
		_state_timer = 8.0
		_try_find_assisting_staff()
		return
	if _state_timer <= 0.0:
		# Checkout done! Leave store
		_actor.cart_item_count = 0
		_has_cart = false
		_actor.has_cart = false
		_hide_cart()
		_leave_store()

# ─── Elder Assistance ───────────────────────────────────────

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
	# Find a nearby staff member on the same floor to assist
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
		# Staff member found! Direct them to assist
		npc._start_assist_elder(self)
		_assisting_staff = npc
		break

func _start_assist_elder(elder: NPCController) -> void:
	_state = BehaviorState.ASSISTING_ELDER
	_target_pos = elder.global_position
	_state_timer = 6.0

func _do_receiving_help(delta: float) -> void:
	# Stand still, waiting for staff
	if _state_timer <= 0.0 or _assisting_staff != null:
		if _help_received:
			_hide_speech_bubble()
			_state_timer = 3.0
			_state = BehaviorState.IDLE
		else:
			# No help came, proceed anyway
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
	# At elder — show help bubble
	_show_speech_bubble("Here, let me help!")
	_state_timer -= delta
	if _state_timer <= 0.0:
		# Help complete — award XP to player if main node available
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

func _get_floor_for_section(section_id: String) -> int:'''

if old in content:
    content = content.replace(old, new)
    with open(r'C:\Users\user\Documents\game-test\scripts\npc_controller.gd', 'w', encoding='utf-8') as f:
        f.write(content)
    print('Replaced successfully')
else:
    print('Pattern not found')
    # Debug: show the area around checkout
    idx = content.find('func _do_at_checkout_npc')
    if idx >= 0:
        print(repr(content[idx:idx+500]))
