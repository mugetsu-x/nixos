# 06 — Immich: storage layout and migrating ~950 GB off the NAS

Parent: [map](../map.md)
Type: grilling
Status: resolved
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

## Answer

Resolved 2026-07-26 via `/grilling`. Placement was already fixed by the keystone
(03): **Immich runs on the ThinkBook.** The five sub-decisions:

### 1. Storage layout

- **Originals live on the NAS array, mounted over NFS by Immich on the ThinkBook.**
  The irreplaceable photos stay on the RAID 5 + btrfs-snapshotted storage-of-record
  box — the keystone's division-of-labour default. Only bulk original reads cross
  the LAN, which for a photo library is a cold path.
- **Postgres, the thumbnail/encoded cache, and the ML model cache all live on the
  laptop's local NVMe.** Non-negotiable split: Postgres on an NFS mount is a
  corruption risk, and the hot thumbnail-serving path must not cross the LAN.
- Concretely: Immich's `UPLOAD_LOCATION` → the NAS NFS mount; the DB volume and
  `*/thumbs`, `*/encoded-video`, model cache → local NVMe.

### 2. Library mode — managed, not external

- **Managed / upload library**, not an in-place external library. Immich owns the
  files under `UPLOAD_LOCATION`; the existing 950 GB is brought in by a **one-time
  bulk import via the Immich CLI**, which **deduplicates by hash** and consolidates
  everything into one clean, date-templated store. Phone auto-backup lands in the
  same library going forward.
- Rejected external-library (index-in-place) because it's a read-only viewer: no
  dedup, no consolidation, phone uploads can't land in it → a permanent split of
  "old external" + "new uploaded." The point of adopting Immich is to unify the
  scattered shares, which is worth a one-time copy.

### 3. Users — two accounts + partner sharing

- **Two accounts: Walter (admin) and Anja**, with Immich's **partner sharing**
  enabled both ways so each owns their own library and phone backup but sees a
  merged timeline.
- Import mapping: `Walter/*` → Walter, `Anja/*` → Anja, shared `homes` → Walter
  (admin) as the family baseline. Doesn't need a perfect sort — mis-placed assets
  can be moved or shared via albums afterward.

### 4. Migration sequence (dependency on 05)

Everything is a **copy, not a move** — the CLI import leaves the source shares
intact until an explicit delete — which gives a safe order:

1. **Off-array second copy first (05's immediate step) — the hard gate.** Neither
   the import nor PLAN.md's phase-0 array expansion proceeds until ≥1 copy of the
   950 GB lives *off* the NAS.
2. **Run the Immich CLI import** from the ThinkBook (reads old shares over the NAS
   mount, writes into the managed store on the NAS). Non-destructive. Dedup means
   the managed library may land *under* 950 GB; both copies fit on the array
   (~2.6 TB free after the 471 GB Plex cleanup, and phase-0 expansion adds more).
3. **Verify** — asset counts vs. source, spot-check a sample, confirm thumbnails +
   ML jobs completed.
4. **Reclaim only then** — delete the old `homes`/`Walter`/`Anja` photo copies, and
   *only if* the off-array backup (05) now covers the Immich store **and** Immich's
   own backups run. Never delete source on the import alone.
5. **Array expansion (PLAN.md phase 0)** proceeds under the same off-array gate.

Recorded as a **soft execution-sequencing dependency on 05, not a formal
`Blocked by` edge** — 06 is a planning ticket and its *decision* needs nothing
from 05; only its *execution* is gated on 05's first step.

### 5. ML config on the RTX 3060 6 GB

- **CUDA-accelerated `immich-machine-learning` image**, GPU passed into the
  container. VRAM is not the binding constraint — one CLIP model + the face model
  loaded together is ~2–3 GB, comfortable in 6 GB. (AV1-encode absence from 01 is
  irrelevant — that's video transcode, not ML.)
- **Smart Search: English-only, `ViT-B-16-SigLIP2__webli`.** Both users are German
  natives but English-proficient; smart search is concept-based (you type "beach",
  "snow"), so multilingual buys nothing while the strong English SigLIP2 model
  retrieves English queries better. Not a one-way door — swapping the model later
  just re-runs the Smart Search job.
- **Face detection/recognition: default `buffalo_l`, enabled**, so people get
  grouped.
- **Job concurrency ≈2** (Smart Search / Face Detection) so the big initial
  backlog run doesn't stack multiple model copies in VRAM.
- **Host prerequisite:** `hardware.nvidia-container-toolkit.enable = true` (plus the
  container getting GPU access) on the new `home-server` NixOS flake host from the
  keystone — not this repo's `main-pc`.
