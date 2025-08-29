#!/usr/bin/env bash
# Cached speedtest (≤ every 180s). Prints only download as integer Mb/s.

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar_speed.json"
AGE=180
now=$(date +%s)
mtime=0
[[ -f "$CACHE" ]] && mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)

if (( now - mtime >= AGE )); then
  if speedtest-cli --json > "$CACHE".tmp 2>/dev/null; then
    mv "$CACHE".tmp "$CACHE"
  fi
fi

if [[ -s "$CACHE" ]]; then
  down=$(jq -r '.download // 0' "$CACHE")
  down_mbps=$(awk -v b="$down" 'BEGIN{printf "%d", b/1000000}')
  # simple cloud+down line; we’ll style later
  echo "☁ ${down_mbps} Mb/s"
else
  echo "☁ …"
fi
