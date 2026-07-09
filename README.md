# Year Progress Live Wallpaper

Single-file `index.html`. GitHub-style year grid + 4 editable to-do panels (Year/Quarter/Month/Week). No build step, no network calls.

## Setup (Windows 11 + Lively Wallpaper)

1. **Install Lively Wallpaper** — https://github.com/rocksdanister/lively/releases (or Microsoft Store).
2. Open Lively → **Add Wallpaper** → **Web** → pick this folder's `index.html`.
3. Wallpaper applies immediately. Grid + to-dos render right away.
4. **Enable Interactive mode** (required to edit to-dos): right-click the wallpaper thumbnail in Lively → **Properties** → toggle **Interactive** (or right-click desktop → Lively → Interactive Mode). Without this, clicks pass through to your desktop icons and to-dos are read-only.
5. Test: click a to-do panel, type an item, hit Enter. Reload Lively (or reboot) — item should still be there.

## Survives reboot/login?

Yes. Lively re-launches your wallpaper on login; the webview's `localStorage` persists on disk between sessions (see below). No manual restart needed — the page also self-updates at local midnight and every 5 min as a safety net (covers sleep/wake).

## Editing colors / position / cell size later

Open `index.html`, look at the `:root { ... }` block at the top of `<style>`. Everything visual is a CSS variable there:

- `--cell-filled`, `--cell-empty`, `--cell-today-ring` — colors
- `--cell-size`, `--cell-gap`, `--cell-radius` — grid dimensions
- `--grid-top`, `--grid-right` — grid placement
- `--todo-panel-width`, `--todo-panel-max-height` — to-do panel sizing

Week start day (Sunday vs Monday) is `WEEK_START` near the top of the `<script>` block (`0` = Sunday, `1` = Monday).

## Backing up / migrating to-do data

To-dos live in the webview's `localStorage` under key `yearProgressTodos`, as one JSON blob. Lively's Chromium webview persists this to a profile folder on disk — typically under:

```
%LOCALAPPDATA%\Lively Wallpaper\...\LocalStorage\
```

(Exact subpath varies by Lively version — it's a Chromium/CEF/WebView2 implementation detail, not something this HTML file controls.) To manually back up: open the wallpaper's Interactive mode, open the browser devtools if Lively exposes them, go to **Application → Local Storage**, copy the `yearProgressTodos` value. To restore on a new machine, paste it back into `localStorage.setItem("yearProgressTodos", "<value>")` via the same devtools console.

## Notes

- Fully offline — zero network requests.
- Past to-do periods (last month, last quarter, etc.) aren't deleted on rollover, just no longer shown — they stay in `localStorage` if you inspect it directly.
