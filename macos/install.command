#!/bin/zsh
# Double-clickable installer for Year Wallpaper.
# Copies the app to /Applications, clears the download quarantine flag so
# Gatekeeper won't block it, and launches it.

set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/YearWallpaper.app"
DEST="/Applications/YearWallpaper.app"

echo "Installing Year Wallpaper…"

if [ ! -d "$APP" ]; then
  echo "ERROR: YearWallpaper.app not found next to this installer."
  echo "Keep install.command in the same folder as YearWallpaper.app."
  read "?Press Return to close."
  exit 1
fi

# Remove any old copy, install fresh.
rm -rf "$DEST"
cp -R "$APP" "$DEST"

# Strip quarantine so the ad-hoc-signed app opens without the Gatekeeper block.
xattr -cr "$DEST" 2>/dev/null || true

echo "Installed to /Applications."
open "$DEST"
echo "Launched. Look for the ◔ icon in your menu bar."
echo "Tip: menu bar ◔ → Open at Login  keeps it running after reboot."
sleep 1
