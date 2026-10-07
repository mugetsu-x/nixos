# 16 — Homepage (start page for all services)

**What to build:** [Homepage](https://gethomepage.dev) on `home-server`. One page
linking every service (Jellyfin, Jellyseerr, the arr stack, SABnzbd, Immich, and
the later 15/17/18/19), with live widgets: download queue, Jellyfin streams,
Immich counts, disk usage of the NAS shares.

Added 2026-10-06 as a wish (Walter); **not grilled yet**.

**Shape (proposal):**
- nixpkgs has `services.homepage-dashboard`, whose `services`, `widgets`,
  `bookmarks` and `settings` are Nix attrsets. **The whole dashboard is
  declarative**, which fits this repo better than any of the other new tickets.
- Holds no data of its own, so nothing for 13 to back up. It can be built any
  time, independent of the backup gate.

**Things that will bite:**
- **Widget API keys are secrets.** Radarr/Sonarr/Prowlarr/SABnzbd/Jellyfin/Immich
  keys go through sops into an env file as `HOMEPAGE_VAR_*` and get referenced as
  `{{HOMEPAGE_VAR_…}}`, never as literals in the public repo. (Today the arr keys
  live only in each app's `config.xml`, see TODO.)
- **`HOMEPAGE_ALLOWED_HOSTS`** must list every name it's reached by
  (`home-server:<port>`, the tailnet name/IP), or it refuses the request.
- Host networking like the rest, so widgets reach the apps on localhost.

**Open questions:**
- Which port, and is it the browser start page on main-pc / the phones?
- Which widgets are worth it. Not every app needs live stats.
- Should it also show home-server health (CPU temp, battery, NFS mounts), or
  leave health to [14](14-alerting.md)?

**Blocked by:** 06. Nicer once the other services exist.

**Status:** done 2026-10-07: `http://home-server:8082`, `modules/server/homepage.nix`

## Decisions (Walter, 2026-10-07)

- **Port 8082**, the nixpkgs default. 80/443 stay free for the HTTPS answer
  17/18 need.
- **Widgets:** SABnzbd, Radarr, Sonarr (downloads), Jellyfin (now playing),
  Jellyseerr (requests), Immich (counts). Prowlarr is a link only.
- **Health:** the built-in `resources` widget only: CPU, RAM, CPU temp, uptime,
  `/`, and the NAS. `/data` and `/photos` are one volume, so one disk entry.
  Battery and alerting stay in 14.
- **Not** set as Chrome's start page on main-pc; just a bookmark.

## What landed (2026-10-07)

- Keys in sops as `<app>_api_key`, rendered into one env file
  (`sops.templates."homepage.env"`) as `HOMEPAGE_VAR_<APP>_KEY`. Radarr, Sonarr,
  SABnzbd and Jellyseerr were copied from the apps' config files on the box.
  Jellyfin and Immich were made in their UIs, both named `homepage`. Immich's
  is Walter's (admin) key with only `server.statistics`.
- `allowedHosts`: localhost, `home-server`, .73, .87, the tailnet name and IP.
  The check guards **the API, not the page**: an unknown `Host` still gets the
  HTML shell but `400 Host validation failed` on every widget call.
- Every service has a `siteMonitor` up/down dot.
- Verified through Homepage's own proxy: all six widgets return data, and the
  `resources` widget reads `/data` over NFS despite the unit's `PrivateMounts`.
- **Gotcha:** the Immich widget's v2 endpoint is called `statistics_v2`.
  `statistics` maps to the old `/api/server-info/statistics` and returns 404.
  The page itself uses the right one; only a hand-made proxy call trips on it.
