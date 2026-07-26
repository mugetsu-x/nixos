# 05 — Backup strategy: 3-2-1 topology and offsite target for the photos

Parent: [map](../map.md)
Type: grilling
Status: resolved
Blocked by: —

## Question

The highest-stakes decision in the map: ~950 GB of **irreplaceable family
photos** currently exist as a single copy on the NAS's RAID 5 array. RAID is not
a backup. `nas/PLAN.md` even flags that its phase-0 array expansion runs degraded
and wants the photos backed up off the NAS *first* — so this is also a near-term
blocker, not just future architecture.

Decide the **3-2-1 topology**:

- **Second on-site copy:** where does copy #2 live? (External USB disk on the NAS?
  The laptop's disks? A second machine?) The laptop-as-target option references
  the keystone (03) but the *principle* — that a second local copy must exist —
  can be settled now.
- **Offsite copy #3:** cloud (Backblaze B2 / Storj / rsync.net) vs. a physical
  disk rotated to another location. What budget, and encrypted how?
- **Tooling & scope:** what runs the backups (Synology Hyper Backup, restic,
  borg, Syncthing?), how often, versioned/immutable against ransomware, and
  which datasets beyond photos are included.
- **Restore test:** how you'll verify a restore actually works.

Resolution names the topology, the tools, the offsite target, and an immediate
"get the photos to a second copy before any risky NAS operation" step.

## Answer

Resolved 2026-07-26 via `/grilling`. A tiered **3-2-1** topology built around the
keystone (03) always-on ThinkBook as backup orchestrator, and reconciled with the
Immich decision (06), which lands the same day and shares 05's off-array gate.

### 1. Scope — tiered

- **Photos (~950 GB) → full 3-2-1.** The irreplaceable crown jewels.
- **Media (~471 GB movies/TV) → excluded.** Re-downloadable via the usenet
  pipeline; RAID + btrfs snapshots suffice. Backing it up would dominate offsite
  cost for zero irreplaceability.
- **Laptop irreplaceable app-state → included, lighter tier.** App databases and
  non-reproducible config that don't rebuild from the flake (Immich Postgres +
  face/album metadata; file-sync data from 07 if it becomes source-of-record).
  The OS itself rebuilds from git → no backup needed.

### 2. Topology — laptop-orchestrated 3-2-1

- **Copy #1 (primary):** the NAS RAID 5 array (btrfs, snapshotted). *Post-Immich,
  the photo source-of-record is Immich's managed library on the NAS* (06), not the
  raw `homes`/`Walter`/`Anja` shares.
- **Copy #2 (on-site):** a **dedicated 4 TB external USB HDD on the ThinkBook**
  (already in hand), which **pulls from the NAS** nightly. A separate device from
  the NAS (satisfies the "2" of 3-2-1) and a dedicated disk (not the laptop OS/app
  NVMe), so a full laptop-disk failure doesn't also cost the backup. Pull-from-a-
  separate-box beats NAS-push for ransomware resistance. Same room/power as the NAS
  is fine — surviving fire/theft is copy #3's job.
- **Copy #3 (offsite):** **Hetzner Storage Box**, client-side encrypted. Sized to
  the **5 TB BX21 (~€11.90/mo, ~€143/yr)** for years of headroom (photos are
  already ~950 GB; a 1 TB box would fill instantly with versioned history).
  European (EU residency, low latency), speaks restic/borg/rsync/sftp. Rejected:
  Backblaze B2 (fine, pricier, non-EU) and physical-disk rotation (€0 recurring but
  depends on human discipline + a second location — unacceptable for the *primary*
  offsite of irreplaceable data).

### 3. Tooling — restic, declarative

- **restic**, driven by the NixOS **`services.restic.backups`** module on the
  `home-server` flake host. One tool, both destinations: two backups from the same
  NAS source → local USB repo (copy #2) and Hetzner sftp repo (copy #3). Dedup +
  client-side encryption; version-controlled and CI-checked like the rest of the
  flake. Rejected: Synology Hyper Backup (NAS-push, splits orchestration off the
  chosen laptop-pull model); Syncthing (sync, not backup — no real versioning,
  propagates deletes).
- **Databases are dumped, not file-snapshotted.** Immich/Nextcloud Postgres get a
  `pg_dump` (or Immich's built-in DB backup) into a staging dir first; restic backs
  up the dump. Plain photo files have no such issue.

### 4. Cadence, retention, immutability

- **Nightly** restic run to both repos (systemd timer from the module); photos are
  near-append-only, so nightly is ample.
- **Retention:** `--keep-daily 7 --keep-weekly 8 --keep-monthly 12 --keep-yearly 5`.
  Dedup makes long history nearly free and guards against silently
  corrupted/deleted photos noticed months later. **Prune weekly**, as a separate,
  deliberate, logged op (the one dangerous space-reclaiming step).
- **Ransomware/immutability backstop: Hetzner Storage Box snapshots.** Storage-layer
  snapshots the sftp/restic user *cannot* delete — so even a fully-compromised
  laptop that nukes the repo can't destroy the offsite; you roll the Storage Box
  back. This keeps the restic+Hetzner design while giving real immutability, no need
  for borg append-only or B2 Object Lock.

### 5. Immediate step (near-term blocker — PLAN.md phase 0 + 06's hard gate)

The phase-0 array expansion runs **degraded**; both it and the Immich import are
gated (06 step 1) on ≥1 copy of the 950 GB living **off** the NAS first.

- **Do it now, as restic, from `main-pc`.** `restic init` on the 4 TB USB (in hand
  — no purchase) + a first snapshot of today's raw `homes`/`Walter`/`Anja` shares,
  run by hand from `main-pc` (already NixOS, tools ready, can mount the NAS today).
  This is **not a throwaway**: when the `home-server` host comes up, its
  `services.restic.backups` job *continues the same repo* — the manual snapshot is
  copy #2's first snapshot.
- **This one off-box copy clears phase-0.** The degraded-array danger is a
  hardware-failure risk, covered by a single independent copy. Do **not** block the
  expansion on the Hetzner upload (~950 GB over a home uplink can take days — run it
  in parallel/after, off the critical path).
- **Sequence:** `restic init` + first snapshot from main-pc → phase-0 expansion →
  Immich CLI import (06) → stand up `home-server` (adopts the USB repo, adds Hetzner
  offsite) → **only then** 06's reclaim (delete old shares) once 05's copies cover
  the *Immich managed library* + Immich DB backups run.

### 6. Restore test

- **Automated monthly:** systemd timer runs `restic check --read-data-subset=5%` on
  both repos (verifies a rotating slice of real data blocks) + a sample restore of a
  few random files to scratch with hash comparison. Failure fires a notification.
- **One real drill at setup:** after the offsite is seeded, restore ~10 GB of photos
  from **Hetzner** to a clean location and actually open them — proving the offsite
  path, keys, and recovery without the original machine.
- **Off-box keys:** the restic repo password/keys live **independent of the laptop**
  (password manager + a printed copy). A restore after losing the laptop is
  worthless if the key only lived on the laptop — the most common real-world backup
  failure.

**Coupling recorded:** 05 is the explicit gate for 06's reclaim step, and 05's
immediate copy *is* 06's migration step 1. No formal `Blocked by` edge either way —
both are planning tickets whose *decisions* need nothing from each other; only their
*execution* is sequenced. No new tickets or fog surfaced; the "laptop app-state"
scope tier will be finalised by 07's data-location choice but needs no separate
ticket (05 covers it generically).

---

## Amendment — second pass (2026-07-26)

The **topology** (laptop-orchestrated 3-2-1), the **tool** (restic via
`services.restic.backups`), the **cadence and retention** (nightly,
7d/8w/12m/5y, weekly prune) and the **restore-test regime** all stand. Four things
change, one of which is a genuine gap in the original answer.

### 1. Offsite copy #3: Google Drive, not Hetzner

**The original comparison had a blind spot.** It weighed Hetzner Storage Box
against Backblaze B2 and physical-disk rotation, and **never considered storage
already owned.** The user has Google Workspace **Business Plus — 5 TB pooled, free
and unused.** Hetzner was a genuine new €143/yr for capability already paid for.

| | Hetzner Storage Box | **Google Drive (chosen)** |
|---|---|---|
| Cost | €143/yr | already paid |
| restic support | native sftp | via the **rclone** backend — works, second-class |
| Seeding ~950 GB | uplink-bound | uplink-bound **and** capped at **750 GB/day per user** |
| `check` / `prune` | fine | slow: lists ~60k objects through a paginated, rate-limited API |
| Immutability | server-side snapshots the client can't delete | 30-day trash **+ Google Vault** retention (included in Business Plus) |
| Quota | dedicated | **pooled with Gmail and Drive** |

**Mandatory conditions** — the decision is only sound with all of these:

- **Own OAuth client ID for rclone.** The shared default is rate-limited into
  uselessness. Non-negotiable.
- **`--pack-size 64`** (restic default is 16 MiB), cutting object count ~4×. This
  is what makes `check` and `prune` tolerable against Drive's API.
- **Hard retention ceiling + an alert on Workspace pool usage.** This is the one
  failure mode Hetzner did not have: if the repo's history grows into the pool,
  **Gmail stops receiving mail.** Coupling the thing that protects the photos to
  the thing that runs the email is the sharpest trade-off in this switch.
- **Drive proper, not Google Photos** — that API is no longer usable for this.
- **Verify Google Vault's Drive retention behaviour before relying on it** as the
  immutability backstop.

**Why the weaker immutability is acceptable here:** the original answer chose
Hetzner snapshots as a *ransomware* backstop. The realistic threats to this estate
are `rm -rf`, a mistaken `prune`, hardware failure, fire and theft — not ransomware
on a headless NixOS box with no inbound ports behind a Tailscale-only overlay.
Drive's 30-day trash covers the accident cases, and Vault covers the rest.
**It is copy #3**: copies #1 and #2 exist independently, so the blast radius of
Drive underperforming is bounded, and restic repos are portable — moving to Hetzner
later is an `rclone` job, not a redesign. Hetzner stays documented as the fallback.

### 2. Scope becomes a denylist, not an allowlist

The original scope named three shares: `homes`, `Walter`, `Anja`. Review found a
fourth photo location that appears in **no ticket in this repo** —
**`/volume1/photo`**, Synology Photos' *shared space* (personal space lives under
`homes/<user>/Photo`, which was covered).

**Snapshot everything under `/volume1` except confirmed-disposable media**
(`PlexMediaServer/*`). restic dedups and compresses, so over-including costs
almost nothing — while an enumerated allowlist is *precisely* how `/volume1/photo`
came to be missing. Run `du -sh /volume1/*` before anything is deleted.

Confirmed disposable by the user: all Plex data including `PlexMediaServer/Photos`
(artwork, not family pictures). There is no music on the NAS.

### 3. The immediate step is now an evacuation, and it is bigger

The NAS is being **wiped and rebuilt** (see
[08](08-media-relocation-and-plan-consolidation.md#answer--second-pass-2026-07-26)),
not expanded in place. So the "get one copy off the box" step becomes a full
evacuation, and the sequencing gets stricter:

1. **restic repo on USB #1** from `main-pc` — this repo *is* backup copy #2 later,
   exactly as originally intended.
2. **An independent plain-file copy on USB #2** — deliberately a *different tool*,
   so a restic-format problem cannot cost you both copies. Both drives ≥2 TB and
   wipeable; **SMART-check both first** — for the duration of the wipe they *are*
   the data.
3. **Seed Google Drive before the wipe, not after.** At 750 GB/day this is ≥2 days
   unattended. It is what keeps you at **three copies during the one window where
   both on-site copies are unplugged USB disks in the same room.** This is the
   condition to hold firmest.
4. **Only then** wipe and rebuild the array.

The old sequence's "reclaim after verification" step **disappears** — Immich
imports from USB into a clean empty library, so there is never a double copy on the
array and nothing to reclaim.

### 4. The tiered scope shifts with the services

- **NAS application state is no longer a concern** — the NAS runs zero containers
  after the rebuild, so there is no arr/Jellyfin/Plex state on it to protect. (This
  was a real gap in the first-pass architecture, where those apps lived on the NAS
  and fell into no tier; the relocation resolved it by accident.)
- **Laptop app-state grows correspondingly** and is now the whole application
  layer: Immich Postgres, Jellyfin metadata + watch history + users, and the arr
  databases (quality profiles, indexer config, monitored series). None of it
  rebuilds from the flake, and it represents real accumulated curation. `pg_dump`
  first, then restic — same lighter tier, more in it.
- **Media stays excluded.** Re-downloadable, and the array is a rotating pool.

### 5. Mandatory: a mount guard

With every service on the laptop and all bulk data behind one NFS mount, the
destructive failure mode is **restic snapshotting an unmounted mountpoint** —
writing a near-empty snapshot, after which `forget --prune` ages out the real
history on schedule. That is how people delete their own backups.

The backup job must verify the mount is live and **abort loudly** rather than
snapshot an empty tree. Paired with `hard` NFS mounts, `x-systemd.automount`, and
`RequiresMountsFor=` ordering on the containers.

### 6. Restic hygiene carried over from the one-shot

The evacuation snapshot is taken from `main-pc`; the ongoing service runs on
`home-server` against the same repo. restic's `forget` groups snapshots by
**host + paths**, so a differing hostname or mount path would silently place your
first and most precious snapshot in a *separate retention lineage* from the policy
meant to protect it. **Pin `--host` and use an identical mount path in both.**
