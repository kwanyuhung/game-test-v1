# PowerShell script to update preload paths for remaining files
# Updates paths for files that were missed in the first pass

$scriptDir = "c:/Users/User/Documents/GitHub/game-test-v1/scripts"

# Additional mappings for files moved after initial path update
$additionalMappings = @{
    # Files that were in wrong directories
    "hud.gd" = "ui"
    "floors.gd" = "world"
    "parking_lot.gd" = "systems"
    "floor_builder.gd" = "world"
    "floor_manager.gd" = "world"
    "main_spawner.gd" = "world"
    "section.gd" = "world"
    "section_browse.gd" = "world"
    "store_data.gd" = "world"
    
    # Newly moved files
    "fade_transition.gd" = "ui"
    "floating_text.gd" = "ui"
    "pixel_art_generator.gd" = "utils"
    "player_stats.gd" = "managers"
}

Write-Host "Updating additional preload paths..."

# Get all .gd files recursively
$gdFiles = Get-ChildItem -Path $scriptDir -Filter "*.gd" -Recurse | Where-Object { $_.Name -ne "__init__.gd" }

$updatedCount = 0

foreach ($file in $gdFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $newContent = $content
    
    foreach ($mapping in $additionalMappings.GetEnumerator()) {
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
Write-Host "Updated $updatedCount additional files"
Write-Host "Path update complete!"
