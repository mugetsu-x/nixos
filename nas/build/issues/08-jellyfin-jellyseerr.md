# 08 — Deploy Jellyfin + Jellyseerr alongside Plex

**What to build:** Jellyseerr (request UI) + Jellyfin on the **NAS** alongside the
existing Plex, all pointed at `data/media`. The end-to-end "easy" flow: request a
film in Jellyseerr → it downloads → it appears on the **Shield** via Jellyfin
direct-play. Playback is designed for the home LAN; remote is best-effort over
Tailscale. Plex stays as the safety net — retire it **only once** Jellyfin is
proven on the Shield.

**Blocked by:** 07 (arr stack).

**Status:** ready-for-agent

- [ ] Jellyfin serving `data/media`; Shield plays a 4K HEVC title via direct-play
- [ ] Jellyseerr requests flow through to Radarr/Sonarr
- [ ] Plex still running (retirement deferred until Jellyfin proven)

_Detail: [ARCHITECTURE.md](../../ARCHITECTURE.md) (Media)._
