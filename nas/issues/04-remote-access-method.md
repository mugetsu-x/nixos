# 04 — Remote-access method for reaching home services

Parent: [map](../map.md)
Type: grilling
Status: resolved
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

## Answer

**Tailscale-only overlay VPN — single-user, no public exposure.** Resolved by
grilling, 2026-07-26.

### Decisions

- **Audience: just you** (VPN-client access). No non-technical family member needs
  a URL today, so the entire **public reverse-proxy / domain / TLS-hardening branch
  is ruled out** — no public attack surface to harden.
- **Method: Tailscale**, hosted coordination server (accepted). Turnkey, free tier
  is ample for one user, first-class NixOS module (`services.tailscale.enable`) on
  the ThinkBook. Trust trade-off accepted: Tailscale brokers connections but never
  decrypts traffic (end-to-end WireGuard); requires an account tied to an identity
  provider. Headscale (self-host the control plane) and bare WireGuard both rejected
  — Headscale would put the remote-access *control plane* on the very network you're
  trying to reach, and bare WireGuard reintroduces the endpoint/port-forward problem.
- **ISP situation is moot.** Overlay VPN does NAT traversal via relays — **no inbound
  port, no DDNS, CGNAT / dynamic IP all fine.** The thorniest sub-question evaporates.
- **Topology: direct Tailscale clients on BOTH the ThinkBook and the NAS; no subnet
  router.** Both are always-on and both run a native client (Synology DSM 7.3 ships a
  Tailscale package), giving clean MagicDNS names (`thinkbook`, `alexandria`). Crucially
  the **NAS stays independently reachable even if the ThinkBook is down** — matters for
  the durability layer (ticket 05) and for administering storage-of-record. A subnet
  router was rejected as it ties all remote access to the most-rebooted node. Subnet
  *routes* on the ThinkBook can be added later if the Shield/router ever need remote
  reach (that's the deferred "which apps/devices" fog, not a day-one need).
- **Node key expiry DISABLED on the two always-on server nodes** (ThinkBook + NAS),
  brought up with a pre-authenticated auth key; carried devices (laptop/phone) keep
  normal expiry. Prevents the classic "node key expired while travelling → locked out,
  must re-auth physically at the machine" failure — the exact outcome this ticket exists
  to avoid.

### Prerequisites

- A Tailscale account tied to an identity provider (Google/GitHub).
- `services.tailscale.enable = true` on the `home-server` NixOS host (ticket 03).
- Tailscale package installed + logged in on the Synology (Package Center / manual).
- In the admin console: disable key expiry on both server nodes. Default ACL
  (single-user allow-all) is sufficient; no tags/ACL work needed.

### Accepted risks / deferrals

- Reliance on Tailscale Inc.'s coordination server (brokering, not decryption).
- If family URL-access ever becomes a real need, a **hardened public reverse proxy is
  added then**, scoped to that one service — not designed now.
