# TODO

Planned work on this config. Newest context at the top of each item so we do not
have to rediscover it.

## 1. Home infrastructure — NAS + `home-server`

Planned in detail, nothing executed yet. Architecture in
[nas/ARCHITECTURE.md](nas/ARCHITECTURE.md), build detail in
[nas/PLAN.md](nas/PLAN.md), ordered queue in [nas/build/](nas/build/README.md) —
read those, not this summary.

**Shape (revised 2026-07-26, second pass).** Two machines: the DS420+ is **pure
storage** — btrfs SHR-1, NFS exports, Tailscale, **zero containers** — and the
repurposed ThinkBook 16p Gen 2 (`home-server`, a second host in this flake) runs
**everything**: SABnzbd + Prowlarr + Radarr + Sonarr, Jellyfin + Jellyseerr,
Immich on the RTX 3060, and the restic 3-2-1. All `oci-containers`, declarative,
secrets via sops-nix.

An earlier version of this plan kept the media stack on the NAS. That rested on
two claims that turned out to be false — hardlinks *do* work over NFS, and the
Celeron *cannot* actually handle the "rare transcode" case (no Plex Pass ⇒ no
hardware transcode at all, and UHD 600 can't tone-map 4K HDR). Both are written up
in [ticket 08](nas/issues/08-media-relocation-and-plan-consolidation.md).

**The array is wiped and rebuilt, not expanded.** The 4 GB SODIMM and the 4 TB
IronWolf are in hand and get fitted during the rebuild. This replaces the old
online-expansion phase 0 and removes the day-long degraded reshape.

**Critical path:** evacuate the photos to USB → seed Google Drive (copy #3, before
the wipe) → wipe. Nothing destructive starts until three copies exist. The usenet
accounts (Eweka + NZBGeek, need a card) block only the arr stack, and secrets
(sops-nix) block the laptop host.

## 2. E-book library and download flow

Not started. Wants a library plus a way to get books into it. Open questions:
which reader (Calibre? Foliate?), whether a Kobo/Kindle is in the picture, and
where the library lives on disk.

## 3. Manga downloader

Not started. Candidates to evaluate in nixpkgs.

## 4. Monitors and Hyprland behaviour

Mostly done. The physical setup is two Dells: DP-2, the AW3423DWF ultrawide
(3440x1440 @ 165 Hz), and DP-4, a P2426H (1920x1080 @ 120 Hz) sitting **below**
it, not to the right. Both are now positioned and rate-pinned explicitly in
`hyprland.conf`, the layout moved from `master` to `dwindle`, and waybar is
pinned to DP-4 only (`"output"` in `waybar/config.jsonc`).

Still open:

- Workspace-to-monitor pinning (`workspace = 1, monitor:DP-2` etc). Today
  workspaces float between outputs.
- `input { follow_mouse = 0 }` is click-to-focus; confirm that is deliberate.
- VRR is now on for DP-2, fullscreen-only (`vrr,2`). Watch for OLED flicker in
  games with uneven frame times; if it shows up, cap the in-game frame rate
  (mangohud can) rather than turning VRR off — the flicker comes from the swing,
  not from VRR itself.

## 5. Development setup — DONE

The environment is in place; see the "Development" section of CLAUDE.md.

Shape that landed: **Zed** as the primary editor (declarative, in
`home/modules/zed.nix`), VSCode and Cursor removed. The LSP/formatter list moved
out of the Neovim module into `home/lib/ts-packages.nix`, shared by both editors.
`home/modules/dev.nix` puts node/pnpm/tsc/psql/httpie in the profile as a
baseline; per-project versions come from a flake devShell via direnv.
`templates/nextjs` scaffolds a project (devShell + `.envrc` + Postgres in Docker).

The people-management-app itself is still to be created — the environment is
ready for it, the app is not written.

Still open:

- Zed's agent needs an interactive sign-in on first launch (provider + model).
- No ORM picked yet. Drizzle is the assumed default; decide when the app starts.
