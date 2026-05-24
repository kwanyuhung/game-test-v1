# panel_manager.gd
# Centralized panel management — registers all UI panels, enforces duplicate
# policies, and aggregates the input-blocking counter.
# ═══════════════════════════════════════════════════════════════════════
# POLICIES
#   ALONE    — when opened, all other ALONE panels are closed first
#   DUPLICATE — multiple instances of this panel type are allowed
# ═══════════════════════════════════════════════════════════════════════
# USAGE
#   1. Register panels after instantiation:
#        PanelManager.register("settings", _settings_panel, PanelManager.Policy.ALONE)
#   2. Call toggle from your input handler:
#        PanelManager.toggle("settings")
#   3. Replace _is_input_blocked() body with:
#        PanelManager.is_input_blocked()
#   4. Panels must emit input_blocked(bool) from their open()/close()
#      so the manager can maintain the blocking counter automatically.
# ═══════════════════════════════════════════════════════════════════════
extends Node

enum Policy {
	ALONE,     # exclusive — closes all other ALONE panels when opened
	DUPLICATE, # concurrent — multiple of this kind allowed
}

signal input_blocked(blocking: bool)  # aggregated for listeners

var _registry: Dictionary = {}   # panel_id -> {node: Node, policy: Policy, is_open: bool}
var _blocking_count: int = 0    # number of panels currently emitting input_blocked(true)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# ─── Registration ─────────────────────────────────────────────────

func register(panel_id: String, panel: Node, policy: Policy) -> void:
	_registry[panel_id] = {node = panel, policy = policy, is_open = false}
	if panel.has_signal("input_blocked"):
		panel.input_blocked.connect(_on_panel_input_blocked.bind(panel_id))

# ─── Public API ───────────────────────────────────────────────────

func toggle(panel_id: String) -> void:
	if not _registry.has(panel_id):
		return
	var info: Dictionary = _registry[panel_id]
	var panel: Node = info.node

	if info.is_open:
		_close_panel(panel_id)
	else:
		_open_panel(panel_id)

func open(panel_id: String) -> void:
	if not _registry.has(panel_id):
		return
	if _registry[panel_id].is_open:
		return
	_open_panel(panel_id)

func close(panel_id: String) -> void:
	if not _registry.has(panel_id):
		return
	if not _registry[panel_id].is_open:
		return
	_close_panel(panel_id)

func is_panel_open(panel_id: String) -> bool:
	return _registry.get(panel_id, {}).get("is_open", false)

func is_input_blocked() -> bool:
	return _blocking_count > 0

func close_all_panels() -> void:
	for pid in _registry.keys():
		if _registry[pid].is_open:
			_close_panel(pid)

func close_all_alone_panels() -> void:
	for pid in _registry.keys():
		if _registry[pid].is_open and _registry[pid].policy == Policy.ALONE:
			_close_panel(pid)

func get_panel(panel_id: String) -> Node:
	return _registry.get(panel_id, {}).get("node", null)

func get_policy(panel_id: String) -> Policy:
	return _registry.get(panel_id, {}).get("policy", Policy.ALONE)

# ─── Internal ─────────────────────────────────────────────────────

func _open_panel(panel_id: String) -> void:
	var info: Dictionary = _registry[panel_id]
	var panel: Node = info.node

	# ALONE policy — close all other ALONE panels first
	if info.policy == Policy.ALONE:
		for other_id in _registry.keys():
			if other_id != panel_id and _registry[other_id]["policy"] == Policy.ALONE and _registry[other_id]["is_open"]:
				_close_panel(other_id, true)

	info.is_open = true

	# Call the panel's public open method
	if panel.has_method("toggle"):
		panel.toggle()
	elif panel.has_method("open"):
		panel.open()
	elif panel.has_method("show_panel"):
		panel.show_panel()

func _close_panel(panel_id: String, skip_blocking_update: bool = false) -> void:
	var info: Dictionary = _registry[panel_id]
	var panel: Node = info.node

	info.is_open = false

	if panel.has_method("toggle"):
		panel.toggle()
	elif panel.has_method("close"):
		panel.close()
	elif panel.has_method("hide_panel"):
		panel.hide_panel()
	elif panel.has_method("hide"):
		panel.hide()

func _on_panel_input_blocked(blocking: bool, panel_id: String) -> void:
	if blocking:
		_blocking_count += 1
	else:
		_blocking_count = maxi(0, _blocking_count - 1)
	input_blocked.emit(_blocking_count > 0)
