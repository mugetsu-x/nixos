# TODO

Planned work on this config. Newest context at the top of each item so we do not
have to rediscover it.

## 1. NAS media pipeline

Planned in detail, nothing executed yet. Full plan in [nas/PLAN.md](nas/PLAN.md)
— read that, not this summary.

Shape: usenet (SABnzbd) + Prowlarr + Radarr in Container Manager on the DS420+,
importing by hardlink into a single new `/volume1/data` shared folder. Plex stays
as the player for now; Jellyfin + Jellyseerr + Sonarr land in phase 2, which is
blocked on a €20 4 GB SODIMM (the NAS has 2 GB and it does not fit).

The compose file will live in `nas/` in this repo and be deployed to the NAS over
SSH, so it stays version-controlled even though it does not run on this machine.

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
