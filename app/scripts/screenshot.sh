#!/bin/bash
# Opens the built app on demo data and captures its window (light and dark).
#   app/scripts/screenshot.sh   → app/build/screenshot-light.png, screenshot-dark.png
set -eu
cd "$(dirname "$0")/.."
python3 scripts/demo-scan.py build/demo.dat
shot() {
  local mode="$1"
  MACSWEEP_DEMO_APPEARANCE="$mode" MACSWEEP_DEMO_DUMP="$PWD/build/demo.dat" MACSWEEP_DEMO_SELECT=1 build/MacSweep.app/Contents/MacOS/MacSweep &
  local pid=$! id=""
  for _ in $(seq 1 30); do sleep 1; id=$(swift scripts/window-id.swift MacSweep 2>/dev/null) && break; done
  sleep 3
  if [ -n "$id" ]; then screencapture -x -o -l "$id" "build/screenshot-$mode.png"; else screencapture -x "build/screenshot-$mode.png"; fi
  kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
}
shot light
shot dark
ls -la build/screenshot-*.png
