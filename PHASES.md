# 🏪 Supermarket — Phases Roadmap

## Phase 1 ✅ Core World
Basic supermarket with 8 sections, player movement, section browsing.

## Phase 2 ✅ Commerce
Food stalls (12 cuisines), shopping cart, checkout receipts, Telegram bot.

## Phase 3 ✅ NPC System
Full NPC characters — 7 staff roles, 9 customer group types, customizable appearances (hair, makeup, glasses, accessories, shoes), babies in strollers, groups moving together.

## Phase 3b ✅ Chat & Pet Floor
- **Chat**: Press C near any NPC → chat panel opens → type messages → AI responds contextually. NPCs also chat with each other autonomously (proximity-based, every ~15s).
- **Pet Paradise (Floor 11)**: Adoption corner with dog/cat/rabbit in kennels, pet food shelves, 25+ pet products.

## Phase 4 ✅ Time & Lighting
24-hour game clock. Store opens 06:00, closes 23:00. Floor lighting changes by time of day. Customer spawn rate varies with time. Staff shift schedules.

## Phase 5 ✅ Parking Lot & Vehicles
Ground floor parking zone, parked NPC cars, parking attendant, player can see slot numbers.

## Phase 6 ✅ 24-Hour Ops & Maintenance
Issues spawn randomly on floors (spills, broken lights, out-of-stock, lost children, etc.)
- `M` — Open Maintenance Panel
- `E` near issue — Fix it and earn XP
- 8 issue types with urgency levels and distinct world sprites

## Phase 7 ⏭️ Skipped

## Phase 8 ✅ Player Progression & Stats
- XP from shopping, fixing issues, winning claw machines
- 12 achievements with icons and XP rewards
- `P` — Stats dashboard

## Phase 9 ✅ Customer Cart Shopping
- Customers auto-pick up carts at entrance
- Walk section-by-section checking off their shopping list
- Cart sprite attached behind customer
- Proceed to checkout lane and leave store

## Phase 10 ✅ ATMs
- 2 ATMs on Ground Floor (lobby + food court)
- Press `E` near ATM → PIN entry panel (PIN: 1234)
- Quick-withdraw buttons ($20/$50/$100) + keypad
- Locked after 3 wrong attempts

## Phase 11 ✅ Warehouse & Stock System
- **Floor 12 — Warehouse/Receiving Dock**: shelving units, delivery dock, stock crates
- **WarehouseSystem**: tracks stock per section, sections consume on purchase
- Low stock warnings when sections run below threshold
- Player can trigger restock delivery

---

## What's Left?

No more numbered phases! The core game loop is complete:

| Feature | Status |
|---------|--------|
| 12-floor world with unique themes | ✅ |
| Section browsing (190+ products) | ✅ |
| Food stalls (12 cuisines) | ✅ |
| Shopping cart + checkout | ✅ |
| NPCs (staff + customers) with AI | ✅ |
| NPC chat + AI-to-AI chat | ✅ |
| 24-hour clock | ✅ |
| Maintenance/issues system | ✅ |
| Player stats + achievements | ✅ |
| Customer cart shopping AI | ✅ |
| ATMs | ✅ |
| Warehouse stock system | ✅ |
| Pet Paradise (Floor 11) | ✅ |
| Arcade claw machines | ✅ |

## Ideas for Future Expansion

- **Multiple floors open simultaneously** — elevator ride animation between floors
- **Shopping list UI** — player can see what they came to buy
- **Pet adoption interaction** — press E at adoption corner to "adopt"
- **Multiple floors open at once** — seamless vertical traversal
- **Sound effects** — ambient store noise, checkout beeps, NPC chatter
- **Weather system** — affects customer spawn rates
- **Store reputation score** — visible to player
- **Staff scheduling** — staff go on breaks, shifts change
- **Customer impatience** — customers leave if wait too long at checkout

_Current: Fully featured supermarket game with 12 floors, NPCs, commerce, maintenance, progression, and warehouse operations._
