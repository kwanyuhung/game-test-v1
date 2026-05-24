# Panel Keyboard Configuration
# Maps keys to panels, defines policies, and documents duplicate status.
# ═══════════════════════════════════════════════════════════════════════════════
#
# HOW IT WORKS
# Each key can be registered with a panel via PanelManager.
# When the key is pressed (in main.gd _input), PanelManager.toggle(key) is called.
# PanelManager checks the panel's policy:
#   ALONE   — only one of this panel can be open. Closes other ALONE panels first.
#   DUPLICATE — multiple instances allowed (e.g., floating text, toasts).
#
# DUPLICATE KEY CONFLICTS (keys used by multiple panels/contexts):
# These keys are used in BOTH game-world and panel overlays.
# If a panel does NOT emit input_blocked, game-world input fires too.
#   W/S/A/D — movement (game) vs panel navigation (settings, quest, etc.)
#   E        — interact/confirm across many contexts
#   Q        — game action (nearby NPC) vs panel action
#   H        — game action (hire staff) vs panel action
#   F        — catch thief (game) vs panel navigation
#   SPACE    — pause (global) vs panel confirm
# ═══════════════════════════════════════════════════════════════════════════════

{
  "_comment": "Keys registered with PanelManager — handled via PanelManager.toggle()",

  "registered": {
    "settings":  {"key": "O",       "policy": "ALONE",    "panel": "SettingsPanel",    "desc": "Settings panel"},
    "pause":    {"key": "P/Space", "policy": "ALONE",    "panel": "PauseMenu",         "desc": "Pause/resume game"},
    "map":      {"key": "M",       "policy": "ALONE",    "panel": "MapPanel",          "desc": "Full floor map"},
    "floor":    {"key": "V",       "policy": "ALONE",    "panel": "FloorPanel",        "desc": "Clickable floor selector"},
    "quest_journal": {"key": "J",   "policy": "ALONE",    "panel": "QuestJournal",      "desc": "Quest journal"},
    "stats_dashboard": {"key": "K",  "policy": "ALONE",    "panel": "StatsDashboard",    "desc": "Player stats dashboard"},
    "dev_tools": {"key": "F3",      "policy": "ALONE",    "panel": "DevTools",          "desc": "Developer tools (DEV_MODE)"},
    "chat":     {"key": "C",        "policy": "ALONE",    "panel": "ChatPanel",         "desc": "NPC chat"},
    "robot":    {"key": "R",        "policy": "ALONE",    "panel": "RobotPanelSystem",  "desc": "Robot management panel"}
  },

  "_comment_registered_but_no_global_key": "Panels below are registered with PanelManager but have no dedicated global key. They are opened via proximity/E-key contextually.",
  "proximity_only": {
    "maintenance": {"panel": "MaintenancePanel", "opens": "via E key near maintenance issue"},
    "shelf":       {"panel": "ShelfPanel",       "opens": "via E key near shelf"},
    "stats":        {"panel": "StatsPanel",        "opens": "via E key near stats terminal"}
  },

  "_comment2": "Keys handled via direct function calls (not PanelManager.toggle())",

  "direct_handlers": {
    "KEY_B":      {"handler": "_toggle_brand_portal / _toggle_business_mode", "note": "B=brand portal, Shift+B=business mode", "shift_aware": true},
    "KEY_F":      {"handler": "_attempt_catch_thief / (panel)", "note": "Catch thief when suspicious NPC nearby; F also used in section_browse for decrease qty"},
    "KEY_R":      {"handler": "_restock_nearby_section / _toggle_robot_panel", "note": "R=restock (staff mode), else robot panel"},
    "KEY_X":      {"handler": "_renovate_nearby_section", "note": "Renovate section (staff mode)"},
    "KEY_T":      {"handler": "_toggle_floor_jump_panel", "note": "Teleport/floor jump"},
    "KEY_L":      {"handler": "_toggle_shopping_list", "note": "Shopping list (not a PanelManager panel)"},
    "KEY_C":      {"handler": "_open_npc_chat", "note": "Opens ChatPanel via PanelManager.close_all_alone_panels + open"},
    "KEY_0-9":   {"handler": "_temp_order_mode / numbered_bubble_interactions", "note": "Quick order in food court / bubble interactions"}
  },

  "_comment3": "Keys defined in project.godot input actions (not keycode-based)",

  "action_bindings": {
    "move_up":    {"keys": "W, ArrowUp",   "desc": "Move player up"},
    "move_down":  {"keys": "S, ArrowDown", "desc": "Move player down"},
    "move_left":  {"keys": "A, ArrowLeft", "desc": "Move player left"},
    "move_right": {"keys": "D, ArrowRight","desc": "Move player right"},
    "interact":   {"keys": "E",            "desc": "Interact with nearby object / confirm"},
    "toggle_cart":{"keys": "Tab",          "desc": "Toggle shopping cart"},
    "pause":      {"keys": "Escape",       "desc": "Pause game"}
  },

  "_comment4": "Keys used inside panels (panel-local, not global)",

  "panel_internal_keys": {
    "SettingsPanel":  {"nav": "W/S/A/D", "confirm": "Enter/Space", "close": "Escape/Tab"},
    "QuestJournal":    {"nav": "W/S/A/D", "close": "Escape/Tab/J"},
    "MapPanel":        {"nav": "W/S/A/D", "close": "Escape/Tab"},
    "FloorPanel":      {"click": "Mouse click on floor buttons", "close": "Escape/Tab"},
    "ChatPanel":       {"input": "Enter to send", "close": "Escape"},
    "PauseMenu":       {"confirm": "P/Space/Escape"},
    "MaintenancePanel": {"nav": "W/S", "confirm": "E/Enter", "close": "Escape"},
    "ShelfPanel":      {"nav": "W/S/A/D", "close": "Escape/E"},
    "StatsDashboard":   {"close": "Escape/Tab/K"},
    "BusinessMode":     {"nav": "W/S/A/D", "close": "Escape"},
    "SectionBrowse":    {"nav": "W/S/A/D", "confirm": "E", "close": "Escape", "qty": "Q/R", "page": "PageUp/PageDown", "num_keys": "1-9"},
    "FoodStallBrowse":  {"nav": "W/S", "confirm": "E/+/Plus", "close": "Escape", "qty_keys": "1-5"},
    "PriceTerminal":    {"nav": "W/S/A/D", "confirm": "E", "close": "Escape", "qty": "Q/R", "num_keys": "1-9"},
    "MonitorPanel":     {"close": "Escape/E"},
    "BrandPortal":      {"nav": "W/S/A/D", "confirm": "E", "close": "Escape/B", "page": "PageUp/PageDown"},
    "Elevator":         {"confirm": "E", "close": "Escape"},
    "ATMPanel":         {"num_keys": "0-9", "confirm": "Enter", "close": "Escape", "backspace": "KEY_BACKSPACE"}
  },

  "_comment5": "Missing / unimplemented keys from README",

  "missing": {
    "?":         {"desc": "Show controls tutorial", "note": "Mentioned in README but not implemented in code"},
    "N":         {"desc": "Toggle mini-map", "note": "Code commented out in main.gd"},
    "1-9_in_section_view": {"desc": "Quick-add product by number in section view", "note": "Partially implemented in section_browse but not connected globally"}
  },

  "_comment7": "Proximity/context panels — opened via E key near object, NOT via global key. Registered with PanelManager? No (context-specific).",

  "context_panels": {
    "ATMPanel":     {"opens": "E key near ATM",         "has_input_blocked": false, "note": "NOT registered with PanelManager — no global key"},
    "MonitorPanel": {"opens": "E key near monitor",        "has_input_blocked": false, "note": "NOT registered with PanelManager — no global key"},
    "DailyBonus":  {"opens": "auto on game start",     "has_input_blocked": false, "note": "Auto-dismissed; NOT registered with PanelManager"},
    "ShelfPanel":   {"opens": "E key near shelf",         "has_input_blocked": false, "note": "NOT registered with PanelManager — no global key"},
    "SectionBrowse": {"opens": "E key near section",     "has_input_blocked": true,  "note": "Has internal WASD/E/Q/R/1-9/PageUp/PageDown keys"}
  }
}


  "_comment6": "DUPLICATE keys — used by multiple panels / contexts. These work correctly because panels with input_blocked emit block the game-world input.",

  "duplicate_keys": {
    "W":         {"used_by": ["main.gd (stairs up)", "settings_panel", "quest_journal", "section_browse", "food_stall_browse", "maintenance_panel", "brand_portal", "price_terminal"], "note": "Works if panel emits input_blocked"},
    "S":         {"used_by": ["main.gd (stairs down)", "settings_panel", "quest_journal", "section_browse", "food_stall_browse", "maintenance_panel", "brand_portal", "price_terminal"], "note": "Works if panel emits input_blocked"},
    "A":         {"used_by": ["section_browse", "price_terminal", "brand_portal"], "note": "Left navigation in browse contexts"},
    "D":         {"used_by": ["section_browse", "price_terminal", "brand_portal"], "note": "Right navigation in browse contexts"},
    "E":         {"used_by": ["interact action (game)", "section_browse confirm", "food_stall_browse confirm", "price_terminal confirm", "elevator confirm", "brand_portal confirm", "monitor_panel close", "shelf_panel close"], "note": "HIGH CONFLICT — used everywhere. Works because panel overlay intercepts input when visible."},
    "Q":         {"used_by": ["section_browse (qty decrease)", "price_terminal (qty decrease)", "main.gd game action near NPC"], "note": "Q is also a game action near NPC"},
    "R":         {"used_by": ["section_browse (qty increase)", "price_terminal (qty increase)", "main.gd robot panel / restock toggle"], "note": "R is restock (staff mode) or robot panel"},
    "H":         {"used_by": ["main.gd (hire staff, staff mode)"], "note": "No panel conflict currently"},
    "F":         {"used_by": ["main.gd (catch thief)", "section_browse navigation"], "note": "Catch thief takes priority; section_browse gets F when browse is open"},
    "SPACE":     {"used_by": ["pause toggle", "settings_panel confirm", "quest_journal confirm"], "note": "Pause is global; panel confirm works when panel is open"},
    "PAGEUP":    {"used_by": ["section_browse", "price_terminal", "brand_portal"], "note": "Page navigation in browse contexts"},
    "PAGEDOWN":  {"used_by": ["section_browse", "price_terminal", "brand_portal"], "note": "Page navigation in browse contexts"},
    "KEY_B":     {"used_by": ["brand_portal (no shift)", "business_mode (shift)"], "note": "Handled via shift check in main.gd"},
    "ESCAPE":    {"used_by": ["close all panels", "pause", "section_browse", "food_stall_browse", "price_terminal", "brand_portal", "elevator", "atm_panel"], "note": "Universal close — always routes to closest active panel"}
  }
}
