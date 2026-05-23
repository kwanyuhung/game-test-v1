# Floor 9 - Staff_Room 

**Theme:** staff_room | **Label:** 9 | **Ambient Color:** `#606B7F`

## Overview

Floor 9 is a **staff_room** themed floor (staff only) (rooftop).

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_OFFICE_DESK | (10, 3) | 30x20 | terminal |
| ZONE_STAFF_LOUNGE | (42, 3) | 34x20 | STAFF AREA |
| ZONE_TRAINING | (2, 25) | 78x14 | OPERATIONS CENTER |
| ZONE_ELEVATOR | (80, 2) | 4x40 | ZONE_ELEVATOR |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
*None*

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_OFFICE_DESK**: 1 instance(s) - terminal
- **ZONE_STAFF_LOUNGE**: 1 instance(s) - STAFF AREA
- **ZONE_TRAINING**: 1 instance(s) - OPERATIONS CENTER
- **ZONE_ELEVATOR**: 1 instance(s) - -

## Properties

| Property | Value |
|----------|-------|
| has_shopping | false |
| has_checkout | false |
| has_elevator | true |
| has_stairs | true |
| is_staff_only | true |
| is_rooftop | true |

## Handler Files

- Handler: `scripts/areas/floor_9/floor_9_handler.gd`
- Common: `scripts/areas/floor_9/floor_9_common_handler.gd`
