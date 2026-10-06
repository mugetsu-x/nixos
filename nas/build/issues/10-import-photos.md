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

**Status:** in progress 2026-10-06: walter imported, anja uploading (detached, see "Handover"); see "Run" below

- [ ] `@eaDir` excluded — confirmed by asset count sanity, not by hope
- [ ] All sources imported to the correct accounts. There is no `photo/`: the shared space was never used (01). Mapping decided 2026-10-06, see "Run"
- [ ] Hash-dedup confirmed working (re-running the import adds nothing)
- [ ] Counts + spot-checks verify nothing lost vs. source
- [ ] Thumbnail + ML jobs completed across the whole library
- [x] Partner sharing visible from both accounts — set up in 09 (2026-10-06): both directions, in timeline
- [ ] Per-source asset counts in Immich reconciled against 01's manifest counts (minus non-media files)
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
- [ ] `run.log` shows the anja upload's summary. Account for its failures the same
      way (manifest hash), and both re-check passes find 0 new.
- [ ] Per-account counts reconciled: walter 18,429 (+1 test photo); anja ≈ 36,059 − duplicates.
- [ ] Spot-check a few albums from both accounts in the UI (dates, videos play).
- [ ] Wait for every job queue to read 0, then:
  - put the job concurrency back to the defaults;
  - stop the main-pc worker (`sudo systemctl stop docker-immich-machine-learning`);
  - run the PC-off fallback test for 09.
- [ ] **Delete both API keys**, in Immich (each user's Account Settings → API
      Keys) and in `~/.cache/immich-import/` (`walter.key`, `anja.key`, plus
      `config*.json`, which holds the system config).
- [ ] Walter: move private photos into the Locked Folder (sharing to Anja stayed on).
