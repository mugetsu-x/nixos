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

**Status:** deployed and set up 2026-10-06 (`modules/server/immich.nix`). Open: the first nightly DB dump in `/photos/backups` (check 2026-10-07) and the optional main-pc ML worker

- [x] Immich UI reachable; image tag pinned, not `:release` — 2026-10-06: `http://home-server:2283`, server + ML `v3.2.4` (ML `v3.2.4-cuda`), Postgres + valkey digest-pinned from that release's compose
- [x] `upload/` + `library/` on NFS; thumbs, encoded-video, model cache and Postgres on NVMe — verified by inspecting where files actually land — 2026-10-06: the test photo's original is in `/photos/library/walter/2026/2026-10-01/`, its thumbnail + preview in `/var/cache/immich/thumbs/<user-id>/…`, models in `/var/cache/immich/model-cache`, and nothing in the NAS-side `thumbs/`/`encoded-video/`
- [x] CUDA ML container healthy; **`nvidia-smi` shows it using the 3060**, not silently falling back to CPU — 2026-10-06: every model (CLIP, `buffalo_l`, OCR) loads with `CUDAExecutionProvider`, and `nvidia-smi` shows the ML `python` process at 682 MiB of 6 GB
- [x] `MACHINE_LEARNING_MODEL_TTL` set — `300` (s), in `immich.nix`
- [ ] `backups/` on NFS; a DB dump has appeared on the NAS after the first nightly run
- [x] Storage template enabled **before** any asset is uploaded; a test upload lands under `library/<user>/<year>/…` — 2026-10-06, template `{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}`: `library/walter/2026/2026-10-01/PXL_….jpg`. Storage labels are `walter` and `anja`. Set them **before** the import: the admin account defaults to `admin`, and changing a label later needs a Storage Template Migration job (Administration → Job Queues) that moves every file
- [ ] *Optional:* `main-pc` ML worker listed first, laptop second; with the PC off, a test upload still gets smart-search + faces — 2026-10-06: `modules/immich-ml.nix` on main-pc (Docker, host network, **not started at boot**: `sudo systemctl start docker-immich-machine-learning`; 3003 open to .73/.87 only). URLs set to `http://192.168.0.119:3003`, then the local container. Serving the 10 backlog. Left: the PC-off fallback test
- [x] Walter (admin) + Anja accounts created with partner sharing — 2026-10-06: both directions, `inTimeline` on for both (one merged timeline each; partner assets are view-only, and face names are kept per account)
- [x] DB password sourced from sops-nix — `immich_db_password` (40 alnum chars, generated straight into `secrets/home-server.yaml`), rendered into a sops template env file shared by server + Postgres

_Decision detail: [06](../../issues/06-immich-placement-migration.md#amendment--second-pass-2026-07-26)._

## Deployed (2026-10-06)

- **Containers:** `immich-server`, `immich-machine-learning`, `immich-postgres`,
  `immich-redis`, all `--network=host` like the rest of home-server. The images'
  default hostnames (`database`, `redis`, `immich-machine-learning`) are mapped
  to 127.0.0.1 with `--add-host`, so Immich's ML URL setting stays at its
  default. From main-pc only **2283** is open. 3003 (ML, no auth), 5432 and
  6379 are closed by the firewall, and `tailscale0` isn't trusted, so the same
  holds on the tailnet.
- **Storage:** the `photos` export is mounted as Immich's `/data` as a whole.
  `thumbs/` and `encoded-video/` are bind-overlaid from `/var/cache/immich/`, the
  model cache is `/var/cache/immich/model-cache`, and Postgres is
  `/var/lib/immich/postgres`. Everything under `/var/cache/immich` can be
  regenerated, so 13 can skip it. Postgres is covered by the nightly dumps in
  `/photos/backups`. Podman leaves empty `thumbs/` + `encoded-video/` dirs on
  the NAS as bind-mount points: expected, they stay empty.
- `podman-immich-server` has `RequiresMountsFor = /photos`.
- **Images were pre-pulled** (`podman pull` on the box, ~7 GB with the 4.5 GB
  CUDA ML image) before the switch. Do the same on a version bump so the switch
  doesn't wait on the download.
- **Bumping the version:** read every release note between the two versions
  (stepped migrations), take the Postgres/valkey digests from the new
  release's `docker-compose.yml`, pre-pull, then switch.

**First-run setup (Walter, in the browser):** `http://home-server:2283`
1. Create the admin account (Walter). During onboarding, **turn the storage
   template on** before uploading anything. Pick a year/month preset, e.g.
   `{{y}}/{{MM}}/{{filename}}`.
2. Admin → Machine Learning: smart search model `ViT-B-16-SigLIP2__webli`,
   facial recognition `buffalo_l`. Admin → Jobs: concurrency ~2 for smart search
   and face detection.
3. Upload one test photo. Check it lands in `/photos/library/<user>/<year>/…`
   and its thumbnail in `/var/cache/immich/thumbs`, and that `nvidia-smi` shows
   the ML process while it's being processed.
4. Create Anja's account, then set up partner sharing both ways (each user's
   Account settings → Partner sharing).
