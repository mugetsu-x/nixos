# 07 — File-sync / personal-cloud solution (hosted on the ThinkBook)

Parent: [map](../map.md)
Type: grilling
Status: resolved
Blocked by: —

## Question

Placement is settled by the keystone (03): **file-sync runs on the ThinkBook**
(compute/application layer). The open decision is *which solution*, driven by
what you actually need it to do:

- **Syncthing** — peer-to-peer folder sync, no server-of-record, no web UI for
  files, no sharing links. Lightweight, great for "keep these folders in sync
  across my devices." Weak for non-technical family or web access.
- **Nextcloud** — full personal cloud: web UI, mobile apps, file sharing links,
  calendar/contacts, but heavier (PHP + DB + cron) and more to maintain. Has a
  first-class NixOS module. Right choice if family members need a URL/app to
  reach files, or you want more than raw folder sync.
- **Other** (Seafile, ownCloud, plain SMB + a mobile client, etc.).

Consider: is this just *your* multi-device sync, or a **shared household**
service? Does it need to be reachable from outside the house (references remote
access, 04)? Where does the synced data live — laptop NVMe vs NAS mount (mirrors
the 06 storage question)?

Resolution names the tool, where its data lives, and any prerequisites.

## Answer

Resolved 2026-07-26 via `/grilling`. **Decision: run no self-hosted file-sync /
personal-cloud service at all** — neither the ThinkBook nor the NAS hosts one. The
ticket's framing ("which tool") was pre-empted by the prior question ("do we need
one?"), and the honest answer is no.

### Why "don't build it"

The workload is already covered by three things that fall outside a self-hosted
file cloud:

- **Documents → Google Drive**, plus physical copies of the important ones. Working
  well; the user is happy with it and has **no de-Googling intent** — the usual
  motivation for self-hosting documents is absent.
- **Photos (~950 GB) → Immich on the ThinkBook** — ticket 06, a separate workload,
  already placed. This also covers phone photo/video auto-backup, the one thing
  Drive doesn't do well.
- **Movies/TV → the media stack on the NAS.**

No large-file, household-web-surface, or device-sync need falls through those
cracks. Every self-hosted service is permanent maintenance (Nextcloud especially:
PHP + Postgres + cron); standing one up to re-solve a solved problem is a net
negative. **Rejected:** Syncthing (no unmet personal-sync need), Nextcloud/Seafile
(no family-facing file surface required).

### Backup coupling closed (05)

The 3-2-1 backup strategy (05) does **not** depend on any file-sync tool: it uses
**restic** and explicitly *rejected* Syncthing ("sync, not backup — no versioning,
propagates deletes"). 05 carried one conditional scope tier — *"file-sync data from
07 if it becomes source-of-record"* — which now evaluates to **nothing**: there is
no self-hosted file-sync source-of-record to back up. Google Drive is
externally-redundant by Google; local physical copies cover the important docs. No
edit to 05 needed — its conditional simply resolves empty.

### Revisit trigger (not a ticket)

If a concrete need later appears — large files unfit for Drive (video projects,
datasets, VM images), a genuine push to pull documents off Google, or a
family-facing "reach a file by URL/app" surface — reopen as a **fresh ticket**:
Nextcloud (first-class NixOS module) for the household-web case, Syncthing for pure
personal multi-device sync. Nothing to pre-specify now; no fog graduated, no new
tickets surfaced.
