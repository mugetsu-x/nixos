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

**Status:** idea, not grilled
