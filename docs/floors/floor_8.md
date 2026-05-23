# Floor 8 - Arcade 

**Theme:** arcade | **Label:** 8 | **Ambient Color:** `#382D60`

## Overview

Floor 8 is a **arcade** themed floor (staff only).

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
| ZONE_COMMON | (2, 3) | 78x38 | ZONE_COMMON |
| ZONE_KIDS_PLAY | (10, 3) | 30x20 | PLAY ZONE |
| ZONE_CLAW_MACHINE | (2, 3) | 10x14 | prize_pool |
| ZONE_CLAW_MACHINE | (14, 3) | 10x14 | prize_pool |
| ZONE_CLAW_MACHINE | (2, 20) | 10x14 | prize_pool |
| ZONE_CLAW_MACHINE | (14, 20) | 10x14 | prize_pool |
| ZONE_ELEVATOR | (80, 2) | 4x40 | ZONE_ELEVATOR |
| ZONE_STAIRS | (84, 2) | 6x40 | ZONE_STAIRS |

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
*None*

## Zone Types Summary

- **ZONE_COMMON**: 1 instance(s) - -
- **ZONE_KIDS_PLAY**: 1 instance(s) - PLAY ZONE
- **ZONE_CLAW_MACHINE**: 4 instance(s) - prize_pool, prize_pool, prize_pool, prize_pool
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

- Handler: `scripts/areas/floor_8/floor_8_handler.gd`
- Common: `scripts/areas/floor_8/floor_8_common_handler.gd`
