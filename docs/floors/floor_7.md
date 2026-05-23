# Floor 7 - Back_Office 

**Theme:** back_office | **Label:** 7 | **Ambient Color:** `#666B72`

## Overview

Floor 7 is a **back_office** themed floor (staff only).

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_OFFICE_DESK | (2, 3) | 38x18 | ADMIN OFFICE |
| ZONE_OFFICE_DESK | (42, 3) | 36x18 | HR DEPARTMENT |
| ZONE_OFFICE_DESK | (2, 23) | 78x14 | OPEN OFFICE |
| ZONE_MONITOR_ROOM | (66, 3) | 12x35 | MONITORING ROOM |
| ZONE_ELEVATOR | (80, 2) | 4x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (84, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
*None*

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_OFFICE_DESK**: 3 instance(s) - ADMIN OFFICE, HR DEPARTMENT, OPEN OFFICE
- **ZONE_MONITOR_ROOM**: 1 instance(s) - MONITORING ROOM
- **ZONE_ELEVATOR**: 1 instance(s) - -
- **ZONE_STAIRS**: 1 instance(s) - -

## Properties

| Property | Value |
|----------|-------|
| has_shopping | false |
| has_checkout | false |
| has_elevator | true |
| has_stairs | true |
| is_staff_only | true |
| is_rooftop | false |

## Handler Files

- Handler: `scripts/areas/floor_7/floor_7_handler.gd`
- Common: `scripts/areas/floor_7/floor_7_common_handler.gd`
