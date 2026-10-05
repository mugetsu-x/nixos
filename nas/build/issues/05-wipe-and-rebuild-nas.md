# 05 — Wipe and rebuild the NAS as pure SHR-1 storage

**What to build:** Alexandria rebuilt from scratch as a **storage-only** box: fresh
DSM, fresh **SHR-1** array across all four disks (~6 TB usable), the clean share
layout, NFS exports, btrfs snapshots + scheduled scrub, and the Tailscale package.
**Container Manager and Plex are not reinstalled.**

**⚠️ This step is destructive and irreversible.** Do not start it until
[01](01-inventory-and-evacuate.md) is green — copy A (USB HDD) and copy C
(`main-pc`) both verified against the NAS manifest — **and 01's freeze + final
delta has verified green.** The offsite copy ([02](02-seed-google-drive-offsite.md))
was deferred on 2026-10-04: during the wipe window both copies sit in one house,
an accepted risk. Keep the WD unplugged and in another room once verified.

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

**Blocked by:** 01 (evacuation). Hard gate. (02 deferred — not a gate.)

**Status:** ready-for-agent

- [x] 01 verified green, **including its freeze box** — copies A and C (B too, if added) exist before a single byte is destroyed — 2026-10-05
- [ ] 4 GB SODIMM + IronWolf 4 TB fitted in one session; DSM memory test passes; Info Center reads ~6 GB — 2026-10-05: SODIMM was already in (5,776 MB visible), IronWolf in bay 4, healthy. **Memory test deferred (Walter's call)** — Synology Assistant's current version has no memory test; substitute is a static `memtester` (`nix build nixpkgs#pkgsStatic.memtester`, copy over `ssh 'cat > ~/memtester'` — no SFTP on DSM), run as `sudo nohup ~/memtester 4000 2 > memtest.log 2>&1 &`. **Must pass before [10](10-import-photos.md) writes the photos to the array.**
- [ ] DSM reinstalled clean; **Container Manager and Plex absent**
- [ ] Fresh **SHR-1** array across all 4 disks, ~6 TB usable, healthy
- [ ] Share layout created exactly as above
- [ ] NFS exports for `data` + `photos`; UID/squash mapping decided and documented **now**, not debugged later under [09](09-deploy-immich.md)
- [ ] btrfs snapshots enabled on `photos`; **scheduled data scrub + SMART tests configured**
- [ ] SSH re-enabled (fresh DSM keeps nothing)
- [ ] Tailscale DSM package installed (see [07](07-tailscale-overlay.md))
- [ ] ⬜ *Recommended:* small UPS fitted — the durability layer is the only box without power protection

_Detail: [PLAN.md](../../PLAN.md); [ARCHITECTURE.md](../../ARCHITECTURE.md) → The NAS is rebuilt, not expanded._
