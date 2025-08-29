#!/usr/bin/env bash
# Run speedtest no more than every 180s, cache result, print "↓X ↑Y Mb/s".

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar_speed.json"
AGE=180

now=$(date +%s)
if [[ -f "$CACHE" ]]; then
  mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)
else
  mtime=0
fi

if (( now - mtime >= AGE )); then
  if speedtest-cli --json > "$CACHE".tmp 2>/dev/null; then
    mv "$CACHE".tmp "$CACHE"
  fi
fi

if [[ -s "$CACHE" ]]; then
  down=$(jq -r '.download // 0' "$CACHE")
  up=$(jq -r   '.upload   // 0' "$CACHE")

  # Convert bits/s → Mb/s, round to integer
  down_mbps=$(awk -v b="$down" 'BEGIN{printf "%d", b/1000000}')
  up_mbps=$(awk   -v b="$up"   'BEGIN{printf "%d", b/1000000}')

  echo "  ${down_mbps}↓  ${up_mbps}↑ Mb/s"
else
  echo "  …"
fi
