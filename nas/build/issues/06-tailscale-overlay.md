# 06 — Tailscale overlay: home-server + NAS nodes

**What to build:** A single-user overlay VPN for reaching home services with **no
public exposure**. Tailscale on both `home-server` (`services.tailscale.enable`)
and the NAS (DSM package), each a **direct node** (no subnet router) so the NAS is
reachable independently of the laptop. MagicDNS names; **key-expiry disabled** on
both server nodes to avoid lock-out while away.

**Blocked by:** 03 (home-server host).

**Status:** ready-for-agent

- [ ] `home-server` + NAS both on the tailnet with MagicDNS names
- [ ] Key expiry disabled on both nodes
- [ ] Both reachable by MagicDNS name from a remote (off-LAN) client

_Decision detail: [04](../../issues/04-remote-access-method.md)._
