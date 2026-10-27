#!/usr/bin/env bash
# Packs app/build/MacSweep.app into app/build/MacSweep.dmg with a styled window
# (background, drag-to-Applications arrow, volume icon). Run app/build-app.sh first.
# Needs dmgbuild (pip install dmgbuild); it writes the Finder layout directly,
# so it also works on headless CI machines.
set -euo pipefail
cd "$(dirname "$0")"
APP=build/MacSweep.app
[ -d "$APP" ] || { echo "build $APP first (app/build-app.sh)" >&2; exit 1; }
DMGBUILD=${DMGBUILD:-dmgbuild}
command -v "$DMGBUILD" >/dev/null || { echo "dmgbuild not found: pip install dmgbuild" >&2; exit 1; }

swift scripts/make-dmg-background.swift build
tiffutil -cathidpicheck build/bg.png build/bg@2x.png -out build/dmg-background.tiff >/dev/null

rm -f build/MacSweep.dmg
"$DMGBUILD" -s dmg-settings.py \
  -D app="$APP" -D background=build/dmg-background.tiff -D icon="$APP/Contents/Resources/AppIcon.icns" \
  "MacSweep" build/MacSweep.dmg
hdiutil verify build/MacSweep.dmg >/dev/null
echo "built $PWD/build/MacSweep.dmg"
