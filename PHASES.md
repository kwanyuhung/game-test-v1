# 🏪 Supermarket — Phases Roadmap

## Phase 1 ✅ Core World
**Store Layout — 12 Floors:**
- **Ground (G)**: Compact lobby, staff entrance, ATM
- **Floor 1 — Shoes**: Ladies Shoes, Mens Shoes, Kids Shoes, Sport Shoes, Sandals
- **Floor 2 — Fashion / Dresses**: Ladies Wear, Mens Wear, Kids Wear, Activewear, Formal Wear
- **Floor 3 — Sport & Active**: Gym Equipment, Sports Gear, Team Sports, Activewear, Fitness
- **Floor 4 — Outdoor**: Fishing, Hiking, Running, Camping, Cycling
- **Floor 5 — Stationery & Plants**: Office Supplies, School Stationery, Indoor Plants, Garden Plants
- **Floor 6 — Staff Areas**: Locker Room, Staff Lounge, Training Room
- **Floor 7 — Back Office**: Admin Office, HR Department, Open Office
- **Floor 8 — Executive Office**: Exec Suite, Board Room, Secretaries
- **Floor 9 — Rooftop Café**: Food stalls, outdoor dining
- **Floor 10 — Pet Paradise**: Adoption corner, pet supplies
- **Floor 11 — Warehouse**: Receiving dock, stock shelves

Player movement across all floors, section browsing.

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

## Phase C — Store Expansion & Renovation
Unlock and build new areas of the store.
- Expand the parking lot (more vehicle slots, drive-through window)
- Renovate floors to unlock premium sections (organic aisle, deluxe bakery)
- Store layout editor — choose where sections go
- Unlock new building wings as revenue milestones

## Phase D — Staff Management & HR
Hire, train, and manage your workforce.
- Staff hiring panel — open positions, interview candidates
- Assign staff to specific floors/sections
- Staff morale system — happy staff work faster, unhappy staff call in sick
- Shift scheduling — morning/afternoon/night crews
- Staff training — improve speed/quality per skill type

## Phase E — Marketing & Promotions
Attract more customers with deals and campaigns.
- Weekly sale events — discounted products bring crowds
- Loyalty card — repeat customers earn points toward rewards
- Store flyer/circular — promote today's deals (in-game notification)
- Advertising budget — spend to increase customer spawn rate
- VIP customer program — special shoppers with bigger carts

## Phase F — Finance & Supplier Contracts
Manage the business side of the supermarket.
- Dynamic pricing — raise/lower prices per section
- Supplier contracts — negotiate bulk deals, faster delivery tiers
- Daily/weekly profit & loss statement
- Tax season — file reports, reinvest in store
- Store reputation score — affects customer volume and staff satisfaction

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
