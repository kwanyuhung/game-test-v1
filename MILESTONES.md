# Pixel Supermarket — Milestones

## Context
Current game: 18 floors, 128×50 tiles (ground), 190+ products, 6 AI shoppers, 3 checkout lanes.
Achieved: Multi-floor traversal, NPC system, commerce, mini-games, dynamic pricing, loyalty tiers, anti-theft, supplier system, and more.

---

## 🏗️ Phase 1 — Multi-Floor Infrastructure
**Goal:** Core architecture for vertical building traversal

| # | Task | Description |
|---|------|-------------|
| 1.1 | World redesign | Replace single-floor 96×50 with a 10-floor building. Each floor: 96×50 tiles. Ground = Floor 1. |
| 1.2 | Elevator system | Add elevator shafts (tiles) and an elevator car the player can enter. Call button → select floor. |
| 1.3 | Staircase system | Stairs between floors (tile-based up/down). Take 1-2 seconds to climb. |
| 1.4 | Floor navigation HUD | Show current floor (e.g. "Floor 3/10") and elevator/stair indicators on screen. |
| 1.5 | Floor transition | Seamless camera/world switch when boarding elevator or climbing stairs. |

**Acceptance:** Player can move between all 10 floors via elevator and stairs.

---

## 🛒 Phase 2 — Floor Layouts (18 Floors)
**Goal:** Each floor has a distinct theme and product mix

| Floor | Theme | Sections / Facilities |
|-------|-------|----------------------|
| **G** Ground | Entrance + Lobby | Information desk, WC, Elevator, Stairs, Mall directory |
| **1** | Fresh Market | Dairy, Produce, Bakery, Deli |
| **2** | Pantry & Dry Goods | Pantry, Canned goods, Condiments, Spices |
| **3** | Beverages | Drinks, Juice bar, Coffee/Tea |
| **4** | Snacks & Candy | Snacks, Chocolates, Ice cream |
| **5** | Frozen Foods | Frozen meals, Frozen veg, Ice cream freezer |
| **6** | Household | Cleaning supplies, Paper goods, Home care |
| **7** | Health & Beauty | Pharmacy, Cosmetics, Personal care |
| **8** | Toys & Play | Toy section, Play area (interactive), Kids zone |
| **9** | Staff Room (restricted) | Employee break room, Office (price management terminal) |
| **10** | Rooftop Café | Seating area, café counter, vending machines |

| # | Task | Description |
|---|------|-------------|
| 2.1 | Per-floor section definitions | Add `floor` field to `SectionDef`. Update layout for all 10 floors in `store_data.gd`. |
| 2.2 | Floor G — Lobby | Entrance tile at y=0. Directory sign showing floor map. WC accessible. |
| 2.3 | Floors 1-5 — Retail floors | Upper/lower section layout (same 96×50 grid per floor). Sections repeat or differ. |
| 2.4 | Floor 6-7 — Non-food floors | Adjusted shelf/fridge styling. Different product categories. |
| 2.5 | Floor 8 — Toy floor | Larger open area. Dedicated play zone tiles (interactive). Toy shelves. |
| 2.6 | Floor 9 — Staff floor | Locked door / "STAFF ONLY" tile. Player enters as staff mode toggle. |
| 2.7 | Floor 10 — Rooftop | Open seating area, café counter, ambient decorations. |

---

## 🚻 Phase 3 — Interactive Facilities
**Goal:** Beyond shopping — functional building facilities

| # | Task | Description |
|---|------|-------------|
| 3.1 | WC (Water Closet) | Unisex WC on Floor G (and Floor 8). Press E to enter a small WC room. No gameplay effect — just immersion. Door animation. |
| 3.2 | Play Area (Floor 8) | A gated zone with toy blocks. NPCs (kids) can "play" here — animation loop. |
| 3.3 | Information Desk (Floor G) | Press E to see a floating floor directory panel. |
| 3.4 | Mall Directory (Floor G) | Lists all floors and their themes. |
| 3.5 | Café Counter (Floor 10) | Buy coffee/snacks here. Special limited items. |
| 3.6 | Vending Machines (Floor 10 & G) | Dispense drinks/snacks for small cost. Coin or card. |

---

## 👥 Phase 4 — AI Customer Diversity
**Goal:** Realistic shopper demographics by age

| Age Group | Visual | Behavior Traits |
|-----------|--------|-----------------|
| Kid (5-12) | Short sprite, bright colors, small cart | Moves erratically, picks toys/sweets, wanders play area |
| Teen (13-19) | Taller sprite, casual clothes | Fast movement, phone in hand (sprite), grabs snacks |
| Adult (20-60) | Standard adult sprite | Normal pace, fills cart, uses checkout |
| Senior (60+) | Slower sprite, may use walking stick | Slow movement, takes time at sections, needs help at checkout |

| # | Task | Description |
|---|------|-------------|
| 4.1 | Age sprite variants | Create 4 age variants for NPC sprites (kid, teen, adult, senior). Pixel art style. |
| 4.2 | Age-based AI behavior | Kids → go to toys/sweets. Seniors → slow, avoid crowds. Teens → fast in/out. |
| 4.3 | Spawn distribution | Each floor spawns 2-4 NPCs appropriate to that floor's theme. |
| 4.4 | Family groups | 30% of kids spawn with a senior (grandparent) — paired AI movement. |
| 4.5 | Elder assistance | Seniors occasionally need help at checkout — flag triggers staff prompt. |

---

## 🧾 Phase 5 — Checkout Evolution
**Goal:** Multiple checkout approaches

| Type | Description |
|------|-------------|
| **Staffed Lane** | Standard checkout — human cashier NPC. One per floor where checkout exists. |
| **Self-Checkout** | Unattended kiosk. Player scans own items. 10% chance of "item not found" error. |
| **Express Lane** | Max 10 items. Fast lane. No packing. |
| **Scan & Go** | Staff member with handheld scanner walks with you — pay at end. |
| **Click & Collect** | Order on app → pickup counter (Floor G). Not implemented in MVP. |

| # | Task | Description |
|---|------|-------------|
| 5.1 | Checkout counter variants | Subclass `checkout_counter.gd` into staffed vs self-checkout types. |
| 5.2 | Express lane logic | Item count cap (10). Express lane sprite distinct from regular. |
| 5.3 | Self-checkout error simulation | Random "unexpected item in bagging area" events. Player must press E to dismiss. |
| 5.4 | Staffed checkout NPC | AI cashier NPC at staffed lanes. Animation: scan, bag, gesture. |
| 5.5 | Scan & Go staff role | Staff member walks with player, scans on the go. |
| 5.6 | Checkout floor distribution | Ground floor: all types. Floors 1-8: only self-checkout or express. |

---

## 👔 Phase 6 — Staff Role
**Goal:** Player can switch to staff mode and perform worker tasks

### Staff Mode
- Press `K` to toggle staff mode (requires being on Floor 9 or near staff area)
- Staff sprite variant (overalls / uniform)
- Cannot buy items while in staff mode

### Staff Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| Price Management | `E` at office terminal | Open price editor UI. Select product → edit name/price → save. |
| Checkout Assistance | `E` at staffed lane | Help senior NPCs with checkout. |
| Inventory Alert | Auto | Notify when a section is low stock (visual flair on shelf). |

| # | Task | Description |
|---|------|-------------|
| 6.1 | Staff mode toggle | Add `staff_mode` flag to player. Sprite swap to uniform. |
| 6.2 | Staff-only floor access | Floor 9 restricted. Door opens when in staff mode. |
| 6.3 | Price management terminal | On Floor 9. `E` opens a UI panel listing all products with editable price field. |
| 6.4 | Price change propagation | Updated prices reflect in catalog and section browse immediately. |
| 6.5 | Staff NPC counterpart | Hire a staff NPC that walks around cleaning / stocking shelves. |

---

## 📊 Phase 7 — Polish & Systems
**Goal:** Game feel, balance, and edge cases

| # | Task | Description |
|---|------|-------------|
| 7.1 | Elevator music / ambient sound | Different bgm per floor theme. |
| 7.2 | Floor ambiance | Lighting color shift per floor (warm ground, cool frozen, etc.) |
| 7.3 | NPC pathfinding upgrade | NPCs avoid congestion, use elevator, don't stack. |
| 7.4 | Cart theft detection | If NPC walks out without paying → alarm sound, guard NPC chases. |
| 7.5 | Shopping cart physics | Carts stack, block paths, make noise when pushed. |
| 7.6 | Receipt persistence | Save receipts to file. Can view past purchases. |
| 7.7 | Day/night cycle | Exterior windows change brightness over time (cosmetic). |

---

## 🚀 Phase 8 — Launch
**Goal:** Ship the full 10-floor experience

| # | Task |
|---|------|
| 8.1 | Full test suite — all floors, all sections, all checkout types, staff mode |
| 8.2 | Performance audit — 60fps with 20+ NPCs across multiple floors |
| 8.3 | Tutorial — first-time player guided tour on Floor G |
| 8.4 | Godot export settings — Windows executable |
| 8.5 | GitHub release + Telegram notification |

---

## Suggested Order
```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7 → Phase 8
   ↑          ↑          ↑          ↑          ↑          ↑
 (Foundation) (Content) (Facilities) (NPCs)   (Checkout) (Staff)
```

**Recommended start:** Phase 1 first so all subsequent work builds on the multi-floor engine.

---

## Out of Scope (v1)
- Online multiplayer
- Persistent world (save/load between sessions)
- In-app purchases
- Mobile export
