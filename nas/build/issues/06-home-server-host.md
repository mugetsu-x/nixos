# 06 — Stand up the `home-server` NixOS host

**What to build:** The repurposed ThinkBook 16p Gen 2 running NixOS as a **second
host in this flake** (`nixosConfigurations.home-server` + `hosts/home-server.nix`),
always-on. Boots unattended lid-closed, out of the living space, networked over the
owned **USB-C→RJ45 adapter**, SSH-reachable on the LAN.

Base host only — GPU/NFS ([08](08-gpu-nfs-foundation.md)), Tailscale
([07](07-tailscale-overlay.md)), and every service build on top of this.

**Minor flake wiring:** the flake currently defines a single host inline. Factor the
`nixosConfigurations` entry so a second one doesn't duplicate the input plumbing.

**Things that will bite:**

- **Headless-idle EDID quirk** — apply the dummy-plug/EDID fix; it is also what
  holds idle power at the low end.
- **USB Ethernet is the only wired NIC, and it can drop.** Configure **Wi-Fi as a
  persistent failover** so a dongle re-enumeration doesn't leave a headless box in a
  cupboard unreachable. Match the interface by MAC in `systemd.network`, not by name.
- **Decide the deploy mechanism** — `nixos-rebuild --target-host` pushed from
  `main-pc`, or SSH in and pull. It determines where the CUDA closure builds.
- **Battery charge threshold: verify it exists before relying on it.** Ticket 01
  carried this over as a *ThinkPad* feature (`thinkpad_acpi`). ThinkBooks generally
  are not covered by it — check BIOS or `ideapad_laptop`'s `conservation_mode`.
- Use the **nvidia open** kernel modules (Ampere GA106 supports them).

**Blocked by:** 03 (secrets — the host needs sops-nix from first activation).

**Status:** ready-for-agent

- [ ] `nixosConfigurations.home-server` builds; `nix flake check --no-build` passes in CI
- [ ] ThinkBook boots NixOS from the flake, unattended, lid closed
- [ ] Reachable over SSH on the LAN via USB-C→RJ45
- [ ] **Wi-Fi failover configured and tested by unplugging the dongle**
- [ ] Stays up 24/7 — no idle suspend, no lid-close suspend
- [ ] Deploy mechanism chosen and documented
- [ ] **Real idle draw measured** (plan assumed ~20 W; expect 25–40 W with the dGPU present)
- [ ] Battery charge-cap availability confirmed either way
- [ ] Thermals sane in its final location — 45 W CPU + dGPU in a closed cupboard needs airflow

_Decision detail: [03](../../issues/03-keystone-server-or-not.md), [01](../../issues/01-thinkpad-unit-and-always-on.md), [research](../../research/thinkpad-p16g2-home-server.md)._
