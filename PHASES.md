# 🏪 Supermarket — Phases Roadmap

## Phase 1 ✅ Core World
**Store Layout — 14 Floors:**
- **Ground (G)**: Compact lobby, ATM, **Phase I** Info Hub, **Phase H** Electronics
- **Floor 1 — Shoes**: Ladies Shoes, Mens Shoes, Kids Shoes, Sport Shoes, Sandals
- **Floor 2 — Fashion / Dresses**: Ladies Wear, Mens Wear, Kids Wear, Activewear, Formal Wear
- **Floor 3 — Sport & Active**: Gym Equipment, Sports Gear, Team Sports, Activewear, Fitness
- **Floor 4 — Outdoor**: Fishing, Hiking, Running, Camping, Cycling
- **Floor 5 — Garden & Home**: Home Decor, Furniture, Outdoor Living, Organization, Lighting, Plants
- **Floor 6 — Staff Areas**: Locker Room, Staff Lounge, Training Room
- **Floor 7 — Back Office**: Admin, HR, Open Office, **Monitor Room (CCTV)**
- **Floor 8 — Executive Office**: Exec Suite, Board Room, Secretaries, **Monitor Room (CCTV)**
- **Floor 9 — Rooftop Café**: Food stalls, outdoor dining
- **Floor 10 — Pet Paradise**: Adoption corner, pet supplies
- **Floor 11 — Warehouse**: Receiving dock, stock shelves
- **Floor 12 — Juice Bar & Fresh**: Juices, Smoothies, Salads, Health Foods
- **Floor 13 — Kids Kingdom**: Play Zone, Nursing Room, Family WC, Kids Club
- **Floor 14 — Electronics**: Phones, Smart Home, TVs, Repair Counter

Player movement across all floors, section browsing.

## Phase 2 ✅ Commerce
Food stalls (12 cuisines), shopping cart, checkout receipts, Telegram bot.

## Phase 3 ✅ NPC System
Full NPC characters — 7 staff roles, 9 customer group types, customizable appearances.

## Phase 3b ✅ Chat & Pet Floor
Chat system (press C near NPC), Pet Paradise (Floor 10) with adoption corner.

## Phase 4 ✅ Time & Lighting
24-hour game clock. Store opens 06:00, closes 23:00. Floor lighting changes by time.

## Phase 5 ✅ Parking Lot & Vehicles
Ground floor parking zone, parked NPC cars, parking attendant.

## Phase 6 ✅ 24-Hour Ops & Maintenance
Issues spawn randomly on floors — `M` opens panel, `E` fixes issues for XP.

## Phase 7 ⏭️ Skipped

## Phase 8 ✅ Player Progression & Stats
XP system, 12 achievements, `P` opens stats dashboard.

## Phase 9 ✅ Customer Cart Shopping
Customers auto-pick up carts, shop section-by-section, proceed to checkout.

## Phase 10 ✅ ATMs
Ground floor ATMs — press E, enter PIN (1234), withdraw $20/$50/$100.

## Phase 11 ✅ Warehouse & Stock System
Floor 11 warehouse, stock tracking, low stock alerts, delivery system.

---

## Phase G ✅ Garden & Home Living
**Floor 5 — Home & Garden**

A nature-inspired floor with home decor, outdoor furniture, and home organization.

**Zones:** Home Decor | Furniture Display | Outdoor Living | Organization | Lighting | Plants

## Phase H ✅ Home Electronics & Tech
**Ground Floor extension + Floor 14**

Gadgets, phones, smart home devices, and tech repair services.

**Ground Floor zones:** Phones & Gadgets | Smart Home | Electronics | Repair Counter
**Floor 14 (Electronics Megastore):** Full floor — TV wall display, speakers, headphones, phone repair workshop.

**Press E at repair counter** → pay for screen fix / battery replacement (+XP)

## Phase I ✅ Information Hub & Services
**Ground Floor — Customer Service & Loyalty Center**

**Zones:** Customer Service Desk | Loyalty Kiosk | Gift Wrapping | Digital Info Kiosk

**Loyalty System:** Earn 1 pt/$1 spent → 100 pts = $5 credit. VIP at 1000 pts. Birthday bonus.

**Press E at loyalty kiosk** → sign up | **Press E at gift wrap** → wrap for +XP bonus

## Phase J ✅ Juice Bar & Fresh Foods
**Floor 12 — Juice Bar, Smoothies & Health Foods**

**Zones:** Juice Bar | Smoothie Station | Açaí Bowl Corner | Salad Bar | Health Food Shelf

| Item | Price | XP |
|------|-------|-----|
| Fresh Orange Juice | $4.50 | +15 |
| Green Detox Smoothie | $6.00 | +20 |
| Açaí Bowl | $8.50 | +25 |
| Garden Salad | $5.50 | +18 |
| Protein Shake | $5.00 | +15 |
| Vitamin Pack | $12.00 | +30 |

**Press E** at any counter → browse menu → add to cart

## Phase K ✅ Kids Kingdom & Family Zone
**Floor 13 — Kids Play Area & Family Facilities**

**Zones:** Supervised Play Zone | Kids Club Reception | Nursing Room | Family WC | Kids Clothing | Stroller Parking

**Family Bonus:** Parent + child together → +10% XP → "Family Day" achievement

**Press E at nursing room** → private area (NPCs don't enter)

---

## DEV MODE — Testing Tools
Press **F3** to open Dev Tools (dev mode only).

| Button | What it does |
|--------|-------------|
| SUPER ACTOR | Golden-crown character, E to interact with any NPC |
| GOD MODE | Walk through walls |
| INFINITE MONEY | Set cash to $999,999 |
| FAST TIME | Toggle 5x speed |
| SPAWN 5 CUSTOMERS | Add 5 test customers |
| SPAWN 3 STAFF | Add 3 test staff |
| ALL ACHIEVEMENTS | Unlock all instantly |
| MAX STATS | XP max, level 50 |
| TRIGGER DELIVERY | Force warehouse delivery |
| LOW STOCK ALERT | Trigger stock warnings |
| KILL ALL NPCs | Remove all NPCs |

## Ad Billboards
Ground: SUMMER SALE, MEMBERS ONLY | Floor 1: SPORT SALE | Floor 2: NEW LOOKS! | Floor 3: GEAR UP! | Floor 4: ADVENTURE! | Floor 5: BACK TO SCHOOL! | Floor 12: 100% ORGANIC! | Floor 13: FAMILY DAY! | Floor 14: TECH SALE!

_Current: 14-floor supermarket with Phases G-K implemented. Electronics (H), Juice Bar (J), and Kids Kingdom (K) are the newest additions._

---

## Brand Partnership System (New Feature)
**Open with: Press [B] in-game**

A portal where external brands (Ferrero, Hershey's, etc.) can manage their presence in the supermarket without touching game code.

### Architecture
```
brands/
  ferrero.json     ← Brand data file (products, events, ads, stats)
  hershey.json
  brands.json      ← Index file

scripts/
  brand_manager.gd  ← Singleton: loads brands, manages products/events/ads
  brand_portal.gd   ← UI dashboard for brand partners
```

### Features

**Products**
- Brands add products via JSON: name, price, section, subcategory, shape, color, description
- Products auto-appear in the correct section browse alongside regular items
- `limited_edition: true` flag shows a "LIMITED!" badge in the UI

**Events**
- Scheduled promotions: start_time / end_time
- XP multipliers: `xp_multiplier: 2.0` doubles XP on brand products at checkout
- Branded NPC promoters spawn during events
- Toast announcement when events go live

**Ads**
- Brands place billboard ads on specific floors
- Ad text + color stored in JSON, rendered via floor_builder

**Stats**
- Tracks: total_views, total_purchases, revenue per brand
- Visible in the Stats tab of the Brand Portal

**Partner Workflow**
1. Partner receives `brands/ferrero_example.json` as template
2. They fill in: products, event schedule, ad placements
3. File goes into `brands/` folder — no code changes needed
4. Game reloads → brand appears automatically

**Example: Ferrero adding a new chocolate bar**
```json
{
  "brand_id": "ferrero",
  "products": [
    {
      "product_id": "ferrero_newbar",
      "name": "Roccha Dark",
      "price": 5.50,
      "section": "snacks",
      "subcategory": "Chocolate",
      "shape": 0,
      "color": "#3d1a00",
      "description": "Dark chocolate with hazelnot"
    }
  ],
  "active_events": [
    {
      "event_id": "ferrero_summer",
      "name": "Ferrero Summer",
      "xp_multiplier": 2.0,
      "start_time": "2026-06-01T00:00",
      "end_time": "2026-06-30T23:59",
      "ad_text": "FERRERO SUMMER 2X XP!"
    }
  ]
}
```

### Dev Tools Integration
| Action | What it does |
|--------|-------------|
| `brand list` | Show all registered brands |
| `brand add <brand_id> <json_path>` | Register a new brand from JSON |
| `brand event <brand_id> <event_id>` | Trigger an event immediately |
| `brand stats <brand_id>` | Show brand stats |
