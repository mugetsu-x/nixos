# NAS media pipeline

Goal: request a film on the phone, have it appear on the projector, correctly
named and with artwork, without ever touching a file.

> **This is the media *execution runbook*.** The whole-home architecture (which
> machine runs what, backups, remote access) lives in
> [`ARCHITECTURE.md`](ARCHITECTURE.md); the decision trail is in
> [`map.md`](map.md) + [`issues/`](issues/). This doc is the build steps.

Status: **planned, nothing executed yet.** Written 2026-07-14. Update 2026-07-22:
the 4 GB RAM stick and the fourth drive have both arrived (not yet installed).
Installing them is now **phase 0**, ahead of the software. **Update 2026-07-26
(laptop-aware):** the wayfinder effort added an always-on ThinkBook
(`home-server`) as the compute host and settled the media decisions against it —
the whole media pipeline **stays on the NAS** (arr for hardlink locality, media
server because playback is same-network / direct-play). Quality is now **4K for
films and TV**, and photos are handled by **Immich on the laptop** (not "a later
project"). Changes are folded into the sections below.

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
- **4K is the default, for films *and* TV** (updated 2026-07-26 — the home theater
  is 4K). This is safe *only* because media is re-downloadable and is excluded from
  backup ([ticket 05](issues/05-backup-topology.md)): the array is a **rotating
  pool, not an archive.** When it fills you **curate/delete first** (it re-downloads
  on demand); disk upgrades are for growing the genuine keep-set, not to avoid
  deleting. Set two Radarr/Sonarr quality profiles to 4K/Ultra-HD. See
  [Growing the pool](#growing-the-pool) for the capacity path.
- **Jellyfin eventually replaces Plex, but not on day one.** Home-only playback
  and no Plex Pass means Plex gives us nothing we would miss, while Jellyfin
  gives free hardware transcoding and no account. But Plex already runs and
  already works, and RAM is scarce — so it stays until phase 2. **Both stay on the
  NAS** (updated 2026-07-26): playback is designed for the **home LAN**, where the
  Shield and capable devices direct-play 4K HEVC, so the server wants to sit next
  to its data. Remote/away-from-home viewing is *best-effort* over Tailscale
  ([04](issues/04-remote-access-method.md)), not a design driver. **Escape hatch:**
  if remote transcode ever becomes routine, the *only* fix is to move Jellyfin onto
  the laptop's RTX 3060 — the GPU is held in reserve for exactly that. The rare
  same-network browser transcode runs on the Celeron QuickSync.
- **The stack runs on the NAS, not the laptop.** Updated 2026-07-26: an always-on
  laptop (`home-server`) now exists, so "must be awake at 03:00" no longer uniquely
  favours the NAS. The load-bearing reason is now **hardlink locality** — Radarr
  imports by hardlinking within the single btrfs share (see
  [The storage layout](#the-storage-layout-and-why-it-matters)); run over NFS from
  the laptop and the arr apps fall back to full copies. The compose file still lives
  in *this repo* and is deployed to the NAS over SSH, so it stays version-controlled.
- **We are not wiping the NAS.** Considered and rejected: btrfs is already in
  place (the only thing a rebuild would have bought), and the photos are the one
  irreplaceable thing on the box. The clean slate we want is media-only, and
  costs nothing to get without a wipe.
- **Photos: decided — Immich on the laptop.** (Updated 2026-07-26; was "a separate
  project.") ~950 GB across `homes`, `Walter` and `Anja` are migrated into **Immich
  running on `home-server`**, with originals kept on the NAS array over NFS and the
  Postgres/thumbnail/ML cache on the laptop's NVMe. Full plan:
  [ticket 06](issues/06-immich-placement-migration.md). It shares the array with
  media but is a distinct workload — not part of this runbook beyond the storage it
  occupies.

### The RAM constraint

DSM itself eats ~700 MB–1 GB, leaving ~1 GB for containers. The full stack wants
closer to 1.5 GB, so it does not fit today — hence the two phases below.

The DS420+ has 2 GB soldered **plus one empty SODIMM slot**. A single 4 GB
DDR4-2666 SODIMM takes it to 6 GB, Synology's official maximum and far more than
this stack needs. Five minutes with a screwdriver; the slot is reachable once the
drive bays are out. **This is the highest-value €20 in the whole plan.** The
stick is now in hand; fitting it is phase 0, step 2, so phase 2 is no longer
blocked on it.

**Do not buy bigger.** The real ceiling is the J4025's memory controller, which
Intel specs at 8 GB total. An 8 GB stick (→ 10 GB) is reported to work but is out
of spec, and this box holds the only copy of the family photos. 6 GB is ample.

**Part chosen (bought, in hand): Timetec DDR4-2666 4 GB non-ECC unbuffered SODIMM** (the Synology
D4NESO-2666-4G equivalent, explicitly lists DS420+ compatibility). Off-brand is
fine — DSM shows a cosmetic *"unsupported memory"* warning in Info Center and
otherwise works normally. Run DSM's memory test after fitting it.

Specs, if the part is ever unavailable: DDR4 **SODIMM** (260-pin), **2666 MHz**
(PC4-21300), non-ECC, unbuffered, 1.2 V. A 3200 stick fits but downclocks to 2666
— no benefit, just buy 2666.

### Growing the pool

One empty bay. A fourth drive expands the array **online** — no downtime, no data
migration.

**Part chosen (bought, in hand): Seagate IronWolf 4 TB, `ST4000VNZ06`** (CMR, NAS-rated, 5400 rpm).

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
~950 GB of irreplaceable photos is what is riding on it. Updated 2026-07-26: this
off-array copy is now the **immediate `restic init` + first snapshot from
`main-pc`** that [ticket 05](issues/05-backup-topology.md) calls for — do that
(it doubles as Immich 06's hard gate), don't invent a one-off copy here.

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

## Phase 0 — fit the hardware (parts are here, nothing installed yet)

Both parts — the 4 GB SODIMM and the IronWolf 4 TB — are physically on hand. This
phase turns them into 6 GB of RAM and a bigger pool *before* any software is
deployed, so phase 1 runs on 6 GB from the start and phase 2 is unblocked.

1. **Back up the photos off the NAS first** — via the restic path in
   [ticket 05](issues/05-backup-topology.md) (`restic init` + first snapshot from
   `main-pc`), not a one-off copy. ~950 GB across `homes`, `Walter` and `Anja`.
   Step 3 expands the array online and it runs *degraded* the whole time — a day or
   more on the Celeron, the most dangerous hour this box will ever have. Do not skip
   this. Btrfs snapshots (phase 1, step 4) are **not** a substitute: they live on
   the same array that is at risk.
2. **Power down and fit both parts in one bay-out session.** The SODIMM slot is
   only reachable with the drive bays out, so do the RAM and the drive together:
   seat the 4 GB stick in the empty slot, and the IronWolf in the empty bay 4.
   Five minutes with a screwdriver.
3. **Power on, verify, then expand.** Run DSM's memory test (Info Center should
   now read ~6 GB; the cosmetic *"unsupported memory"* warning on an off-brand
   stick is expected and harmless). Then add the new drive to the RAID 5 array in
   Storage Manager — an **online** expansion, pool → ~5.4 TB usable. Let it finish
   before starting phase 1.

## Phase 1 — the pipeline

Runs on 6 GB now (it was designed to fit in 2 GB, so nothing here is at risk on
the roomier box — the headroom just lets phase 2 follow immediately).

4. **Snapshots first.** Enable btrfs snapshots on `homes`, `Walter` and `Anja`.
   Minutes of work, near-zero space, and it is the difference between "oops" and
   "the photos are gone." Do this *before* anything else touches the media.
5. **Create the `data` shared folder** with the structure above.
6. **Delete `/volume1/PlexMediaServer/Movies` and `/Shows`** (~470 GB, confirmed
   disposable). Leave `AppData` alone — Plex must keep working. Reclaims ~470 GB.
7. **Sign up for usenet.** Needs a card, so this one is on Walter:
   - Provider: **Eweka** (~€7/mo, good European retention)
   - Indexer: **NZBGeek** (~$20/yr)
8. **Deploy the containers** via Container Manager — compose file lives in
   `nas/` in this repo, deployed over SSH:
   - **SABnzbd** — the downloader
   - **Prowlarr** — manages the indexer, feeds Radarr
   - **Radarr** — the brain: decides what to grab, renames, files it
9. **Repoint Plex** at `/volume1/data/media/movies`. Two clicks in Plex settings.

At the end of phase 1: add a film in Radarr, it downloads, gets named, and shows
up on the projector.

## Phase 2 — the nice front end

RAM is already fitted (phase 0), so this follows straight on from phase 1.

10. **Sonarr** — TV, alongside Radarr.
11. **Jellyseerr** — the phone/web request UI. *This is the "easy" that was
    actually asked for*: search a film, tap Request, done.
12. **Jellyfin** — run it alongside Plex against the same `data/media` folder for
    a couple of weeks. Retire Plex only once the Shield experience is proven.

## Shopping list

| Item | Part | Why |
|---|---|---|
| RAM ✅ in hand | Timetec DDR4-2666 4 GB SODIMM, non-ECC unbuffered | 2 GB → 6 GB. **Fit in phase 0.** |
| Disk ✅ in hand | Seagate IronWolf 4 TB `ST4000VNZ06` (CMR) | Fills bay 4. Pool → ~5.4 TB. Fit in phase 0. |
| Usenet provider | Eweka, ~€7/mo | Needs a card — Walter's to do. |
| Usenet indexer | NZBGeek, ~$20/yr | Needs a card — Walter's to do. |

Nothing in phase 1 can be tested end-to-end until the usenet accounts exist.

## Open items

- Nothing blocking. RAID type resolved (classic RAID 5); both parts bought and on
  hand — installing them is phase 0. The remaining critical-path item is the
  usenet accounts (Eweka + NZBGeek): phase 1 cannot be tested end-to-end until
  they exist, and both need a card.

## Access notes

- NAS hostname: `Alexandria`. SSH as `Walter`, password = the DSM login password.
- SSH is enabled (Control Panel → Terminal & SNMP).
- `sudo` is needed for anything under `/volume1`.
