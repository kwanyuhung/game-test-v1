"""
Floor Tile Generator using MiniMax Image Generation API

This script generates pixel art floor tiles based on the specifications
in ARTIST_README.md for the Pixel Supermarket game.

Requirements:
    pip install requests python-dotenv Pillow

Usage:
    python generate_tiles.py

Environment:
    Set MINIMAX_API_KEY in your environment or .env file
"""

import os
import base64
import requests
from pathlib import Path
from dotenv import load_dotenv
from PIL import Image
import io

load_dotenv()

API_URL = "https://api.minimaxi.com/v1/image_generation"
API_KEY = os.environ.get("MINIMAX_API_KEY")

OUTPUT_DIR = Path(__file__).parent / "generated_tiles"
# Use 1:1 aspect ratio with 64x64 pixel tiles for AAA quality
TILE_SIZE = "1:1"
TILE_PIXELS = 16  # 16x16 pixel tiles (matches CELL_SIZE in game code)


def generate_tile(prompt: str, filename: str, style_type: str = None) -> str:
    """Generate a single tile and save it at 16x16 pixels."""
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "image-01",
        "prompt": prompt,
        "width": 512,
        "height": 512,
        "response_format": "base64",
    }

    response = requests.post(API_URL, headers=headers, json=payload)
    response.raise_for_status()

    data = response.json()["data"]["image_base64"]
    image_bytes = base64.b64decode(data[0])

    # Open image and resize to 16x16 with nearest-neighbor for pixel art
    img = Image.open(io.BytesIO(image_bytes))
    img = img.resize((TILE_PIXELS, TILE_PIXELS), Image.Resampling.NEAREST)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    filepath = OUTPUT_DIR / filename
    img.save(filepath, "PNG")

    print(f"Generated: {filename} ({TILE_PIXELS}x{TILE_PIXELS} pixel art)")
    return str(filepath)


def generate_pixel_art_tile(tile_name: str, description: str, color_hex: str = None) -> str:
    """Generate a high-quality 64x64 pixel art tile with specific prompt."""
    base_prompt = f"""
    64x64 pixel art tile, {description}.
    AAA game quality pixel art, highly detailed, professional game asset.
    Crisp clean pixel edges, no anti-aliasing, proper dithering.
    Seamless tiling texture, natural material look.
    Realistic indoor mall or supermarket flooring material.
    {f'Color palette: {color_hex}.' if color_hex else ''}
    Professional game sprite, clean and detailed.
    """.strip()

    filename = f"{tile_name}.png"
    return generate_tile(base_prompt, filename)


# ============================================================
# FLOOR LAYER TILES (Layer 0)
# ============================================================

FLOOR_TILES = [
    ("floor_lobby", "Polished marble lobby floor, light beige cream marble texture with subtle veining, indoor mall, glossy reflective surface, premium AAA game quality pixel art", "#E8E0D8"),
    ("floor_common", "Ceramic tile flooring, light warm gray with subtle speckle pattern, shopping mall corridor, clean polished surface, AAA game quality pixel art", "#C8C4C0"),
    ("floor_warehouse", "Industrial concrete floor, medium gray with subtle crack texture, warehouse storage area, matte finish, AAA game quality pixel art", "#909090"),
    ("floor_food_court", "Warm tan sandstone tile, food court dining area, slightly textured non-slip surface, mall flooring, AAA game quality pixel art", "#D4C4A8"),
    ("floor_wc", "White ceramic bathroom tile, clean restroom floor, subtle grid pattern, public toilet flooring, AAA game quality pixel art", "#E0E8E8"),
    ("floor_parking", "Dark asphalt parking lot, subtle aggregate texture, indoor parking garage, realistic asphalt, AAA game quality pixel art", "#606060"),
    ("floor_rooftop", "Stone patio tile, outdoor rooftop plaza, light beige gray, subtle texture, outdoor mall, AAA game quality pixel art", "#C8C0B0"),
    ("floor_pet_adoption", "Light beige laminate flooring, pet friendly area, subtle wood grain, easy clean, warm tone, AAA game quality pixel art", "#D8D0C0"),
    ("floor_truck_dock", "Heavy duty concrete dock, dark gray with yellow safety line markings, loading dock, industrial texture, AAA game quality pixel art", "#707070"),
    ("floor_forklift", "Industrial epoxy floor, medium gray with subtle texture, forklift working area, warehouse interior, AAA game quality pixel art", "#888080"),
    ("floor_conveyor", "Metal plate floor, silver gray with bolt pattern, conveyor belt area, industrial steel, AAA game quality pixel art", "#A0A0A0"),
    ("floor_storage_shelf", "Industrial concrete, dark gray with pallet marks, storage room, warehouse shelving area, AAA game quality pixel art", "#686868"),
    ("floor_shoes", "Soft carpet flooring, warm brown with subtle pattern, shoes retail section, comfortable feel, AAA game quality pixel art", "#A08070"),
    ("floor_dress", "Luxury carpet, cool gray with subtle texture, fashion retail section, elegant clothing store, AAA game quality pixel art", "#909898"),
    ("floor_sport", "Rubber mat flooring, medium green gray, sports equipment area, gym texture, non-slip surface, AAA game quality pixel art", "#808878"),
]

# ============================================================
# DECORATION LILES (Layer 2)
# ============================================================

DECOR_TILES = [
    ("table", "Round dining table top view, light oak wood grain, mall food court, realistic texture, AAA game quality pixel art", "#C8A878"),
    ("plant", "Decorative potted palm plant, indoor mall decoration, green leaves in white pot, vibrant well-lit, AAA game quality pixel art", "#50A060"),
    ("kiosk", "Modern digital information kiosk, sleek white frame with bright screen, mall directory, AAA game quality pixel art", "#E8F0F8"),
    ("atm", "Modern ATM machine, white and blue colors, sleek banking terminal, clear display screen, AAA game quality pixel art", "#B0C8E0"),
    ("vending_machine", "Colorful vending machine with snacks visible, glass front showing products, bright LED display, AAA game quality pixel art", "#E0A870"),
    ("promo_booth", "Colorful promotional booth stand, event marketing kiosk, bright banners and signage, mall advertisement, AAA game quality pixel art", "#F0B080"),
]


def generate_all_floor_tiles():
    """Generate all floor layer tiles."""
    print("\n=== Generating Floor Tiles ===\n")
    for tile_name, description, color in FLOOR_TILES:
        try:
            generate_pixel_art_tile(tile_name, description, color)
        except Exception as e:
            print(f"Failed to generate {tile_name}: {e}")


def generate_all_decor_tiles():
    """Generate all decoration tiles."""
    print("\n=== Generating Decor Tiles ===\n")
    for item in DECOR_TILES:
        tile_name = item[0]
        description = item[1]
        try:
            generate_pixel_art_tile(tile_name, description)
        except Exception as e:
            print(f"Failed to generate {tile_name}: {e}")


def generate_tile_atlas():
    """Generate a single atlas image containing all tiles."""
    print("\n=== Generating Tile Atlas ===\n")

    atlas_prompt = """
    Create a pixel art tile sheet (sprite sheet) containing these floor tiles arranged in a grid:
    Row 1: lobby floor, common walkway, warehouse floor, food court floor, wc floor, parking floor
    Row 2: rooftop patio, pet area, truck dock, forklift zone, conveyor belt, storage shelf
    Row 3: shoes carpet, dress carpet, sport mat, table, plant, kiosk
    Pixel art style, crisp edges, muted earth tones.
    Clean sprite sheet with clear tile boundaries.
    Video game asset style.
    """.strip()

    try:
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": "image-01",
            "prompt": atlas_prompt,
            "width": 512,
            "height": 512,
            "response_format": "base64",
        }
        response = requests.post(API_URL, headers=headers, json=payload)
        response.raise_for_status()

        data = response.json()["data"]["image_base64"]
        image_bytes = base64.b64decode(data[0])

        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        filepath = OUTPUT_DIR / "tile_atlas.png"
        with open(filepath, "wb") as f:
            f.write(image_bytes)

        print(f"Generated: tile_atlas.png")
    except Exception as e:
        print(f"Failed to generate atlas: {e}")


if __name__ == "__main__":
    if not API_KEY:
        print("Error: MINIMAX_API_KEY environment variable not set")
        print("Set it with: export MINIMAX_API_KEY=your_key")
        exit(1)

    print("Floor Tile Generator for Pixel Supermarket")
    print("=" * 50)

    generate_all_floor_tiles()
    generate_all_decor_tiles()
    generate_tile_atlas()

    print("\n=== Complete! ===")
    print(f"Tiles saved to: {OUTPUT_DIR}")
