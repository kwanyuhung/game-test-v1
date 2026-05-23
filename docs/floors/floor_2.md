# Floor 2 - Fashion 

**Theme:** fashion | **Label:** 2 | **Ambient Color:** `#8C6B84`

## Overview

Floor 2 is a **fashion** themed floor.

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_DRESS_RACK | (2, 3) | 26x18 | LADIES WEAR |
| ZONE_DRESS_RACK | (30, 3) | 26x18 | MENS WEAR |
| ZONE_DRESS_RACK | (58, 3) | 20x18 | KIDS WEAR |
| ZONE_DRESS_RACK | (2, 23) | 38x14 | ACTIVEWEAR |
| ZONE_DRESS_RACK | (42, 23) | 36x14 | FORMAL WEAR |
| ZONE_AD | (68, 4) | 4x6 | ad_color |
| ZONE_ELEVATOR | (6, 2) | 14x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (20, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
| ladies_wear | (2, 3) | 26x18 |
| mens_wear | (30, 3) | 26x18 |
| kids_wear | (58, 3) | 20x18 |

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_DRESS_RACK**: 5 instance(s) - LADIES WEAR, MENS WEAR, KIDS WEAR, ACTIVEWEAR, FORMAL WEAR
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

- Handler: `scripts/areas/floor_2/floor_2_handler.gd`
- Common: `scripts/areas/floor_2/floor_2_common_handler.gd`
