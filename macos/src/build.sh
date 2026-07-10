#!/bin/zsh
# Build YearWallpaper.app from source.
#   Run from anywhere:  zsh macos/src/build.sh
# Produces macos/YearWallpaper.app (ad-hoc signed, ready to run / to feed install.command).
set -euo pipefail

# Resolve repo paths relative to THIS script (macos/src/build.sh), so it works
# on any machine regardless of where the repo was cloned.
SRC="$(cd "$(dirname "$0")" && pwd)"          # …/macos/src
MACOS="$(cd "$SRC/.." && pwd)"                # …/macos
REPO="$(cd "$MACOS/.." && pwd)"               # repo root
HTML="$REPO/index.html"                        # the wallpaper the app displays
APP="$MACOS/YearWallpaper.app"
BIN="$APP/Contents/MacOS/YearWallpaper"

CACHE="$SRC/.swiftcache"
mkdir -p "$CACHE"

SDK="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
[ -d "$SDK" ] || { echo "macOS SDK not found — install Xcode command line tools: xcode-select --install"; exit 1; }
echo "SDK=$SDK"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

/usr/bin/swiftc \
  -sdk "$SDK" -target arm64-apple-macos13.0 \
  -module-cache-path "$CACHE" \
  -framework Cocoa -framework WebKit -framework ServiceManagement \
  -O -o "$BIN" "$SRC/main.swift"

cp "$SRC/Info.plist" "$APP/Contents/Info.plist"
cp "$HTML"           "$APP/Contents/Resources/index.html"

# Icon: resize with ffmpeg (if available), pack .icns directly in Python.
# Falls back gracefully if ffmpeg is missing — the app just ships without a custom icon.
ICON_SRC="$SRC/icon_src.png"
if [ -f "$ICON_SRC" ] && command -v ffmpeg >/dev/null 2>&1; then
  ICONSET="$APP/Contents/Resources/AppIcon.iconset"
  rm -rf "$ICONSET"; mkdir -p "$ICONSET"
  for s in 16 32 128 256 512; do
    ffmpeg -y -i "$ICON_SRC" -vf "scale=${s}:${s}"         "$ICONSET/icon_${s}x${s}.png"    2>/dev/null
    ffmpeg -y -i "$ICON_SRC" -vf "scale=$((s*2)):$((s*2))" "$ICONSET/icon_${s}x${s}@2x.png" 2>/dev/null
  done
  python3 - "$ICONSET" "$APP/Contents/Resources/AppIcon.icns" <<'PYEOF'
import struct, os, sys
iconset, out = sys.argv[1], sys.argv[2]
tags = {"icon_16x16.png":b"icp4","icon_16x16@2x.png":b"ic11","icon_32x32.png":b"icp5",
        "icon_32x32@2x.png":b"ic12","icon_128x128.png":b"ic07","icon_128x128@2x.png":b"ic13",
        "icon_256x256.png":b"ic08","icon_256x256@2x.png":b"ic14","icon_512x512.png":b"ic09",
        "icon_512x512@2x.png":b"ic10"}
chunks = b""
for fname, tag in tags.items():
    data = open(os.path.join(iconset, fname), "rb").read()
    chunks += tag + struct.pack(">I", 8 + len(data)) + data
icns = b"icns" + struct.pack(">I", 8 + len(chunks)) + chunks
open(out, "wb").write(icns)
PYEOF
  rm -rf "$ICONSET"
  echo "Icon: AppIcon.icns built"
else
  echo "Icon: skipped (need icon_src.png + ffmpeg)"
fi

# Ad-hoc sign. No hardened runtime => WKWebView JIT works for a locally-built app.
codesign -f -s - "$APP"

echo "Built: $APP"
