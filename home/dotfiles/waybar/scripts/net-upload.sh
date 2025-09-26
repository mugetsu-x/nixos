#!/usr/bin/env bash
# Current upload only (Mb/s), aggregated over real interfaces.

filter() {
  awk -F: 'NR>2{gsub(/^[[:space:]]+/,"",$1); print $1}' /proc/net/dev \
    | grep -Ev '^(lo|veth|docker|br|tun|tap|tailscale|wg|vmnet)'
}

sum_tx() {
  total=0
  for ifc in $(filter); do
    line=$(grep -E "^[[:space:]]*$ifc:" /proc/net/dev)
    vals=${line#*:}
    txb=$(awk '{print $9}' <<<"$vals")
    total=$((total + txb))
  done
  echo "$total"
}

t1=$(sum_tx); sleep 1; t2=$(sum_tx)
up=$(awk -v dt="$((t2-t1))" 'BEGIN{printf "%.1f", (dt*8)/1000000.0}')
[[ $(awk "BEGIN{print ($up<0)}") -eq 1 ]] && up=0.0
echo "↑ ${up} Mb/s"
