# 09 — Deploy Immich on `home-server`

**What to build:** Immich running on `home-server` against a clean, **empty**
managed library on the freshly rebuilt array — ready for [10](10-import-photos.md).

**Deploy as `oci-containers`, NOT `services.immich`.** Verified against the pinned
`nixos-25.05` (Immich 2.3.1), the NixOS module cannot do the job:

- **No CUDA.** `pkgs/by-name/im/immich-machine-learning` carries no
  `onnxruntime-gpu` and no CUDA at all — ML would run on CPU, defeating the entire
  reason Immich lives on this machine.
- **`mediaLocation` is a single path**, so the originals-on-NFS /
  thumbnails-on-NVMe split can't be expressed through it.

Use the official upstream images with **`immich-machine-learning:release-cuda`**,
and **pin the tag** — Immich ships breaking DB migrations regularly and occasionally
needs stepped upgrades. Never track `:release` unpinned.

**Storage split (non-negotiable):**

| Path | Lives on |
|---|---|
| `upload/`, `library/` | **NAS over NFS** — storage-of-record |
| `backups/` | **NAS over NFS** — Immich's own nightly DB dumps; see below |
| `thumbs/`, `encoded-video/`, ML model cache | **local NVMe** — hot path must not cross the LAN |
| Postgres volume | **local NVMe** — a DB on NFS is a corruption risk |

**`backups/` belongs on the NAS.** Immich writes a daily Postgres dump into
`backups/` under the upload location. With Postgres itself on the laptop's NVMe,
mapping that folder onto NFS means a fresh copy of the database (albums, faces,
names, edits — the only data that exists nowhere else) lands on the array every
night, independent of restic. If the laptop dies, this is what you restore from.

**Enable the storage template before the first upload.** Without it, originals land
under opaque `upload/<user-id>/xx/yy/<uuid>.jpg` paths; with it, they go to
readable `library/<user>/<year>/<month>/…`. That is what makes the NAS copy usable
as plain photos — from DSM, SMB, or a restore — if Immich is ever gone. Turning it
on later triggers a migration job that moves every file; turning it on now costs
nothing.

**ML config:** `ViT-B-16-SigLIP2__webli` smart search (English), `buffalo_l` faces,
job concurrency ≈2. Set **`MACHINE_LEARNING_MODEL_TTL`** so idle models unload —
6 GB of VRAM is now shared with Jellyfin's NVENC ([12](12-jellyfin-jellyseerr.md)).

**Optional: `main-pc` as a remote ML worker.** Immich (≥ v1.122) takes a *list* of
machine-learning URLs in Admin → Machine Learning and falls back in order. Run a
second `immich-machine-learning:release-cuda` container on `main-pc` (RTX 3080,
10 GB) and list it **first**, with the laptop's own container second: when the PC is
on, it takes the work; when it's off, the 3060 picks it up with no wake plumbing.
The value is the **initial backlog** in [10](10-import-photos.md) and model swaps —
day-to-day load is a few dozen photos and the 3060 doesn't notice it. Conditions:

- Same image tag as the server — ML and server versions must match.
- `hardware.nvidia-container-toolkit.enable` on `main-pc` too.
- Port 3003 reachable **from the LAN/tailnet only** — the ML service has no auth.
- It competes with games for VRAM. Stop the container while gaming, or drop it
  entirely once the backlog is done.

This is not ticket 03's rejected wake-on-demand model: the server, DB and library
stay always-on on the laptop; only spare GPU time is borrowed.

Two accounts — **Walter** (admin) + **Anja** — with partner sharing both ways.

**Blocked by:** 08 (GPU + NFS foundation).

**Status:** ready-for-agent

- [ ] Immich UI reachable; image tag pinned, not `:release`
- [ ] `upload/` + `library/` on NFS; thumbs, encoded-video, model cache and Postgres on NVMe — verified by inspecting where files actually land
- [ ] CUDA ML container healthy; **`nvidia-smi` shows it using the 3060**, not silently falling back to CPU
- [ ] `MACHINE_LEARNING_MODEL_TTL` set
- [ ] `backups/` on NFS; a DB dump has appeared on the NAS after the first nightly run
- [ ] Storage template enabled **before** any asset is uploaded; a test upload lands under `library/<user>/<year>/…`
- [ ] *Optional:* `main-pc` ML worker listed first, laptop second; with the PC off, a test upload still gets smart-search + faces
- [ ] Walter (admin) + Anja accounts created with partner sharing
- [ ] DB password sourced from sops-nix

_Decision detail: [06](../../issues/06-immich-placement-migration.md#amendment--second-pass-2026-07-26)._
