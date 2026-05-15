# __init__.gd
# ─────────────────────────────────────────────────────────────────────────────
# Floor 8 (Executive Office) Areas module
# Exports all area handler classes for Floor 8
# ─────────────────────────────────────────────────────────────────────────────

class_name Floor8Areas

# Floor 8 handlers
const ExecOfficeHandler = preload("res://scripts/areas/floor_8/exec_office_handler.gd")
const ExecOfficeCommonHandler = preload("res://scripts/areas/floor_8/exec_office_common_handler.gd")
const Floor8Handler = preload("res://scripts/areas/floor_8/floor_8_handler.gd")

# Shared handlers used by Floor 8
const ElevatorHandler = preload("res://scripts/areas/shared/elevator_handler.gd")
const StairsHandler = preload("res://scripts/areas/shared/stairs_handler.gd")