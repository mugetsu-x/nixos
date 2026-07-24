# 04 — Remote-access method for reaching home services

Parent: [map](../map.md)
Type: grilling
Status: open
Blocked by: —

## Question

How do you reach your home services (Immich, Jellyseerr, file sync, dashboards)
from outside the house, and expose them safely? Largely independent of the
keystone — it's a networking-layer choice that applies wherever the services end
up. Decide the approach:

- **Overlay VPN (Tailscale / Headscale / plain WireGuard)** — mesh, no ports
  opened, per-device. The modern default. Tailscale is turnkey; Headscale/
  WireGuard are self-hosted/no-account. Which, and do you accept a third-party
  coordination server?
- **Reverse proxy + public domain + TLS (Caddy/Traefik + Cloudflare Tunnel or an
  open port)** — real URLs, shareable with family, but a public attack surface to
  harden. Needed if non-technical family members must reach a service by URL.
- **Both / hybrid**, or **LAN-only** (nothing leaves the house).

Consider: your ISP situation (CGNAT? static IP?), whether family members need
access without installing a VPN client, and where a reverse proxy would run
(this may lightly reference the keystone). Resolution names the method and any
prerequisites (domain, account, DNS).
