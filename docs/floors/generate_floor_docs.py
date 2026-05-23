#!/usr/bin/env python3
"""Generate markdown documentation for each floor from floor_config_data.json"""

import json
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
JSON_PATH = os.path.join(os.path.dirname(os.path.dirname(SCRIPT_DIR)), "scripts", "floor_config_data.json")

def color_to_hex(c):
    return "#{:02X}{:02X}{:02X}".format(int(c[0]*255), int(c[1]*255), int(c[2]*255))

def get_zone_table(zones):
    lines = []
    for z in zones:
        meta = z.get("meta", {})
        name = meta.get("name", z["type"])
        lines.append(f"| {z['type']} | ({z['x']}, {z['y']}) | {z['w']}x{z['h']} | {name} |")
    return "\n".join(lines)

def get_sections_table(sections):
    if not sections:
        return "*None*"
    lines = []
    for s in sections:
        lines.append(f"| {s['id']} | ({s['x']}, {s['y']}) | {s['w']}x{s['h']} |")
    return "\n".join(lines)

def generate_floor_doc(floor):
    f_id = floor["id"]
    label = floor["label"]
    theme = floor["theme"]
    ambient = color_to_hex(floor["ambient_color"])

    zones = floor["zones"]
    sections = floor.get("sections", [])
    has_shopping = floor.get("has_shopping", True)
    has_checkout = floor.get("has_checkout", True)
    has_elevator = floor.get("has_elevator", True)
    has_stairs = floor.get("has_stairs", True)
    is_staff_only = floor.get("is_staff_only", False)
    is_rooftop = floor.get("is_rooftop", False)

    # Group zones by type for cleaner docs
    zone_types = {}
    for z in zones:
        ztype = z["type"]
        if ztype not in zone_types:
            zone_types[ztype] = []
        zone_types[ztype].append(z)

    doc = f"""# Floor {f_id} - {theme.title()} {f"({label})" if label != str(f_id) else ""}

**Theme:** {theme} | **Label:** {label} | **Ambient Color:** `{ambient}`

## Overview

Floor {f_id} is a **{theme}** themed floor{" (staff only)" if is_staff_only else ""}{" (rooftop)" if is_rooftop else ""}.

## Zones

| Zone | Position (x,y) | Size (wxh) | Name/Meta |
|------|----------------|-------------|-----------|
{get_zone_table(zones)}

## Sections

| Section ID | Position (x,y) | Size (wxh) |
|------------|----------------|-------------|
{get_sections_table(sections)}

## Zone Types Summary

"""

    for ztype, zlist in zone_types.items():
        names = [z.get("meta", {}).get("name", "-") for z in zlist]
        doc += f"- **{ztype}**: {len(zlist)} instance(s) - {', '.join(names)}\n"

    doc += f"""
## Properties

| Property | Value |
|----------|-------|
| has_shopping | {'true' if has_shopping else 'false'} |
| has_checkout | {'true' if has_checkout else 'false'} |
| has_elevator | {'true' if has_elevator else 'false'} |
| has_stairs | {'true' if has_stairs else 'false'} |
| is_staff_only | {'true' if is_staff_only else 'false'} |
| is_rooftop | {'true' if is_rooftop else 'false'} |

## Handler Files

"""

    # Determine handler file path based on floor
    if f_id == 0:
        doc += "- Config: `scripts/areas/floor_0/floor_0_config.gd`\n"
        doc += "- Handler: `scripts/areas/floor_0/floor_0_handler.gd`\n"
    elif f_id < 10:
        doc += f"- Handler: `scripts/areas/floor_{f_id}/floor_{f_id}_handler.gd`\n"
        doc += f"- Common: `scripts/areas/floor_{f_id}/floor_{f_id}_common_handler.gd`\n"
    else:
        doc += f"- Handler: `scripts/areas/floor_{f_id}/floor_{f_id}_handler.gd`\n"

    return doc

def main():
    with open(JSON_PATH, "r") as f:
        floors = json.load(f)

    output_dir = SCRIPT_DIR

    for floor in floors:
        f_id = floor["id"]
        doc = generate_floor_doc(floor)
        out_path = os.path.join(output_dir, f"floor_{f_id}.md")
        with open(out_path, "w") as f:
            f.write(doc)
        print(f"Generated: {out_path}")

    # Generate index
    index = """# Floors Overview

Generated documentation for all floors in Pixel Supermarket.

## Floor Index

| Floor | Label | Theme | Staff Only | Shopping | Checkout |
|-------|-------|-------|------------|----------|----------|
"""

    for floor in floors:
        f_id = floor["id"]
        label = floor["label"]
        theme = floor["theme"]
        staff = "Yes" if floor.get("is_staff_only", False) else "No"
        shopping = "Yes" if floor.get("has_shopping", True) else "No"
        checkout = "Yes" if floor.get("has_checkout", True) else "No"
        index += f"| [{f_id}](floor_{f_id}.md) | {label} | {theme} | {staff} | {shopping} | {checkout} |\n"

    index += """
## Structure

Each floor has:
- **Zone definitions** - rectangular areas with types (e.g., `ZONE_SHOES_RACK`, `ZONE_ELEVATOR`)
- **Section definitions** - retail sections within the floor
- **Properties** - flags for shopping, checkout, elevator, stairs, staff-only, rooftop

## Zone Type Legend

| Zone Type | Description |
|-----------|-------------|
| ZONE_COMMON | General walkable area |
| ZONE_ELEVATOR | Elevator shaft |
| ZONE_STAIRS | Staircase |
| ZONE_ESCALATOR | Escalator |
| ZONE_WC | Restroom |
| ZONE_AD | Advertising display |
| ZONE_ATM | ATM machine |
| ZONE_DECOR | Decorative element |
| ZONE_SECTION | Retail section marker |
"""

    # Add zone types based on what's in the data
    all_zones = set()
    for floor in floors:
        for zone in floor["zones"]:
            all_zones.add(zone["type"])

    for ztype in sorted(all_zones):
        index += f"| {ztype} | (see floor docs) |\n"

    with open(os.path.join(output_dir, "README.md"), "w") as f:
        f.write(index)
    print(f"Generated: {os.path.join(output_dir, 'README.md')}")

if __name__ == "__main__":
    main()
