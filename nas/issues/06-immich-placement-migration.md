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

---

## Amendment — second pass (2026-07-26)

Placement, storage split, library mode, user model and ML configuration all
**stand**. Three corrections, one of which is load-bearing.

### 1. Deploy as `oci-containers`, NOT `services.immich`

**The NixOS module cannot do what this ticket requires.** Verified against the
pinned `nixos-25.05` (Immich 2.3.1):

- **No CUDA.** `pkgs/by-name/im/immich-machine-learning/package.nix` carries
  `insightface`, `opencv-python-headless`, `rapidocr` and friends — and **no
  `onnxruntime-gpu`, no CUDA anywhere.** ML would run on CPU, which defeats the
  entire reason Immich is on this machine rather than the NAS.
- **`mediaLocation` is a single path.** The originals-on-NFS /
  thumbnails-and-DB-on-NVMe split decided in §1 above cannot be expressed through
  the module without hand-rolled bind mounts underneath it.

So Immich runs from the **official upstream images** —
`immich-machine-learning:release-cuda` for ML — under
`virtualisation.oci-containers`, with separate bind mounts per subfolder
(`upload/` and `library/` on NFS; `thumbs/`, `encoded-video/`, model cache and the
Postgres volume on local NVMe). This is upstream's supported configuration for a
split layout.

**Pin the image tag explicitly.** Immich ships breaking DB migrations regularly and
occasionally requires stepped upgrades — never track `:release` unpinned.

This inverts the keystone's stated preference for first-class NixOS modules over
containers; see the amendment in
[03](03-keystone-server-or-not.md#amendment--second-pass-2026-07-26).

### 2. The source inventory was incomplete

The migration mapping named `Walter/*`, `Anja/*` and `homes`. The user's photos are
all in **Synology Photos**, which stores:

- **personal space** → `/volume1/homes/<user>/Photo` ✅ covered by `homes`
- **shared space** → **`/volume1/photo`** ❌ **named in no ticket in this repo**

`/volume1/photo` joins the import mapping and the backup scope. Confirmed *not*
photos: `PlexMediaServer/Photos` is Plex artwork.

**Exclude `@eaDir` from the import.** Every Synology Photos folder is littered with
these DSM thumbnail directories; imported blindly they add hundreds of thousands of
junk assets to the library.

### 3. The migration sequence collapses

The original sequence was: off-array copy → CLI import *on the array* → verify →
**reclaim** (delete the old shares), with two copies of ~950 GB coexisting on the
array and a delete step that had to be gotten exactly right.

Because the NAS is now **wiped and rebuilt** rather than expanded
([08](08-media-relocation-and-plan-consolidation.md#answer--second-pass-2026-07-26)),
the photos are already evacuated to USB before anything else happens. So:

1. Photos evacuated to USB #1 (restic) + USB #2 (plain copy), Drive seeded.
2. NAS wiped, fresh SHR-1 array, clean share layout, NFS exports.
3. Immich deployed against an **empty** managed library on the fresh array.
4. **Immich CLI imports directly from the USB copy** into that empty library.

**No double copy on the array. No space pressure. No reclaim step at all.** The
riskiest part of the original migration — deleting the source after verification —
simply ceases to exist, because the source is a USB drive that stays untouched and
becomes backup copy #2.

The old "soft execution gate on 05's off-array copy" is now a **hard structural
dependency**: the import's source *is* the evacuation copy.

### 4. Sizing note

Immich's thumbnails and previews land on the laptop's 1 TB NVMe alongside
Postgres, the ML cache, Jellyfin's cache and SABnzbd's `incomplete/`. For a library
this size expect roughly **50–150 GB of thumbnails** depending on final asset
count. It fits, but the NVMe is now the tightest resource on the box — confirm the
free second M.2 slot from [01](01-thinkpad-unit-and-always-on.md).

Also, **6 GB of VRAM is now shared with Jellyfin's NVENC transcodes.** Set
`MACHINE_LEARNING_MODEL_TTL` so idle models unload, and expect GPU contention
during the initial ML backlog run over the whole library.
