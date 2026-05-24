# Task Status — 2026-05-24

## Completed Tasks

### 1. Settings Panel i18n (Chinese + English)
- **File**: `scripts/ui/settings_panel.gd`
- **Status**: ✅ COMPLETE
- **Changes**:
  - Added inline `_i18n` translation table with all UI strings in `en` and `zh`
  - Added `_t(key)` helper (renamed from `tr()` to avoid `Object.tr()` override conflict)
  - Added `"language"` row with type `"lang"` — press `E` to toggle EN/中文
  - All option labels, controls descriptions, titles, and hints now localized
  - Toggle values show `开/关` in Chinese, `ON/OFF` in English
  - Language preference persisted in `_settings["language"]`

### 2. PanelManager System
- **Files**: New `scripts/managers/panel_manager.gd` + wired into `main.gd`, `main_init.gd`, `project.godot`
- **Status**: ✅ COMPLETE
- **Changes**:
  - Created `PanelManager` autoload singleton
  - Policies: `ALONE` (exclusive — closes others when opened), `DUPLICATE` (concurrent)
  - `register(panel_id, panel_node, policy)`: registers panel + auto-connects `input_blocked` signal
  - `toggle(panel_id)`: opens if closed, closes if open; ALONE panels auto-close other ALONE panels
  - `is_input_blocked()`: returns `_blocking_count > 0`
  - `close_all_panels()`, `close_all_alone_panels()`, `get_panel()`, `get_policy()`
  - All 13 panels registered: `chat`, `maintenance`, `stats`, `settings`, `pause`, `quest_journal`, `stats_dashboard`, `dev_tools`, `shelf`, `map`, `floor`, `robot`
  - `main.gd.is_input_blocked()` now delegates to `PanelManager.is_input_blocked()`
  - Removed manual `_input_blocking_panels` counter and per-panel `input_blocked.connect()` handlers
  - Direct key handlers: M→map, V→floor, O→settings, J→quest_journal, K→stats_dashboard, F3→dev_tools, P/Space→pause (with guards)
  - Chat panel: `PanelManager.close_all_alone_panels()` called before `_chat_panel.open()` to enforce ALONE policy

### 3. All Floor Configs (Floor 0–14)
- **Files**: `scripts/areas/floor_N/floor_N_config.gd` for N in 0..14
- **Status**: ✅ COMPLETE
- **Changes** (per floor):
  - Added `tile_to_pixel(tx, ty)` / `pixel_to_tile(px, py)` helpers
  - Added `EntitySpawnDef` with `entity_type`, `role`, `area`, `x/y` (TILE coords), `patrol_points` (WORLD PIXEL coords)
  - Added `AreaDef` with `world_bounds` in tiles, `spawns` array, `get_center()`, `contains_point()`
  - Added `Facility` and `Place` classes for POI definitions
  - Added per-area NPC + robot spawns with patrol routes
  - Added full public API: `get_area()`, `get_spawns_by_area()`, `get_npc_staff_spawns()`, `get_robot_spawns()`, `get_places()`, `get_facilities()`, `get_floor_N_summary()`, `get_debug_info()`
- **Floor breakdown**:
  - Floor 0 (Lobby): 7 NPC + 2 robots — GREETER, CUSTOMER_SERVICE, LOYALTY_KIOSK, INFO_DESK, PROMO_BOOTH, LOST_FOUND, STORE_NEWS, GREETER_BOT, GUIDANCE_ROBOT
  - Floor 1 (Shoes): 6 NPC + 3 robots — SHELF_STOCKER, CUSTOMER_SERVICE, FITNESS_ADVISOR, GUIDANCE_ROBOT, CLEANING_ROBOT, SECURITY_ROBOT
  - Floor 2 (Fashion): 8 NPC + 3 robots — SHELF_STOCKER, STYLIST, FITNESS_ADVISOR, GUIDANCE_ROBOT, CLEANING_ROBOT, SECURITY_ROBOT
  - Floor 3 (Sports): 7 NPC + 3 robots — FITNESS_ADVISOR, SHELF_STOCKER, GUIDANCE_ROBOT, CLEANING_ROBOT, SECURITY_ROBOT
  - Floor 4 (Outdoor): 7 NPC + 3 robots — EXPERT, FITNESS_ADVISOR, SHELF_STOCKER, GUIDANCE_ROBOT, CLEANING_ROBOT, SECURITY_ROBOT
  - Floor 5 (Stationery+Plants): 6 NPC + 3 robots — SHELF_STOCKER, CUSTOMER_SERVICE, FLORIST, GUIDANCE_ROBOT, CLEANING_ROBOT, SECURITY_ROBOT
  - Floor 6 (Staff: Locker/Lounge/Training): 5 NPC + 2 robots — LOCKER_ATTENDANT, LOUNGE_STAFF, TRAINER, TRAINING_COORDINATOR, SECURITY_ROBOT, BREAK_ROBOT
  - Floor 7 (Back Office): 7 NPC + 2 robots — ADMIN_STAFF, HR_STAFF, RECRUITER, OFFICE_WORKER, OFFICE_ROBOT, SECURITY_MONITOR, SECURITY
  - Floor 8 (Exec/Arcade): 5 NPC + 2 robots — PLAY_ATTENDANT, ENTERTAINMENT_STAFF, CLAW_ATTENDANT, CLEANING_ROBOT, MAINTENANCE_ROBOT, SECURITY_ROBOT
  - Floor 9 (Staff Room Rooftop): 5 NPC + 2 robots — OPERATOR, OFFICE_ROBOT, STAFF_MEMBER, BREAK_ROBOT, OPERATIONS_STAFF, SHIFT_SUPERVISOR, SECURITY_ROBOT
  - Floor 10 (Rooftop Cafe): 4 NPC + 1 robot — CAFE_BARISTA, WAITER, CLEANING_ROBOT
  - Floor 11 (Warehouse): 5 NPC + 3 robots — DOCK_WORKER, DELIVERY_ROBOT, FORKLIFT_OPERATOR, CONVEYOR_OPERATOR, MAINTENANCE_ROBOT, PACKING_STAFF, PACKING_ROBOT, SECURITY_ROBOT
  - Floor 12 (Juice Bar): 6 NPC + 2 robots — JUICE_BARTENDER, CLEANING_ROBOT, NUTRITIONIST, SHELF_STOCKER, SMOOTHIE_MAKER, SALAD_CHEF, SECURITY_ROBOT
  - Floor 13 (Kids Kingdom): 5 NPC + 2 robots — PLAY_ATTENDANT, ENTERTAINMENT_STAFF, CLEANING_ROBOT, KIDS_CLUB_HOST, ENTERTAINMENT_ROBOT, SECURITY_ROBOT
  - Floor 14 (Electronics Rooftop): 7 NPC + 3 robots — SALES_STAFF, GUIDANCE_ROBOT, TECH_ADVISOR, DEMO_SPECIALIST, SHELF_STOCKER, REPAIR_TECHNICIAN, MAINTENANCE_ROBOT, CLEANING_ROBOT, SECURITY_ROBOT
- **Note**: Floor 8 zone data (JSON theme="arcade", zones: kids_play + claw_machine) differs from handler filename `exec_office_handler.gd` — used actual JSON zone data. Floor 9 has no stairs (elevator only). Floor 7 monitoring room zone (JSON) is wired to floor_8_handler in code (zone mismatch).

### 4. Floor 0 Config — Spawn Coordinate System Fix
- **File**: `scripts/areas/floor_0/floor_0_config.gd`
- **Status**: ✅ COMPLETE
- **Changes**:
  - Added `tile_to_pixel(tx, ty)` and `pixel_to_tile(px, py)` static helpers
  - `tile_to_world()` now delegates to `tile_to_pixel()` for consistency
  - Clarified `EntitySpawnDef.x/y` comments: TILE coords (→ world px via `tile_to_world`)
  - Clarified `patrol_points` comments: WORLD PIXEL coords (not tiles)
  - All patrol_points updated to use consistent pixel coordinates near spawn positions
  - Lobby: expanded to 7 NPC + 2 robots (added INFO_DESK, PROMO_BOOTH, LOST_FOUND, STORE_NEWS, GREETER_BOT)
  - Food Court: expanded to 3 NPC + 1 robot (added CLEANER role)
  - Warehouse: expanded to 3 NPC + 3 robots (added SECURITY humanoid)
  - Debug output now shows both tile and world pixel coordinates
  - `get_center()` syntax error already fixed in prior session (Vector2(cx, cy))

### 5. FloorPanel Missing `input_blocked` Signal
- **File**: `scripts/ui/floor_panel.gd`
- **Issue**: FloorPanel did NOT emit `input_blocked` signal when opened/closed
- **Impact**: When FloorPanel is open, player could still move and interact — input was not blocked
- **Fix**: ✅ ADDED — added `input_blocked(bool)` signal and emit in `show_panel()`/`hide_panel()`
- **Priority**: ✅ FIXED

---

## Incomplete / Known Issues

### 6. Duplicate Keys — W/S/A/D/E/KEY_*
- **Issue**: These keys are used by BOTH game-world handlers AND panel overlays
- **Impact**: When a non-blocking panel is open (e.g., floor panel without `input_blocked`), W/S/A/D navigate the player instead of panel
- **Root cause**: Panels that don't emit `input_blocked` don't block game-world input
- **Fix**: Ensure all registered panels emit `input_blocked` properly

### 7. Context Panels — No Global Key (Correct Behavior)
- **Panels**: ATMPanel, MonitorPanel, SectionBrowse, DailyBonus, ShelfPanel, StatsPanel
- **Status**: ✅ INTENTIONAL — these are opened via proximity/E-key context, not global toggle
- **Note**: ATMPanel, MonitorPanel, ShelfPanel don't emit `input_blocked` — player can move while open (contextually appropriate)
- **Orphaned**: `StatsPanel` (`_toggle_stats_panel()`) is dead code — no longer connected to any key
- **Fix**: No fix needed for context panels. StatsPanel should be removed or wired to a key.

---

## Keyboard Config — Missing Keys
The following documented keys in the README are NOT handled in code:
- `?` — Tutorial (mentioned in README, not implemented)
- `1–9` — Quick-add product by number (in section view — partially implemented in `section_browse`)
- `N` — Toggle mini-map (commented out in main.gd)
