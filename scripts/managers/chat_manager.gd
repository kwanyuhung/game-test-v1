# chat_manager.gd
# Global chat router — handles NPC-to-NPC autonomous conversations
# and player-to-NPC chat sessions.
# ═══════════════════════════════════════════════════════════════════════
# NPC-to-NPC chat: periodically check if two nearby NPCs should talk.
# Player chat: routed through ChatPanel → ChatBubble on NPC.
# ═══════════════════════════════════════════════════════════════════════
class_name ChatManager
extends Node

const ActorData = preload("res://scripts/entities/actor_data.gd")
const ChatBubble = preload("res://scripts/ui/chat_bubble.gd")

var _npcs: Array = []     # all NPCController nodes
var _chat_cooldowns: Dictionary = {}  # npc_id → cooldown timer
var _active_chats: Dictionary = {}   # pair_id → chat state
var _chat_check_interval: float = 6.0
var _chat_check_timer: float = 0.0

const CHAT_RANGE := 120.0   # pixels — NPCs within this range may chat
const CHAT_INTERVAL := 15.0 # seconds between same pair chatting

func _ready() -> void:
	_chat_check_timer = randf_range(2.0, _chat_check_interval)

func register_npc(npc: Node) -> void:
	if not _npcs.has(npc):
		_npcs.append(npc)
		var id := npc.get_instance_id()
		_chat_cooldowns[id] = 0.0

func unregister_npc(npc: Node) -> void:
	var id := npc.get_instance_id()
	_npcs.erase(npc)
	_chat_cooldowns.erase(id)  # Clean up cooldown for this NPC

func _process(delta: float) -> void:
	_chat_check_timer -= delta
	if _chat_check_timer <= 0.0:
		_chat_check_timer = _chat_check_interval
		_check_for_npc_chats()

	for id in _chat_cooldowns.keys():
		_chat_cooldowns[id] = maxf(0.0, _chat_cooldowns[id] - delta)

# ─── NPC-to-NPC Autonomous Chat ────────────────────────────────

func _check_for_npc_chats() -> void:
	# Pick random pairs within range to have a conversation
	# First, clean up any invalid NPC references from _npcs array
	var valid_npcs: Array = []
	for npc in _npcs:
		if is_instance_valid(npc):
			valid_npcs.append(npc)
	_npcs = valid_npcs
	
	for i in range(_npcs.size()):
		for j in range(i + 1, _npcs.size()):
			var npc_a: Node = _npcs[i]
			var npc_b: Node = _npcs[j]
			if not is_instance_valid(npc_a) or not is_instance_valid(npc_b):
				continue
			if not _are_valid_for_chat(npc_a, npc_b):
				continue
			var id_a := npc_a.get_instance_id()
			var id_b := npc_b.get_instance_id()
			var pair_key := "%d_%d" % [mini(id_a, id_b), maxi(id_a, id_b)]
			if _chat_cooldowns.get(id_a, 0.0) > 0.0 or _chat_cooldowns.get(id_b, 0.0) > 0.0:
				continue
			# Check if within range
			var pos_a: Vector2 = npc_a.global_position if "global_position" in npc_a else Vector2.ZERO
			var pos_b: Vector2 = npc_b.global_position if "global_position" in npc_b else Vector2.ZERO
			if pos_a.distance_to(pos_b) > CHAT_RANGE:
				continue
			# Start a chat between these two
			if randf() < 0.4:  # 40% chance per eligible pair
				_start_npc_chat(npc_a, npc_b)
				_chat_cooldowns[id_a] = CHAT_INTERVAL
				_chat_cooldowns[id_b] = CHAT_INTERVAL
				break  # one chat per tick max

func _are_valid_for_chat(npc_a: Node, npc_b: Node) -> bool:
	# Must both have brains (检查是否拥有 get_actor 方法)
	if not npc_a.has_method("get_actor") or not npc_b.has_method("get_actor"):
		return false
	var actor_a: ActorData.Actor = npc_a.get_actor()
	var actor_b: ActorData.Actor = npc_b.get_actor()
	# Staff and customers can both chat
	return actor_a != null and actor_b != null and actor_a.is_active and actor_b.is_active

func _start_npc_chat(npc_a: Node, npc_b: Node) -> void:
	# Both NPCs must be valid and expose get_chat_brain() (NPCController does)
	if not is_instance_valid(npc_a) or not is_instance_valid(npc_b):
		return
	var brain_a: AIChatBrain = npc_a.get_chat_brain()
	var brain_b: AIChatBrain = npc_b.get_chat_brain()
	if brain_a == null or brain_b == null:
		return

	if not brain_a.should_initiate_chat():
		return

	# Walk both NPCs to within ~0.5 character widths of each other so the
	# shared bubble sits naturally between them. If either can't be
	# commanded (frozen, already in chat, etc.) skip the step.
	const TARGET_GAP := 16.0
	var pos_a: Vector2 = npc_a.global_position
	var pos_b: Vector2 = npc_b.global_position
	var mid: Vector2 = (pos_a + pos_b) * 0.5
	var diff: Vector2 = pos_b - pos_a
	var dist: float = diff.length()
	if dist > 0.001:
		var dir: Vector2 = diff / dist
		var goal_a: Vector2 = mid - dir * TARGET_GAP * 0.5
		var goal_b: Vector2 = mid + dir * TARGET_GAP * 0.5
		npc_a.walk_to_position(goal_a, 3.0)
		npc_b.walk_to_position(goal_b, 3.0)

	# Wait for them to arrive (or for the walk timeout to elapse).
	# Polling at 0.1s gives a snappy start without busy-waiting.
	var waited := 0.0
	const ARRIVE_TOL := 6.0
	const MAX_WAIT := 3.5
	while waited < MAX_WAIT:
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(npc_a) or not is_instance_valid(npc_b):
			return
		if npc_a.is_at_target(ARRIVE_TOL) and npc_b.is_at_target(ARRIVE_TOL):
			break
		waited += 0.1

	# Lock both NPCs in place and have them face each other
	npc_a.set_in_chat(true)
	npc_b.set_in_chat(true)
	npc_a.face_towards(npc_b.global_position)
	npc_b.face_towards(npc_a.global_position)

	var topic := _pick_npc_topic(npc_a, npc_b)
	var greeting := brain_a.trigger_autonomous_chat()
	_show_pair_bubble(npc_a, npc_b, greeting)

	# NPC B 延迟回复
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(npc_a) or not is_instance_valid(npc_b):
		return
	if not npc_a.is_in_chat() or not npc_b.is_in_chat():
		return
	var response := brain_b.generate_response(greeting)
	_show_pair_bubble(npc_a, npc_b, response)

	# 随机追加对话
	if randf() < 0.5:
		await get_tree().create_timer(2.0).timeout
		if not is_instance_valid(npc_a) or not is_instance_valid(npc_b):
			return
		if not npc_a.is_in_chat() or not npc_b.is_in_chat():
			return
		var reply := brain_a.generate_response(response)
		_show_pair_bubble(npc_a, npc_b, reply)

	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(npc_a): npc_a.set_in_chat(false)
	if is_instance_valid(npc_b): npc_b.set_in_chat(false)

func _pick_npc_topic(npc_a: Node, npc_b: Node) -> String:
	var topics := ["hello", "food", "arcade", "products", "family", "weather"]
	return topics[randi() % topics.size()]

func _show_npc_bubble(npc: Node, text: String) -> void:
	if not is_instance_valid(npc):
		return
	var bubble := ChatBubble.new()
	if npc.get_parent() != null:
		npc.get_parent().add_child(bubble)
		bubble.global_position = npc.global_position + Vector2(0, -30)
		bubble.display(text, 3.5)
	else:
		return

# Show a single shared bubble that sits at the midpoint of two NPCs'
# heads and tracks them every frame, with tail lines pointing to each.
func _show_pair_bubble(npc_a: Node, npc_b: Node, text: String) -> void:
	if not is_instance_valid(npc_a) or not is_instance_valid(npc_b):
		return
	var parent: Node = npc_a.get_parent()
	if parent == null or npc_b.get_parent() != parent:
		# Pair must share a parent (the world / a floor) for shared space coords
		return
	var bubble := ChatBubble.new()
	parent.add_child(bubble)
	bubble.set_anchor_pair(npc_a, npc_b)
	bubble.display(text, 3.5)
