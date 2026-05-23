# Floor 3 - Sport 

**Theme:** sport | **Label:** 3 | **Ambient Color:** `#667F8C`

## Overview

Floor 3 is a **sport** themed floor.

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_SPORT_AREA | (2, 3) | 24x16 | GYM EQUIPMENT |
| ZONE_SPORT_AREA | (28, 3) | 24x16 | SPORTS GEAR |
| ZONE_SPORT_AREA | (54, 3) | 24x16 | TEAM SPORTS |
| ZONE_SPORT_AREA | (2, 21) | 38x16 | ACTIVEWEAR |
| ZONE_SPORT_AREA | (42, 21) | 36x16 | FITNESS |
| ZONE_AD | (70, 4) | 4x6 | ad_color |
| ZONE_ELEVATOR | (6, 2) | 14x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (20, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
| gym | (2, 3) | 24x16 |
| sports_gear | (28, 3) | 24x16 |
| activewear | (2, 21) | 38x16 |

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_SPORT_AREA**: 5 instance(s) - GYM EQUIPMENT, SPORTS GEAR, TEAM SPORTS, ACTIVEWEAR, FITNESS
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

- Handler: `scripts/areas/floor_3/floor_3_handler.gd`
- Common: `scripts/areas/floor_3/floor_3_common_handler.gd`
