# 12 — restic 3-2-1 backup service on home-server

**What to build:** The full backup service on `home-server`
(`services.restic.backups`), completing 3-2-1. Copy #1 = NAS live managed library;
copy #2 = the 4 TB USB HDD, **nightly pull** from NAS; copy #3 = **Hetzner Storage
Box** (provision BX21 ~5 TB), client-side encrypted, immutable via server-side
snapshots the client can't delete. DBs `pg_dump`'d first. Tiered scope: **photos
full 3-2-1**, media excluded (re-downloadable), laptop app-state on a lighter tier.
Retention 7d/8w/12m/5y, weekly prune. Absorbs 01's one-shot into the ongoing
service. Monthly check + one real offsite restore drill; keys off the laptop.

**Blocked by:** 03 (home-server host), 10 (Immich — the managed library + DB to back up).

**Status:** ready-for-agent

- [ ] Hetzner Storage Box provisioned; restic repo there, client-side encrypted
- [ ] Nightly USB-HDD pull + Hetzner snapshots running; DBs `pg_dump`'d first
- [ ] Retention/prune configured; media excluded, photos full 3-2-1
- [ ] Monthly `restic check` + one real offsite restore drill; keys stored off the laptop

_Decision detail: [05](../../issues/05-backup-topology.md)._
