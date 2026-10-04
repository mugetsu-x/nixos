# 01 — Inventory `/volume1` and evacuate it to two USB HDDs

**What to build:** Two independent, verified copies of every irreplaceable file on
the NAS, living **off** the NAS, before anything is deleted or rebuilt. This is the
hard gate for the entire plan — [05](05-wipe-and-rebuild-nas.md) destroys the array.

> **Revised 2026-10-04.** The evacuation now runs from the **Windows machine with
> TeraCopy** and lands as **zip archives** on both USB HDDs (and on Drive, see
> [02](02-seed-google-drive-offsite.md)). This replaces the restic-from-`main-pc`
> approach. Consequence: the evacuation is a **one-off archive**, not the start of
> the ongoing restic lineage — [13](13-restic-321-service.md) initialises fresh
> repos, so the old `--host`/mount-path pinning concern no longer exists.

**Inventory first.** Run `du -sh /volume1/*` over SSH (or read sizes in File
Station) and write the result down. The scope is a **denylist, not an allowlist**:
take *everything* except confirmed-disposable media. An enumerated allowlist is
exactly how `/volume1/photo` came to be missing from every ticket in this repo.

- Synology Photos **personal** space → `homes/<user>/Photo` — over SMB, an admin
  sees every user's folder inside the `homes` share. **Anja's must be in it.**
- Synology Photos **shared** space → **`photo`** share ← the one that was missed
- Confirmed disposable: `PlexMediaServer/*` (including `Photos`, which is artwork).
  There is no music on the NAS.
- Look inside `#recycle` before skipping it — deleted-by-accident photos live there.

**The flow:**

1. **Copy** NAS → staging with TeraCopy, **"Verify after transfer" on**, and save
   TeraCopy's checksum file next to the copy. If `@eaDir` folders show up over SMB,
   drop them from the staging copy (they are DSM thumbnails — hundreds of
   thousands of junk files that would also slow every later step).
2. **Zip with 7-Zip, not Explorer's "Send to → Compressed folder".** Explorer's zip
   has historically written filenames in the legacy OEM code page without the
   UTF-8 flag, which turns `Mädchen_Strand.jpg` into mojibake when extracted on
   Linux. 7-Zip sets the flag. Use **store mode** (`-mx0`) — JPEG/HEIC/MP4 don't
   compress, so compression only costs time.
3. **One archive per import source** (`photo`, `homes/Walter/Photo`,
   `homes/Anja/Photo`, `Walter`, `Anja`, …), split further by year if one is huge.
   This keeps a corrupt archive from costing everything, lets Drive uploads resume
   per file, and lines the archives up with [10](10-import-photos.md)'s
   source → account mapping.
4. **Test and hash.** `7z t` every archive, then write a manifest with **SHA-256
   *and* MD5** of each (`Get-FileHash -Algorithm SHA256` / `MD5`). MD5 is there
   because it's the hash Google Drive reports, so [02](02-seed-google-drive-offsite.md)
   can be verified against the same manifest.
5. **Copy archives + manifest to HDD A and HDD B**, re-hash on each disk, compare.
6. **Prove it on Linux before you rely on it:** extract one archive on `main-pc`
   and check that umlaut filenames are intact and file dates look right. This is
   the one check that catches the encoding problem while it is still free to fix.

**Disk space.** Staging ~950 GB *and* writing zips beside it needs ~2 TB on the
Windows machine. If it doesn't have that (the ThinkBook's 1 TB NVMe doesn't), stage
straight onto HDD A and zip from there.

**What a file copy cannot carry.** Synology Photos keeps **albums, person names and
shared links in its database**, not in the files. They will not survive the move.
Before the wipe, list (or screenshot) the albums worth recreating in Immich — or
decide explicitly to let them go.

**Blocked by:** None — start here.

**Status:** ready-for-agent

- [ ] `du -sh /volume1/*` inventory recorded; every non-disposable path identified, including `photo`, every user under `homes`, and a look at `#recycle`
- [ ] **SMART check passes on both USB HDDs** — for the duration of the wipe they *are* the data
- [ ] TeraCopy copy with verify on; checksum file saved; `@eaDir` dropped
- [ ] Archives made with **7-Zip**, store mode, one per import source
- [ ] `7z t` passes on every archive; SHA-256 + MD5 manifest written
- [ ] Archives + manifest on **HDD A and HDD B**, re-hashed on each disk and matching
- [ ] One archive extracted on `main-pc`: umlauts intact, dates sane
- [ ] File count per source in the archives matches the count on the NAS (not just total size)
- [ ] Synology Photos albums worth keeping listed — or explicitly let go
- [ ] Archive password (if any, see [02](02-seed-google-drive-offsite.md)) stored off the NAS *and* off both laptops (password manager + printed)

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--third-pass-2026-10-04)._
