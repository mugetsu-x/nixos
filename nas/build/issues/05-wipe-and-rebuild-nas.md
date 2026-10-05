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

**Status:** in progress 2026-10-05 (Walter at the DSM UI, agent guiding)

- [x] 01 verified green, **including its freeze box** — copies A and C (B too, if added) exist before a single byte is destroyed — 2026-10-05
- [ ] 4 GB SODIMM + IronWolf 4 TB fitted in one session; DSM memory test passes; Info Center reads ~6 GB — 2026-10-05: SODIMM was already in (5,776 MB visible), IronWolf in bay 4, healthy. **Memory test deferred (Walter's call)** — Synology Assistant's current version has no memory test; substitute is a static `memtester` (`nix build nixpkgs#pkgsStatic.memtester`, copy over `ssh 'cat > ~/memtester'` — no SFTP on DSM), run as `sudo nohup ~/memtester 4000 2 > memtest.log 2>&1 &`. **Must pass before [10](10-import-photos.md) writes the photos to the array.**
- [x] DSM reinstalled clean; **Container Manager and Plex absent** — 2026-10-05, Control Panel → Update & Restore → Reset → Erase All Data; all suggested packages declined. QuickConnect ships as a system package but is switched off
- [ ] Fresh **SHR-1** array across all 4 disks, ~6 TB usable, healthy — 2026-10-05: DSM 7.4.1, SHR (LVM `vg1` over `md2`, RAID 5 on the `p5` partitions of all four disks), btrfs, **5.3 TiB** usable. The IronWolf's other 2 TB sits unused until a second ≥4 TB disk arrives — that's SHR working as designed. Initial resync at 49 % at 20:45, ~2 h to go; tick when Storage Manager says *Healthy*
- [x] Share layout created exactly as above — 2026-10-05; both shares with **data checksum on, recycle bin off**
- [x] NFS exports for `data` + `photos`; UID/squash mapping decided and documented **now**, not debugged later under [09](09-deploy-immich.md) — **decided 2026-10-05: squash = "Map all users to admin"**. Every write lands as DSM's built-in `admin` (UID 1024), which stays *disabled*: no login, Walter remains the only admin human. Containers can run as any UID (Immich as root, the *arr apps as PUID) without permission mismatches; the cost is no per-service ownership on the NAS. Rules per share: one each for home-server's wired `.73` and Wi-Fi `.87` (failover changes the source IP; moved from .74/.88 the same evening once the addresses were bound on the router, see Open), Read/Write, `sys`, non-privileged ports off, mounted subfolders on; **async on for `data`, off for `photos`** (no UPS — don't acknowledge photo writes before they are on disk). The `administrators` group needs R/W on both shares, since `admin` is who NFS writes as. **Verified 2026-10-05 from home-server** (temporary NFSv4.1 `hard` mount in `/tmp`, removed after): writes from root and from UID 65534 both land as `1024:100`; a hardlink `usenet/complete` → `media` shares one inode (link count 2); `photos` writable. `showmount -e` lists exactly the two home-server addresses.
- [x] btrfs snapshots enabled on `photos`; **scheduled data scrub + SMART tests configured** — 2026-10-05, read back from `/usr/syno/etc/synoschedule.d/root/*.task` and `datascrubbing.conf`: `photos` snapshot daily 04:00 (Snapshot Replication; `data` deliberately not snapshotted); SMART quick weekly 02:00 and SMART extended every 3 months from 2026-10-20 08:00, both on all four disks by serial; data scrub every 2 months from 2026-10-05, allowed to run 01:00–17:00
- [x] SSH re-enabled (fresh DSM keeps nothing) — 2026-10-05, port 2288, user home service on, key auth works (`ssh -o BatchMode=yes alexandria`). Walter is UID 1026 in `administrators`. The evacuation's `/etc/sudoers.d/evac` is gone with the old DSM, so `sudo` needs the password again
- [x] Tailscale DSM package installed (see [07](07-tailscale-overlay.md)) — 2026-10-05, `alexandria.tail2c2ea8.ts.net`, key expiry disabled. Also done the same evening: SMART extended moved to start on the 20th so it never shares a day with the scrub (which runs on the 5th); QuickConnect confirmed off
- [ ] ⬜ *Recommended:* small UPS fitted — the durability layer is the only box without power protection

## Open

- ~~**home-server's addresses are not reserved on the router**~~ **Solved
  2026-10-05.** Wired **192.168.0.73** (`00:E0:7C:C9:18:A2`) and Wi-Fi
  **192.168.0.87** (`E4:FD:45:25:A5:C1`) are bound on the A1 ZTE MC888
  (firmware `BD_A1EUMC888BV1.0.0B10`). Three things stood in the way, and the
  last one is the actual fix:
  1. networkd sent a DUID-based DHCP client ID, so the router had no MAC to
     reserve against (and leased a different address than the installer had:
     the .73 → .74 jump). Fixed with `ClientIdentifier = "mac"` in
     `modules/server/networking.nix`. The box went back to .73.
  2. Both links sent the hostname `home-server`, so the router's "Verbundene
     Geräte" list merged them into one entry showing two IPs. Wi-Fi now sends
     `home-server-wifi`.
  3. Even split into two entries, each still showed both IPs. Linux answers
     ARP for any local address on every interface, which is wrong with two
     links on one subnet. Fixed with `arp_ignore=1` / `arp_announce=2`. The
     "Bind IP" button on that page **still** stayed greyed out. What works
     is the separate **MAC-IP-Bindung** page (a manual MAC → IP table, which
     the printer already used), plus a reboot of the device.

  The NFS rules moved to .73/.87 to match.

_Detail: [PLAN.md](../../PLAN.md); [ARCHITECTURE.md](../../ARCHITECTURE.md) → The NAS is rebuilt, not expanded._
