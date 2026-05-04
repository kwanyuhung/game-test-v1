# atm.gd
# ATM machine — provides store cash withdrawals.
# Player walks close and presses E to open ATM panel.
# Simple 4-digit PIN entry. Player has a cash balance.
# ═══════════════════════════════════════════════════════════════════════
class_name ATM
extends Node2D

signal cash_withdrawn(amount: float)

const PIN := "1234"  # Default PIN for all ATMs

var _panel_shown := false
var _entered_pin := ""
var _attempts := 0
var _locked := false
var _lock_timer := 0.0

# Player's cash balance (shared via a static var, managed by Player or a wallet system)
var _player_cash: float = 200.0  # Starting cash

func _ready() -> void:
	add_to_group("atm")

func is_nearby(pos: Vector2) -> bool:
	return position.distance_to(pos) < CELL_SIZE * 6.0

func _process(delta: float) -> void:
	if _locked:
		_lock_timer -= delta
		if _lock_timer <= 0.0:
			_locked = false
			_attempts = 0
			_entered_pin = ""

func attempt_withdraw(amount: float, pin: String) -> Dictionary:
	if _locked:
		return {"success": false, "msg": "ATM locked. Try again later."}
	if pin != PIN:
		_attempts += 1
		_entered_pin = ""
		if _attempts >= 3:
			_locked = true
			_lock_timer = 15.0
			return {"success": false, "msg": "Too many attempts. Locked for 15s."}
		return {"success": false, "msg": "Incorrect PIN. %d attempts left." % (3 - _attempts)}
	if amount <= 0:
		return {"success": false, "msg": "Enter a valid amount."}
	if _player_cash < amount:
		return {"success": false, "msg": "Insufficient funds. Balance: $%.2f" % _player_cash}
	_player_cash -= amount
	cash_withdrawn.emit(amount)
	return {"success": true, "msg": "Withdrawn $%.2f. Balance: $%.2f" % [amount, _player_cash], "amount": amount}

func balance() -> float:
	return _player_cash

func set_balance(val: float) -> void:
	_player_cash = val

const CELL_SIZE := 16
