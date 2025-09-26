#!/usr/bin/env bash
set -e
active="$(hyprctl -j activeworkspace | jq -r '.id // 1' 2>/dev/null || echo 1)"
out=""
for i in 1 2 3; do
  if [ "$i" = "$active" ]; then
    out="$out [$i]"
  else
    out="$out $i"
  fi
done
echo "${out# }"
