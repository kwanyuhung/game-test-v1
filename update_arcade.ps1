param(
    [string]$path = "C:\Users\user\Documents\game-test\scripts\floor_config.gd"
)
$lines = @(Get-Content $path)

# Lines are 1-indexed in output, 0-indexed in array.
# We want to replace lines 466-485 (Floor 8) with the new Arcade floor.

$newFloor8 = @(
    "	# ──────────────────────────────────────────────────────────────────",
    "	# FLOOR 8 — Arcade & Claw Machines",
    "	# Neon arcade: 4 claw machines, prize shelves, retro game vibes.",
    "	# Left: 2 claw machines. Right: 2 claw machines. Center: prize aisles.",
    "	# ──────────────────────────────────────────────────────────────────",
    "	FLOOR_DEFS.append(FloorDef.new(",
    "		8, `"8`", `"arcade`", Color(0.38, 0.35, 0.50),",
    "		[",
    "			# Main aisle structure",
    "			Z(ZONE_AISLE,       0,  2, 80,  1),",
    "			Z(ZONE_AISLE,      36,  2,  2, 38),",
    "			Z(ZONE_AISLE,       0, 19, 80,  2),",
    "			Z(ZONE_ELEVATOR,   80,  2,  4, 40),",
    "			Z(ZONE_STAIRS,     84,  2,  6, 40),",
    "			# Claw machine zones",
    "			Z(ZONE_CLAW_MACHINE,  2,  3, 16, 16, {`"machine_id`": `"claw_1`", `"prize_pool`": 0}),",
    "			Z(ZONE_CLAW_MACHINE,  2, 21, 16, 16, {`"machine_id`": `"claw_2`", `"prize_pool`": 1}),",
    "			Z(ZONE_CLAW_MACHINE, 38,  3, 16, 16, {`"machine_id`": `"claw_3`", `"prize_pool`": 2}),",
    "			Z(ZONE_CLAW_MACHINE, 38, 21, 16, 16, {`"machine_id`": `"claw_4`", `"prize_pool`": 3}),",
    "			# Prize display shelves",
    "			Z(ZONE_DECOR,       14,  5, 10,  8, {`"decor_type`": `"shelf`"}),",
    "			Z(ZONE_DECOR,       14, 25, 10,  8, {`"decor_type`": `"shelf`"}),",
    "		],",
    "		[],  # no retail sections on arcade floor",
    "		false, true, true",
    "	))",
    ""
)

# Replace lines 466-485 (indices 465-484)
$result = @()
for ($i = 0; $i -lt 465; $i++) { $result += $lines[$i] }
foreach ($l in $newFloor8) { $result += $l }
for ($i = 485; $i -lt $lines.Count; $i++) { $result += $lines[$i] }

[System.IO.File]::WriteAllLines($path, $result)
Write-Host "Replaced Floor 8. Total lines: $($result.Count)"
