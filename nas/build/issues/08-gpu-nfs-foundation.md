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

**Status:** done 2026-10-05 (one item open: NVMe headroom is measured only when 09/11/12 land). Code: `modules/server/storage.nix` (mounts, podman, toolkit, `nas-mount-guard`). Mounts: `/data` and `/photos`, NFSv4.1 from the NAS LAN address 192.168.0.70 (not the tailnet name), identical paths in every container. A service orders itself with `unitConfig.RequiresMountsFor = [ "/data" ];`. restic (13) calls `nas-mount-guard /data /photos` first; it exits non-zero unless each path is a live nfs4 mount from the NAS.

- [x] `nvidia-container-toolkit` working — `podman run --device nvidia.com/gpu=all ubuntu nvidia-smi -L` lists the RTX 3060; a CUDA container enumerates the 3060
- [x] oci-containers (podman) backend configured
- [x] NAS `data` + `photos` exports mounted, `hard` + `x-systemd.automount`
- [x] UID/permission — writes land as 1024:100 via root and via container mapping resolved — a container can read *and write* the export
- [x] Containers ordered — a unit with RequiresMountsFor pulled the stopped mount up before running on the mount unit; verified they don't start before it
- [x] **Hardlink proven across the mount:** `ln` a file from `usenet/complete` into `media/` and confirm the inode matches and no copy occurred
- [x] Mount-guard — passes on live mounts, fails on an unmounted /data, a local dir and a missing path helper written and unit-tested against a deliberately unmounted path
- [ ] NVMe headroom checked against the projected load (Immich thumbs + DB + Jellyfin cache + SAB `incomplete/` ~160 GB transient)

_Decision detail: [06](../../issues/06-immich-placement-migration.md), [08](../../issues/08-media-relocation-and-plan-consolidation.md#answer--second-pass-2026-07-26)._
