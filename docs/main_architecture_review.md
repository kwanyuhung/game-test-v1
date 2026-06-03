# Main 架构评审 — `main.gd` 分析与 `MainManager` 重构方案

> **状态：** 待评审草稿
> **作者：** Claude Code review
> **日期：** 2026-05-30

---

## 1. 概述

`main.gd` 是一个**约 1860 行的 Godot 2D Node2D**，作为整个游戏的中央协调器。它目前持有：
- **约 180 个实例变量**（状态）
- **约 65 个预加载脚本引用**
- **约 60+ 个函数定义**
- **零有意义封装** — 每个系统都作为原始变量堆在一个类里

游戏共有 15 层楼，包含完整的 NPC 经济系统、购物/结账、仓库收货、员工管理、商业模式、任务、品牌、促销、防盗、动态定价等功能 — 所有逻辑都通过 `main.gd` 连接。

---

## 2. 当前组件创建流程

### 2.1 入口调用链

```
main.gd _ready()
  └─ main_init.setup(self)        # 创建所有子节点组件
	   └─ init_all()               # 约 300 行顺序组件设置
			├─ add_to_group("main")
			├─ MainConfig (child node)
			├─ MainPanels.new().setup()  # UI 构建器（电梯、楼梯、停车场、HUD）
			├─ MainSpawner.new().setup() # 玩家 + NPC 生成
			├─ GameClock (child node)     # 时间系统
			├─ PriceOverride (child node)
			├─ BrandManager (child node)
			├─ PromotionManager (child node)
			├─ StoreExpansion (child node)
			├─ AntiTheft (child node)
			├─ DynamicPricing (child node)
			├─ SupplierManager (child node)
			├─ BrandPortal (child node)
			├─ MaintenanceSystem (child node)
			├─ MaintenanceVisual (child node)
			├─ WarehouseSystem (child node)
			├─ PlayerStats (child node)
			├─ ChatManager (child node)
			├─ ProximitySystem (child node)
			├─ CheckoutSystem (child node)
			├─ FoodCourtSystem (child node)
			├─ TruckDockSystem (child node)
			├─ StairsSystem (child node)
			├─ FloorManager (child node)   # 多楼层 LOD，预构建所有楼层
			├─ AudioManager (通过 get_node_or_null — 单例模式)
			├─ SaveHintLabel（内联创建的 Label）
			├─ SaveSystem.load_game()      # 可能还会创建 TutorialOverlay
			├─ MiniMap (child node)
			├─ ToastManager (child node)
			├─ FloatingText (child node)
			├─ FadeTransition (child node)
			├─ DailyBonus (child node)
			├─ ShoppingList (child node)
			├─ LoyaltyPanel (Node2D child)
			├─ QuestSystem (child node)
			├─ QuestJournal (child node)
			├─ SettingsPanel (child node)
			├─ PauseMenu (child node)
			├─ StatsDashboard (child node)
			├─ InteractionBubble (child node)
			├─ DebugBounds (child node)
			├─ SectionBrowse (child node)
			├─ FoodStallBrowse (child node)
			├─ DevTools (child node, 仅 DEV_MODE)
			├─ DebugSpriteViewer (child node)
			└─ ShelfPanel (child node)
```

### 2.2 init_all 之后的次级构建步骤

`main_init.init_all()` 之后接着 `main.gd._build_floor(0)`（在 `init_all()` 内部调用），其执行：

```
_build_floor(idx)
  ├─ _clear_floor_nodes()          # 移除旧楼层内容、NPC、机器人
  ├─ _main_panels.build_floor_hud() # 每层楼的 HUD 标签
  ├─ FloorBuilder.new().build()    # 为当前楼层渲染 TileMap 区域
  ├─ 收集 sections、checkout_counters、food_stalls、claw_machines、escalators
  ├─ 连接 section/stall/claw/escalator 信号
  ├─ WarehouseFloor.new()          # 11 楼仓库控制器
  └─ _spawn_robots()              # AI 机器人员工
```

### 2.3 玩家与 NPC 生成（通过 MainSpawner）

`MainSpawner`（作为 `_main_spawner` 引用）负责：
- `spawn_player()` → 创建 Player 节点
- `build_npcs()` → 在每层楼生成员工和顾客
- `spawn_npc_staff()`、`spawn_customer()`、`spawn_customer_group()`
- `spawn_robots()`、`spawn_robot_humanoid()`、`spawn_robot_single()`
- `spawn_scan_go_companion()`、`remove_scan_go_companion()`
- 开发测试辅助：`spawn_test_customers()`、`spawn_test_staff()`

---

## 3. 组件清单 — 当前状态

### 3.1 分类与所有权

| 分类 | 组件 | 创建位置 | 访问方式 |
|------|------|----------|----------|
| **World（世界）** | FloorBuilder, FloorManager, MainSpawner, TileMapBuilder, SectionBrowse, StoreData | main_init / main | 直接变量 |
| **Player（玩家）** | Player | MainSpawner | `_player` 变量 |
| **NPCs** | NPCController, RobotController, ActorData, AIChatBrain | MainSpawner | `_npcs[]`、`_robots[]` |
| **Systems（系统）** | ProximitySystem, CheckoutSystem, FoodCourtSystem, TruckDockSystem, StairsSystem, MaintenanceSystem, WarehouseSystem, AntiTheft, DynamicPricing, StoreExpansion, SupplierManager, PriceOverride, PromotionManager | main_init | 直接变量 |
| **Elevator（电梯）** | Elevator | MainPanels | `_elevator` 变量 |
| **Floor Infrastructure（楼层基础设施）** | ParkingLot, StairsNode | MainPanels | `_parking_lot`、`_stairs_node` |
| **Warehouse（仓库）** | WarehouseFloor | _build_floor() | `_warehouse_floor` 变量 |
| **Managers（管理器）** | GameClock, PlayerStats, ChatManager, BrandManager, BrandPortal, SaveSystem, AudioManager, RobotPanelSystem | main_init | 直接变量 |
| **UI Managers（UI 管理器）** | ToastManager, MiniMap, InteractionBubble, FloatingText, FadeTransition | main_init | 直接变量 |
| **Panels（面板，ALONE 策略）** | StatsPanel, MaintenancePanel, ATMPanel, MonitorPanel, PriceTerminal, SectionBrowse, FoodStallBrowse, BusinessMode, QuestJournal, SettingsPanel, PauseMenu, StatsDashboard, MapPanel, FloorPanel, DevTools, ShelfPanel, TutorialOverlay, DailyBonus, ShoppingList, LoyaltyPanel, FloorJumpPanel, AchievementPopup, ChatPanel | 内联 `new()` + add_child | 带 `_panel` 后缀的直接变量 |
| **Helpers（辅助工具）** | MainInit, MainPanels, MainHUD, MainConfig, DebugBounds, DebugSpriteViewer | main_init | `_main_init`、`_main_panels` 等 |

### 3.2 当前架构问题

#### 问题 1：`main.gd` 是一个"上帝对象"
`main.gd` 直接持有约 180 个实例变量，涵盖 10+ 个不同领域。添加一个新系统意味着在这里添加 2-5 个变量、连接 3-5 个信号、写 5-20 行输入处理 — 全都在同一个文件里。

#### 问题 2：`main.gd._input()` 长达 140 行
`_input()` 函数处理：楼梯 W/S、聊天 C、开发者 F3、保存 F5、加载 F9、购物清单 L、楼层跳转 T、地图 M、楼层面板 V、装修 X、抓小偷 F、品牌 B/Shift+B、任务日志 J、机器人 R、设置 O、暂停 P/Space、员工模式 K、数字气泡 0-9、仓库设备 WASD/Q/E/F/H，以及临时点餐数字键。每一个都可以活在各自对应的系统管理器里。

#### 问题 3：没有清晰的所有权边界
当 `_process()` 中调用 `_proximity_system.update_all()` 时，是 `main.gd` 在调用它。系统不拥有自己的更新循环 — `main.gd` 驱动所有系统。

#### 问题 4：到处都是直接变量访问
像 `_on_streak_reward()` 这样的函数用 `var audio = get("_audio")` 而不是使用类型化 getter。代码使用 `get("_xxx")` / `set("_xxx", ...)` 作为伪动态属性系统，绕过了 Godot 的类型检查器和 IDE 自动补全。

#### 问题 5：输入通过 main 路由
`PanelManager.is_input_blocked()` 在 `main.gd._input()` 中检查，然后所有键事件在一个巨大的 `match` 块中匹配。面板级输入应由面板或专用输入管理器处理。

#### 问题 6：信号连接是手动的且分散的
每个组件在 `main_init` 中手动将其信号连接到 `main.gd._on_*` 方法。没有中央信号注册表或约定。

---

## 4. Proposed Architecture: `MainManager` Super-Manager

### 4.1 设计目标

1. **将 `main.gd` 缩减为薄协调器** — 它应该持有子管理器的引用并路由全局事件，而不是实现领域逻辑。
2. **子管理器拥有各自的领域** — 每个管理器持有其组件、运行其 `_process()`，并暴露类型化 getter。
3. **类型化信号总线** — 子管理器通过 `MainManager` 上的类型化信号通信，而不是通过 `main.gd` 作为中介。
4. **最小化重构风险** — 保持 `main.gd` 作为场景根节点；只切割出逻辑分组。

### 4.2 提议的子管理器结构

```
MainManager（新类，替代 main.gd 的直接变量堆砌）
├── WorldManager        # 楼层、TileMap、区域、结账柜台
├── CharacterManager    # 玩家、NPC、机器人、生成逻辑
├── SystemManager       # 所有游戏系统（邻近、结账、美食街等）
├── UIManager          # 所有面板、HUD 元素、Toast、Minimap
├── CommandManager      # 输入处理、按键绑定、动作路由
└── AssetManager       # 音频、保存、配置

MainManager 还持有：
├── _elevator (Elevator)         # 楼层间导航
├── _game_clock (GameClock)      # 实时系统
└── _current_floor_idx (int)    # 楼层导航状态
```

### 4.3 子管理器职责

#### `WorldManager`
- **拥有：** FloorBuilder, FloorManager, MainSpawner, SectionBrowse, StoreData
- **暴露：** `get_floor()`、`get_sections()`、`get_checkout_counters()`、`rebuild_floor()`、`set_current_floor()`
- **委托给：** 当前 `main.gd` 中的 `_build_floor()` 逻辑

#### `CharacterManager`
- **拥有：** Player, NPCs 数组, Robots 数组, ActorData, AIChatBrain
- **暴露：** `get_player()`、`get_npcs()`、`get_robots()`、`spawn_player()`、`spawn_npc_staff()`、`spawn_customer()`
- **委托给：** `MainSpawner`

#### `SystemManager`
- **拥有：** ProximitySystem, CheckoutSystem, FoodCourtSystem, TruckDockSystem, StairsSystem, MaintenanceSystem, WarehouseSystem, AntiTheft, DynamicPricing, StoreExpansion, SupplierManager, PriceOverride, PromotionManager, WarehouseFloor, Elevator
- **暴露：** `get_proximity_system()`、`get_checkout_system()`、`get_maintenance_system()`、`get_warehouse()`、`get_elevator()` 等
- **拥有：** `update_all_systems()` — 调用所有需要的系统的 `_process()`

#### `UIManager`
- **拥有：** 所有面板实例（StatsPanel、MaintenancePanel、ChatPanel 等）、ToastManager、MiniMap、InteractionBubble、FloatingText、FadeTransition、QuestJournal、SettingsPanel、PauseMenu、StatsDashboard、MapPanel、FloorPanel、DevTools、ShelfPanel、TutorialOverlay、DailyBonus、ShoppingList、LoyaltyPanel、FloorJumpPanel、AchievementPopup、SectionBrowse、FoodStallBrowse、BusinessMode
- **暴露：** `show_panel()`、`hide_panel()`、`toggle_panel()`、`show_toast()`、`register_panel()`
- **拥有：** `PanelManager` 使用 — 所有 ALONE 策略面板在此注册

#### `CommandManager`
- **拥有：** 输入处理、按键绑定映射、动作路由
- **暴露：** `handle_input(event)`、`bind_action(key, callback)`
- **委托给：** `PanelManager` 进行输入阻塞检查，然后路由到相应系统

#### `AssetManager`
- **拥有：** AudioManager, SaveSystem, MainConfig, DebugBounds, DebugSpriteViewer
- **暴露：** `play_sfx()`、`save_game()`、`load_game()`

### 4.4 信号总线（提案）

```
MainManager 发出信号：
  - floor_changed(floor_idx: int)       # 楼层切换
  - player_interacted(target)            # 玩家交互
  - game_paused()                       # 游戏暂停
  - game_resumed()                      # 游戏恢复
  - day_changed()                       # 天数变化
  - hour_changed(hour: int)             # 小时变化

子管理器按需订阅：
  - SystemManager 监听 floor_changed → 更新系统引用
  - UIManager 监听 floor_changed → 更新 HUD
  - CharacterManager 监听 floor_changed → 为当前楼层重新生成 NPC
```

### 4.5 迁移计划（分阶段）

| 阶段 | 目标 | 变更内容 |
|------|------|----------|
| **阶段 1** | 记录当前状态 | 本文档 |
| **阶段 2** | 提取 `WorldManager` | 将楼层/区域/结账状态从 main.gd 移至新的 WorldManager 类 |
| **阶段 3** | 提取 `CharacterManager` | 将玩家/NPC/机器人状态和 MainSpawner 移入 CharacterManager |
| **阶段 4** | 提取 `SystemManager` | 将所有 *System 节点整合到一个管理器下并提供类型化 getter |
| **阶段 5** | 提取 `UIManager` | 将所有 UI 面板创建和 ToastManager 整合到 UIManager 下 |
| **阶段 6** | 提取 `CommandManager` | 将 `_input()` 重构为 CommandManager 中的按键绑定映射 |
| **阶段 7** | 精简 `main.gd` | 将 main.gd 缩减至约 100 行：持有子管理器、路由全局信号、实现游戏循环 |

### 4.6 新文件结构

```
scripts/
├── core/
│   ├── main.gd                      # 薄协调器（约 100 行）
│   ├── main_init.gd                 # 启动脚本，将 main 添加到场景
│   ├── main_panels.gd               # [现有] 面板构建器
│   ├── main_hud.gd                 # [现有] HUD 构建器
│   ├── main_config.gd              # [现有] 配置数据
│   └── main_manager/
│       ├── main_manager.gd         # 新建：超级管理器容器
│       ├── world_manager.gd        # 新建：楼层、区域、结账
│       ├── character_manager.gd    # 新建：玩家、NPC、机器人
│       ├── system_manager.gd       # 新建：所有游戏系统
│       ├── ui_manager.gd           # 新建：所有 UI 面板
│       ├── command_manager.gd      # 新建：输入处理
│       └── asset_manager.gd        # 新建：音频、保存
```

---

## 5. 验证清单

- [ ] `main.gd._on_*` 的所有现有信号仍能正确触发
- [ ] 所有 `_input()` 按键处理器映射到相同的动作
- [ ] `SaveSystem.load_game()` / `save_game()` 仍能恢复完整状态
- [ ] `PanelManager` ALONE 策略仍能在面板打开时阻止输入
- [ ] 楼层切换（电梯 + 楼梯）在所有 15 层楼仍能正常工作
- [ ] NPC 仍能正确在每层楼生成和更新
- [ ] 所有开发工具（F3、F5、F9）仍能正常使用
- [ ] 游戏在任何楼层运行时没有空引用警告

---

## 6. 待评审开放问题

1. **改造 vs. 重写** — `main.gd` 应该原地重构，还是应该创建新的 `MainManager` 类并让 `main.gd` 成为薄 `Node2D` 外壳？
2. **信号总线耦合** — 子管理器互相订阅对方的信号会产生耦合。共享 `MainManager` 信号总线是否可接受，还是应该优先使用直接注入（管理器 A 获取管理器 B 的引用）？
3. **PanelManager 所有权** — `PanelManager` 目前是全局单例。它应该成为 `UIManager` 的属性，还是保持全局？
4. **FloorManager 关系** — `FloorManager` 已经像世界的一个子管理器。它应该重命名为 `WorldManager` 并吸收，还是作为新 `WorldManager` 内部的专门楼层管理器保留？
5. **Godot 场景 vs. 纯 GDScript** — 子管理器应该是添加到 `main.tscn` 的 Godot 场景（`*.tscn`），还是通过 `add_child` 添加的纯 GDScript 类？（当前模式是纯 GDScript）
6. **如何处理 `get()`/`set()` 动态访问** — `main.gd` 中多处使用 `get("_xxx")` 来获取组件。重构后是否应该强制所有地方使用类型化 getter？
