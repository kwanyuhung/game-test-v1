# Pixel Supermarket — SPEC.md

## 1. Project Overview

**Name:** Pixel Supermarket  
**Type:** 2D interactive supermarket simulation  
**Core:** Walk through a cozy pixel-art supermarket, browse fully-stocked sections, pick up items into your cart, and checkout.  
**Style:** Warmart / Kairosoft — warm lighting, charming pixel art, cozy atmosphere.  
**Scale:** 6 interactive sections, 200+ products, 8 AI shoppers  
**Engine:** Godot 4.6 (Forward+, 2D, pixel art)

---

## 2. Visual & Rendering Specification

### Resolution & Scaling
- **Game:** 320×180 px (16:9)  
- **Scale:** Integer倍缩放，全屏填充  
- **Pixel filter:** Snap 2D Transforms To Pixel = ON

### Camera
- Player follows with smooth lerp (0.1 factor)
- 3× zoom (shows ~106×60 tiles)
- Constrained to world bounds

### Color Palette
| Element | Hex |
|---|---|
| Floor | #2a2a2e |
| Floor accent tile | #363640 |
| Warm wood shelves | #8b7355 |
| Shelf highlight | #a08060 |
| Player | #e8c170 |
| Cart | #c8c8d0 |
| Refrigerator body | #b0c8e0 |
| Refrigerator light | #80d0ff |
| Produce glow | #90d060 |
| Bakery warm | #f0c070 |
| Checkout | #7a6a8a |
| UI background | #1a1a1f (alpha 0.92) |
| UI text | #f0f0e8 |
| UI accent | #e8c170 |

### Sprite Generation
All sprites are procedural via `pixel_art_generator.gd` — no external assets.

---

## 3. Section System — Core Feature

Each **Section** is a distinct zone with:
- Unique visual treatment (lighting, shelf style)
- A fixed set of **slots** holding **Products**
- An **interaction zone** — player enters to "browse"
- A **Section Browse UI** — shows ALL products in that section
- Product **respawn** after pickup

### Sections (6 total)

```
┌─────────────────────────────────────────────────┐
│  ENTRANCE / EXIT                                │
│  Player starts here                              │
├─────────┬──────────┬──────────┬────────────────┤
│DAIRY    │PRODUCE   │BAKERY    │ DRINKS         │
│Chiller  │Open stall│Shelves   │ Glass cooler   │
│(Fridge) │(Warm)    │(Warm)    │ (Cold/Blue)    │
├─────────┼──────────┼──────────┼────────────────┤
│SNACKS   │MEAT/DELI │PANTRY    │ FROZEN         │
│Tall     │Counter   │Shelves   │ Freezer chest  │
│shelves  │(Red)     │(Brown)   │ (Cold/White)   │
├─────────┴──────────┴──────────┴────────────────┤
│  CHECKOUT COUNTERS × 3                          │
└─────────────────────────────────────────────────┘
```

### Interaction Model
1. Player walks near a section → zone label appears: `[E] Browse SECTION NAME`
2. Player presses `E` → **Section Browse Panel** opens
3. Panel shows a **grid of ALL products** in that section (page if many)
4. Player **clicks a product** or presses **number key** → item added to cart
5. Panel stays open so player can keep shopping
6. Press `ESC` or `E` again → close panel, back to walking

### Section Browse Panel
- Dark overlay (0.85 alpha) over game world
- Header: Section name + icon
- Product grid: 4 columns × scrollable rows
- Each product: 32×32 sprite, name, price
- Highlight on hover/keyboard select
- Cart count shown at bottom
- `[E] Add to Cart` / `[ESC] Close`

---

## 4. Product Data

200+ products across 6 sections × sub-categories:

| Section | Sub-categories | Products |
|---|---|---|
| Produce | Fruits, Vegetables, Fresh Herbs | 35 |
| Dairy | Milk, Cheese, Yogurt, Butter/Cream | 28 |
| Bakery | Bread, Cakes, Pastries, Buns | 24 |
| Drinks | Water, Juice, Soda, Tea, Coffee, Energy | 32 |
| Snacks | Chips, Cookies, Candy, Chocolate, Nuts | 30 |
| Meat/Deli | Chicken, Beef, Pork, Fish, Ham/Sausage | 24 |
| Pantry | Rice, Pasta, Cereal, Condiments, Oil, Soup | 40 |
| Frozen | Ice Cream, Frozen Meals, Frozen Veg | 22 |

Each product:
```
Product {
  id: String
  name: String (localized feel)
  price: float
  color: Color
  shape: int (0-7, for pixel art)
  section: String
  subcategory: String
}
```

---

## 5. Pixel Art Sprites (Programmatic)

### Player (16×16)
- Warm yellow body (#e8c170)
- Simple 2-frame walk animation (bobbing)
- Faces movement direction (flip_h)

### Shopping Cart (20×16)
- Silver/gray metal frame
- Red handle accent
- Shows stacked items on top when cart has items

### Section Backgrounds
- **Refrigerator:** Light blue-gray glass door, white interior, cold glow
- **Produce:** Green-tinted floor, warm overhead lamp glow
- **Bakery:** Warm orange/brown, golden floor
- **Shelves:** Wood brown, 3D top highlight

### Products (8×8 base)
7 shapes: round, rectangle, bottle, can, box, tub, tall bottle

---

## 6. AI Customers

8 NPCs wandering the store:
- Procedural sprite (head + upper + lower body)
- Walk → pause → walk loop
- Avoid walls/shelves (simple boundary check)
- Walking bob animation

---

## 7. Interaction Specification

### Controls
| Key | Action |
|---|---|
| WASD / Arrows | Move |
| E | Interact (browse section at zone / confirm) |
| ESC | Close panel |
| Tab | Toggle cart inventory |
| 1-9 | Quick-add product by number (in section view) |

### Cart
- Holds up to **30 items**
- Follows player (rubber-band offset)
- Cart icon + count in HUD
- Cart blocks narrow passages (player must route around)

### Checkout
- 3 checkout lanes at bottom
- Walk to counter + press `E`
- Receipt shows: items, subtotal, tax (6%), total
- "THANK YOU!" → cart clears

---

## 8. HUD Layout

- **Top-left:** Cart icon + item count
- **Top-center:** Current section name (when inside zone)
- **Bottom-center:** Context action prompt `[E] Browse DRINKS`
- **Bottom-right:** Mini-map placeholder (section names only)

---

## 9. File Structure

```
game-test/
├── project.godot
├── SPEC.md
├── scenes/
│   ├── main.tscn
│   ├── player.tscn
│   ├── section.tscn          # Generic section template
│   ├── checkout_lane.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── section_browse.tscn
│       ├── cart_panel.tscn
│       └── checkout_screen.tscn
├── scripts/
│   ├── main.gd               # World builder, spawns sections
│   ├── player.gd             # Movement + cart following
│   ├── shopping_cart.gd
│   ├── section.gd            # Section logic + interaction zone
│   ├── checkout_lane.gd
│   ├── product_data.gd       # 200+ products
│   ├── product.gd            # Product class
│   ├── pixel_art_generator.gd
│   ├── npc_controller.gd
│   ├── npc_sprite.gd
│   └── ui/
│       ├── hud.gd
│       ├── section_browse.gd
│       ├── cart_panel.gd
│       └── checkout_screen.gd
└── assets/
	└── (all procedural — no external files)
```

---

## 10. Implementation Priority

### Phase 1 — Foundation
- [ ] Restructure world grid with 6 section zones
- [ ] Section browse panel UI (grid of all products)
- [ ] E to open section view, click to add to cart
- [ ] Proper section backgrounds (fridge glass, warm lighting, etc.)
- [ ] Player inside-zone detection

### Phase 2 — Cart & Checkout
- [ ] Cart follows player
- [ ] Cart panel with item list + total
- [ ] Checkout receipt screen
- [ ] Cart respawns products over time

### Phase 3 — Polish
- [ ] 8 AI customers
- [ ] Mini-map
- [ ] Sound effects (optional)
- [ ] Product descriptions on hover
