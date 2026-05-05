# 🏪 Pixel Supermarket

A cozy pixel-art supermarket simulation built in **Godot 4.6**. Walk the aisles, browse 190+ products across 8 sections, chat with AI shoppers, play claw machines, and more.

**GitHub:** https://github.com/kwanyuhung/game-test-v1

---

## 🎮 What You Can Do

- **Browse sections** — Walk close to any section and press `E` to open the full product browser
- **Shop with quantity** — Add multiple of the same item, see details before buying
- **Checkout** — 3 lanes on the ground floor, printed receipt with tax breakdown
- **Ride the elevator** — Access 10 floors of shopping, parking, food court, arcade, and rooftop café
- **Chat with NPCs** — Press `C` near any AI shopper or staff member
- **Play claw machines** — Floor 8, 4 machines with different plush prize themes
- **Withdraw cash** — ATMS on the ground floor (PIN: 1234)
- **Fix maintenance issues** — Press `M` to open the maintenance panel, earn XP
- **Daily quests** — 3 quests per day with XP rewards, press `J` to check
- **Save/Load** — `F5` quick save, `F9` quick load, auto-saves on checkout/level-up
- **Telegram alerts** — Get notified on checkout, level-up, cart theft, and more

---

## 🕹️ Controls

| Key | Action |
|-----|--------|
| `W A S D` / Arrows | Move |
| `E` | Interact (browse section / checkout / use ATM / fix) |
| `ESC` | Close any panel |
| `Tab` | Toggle shopping cart panel |
| `C` | Chat with nearby NPC |
| `M` | Open Maintenance Panel |
| `P` | Open Stats Dashboard |
| `F5` | Quick save |
| `F9` | Quick load |
| `N` | Toggle mini-map |
| `L` | Toggle shopping list |
| `J` | Open quest journal |
| `O` | Settings (volume, speed, notifications) |
| `?` | Show controls tutorial |
| `1–9` | Quick-add product by number (in section view) |

---

## 🗺️ 10-Floor Building

| Floor | Theme | Highlights |
|-------|-------|------------|
| **G** Ground | Lobby + Food Street + Parking | 12 international food stalls, 3 checkout lanes, ATMs, 10 parking slots |
| **1** | Fresh Market | Dairy, Produce, Bakery, Meat/Deli — all browsable sections |
| **2** | Pantry | Rice, pasta, canned goods, spices |
| **3** | Beverages | Soft drinks, juice, coffee, tea |
| **4** | Snacks | Chips, crackers, candy, chocolate |
| **5** | Frozen Foods | Ice cream, frozen meals, frozen vegetables |
| **6** | Household | Cleaning supplies, paper goods |
| **7** | Health & Beauty | Pharmacy, cosmetics |
| **8** | **Arcade & Claw Machines** | 4 claw machines, neon-themed floor |
| **9** | Staff Room | Restricted lore area |
| **10** | Rooftop Café | Outdoor seating, café counter |

---

## 🛠️ Dev Setup

### Prerequisites
- **Godot 4.6** (with .NET support for GDScript 2)
- **PowerShell 5+**
- Telegram bot token (optional, for notifications)

### Running the Game
```powershell
.\run.ps1
# or open the project.godot file directly in Godot
```

### Dev Workflow Scripts

| Script | What It Does |
|--------|-------------|
| `dev.ps1` | Full pipeline: test → commit → push → Telegram summary |
| `autotest.ps1` | File watcher — auto-runs tests on `.gd` changes, alerts on 3 consecutive failures |
| `quick_commit.ps1` | Fast test + commit with a message |
| `notify.ps1` | Standalone Telegram notifier |

### Telegram Setup
1. Create a bot via **@BotFather** on Telegram
2. Add your token to `scripts/telegram_bot.gd` or set it as an environment variable
3. Start the bot and open the game — events will post automatically

---

## 🧪 Testing & Progress Viewing

### Best Tools for This Project

**In-Editor (Godot):**
- **Debugger** panel — Inspect variables, step through code, watch signals
- **Profiler** — Find performance bottlenecks in GDScript
- **Remote** scene tree — Inspect live nodes while the game runs
- **Animation playback** — Test claw machine animations, elevator transitions

**Automated Testing:**
```
.\test.ps1          # Run Godot in headless mode, check for script errors
.\autotest.ps1      # Continuous file watcher with crash detection
```

**Version Control & Progress:**
- **GitHub Issues** — Track features, bugs, milestones
- **GitHub Projects** — Kanban board for the 10-floor roadmap
- **GitHub Actions** — CI pipeline that runs `test.ps1` on every push

**Milestone Tracking:**
| Milestone | Contents |
|-----------|----------|
| Phase 1 ✅ | Multi-floor infrastructure — elevator, stairs, 10 floors |
| Phase 2 ✅ | Commerce — cart, checkout receipts, Telegram bot |
| Phase 3 ✅ | NPC system — 7 staff roles, 9 customer types, procedural appearances |
| Phase 4 ✅ | 24-hour clock, time-based lighting |
| Phase 5 ✅ | Parking lot, vehicles |
| Phase 6 ✅ | Maintenance system (M panel), XP rewards |
| Phase 8 ✅ | XP/level system, 12 achievements, stats dashboard |
| Phase 9 ✅ | AI customers auto-shop with carts |
| Phase 10 ✅ | ATMs with PIN entry |

See **[MILESTONES.md](MILESTONES.md)** for the full 10-floor expansion roadmap.

**Feature Changelog:**
See **[PHASES.md](PHASES.md)** for the phase-by-phase build history.

---

## 📁 Key Scripts

| Script | Purpose |
|--------|---------|
| `main.gd` | World builder, spawns floors/sections/player/NPCs |
| `section_browse.gd` | Section browser UI — category tabs, detail panel, qty selector |
| `store_data.gd` | 190+ products, SectionDef/MarketProduct classes |
| `shopping_cart.gd` | Quantity-aware cart, subtotal, tax |
| `player.gd` | WASD movement, cart, section detection |
| `floor_builder.gd` | Procedural tile rendering per floor |
| `floor_config.gd` | Floor/section definitions, food stall roster |
| `npc_controller.gd` | AI shoppers — pathfinding, task system, group behavior |
| `claw_machine.gd` | Claw machine game logic |
| `elevator.gd` | Elevator car, floor selector UI, transition animations |
| `telegram_bot.gd` | Telegram notification helper |
| `save_system.gd` | Save/load, receipt export |
| `audio_manager.gd` | Procedural audio (no external files) |

---

## 📊 Architecture

- **Engine:** Godot 4.6 (Forward+, 2D pixel art)
- **Resolution:** 320×180 game pixels, integer scaling to fullscreen
- **Sprites:** 100% procedural via `pixel_art_generator.gd` — zero external assets
- **Audio:** 100% procedural via `audio_manager.gd` — zero external audio files
- **AI:** GDScript 2 coroutines for NPC behavior, no external AI needed
- **Persistence:** JSON save files in Godot `user://` directory

---

_Current features: 10 floors, 190+ products, 8 sections, 6 AI shoppers, procedural sprites/audio, save/load, claw machines, ATMs, chat system, maintenance, quests, achievements, Telegram integration._
