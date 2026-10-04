# 13 — restic 3-2-1 backup service on `home-server`

**What to build:** The ongoing backup service via `services.restic.backups` on
`home-server`: a maintained 3-2-1 that takes over from
[01](01-inventory-and-evacuate.md)/[02](02-seed-google-drive-offsite.md)'s one-off
evacuation archives. Both repos are **initialised fresh** here — the evacuation was
zip archives, not restic (revised 2026-10-04).

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
- **Media → excluded.** Re-downloadable; the array is a rotating pool.
- **Laptop app-state → lighter tier, and it is now the *whole* application layer:**
  Immich Postgres, Jellyfin metadata + watch history + users, and the arr databases
  (quality profiles, indexer config, monitored series). None of it rebuilds from the
  flake. **`pg_dump` first, then restic the dump** — never file-snapshot a live DB.
  *(The first-pass plan had these apps on the NAS, where they fell into no tier at
  all. The relocation fixed that by accident; make it deliberate here.)*

**⚠️ The mount guard is not optional.** All bulk data sits behind one NFS mount. If
restic runs against an *unmounted* mountpoint it writes a near-empty snapshot, and
`forget --prune` then ages out the real history on schedule. **That is how people
delete their own backups.** Use the guard from [08](08-gpu-nfs-foundation.md): verify
the mount is live, **abort loudly** otherwise.

**Which USB HDD:** copy #2 needs a disk of its own on the ThinkBook. If it's one
of 01's evacuation disks, reformat it **only after** both repos below have passed a
restore drill — until then the archives on it are still a copy.

Retention 7d/8w/12m/5y; **prune weekly as a separate, deliberate, logged operation**
— it is the one dangerous space-reclaiming step.

**Blocked by:** 09 (Immich — the library + DB to back up), 06, 03.

**Status:** ready-for-agent

- [ ] Nightly restic to both repos from `services.restic.backups`; DBs `pg_dump`'d first
- [ ] **Mount guard proven:** unmount the NFS share, run the job, confirm it aborts instead of snapshotting an empty tree
- [ ] Own OAuth client ID; Drive repo initialised with `--pack-size 64`
- [ ] Retention 7d/8w/12m/5y configured; weekly prune as a separate logged unit
- [ ] Photos full 3-2-1; media excluded; Immich/Jellyfin/arr state in the lighter tier
- [ ] **Hard retention ceiling + Workspace pool alert** — the repo must never grow into the quota that runs Gmail
- [ ] Monthly `restic check --read-data-subset=5%` + sample restore with hash comparison, on **both** repos
- [ ] One real offsite drill completed from Drive to a clean machine
- [ ] **Only then:** 01/02's evacuation archives retired — deleted from Drive, USB disk reformatted if reused
- [ ] Keys stored off the laptop (password manager + printed)

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--second-pass-2026-07-26)._
