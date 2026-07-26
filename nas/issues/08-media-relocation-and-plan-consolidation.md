# 08 — Media stack: what (if anything) relocates, and fold PLAN.md into the map

Parent: [map](../map.md)
Type: grilling
Status: **re-resolved** (first answer superseded 2026-07-26, second pass)
Blocked by: —

> ⚠️ **The first answer below is wrong and is kept only for the decision trail.**
> Both of its load-bearing premises were factually false. The binding resolution is
> [Answer — second pass](#answer--second-pass-2026-07-26) at the bottom.

## Question

The keystone (03) division-of-labour principle keeps the **media pipeline on the
NAS** as a storage-adjacent service (the arr stack is light; the data lives on
the NAS array; the Shield direct-plays so transcode rarely fires). This ticket
confirms that against the one real pull toward the laptop and then consolidates
the plan:

1. **Does Jellyfin/transcoding relocate to the laptop's RTX 3060?** From 01 the
   3060 does HEVC/H.264 encode (no AV1) — better than the Celeron's QuickSync,
   but the Shield direct-plays most content so transcode is rare. Decide: keep
   transcoding on the NAS (simpler, data-local) vs. move Jellyfin to the laptop
   to use the GPU. Default per the principle: **stays on the NAS**; justify any
   exception (e.g. lots of remote/off-Shield playback that forces transcode).

2. **Any arr component relocate?** Almost certainly no — the stack is light and
   wants to sit next to its storage. Confirm the whole pipeline stays on the NAS.

3. **Consolidate `PLAN.md` into this map.** Per the map's Notes: once 03 resolved,
   fold `PLAN.md`'s media detail (usenet, hardlink layout, phase-0 hardware,
   shopping list, access notes) into this map as its *media* section — merging
   the **final, laptop-aware** media decision, not the old laptop-blind one. This
   ticket produces that consolidated media section (or decides to keep `PLAN.md`
   standalone and just link it, if that reads cleaner).

Resolution names what stays vs. moves and delivers the consolidated media plan.

## Answer — first pass (SUPERSEDED)

Grilled the media decisions against the post-keystone architecture. The user
reopened more than the ticket's original scope — PLAN.md's *quality* decision too —
because "so much new information" (laptop, Tailscale, Immich 06, backups 05) had
accumulated. Triaged: some PLAN.md decisions rest on premises that genuinely
changed (placement, quality) and were re-grilled; the true internals (usenet vs.
torrents, provider choice) were untouched by any new fact and left settled.

**1. Does the media server / transcoding relocate to the laptop's RTX 3060? — NO.**
The decision hinged entirely on one variable: *does transcode fire routinely?* The
user first wanted remote phone playback (which, against 4K sources, forces heavy
transcode and pulled Jellyfin toward the GPU), then chose to **restrict playback to
same-network** to keep things simple. Same-network ⇒ direct-play dominates (Shield +
capable LAN devices decode 4K HEVC) ⇒ **data-locality wins**, so Jellyfin stays on
the NAS next to its data, co-located with the arr stack. Remote viewing is
**best-effort over Tailscale**; the RTX 3060 is the **documented escape hatch** —
the *only* trigger to move Jellyfin to the laptop is remote transcode becoming
routine. The rare same-network browser transcode runs on the Celeron QuickSync;
Shield direct-plays 4K HEVC natively.

**2. Does any arr component relocate? — NO.** The old "must be awake at 03:00"
reason is dead (the laptop is also 24/7), so placement now rests on **hardlink
locality**: Radarr imports by hardlinking `usenet/complete` → `media/` within the
single btrfs share; run over NFS from the laptop and the arr apps fall back to full
copies. Zero compute upside, and it's exactly the "light storage-adjacent service"
the keystone (03) left on the NAS.

**Bonus decision — quality (PLAN.md's "1080p default" broke):** the home theater is
4K. Chose **4K for both films and TV**, made safe by 05 (media is re-downloadable,
excluded from backup). The array is therefore a **rotating pool, not an archive** —
curate/delete first when it fills (re-downloads on demand); disk upgrades
(2→4→8 TB) are for real keep-set growth, not to avoid deleting.

**3. Consolidation.** PLAN.md is **kept standalone and updated laptop-aware** (not
folded into the map — the map is a decision *index*; PLAN.md is the execution
runbook). Additionally, per the destination ("a written architecture plan"),
assembled the whole-home capstone **[`ARCHITECTURE.md`](../ARCHITECTURE.md)** from
all 8 tickets: the workload→machine division, backup topology, and remote-access
approach, in one readable doc.

Assets: [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (new), [`../PLAN.md`](../PLAN.md)
(updated). With this ticket closed the map has no open frontier and the
destination is reached.

---

## Answer — second pass (2026-07-26)

Re-grilled after review found **both** load-bearing premises of the first answer
to be false. The corrections cascaded well beyond this ticket's original scope.

### The two false premises

**1. "Run the arr apps over NFS from the laptop and they fall back to full
copies." — False.** NFSv3 and NFSv4 both implement the `LINK` operation; a
hardlink created on an NFS mount is created **server-side** on the NAS's btrfs.
What actually breaks hardlink imports is having downloads and library on
*different mounts*, or *inconsistent path mappings between containers* — neither
of which is a property of NFS, and both of which the single-share layout already
prevents. The entire stated justification for keeping the arr stack on the NAS
therefore rested on nothing. (The reason it *replaced* — "must be awake at 03:00"
— was already dead, so the decision had no surviving support at all.)

**2. "The rare same-network browser transcode runs on the Celeron's QuickSync." —
Effectively false.** Two compounding facts:

- **Plex cannot hardware-transcode without a Plex Pass**, which we do not have. So
  Plex — the designated safety net — was software-transcoding on two Celeron
  cores, i.e. unable to serve 4K at all.
- **Gemini Lake's UHD 600 cannot tone-map 4K HDR→SDR in real time.** Practically
  all 4K sources are HDR and practically all non-Shield clients are SDR, so the
  "rare exception" was neither rare nor handled. Those clients did not get a slow
  stream; they got a broken one.

The RTX 3060 was documented as an *escape hatch* to be pulled only if remote
viewing became routine. The real trigger was far lower: **any client that isn't
the Shield.**

### Decisions

**1. Jellyfin → laptop.** Phones and browsers must work; that requires NVENC and
GPU tone mapping. The escape hatch becomes the design.

**2. SABnzbd + Prowlarr + Radarr + Sonarr → laptop**, as `oci-containers` in this
flake. `incomplete/` on local NVMe, `complete/` on the NFS share beside `media/`
so hardlink imports still work.

**Important — the speed argument is NOT the justification.** At the user's actual
line speed (170–250 Mbps), a 60 GB 4K release costs roughly:

| | NAS (J4025) | Laptop (5900HX) |
|---|---|---|
| Download @250 Mbps | ~32 min (line-bound) | ~32 min (line-bound) |
| par2 verify | ~10–17 min | ~2 min |
| unrar (store-mode) | ~7–10 min | ~1–2 min |
| **Total** | **~55 min** | **~37 min** |

~20 minutes, in a workflow where nobody watches the progress bar. And moving
Jellyfin off had already freed the RAM that was the other pressure. **The move is
justified by the clean boundary — the NAS runs zero containers, everything is
declarative and rolled back with the flake — not by performance.** Recorded
explicitly so it is not "optimised" back later on the wrong grounds.

**3. Jellyseerr → laptop**, following Jellyfin.

**4. Plex is retired outright.** The first pass kept it as a proving-window safety
net. That does not work: `build/05` deletes its library before `build/07` proves a
single grab, so it would have been a fallback with nothing in it — and without a
Pass it could never serve the clients that motivated the change. Jellyfin is
proven instead against **open-licence 4K HDR test files** before any usenet account
exists, which tests NFS reads, NVENC tone mapping and Shield direct-play at the
point where fixing them is cheapest.

**5. The NAS becomes pure storage.** Container Manager uninstalled; DSM runs
btrfs + NFS + the native Tailscale package and nothing else.

### Consequences accepted outside this ticket's original scope

- **The keystone principle (03) is materially rewritten.** "Light
  storage-adjacent services stay on the NAS" is dead. The user chose the
  container-free NAS over an unbroken principle, explicitly.
- **The array is wiped and rebuilt, not expanded.** Once everything non-photo is
  disposable and the photos are evacuated, a fresh **SHR-1** array is both safer
  (no day-long degraded reshape holding the only copy) and strictly better (SHR
  pays off on every disk upgrade; classic RAID 5 pays off on none until the
  fourth). See [`../ARCHITECTURE.md`](../ARCHITECTURE.md).
- **The offsite copy moves from Hetzner to Google Drive** — Workspace Business
  Plus, 5 TB pooled, already paid. Ticket 05 never considered storage already
  owned. Saves ~€143/yr. See the amendment in
  [05](05-backup-topology.md#amendment--second-pass-2026-07-26).
- **Immich deploys as `oci-containers`, not `services.immich`** — the module in the
  pinned nixpkgs has no CUDA. See the amendment in
  [06](06-immich-placement-migration.md#amendment--second-pass-2026-07-26).
- **Quality profiles must be custom.** Radarr/Sonarr's stock *Ultra-HD* profile
  allows only 2160p, so Sonarr would wait indefinitely for 4K TV releases that
  mostly do not exist on usenet. Both apps get **1080p allowed, 2160p as the
  upgrade cutoff.**

### Risks accepted

1. **The NFS mount becomes a hard dependency for every service.** The dangerous
   case is not playback breaking — it is restic snapshotting an *unmounted*
   mountpoint and `forget --prune` then ageing out the real history. Mitigated by a
   mandatory **mount guard** in the backup job, `hard` mounts with
   `x-systemd.automount`, and container ordering on the mount unit.
2. **The laptop is a genuine SPOF** for playback, photos, downloads and backups.
   A `nixos-rebuild` takes down movie night. Accepted.
3. **6 GB of VRAM is shared** between Immich ML and Jellyfin NVENC. Mitigated with
   `MACHINE_LEARNING_MODEL_TTL`; contention expected during the initial ML backlog.
4. **The 1 TB NVMe is now the tightest resource** — Immich thumbnails, Postgres,
   ML cache, Jellyfin cache, container images and SAB `incomplete/` (up to ~160 GB
   transient mid-unpack). Fits; confirm the free second M.2 slot.

Assets rewritten: [`../ARCHITECTURE.md`](../ARCHITECTURE.md),
[`../PLAN.md`](../PLAN.md), the whole of [`../build/issues/`](../build/issues/).
