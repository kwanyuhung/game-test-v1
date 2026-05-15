# scripts/anti_theft.gd
# Phase Q: Anti-Theft System
class_name AntiTheftScript
extends Node

# Suspicious activity tracking
var _suspicious_npcs: Array = []  # [{npc, section_id, linger_time, detected}]
var _active_thefts: int = 0
var _thefts_caught: int = 0
var _total_fines_collected: int = 0

signal suspicious_activity(npc, section_id: String)
signal theft_caught(npc, xp_reward: int, cash_reward: float)
signal theft_escaped(npc)

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Check for suspicious lingering NPCs
	_update_suspicious(delta)

func _update_suspicious(delta: float) -> void:
	var to_remove := []
	for entry in _suspicious_npcs:
		entry["linger_time"] += delta
		if entry["linger_time"] > 15.0 and not entry.get("detected", false):
			# NPC has been lingering too long — suspicious!
			entry["detected"] = true
			_active_thefts += 1
			suspicious_activity.emit(entry["npc"], entry["section_id"])
	for entry in _suspicious_npcs:
		if entry["linger_time"] > 60.0:
			# NPC escaped after lingering too long without being caught
			_active_thefts = maxi(_active_thefts - 1, 0)
			theft_escaped.emit(entry["npc"])
			to_remove.append(entry)
	for entry in to_remove:
		_suspicious_npcs.erase(entry)

func report_suspicious_behavior(npc, section_id: String) -> void:
	# Called when NPC lingers near a section for too long
	for entry in _suspicious_npcs:
		if entry["npc"] == npc:
			return  # already tracked
	_suspicious_npcs.append({"npc": npc, "section_id": section_id, "linger_time": 0.0, "detected": false})

func catch_thief(npc, catcher_is_player: bool) -> Dictionary:
	# Returns {xp, cash} reward for catching a thief
	_active_thefts = maxi(_active_thefts - 1, 0)
	_thefts_caught += 1
	var base_xp := 25
	var base_cash := 15.0
	# Bonus if player caught it themselves
	if catcher_is_player:
		base_xp *= 2
		base_cash *= 1.5
	_total_fines_collected += int(base_cash)
	theft_caught.emit(npc, base_xp, base_cash)
	return {"xp": base_xp, "cash": base_cash}

func get_active_thefts() -> int:
	return _active_thefts

func get_thefts_caught() -> int:
	return _thefts_caught

func get_total_fines() -> int:
	return _total_fines_collected

func is_npc_suspicious(npc) -> bool:
	for entry in _suspicious_npcs:
		if entry["npc"] == npc and entry.get("detected", false):
			return true
	return false

func get_security_alert_level() -> String:
	# 0 = clear, 1 = watch, 2 = alert, 3 = active theft
	var thefts := _active_thefts
	if thefts == 0:
		return "CLEAR"
	elif thefts == 1:
		return "SUSPICIOUS"
	else:
		return "ACTIVE THEFT"
