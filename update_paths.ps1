# PowerShell script to update preload paths after reorganization
# Updates all "res://scripts/xxx.gd" to "res://scripts/category/xxx.gd"

$scriptDir = "c:/Users/User/Documents/GitHub/game-test-v1/scripts"
$baseDir = "c:/Users/User/Documents/GitHub/game-test-v1"

# Mapping of file names to their new directories
$pathMappings = @{
    # Core
    "main.gd" = "core"
    "main_init.gd" = "core"
    "main_config.gd" = "core"
    "main_hud.gd" = "core"
    "main_panels.gd" = "core"
    
    # Entities
    "player.gd" = "entities"
    "super_actor.gd" = "entities"
    "npc_controller.gd" = "entities"
    "npc_sprite.gd" = "entities"
    "robot_controller.gd" = "entities"
    "ai_chat_brain.gd" = "entities"
    "actor_data.gd" = "entities"
    "maintenance_visual.gd" = "entities"
    
    # World
    "main_spawner.gd" = "world"
    "store_data.gd" = "world"
    "section_browse.gd" = "world"
    "section.gd" = "world"
    "floor_builder.gd" = "world"
    "floor_manager.gd" = "world"
    "floors.gd" = "world"
    "floor_config.gd" = "world"
    "floor_0_config.gd" = "areas/floor_0"
    "spawn_config.gd" = "world"
    "spawn_manager.gd" = "world"
    
    # Systems
    "checkout_system.gd" = "systems"
    "checkout_counter.gd" = "systems"
    "food_court_system.gd" = "systems"
    "food_stall.gd" = "systems"
    "food_stall_browse.gd" = "systems"
    "truck_dock_system.gd" = "systems"
    "warehouse_system.gd" = "systems"
    "warehouse_floor.gd" = "systems"
    "parking_lot.gd" = "systems"
    "anti_theft.gd" = "systems"
    "price_override.gd" = "systems"
    "price_terminal.gd" = "systems"
    "promotion_manager.gd" = "systems"
    "dynamic_pricing.gd" = "systems"
    "supplier_manager.gd" = "systems"
    "store_expansion.gd" = "systems"
    "quest_system.gd" = "systems"
    "proximity_system.gd" = "systems"
    "stairs_system.gd" = "systems"
    "escalator.gd" = "systems"
    "elevator.gd" = "systems"
    "maintenance_system.gd" = "systems"
    
    # UI
    "achievement_popup.gd" = "ui"
    "chat_bubble.gd" = "ui"
    "chat_panel.gd" = "ui"
    "dev_tools.gd" = "ui"
    "pause_menu.gd" = "ui"
    "settings_panel.gd" = "ui"
    "quest_journal.gd" = "ui"
    "toast_manager.gd" = "ui"
    "interaction_bubble.gd" = "ui"
    "product_tooltip.gd" = "ui"
    "mini_map.gd" = "ui"
    "map_panel.gd" = "ui"
    "floor_panel.gd" = "ui"
    "monitor_panel.gd" = "ui"
    "maintenance_panel.gd" = "ui"
    "shelf_panel.gd" = "ui"
    "daily_bonus.gd" = "ui"
    "stats_panel.gd" = "ui"
    "stats_dashboard.gd" = "ui"
    "business_mode.gd" = "ui"
    "tutorial_overlay.gd" = "ui"
    
    # Managers
    "save_system.gd" = "managers"
    "game_clock.gd" = "managers"
    "audio_manager.gd" = "managers"
    "brand_manager.gd" = "managers"
    "brand_portal.gd" = "managers"
    "chat_manager.gd" = "managers"
    "robot_panel_system.gd" = "managers"
    
    # Amenities
    "atm.gd" = "amenities"
    "atm_panel.gd" = "amenities"
    "shopping_cart.gd" = "amenities"
    "shopping_list.gd" = "amenities"
    "claw_machine.gd" = "amenities"
    
    # Utils
    "debug_config.gd" = "utils"
    "debug_bounds.gd" = "utils"
    "debug_sprite_viewer.gd" = "utils"
    
    # Integration
    "telegram_bot.gd" = "integration"
}

Write-Host "Updating preload paths..."

# Get all .gd files recursively
$gdFiles = Get-ChildItem -Path $scriptDir -Filter "*.gd" -Recurse | Where-Object { $_.Name -ne "__init__.gd" }

$updatedCount = 0

foreach ($file in $gdFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $newContent = $content
    
    foreach ($mapping in $pathMappings.GetEnumerator()) {
        $oldPattern = "res://scripts/$($mapping.Key)"
        $newPath = "res://scripts/$($mapping.Value)/$($mapping.Key)"
        
        if ($newContent -match [regex]::Escape($oldPattern)) {
            $newContent = $newContent -replace [regex]::Escape($oldPattern), $newPath
            Write-Host "  Updated: $($file.Name) -> $($mapping.Value)/$($mapping.Key)"
        }
    }
    
    if ($newContent -ne $content) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        $updatedCount++
    }
}

Write-Host ""
Write-Host "Updated $updatedCount files"
Write-Host "Path update complete!"
