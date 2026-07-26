# 05 — Prepare NAS storage: snapshots, data share, reclaim, NFS exports

**What to build:** NAS storage ready for the media pipeline and for the laptop to
mount. Enable btrfs snapshots on `homes`/`Walter`/`Anja` (before anything else
touches the box). Create the `/volume1/data` shared folder with the **single-share
hardlink layout** (`media/{movies,tv}`, `usenet/{incomplete,complete}`) — downloads
and library in one share is the one expensive-to-undo decision. Delete the
disposable `PlexMediaServer/Movies` + `Shows` (~470 GB; leave `AppData`). Export
media + photo-originals over **NFS** for `home-server` to mount.

**Blocked by:** 04 (phase-0 hardware).

**Status:** ready-for-agent

- [ ] btrfs snapshots active on the three photo shares
- [ ] `/volume1/data` created with the hardlink-compatible layout
- [ ] ~470 GB disposable Plex media deleted; Plex still runs (AppData intact)
- [ ] NFS exports for media + photo originals reachable on the LAN

_Detail: [PLAN.md](../../PLAN.md) storage layout + phase 1._
