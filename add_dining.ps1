param([string]$path = "C:\Users\user\Documents\game-test\scripts\floor_config.gd")
$content = Get-Content $path -Raw

$old = @"
			Z(ZONE_STAIRS,      84,  2,  6, 47),       # stairs
		],
		[],  # no retail sections on ground floor
"@

$new = @"
			Z(ZONE_STAIRS,      84,  2,  6, 47),       # stairs
			# Dining tables in aisle gap between row 1 & 2 stalls (y=11..15)
			Z(ZONE_DECOR,      16, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      34, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      52, 11,  4,  4, {"decor_type": "dining_table"}),
			Z(ZONE_DECOR,      70, 11,  4,  4, {"decor_type": "dining_table"}),
		],
		[],  # no retail sections on ground floor
"@

if ($content.Contains($old)) {
    $content = $content.Replace($old, $new)
    [System.IO.File]::WriteAllText($path, $content)
    Write-Host "Successfully added dining tables to Floor G"
} else {
    Write-Host "Could not find the target text block"
    # Try to find similar text
    $lines = $content -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "ZONE_STAIRS.*84.*47") {
            Write-Host "Found at line $($i+1): $($lines[$i])"
            Write-Host "Next line: $($lines[$i+1])"
            Write-Host "Next+1: $($lines[$i+2])"
        }
    }
}
