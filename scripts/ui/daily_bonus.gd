class_name DailyBonus
# Daily login streak — rewards players who return each day.
# Tracks last login date and streak count in save data.
extends Node

const STREAK_FILE := "user://streak.json"

var _streak_days: int = 0
var _last_login_date: String = ""
var _bonus_claimed_today: bool = false

signal streak_reward(days: int, bonus_xp: int)

func _ready() -> void:
	_load_streak()

func _load_streak() -> void:
	if not FileAccess.file_exists(STREAK_FILE):
		_streak_days = 0
		_last_login_date = ""
		return
	var f = FileAccess.open(STREAK_FILE, FileAccess.READ)
	if f == null:
		_streak_days = 0
		return
	# Godot 3 标准 JSON 解析
	var json = JSON.new()
	var result = json.parse(f.get_as_text())
	f.close()
	if result != OK:
		return
	# 🔥 修复：Godot 3 用 .data 而非 .result
	var data: Dictionary = json.data
	_streak_days = data.get("streak_days", 0)
	_last_login_date = data.get("last_login_date", "")

func _save_streak() -> void:
	var data: Dictionary = {
		"streak_days": _streak_days,
		"last_login_date": _last_login_date,
	}
	# 🔥 100% 兼容 Godot 3 的正确写法
	var json = JSON.new()
	var json_str: String = json.stringify(data)
	
	var f = FileAccess.open(STREAK_FILE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(json_str)
	f.close()

func check_and_award(main_node) -> void:
	var today: String = Time.get_date_string_from_system()
	if today == _last_login_date:
		# Already logged in today
		return

	if _last_login_date != "":
		var yesterday_str: String = _get_yesterday()
		if yesterday_str == _last_login_date:
			# Consecutive day — increase streak
			_streak_days += 1
		else:
			# Streak broken — reset
			_streak_days = 1
	else:
		_streak_days = 1

	_last_login_date = today
	_save_streak()

	var bonus_xp: int = _get_bonus_for_streak(_streak_days)
	if bonus_xp > 0:
		# 🔥 修复第70行：显式声明变量类型
		var ps: Node = main_node._player_stats
		if ps != null:
			ps.add_xp(bonus_xp, "Daily Login Bonus (Day %d)" % _streak_days)
		streak_reward.emit(_streak_days, bonus_xp)

func _get_yesterday() -> String:
	# Returns yesterday's date string in YYYY-MM-DD format
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	# 🔥 修复第78行：显式声明int类型
	var yesterday: int = dt["day"] - 1
	if yesterday < 1:
		# Approximate — would need month handling for real use
		yesterday = 1
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], yesterday]

func _get_bonus_for_streak(days: int) -> int:
	# Bonus XP scales with streak length
	if days >= 7:
		return 50
	elif days >= 3:
		return 25
	elif days >= 1:
		return 10
	return 0

func get_streak() -> int: 
	return _streak_days

func get_streak_message() -> String:
	if _streak_days == 0:
		return "No streak — play tomorrow to start one!"
	var xp: int = _get_bonus_for_streak(_streak_days)
	return "Day %d streak! +%d XP bonus" % [_streak_days, xp]
