# 01 — Inventory `/volume1` and evacuate the photos to USB

**What to build:** Two independent, verified copies of every irreplaceable file on
the NAS, living **off** the NAS, before anything is deleted or rebuilt. This is the
hard gate for the entire plan — [05](05-wipe-and-rebuild-nas.md) destroys the array.

**Inventory first.** Run `du -sh /volume1/*` and write the result down. The scope is
a **denylist, not an allowlist**: back up *everything* except confirmed-disposable
media. An enumerated allowlist is exactly how `/volume1/photo` came to be missing
from every ticket in this repo.

- Synology Photos **personal** space → `/volume1/homes/<user>/Photo`
- Synology Photos **shared** space → **`/volume1/photo`** ← the one that was missed
- Confirmed disposable: `PlexMediaServer/*` (including `Photos`, which is artwork).
  There is no music on the NAS.

**Two copies, two tools, on purpose.** USB #1 gets a **restic** repo — checksummed
verification via `restic check` rather than hoping `cp` worked, and this repo
*becomes backup copy #2* in [13](13-restic-321-service.md). USB #2 gets an
independent **plain-file copy**, deliberately a different tool so a restic-format
problem cannot cost you both copies.

Run it from `main-pc` (already NixOS, tools ready, can mount the NAS today).
**Pin `--host` and use a mount path identical to the one `home-server` will use
later** — restic's `forget` groups snapshots by host + paths, so a mismatch would
silently put your first and most precious snapshot in a separate retention lineage
from the policy meant to protect it.

**Blocked by:** None — start here.

**Status:** ready-for-agent

- [ ] `du -sh /volume1/*` inventory recorded; every non-disposable path identified
- [ ] **SMART check passes on both USB drives** — for the duration of the wipe they *are* the data
- [ ] restic repo initialised on USB #1; snapshot covers everything except `PlexMediaServer/*`
- [ ] `restic check` passes; a sample file restores and opens correctly
- [ ] Independent plain-file copy on USB #2, verified by checksum (not just file count)
- [ ] `--host` and mount path pinned to match the future `home-server` job
- [ ] Repo password/keys stored off the NAS *and* off both laptops (password manager + printed)

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--second-pass-2026-07-26)._
