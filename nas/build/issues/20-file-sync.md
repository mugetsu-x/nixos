# 20 — A Google-Drive-like file service

**What to build:** a self-hosted file sync and share service on `home-server`,
over the NAS's `files` share: a folder that syncs across main-pc and the phones,
web access, and the occasional share link.

Added 2026-10-07 as a wish (Walter); **not grilled yet**.

**Shape (proposal):**
- Immich already covers photos and [15](15-paperless-ngx.md) would cover
  documents, so this is the remaining "everything else" folder, not a Drive
  replacement for all of it.
- The data is the `files` share created for 13 (2026-10-07): **one share, one
  folder per person** (`files/walter`, `files/anja`), so each folder can become
  that user's home in whatever service is picked, with nothing to reorganise.

**Candidates (all have modules in the pinned nixpkgs, checked 2026-10-07):**
- **Nextcloud** (`services.nextcloud`), the front-runner. Mature, good
  Android/desktop/web clients, native module (no container), and the files stay
  an ordinary tree on the NAS. Heavy (PHP + Postgres + Redis), and major
  upgrades must be stepped one version at a time (the module enforces it). Files
  written to the share behind its back need `occ files:scan`.
- **OpenCloud** (`services.opencloud`). A lighter, files-only fork of oCIS
  (2025). Young, and by default it stores files in its own layout rather than a
  plain tree, which makes restoring from restic less direct.
- Syncthing (`services.syncthing`) is sync only: no web view, no share links.
  Not Drive-like.

**Things that will bite:**
- The sync clients effectively require **HTTPS**. Same open question as
  [17](17-actual-budget.md)/[18](18-home-assistant.md); `tailscale cert` on the
  `*.ts.net` name is the likely shared answer.
- It holds irreplaceable data: its DB (`pg_dump`) and the `files` share go into
  [13](13-restic-321-service.md).

**Open questions:**
- Nextcloud or OpenCloud?
- Does Anja want it, or is this Walter-only?
- Share links to people outside the tailnet: needed? That would mean public
  exposure (Funnel or a reverse proxy), which nothing else here has.

**Blocked by:** 13 for real use; the HTTPS answer.

**Status:** idea, not grilled
