param([string]$path = "C:\Users\user\Documents\game-test\scripts\main.gd")
$lines = @(Get-Content $path)

# Find _on_player_interact start and _on_section_entered start
$startLine = -1
$sectionEnteredLine = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "func _on_player_interact\b") { $startLine = $i }
    if ($lines[$i] -match "func _on_section_entered\b") { $sectionEnteredLine = $i }
}

Write-Host "Found _on_player_interact at line $($startLine+1)"
Write-Host "Found _on_section_entered at line $($sectionEnteredLine+1)"

if ($startLine -lt 0 -or $sectionEnteredLine -lt 0) {
    Write-Host "Could not find functions, exiting"
    exit 1
}

# New lines to insert
$newLines = @(
    "func _on_player_interact() -> void:",
    "	if _checkout_receipt_visible:",
    "		_hide_checkout_receipt()",
    "		return",
    "	if _current_section_browse != null and _current_section_browse.visible:",
    "		return",
    "	# Elevator first",
    "	if _nearby_elevator:",
    "		_elevator.open_panel(_player.position, _player)",
    "		return",
    "	# Food stall order",
    "	if _nearby_stall != null:",
    "		_show_stall_menu(_nearby_stall)",
    "		return",
    "	# Checkout with items",
    "	if _nearby_checkout != null:",
    "		var cart = _player.get_cart()",
    "		if cart.get_item_count() > 0:",
    "			_show_checkout_receipt()",
    "		return",
    "	# Section browse",
    "	if _nearby_section != null:",
    "		var def = _nearby_section.get_def()",
    "		var prods = _nearby_section.get_all_products()",
    "		_current_section_browse = _section_browse",
    "		_section_browse.open(def.id, prods, _player.get_cart())",
    "		notify_telegram_section_browse(def.name, prods.size())",
    "",
    "func _on_stall_interact_requested(stall_id: String) -> void:",
    "	if _floor_builder != null:",
    "		for stall in _floor_builder.get_food_stalls():",
    "			if stall.get_stall_id() == stall_id:",
    "				_show_stall_menu(stall)",
    "				break",
    "",
    "func _show_stall_menu(stall: Node) -> void:",
    "	if _food_stall_browse == null:",
    "		_food_stall_browse = FoodStallBrowseScript.new()",
    "		add_child(_food_stall_browse)",
    "		_food_stall_browse.closed.connect(_on_food_stall_closed)",
    "		_food_stall_browse.item_added.connect(_on_food_stall_item_added)",
    "	var fd: FloorConfig.FoodStallDef = stall.get_stall_def()",
    "	_food_stall_browse.open(fd, _player.get_cart())",
    "",
    "func _on_food_stall_closed() -> void:",
    "	pass",
    "",
    "func _on_food_stall_item_added(item_name: String, qty: int, price: float) -> void:",
    "	pass",
    ""
)

# Build new file: lines before startLine, then newLines, then lines from sectionEnteredLine
$result = @()
for ($i = 0; $i -lt $startLine; $i++) {
    $result += $lines[$i]
}
foreach ($l in $newLines) { $result += $l }
for ($i = $sectionEnteredLine; $i -lt $lines.Count; $i++) {
    $result += $lines[$i]
}

[System.IO.File]::WriteAllLines($path, $result)
Write-Host "Done. Total lines: $($result.Count)"
