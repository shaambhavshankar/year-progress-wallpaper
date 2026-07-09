# Year Progress Wallpaper

> Your calendar shows you *what day it is.*  
> This shows you *how much of your life is passing.*

[![Star History Chart](https://api.star-history.com/svg?repos=shaambhav/year-progress-wallpaper&type=Date)](https://star-history.com/#shaambhav/year-progress-wallpaper&Date)

**If this changes how you work, star it.** It takes one second and tells me to keep building.

---

## Why this exists

You already have a calendar. You already have a to-do app. You use both every day and you still feel like the year is slipping through your fingers.

That is not a productivity problem. It is a visibility problem.

Calendars show you appointments. To-do apps show you lists. Neither shows you the one thing that actually changes behavior: **how much time you have left.**

This wallpaper puts that number on your desktop, permanently, in your peripheral vision — alongside your tasks. Not in a tab you forget to open. Not in an app you have to launch. On your desktop. Always there.

---

## What it does

A single `index.html` file — no app, no subscription, no account, no internet.

**Left side:** A GitHub-style grid of every day in the year. Past days fill in. Today glows. Days where you completed tasks get a darker green — the more tasks, the darker. At a glance you see not just how far through the year you are, but where you were actually working.

**Right side:** Four to-do columns — Year, Quarter, Month, Week. Add tasks. Check them off. They auto-update at midnight. Move tasks forward when a week ends. Everything persists across reboots.

**Every completed task shows how long it took.** You marked it done at 3:47pm. You added it at 9:12am. It shows `6h 35m`. Over weeks, patterns emerge. The tasks you thought took an hour took three. The ones you dreaded took twenty minutes. This is data you cannot get from any to-do app that does not sit next to a live time-remaining counter.

---

## The psychology of time visibility

Parkinson's Law: work expands to fill the time available.

The corollary: when you cannot see time passing, it expands infinitely.

Research on temporal landmarks (Hengchen Dai, 2014 — "The Fresh Start Effect") shows that people dramatically increase goal-directed behavior when a time boundary is made visible and salient. The start of a week, a month, a year. This wallpaper makes every day a visible landmark. The grid filling up is not decoration. It is a behavioral intervention.

**The countdown bars** — X days left in this week, Y weeks left in this quarter, Z months left in this year — activate what psychologists call *urgency heuristics*. When a deadline is abstract ("end of Q3") behavior stays relaxed. When it is concrete ("11 days") behavior sharpens. The wallpaper keeps it concrete, permanently.

**The task duration log** turns vague effort into measurable data. Once you see that "write report" consistently takes 4 hours and "review designs" consistently takes 20 minutes, you stop underestimating the former and overblocking the latter. You plan better because you finally have evidence, not guesses.

---

## Against calendars and to-do apps

| | Calendar | To-Do App | This |
|---|---|---|---|
| Shows time passing | No | No | Yes — always |
| Tasks tied to time scale | No | No | Yes — year/quarter/month/week |
| Visible without opening | No | No | Yes — it's your desktop |
| Shows how long tasks took | No | Rarely | Yes — every completed task |
| Internet required | Yes | Usually | Never |
| Costs money | Often | Often | Zero |

The point is not to replace your calendar. Keep your calendar. The point is that your wallpaper is 8 hours of peripheral vision per day, and right now it is showing you a photograph of a mountain. This uses it for something.

---

## Setup — Windows 11

**Step 1 — Get Lively Wallpaper**

Download from the [Microsoft Store](https://apps.microsoft.com/store/detail/lively-wallpaper/9NTM2QC6QWS7) or [GitHub releases](https://github.com/rocksdanister/lively/releases). Free, open source.

**Step 2 — Load the wallpaper**

Open Lively → click **Add Wallpaper** → select **Web** → pick `index.html` from this folder.

**Step 3 — Enable interaction**

Right-click the wallpaper thumbnail in Lively → **Properties** → toggle **Interactive**. Without this, clicks pass through to the desktop and to-dos are read-only.

**Step 4 — Enable keyboard**

Lively disables keyboard input by default. Fix: **Lively Settings → Wallpaper → Interaction → Wallpaper Input → enable Keyboard**. Without this step, clicking a text field shows a cursor for one second then loses focus — you cannot type anything.

**Step 5 — Test it**

Click any to-do panel. Type a task. Press Enter. Reboot. The task should still be there.

---

## Setup — macOS

macOS has no public API for true live wallpapers. Every solution is an overlay window that sits above your static wallpaper. The visual result is identical — the only side effect is the menu bar tint still reads from the static wallpaper behind it.

**Option A — Plash** (simplest)

1. Download from the [Mac App Store](https://apps.apple.com/app/plash/id1494023538). Free.
2. Click the Plash icon in your menu bar → **Open URL…** → enter:
   ```
   file:///path/to/year-progress-wallpaper/index.html
   ```
   Replace `path/to` with the actual folder path.
3. In **Plash Preferences**: enable full-screen coverage, set it to show on all spaces.
4. To edit to-dos: menu bar → Plash → **Enter Browsing Mode** (enables clicks and typing). Exit Browsing Mode when done.
5. Set your macOS wallpaper to a solid dark color (`System Settings → Wallpaper → Color`) so the overlay appears seamless.

> **localStorage on `file://`**: WebKit (Safari engine, used by Plash) may not persist `localStorage` on `file://` URLs across sessions in some configurations. If your tasks disappear after reboot, serve the file locally instead:
> ```bash
> cd /path/to/year-progress-wallpaper && python3 -m http.server 4321
> ```
> Then point Plash at `http://localhost:4321`. To make it survive reboot, add a Login Item or launchd plist that runs the command.

**Option B — AetherDesk** (multi-monitor, more capable)

1. Download from [GitHub](https://github.com/sdelavega/AetherDesk). Free, MIT license. Requires Apple Silicon Mac, macOS 12+.
2. Drag to Applications, open it.
3. Add wallpaper → select `index.html` from this folder. AetherDesk supports the Lively Wallpaper bundle format natively.
4. Interaction is built in — click and type directly without toggling a mode.

---

## Survives reboot?

Yes. Both Lively (Windows) and Plash/AetherDesk (macOS) relaunch the wallpaper on login. The `localStorage` data persists on disk between sessions. The page also self-updates at local midnight and every 5 minutes as a safety net for sleep/wake cycles.

---

## Customization

Open `index.html` and edit the `:root { }` block at the top of `<style>`. Everything visual is a CSS variable:

- `--cell-filled`, `--cell-empty`, `--cell-today-ring` — dot colors
- `--cell-size`, `--cell-gap`, `--cell-radius` — grid dimensions
- `--grid-top`, `--grid-right` — grid position on screen
- `--todo-panel-width`, `--todo-panel-max-height` — panel sizing

Week start day: find `WEEK_START` near the top of `<script>`. Set `0` for Sunday, `1` for Monday.

---

## Backing up your data

To-dos are stored in `localStorage` under the key `yearProgressTodos` as a single JSON object. To back up: open devtools (F12 in Lively, or in Plash's Browsing Mode → right-click → Inspect), go to **Application → Local Storage**, copy the value. To restore on a new machine, run in the console:

```js
localStorage.setItem("yearProgressTodos", "<paste value here>")
```

---

## Technical notes

- Zero network requests. Fully offline.
- Single `index.html`. No build step, no dependencies, no framework.
- Past periods are never deleted on rollover — they stay in `localStorage` and are just no longer shown in the UI.
- Tasks store `createdAt` and `completedAt` as ISO timestamps. Duration is computed at render time.
