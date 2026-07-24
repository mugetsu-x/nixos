# 02 — Research: ThinkPad 16p Gen 2 as an always-on home server

Parent: [map](../map.md)
Type: research
Status: resolved
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

## Answer

Full note: [`research/thinkpad-p16g2-home-server.md`](../research/thinkpad-p16g2-home-server.md).
Primary/high-trust sources cited inline (Lenovo PSREF, StorageReview/Notebookcheck,
NVIDIA dev forums, Tom's/VideoCardz on NVENC limits, NixOS wiki/Jellyfin docs).

- **Model = Lenovo ThinkPad P16 Gen 2 (16″ Intel)**, HX-class mobile workstation
  (type `21FA…`); "16p Gen 2" is a transposition of "P16 Gen 2". *Beware the
  weaker P16v / P16s.* Exact CPU/RAM/GPU must be read off the unit (ticket 01) —
  every GPU-dependent conclusion hinges on which card is fitted.
- **Specs:** Intel 13th/14th-gen **HX** (up to 24 cores), **DDR5 to 192 GB** / 4
  SO-DIMM slots, **NVIDIA RTX Ada** dGPU (2000/3500/4000/5000 Ada, 8–16 GB — or
  base RTX A1000 6 GB Ampere), 2× M.2 NVMe (one likely free, SSD-only — bulk
  media stays on the NAS), ~94 Wh battery, 170–230 W adapter.
- **Transcode/ML — categorically beats the NAS:** Ada = 8th-gen NVENC with **AV1
  encode**, and as a *professional* card it has **no NVENC concurrent-session
  cap** (GeForce caps at 8; the Celeron is fixed-function H.264/HEVC only, no
  AV1). Plus **CUDA + 8–16 GB VRAM for Immich ML**. Caveat: home playback is a
  direct-playing Shield, so routine media transcode rarely fires — the everyday
  win is **Immich ML**, not media transcode.
- **Power — the main downside:** a 200 W+ workstation chassis, not a low-idle
  NAS. Realistic idle **~15–25 W** (measure it), well above a DS420+. Watch the
  documented **NVIDIA headless-idle penalty** (dGPU won't reach lowest idle with
  no display) — mitigate with a dummy/fake EDID.
- **No built-in RJ-45** — wired Ethernet needs a USB-C/Thunderbolt adapter; a
  real gap for an always-on server. Plan the dongle.
- **Battery = genuine mini-UPS** (blips + clean shutdown), but cap the charge
  threshold for longevity; not a full-outage UPS.
- **NixOS — well supported, low-risk:** a second `nixosConfigurations.<host>` is
  additive; reuse the repo's NVIDIA-open-driver setup +
  `hardware.graphics.enable` + `nvidia-container-toolkit` + lid-ignore + a
  headless (no-desktop) module set. Gotchas: the headless-idle EDID quirk and the
  Ethernet dongle.
