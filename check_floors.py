import json

with open('scripts/floor_config_data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
print(f'Total floors in JSON: {len(data)}')
for floor in data:
    print(f'  Floor {floor["id"]}: {floor["label"]} ({floor["theme"]}) - {len(floor["zones"])} zones, {len(floor["sections"])} sections')
