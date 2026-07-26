# Map: Home infrastructure — NAS + repurposed ThinkPad

Label: `wayfinder:map`
Tracker: local-markdown. This map lives in `nas/` next to `PLAN.md`; tickets in
`./issues/`, research in `./research/`.
Charted: 2026-07-24.

## Destination

A **written architecture plan** for extensive home use, spanning the Synology
DS420+ ("Alexandria") and the ThinkPad 16p Gen 2 you no longer need — deciding,
for each workload (media, photos, file sync, backups, remote access), **which
machine runs it and how the two divide labour**, plus backup topology and the
remote-access approach. "Plan, don't do": the map produces decisions written up
like `nas/PLAN.md`, then you execute. Done when nothing architectural is left to
decide.

## Notes

- **Domain:** home lab / self-hosting for a single household. NixOS shop (this
  repo); the DS420+ runs DSM 7.3, Container Manager, btrfs, RAID 5. Weak Celeron
  J4025 / 6 GB (after phase 0). Playback is home-only via an NVIDIA Shield.
- **Keystone insight (from charting):** `nas/PLAN.md` is generally correct but
  was written *before* the laptop existed in the picture. The standing rule for
  this whole effort: **for any workload, if it makes more sense on the laptop
  than the NAS, put it on the laptop.** So the laptop-role decision cascades into
  almost everything and must resolve early.
- **Consistency, not re-litigation:** the media pipeline's *internals* (usenet,
  hardlink layout, phase-0 hardware) are settled in `nas/PLAN.md` and are out of
  scope here. What *is* in scope is whether any of those workloads **relocate**
  to the laptop.
- **Skills:** `/grilling` + `/domain-modeling` for decision tickets; `/research`
  for AFK fact-finding; `/prototype` if a topology needs a concrete sketch.
- **Irreplaceable data:** ~950 GB of family photos on the NAS. Backups (ticket
  05) is the highest-stakes decision; treat it as such.

## Decisions so far

<!-- one line per closed ticket: gist + link -->

- [Research: ThinkPad 16p Gen 2 as an always-on home server](issues/02-thinkpad-home-server-research.md)
  — general viability of a laptop-as-server: NixOS 2nd flake host low-risk; ~15–25 W
  idle (measure), **no built-in Ethernet**, headless-idle EDID quirk, battery = mini-UPS.
  ⚠️ **Its GPU/CPU premise was wrong** — corrected by 01 below (real unit is a
  ThinkBook, not a P16; consumer RTX 3060, not pro Ada). Full note in `research/`.
- [Establish the ThinkPad's real specs and 24/7 acceptability](issues/01-thinkpad-unit-and-always-on.md)
  — it's a **Lenovo ThinkBook 16p Gen 2 (20YM)**: Ryzen 9 5900HX (8c/16t), GeForce
  **RTX 3060 6 GB** (CUDA ✓, HEVC/H.264 ✓, **no AV1 encode**, GeForce session cap),
  32 GB (both slots full), 1 TB NVMe + likely-free 2nd M.2, Wi‑Fi only. Immich-ML
  value case survives; Ada/AV1/pro-card case does not. **Always-on = YES**, lid
  closed + out of living space, ~**€62–93/yr** at €0.355/kWh. Unblocks keystone 03.
- [Keystone: does the ThinkPad become the always-on server, and how is it managed?](issues/03-keystone-server-or-not.md)
  — **YES, always-on services host (Model A):** laptop is the "brain", NAS demoted
  to storage-of-record + light storage-adjacent services. Ethernet via owned
  USB-C→RJ45 (Wi-Fi-only caveat resolved); wake-on-demand rejected (doesn't fix
  the weak NAS; WoL dead over USB Ethernet). **OS = NixOS second host in this
  flake** (`home-server`), NixOS modules + oci-containers. **Principle:** NAS =
  storage/durability layer; laptop = compute/application layer, mounting NAS bulk
  storage over LAN. Graduates the fog into 06/07/08.

## Not yet specified

<!-- in-scope fog; graduates as the frontier advances. The keystone (03) is now
     resolved — placement is fixed at "laptop = compute", so the Immich, file-sync
     and media-relocation patches graduated into tickets 06/07/08. What remains
     here is still too coarse to ticket. -->

- **Other self-hosted apps.** Ebooks/manga (TODO items 2–3), a dashboard, maybe
  home automation. Trivial to place once a compute home (03 ✓) and remote access
  (04) exist; still fog because the specific set isn't pinned. Graduates once 04
  lands and you name which apps you actually want.

## Out of scope

- **Media pipeline internals** — usenet provider/indexer, SABnzbd/Prowlarr/Radarr
  choice, the single-shared-folder hardlink layout, phase-0 RAM+drive fit. Settled
  in [`PLAN.md`](PLAN.md); this effort only revisits *where* they run.
