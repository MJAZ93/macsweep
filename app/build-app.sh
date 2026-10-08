#!/usr/bin/env bash
# Builds app/build/MacSweep.app (and MacSweep.zip) from source. Needs Xcode or
# the Command Line Tools on macOS 13+.
#   app/build-app.sh            universal (Apple silicon + Intel) when Xcode is installed
#   ARCH=native app/build-app.sh  only this Mac's architecture
set -euo pipefail
cd "$(dirname "$0")"
VERSION=$(sed -n 's/^VERSION="\(.*\)"$/\1/p' ../macsweep)
APP=build/MacSweep.app

ARGS=(-c release)
if [ "${ARCH:-universal}" = "universal" ] && swift build "${ARGS[@]}" --arch arm64 --arch x86_64; then
  ARGS+=(--arch arm64 --arch x86_64)
else
  swift build "${ARGS[@]}"
fi
BIN="$(swift build "${ARGS[@]}" --show-bin-path)/MacSweep"

rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/MacSweep"
install -m 0755 ../macsweep "$APP/Contents/Resources/macsweep"   # the engine: same script as the CLI
sed "s/__VERSION__/$VERSION/g" Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# icon (optional: the app works without it)
if swift scripts/make-icon.swift build/icon.png 2>/dev/null; then
  mkdir -p build/AppIcon.iconset
  for s in 16 32 128 256 512; do
    sips -z $s $s build/icon.png --out "build/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) build/icon.png --out "build/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
else
  echo "warning: icon not generated" >&2
fi

codesign --force --deep --sign - "$APP"   # ad-hoc signature, required on Apple silicon
(cd build && ditto -c -k --keepParent MacSweep.app MacSweep.zip)
echo "built $PWD/$APP ($VERSION)"
