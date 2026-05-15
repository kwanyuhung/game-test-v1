# ai_chat_brain.gd
# Per-NPC AI chat brain — generates contextual responses based on role, mood, and floor.
# Also handles NPC-to-NPC autonomous chat.
# ═══════════════════════════════════════════════════════════════════════
# EXTENDING: Add new topic keywords to RESPONSES or override generate_response().
# ═══════════════════════════════════════════════════════════════════════
class_name AIChatBrain
extends Node

const ActorData = preload("res://scripts/entities/actor_data.gd")

var _actor: ActorData.Actor
var _mood: float = 0.7   # 0=sad, 1=happy
var _topic_memory: Array = []  # last few topics discussed
var _chat_cooldown: float = 0.0
var _is_in_chat: bool = false

# ─── Response Database ────────────────────────────────────────────
# Topic → mood modifier → response array
const RESPONSES := {
	"hello": {
		"greeting": [
			"Hello! Welcome to the store!", "Hi there! Can I help you find something?",
			"Hey! Great to see a customer!", "Good day! How can I assist you today?",
			"Hi! Looking for anything specific?", "Hello! Feel free to browse around!",
		],
		"staff_greeting": [
			"Good morning! How can I help you today?",
			"Hello! Let me know if you need any assistance!",
			"Hi! Welcome to our supermarket!",
		],
	},
	"products": {
		"positive": [
			"Our produce section is amazing today!",
			"The bakery just got fresh bread this morning!",
			"We have a great deal on dairy right now!",
			"Have you seen our new snack aisle? So many choices!",
			"The frozen section has everything you need for dinner!",
		],
		"neutral": [
			"We stock all the essentials here.",
			"Most sections have what you need!",
			"Just take a look around, everything is organized by floor.",
		],
	},
	"staff_help": {
		"positive": [
			"I'm happy to help! What are you looking for?",
			"That's my job! Let me know if you need guidance.",
			"Sure thing! I can show you around if you'd like.",
			"Of course! This store has everything you need.",
		],
	},
	"food": {
		"hungry": [
			"The food street on this floor has amazing ramen!",
			"I'd recommend the Thai stall — their Pad Thai is incredible!",
			"The Italian stall does a great Margherita pizza!",
			"Have you tried the Bubble Tea Bar? So refreshing!",
			"The bakery on Floor 1 has the best pastries in town!",
			"The taco stall is my personal favourite!",
		],
		"neutral": [
			"There's a great selection of food here.",
			"The food court has options for everyone!",
			"Different cuisines every few steps — it's like a world tour!",
		],
	},
	"family": {
		"positive": [
			"This store is great for families!",
			"Bringing the kids? They'll love the arcade on Floor 8!",
			"The rooftop café is lovely in the evening!",
		],
	},
	"arcade": {
		"positive": [
			"Oh the arcade! Floor 8 has the claw machines — they're so fun!",
			"I spent way too much on the claw machines last week...",
			"Want to try your luck? The red plushies are the cutest!",
		],
	},
	"checkout": {
		"positive": [
			"The checkout lanes are on the ground floor!",
			"Just grab what you need and come pay at any lane.",
			"We accept all cards and cash!",
		],
	},
	"elevator": {
		"positive": [
			"The elevator is just to the right! Press E when you're near it.",
			"Which floor do you need? The elevator goes everywhere!",
			"You can also take the stairs if you prefer the exercise!",
		],
	},
	"weather": {
		"positive": [
			"Beautiful day to be shopping!",
			"I heard it might rain later — stay dry inside here!",
			"The rooftop is the best spot on a day like this!",
		],
	},
	"help": {
		"positive": [
			"Of course! What do you need help with?",
			"I'm here to help! Just ask.",
			"Sure, how can I assist you?",
		],
	},
	"goodbye": {
		"greeting": [
			"See you later! Happy shopping!", "Bye! Come back soon!",
			"Take care! Hope you find everything!",
			"Bye for now! Have a wonderful day!",
		],
	},
	"default": {
		"positive": [
			"That's interesting! Tell me more.",
			"I see! I'm not sure about that, but I know a lot about our products!",
			"Hmm, I'm just a shopper here myself! Ha ha!",
			"Oh that's cool! I love this store!",
			"I agree! This place has everything!",
			"Ha! You said it! I'm here almost every day.",
		],
		"neutral": [
			"Yeah, I know what you mean.",
			"I'm just here grabbing a few things!",
			"That's a popular opinion around here.",
			"Hmm, not sure — have you asked someone who works here?",
		],
	},
}

# ─── Initialization ───────────────────────────────────────────────

func configure(actor: ActorData.Actor) -> void:
	_actor = actor
	_mood = randf_range(0.5, 1.0)

# ─── Response Generation ───────────────────────────────────────────

func generate_response(input_text: String) -> String:
	_topic_memory.append(input_text)
	if _topic_memory.size() > 5:
		_topic_memory.pop_front()

	var mood_key := "positive" if _mood > 0.6 else "neutral"
	if _mood < 0.3:
		mood_key = "neutral"

	# Detect topic
	var topic := _detect_topic(input_text)

	# Staff have more helpful responses
	if _actor != null and _actor.role == ActorData.Role.STAFF:
		var role_responses: Array = RESPONSES.get(topic, {}).get("staff_greeting", [])
		if role_responses.is_empty():
			role_responses = RESPONSES.get(topic, {}).get(mood_key, RESPONSES["default"][mood_key])
		return _pick(role_responses)

	var candidates :Array= RESPONSES.get(topic, {}).get(mood_key, [])
	if candidates.is_empty():
		candidates = RESPONSES.get("default", {}).get(mood_key, ["Sure!"])
	return _pick(candidates)

func _detect_topic(text: String) -> String:
	text = text.to_lower()
	if text.contains("hello") or text.contains("hi ") or text.contains("hey") or text.contains("good morning"):
		return "hello"
	if text.contains("help") or text.contains("where") or text.contains("can i find"):
		return "help"
	if text.contains("food") or text.contains("eat") or text.contains("hungry") or text.contains("meal") or text.contains("lunch") or text.contains("dinner"):
		return "food"
	if text.contains("product") or text.contains("buy") or text.contains("shop"):
		return "products"
	if text.contains("family") or text.contains("kids") or text.contains("child") or text.contains("baby"):
		return "family"
	if text.contains("arcade") or text.contains("claw") or text.contains("game") or text.contains("play"):
		return "arcade"
	if text.contains("checkout") or text.contains("pay") or text.contains("cash"):
		return "checkout"
	if text.contains("elevator") or text.contains("lift") or text.contains("floor"):
		return "elevator"
	if text.contains("weather") or text.contains("sun") or text.contains("rain"):
		return "weather"
	if text.contains("bye") or text.contains("see you") or text.contains("goodbye"):
		return "goodbye"
	return "default"

func _pick(arr: Array) -> String:
	if arr.is_empty():
		return "Sure!"
	return arr[randi() % arr.size()]

# ─── NPC-to-NPC Chat ───────────────────────────────────────────────

func should_initiate_chat() -> bool:
	if _chat_cooldown > 0.0:
		return false
	_chat_cooldown = randf_range(8.0, 20.0)
	return randf() < 0.3  # 30% chance per check

func trigger_autonomous_chat() -> String:
	var topics := ["hello", "food", "arcade", "products", "family"]
	var topic: String = topics[randi() % len(topics)]
	var mood_key := "positive" if _mood > 0.6 else "neutral"
	var candidates: Array = RESPONSES.get(topic, {}).get(mood_key, [])
	if candidates.is_empty():
		candidates = RESPONSES.get("default", {}).get(mood_key, [])
	return _pick(candidates)

func process(delta: float) -> void:
	_chat_cooldown = maxf(0.0, _chat_cooldown - delta)

func set_mood(val: float) -> void:
	_mood = clampf(val, 0.0, 1.0)

func get_mood() -> float:
	return _mood
