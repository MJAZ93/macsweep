#!/usr/bin/env bash
# Installs macsweep into /usr/local/bin (or ~/.local/bin if /usr/local/bin is not writable).
set -eu
URL="https://raw.githubusercontent.com/MJAZ93/macsweep/main/macsweep"
DEST="/usr/local/bin"
[ -w "$DEST" ] || { DEST="$HOME/.local/bin"; mkdir -p "$DEST"; }
curl -fsSL "$URL" -o "$DEST/macsweep"
chmod +x "$DEST/macsweep"
echo "✔ installed to $DEST/macsweep"
case ":$PATH:" in *":$DEST:"*) ;; *) echo "  add $DEST to your PATH" ;; esac
echo "  run: macsweep        (scan)"
echo "       macsweep clean  (interactive cleanup)"
