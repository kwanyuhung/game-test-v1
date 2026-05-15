# Keyboard Controls Reference

This document lists all keyboard controls in **Pixel Supermarket**.

---

## Movement Controls

| Key | Action | Description |
|-----|--------|-------------|
| `W` | Move Up | Move player character up |
| `↑` (Up Arrow) | Move Up | Alternative: Move player character up |
| `S` | Move Down | Move player character down |
| `↓` (Down Arrow) | Move Down | Alternative: Move player character down |
| `A` | Move Left | Move player character left |
| `←` (Left Arrow) | Move Left | Alternative: Move player character left |
| `D` | Move Right | Move player character right |
| `→` (Right Arrow) | Move Right | Alternative: Move player character right |

---

## Core Game Actions

| Key | Action | Description |
|-----|--------|-------------|
| `E` | Interact | Interact with objects, NPCs, and panels |
| `Tab` | Toggle Cart | Show/hide shopping cart |
| `Esc` | Pause | Pause/unpause the game |

---

## Quick Access Keys

| Key | Action | Description |
|-----|--------|-------------|
| `C` | Chat | Open chat with nearby NPC |
| `F` | Catch Thief | Attempt to catch a suspicious thief (when nearby) |
| `J` | Quest Journal | Toggle quest journal panel |
| `K` | Stats Dashboard | Toggle statistics dashboard |
| `L` | Shopping List | Toggle shopping list panel |
| `M` | Map | Toggle full map panel |
| `O` | Settings | Toggle settings panel |
| `P` | Pause | Toggle pause (alternative) |
| `R` | Restock | Restock nearby section (staff mode) |
| `Space` | Pause | Toggle pause (alternative) |
| `T` | Floor Jump | Toggle floor jump/teleport panel |
| `X` | Renovate | Renovate nearby section (staff mode) |
| `B` | Business Mode | Toggle business mode panel |
| `Shift+B` | Brand Portal | Open brand portal |

---

## Debug & Development

| Key | Action | Description |
|-----|--------|-------------|
| `F3` | Debug Bounds | Toggle debug collision bounds visibility |
| `F5` | Quick Save | Save game immediately |
| `F9` | Debug Sprite Viewer | Toggle sprite viewer (DEV_MODE only) |

---

## Warehouse / Staff Controls

| Key | Action | Description |
|-----|--------|-------------|
| `Q` | Lower Forklift | Lower forklift forks |
| `E` | Raise Forklift | Raise forklift forks |
| `F` | Toggle Conveyor | Turn conveyor belt on/off |
| `Space` | Stop Truck | Stop truck at dock |
| `H` | Shelf Panel | Toggle warehouse shelf panel |

---

## Floor Navigation

| Key | Action | Description |
|-----|--------|-------------|
| `W` / `↑` | Go Up | Navigate to floor above (when at stairs/elevator) |
| `S` / `↓` | Go Down | Navigate to floor below (when at stairs/elevator) |
| `0` - `9` | Floor Jump | Teleport to floor 0-9 |
| `-` (Minus) | Floor 10 | Teleport to floor 10 |

---

## UI Navigation (Panels & Menus)

| Key | Action | Description |
|-----|--------|-------------|
| `W` / `↑` | Navigate Up | Move selection up in lists |
| `S` / `↓` | Navigate Down | Move selection down in lists |
| `A` / `←` | Decrease | Decrease value / go left |
| `D` / `→` | Increase | Increase value / go right |
| `E` / `Enter` | Confirm | Confirm selection / interact |
| `Space` | Confirm | Alternative confirm key |
| `Tab` | Close | Close current panel |
| `Esc` | Close / Back | Close panel or go back |
| `1` - `9` | Quantity | Select quantity 1-9 (in shops) |
| `PageUp` | Page Up | Navigate up pages |
| `PageDown` | Page Down | Navigate down pages |
| `Delete` / `Backspace` | Delete | Remove selected item |

---

## Numeric Keypad Mapping

| Key | Action | Description |
|-----|--------|-------------|
| `Keypad +` (`+`) | Add | Add item to cart (alternative) |
| `Keypad 0-9` | Numbers | Number input for panels |

---

## Keycode Reference

### Physical Keycodes (from project.godot)

| Keycode | Key | Notes |
|---------|-----|-------|
| `87` | W | Physical keycode |
| `4194320` | Up Arrow | Keycode constant |
| `83` | S | Physical keycode |
| `4194322` | Down Arrow | Keycode constant |
| `65` | A | Physical keycode |
| `4194319` | Left Arrow | Keycode constant |
| `68` | D | Physical keycode |
| `4194321` | Right Arrow | Keycode constant |
| `69` | E | Interact key |
| `167` | Tab | Toggle cart (physical) |
| `27` | Escape | Pause key |

---

## Input System Notes

- **Deadzone**: 0.5 (for gamepad compatibility)
- **Input Actions**: Defined in `project.godot` under `[input]` section
- **Direct Keycode Checks**: Some scripts use direct `KEY_*` constants instead of input actions (e.g., warehouse controls, debug keys)

---

## Summary by Category

| Category | Keys |
|----------|------|
| Movement | `W` `A` `S` `D` / Arrow keys |
| Interact | `E` |
| Pause | `Esc` `P` `Space` |
| UI Panels | `M` `L` `T` `J` `K` `O` `B` |
| Staff/Shop | `R` `F` `X` `C` |
| Warehouse | `Q` `E` `F` `H` `Space` |
| Debug | `F3` `F5` `F9` |
| Floor Jump | `0`-`9` `-` |
| Navigation | `W` `S` `A` `D` / Arrows |
| Confirm/Cancel | `E` `Enter` `Space` / `Esc` `Tab` |
