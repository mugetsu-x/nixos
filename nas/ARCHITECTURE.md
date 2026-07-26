# Home infrastructure — architecture

The written architecture plan for extensive home use across two machines:

- **Alexandria** — Synology **DS420+** (DSM 7.3, Celeron J4025, 6 GB after phase 0,
  btrfs RAID 5). The **storage/durability layer**.
- **home-server** — repurposed **Lenovo ThinkBook 16p Gen 2** (Ryzen 9 5900HX,
  RTX 3060 6 GB, 32 GB, NVMe), a second NixOS host in this flake, always-on. The
  **compute/application layer**.

This doc is the readable summary; each decision's *detail and rationale* lives in
its wayfinder ticket under [`issues/`](issues/), and the media build runbook is
[`PLAN.md`](PLAN.md). Charted via [`map.md`](map.md).

## Governing principle

**The NAS is the storage-of-record; the laptop is the compute.** Any application
that needs CPU/GPU or wants to be a clean service runs on `home-server` and mounts
NAS bulk storage over the LAN. The NAS keeps only durability and *light,
storage-adjacent* services that genuinely want to sit next to their data.
Established in the keystone, [ticket 03](issues/03-keystone-server-or-not.md).

## Division of labour

| Workload | Runs on | Data lives on | Why there |
|---|---|---|---|
| **Download + arr** (SAB, Prowlarr, Radarr, Sonarr) | **NAS** | NAS array | Hardlink imports must be same-filesystem — local, not over NFS |
| **Media server** (Jellyfin, Plex during proving) | **NAS** | NAS array | Same-network playback ⇒ direct-play dominates ⇒ data-local wins |
| **Photos** (Immich) | **laptop** | originals on NAS/NFS; Postgres + thumbnails + ML cache on local NVMe | CUDA smart-search/faces on the 3060; DB never on NFS |
| **File sync** | *nothing self-hosted* | Google Drive | A solved problem; not worth re-solving ([07](issues/07-file-sync-solution.md)) |
| **Backups** (restic) | **laptop** | 4 TB USB HDD (laptop) + Hetzner Storage Box | Laptop orchestrates the 3-2-1; DBs `pg_dump`'d first |
| **Remote access** (Tailscale) | **both nodes** | — | Each node independently reachable; no public exposure |

## Media

- **Placement:** the whole pipeline stays on the NAS — arr stack for hardlink
  locality, media server because same-network playback is dominated by direct-play
  (Shield, capable LAN devices) and wants its data local.
- **Playback is designed for the home LAN.** Remote/away-from-home viewing works
  *best-effort* over Tailscale when bandwidth + a capable client allow it, but is
  not a design driver. **Escape hatch:** if remote viewing ever becomes routine,
  the *only* fix is to move Jellyfin onto the laptop's RTX 3060 (NVENC/NVDEC) — the
  GPU is deliberately held in reserve for exactly this.
- **Quality: 4K for both films and TV.** The home theater is 4K.
- **Storage model: the array is a rotating pool, not an archive.** Media is
  re-downloadable (which is why [05](issues/05-backup-topology.md) excludes it from
  backup), so when the array fills you **curate/delete first** — it re-downloads on
  demand. Disk upgrades (2 TB → 4 TB → ~10.9 TB usable, then bigger drives) are for
  growing the genuine keep-set, **not** a substitute for deleting.
- **Transcode:** the rare same-network exception (a web browser) transcodes on the
  Celeron's QuickSync; the Shield direct-plays 4K HEVC natively.
- Build steps, hardware, usenet, and the hardlink share layout: [`PLAN.md`](PLAN.md).

## Photos — Immich ([06](issues/06-immich-placement-migration.md))

Runs on `home-server`. **Originals on NAS/NFS** (storage-of-record); **Postgres +
thumbnails + ML cache on local NVMe** (DB never on NFS). Managed library, one-time
Immich-CLI import (hash-dedup). Two accounts (Walter admin + Anja) with partner
sharing. ML on the **CUDA image** (`ViT-B-16-SigLIP2__webli` smart search,
`buffalo_l` faces, concurrency ≈2 — 6 GB VRAM ample). Host prereq:
`nvidia-container-toolkit`. Migration is non-destructive copy → verify → reclaim,
gated on 05's off-array copy existing first.

## Backups — 3-2-1 ([05](issues/05-backup-topology.md))

Laptop-orchestrated **restic** (`services.restic.backups` on `home-server`; DBs
`pg_dump`'d first). Tiered scope: **photos get full 3-2-1**, media excluded
(re-downloadable), laptop app-state on a lighter tier.

- Copy #1 — NAS array (the live managed library).
- Copy #2 — dedicated **4 TB USB HDD on the ThinkBook**, nightly pull from NAS.
- Copy #3 — **Hetzner Storage Box** (BX21 ~5 TB, ~€143/yr), client-side encrypted,
  immutable via server-side snapshots the client can't delete.

Retention 7d/8w/12m/5y, weekly prune. Monthly `restic check` + sample restore, one
real offsite drill, keys stored **off** the laptop. **Immediate action:**
`restic init` + first snapshot of the raw NAS shares from `main-pc` now — clears
PLAN.md phase-0 *and* is 06's hard gate.

## Remote access — Tailscale ([04](issues/04-remote-access-method.md))

Single-user overlay VPN, **no public exposure** — this rules out the whole
reverse-proxy/domain/TLS branch and makes ISP/CGNAT moot. Direct Tailscale clients
on **both** the ThinkBook and the NAS (no subnet router) so each stays reachable
independently; MagicDNS names. **Key expiry disabled on both server nodes** to
avoid lock-out while away. `services.tailscale.enable` on `home-server`; DSM
Tailscale package on the NAS.

## Future self-hosted apps

No architectural decision remains — the **placement pattern above already decides
it**: a new light app (ebooks/manga, a dashboard, home automation) runs on
`home-server` as an oci-container mounting NAS storage as needed, reached over
Tailscale, following the Immich pattern. Only *picking and deploying* specific apps
is left, and that is execution, not architecture.
