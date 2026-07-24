# 02 — Research: ThinkPad 16p Gen 2 as an always-on home server

Parent: [map](../map.md)
Type: research
Status: claimed (research subagent, branch `research/thinkpad-home-server`)
Blocked by: —

## Question

Surface the facts the keystone (03) and the "does media relocate" fog depend on,
for the ThinkPad 16p Gen 2 model class (a.k.a. ThinkPad P16 Gen 2 mobile
workstation — confirm the exact marketing name):

- **Spec range:** which CPUs (Intel 13th-gen HX?), max RAM, which NVIDIA dGPUs
  (RTX Ada / A-series) ship in it, storage/NVMe layout, NIC (2.5GbE?).
- **Always-on viability:** typical idle vs load power draw (watts), thermals and
  fan noise at idle, whether it runs reliably headless / lid-closed, and using
  the internal battery as a UPS.
- **NVIDIA + transcoding:** NVENC/NVDEC generation on its likely dGPU (for
  Jellyfin/Immich hardware transcode) vs the NAS's Intel QuickSync.
- **NixOS support:** how well this hardware (esp. the NVIDIA dGPU, in a headless
  server context) is supported on NixOS; known gotchas; whether it can slot in as
  a second `nixosConfigurations.*` host in this flake.

Findings → `.scratch/home-infra/research/thinkpad-p16g2-home-server.md`, resolved
by a `/research` subagent.
