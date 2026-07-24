# 03 — Keystone: Does the ThinkPad become the always-on server, and how is it managed?

Parent: [map](../map.md)
Type: grilling
Status: open
Blocked by: 01, 02

## Question

**The decision the whole map hangs on.** Given the real specs and always-on
verdict (01) and the general viability facts (02), decide:

1. **Role:** does the ThinkPad become an **always-on home-server / compute node**
   (heavy services move to it, NAS demoted to storage + light services), a
   **secondary node** (powered on when needed — backup target / occasional
   compute), or **neither** (sell/retire, effort stays NAS-only)?

2. **If it's a server — management:** run **NixOS on it as a second host in this
   flake** (`nixosConfigurations.home-server`, declarative, fits the repo) vs.
   something else (Proxmox, plain Debian + Docker, DSM-style). What's the
   division-of-labour principle between the two boxes?

Resolving this fixes the scope of every downstream placement decision. When it
closes, the fog (Immich placement, file-sync placement, media relocation,
on-site backup copy) graduates into concrete "NAS or laptop for X" tickets.
