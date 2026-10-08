#!/bin/bash
# Exercises the script's app modes (__scan / __exec) against a fake home.
# Runs under /bin/bash on purpose: on macOS that is bash 3.2.
set -eu
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
H="$T/home"; W="$T/work"; mkdir -p "$W"
mk() { mkdir -p "$1"; head -c $(($2 * 1024 * 1024)) /dev/zero > "$1/blob"; }
mk "$H/.npm/_cacache" 3
mk "$H/Library/Caches/Yarn" 2
mk "$H/go/pkg/mod" 2

run() { HOME="$H" /bin/bash "$ROOT/macsweep" "$@" --fast --min-mb 1 --lang en; }
run __scan "$W"
python3 - "$W/scan.dat" > "$T/items" <<'PY'
import sys
f = open(sys.argv[1], "rb").read().decode().split("\0")
assert f[0] == "macsweep-ui-1", f[0]
n = int(f[9])
for i in range(n):
    print("%d\t%s\t%s" % (i, f[10 + i * 7], f[11 + i * 7]))
PY
cat "$T/items"
grep -q $'\tSAFE\tnpm cache$' "$T/items"
grep -q $'\tSAFE\tYarn cache$' "$T/items"
grep -q $'\tREBUILD\tGo module cache' "$T/items"

npm=$(awk -F'\t' '$3=="npm cache"{print $1}' "$T/items")
go=$(awk -F'\t' '$3 ~ /^Go module/{print $1}' "$T/items")

# dry run: progress lines, nothing deleted
out=$(run __exec "$W" "$npm,$go" --dry-run)
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -q "^S	$npm$"
printf '%s\n' "$out" | grep -q "^D	$go$"
printf '%s\n' "$out" | grep -q "^F	"
[ -d "$H/.npm/_cacache" ] && [ -d "$H/go/pkg/mod" ]

# real run on one item; ids out of range and garbage are ignored
out=$(run __exec "$W" "$npm,999,x;rm")
printf '%s\n' "$out"
[ ! -e "$H/.npm/_cacache" ] || { echo "npm cache not deleted" >&2; exit 1; }
[ -d "$H/Library/Caches/Yarn" ] && [ -d "$H/go/pkg/mod" ]
grep -q "npm cache" "$H/Library/Logs/macsweep.log"
echo "engine OK ($(/bin/bash --version | head -1))"
