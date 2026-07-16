# nixos-config

Flake-based NixOS config for a single machine. One host (`main-pc`), one user
(`rennsemml`). Hyprland on Wayland, NVIDIA, Catppuccin Macchiato Blue everywhere.

Remote: `git@github.com:mugetsu-x/nixos.git`. CI runs `nix flake check --no-build`
on every push (`.github/workflows/check.yml`).

Planned work lives in [TODO.md](TODO.md) — read it before starting something new,
and keep it updated as items land.

## Rebuild

```
nixre     # alias for: sudo nixos-rebuild switch --flake ~/nixos-config#main-pc
nixhome   # alias for: cd ~/nixos-config
```

Both aliases are defined in `home/modules/shell.nix`, not in a shell rc file.

Channel: nixpkgs `nixos-25.05`, home-manager `release-25.05` (pinned to follow
nixpkgs). `system.stateVersion` and `home.stateVersion` are both `25.05` — do not
bump these to "update"; they are compatibility markers.

## Layout

```
flake.nix              inputs + the single nixosConfigurations.main-pc
hosts/main-pc.nix      host entrypoint: imports modules/, wires home-manager
modules/               system-level (NixOS options)
  hardware.nix         disk UUIDs, kernel modules — machine-specific, rarely touched
  nvidia.nix           nvidia open driver + Wayland env vars
  common.nix           bootloader, networking, locale, audio, bluetooth, fonts, user
  login.nix            greetd + regreet greeter, UWSM-managed Hyprland session
  gaming.nix           steam (+ GE-Proton), gamemode, gamescope
home/
  rennsemml.nix        home-manager entrypoint: imports home/modules/
  modules/             user-level (home-manager options)
    packages.nix       home.packages — the big app/CLI list
    shell.nix          zsh (aliases live here) + starship prompt
    wayland.nix        links dotfiles/ into ~/.config; waybar/hyprpaper/mako,
                       hyprlock, hypridle
    services.nix       cliphist, udiskie, blueman-applet + the hand-written
                       bt-autoconnect unit
    neovim-lazyvim.nix LazyVim starter pinned by commit + LSP/formatter overrides
    zed.nix            Zed — the primary editor. Nix-pinned node + LSP binaries
    claude.nix         symlinks claude/ (skills, settings, workspace rules) into place
    dev.nix            baseline dev toolchain (node, pnpm, tsc, psql, httpie)
    chrome.nix         google-chrome + Wayland .desktop override + default browser
    theme.nix          GTK/Qt theming, cursor, qt6ct palette
    pwas.nix           Chrome --app= desktop entries (Teams, Outlook, Notion, ...)
    gaming.nix         mangohud, vulkan-tools (system half is modules/gaming.nix)
  lib/
    ts-packages.nix    the shared LSP/formatter list (Neovim + Zed both import it)
  dotfiles/            raw config files, sourced verbatim by wayland.nix
    hypr/ kitty/ mako/ waybar/ wofi/
claude/                Claude Code config, symlinked live by home/modules/claude.nix
  skills/              user-level skills (grill-me + Matt Pocock's engineering set)
  settings.json        global Claude Code settings
  workspace-CLAUDE.md  house rules for every project under ~/workspace
templates/nextjs/      `nix flake init -t ~/nixos-config#nextjs` — project scaffold
```

## Where things go

- **New CLI tool or GUI app** → `home/modules/packages.nix`.
- **System service, driver, hardware, boot** → `modules/`.
- **Anything scoped to my user** → `home/modules/`.
- **Hyprland/waybar/kitty/wofi/mako tweaks** → edit the file in `home/dotfiles/`
  directly. These are plain config files symlinked in by `wayland.nix`; you do
  not need to touch Nix to change a keybind or a bar module.
- **Something that should run in the background** → prefer a home-manager module
  (`services.foo.enable`) over `exec-once` in `hyprland.conf` or a hand-written
  `systemd.user.services` block. See below.
- **Shell alias** → `shellAliases` in `home/modules/shell.nix`.
- **Claude Code skill / settings / workspace rules** → edit the file in
  `claude/` directly. It is symlinked live into `~/.claude` and `~/workspace`
  (see `home/modules/claude.nix`), so changes are picked up with no rebuild.

## Conventions that matter

- **home-manager runs as a NixOS module**, not standalone. `useGlobalPkgs` and
  `useUserPackages` are both `true`, so user packages land in
  `/etc/profiles/per-user/rennsemml/bin`, **not** `~/.nix-profile/bin`. If
  something references `~/.nix-profile`, it is stale.
- `backupFileExtension = "hm-bak"` — home-manager will move conflicting files to
  `*.hm-bak` instead of failing the switch.
- `allowUnfree = true` is set once in `modules/common.nix` and inherited by
  home-manager via `useGlobalPkgs`. Don't re-declare it in `home/`.
- Nix files are formatted with **nixfmt-rfc-style** (the `nixfmt` binary).
- **No editor is allowed to download its own language servers.** Both Neovim's
  Mason and Zed's built-in downloader fetch dynamically linked binaries that have
  no `ld.so` to link against on NixOS: they fail, sometimes silently, and you get
  an editor with no types. Every LSP comes from Nix. See "Development" below.
- The LazyVim starter is pinned by `rev` + `sha256`. Bumping it requires updating
  both.
- Theming is Catppuccin **Macchiato, Blue accent**, dark. Palette hexes are
  duplicated in `theme.nix` (Qt colors), `shell.nix` (starship), and the waybar/
  kitty/wofi dotfiles — a color change touches several files.
- `nix.gc` runs weekly, deleting generations older than 14 days; boot menu is
  capped at 20 entries.
- **Background apps are systemd user units, not `exec-once`.** waybar, hyprpaper,
  cliphist, udiskie and blueman-applet are enabled via their home-manager
  modules; mako is D-Bus activated. The *only* remaining `exec-once` in
  `hyprland.conf` is the polkit agent. Debug them with
  `journalctl --user -u waybar` etc., not by hunting for stray processes.
- These modules generate a config file *only* when their `settings` option is
  non-empty. We deliberately leave `settings` unset so the raw files in
  `home/dotfiles/` remain the source of truth. If you ever set `settings`, it
  will collide with the `xdg.configFile` link in `wayland.nix`.

## Development

TypeScript, fullstack. **Zed** is the primary editor; Neovim stays as `$EDITOR`
and for quick edits. VSCode and Cursor were deliberately removed.

**Adding a language server** — one place: `home/lib/ts-packages.nix`. Both
`zed.nix` and `neovim-lazyvim.nix` import that list, so the package lands on both
editors' PATH. Then wire it up in each editor that should use it:

- Zed → an `lsp.<name>.binary` entry in `zed.nix` with **both `path` and
  `arguments`**.
- Neovim → a `mason = false` entry in the `lsp-nix.lua` block.

**Setting `binary.path` in Zed discards the adapter's default arguments.** You
must supply them yourself. Anything built on `vscode-languageserver` (vtsls,
eslint, tailwind) needs `--stdio`; marksman needs `server`; nixd defaults to
stdio. Get this wrong and the server launches and dies on the spot —

```
Error: Connection input stream is not set ... set '--stdio'
ERROR [lsp] cannot read LSP message headers
```

— which presents as an editor with no hover types and no diagnostics, with the
real cause buried in `~/.local/share/zed/logs/Zed.log`. **That log is the first
place to look whenever Zed "works but has no types".**

Zed will otherwise download its own server (and its own Node) and it will not run.
`node.path`/`node.npm_path` in `zed.nix` exist for exactly this reason — do not
remove them "because Zed bundles Node".

`load_direnv = "direct"` in `zed.nix` is what makes Zed's language servers see a
project's devShell. Without it, a project pinning its own Node version is ignored
by the editor even though the terminal has it right.

**Toolchain layering.** `home/modules/dev.nix` puts `node`, `pnpm`, `tsc`, `psql`
and `httpie` in the user profile as a baseline, so a bare shell — and any AI agent
spawned into one — is never toolchain-less. Per-project versions come from a flake
devShell loaded by direnv and shadow the global ones.

**Starting a project.** Order matters: `create-next-app` refuses to run in a
non-empty directory, so scaffold the app *first* and layer the Nix template on
top. Step 1 runs on the global toolchain from `dev.nix`, which is the whole
reason it exists.

```
mkdir ~/workspace/foo && cd ~/workspace/foo
pnpm create next-app .                    # global pnpm — no devShell yet
nix flake init -t ~/nixos-config#nextjs   # adds flake.nix, .envrc, compose.yaml, .env.example
echo ".direnv/" >> .gitignore
direnv allow                              # once; afterwards `cd` is enough
cp .env.example .env && docker compose up -d   # Postgres 16 on :5432
```

The template deliberately ships **no** `.gitignore` — `create-next-app` writes
one, and `nix flake init` refuses to overwrite an existing file.

`docker compose down -v` wipes the database. The volume is project-scoped, so
resetting is free.

## Non-obvious bits

- **Two monitors, stacked vertically.** DP-2 is a 3440x1440 ultrawide at `0x0`;
  DP-4 is a 1920x1080 panel *below* it at `760x1440` (centred under it), **not**
  to its right. Waybar is pinned to DP-4 alone via `"output"` in
  `waybar/config.jsonc` — drop that key and you get a bar on every output.
- Monitor **refresh rates are pinned explicitly** (165 Hz / 120 Hz). Do not
  "simplify" these back to `preferred`: the EDID-preferred mode is 60 Hz on both
  panels, so `preferred` silently costs you the high refresh rate.
- Chrome and all PWAs are launched with `--ozone-platform-hint=wayland`. The
  Gemini PWA additionally uses a separate `--user-data-dir` so it has its own
  Google login, isolated from the main Chrome profile.
- `nix-claude-code` is a third-party flake input, installed as a *system* package
  in `hosts/main-pc.nix` and passed through `specialArgs`. It is pinned with
  `inputs.nixpkgs.follows = "nixpkgs"` — without that it drags in a second, full
  nixos-unstable nixpkgs. Keep the `follows`.
- **Claude Code config is symlinked *out of store*** (`mkOutOfStoreSymlink` in
  `home/modules/claude.nix`), pointing at `~/nixos-config/claude/` in the live
  working tree, not a `/nix/store` copy. This is deliberate: a store copy is
  read-only and Claude Code writes back to `settings.json` (e.g. `/config`),
  which would fail. The trade-off is the symlink resolves to a fixed path, so
  the repo must stay at `~/nixos-config`. Only `skills/`, `settings.json` and
  the workspace rules are managed; credentials/sessions/memory under `~/.claude`
  are left alone.
- The bluetooth auto-connect user service is a shell script built inline with
  `pkgs.writeShellScript` in `home/modules/services.nix`.
- **Zed's agent needs a Secret Service, and bare Hyprland has none.** Zed keeps
  API keys in the `org.freedesktop.secrets` D-Bus service. Without a provider it
  logs `Failed to authenticate provider: Anthropic: DBus error ... The name is
  not activatable` and silently cannot store credentials. `modules/keyring.nix`
  enables gnome-keyring for this, unlocked by PAM on the **greetd** service (not
  `login` — greetd is what actually authenticates you). `kwalletd6` being present
  is a red herring: it does not claim the freedesktop name.
- Zed's binary is **`zeditor`**, not `zed` (nixpkgs names it that way).
- **Hyprland keybind keys are XKB keysym names, and a bad one fails silently.**
  Hyprland registers the bind and shows it in `hyprctl binds`, but it can never
  fire — `ESC` is not a keysym (`Escape`/`escape` is), so `bind = SUPER, ESC`
  looks correct and does nothing. If a bind is listed but dead, check the keysym
  name first.
