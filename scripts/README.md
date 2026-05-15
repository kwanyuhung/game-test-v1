# Scripts Directory Structure

This document describes the organization and purpose of each subdirectory in the `scripts/` folder.

---

## 📁 `areas/`

**Purpose:** Floor-specific game logic handlers

**Contains:**
- `floor_0/` through `floor_14/` directories, each containing handlers for specific supermarket floors
- `shared/` - Common handlers shared across multiple floors

**Key Files:**
- `floor_N/floor_N_handler.gd` - Main handler for each floor
- `floor_N/food_stall_handler.gd` - Food stall logic per floor
- `floor_N/electronics_handler.gd`, `shoes_rack_handler.gd`, etc. - Section-specific handlers

**Function:** Each floor in the supermarket has specialized handlers that manage zone interactions, NPC spawning, and section-specific gameplay for that floor.

---

## 📁 `core/`

**Purpose:** Main game entry point and initialization

**Contains:**
- `main.gd` - Primary game node, world builder for 10-floor supermarket
- `main_init.gd` - All game system initialization extracted from main.gd's _ready()
- `main_config.gd` - Loads main_config.json and provides typed access to game config
- `main_hud.gd` - Heads-up display attached to main node
- `main_panels.gd` - Manages UI panels (elevator, stairs, etc.)

**Function:** These are the core files that bootstrap the entire game. `main.gd` is the root Node2D that contains the supermarket world, while `main_init.gd` handles the systematic initialization of all subsystems.

**Dependencies:** References virtually all other scripts in the project.

---

## 📁 `entities/`

**Purpose:** Character entities, NPCs, and robots

**Contains:**
- `player.gd` - Player character with movement, cart handling, staff mode
- `super_actor.gd` - Base class for interactable characters
- `npc_controller.gd` - NPC/AI character with pathfinding and behavior
- `npc_sprite.gd` - NPC visual rendering and animation
- `robot_controller.gd` - Robot entities (cleaning, security, delivery)
- `ai_chat_brain.gd` - AI chat/talking behavior for NPCs
- `actor_data.gd` - Shared data structure for character properties
- `maintenance_visual.gd` - Visual effects for maintenance areas

**Function:** Contains all entity classes that can move, interact, and populate the game world. The player-controlled character, AI-controlled NPCs, and utility robots all live here.

**Extends:** CharacterBody2D (player, npc), Node2D (robots)

---

## 📁 `world/`

**Purpose:** World building, floor management, spawning, and data

**Contains:**
- `main_spawner.gd` - All NPC/customer/robot spawning methods
- `store_data.gd` - Product catalog and section layout data
- `section_browse.gd` - Full-screen interactive product browser UI
- `section.gd` - Individual section/supermarket aisle representation
- `floor_builder.gd` - Renders floors using configuration data
- `floor_manager.gd` - Manages active floors and freeze/unfreeze
- `floors.gd` - Floor utility functions
- `floor_config.gd` - Floor configuration and constants
- `floor_0_config.gd` - Ground floor specific configuration
- `spawn_config.gd` - NPC spawn configuration
- `spawn_manager.gd` - Handles spawn limits and weighted random selection

**Function:** These scripts handle the construction and data management of the supermarket world. They define where sections go, how products are organized, how floors are rendered, and how NPCs spawn.

**Note:** This is distinct from `entities/` - `world/` handles the static structure while `entities/` handles mobile characters.

---

## 📁 `systems/`

**Purpose:** Gameplay systems and mechanics

**Contains:**

*Checkout & Payment:*
- `checkout_system.gd` - All checkout logic, receipt display, error handling
- `checkout_counter.gd` - Checkout counter Area2D interactions
- `price_override.gd` - Manual price changes (signal: price_changed)
- `price_terminal.gd` - Price check terminal interface

*Food & Dining:*
- `food_court_system.gd` - Cafe, vending, loyalty, entertainment mini-games
- `food_stall.gd` - Individual food stall behavior
- `food_stall_browse.gd` - Food stall browsing interface

*Warehouse & Logistics:*
- `truck_dock_system.gd` - Truck dock visual and unload logic
- `warehouse_system.gd` - Warehouse management
- `warehouse_floor.gd` - Warehouse floor rendering
- `supplier_manager.gd` - Supplier relationship management

*Facilities:*
- `elevator.gd` - Elevator movement and player transport
- `escalator.gd` - Escalator continuous movement zones
- `stairs_system.gd` - Stair navigation between floors
- `parking_lot.gd` - Parking lot interactions

*Economy & Business:*
- `store_expansion.gd` - Store expansion mechanics
- `promotion_manager.gd` - Promotional offers and discounts
- `dynamic_pricing.gd` - Automated price adjustments
- `anti_theft.gd` - Security and theft prevention

*Maintenance & Operations:*
- `maintenance_system.gd` - Maintenance tracking and scheduling
- `proximity_system.gd` - Frame-by-frame proximity detection for interactions
- `quest_system.gd` - Quest tracking and completion

**Function:** These scripts implement the core gameplay mechanics and business simulation aspects of the supermarket.

---

## 📁 `ui/`

**Purpose:** User interface panels, HUD elements, and overlays

**Contains:**

*Panels:*
- `achievement_popup.gd` - Achievement unlock notifications
- `chat_panel.gd` - Chat/message interface
- `chat_bubble.gd` - In-world chat bubbles
- `dev_tools.gd` - Developer console (F3 toggle)
- `pause_menu.gd` - Game pause menu
- `settings_panel.gd` - Settings configuration
- `quest_journal.gd` - Quest tracking display
- `stats_panel.gd` - Statistics display
- `stats_dashboard.gd` - Main statistics dashboard
- `business_mode.gd` - Business simulation overlay
- `tutorial_overlay.gd` - Tutorial/help system

*Floor/Navigation:*
- `floor_panel.gd` - Floor selection panel
- `map_panel.gd` - Full map view
- `mini_map.gd` - Minimap in HUD
- `monitor_panel.gd` - Security camera monitor (Floor 7/8)

*Interactions:*
- `interaction_bubble.gd` - Floating numbered bubbles for quick selection (0-9)
- `product_tooltip.gd` - Product information tooltips
- `maintenance_panel.gd` - Maintenance management UI
- `shelf_panel.gd` - Shelf management interface
- `daily_bonus.gd` - Daily login bonus UI

*Visual Effects:*
- `floating_text.gd` - Floating damage/number text
- `fade_transition.gd` - Screen fade transitions
- `toast_manager.gd` - Toast notification system
- `hud.gd` - Main HUD rendering

**Function:** All visual interface elements that the player sees and interacts with. These extend `Control` and handle user input and information display.

---

## 📁 `managers/`

**Purpose:** Singleton services and global managers

**Contains:**
- `save_system.gd` - Player data persistence (position, floor, XP, level, cash, achievements, stats)
- `game_clock.gd` - Game time tracking (hour/day/shift changes)
- `audio_manager.gd` - Audio synthesis and sound management
- `brand_manager.gd` - Brand configuration and portal management
- `brand_portal.gd` - Brand display/portal interactions
- `chat_manager.gd` - Global chat message handling
- `robot_panel_system.gd` - Robot management UI
- `player_stats.gd` - Player statistics tracking

**Function:** These scripts provide global services that persist across scenes and don't belong to any specific entity. They are typically added to the tree once and remain active.

**Pattern:** Most extend `Node` and are added as children to autoload singletons or the main scene.

---

## 📁 `amenities/`

**Purpose:** Shop facilities and customer amenities

**Contains:**
- `atm.gd` - ATM machine (Node2D)
- `atm_panel.gd` - ATM interface panel
- `shopping_cart.gd` - Shopping cart logic and rendering
- `shopping_list.gd` - Customer shopping list management
- `claw_machine.gd` - Claw machine mini-game

**Function:** These represent physical amenities in the supermarket that customers (player or NPCs) can interact with. They extend `Node2D` and have spatial presence in the world.

---

## 📁 `utils/`

**Purpose:** Debugging tools and utility functions

**Contains:**
- `debug_config.gd` - Development settings and configuration
- `debug_bounds.gd` - Debug bounding box display (F3 toggle)
- `debug_sprite_viewer.gd` - Sprite debugging and inspection
- `pixel_art_generator.gd` - Pixel art generation utilities

**Function:** Developer-focused scripts that help with debugging, testing, and asset generation. Typically only active in development builds.

---

## 📁 `integration/`

**Purpose:** External service integrations

**Contains:**
- `telegram_bot.gd` - Telegram bot interface for remote game control/monitoring

**Function:** Bridges the game with external services and platforms.

---

## 📁 `areas/` vs `world/` vs `systems/` - Clarification

- **`areas/`** - Per-floor specific handlers (which floor has which sections, floor-unique logic)
- **`world/`** - Global world structure (how floors are built, where sections are positioned, spawn configuration)
- **`systems/`** - Gameplay mechanics that span across the entire game (checkout, pricing, quests)

---

## Dependency Flow

```
main.gd (core)
    ├── main_init.gd (core) - initializes all systems
    ├── main_panels.gd (core) - builds UI structure
    ├── main_hud.gd (core) - displays HUD
    ├── main_spawner.gd (world) - spawns entities
    ├── floor_builder.gd (world) - builds floors
    ├── store_data.gd (world) - product catalog
    │
    ├── entities/ - Characters that move and interact
    │
    ├── systems/ - Mechanics (checkout, pricing, etc.)
    │
    ├── ui/ - Panels and interfaces
    │
    └── managers/ - Global services
```

---

*Last updated: 2026-05-15*
