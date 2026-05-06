import re
import json

with open('scripts/floor_config.gd', 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r'func _init_floors\(\) -> void:(.+?)\nstatic func get_floor', content, re.DOTALL)
body = match.group(1)
parts = re.split(r'FLOOR_DEFS\.append\(FloorDef\.new\(', body)

# For floor 1 (shoes), look at sections parsing
for part in parts:
    if '"shoes"' in part:
        first_bracket = part.find('[')
        header = part[:first_bracket]
        after_header = part[first_bracket:]

        # Find zones array - first [ ]
        depth = 0
        zones_start = -1
        zones_end = -1
        for j, c in enumerate(after_header):
            if c == '[':
                if zones_start == -1:
                    zones_start = j
                depth += 1
            elif c == ']':
                depth -= 1
                if depth == 0:
                    zones_end = j
                    break

        zones_content = after_header[zones_start+1:zones_end]
        sections_rest = after_header[zones_end+1:].lstrip()

        print(f"zones_content (first 100 chars): {repr(zones_content[:100])}")
        print(f"sections_rest (first 200 chars): {repr(sections_rest[:200])}")

        # Check: does sections_rest start with [SZ( ?
        print(f"Starts with [SZ ?: {sections_rest.startswith('[SZ(')}")
        print(f"Starts with [: {sections_rest.startswith('[')}")

        # Find ] for sections
        depth2 = 0
        sec_end = -1
        for j2, c2 in enumerate(sections_rest):
            if c2 == '[':
                depth2 += 1
            elif c2 == ']':
                depth2 -= 1
                if depth2 == 0:
                    sec_end = j2
                    break

        print(f"sec_end = {sec_end}")
        if sec_end > 0:
            sections_content = sections_rest[1:sec_end]
            print(f"sections_content: {repr(sections_content[:200])}")

            # Parse SZ
            for line in sections_content.split('\n'):
                line = line.strip().rstrip(',')
                print(f"  Section line: {repr(line)}")
                m = re.match(r'SZ\("(\w+)",\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)', line)
                if m:
                    print(f"    MATCHED: id={m.group(1)} x={m.group(2)}")
        break
