# 06 — Immich: storage layout and migrating ~950 GB off the NAS

Parent: [map](../map.md)
Type: grilling
Status: open
Blocked by: —

## Question

Placement is settled by the keystone (03): **Immich runs on the ThinkBook**
(server + ML), because that's where the CPU/GPU/RAM is. What remains:

1. **Storage layout — where do the ~950 GB of photos physically live?**
   - **On the NAS array, mounted over the LAN (NFS/SMB) by Immich on the laptop**
     — keeps the photos on RAID'd, snapshotted, storage-of-record disks (the
     division-of-labour default). Cost: Immich's library I/O crosses the LAN; DB
     stays local on NVMe.
   - **On the laptop's NVMe (local copy)** — faster, but now the irreplaceable
     data lives on a single non-RAID disk unless backup (05) covers it, and the
     laptop becomes storage-of-record, violating the principle.
   - Likely answer: **library on NAS/NFS, Postgres + thumbnails + ML models on
     local NVMe.** Confirm and pin the exact mount + which datasets are local.

2. **Migration of the ~950 GB** off the current NAS shares (`homes`/`Walter`/
   `Anja`) into Immich's library structure — how, and in what order relative to
   the backup ticket (05). **Ordering constraint:** the photos are a single copy
   today; a second copy (05) should exist *before* any large move. Sequence this.

3. **Immich ML config on the RTX 3060 6 GB** (from 01: CUDA ✓, no AV1 encode —
   irrelevant to ML): which ML models/jobs (face recognition, smart/CLIP search),
   and confirm 6 GB VRAM is enough for the chosen models.

Resolution names the storage layout, the migration sequence (with its dependency
on 05), and the ML configuration.
