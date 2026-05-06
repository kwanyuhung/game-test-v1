import json
with open('scripts/floor_config_data.json') as f:
    data = json.load(f)
for floor in data[:6]:
    print(f'Floor {floor["id"]}: sections={len(floor["sections"])}, zones={len(floor["zones"])}')
    if floor['sections']:
        print(f'  First section: {floor["sections"][0]}')
