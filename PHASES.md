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
- **Floor 7 — Back Office**: Admin Office, HR Department, Open Office, **Monitor Room (CCTV)**
- **Floor 8 — Executive Office**: Exec Suite, Board Room, Secretaries, **Monitor Room (CCTV)**
- **Floor 9 — Rooftop Café**: Food stalls, outdoor dining
- **Floor 10 — Pet Paradise**: Adoption corner, pet supplies
- **Floor 11 — Warehouse**: Receiving dock, stock shelves

**Monitor Room (CCTV) — Floors 7 & 8:**
Press **E** near the monitor room zone to open the CCTV panel — live grid showing all 12 floor feeds with customer counts, stock levels, and issue alerts.

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

## Phase G ✅ Garden & Home Living
**New Floor — Home & Garden (between Fashion and Sport)**

A warm, nature-inspired floor with home decor, indoor plants, outdoor furniture, and home organization.

**Zones & Features:**
- **Home Decor Section**: Rugs, candles, vases, wall art, photo frames
- **Furniture Display**: Sofas, tables, shelving units, chairs on display
- **Indoor Plants Corner**: Potted plants, succulents, hanging planters, plant care products
- **Outdoor Furniture Zone**: Patio sets, garden chairs, BBQ equipment display
- **Home Organization**: Storage boxes, closet organizers, kitchen organizers
- **Lighting Section**: Lamps, fairy lights, ceiling fixtures

**Player Interactions:**
- Browse and add home items to cart
- Seasonal decor rotates (e.g., Christmas ornaments in December)
- Staff home consultant NPC

---

## Phase I ✅ Information Hub & Services
**New Service Area — Customer Service & Loyalty Center**

A dedicated service hub for customer support, loyalty programs, and digital services.

**Zones & Features:**
- **Customer Service Desk**: Returns, exchanges, complaints, price matching
- **Loyalty Sign-Up Kiosk**: Register for store membership card, earn points
- **Gift Wrapping Station**: Pay for premium gift wrapping (costs extra, gives XP bonus)
- **Digital Kiosk Zone**: Interactive store directory map, product lookup, current deals
- **Self-Checkout Express Lane**: 10-items-or-less self-scan counter
- **Information Board**: Today's deals, store events, upcoming promotions

**Player Interactions:**
- Press E at loyalty kiosk to sign up → earn loyalty points on purchases
- Press E at gift wrapping → option to wrap items for +XP bonus tip
- Press E at digital kiosk → browse deals and store map
- Loyalty points accumulate and can be redeemed at checkout for discounts

**Loyalty System:**
- Earn 1 loyalty point per $1 spent
- Every 100 points = $5 store credit at checkout
- VIP tier unlocked at 1000 lifetime points (faster point earning)
- Birthday bonus: double points on birthday

---

## Phase J ✅ Juice Bar & Fresh Foods
**New Floor — Juice Bar, Smoothies & Health Foods**

A vibrant health-focused floor with freshly made drinks and nutritious snack options.

**Zones & Features:**
- **Juice Bar Counter**: Freshly squeezed orange, apple, carrot, watermelon juices
- **Smoothie Station**: Mixed fruit smoothies, protein shakes, green detox smoothies
- **Açaí Bowl Corner**: Açaí bowls with toppings (granola, honey, fresh fruit)
- **Salad Bar**: Fresh pre-made salads, grain bowls, wrap selections
- **Health Food Shelf**: Organic snacks, trail mix, protein bars, dried fruits
- **Vitamin & Supplements Corner**: Vitamins, minerals, health supplements

**Menu Items (Price List):**
| Item | Price | XP |
|------|-------|-----|
| Fresh Orange Juice | $4.50 | +15 XP |
| Green Detox Smoothie | $6.00 | +20 XP |
| Açaí Bowl | $8.50 | +25 XP |
| Garden Salad | $5.50 | +18 XP |
| Protein Shake | $5.00 | +15 XP |
| Health Snack Box | $3.50 | +10 XP |
| Vitamin Pack | $12.00 | +30 XP |

**Player Interactions:**
- Press E at juice bar → browse drink menu → add to cart
- Press E at salad bar → browse salad menu → add to cart
- Staff: Juice barista NPC behind counter

---

## Phase K ✅ Kids Kingdom & Family Zone
**New Floor — Kids Play Area & Family Facilities**

A dedicated family floor with supervised kids play area, nursing room, and family amenities.

**Zones & Features:**
- **Supervised Play Zone**: Colorful soft-play area, slides, ball pit (visible through window from corridor)
- **Kids Club Reception**: Sign kids in/out of supervised play (costs $5/30min)
- **Nursing / Baby Room**: Private room for breastfeeding, nappy changing station
- **Family Changing Room**: Accessible toilet + changing facility for families
- **Kids Clothing Rack**: Small clothing section for children (shoes, socks, accessories)
- **Toy Display Corner**: Sample toys from Floor 10 on display with "ask staff" ordering
- **Stroller Parking**: Dedicated stroller storage area near entrance

**Player Interactions:**
- Parents can drop kids at supervised play → kids disappear for 30min game time → XP bonus when picked up
- Press E at nursing room → private area (other NPCs don't enter)
- Press E at kids clothing → browse small section
- Family WC has family-friendlier access than standard WC
- Stroller can be "parked" here for convenience

**Family Bonus:**
- When parent and child NPCs are together on this floor, both get +10% XP bonus
- Triggers "Family Day" achievement

---

## DEV MODE — Testing Tools
Press **F3** to open the Dev Tools panel (dev mode only).

| Button | What it does |
|--------|-------------|
| SUPER ACTOR [S] | Spawn a golden-crown test character you can walk around and press E next to any NPC to interact |
| GOD MODE [G] | Walk through walls, ignore collisions |
| INFINITE MONEY [M] | Set cash to $999,999 |
| FAST TIME [T] | Toggle 5x game speed |
| SPAWN 5 CUSTOMERS | Add 5 test customers to the store |
| SPAWN 3 STAFF | Add 3 test staff members |
| ALL ACHIEVEMENTS | Unlock all 12 achievements instantly |
| MAX STATS | Set XP to max, level to 50 |
| TRIGGER DELIVERY | Force a warehouse delivery |
| LOW STOCK ALERT | Trigger low stock warnings on all sections |
| KILL ALL NPCs | Remove all NPCs from the store |

## Ad Billboards
Colorful promotional billboards placed throughout the store:
- **Ground floor**: SUMMER SALE (lobby), MEMBERS ONLY (lobby)
- **Floor 1 (Shoes)**: SPORT SALE
- **Floor 2 (Fashion)**: NEW LOOKS!
- **Floor 3 (Sport)**: GEAR UP!
- **Floor 4 (Outdoor)**: ADVENTURE!
- **Floor 5 (Stationery)**: BACK TO SCHOOL!
- **Floor 10 (Pet)**: ADOPT ME!

## Ideas for Future Expansion

- **Multiple floors open simultaneously** — elevator ride animation between floors
- **Shopping list UI** — player can see what they came to buy
- **Sound effects** — ambient store noise, checkout beeps, NPC chatter
- **Weather system** — affects customer spawn rates
- **Customer impatience** — customers leave if wait too long at checkout

_Current: Fully featured supermarket game with 12 floors, NPCs, commerce, maintenance, progression, and warehouse operations._
