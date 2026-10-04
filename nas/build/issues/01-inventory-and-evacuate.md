# 01 — Inventory `/volume1` and evacuate it (two USB HDDs + `main-pc`)

**What to build:** Every irreplaceable file on the NAS copied **off** it, as plain
file trees, onto **HDD A, HDD B** and (photos at minimum) **`main-pc`'s NVMe** —
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
| **A** | USB HDD, 2 TB, **ext4**, label `evac-a` | everything irreplaceable | cold copy; source for the Drive upload ([02](02-seed-google-drive-offsite.md)) |
| **B** | USB HDD, 2 TB, **NTFS**, label `evac-b` | everything irreplaceable | cold copy, **unplugged and stored in another room** once verified |
| **C** | `main-pc` NVMe, `~/evac/` (~726 GB free) | all photo sources; everything if it fits with ≥100 GB to spare | warm copy on a different medium (SSD, not USB HDD); fast source for [10](10-import-photos.md) |
| **D** | Google Drive, `rclone crypt` | everything irreplaceable | offsite — [02](02-seed-google-drive-offsite.md) |

Four copies on three media types, one offsite, before a byte is destroyed.

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
3. **Confirm both USB HDDs hold nothing you need**, then format them (destroys
   their contents):
   ```
   sudo mkfs.ext4 -L evac-a -m 0 /dev/sdX1                      # disk A — check with lsblk first
   nix shell nixpkgs#ntfs3g
   sudo "$(command -v mkntfs)" -Q -L evac-b /dev/sdY1            # disk B
   ```
   A: `udisksctl mount -b /dev/disk/by-label/evac-a`, then
   `sudo chown rennsemml: /run/media/rennsemml/evac-a`.
   B: `sudo mkdir -p /mnt/evac-b && sudo "$(command -v ntfs-3g)" -o windows_names,uid=1000,gid=100 /dev/disk/by-label/evac-b /mnt/evac-b`.
4. **SMART long test on both USB HDDs** —
   `sudo nix run nixpkgs#smartmontools -- -t long -d sat /dev/sdX` (~4–5 h, both can
   run at once). For the wipe window they *are* the data; a disk with pending or
   reallocated sectors doesn't get used.

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

**Gate:** if the irreplaceable total exceeds **~1.7 TB**, it doesn't fit on one
2 TB disk with headroom. Stop and re-plan before copying anything.

### Step 2 — Manifest on the NAS (agent, ~1–2 h unattended)

```
cd /volume1 && sudo find <sources> -type f ! -path '*/@eaDir/*' ! -path '*/#snapshot/*' -print0 \
  | sort -z | xargs -0 sudo sha256sum > /tmp/evac-manifest.sha256
```

Pulled to `main-pc` and stored next to each copy. The J4025 has SHA extensions,
so this is disk-bound, not CPU-bound. Paths are relative to `/volume1`, so the same
manifest checks every copy with `sha256sum -c`.

### Step 3 — Pull the copies (agent, ~3 h each at gigabit)

Run **one at a time** — parallel pulls just split the same gigabit link and the
same three spindles.

```
rsync -rlt --partial --info=progress2 -s --rsync-path='sudo rsync' \
  --exclude='@eaDir/' --exclude='#snapshot/' \
  alexandria:/volume1/<source> /run/media/rennsemml/evac-a/     # B: /mnt/evac-b/
```

`-t` keeps mtimes (Immich falls back to them when EXIF is missing). Ownership and
ACLs are deliberately not carried — Immich assigns ownership by account at import.
`--partial` plus an idempotent re-run means an interrupted copy just resumes.

Order: **A → B → C**. C is photo sources first, then the rest while space allows.

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
   moves the difference), re-run step 4, and push the delta to Drive ([02](02-seed-google-drive-offsite.md)).

[05](05-wipe-and-rebuild-nas.md) starts only from a freeze whose final delta has
verified green — not from the first pass.

## What a file copy cannot carry

Synology Photos keeps **albums, person names and shared links in its database**,
not in the files. They will not survive the move. Before the wipe, list (or
screenshot) the albums worth recreating in Immich — or decide explicitly to let
them go.

**Blocked by:** None — start here.

**Status:** ready-for-agent (after step 0)

- [ ] NAS data scrub clean; SMART quick test passes on all three NAS disks
- [ ] SSH key + `/etc/sudoers.d/evac` on the NAS; agent can `ssh -o BatchMode=yes alexandria sudo -n du -sh /volume1/*` without a prompt
- [ ] Both USB HDDs confirmed empty, formatted (`evac-a` ext4, `evac-b` NTFS via ntfs-3g), **SMART long test passes on both**
- [ ] Inventory recorded below; every non-disposable path identified, including `photo`, every user under `homes`, and `#recycle`; total ≤ ~1.7 TB
- [ ] SHA-256 manifest generated **on the NAS**, stored with every copy
- [ ] Copy A: `sha256sum -c` clean, per-source file counts match
- [ ] Copy B: `sha256sum -c` clean, per-source file counts match, any `windows_names` rejects listed and resolved — then **unplugged, other room**
- [ ] Copy C (`main-pc`): all photo sources at minimum, `sha256sum -c` clean
- [ ] Random sample opened by a human: renders, umlauts intact, dates sane
- [ ] Synology Photos albums worth keeping listed — or explicitly let go
- [ ] **Freeze:** phone backup off, shares read-only; final delta to A/B/C/Drive verified green — *this box is ticked last, immediately before [05](05-wipe-and-rebuild-nas.md)*

## Inventory

_Filled in by step 1._

_Decision detail: [05](../../issues/05-backup-topology.md#amendment--fourth-pass-2026-10-04)._
