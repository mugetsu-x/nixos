# 01 — Off-array backup gate: restic init + first snapshot from main-pc

**What to build:** An off-NAS backup copy of the irreplaceable ~950 GB of family
photos (`homes`, `Walter`, `Anja` shares) exists *before* any risky NAS operation.
Run `restic init` and take a first snapshot of the raw photo shares from `main-pc`,
targeting the in-hand 4 TB USB HDD. This is the **hard prerequisite gate** for the
phase-0 array expansion (04) and the Immich migration (11) — both put the only copy
of the photos at risk. Hetzner upload is off the critical path (see 12). btrfs
snapshots are *not* a substitute — they live on the same at-risk array.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] restic repo initialised on the 4 TB USB HDD (or other genuinely off-NAS target)
- [ ] First snapshot of `homes`, `Walter`, `Anja` completed; `restic snapshots` lists it
- [ ] `restic check` passes and a sample file restores correctly
- [ ] Repo password/keys stored off the NAS *and* off the laptop

_Decision detail: [05](../../issues/05-backup-topology.md)._
