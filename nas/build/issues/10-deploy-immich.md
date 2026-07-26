# 10 — Deploy Immich on home-server

**What to build:** Immich running on `home-server`. Server + Postgres +
thumbnail/ML cache on **local NVMe** (DB never on NFS); originals storage path on
the **NFS** mount; ML on the **CUDA** image (`ViT-B-16-SigLIP2__webli` smart
search, `buffalo_l` faces, concurrency ≈2 — 6 GB VRAM ample). Two accounts —
**Walter** (admin) + **Anja** — with partner sharing. A managed, empty library on
the correct storage, ready for migration (11).

**Blocked by:** 09 (laptop GPU + NFS foundation).

**Status:** ready-for-agent

- [ ] Immich UI reachable; DB + caches on NVMe, originals path on NFS
- [ ] CUDA ML container healthy (smart-search + face models loaded)
- [ ] Walter (admin) + Anja accounts created with partner sharing

_Decision detail: [06](../../issues/06-immich-placement-migration.md)._
