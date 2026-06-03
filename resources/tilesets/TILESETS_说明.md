# 资源/瓦片集 (Tilesets) 目录说明

本目录包含 Pixel Supermarket 游戏的瓦片集资源，用于 Godot 4 的 TileMap 系统。

---

## 目录结构

```
resources/tilesets/
├── floor_tileset.tres          # Godot 4 TileSet 资源文件
├── ARTIST_README.md             # 美术设计规范（英文）
├── BATCH_GENERATE.md            # 批量生成策略（英文）
├── generate_tileset.py          # TileSet 生成脚本
├── generate_tiles.py             # 瓦片图片生成脚本
└── generated_tiles/             # 生成的瓦片图片目录
	├── tile_atlas.png           # 瓦片图集（所有瓦片合并）
	├── blocked.png              # 阻挡瓦片（不可行走区域）
	├── floor_*.png              # 地面瓦片（15种）
	├── table.png                # 装饰：桌子
	├── plant.png                # 装饰：植物
	├── kiosk.png                # 装饰：信息亭
	├── atm.png                  # 装饰：ATM机
	├── vending_machine.png      # 装饰：贩卖机
	└── promo_booth.png          # 装饰：促销展位
```

---

## 瓦片类型

### 地面瓦片 (Layer 0)

| ID | 文件名 | 描述 | 颜色 |
|----|--------|------|------|
| 0 | `blocked.png` | 阻挡区域（黑色实心） | #000000 |
| 1 | `floor_lobby.png` | 大堂地面 | 米黄大理石 |
| 2 | `floor_common.png` | 普通走廊 | 中性灰 |
| 3 | `floor_warehouse.png` | 仓库地面 | 深灰混凝土 |
| 4 | `floor_food_court.png` | 美食广场 | 暖棕 |
| 5 | `floor_wc.png` | 洗手间 | 浅灰瓷砖 |
| 6 | `floor_parking.png` | 停车场 | 深沥青灰 |
| 7 | `floor_rooftop.png` | 天台 | 浅米灰 |
| 8 | `floor_pet_adoption.png` | 宠物区 | 暖米色 |
| 9 | `floor_truck_dock.png` | 卸货区 | 深灰+黄线 |
| 10 | `floor_forklift.png` | 叉车区 | 中灰 |
| 11 | `floor_conveyor.png` | 传送带 | 金属银 |
| 12 | `floor_storage_shelf.png` | 仓储区 | 深灰 |
| 13 | `floor_shoes.png` | 鞋区 | 暖棕地毯 |
| 14 | `floor_dress.png` | 服装区 | 冷灰地毯 |
| 15 | `floor_sport.png` | 运动区 | 绿灰橡胶 |

### 装饰瓦片 (Layer 2)

| ID | 文件名 | 描述 |
|----|--------|------|
| 200 | `table.png` | 餐桌 |
| 201 | `plant.png` | 盆栽植物 |
| 202 | `kiosk.png` | 信息亭 |
| 203 | `atm.png` | ATM机 |
| 204 | `vending_machine.png` | 贩卖机 |
| 205 | `promo_booth.png` | 促销展位 |

---

## 文件说明

### `generate_tiles.py`

使用 MiniMax AI API 生成像素艺术瓦片图片。

**前置要求：**
```bash
pip install requests python-dotenv Pillow
```

**环境变量：**
```bash
export MINIMAX_API_KEY=your_api_key
```

**使用方法：**
```bash
cd resources/tilesets
python generate_tiles.py
```

**生成内容：**
- 15种地面瓦片 (16x16 PNG)
- 6种装饰瓦片
- 1个瓦片图集 (tile_atlas.png)

---

### `generate_tileset.py`

将生成的瓦片图片打包成 Godot 4 的 TileSet 资源文件。

**前置要求：**
```bash
pip install Pillow
```

**使用方法：**
```bash
cd resources/tilesets
python generate_tileset.py
```

**输出：**
- `generated_tiles/tile_atlas.png` - 合并后的图集
- `floor_tileset.tres` - Godot 4 TileSet 资源

---

## TileSet 结构 (Godot 4)

`floor_tileset.tres` 文件结构：

```
[gd_resource type="TileSet" format=3]
├── ext_resource: 各瓦片图片引用 (uid://...)
├── sub_resource: TileSetAtlasSource 每个瓦片一个
└── resource:
	├── resource_name = "Floor TileSet"
	├── tile_shape = 1 (正方形)
	├── tile_layout = 5
	├── tile_size = Vector2i(16, 16)
	└── sources/0-21 = SubResource 各瓦片源
```

瓦片 ID 映射：
- `sources/0` = blocked (阻挡)
- `sources/1` = atm
- `sources/2` = floor_common
- `sources/3` = floor_shoes
- ...以此类推

---

## 美术规范

### 像素尺寸
- **基准：** 16x16 像素
- **风格：** 像素艺术，无抗锯齿，边缘清晰

### 颜色参考

| 区域 | 颜色代码 |
|------|----------|
| 大堂/暖色 | #8B7355 (Tan), #C4A77D (Sand) |
| 普通/中性 | #4A4A4A, #6B6B6B |
| 仓库 | #3D3D3D, #5C5C5C |
| 绿色/自然 | #4A7C3F, #6B9B5A |
| 食品区 | #8B6B4A, #A68B6B |

### UI/标记颜色
```
玩家高亮: #00FFAA (青绿)
机器人标记: #32CD32 (绿), #FFD700 (金), #FF4444 (红)
```

---

## 工作流程

1. **生成瓦片** - 运行 `generate_tiles.py` 调用 MiniMax API
2. **打包图集** - 运行 `generate_tileset.py` 生成 atlas 和 .tres
3. **导入 Godot** - Godot 自动读取 `floor_tileset.tres`
4. **使用 TileMap** - 在场景中引用 TileSet 构建地图

---

## 相关代码文件

| 文件 | 说明 |
|------|------|
| `scripts/world/tilemap_builder.gd` | TileMap 构建逻辑 |
| `scripts/world/floor_config.gd` | 区域与瓦片ID映射 (`get_tile_for_zone()`) |
| `scripts/floor_config_data.json` | 区域布局配置 |
