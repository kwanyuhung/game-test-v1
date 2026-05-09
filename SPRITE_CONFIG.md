# Sprite & Asset Configuration Guide
# For artists implementing sprites and images

## Grid System

| Property | Value | Description |
|----------|-------|-------------|
| **CELL_SIZE** | 16 pixels | Base unit for tile-based positioning |
| **TILE_WIDTH** | 16 pixels | Standard tile width |
| **TILE_HEIGHT** | 16 pixels | Standard tile height |
| **MAP_WIDTH** | 100 tiles | Total map width (1600 pixels) |
| **MAP_HEIGHT_PER_FLOOR** | 50 tiles | Floor height (800 pixels) |

---

## Player Character

| Property | Value | Description |
|----------|-------|-------------|
| **PLAYER_WIDTH** | 12 pixels | Player sprite width |
| **PLAYER_HEIGHT** | 24 pixels | Player sprite height |
| **PLAYER_BOUNDING_X** | 8 pixels | Collision box center offset X |
| **PLAYER_BOUNDING_Y** | 0 pixels | Collision box center offset Y |
| **PLAYER_BOUNDING_W** | 10 pixels | Collision box width |
| **PLAYER_BOUNDING_H** | 20 pixels | Collision box height |
| **NPC_WIDTH** | 12 pixels | NPC sprite width |
| **NPC_HEIGHT** | 28 pixels | NPC sprite height |

---

## Elevator

| Property | Value | Description |
|----------|-------|-------------|
| **SHAFT_X** | 6 tiles (96 px) | Elevator shaft X position |
| **CAR_WIDTH** | 14 tiles (224 px) | Elevator car width |
| **CAR_HEIGHT** | 10 tiles (160 px) | Elevator car height |
| **DOOR_WIDTH** | 5 tiles (80 px) | Elevator door width |
| **ELEVATOR_ZONE_X** | 6 tiles | Zone left edge |
| **ELEVATOR_ZONE_W** | 14 tiles | Zone width |
| **ELEVATOR_ZONE_H** | 40-47 tiles | Zone height (per floor) |

---

## Stairs

| Property | Value | Description |
|----------|-------|-------------|
| **STAIRS_ZONE_X** | 20 tiles | Stairs zone X position |
| **STAIRS_ZONE_W** | 6 tiles | Stairs zone width |
| **STAIRS_ZONE_H** | 40-47 tiles | Stairs zone height |

---

## Sections (Shopping Areas)

### Standard Section Bounds

| Property | Value | Description |
|----------|-------|-------------|
| **SECTION_MIN_W** | 2 tiles | Minimum section width |
| **SECTION_MIN_H** | 2 tiles | Minimum section height |
| **SECTION_PROXIMITY** | 8 tiles | Detection radius for interaction |

### Floor 1 (Shoes) Sections

| Section ID | X | Y | W | H | Description |
|------------|---|---|---|---|-------------|
| shoes_ladies | 2 | 3 | 24 | 16 | Ladies Shoes |
| shoes_mens | 28 | 3 | 24 | 16 | Mens Shoes |
| shoes_kids | 54 | 3 | 24 | 16 | Kids Shoes |
| shoes_sport | 2 | 21 | 38 | 16 | Sport Shoes |
| shoes_sandals | 42 | 21 | 36 | 16 | Sandals |

### Floor 2 (Fashion) Sections

| Section ID | X | Y | W | H | Description |
|------------|---|---|---|---|-------------|
| ladies_wear | 2 | 3 | 26 | 18 | Ladies Wear |
| mens_wear | 30 | 3 | 26 | 18 | Mens Wear |
| kids_wear | 58 | 3 | 20 | 18 | Kids Wear |
| activewear | 2 | 23 | 38 | 14 | Activewear |
| formal_wear | 42 | 23 | 36 | 14 | Formal Wear |

### Floor 3 (Sports) Sections

| Section ID | X | Y | W | H | Description |
|------------|---|---|---|---|-------------|
| gym | 2 | 3 | 24 | 16 | Gym Equipment |
| sports_gear | 28 | 3 | 24 | 16 | Sports Gear |
| team_sports | 54 | 3 | 24 | 16 | Team Sports |
| activewear | 2 | 21 | 38 | 16 | Activewear |
| fitness | 42 | 21 | 36 | 16 | Fitness |

---

## Zone Types & Colors

### Zone Bounds (from floor_config_data.json)

| Zone Type | Typical W | Typical H | Description |
|-----------|-----------|-----------|-------------|
| ZONE_COMMON | 78 | 38 | Common area |
| ZONE_LOBBY | 80 | 13 | Lobby area |
| ZONE_SHOES_RACK | 24-38 | 16 | Shoe display area |
| ZONE_DRESS_RACK | 20-38 | 14-18 | Clothing display |
| ZONE_SPORT_AREA | 24-38 | 16 | Sports equipment |
| ZONE_FOOD_STALL | 14 | 8 | Food stall |
| ZONE_CHECKOUT | 8 | 4 | Checkout counter |
| ZONE_AD | 4 | 5-6 | Advertisement display |
| ZONE_WC | 12 | 7 | Restroom |
| ZONE_ATM | 4 | 5 | ATM machine |
| ZONE_VENDING | 10 | 10 | Vending machine |
| ZONE_INFO_DESK | 16 | 7 | Information desk |
| ZONE_CUSTOMER_SERVICE | 16 | 7 | Customer service |
| ZONE_LOYALTY_KIOSK | 14 | 7 | Loyalty signup |
| ZONE_GIFT_WRAP | 14 | 7 | Gift wrapping |
| ZONE_DIGITAL_KIOSK | 8 | 7 | Digital directory |
| ZONE_PROMO_BOOTH | 12 | 8 | Promotion booth |
| ZONE_LOST_FOUND | 12 | 7 | Lost & found |
| ZONE_STORE_NEWS | 12 | 7 | Store news |
| ZONE_ELEVATOR | 14 | 40-47 | Elevator shaft |
| ZONE_STAIRS | 6 | 40-47 | Stairs |

---

## Food Stalls (Floor 0)

| Stall ID | X | Y | W | H | Description |
|----------|---|---|---|---|-------------|
| jp_ramen | 2 | 3 | 14 | 8 | Japanese Ramen |
| jp_sushi | 18 | 3 | 14 | 8 | Japanese Sushi |
| jp_takoyaki | 34 | 3 | 14 | 8 | Japanese Takoyaki |
| thai | 50 | 3 | 14 | 8 | Thai Food |
| indian | 66 | 3 | 14 | 8 | Indian Food |
| chinese | 2 | 15 | 14 | 8 | Chinese Food |
| korean | 18 | 15 | 14 | 8 | Korean Food |
| turkish | 34 | 15 | 14 | 8 | Turkish Food |
| vietnamese | 50 | 15 | 14 | 8 | Vietnamese Food |
| italian | 66 | 15 | 14 | 8 | Italian Food |
| mexican | 2 | 25 | 14 | 8 | Mexican Food |
| drinks | 18 | 25 | 14 | 8 | Drinks |

---

## Checkout Counters

| Property | Value | Description |
|----------|-------|-------------|
| **CHECKOUT_WIDTH** | 8 tiles (128 px) | Counter width |
| **CHECKOUT_HEIGHT** | 4 tiles (64 px) | Counter height |
| **CHECKOUT_Y** | 40 | Y position on floor |
| **CHECKOUT_SLOT_W** | 3 tiles | Payment slot width |
| **CHECKOUT_SLOT_H** | 3 pixels | Payment slot height |

---

## Parking Lot (Floor 0)

| Property | Value | Description |
|----------|-------|-------------|
| **PARKING_ZONE_X** | 0 | Parking zone X |
| **PARKING_ZONE_Y** | 35 | Parking zone Y |
| **PARKING_ZONE_W** | 22 | Parking zone width |
| **PARKING_ZONE_H** | 14 | Parking zone height |
| **SPAWN_POINT_X** | 3 tiles | Player spawn X |
| **SPAWN_POINT_Y** | 40 tiles | Player spawn Y |

---

## Interaction Bubbles & Prompts

| Property | Value | Description |
|----------|-------|-------------|
| **BUBBLE_OFFSET_Y** | -40 pixels | Bubble above player |
| **PROMPT_Y** | varies | Prompt label Y position |
| **INTERACTION_RADIUS** | 8 tiles | General interaction distance |
| **ELEVATOR_RADIUS** | 15 tiles | Elevator detection radius |
| **NPC_CHAT_RADIUS** | 8 tiles | NPC chat detection radius |

---

## Floor Layout

| Floor | Label | Theme | Y Offset (px) |
|-------|-------|-------|---------------|
| 0 | G | Lobby/Fresh Market | 32 * 16 = 512 |
| 1 | 1 | Shoes | 22 * 16 = 352 |
| 2 | 2 | Fashion | 12 * 16 = 192 |
| 3 | 3 | Sports | 2 * 16 = 32 |

**Note**: Floors stack vertically. Camera follows player, showing ~16 tiles vertically.

---

## Sprite Sheet Guidelines

### Character Sprites
- Player: 12x24 pixels (walk cycle ~4 frames)
- NPC: 12x28 pixels (with variation for different roles)
- Staff uniform colors differentiate roles

### Tile-based Objects
- All positions snap to 16x16 grid
- Shelves, racks, counters align to tile boundaries
- Collision boxes typically smaller than visual sprite

### Section Sprites
- Sections span multiple tiles (e.g., 24x16 = 384x256 pixels)
- Include shelf rows and product displays
- Glow/sign sprite above section

### UI Elements
- Interaction bubble: ~40x20 pixels
- Prompt background: ~300x20 pixels
- Floor indicator: ~30x20 pixels

---

## Color Palette (from store_data.gd)

### Section Floor Colors
| Style | RGB (0-1) | Description |
|-------|-----------|-------------|
| FRIDGE | [0.65, 0.80, 0.90] | Cool blue-white |
| PRODUCE | [0.70, 0.85, 0.60] | Fresh green |
| BAKERY | [0.90, 0.80, 0.65] | Warm brown |
| SHELF | [0.75, 0.70, 0.65] | Neutral tan |
| DELI | [0.90, 0.75, 0.70] | Warm pink |
| FREEZER | [0.75, 0.85, 0.95] | Ice blue |
| SHOES_RACK | [0.70, 0.60, 0.55] | Brown gray |
| DRESS_RACK | [0.75, 0.65, 0.70] | Mauve |
| SPORT_AREA | [0.60, 0.75, 0.70] | Athletic green |

---

## Implementation Notes

1. **All positions in code use 16x16 tile grid**
2. **Collision detection uses smaller boxes than visual sprites**
3. **Zones in floor_config_data.json define interaction areas**
4. **Sections emit signals when player enters/exits their Area2D**
5. **Elevator and stairs are global objects, not per-floor**
6. **Camera follows player with ~16 tile vertical view**
