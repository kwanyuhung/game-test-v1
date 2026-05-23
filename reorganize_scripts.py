#!/usr/bin/env python3
"""
Script to reorganize scripts into proper directory structure.
Moves scripts to categorized subdirectories and updates all preload paths.
"""

import os
import re
import shutil
from pathlib import Path

BASE_DIR = Path("c:/Users/User/Documents/GitHub/game-test-v1/scripts")

# Define reorganization mapping: current_file -> new_subdirectory
REORGANIZE_MAP = {
    # Core - main game entry point and initialization
    "main.gd": "core",
    "main_init.gd": "core",
    "main_config.gd": "core",
    "main_hud.gd": "core",
    "main_panels.gd": "core",
    
    # Entities - player, NPCs, robots, characters
    "player.gd": "entities",
    "super_actor.gd": "entities",
    "npc_controller.gd": "entities",
    "npc_sprite.gd": "entities",
    "robot_controller.gd": "entities",
    "ai_chat_brain.gd": "entities",
    "actor_data.gd": "entities",
    "maintenance_visual.gd": "entities",
    
    # World - floor, section, store data, spawning
    "main_spawner.gd": "world",
    "store_data.gd": "world",
    "section_browse.gd": "world",
    "section.gd": "world",
    "floor_builder.gd": "world",
    "floor_manager.gd": "world",
    "floors.gd": "world",
    "floor_config.gd": "world",
    "floor_0_config.gd": "areas/floor_0",
    "spawn_config.gd": "world",
    "spawn_manager.gd": "world",
    
    # Systems - gameplay systems
    "checkout_system.gd": "systems",
    "checkout_counter.gd": "systems",
    "food_court_system.gd": "systems",
    "food_stall.gd": "systems",
    "food_stall_browse.gd": "systems",
    "truck_dock_system.gd": "systems",
    "warehouse_system.gd": "systems",
    "warehouse_floor.gd": "systems",
    "parking_lot.gd": "systems",
    "anti_theft.gd": "systems",
    "price_override.gd": "systems",
    "price_terminal.gd": "systems",
    "promotion_manager.gd": "systems",
    "dynamic_pricing.gd": "systems",
    "supplier_manager.gd": "systems",
    "store_expansion.gd": "systems",
    "quest_system.gd": "systems",
    "proximity_system.gd": "systems",
    "stairs_system.gd": "systems",
    "escalator.gd": "systems",
    "elevator.gd": "systems",
    "maintenance_system.gd": "systems",
    
    # UI - user interface panels and HUD elements
    "achievement_popup.gd": "ui",
    "chat_bubble.gd": "ui",
    "chat_panel.gd": "ui",
    "dev_tools.gd": "ui",
    "pause_menu.gd": "ui",
    "settings_panel.gd": "ui",
    "quest_journal.gd": "ui",
    "toast_manager.gd": "ui",
    "interaction_bubble.gd": "ui",
    "product_tooltip.gd": "ui",
    "mini_map.gd": "ui",
    "map_panel.gd": "ui",
    "floor_panel.gd": "ui",
    "monitor_panel.gd": "ui",
    "maintenance_panel.gd": "ui",
    "shelf_panel.gd": "ui",
    "daily_bonus.gd": "ui",
    "stats_panel.gd": "ui",
    "stats_dashboard.gd": "ui",
    "business_mode.gd": "ui",
    "tutorial_overlay.gd": "ui",
    
    # Managers - singleton services
    "save_system.gd": "managers",
    "game_clock.gd": "managers",
    "audio_manager.gd": "managers",
    "brand_manager.gd": "managers",
    "brand_portal.gd": "managers",
    "chat_manager.gd": "managers",
    "robot_panel_system.gd": "managers",
    
    # Amenities - shop/facility elements
    "atm.gd": "amenities",
    "atm_panel.gd": "amenities",
    "shopping_cart.gd": "amenities",
    "shopping_list.gd": "amenities",
    "claw_machine.gd": "amenities",
    
    # Utils - debugging and utilities
    "debug_config.gd": "utils",
    "debug_bounds.gd": "utils",
    "debug_sprite_viewer.gd": "utils",
    
    # Integration - external integrations
    "telegram_bot.gd": "integration",
}

# Files to keep in root (data/config files)
KEEP_IN_ROOT = [
    "floor_config_data.json",
    "debug_config.json",
    "main_config.json",
    "spawn_config.json",
]


def create_directories():
    """Create target directories if they don't exist."""
    dirs = set(REORGANIZE_MAP.values())
    for d in dirs:
        dir_path = BASE_DIR / d
        dir_path.mkdir(exist_ok=True)
        # Create __init__.gd if it doesn't exist
        init_file = dir_path / "__init__.gd"
        if not init_file.exists():
            init_file.write_text("extends Node\n")
    print(f"Created directories: {dirs}")


def move_scripts():
    """Move scripts to their new locations."""
    moved = []
    for filename, target_dir in REORGANIZE_MAP.items():
        src = BASE_DIR / filename
        if src.exists():
            dst = BASE_DIR / target_dir / filename
            shutil.move(str(src), str(dst))
            moved.append(f"{filename} -> {target_dir}/")
            
            # Move .uid file if exists
            uid_src = BASE_DIR / f"{filename}.uid"
            if uid_src.exists():
                shutil.move(str(uid_src), str(BASE_DIR / target_dir / f"{filename}.uid"))
        else:
            print(f"WARNING: {filename} not found, skipping")
    return moved


def update_preload_paths():
    """Update all preload paths in .gd files after reorganization."""
    # Pattern to find preload statements
    pattern = re.compile(r'preload\s*\(\s*"res://scripts/(\w+\.gd)"\s*\)')
    
    updated_files = []
    for gd_file in BASE_DIR.rglob("*.gd"):
        if gd_file.name == "__init__.gd":
            continue
            
        content = gd_file.read_text(encoding='utf-8')
        new_content = content
        
        for match in pattern.finditer(content):
            old_name = match.group(1)
            if old_name in REORGANIZE_MAP:
                new_dir = REORGANIZE_MAP[old_name]
                new_path = f"res://scripts/{new_dir}/{old_name}"
                old_path = f"res://scripts/{old_name}"
                new_content = new_content.replace(old_path, new_path)
        
        if new_content != content:
            gd_file.write_text(new_content, encoding='utf-8')
            updated_files.append(str(gd_file.relative_to(BASE_DIR)))
    
    return updated_files


def main():
    print("=" * 60)
    print("Script Reorganization Tool")
    print("=" * 60)
    
    print("\n1. Creating directories...")
    create_directories()
    
    print("\n2. Moving scripts...")
    moved = move_scripts()
    for m in moved:
        print(f"   {m}")
    
    print("\n3. Updating preload paths...")
    updated = update_preload_paths()
    for f in updated:
        print(f"   Updated: {f}")
    
    print("\n" + "=" * 60)
    print("Reorganization complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
