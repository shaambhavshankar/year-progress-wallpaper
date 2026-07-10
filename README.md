# Year Progress Wallpaper

> Your calendar shows you *what day it is.*  
> This shows you *how much of your life is passing.*

**If this changes how you work, star it.** It takes one second and tells me to keep building.

---

## Why this exists

You already have a calendar. You already have a to-do app. You use both every day and you still feel like the year is slipping through your fingers.

That is not a productivity problem. It is a visibility problem.

Calendars show you appointments. To-do apps show you lists. Neither shows you the one thing that actually changes behavior: **how much time you have left.**

This wallpaper puts that number on your desktop, permanently, in your peripheral vision — alongside your tasks. Not in a tab you forget to open. Not in an app you have to launch. On your desktop. Always there.

---

## What it does

A single self-contained HTML file — no app, no subscription, no account, no internet. Two builds ship: **`index.html`** (transparent — for macOS, so desktop folders show through) and **`index-windows.html`** (solid black — for Windows/Lively). They are identical except for the backdrop.

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

Open Lively → click **Add Wallpaper** → select **Web** → pick **`index-windows.html`** from this folder. (Windows uses the solid-black build; `index.html` is the transparent macOS build — using it on Windows would show a see-through backdrop.)

**Step 3 — Enable interaction**

Right-click the wallpaper thumbnail in Lively → **Properties** → toggle **Interactive**. Without this, clicks pass through to the desktop and to-dos are read-only.

**Step 4 — Enable keyboard**

Lively disables keyboard input by default. Fix: **Lively Settings → Wallpaper → Interaction → Wallpaper Input → enable Keyboard**. Without this step, clicking a text field shows a cursor for one second then loses focus — you cannot type anything.

**Step 5 — Test it**

Click any to-do panel. Type a task. Press Enter. Reboot. The task should still be there.

---

## Setup — macOS

macOS has no public API for true live wallpapers, and every third-party wallpaper host (Plash, AetherDesk) deliberately makes its window refuse keyboard focus — so you can *see* the wallpaper but can't reliably *type* into it. To get a wallpaper you can click and type into directly on the desktop, this repo ships its own tiny native host: **YearWallpaper.app**.

**Option A — YearWallpaper.app** (recommended — type directly on the desktop)

A ~130-line Swift/WebKit app under [`macos/`](macos/). It renders `index.html` in a transparent, full-screen window pinned at the desktop-icon layer, and — unlike Plash/AetherDesk — its window *can* take keyboard focus, so to-dos are editable in place. Your desktop folders stay visible and clickable through the transparent background. Apple Silicon, macOS 13+.

**Install (prebuilt):**

1. Download this repo (green **Code** button → **Download ZIP**, or `git clone`).
2. Open the `macos` folder in Finder.
3. Double-click **`install.command`**. It copies `YearWallpaper.app` to `/Applications`, clears the download-quarantine flag so macOS doesn't block it, and launches it.
   - If macOS still warns "unidentified developer": right-click the app → **Open** → **Open**. Only needed once.
4. Look for the **◔** icon in your menu bar. That's the whole UI:
   - **Theme** — *Original* (dark, mint accent) or *Neutral* (white/grey, readable on any wallpaper).
   - **Background** — transparency of the backdrop (0% = fully see-through, 100% = solid).
   - **Open at Login** — relaunch automatically after reboot.
   - **Quit**.
5. Set a dark solid desktop picture (`System Settings → Wallpaper`) if you want the panels to pop, or leave your photo and raise **Background** opacity a little.

**One macOS setting to change:** turn off **System Settings → Desktop & Dock → "Click wallpaper to reveal desktop"** (set to *Only in Stage Manager*, or off). Otherwise clicking empty desktop space slides your windows away.

**Build from source instead:**

```bash
cd year-progress-wallpaper
zsh macos/src/build.sh      # needs Xcode command line tools; ffmpeg optional (for the app icon)
```
Produces `macos/YearWallpaper.app`, ad-hoc signed and ready to run. Source is `macos/src/main.swift`.

> **Why a custom app?** Keyboard input on the desktop layer requires a window that returns `canBecomeKeyWindow = true`. Plash and AetherDesk return `false` by design, which is why their to-do editing never sticks. YearWallpaper overrides it, plus does synchronous cursor hit-testing so clicks reliably hit either a to-do panel (capture) or a desktop folder (pass through to Finder).

**Option B — Plash** (no build, but read-mostly)

1. Download from the [Mac App Store](https://apps.apple.com/app/plash/id1494023538). Free.
2. Menu bar Plash icon → **Open URL…** → `file:///path/to/year-progress-wallpaper/index.html` (use the real path).
3. **Plash Preferences**: enable full-screen coverage, show on all spaces.
4. To edit to-dos: menu bar → Plash → **Enter Browsing Mode**. Exit when done. (Typing here is unreliable — this is the limitation Option A solves.)
5. Set a solid dark desktop color so the overlay looks seamless.

> **localStorage on `file://`**: Plash's WebKit may not persist `localStorage` on `file://` across sessions. If tasks vanish after reboot, serve locally: `cd /path/to/year-progress-wallpaper && python3 -m http.server 4321`, then point Plash at `http://localhost:4321` (add a Login Item to survive reboot).

**Option C — AetherDesk** (multi-monitor)

1. Download from [GitHub](https://github.com/sdelavega/AetherDesk). Free, MIT. Apple Silicon, macOS 12+.
2. Drag to Applications, open, add wallpaper → select `index.html`. Same keyboard-focus caveat as Plash.

---

## Survives reboot?

Yes. On Windows, Lively relaunches on login. On macOS, YearWallpaper.app has **Open at Login** in its menu (Plash/AetherDesk relaunch on login too). The `localStorage` data persists on disk between sessions — YearWallpaper serves the page from a stable `wallpaper://` origin specifically so it survives relaunch. The page also self-updates at local midnight and every 5 minutes as a safety net for sleep/wake cycles.

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

---

## Star History

<a href="https://www.star-history.com/?type=date&repos=shaambhavshankar%2Fyear-progress-wallpaper">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=shaambhavshankar/year-progress-wallpaper&type=date&theme=dark&legend=top-left&sealed_token=4svvC_Ge4S0F5I6c-q_Xezy5Vs9T8zVYEhRX2d9peBEArT5P05jIYWwxjnoZBkYuKdH40Z75PLIfZSxewszMt8yBs4wblHt2E64sxNhyBpsq3mMeLjMh5GKsG88dL2nP60TTHh5MPPfILu8dKui9Yc8yRUuOhnrTvjmQyc910jJejU9EuB3CpxGx14pA" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=shaambhavshankar/year-progress-wallpaper&type=date&legend=top-left&sealed_token=4svvC_Ge4S0F5I6c-q_Xezy5Vs9T8zVYEhRX2d9peBEArT5P05jIYWwxjnoZBkYuKdH40Z75PLIfZSxewszMt8yBs4wblHt2E64sxNhyBpsq3mMeLjMh5GKsG88dL2nP60TTHh5MPPfILu8dKui9Yc8yRUuOhnrTvjmQyc910jJejU9EuB3CpxGx14pA" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=shaambhavshankar/year-progress-wallpaper&type=date&legend=top-left&sealed_token=4svvC_Ge4S0F5I6c-q_Xezy5Vs9T8zVYEhRX2d9peBEArT5P05jIYWwxjnoZBkYuKdH40Z75PLIfZSxewszMt8yBs4wblHt2E64sxNhyBpsq3mMeLjMh5GKsG88dL2nP60TTHh5MPPfILu8dKui9Yc8yRUuOhnrTvjmQyc910jJejU9EuB3CpxGx14pA" />
 </picture>
</a>
