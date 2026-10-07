# 10 — Import the photos from the evacuation copies into Immich

**What to build:** The full photo library imported into Immich via a one-time
**Immich CLI** bulk import (hash-dedup, managed library — not external/index-in-place),
reading **from 01's evacuation copies** (plain file trees), writing into the empty library on the fresh
array.

**This ticket got much safer.** The original plan imported *on the array*, holding
two ~950 GB copies simultaneously, then deleted the source after verification —
with the delete step being the risky part. Because the NAS was wiped
([05](05-wipe-and-rebuild-nas.md)), the source is now one of 01's copies, which
stays untouched. **No reclaim step on real data at all.**

**No extraction step.** 01 copies plain file trees (not archives), so the CLI reads
the source directly — from **copy C on `main-pc`'s NVMe** (`~/evac/`), which holds
everything. Fast, and the USB disks stay cold. HDD A (mounted `-o ro`) is the
fallback; HDD B is never connected for this.

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

**Blocked by:** 09 (Immich deployed), 01 (copies C and A are the source), and the **NAS memory test** in [05](05-wipe-and-rebuild-nas.md) — **passed 2026-10-06** (2 loops, 4,000 MB, 0 failures); no longer a blocker.

**Status:** import done 2026-10-07; cleanup left for Walter (see "Handover" and "Result" below)

- [x] `@eaDir` excluded — confirmed by asset count sanity, not by hope — 2026-10-07: the CLI's file counts equal the files on disk *excluding* `@eaDir`/`#recycle`, for both accounts
- [x] All sources imported to the correct accounts. There is no `photo/`: the shared space was never used (01). Mapping decided 2026-10-06, see "Run"
- [x] Hash-dedup confirmed working (re-running the import adds nothing) — 2026-10-07: both re-check passes 0 new (only the 0-byte files re-attempted, rejected again)
- [ ] Counts + spot-checks verify nothing lost vs. source — counts done 2026-10-07; **UI spot-check left (Walter)**
- [x] Thumbnail + ML jobs completed across the whole library — 2026-10-07 08:15: every queue 0 waiting / 0 active / 0 failed
- [x] Partner sharing visible from both accounts — set up in 09 (2026-10-06): both directions, in timeline
- [x] Per-source asset counts in Immich reconciled against 01's manifest counts (minus non-media files) — 2026-10-07, see "Result"
- [ ] **Copies A/B/C left intact** — they are the fallback until [13](13-restic-321-service.md) is green on both repos

_Decision detail: [06](../../issues/06-immich-placement-migration.md#amendment--second-pass-2026-07-26)._

## Run (2026-10-06)

**Mapping (Walter's call):**

| Account | Sources (in `~/evac`) |
|---|---|
| walter | `homes/Walter/Photos`, `Walter/pictures` |
| anja | `homes/Anja/Photos`, `Anja/04_Media/Fotos`, `Anja/20210818_Hochzeit-Fotograf` |

**Skipped, still in the evac copies:**
- `Walter/reports`: Synology Report UI icons.
- `Anja/01_Ausbildung`, `Anja/06_Freizeitstuff`, `Anja/08_Dokumente`: school material, game clips, scans.
- `docker/`, `homes/plex`, `homes/admin`: no photos (admin is empty).

**Other decisions:**
- No albums from folder names: the timeline is enough.
- **The 406 files present in both accounts are uploaded to both.** Dedup is per owner, so they show twice in the merged timeline (Walter: fine).
- Private photos go into the Locked Folder **after** the import (Walter). Sharing stayed on, so Anja's timeline shows them until he moves them.

**Command** (from main-pc, CLI matching the server version):
```
cd ~/evac
IMMICH_INSTANCE_URL=http://home-server:2283/api IMMICH_API_KEY=$(cat ~/.cache/immich-import/<user>.key) \
  pnpm dlx @immich/cli@3.2.4 upload --recursive --ignore '**/{@eaDir,#recycle}/**' --no-progress <sources…>
```
Logs go to `~/.cache/immich-import/upload-<user>.log`. The API keys are temporary and get **deleted after the import**, in Immich and in that folder.

**Expected counts:**
- **walter:** the CLI found **22,367** files (146 GB), matching the manifest (22,834 media files − 468 report icons ≈ 22,366).
- The CLI's own duplicate check is against the server only, so the ~3,960 byte-identical copies within Walter's tree (and ~3,440 in Anja's) count as "new" in its report. The server rejects them on upload. Expect roughly **18.4 k** walter assets and **33 k** anja assets.

**ML backlog runs on main-pc's 3080** (09's optional worker, listed first) and video on the 3060's NVENC. For the import, job concurrency was raised: smart search + faces 4, video 2, thumbnails 4, OCR 2. **Set these back to the defaults (2/2/1/3/1) afterwards.**

**Observed:**
- ~60 MB/s from main-pc.
- The 3060 stayed in D3 while main-pc did all the ML.
- Laptop load ~5.7, Tctl 49 °C.

**Walter's result (20:48–21:31):** found 22,366, **uploaded 18,429 (139.7 GB)**,
skipped 3,926 server-side duplicates (6.7 GB), **11 failed with "File is empty"**.
The numbers add up exactly. All 11 are 0-byte files whose hash in 01's
NAS-side manifest is the empty-file SHA-256 (`e3b0c442…`): they were already
empty on the old array (WhatsApp images and one `.MOV` under
`homes/Walter/Photos/Handy/backup/`). The import lost nothing.

## Handover (end of 2026-10-06 session)

**The import runs detached** as a transient user unit on main-pc,
`immich-import.service` (`systemd-run --user`), running
`~/.cache/immich-import/run.sh`:
1. the anja upload (started 21:33; 36,059 files / 299.8 GB found, about 80–90 min at ~60 MB/s);
2. then a **re-check pass for walter**, then one for anja. Both must report 0 new
   files: that's the "re-running adds nothing" box.

Progress: `cat ~/.cache/immich-import/run.log` (one summary per pass) and the
`upload-anja.log` / `recheck-<user>.log` files beside it. Unit:
`systemctl --user status immich-import`. **Linger is off**: it survives closing
the terminal/Claude, **not logging out of the desktop or a reboot**. If it dies,
re-run `run.sh`: everything already uploaded gets skipped by hash.

**Needs main-pc on** until the ML queue drains too. The ML worker
(`docker-immich-machine-learning`) does the faces/smart search/OCR backlog on the
3080, and video goes through NVENC on the 3060. At 21:26 the queues held ~7 k
face grouping, ~5 k OCR, ~3 k metadata, ~2.4 k thumbnails, ~230 videos. Anja's
assets add to that.

**To finish 10, next session:**
- [x] `run.log` shows the anja upload's summary. Account for its failures the same
      way (manifest hash), and both re-check passes find 0 new. — 2026-10-07, see "Result"
- [x] Per-account counts reconciled: walter 18,429 (+1 test photo); anja ≈ 36,059 − duplicates. — 2026-10-07, see "Result"
- [ ] Spot-check a few albums from both accounts in the UI (dates, videos play).
- [x] Wait for every job queue to read 0 — 2026-10-07 08:15. Then:
  - [x] put the job concurrency back to the defaults (thumbnails 3, video 1,
        faces 2, smart search 2, OCR 1) — Walter, 2026-10-07;
  - [x] stop the main-pc worker — Walter, 2026-10-07;
  - [ ] run the PC-off fallback test for 09.
- [x] **Delete both API keys** in Immich — Walter, 2026-10-07. The local copies
      in `~/.cache/immich-import/` were deleted the same day; the logs and
      `run.sh` stay. (The key named `homepage` on Walter's account is 16's,
      created afterwards: keep it.)
- [ ] Walter: move private photos into the Locked Folder (sharing to Anja stayed on).

## Result (2026-10-07)

`run.sh` finished 23:11 on 2026-10-06, all three passes exit 0:

| Pass | Found | Uploaded | Duplicates | Failed |
|---|---|---|---|---|
| anja upload (21:33–23:07) | 36,059 (299.8 GB) | **32,628 (293.3 GB)** | 3,430 (6.5 GB) | 1 |
| walter re-check | 22,367 | 0 | 22,356 | 11 |
| anja re-check | 36,059 | 0 | 36,058 | 1 |

- **Failures:** the same 12 files every time, all 0 bytes and all hashed
  `e3b0c442…` (empty) in 01's NAS-side manifest. Anja's one is
  `homes/Anja/Photos/MobileBackup/Mi A3/DCIM/Camera/2022/04/IMG_20220416_143536.jpg`.
  Nothing lost.
- **Immich:** walter **18,430** (17,357 photos, 1,073 videos, 145 GB) = 18,429 + the
  test photo. anja **32,628** (31,043 photos, 1,585 videos, 302 GB).
- **Anja vs. 01's manifests:** 36,059 files on disk in her sources (minus
  `@eaDir`/`#recycle`) = 36,054 in `evac-manifest.full.sha256` + the 5 freeze-delta
  files; = 36,011 in `evac-manifest2.full.sha256` + the 48 files gone at the freeze.
  Every file on disk is accounted for.
- **Those 48 are now in Anja's Immich.** 01: Anja deleted them from the NAS on
  purpose (Pixel 7a, Jul–Sep 2026, `DCIM/Camera`, `Screenshots`, `WhatsApp Images`),
  but rsync kept them in C, and C was the import source. They show up in her
  timeline again. Her call whether to delete them again; the paths are the
  `comm -23` of the two manifests.
