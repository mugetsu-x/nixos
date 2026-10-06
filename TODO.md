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
192.168.0.73, bound on the router, deployed from main-pc). Uptime and thermals were
ticked 2026-10-06. Still to do: the plug-meter idle reading, and the upower
low-battery shutdown, which is urgent (see the handoff).
Tailscale (07) done for home-server 2026-10-05 (tailnet owned by
walter@pariggers.com); the NAS joined 2026-10-05, key expiry off on both — 07's
off-LAN and laptop-down checks remain. **NAS rebuilt (05) 2026-10-05:** DSM
7.4.1, SHR-1 over all four disks (5.3 TiB), `data` + `photos` exported to
home-server with squash "Map all users to admin" (write + hardlink tested from
home-server). Resync is *Healthy* and home-server's addresses are bound on the
router; the memory test **passed 2026-10-06** (memtester, 2 loops, 0 failures), so 05 is done (memtester removed from the NAS 2026-10-06).
**08 (GPU + NFS), 11 (arr stack) and 12 (Jellyfin + Jellyseerr) done 2026-10-05;
09 (Immich) deployed and set up 2026-10-06; 10 (photo import) running.**

**Handoff, end of 2026-10-06 session.** Running on home-server now: Jellyfin
(`:8096`), Jellyseerr (`:5055`), Radarr (`:7878`), Sonarr (`:8989`), Prowlarr
(`:9696`), SABnzbd (`:8080`), Immich (`:2283`, since 2026-10-06); mounts `/data` + `/photos` from the NAS
(192.168.0.70) with `nas-mount-guard`; podman + GPU toolkit. Code is in
`modules/server/{storage,media,arr,immich}.nix`. Tickets 08, 11, 12 are done; one real
film (Obsession 2026) went request → download → import → Jellyfin.
- **10, the photo import, is running *detached* on main-pc.**
  - It runs as `immich-import.service`, a transient user unit. **Read 10's
    "Handover" first.** Status: `cat ~/.cache/immich-import/run.log`.
  - Walter is done: 18,429 assets, 3,926 duplicates skipped, 11 files that were
    already 0-byte on the old NAS. Anja's upload (~300 GB) started 21:33, followed by
    a re-check pass for each account (must find 0 new).
  - **Keep main-pc on and logged in** until the run and the ML queues finish.
    The 3080 does the ML (`modules/immich-ml.nix`, started by hand), and the
    3060's NVENC does video.
  - Then: reconcile counts, reset job concurrency, stop the main-pc worker,
    **delete both API keys**.
- **09, Immich:** deployed 2026-10-06 (`modules/server/immich.nix`, v3.2.4,
  `http://home-server:2283`). Setup is done (storage template, labels
  `walter`/`anja`, partner sharing both ways, CUDA ML, NVENC). Left: confirm a DB
  dump in `/photos/backups` after the 02:00 run on 2026-10-07, and the PC-off
  fallback test.
- **Urgent, 06: the upower low-battery shutdown.**
  - Unplugged to park the battery at 60 %, the server drew **35.8 W** under the
    import and was at **36 %** by 21:30, ~38 min from flat with Postgres
    mid-write.
  - Charger back in; it now charges to the ~60 % cap and holds.
  - Idle on battery is ~2.4 W. Runtime D3 works on its own: the old "stuck in
    P0" was `nvidia-smi` waking the GPU.
- **Still waiting on Walter:** the plug-meter reading (06), the private photos
  into the Locked Folder (10), and 07's home-server-down check (**deferred by
  Walter**, do it any time).
- **Next builds:** 13 (restic; must call `nas-mount-guard /data /photos`; skip
  `/var/cache/immich`; Postgres via the dumps in `/photos/backups`), then 14.
  **New 2026-10-06, not grilled:** 15 Paperless-ngx, 16 Homepage, 17 Actual
  Budget, 18 Home Assistant, 19 Mealie (in `nas/build/`). 15/17/19 hold
  irreplaceable data, so they wait for 13. 17/18 need one shared HTTPS answer
  (tailscale serve?).
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
