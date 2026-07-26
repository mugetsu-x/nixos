# 03 — Stand up the home-server NixOS host

**What to build:** The repurposed ThinkBook 16p Gen 2 running NixOS as a **second
host in this flake** (`nixosConfigurations.home-server` + `hosts/home-server.nix`),
always-on. It boots unattended lid-closed and out of the living space, networks
over the owned **USB-C→RJ45 adapter** (Wi-Fi only otherwise), and is SSH-reachable
on the LAN. Base host only — GPU-containers (09), Tailscale (06), Immich (10) and
backups (12) build on top of this. Mind the headless-idle EDID quirk and use the
nvidia open driver. Minor flake wiring: the flake currently defines one host, so
factor the `nixosConfigurations` entry cleanly for a second.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `nixosConfigurations.home-server` builds; `nix flake check --no-build` passes
- [ ] ThinkBook boots NixOS from the flake, unattended, lid-closed
- [ ] Reachable over SSH on the LAN via the USB-C→RJ45 Ethernet
- [ ] Stays up 24/7 (no idle suspend); idle power draw sanity-checked

_Decision detail: [03](../../issues/03-keystone-server-or-not.md), [01](../../issues/01-thinkpad-unit-and-always-on.md), [research](../../research/thinkpad-p16g2-home-server.md)._
