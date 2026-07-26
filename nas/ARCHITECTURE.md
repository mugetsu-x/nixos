# Home infrastructure — architecture

The written architecture plan for extensive home use across two machines:

- **Alexandria** — Synology **DS420+** (DSM 7.x, Celeron J4025, 6 GB, btrfs
  **SHR-1** after the rebuild). The **storage layer, and nothing else**.
- **home-server** — repurposed **Lenovo ThinkBook 16p Gen 2** (Ryzen 9 5900HX,
  RTX 3060 6 GB, 32 GB, 1 TB NVMe), a second NixOS host in this flake, always-on.
  The **compute/application layer** — it runs everything.

This doc is the readable summary; each decision's *detail and rationale* lives in
its wayfinder ticket under [`issues/`](issues/), the build runbook is
[`PLAN.md`](PLAN.md), and the execution queue is [`build/issues/`](build/issues/).
Charted via [`map.md`](map.md).

> **Revised 2026-07-26 (second pass).** Ticket [08](issues/08-media-relocation-and-plan-consolidation.md)
> was re-grilled after both of its load-bearing premises turned out to be false,
> and the result cascaded. The NAS is now *pure storage*; every service runs on
> the laptop; the array is rebuilt from scratch rather than expanded live; and the
> offsite copy is Google Drive rather than Hetzner. See
> [What changed in the second pass](#what-changed-in-the-second-pass).

## Governing principle

**The NAS stores bytes. The laptop runs everything.**

The DS420+ is a 2-core Celeron. Every attempt to give it a service role has been
justified by a premise that did not survive checking — it cannot hardware
transcode 4K HDR, and it was never needed for hardlink locality. So it keeps
exactly one job, the one it is actually good at: RAID'd, snapshotted, checksummed
storage exposed over NFS. **It runs zero containers.** Container Manager is
uninstalled.

Everything else — media, photos, downloads, backups — is an `oci-container` on
`home-server`, declared in this flake, mounting NAS storage over NFS.

Established in the keystone [03](issues/03-keystone-server-or-not.md), materially
revised by [08](issues/08-media-relocation-and-plan-consolidation.md).

## Division of labour

| Workload | Runs on | Data lives on | Why there |
|---|---|---|---|
| **Download + post-processing** (SABnzbd) | **laptop** | `incomplete/` on local NVMe, `complete/` on NAS | par2 + unrar are random-I/O and CPU-bound — keep them off the array and off the Celeron |
| **arr** (Prowlarr, Radarr, Sonarr) | **laptop** | NAS array over NFS | Hardlinks work fine over NFS; declarative in-flake beats a hand-deployed DSM compose |
| **Media server** (Jellyfin, Jellyseerr) | **laptop** | NAS array over NFS | Phones and browsers need real transcoding — that means the RTX 3060 |
| **Photos** (Immich) | **laptop** | originals on NAS/NFS; Postgres + thumbnails + ML cache on local NVMe | CUDA smart-search/faces on the 3060; DB never on NFS |
| **File sync** | *nothing self-hosted* | Google Drive | A solved problem; not worth re-solving ([07](issues/07-file-sync-solution.md)) |
| **Backups** (restic) | **laptop** | 4 TB USB HDD + Google Drive | Laptop orchestrates the 3-2-1; DBs `pg_dump`'d first |
| **Remote access** (Tailscale) | **both nodes** | — | Each node independently reachable; no public exposure |
| **Storage, NFS, snapshots, scrub** | **NAS** | — | Its only job |

## The NAS is rebuilt, not expanded

The original plan expanded the live 3×2 TB RAID 5 array by adding the in-hand
4 TB IronWolf — an **online reshape that runs degraded for a day or more** on a
Celeron, with the only primary copy of ~950 GB of irreplaceable family photos on
it. That was the single most dangerous operation in the whole plan.

Since everything on the NAS except the photos is disposable, the photos come off
first anyway. Once they are off, a **wipe and fresh rebuild is both safer and
strictly better**:

- **The degraded reshape disappears.** A freshly created array has nothing at risk
  on it.
- **It is the only way onto SHR.** DSM cannot convert classic RAID 5 → SHR. Same
  capacity today, much better upgrade path:

  | Disks | Classic RAID 5 | **SHR-1** |
  |---|---|---|
  | 2,2,2,**4** | 6 TB | 6 TB |
  | 2,2,**4,4** | 6 TB | **8 TB** |
  | 2,**4,4,4** | 6 TB | **10 TB** |
  | **4,4,4,4** | 12 TB | 12 TB |

  Under classic RAID 5 the next two disks you buy give you **nothing**. Under SHR
  each one pays off immediately — which matters because 4K makes capacity the
  binding constraint.
- **It collapses the Immich migration.** Photos are already on USB, so Immich
  imports from USB into a clean empty library: no double copy on the array, no
  space pressure, no reclaim step to get right.
- **It removes accumulated DSM cruft** — legacy Plex package, the media-inside-the-
  Plex-share layout, whatever else has built up.

**SHR-2 / RAID 6 considered and rejected:** dual redundancy costs 2 TB of the 6,
and with a genuine 3-2-1 in place that is over-insuring capacity you have already
decided you need.

Detail and the exact sequence: [`PLAN.md`](PLAN.md).

## Media

- **Placement: the entire pipeline runs on `home-server`.** SABnzbd, Prowlarr,
  Radarr, Sonarr, Jellyfin, Jellyseerr — all `oci-containers` in this flake.
- **Hardlinks work over NFS.** This is the fact the old plan got wrong. NFSv3/v4
  implement `LINK`; the hardlink is created server-side on the NAS's btrfs.
  The requirement is that `usenet/complete` and `media/` sit inside **one NFS
  export, mounted at one path, with identical paths inside every container** —
  which is exactly the single-share layout already designed. What breaks hardlinks
  is separate mounts or inconsistent container path mappings, not NFS.
- **SABnzbd is split across two filesystems on purpose.** `incomplete/` on the
  laptop's local NVMe, `complete/` on the NFS mount. par2 verification and unrar
  are heavy random I/O; running them on NVMe keeps that churn off a RAID 5-style
  array where it would compete with Immich reads and the nightly restic run, and
  the finished file crosses the LAN exactly once — landing in the same share as
  `media/`, so Radarr's hardlink import still works.
- **Playback is designed for the whole house, not just the Shield.** The Shield
  direct-plays 4K HEVC. Everything else — phones, tablets, browsers, other TVs —
  needs a real transcode, and against 4K HDR sources that means **HDR→SDR tone
  mapping**, which the J4025's UHD 600 cannot do in real time. Jellyfin therefore
  runs on the RTX 3060 (NVENC HEVC/H.264 + GPU tone mapping). Remote viewing over
  Tailscale is best-effort but now actually works, because the GPU is in the path.
- **Plex is retired outright.** Home-only playback and no Plex Pass meant Plex
  could never hardware-transcode at all — it was a fallback that only worked for
  the one client that never needed a fallback.
- **Quality: 4K for both films and TV**, with a caveat that matters —
  Radarr/Sonarr's stock *Ultra-HD* profile allows **only** 2160p, so Sonarr would
  wait forever for 4K releases that mostly do not exist on usenet. Both apps get a
  **custom profile: 1080p allowed, 2160p as the upgrade cutoff.**
- **Storage model: the array is a rotating pool, not an archive.** Media is
  re-downloadable (which is why [05](issues/05-backup-topology.md) excludes it from
  backup), so when it fills you **curate/delete first**. Concretely: ~6 TB usable
  minus the photo library leaves roughly **4 TB for media — on the order of 60–100
  4K titles**, not 500. Write that number down; "curate first" reads very
  differently once you know the pool size.
- Build steps, hardware, usenet, share layout: [`PLAN.md`](PLAN.md).

## Photos — Immich ([06](issues/06-immich-placement-migration.md))

Runs on `home-server`. **Originals on NAS/NFS** (storage-of-record); **Postgres +
thumbnails + ML cache on local NVMe** (DB never on NFS). Managed library, one-time
Immich-CLI import (hash-dedup) **from the USB evacuation copy** into a clean, empty
library. Two accounts (Walter admin + Anja) with partner sharing. ML on the **CUDA
image** (`ViT-B-16-SigLIP2__webli` smart search, `buffalo_l` faces, concurrency ≈2).

Two corrections from the second pass:

- **Deployed as `oci-containers`, not `services.immich`.** The NixOS module in the
  pinned nixpkgs (`nixos-25.05`, Immich 2.3.1) has **no CUDA support** —
  `immich-machine-learning` carries no `onnxruntime-gpu`, so ML would run on CPU,
  defeating the entire reason Immich is on this machine. The module's
  `mediaLocation` is also a single path, so the originals-on-NFS /
  thumbnails-on-NVMe split cannot be expressed in it.
- **Source photos live in more places than the old inventory listed.** Synology
  Photos keeps personal space in `homes/<user>/Photo` and **shared space in
  `/volume1/photo`** — a share that appeared in no ticket. Every Synology Photos
  folder also contains **`@eaDir`** thumbnail directories that must be excluded
  from the import.

## Backups — 3-2-1 ([05](issues/05-backup-topology.md))

Laptop-orchestrated **restic** (`services.restic.backups` on `home-server`; DBs
`pg_dump`'d first). Tiered scope: **photos get full 3-2-1**, media excluded
(re-downloadable), laptop app-state on a lighter tier.

- Copy #1 — NAS array (the live Immich managed library).
- Copy #2 — dedicated **USB HDD on the ThinkBook**, nightly pull from NAS.
- Copy #3 — **Google Drive** (Workspace Business Plus, 5 TB pooled, already paid),
  via restic's **rclone** backend, client-side encrypted.

**Google Drive replaces Hetzner Storage Box.** Ticket 05 compared Hetzner against
Backblaze B2 and physical-disk rotation but never considered storage already
owned — that was the ticket's blind spot. Business Plus includes **Google Vault**,
whose admin-enforced retention restores most of the immutability that Hetzner's
server-side snapshots provided. Saves ~€143/yr. Mandatory conditions:

- **Own OAuth client ID** for rclone — the shared default is rate-limited into
  uselessness.
- **`--pack-size 64`** (default 16 MiB) to cut object count ~4×, which is what
  makes `check` and `prune` tolerable over Drive's paginated, rate-limited API.
- **Hard retention ceiling + an alert on pool usage**, so the repo can never grow
  into the quota that also runs Gmail. This is the one failure mode Hetzner did
  not have.
- Drive proper, **not** Google Photos — that API is no longer usable for this.
- Seeding is capped at **750 GB/day per user**, so ~950 GB takes ≥2 days. Run it
  before the wipe, unattended, off the critical path.

Retention 7d/8w/12m/5y, weekly prune. Monthly `restic check` + sample restore, one
real offsite drill, keys stored **off** the laptop.

**Backup scope is a denylist, not an allowlist.** The evacuation snapshot covers
*everything* under `/volume1` except confirmed-disposable media. restic dedups and
compresses, so over-including is nearly free — while an enumerated allowlist is
exactly how `/volume1/photo` came to be missing from every ticket.

## Remote access — Tailscale ([04](issues/04-remote-access-method.md))

Single-user overlay VPN, **no public exposure** — this rules out the whole
reverse-proxy/domain/TLS branch and makes ISP/CGNAT moot. Direct Tailscale clients
on **both** the ThinkBook and the NAS (no subnet router) so each stays reachable
independently; MagicDNS names. **Key expiry disabled on both server nodes** to
avoid lock-out while away. `services.tailscale.enable` on `home-server`; DSM
Tailscale package on the NAS — the one non-storage thing the NAS still runs, and
it is a native package, not a container.

## Cross-cutting concerns

These are not workload placements, but nothing works without them.

### Secrets

Every service needs one: restic repo password, Google Drive OAuth + rclone config,
Tailscale auth key, Eweka credentials, NZBGeek API key, Immich DB password. This
repo has a **public GitHub remote** and CI runs on every push, so secrets are
managed with **sops-nix**, keyed to each host. Nothing in plaintext, ever. This
gates the `home-server` host coming up at all.

### Alerting

An unattended box whose job is holding your only backup fails **silently** — a
restic job erroring for four months looks identical to one that works. Alerting is
**dead-man style** (alert on the *absence* of success, not on error) via
healthchecks.io pings from every timer, plus `ntfy` for immediate failures.

### The NFS mount is a hard dependency for every service

With everything on the laptop, a dropped mount breaks media, photos and downloads
at once. That is survivable. What is **not** survivable: restic snapshotting an
*unmounted* mountpoint, writing a near-empty snapshot, and `forget --prune` then
ageing out the real history. That is how people delete their own backups.

- NFS mounts are `hard` with `x-systemd.automount`.
- Containers order on the mount unit (`RequiresMountsFor=`).
- The backup job runs a **mount guard** and aborts loudly rather than snapshotting
  an empty tree.

### Power and integrity

- **The NAS has no UPS.** The laptop has a battery; the durability layer — btrfs
  parity, holding copy #1 — has nothing. A small UPS is the cheapest risk
  reduction in the plan.
- **Scheduled btrfs scrub + SMART tests** on the NAS. On a multi-year array, scrub
  is how bit rot is found before it propagates into every backup.

### Known tight resource: the laptop's 1 TB NVMe

Now holds NixOS, Immich Postgres, Immich thumbnails (~50–150 GB depending on asset
count), the ML model cache, Jellyfin metadata + transcode cache, the restic local
cache, container images, **and** SABnzbd's `incomplete/` — which needs up to
~160 GB transiently for a 4K release mid-unpack. It fits, but it is the tightest
resource on the box. The likely-free second M.2 slot noted in
[01](issues/01-thinkpad-unit-and-always-on.md) is worth confirming.

Also: **6 GB of VRAM is shared** between Immich ML and Jellyfin NVENC. Set
`MACHINE_LEARNING_MODEL_TTL` so models unload when idle; expect contention during
the initial ML backlog run.

## Future self-hosted apps

No architectural decision remains — the placement pattern already decides it: a new
app runs on `home-server` as an `oci-container` mounting NAS storage as needed,
reached over Tailscale, secrets via sops-nix, following the Immich pattern. Only
*picking and deploying* specific apps is left, and that is execution.

## What changed in the second pass

| | First pass (2026-07-26 AM) | Second pass (2026-07-26 PM) |
|---|---|---|
| Jellyfin | NAS | **laptop** — phones/browsers need the 3060 |
| SAB + arr | NAS ("hardlink locality") | **laptop** — that premise was false |
| Jellyseerr | NAS | **laptop** |
| Plex | kept during proving | **retired outright** — no Pass, so no HW transcode ever |
| NAS role | storage + light services | **pure storage, zero containers** |
| Array | live RAID 5 reshape → 5.4 TB | **wipe + fresh SHR-1** → 6 TB, better upgrade path |
| Immich deploy | `services.immich` | **`oci-containers`** — the module has no CUDA |
| Immich import | copy on-array → verify → reclaim | **from USB into an empty library** |
| Offsite | Hetzner, €143/yr | **Google Drive**, already paid |
| Quality profile | stock "Ultra-HD" | **custom: 1080p allowed, 2160p cutoff** |
| Secrets / alerting | unspecified | **sops-nix / dead-man healthchecks** |

The speed argument did **not** drive the arr relocation: at 170–250 Mbps the
Celeron costs roughly 20 minutes on a 60 GB film in an asynchronous workflow. The
move is justified by the clean boundary and declarative management. Recorded
explicitly so nobody "optimises" it back later on the wrong grounds.
