# Tile Generation Batching Strategy

Since the MiniMax API supports generating up to 9 images per request, we can batch tile generation for efficiency.

## Batch Prompts

Use these prompts with `n=9` to generate tiles in groups.

---

### Batch 1: Floor Tiles (Row 1) - 9 tiles
```
16x16 pixel art game tiles, seamless tiling, arranged in 3x3 grid:
- Tile 1: Lobby marble floor, warm tan #8B7355
- Tile 2: Common walkway stone, neutral gray #6B6B6B
- Tile 3: Warehouse concrete, dark gray #5C5C5C
- Tile 4: Food court dining tile, warm brown #8B6B4A
- Tile 5: WC restroom ceramic, light gray #7A7A7A
- Tile 6: Parking asphalt, dark #4A4A4A
- Tile 7: Rooftop patio stone, beige #9B8B7A
- Tile 8: Pet adoption floor, warm tan #A08060
- Tile 9: Truck dock industrial, gray #5A5A5A

Pixel art style, crisp edges, video game sprite, muted earth tones.
```

---

### Batch 2: Floor Tiles (Row 2) + Some Decor
```
16x16 pixel art game tiles, seamless tiling, arranged in 3x3 grid:
- Tile 1: Forklift zone marking, industrial gray #6B6B6B
- Tile 2: Conveyor belt metal surface, steel gray #7A7A7A
- Tile 3: Storage shelf floor, dark concrete #5C5C5C
- Tile 4: Shoes department carpet, warm brown #6B5A4A
- Tile 5: Dress/clothing carpet, cool gray #5A5A6A
- Tile 6: Sport area floor mat, green gray #4A5A4A
- Tile 7: Simple table top view pixel art
- Tile 8: Potted indoor plant pixel art
- Tile 9: Information kiosk pixel art

Pixel art style, crisp edges, video game sprite.
```

---

### Batch 3: Decor & Fixtures
```
16x16 pixel art game tiles, arranged in 3x3 grid:
- Tile 1: ATM machine pixel art
- Tile 2: Vending machine pixel art
- Tile 3: Promotion booth stand pixel art
- Tile 4: Lost and found box pixel art
- Tile 5: Store news bulletin board pixel art
- Tile 6: Locker unit pixel art
- Tile 7: Claw machine game pixel art
- Tile 8: Wall/fence standard tile
- Tile 9: Decorative boundary wall tile

Pixel art style, crisp edges, video game sprite, muted colors.
```

---

## Manual Generation Commands

If using the API directly, generate individual tiles with prompts like:

```python
# Example: Generate lobby floor tile
payload = {
	"model": "image-01",
	"prompt": "16x16 pixel art tile: warm marble ceramic lobby floor, seamless tiling, muted tan brown #8B7355, pixel art style, crisp edges, video game sprite",
	"aspect_ratio": "16:9",
	"response_format": "base64",
	"n": 1
}
```

---

## Post-Processing

After generation:
1. Extract individual 16x16 tiles from the grid images
2. Ensure pixel-perfect edges (no anti-aliasing)
3. Convert to PNG format
4. Organize into TileSet layers in Godot editor
