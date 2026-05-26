"""
TileSet Generator for Godot 4

This script generates a floor_tileset.tres file for Godot 4 TileMap.
It reads individual tile images from generated_tiles/ and creates a proper TileSet.

Usage:
    python generate_tileset.py

Requirements:
    pip install Pillow
"""

import os
import json
from pathlib import Path
from PIL import Image

TILES_DIR = Path(__file__).parent / "generated_tiles"
OUTPUT_FILE = Path(__file__).parent / "floor_tileset.tres"

# Tile definitions: (filename, atlas_coords, tile_name, layer)
# layer 0 = floor, layer 1 = walls, layer 2 = decor
# IMPORTANT: Index 0 is reserved for blocked/wall tile
TILES = [
    # Blocked tile (index 0) - black solid tile for non-walkable areas
    ("blocked.png", (0, 0), "Blocked", 0),
    # Floor tiles (layer 0)
    ("floor_lobby.png", (1, 0), "Floor Lobby", 0),
    ("floor_common.png", (2, 0), "Floor Common", 0),
    ("floor_warehouse.png", (3, 0), "Floor Warehouse", 0),
    ("floor_food_court.png", (4, 0), "Floor Food Court", 0),
    ("floor_wc.png", (5, 0), "Floor WC", 0),
    ("floor_parking.png", (0, 1), "Floor Parking", 0),
    ("floor_rooftop.png", (1, 1), "Floor Rooftop", 0),
    ("floor_pet_adoption.png", (2, 1), "Floor Pet Adoption", 0),
    ("floor_truck_dock.png", (3, 1), "Floor Truck Dock", 0),
    ("floor_forklift.png", (4, 1), "Floor Forklift", 0),
    ("floor_conveyor.png", (5, 1), "Floor Conveyor", 0),
    ("floor_storage_shelf.png", (0, 2), "Floor Storage Shelf", 0),
    ("floor_shoes.png", (1, 2), "Floor Shoes", 0),
    ("floor_dress.png", (2, 2), "Floor Dress", 0),
    ("floor_sport.png", (3, 2), "Floor Sport", 0),
    # Decor tiles (layer 2)
    ("table.png", (4, 2), "Table", 2),
    ("plant.png", (5, 2), "Plant", 2),
    ("kiosk.png", (0, 3), "Kiosk", 2),
    ("atm.png", (1, 3), "ATM", 2),
    ("vending_machine.png", (2, 3), "Vending Machine", 2),
    ("promo_booth.png", (3, 3), "Promo Booth", 2),
]

ATLAS_COLS = 6
ATLAS_ROWS = 5
TILE_SIZE = 16


def create_atlas_from_tiles() -> Image.Image:
    """Create a tile atlas image from individual tiles."""
    atlas_width = ATLAS_COLS * TILE_SIZE
    atlas_height = ATLAS_ROWS * TILE_SIZE
    atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))

    for filename, (col, row), name, layer in TILES:
        filepath = TILES_DIR / filename
        if filepath.exists():
            tile = Image.open(filepath)
            tile = tile.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)
            x = col * TILE_SIZE
            y = row * TILE_SIZE
            atlas.paste(tile, (x, y))

    return atlas


def generate_tileset_tres(atlas_path: str) -> str:
    """Generate TileSet .tres file content."""
    atlas_rel_path = atlas_path.replace("\\", "/")

    tres_content = f'''[gd_resource type="TileSet" load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://resources/tilesets/generated_tiles/tile_atlas.png" id="1"]

[resource]
resource_name = "Floor TileSet"
tile_shape = 1
tile_layout = 5
tile_center_origin = 0
tile_offset = Vector2(0, 0)
tile_size = Vector2i({TILE_SIZE}, {TILE_SIZE})
usage = 1
physics_layer_0/collision_layer = 0
physics_layer_0/collision_mask = 0
navigation_layer_0/layers = 1
terrain_layer_0/modes = 0
terrain_layer_0/terrains = []

'''

    # Add source for atlas
    source_id = 0
    tres_content += f'''[source]
source_id = {source_id}
creator = ""
type = 2
uuid = "{generate_uuid()}"
name = "tile_atlas"
size = Vector2i({ATLAS_COLS}, {ATLAS_ROWS})
separation = Vector2i(0, 0)
texture = ExtResource("1")
texture_region_size = Vector2i({TILE_SIZE}, {TILE_SIZE})

'''

    # Add individual tiles from atlas
    for filename, (col, row), name, layer in TILES:
        tile_id = ATLAS_COLS * row + col
        tres_content += f'''[source@{source_id + tile_id + 1}]
source_id = {source_id}
creator = ""
type = 2
uuid = "{generate_uuid()}"
name = "{name}"
enable_rotate = false
corner_uv = Vector2(0, 0)
rotate_uv = false
tile_mode = 0
occlusion_layer_0/polygon = SubResource("null")
physics_layer_0/shape_index_0 = SubResource("null")
terrain_layer_0/terrain_0 = SubResource("null")
terrain_layer_0/terrain_1 = SubResource("null")
terrain_layer_0/terrain_2 = SubResource("null")
terrain_layer_0/terrain_3 = SubResource("null")
terrain_layer_0/terrain_4 = SubResource("null")
terrain_layer_0/terrain_5 = SubResource("null")
terrain_layer_0/terrain_6 = SubResource("null")
terrain_layer_0/terrain_7 = SubResource("null")
layer_0/name = "Layer 0"
layer_0/texture = SubResource("null")
layer_0/texture_offset = Vector2(0, 0)
layer_0/texture_rotation = 0
layer_0/modulate = Color(1, 1, 1, 1)
layer_0/y_sorting_enabled = false
layer_0/y_sort_origin = 0
layer_0/z_index = 0
layer_0/is_collision_10 = false

'''

    return tres_content


def generate_uuid() -> str:
    """Generate a simple UUID-like string."""
    import random
    import string
    return ''.join(random.choices(string.hexdigits.lower(), k=32))


def main():
    print("TileSet Generator for Godot 4")
    print("=" * 40)

    # Check if tiles exist
    if not TILES_DIR.exists():
        print(f"Error: {TILES_DIR} not found")
        print("Run generate_tiles.py first to generate tiles")
        return

    # Create atlas
    print("Creating tile atlas...")
    atlas = create_atlas_from_tiles()

    # Save atlas
    atlas_path = TILES_DIR / "tile_atlas.png"
    atlas.save(atlas_path, "PNG")
    print(f"Saved atlas to: {atlas_path}")

    # Generate TileSet .tres
    print("Generating TileSet .tres file...")
    tres_content = generate_tileset_tres(str(atlas_path))

    with open(OUTPUT_FILE, "w") as f:
        f.write(tres_content)

    print(f"Saved TileSet to: {OUTPUT_FILE}")
    print("\nDone! Copy floor_tileset.tres to your Godot project:")
    print("  res://resources/tilesets/floor_tileset.tres")


if __name__ == "__main__":
    main()
