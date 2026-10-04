# 10 — Import the photos from the evacuation archives into Immich

**What to build:** The full photo library imported into Immich via a one-time
**Immich CLI** bulk import (hash-dedup, managed library — not external/index-in-place),
reading **from 01's evacuation archives**, writing into the empty library on the fresh
array.

**This ticket got much safer.** The original plan imported *on the array*, holding
two ~950 GB copies simultaneously, then deleted the source after verification —
with the delete step being the risky part. Because the NAS was wiped
([05](05-wipe-and-rebuild-nas.md)), the source is now an archive on a USB HDD that
stays untouched. **No reclaim step on real data at all.**

**Extract first — the CLI reads files, not zips.** ~950 GB has to land somewhere
with room for it: not the laptop's NVMe (Immich's thumbnails are about to need it),
and not `main-pc` (~726 GB free). Use a **temporary, non-snapshotted `scratch`
share on the fresh array** — it's empty and has ~6 TB — extract one archive at a
time, import it, and delete the scratch share once the checks below
pass. (A btrfs snapshot on it would pin the space, hence non-snapshotted.) The
archives on HDD A/B are never written to.

**Run the backlog with `main-pc`'s GPU if you set it up** in
[09](09-deploy-immich.md) — this is the one job where the 3080 is worth its power
draw.

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

**Blocked by:** 09 (Immich deployed), 01 (the archives are the source).

**Status:** ready-for-agent

- [ ] `@eaDir` excluded — confirmed by asset count sanity, not by hope
- [ ] All sources imported to the correct accounts, including `photo/`
- [ ] Hash-dedup confirmed working (re-running the import adds nothing)
- [ ] Counts + spot-checks verify nothing lost vs. source
- [ ] Thumbnail + ML jobs completed across the whole library
- [ ] Partner sharing visible from both accounts
- [ ] `scratch` share deleted after verification
- [ ] **HDD A/B archives left intact** — they are the fallback until [13](13-restic-321-service.md) is green on both repos

_Decision detail: [06](../../issues/06-immich-placement-migration.md#amendment--second-pass-2026-07-26)._
