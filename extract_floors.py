import re
import json

with open('scripts/floor_config.gd', 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r'func _init_floors\(\) -> void:(.+?)\nstatic func get_floor', content, re.DOTALL)
body = match.group(1)
parts = re.split(r'FLOOR_DEFS\.append\(FloorDef\.new\(', body)

def parse_floor(block):
    first_bracket = block.find('[')
    if first_bracket == -1:
        return None
    header = block[:first_bracket]
    nums = re.findall(r'\d+', header)
    if not nums:
        return None
    floor_id = int(nums[0])
    labels = re.findall(r'"([^"]+)"', header)
    label = labels[0] if labels else ""
    theme = labels[1] if len(labels) > 1 else ""
    color_m = re.search(r'Color\(([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\)', header)
    ambient_color = ([float(color_m.group(1)), float(color_m.group(2)), float(color_m.group(3))]
                    if color_m else [0.5, 0.5, 0.5])
    after_header = block[first_bracket:]

    depth = 0
    zones_start = -1
    for j, c in enumerate(after_header):
        if c == '[':
            if zones_start == -1:
                zones_start = j
            depth += 1
        elif c == ']':
            depth -= 1
            if depth == 0:
                zones_end = j
                zones_content = after_header[zones_start+1:zones_end]
                sections_rest = after_header[zones_end+1:].lstrip(',\n\t ')
                break

    zones = []
    for line in zones_content.split('\n'):
        line = line.strip().rstrip(',')
        if not line or line.startswith('#'):
            continue
        m = re.match(r'Z\((\w+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)(.*)\)', line)
        if m:
            zone = {"type": m.group(1), "x": int(m.group(2)), "y": int(m.group(3)),
                    "w": int(m.group(4)), "h": int(m.group(5))}
            extra = m.group(6).strip()
            if extra.startswith(','):
                meta_str = extra[1:].strip()
                if meta_str.startswith('{') and meta_str.endswith('}'):
                    meta_str = meta_str[1:-1]
                    meta = {}
                    for cm in re.findall(r'Color\(([^)]+)\)', meta_str):
                        try:
                            meta['color'] = [float(x.strip()) for x in cm.split(',')]
                        except: pass
                    for sm in re.findall(r'"([^"]+)"', meta_str):
                        if sm not in ('color',):
                            meta['name'] = sm
                    for kv in re.findall(r'(\w+):\s*([0-9.]+)', meta_str):
                        meta[kv[0]] = float(kv[1])
                    for kv in re.findall(r'(\w+):\s*"([^"]+)"', meta_str):
                        meta[kv[0]] = kv[1]
                    zone['meta'] = meta if meta else {}
            zones.append(zone)

    sections = []
    bools = []
    if sections_rest.startswith('['):
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
        if sec_end > 0:
            sections_content = sections_rest[1:sec_end]
            bools_rest = sections_rest[sec_end+1:].lstrip(',\n\t ')
            for line in sections_content.split('\n'):
                line = line.strip().rstrip(',')
                if not line or line.startswith('#'):
                    continue
                m = re.match(r'SZ\("(\w+)",\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)', line)
                if m:
                    sections.append({"id": m.group(1), "x": int(m.group(2)), "y": int(m.group(3)),
                                    "w": int(m.group(4)), "h": int(m.group(5))})
        else:
            bools_rest = sections_rest
    else:
        bools_rest = sections_rest

    bools = [w == 'true' for w in re.findall(r'\b(true|false)\b', bools_rest)]
    bools = bools[-6:] if len(bools) >= 6 else bools

    return {
        "id": floor_id, "label": label, "theme": theme, "ambient_color": ambient_color,
        "zones": zones, "sections": sections,
        "has_shopping": bools[0] if len(bools) > 0 else True,
        "has_checkout": bools[1] if len(bools) > 1 else True,
        "has_elevator": bools[2] if len(bools) > 2 else True,
        "has_stairs": bools[3] if len(bools) > 3 else True,
        "is_staff_only": bools[4] if len(bools) > 4 else False,
        "is_rooftop": bools[5] if len(bools) > 5 else False,
    }

floors = []
for part in parts[1:]:
    f = parse_floor(part)
    if f:
        floors.append(f)

print(f"Total floors: {len(floors)}")
for f in floors:
    print(f"  Floor {f['id']}: {f['label']} ({f['theme']}) - {len(f['zones'])} zones, {len(f['sections'])} sections")

with open('scripts/floor_config_data.json', 'w', encoding='utf-8') as f:
    json.dump(floors, f, indent="\t")
print("Written!")
