# 03 — Keystone: Does the ThinkPad become the always-on server, and how is it managed?

Parent: [map](../map.md)
Type: grilling
Status: resolved
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

## Answer

**Role: always-on home-server / compute node (Model A).** The ThinkBook becomes
the always-on "brain"; the NAS is demoted to storage + storage-adjacent light
services. Chosen because the *reason* to bring the laptop in at all is that the
DS420+ (2-core Celeron J4025, 6 GB) is too weak to host the application layer —
so the services must actually move there, not just borrow its GPU.

- **Networking caveat (from 01) resolved:** Wi-Fi-only is fine — user already
  owns a USB-C→RJ45 adapter. The box sits lid-closed, out of the living space,
  by the router.
- **Wake-on-demand (Model B) considered and rejected:** it leaves the services
  on the too-weak NAS and only borrows the GPU, so it doesn't fix the actual
  bottleneck; WoL **does not work through USB Ethernet adapters**, so "wake on
  upload" degrades to scheduled-wake windows or the manual power button; and the
  ~€40–50/yr saving doesn't justify the fragile wake/handoff/sleep plumbing. If
  the NAS were beefy, Model B would be the elegant answer — with this NAS it
  isn't.

**Management: NixOS as a second host in this flake** (`nixosConfigurations.home-server`).
Objective call, not "because we already run NixOS": the reproducibility /
rollback / rebuild-from-git properties are genuinely valuable for an unattended
always-on box, and the marginal cost of getting them is near zero because the
flake, CI (`nix flake check`), and the skillset already exist. Proxmox rejected
(hypervisor for VM/cluster needs that don't apply to one container box);
Debian+Docker rejected (makes the box a hand-tended pet and adds a second OS
paradigm). Big services use first-class NixOS modules (Immich, Nextcloud) with
`virtualisation.oci-containers` as the fallback for container-only apps. *(For a
non-NixOS user the honest pick would be Debian+Docker; the learning cost that
normally counts against NixOS is already paid here.)*

**Division-of-labour principle:**

- **NAS = storage & durability layer.** Owns the disks: bulk datasets (photos,
  media, file shares), RAID + snapshots, and only *storage-adjacent* light
  services (the arr/media pipeline per `PLAN.md`, SMB/NFS, Synology backup
  tooling).
- **ThinkBook = compute & application layer.** Always-on host for anything
  wanting CPU/GPU/RAM: Immich (server + ML), file-sync, dashboards, other apps,
  remote-access entry. Bulk data stays on the NAS and is mounted over the LAN;
  the laptop's NVMe holds OS + app data + DBs + ML models. The exact
  "Immich mounts NFS vs. holds photos locally" call is a detail that graduates
  into the Immich placement ticket.

**Graduates the fog into:** Immich placement + migration (06), file-sync
solution (07), media-relocation + `PLAN.md` consolidation (08). On-site backup
copy placement is now answerable within the existing backup ticket (05).

---

## Amendment — second pass (2026-07-26)

The **role** and **management** decisions above stand unchanged: the ThinkBook is
the always-on server, running NixOS as a second host in this flake. The
**division-of-labour principle is materially rewritten** by the re-grill of
[08](08-media-relocation-and-plan-consolidation.md).

### What changed

The original principle parked "light storage-adjacent services" on the NAS — the
arr/media pipeline, SMB/NFS, Synology backup tooling — and ticket 01 recorded
*"NAS is enough for the light stuff (arr suite)."* Every service that principle
placed on the NAS has since been moved off it, because each placement rested on a
premise that failed on checking:

| Service | Reason it stayed on the NAS | Why that failed |
|---|---|---|
| arr stack | hardlink locality | **Hardlinks work over NFS** — the link is created server-side on btrfs |
| Jellyfin | direct-play dominates ⇒ data-locality wins | Only true for the Shield; every other client needs tone mapping the J4025 can't do |
| Plex | working safety net during proving | No Plex Pass ⇒ no hardware transcode ever, and its library was scheduled for deletion anyway |

With nothing left, the honest principle is simpler.

### The revised principle

> **The NAS stores bytes. The laptop runs everything.**

- **NAS = storage layer, and nothing else.** RAID + btrfs snapshots + scrub, NFS
  exports, and the native DSM Tailscale package so it stays independently
  reachable. **Zero containers** — Container Manager is uninstalled during the
  rebuild.
- **ThinkBook = every service.** Media pipeline, media server, photos, backups,
  and anything added later — all `oci-containers` declared in this flake, mounting
  NAS bulk storage over NFS, with secrets from sops-nix.

The user chose the container-free NAS over an unbroken principle, explicitly and
with the trade-off stated. The practical argument that carried it: *"the NAS runs
no containers at all"* is a materially simpler durability layer to reason about
and to recover after a DSM upgrade, and it is the only version of this plan
consistent with how the rest of this repo is run.

### What this does not change

- **Proxmox and Debian+Docker stay rejected** for the reasons given above.
- **Wake-on-demand (Model B) stays rejected** — and is now further out of reach,
  since the laptop hosts playback and would have to be awake continuously anyway.
- **`virtualisation.oci-containers` is now the primary deployment mechanism, not
  the fallback.** The original text preferred first-class NixOS modules for big
  services, naming Immich as an example. That specific case inverted: the nixpkgs
  Immich module cannot do CUDA (see
  [06](06-immich-placement-migration.md#amendment--second-pass-2026-07-26)), which
  is the whole reason Immich is on this machine. Prefer a NixOS module where one
  exists *and* covers the requirement; otherwise containers.

### New cross-cutting requirements this creates

Concentrating every service on one host makes three things load-bearing that the
original answer did not address:

- **Secrets management (sops-nix).** The repo has a public GitHub remote and CI on
  every push. restic passwords, rclone/Drive OAuth, the Tailscale auth key, usenet
  credentials and the Immich DB password all need it. This gates the host coming
  up at all.
- **Dead-man alerting.** An unattended box that silently stops backing up looks
  identical to one that works. Alert on the *absence* of success.
- **NFS mount robustness.** Every service now depends on one mount. `hard` mounts,
  `x-systemd.automount`, containers ordered on the mount unit, and a mount guard in
  the backup job so restic can never snapshot an empty tree and prune real history.
