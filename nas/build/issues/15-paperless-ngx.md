# 15 — Paperless-ngx (document archive)

**What to build:** [Paperless-ngx](https://docs.paperless-ngx.com) on `home-server`.
It's a scan/upload → OCR → full-text-searchable archive for letters, invoices,
contracts and payslips, so the paper stack and the `08_Dokumente`-style folders
become one searchable place.

Added 2026-10-06 as a wish (Walter); **not grilled yet**. Run `grill-me` on the
open questions before building.

**Shape (proposal):**
- Same pattern as Immich: **originals on the NAS, database + OCR working files
  on NVMe**. Postgres (or SQLite, see below) under `/var/lib`, never on NFS.
- nixpkgs has a native `services.paperless` module. Unlike Immich, nothing here
  needs CUDA, so the module may beat `oci-containers`. Check what it can and can't
  express (media dir on NFS, consume dir) before choosing.
- OCR languages **`deu+eng`**. Austrian paperwork is German.

**Things that will bite:**
- **Set `PAPERLESS_FILENAME_FORMAT` before the first document.** Otherwise the
  archive on disk is `0000001.pdf…`, unreadable without Paperless. This is the
  Immich storage-template lesson again. Changing it later renames everything.
- **inotify does not work on NFS.** If the consume folder lives on the NAS, set
  `PAPERLESS_CONSUMER_POLLING`, or keep the consume dir local.
- Paperless stores the original *and* an OCR'd archive PDF, so the library is
  about double the size of the input. Disk is plentiful, but 13's repos grow with it.

**Open questions:**
- How do documents get in? Phone scanner app, a network scanner writing to an
  SMB/NFS consume share, mail fetching (`PAPERLESS_CONSUMER_*` / mail rules), or
  just drag-and-drop?
- One shared archive for Walter + Anja, or per-user ownership and permissions?
- Import the old documents from the evac copies (`Anja/08_Dokumente`, the
  `Rechnung …`/`Konto-…` files)? Which ones?
- Where do the originals live? A new `documents` share (own snapshot schedule,
  like `photos`) or a folder in `data`?

**Backup:** the DB plus originals are data that exists nowhere else. They must
be in [13](13-restic-321-service.md)'s scope (`pg_dump`, not the raw Postgres
directory). **Don't put real documents in before 13 is green.**

**Blocked by:** 08 (GPU + NFS foundation: mounts + podman), 13 for real use.

**Status:** idea, not grilled
