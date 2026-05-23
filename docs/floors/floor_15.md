# Floor 15 - Canteen 

**Theme:** canteen | **Label:** 15 | **Ambient Color:** `#8C7F6B`

## Overview

Floor 15 is a **canteen** themed floor.

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_CANTEEN | (2, 3) | 76x8 | CANTEEN COUNTER |
| ZONE_FOOD_STALL | (2, 3) | 12x8 | canteen_rice |
| ZONE_FOOD_STALL | (16, 3) | 12x8 | canteen_noodle |
| ZONE_FOOD_STALL | (30, 3) | 12x8 | canteen_meat |
| ZONE_FOOD_STALL | (44, 3) | 12x8 | canteen_veg |
| ZONE_FOOD_STALL | (58, 3) | 12x8 | canteen_drinks |
| ZONE_FOOD_STALL | (70, 3) | 8x8 | canteen_fruit |
| ZONE_DECOR | (4, 14) | 72x22 | canteen_tables |
| ZONE_ENTRY_GATE | (38, 3) | 6x5 | CANTEEN ENTRANCE |
| ZONE_ELEVATOR | (80, 2) | 4x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (84, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
*None*

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_CANTEEN**: 1 instance(s) - CANTEEN COUNTER
- **ZONE_FOOD_STALL**: 6 instance(s) - canteen_rice, canteen_noodle, canteen_meat, canteen_veg, canteen_drinks, canteen_fruit
- **ZONE_DECOR**: 1 instance(s) - canteen_tables
- **ZONE_ENTRY_GATE**: 1 instance(s) - CANTEEN ENTRANCE
- **ZONE_ELEVATOR**: 1 instance(s) - -
- **ZONE_STAIRS**: 1 instance(s) - -

## Properties

| Property | Value |
|----------|-------|
| has_shopping | true |
| has_checkout | false |
| has_elevator | true |
| has_stairs | false |
| is_staff_only | false |
| is_rooftop | false |

## Handler Files

- Handler: `scripts/areas/floor_15/floor_15_handler.gd`
