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

## Decisions (Walter, 2026-11-01)

- **Originals on a new `documents` NAS share**, mounted at `/documents`. Not a
  folder in `data`: that is the media pool, which 13 excludes.
- **In via web upload / phone app, plus a consume folder** on the share
  (`documents/consume`) that a scanner or PC writes into over SMB. Polled
  every 60 s (inotify is blind on NFS), and subfolders are included.
- **One shared archive, two accounts.** `walter` is the superuser (password in
  sops: `paperless_admin_password`). Anja gets a normal account in the UI.
- Mail fetching: not now (configured in the UI if ever wanted).
- Importing the old documents: open, and after 13 in any case.

## Build (2026-11-01)

`modules/server/paperless.nix`, using the native `services.paperless` module
(2.20.15), at `http://home-server:28981`, with a Homepage tile under
"Documents".
- Postgres is native, **socket-only** (`listen_addresses = ""`), because
  Immich's container already holds 0.0.0.0:5432 on the host network. Redis is
  native, also socket-only.
- `/var/lib/paperless` (NVMe) holds the search index, the Django secret key and
  `superuser-state`. `/documents/media` holds the originals, archive PDFs and
  thumbnails.
- `PAPERLESS_FILENAME_FORMAT` = `{{ created_year }}/{{ correspondent }}/{{ created }} {{ title }}`,
  set before any document.
- OCR `deu+eng`; the module builds tesseract with just those languages.
- The module's tmpfiles rules for the two NAS folders are dropped (tmpfiles at
  early boot would trip the automount before the network is up), so the folders
  are created once by hand. Every Paperless unit has
  `RequiresMountsFor = /documents`.
- `services.postgresqlBackup` writes a nightly dump to
  `/var/backup/postgresql/paperless.sql.gz` for 13.
- **Changing `paperless_admin_password` in sops does not change the login.**
  The module's `manage_superuser` only *creates* the user ("Did not create
  superuser, a user walter already exists"). After `sops set` + deploy, set
  it in the DB as well (stdin, because `paperless-manage` runs as `paperless`
  and can't read the root-only secret):
  `cat /run/secrets/paperless_admin_password | paperless-manage shell -c "import sys; from django.contrib.auth.models import User; u=User.objects.get(username='walter'); u.set_password(sys.stdin.read().strip()); u.save()"`
- No Tika/Gotenberg yet: PDFs and images only, no Office files or `.eml`.
  `services.paperless.configureTika = true` adds them.

### Deploy runbook

1. **DSM (Walter):** create a shared folder `documents` on volume1, with an NFS
   rule for 192.168.0.73 and 192.168.0.87 matching `photos` (read/write, squash
   "Map all users to admin"). Enable SMB access to it for the scanner and PCs.
   Give it a snapshot schedule like `photos`.
2. Check from home-server: `showmount -e 192.168.0.70` lists `/volume1/documents`.
3. Deploy: `nixos-rebuild switch --flake .#home-server --target-host root@home-server`.
4. Once: `mkdir -p /documents/media /documents/consume` on home-server, then
   `systemctl restart paperless-scheduler`.
5. Log in as `walter` (`sops -d --extract '["paperless_admin_password"]' secrets/home-server.yaml`)
   and create Anja's account.

- [x] `documents` share + NFS rule in DSM — 2026-11-01: checksum on, recycle bin off, not encrypted; NFS like `photos` (async off); daily snapshot 04:15
- [x] Deployed 2026-11-01; web UI up; a test PDF in `consume/` was picked up on the next poll, OCR'd and filed as `originals/2026/2026-11-01 claude-test.pdf`, found by full-text search, then deleted (+ trash emptied)
- [ ] Anja's account
- [ ] 13 covers `/documents` + the dump, **then** real documents

**Status:** deployed 2026-11-01. Left: Anja's account; real documents only after 13.

**Watch:** OCRmyPDF warns that Ghostscript 10.6.x can corrupt JPEG images in the *archive* PDF. Originals are never touched. Spot-check the first real photo-scans and bump nixpkgs when a fixed Ghostscript lands.
