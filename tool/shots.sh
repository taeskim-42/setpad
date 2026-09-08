#!/bin/zsh
# Capture store screenshots. $1 = simulator udid, $2 = output dir.
set -e
UDID=$1; OUT=$2; LOG=$(mktemp)
mkdir -p "$OUT"; rm -f "$OUT"/*.png
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
~/flutter/bin/flutter run -t lib/_shots.dart -d "$UDID" > "$LOG" 2>&1 &
RUN=$!
for k in ko en ja es th vi zhHans zhHant; do
  for n in 1-pad 2-list 3-memo 4-dark; do
    for i in $(seq 1 400); do grep -q "\[shot\] $k-$n\$" "$LOG" && break; sleep 1; done
    sleep 2.5
    xcrun simctl io "$UDID" screenshot "$OUT/$k-$n.png" >/dev/null 2>&1
  done
done
kill $RUN 2>/dev/null || true
ls "$OUT" | wc -l
