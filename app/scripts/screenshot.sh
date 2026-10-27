#!/bin/bash
# Opens the built app on demo data and captures its screens into app/build/screenshot-*.png:
#   main (light), dark, scanning, confirm, done, settings
set -eu
cd "$(dirname "$0")/.."
python3 scripts/demo-scan.py build/demo.dat

# shot NAME APPEARANCE WAIT PICK [VAR=value ...]
#   WAIT = seconds after the window appears; PICK = --largest (main window + sheet) or --front
shot() {
  local name="$1" mode="$2" wait="$3" pick="$4"; shift 4
  env "$@" MACSWEEP_DEMO_APPEARANCE="$mode" MACSWEEP_DEMO_DUMP="$PWD/build/demo.dat" MACSWEEP_DEMO_SELECT=1 \
    build/MacSweep.app/Contents/MacOS/MacSweep &
  local pid=$! info=""
  for _ in $(seq 1 30); do sleep 1; info=$(swift scripts/window-id.swift MacSweep 2>/dev/null) && break; done
  sleep "$wait"
  info=$(swift scripts/window-id.swift MacSweep "$pick" 2>/dev/null || echo "$info")
  # capture the screen area of the window, so sheets (separate windows) are included
  if [ -n "$info" ]; then screencapture -x -R "${info#* }" "build/screenshot-$name.png"; else screencapture -x "build/screenshot-$name.png"; fi
  kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
}
shot light    light 3 --largest
shot dark     dark  3 --largest
shot scanning dark  3 --largest MACSWEEP_DEMO_DELAY=60
shot confirm  light 4 --largest MACSWEEP_DEMO_SHOW=confirm
shot done     light 9 --largest MACSWEEP_DEMO_SHOW=done
shot settings light 4 --front   MACSWEEP_DEMO_SHOW=settings
ls -la build/screenshot-*.png
