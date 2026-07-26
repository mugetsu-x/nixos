# Build runbook — NAS rebuild + media pipeline

Goal: request a film on the phone, have it appear on the projector — or on the
phone itself, or a browser — correctly named, with artwork, without ever touching
a file. And never lose a photo.

> **This is the *execution runbook*.** The whole-home architecture (which machine
> runs what, backups, remote access) lives in [`ARCHITECTURE.md`](ARCHITECTURE.md);
> the decision trail is in [`map.md`](map.md) + [`issues/`](issues/); the ordered
> execution queue with acceptance criteria is [`build/issues/`](build/issues/).
> This doc is the reference detail behind those tickets.

Status: **planned, nothing executed yet.** Written 2026-07-14.

**Update 2026-07-22:** the 4 GB RAM stick and the fourth drive have both arrived.

**Update 2026-07-26 (laptop-aware):** the wayfinder effort added an always-on
ThinkBook (`home-server`) as the compute host.

**Update 2026-07-26 (second pass — this is the current plan).** Ticket
[08](issues/08-media-relocation-and-plan-consolidation.md) was re-grilled after
both of its load-bearing premises failed:

- *"Hardlinks don't work over NFS"* — **false.** NFS implements `LINK`; the
  hardlink is created server-side on the NAS's btrfs. There was never a technical
  reason to keep the arr stack on the NAS.
- *"The rare browser transcode runs on the Celeron's QuickSync"* — **effectively
  false.** Plex cannot hardware-transcode without a Plex Pass, and the J4025's
  UHD 600 cannot tone-map 4K HDR→SDR in real time. Non-Shield clients did not get
  a slow stream; they got a broken one.

The cascade: **every service moved to the laptop, the NAS became pure storage, and
the array is now wiped and rebuilt rather than expanded live.** Plex is retired,
the offsite copy moved from Hetzner to Google Drive, and the old phase 0/1/2
structure is replaced by the sequence below.

## The hardware

Synology **DS420+** ("Alexandria").

| | |
|---|---|
| CPU | Intel Celeron J4025, 2 cores @ 2 GHz. Has UHD 600 / QuickSync — but see [the transcode reality](#why-quicksync-was-not-enough) |
| RAM | 2 GB soldered + one free SODIMM slot → **6 GB** once the in-hand stick is fitted |
| Storage | 3 × 2 TB, being rebuilt as **SHR-1** with a 4th 4 TB disk → ~6 TB usable |
| Bays | 4, all populated after the rebuild |
| Filesystem | **btrfs** — snapshots, checksums, scrub |
| Docker | Container Manager — **uninstalled during the rebuild.** The NAS runs zero containers |
| Plex | **retired.** Native DSM package removed, `AppData` deleted |

Lenovo **ThinkBook 16p Gen 2** (`home-server`), type 20YM — full spec sheet in
[ticket 01](issues/01-thinkpad-unit-and-always-on.md). Ryzen 9 5900HX (8c/16t),
RTX 3060 Laptop 6 GB, 32 GB DDR4, 1 TB NVMe, Wi-Fi + USB-C→RJ45 dongle.

## Decisions taken (and why)

- **Usenet, not torrents.** ~€7/mo provider + ~$20/yr indexer. Saturates the line,
  no seeding, no ratios, no VPN layer to maintain. *(Untouched by either pass — no
  new fact bore on it.)*
- **Everything runs on the laptop.** The NAS stores bytes and exports NFS. See
  [ARCHITECTURE.md](ARCHITECTURE.md) → Governing principle.
- **4K for films *and* TV**, because the home theater is 4K. Safe only because
  media is re-downloadable and excluded from backup
  ([05](issues/05-backup-topology.md)): the array is a **rotating pool, not an
  archive.** ~6 TB usable minus the photo library leaves roughly **4 TB for media —
  about 60–100 4K titles.** When it fills, curate and delete; it re-downloads on
  demand.
- **Quality profiles must be custom, not stock.** See
  [the Ultra-HD trap](#the-ultra-hd-trap).
- **Jellyfin replaces Plex immediately, not eventually.** The old plan ran them in
  parallel for a proving window. That window doesn't work: Plex's library was going
  to be deleted anyway, so it protected nothing, and without a Pass it could never
  serve the clients that motivated the change. Jellyfin is proven instead against
  **open-licence 4K HDR test files** (Blender's *Tears of Steel*, the standard
  Jellyfish HEVC bitstreams) before a single usenet account exists — which tests
  the hard parts (NFS reads, NVENC tone mapping, Shield direct-play) at the point
  where fixing them is cheap.
- **We *are* wiping the NAS.** Reversed from the first pass. Everything on it
  except the photos is disposable, and the photos come off first regardless — at
  which point the wipe is both safer and strictly better. Reasoning and the SHR
  capacity table: [ARCHITECTURE.md](ARCHITECTURE.md) → *The NAS is rebuilt, not
  expanded*.
- **Photos: Immich on the laptop**, importing from the USB evacuation copy into a
  clean empty library. Full plan: [ticket 06](issues/06-immich-placement-migration.md).

### Why QuickSync was not enough

The DS420+ *does* have QuickSync, which is why the first pass assumed transcoding
was covered. Two things break that:

1. **Plex without a Plex Pass does software transcoding only.** Hardware
   acceleration is a paid feature. On a 2-core Celeron, software-transcoding 4K is
   not slow — it is impossible.
2. **Gemini Lake's UHD 600 cannot tone-map 4K HDR in real time.** Essentially all
   4K sources are HDR; every SDR client (phones, browsers, most TVs) therefore
   needs an HDR→SDR conversion that this iGPU's OpenCL/VPP path cannot sustain.

So the "rare browser transcode" case wasn't rare *and* wasn't handled. The RTX
3060 does NVENC HEVC/H.264 with GPU tone mapping, which is exactly this workload.
It was documented as an escape hatch; it is the design.

### The Ultra-HD trap

Radarr and Sonarr ship a stock **Ultra-HD** quality profile that permits **only**
2160p qualities. Set that on Sonarr and most shows never download at all — 4K TV
is far sparser on usenet than on torrents, so Sonarr sits waiting for releases that
do not exist, silently.

**Both apps get a custom profile: 1080p allowed, 2160p as the upgrade cutoff, with
`Upgrades Allowed` on.** You get 4K where it exists and 1080p where it doesn't,
upgraded automatically later.

### The RAM stick

Still fit it — it is bought, it takes five minutes during the same bay-out session
as the disks, and it becomes btrfs/NFS page cache. But note its **justification has
changed**: it was "the highest-value €20 in the whole plan" when it was what let
the container stack fit in memory. The NAS runs no containers now, so it is a
nice-to-have, not a blocker.

**Do not buy bigger.** The J4025's memory controller is specced at 8 GB total; an
8 GB stick is out of spec, and this box holds the family photos.

**Part (in hand): Timetec DDR4-2666 4 GB non-ECC unbuffered SODIMM.** DSM will show
a cosmetic *"unsupported memory"* warning on an off-brand stick — expected and
harmless. Run DSM's memory test after fitting. Specs if unavailable: DDR4 **SODIMM**
(260-pin), **2666 MHz** (PC4-21300), non-ECC, unbuffered, 1.2 V.

### The disks

**Part (in hand): Seagate IronWolf 4 TB, `ST4000VNZ06`** (CMR, NAS-rated, 5400 rpm).

**Buy CMR, never SMR.** SMR drives overlap their tracks, making the random-write
workload of a RAID rebuild catastrophically slow — days instead of hours, and
drives have been known to drop out of the array mid-rebuild, which is how people
lose everything. **Seagate BarraCuda (e.g. `ST2000DMZ08`) is SMR — rejected.** So
is plain "WD Red" (WD Red *Plus* is CMR). BarraCuda is also a desktop drive: no
error-recovery control (TLER), so a bad sector can stall it long enough for the
array to eject it, and it is not rated for 24/7 or four-bay vibration.

**Why SHR and not classic RAID 5** — the capacity table is in
[ARCHITECTURE.md](ARCHITECTURE.md). Short version: identical usable space today
(6 TB), but under classic RAID 5 the next two disks you buy give you *zero* extra
space, while SHR pays off on every single upgrade.

## The storage layout, and why it matters

```
/volume1/data/                 <- ONE shared folder, ONE NFS export
  media/
    movies/
    tv/
  usenet/
    complete/                  <- SAB's finished output
/volume1/photos/               <- Immich managed library (its own export)
```

On the laptop:

```
/var/lib/sabnzbd/incomplete/   <- local NVMe: par2 + unrar happen here
/mnt/nas/data/                 <- the NFS mount, identical path in every container
```

**Downloads and library must sit in the same shared folder — and in the same NFS
export, mounted at one path, with identical paths inside every container.** Radarr
imports by *hardlinking* from `usenet/complete` into `media/`: instant, zero extra
disk. Across different shares or mismatched container path mappings the hardlink
silently fails and every import becomes a full copy — slow, and it doubles space
used until cleanup.

**Hardlinks work over NFS.** This is worth stating plainly because the first pass
got it wrong and used it to justify a placement decision. NFSv3 and v4 both
implement the `LINK` operation; the link is created server-side on btrfs. The
failure mode people attribute to NFS is really *multiple mounts* or *inconsistent
container paths*.

**`incomplete/` is deliberately not on the NAS.** par2 verification and unrar are
heavy random I/O. Running them on local NVMe keeps that churn off the array, where
it would compete with Immich reads and the nightly restic run, and means the
finished file crosses the LAN exactly once — landing in `complete/`, on the same
filesystem as `media/`, so the hardlink import still works.

## Where the photos actually are

The old inventory said `homes`, `Walter`, `Anja` (~950 GB). Synology Photos stores:

- **personal space** → `/volume1/homes/<user>/Photo` ✅ covered
- **shared space** → **`/volume1/photo`** ❌ **appeared in no ticket**

Also, every Synology Photos folder contains **`@eaDir`** directories full of
DSM-generated thumbnails. These must be **excluded from the Immich import** or you
pull in hundreds of thousands of junk files.

Confirmed disposable: `PlexMediaServer/{Movies,Shows,AppData}` and
`PlexMediaServer/Photos` (Plex artwork, not family pictures). There is no music on
the NAS.

**Inventory `/volume1` (`du -sh /volume1/*`) before deleting anything.** The
backup scope is a **denylist** — everything except confirmed-disposable media —
precisely because an allowlist is how `/volume1/photo` got missed.

## Build sequence

Each step is a ticket in [`build/issues/`](build/issues/) with acceptance criteria.

**Before anything touches the NAS**

1. **Inventory + evacuate.** `du -sh /volume1/*`, then restic repo on USB #1 (that
   repo *is* backup copy #2 later) plus an independent plain-file copy on USB #2,
   both verified. SMART-check both drives first — for the duration of the wipe,
   they *are* your data.
2. **Seed Google Drive** from `main-pc`. ~950 GB at Drive's 750 GB/day cap is ≥2
   days, unattended. **This is what keeps you at three copies during the wipe** —
   otherwise the only copies are two USB drives in one room.
3. **Secrets** (sops-nix) — gates the laptop host.
4. **Usenet accounts** (Eweka + NZBGeek) — needs a card, can run in parallel.

**The NAS**

5. **Wipe and rebuild.** Fit the RAM and the 4th disk in one bay-out session,
   fresh DSM, fresh **SHR-1** array, the share layout above, NFS exports, btrfs
   snapshots + scheduled scrub, Tailscale package. Container Manager and Plex do
   not get reinstalled.

**The laptop**

6. **Stand up `home-server`** as a second flake host.
7. **Tailscale** on both nodes, key expiry disabled.
8. **GPU + NFS foundation** — `nvidia-container-toolkit`, `hard` mounts with
   `x-systemd.automount`, container ordering on the mount unit.
9. **Immich** (oci-containers, CUDA image) — empty library on the right storage.
10. **Import photos** from USB into Immich.
11. **arr stack + SABnzbd**, with the split `incomplete`/`complete` layout.
12. **Jellyfin + Jellyseerr**, proven on test files first.
13. **restic 3-2-1 service** — USB + Google Drive, with a mount guard.
14. **Alerting** — dead-man checks on every timer.

## Shopping list

| Item | Part | Why |
|---|---|---|
| RAM ✅ in hand | Timetec DDR4-2666 4 GB SODIMM | 2 → 6 GB. Now optional; fit it anyway |
| Disk ✅ in hand | Seagate IronWolf 4 TB `ST4000VNZ06` (CMR) | 4th bay. Pool → ~6 TB SHR-1 |
| USB HDDs ✅ in hand | 2 × ≥2 TB, wipeable | Evacuation pair; one becomes backup copy #2 |
| Usenet provider | Eweka, ~€7/mo | Needs a card |
| Usenet indexer | NZBGeek, ~$20/yr | Needs a card |
| **UPS for the NAS** ⬜ | small line-interactive | The durability layer is the one without power protection |
| ~~Hetzner Storage Box~~ | — | **Dropped** — Google Drive (Business Plus, 5 TB) is already paid |

## Open items

- **Confirm the second M.2 slot** on the ThinkBook is free. The 1 TB NVMe now
  carries Immich thumbnails, Postgres, Jellyfin cache *and* SAB `incomplete/`
  (up to ~160 GB transient for a 4K release). It fits, but it is the tightest
  resource on the box.
- **Verify Google Vault's Drive retention behaviour** before relying on it as the
  immutability backstop.
- **ThinkBook battery charge threshold** — this is a *ThinkPad* feature
  (`thinkpad_acpi`). ThinkBooks generally are not covered by it; check BIOS or
  `ideapad_laptop`'s `conservation_mode` before assuming a 24/7 charge cap is
  available at all.
- **Measure real idle draw.** ~20 W assumes the dGPU is genuinely parked; with the
  nvidia driver loaded and the container toolkit ready, expect 25–40 W (≈€90–125/yr
  at €0.355/kWh).

## Access notes

- NAS hostname: `Alexandria`. SSH as `Walter`, password = the DSM login password.
- SSH is enabled (Control Panel → Terminal & SNMP). `sudo` for anything under
  `/volume1`.
- After the rebuild, DSM is a fresh install — SSH must be re-enabled and the NFS
  exports recreated. Do not assume any current DSM setting survives.
