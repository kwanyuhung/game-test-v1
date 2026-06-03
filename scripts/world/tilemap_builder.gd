# tilemap_builder.gd
# Builds TileMap from zone definitions for floor rendering
class_name TileMapBuilder
extends Node

const CELL_SIZE := 16

enum LAYER { FLOOR = 0, WALLS = 1, DECOR = 2 }

const FloorConfig = preload("res://scripts/world/floor_config.gd")

func build_from_zones(zones: Array, tileset: TileSet) -> TileMap:
	var tilemap: TileMap = TileMap.new()
	tilemap.tile_set = tileset
	print("[TileMapBuilder] TileSet tile_size: ", tileset.tile_size if tileset else "null")
	print("[TileMapBuilder] Building TileMap with ", zones.size(), " zones")

	# Ensure TileMap has enough layers for all zones (max layer = 2 for decor)
	_expand_layers_if_needed(tilemap, 3)

	for zone in zones:
		_apply_zone(tilemap, zone)
	var tile_count = tilemap.get_used_cells(0).size()
	print("[TileMapBuilder] TileMap built, layer 0 tiles: ", tile_count)
	return tilemap

func _expand_layers_if_needed(tilemap: TileMap, min_layers: int) -> void:
	# Godot 4: TileMap layers must be set via TileSet or use add_layer()
	# Since TileSet controls layers, we add extra layers via the TileMap's layer system
	# In Godot 4 a TileMap's layers are fixed by the TileSet; we ensure the TileSet
	# has enough layers by checking and warning
	if tilemap.get_layers_count() < min_layers:
		for _i in range(tilemap.get_layers_count(), min_layers):
			tilemap.add_layer(_i)

func _apply_zone(tilemap: TileMap, zone: Dictionary) -> void:
	var zone_type: String = zone.get("type", "")
	var tile_info: Dictionary = FloorConfig.get_tile_for_zone(zone_type)
	var tile_id: int = tile_info.tile_id
	var layer: int = tile_info.layer

	# Debug output for zone processing
	print("[TileMapBuilder] Zone: ", zone_type, " -> tile_id=", tile_id, " layer=", layer)

	# Skip only if tile_id < 0 (special zones without floor tiles)
	# Note: elevator_shaft, stairs, escalator now render blocked (black) tiles
	if tile_id < 0:
		return

	var x: int = zone.get("x", 0)
	var y: int = zone.get("y", 0)
	var w: int = zone.get("w", 0)
	var h: int = zone.get("h", 0)

	for tx in range(x, x + w):
		for ty in range(y, y + h):
			tilemap.set_cell(layer, Vector2i(tx, ty), tile_id, Vector2i.ZERO)

# Apply a single tile at a specific position
func set_tile(tilemap: TileMap, layer: int, tile_x: int, tile_y: int, tile_id: int) -> void:
	tilemap.set_cell(layer, Vector2i(tile_x, tile_y), tile_id, Vector2i.ZERO)

# Fill a rectangular region with tiles
func fill_region(tilemap: TileMap, layer: int, x: int, y: int, w: int, h: int, tile_id: int) -> void:
	for tx in range(x, x + w):
		for ty in range(y, y + h):
			tilemap.set_cell(layer, Vector2i(tx, ty), tile_id, Vector2i.ZERO)

# Clear a region (set to empty, use -1 to clear in Godot 4)
const INVALID_CELL: int = -1

func clear_region(tilemap: TileMap, layer: int, x: int, y: int, w: int, h: int) -> void:
	for tx in range(x, x + w):
		for ty in range(y, y + h):
			tilemap.set_cell(layer, Vector2i(tx, ty), INVALID_CELL, Vector2i.ZERO)
