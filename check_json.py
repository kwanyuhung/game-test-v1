import json

with open("scripts/floor_config_data.json") as f:
    data = json.load(f)
for floor in data[:5]:
    print(f'Floor {floor["id"]}: {floor["label"]} - {len(floor["zones"])} zones, {len(floor["sections"])} sections')
    for z in floor['zones'][:3]:
        print(f'  {z}')
    if floor['sections']:
        print(f'  Sections: {floor["sections"][:2]}')
