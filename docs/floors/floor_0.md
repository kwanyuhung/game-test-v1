# Floor 0 - Lobby (G)

**Theme:** lobby | **Label:** G | **Ambient Color:** `#6B7066`

## Overview

Floor 0 is the main entrance floor of the supermarket. It serves as the central hub connecting all other floors via elevator, stairs, and escalator. The floor features a large food court area and warehouse facilities.

## Properties

| Property | Value |
|----------|-------|
| has_shopping | false |
| has_checkout | false |
| has_elevator | true |
| has_stairs | true |
| is_staff_only | false |
| is_rooftop | false |

---

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_LOBBY | (0, 2) | 80x13 | ZONE_LOBBY |
| ZONE_INFO_DESK | (40, 3) | 16x7 | ZONE_INFO_DESK |
| ZONE_WC | (68, 3) | 12x7 | ZONE_WC |
| ZONE_AD | (56, 3) | 4x5 | ad_color |
| ZONE_AD | (56, 9) | 4x5 | ad_color |
| ZONE_ATM | (58, 4) | 4x5 | ZONE_ATM |
| ZONE_ATM | (58, 28) | 4x5 | ZONE_ATM |
| ZONE_CUSTOMER_SERVICE | (8, 3) | 16x7 | CUSTOMER SERVICE |
| ZONE_LOYALTY_KIOSK | (26, 3) | 14x7 | LOYALTY CENTER |
| ZONE_GIFT_WRAP | (42, 3) | 14x7 | GIFT WRAPPING |
| ZONE_DIGITAL_KIOSK | (58, 11) | 8x7 | INFO KIOSK |
| ZONE_FOOD_STALL | (2, 3) | 14x8 | jp_ramen |
| ZONE_FOOD_STALL | (18, 3) | 14x8 | jp_sushi |
| ZONE_FOOD_STALL | (34, 3) | 14x8 | jp_takoyaki |
| ZONE_FOOD_STALL | (50, 3) | 14x8 | thai |
| ZONE_FOOD_STALL | (66, 3) | 14x8 | indian |
| ZONE_FOOD_STALL | (2, 15) | 14x8 | chinese |
| ZONE_FOOD_STALL | (18, 15) | 14x8 | korean |
| ZONE_FOOD_STALL | (34, 15) | 14x8 | turkish |
| ZONE_FOOD_STALL | (50, 15) | 14x8 | vietnamese |
| ZONE_FOOD_STALL | (66, 15) | 14x8 | italian |
| ZONE_FOOD_STALL | (2, 25) | 14x8 | mexican |
| ZONE_FOOD_STALL | (18, 25) | 14x8 | drinks |
| ZONE_WAREHOUSE | (0, 35) | 120x14 | WAREHOUSE FLOOR |
| ZONE_TRUCK_DOCK | (0, 35) | 22x14 | TRUCK DOCK |
| ZONE_FORKLIFT | (0, 42) | 22x7 | FORKLIFT ZONE |
| ZONE_CONVEYOR | (22, 38) | 50x8 | CONVEYOR BELT |
| ZONE_STORAGE_SHELF | (75, 35) | 45x14 | STORAGE |
| ZONE_ELEVATOR | (6, 2) | 14x47 | ZONE_ELEVATOR |
| ZONE_STAIRS | (20, 2) | 6x47 | ZONE_STAIRS |
| ZONE_ESCALATOR | (26, 2) | 6x47 | ZONE_ESCALATOR |
| ZONE_DECOR | (16, 11) | 4x4 | dining_table |
| ZONE_DECOR | (34, 11) | 4x4 | dining_table |
| ZONE_DECOR | (52, 11) | 4x4 | dining_table |
| ZONE_DECOR | (70, 11) | 4x4 | dining_table |
| ZONE_VENDING_MACHINE | (70, 3) | 10x10 | Energy Drink $3.00 |
| ZONE_VENDING_MACHINE | (70, 20) | 10x10 | Energy Drink $3.00 |
| ZONE_PROMO_BOOTH | (3, 3) | 12x8 | DAILY DEALS |
| ZONE_WAREHOUSE_STOCK_VIEW | (116, 35) | 10x12 | STOCK STATUS |
| ZONE_LOST_FOUND | (22, 3) | 12x7 | LOST & FOUND |
| ZONE_STORE_NEWS | (36, 3) | 12x7 | STORE NEWS |

---

## Areas (Grouped Zones)

| Area ID | Name | Zone Types |
|---------|------|-----------|
| lobby | Lobby | Lobby, Info Desk, Customer Service, Loyalty, Gift Wrap, Digital Kiosk, AD, ATM, Lost & Found, Store News, Decor, Promo Booth |
| food_court | Food Court | Food Stall, Decor, Vending Machine |
| warehouse | Warehouse | Warehouse, Truck Dock, Forklift, Conveyor, Storage Shelf, Stock View |
| transit | Transit | Elevator, Stairs, Escalator |

---

## Player Moveable Areas

| Area Name | Position (x,y) | Size | Description |
|-----------|-----------------|------|-------------|
| Lobby Main | (0, 2) | 80x13 | Main lobby area with info desk, customer service, loyalty kiosk |
| Food Court | (0, 2) | 80x33 | Food court with 10 stalls and dining tables |
| Warehouse | (0, 35) | 120x14 | Warehouse floor with truck dock, conveyor, storage (staff only) |
| Elevator Area | (6, 2) | 14x47 | Elevator shaft area |
| Stairs Area | (20, 2) | 6x47 | Staircase area |
| Escalator Area | (26, 2) | 6x47 | Escalator area |

**Total Moveable Tiles:** ~4,200

---

## Facilities (Amenities)

| Facility | Count | Position |
|----------|-------|----------|
| ATM Machine | 2 | (58, 4), (58, 28) |
| Restroom | 2 | (68, 3), (68, 3) |
| Vending Machine | 2 | (70, 3), (70, 20) |
| AD Display | 4 | (56, 3), (56, 9), and 2 more |
| Promo Booth | 1 | (3, 3) |
| Lost & Found | 1 | (22, 3) |
| Store News Board | 1 | (36, 3) |

---

## Places (Named Locations)

### Service Places
| Place | Position |
|-------|----------|
| Info Desk | (40, 3) |
| Customer Service | (8, 3) |
| Loyalty Center | (26, 3) |
| Gift Wrapping | (42, 3) |
| Digital Kiosk | (58, 11) |

### Transit Places
| Place | Position |
|-------|----------|
| Elevator | (6, 2) |
| Stairs | (20, 2) |
| Escalator | (26, 2) |
| Entry Gate | (38, 3) |

### Food Stalls (12 Total)
| Stall | Cuisine | Position |
|-------|---------|----------|
| Ramen (jp_ramen) | Japanese | (2, 3) |
| Sushi (jp_sushi) | Japanese | (18, 3) |
| Takoyaki (jp_takoyaki) | Japanese | (34, 3) |
| Thai Food | Thai | (50, 3) |
| Indian | Indian | (66, 3) |
| Chinese | Chinese | (2, 15) |
| Korean | Korean | (18, 15) |
| Turkish | Turkish | (34, 15) |
| Vietnamese | Vietnamese | (50, 15) |
| Italian | Italian | (66, 15) |
| Mexican | Mexican | (2, 25) |
| Drinks | Beverages | (18, 25) |

---

## Entity Spawns

### NPC Staff
| Role | Area | Position | Patrol |
|------|------|----------|--------|
| GREETER | lobby | (35, 5) | Yes |
| CUSTOMER_SERVICE | lobby | (12, 5) | No |
| LOYALTY_KIOSK | lobby | (28, 5) | No |
| SHELF_STOCKER | food_court | (5, 6) | Yes |
| FLOOR_STAFF | food_court | (40, 20) | Yes |
| SHELF_STOCKER | warehouse | (10, 40) | Yes |
| FLOOR_STAFF | warehouse | (50, 42) | Yes |

### Robots
| Type | Role | Area | Position | Patrol |
|------|------|------|----------|--------|
| robot_humanoid | GREETER | lobby | (25, 12) | Yes |
| robot_single | GUIDANCE_ROBOT | lobby | (30, 10) | Yes |
| robot_single | CLEANING_ROBOT | food_court | (40, 15) | Yes |
| robot_single | DELIVERY_ROBOT | warehouse | (10, 38) | Yes |
| robot_single | SHELF_ROBOT | warehouse | (90, 40) | Yes |
| robot_humanoid | MANAGER | warehouse | (60, 42) | Yes |
| robot_single | SECURITY_ROBOT | transit | (8, 20) | Yes |
| robot_humanoid | SECURITY | transit | (12, 25) | Yes |

### Entity Stats Summary
| Category | Count |
|----------|-------|
| NPC Staff | 7 |
| Robots | 8 |
| Total Entities | 15 |

---

## Handler Files

| File | Location | Description |
|------|----------|-------------|
| floor_0_config.gd | `scripts/areas/floor_0/` | Floor 0 configuration with player areas, facilities, places, spawns |
| floor_0_handler.gd | `scripts/areas/floor_0/` | Main floor 0 handler |
| lobby_handler.gd | `scripts/areas/floor_0/` | Lobby-specific rendering |
| warehouse_handler.gd | `scripts/areas/floor_0/` | Warehouse-specific rendering |
| service_area_handler.gd | `scripts/areas/floor_0/` | Info desk, customer service, loyalty kiosk |
| food_stall_handler.gd | `scripts/areas/floor_0/` | Food stall rendering |
| misc_handler.gd | `scripts/areas/floor_0/` | ATM, vending, promo booth, lost & found |
| elevator_handler.gd | `scripts/areas/shared/` | **Shared** - Elevator rendering |
| stairs_handler.gd | `scripts/areas/shared/` | **Shared** - Stairs rendering |
| ad_display_handler.gd | `scripts/areas/shared/` | **Shared** - AD display rendering |
| wc_handler.gd | `scripts/areas/shared/` | **Shared** - WC/restroom rendering |
