# 07 — Tailscale overlay: `home-server` + NAS nodes

**What to build:** A single-user overlay VPN for reaching home services with **no
public exposure**. Tailscale on both `home-server` (`services.tailscale.enable`) and
the NAS (native DSM package — the one non-storage thing the NAS still runs, and it is
not a container). Each is a **direct node, no subnet router**, so the NAS stays
reachable independently of the laptop — which matters because the laptop is now a
SPOF for every service.

MagicDNS names; **key expiry disabled on both server nodes** to avoid the classic
"node key expired while travelling → locked out, must re-auth physically" failure.

Auth key comes from sops-nix ([03](03-secrets-management.md)).

**Blocked by:** 06 (home-server host). The NAS half needs 05.

**Status:** ready-for-agent

- [ ] `home-server` + NAS both on the tailnet with MagicDNS names
- [ ] Key expiry disabled on both nodes in the admin console
- [ ] Both reachable by MagicDNS name from a genuinely off-LAN client
- [ ] NAS verified reachable **with `home-server` powered down**

_Decision detail: [04](../../issues/04-remote-access-method.md)._
