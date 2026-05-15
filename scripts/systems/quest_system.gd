class_name QuestSystem
# Simple daily quests — 3 objectives per day, bonus XP on completion.
# Tracks completion in save data.
extends Node

const QUEST_FILE := "user://quests.json"

const ALL_QUESTS: Array = [
	{"id": "buy_dairy", "desc": "Buy 3 Dairy items", "target": 3, "section": "dairy", "xp": 15},
	{"id": "buy_produce", "desc": "Buy 3 Produce items", "target": 3, "section": "produce", "xp": 15},
	{"id": "checkout_50", "desc": "Checkout spending $50+", "target": 50.0, "type": "spend", "xp": 20},
	{"id": "checkout_5", "desc": "Checkout 5 times", "target": 5, "type": "checkouts", "xp": 25},
	{"id": "fix_issue", "desc": "Fix 1 maintenance issue", "target": 1, "type": "fix", "xp": 15},
	{"id": "explore_3floors", "desc": "Visit 3 different floors", "target": 3, "type": "floors", "xp": 20},
	{"id": "buy_snacks", "desc": "Buy 5 Snacks items", "target": 5, "section": "snacks", "xp": 15},
	{"id": "spend_20", "desc": "Spend $20+ in one checkout", "target": 20.0, "type": "single_checkout", "xp": 10},
]

var _daily_quests: Array = []
var _completed_ids: Array = []
var _progress: Dictionary = {}  # quest_id -> current value
var _notified: bool = false

signal quest_completed(quest_id: String, desc: String, xp: int)
signal all_daily_complete()

func _ready() -> void:
	_load_quests()

func _load_quests() -> void:
	if not FileAccess.file_exists(QUEST_FILE):
		_start_new_day()
		return
	var f = FileAccess.open(QUEST_FILE, FileAccess.READ)
	if f == null:
		_start_new_day()
		return
	# Godot 3 标准 JSON 解析
	var json = JSON.new()
	var result = json.parse(f.get_as_text())
	f.close()
	if result != OK:
		_start_new_day()
		return
	# 🔥 核心修复：Godot 3 使用 .data 获取解析数据
	var data: Dictionary = json.data
	# Check if it's a new day
	var saved_date: String = data.get("date", "")
	var today: String = Time.get_date_string_from_system()
	if saved_date != today:
		_start_new_day()
		return
	_daily_quests = data.get("quests", [])
	_completed_ids = data.get("completed", [])
	_progress = data.get("progress", {})
	
func _save_quests() -> void:
	var data: Dictionary = {
		"date": Time.get_date_string_from_system(),
		"quests": _daily_quests,
		"completed": _completed_ids,
		"progress": _progress,
	}
	# 🔥 修复：Godot 3 不支持 JSON.stringify，改用标准写法
	var json = JSON.new()
	var json_str: String = json.stringify(data)
	
	var f = FileAccess.open(QUEST_FILE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(json_str)
	f.close()

func _start_new_day() -> void:
	# Pick 3 random quests
	var pool: Array = ALL_QUESTS.duplicate()
	pool.shuffle()
	_daily_quests = pool.slice(0, 3)
	_completed_ids = []
	_progress = {}
	for q in _daily_quests:
		_progress[q["id"]] = 0
	_notified = false
	_save_quests()

func get_daily_quests() -> Array:
	return _daily_quests

func get_quest_progress(quest_id: String) -> int:
	return _progress.get(quest_id, 0)

func is_completed(quest_id: String) -> bool:
	return quest_id in _completed_ids

func on_item_bought(section_id: String) -> void:
	for q in _daily_quests:
		if q.get("section", "") == section_id:
			if not is_completed(q["id"]):
				_progress[q["id"]] = _progress.get(q["id"], 0) + 1
				_check_quest(q)
	_save_quests()

func on_checkout_completed(total: float) -> void:
	# Spend quests
	for q in _daily_quests:
		if q.get("type", "") == "spend":
			if not is_completed(q["id"]):
				_progress[q["id"]] = _progress.get(q["id"], 0) + total
				_check_quest(q)
		if q.get("type", "") == "single_checkout":
			if not is_completed(q["id"]) and total >= q["target"]:
				_complete_quest(q)
	_save_quests()

func on_checkout_count() -> void:
	for q in _daily_quests:
		if q.get("type", "") == "checkouts":
			if not is_completed(q["id"]):
				_progress[q["id"]] = _progress.get(q["id"], 0) + 1
				_check_quest(q)
	_save_quests()

func on_issue_fixed() -> void:
	for q in _daily_quests:
		if q.get("type", "") == "fix":
			if not is_completed(q["id"]):
				_progress[q["id"]] = _progress.get(q["id"], 0) + 1
				_check_quest(q)
	_save_quests()

func on_floor_visited(floor_idx: int) -> void:
	var key: String = "floor_%d" % floor_idx
	if not _progress.has(key):
		_progress[key] = 0
	_progress[key] = _progress.get(key, 0) + 1
	for q in _daily_quests:
		if q.get("type", "") == "floors":
			if not is_completed(q["id"]):
				var unique_floors: int = 0
				for k in _progress.keys():
					if k.begins_with("floor_") and _progress[k] > 0:
						unique_floors += 1
				_progress[q["id"]] = unique_floors
				_check_quest(q)
	_save_quests()

# 🔥 修复第144行错误：显式声明变量类型，杜绝 Variant 推断
func _check_quest(q: Dictionary) -> void:
	var current: float = _progress.get(q["id"], 0)
	var target: float = q["target"]
	if current >= target:
		_complete_quest(q)

func _complete_quest(q: Dictionary) -> void:
	if is_completed(q["id"]):
		return
	_completed_ids.append(q["id"])
	_progress[q["id"]] = q["target"]
	quest_completed.emit(q["id"], q["desc"], q["xp"])
	_notify_all_complete()
	_save_quests()

func _notify_all_complete() -> void:
	if _notified:
		return
	if _completed_ids.size() >= _daily_quests.size():
		_notified = true
		all_daily_complete.emit()
