#!/bin/bash
# Runs `macsweep clean --dry-run` end to end against a fake home, under /bin/bash
# on purpose: on macOS that is bash 3.2, which is where the script has to work.
# Needs a pty for the key presses, so it uses BSD script(1) (macOS).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
H="$T/home"
mk() { mkdir -p "$1"; head -c $(($2 * 1024 * 1024)) /dev/zero > "$1/blob"; }
mk "$H/.npm/_cacache" 4
mk "$H/Library/Caches/Yarn" 3
mk "$H/.bun/install/cache" 2
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8   # bash 3.2 misreads "$VAR·" only in a UTF-8 locale

fail=0
check() {  # $1 = name, $2 = keys to type, rest = extra flags
  local name="$1" keys="$2"; shift 2
  local out="$T/$name.out"
  printf '%s' "$keys" | HOME="$H" script -q /dev/null /bin/bash "$ROOT/macsweep" clean --dry-run --fast --min-mb 1 --lang en "$@" > "$out" 2>&1
  if grep -q "DRY RUN" "$out" && ! grep -qiE "unbound variable|syntax error|command not found" "$out"; then
    echo "ok   $name"
  else
    echo "FAIL $name"; sed 's/^/     | /' "$out"; fail=1
  fi
}
check "yes then rest-no" "yr"      # items after 'r' are listed without a prompt
check "all safe"         "a"       # items after 'a' are auto-selected
[ -d "$H/.npm/_cacache" ] || { echo "FAIL dry run deleted something"; fail=1; }
echo "$(/bin/bash --version | head -1)"
exit $fail
