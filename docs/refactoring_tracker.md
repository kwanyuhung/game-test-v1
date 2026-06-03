# Refactoring Tracker — `main.gd` → Sub-Managers

> **Status:** In progress (Phase 2-6: Code duplication)
> **Final cleanup:** Phase 7 (delete duplicated code from main.gd)

---

## Phase 2 — `WorldManager`

**File:** `scripts/core/main_manager/world_manager.gd`
**Goal:** Duplicate floor/section/checkout/build logic from main.gd into WorldManager

### Functions moved (duplicated, NOT deleted from main.gd yet)

| Original Location | Function | Description | Status |
|-------------------|----------|-------------|--------|
| `main.gd` | `_build_floor(idx)` | Builds floor content into container | duplicated in WorldManager ✓ |
| `main.gd` | `_clear_floor_nodes()` | Clears old floor content, NPCs, robots | duplicated in WorldManager ✓ |
| `main.gd` | `_build_sections_for_current_floor()` | Delegates to MainPanels | duplicated in WorldManager ✓ |
| `main.gd` | `_build_checkout_for_current_floor()` | Delegates to MainPanels | duplicated in WorldManager ✓ |
| `main.gd` | `_rebuild_floor(idx)` | Rebuilds floor with FloorManager check | duplicated in WorldManager ✓ |
| `main.gd` | `_rebuild_floor_with_manager(idx)` | Updates local refs from FloorManager container | duplicated in WorldManager ✓ |
| `main.gd` | `get_floor_info()` | Returns floor metadata dict | duplicated in WorldManager ✓ |
| `main.gd` | `_apply_ambient_shift()` | Applies floor ambient color to world bg | duplicated in WorldManager ✓ |
| `main.gd` | `set_ambient_floor(idx)` | Sets ambient and updates HUD | duplicated in WorldManager ✓ |
| `main.gd` | `_update_floor_hud()` | Delegates to MainPanels | duplicated in WorldManager ✓ |
| `main.gd` | `_get_floor_zone_bounds(floor_idx)` | Returns {min_y, max_y, height} for camera limits | duplicated in WorldManager ✓ |

### Variables moved (duplicated, NOT deleted from main.gd yet)

| Variable | Type | Description | Status |
|----------|------|-------------|--------|
| `_floor_builder` | `FloorBuilder` | Floor rendering engine | duplicated in WorldManager ✓ |
| `_food_stall_browse` | `FoodStallBrowse` | Food stall UI | duplicated in WorldManager ✓ |
| `_sections` | `Array` | Current floor sections | duplicated in WorldManager ✓ |
| `_checkout_counters` | `Array` | Current floor checkout counters | duplicated in WorldManager ✓ |
| `_floor_nodes` | `Array` | Built floor node references | duplicated in WorldManager ✓ |
| `_floor_ambient` | `Color` | Current floor ambient color | duplicated in WorldManager ✓ |
| `_current_floor_idx` | `int` | Active floor index | duplicated in WorldManager ✓ |
| `_aisle_labels` | `Array` | Aisle label nodes | duplicated in WorldManager ✓ |
| `_world_bg` | `ColorRect` | World background color rect | duplicated in WorldManager ✓ |
| `_in_elevator` | `bool` | Elevator travel state | duplicated in WorldManager ✓ |
| `_nearby_section` | `Node` | Player's nearby section | duplicated in WorldManager ✓ |
| `_nearby_checkout` | `Node` | Player's nearby checkout counter | duplicated in WorldManager ✓ |
| `_nearby_stall` | `Node` | Player's nearby food stall | duplicated in WorldManager ✓ |
| `_floor_manager` | `Node` | FloorManager reference | duplicated in WorldManager ✓ |
| `_stairs_system` | `Node` | Stairs system reference | duplicated in WorldManager ✓ |
| `_proximity_system` | `Node` | Proximity system reference | duplicated in WorldManager ✓ |
| `_checkout_system` | `Node` | Checkout system reference | duplicated in WorldManager ✓ |
| `_food_court_system` | `Node` | Food court system reference | duplicated in WorldManager ✓ |
| `_truck_dock_system` | `Node` | Truck dock system reference | duplicated in WorldManager ✓ |
| `_warehouse_floor` | `Node2D` | Warehouse floor controller | duplicated in WorldManager ✓ |
| `_nearby_elevator` | `bool` | Is player near elevator | duplicated in WorldManager ✓ |
| `_nearby_parking` | `bool` | Is player near parking | duplicated in WorldManager ✓ |
| `_nearby_warehouse` | `bool` | Is player near warehouse | duplicated in WorldManager ✓ |
| `_nearby_warehouse_dock` | `bool` | Is player near receiving dock | duplicated in WorldManager ✓ |
| `_nearby_terminal` | `bool` | Is player near price terminal | duplicated in WorldManager ✓ |
| `_nearby_loyalty` | `bool` | Is player near loyalty kiosk | duplicated in WorldManager ✓ |
| `_nearby_gift_wrap` | `bool` | Is player near gift wrap | duplicated in WorldManager ✓ |
| `_nearby_digital_kiosk` | `bool` | Is player near digital kiosk | duplicated in WorldManager ✓ |
| `_nearby_info_desk` | `bool` | Is player near info desk | duplicated in WorldManager ✓ |
| `_nearby_cafe` | `bool` | Is player near cafe | duplicated in WorldManager ✓ |
| `_nearby_promo_booth` | `bool` | Is player near promo booth | duplicated in WorldManager ✓ |
| `_nearby_lost_found` | `bool` | Is player near lost & found | duplicated in WorldManager ✓ |
| `_nearby_store_news` | `bool` | Is player near store news | duplicated in WorldManager ✓ |
| `_nearby_vending` | `bool` | Is player near vending machine | duplicated in WorldManager ✓ |
| `_nearby_karaoke` | `bool` | Is player near karaoke | duplicated in WorldManager ✓ |
| `_nearby_pool_table` | `bool` | Is player near pool table | duplicated in WorldManager ✓ |
| `_nearby_darts_board` | `bool` | Is player near darts | duplicated in WorldManager ✓ |
| `_nearby_claw_machine` | `ClawMachine` | Player's nearby claw machine | duplicated in WorldManager ✓ |
| `_nearby_npc_for_chat` | `NPCController` | NPC available for chat | duplicated in WorldManager ✓ |
| `_nearby_issue` | `bool` | Is player near maintenance issue | duplicated in WorldManager ✓ |
| `_nearby_atm` | `bool` | Is player near ATM | duplicated in WorldManager ✓ |
| `_nearby_monitor` | `bool` | Is player near monitor | duplicated in WorldManager ✓ |
| `_staff_blocked_floor` | `int` | Floor blocked for non-staff | duplicated in WorldManager ✓ |
| `_warehouse_mode` | `bool` | Warehouse control mode active | duplicated in WorldManager ✓ |
| `_truck_arrived` | `bool` | Truck has arrived at dock | duplicated in WorldManager ✓ |
| `_temp_order_mode` | `String` | Temp order mode ("loyalty" etc.) | duplicated in WorldManager ✓ |
| `_temp_order_items` | `Array` | Temp order items | duplicated in WorldManager ✓ |
| `_cart_gift_wrapped` | `bool` | Cart has gift wrap applied | duplicated in WorldManager ✓ |
| `_checkout_receipt_visible` | `bool` | Checkout receipt panel showing | duplicated in WorldManager ✓ |
| `_nearby_gift_wrap` | `bool` | Near gift wrap station | duplicated in WorldManager ✓ |

### Signals re-emitted by WorldManager

| Signal | Payload | Subscribers |
|--------|---------|------------|
| `floor_changed(idx)` | `int` | UIManager, CharacterManager |
| `section_entered(section_id)` | `String` | main.gd → prompt label |
| `section_exited(section_id)` | `String` | main.gd |
| `floor_rebuilt(idx)` | `int` | UIManager |

---

## Phase 3 — `CharacterManager`

**File:** `scripts/core/main_manager/character_manager.gd`
**Goal:** Duplicate player/NPC/robot state and MainSpawner access into CharacterManager

### Functions moved (duplicated, NOT deleted from main.gd yet)

| Original Location | Function | Description | Status |
|-------------------|----------|-------------|--------|
| `main.gd` | `_spawn_player()` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_build_npcs()` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_npc_staff(role, floor_idx, pos)` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_customer(group_type, floor_idx, pos)` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_customer_group(...)` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_robots()` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_scan_go_companion()` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_remove_scan_go_companion()` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_test_customers(count)` | Dev: spawn test NPCs | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_test_staff(count)` | Dev: spawn test staff | duplicated in CharacterManager ✓ |
| `main.gd` | `_kill_all_test_npcs()` | Dev: despawn all NPCs | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_robot_humanoid(staff_role)` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_robot_single(robot_role)` | Delegates to MainSpawner | duplicated in CharacterManager ✓ |
| `main.gd` | `_spawn_truck_at_dock()` | Delegates to TruckDockSystem | duplicated in CharacterManager ✓ |

### Variables moved (duplicated, NOT deleted from main.gd yet)

| Variable | Type | Description | Status |
|----------|------|-------------|--------|
| `_player` | `Player` | Player instance | duplicated in CharacterManager ✓ |
| `_npcs` | `Array` | Active NPC instances | duplicated in CharacterManager ✓ |
| `_robots` | `Array` | Active robot instances | duplicated in CharacterManager ✓ |
| `_main_spawner` | `Node` | MainSpawner node | duplicated in CharacterManager ✓ |
| `_current_section_browse` | `SectionBrowse` | Active section browse panel | duplicated in CharacterManager ✓ |
| `_section_browse` | `SectionBrowse` | Section browse instance | duplicated in CharacterManager ✓ |

---

## Phase 4 — `SystemManager`

**File:** `scripts/core/main_manager/system_manager.gd`
**Goal:** Consolidate all *System nodes under one manager with typed getters

### Functions moved (duplicated, NOT deleted from main.gd yet)

| Original Location | Function | Description | Status |
|-------------------|----------|-------------|--------|
| `main.gd` | `_process(delta)` | Main game loop — calls systems update_all | duplicated in SystemManager ✓ |
| `main.gd` | `_open_npc_chat()` | Opens chat with nearby NPC | duplicated in SystemManager ✓ |
| `main.gd` | `_open_stall_browse(stall)` | Opens food stall browse | duplicated in SystemManager ✓ |
| `main.gd` | `_on_stall_interact_requested(stall_id)` | Signal handler for stall interaction | duplicated in SystemManager ✓ |
| `main.gd` | `_handle_warehouse_interact()` | Warehouse mode toggle | duplicated in SystemManager ✓ |
| `main.gd` | `_on_claw_interact_requested()` | Opens claw machine game | duplicated in SystemManager ✓ |
| `main.gd` | `_on_claw_played(prize, won, machine)` | Claw game result handler | duplicated in SystemManager ✓ |
| `main.gd` | `_on_checkout_interacted(id, type)` | Checkout interaction handler | duplicated in SystemManager ✓ |
| `main.gd` | `_on_self_checkout_cleared()` | Self-checkout error cleared | duplicated in SystemManager ✓ |
| `main.gd` | `_open_section_browse(section)` | Opens section browse panel | duplicated in SystemManager ✓ |
| `main.gd` | `_attempt_catch_thief()` | Anti-theft catch attempt | duplicated in SystemManager ✓ |
| `main.gd` | `_renovate_nearby_section()` | Renovation (staff only) | duplicated in SystemManager ✓ |
| `main.gd` | `_restock_nearby_section()` | Restock section (staff only) | duplicated in SystemManager ✓ |
| `main.gd` | `_on_player_interact()` | Central E-key interaction router | duplicated in SystemManager ✓ |
| `main.gd` | `_handle_facility_interact()` | Route to specific facility handler | duplicated in SystemManager ✓ |
| `main.gd` | `_handle_parking_interact()` | Parking lot interaction | duplicated in SystemManager ✓ |
| `main.gd` | `_handle_stairs_interaction()` | Stairs up/down | duplicated in SystemManager ✓ |
| `main.gd` | `_start_claw_machine(machine)` | Start claw game | duplicated in SystemManager ✓ |
| `main.gd` | `_open_atm_panel()` | Open ATM panel | duplicated in SystemManager ✓ |
| `main.gd` | `_open_monitor_panel()` | Open security monitor panel | duplicated in SystemManager ✓ |
| `main.gd` | `_open_price_terminal()` | Open price terminal | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_dev_tools()` | Toggle dev tools visibility | duplicated in SystemManager ✓ |
| `main.gd` | `_on_dev_command(cmd, args)` | Dev command dispatcher | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_maintenance_panel()` | Open maintenance panel | duplicated in SystemManager ✓ |
| `main.gd` | `_on_maintenance_panel_closed()` | Cleanup on panel close | duplicated in SystemManager ✓ |
| `main.gd` | `_on_maintenance_issue_selected(issue)` | Select maintenance issue | duplicated in SystemManager ✓ |
| `main.gd` | `_navigate_to_floor(floor_idx)` | Navigate player to floor | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_shopping_list()` | Toggle shopping list panel | duplicated in SystemManager ✓ |
| `main.gd` | `add_to_shopping_list(product_name)` | Add item to shopping list | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_stats_dashboard()` | Toggle stats dashboard | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_map_panel()` | Toggle map panel | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_floor_panel()` | Toggle floor selector panel | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_floor_jump_panel()` | Toggle floor jump panel | duplicated in SystemManager ✓ |
| `main.gd` | `_on_floor_jump_panel_input(event)` | Floor jump panel input | duplicated in SystemManager ✓ |
| `main.gd` | `_on_floor_jump_btn_input(event)` | Floor jump button click | duplicated in SystemManager ✓ |
| `main.gd` | `_close_floor_jump_panel()` | Close floor jump panel | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_brand_portal()` | Toggle brand portal | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_business_mode()` | Toggle business mode | duplicated in SystemManager ✓ |
| `main.gd` | `_build_business_mode()` | Create business mode panel | duplicated in SystemManager ✓ |
| `main.gd` | `close_business_mode()` | Close business mode | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_robot_panel()` | Toggle robot management panel | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_stats_panel()` | Toggle stats panel | duplicated in SystemManager ✓ |
| `main.gd` | `_on_stats_panel_closed()` | Cleanup on stats panel close | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_pause()` | Toggle pause menu | duplicated in SystemManager ✓ |
| `main.gd` | `_on_game_paused()` | Pause signal handler | duplicated in SystemManager ✓ |
| `main.gd` | `_on_game_resumed()` | Resume signal handler | duplicated in SystemManager ✓ |
| `main.gd` | `_show_tutorial_overlay()` | Show tutorial | duplicated in SystemManager ✓ |
| `main.gd` | `_on_tutorial_dismissed()` | Tutorial dismissed | duplicated in SystemManager ✓ |
| `main.gd` | `_on_setting_changed(key, value)` | Setting change dispatcher | duplicated in SystemManager ✓ |
| `main.gd` | `_apply_factory_robot_settings()` | Apply robot visibility settings | duplicated in SystemManager ✓ |
| `main.gd` | `_apply_interactive_settings(enabled)` | Apply interactive bubble settings | duplicated in SystemManager ✓ |
| `main.gd` | `_on_cart_updated(items, subtotal)` | Cart update handler | duplicated in SystemManager ✓ |
| `main.gd` | `_on_warehouse_delivery_arrived(contents)` | Delivery arrived signal | duplicated in SystemManager ✓ |
| `main.gd` | `_on_warehouse_low_stock(section_id)` | Low stock warning | duplicated in SystemManager ✓ |
| `main.gd` | `_on_atm_panel_closed()` | ATM panel cleanup | duplicated in SystemManager ✓ |
| `main.gd` | `_on_monitor_panel_closed()` | Monitor panel cleanup | duplicated in SystemManager ✓ |
| `main.gd` | `_on_atm_withdraw_success(amount)` | ATM withdrawal success | duplicated in SystemManager ✓ |
| `main.gd` | `is_input_blocked()` | Check if input is blocked | duplicated in SystemManager ✓ |
| `main.gd` | `_toggle_shelf_panel()` | Warehouse shelf panel toggle | duplicated in SystemManager ✓ |

### Variables moved (duplicated, NOT deleted from main.gd yet)

| Variable | Type | Description | Status |
|----------|------|-------------|--------|
| `_proximity_system` | `Node` | Proximity detection system | duplicated in SystemManager ✓ |
| `_checkout_system` | `Node` | Checkout processing system | duplicated in SystemManager ✓ |
| `_food_court_system` | `Node` | Food court system | duplicated in SystemManager ✓ |
| `_truck_dock_system` | `Node` | Truck dock system | duplicated in SystemManager ✓ |
| `_stairs_system` | `Node` | Stairs/floor navigation | duplicated in SystemManager ✓ |
| `_maintenance_system` | `MaintenanceSystem` | Maintenance issue tracker | duplicated in SystemManager ✓ |
| `_maintenance_visual` | `MaintenanceVisual` | Visual overlay for issues | duplicated in SystemManager ✓ |
| `_maintenance_panel` | `MaintenancePanel` | Maintenance UI panel | duplicated in SystemManager ✓ |
| `_target_issue` | `Object` | Selected issue for resolution | duplicated in SystemManager ✓ |
| `_warehouse` | `WarehouseSystem` | Warehouse stock management | duplicated in SystemManager ✓ |
| `_anti_theft` | `AntiTheft` | Anti-theft system | duplicated in SystemManager ✓ |
| `_store_expansion` | `StoreExpansion` | Store renovation/expansion | duplicated in SystemManager ✓ |
| `_dynamic_pricing` | `DynamicPricing` | Dynamic pricing engine | duplicated in SystemManager ✓ |
| `_supplier_manager` | `SupplierManager` | Supplier management | duplicated in SystemManager ✓ |
| `_promo_manager` | `Node` | Promotion manager | duplicated in SystemManager ✓ |
| `_elevator` | `Elevator` | Elevator controller | duplicated in SystemManager ✓ |
| `_robots` | `Array` | Robot instances | duplicated in SystemManager ✓ |
| `_robot_panel_system` | `Node` | Robot management panel | duplicated in SystemManager ✓ |
| `_robot_panel` | `Control` | Robot panel UI | duplicated in SystemManager ✓ |
| `_price_terminal` | `PriceTerminal` | Price check terminal | duplicated in SystemManager ✓ |
| `_business_mode` | `BusinessMode` | Business mode panel | duplicated in SystemManager ✓ |
| `_brand_portal` | `BrandPortal` | Brand portal panel | duplicated in SystemManager ✓ |
| `_brand_manager` | `BrandManager` | Brand management | duplicated in SystemManager ✓ |
| `_player_stats` | `PlayerStats` | Player stats/cash/XP | duplicated in SystemManager ✓ |
| `_stats_panel` | `StatsPanel` | Stats panel | duplicated in SystemManager ✓ |
| `_atm_panel` | `ATMPanel` | ATM panel | duplicated in SystemManager ✓ |
| `_monitor_panel` | `MonitorPanel` | Monitor panel | duplicated in SystemManager ✓ |
| `_settings_panel` | `SettingsPanel` | Settings panel | duplicated in SystemManager ✓ |
| `_pause_menu` | `PauseMenu` | Pause menu | duplicated in SystemManager ✓ |
| `_stats_dashboard` | `StatsDashboard` | Stats dashboard | duplicated in SystemManager ✓ |
| `_map_panel` | `MapPanel` | Map panel | duplicated in SystemManager ✓ |
| `_floor_panel` | `FloorPanel` | Floor selector panel | duplicated in SystemManager ✓ |
| `_floor_jump_panel` | `Control` | Floor jump panel | duplicated in SystemManager ✓ |
| `_interaction_bubble` | `Node` | Interaction bubble overlay | duplicated in SystemManager ✓ |
| `_shopping_list` | `ShoppingList` | Shopping list | duplicated in SystemManager ✓ |
| `_toasts` | `ToastManager` | Toast notification manager | duplicated in SystemManager ✓ |
| `_floating_text` | `FloatingText` | Floating text effects | duplicated in SystemManager ✓ |
| `_fade` | `FadeTransition` | Screen fade transitions | duplicated in SystemManager ✓ |
| `_minimap` | `MiniMap` | Mini map | duplicated in SystemManager ✓ |
| `_daily_bonus` | `DailyBonus` | Daily login bonus | duplicated in SystemManager ✓ |
| `_quest_system` | `QuestSystem` | Quest tracker | duplicated in SystemManager ✓ |
| `_quest_journal` | `QuestJournal` | Quest journal panel | duplicated in SystemManager ✓ |
| `_chat_panel` | `ChatPanel` | Chat panel | duplicated in SystemManager ✓ |
| `_chat_manager` | `ChatManager` | Chat manager | duplicated in SystemManager ✓ |
| `_game_clock` | `GameClock` | Game clock | duplicated in SystemManager ✓ |
| `_dev_tools` | `DevTools` | Dev tools panel | duplicated in SystemManager ✓ |
| `_debug_viewer` | `CanvasLayer` | Debug sprite viewer | duplicated in SystemManager ✓ |
| `_shelf_panel` | `CanvasLayer` | Shelf/warehouse panel | duplicated in SystemManager ✓ |
| `_audio` | `AudioManager` | Audio manager | duplicated in SystemManager ✓ |
| `_tutorial_overlay` | `TutorialOverlay` | Tutorial overlay | duplicated in SystemManager ✓ |
| `_save_hint_label` | `Label` | Save hint label | duplicated in SystemManager ✓ |
| `_section_browse` | `SectionBrowse` | Section browse panel | duplicated in SystemManager ✓ |
| `_food_stall_browse` | `FoodStallBrowse` | Food stall browse | duplicated in SystemManager ✓ |

---

## Phase 5 — `UIManager`

**File:** `scripts/core/main_manager/ui_manager.gd`
**Goal:** Consolidate all UI panel creation, ToastManager, and HUD under UIManager

### Functions moved (duplicated, NOT deleted from main.gd yet)

| Original Location | Function | Description | Status |
|-------------------|----------|-------------|--------|
| `main.gd` | `_show_save_hint(msg)` | Show temporary save hint | duplicated in UIManager ✓ |
| `main.gd` | `_show_achievement_popup(...)` | Show achievement unlock popup | duplicated in UIManager ✓ |
| `main.gd` | `_on_achievement_unlocked(ach_id)` | Achievement unlocked signal | duplicated in UIManager ✓ |
| `main.gd` | `_on_staff_rank_up(new_rank)` | Staff rank up handler | duplicated in UIManager ✓ |
| `main.gd` | `_update_staff_rank_hud()` | Update staff rank label | duplicated in UIManager ✓ |
| `main.gd` | `_on_player_level_up(new_level)` | Level up handler | duplicated in UIManager ✓ |
| `main.gd` | `_on_hour_changed(hour)` | Hour change signal | duplicated in UIManager ✓ |
| `main.gd` | `_on_day_changed()` | Day change signal | duplicated in UIManager ✓ |
| `main.gd` | `_on_shift_report()` | Shift report handler | duplicated in UIManager ✓ |
| `main.gd` | `_on_quest_completed(quest_id, desc, xp)` | Quest completed handler | duplicated in UIManager ✓ |
| `main.gd` | `_on_all_quests_complete()` | All quests done handler | duplicated in UIManager ✓ |
| `main.gd` | `_on_cart_grabbed()` | Cart grabbed handler | duplicated in UIManager ✓ |
| `main.gd` | `_on_cart_dropped()` | Cart dropped handler | duplicated in UIManager ✓ |
| `main.gd` | `_toggle_quest_journal()` | Toggle quest journal | duplicated in UIManager ✓ |
| `main.gd` | `_on_issue_created(issue)` | Maintenance issue created | duplicated in UIManager ✓ |
| `main.gd` | `_on_issue_resolved(issue, by_player)` | Issue resolved handler | duplicated in UIManager ✓ |
| `main.gd` | `_on_streak_reward(days, bonus_xp)` | Daily streak reward | duplicated in UIManager ✓ |
| `main.gd` | `_on_item_added_to_cart(item_data, count)` | Item added to cart | duplicated in UIManager ✓ |
| `main.gd` | `_on_browse_closed()` | Browse panel closed | duplicated in UIManager ✓ |
| `main.gd` | `_on_brand_portal_closed()` | Brand portal closed | duplicated in UIManager ✓ |
| `main.gd` | `_on_chat_panel_closed()` | Chat panel closed | duplicated in UIManager ✓ |

### Variables moved (duplicated, NOT deleted from main.gd yet)

| Variable | Type | Description | Status |
|----------|------|-------------|--------|
| `_toasts` | `ToastManager` | Toast notification system | duplicated in UIManager ✓ |
| `_floating_text` | `FloatingText` | Floating text | duplicated in UIManager ✓ |
| `_fade` | `FadeTransition` | Screen fade | duplicated in UIManager ✓ |
| `_minimap` | `MiniMap` | Mini map | duplicated in UIManager ✓ |
| `_daily_bonus` | `DailyBonus` | Daily bonus | duplicated in UIManager ✓ |
| `_quest_system` | `QuestSystem` | Quest system | duplicated in UIManager ✓ |
| `_quest_journal` | `QuestJournal` | Quest journal | duplicated in UIManager ✓ |
| `_shopping_list` | `ShoppingList` | Shopping list | duplicated in UIManager ✓ |
| `_stats_dashboard` | `StatsDashboard` | Stats dashboard | duplicated in UIManager ✓ |
| `_map_panel` | `MapPanel` | Map panel | duplicated in UIManager ✓ |
| `_floor_panel` | `FloorPanel` | Floor panel | duplicated in UIManager ✓ |
| `_floor_jump_panel` | `Control` | Floor jump panel | duplicated in UIManager ✓ |
| `_interaction_bubble` | `Node` | Interaction bubble | duplicated in UIManager ✓ |
| `_chat_panel` | `ChatPanel` | Chat panel | duplicated in UIManager ✓ |
| `_achievement_popup` | `Node` | Achievement popup (inline created) | duplicated in UIManager ✓ |
| `_stats_panel` | `StatsPanel` | Stats panel | duplicated in UIManager ✓ |
| `_maintenance_panel` | `MaintenancePanel` | Maintenance panel | duplicated in UIManager ✓ |
| `_atm_panel` | `ATMPanel` | ATM panel | duplicated in UIManager ✓ |
| `_monitor_panel` | `MonitorPanel` | Monitor panel | duplicated in UIManager ✓ |
| `_settings_panel` | `SettingsPanel` | Settings panel | duplicated in UIManager ✓ |
| `_pause_menu` | `PauseMenu` | Pause menu | duplicated in UIManager ✓ |
| `_tutorial_overlay` | `TutorialOverlay` | Tutorial overlay | duplicated in UIManager ✓ |
| `_dev_tools` | `DevTools` | Dev tools | duplicated in UIManager ✓ |
| `_shelf_panel` | `CanvasLayer` | Shelf panel | duplicated in UIManager ✓ |
| `_save_hint_label` | `Label` | Save hint | duplicated in UIManager ✓ |
| `_time_label` | `Label` | Time display label | duplicated in UIManager ✓ |
| `_store_status_label` | `Label` | Store open/closed label | duplicated in UIManager ✓ |
| `_shopping_list_count_lbl` | `Label` | Shopping list count label | duplicated in UIManager ✓ |
| `_xp_bar_bg` | `ColorRect` | XP bar background | duplicated in UIManager ✓ |
| `_xp_bar_fill` | `ColorRect` | XP bar fill | duplicated in UIManager ✓ |
| `_checkout_counter_label` | `Label` | Checkout counter label | duplicated in UIManager ✓ |
| `_checkout_items_lbl` | `Label` | Checkout items label | duplicated in UIManager ✓ |
| `_checkout_total_lbl` | `Label` | Checkout total label | duplicated in UIManager ✓ |
| `_minimap_visible` | `bool` | Minimap visibility | duplicated in UIManager ✓ |
| `_shopping_list_visible` | `bool` | Shopping list visibility | duplicated in UIManager ✓ |
| `_loyalty_panel` | `Node2D` | Loyalty panel | duplicated in UIManager ✓ |
| `_truck_dock_node` | `Node2D` | Truck dock node | duplicated in UIManager ✓ |

---

## Phase 6 — `CommandManager`

**File:** `scripts/core/main_manager/command_manager.gd`
**Goal:** Refactor `_input()` into key-binding map in CommandManager

### Functions moved (duplicated, NOT deleted from main.gd yet)

| Original Location | Function | Description | Status |
|-------------------|----------|-------------|--------|
| `main.gd` | `_input(event)` | Central input handler (140+ lines, all key matching) | duplicated in CommandManager ✓ |
| `main.gd` | `_handle_numbered_interaction(num)` | Routes 0-9 bubble interactions | duplicated in CommandManager ✓ |

### Key Bindings Mapped

| Key | Action | Current Handler |
|-----|--------|-----------------|
| `W / UP` | Stairs up | `_input()` → stairs_system |
| `S / DOWN` | Stairs down | `_input()` → stairs_system |
| `KEY_C` | Chat with NPC | `_input()` → `_open_npc_chat()` |
| `KEY_F3` | Dev tools toggle | `_input()` → `PanelManager.toggle("dev_tools")` |
| `KEY_F5` | Quick save | `_input()` → `SaveSystem.save_game()` |
| `KEY_F9` | Debug viewer / load | `_input()` → `_debug_viewer.toggle()` or `SaveSystem.load_game()` |
| `KEY_L` | Shopping list toggle | `_input()` → `_toggle_shopping_list()` |
| `KEY_T` | Floor jump panel | `_input()` → `_toggle_floor_jump_panel()` |
| `KEY_M` | Map panel | `_input()` → `PanelManager.toggle("map")` |
| `KEY_V` | Floor panel | `_input()` → `PanelManager.toggle("floor")` |
| `KEY_X` | Renovate section | `_input()` → `_renovate_nearby_section()` |
| `KEY_F` | Catch thief | `_input()` → `_attempt_catch_thief()` |
| `KEY_B` | Brand portal | `_input()` → `_toggle_brand_portal()` |
| `Shift+KEY_B` | Business mode | `_input()` → `_toggle_business_mode()` |
| `KEY_J` | Quest journal | `_input()` → `_toggle_quest_journal()` |
| `KEY_R` | Robot panel / restock | `_input()` → `_toggle_robot_panel()` or `_restock_nearby_section()` |
| `KEY_O` | Settings | `_input()` → `PanelManager.toggle("settings")` |
| `KEY_P / SPACE` | Pause | `_input()` → `_toggle_pause()` |
| `KEY_K` | Stats dashboard | `_input()` → `_toggle_stats_dashboard()` |
| `KEY_H` | Shelf panel | `_input()` → `_toggle_shelf_panel()` |
| `KEY_0-9` | Numbered bubble | `_input()` → `_handle_numbered_interaction()` |
| `KEY_WASD` | Warehouse equipment | `_input()` (when `_warehouse_mode`) |
| `Interact (E)` | Interact with nearby | `_input()` → `_on_player_interact()` |

### Variables moved (duplicated, NOT deleted from main.gd yet)

| Variable | Type | Description | Status |
|----------|------|-------------|--------|
| `_temp_order_mode` | `String` | Temporary order mode state | duplicated in CommandManager ✓ |
| `_temp_order_items` | `Array` | Temporary order items | duplicated in CommandManager ✓ |
| `_warehouse_mode` | `bool` | Warehouse equipment control mode | duplicated in CommandManager ✓ |
| `_in_elevator` | `bool` | In elevator (blocks input) | duplicated in CommandManager ✓ |
| `_checkout_receipt_visible` | `bool` | Checkout receipt panel showing | duplicated in CommandManager ✓ |

---

## Phase 7 — Cleanup (TODO)

**Status:** Not started — depends on Phase 2-6 completion

After all phases 2-6 agents complete and verification passes:
1. Delete duplicated functions from `main.gd` (keep stubs that delegate to new managers)
2. Delete duplicated instance variables from `main.gd`
3. Remove `main_init.gd` inline setup code that duplicates manager creation
4. Thin `main.gd` to ~100 lines: game loop, global signal routing, getter stubs
5. Update all `get("_xxx")` / `set("_xxx")` pseudo-dynamic access to typed getters
