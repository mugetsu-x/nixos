# NAS media pipeline

Goal: request a film on the phone, have it appear on the projector, correctly
named and with artwork, without ever touching a file.

Status: **planned, nothing executed yet.** Written 2026-07-14.

## The hardware we are building on

Synology **DS420+** ("Alexandria"), DSM 7.3.2-86009 Update 4.

| | |
|---|---|
| CPU | Intel Celeron J4025, 2 cores @ 2 GHz — has UHD 600, so **QuickSync** is available for hardware transcoding |
| RAM | **2 GB** — the binding constraint. See [RAM](#the-ram-constraint) |
| Storage | 3 × disks in **RAID 5**, 3.5 TB usable, 1.4 TB used, 2.1 TB free |
| Bays | **3 populated, 1 empty** — room to expand online |
| RAID | **Classic RAID 5** (confirmed in Storage Manager — *not* SHR), 3 × 2 TB |
| Filesystem | **btrfs** (confirmed) — snapshots are available, no reason to rebuild the NAS |
| Docker | **Container Manager 24.0.2 installed** |
| Plex | 1.41.5, installed as a **native DSM package**, not a container |

Playback is home-only: projector via an **NVIDIA Shield** (Google TV). No remote
streaming, no Plex Pass. The Shield direct-plays essentially everything, so
transcoding will rarely fire regardless of what server we run.

## Decisions taken (and why)

- **Usenet, not torrents.** ~€7/mo provider + ~$20/yr indexer. Saturates the
  line, no seeding, no ratios, no VPN layer to maintain.
- **1080p is the default; 4K is a per-film exception.** 2.1 TB free is ~40 films
  at 4K but 200+ at 1080p. Not a one-way door — see [Growing the pool](#growing-the-pool).
- **Jellyfin eventually replaces Plex, but not on day one.** Home-only playback
  and no Plex Pass means Plex gives us nothing we would miss, while Jellyfin
  gives free hardware transcoding and no account. But Plex already runs and
  already works, and RAM is scarce — so it stays until phase 2.
- **The stack runs on the NAS, not the NixOS box.** Radarr grabbing a release at
  03:00 only works on a machine that is awake. The compose file still lives in
  *this repo* and is deployed to the NAS over SSH, so it stays version-controlled.
- **We are not wiping the NAS.** Considered and rejected: btrfs is already in
  place (the only thing a rebuild would have bought), and the photos are the one
  irreplaceable thing on the box. The clean slate we want is media-only, and
  costs nothing to get without a wipe.
- **Photos are a separate project.** ~950 GB across `homes`, `Walter` and `Anja`.
  Organising them (Immich is the likely answer) comes *after* this. Not scoped here.

### The RAM constraint

DSM itself eats ~700 MB–1 GB, leaving ~1 GB for containers. The full stack wants
closer to 1.5 GB, so it does not fit today — hence the two phases below.

The DS420+ has 2 GB soldered **plus one empty SODIMM slot**. A single 4 GB
DDR4-2666 SODIMM takes it to 6 GB, Synology's official maximum and far more than
this stack needs. Five minutes with a screwdriver; the slot is reachable once the
drive bays are out. **This is the highest-value €20 in the whole plan** and phase
2 is blocked on it.

**Do not buy bigger.** The real ceiling is the J4025's memory controller, which
Intel specs at 8 GB total. An 8 GB stick (→ 10 GB) is reported to work but is out
of spec, and this box holds the only copy of the family photos. 6 GB is ample.

**Part chosen: Timetec DDR4-2666 4 GB non-ECC unbuffered SODIMM** (the Synology
D4NESO-2666-4G equivalent, explicitly lists DS420+ compatibility). Off-brand is
fine — DSM shows a cosmetic *"unsupported memory"* warning in Info Center and
otherwise works normally. Run DSM's memory test after fitting it.

Specs, if the part is ever unavailable: DDR4 **SODIMM** (260-pin), **2666 MHz**
(PC4-21300), non-ECC, unbuffered, 1.2 V. A 3200 stick fits but downclocks to 2666
— no benefit, just buy 2666.

### Growing the pool

One empty bay. A fourth drive expands the array **online** — no downtime, no data
migration.

**Part chosen: Seagate IronWolf 4 TB, `ST4000VNZ06`** (CMR, NAS-rated, 5400 rpm).

**Buy CMR, never SMR.** This is the trap. SMR drives overlap their tracks, which
makes the random-write workload of a RAID rebuild catastrophically slow — days
instead of hours, and drives have been known to drop out of the array mid-rebuild,
which is how people lose everything. **Seagate BarraCuda (e.g. ST2000DMZ08) is SMR
— rejected.** So is plain "WD Red" (WD Red *Plus* is CMR). BarraCuda is also a
desktop drive: no error-recovery control (TLER), so a bad sector can stall it long
enough for the array to eject it, and it is not rated for 24/7 or for four-bay
vibration. High RPM and big cache on a desktop drive do not compensate for any of
this.

**Why 4 TB on a classic RAID 5 array.** RAID 5 clamps every member to the smallest
disk, so a 4 TB fourth disk yields only 2 TB usable today (pool → ~5.4 TB). At the
time of buying, 2 TB and 4 TB IronWolfs cost the same, so the extra capacity is
free optionality: classic RAID 5 supports **expansion by replacement** — swap each
2 TB disk for a 4 TB one, letting the array rebuild between each, and once all four
are 4 TB the pool expands to ~10.9 TB. The drive bought today is the first of four,
not a wasted purchase.

**Before any expansion or disk replacement: back the photos up off the NAS.** The
rebuild runs online but takes a day or more on the Celeron, and the array is
degraded throughout. It is the most dangerous hour this box will ever have, and
~950 GB of irreplaceable photos is what is riding on it.

## The storage layout, and why it matters

Today the media lives *inside Plex's own application share* —
`/volume1/PlexMediaServer/` holds `AppData` (the Plex database) alongside
`Movies`, `Shows`, `Music`, `Photos`. Plex literally ships warning files in six
languages telling you not to do this. It is ~471 GB and it is all disposable.

The target:

```
/volume1/data/                 <- ONE shared folder
  media/
    movies/
    tv/
  usenet/
    incomplete/
    complete/
```

**Downloads and library must sit in the same shared folder.** Radarr imports by
*hardlinking* from `usenet/complete` into `media/`: instant, and it costs zero
extra disk. Across different shared folders the hardlink silently fails and every
import becomes a full copy — slow, and it doubles the space used until cleanup.
On 2.5 TB free that hurts. This is the single decision that is expensive to undo,
which is why it is settled before anything is deployed.

Moving folders *within* `/volume1` is an instant rename, not a copy, because it
is all one btrfs volume. Restructuring is therefore free.

## Phase 1 — the pipeline (buildable today, on 2 GB)

1. **Snapshots first.** Enable btrfs snapshots on `homes`, `Walter` and `Anja`.
   Minutes of work, near-zero space, and it is the difference between "oops" and
   "the photos are gone." Do this *before* anything else touches the NAS.
2. **Create the `data` shared folder** with the structure above.
3. **Delete `/volume1/PlexMediaServer/Movies` and `/Shows`** (~470 GB, confirmed
   disposable). Leave `AppData` alone — Plex must keep working. Frees the pool to
   ~2.5 TB.
4. **Sign up for usenet.** Needs a card, so this one is on Walter:
   - Provider: **Eweka** (~€7/mo, good European retention)
   - Indexer: **NZBGeek** (~$20/yr)
5. **Deploy the containers** via Container Manager — compose file lives in
   `nas/` in this repo, deployed over SSH:
   - **SABnzbd** — the downloader
   - **Prowlarr** — manages the indexer, feeds Radarr
   - **Radarr** — the brain: decides what to grab, renames, files it
6. **Repoint Plex** at `/volume1/data/media/movies`. Two clicks in Plex settings.

At the end of phase 1: add a film in Radarr, it downloads, gets named, and shows
up on the projector.

## Phase 2 — the nice front end (blocked on the 4 GB stick)

7. **Fit the RAM.** 2 GB → 6 GB.
8. **Sonarr** — TV, alongside Radarr.
9. **Jellyseerr** — the phone/web request UI. *This is the "easy" that was
   actually asked for*: search a film, tap Request, done.
10. **Jellyfin** — run it alongside Plex against the same `data/media` folder for
    a couple of weeks. Retire Plex only once the Shield experience is proven.

## Shopping list

| Item | Part | Why |
|---|---|---|
| RAM | Timetec DDR4-2666 4 GB SODIMM, non-ECC unbuffered | 2 GB → 6 GB. **Unblocks phase 2.** |
| Disk | Seagate IronWolf 4 TB `ST4000VNZ06` (CMR) | Fills bay 4. Pool → ~5.4 TB. |
| Usenet provider | Eweka, ~€7/mo | Needs a card — Walter's to do. |
| Usenet indexer | NZBGeek, ~$20/yr | Needs a card — Walter's to do. |

Nothing in phase 1 can be tested end-to-end until the usenet accounts exist.

## Open items

- Nothing blocking. RAID type resolved (classic RAID 5), parts chosen.

## Access notes

- NAS hostname: `Alexandria`. SSH as `Walter`, password = the DSM login password.
- SSH is enabled (Control Panel → Terminal & SNMP).
- `sudo` is needed for anything under `/volume1`.
