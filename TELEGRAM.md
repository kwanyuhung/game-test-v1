# Telegram Bot Integration

**Bot:** [@kwanyuhungbot](https://t.me/kwanyuhungbot)  
**Chat ID:** `1718058079`  
**Token:** `8661389914:AAHt0UDFntFdbnFwnhoxIN58N2hxC0mK3rk`

---

## Architecture

```
main.gd
  +- TelegramBot (Node, child of Main in main.tscn)
  |   +- _report_queue[]   <- queue, flushed every 30s or on important events
  |       +- _flush_reports()
  |           +- send_message()  <- HTTP POST to Telegram API
  +- AudioManager (procedural sounds)
  +- MiniMap
  +- ToastManager (sliding in-game toasts)
  +- FloatingText
  +- FadeTransition
```

### Node placement (main.tscn)
```
[Main] <- main.gd
  +- [TelegramBot]
  +- [AudioManager]
  +- [MiniMap]
  +- [ToastManager]
  +- [FloatingText]
  +- [FadeTransition]
```

`main.gd` grabs the TelegramBot in `_ready()`:
```gdscript
_telegram_bot = get_node_or_null("/root/Main/TelegramBot")
```

All game events call through thin wrapper methods that guard against null:
```gdscript
func notify_telegram(msg: String) -> void:
    if _telegram_bot != null:
        _telegram_bot.queue_report(msg)
```

---

## Reporting Flow

```
Event in game code
  -> main.gd notify wrapper
      -> TelegramBot.queue_report(msg)
          -> _report_queue.append(msg)      (deduped)
          -> if starts with important emoji -> _flush_reports() immediately
             else -> waits until timer hits 30s

_flush_reports()
  -> slices first 5 items, joins with \n\n
  -> _send_deferred()  (call_deferred)
      -> send_message()  -> HTTP POST -> Telegram
```

**Deduplication:** identical messages within the same queue are dropped.

**Immediate flush triggers:** any message starting with `🟢` or `🔴`.

**Batched flush:** every 30 seconds of game time, or when queue exceeds 5 items.

---

## Event Types

| Emoji | Event | Trigger |
|-------|-------|---------|
| 🟢 | Game loaded | `main.gd` `_ready()` completes |
| 📁 | Save loaded | Auto-load on startup finds a save |
| 📋 | New game | No save found on startup |
| 💾 | Game saved | F5 quick-save or auto-save |
| 📂 | Game loaded | F9 quick-load triggered |
| 📋 | Browsing section | Player presses `E` at a section |
| 🛒 | Cart updated | Player adds item; only when >= 3 items |
| 💳 | Checkout complete | Player finishes checkout |
| 👥 | NPCs spawned | `_build_npcs()` finishes |
| 📦 | Delivery arrived | Warehouse delivers stock to sections |
| 🔧 | Maintenance fixed | Player resolves a maintenance issue |
| ⬆️ | Level up | Player XP crosses threshold |
| 🔥 | Daily streak bonus | Player logged in on consecutive day |
| 🎯 | Daily quest complete | Finished a daily objective (+XP) |
| 🏅 | All quests done | All 3 daily quests completed (+50 XP bonus) |
| 🏆 | Achievement unlocked | New achievement earned |
| 🌆 | Evening hours | Game clock reaches evening |
| 🚨 | Cart theft | NPC customer left store with unpaid cart |
| ❌ | Game error | Runtime script error caught |

---

## Static API (for scripts without a TelegramBot reference)

`telegram_bot.gd` exposes static methods for use from any script context:

```gdscript
TelegramBot.send_message("text")                    # raw send
TelegramBot.notify_test_failed("error details")    # dev/test
TelegramBot.notify_test_pass()                      # dev/test
TelegramBot.notify_commit("commit message")          # dev pipeline
TelegramBot.notify_game_error("err msg")             # runtime error
```

Static methods bypass the queue and send immediately — use these for **external pipeline events** (commit, test results) rather than in-game events.

---

## Adding a New Event

**1. Add the trigger in `main.gd`**:

```gdscript
const TelegramBot = preload("res://scripts/telegram_bot.gd")

# Call via the wrapper (guards null):
notify_telegram("📦 *Delivery arrived!* %d items restocked." % count)
```

**2. Pick an emoji + format:**

```gdscript
notify_telegram("🟡 *Something happened!* Details here")
notify_telegram("🛒 *Cart Updated*\n%d items · $%.2f" % [count, total])
```

**3. For static-only scripts** (e.g. a dedicated test runner):

```gdscript
TelegramBot.notify_test_failed("SCRIPT ERROR: Null pointer")
```

---

## Dev Pipeline — `dev.ps1`

```
.\dev.ps1 "commit message"
```

Flow:
1. Run Godot headless test (8s, --quit-after)
2. If fail -> send ❌ *Test Failed* to Telegram, exit 1
3. Git add + commit + push
4. Send 📦 *Committed* with file list to Telegram

Tokens are hardcoded in the script (`$BOT_TOKEN`, `$CHAT_ID`).

---

## Auto-Testing — `autotest.ps1`

```
.\autotest.ps1             # watch mode — runs forever
.\autotest.ps1 -OneShot    # single test and exit
```

Watches `.gd`, `.tscn`, `.godot` files. On every change:
1. Run Godot headless test
2. If pass -> `$failCount = 0`
3. If fail -> increment `$failCount`, send ❌ *AutoTest Failed* to Telegram
4. After 3 consecutive failures -> pause 10s before resuming

---

## Telegram Bot API

**Endpoint:** `https://api.telegram.org/bot<TOKEN>/sendMessage`

**Method:** `POST`

**Body (form-encoded):**
```
chat_id=<CHAT_ID>&text=<URI_ENCODED_TEXT>&parse_mode=Markdown
```

**Success:** HTTP 200  
**Failure:** logs to console, silently continues

---

## Limitations & Notes

- Messages are **Markdown**, not HTML. Use `*bold*`, `_italic_`, `` `code` ``.
- Telegram has a **4096 char** message limit. Long `notify_game_error()` truncates to 200 chars.
- The queue batches low-priority events (cart updates) to avoid spamming. Important events (start, errors) bypass the queue.
- The bot only sends — it cannot receive commands or reply. Two-way communication would require a long-polling `getUpdates` loop or webhook.
