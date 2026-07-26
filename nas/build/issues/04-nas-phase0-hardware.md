# 04 — NAS phase-0 hardware: fit RAM + 4th drive, expand array

**What to build:** The in-hand 4 GB SODIMM and 4 TB IronWolf fitted, taking
Alexandria to **6 GB RAM** and expanding the RAID 5 pool **online** to ~5.4 TB
usable. One bay-out session (the SODIMM slot is only reachable with the drive bays
out). The array runs **degraded** through the rebuild — a day or more on the
Celeron — so this only happens *after* 01's off-array copy exists.

**Blocked by:** 01 (off-array backup gate).

**Status:** ready-for-agent

- [ ] Both parts fitted; DSM memory test passes; Info Center reads ~6 GB
- [ ] 4th drive added to the RAID 5 array; online expansion completes; pool ~5.4 TB
- [ ] Array healthy after the rebuild

_Detail: [PLAN.md](../../PLAN.md) phase 0._
