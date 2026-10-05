# TODO

Planned work on this config. Newest context at the top of each item so we do not
have to rediscover it.

## 1. Home infrastructure — NAS + `home-server`

Underway since 2026-10-05; current state and handoff below. Architecture in
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

**Critical path:** agent-run evacuation from `main-pc` — SHA-256 manifest hashed
on the NAS, plain-tree `rsync` onto a USB HDD (A) + `main-pc`'s NVMe (C) → freeze + final
delta → wipe. Nothing destructive starts until both copies verify against the
manifest. Evacuation (01) **done 2026-10-05** — copies A + C verified, freeze +
final delta run, SMART long test on A passed — so the wipe (05) is unblocked.
Usenet accounts (Eweka + NZBGeek) done 2026-10-05, credentials in
`secrets/home-server.yaml`; secrets (sops-nix) done for main-pc. The
`home-server` host (06) is **installed and running** 2026-10-05 (`home-server`,
192.168.0.73, bound on the router, deployed from main-pc). Still to do: idle-draw measurement (plug
meter ordered 2026-10-05; measure as-is, then with runtime D3) and thermals.
Tailscale (07) done for home-server 2026-10-05 (tailnet owned by
walter@pariggers.com); the NAS joined 2026-10-05, key expiry off on both — 07's
off-LAN and laptop-down checks remain. **NAS rebuilt (05) 2026-10-05:** DSM
7.4.1, SHR-1 over all four disks (5.3 TiB), `data` + `photos` exported to
home-server with squash "Map all users to admin" (write + hardlink tested from
home-server). Resync is *Healthy* and home-server's addresses are bound on the
router; left in 05: the memory test, running since 2026-10-05 (must pass before 10).
**08 (GPU + NFS), 11 (arr stack) and 12 (Jellyfin + Jellyseerr) done 2026-10-05; 09 (Immich) is next.**

**Handoff, end of 2026-10-05 session.** Running on home-server now: Jellyfin
(`:8096`), Jellyseerr (`:5055`), Radarr (`:7878`), Sonarr (`:8989`), Prowlarr
(`:9696`), SABnzbd (`:8080`); mounts `/data` + `/photos` from the NAS
(192.168.0.70) with `nas-mount-guard`; podman + GPU toolkit. Code is in
`modules/server/{storage,media,arr}.nix`. Tickets 08, 11, 12 are done; one real
film (Obsession 2026) went request → download → import → Jellyfin.
- **Next: 09 Immich** (CUDA on the 3060, Postgres + thumbnails on NVMe, originals on
  `/photos`). Order its units on `RequiresMountsFor = [ "/photos" ]`. Hold **10**
  (import) until the NAS memory test passes.
- **Still waiting on Walter:** the `memtester` result (running; gate for 10), the
  plug-meter reading, a day of uptime for 06 (server rebooted 2026-10-05 ~21:15),
  and 07's home-server-down check (postponed; do it after the uptime tick, since
  it resets the clock). Then 13 (restic, must call `nas-mount-guard /data /photos`) and 14.
- **Gotchas learned.** SABnzbd's in-app Restart does not survive in a container:
  `systemctl restart podman-sabnzbd`. A release with a foreign title (e.g.
  "Saplanti") ends as `importBlocked`: Radarr → Activity → Queue → manual import.
  Usenet imports are a rename inside one export, not a hardlink. Arr/SAB settings
  live in `/var/lib/<app>` (backup scope for 13), not in Nix. API keys are in each
  app's `config.xml`; none are in the repo.

**Renewals:** NZBGeek expires **2027-10-08**, Eweka (15-month plan) ~**2028-01-05**.
Black Friday is the time to look at an NZBGeek lifetime deal and a block account
on a second backbone (not Omicron) for missing articles — see nas/build 04.

### Future improvement: an offsite copy

Deferred 2026-10-04 because the Google account situation is unsettled: the 5 TB
lives on a personal `@gmail.com` account (made because Health/Gemini refuse the
`pariggers.com` Workspace account), not on Workspace as the plan assumed. Until
it's decided which account stays, there is **no offsite copy** — neither the
one-off evacuation upload ([ticket 02](nas/build/issues/02-seed-google-drive-offsite.md))
nor the Drive leg of the restic 3-2-1 ([ticket 13](nas/build/issues/13-restic-321-service.md)).
Revisit once the account is settled; the alternative is a different offsite
target (e.g. B2/Hetzner Storage Box) or a USB disk kept at someone else's house.

**Half-settled 2026-10-05:** `walter@pariggers.com` is permanent (Walter: "100%
not changing away"); the personal `@gmail.com` is the one that may go. So
anything long-lived belongs to pariggers.com (Tailscale does, ticket 07), and the
offsite copy should not land on the gmail account's 5 TB unless that account is
explicitly kept.

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
