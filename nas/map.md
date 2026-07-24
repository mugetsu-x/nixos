# Map: Home infrastructure — NAS + repurposed ThinkPad

Label: `wayfinder:map`
Tracker: local-markdown. This map lives in `nas/` next to `PLAN.md`; tickets in
`./issues/`, research in `./research/`.
Charted: 2026-07-24.

## Destination

A **written architecture plan** for extensive home use, spanning the Synology
DS420+ ("Alexandria") and the ThinkPad 16p Gen 2 you no longer need — deciding,
for each workload (media, photos, file sync, backups, remote access), **which
machine runs it and how the two divide labour**, plus backup topology and the
remote-access approach. "Plan, don't do": the map produces decisions written up
like `nas/PLAN.md`, then you execute. Done when nothing architectural is left to
decide.

## Notes

- **Domain:** home lab / self-hosting for a single household. NixOS shop (this
  repo); the DS420+ runs DSM 7.3, Container Manager, btrfs, RAID 5. Weak Celeron
  J4025 / 6 GB (after phase 0). Playback is home-only via an NVIDIA Shield.
- **Keystone insight (from charting):** `nas/PLAN.md` is generally correct but
  was written *before* the laptop existed in the picture. The standing rule for
  this whole effort: **for any workload, if it makes more sense on the laptop
  than the NAS, put it on the laptop.** So the laptop-role decision cascades into
  almost everything and must resolve early.
- **Consistency, not re-litigation:** the media pipeline's *internals* (usenet,
  hardlink layout, phase-0 hardware) are settled in `nas/PLAN.md` and are out of
  scope here. What *is* in scope is whether any of those workloads **relocate**
  to the laptop.
- **Skills:** `/grilling` + `/domain-modeling` for decision tickets; `/research`
  for AFK fact-finding; `/prototype` if a topology needs a concrete sketch.
- **Irreplaceable data:** ~950 GB of family photos on the NAS. Backups (ticket
  05) is the highest-stakes decision; treat it as such.

## Decisions so far

<!-- one line per closed ticket: gist + link -->

- [Research: ThinkPad 16p Gen 2 as an always-on home server](issues/02-thinkpad-home-server-research.md)
  — it's a **ThinkPad P16 Gen 2** (HX + RTX Ada); GPU categorically beats the NAS
  Celeron (AV1 NVENC, unlimited sessions, CUDA/VRAM for Immich ML), NixOS as a 2nd
  flake host is low-risk. Downsides: ~15–25 W idle (200 W+ chassis), **no built-in
  Ethernet**, headless-idle EDID quirk. Full note in `research/`.

## Not yet specified

<!-- in-scope fog; graduates as the frontier advances. Most of this hangs on the
     keystone (ticket 03) — once the laptop's role is fixed, these sharpen into
     placement tickets. -->

- **Immich (photos): placement + migration.** Where Immich runs (GPU for ML
  favours the laptop) and how the ~950 GB is migrated off the current NAS shares
  (`homes`/`Walter`/`Anja`). Hangs on the keystone (03).
- **File sync / personal cloud: solution + placement.** Nextcloud vs Syncthing
  vs other, and which machine hosts it. Hangs on the keystone (03).
- **Does the media stack relocate?** Whether the *arr stack and/or Jellyfin
  transcoding move from the NAS to the laptop, revising `nas/PLAN.md`. GPU facts
  now in (02: Ada NVENC ≫ Celeron QuickSync, but Shield direct-plays so transcode
  rarely fires). Now hangs only on the keystone (03).
- **On-site backup copy placement.** Whether the laptop (or its disks) serves as
  the local second copy in the 3-2-1 scheme. Hangs on both keystone (03) and the
  backup-topology decision (05).
- **Other self-hosted apps.** Ebooks/manga (TODO items 2–3), a dashboard, maybe
  home automation. Trivial to place once a compute home and remote access exist;
  fog until then.

## Out of scope

- **Media pipeline internals** — usenet provider/indexer, SABnzbd/Prowlarr/Radarr
  choice, the single-shared-folder hardlink layout, phase-0 RAM+drive fit. Settled
  in [`PLAN.md`](PLAN.md); this effort only revisits *where* they run.
