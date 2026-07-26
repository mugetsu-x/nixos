# 10 — Import the photos from USB into Immich

**What to build:** The full photo library imported into Immich via a one-time
**Immich CLI** bulk import (hash-dedup, managed library — not external/index-in-place),
reading **from the USB evacuation copy**, writing into the empty library on the fresh
array.

**This ticket got much safer.** The original plan imported *on the array*, holding
two ~950 GB copies simultaneously, then deleted the source after verification —
with the delete step being the risky part. Because the NAS was wiped
([05](05-wipe-and-rebuild-nas.md)), the source is now a USB drive that stays
untouched and **becomes backup copy #2**. No double copy, no space pressure, **no
reclaim step at all.**

**Import mapping:**

| Source | → Account |
|---|---|
| `homes/Walter/Photo` | Walter |
| `homes/Anja/Photo` | Anja |
| **`photo/`** (Synology Photos *shared* space) | Walter (admin) — the family baseline |
| `Walter/*`, `Anja/*` | respective owners |

**`/volume1/photo` was missing from every original ticket** — Synology Photos keeps
shared-space assets there while personal space lives under `homes/<user>/Photo`.

**Exclude `@eaDir`.** Every Synology Photos folder is littered with these DSM
thumbnail directories. Import them blindly and you add hundreds of thousands of junk
assets.

Mis-sorted assets can be moved or shared via albums afterwards — the mapping doesn't
need to be perfect.

**Blocked by:** 09 (Immich deployed), 01 (the USB copy is the source).

**Status:** ready-for-agent

- [ ] `@eaDir` excluded — confirmed by asset count sanity, not by hope
- [ ] All sources imported to the correct accounts, including `photo/`
- [ ] Hash-dedup confirmed working (re-running the import adds nothing)
- [ ] Counts + spot-checks verify nothing lost vs. source
- [ ] Thumbnail + ML jobs completed across the whole library
- [ ] Partner sharing visible from both accounts
- [ ] **USB source left intact** — it is backup copy #2, not scratch space

_Decision detail: [06](../../issues/06-immich-placement-migration.md#amendment--second-pass-2026-07-26)._
