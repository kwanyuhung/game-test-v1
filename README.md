# 🏪 Pixel Supermarket

A cozy pixel-art supermarket simulation built in **Godot 4.6**. Walk the aisles, browse 190+ products across 18 floors, chat with AI shoppers, play mini-games, and more.

**GitHub:** https://github.com/kwanyuhung/game-test-v1

---

## 🎮 What You Can Do

- **Browse sections** — Walk close to any section and press `E` to open the full product browser
- **Shop with quantity** — Add multiple of the same item, see details before buying
- **Checkout** — 3 lanes on the ground floor, printed receipt with tax breakdown + loyalty savings
- **Ride the elevator** — Access 18 floors of shopping, dining, and entertainment
- **Floor panel** — Press `V` to open a clickable floor selector for quick navigation between floors
- **Chat with NPCs** — Press `C` near any AI shopper or staff member
- **Play claw machines** — Floor 8 and Floor 17, multiple machines with different prize themes
- **Play mini-games** — Karaoke (Floor 17), Pool Table, Darts — each gives XP rewards!
- **Withdraw cash** — ATMs on the ground floor (PIN: 1234)
- **Gift wrapping** — Wrap your cart before checkout for bonus XP + tip
- **Daily quests** — 3 quests per day with XP rewards, press `J` to check
- **Save/Load** — `F5` quick save, `F9` quick load, auto-saves on checkout/level-up
- **Telegram alerts** — Get notified on checkout, level-up, cart theft, delivery arrivals, and more

---

## 🕹️ Controls

| Key | Action |
|-----|--------|
| `W A S D` / Arrows | Move |
| `E` | Interact (browse section / checkout / use ATM / play mini-game) |
| `ESC` | Close any panel |
| `Tab` | Toggle shopping cart panel |
| `C` | Chat with nearby NPC |
| `H` | Hire staff (staff mode) |
| `F` | Catch thief / Fire staff (staff mode) |
| `K` | Toggle staff/business mode |
| `L` | Toggle shopping list |
| `J` | Open quest journal |
| `M` | Toggle map panel |
| `V` | Floor panel (clickable floor selector) |
| `P` | Pause menu |
| `O` | Settings (volume, speed, notifications) |
| `X` | Renovation panel (staff mode) |
| `R` | Restock nearby section (staff mode) |
| `B` | Business mode overview |
| `F5` | Quick save |
| `F9` | Quick load |
| `N` | Toggle mini-map |
| `?` | Show controls tutorial |
| `1–9` | Quick-add product by number (in section view) |

---

## 🗺️ 18-Floor Building

| Floor | Theme | Highlights |
|-------|-------|------------|
| **G** | Ground Floor | Lobby + Food Street (12 stalls) + Warehouse Receiving Dock |
| **1** | Shoes | Ladies / Mens / Kids / Sport Shoes |
| **2** | Fashion | Ladies / Mens / Kids Wear |
| **3** | Sport & Active | Gym Equipment / Sports Gear / Activewear |
| **4** | Outdoor | Fishing / Hiking / Running |
| **5** | Stationery + Plants | Office supplies + Indoor plants |
| **6** | Staff Areas | Locker Room / Staff Lounge / Training |
| **7** | Back Office | Admin / HR / Open Office |
| **8** | Arcade & Claw Machines | 4 claw machines + games |
| **9** | Staff Room | Restricted lore area |
| **10** | Rooftop Café | Italian / Mexican / Bubble Tea |
| **11** | Warehouse Storage | Full warehouse with stock shelves |
| **12** | Juice Bar & Fresh | Smoothies / Salads / Health Foods |
| **13** | Kids Kingdom | Play Zone / Kids Club / Nursery / Family WC |
| **14** | Electronics Megastore | Phones / Smart Home / TVs / Repair |
| **15** | Canteen | 6 serving stations (rice, noodle, grill, veg, drinks, fruit) |
| **16** | Food Court | Fast food stalls (burger, pizza, chicken, hot dog, ice cream) |
| **17** | Entertainment | Karaoke / Pool Table / Darts / 3 Claw Machines |

---

## 🛠️ Dev Setup

### Prerequisites
- **Godot 4.6** (Forward+ renderer, 2D pixel art)
- **PowerShell 5+**
- Telegram bot token (optional, for notifications)

### Running the Game
```powershell
.\run.ps1
# or open project.godot directly in Godot
```

### Dev Workflow Scripts

| Script | What It Does |
|--------|-------------|
| `dev.ps1` | Full pipeline: test → commit → push → Telegram summary |
| `autotest.ps1` | File watcher — auto-runs tests on `.gd` changes |
| `quick_commit.ps1` | Fast test + commit with a message |
| `notify.ps1` | Standalone Telegram notifier |
| `test.ps1` | Godot headless run — checks for script errors |

---

## 🧪 Testing

```powershell
.\test.ps1          # Run Godot in headless mode, check for script errors
.\autotest.ps1      # Continuous file watcher with crash detection
```

---

## 📊 Game Systems (Phases)

- **Phase L** — Inventory & Stock (color-coded stock bars, OOS blocking, restock with R)
- **Phase M** — Staff Management (hire/fire, wages, morale, performance bonus)
- **Phase N** — Customer Experience (satisfaction stars, 1.0-1.5× XP multiplier)
- **Phase O** — Promotions & Loyalty (Bronze→Platinum tiers, tier discounts at checkout)
- **Phase P** — Store Expansion (renovate with X, reputation system, store levels)
- **Phase Q** — Anti-Theft (suspicious customers, catch with F for XP + fine)
- **Phase R** — Dynamic Pricing (stock level → 0.8× to 1.3× price modifier)
- **Phase S** — Supplier Relations (6 suppliers, contracts, favor system)
- **Phase T** — Technology & Upgrades (digital shelf labels, self-checkout)

See **[PHASES.md](PHASES.md)** for the full roadmap.

---

## 🎯 Tips

- **Restock sections** (press `R` in staff mode) before they go empty — OOS items hurt customer satisfaction
- **Gift wrap your cart** before checkout for +15 XP + $2 tip
- **Unload trucks** at the warehouse dock when delivery arrives — bonus XP!
- **Loyalty sign-up** is free and gives permanent discounts at checkout
- **Catch thieves** with `F` when you see "ACTIVE THEFT" — big XP + fine reward
- **Play mini-games** on Floor 17 for easy XP between shopping runs
