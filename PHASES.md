# 🏪 Supermarket — Phases Roadmap

## Phase 1 ✅ Core World
Basic supermarket with 8 sections, player movement, section browsing.

## Phase 2 ✅ Commerce
Food stalls (12 cuisines), shopping cart, checkout receipts, Telegram bot.

## Phase 3 ✅ NPC System
Full NPC characters — 7 staff roles, 9 customer group types, customizable appearances (hair, makeup, glasses, accessories, shoes), babies in strollers, groups moving together.

## Phase 3b ✅ Chat & Pet Floor
- **Chat**: Press C near any NPC → chat panel opens → type messages → AI responds contextually. NPCs also chat with each other autonomously (proximity-based, every ~15s).
- **Pet Paradise (Floor 11)**: Adoption corner with dog/cat/rabbit in kennels, pet food shelves, 25+ pet products.

## Phase 4 ✅ Time & Lighting
24-hour game clock. Store opens 06:00, closes 23:00. Floor lighting changes by time of day. Customer spawn rate varies with time. Staff shift schedules.

## Phase 5 ✅ Parking Lot & Vehicles
Ground floor parking zone, parked NPC cars, parking attendant, player can see slot numbers.

## Phase 6 🔧 24-Hour Ops & Maintenance (DONE)
**Theme: Realistic store operations with issues and repairs**

### Features:
- **24/7 Operation**: Store never fully closes — but floors can be taken offline for maintenance
- **Maintenance System**: Issues spawn randomly (spills, broken equipment, power flickers, stock depletion, angry customers)
- **Issue Types**: Spill, Broken Light, Out-of-Stock, Machine Malfunction, Security Alert, Lost Child, Cleanup Needed, Power Flicker
- **Maintenance Tasks**: Staff or player can pick up and resolve tasks
- **Floor Maintenance Mode**: A floor can be flagged "under maintenance" — visually shows caution tape, NPCs avoid it
- **Shift Reports**: End-of-shift summary of resolved issues
- **Controls**:
  - `M` — Open Maintenance Panel (see all open issues, select one to go fix)
  - `E` (near issue) — Resolve the issue and earn XP
  - Issues appear as distinct sprites in the world (puddles, warning cones, etc.)
  - High-urgency issues pulse with animation

### Issue Types:
| Type | Urgency | Fix Time | XP |
|------|---------|----------|-----|
| Wet Floor Spill | Medium | 8s | 10 |
| Broken Light | Low | 15s | 10 |
| Stock Runout | Low | 20s | 10 |
| Machine Malfunction | Medium | 30s | 10 |
| Security Alert | High | 12s | 15 |
| Lost Child | High | 25s | 25 |
| Cleanup Required | Low | 18s | 10 |
| Power Flicker | Medium | 22s | 10 |

## Phase 7 ⏭️ Skipped

## Phase 8 🏆 Player Progression & Stats (DONE)
**Theme: Track your supermarket career**

### Features:
- **Player Level & XP**: Earn XP from shopping, resolving issues, helping staff, winning claw machines
- **XP Sources**:
  - Buy item: +2 XP
  - Resolve issue: +10 XP
  - Browse section: +5 XP
  - Full cart checkout (10+ items): +20 XP
  - Win claw machine: +15 XP
  - Adopt a pet: +50 XP
  - Help lost child: +25 XP
- **12 Achievements** with icons and XP rewards:
  - First Purchase, Full Cart, Issue Fixer (5 issues), Hero of the Floor (25 issues)
  - Collector (20 unique products), Big Spender ($500 total spent)
  - Claw Champion (5 wins), Animal Friend (adopt pet)
  - Social Butterfly (10 NPC chats), World Explorer (all 12 floors)
  - Regular Customer (20 checkouts), Chatty Patty (50 chats)
  - Supermarket Master (reach Level 10)
- **Achievement Popup**: Shows top-center when unlocked with icon and XP
- **Stats Dashboard**: Press `P` to view all lifetime stats
- **Level-Up Notification**: On-screen notification + Telegram when you level up

### Controls:
| Key | Action |
|-----|--------|
| `P` | Open Stats Dashboard |
| `M` | Open Maintenance Panel |
| `C` | Chat with nearby NPC |
| `E` | Interact / Fix issue |
| `ESC` | Close any panel |

---

_Current: Phase 6 + Phase 8 Complete_
