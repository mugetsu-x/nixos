# Build queue

Ordered execution tickets for the architecture in
[`../ARCHITECTURE.md`](../ARCHITECTURE.md). Reference detail lives in
[`../PLAN.md`](../PLAN.md); the decision trail is in [`../issues/`](../issues/).

> **Rewritten 2026-07-26 (second pass).** The original 12 tickets were built around
> expanding the NAS in place and running services on it. The re-grill of
> [ticket 08](../issues/08-media-relocation-and-plan-consolidation.md) inverted both,
> so the queue was rebuilt rather than patched.

## Dependency graph

```
01 inventory + evacuate ──┬─> 02 seed Google Drive ──┬─> 05 wipe + rebuild NAS ──┐
                          │                          │                            │
                          └──────────────────────────┴────> 10 import photos      │
                                                              ^                   │
03 secrets (sops-nix) ──> 06 home-server host ──┬─> 07 tailscale                  │
                                                │                                 │
                                                ├─> 14 alerting                   │
                                                │                                 │
                                                └─> 08 GPU + NFS foundation <─────┘
                                                      │
                                    ┌─────────────────┼──────────────────┐
                                    v                 v                  v
                              09 immich ──> 10   11 arr stack      12 jellyfin
                                    │        ^     (needs 04)      (jellyseerr
                                    │        │                      needs 11)
                                    └──> 13 restic 3-2-1

04 usenet signup ──> 11        (independent, manual, do it whenever)
```

## The tickets

| # | Ticket | Blocked by |
|---|---|---|
| 01 | [Inventory `/volume1` + evacuate photos to USB](issues/01-inventory-and-evacuate.md) | — |
| 02 | [Seed the Google Drive offsite copy](issues/02-seed-google-drive-offsite.md) | 01 |
| 03 | [Secrets management (sops-nix)](issues/03-secrets-management.md) | — |
| 04 | [Sign up usenet: Eweka + NZBGeek](issues/04-usenet-signup.md) | — |
| 05 | [**Wipe and rebuild the NAS** as pure SHR-1 storage](issues/05-wipe-and-rebuild-nas.md) | 01, 02 |
| 06 | [Stand up the `home-server` NixOS host](issues/06-home-server-host.md) | 03 |
| 07 | [Tailscale overlay](issues/07-tailscale-overlay.md) | 06 |
| 08 | [Laptop GPU + NFS foundation](issues/08-gpu-nfs-foundation.md) | 06, 05 |
| 09 | [Deploy Immich](issues/09-deploy-immich.md) | 08 |
| 10 | [Import the photos from USB into Immich](issues/10-import-photos.md) | 09, 01 |
| 11 | [Deploy SABnzbd + the arr stack](issues/11-arr-stack.md) | 08, 04 |
| 12 | [Deploy Jellyfin + Jellyseerr](issues/12-jellyfin-jellyseerr.md) | 08 |
| 13 | [restic 3-2-1 backup service](issues/13-restic-321-service.md) | 09, 06, 03 |
| 14 | [Dead-man alerting](issues/14-alerting.md) | 06 |

## Three things not to get wrong

1. **Ticket 05 is irreversible.** It destroys the array. Do not start it until 01
   *and* 02 are both green — two verified USB copies **and** the offsite seed. The
   window between wipe and restore is the only time your photos live solely on
   unplugged disks in one room; the Drive seed is what keeps you at three copies
   through it.
2. **The mount guard in 08/13.** restic snapshotting an unmounted mountpoint writes
   a near-empty snapshot, and the next `prune` ages out the real history. It is the
   one failure mode in this plan that destroys data silently and on schedule.
3. **The quality profile in 11.** The stock *Ultra-HD* profile allows only 2160p, so
   Sonarr waits forever for 4K TV that mostly doesn't exist on usenet, and reports
   nothing wrong. Custom profile: 1080p allowed, 2160p cutoff.

## Parallelism

01 → 02 → 05 (the NAS track) and 03 → 06 (the laptop track) are independent — run
them at the same time. 04 is manual and blocks only 11. The two tracks converge at
08, which needs both a working host and NAS exports.
