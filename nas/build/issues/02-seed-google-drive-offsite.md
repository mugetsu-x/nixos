# 02 — Upload the evacuation to Google Drive, encrypted (before the wipe)

**What to build:** Copy D of [01](01-inventory-and-evacuate.md)'s evacuation living
offsite in Google Drive, **client-side encrypted with `rclone crypt`**, uploaded
from **copy C on `main-pc`** and verified **before** [05](05-wipe-and-rebuild-nas.md) touches the
array.

> **Revised 2026-10-04 (second revision).** 01 now produces plain file trees, not
> 7-Zip archives, so this is an `rclone` sync of the tree into an encrypted remote,
> run by the agent from `main-pc`. The restic repo on Drive is still created fresh
> by [13](13-restic-321-service.md) once `home-server` is running; its mandatory
> configuration (own OAuth client ID, `--pack-size 64`) lives there.

**Why this is not optional and not deferrable.** Between "wipe the NAS" and
"photos restored into Immich" the other copies all sit in one house. One fire, one
theft, one bad power event and they are gone together. The upload is what keeps
an offsite copy through the one window where it actually matters. It is days of
unattended uplink and it blocks nothing else — start it and walk away.

**Target:** Google Workspace **Business Plus**, 5 TB pooled, already paid. A
dedicated folder in Drive proper — **not Google Photos**.

**Encryption: decided — yes, `rclone crypt`, filenames included.** The earlier
"plain or AES zip?" question goes away: crypt encrypts contents *and* names, needs
no staging space, and the same rclone is what restores it. The only things needed
to read it back are rclone and **the two crypt passwords** (password + salt).

**How (agent, `nix run nixpkgs#rclone`, nothing installed):**

1. **You:** `rclone config` once — a `drive` remote (`gdrive:`) authorised via the
   browser, then a `crypt` remote (`evac:` → `gdrive:evac-2026-10`), filename
   encryption `standard`. Use a **dedicated OAuth client ID** (same reason as in
   [13](13-restic-321-service.md): rclone's shared one is rate-limited across every
   rclone user on Earth). Store both crypt passwords in the password manager
   **and printed** before the upload starts — without them copy D is noise.
2. **Agent:** `rclone copy ~/evac evac: --transfers 4 --checkers 8`
   — with the manifest included. Resumable: a re-run uploads only what's missing.
3. **Agent:** `rclone cryptcheck ~/evac evac:` — verifies every
   uploaded file's checksum through the encryption layer. Zero differences, zero
   missing.

**Expect ≥2 days.** Drive caps uploads at **750 GB/day per user**, and creating
files is itself rate-limited (~2–3/s), so a library with hundreds of thousands of
small files adds hours on top. rclone backs off and retries on 403
`userRateLimitExceeded` by itself. Uploading from the NVMe copy means no USB disk
has to stay plugged in for days.

**Restore drill before the wipe.** Download one whole source folder from `evac:` to
a clean location and run `sha256sum -c` on it against the manifest — that proves
the passwords, the config and the data, together, while every other copy still
exists.

**Lifetime:** keep copy D until 13's Drive repo has passed its restore drill, then
delete `gdrive:evac-2026-10` so it doesn't sit in the 5 TB pool that also runs
Gmail.

**Blocked by:** 01 (copy C exists and is verified).

**Status:** ready-for-agent (after you've done the `rclone config`)

- [ ] `gdrive:` + `evac:` remotes configured with a dedicated OAuth client ID
- [ ] Crypt password + salt stored in the password manager **and printed**, before upload
- [ ] Full upload of copy C, including the manifest
- [ ] **`rclone cryptcheck` clean** — no differences, nothing missing
- [ ] **Restore drill:** one source folder downloaded to a clean location, `sha256sum -c` passes against the manifest
- [ ] Final delta from 01's freeze uploaded and cryptchecked
- [ ] Workspace pool usage noted
- [ ] Google Vault retention behaviour on Drive **verified**, not assumed

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--fourth-pass-2026-10-04)._
