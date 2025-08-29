#!/usr/bin/env bash
# Show live throughput (down/up) in Mb/s for the active interface.

# Prefer default-route interface
IF=$(ip route show default 2>/dev/null | awk '{print $5; exit}')

# Fallback: first UP, non-virtual interface (exclude lo, veth, docker, br, vmnet, tailscale)
if [ -z "$IF" ]; then
  for cand in /sys/class/net/*; do
    name=$(basename "$cand")
    case "$name" in
      lo|veth*|docker*|br*|vmnet*|tailscale*|tun*|tap*) continue;;
    esac
    if [ "$(cat "$cand/operstate" 2>/dev/null)" = "up" ]; then
      IF="$name"; break
    fi
  done
fi

[ -z "$IF" ] && { echo " no net"; exit 0; }

rx() { cat "/sys/class/net/$IF/statistics/rx_bytes" 2>/dev/null || echo 0; }
tx() { cat "/sys/class/net/$IF/statistics/tx_bytes" 2>/dev/null || echo 0; }

RX1=$(rx); TX1=$(tx)
sleep 1
RX2=$(rx); TX2=$(tx)

# bytes/s -> megabits/s = (delta * 8) / 1_000_000
awk -v dr="$((RX2-RX1))" -v dt="$((TX2-TX1))" '
BEGIN{
  down = (dr * 8) / 1000000.0
  up   = (dt * 8) / 1000000.0
  printf " %.1f   %.1f Mb/s\n", down, up
}'
