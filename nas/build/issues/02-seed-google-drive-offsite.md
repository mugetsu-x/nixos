# 02 — Seed the Google Drive offsite copy (before the wipe)

**What to build:** Copy #3 of the photos living offsite in Google Drive, seeded
**before** [05](05-wipe-and-rebuild-nas.md) touches the array.

**Why this is not optional and not deferrable.** Between "wipe the NAS" and
"photos restored into Immich" your only copies are two USB disks in one room. One
house fire, one theft, one bad power event on the desk they're sitting on and it is
all gone. Seeding Drive first is what keeps you at **three copies through the one
window where it actually matters.** It is days of unattended uplink and it blocks
nothing else — start it and walk away.

**Target:** Google Workspace **Business Plus**, 5 TB pooled, already paid — this
replaces the Hetzner Storage Box from the original plan (~€143/yr saved). restic
via the **rclone** backend, client-side encrypted.

**Mandatory configuration** — the decision is only sound with all of it:

- **Your own OAuth client ID** for rclone. The shared default is rate-limited into
  uselessness.
- **`--pack-size 64`** (restic default is 16 MiB). Cuts object count ~4×, which is
  what makes `check` and `prune` tolerable against Drive's paginated, rate-limited
  API.
- **Drive proper, not Google Photos** — that API is no longer usable for this.
- Expect **≥2 days**: Drive caps uploads at **750 GB/day per user**.

**Blocked by:** 01 (inventory — so you know what's in scope).

**Status:** ready-for-agent

- [ ] Own OAuth client ID created; rclone remote configured and authorised
- [ ] restic repo initialised on the Drive remote with `--pack-size 64`
- [ ] Full seed completed — `restic snapshots` lists it from a clean machine
- [ ] `restic check` passes against the Drive repo
- [ ] **A real restore drill:** pull ~10 GB back to a clean location and open the files
- [ ] Workspace pool usage noted; alert threshold decided (see [14](14-alerting.md))
- [ ] Google Vault retention behaviour on Drive **verified**, not assumed

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--second-pass-2026-07-26)._
