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

**Status:** home-server half done 2026-10-05. The NAS half waits for [05](05-wipe-and-rebuild-nas.md).

## As built (2026-10-05)

- **Tailnet owner: `walter@pariggers.com`** (Google sign-in), tailnet
  `tail2c2ea8.ts.net`. Chosen because that address is permanent, and the
  personal gmail may go (see TODO.md). Manual user approval is on, so other
  pariggers.com accounts can't join on their own.
- `modules/server/tailscale.nix`: a plain node (no routes, no exit node),
  `openFirewall` for UDP 41641. It joins once from `tailscale_authkey` in
  `secrets/home-server.yaml` (single-use, non-ephemeral, untagged). After that
  the identity lives in `/var/lib/tailscale` and the key is dead weight. NixOS
  marks `tailscale0` unmanaged for networkd by itself (`50-tailscale`), and
  MagicDNS goes through systemd-resolved, so no DNS workarounds.
- **home-server:** `100.81.84.22`, `home-server.tail2c2ea8.ts.net`, node key
  expiry disabled. To check from the box, look at the `Self` block of
  `tailscale status --json` only. Grepping the whole output for `KeyExpiry`
  finds the *phone's* expiry, since carried devices keep theirs.
- **Off-LAN test:** a Pixel 10 on mobile data (Wi-Fi off) pinged home-server. It
  worked, **relayed via DERP Frankfurt**, not direct.
- **Why relayed:** `tailscale netcheck` at home shows `MappingVariesByDestIP:
  true` (the router does hard NAT) and no UPnP/NAT-PMP. Mobile carriers are hard
  NAT too, and hard ↔ hard can't hole-punch. That's harmless for SSH/admin. If
  remote Jellyfin ([12](12-jellyfin-jellyseerr.md)) or Immich uploads over mobile
  feel slow, the fix is one router port forward: **UDP 41641 → 192.168.0.74**
  (wired address; in Wi-Fi failover it falls back to relayed). Deferred until
  there's a need.

- [ ] `home-server` + NAS both on the tailnet with MagicDNS names (home-server ✔, NAS after 05)
- [ ] Key expiry disabled on both nodes in the admin console (home-server ✔)
- [ ] Both reachable by MagicDNS name from a genuinely off-LAN client (home-server ✔, from the phone on mobile data)
- [ ] NAS verified reachable **with `home-server` powered down**

_Decision detail: [04](../../issues/04-remote-access-method.md)._
