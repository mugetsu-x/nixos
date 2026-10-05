# 11 — Deploy SABnzbd + the arr stack on `home-server`

**What to build:** SABnzbd, Prowlarr, Radarr and Sonarr as `oci-containers` on
**`home-server`** (not the NAS — see below), with the split download layout.

**Why these moved off the NAS.** The original plan kept them there for "hardlink
locality." That premise was false — **hardlinks work over NFS**; the link is created
server-side on btrfs. What actually breaks imports is separate mounts or mismatched
container paths, which [08](08-gpu-nfs-foundation.md) already rules out. The real
justification is the clean boundary: the NAS runs zero containers, and everything
here is declarative and rolls back with the flake. **Not speed** — at 170–250 Mbps
the Celeron only cost ~20 min on a 60 GB film.

**The split layout, and why:**

```
/var/lib/sabnzbd/incomplete/   <- local NVMe: par2 + unrar happen here
/mnt/nas/data/usenet/complete/ <- NFS: SAB's finished output
/mnt/nas/data/media/           <- NFS: same share, so Radarr hardlinks into it
```

par2 verification and unrar are heavy random I/O — keeping them on NVMe keeps that
churn off the array where it would compete with Immich reads and the nightly restic
run. The finished file crosses the LAN once, landing on the same filesystem as
`media/` so the hardlink import still works. Budget up to **~160 GB transient** on
the NVMe for a 4K release mid-unpack.

**⚠️ Quality profiles must be custom, not stock.** Radarr/Sonarr ship an
**Ultra-HD** profile that permits **only 2160p**. Set that on Sonarr and most shows
never download at all — 4K TV is far sparser on usenet than on torrents, so Sonarr
sits silently waiting for releases that don't exist. **Both apps: 1080p allowed,
2160p as the upgrade cutoff, `Upgrades Allowed` on.**

Credentials from sops-nix ([03](03-secrets-management.md), [04](04-usenet-signup.md)).

**Blocked by:** 08 (GPU + NFS foundation), 04 (usenet accounts).

**Status:** done 2026-10-05 (UI logins set). Code: `modules/server/arr.nix` (linuxserver images pinned, host networking, PUID/PGID 1024:100, ports SAB 8080, Prowlarr 9696, Radarr 7878, Sonarr 8989). **Provisioned over the apps' APIs, not declaratively:** the settings (SAB server + categories + dirs, root folders, download clients, the `1080p + 4K` profile, the NZBgeek indexer and the Prowlarr→Radarr/Sonarr links) live in each app's config under `/var/lib/<app>`, which is therefore backup scope for 13 (with `/var/lib/jellyfin` and `/var/lib/jellyseerr`). Credentials were read from `/run/secrets` at setup time. **Usenet imports are a rename, not a hardlink** (hardlinks are for torrents that keep seeding): a same-export `mv` keeps the inode and takes 5 ms for 200 MB, so there is no copy fallback. Test grab: Tears of Steel (CC-BY), 108 MB, imported by Radarr as `Tears of Steel (2012)/…mp4`.

- [x] All four containers running on `home-server` from in-flake definitions
- [x] `incomplete/` (`/config/Downloads/incomplete`, i.e. `/var/lib/sabnzbd`) on NVMe, `complete/` on NFS beside `media/`
- [x] Identical paths inside every container
- [x] **A real test grab — rename not hardlink for usenet, see Status downloads, hardlink-imports, and lands correctly named — verified by inode, confirming no full-copy fallback**
- [x] Custom quality — Radarr and Sonarr, profile id 7, cutoff WEB 2160p, upgrades on profiles on both: 1080p allowed, 2160p cutoff
- [x] Prowlarr feeding NZBGeek to both Radarr and Sonarr
- [x] Usenet credentials sourced from sops-nix, not stored in container config
- [x] arr databases identified as backup scope for [13](13-restic-321-service.md)

_Decision detail: [08](../../issues/08-media-relocation-and-plan-consolidation.md#answer--second-pass-2026-07-26)._
