# Floor 4 - Outdoor 

**Theme:** outdoor | **Label:** 4 | **Ambient Color:** `#6B8C72`

## Overview

Floor 4 is a **outdoor** themed floor.

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_OUTDOOR_AREA | (2, 3) | 24x16 | FISHING |
| ZONE_OUTDOOR_AREA | (28, 3) | 24x16 | HIKING |
| ZONE_OUTDOOR_AREA | (54, 3) | 24x16 | RUNNING |
| ZONE_OUTDOOR_AREA | (2, 21) | 38x16 | CAMPING |
| ZONE_OUTDOOR_AREA | (42, 21) | 36x16 | CYCLING |
| ZONE_AD | (70, 4) | 4x6 | ad_color |
| ZONE_ELEVATOR | (80, 2) | 4x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (84, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
| fishing | (2, 3) | 24x16 |
| hiking | (28, 3) | 24x16 |
| running | (54, 3) | 24x16 |

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_OUTDOOR_AREA**: 5 instance(s) - FISHING, HIKING, RUNNING, CAMPING, CYCLING
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

- Handler: `scripts/areas/floor_4/floor_4_handler.gd`
- Common: `scripts/areas/floor_4/floor_4_common_handler.gd`
