# 08 — Laptop GPU + NFS foundation

**What to build:** `home-server` ready to run GPU containers against NAS storage.
This is the substrate every remaining service sits on, and it is where the plan's
sharpest failure mode is designed out.

**GPU:** `hardware.nvidia-container-toolkit.enable = true` plus an oci-containers
backend, proven by a CUDA container that enumerates the RTX 3060.

**NFS — and this is the important half.** With every service on the laptop, one
mount carries media, downloads and the photo library. A dropped mount breaking
playback is survivable. What is **not** survivable: restic snapshotting an
*unmounted* mountpoint, writing a near-empty snapshot, and `forget --prune` then
ageing out the real history on schedule. **That is how people delete their own
backups.** The guard rails go in here, before anything depends on them:

- `hard` mounts (never `soft`) with **`x-systemd.automount`**
- containers ordered on the mount unit via **`RequiresMountsFor=`**
- identical mount paths inside every container — this is what preserves hardlink
  imports in [11](11-arr-stack.md)
- a reusable **mount-guard** helper that [13](13-restic-321-service.md) will call

**Blocked by:** 06 (home-server host), 05 (NAS NFS exports).

**Status:** ready-for-agent

- [ ] `nvidia-container-toolkit` working; a CUDA container enumerates the 3060
- [ ] oci-containers backend configured
- [ ] NAS `data` + `photos` exports mounted, `hard` + `x-systemd.automount`
- [ ] UID/permission mapping resolved — a container can read *and write* the export
- [ ] Containers ordered on the mount unit; verified they don't start before it
- [ ] **Hardlink proven across the mount:** `ln` a file from `usenet/complete` into `media/` and confirm the inode matches and no copy occurred
- [ ] Mount-guard helper written and unit-tested against a deliberately unmounted path
- [ ] NVMe headroom checked against the projected load (Immich thumbs + DB + Jellyfin cache + SAB `incomplete/` ~160 GB transient)

_Decision detail: [06](../../issues/06-immich-placement-migration.md), [08](../../issues/08-media-relocation-and-plan-consolidation.md#answer--second-pass-2026-07-26)._
