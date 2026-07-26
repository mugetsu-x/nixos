# 05 — Wipe and rebuild the NAS as pure SHR-1 storage

**What to build:** Alexandria rebuilt from scratch as a **storage-only** box: fresh
DSM, fresh **SHR-1** array across all four disks (~6 TB usable), the clean share
layout, NFS exports, btrfs snapshots + scheduled scrub, and the Tailscale package.
**Container Manager and Plex are not reinstalled.**

**⚠️ This step is destructive and irreversible.** Do not start it until
[01](01-inventory-and-evacuate.md) *and* [02](02-seed-google-drive-offsite.md) are
both green — two verified USB copies **and** the offsite seed. Not one of the three.

**Why a wipe rather than the original online expansion:** the old plan added the 4 TB
disk to the live RAID 5, an **online reshape running degraded for a day or more** on
a Celeron with the only primary copy of the photos on it — the single most dangerous
operation in the whole plan. Once the photos are off, a fresh array is both safer
(nothing at risk on it) and strictly better: **DSM cannot convert classic RAID 5 to
SHR**, and SHR is the only layout where the next disk you buy actually gains you
space. Full reasoning + capacity table: [ARCHITECTURE.md](../../ARCHITECTURE.md).

**One bay-out session:** the SODIMM slot is only reachable with the drive bays out,
so fit the 4 GB stick and the IronWolf together. Note the RAM's justification has
changed — it was bought to make the container stack fit, and the NAS runs no
containers now. Fit it anyway; it becomes btrfs/NFS page cache.

**Target layout:**

```
/volume1/data/          <- ONE share, ONE NFS export
  media/{movies,tv}
  usenet/complete/
/volume1/photos/        <- Immich managed library, its own export
```

`usenet/complete` and `media/` **must** be in the same share and the same export —
that is what lets Radarr hardlink-import instead of full-copying. (Hardlinks work
fine over NFS; what breaks them is separate mounts or mismatched container paths.)

**Blocked by:** 01 (evacuation) **and** 02 (offsite seed). Hard gate, both.

**Status:** ready-for-agent

- [ ] Both prerequisites verified green — three copies exist before a single byte is destroyed
- [ ] 4 GB SODIMM + IronWolf 4 TB fitted in one session; DSM memory test passes; Info Center reads ~6 GB
- [ ] DSM reinstalled clean; **Container Manager and Plex absent**
- [ ] Fresh **SHR-1** array across all 4 disks, ~6 TB usable, healthy
- [ ] Share layout created exactly as above
- [ ] NFS exports for `data` + `photos`; UID/squash mapping decided and documented **now**, not debugged later under [09](09-deploy-immich.md)
- [ ] btrfs snapshots enabled on `photos`; **scheduled data scrub + SMART tests configured**
- [ ] SSH re-enabled (fresh DSM keeps nothing)
- [ ] Tailscale DSM package installed (see [07](07-tailscale-overlay.md))
- [ ] ⬜ *Recommended:* small UPS fitted — the durability layer is the only box without power protection

_Detail: [PLAN.md](../../PLAN.md); [ARCHITECTURE.md](../../ARCHITECTURE.md) → The NAS is rebuilt, not expanded._
