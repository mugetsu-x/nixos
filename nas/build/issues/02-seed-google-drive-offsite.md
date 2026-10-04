# 02 — Upload the evacuation archives to Google Drive (before the wipe)

**What to build:** Copy #3 of the evacuation archives from [01](01-inventory-and-evacuate.md)
living offsite in Google Drive, uploaded and verified **before**
[05](05-wipe-and-rebuild-nas.md) touches the array.

> **Revised 2026-10-04.** This is now a plain upload of 01's zip archives, not a
> restic seed. The restic repo on Drive is created fresh by
> [13](13-restic-321-service.md) once `home-server` is running; its mandatory
> configuration (own OAuth client ID, `--pack-size 64`) moved there.

**Why this is not optional and not deferrable.** Between "wipe the NAS" and
"photos restored into Immich" your only other copies are two USB disks in one room.
One house fire, one theft, one bad power event on the desk they're sitting on and it
is all gone. Uploading first is what keeps you at **three copies through the one
window where it actually matters.** It is days of unattended uplink and it blocks
nothing else — start it and walk away.

**Target:** Google Workspace **Business Plus**, 5 TB pooled, already paid. A
dedicated folder in Drive proper — **not Google Photos**.

- **Use Drive for desktop or `rclone copy`, not the browser.** Browser uploads of
  multi-GB files fail without resuming; the other two resume.
- Expect **≥2 days**: Drive caps uploads at **750 GB/day per user**.

**Decide: encrypted or plain archives.** The original plan had the offsite copy
client-side encrypted. Plain zips are readable by anyone with access to the Workspace
account (and to Google). If that matters, create the archives in 01 with 7-Zip's
**AES-256** and keep the password in the password manager + printed — note that zip
AES encrypts contents but not filenames; the `.7z` format with "encrypt file names"
hides both. If it doesn't matter, plain is fine: it's your own tenant, and these
archives are retired once 13's encrypted repo is proven.

**Verify against 01's manifest, not by eye.** Drive stores an MD5 for every file;
`rclone md5sum <remote>:<folder>` lists them, and they must match the manifest.

**Lifetime:** keep the archives on Drive until 13's Drive repo has passed its
restore drill, then delete them so they don't sit in the 5 TB pool that also runs
Gmail.

**Blocked by:** 01 (the archives and their manifest).

**Status:** ready-for-agent

- [ ] Encryption decided (plain or AES-256); if encrypted, password stored off-machine
- [ ] All archives + manifest uploaded to a dedicated Drive folder
- [ ] **Drive MD5s match the manifest** for every archive
- [ ] **A real restore drill:** download one archive to a clean location, `7z t` passes, files open
- [ ] Workspace pool usage noted
- [ ] Google Vault retention behaviour on Drive **verified**, not assumed

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--third-pass-2026-10-04)._
