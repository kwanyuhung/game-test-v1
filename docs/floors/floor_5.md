# Floor 5 - Stationery 

**Theme:** stationery | **Label:** 5 | **Ambient Color:** `#7A8C72`

## Overview

Floor 5 is a **stationery** themed floor.

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_STATIONERY | (2, 3) | 36x18 | STATIONERY |
| ZONE_STATIONERY | (40, 3) | 38x18 | OFFICE SUPPLIES |
| ZONE_PLANTS_AREA | (2, 23) | 38x14 | INDOOR PLANTS |
| ZONE_PLANTS_AREA | (42, 23) | 36x14 | GARDEN PLANTS |
| ZONE_AD | (72, 4) | 4x6 | ad_color |
| ZONE_ELEVATOR | (80, 2) | 4x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (84, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
| stationery | (2, 3) | 36x18 |
| plants | (2, 23) | 38x14 |

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_STATIONERY**: 2 instance(s) - STATIONERY, OFFICE SUPPLIES
- **ZONE_PLANTS_AREA**: 2 instance(s) - INDOOR PLANTS, GARDEN PLANTS
- **ZONE_AD**: 1 instance(s) - ad_color
- **ZONE_ELEVATOR**: 1 instance(s) - -
- **ZONE_STAIRS**: 1 instance(s) - -

## Properties

| Property | Value |
|----------|-------|
| has_shopping | true |
| has_checkout | true |
| has_elevator | true |
| has_stairs | true |
| is_staff_only | false |
| is_rooftop | false |

## Handler Files

- Handler: `scripts/areas/floor_5/floor_5_handler.gd`
- Common: `scripts/areas/floor_5/floor_5_common_handler.gd`
