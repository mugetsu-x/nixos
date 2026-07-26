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
| `thumbs/`, `encoded-video/`, ML model cache | **local NVMe** — hot path must not cross the LAN |
| Postgres volume | **local NVMe** — a DB on NFS is a corruption risk |

**ML config:** `ViT-B-16-SigLIP2__webli` smart search (English), `buffalo_l` faces,
job concurrency ≈2. Set **`MACHINE_LEARNING_MODEL_TTL`** so idle models unload —
6 GB of VRAM is now shared with Jellyfin's NVENC ([12](12-jellyfin-jellyseerr.md)).

Two accounts — **Walter** (admin) + **Anja** — with partner sharing both ways.

**Blocked by:** 08 (GPU + NFS foundation).

**Status:** ready-for-agent

- [ ] Immich UI reachable; image tag pinned, not `:release`
- [ ] `upload/` + `library/` on NFS; thumbs, encoded-video, model cache and Postgres on NVMe — verified by inspecting where files actually land
- [ ] CUDA ML container healthy; **`nvidia-smi` shows it using the 3060**, not silently falling back to CPU
- [ ] `MACHINE_LEARNING_MODEL_TTL` set
- [ ] Walter (admin) + Anja accounts created with partner sharing
- [ ] DB password sourced from sops-nix

_Decision detail: [06](../../issues/06-immich-placement-migration.md#amendment--second-pass-2026-07-26)._
