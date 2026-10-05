# 01 — Inventory `/volume1` and evacuate it (two USB HDDs + `main-pc`)

**What to build:** Every irreplaceable file on the NAS copied **off** it, as plain
file trees, onto **HDD A, HDD B** and **`main-pc`'s NVMe** —
each copy verified file-by-file against a SHA-256 manifest **computed on the NAS
itself**. This is the hard gate for the entire plan:
[05](05-wipe-and-rebuild-nas.md) destroys the array.

> **Revised 2026-10-04 (second revision the same day).** The TeraCopy → 7-Zip flow
> from Windows is replaced by an **agent-run `rsync` from `main-pc`**, pulling over
> SSH. Why it is lower-risk, not just more automated:
>
> - **Plain trees, not archives.** No packing step, no staging space, no zip
>   encoding question (`rsync` copies filename bytes verbatim, ext4 stores them
>   verbatim), and every copy is directly browsable and directly importable by
>   [10](10-import-photos.md) — no extraction step there either. A damaged file
>   costs one file, not one archive.
> - **The NAS is only ever a source.** Every command reads from Alexandria and
>   writes to local disks. There is no `--delete`, no write path toward the NAS.
> - **End-to-end verification.** The manifest is hashed *on the NAS* from btrfs,
>   then every copy is checked against it. That catches corruption anywhere on the
>   way — network, USB bridge, disk — which a copy tool's own "verify" (reading back
>   what it just wrote) cannot fully do.
> - **Independent copies.** A and B are each pulled from the NAS separately, not
>   A → B, so a bad read on one copy is not cloned into the other.
>
> The evacuation is still a **one-off**, not the start of the restic lineage —
> [13](13-restic-321-service.md) initialises fresh repos.

## Where the copies live

| Copy | Medium | Contents | Role |
|---|---|---|---|
| **A** | WD My Passport 2 TB (`WD-WXH1E93CDLC9`), **ext4**, label `evac-a` | everything irreplaceable | cold copy; later reusable as [13](13-restic-321-service.md)'s USB target |
| **B** | Seagate Expansion 1 TB (`NA8C56DC`), **NTFS**, label `evac-b` | everything irreplaceable | cold copy, **unplugged and stored in another room** once verified |
| **C** | `main-pc` NVMe, `~/evac/` (~726 GB free) | everything irreplaceable | warm copy on a different medium (SSD, not USB HDD); source for [10](10-import-photos.md) |
| ~~**D**~~ | ~~Google Drive, `rclone crypt`~~ | — | **deferred 2026-10-04** — [02](02-seed-google-drive-offsite.md) |

**As executed (2026-10-04): A + C required, B optional, D deferred.** Two
verified copies on two media types (USB HDD, NVMe), none offsite — an accepted
risk for the wipe window, while the Google account question is open.

**A is ext4, B is NTFS — on purpose (decided 2026-10-04).** ext4 is Linux's native
filesystem with a real `fsck`; NTFS keeps one copy readable by plugging it into any
Windows machine. Different filesystems also means no single filesystem bug can
reach both disks. B is written with **`ntfs-3g`** (mature FUSE driver), not the
in-kernel `ntfs3`, and mounted with **`windows_names`**, so a filename Windows can't
open (`: ? * " < > |`, trailing dot/space) fails loudly in rsync instead of landing
as an unopenable file. Any such failures are listed and resolved by hand — they
are still on A, C and D.

## Who does what

The agent runs everything from `main-pc` except the steps that need a password or
root, which are yours (marked **you**). Total hands-on time ≈ 30 min.

### Step 0 — Preconditions (you, ~20 min, then mostly waiting)

1. **NAS health first.** DSM → Storage Manager: run a **data scrub** and a
   **SMART quick test on all three disks**; both must be clean before we trust the
   source. A scrub that fixes errors is a finding — stop and look before copying.
2. **SSH key + temporary read-only sudo on the NAS**, so the agent can read every
   user's home without a password prompt:
   ```
   ssh-copy-id alexandria       # ~/.ssh/config: alexandria → 192.168.0.70:2288, user Walter
   ssh alexandria
   chmod 755 ~ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys   # DSM's loose home perms make sshd ignore the key
   sudo sh -c 'echo "Walter ALL=(root) NOPASSWD: /usr/bin/rsync, /usr/bin/sha256sum, /usr/bin/find, /usr/bin/du" > /etc/sudoers.d/evac && chmod 440 /etc/sudoers.d/evac'
   ```
   Harmless to leave: [05](05-wipe-and-rebuild-nas.md) wipes it with the rest of DSM.
3. **Empty both USB HDDs** (done from Windows, 2026-10-04) — anything on them that
   matters goes elsewhere first.
4. **SMART long test on both USB HDDs, before formatting** — for the wipe window
   they *are* the data, and a disk with pending or reallocated sectors doesn't get
   used. ~4–5 h (the 1 TB is quicker); both can run at once:
   ```
   nix shell nixpkgs#smartmontools
   sudo "$(command -v smartctl)" -d sat -t long /dev/disk/by-id/usb-<id>   # once per disk
   sudo "$(command -v smartctl)" -d sat -a /dev/disk/by-id/usb-<id>        # result
   ```
   Pass = `PASSED`, `Reallocated_Sector_Ct` / `Current_Pending_Sector` /
   `Offline_Uncorrectable` all 0, self-test log *Completed without error*.
   **Skipped for A (Walter's call, 2026-10-04)** — to be run later. Copies C and D
   are the trusted ones; A's integrity rests on `sha256sum -c` against the manifest.
5. **Format.**
   - **B (Seagate, NTFS):** formatted **in Windows** — Explorer → right-click →
     Format → NTFS, *Quick Format*, volume label `evac-b`. Windows' own formatter is
     the most trustworthy NTFS writer there is.
   - **A (WD, ext4):** on `main-pc` with the guard script, which refuses anything
     that isn't a ≤2.2 TB USB disk and asks for the serial:
     `sudo nas/evac/format-evac-disk.sh a /dev/disk/by-id/usb-…-part1`
6. **Mount.**
   - A: `udisksctl mount -b /dev/disk/by-label/evac-a`, then
     `sudo chown rennsemml: /run/media/rennsemml/evac-a`.
   - B, **always via ntfs-3g, never by clicking it** (that picks the kernel `ntfs3` driver):
     ```
     sudo mkdir -p /mnt/evac-b
     sudo "$(nix build --no-link --print-out-paths 'nixpkgs#ntfs3g.out')/bin/ntfs-3g" \
       -o windows_names,uid=1000,gid=100 /dev/disk/by-label/evac-b /mnt/evac-b
     ```

**B and Windows (dual boot).** Windows *Fast Startup* leaves a connected NTFS disk
half-hibernated, and Linux must not write to it then — ntfs-3g refuses, so it
fails safe, but the copy stalls. In Windows, only read from B and **eject it before
shutting down** (or turn Fast Startup off).

### Step 1 — Inventory (agent)

`sudo du -sh /volume1/*` and per-share file counts over SSH, written into a
**Inventory** section at the bottom of this ticket. The scope is a **denylist**:
take everything except confirmed-disposable. An allowlist is how `/volume1/photo`
came to be missing from every ticket in this repo.

- Synology Photos **personal** space → `homes/<user>/Photo`. **Anja's must be in it.**
- Synology Photos **shared** space → **`photo`** ← the one that was missed
- Look inside `#recycle` and take it — deleted-by-accident photos live there.
- Always excluded: `@eaDir` (DSM thumbnails — hundreds of thousands of junk files),
  `#snapshot`, `@`-prefixed system dirs at the volume root.
- Confirmed disposable: `PlexMediaServer/*` (including `Photos`, which is artwork).
  No music on the NAS.

**Gate:** the smallest copy target is B at 1 TB (~930 G usable). If the
irreplaceable total exceeds **~850 G**, it doesn't fit there with headroom. Stop
and re-plan before copying anything.

### Step 2 — Manifest on the NAS (agent, ~1–2 h unattended)

```
cd /volume1 && sudo find <sources> -type f ! -path '*/@eaDir/*' ! -path '*/#snapshot/*' -print0 \
  | sort -z | xargs -0 sudo sha256sum > /tmp/evac-manifest.sha256
```

Pulled to `main-pc` and stored next to each copy. The J4025 has SHA extensions,
so this is disk-bound, not CPU-bound. Paths are relative to `/volume1`, so the same
manifest checks every copy with `sha256sum -c`.

### Step 3 — Pull the copies (agent, ~3 h each at gigabit)

**Run as Walter, not root (found 2026-10-04).** Synology's patched rsync refuses
root outright (`ERROR: user has disabled/expired`, code 44), and refuses everyone
until DSM → File Services → **rsync service is enabled** and Walter has the rsync
application privilege. Walter can read every source except
`docker/alexandria/config/suwayomi/cache` (disposable, excluded). So: no
`--rsync-path='sudo rsync'`; add `--exclude='/docker/alexandria/config/suwayomi/cache/'`,
and drop that path from the manifest before `sha256sum -c`.

Run **one at a time** — parallel pulls just split the same gigabit link and the
same three spindles.

```
rsync -rlt --partial --info=progress2 -s \
  --exclude='@eaDir/' --exclude='#snapshot/' --exclude='/docker/alexandria/config/suwayomi/cache/' \
  alexandria:/volume1/<source> /run/media/rennsemml/evac-a/     # B: /mnt/evac-b/
```

`-t` keeps mtimes (Immich falls back to them when EXIF is missing). Ownership and
ACLs are deliberately not carried — Immich assigns ownership by account at import.
`--partial` plus an idempotent re-run means an interrupted copy just resumes.

Order: **C → A → B.** (C first was chosen to feed the Drive upload, now deferred.)

### Step 4 — Verify every copy (agent)

On each copy:

- `sha256sum -c --quiet evac-manifest.sha256` → **zero** failures, zero missing
- file count per source == the NAS count from step 1
- **One file nobody chose**: open a random sample of ~20 photos/videos across years,
  including at least one with an umlaut in its path, and check it renders and the
  date looks right

Then **unplug B and put it in a different room.** From here on it is only
reconnected for the final delta.

### Step 5 — Freeze and final delta (you + agent, right before [05](05-wipe-and-rebuild-nas.md))

The NAS stays in use while 01–02 run over several days, so anything added in that
window would be in no copy. Immediately before the wipe:

1. **You:** turn off Synology Photos backup in the app on **both phones** (photos
   stay on the phones — don't free phone storage until Immich is live), and set
   every source share to read-only in DSM.
2. **Agent:** regenerate the manifest, re-run step 3 into A, B and C (rsync only
   moves the difference), re-run step 4. (No Drive delta — 02 is deferred.)

[05](05-wipe-and-rebuild-nas.md) starts only from a freeze whose final delta has
verified green — not from the first pass.

## What a file copy cannot carry

Synology Photos keeps **albums, person names and shared links in its database**,
not in the files. They will not survive the move. Before the wipe, list (or
screenshot) the albums worth recreating in Immich — or decide explicitly to let
them go.

**Blocked by:** None — start here.

**Status:** done 2026-10-05 — 05 unblocked. B was never used (optional). Open tail: SMART long test on A (running), then the WD goes to another room.

- [x] NAS data scrub clean; SMART quick test passes on all three NAS disks — 2026-10-04
- [ ] SSH key + `/etc/sudoers.d/evac` on the NAS; agent can `ssh -o BatchMode=yes alexandria sudo -n du -sh /volume1/*` without a prompt
- [ ] Both USB HDDs emptied; **SMART long test passes on both**; A formatted ext4 (`evac-a`, guard script), B formatted NTFS in Windows (`evac-b`)
- [ ] Inventory recorded below; every non-disposable path identified, including `photo`, every user under `homes`, and `#recycle`; total ≤ ~1.7 TB
- [x] SHA-256 manifest generated **on the NAS**, stored with every copy — 2026-10-04, 0 read errors; `~/evac-manifest.full.sha256` is the raw one
- [x] Copy A: `sha256sum -c` clean, per-source file counts match — 2026-10-04, same 64,849 files as C; SMART long test still to run (deferred by choice)
- [ ] Copy B: `sha256sum -c` clean, per-source file counts match, any `windows_names` rejects listed and resolved — then **unplugged, other room**
- [x] Copy C (`main-pc`): everything, `sha256sum -c` clean — 2026-10-04, 64,849 files. Manifest (64,877 on NAS) minus 25 suwayomi cache + 3 calibre qtshadercache files Walter can't read; both disposable
- [x] Random sample opened by a human: renders, umlauts intact, dates sane — Walter, 2026-10-05
- [x] Synology Photos albums worth keeping listed — or explicitly let go — Walter, 2026-10-05
- [x] **Freeze:** phone backup off, shares read-only; final delta to A/C (and B, if added) verified green — *this box is ticked last, immediately before [05](05-wipe-and-rebuild-nas.md)* — 2026-10-05: C fully re-verified; A got the delta but no full re-hash (Walter's call — A was verified clean on 10-04 and no NAS content changed since)

## Progress log

**2026-10-04/05.** Manifest hashed on the NAS (64,877 files, 0 read errors). Copies
C (`~/evac/`) and A (WD, `evac-a`) pulled as Walter and `sha256sum -c` clean
against `evac-manifest.sha256` (64,849 files — the full NAS manifest minus the 25 suwayomi-cache
and 3 unreadable calibre qtshadercache files; raw manifest kept as
`evac-manifest.full.sha256`). Both manifests sit at the root of each copy and in
`~`. rsync/verify logs: `~/evac-{c,a}.log`, `~/evac-{c,a}-verify.log`. One file
is newer than the manifest (`homes/Anja/…/WhatsApp Images/2026/10/IMG_20261004_163036.jpg`)
— the freeze delta covers it. Dates spot-checked by the agent (mtimes match
filenames, umlaut paths intact).

**Open:**
- **SMART long test on A** — first run came back `Interrupted (host reset)` at 90%
  remaining; attributes clean (0 reallocated/pending/uncorrectable, 0 CRC, 1,362 h).
  Not autosuspend (`power/control` = `on`), nothing in the kernel log — most likely
  the WD's USB bridge resetting when idle. Retry: unmount `evac-a` (stay powered —
  no `power-off`), `smartctl -d sat -t long /dev/sda`, keep a loop querying
  `smartctl -c` every 120 s so the bridge stays awake; result into `~/smart-wd.txt`.
- ~~Human spot check~~, ~~albums~~ — done by Walter 2026-10-05.

**2026-10-05.** Freeze done by Walter (phone backup off, shares read-only).
SMART long-test retry on A running (Walter). Final delta: manifest regenerated on the
NAS as `/tmp/evac-manifest2.sha256`; delta into C pulled — 4 new files from Anja's
Pixel 7a (`DCIM/Camera/2026/10/…` ×3, `WhatsApp/2026/10/…` ×1), log
`~/evac-c-delta.log`. A's delta waits for its SMART test to finish.

Freeze manifest finished 10:03, 0 read errors: **64,834** files (`~/evac-manifest2.full.sha256`;
filtered as before → `~/evac-manifest2.sha256`, 64,806). Against the first manifest:
5 new (above, plus `WhatsApp Images/2026/10/IMG_20261004_163036.jpg`, already in C), **no
content changes**, and **48 files gone** — all Anja's Pixel 7a, Jul–Sep 2026
(`DCIM/Camera`, `Screenshots`, `WhatsApp Images`), not moved anywhere on the NAS, so
deleted outright — by Anja, on purpose (Walter, 2026-10-05). All 48 are still in C and A (rsync never deletes); harmless leftovers. C verified
against the freeze manifest: `sha256sum -c` clean, per-source counts match
(`homes` has the 48 extras). Log `~/evac-c-delta-verify.log`; both manifests copied into `~/evac/`.

A: same 4-file delta pulled (`~/evac-a-delta.log`), both manifests copied to its root.
The full re-hash of A was stopped by Walter's call — the 4 new files are not worth a
541 G read; A's first-pass verification stands. **01 closed; 05 unblocked.**

## Inventory

Taken 2026-10-04 over SSH (`du -sh --exclude=@eaDir`, `find -type f | wc -l`).

| Share | Size | Files | Take? |
|---|---|---|---|
| `homes/Walter/Photos` | 134 G | | ✅ Synology Photos personal space |
| `homes/Anja/Photos` | 278 G | | ✅ Synology Photos personal space |
| `homes` total | 411 G | 57,065 | ✅ |
| `Walter` | 32 G | | ✅ — its 379 G `#recycle` was emptied by Walter on 2026-10-04 |
| `Anja` | 62 G | 5,342 | ✅ — 18 G `#recycle` |
| `docker` | 271 M | 1,232 | ✅ (`alexandria/books` + config) |
| `PlexMediaServer` | 471 G | | ❌ disposable |
| `@docker`, `@appstore`, other `@*`, `*.core.gz` | ~53 G | | ❌ DSM system / crash dumps |
| `@database` | 1.9 G | | ⬜ Synology Photos' DB — a raw copy of a live DB, only "just in case" for albums |

**Irreplaceable total ≈ 541 G** (after the recycle-bin purge) — fits every target, including the 1 TB disk B. File count
is low enough that Drive's per-file rate limit is not a concern. For contrast, `@eaDir`
holds **303,165** thumbnail files — 4× the real data, all excluded.

**There is no `/volume1/photo` share** — the Synology Photos shared space was never
used. Photos live in `homes/<user>/Photos` (plural).

**Copy C holds everything:** 541 G of 726 G free on `main-pc`, leaving ~185 G.

`Anja/#recycle` (18 G) is still there and is taken — it's Anja's to decide.

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--fourth-pass-2026-10-04)._
