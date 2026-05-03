# Supermarket Prototype — SPEC.md

## 1. Project Overview

**Name:** Pixel Supermarket  
**Type:** 2D interactive simulation / prototype  
**Core:** A top-down pixel art supermarket where the player walks around, picks up items with a shopping cart, and checks out.  
**Scale:** 12 aisles, 200+ products  
**Target:** Extendable prototype — modular aisle/product system for future game dev work.  
**Engine:** Godot 4.6 (2D scene, pixel art aesthetic)

**Image Generation Note:** The `image_generate` tool (MiniMax) is unavailable in the current sandbox environment due to a system-level `fsync` restriction (EPERM). All pixel art is generated programmatically via `pixel_art_generator.gd` — this produces consistent, deterministic sprites without external dependencies.

---

## 2. Visual & Rendering Specification

### Resolution & Scaling
- **Game resolution:** 320×180 (16:9, very low-res for crisp pixel art)
- **Viewport scaling:** `stretch_mode = "integer"` — renders at integer scale, fullscreen
- **Pixel art filter:** `Snap 2D Transforms To Pixel` = ON

### Scene Setup
- **Camera:** Follows player (smooth lerp, no rotation)
- **Lighting:** Flat shading, no dynamic lights — pure sprite-based
- **Environment:** Dark charcoal floor (#2a2a2e), supermarket tiles

### Visual Style — Pixel Art Palette
| Element | Color |
|---|---|
| Floor | #2a2a2e (dark charcoal) |
| Floor tile lines | #363640 |
| Shelf / Aisle | #8b7355 (warm wood brown) |
| Shelf top highlight | #a08060 |
| Player | #e8c170 (warm yellow, stands out) |
| Cart | #c0c0c0 (silver) |
| Products — produce | #5a9c4a (green) |
| Products — dairy | #e8e8a0 (cream) |
| Products — drinks | #4a8cc7 (blue) |
| Products — snacks | #d48a3a (orange) |
| Products — meat | #c05050 (red) |
| Checkout desk | #7a6a8a (muted purple) |
| UI background | #1a1a1f |
| UI text | #f0f0e8 |

### Sprite Generation
All sprites generated procedurally via `Image` + `Texture2D` — no external assets required.

- **Tile size:** 16×16 pixels (logical)
- **Player sprite:** 16×16 yellow figure
- **Cart sprite:** 20×16
- **Product sprites:** 8×8 or 12×12 items on shelf
- **Shelf unit:** Multi-tile, 16px per cell

---

## 3. Supermarket Layout

### Grid
- Cell size: 16×16 game pixels
- World size: 80×60 cells = 1280×960 game pixels
- Camera view: ~40×23 cells visible at 320×180

### Zones
```
┌─────────────────────────────────────────────────┐
│  Entrance / Exit                                │
│  [PLAYER START]                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│  AISLE A        AISLE B        AISLE C           │
│  [Shelves]     [Shelves]      [Shelves]          │
│                                                  │
│  AISLE D        AISLE E        AISLE F           │
│  [Shelves]     [Shelves]      [Shelves]          │
│                                                  │
├─────────────────────────────────────────────────┤
│  CHECKOUT COUNTERS (3 registers)                 │
│  [REG1] [REG2] [REG3]                           │
└─────────────────────────────────────────────────┘
```

### Aisle Contents (extendable via data)
| Aisle | Products | Color Tag |
|---|---|---|
| A | Apples, Bananas, Carrots, Lettuce | Green |
| B | Milk, Cheese, Yogurt, Butter | Cream |
| C | Cola, Juice, Water, Tea | Blue |
| D | Chips, Cookies, Candy, Chocolate | Orange |
| E | Chicken, Beef, Pork, Fish | Red |
| F | Bread, Rice, Pasta, Cereal | Brown |

### Checkout
- 3 checkout lanes
- Each has a conveyor belt and register
- Player walks to counter → press interact → cart contents converted to receipt → total shown

---

## 4. Interaction Specification

### Player Controls
| Input | Action |
|---|---|
| W / ↑ | Move up |
| S / ↓ | Move down |
| A / ← | Move left |
| D / → | Move right |
| E | Interact (pick up item / checkout) |
| Tab | Open/close cart inventory UI |
| ESC | Pause / resume |

### Movement
- Player moves at 80 px/sec (5 cells/sec)
- Cart moves with player, offset behind
- Player cannot walk through shelves or walls
- Smooth movement, 8-directional

### Item Pickup
1. Player walks adjacent to a shelf (within 1 tile)
2. The nearest product highlights (white outline)
3. Press `E` → item is removed from shelf, added to cart
4. Shelf slot becomes empty (visual: darker square)
5. Product respawns after 30 seconds

### Cart System
- Cart holds up to 20 items
- Cart follows player with a fixed offset (1 tile behind in movement direction)
- Cart has a visible list of items (Tab UI)
- Cart is blocked by shelves — player must navigate around

### Checkout
1. Player walks to any checkout counter
2. Press `E` at register
3. Cart UI opens → receipt shows item list + total
4. Press `E` again → items cleared, "THANK YOU!" message
5. Cart is now empty

---

## 5. UI Specification

### HUD (Always visible)
- Top-left: Cart item count badge (e.g., "🛒 3")
- Top-right: Current zone name (e.g., "AISLE A — PRODUCE")
- Bottom: Interaction prompt when near item (e.g., "[E] Pick up Apple — $1.50")

### Cart Inventory (Tab)
- Dark semi-transparent panel, full screen overlay
- Grid of item icons (64×64 display per item)
- Item name + price per row
- Total at bottom
- "[E] Checkout" or "[Tab] Close"

### Checkout Screen
- Full receipt style
- Item list with prices
- Subtotal / Tax / Total
- "THANK YOU FOR SHOPPING!" / Press E to continue

---

## 6. Architecture — Extensibility

### Data-Driven Product System
```gdscript
# Products defined as a Resource / Dictionary
# Easy to add new products without changing code:
#   add_product("aisle_a", {"name": "Avocado", "price": 2.99, "color": Color(0.4, 0.8, 0.3)})
```

### Aisle Module
- Each aisle is a `SupermarketAisle` node
- Accepts a product list as a parameter
- Handles respawning, empty states

### Cart Module
- `ShoppingCart` node attached to player
- Inventory is just an Array of product IDs
- Serializable — could save/load

---

## 7. File Structure

```
game-test/
├── project.godot
├── SPEC.md
├── scenes/
│   ├── main.tscn              # Main game scene
│   ├── player.tscn            # Player + cart combined
│   ├── supermarket_aisle.tscn # Reusable aisle template
│   ├── checkout_counter.tscn  # Checkout lane
│   └── ui/
│       ├── cart_panel.tscn
│       ├── checkout_screen.tscn
│       └── hud.tscn
├── scripts/
│   ├── main.gd
│   ├── player.gd
│   ├── shopping_cart.gd
│   ├── supermarket_aisle.gd
│   ├── product_sprite.gd      # Generates pixel art product textures
│   ├── checkout_counter.gd
│   └── ui/
│       ├── cart_panel.gd
│       ├── checkout_screen.gd
│       └── hud.gd
└── assets/
    └── (all generated via code, no external files)
```

---

## 8. Acceptance Criteria

- [x] Player can walk in 8 directions, cart follows
- [x] Player cannot walk through shelves/walls
- [x] Walking adjacent to product shows interaction prompt
- [x] Pressing E picks up product → appears in cart
- [x] Cart inventory shows all items + total price
- [x] Player can go to checkout, see receipt, complete purchase
- [x] Cart empties after checkout
- [x] Products respawn after 30s
- [x] Pixel art aesthetic — no blurry scaling
- [x] Runs at stable 60 FPS
- [x] Extensible: adding a new product = editing data, not code
