# Map: Home infrastructure — NAS + repurposed ThinkPad

Label: `wayfinder:map`
Tracker: local-markdown. This map lives in `nas/` next to `PLAN.md`; tickets in
`./issues/`, research in `./research/`.
Charted: 2026-07-24. **Complete: 2026-07-26** — all 8 tickets resolved, no open
frontier, destination reached. Deliverable: [`ARCHITECTURE.md`](ARCHITECTURE.md)
(+ the updated execution runbook [`PLAN.md`](PLAN.md)).

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
- [Remote-access method for reaching home services](issues/04-remote-access-method.md)
  — **Tailscale-only overlay VPN, single-user, no public exposure.** VPN-only (just
  you) rules out the whole public reverse-proxy/domain/TLS branch; ISP/CGNAT moot
  (relay NAT traversal). Direct clients on **both ThinkBook + NAS** (no subnet router)
  so the NAS stays reachable independently; MagicDNS names. **Key expiry disabled on
  both server nodes** to avoid lock-out while away. `services.tailscale.enable` on the
  `home-server` host; DSM Tailscale package on the NAS.
- [Immich: storage layout and migrating ~950 GB off the NAS](issues/06-immich-placement-migration.md)
  — **originals on NAS/NFS** (storage-of-record); **Postgres + thumbnail + ML cache on
  local NVMe** (DB never on NFS). **Managed library**, one-time **Immich CLI import**
  (dedups by hash) — not external/index-in-place. **Two accounts** (Walter admin +
  Anja) with partner sharing; import `Walter/*`→Walter, `Anja/*`→Anja, `homes`→Walter.
  Migration is a non-destructive copy → verify → reclaim, under a **soft execution gate
  on 05's off-array copy** (no formal block). ML: **CUDA image**, English smart search
  `ViT-B-16-SigLIP2__webli`, `buffalo_l` faces, concurrency ≈2 — 6 GB VRAM ample. Host
  prereq: `nvidia-container-toolkit` on the `home-server` host.
- [Backup strategy: 3-2-1 topology and offsite target for the photos](issues/05-backup-topology.md)
  — tiered scope: **photos full 3-2-1**, media excluded (re-downloadable), laptop app-state
  lighter tier. **Laptop-orchestrated:** copy #1 = NAS array (post-Immich = the managed
  library); copy #2 = **dedicated 4 TB USB HDD on the ThinkBook** (in hand), nightly **pull**
  from NAS; copy #3 = **Hetzner Storage Box** (5 TB BX21 ~€143/yr, client-side encrypted).
  Tool = **restic** via `services.restic.backups` on `home-server` (DBs `pg_dump`'d first).
  Nightly, retention 7d/8w/12m/5y, weekly prune; **immutability via Hetzner Storage Box
  snapshots** the client can't delete. **Immediate:** `restic init` + first snapshot of the
  raw shares from `main-pc` *now* — clears PLAN.md phase-0 **and** is 06's off-array hard
  gate; Hetzner upload runs off the critical path. Restore test: monthly `restic check`
  + sample restore, one real offsite drill, keys stored off the laptop.
- [File-sync / personal-cloud solution](issues/07-file-sync-solution.md)
  — **Build nothing.** No self-hosted file-sync on either machine. Documents stay on
  **Google Drive** (+ physical copies; no de-Googling intent), Immich (06) covers photos,
  the media stack covers media — nothing falls through the cracks. Rejected Syncthing +
  Nextcloud (permanent maintenance to re-solve a solved problem). Closes 05's dangling
  conditional (no file-sync source-of-record to back up). Revisit as a *fresh* ticket only
  if a real need appears (large files unfit for Drive, de-Googling, family web surface).

- [Media stack: what relocates, and fold PLAN.md into the map](issues/08-media-relocation-and-plan-consolidation.md)
  — **Nothing relocates: the whole media pipeline stays on the NAS.** arr stack stays
  for **hardlink locality** (old "must be awake" reason retired); Jellyfin stays because
  playback is **restricted to same-network** ⇒ direct-play dominates ⇒ data-locality wins.
  Remote = best-effort over Tailscale; **RTX 3060 = documented escape hatch** if remote
  transcode ever becomes routine. Quality flipped **1080p → 4K for films *and* TV** (safe
  because 05 makes media re-downloadable), so the array is a **rotating pool, not an
  archive** — curate/delete first, upgrade disks (2→4→8 TB) for real growth.
  **Consolidation:** PLAN.md kept standalone + updated laptop-aware; whole-home capstone
  **[`ARCHITECTURE.md`](ARCHITECTURE.md)** assembled from all 8 tickets. **Map complete.**

## Not yet specified

<!-- Empty — the frontier reached the destination. The last fog patch below
     resolved by *pattern* rather than by ticket: there was no architectural
     decision left in it. -->

- ~~**Other self-hosted apps** (ebooks/manga, dashboard, home automation).~~
  **Resolved by pattern, not by ticket** (08). The placement rule is fully
  determined — a new light app runs on `home-server` as an oci-container mounting
  NAS storage, reached over Tailscale, following the Immich pattern (see
  [`ARCHITECTURE.md`](ARCHITECTURE.md) → "Future self-hosted apps"). Naming and
  deploying specific apps is **execution**, not an architectural decision — so no
  ticket is owed and the map is done.

## Out of scope

- **Media pipeline internals** — usenet provider/indexer, SABnzbd/Prowlarr/Radarr
  choice, the single-shared-folder hardlink layout, phase-0 RAM+drive fit. Settled
  in [`PLAN.md`](PLAN.md); this effort only revisits *where* they run.
