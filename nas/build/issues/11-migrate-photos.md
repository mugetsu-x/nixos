# 11 — Migrate ~950 GB photos into Immich

**What to build:** The ~950 GB migrated into Immich via a one-time **Immich CLI
import** (hash-dedup, **managed library** — not external/index-in-place):
`Walter/*` → Walter, `Anja/*` → Anja, `homes` → Walter. **Non-destructive**: copy →
verify → reclaim. Gated on 01's off-array copy existing (the source is the only
copy until verified).

**Blocked by:** 10 (Immich deployed), 01 (off-array backup gate).

**Status:** ready-for-agent

- [ ] All three shares imported to the correct accounts; hash-dedup confirmed
- [ ] Counts / spot-checks verify nothing lost vs. source
- [ ] Partner sharing visible across both accounts
- [ ] Source reclaimed **only after** verification

_Decision detail: [06](../../issues/06-immich-placement-migration.md)._
