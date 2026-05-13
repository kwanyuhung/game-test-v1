# dev_tools.gd

# Developer tools panel — accessible only in DEV_MODE
# Press F3 to toggle this panel
extends Control

signal super_actor_spawned(actor)
signal dev_commandIssued(cmd: String, args: Dictionary)

const DEV_MODE := true  # Set to false to disable dev tools globally

var _main: Node = null
var _super_actor: Node = null
var _visible := false
var _debug_config = null

# ─── Panel Layout ────────────────────────────────────────────────
# Title bar + action buttons stacked vertically
func _ready() -> void:
	visible = false
	_custom_init()

func _custom_init() -> void:
	# Load debug config
	_debug_config = preload("res://scripts/debug_config.gd").new()
	
	# Semi-transparent dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.10, 0.92)
	add_child(bg)

	# Title bar
	var title_bar := ColorRect.new()
	title_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_bar.offset_left = 0; title_bar.offset_top = 0
	title_bar.offset_right = 340; title_bar.offset_bottom = 26
	title_bar.color = Color(0.20, 0.20, 0.35, 1.0)
	add_child(title_bar)

	var title_lbl := Label.new()
	title_lbl.text = "DEV TOOLS  [F3] to close"
	title_lbl.set_anchors_preset(Control.PRESET_CENTER)
	title_lbl.anchor_left = 0.5; title_lbl.anchor_right = 0.5
	title_lbl.offset_left = -120; title_lbl.offset_top = 4
	title_lbl.offset_right = 120; title_lbl.offset_bottom = 24
	title_lbl.add_theme_color_override("font_color", Color(0.50, 0.85, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_lbl)

	# Button grid starts at y=36
	var y_offset := 38
	var col_width := 160
	var btn_height := 26
	var btn_gap := 4

	var buttons := [
		{"label": "SUPER ACTOR [S]", "cmd": "spawn_super"},
		{"label": "GOD MODE [G]", "cmd": "god_mode"},
		{"label": "∞ MONEY [M]", "cmd": "infinite_money"},
		{"label": "FAST TIME [T]", "cmd": "fast_time"},
		{"label": "SPAWN 5 CUSTOMERS", "cmd": "spawn_customers"},
		{"label": "SPAWN 3 STAFF", "cmd": "spawn_staff"},
		{"label": "ALL ACHIEVEMENTS", "cmd": "all_achievements"},
		{"label": "MAX STATS", "cmd": "max_stats"},
		{"label": "TRIGGER DELIVERY", "cmd": "trigger_delivery"},
		{"label": "LOW STOCK ALERT", "cmd": "low_stock_alert"},
		{"label": "KILL ALL NPCs", "cmd": "kill_npcs"},
		{"label": "REGEN FLOOR 0", "cmd": "regen_floor_0"},
		{"label": "REGEN FLOOR 1", "cmd": "regen_floor_1"},
		{"label": "REGEN FLOOR 2", "cmd": "regen_floor_2"},
		{"label": "REGEN ALL CFG FLOORS", "cmd": "regen_configured_floors"},
		{"label": "CLOSE PANEL [ESC]", "cmd": "close"},
	]

	for i in range(buttons.size()):
		var btn_data: Dictionary = buttons[i]
		var col := i % 2
		var row := i / 2
		var bx := col * col_width + 8
		var by := y_offset + row * (btn_height + btn_gap)

		var btn := Button.new()
		btn.text = btn_data["label"]
		btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		btn.offset_left = bx; btn.offset_top = by
		btn.offset_right = bx + col_width - 8
		btn.offset_bottom = by + btn_height
		btn.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
		btn.add_theme_color_override("font_color_hover", Color(1.0, 1.0, 0.60))
		btn.add_theme_color_override("bg_color", Color(0.12, 0.14, 0.22))
		btn.add_theme_color_override("bg_color_pressed", Color(0.18, 0.22, 0.38))
		btn.add_theme_color_override("border_color", Color(0.30, 0.40, 0.60))
		btn.add_theme_font_size_override("font_size", 9)
		btn.pressed.connect(_on_dev_button.bind(btn_data["cmd"]))
		add_child(btn)

	# Status bar at bottom
	var status_bar := ColorRect.new()
	status_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	status_bar.offset_left = 0; status_bar.offset_top = -24
	status_bar.offset_right = 340; status_bar.offset_bottom = 0
	status_bar.color = Color(0.08, 0.08, 0.15, 1.0)
	add_child(status_bar)

	var status_lbl := Label.new()
	status_lbl.name = "StatusLbl"
	status_lbl.text = "DEV MODE ACTIVE"
	status_lbl.set_anchors_preset(Control.PRESET_CENTER)
	status_lbl.anchor_left = 0.5; status_lbl.anchor_right = 0.5
	status_lbl.offset_left = -100; status_lbl.offset_top = -20
	status_lbl.offset_right = 100; status_lbl.offset_bottom = -4
	status_lbl.add_theme_color_override("font_color", Color(0.40, 0.90, 0.50))
	status_lbl.add_theme_font_size_override("font_size", 9)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_lbl)

func open() -> void:
	if not DEV_MODE:
		return
	visible = true
	_z_sort()
	_update_status("DEV MODE ACTIVE")

func close() -> void:
	visible = false

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func set_main(main_node: Node) -> void:
	_main = main_node

func _z_sort() -> void:
	z_index = 1000

func _on_dev_button(cmd: String) -> void:
	match cmd:
		"spawn_super":
			_spawn_super_actor()
		"god_mode":
			_toggle_god_mode()
		"infinite_money":
			_infinite_money()
		"fast_time":
			_fast_time()
		"spawn_customers":
			_spawn_customers()
		"spawn_staff":
			_spawn_staff()
		"all_achievements":
			_all_achievements()
		"max_stats":
			_max_stats()
		"trigger_delivery":
			_trigger_delivery()
		"low_stock_alert":
			_low_stock_alert()
		"kill_npcs":
			_kill_npcs()
		"regen_floor_0":
			_regen_floor(0)
		"regen_floor_1":
			_regen_floor(1)
		"regen_floor_2":
			_regen_floor(2)
		"regen_configured_floors":
			_regen_configured_floors()
		"close":
			close()

func _spawn_super_actor() -> void:
	if _main == null:
		_update_status("Error: main not set")
		return
	# Remove existing super actor
	if _super_actor != null and is_instance_valid(_super_actor):
		_super_actor.queue_free()
		_super_actor = null
		_update_status("Super actor removed")
		return
	# Spawn near player
	var player: Node = _main.get_node_or_null("_player")
	var spawn_pos := Vector2(200.0, 200.0)
	if player != null:
		spawn_pos = player.position + Vector2(60.0, 0.0)
	var sa := preload("res://scripts/super_actor.gd").new()
	sa.position = spawn_pos
	sa.name = "SuperActor"
	_main.add_child(sa)
	_super_actor = sa
	_update_status("Super actor spawned!")
	dev_commandIssued.emit("spawn_super", {"pos": spawn_pos})

func _toggle_god_mode() -> void:
	if _main == null:
		return
	var player: Node = _main.get_node_or_null("_player")
	if player != null and player.has_method("set_god_mode"):
		var current: bool = player.get("god_mode") if "god_mode" in player else false
		player.set("god_mode", not current)
		_update_status("God mode: ON" if not current else "God mode: OFF")

func _infinite_money() -> void:
	if _main == null:
		return
	var stats = _main.get_node_or_null("_player_stats")
	if stats != null and stats.has_method("set_cash"):
		stats.set("cash", 999999.0)
	_update_status("Cash set to $999,999")

func _fast_time() -> void:
	if _main == null:
		return
	var clock = _main.get_node_or_null("_game_clock")
	if clock != null and clock.has_method("set_time_scale"):
		var current: float = clock.get("time_scale") if "time_scale" in clock else 1.0
		clock.set("time_scale", 5.0 if current < 5.0 else 1.0)
		_update_status("Time scale: %.1fx" % (5.0 if current < 5.0 else 1.0))

func _spawn_customers() -> void:
	if _main == null:
		return
	# Trigger the NPC spawn to add 5 more customers
	dev_commandIssued.emit("spawn_customers", {"count": 5})
	_update_status("Spawning 5 customers...")

func _spawn_staff() -> void:
	if _main == null:
		return
	dev_commandIssued.emit("spawn_staff", {"count": 3})
	_update_status("Spawning 3 staff...")

func _all_achievements() -> void:
	if _main == null:
		return
	var stats = _main.get_node_or_null("_player_stats")
	if stats != null and stats.has_method("unlock_all"):
		stats.unlock_all()
	_update_status("All achievements unlocked!")

func _max_stats() -> void:
	if _main == null:
		return
	var stats = _main.get_node_or_null("_player_stats")
	if stats != null:
		if stats.has_method("set_xp"):
			stats.set("xp", 999999)
		if stats.has_method("set_level"):
			stats.set("level", 50)
	_update_status("Stats maxed!")

func _trigger_delivery() -> void:
	if _main == null:
		return
	var wh = _main.get_node_or_null("_warehouse")
	if wh != null and wh.has_method("trigger_delivery"):
		wh.trigger_delivery()
	_update_status("Delivery triggered!")

func _low_stock_alert() -> void:
	if _main == null:
		return
	var wh = _main.get_node_or_null("_warehouse")
	if wh != null and wh.has_method("simulate_low_stock"):
		wh.simulate_low_stock()
	_update_status("Low stock alerts triggered!")

func _kill_npcs() -> void:
	if _main == null:
		return
	dev_commandIssued.emit("kill_npcs", {})
	_update_status("All NPCs removed")

func _update_status(msg: String) -> void:
	var lbl := get_node_or_null("StatusLbl")
	if lbl != null:
		lbl.text = msg

func _regen_floor(floor_idx: int) -> void:
	if _main == null:
		_update_status("Error: main not set")
		return
	var floor_manager = _main.get_node_or_null("_floor_manager")
	if floor_manager == null:
		_update_status("Error: floor_manager not found")
		return
	floor_manager.clear_floor_entities(floor_idx)
	floor_manager.regenerate_floor_npcs(floor_idx)
	floor_manager.regenerate_floor_robots(floor_idx)
	_update_status("Regenerated floor %d" % floor_idx)

func _regen_configured_floors() -> void:
	if _main == null:
		_update_status("Error: main not set")
		return
	if _debug_config == null:
		_update_status("Error: debug_config not loaded")
		return
	var floor_manager = _main.get_node_or_null("_floor_manager")
	if floor_manager == null:
		_update_status("Error: floor_manager not found")
		return
	var floors: Array = _debug_config.get_regenerate_floors()
	var floor_list := ""
	for i in range(floors.size()):
		var floor_idx: int = floors[i]
		floor_manager.clear_floor_entities(floor_idx)
		floor_manager.regenerate_floor_npcs(floor_idx)
		floor_manager.regenerate_floor_robots(floor_idx)
		floor_list += "%d" % floor_idx
		if i < floors.size() - 1:
			floor_list += ", "
	_update_status("Regenerated floors: %s" % floor_list)
