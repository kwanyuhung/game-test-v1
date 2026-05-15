# game_clock.gd
# 24-hour game clock. Runs independently of physics/gameplay.
# Emits signals for time-based events (store open/close, rush hour, etc.)
# ═══════════════════════════════════════════════════════════════════════
# SPEED: 1 real second = 1 game minute
# Full day = 24 * 60 = 1440 game minutes = 24 real minutes
# ═══════════════════════════════════════════════════════════════════════
class_name GameClock
extends Node

signal hour_changed(hour: int)
signal day_changed(day_index: int)
signal period_changed(period: int)  # 0=night, 1=morning, 2=afternoon, 3=evening
signal shift_report(report: Dictionary)

const MINUTES_PER_REAL_SECOND := 1.0  # 1 real sec = 1 game minute
const STORE_OPEN_HOUR := 6    # 06:00
const STORE_CLOSE_HOUR := 23  # 23:00
const NIGHT_START := 23       # 23:00 — night period starts
const MORNING_START := 6      # 06:00
const RUSH_MORNING_START := 7
const RUSH_EVENING_START := 17

enum Period { NIGHT = 0, MORNING = 1, AFTERNOON = 2, EVENING = 3 }

var _game_minute: int = 0      # 0..1439
var _game_hour: int = 0        # 0..23
var _day_index: int = 1       # starts at day 1
var _period: Period = Period.NIGHT
var _accumulator: float = 0.0  # real seconds accumulated

var _report_issues_resolved: int = 0
var _report_issues_created: int = 0

func _process(delta: float) -> void:
	_accumulator += delta
	if _accumulator >= MINUTES_PER_REAL_SECOND:
		var mins := int(_accumulator / MINUTES_PER_REAL_SECOND)
		_accumulator = fmod(_accumulator, MINUTES_PER_REAL_SECOND)
		for _i in range(mins):
			_advance_minute()

func _advance_minute() -> void:
	_game_minute += 1
	if _game_minute >= 60:
		_game_minute = 0
		_game_hour += 1
		if _game_hour >= 24:
			_game_hour = 0
			_end_day()
		hour_changed.emit(_game_hour)
		_update_period()

func _update_period() -> void:
	var new_period: Period
	match _game_hour:
		0, 1, 2, 3, 4, 5:  new_period = Period.NIGHT
		6, 7, 8, 9, 10, 11: new_period = Period.MORNING
		12, 13, 14, 15, 16: new_period = Period.AFTERNOON
		17, 18, 19, 20, 21, 22: new_period = Period.EVENING
		23: new_period = Period.NIGHT
	if new_period != _period:
		_period = new_period
		period_changed.emit(_period)

func _end_day() -> void:
	_day_index += 1
	# Emit shift report before reset
	shift_report.emit({
		"day": _day_index - 1,
		"issues_resolved": _report_issues_resolved,
		"issues_created": _report_issues_created,
	})
	_report_issues_resolved = 0
	_report_issues_created = 0
	day_changed.emit(_day_index)

# ─── Accessors ─────────────────────────────────────────────────────

func game_hour() -> int:
	return _game_hour

func game_minute() -> int:
	return _game_minute

func game_time_string() -> String:
	return "%02d:%02d" % [_game_hour, _game_minute]

func day_index() -> int:
	return _day_index

func period() -> Period:
	return _period

func period_name() -> String:
	match _period:
		Period.NIGHT:     return "Night"
		Period.MORNING:   return "Morning"
		Period.AFTERNOON: return "Afternoon"
		Period.EVENING:   return "Evening"
	return "Unknown"

func is_store_open() -> bool:
	return _game_hour >= STORE_OPEN_HOUR and _game_hour < STORE_CLOSE_HOUR

func is_rush_hour() -> bool:
	return (_game_hour >= RUSH_MORNING_START and _game_hour <= 9) or \
		   (_game_hour >= RUSH_EVENING_START and _game_hour <= 20)

func is_night() -> bool:
	return _period == Period.NIGHT

# Customer spawn rate multiplier based on time
func customer_rate_multiplier() -> float:
	match _period:
		Period.NIGHT:     return 0.1
		Period.MORNING:   return 0.8 if _game_hour < 9 else 1.2
		Period.AFTERNOON: return 0.9
		Period.EVENING:   return 1.5 if _game_hour >= 18 else 1.0
	return 1.0

# Ambient lighting tint based on time
func ambient_tint() -> Color:
	match _period:
		Period.NIGHT:     return Color(0.10, 0.12, 0.20)   # dark blue
		Period.MORNING:   return Color(0.85, 0.80, 0.70)  # warm morning
		Period.AFTERNOON: return Color(0.80, 0.82, 0.78)  # neutral
		Period.EVENING:   return Color(0.60, 0.55, 0.70)  # purple dusk
	return Color.WHITE

# ─── Report tracking ───────────────────────────────────────────────

func record_issue_resolved():
	_report_issues_resolved += 1

func record_issue_created():
	_report_issues_created += 1
