# 13 — restic 3-2-1 backup service on `home-server`

**What to build:** The ongoing backup service via `services.restic.backups` on
`home-server`: a maintained 3-2-1 that takes over from
[01](01-inventory-and-evacuate.md)/[02](02-seed-google-drive-offsite.md)'s one-off
evacuation copies. Both repos are **initialised fresh** here — the evacuation was
a one-off rsync, not restic (revised 2026-10-04).

| Copy | Where | How |
|---|---|---|
| #1 | NAS array | the live Immich managed library |
| #2 | **USB HDD on the ThinkBook** | nightly **pull** from the NAS — fresh repo |
| #3 | **Google Drive** | via rclone, client-side encrypted — fresh repo |

**Google Drive replaces Hetzner** (~€143/yr saved). Ticket 05's original comparison
weighed Hetzner against B2 and disk rotation but **never considered storage already
owned**. Mandatory config, all of it:

- **Your own OAuth client ID** for rclone. The shared default is rate-limited into
  uselessness.
- **`--pack-size 64`** (restic default is 16 MiB). Cuts object count ~4×, which is
  what makes `check` and `prune` tolerable against Drive's paginated, rate-limited
  API.
- **Drive proper, not Google Photos.**
- First run is ~950 GB against Drive's **750 GB/day** cap — expect ≥2 days.

**Scope, tiered:**

- **Photos → full 3-2-1.** The crown jewels. This includes Immich's `backups/`
  folder of nightly DB dumps, which [09](09-deploy-immich.md) puts on the NAS.
- **Documents → full 3-2-1, same as photos.** Paperless ([15](15-paperless-ngx.md)):
  the `documents` share (`/documents`, guard it like `/photos`) plus its DB, which
  is **only** on the NVMe. `services.postgresqlBackup` already dumps it nightly
  to `/var/backup/postgresql/paperless.sql.gz`. Back up that dump and
  `/var/lib/paperless` (search index, secret key), never `/var/lib/postgresql`.
- **Media → excluded.** Re-downloadable; the array is a rotating pool.
- **Laptop app-state → lighter tier, and it is now the *whole* application layer:**
  Immich Postgres, Jellyfin metadata + watch history + users, and the arr databases
  (quality profiles, indexer config, monitored series), and the Enshrouded world
  (`/var/lib/enshrouded/savegame`; the server already zips it to `backups/`
  every 30 min). None of it rebuilds from the flake. **`pg_dump` first, then restic the dump** — never file-snapshot a live DB.
  *(The first-pass plan had these apps on the NAS, where they fell into no tier at
  all. The relocation fixed that by accident; make it deliberate here.)*

**⚠️ The mount guard is not optional.** All bulk data sits behind one NFS mount. If
restic runs against an *unmounted* mountpoint it writes a near-empty snapshot, and
`forget --prune` then ages out the real history on schedule. **That is how people
delete their own backups.** Use the guard from [08](08-gpu-nfs-foundation.md): verify
the mount is live, **abort loudly** otherwise.

**Which USB HDD:** copy #2 needs a disk of its own on the ThinkBook. If it's one
of 01's evacuation disks, reformat it **only after** both repos below have passed a
restore drill — until then the evacuation tree on it is still a copy.

Retention 7d/8w/12m/5y; **prune weekly as a separate, deliberate, logged operation**
— it is the one dangerous space-reclaiming step.

**Blocked by:** 09 (Immich — the library + DB to back up), 06, 03.

**Status:** ready-for-agent. **Scoped 2026-10-07 (Walter):** USB leg now, Drive
leg waits for the Google account decision (see TODO.md "offsite copy").

**Before A is wiped (found 2026-10-07):** ~100 GB of the evacuation is not photos
and was never restored. [10](10-import-photos.md) imported photos only, so
`Anja/{01_Ausbildung,06_Freizeitstuff,07_Rezepte,08_Dokumente}`, the rest of
`Walter`, and `docker/alexandria/books` exist **only on A and C**. Copy B was never
made. Order: restore those from C into a new NAS share `files` (one folder per
person, `files/walter` + `files/anja`, so [20](20-file-sync.md) can adopt it),
verify against 01's manifests, add `files` to the restic scope, **then** wipe A
for the repo. C stays until an offsite copy exists.

- [ ] Nightly restic to both repos from `services.restic.backups`; DBs `pg_dump`'d first
- [ ] **Mount guard proven:** unmount the NFS share, run the job, confirm it aborts instead of snapshotting an empty tree
- [ ] Own OAuth client ID; Drive repo initialised with `--pack-size 64`
- [ ] Retention 7d/8w/12m/5y configured; weekly prune as a separate logged unit
- [ ] Photos full 3-2-1; media excluded; Immich/Jellyfin/arr state in the lighter tier
- [ ] **Hard retention ceiling + Workspace pool alert** — the repo must never grow into the quota that runs Gmail
- [ ] Monthly `restic check --read-data-subset=5%` + sample restore with hash comparison, on **both** repos
- [ ] One real offsite drill completed from Drive to a clean machine
- [ ] **Only then:** 01/02's evacuation copies retired — `gdrive:evac-2026-10` deleted, `~/evac/` on `main-pc` deleted, USB disk reformatted if reused
- [ ] Keys stored off the laptop (password manager + printed)

## Interim offsite: rotated SSD

**Agreed 2026-11-04 (Walter).** Until the Drive leg exists there is no offsite
copy. A spare **1 TB SATA SSD** on a USB adapter fills the gap. It is kept at
**another address**, not in another room: fire, theft and surges reach the next
room too. Ticket 05 rejected disk rotation as the *primary* offsite because it
depends on discipline. As a stopgap it beats having no copy at all, and it stays
in place alongside Drive later if Walter wants.

- **Size:** today's set is ~510 GB (`/photos/library` 407 GB, `files` ~100 GB,
  `/documents`, dumps, `/var/lib` state). Photos are append-only and restic
  dedups, so history is cheap. Watch the fill level once Anja's phone backs up
  too.
- **Its own restic repo, pulled from the source.** It is a second
  `services.restic.backups` target, never a copy of disk A's repo. Same rule as
  01: copies are independent, so one bad read can't land in both. It uses the
  same mount guard on the source, plus a guard that the SSD itself is mounted.
- **One action per swap:** plug into home-server → one unit runs backup +
  `restic check --read-data-subset` + a small sample restore → notification
  (14) → unplug and take it back. A fixed **monthly** date.
- **SSD, not HDD:** an unpowered consumer SSD slowly loses data. The monthly
  swap powers it up regularly. Don't let it sit unplugged for many months.
- **Encrypted by restic**, so leaving it at someone else's place is fine.
  Restoring needs the repo password, which is in the password manager and on paper.

- [ ] USB 3 → 2.5" SATA adapter bought (bus-powered, UASP, ASMedia ASM1153E/ASM235CM)
- [ ] SSD SMART-checked (`smartctl -a`: power-on hours, wear, reallocated/pending, CRC errors)
- [ ] Repo initialised; swap-in unit runs backup + check + sample restore, notifies, aborts if source or SSD isn't mounted
- [ ] First full backup + restore drill done, SSD moved to its offsite address
- [ ] Monthly swap date set
- [ ] **Then** decide whether this counts as the offsite copy that lets C (`~/evac` on main-pc) go

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--second-pass-2026-07-26)._
