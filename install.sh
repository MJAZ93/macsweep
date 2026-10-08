#!/usr/bin/env bash
# macsweep installer — single file, no dependencies.
#   curl -fsSL https://raw.githubusercontent.com/MJAZ93/macsweep/main/install.sh | bash
#
# Picks the first writable directory that is already on your PATH:
#   /opt/homebrew/bin  (Apple Silicon Homebrew)  →  /usr/local/bin  →  ~/.local/bin
# If it has to fall back to ~/.local/bin, it adds that directory to your shell rc.
set -eu
URL="https://raw.githubusercontent.com/MJAZ93/macsweep/main/macsweep"
DEST=""
for d in /opt/homebrew/bin /usr/local/bin; do
  [ -d "$d" ] && [ -w "$d" ] && { DEST="$d"; break; }
done
if [ -z "$DEST" ]; then
  DEST="$HOME/.local/bin"; mkdir -p "$DEST"
  case "${SHELL:-}" in */zsh) RC="$HOME/.zshrc" ;; */bash) RC="$HOME/.bashrc" ;; *) RC="$HOME/.profile" ;; esac
  if ! grep -qs 'macsweep' "$RC"; then
    printf '\n# macsweep\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$RC"
    echo "  added ~/.local/bin to PATH in $RC"
  fi
fi

TMP=$(mktemp)
curl -fsSL "$URL" -o "$TMP" || { echo "✘ download failed: $URL" >&2; rm -f "$TMP"; exit 1; }
head -1 "$TMP" | grep -q bash || { echo "✘ unexpected content from $URL" >&2; rm -f "$TMP"; exit 1; }
install -m 0755 "$TMP" "$DEST/macsweep"; rm -f "$TMP"

echo "✔ installed $DEST/macsweep ($("$DEST/macsweep" --version))"
case ":$PATH:" in
  *":$DEST:"*) echo "  run:  macsweep          (scan, deletes nothing)"
               echo "        macsweep clean    (interactive cleanup)" ;;
  *)           echo "  open a new terminal (or run: exec \$SHELL) and then:  macsweep" ;;
esac
