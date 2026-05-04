# atm_panel.gd
# ATM interface — PIN entry + withdrawal amount.
# ═══════════════════════════════════════════════════════════════════════
class_name ATMPanel
extends CanvasLayer

signal closed()
signal withdraw_success(amount: float)

const PIN := "1234"

var _atm: ATM = null
var _cash_balance: float = 200.0
var _entered_pin := ""
var _entered_amount: String = ""
var _step: int = 0  # 0=idle, 1=pin_entry, 2=amount_entry
var _msg: String = ""
var _is_open: bool = false

var _msg_lbl: Label
var _display_lbl: Label

const WITHDRAW_AMOUNTS := [10.0, 20.0, 50.0, 100.0]

func _ready() -> void:
	visible = false

func open(atm: ATM) -> void:
	_atm = atm
	_cash_balance = atm.balance()
	_entered_pin = ""
	_entered_amount = ""
	_step = 0
	_msg = "Welcome to Store ATM\nYour Balance: $%.2f" % _cash_balance
	_is_open = true
	_build_ui()
	visible = true

func close() -> void:
	_is_open = false
	visible = false
	_clear_ui()
	closed.emit()

func _clear_ui() -> void:
	for c in get_children():
		if is_instance_valid(c):
			c.queue_free()

func _build_ui() -> void:
	_clear_ui()
	var scr_w := 320.0
	var scr_h := 180.0
	var pan_x := (scr_w - 180) * 0.5
	var pan_y := (scr_h - 140) * 0.5
	var pan_w := 180.0
	var pan_h := 140.0

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.gui_input.connect(func(_e): pass)
	add_child(overlay)

	var panel := ColorRect.new()
	panel.position = Vector2(pan_x, pan_y)
	panel.size = Vector2(pan_w, pan_h)
	panel.color = Color(0.04, 0.04, 0.08, 0.97)
	add_child(panel)

	# Header
	var hdr := ColorRect.new()
	hdr.position = Vector2(pan_x, pan_y)
	hdr.size = Vector2(pan_w, 18)
	hdr.color = Color(0.08, 0.28, 0.08)
	add_child(hdr)

	var title_lbl := Label.new()
	title_lbl.text = "  STORE ATM  [ESC to close]"
	title_lbl.position = Vector2(pan_x + 2, pan_y + 3)
	title_lbl.add_theme_color_override("font_color", Color(0.80, 0.95, 0.80))
	title_lbl.add_theme_font_size_override("font_size", 8)
	add_child(title_lbl)

	# Display
	var disp_bg := ColorRect.new()
	disp_bg.position = Vector2(pan_x + 6, pan_y + 22)
	disp_bg.size = Vector2(pan_w - 12, 22)
	disp_bg.color = Color(0.05, 0.05, 0.08)
	add_child(disp_bg)

	_display_lbl = Label.new()
	_display_lbl.text = _msg
	_display_lbl.position = Vector2(pan_x + 10, pan_y + 24)
	_display_lbl.size = Vector2(pan_w - 20, 18)
	_display_lbl.add_theme_color_override("font_color", Color(0.30, 0.95, 0.40))
	_display_lbl.add_theme_font_size_override("font_size", 7)
	add_child(_display_lbl)

	# Message line
	_msg_lbl = Label.new()
	_msg_lbl.text = ""
	_msg_lbl.position = Vector2(pan_x + 6, pan_y + 46)
	_msg_lbl.size = Vector2(pan_w - 12, 12)
	_msg_lbl.add_theme_color_override("font_color", Color(0.95, 0.60, 0.30))
	_msg_lbl.add_theme_font_size_override("font_size", 6)
	add_child(_msg_lbl)

	# Quick amount buttons
	var btn_y := pan_y + 60
	var amounts := [20.0, 50.0, 100.0]
	for i in range(amounts.size()):
		var amt: float = amounts[i]
		var btn := _make_atm_button(pan_x + 6 + i * 56, btn_y, 52, 18,
			"$%.0f" % amt, amt)
		add_child(btn)

	# Keypad
	var key_y := pan_y + 84
	var keys := [
		["1","2","3"],
		["4","5","6"],
		["7","8","9"],
		["CLR","0","ENT"],
	]
	for row in range(keys.size()):
		for col in range(keys[row].size()):
			var kx := pan_x + 6 + col * 56
			var ky := key_y + row * 16
			var key_lbl: String = keys[row][col]
			var btn := _make_key_button(kx, ky, 52, 14, key_lbl)
			add_child(btn)

	_update_display()

func _make_atm_button(x: float, y: float, w: float, h: float, label: String, amount: float) -> Control:
	var btn := ColorRect.new()
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.color = Color(0.10, 0.30, 0.10)
	var lbl := Label.new()
	lbl.text = label
	lbl.position = Vector2(x, y + 3)
	lbl.size = Vector2(w, h)
	lbl.add_theme_color_override("font_color", Color(0.80, 0.95, 0.80))
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.add_theme_alignment_override(HORIZONTAL_ALIGNMENT_CENTER)
	add_child(lbl)
	btn.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_on_quick_withdraw(amount)
	)
	return btn

func _make_key_button(x: float, y: float, w: float, h: float, label: String) -> Control:
	var btn := ColorRect.new()
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	var key_color := Color(0.18, 0.18, 0.22) if label != "ENT" else Color(0.10, 0.40, 0.10)
	if label == "CLR":
		key_color = Color(0.40, 0.18, 0.10)
	btn.color = key_color
	var lbl := Label.new()
	lbl.text = label
	lbl.position = Vector2(x, y + 2)
	lbl.size = Vector2(w, h)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))
	lbl.add_theme_font_size_override("font_size", 7)
	lbl.add_theme_alignment_override(HORIZONTAL_ALIGNMENT_CENTER)
	add_child(lbl)
	btn.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_on_key_pressed(label)
	)
	return btn

func _on_key_pressed(key: String) -> void:
	match key:
		"CLR":
			if _step == 0 or _step == 1:
				_entered_pin = ""
				_msg = ""
			elif _step == 2:
				_entered_amount = ""
				_msg = ""
		"ENT":
			if _step == 0:
				_step = 1
				_msg = "Enter PIN:"
			elif _step == 1:
				_process_pin()
			elif _step == 2:
				_process_withdraw()
		_:
			if _step == 0:
				_step = 1
				_msg = "Enter PIN:"
			if _step == 1 and _entered_pin.length() < 4:
				_entered_pin += key
			elif _step == 2 and _entered_amount.length() < 4:
				_entered_amount += key
	_update_display()

func _on_quick_withdraw(amount: float) -> void:
	if _step < 2:
		_step = 2
		_msg = "Pin OK. Select or enter amount:"
	if _step == 2:
		var result: Dictionary = _atm.attempt_withdraw(amount, PIN)
		_show_result(result)
	_update_display()

func _process_pin() -> void:
	if _entered_pin == PIN:
		_step = 2
		_msg = "PIN accepted!\nSelect or enter amount to withdraw."
		_attempts = 0
	else:
		_entered_pin = ""
		var attempts_left := 3 - (_attempts + 1)
		if attempts_left <= 0:
			_msg = "Too many attempts. ATM locked."
			close()
		else:
			_msg = "Incorrect PIN. %d attempts left." % attempts_left

func _process_withdraw() -> void:
	if _entered_amount.is_empty():
		return
	var amount := _entered_amount.to_float()
	if amount <= 0:
		_msg = "Enter a valid amount."
		return
	var result: Dictionary = _atm.attempt_withdraw(amount, PIN)
	_show_result(result)

func _show_result(result: Dictionary) -> void:
	_msg = result["msg"]
	_entered_amount = ""
	if result["success"]:
		withdraw_success.emit(result["amount"])
		await get_tree().create_timer(1.5).timeout
		close()

func _update_display() -> void:
	if _display_lbl == null:
		return
	if _step == 0:
		_display_lbl.text = "Welcome!\nYour Balance: $%.2f\nPress a key to begin." % _cash_balance
	elif _step == 1:
		var dots := "•" * _entered_pin.length()
		_display_lbl.text = "Enter PIN: %s" % dots
	elif _step == 2:
		var amt_str := "$%s" % _entered_amount if not _entered_amount.is_empty() else "$---"
		_display_lbl.text = "Balance: $%.2f\nWithdraw: %s" % [_cash_balance, amt_str]
	if _msg_lbl != null:
		_msg_lbl.text = _msg

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close()
			return
		# Number keys
		var key_map := {
			KEY_0: "0", KEY_1: "1", KEY_2: "2", KEY_3: "3",
			KEY_4: "4", KEY_5: "5", KEY_6: "6",
			KEY_7: "7", KEY_8: "8", KEY_9: "9",
		}
		if key_map.has(event.keycode):
			_on_key_pressed(key_map[event.keycode])
		elif event.keycode == KEY_ENTER:
			_on_key_pressed("ENT")
		elif event.keycode == KEY_BACKSPACE:
			_on_key_pressed("CLR")
