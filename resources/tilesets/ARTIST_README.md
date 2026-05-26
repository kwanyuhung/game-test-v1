# Floor TileSet Artist Specification

## Overview
Create pixel art tiles (16x16 pixels) for the Pixel Supermarket game floor rendering system.

## TileSet Structure

**File:** `res://resources/tilesets/floor_tileset.tres`
**Format:** Godot 4 TileSet with 3 layers

---

## Layer 0: Floor Layer (Walkable)

Base floor tiles that players walk on. These should be seamless/tiling textures.

### Required Tiles (Tile IDs)

| ID | Name | Description | Style |
|----|------|-------------|-------|
| 1 | `floor_lobby` | Main lobby area | Warm marble/ceramic, subtle pattern |
| 2 | `floor_common` | General walkway/aisle | Neutral stone/concrete |
| 3 | `floor_warehouse` | Warehouse/storage | Industrial concrete, darker |
| 4 | `floor_food_court` | Food court dining | Clean easy-to-clean look |
| 5 | `floor_wc` | Restroom floor | Tile-like, water resistant feel |
| 6 | `floor_parking` | Parking area | Asphalt gray |
| 7 | `floor_rooftop` | Rooftop cafe | Outdoor/patio style |
| 8 | `floor_pet_adoption` | Pet area | Easy clean, warm tone |
| 9 | `floor_truck_dock` | Loading dock | Industrial, heavy duty |
| 10 | `floor_forklift` | Forklift zone | Industrial markings |
| 11 | `floor_conveyor` | Conveyor belt | Metal/machinery |
| 12 | `floor_storage_shelf` | Storage area | Industrial shelving floor |
| 13 | `floor_wh_stock_view` | Warehouse viewing | Clear walkable area |
| 14 | `floor_shoes` | Shoes department | Carpet-like, retail |
| 15 | `floor_dress` | Clothing department | Carpet-like, retail |
| 16 | `floor_sport` | Sports department | Sport floor mat feel |
| 17 | `floor_outdoor` | Outdoor area | Grass/pavement |
| 18 | `floor_stationery` | Stationery | Clean retail |
| 19 | `floor_plants` | Plants area | Clean, garden feel |
| 20 | `floor_staff_lounge` | Staff break room | Homey, comfortable |
| 21 | `floor_training` | Training room | Classroom/meeting |
| 22 | `floor_office_desk` | Office area | Carpet, professional |
| 23 | `floor_exec_office` | Executive office | Premium carpet/floor |
| 24 | `floor_monitor_room` | Security/monitor | Dark, tech feel |
| 25-48 | (various dept floors) | Other departments | Match department theme |

### Style Guidelines for Floor Tiles
- **Pixel size:** 16x16 pixels
- **Style:** Pixel art, crisp edges, no anti-aliasing
- **Colors:** Muted, natural tones (oranges, browns, grays, greens)
- **Pattern:** Subtle texture that tiles seamlessly
- **Purpose:** Should not be distracting; supports gameplay visibility

---

## Layer 1: Wall Layer

Boundary and wall tiles. Used for visual separation and collision.

### Required Tiles

| ID | Name | Description |
|----|------|-------------|
| 100 | `wall_standard` | Standard wall/fence |
| 101 | `wall_decorative` | Decorative boundary |

### Style Guidelines for Wall Tiles
- **Height suggestion:** 1 tile (16px) for low boundaries, can stack
- **Colors:** Earth tones or neutral grays
- **Style:** Clear visual distinction from floor

---

## Layer 2: Decoration Layer

Furniture, fixtures, and decorative elements placed on top of floors.

### Required Tiles (Suggested)

| ID | Name | Description |
|----|------|-------------|
| 200 | `table` | Dining/general table |
| 201 | `plant` | Potted plant decoration |
| 202 | `kiosk` | Information kiosk |
| 203 | `claw_machine` | Claw game machine |
| 204 | `lost_found` | Lost & found box |
| 205 | `store_news` | News bulletin board |
| 206 | `locker` | Locker unit |
| 207 | `vending_machine` | Vending machine |
| 208 | `atm` | ATM machine |
| 209 | `promo_booth` | Promotion booth |

### Style Guidelines for Decor Tiles
- **Size:** 16x16 or multi-tile (e.g., 32x32 for larger items)
- **Colors:** Match game palette (see below)
- **Style:** Simple, readable silhouettes
- **Purpose:** Visual interest, not gameplay critical

---

## Color Palette Reference

### Primary Colors
```
Lobby/Warm:     #3D2E1E (dark brown)  #8B7355 (tan)  #C4A77D (sand)
Common/Neutral: #4A4A4A (gray)       #6B6B6B (medium gray)
Warehouse:      #3D3D3D (dark gray)  #5C5C5C (industrial gray)
Green/Nature:   #4A7C3F (forest)    #6B9B5A (grass)
Blue/Tech:      #4A6B8A (steel blue) #6B8BA8 (light steel)
Food/Cafe:      #8B6B4A (warm brown) #A68B6B (cafe tan)
```

### UI/Accent Colors
```
Player highlight: #00FFAA (cyan-green)
Robot markers:   #32CD32 (green), #FFD700 (gold), #FF4444 (red)
```

---

## Technical Requirements

### Image Format
- **Type:** PNG with transparency
- **Recommended:** Individual tile images, or atlas sheet
- **Pixel density:** 16x16 base, export at 1x (no scaling)

### TileSet Configuration (Godot 4)
1. Create TileSet resource at `res://resources/tilesets/floor_tileset.tres`
2. Add 3 layers: `floor_layer` (0), `wall_layer` (1), `decor_layer` (2)
3. Configure physics layer if needed for collision
4. Assign tile textures to each layer

### Naming Convention
- Use lowercase with underscores: `floor_lobby`, `wall_standard`
- Match IDs in `floor_config.gd` `get_tile_for_zone()` mapping

---

## Existing Game References

The game currently uses ColorRects with these approximate colors:

```gdscript
# Lobby
Color(0.22, 0.20, 0.18)    # Warm brownish gray

# Common/Aisle
Color(0.20, 0.19, 0.18)    # Dark gray

# Warehouse
Color(0.18, 0.18, 0.20)     # Blue-gray

# Food Court
Color(0.24, 0.20, 0.18)     # Warm dark

# Section floors (various)
Color(0.14, 0.18, 0.24)     # Fridge blue
Color(0.14, 0.19, 0.12)     # Produce green
Color(0.20, 0.15, 0.10)     # Bakery brown
```

---

## Deliverables Checklist

- [ ] Floor tiles (IDs 1-48) as 16x16 pixel PNG
- [ ] Wall tiles (IDs 100-101)
- [ ] Decoration tiles (IDs 200+)
- [ ] TileSet configured in Godot editor
- [ ] Test in-game to verify visual clarity

---

## AI Generation Option

Instead of manual drawing, tiles can be generated using AI image generation.

### Quick Start
```bash
cd resources/tilesets
python generate_tiles.py
```

Requires `MINIMAX_API_KEY` environment variable set.

### Batch Generation
See `BATCH_GENERATE.md` for pre-designed batch prompts that generate 9 tiles per API call.

### Manual API Generation
Use the MiniMax Image Generation API with prompts like:
```
16x16 pixel art tile: warm marble ceramic lobby floor, seamless tiling, muted tan brown #8B7355, pixel art style, crisp edges, video game sprite
```

Set aspect_ratio: "16:9" for 16x16 output.

---

## Contact

For questions about implementation, check:
- `scripts/world/floor_config.gd` - `get_tile_for_zone()` for ID mapping
- `scripts/world/tilemap_builder.gd` - TileMap building logic
- `scripts/floor_config_data.json` - Zone layouts
