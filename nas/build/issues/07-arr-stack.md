# 07 — Deploy download + arr stack (SAB, Prowlarr, Radarr, Sonarr)

**What to build:** The download + automation stack on the **NAS** via Container
Manager, compose file living in-repo and deployed over SSH. Prowlarr feeds NZBGeek
to Radarr/Sonarr; SABnzbd downloads into `data/usenet`; Radarr/Sonarr
**hardlink-import** into `data/media` (must stay same-filesystem — no full-copy
fallback). Both set to **4K/Ultra-HD quality profiles**. Verified by a real test
grab landing correctly named.

**Blocked by:** 05 (NAS storage), 02 (usenet accounts).

**Status:** ready-for-agent

- [ ] All four containers running on the NAS from the in-repo compose
- [ ] A test film downloads, hardlink-imports, lands correctly named in `data/media/movies` (no full-copy fallback)
- [ ] Radarr + Sonarr on 4K/Ultra-HD quality profiles

_Detail: [ARCHITECTURE.md](../../ARCHITECTURE.md) (Media); [PLAN.md](../../PLAN.md) phases 1–2._
