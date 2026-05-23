# Floor 1 - Shoes 

**Theme:** shoes | **Label:** 1 | **Ambient Color:** `#847266`

## Overview

Floor 1 is a **shoes** themed floor.

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_SHOES_RACK | (2, 3) | 24x16 | LADIES SHOES |
| ZONE_SHOES_RACK | (28, 3) | 24x16 | MENS SHOES |
| ZONE_SHOES_RACK | (54, 3) | 24x16 | KIDS SHOES |
| ZONE_SHOES_RACK | (2, 21) | 38x16 | SPORT SHOES |
| ZONE_SHOES_RACK | (42, 21) | 36x16 | SANDALS |
| ZONE_AD | (66, 4) | 4x6 | ad_color |
| ZONE_ELEVATOR | (6, 2) | 14x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (20, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
| shoes_ladies | (2, 3) | 24x16 |
| shoes_mens | (28, 3) | 24x16 |
| shoes_kids | (54, 3) | 24x16 |

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_SHOES_RACK**: 5 instance(s) - LADIES SHOES, MENS SHOES, KIDS SHOES, SPORT SHOES, SANDALS
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

- Handler: `scripts/areas/floor_1/floor_1_handler.gd`
- Common: `scripts/areas/floor_1/floor_1_common_handler.gd`
