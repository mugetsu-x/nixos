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

**Status:** installed and running 2026-10-05. The measurements are left:
idle draw, the runtime-D3 test, and thermals in the final spot.

## As installed (2026-10-05)

- **Hardware, read off the box:** a single WD SN730 1 TB (`nvme0n1`), with no
  second NVMe fitted. 30 GB usable RAM. RTX 3060 Laptop at PCI `01:00.0`,
  Vega iGPU at `05:00.0` (the bus IDs PRIME offload needs). Intel AX200
  Wi-Fi. The dongle shows up as `enp5s0f4u2`.
- **Addresses:** wired **192.168.0.73**, Wi-Fi **192.168.0.87**, both bound by MAC on the router (ticket 05, Open). The first lease was .74/.88. The router's
  DNS resolves `home-server`, so deploys use the name. Wi-Fi sends the DHCP
  hostname `home-server-wifi`.
- **How the install actually went** (it differs slightly from the runbook):
  - At the installer console, `curl https://github.com/mugetsu-x.keys >
    ~/.ssh/authorized_keys`. GitHub publishes main-pc's key, so everything
    after that ran over SSH from main-pc.
  - The system was **built on main-pc** and `nix copy`'d into `/mnt`
    (`ssh://root@<ip>?remote-store=local?root=/mnt`, which needs root's
    authorized_keys in the installer too). Then `nixos-install --system <path>
    --no-root-passwd`. That took under a minute, with nothing compiled on the laptop.
  - The passwords were set at the console via `nixos-enter`.
  - **The installed system got a different DHCP address** from the installer
    (.73 → .74, a different client ID). After a reinstall, find it with
    `nmap -p22 --open 192.168.0.0/24`, or just use `home-server`.
- **BIOS:** Secure Boot off. There is **no power-on-with-AC option**, only
  "Flip to Boot" (powers on when the lid opens), left on. **If a long outage
  drains the battery, someone has to press the power button.** Short outages
  are bridged by the battery.
- **Charge cap: available.** `ideapad_acpi` exposes `conservation_mode`. A udev
  rule in `home-server-hardware.nix` sets it to 1 (≈60 % cap), and it read `1`
  after the first boot.
- **Failover test** (dongle pulled ~45 s, then re-plugged), logged on the box:
  - Carrier loss → routes withdrawn in 60 ms → about **1.2 s** without replies.
  - Re-plug → same wired lease (then .74) and the route back within 35 ms, with no gap.
  - An SSH session on the Wi-Fi address survived throughout.
  - There was also a 9 s gap ~14 s *before* the kernel reported carrier loss.
    The likely cause is the plug being worked loose (packets sent into a dead
    link that wasn't down yet). A clean pull fails over in about a second.
- **Follow-ups (not blocking):**
  - Shut down cleanly on low battery (`services.upower`, critical action
    `PowerOff`), since nothing restarts it after a flat battery anyway.
  - ~~DHCP reservations for both MACs on the router.~~ Done 2026-10-05 (.73/.87, see 05 Open).
  - networkd logs a harmless `Could not set hostname: Access denied` on each
    lease (the hostname is static).

## What landed in the repo (2026-10-05)

- `flake.nix`: a `mkHost` helper. Each host is `hosts/<name>.nix` + sops-nix,
  and home-manager/nix-index are main-pc-only extras.
- `modules/base.nix`: what both hosts share (bootloader, nix/gc, locale, keyboard,
  the user, zsh), split out of `common.nix`, which keeps main-pc's desktop
  layer. **main-pc's system derivation is byte-identical before and after**
  (same `.drv` hash), so the refactor is a no-op for main-pc.
- `hosts/home-server.nix` + `hosts/home-server-hardware.nix` (filesystems **by
  label**, so it evaluates before the disk exists), and `modules/server/`:
  - `headless.nix`: key-only sshd, root login for deploys only, lid/sleep off,
    console blanking.
  - `networking.nix`: networkd with Ethernet → Wi-Fi failover. Wi-Fi SSID +
    PSK come from sops.
  - `nvidia.nix`: open modules, compute only, no X.
  - `secrets.nix`: sops via the SSH host key, plus a `canary`.
- `secrets/home-server.yaml`: added `canary`, `wifi_ssid`, `wifi_psk`. The two
  Wi-Fi values are `REPLACE_ME`. **Fill them in with `sops
  secrets/home-server.yaml` before the deploy in step 8.**

## Decisions taken while writing it

- **Deploy: push from main-pc.**
  `nixos-rebuild switch --flake .#home-server --target-host root@<ip>`. The repo,
  git and Walter's sops key all live on main-pc, so the server needs no checkout
  and no build tools, and main-pc does the building. The "where does the CUDA
  closure build" worry turned out to be small: the host carries only the driver
  (kernel module + libs). CUDA userspace ships inside the Immich/Jellyfin images.
  `--build-host` is there if that ever changes.
- **Failover matches by link type, not by MAC.** No custom `.network` files.
  NixOS's own networkd defaults give every physical Ethernet link
  (`Type=ether`, `Kind=!*`, which excludes container veths) route metric 1024
  and every Wi-Fi station 1025. Both links stay up, so when the dongle
  drops, its routes go and Wi-Fi carries on. The goal behind "match by MAC" was
  "survive renaming". Type matching gets that too, and a replacement dongle needs
  no config change. **Caveat:** the two links have *different* IPs. During
  failover the box is reachable at its Wi-Fi address, not the wired one. Give
  both MACs a DHCP reservation on the router. Tailscale ([07](07-tailscale-overlay.md))
  makes this moot with one stable address.
- **The Wi-Fi SSID is a secret too.** An SSID in a public repo next to a real name
  is a location lookup on WiGLE. Both values feed a sops template that
  wpa_supplicant includes (`extraConfigFiles`).
- **The "headless EDID fix" probably doesn't apply here.** That penalty is a
  desktop-GPU effect (no monitor, no low P-state). This is a hybrid laptop: the
  panel hangs off the Ryzen iGPU, and the dGPU's real low-power state is runtime
  D3 (`hardware.nvidia.powerManagement.finegrained` + PRIME offload, with bus IDs
  from `lspci`). `nvidiaPersistenced` would block D3, so it is off. Decide after
  measuring (see the idle-draw box), not before.

## Install runbook

Do this at the laptop. Steps 6–9 can run from main-pc once SSH works.

1. **Windows goes.** The NVMe is wiped. Make sure nothing on the Windows 11
   install is wanted. While Windows is still there, check Lenovo Vantage for
   "Conservation mode". If it exists, the charge cap is in the EC and survives
   the OS swap (step 9 checks it from Linux).
2. **BIOS:** Secure Boot **off** (systemd-boot and the nvidia modules are
   unsigned). If there is a "power on with AC attach" / restore-on-power-loss
   option, turn it **on**. Once the battery is flat after a long outage, that is
   the only way the box comes back by itself. Note the CPU/fan settings while
   you're there.
3. **Boot the NixOS 26.05 minimal ISO** from USB with the RJ45 dongle plugged in.
   It gets DHCP on its own. Check with `ip -br a`.
4. **Partition by label.** `lsblk` first: confirm which disk is the 1 TB, and
   whether the second M.2 slot is populated (open item in PLAN.md).
   ```
   parted /dev/nvme0n1 -- mklabel gpt
   parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
   parted /dev/nvme0n1 -- set 1 esp on
   parted /dev/nvme0n1 -- mkpart root ext4 1GiB 100%
   mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
   mkfs.ext4 -L nixos /dev/nvme0n1p2
   mount /dev/disk/by-label/nixos /mnt
   mount --mkdir -o umask=077 /dev/disk/by-label/BOOT /mnt/boot
   ```
   The labels **must** be `nixos` and `BOOT`: `home-server-hardware.nix` mounts
   by them.
5. **Install from the flake** (the commit must be pushed):
   ```
   nixos-generate-config --root /mnt --show-hardware-config   # note kernel modules
   nixos-install --flake github:mugetsu-x/nixos#home-server
   nixos-enter --root /mnt -c 'passwd rennsemml'
   ```
   `nixos-install` asks for a root password. Both passwords are for the console
   only, since SSH is key-only. Reboot, pull the USB stick, close the lid.
6. **First boot, expected failures:** `wpa_supplicant` and the sops secrets fail.
   The host key that decrypts them was only generated on this boot. Wired works.
   Find the IP (router, or `ip -br a` on the console) and check
   `ssh rennsemml@<ip>` from main-pc.
7. **Enrol the host key** (on main-pc, in the repo):
   ```
   ssh-keyscan -t ed25519 <ip> | nix run nixpkgs#ssh-to-age
   ```
   Add the `age1…` as `&home-server` in `.sops.yaml`, add it to the
   `home-server.yaml` rule, then run `sops updatekeys secrets/home-server.yaml`.
   Fill in `wifi_ssid`/`wifi_psk` in the same sitting (`sops secrets/home-server.yaml`).
   Update the hardware file with anything step 5 showed. Commit.
8. **Deploy:** `nixos-rebuild switch --flake .#home-server --target-host root@<ip>`.
9. **Verify:**
   - `cat /run/secrets/canary` works as rennsemml.
   - `networkctl` shows both links `routable`.
   - Pull the dongle: an SSH session to the Wi-Fi IP survives, `ip route` shows
     the default route moving, and re-plugging takes it back.
   - `cat /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode`, if the
     path exists.
   - Measure idle at the plug with nothing running. Then try runtime D3
     (`cat /sys/bus/pci/devices/<nvidia>/power/runtime_status`) and measure again.

- [x] `nixosConfigurations.home-server` builds; `nix flake check --no-build` passes in CI (run 37334481819)
- [x] ThinkBook boots NixOS from the flake, unattended, lid closed
- [x] Reachable over SSH on the LAN via USB-C→RJ45 (`home-server`, .73)
- [x] sops: host's SSH key → age (`ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`), added to the existing `secrets/home-server.yaml` rule in `.sops.yaml` (created walter-only by [04](04-usenet-signup.md)), then `sops updatekeys secrets/home-server.yaml`; add a `canary` and check it's readable — see CLAUDE.md "Secrets". Enrolled 2026-10-05, `/run/secrets/canary` reads as rennsemml
- [x] **Wi-Fi failover configured and tested by unplugging the dongle** (~1.2 s, see "As installed")
- [ ] Stays up 24/7 — no idle suspend, no lid-close suspend (configured in `modules/server/headless.nix`; tick after a day of uptime)
- [x] Deploy mechanism chosen and documented. Push from main-pc, see above
- [ ] **Real idle draw measured** (plan assumed ~20 W; expect 25–40 W with the dGPU present)
- [x] Battery charge-cap availability confirmed either way. Yes, `conservation_mode`, set by udev
- [ ] Thermals sane in its final location — 45 W CPU + dGPU in a closed cupboard needs airflow — baseline 2026-10-05 22:53 (idle, on the desk, 1.5 h up): CPU Tctl 41 °C, iGPU edge 41 °C, NVMe 31 °C, 3060 37 °C. Re-read in the cupboard and compare (`ssh root@home-server 'sensors; nvidia-smi'`). **Side finding for the idle-draw item:** the 3060 sits in **P0 with runtime PM `active`** (`/sys/bus/pci/devices/0000:01:00.0/power/runtime_status`), ~19 W by `nvidia-smi -q -d POWER`, persistence mode off — it is not reaching D3 at idle and alone uses most of the plan's 20 W. (The plain `--query-gpu=power.draw` read 752 W: bogus, ignore it.)

_Decision detail: [03](../../issues/03-keystone-server-or-not.md), [01](../../issues/01-thinkpad-unit-and-always-on.md), [research](../../research/thinkpad-p16g2-home-server.md)._
